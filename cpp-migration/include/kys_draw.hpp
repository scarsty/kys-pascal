#pragma once
/// Tile / texture / font drawing helpers.
/// Extracted from sdl_runtime.cpp; mirrors the kys_draw unit in Pascal.

#include "resource_loader.hpp"

#include <algorithm>
#include <array>
#include <cstdint>
#include <filesystem>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#if __has_include(<SDL3/SDL.h>)
#include <SDL3/SDL.h>
#define KYS_HAS_SDL3 1
#else
#define KYS_HAS_SDL3 0
#endif

#if __has_include(<SDL3_image/SDL_image.h>)
#include <SDL3_image/SDL_image.h>
#define KYS_HAS_SDL3_IMAGE 1
#else
#define KYS_HAS_SDL3_IMAGE 0
#endif

#if __has_include(<SDL3_ttf/SDL_ttf.h>)
#include <SDL3_ttf/SDL_ttf.h>
#define KYS_HAS_SDL3_TTF 1
#else
#define KYS_HAS_SDL3_TTF 0
#endif

namespace kys {

// ---------------------------------------------------------------------------
// RLE tile data structures (mmap.grp / sdx / smp format)
// ---------------------------------------------------------------------------

struct TileHeader {
    int width = 0;
    int height = 0;
    int xs = 0;
    int ys = 0;
    bool valid = false;
};

struct RleTile {
    SDL_Texture* texture = nullptr;
    int offsetX = 0;
    int offsetY = 0;
    int width = 0;
    int height = 0;
    TileHeader header;
    bool valid = false;
};

struct BuildDraw {
    int mapX = 0;
    int mapY = 0;
    int tile = 0;
    int sortKey = 0;
};

// ---------------------------------------------------------------------------
// MMapGrpCache — decodes RLE tiles from .grp/.idx/.col triplets
// ---------------------------------------------------------------------------

struct MMapGrpCache {
    explicit MMapGrpCache(SDL_Renderer* inRenderer,
                          std::string appPath,
                          std::string idxRelPath,
                          std::string grpRelPath,
                          std::string colRelPath)
        : renderer(inRenderer),
          loader(std::move(appPath)),
          idxPath(std::move(idxRelPath)),
          grpPath(std::move(grpRelPath)),
          colPath(std::move(colRelPath)) {
        initialize();
    }

    ~MMapGrpCache() {
        for (auto& kv : cache) {
            if (kv.second.texture) {
                SDL_DestroyTexture(kv.second.texture);
            }
        }
        cache.clear();
    }

    bool isLoaded() const {
        return loaded;
    }

    TileHeader headerFor(int tileId) {
        TileHeader h;
        const auto off = offsetFor(tileId);
        if (off >= grp.size() || off + 8 > grp.size()) {
            return h;
        }
        h.width = readI16(off + 0);
        h.height = readI16(off + 2);
        h.xs = readI16(off + 4);
        h.ys = readI16(off + 6);
        h.valid = h.width > 0 && h.height > 0;
        return h;
    }

    bool renderTile(int tileId, int px, int py) {
        RleTile* tile = getOrDecode(tileId);
        if (!tile || !tile->valid || !tile->texture) {
            return false;
        }

        SDL_FRect dst;
        dst.x = static_cast<float>(px + tile->offsetX);
        dst.y = static_cast<float>(py + tile->offsetY);
        dst.w = static_cast<float>(tile->width);
        dst.h = static_cast<float>(tile->height);
        SDL_RenderTexture(renderer, tile->texture, nullptr, &dst);
        return true;
    }

    void clearCache() {
        for (auto& kv : cache) {
            if (kv.second.texture) {
                SDL_DestroyTexture(kv.second.texture);
            }
        }
        cache.clear();
    }

