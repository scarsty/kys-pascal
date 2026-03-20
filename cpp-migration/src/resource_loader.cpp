#include "resource_loader.hpp"

#include <algorithm>
#include <cstring>
#include <filesystem>
#include <fstream>

namespace kys {
namespace {

template <typename T>
T readLE(const std::uint8_t* p) {
    T v{};
    std::memcpy(&v, p, sizeof(T));
    return v;
}

} // namespace

ResourceLoader::ResourceLoader(std::string appPath) : appPath_(std::move(appPath)) {}

std::string ResourceLoader::joinPath(const std::string& relativePath) const {
    if (appPath_.empty()) {
        return relativePath;
    }
    if (appPath_.back() == '/' || appPath_.back() == '\\') {
        return appPath_ + relativePath;
    }
    return appPath_ + "/" + relativePath;
}

bool ResourceLoader::fileExists(const std::string& relativePath) const {
    return std::filesystem::exists(joinPath(relativePath));
}

std::vector<std::uint8_t> ResourceLoader::readFileToBuffer(const std::string& relativePath) const {
    const auto full = joinPath(relativePath);
    std::ifstream in(full, std::ios::binary);
    if (!in) {
        return {};
    }
    in.seekg(0, std::ios::end);
    const auto size = static_cast<std::size_t>(in.tellg());
    in.seekg(0, std::ios::beg);

    std::vector<std::uint8_t> buf(size);
    if (size > 0) {
        in.read(reinterpret_cast<char*>(buf.data()), static_cast<std::streamsize>(size));
        if (!in.good()) {
            return {};
        }
    }
    return buf;
}

bool ResourceLoader::loadIdxGrp(const std::string& idxRelPath,
                                const std::string& grpRelPath,
                                std::vector<std::int32_t>& idxArray,
                                std::vector<std::uint8_t>& grpArray) const {
    if (!idxArray.empty()) {
        return true;
    }

    grpArray = readFileToBuffer(grpRelPath);
    if (grpArray.empty() && !fileExists(grpRelPath)) {
        return false;
    }

    auto idxRaw = readFileToBuffer(idxRelPath);
    if (idxRaw.empty() && !fileExists(idxRelPath)) {
        return false;
    }

    const std::size_t tnum = idxRaw.size() / sizeof(std::int32_t);
    idxArray.resize(tnum + 1, 0);
    if (tnum > 0) {
        std::memcpy(idxArray.data(), idxRaw.data(), tnum * sizeof(std::int32_t));
    }
    return true;
}

int ResourceLoader::loadPngTiles(const std::string& path,
                                 std::vector<PngIndexMeta>& pngIndexArray,
                                 std::size_t& frameCount) const {
    pngIndexArray.clear();
    frameCount = 0;

    std::vector<std::uint8_t> imz;
    if (pngTileMode_ == 2) {
        imz = readFileToBuffer(path + ".imz");
    }

    if (pngTileMode_ == 2 && !imz.empty() && imz.size() >= 4) {
        int result = readLE<std::int32_t>(imz.data());
        result = std::max(0, result);

        for (int i = result - 1; i >= 0; --i) {
            const std::size_t offPos = 4 + static_cast<std::size_t>(i) * 4;
            if (offPos + 8 > imz.size()) {
                continue;
            }
            const auto pngoff = static_cast<std::size_t>(readLE<std::int32_t>(imz.data() + offPos));
            if (pngoff + 8 > imz.size()) {
                continue;
            }
            const auto frame = readLE<std::int32_t>(imz.data() + pngoff + 4);
            if (frame > 0) {
                result = i + 1;
                break;
            }
        }

        pngIndexArray.resize(static_cast<std::size_t>(result));
        int count = 0;
        for (int i = 0; i < result; ++i) {
            const std::size_t offPos = 4 + static_cast<std::size_t>(i) * 4;
            if (offPos + 4 > imz.size()) {
                break;
            }
            const auto pngoff = static_cast<std::size_t>(readLE<std::int32_t>(imz.data() + offPos));
            if (pngoff + 8 > imz.size()) {
                break;
            }

            auto& m = pngIndexArray[static_cast<std::size_t>(i)];
            m.num = count;
            m.x = readLE<std::int16_t>(imz.data() + pngoff);
            m.y = readLE<std::int16_t>(imz.data() + pngoff + 2);
            m.frame = readLE<std::int32_t>(imz.data() + pngoff + 4);
            m.loaded = 0;
            m.useGrp = 0;
            count += std::max(0, m.frame);
        }
        frameCount = static_cast<std::size_t>(count);
        return result;
    }

    // Fall back to PNG_TILE=1 folder mode.
    auto offsetRaw = readFileToBuffer(path + "/index.ka");
    std::vector<std::int16_t> offset;
    offset.resize(offsetRaw.size() / sizeof(std::int16_t), 0);
    if (!offsetRaw.empty()) {
        std::memcpy(offset.data(), offsetRaw.data(), offset.size() * sizeof(std::int16_t));
    }

    int result = 0;
    const int maxProbe = static_cast<int>(offsetRaw.size() / 4);
    for (int i = maxProbe; i >= 0; --i) {
        const auto single = path + "/" + std::to_string(i) + ".png";
        const auto multi0 = path + "/" + std::to_string(i) + "_0.png";
        if (fileExists(single) || fileExists(multi0)) {
            result = i + 1;
            break;
        }
    }

    pngIndexArray.resize(static_cast<std::size_t>(result));
    int count = 0;
    for (int i = 0; i < result; ++i) {
        auto& m = pngIndexArray[static_cast<std::size_t>(i)];
        m.num = -1;
        m.frame = 0;

        const auto single = path + "/" + std::to_string(i) + ".png";
        if (fileExists(single)) {
            m.num = count;
            m.frame = 1;
            count += 1;
        } else {
            int k = 0;
            while (fileExists(path + "/" + std::to_string(i) + "_" + std::to_string(k) + ".png")) {
                if (k == 0) {
                    m.num = count;
                }
                ++k;
                ++count;
            }
            m.frame = k;
        }

        const std::size_t xPos = static_cast<std::size_t>(i) * 2;
        const std::size_t yPos = xPos + 1;
        m.x = xPos < offset.size() ? offset[xPos] : 0;
        m.y = yPos < offset.size() ? offset[yPos] : 0;
        m.loaded = 0;
        m.useGrp = 0;
    }

    frameCount = static_cast<std::size_t>(count);
    return result;
}

ResourceSummary ResourceLoader::readTilesSummary() const {
    ResourceSummary s;

    if (pngTileMode_ == 0) {
        std::vector<std::int32_t> idx;
        std::vector<std::uint8_t> grp;

        if (loadIdxGrp("resource/mmap.idx", "resource/mmap.grp", idx, grp)) {
            s.mPicAmount = static_cast<int>(idx.size() > 0 ? idx.size() - 1 : 0);
        }
        idx.clear(); grp.clear();
        if (loadIdxGrp("resource/sdx", "resource/smp", idx, grp)) {
            s.sPicAmount = static_cast<int>(idx.size() > 0 ? idx.size() - 1 : 0);
        }
        idx.clear(); grp.clear();
        if (loadIdxGrp("resource/wdx", "resource/wmp", idx, grp)) {
            s.bPicAmount = static_cast<int>(idx.size() > 0 ? idx.size() - 1 : 0);
        }
        idx.clear(); grp.clear();
        if (loadIdxGrp("resource/eft.idx", "resource/eft.grp", idx, grp)) {
            s.ePicAmount = static_cast<int>(idx.size() > 0 ? idx.size() - 1 : 0);
        }
        idx.clear(); grp.clear();
        if (loadIdxGrp("resource/cloud.idx", "resource/cloud.grp", idx, grp)) {
            s.cPicAmount = static_cast<int>(idx.size() > 0 ? idx.size() - 1 : 0);
        }
        idx.clear(); grp.clear();
        if (loadIdxGrp("resource/hdgrp.idx", "resource/hdgrp.grp", idx, grp)) {
            s.hPicAmount = static_cast<int>(idx.size() > 0 ? idx.size() - 1 : 0);
        }
        return s;
    }

    std::vector<PngIndexMeta> p;
    s.mPicAmount = loadPngTiles("resource/mmap", p, s.mFrames);
    s.sPicAmount = loadPngTiles("resource/smap", p, s.sFrames);
    s.bPicAmount = loadPngTiles("resource/wmap", p, s.bFrames);
    s.ePicAmount = loadPngTiles("resource/eft", p, s.eFrames);
    s.cPicAmount = loadPngTiles("resource/cloud", p, s.cFrames);

    return s;
}

} // namespace kys
