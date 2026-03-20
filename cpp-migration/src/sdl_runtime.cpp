#include "sdl_runtime.hpp"

#include "kys_state.hpp"
#include "resource_loader.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cstdint>
#include <filesystem>
#include <sstream>
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

namespace {

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

private:
    SDL_Renderer* renderer = nullptr;
    ResourceLoader loader;
    std::string idxPath;
    std::string grpPath;
    std::string colPath;
    std::vector<std::int32_t> idx;
    std::vector<std::uint8_t> grp;
    std::array<std::uint8_t, 768> palette{};
    std::unordered_map<int, RleTile> cache;
    std::unordered_map<int, bool> decodeFailed;
    bool loaded = false;

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
        std::copy_n(col.begin(), palette.size(), palette.begin());
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
};

struct MainMenuState {
    enum class Page {
        Title,
        Root,
        System,
        LoadSlots,
        SaveSlots,
        QuitConfirm,
        Medical,
        Detox,
        ItemType,
        ItemList,
        ItemBrowse,
        ItemTarget,
        Status,
        StatusDetail,
        LeaveTeam,
        Teleport
    };

    bool open = true;  // Start with menu open
    int selected = 0;
    Page page = Page::Title;  // Start with title/start menu
    std::vector<Page> stack;
    std::string status;
    std::chrono::steady_clock::time_point statusTime{};
    int selectedItemType = -1;
    int selectedItemNumber = -1;
    int selectedRole = -1;
    
    // Item browse grid state
    int itemBrowseRow = 0;
    int itemBrowseCols = 0;
    int itemBrowseRows = 0;
    int itemStartIndex = 0;
    std::vector<int> itemBrowseList;  // List of item indices in browse grid

    static std::string pageTitle(Page p) {
        switch (p) {
            case Page::Title: return "乾宇傳說";
            case Page::Root: return "主選單";
            case Page::System: return "系統";
            case Page::LoadSlots: return "讀取";
            case Page::SaveSlots: return "存檔";
            case Page::QuitConfirm: return "離開";
            case Page::Medical: return "醫療";
            case Page::Detox: return "解毒";
            case Page::ItemType: return "物品分類";
            case Page::ItemList: return "物品列表";
            case Page::ItemBrowse: return "物品浏覽";
            case Page::ItemTarget: return "選擇對象";
            case Page::Status: return "狀態";
            case Page::StatusDetail: return "角色詳情";
            case Page::LeaveTeam: return "離隊";
            case Page::Teleport: return "傳送";
            default: return "Menu";
        }
    }

    void enter(Page p) {
        stack.push_back(page);
        page = p;
        selected = 0;
    }

    bool back() {
        if (stack.empty()) {
            open = false;
            return false;
        }
        page = stack.back();
        stack.pop_back();
        selected = 0;
        return true;
    }

    void resetToRoot() {
        open = true;
        page = Page::Root;
        selected = 0;
        stack.clear();
    }

    void setStatus(const std::string& s) {
        status = s;
        statusTime = std::chrono::steady_clock::now();
    }

    bool statusVisible() const {
        if (status.empty()) {
            return false;
        }
        const auto now = std::chrono::steady_clock::now();
        const auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now - statusTime).count();
        return ms < 2500;
    }
};

void mapColor(SDL_Renderer* renderer, int v, int layer) {
    const auto b = static_cast<std::uint8_t>(v & 0xFF);
    switch (layer) {
        case 0: SDL_SetRenderDrawColor(renderer, static_cast<std::uint8_t>(20 + (b % 80)), static_cast<std::uint8_t>(80 + (b % 120)), static_cast<std::uint8_t>(20 + (b % 60)), 255); break;
        case 1: SDL_SetRenderDrawColor(renderer, static_cast<std::uint8_t>(40 + (b % 60)), static_cast<std::uint8_t>(40 + (b % 60)), static_cast<std::uint8_t>(80 + (b % 120)), 140); break;
        default: SDL_SetRenderDrawColor(renderer, static_cast<std::uint8_t>(80 + (b % 120)), static_cast<std::uint8_t>(60 + (b % 80)), static_cast<std::uint8_t>(40 + (b % 60)), 180); break;
    }
}

std::pair<int, int> getPositionOnScreen(int x, int y, int centerX, int centerY, int screenCenterX, int screenCenterY) {
    const int sx = -(x - centerX) * 18 + (y - centerY) * 18 + screenCenterX;
    const int sy = (x - centerX) * 9 + (y - centerY) * 9 + screenCenterY;
    return {sx, sy};
}

} // namespace

SdlRuntime::SdlRuntime(KysState* state, std::string appPath) : state_(state), appPath_(std::move(appPath)) {}