    void applyPaletteRotation(int startIndex, int length, int phase) {
        if (!loaded || length <= 0) {
            return;
        }
        if (startIndex < 0 || startIndex + length > 256) {
            return;
        }

        const int normalized = ((phase % length) + length) % length;
        if (normalized == paletteRotationPhase_ && paletteRotationStart_ == startIndex && paletteRotationLength_ == length) {
            return;
        }

        palette = basePalette;
        const std::size_t start = static_cast<std::size_t>(startIndex) * 3U;
        const std::size_t lenBytes = static_cast<std::size_t>(length) * 3U;
        const std::size_t shiftBytes = static_cast<std::size_t>(normalized) * 3U;

        std::copy_n(basePalette.begin() + start, lenBytes - shiftBytes, palette.begin() + start + shiftBytes);
        std::copy_n(basePalette.begin() + start + (lenBytes - shiftBytes), shiftBytes, palette.begin() + start);

        paletteRotationStart_ = startIndex;
        paletteRotationLength_ = length;
        paletteRotationPhase_ = normalized;
        clearCache();
    }

private:
    SDL_Renderer* renderer = nullptr;
    ResourceLoader loader;
    std::string idxPath;
    std::string grpPath;
    std::string colPath;
    std::vector<std::int32_t> idx;
    std::vector<std::uint8_t> grp;
    std::array<std::uint8_t, 768> basePalette{};
    std::array<std::uint8_t, 768> palette{};
    std::unordered_map<int, RleTile> cache;
    std::unordered_map<int, bool> decodeFailed;
    bool loaded = false;
    int paletteRotationStart_ = -1;
    int paletteRotationLength_ = 0;
    int paletteRotationPhase_ = -1;

    static int readI16(const std::vector<std::uint8_t>& b, std::size_t off) {
        if (off + 1 >= b.size()) {
            return 0;
        }
        const std::uint16_t lo = b[off];
        const std::uint16_t hi = b[off + 1];
        const std::uint16_t u = static_cast<std::uint16_t>(lo | (hi << 8));
        return static_cast<std::int16_t>(u);
    }

    int readI16(std::size_t off) const {
        return readI16(grp, off);
    }

    void initialize() {
        if (!loader.loadIdxGrp(idxPath, grpPath, idx, grp)) {
            loaded = false;
            return;
        }
        const auto col = loader.readFileToBuffer(colPath);
        if (col.size() < palette.size()) {
            loaded = false;
            return;
        }
        std::copy_n(col.begin(), palette.size(), basePalette.begin());
        palette = basePalette;
        loaded = true;
    }

    std::size_t offsetFor(int tileId) const {
        if (tileId < 0 || grp.empty()) {
            return grp.size();
        }
        if (tileId == 0) {
            return 0;
        }
        const std::size_t idxPos = static_cast<std::size_t>(tileId - 1);
        if (idxPos >= idx.size()) {
            return grp.size();
        }
        const int off = idx[idxPos];
        if (off < 0) {
            return grp.size();
        }
        return static_cast<std::size_t>(off);
    }

    std::size_t endFor(int tileId, std::size_t offset) const {
        if (offset >= grp.size()) {
            return grp.size();
        }
        const std::size_t nextPos = static_cast<std::size_t>(tileId);
        if (nextPos < idx.size()) {
            const int off = idx[nextPos];
            if (off > 0 && static_cast<std::size_t>(off) > offset && static_cast<std::size_t>(off) <= grp.size()) {
                return static_cast<std::size_t>(off);
            }
        }
        return grp.size();
    }

