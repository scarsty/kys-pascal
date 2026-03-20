#pragma once

#include <cstdint>
#include <string>
#include <vector>

namespace kys {

struct PngIndexMeta {
    int num = -1;
    int frame = 0;
    std::int16_t x = 0;
    std::int16_t y = 0;
    std::int16_t loaded = 0;
    std::int16_t useGrp = 0;
};

struct ResourceSummary {
    int mPicAmount = 0;
    int sPicAmount = 0;
    int bPicAmount = 0;
    int ePicAmount = 0;
    int cPicAmount = 0;
    int hPicAmount = 0;

    std::size_t mFrames = 0;
    std::size_t sFrames = 0;
    std::size_t bFrames = 0;
    std::size_t eFrames = 0;
    std::size_t cFrames = 0;
};

class ResourceLoader {
public:
    explicit ResourceLoader(std::string appPath);

    void setPngTileMode(int mode) { pngTileMode_ = mode; }

    std::vector<std::uint8_t> readFileToBuffer(const std::string& relativePath) const;

    bool loadIdxGrp(const std::string& idxRelPath,
                    const std::string& grpRelPath,
                    std::vector<std::int32_t>& idxArray,
                    std::vector<std::uint8_t>& grpArray) const;

    int loadPngTiles(const std::string& path,
                     std::vector<PngIndexMeta>& pngIndexArray,
                     std::size_t& frameCount) const;

    ResourceSummary readTilesSummary() const;

private:
    std::string appPath_;
    int pngTileMode_ = 1;

    bool fileExists(const std::string& relativePath) const;
    std::string joinPath(const std::string& relativePath) const;
};

} // namespace kys