int SdlRuntime::runLoop(int milliseconds) {
#if !KYS_HAS_SDL3
    (void)milliseconds;
    return 2;
#else
    if (!state_) {
        return 3;
    }

    if (!SDL_Init(SDL_INIT_VIDEO | SDL_INIT_EVENTS)) {
        return 4;
    }

    constexpr int kRenderWidth = 960;
    constexpr int kRenderHeight = 540;
    SDL_Window* window = SDL_CreateWindow("kys-cpp-migration", kRenderWidth, kRenderHeight, SDL_WINDOW_RESIZABLE);
    if (!window) {
        SDL_Quit();
        return 5;
    }

    SDL_Renderer* renderer = SDL_CreateRenderer(window, nullptr);
    if (!renderer) {
        SDL_DestroyWindow(window);
        SDL_Quit();
        return 6;
    }

    SDL_Texture* frameTexture = SDL_CreateTexture(
        renderer,
        SDL_PIXELFORMAT_RGBA8888,
        SDL_TEXTUREACCESS_TARGET,
        kRenderWidth,
        kRenderHeight);
    const bool useFixedRender = frameTexture != nullptr;
    if (frameTexture) {
        SDL_SetTextureScaleMode(frameTexture, SDL_SCALEMODE_NEAREST);
    }

    const auto begin = std::chrono::steady_clock::now();
    bool running = true;
    int mFace = state_->mapFace();
    int mStep = 0;
    int lastSceneEvent = -1;
    MainMenuState menu;
    TextureCache texCache;
    texCache.renderer = renderer;
    texCache.appPath = appPath_;
    MMapGrpCache mainGrpCache(renderer, appPath_, "resource/mmap.idx", "resource/mmap.grp", "resource/mmap.col");
    MMapGrpCache sceneGrpCache(renderer, appPath_, "resource/sdx", "resource/smp", "resource/mmap.col");
    FontOverlay overlay;
    const bool hasFont = overlay.init(appPath_);
    const std::string appPath = appPath_;

    auto getSavePath = [&appPath](int slot) -> std::string {
        std::ostringstream oss;
        oss << appPath << "/save/r" << slot << ".grp";
        return oss.str();
    };

    auto presentFrame = [&]() {
        if (useFixedRender) {
            SDL_SetRenderTarget(renderer, nullptr);
            SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
            SDL_RenderClear(renderer);

            int ww = 0;
            int wh = 0;
            SDL_GetWindowSize(window, &ww, &wh);
            if (ww <= 0 || wh <= 0) {
                ww = kRenderWidth;
                wh = kRenderHeight;
            }

            const float sx = static_cast<float>(ww) / static_cast<float>(kRenderWidth);
            const float sy = static_cast<float>(wh) / static_cast<float>(kRenderHeight);
            const float scale = std::min(sx, sy);
            const float outW = static_cast<float>(kRenderWidth) * scale;
            const float outH = static_cast<float>(kRenderHeight) * scale;
            SDL_FRect dst{
                (static_cast<float>(ww) - outW) * 0.5f,
                (static_cast<float>(wh) - outH) * 0.5f,
                outW,
                outH};
            SDL_RenderTexture(renderer, frameTexture, nullptr, &dst);
        }

        SDL_RenderPresent(renderer);
        SDL_Delay(16);
    };

    std::vector<int> teamSlotMap;
    std::vector<int> itemSlotMap;
    std::vector<int> sceneMap;

    auto buildTeamLines = [&](bool withHp, bool withPoison) {
        std::vector<std::string> lines;
        teamSlotMap.clear();
        for (int i = 0; i < KysState::kTeamSize; ++i) {
            const int role = state_->getTeam(i);
            if (role < 0) {
                continue;
            }
            std::ostringstream oss;
            oss << (i + 1) << ". " << state_->getRoleName(role);
            if (withHp) {
                oss << " HP:" << state_->roleCurrentHp(role) << "/" << state_->roleMaxHp(role);
            }
            if (withPoison) {
                oss << " 毒:" << state_->rolePoison(role);
            }
            lines.push_back(oss.str());
            teamSlotMap.push_back(i);
        }
        if (lines.empty()) {
            lines.push_back("（無隊友）");
        }
        return lines;
    };

    auto buildMenuItems = [&](bool isFullscreen) {
        std::vector<std::string> items;
        switch (menu.page) {
            case MainMenuState::Page::Root:
                items = {"醫療", "解毒", "物品", "狀態", "離隊", "傳送", "系統"};
                break;
            case MainMenuState::Page::System:
                items = {"讀取", "存檔", isFullscreen ? "窗口" : "全屏", "離開"};
                break;
            case MainMenuState::Page::LoadSlots:
                for (int i = 1; i <= 10; ++i) {
                    const bool ex = std::filesystem::exists(getSavePath(i));
                    items.push_back("進度" + std::to_string(i) + (ex ? " [可讀]" : " [空]"));
                }
                items.push_back("自動檔");
                break;
            case MainMenuState::Page::SaveSlots:
                for (int i = 1; i <= 10; ++i) {
                    const bool ex = std::filesystem::exists(getSavePath(i));
                    items.push_back("進度" + std::to_string(i) + (ex ? " [覆蓋]" : " [新建]"));
                }
                break;
            case MainMenuState::Page::QuitConfirm:
                items = {"取消", "確認", "腳本"};
                break;
            case MainMenuState::Page::Medical:
                items = buildTeamLines(true, false);
                break;
            case MainMenuState::Page::Detox:
                items = buildTeamLines(false, true);
                break;
            case MainMenuState::Page::Status:
                items = buildTeamLines(true, true);
                break;
            case MainMenuState::Page::StatusDetail:
                if (menu.selectedRole >= 0) {
                  const int r = menu.selectedRole;
                  // Format attributes like original: "标签 值  标签 值"
                  std::ostringstream line1;
                  line1 << state_->getRoleName(r) << " Lv" << state_->roleLevel(r)
                      << " 資質:" << state_->roleAptitude(r);
                  
                  std::ostringstream hp;
                  hp << "生命:" << state_->roleCurrentHp(r) << "/" << state_->roleMaxHp(r);
                  std::ostringstream mp;
                  mp << "內力:" << state_->roleCurrentMp(r) << "/" << state_->roleMaxMp(r);
                  std::ostringstream line2;
                  line2 << hp.str() << "  " << mp.str();
                  
                  std::ostringstream line2b;
                  line2b << "體力:" << state_->rolePhyPower(r)
                      << "  經驗:" << state_->roleCurrentExp(r) << "/" << state_->roleExpForItem(r);
                  
                  std::ostringstream line3;
                  line3 << "攻擊:" << state_->roleAttack(r)
                      << "  防禦:" << state_->roleDefence(r)
                      << "  輕功:" << state_->roleSpeed(r);
                  std::ostringstream line4;
                  line4 << "醫療:" << state_->roleMedcine(r)
                      << "  用毒:" << state_->roleUsePoi(r)
                      << "  解毒:" << state_->roleMedPoi(r);
                  std::ostringstream line5;
                  line5 << "拳掌:" << state_->roleFist(r)
                      << "  御劍:" << state_->roleSword(r)
                      << "  耍刀:" << state_->roleKnife(r);
                  std::ostringstream line6;
                  line6 << "奇門:" << state_->roleUnusual(r)
                      << "  暗器:" << state_->roleHidWeapon(r)
                      << "  品德:" << state_->roleEthics(r);
                  
                  std::ostringstream line7;
                  const int hurt = state_->roleHurt(r);
                  const int poison = state_->rolePoison(r);
                  line7 << "受傷:" << hurt;
                  if (hurt > 0) {
                      line7 << " [提醒]";
                  }
                  line7 << "  中毒:" << poison;
                  if (poison > 0) {
                      line7 << " [有毒]";
                  }

                  const int eq0 = state_->roleEquip(r, 0);
                  const int eq1 = state_->roleEquip(r, 1);
                  const int prac = state_->rolePracticeBook(r);
                  const std::string eq0Name = (eq0 >= 0) ? state_->getItemName(eq0) : "（無）";
                  const std::string eq1Name = (eq1 >= 0) ? state_->getItemName(eq1) : "（無）";
                  const std::string pracName = (prac >= 0) ? state_->getItemName(prac) : "（無）";

                  std::ostringstream line8;
                  line8 << "裝備1:" << eq0Name;
                  std::ostringstream line9;
                  line9 << "裝備2:" << eq1Name;
                  std::ostringstream line10;
                  line10 << "修煉:" << pracName;

                  items.push_back(line1.str());
                  items.push_back(line2.str());
                  items.push_back(line2b.str());
                  items.push_back(line3.str());
                  items.push_back(line4.str());
                  items.push_back(line5.str());
                  items.push_back(line6.str());
                  items.push_back(line7.str());
                  items.push_back(line8.str());
                  items.push_back(line9.str());
                  items.push_back(line10.str());

                  bool hasMagic = false;
                  for (int i = 0; i < 10; ++i) {
                    const int magicId = state_->roleMagic(r, i);
                        if (magicId <= 0) {
                        continue;
                    }
                    hasMagic = true;
                    std::ostringstream ml;
                    ml << state_->getMagicName(magicId)
                       << " Lv" << (state_->roleMagicLevel(r, i) / 100 + 1);
                    items.push_back(ml.str());
                  }
                  if (!hasMagic) {
                    items.push_back("（無武功）");
                  }
                    items.push_back("返回");
                } else {
                    items.push_back("（無角色）");
                }
                break;
            case MainMenuState::Page::LeaveTeam:
                items = buildTeamLines(false, false);
                break;
            case MainMenuState::Page::ItemType:
                items = {"劇情", "裝備", "秘笈", "藥品", "暗器", "整理"};
                break;
            case MainMenuState::Page::ItemList:
                itemSlotMap.clear();
                for (int i = 0; i < state_->itemListCount(); ++i) {
                    const int inum = state_->itemListNumber(i);
                    const int amount = state_->itemListAmount(i);
                    if (inum < 0 || amount <= 0) {
                        continue;
                    }
                    const int t = state_->itemType(inum);
                    if (menu.selectedItemType >= 0 && t != menu.selectedItemType) {
                        continue;
                    }
                    std::ostringstream oss;
                    oss << state_->getItemName(inum) << " x" << amount;
                    items.push_back(oss.str());
                    itemSlotMap.push_back(i);
                }
                if (items.empty()) {
                    items.push_back("（無物品）");
                }
                break;
            case MainMenuState::Page::ItemTarget:
                items = buildTeamLines(true, true);
                break;
            case MainMenuState::Page::Teleport:
                sceneMap.clear();
                for (int i = 0; i < state_->sceneAmount(); ++i) {
                    if (state_->getSceneData(i, 6) < 0 || state_->getSceneData(i, 7) < 0) {
                        continue;
                    }
                    std::ostringstream oss;
                    oss << (i + 1) << ". " << state_->getSceneName(i);
                    items.push_back(oss.str());
                    sceneMap.push_back(i);
                }
                if (items.empty()) {
                    items.push_back("（無可傳送場景）");
                }
                break;
            case MainMenuState::Page::ItemBrowse:
                // Item browse uses custom grid rendering, not text items
                // Return empty list - handling is done in render section
                break;
            case MainMenuState::Page::Title:
                items.push_back("新遊戲");
                for (int i = 1; i <= 10; ++i) {
                    const bool ex = std::filesystem::exists(getSavePath(i));
                    items.push_back("載入進度" + std::to_string(i) + (ex ? " [可讀]" : " [空]"));
                }
                items.push_back("載入自動檔");
                break;
            default:
                break;
        }
        return items;
    };

    auto applyMenuAction = [&](int index, bool isFullscreen) {
        switch (menu.page) {
            case MainMenuState::Page::Root:
                switch (index) {
                    case 0: menu.enter(MainMenuState::Page::Medical); break;
                    case 1: menu.enter(MainMenuState::Page::Detox); break;
                    case 2: menu.enter(MainMenuState::Page::ItemType); break;
                    case 3: menu.enter(MainMenuState::Page::Status); break;
                    case 4: menu.enter(MainMenuState::Page::LeaveTeam); break;
                    case 5:
                        if (state_->where() == 0) {
                            menu.enter(MainMenuState::Page::Teleport);
                        } else {
                            menu.setStatus("子場景不可傳送");
                        }
                        break;
                    case 6: menu.enter(MainMenuState::Page::System); break;
                    default: break;
                }
                break;
            case MainMenuState::Page::System:
                switch (index) {
                    case 0: menu.enter(MainMenuState::Page::LoadSlots); break;
                    case 1: menu.enter(MainMenuState::Page::SaveSlots); break;
                    case 2:
                        SDL_SetWindowFullscreen(window, !isFullscreen);
                        menu.setStatus(!isFullscreen ? "切換到全屏" : "切換到窗口");
                        break;
                    case 3: menu.enter(MainMenuState::Page::QuitConfirm); break;
                    default: break;
                }
                break;
            case MainMenuState::Page::LoadSlots:
                if (index >= 0 && index <= 10) {
                    const int slot = index + 1;
                    if (state_->loadR(slot) && state_->loadWorldData()) {
                        menu.setStatus("讀取進度" + std::to_string(slot) + "成功");
                        menu.open = false;
                    } else {
                        menu.setStatus("讀取進度" + std::to_string(slot) + "失敗");
                    }
                }
                break;
            case MainMenuState::Page::SaveSlots:
                if (index >= 0 && index <= 9) {
                    const int slot = index + 1;
                    if (state_->saveR(slot)) {
                        menu.setStatus("存檔進度" + std::to_string(slot) + "成功");
                    } else {
                        menu.setStatus("存檔進度" + std::to_string(slot) + "失敗");
                    }
                }
                break;
            case MainMenuState::Page::QuitConfirm:
                if (index == 0) {
                    menu.back();
                } else if (index == 1) {
                    running = false;
                } else if (index == 2) {
                    menu.setStatus("腳本功能未遷移");
                }
                break;
            case MainMenuState::Page::Medical:
                if (index >= 0 && index < static_cast<int>(teamSlotMap.size())) {
                    const int teamSlot = teamSlotMap[static_cast<std::size_t>(index)];
                    const int role = state_->getTeam(teamSlot);
                    state_->healRoleFull(role);
                    menu.setStatus("已為" + state_->getRoleName(role) + "治療");
                }
                break;
            case MainMenuState::Page::Detox:
                if (index >= 0 && index < static_cast<int>(teamSlotMap.size())) {
                    const int teamSlot = teamSlotMap[static_cast<std::size_t>(index)];
                    const int role = state_->getTeam(teamSlot);
                    state_->detoxRole(role);
                    menu.setStatus("已為" + state_->getRoleName(role) + "解毒");
                }
                break;
            case MainMenuState::Page::ItemType:
                if (index >= 0 && index <= 4) {
                    menu.selectedItemType = index;
                    menu.itemBrowseRow = 0;
                    menu.itemBrowseList.clear();
                    
                    // Build the item browse list
                    for (int i = 0; i < state_->itemListCount(); ++i) {
                        const int inum = state_->itemListNumber(i);
                        const int amount = state_->itemListAmount(i);
                        if (inum >= 0 && amount > 0) {
                            const int t = state_->itemType(inum);
                            if (t == index) {
                                menu.itemBrowseList.push_back(inum);
                            }
                        }
                    }
                    
                    if (menu.itemBrowseList.empty()) {
                        menu.setStatus("此分類無物品");
                    } else {
                        menu.itemBrowseCols = 10;  // 10 columns per row like original
                        menu.itemBrowseRows = (menu.itemBrowseList.size() + menu.itemBrowseCols - 1) / menu.itemBrowseCols;
                        menu.enter(MainMenuState::Page::ItemBrowse);
                    }
                } else if (index == 5) {
                    state_->rearrangeItems();
                    menu.setStatus("物品已整理");
                }
                break;
            case MainMenuState::Page::ItemList:
                if (index >= 0 && index < static_cast<int>(itemSlotMap.size())) {
                    const int itemSlot = itemSlotMap[static_cast<std::size_t>(index)];
                    const int inum = state_->itemListNumber(itemSlot);
                    const int t = state_->itemType(inum);
                    menu.selectedItemNumber = inum;
                    if (t == 1 || t == 2 || t == 3) {
                        menu.enter(MainMenuState::Page::ItemTarget);
                    } else if (t == 0) {
                        menu.setStatus(state_->useStoryItem(inum));
                    } else if (t == 4) {
                        menu.setStatus("暗器僅戰鬥可用");
                    } else {
                        menu.setStatus("此物品目前不可用");
                    }
                }
                break;
            case MainMenuState::Page::ItemTarget:
                if (index >= 0 && index < static_cast<int>(teamSlotMap.size()) && menu.selectedItemNumber >= 0) {
                    const int teamSlot = teamSlotMap[static_cast<std::size_t>(index)];
                    const int role = state_->getTeam(teamSlot);
                    const std::string result = state_->useItemOnRole(menu.selectedItemNumber, role);
                    menu.setStatus(result + "：" + state_->getRoleName(role));
                    menu.back();
                }
                break;
            case MainMenuState::Page::Status:
                if (index >= 0 && index < static_cast<int>(teamSlotMap.size())) {
                    const int teamSlot = teamSlotMap[static_cast<std::size_t>(index)];
                    const int role = state_->getTeam(teamSlot);
                    menu.selectedRole = role;
                    menu.enter(MainMenuState::Page::StatusDetail);
                }
                break;
            case MainMenuState::Page::StatusDetail:
                if (index >= 0) {
                    menu.back();
                }
                break;
            case MainMenuState::Page::LeaveTeam:
                if (index >= 0 && index < static_cast<int>(teamSlotMap.size())) {
                    const int teamSlot = teamSlotMap[static_cast<std::size_t>(index)];
                    const int role = state_->getTeam(teamSlot);
                    const std::string name = state_->getRoleName(role);
                    state_->removeTeamMember(teamSlot);
                    menu.setStatus(name + " 已離隊");
                }
                break;
            case MainMenuState::Page::Teleport:
                if (index >= 0 && index < static_cast<int>(sceneMap.size())) {
                    const int sceneId = sceneMap[static_cast<std::size_t>(index)];
                    if (state_->teleportToScene(sceneId)) {
                        menu.setStatus("已傳送到 " + state_->getSceneName(sceneId));
                        menu.open = false;
                    } else {
                        menu.setStatus("傳送失敗");
                    }
                }
                break;
            case MainMenuState::Page::ItemBrowse:
                // Item browse grid handling done in input loop
                // No action needed here
                break;
            case MainMenuState::Page::Title:
                if (index == 0) {
                    // New game
                    state_->newGame();
                    if (state_->loadWorldData()) {
                        menu.open = false;
                    } else {
                        menu.setStatus("新遊戲初始化失敗");
                    }
                } else if (index >= 1 && index <= 11) {
                    // Load game (slots 1-10 or auto slot 11)
                    const int slot = (index == 11) ? 11 : index;
                    if (state_->loadR(slot) && state_->loadWorldData()) {
                        menu.setStatus("讀取進度" + std::to_string(slot) + "成功");
                        menu.open = false;
                    } else {
                        menu.setStatus("讀取進度" + std::to_string(slot) + "失敗");
                    }
                }
                break;
            default:
                break;
        }
    };

    SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);

    while (running) {
        SDL_Event e;
        while (SDL_PollEvent(&e)) {
            switch (e.type) {
                case SDL_EVENT_QUIT:
                    running = false;
                    break;
                case SDL_EVENT_KEY_DOWN:
                case SDL_EVENT_KEY_UP:
                    state_->setInputState(static_cast<int>(e.key.key), state_->currentButton(), state_->mouseX(), state_->mouseY());
                    if (e.type == SDL_EVENT_KEY_DOWN) {
                        const bool isFullscreen = (SDL_GetWindowFlags(window) & SDL_WINDOW_FULLSCREEN) != 0;
                        auto menuItems = buildMenuItems(isFullscreen);
                        if (menu.open) {
                            // Special handling for ItemBrowse grid navigation
                            if (menu.page == MainMenuState::Page::ItemBrowse) {
                                // itemBrowseRow is already a linear index (0 to totalItems-1)
                                int gridIndex = menu.itemBrowseRow;
                                int col = gridIndex % menu.itemBrowseCols;
                                int row = gridIndex / menu.itemBrowseCols;
                                
                                if (e.key.key == SDLK_UP && row > 0) {
                                    row -= 1;
                                    gridIndex = row * menu.itemBrowseCols + col;
                                    menu.itemBrowseRow = gridIndex;
                                } else if (e.key.key == SDLK_DOWN && row < menu.itemBrowseRows - 1) {
                                    row += 1;
                                    gridIndex = row * menu.itemBrowseCols + col;
                                    if (gridIndex < static_cast<int>(menu.itemBrowseList.size())) {
                                        menu.itemBrowseRow = gridIndex;
                                    }
                                } else if (e.key.key == SDLK_LEFT && col > 0) {
                                    col -= 1;
                                    gridIndex = row * menu.itemBrowseCols + col;
                                    menu.itemBrowseRow = gridIndex;
                                } else if (e.key.key == SDLK_RIGHT && col < menu.itemBrowseCols - 1) {
                                    col += 1;
                                    gridIndex = row * menu.itemBrowseCols + col;
                                    if (gridIndex < static_cast<int>(menu.itemBrowseList.size())) {
                                        menu.itemBrowseRow = gridIndex;
                                    }
                                } else if (e.key.key == SDLK_ESCAPE) {
                                    menu.back();
                                } else if (e.key.key == SDLK_RETURN || e.key.key == SDLK_SPACE) {
                                    // Select item and use it
                                    if (gridIndex >= 0 && gridIndex < static_cast<int>(menu.itemBrowseList.size())) {
                                        menu.selectedItemNumber = menu.itemBrowseList[gridIndex];
                                        const int t = state_->itemType(menu.selectedItemNumber);
                                        if (t == 1 || t == 2 || t == 3) {
                                            menu.enter(MainMenuState::Page::ItemTarget);
                                        } else if (t == 0) {
                                            menu.setStatus(state_->useStoryItem(menu.selectedItemNumber));
                                        }
                                    }
                                }
                                break;
                            }
                            
                            const int maxIndex = static_cast<int>(menuItems.size()) - 1;
                            if (e.key.key == SDLK_UP) {
                                menu.selected -= 1;
                                if (menu.selected < 0) {
                                    menu.selected = maxIndex;
                                }
                            } else if (e.key.key == SDLK_DOWN) {
                                menu.selected += 1;
                                if (menu.selected > maxIndex) {
                                    menu.selected = 0;
                                }
                            } else if (e.key.key == SDLK_ESCAPE) {
                                menu.back();
                            } else if (e.key.key == SDLK_RETURN || e.key.key == SDLK_SPACE) {
                                applyMenuAction(menu.selected, isFullscreen);
                            }
                            break;
                        }

                        if (state_->where() == 0) {
                            int x = state_->mapX();
                            int y = state_->mapY();
                            const bool keyUp = (e.key.key == SDLK_UP || e.key.key == SDLK_W);
                            const bool keyRight = (e.key.key == SDLK_RIGHT || e.key.key == SDLK_D);
                            const bool keyLeft = (e.key.key == SDLK_LEFT || e.key.key == SDLK_A);
                            const bool keyDown = (e.key.key == SDLK_DOWN || e.key.key == SDLK_S);
                            if (e.key.key == SDLK_ESCAPE) {
                                menu.resetToRoot();
                                break;
                            }
                            // Main map coordinate system: Mx/My (0-479 range)
                            // Mface: 0=up(Mx-1), 1=right(My+1), 2=left(My-1), 3=down(Mx+1)
                            if (keyUp) {
                                x -= 1;  // Mx -= 1
                                mFace = 0;
                                state_->setMapFace(mFace);
                            }
                            if (keyRight) {
                                y += 1;  // My += 1
                                mFace = 1;
                                state_->setMapFace(mFace);
                            }
                            if (keyLeft) {
                                y -= 1;  // My -= 1
                                mFace = 2;
                                state_->setMapFace(mFace);
                            }
                            if (keyDown) {
                                x += 1;  // Mx += 1
                                mFace = 3;
                                state_->setMapFace(mFace);
                            }
                            
                            // Clamp to world bounds (0-479)
                            if (x < 0) x = 0;
                            if (x > 479) x = 479;
                            if (y < 0) y = 0;
                            if (y > 479) y = 479;
                            
                            state_->setMapPosition(x, y);
                            if (keyUp || keyDown || keyLeft || keyRight) {
                                mStep += 1;
                                if (mStep > 6) {
                                    mStep = 1;
                                }
                            }
                            if (e.key.key == SDLK_RETURN || e.key.key == SDLK_SPACE) {
                                (void)state_->tryEnterScene();
                            }
                        } else {
                            const int curX = state_->sceneX();
                            const int curY = state_->sceneY();
                            int x = curX;
                            int y = curY;
                            bool moved = false;
                            const bool keyUp = (e.key.key == SDLK_UP || e.key.key == SDLK_W);
                            const bool keyRight = (e.key.key == SDLK_RIGHT || e.key.key == SDLK_D);
                            const bool keyLeft = (e.key.key == SDLK_LEFT || e.key.key == SDLK_A);
                            const bool keyDown = (e.key.key == SDLK_DOWN || e.key.key == SDLK_S);
                            // Scene coordinate system: Sx/Sy (0-63 range)
                            // SFace: 0=up(Sx-1), 1=right(Sy+1), 2=left(Sy-1), 3=down(Sx+1)
                            if (keyUp) {
                                x -= 1;  // Sx -= 1
                                state_->setSceneFace(0);
                                if (state_->canWalkInScene(x, y)) {
                                    moved = true;
                                } else {
                                    x = curX;
                                    y = curY;
                                }
                            }
                            if (keyRight) {
                                y += 1;  // Sy += 1
                                state_->setSceneFace(1);
                                if (state_->canWalkInScene(x, y)) {
                                    moved = true;
                                } else {
                                    x = curX;
                                    y = curY;
                                }
                            }
                            if (keyLeft) {
                                y -= 1;  // Sy -= 1
                                state_->setSceneFace(2);
                                if (state_->canWalkInScene(x, y)) {
                                    moved = true;
                                } else {
                                    x = curX;
                                    y = curY;
                                }
                            }
                            if (keyDown) {
                                x += 1;  // Sx += 1
                                state_->setSceneFace(3);
                                if (state_->canWalkInScene(x, y)) {
                                    moved = true;
                                } else {
                                    x = curX;
                                    y = curY;
                                }
                            }
                            
                            // Clamp coordinates to scene bounds (0-63)
                            if (x < 0) x = 0;
                            if (x > 63) x = 63;
                            if (y < 0) y = 0;
                            if (y > 63) y = 63;
                            
                            if (moved) {
                                state_->setScenePosition(x, y);
                                if (state_->tryLeaveSceneAtCurrentPosition()) {
                                    // Left scene via exit tile, stop scene-only processing for this key.
                                    break;
                                }
                            }

                            if (e.key.key == SDLK_ESCAPE) {
                                menu.resetToRoot();
                            }
                            if (e.key.key == SDLK_RETURN || e.key.key == SDLK_SPACE) {
                                lastSceneEvent = state_->tryTriggerFacingSceneEvent();
                            }
                            // After movement, auto-trigger event if standing on one (optional)
                            if (moved) {
                                (void)state_->tryTriggerCurrentSceneEvent();
                            }
                        }
                    }
                    break;
                case SDL_EVENT_MOUSE_BUTTON_DOWN:
                case SDL_EVENT_MOUSE_BUTTON_UP:
                    state_->setInputState(state_->currentKey(), static_cast<int>(e.button.button), state_->mouseX(), state_->mouseY());
                    break;
                case SDL_EVENT_MOUSE_MOTION:
                    state_->setInputState(state_->currentKey(), state_->currentButton(), static_cast<int>(e.motion.x), static_cast<int>(e.motion.y));
                    break;
                default:
                    break;
            }
        }

        if (useFixedRender) {
            SDL_SetRenderTarget(renderer, frameTexture);
        }

        SDL_SetRenderDrawColor(renderer, 18, 24, 32, 255);
        SDL_RenderClear(renderer);

        int ww = kRenderWidth;
        int wh = kRenderHeight;
        if (!useFixedRender) {
            SDL_GetWindowSize(window, &ww, &wh);
        }

        const int centerX = ww / 2;
        const int centerY = wh / 2;

        if (state_->where() == 0) {
            const int widthRegion = centerX / 36 + 3;
            const int sumRegion = centerY / 9 + 2;
            const int mapCX = state_->mapX();
            const int mapCY = state_->mapY();

            std::vector<BuildDraw> builds;
            builds.reserve(2500);

            for (int sum = -sumRegion; sum <= sumRegion + 15; ++sum) {
                for (int i = -widthRegion; i <= widthRegion; ++i) {
                    const int i1 = mapCX + i + (sum / 2);
                    const int i2 = mapCY - i + (sum - sum / 2);
                    const auto pos = getPositionOnScreen(i1, i2, mapCX, mapCY, centerX, centerY);

                    if (i1 < 0 || i1 >= KysState::kWorldSize || i2 < 0 || i2 >= KysState::kWorldSize) {
                        if (!mainGrpCache.renderTile(0, pos.first, pos.second)) {
                            SDL_FRect r{static_cast<float>(pos.first), static_cast<float>(pos.second), 36.0f, 18.0f};
                            mapColor(renderer, 0, 0);
                            SDL_RenderFillRect(renderer, &r);
                        }
                        continue;
                    }

                    const int earth = state_->earthAt(i1, i2) / 2;
                    if (!mainGrpCache.renderTile(earth, pos.first, pos.second)) {
                        SDL_Texture* t = texCache.loadMMapTexture(earth);
                        if (t) {
                            SDL_FRect r{static_cast<float>(pos.first), static_cast<float>(pos.second), 36.0f, 18.0f};
                            SDL_RenderTexture(renderer, t, nullptr, &r);
                        }
                    }

                    const int surface = state_->surfaceAt(i1, i2) / 2;
                    if (surface > 0) {
                        if (!mainGrpCache.renderTile(surface, pos.first, pos.second)) {
                            SDL_Texture* t = texCache.loadMMapTexture(surface);
                            if (t) {
                                SDL_FRect r{static_cast<float>(pos.first), static_cast<float>(pos.second), 36.0f, 18.0f};
                                SDL_RenderTexture(renderer, t, nullptr, &r);
                            }
                        }
                    }

                    int building = state_->buildingAt(i1, i2) / 2;
                    if (i1 == mapCX && i2 == mapCY) {
                        building = 2501 + mFace * 7 + mStep;
                    }
                    if (building > 0) {
                        const TileHeader h = mainGrpCache.headerFor(building);
                        const int width = h.valid ? h.width : 36;
                        const int height = h.valid ? h.height : 18;
                        const int yoffset = h.valid ? h.ys : 0;
                        int c = ((i1 + i2) - (width + 35) / 36 - (yoffset - height + 1) / 9) * 1024 + i2;
                        if (i1 == mapCX && i2 == mapCY) {
                            c = (i1 + i2) * 1024 + i2;
                        }
                        builds.push_back(BuildDraw{i1, i2, building, c});
                    }
                }
            }

            std::sort(builds.begin(), builds.end(), [](const BuildDraw& a, const BuildDraw& b) {
                return a.sortKey < b.sortKey;
            });

            for (const auto& b : builds) {
                const auto pos = getPositionOnScreen(b.mapX, b.mapY, mapCX, mapCY, centerX, centerY);
                if (!mainGrpCache.renderTile(b.tile, pos.first, pos.second)) {
                    SDL_Texture* t = texCache.loadMMapTexture(b.tile);
                    if (t) {
                        SDL_FRect r{static_cast<float>(pos.first), static_cast<float>(pos.second), 36.0f, 18.0f};
                        SDL_RenderTexture(renderer, t, nullptr, &r);
                    }
                }
            }
        } else {
            const int sceneId = state_->currentScene();
            const int sx = state_->sceneX();
            const int sy = state_->sceneY();
            const int widthRegion = centerX / 36 + 2;
            const int sumRegion = centerY / 9 + 1;

            for (int sum = -sumRegion; sum <= sumRegion + 10; ++sum) {
                for (int i = -widthRegion; i <= widthRegion; ++i) {
                    const int x = sx + i + (sum / 2);
                    const int y = sy - i + (sum - sum / 2);
                    const auto pos = getPositionOnScreen(x, y, sx, sy, centerX, centerY);
                    if (x < 0 || x > 63 || y < 0 || y > 63 || sceneId < 0) {
                        continue;
                    }
                    for (int layer = 0; layer < 6; ++layer) {
                        const int rawTile = state_->getSData(sceneId, layer, x, y);
                        const int tile = rawTile / 2;
                        if (tile <= 0) {
                            continue;
                        }
                        if (!sceneGrpCache.renderTile(tile, pos.first, pos.second)) {
                            SDL_FRect r{static_cast<float>(pos.first), static_cast<float>(pos.second), 36.0f, 18.0f};
                            mapColor(renderer, tile, layer);
                            SDL_RenderFillRect(renderer, &r);
                        }
                    }
                }
            }

            SDL_FRect roleRect{static_cast<float>(centerX - 4), static_cast<float>(centerY - 14), 8.0f, 14.0f};
            SDL_SetRenderDrawColor(renderer, 250, 240, 80, 255);
            SDL_RenderFillRect(renderer, &roleRect);
        }

        SDL_FRect hudBg{8.0f, 8.0f, 420.0f, 44.0f};
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 140);
        SDL_RenderFillRect(renderer, &hudBg);
        if (hasFont) {
            std::ostringstream oss;
            if (state_->where() == 0) {
                oss << "主地圖 X=" << state_->mapX() << " Y=" << state_->mapY() << "  [Enter/Space:進場景  Esc:選單]";
            } else {
                oss << "場景 " << state_->currentScene() << " X=" << state_->sceneX() << " Y=" << state_->sceneY()
                    << " 事件=" << lastSceneEvent << "  [Esc:離開  Enter/Space:觸發]";
            }
            overlay.draw(renderer, oss.str(), 16, 20);
        }

        if (menu.statusVisible()) {
            SDL_FRect toastBg{8.0f, 58.0f, 340.0f, 34.0f};
            SDL_SetRenderDrawColor(renderer, 0, 0, 0, 150);
            SDL_RenderFillRect(renderer, &toastBg);
            if (hasFont) {
                overlay.draw(renderer, menu.status, 16, 68);
            }
        }

        if (menu.open) {
            const bool isFullscreen = (SDL_GetWindowFlags(window) & SDL_WINDOW_FULLSCREEN) != 0;
            const auto items = buildMenuItems(isFullscreen);
            
            // Special rendering for ItemBrowse page
            if (menu.page == MainMenuState::Page::ItemBrowse) {
                const int cols = menu.itemBrowseCols;
                const int itemSize = 42;
                const int iconSpacing = 8;  // pixel gap between items
                const int itemsPerRow = cols;
                const int totalItems = menu.itemBrowseList.size();
                
                // Calculate grid dimensions
                const int gridWidth = cols * (itemSize + iconSpacing) + 8;
                const int gridHeight = menu.itemBrowseRows * (itemSize + iconSpacing) + 8;
                
                // Draw grid background
                SDL_FRect gridBg{static_cast<float>(centerX - gridWidth / 2), 
                                 static_cast<float>(centerY - gridHeight / 2), 
                                 static_cast<float>(gridWidth), 
                                 static_cast<float>(gridHeight)};
                SDL_SetRenderDrawColor(renderer, 0, 0, 0, 130);
                SDL_RenderFillRect(renderer, &gridBg);
                
                // Draw grid border
                SDL_FRect gridFrame{gridBg.x - 1.0f, gridBg.y - 1.0f, gridBg.w + 2.0f, gridBg.h + 2.0f};
                SDL_SetRenderDrawColor(renderer, 255, 255, 255, 200);
                SDL_RenderRect(renderer, &gridFrame);
                
                // Draw selected item info at top
                int selectedIdx = menu.itemBrowseRow;
                if (selectedIdx >= 0 && selectedIdx < static_cast<int>(menu.itemBrowseList.size())) {
                    const int itemId = menu.itemBrowseList[selectedIdx];
                    
                    // Draw item name
                    if (hasFont && itemId >= 0) {
                        const std::string itemName = state_->getItemName(itemId);
                        SDL_FRect nameBg{gridBg.x, gridBg.y - 35.0f, gridBg.w, 30.0f};
                        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 130);
                        SDL_RenderFillRect(renderer, &nameBg);
                        overlay.draw(renderer, itemName, static_cast<int>(gridBg.x + 5), static_cast<int>(gridBg.y - 30));
                    }
                }
                
                // Draw grid items
                for (int idx = 0; idx < static_cast<int>(totalItems); ++idx) {
                    int row = idx / cols;
                    int col = idx % cols;
                    
                    const float xPos = gridBg.x + 4.0f + col * (itemSize + iconSpacing);
                    const float yPos = gridBg.y + 4.0f + row * (itemSize + iconSpacing);
                    
                    SDL_FRect itemRect{xPos, yPos, static_cast<float>(itemSize), static_cast<float>(itemSize)};
                    
                    // Draw selection highlight if this is the selected item
                    if (idx == selectedIdx) {
                        SDL_SetRenderDrawColor(renderer, 255, 204, 0, 180);
                        SDL_RenderFillRect(renderer, &itemRect);
                        SDL_FRect selFrame{itemRect.x - 1.0f, itemRect.y - 1.0f, itemRect.w + 2.0f, itemRect.h + 2.0f};
                        SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);
                        SDL_RenderRect(renderer, &selFrame);
                    } else {
                        // Draw border for unselected items
                        SDL_SetRenderDrawColor(renderer, 100, 100, 100, 150);
                        SDL_RenderRect(renderer, &itemRect);
                    }
                    
                    // Draw item icon - load and render PNG image
                    if (idx < static_cast<int>(menu.itemBrowseList.size())) {
                        const int itemId = menu.itemBrowseList[idx];
                        std::string pngPath = "item/" + std::to_string(itemId) + ".png";
                        std::string fullPath = appPath + "/" + pngPath;
                        
                        // Try to load PNG and render it
                        SDL_IOStream* src = SDL_IOFromFile(fullPath.c_str(), "rb");
                        if (src) {
                            SDL_Surface* surface = SDL_LoadPNG_IO(src, true);
                            if (surface) {
                                // Scale if needed to fit in itemSize box
                                SDL_Texture* texture = SDL_CreateTextureFromSurface(renderer, surface);
                                if (texture) {
                                    // Draw centered image in item rect
                                    const int imgWidth = surface->w;
                                    const int imgHeight = surface->h;
                                    float scale = std::min(static_cast<float>(itemSize - 4) / imgWidth,
                                                          static_cast<float>(itemSize - 4) / imgHeight);
                                    
                                    const int scaledW = static_cast<int>(imgWidth * scale);
                                    const int scaledH = static_cast<int>(imgHeight * scale);
                                    const float offsetX = xPos + (itemSize - scaledW) / 2.0f;
                                    const float offsetY = yPos + (itemSize - scaledH) / 2.0f;
                                    
                                    SDL_FRect imgRect{offsetX, offsetY, static_cast<float>(scaledW), static_cast<float>(scaledH)};
                                    SDL_RenderTexture(renderer, texture, nullptr, &imgRect);
                                    SDL_DestroyTexture(texture);
                                }
                                SDL_DestroySurface(surface);
                            }
                        }
                    }
                }
                
                // Draw help text at bottom
                if (hasFont) {
                    overlay.draw(renderer, "[UP/DOWN/LEFT/RIGHT:選擇  ENTER:確認  ESC:返回]", 
                               static_cast<int>(gridBg.x), static_cast<int>(gridBg.y + gridBg.h + 5));
                }
                
                presentFrame();
                continue;  // Skip normal menu rendering for ItemBrowse
            }
            
            const int maxShow = 10;
            const int itemCount = static_cast<int>(items.size());
            int top = 0;
            if (itemCount > maxShow) {
                top = menu.selected - maxShow / 2;
                if (top < 0) top = 0;
                if (top > itemCount - maxShow) top = itemCount - maxShow;
            }
            const int showCount = std::min(maxShow, itemCount);
            
            // Menu dimensions: 29px header + 22px per item + 2px padding = max * 22 + 29
            const float itemHeight = 22.0f;
            const float menuH = 29.0f + static_cast<float>(showCount) * itemHeight;
            SDL_FRect menuBg{static_cast<float>(centerX - 180), static_cast<float>(centerY - menuH / 2.0f), 360.0f, menuH};
            
            // Draw menu background (black with transparency)
            SDL_SetRenderDrawColor(renderer, 0, 0, 0, 127);
            SDL_RenderFillRect(renderer, &menuBg);

            // Draw menu border (white/bright color like ColColor(255))
            SDL_FRect frame{menuBg.x - 1.0f, menuBg.y - 1.0f, menuBg.w + 2.0f, menuBg.h + 2.0f};
            SDL_SetRenderDrawColor(renderer, 255, 255, 255, 200);
            SDL_RenderRect(renderer, &frame);

            // Draw menu items
            for (int row = 0; row < showCount; ++row) {
                const int i = top + row;
                const float y = menuBg.y + 2.0f + static_cast<float>(row) * itemHeight;
                
                if (i == menu.selected) {
                    // Draw selection highlight for selected item
                    SDL_FRect sel{menuBg.x + 3.0f, y, menuBg.w - 6.0f, itemHeight};
                    // Selected color: ColColor($64) - bright gold/yellow - RGB(255, 204, 0)
                    SDL_SetRenderDrawColor(renderer, 255, 204, 0, 180);
                    SDL_RenderFillRect(renderer, &sel);
                }
                
                if (hasFont) {
                    // Draw text at x + 3, which matches original Pascal DrawShadowText positioning
                    if (i == menu.selected) {
                        // Selected item text color: bright gold
                        overlay.draw(renderer, items[static_cast<std::size_t>(i)], 
                                   static_cast<int>(menuBg.x + 3.0f), static_cast<int>(y));
                    } else {
                        // Unselected item text color: dark (using normal text)
                        overlay.draw(renderer, items[static_cast<std::size_t>(i)], 
                                   static_cast<int>(menuBg.x + 3.0f), static_cast<int>(y));
                    }
                }
            }

            if (itemCount > maxShow) {
                const float barX = menuBg.x + menuBg.w - 10.0f;
                const float barY = menuBg.y + 2.0f;
                const float barH = static_cast<float>(showCount) * itemHeight;
                SDL_FRect barBg{barX, barY, 4.0f, barH};
                SDL_SetRenderDrawColor(renderer, 90, 90, 90, 200);
                SDL_RenderFillRect(renderer, &barBg);
                const float thumbH = std::max(10.0f, barH * static_cast<float>(showCount) / static_cast<float>(itemCount));
                const float thumbY = barY + (barH - thumbH) * static_cast<float>(top) / static_cast<float>(itemCount - showCount);
                SDL_FRect thumb{barX, thumbY, 4.0f, thumbH};
                SDL_SetRenderDrawColor(renderer, 210, 190, 120, 220);
                SDL_RenderFillRect(renderer, &thumb);
            }

            if (hasFont) {
                const std::string title = MainMenuState::pageTitle(menu.page) + " [Esc返回 Enter確認]";
                overlay.draw(renderer, title, static_cast<int>(menuBg.x + 3.0f), static_cast<int>(menuBg.y + 5.0f));
            }
        }

        presentFrame();

        const auto now = std::chrono::steady_clock::now();
        const auto elapsed = std::chrono::duration_cast<std::chrono::milliseconds>(now - begin).count();
        if (milliseconds > 0 && elapsed >= milliseconds) {
            running = false;
        }
    }

    overlay.shutdown();

    if (frameTexture) {
        SDL_DestroyTexture(frameTexture);
        frameTexture = nullptr;
    }

    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
#endif
}

} // namespace kys