    RleTile* getOrDecode(int tileId) {
        if (!loaded || !renderer || tileId < 0) {
            return nullptr;
        }
        if (auto it = cache.find(tileId); it != cache.end()) {
            return &it->second;
        }
        if (decodeFailed.find(tileId) != decodeFailed.end()) {
            return nullptr;
        }

        const auto off = offsetFor(tileId);
        const auto end = endFor(tileId, off);
        if (off >= grp.size() || off + 8 > end) {
            decodeFailed[tileId] = true;
            return nullptr;
        }

        TileHeader h;
        h.width = readI16(off + 0);
        h.height = readI16(off + 2);
        h.xs = readI16(off + 4);
        h.ys = readI16(off + 6);
        h.valid = h.width > 0 && h.height > 0;
        if (!h.valid) {
            decodeFailed[tileId] = true;
            return nullptr;
        }

        struct Px {
            int x;
            int y;
            std::uint8_t c;
        };
        std::vector<Px> pixels;
        pixels.reserve(static_cast<std::size_t>(h.width * h.height));

        int minX = 0;
        int minY = 0;
        int maxX = 0;
        int maxY = 0;
        bool got = false;

        std::size_t p = off + 8;
        for (int iy = 1; iy <= h.height && p < end; ++iy) {
            const int l = grp[p++];
            int w = 1;
            int state = 0;
            for (int ix = 0; ix < l && p < end; ++ix) {
                const std::uint8_t l1 = grp[p++];
                if (state == 0) {
                    w += static_cast<int>(l1);
                    state = 1;
                } else if (state == 1) {
                    state = 2 + static_cast<int>(l1);
                } else {
                    const int x = w - h.xs;
                    const int y = iy - h.ys;
                    pixels.push_back(Px{x, y, l1});
                    if (!got) {
                        minX = maxX = x;
                        minY = maxY = y;
                        got = true;
                    } else {
                        minX = std::min(minX, x);
                        minY = std::min(minY, y);
                        maxX = std::max(maxX, x);
                        maxY = std::max(maxY, y);
                    }
                    ++w;
                    --state;
                    if (state == 2) {
                        state = 0;
                    }
                }
            }
        }

        if (!got) {
            decodeFailed[tileId] = true;
            return nullptr;
        }

        const int outW = std::max(1, maxX - minX + 1);
        const int outH = std::max(1, maxY - minY + 1);

        SDL_Surface* surface = SDL_CreateSurface(outW, outH, SDL_PIXELFORMAT_RGBA32);
        if (!surface) {
            decodeFailed[tileId] = true;
            return nullptr;
        }
        SDL_FillSurfaceRect(surface, nullptr, SDL_MapSurfaceRGBA(surface, 0, 0, 0, 0));

        auto* pxData = static_cast<std::uint8_t*>(surface->pixels);
        for (const auto& px : pixels) {
            const int x = px.x - minX;
            const int y = px.y - minY;
            if (x < 0 || y < 0 || x >= outW || y >= outH) {
                continue;
            }
            const std::size_t palOff = static_cast<std::size_t>(px.c) * 3;
            if (palOff + 2 >= palette.size()) {
                continue;
            }
            const std::uint8_t r = static_cast<std::uint8_t>(palette[palOff] * 4);
            const std::uint8_t g = static_cast<std::uint8_t>(palette[palOff + 1] * 4);
            const std::uint8_t b = static_cast<std::uint8_t>(palette[palOff + 2] * 4);
            const std::uint32_t mapped = SDL_MapSurfaceRGBA(surface, r, g, b, 255);
            auto* row = reinterpret_cast<std::uint32_t*>(pxData + static_cast<std::size_t>(y) * surface->pitch);
            row[x] = mapped;
        }

        SDL_Texture* tex = SDL_CreateTextureFromSurface(renderer, surface);
        SDL_DestroySurface(surface);
        if (!tex) {
            decodeFailed[tileId] = true;
            return nullptr;
        }

        RleTile tile;
        tile.texture = tex;
        tile.offsetX = minX;
        tile.offsetY = minY;
        tile.width = outW;
        tile.height = outH;
        tile.header = h;
        tile.valid = true;
        cache[tileId] = tile;
        return &cache[tileId];
    }
};

// ---------------------------------------------------------------------------
// TextureCache — loads PNG files from resource/mmap/
// ---------------------------------------------------------------------------

struct TextureCache {
    SDL_Renderer* renderer = nullptr;
    std::string appPath;
    std::unordered_map<int, SDL_Texture*> mmapCache;
    std::unordered_map<int, bool> missing;

    ~TextureCache() {
        for (auto& kv : mmapCache) {
            if (kv.second) {
                SDL_DestroyTexture(kv.second);
            }
        }
        mmapCache.clear();
        missing.clear();
    }

    std::string fullPath(const std::string& rel) const {
        if (appPath.empty()) {
            return rel;
        }
        if (appPath.back() == '/' || appPath.back() == '\\') {
            return appPath + rel;
        }
        return appPath + "/" + rel;
    }

    SDL_Texture* loadMMapTexture(int tileId) {
#if !KYS_HAS_SDL3_IMAGE
        (void)tileId;
        return nullptr;
#else
        if (tileId < 0) {
            return nullptr;
        }
        if (auto it = mmapCache.find(tileId); it != mmapCache.end()) {
            return it->second;
        }
        if (missing.find(tileId) != missing.end()) {
            return nullptr;
        }

        const std::string p1 = fullPath("resource/mmap/" + std::to_string(tileId) + ".png");
        const std::string p2 = fullPath("resource/mmap/" + std::to_string(tileId) + "_0.png");

        SDL_Surface* s = nullptr;
        if (std::filesystem::exists(p1)) {
            s = IMG_Load(p1.c_str());
        }
        if (!s && std::filesystem::exists(p2)) {
            s = IMG_Load(p2.c_str());
        }
        if (!s) {
            missing[tileId] = true;
            return nullptr;
        }

        SDL_Texture* tex = SDL_CreateTextureFromSurface(renderer, s);
        SDL_DestroySurface(s);
        if (!tex) {
            missing[tileId] = true;
            return nullptr;
        }
        mmapCache[tileId] = tex;
        return tex;
#endif
    }
};

// ---------------------------------------------------------------------------
// FontOverlay — TTF text rendering wrapper
// ---------------------------------------------------------------------------

struct FontOverlay {
#if KYS_HAS_SDL3_TTF
    TTF_Font* font = nullptr;
#endif

    bool init(const std::string& appPath) {
#if !KYS_HAS_SDL3_TTF
        (void)appPath;
        return false;
#else
        if (!TTF_Init()) {
            return false;
        }
        const std::string p1 = appPath + "/resource/chinese.ttf";
        const std::string p2 = appPath + "/resource/eng.ttf";
        if (std::filesystem::exists(p1)) {
            font = TTF_OpenFont(p1.c_str(), 16.0f);
        }
        if (!font && std::filesystem::exists(p2)) {
            font = TTF_OpenFont(p2.c_str(), 16.0f);
        }
        return font != nullptr;
#endif
    }

    void shutdown() {
#if KYS_HAS_SDL3_TTF
        if (font) {
            TTF_CloseFont(font);
            font = nullptr;
        }
        TTF_Quit();
#endif
    }

    void draw(SDL_Renderer* renderer, const std::string& text, int x, int y) {
#if !KYS_HAS_SDL3_TTF
        (void)renderer;
        (void)text;
        (void)x;
        (void)y;
#else
        if (!font || text.empty()) {
            return;
        }
        SDL_Color color{245, 245, 220, 255};
        SDL_Surface* s = TTF_RenderText_Blended(font, text.c_str(), static_cast<std::size_t>(text.size()), color);
        if (!s) {
            return;
        }
        SDL_Texture* t = SDL_CreateTextureFromSurface(renderer, s);
        const int w = s->w;
        const int h = s->h;
        SDL_DestroySurface(s);
        if (!t) {
            return;
        }
        SDL_FRect dst{static_cast<float>(x), static_cast<float>(y), static_cast<float>(w), static_cast<float>(h)};
        SDL_RenderTexture(renderer, t, nullptr, &dst);
        SDL_DestroyTexture(t);
#endif
    }

    void draw(SDL_Renderer* renderer, const std::string& text, int x, int y, uint8_t r, uint8_t g, uint8_t b) {
#if !KYS_HAS_SDL3_TTF
        (void)renderer;
        (void)text;
        (void)x;
        (void)y;
        (void)r;
        (void)g;
        (void)b;
#else
        if (!font || text.empty()) {
            return;
        }
        SDL_Color color{r, g, b, 255};
        SDL_Surface* s = TTF_RenderText_Blended(font, text.c_str(), static_cast<std::size_t>(text.size()), color);
        if (!s) {
            return;
        }
        SDL_Texture* t = SDL_CreateTextureFromSurface(renderer, s);
        const int w = s->w;
        const int h = s->h;
        SDL_DestroySurface(s);
        if (!t) {
            return;
        }
        SDL_FRect dst{static_cast<float>(x), static_cast<float>(y), static_cast<float>(w), static_cast<float>(h)};
        SDL_RenderTexture(renderer, t, nullptr, &dst);
        SDL_DestroyTexture(t);
#endif
    }
};

// ---------------------------------------------------------------------------
// Rendering helpers
// ---------------------------------------------------------------------------

/// Map a tile value to an SDL draw colour (fallback when no sprite is found).
inline void mapColor(SDL_Renderer* renderer, int v, int layer) {
    const auto b = static_cast<std::uint8_t>(v & 0xFF);
    switch (layer) {
        case 0: SDL_SetRenderDrawColor(renderer, static_cast<std::uint8_t>(20 + (b % 80)), static_cast<std::uint8_t>(80 + (b % 120)), static_cast<std::uint8_t>(20 + (b % 60)), 255); break;
        case 1: SDL_SetRenderDrawColor(renderer, static_cast<std::uint8_t>(40 + (b % 60)), static_cast<std::uint8_t>(40 + (b % 60)), static_cast<std::uint8_t>(80 + (b % 120)), 140); break;
        default: SDL_SetRenderDrawColor(renderer, static_cast<std::uint8_t>(80 + (b % 120)), static_cast<std::uint8_t>(60 + (b % 80)), static_cast<std::uint8_t>(40 + (b % 60)), 180); break;
    }
}

/// Convert isometric map coordinates to screen pixel position.
inline std::pair<int, int> getPositionOnScreen(int x, int y, int centerX, int centerY, int screenCenterX, int screenCenterY) {
    const int sx = -(x - centerX) * 18 + (y - centerY) * 18 + screenCenterX;
    const int sy = (x - centerX) * 9 + (y - centerY) * 9 + screenCenterY;
    return {sx, sy};
}

} // namespace kys
