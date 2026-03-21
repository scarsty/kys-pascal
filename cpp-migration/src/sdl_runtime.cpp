#include "sdl_runtime.hpp"

#include "kys_draw.hpp"
#include "kys_menu.hpp"
#include "kys_state.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <ctime>
#include <filesystem>
#include <iomanip>
#include <random>
#include <sstream>
#include <string>
#include <thread>
#include <unordered_map>
#include <utility>
#include <vector>

namespace kys {


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
    int sStep = 1;
    MainMenuState menu;
    TextureCache texCache;
    texCache.renderer = renderer;
    texCache.appPath = appPath_;
    MMapGrpCache mainGrpCache(renderer, appPath_, "resource/mmap.idx", "resource/mmap.grp", "resource/mmap.col");
    MMapGrpCache sceneGrpCache(renderer, appPath_, "resource/sdx", "resource/smp", "resource/mmap.col");
    MMapGrpCache cloudGrpCache(renderer, appPath_, "resource/cloud.idx", "resource/cloud.grp", "resource/mmap.col");
    FontOverlay overlay;
    const bool hasFont = overlay.init(appPath_);
    const std::string appPath = appPath_;

    auto splitUtf8Sentences = [](const std::string& text) {
        std::vector<std::string> out;
        std::string cur;
        for (std::size_t i = 0; i < text.size();) {
            const unsigned char c = static_cast<unsigned char>(text[i]);
            std::size_t cpLen = 1;
            if ((c & 0x80) == 0x00) cpLen = 1;
            else if ((c & 0xE0) == 0xC0) cpLen = 2;
            else if ((c & 0xF0) == 0xE0) cpLen = 3;
            else if ((c & 0xF8) == 0xF0) cpLen = 4;
            if (i + cpLen > text.size()) cpLen = 1;

            std::string cp = text.substr(i, cpLen);
            i += cpLen;

            if (cp == "\n" || cp == "\r") {
                if (!cur.empty()) {
                    out.push_back(cur);
                    cur.clear();
                }
                continue;
            }

            cur += cp;
            if (cp == "." || cp == "!" || cp == "?" || cp == ";" ||
                cp == u8"。" || cp == u8"！" || cp == u8"？" || cp == u8"；") {
                out.push_back(cur);
                cur.clear();
            }
        }
        if (!cur.empty()) {
            out.push_back(cur);
        }
        if (out.empty()) {
            out.push_back("（空对白）");
        }
        return out;
    };

    auto wrapUtf8Lines = [](const std::string& text, int maxCharsPerLine) {
        std::vector<std::string> lines;
        std::string cur;
        int cnt = 0;
        for (std::size_t i = 0; i < text.size();) {
            const unsigned char c = static_cast<unsigned char>(text[i]);
            std::size_t cpLen = 1;
            if ((c & 0x80) == 0x00) cpLen = 1;
            else if ((c & 0xE0) == 0xC0) cpLen = 2;
            else if ((c & 0xF0) == 0xE0) cpLen = 3;
            else if ((c & 0xF8) == 0xF0) cpLen = 4;
            if (i + cpLen > text.size()) cpLen = 1;
            cur.append(text, i, cpLen);
            i += cpLen;
            ++cnt;
            if (cnt >= maxCharsPerLine) {
                lines.push_back(cur);
                cur.clear();
                cnt = 0;
            }
        }
        if (!cur.empty()) {
            lines.push_back(cur);
        }
        if (lines.empty()) {
            lines.push_back(" ");
        }
        return lines;
    };

    constexpr float kPascalScale = 1.2f;

    std::unordered_map<int, SDL_Texture*> headTextureCache;
    std::unordered_map<int, bool> missingHeadTexture;

    auto loadHeadTexture = [&](int headNum) -> SDL_Texture* {
        if (headNum < 0) {
            return nullptr;
        }
        if (auto it = headTextureCache.find(headNum); it != headTextureCache.end()) {
            return it->second;
        }
        if (missingHeadTexture.find(headNum) != missingHeadTexture.end()) {
            return nullptr;
        }
        const std::string fileName = std::to_string(headNum) + ".png";
        const std::array<std::string, 2> paths = {
            appPath + "/head/" + fileName,
            "head/" + fileName};
        SDL_Surface* surface = nullptr;
        for (const auto& path : paths) {
            SDL_IOStream* stream = SDL_IOFromFile(path.c_str(), "rb");
            if (!stream) { continue; }
            surface = SDL_LoadPNG_IO(stream, true);
            if (surface) { break; }
        }
        if (!surface) {
            missingHeadTexture[headNum] = true;
            return nullptr;
        }
        SDL_Texture* tex = SDL_CreateTextureFromSurface(renderer, surface);
        SDL_DestroySurface(surface);
        if (!tex) {
            missingHeadTexture[headNum] = true;
            return nullptr;
        }
        headTextureCache[headNum] = tex;
        return tex;
    };

    // Draw dialog/blocking panel. headNum >= 0 draws head portrait; headPlace: 0=left, 1=right.
    auto drawBlockingPanel = [&](const std::string& title, const std::vector<std::string>& lines, int mode, bool drawYesNo, int sel, int headNum = -1, int headPlace = 0) {
        int ww = kRenderWidth;
        int wh = kRenderHeight;
        SDL_GetWindowSize(window, &ww, &wh);
        if (ww <= 0 || wh <= 0) { ww = kRenderWidth; wh = kRenderHeight; }

        SDL_SetRenderTarget(renderer, nullptr);
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
        SDL_RenderClear(renderer);

        // Blit the last rendered scene as background
        if (useFixedRender && frameTexture) {
            const float scx = static_cast<float>(ww) / static_cast<float>(kRenderWidth);
            const float scy = static_cast<float>(wh) / static_cast<float>(kRenderHeight);
            const float sc = std::min(scx, scy);
            const float outW = static_cast<float>(kRenderWidth) * sc;
            const float outH = static_cast<float>(kRenderHeight) * sc;
            SDL_FRect dst{
                (static_cast<float>(ww) - outW) * 0.5f,
                (static_cast<float>(wh) - outH) * 0.5f,
                outW, outH};
            SDL_RenderTexture(renderer, frameTexture, nullptr, &dst);
        }

        // Semi-transparent dark overlay so dialog is readable
        SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
        SDL_FRect fullOvl{0.0f, 0.0f, static_cast<float>(ww), static_cast<float>(wh)};
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 128);
        SDL_RenderFillRect(renderer, &fullOvl);

        const float panelW = static_cast<float>(ww) - 40.0f;
        const float panelH = 180.0f;
        float panelY = static_cast<float>(wh) - panelH - 18.0f;
        if (mode == 1) panelY = 18.0f;
        if (mode == 2) panelY = (static_cast<float>(wh) - panelH) * 0.5f;
        SDL_FRect panel{20.0f, panelY, panelW, panelH};
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 188);
        SDL_RenderFillRect(renderer, &panel);
        SDL_SetRenderDrawColor(renderer, 236, 216, 142, 240);
        SDL_RenderRect(renderer, &panel);

        // Draw head portrait if available
        float textXOff = panel.x + 14.0f;  // default text X offset
        if (headNum >= 0) {
            SDL_Texture* headTex = loadHeadTexture(headNum);
            if (headTex) {
                float texW = 0.0f, texH = 0.0f;
                SDL_GetTextureSize(headTex, &texW, &texH);
                // Fit head portrait inside panel with max 100px wide, preserve aspect ratio
                const float maxHeadW = 100.0f;
                const float maxHeadH = panelH - 16.0f;
                const float hsc = std::min(maxHeadW / texW, maxHeadH / texH);
                const float drawW = texW * hsc;
                const float drawH = texH * hsc;
                float headX = 0.0f;
                if (headPlace == 1) {
                    // Head on right side
                    headX = panel.x + panelW - drawW - 10.0f;
                } else {
                    // Head on left side
                    headX = panel.x + 10.0f;
                    textXOff = panel.x + drawW + 20.0f;
                }
                const float headY = panel.y + (panelH - drawH) * 0.5f;
                SDL_FRect headRect{headX, headY, drawW, drawH};
                SDL_RenderTexture(renderer, headTex, nullptr, &headRect);
            }
        }

        if (hasFont) {
            if (!title.empty()) {
                overlay.draw(renderer, title, static_cast<int>(textXOff), static_cast<int>(panel.y + 10.0f));
            }
            for (int i = 0; i < static_cast<int>(lines.size()) && i < 5; ++i) {
                overlay.draw(renderer, lines[static_cast<std::size_t>(i)], static_cast<int>(textXOff), static_cast<int>(panel.y + 42.0f + i * 24.0f));
            }
            if (drawYesNo) {
                const int y = static_cast<int>(panel.y + panel.h - 34.0f);
                overlay.draw(renderer, sel == 0 ? "> 否" : "  否", static_cast<int>(panel.x + panel.w - 210.0f), y);
                overlay.draw(renderer, sel == 1 ? "> 是" : "  是", static_cast<int>(panel.x + panel.w - 120.0f), y);
            } else {
                overlay.draw(renderer, "[空格/回车继续]", static_cast<int>(panel.x + panel.w - 170.0f), static_cast<int>(panel.y + panel.h - 24.0f));
            }
        }
        SDL_RenderPresent(renderer);
    };

    state_->setTalkCallback([&](const std::string& text, int headNum, int dismode) {
        // Skip completely empty dialog (Pascal filters empty lines)
        if (text.empty()) { return; }
        // Determine head portrait placement from dismode (matching Pascal talk_1)
        // dismode 0: top panel, head left; 1: bottom panel, head right;
        // 2: top panel, no head; 3: bottom panel, no head;
        // 4: top panel, head right; 5: bottom panel, head left
        int panelMode = 0;     // 0=bottom, 1=top
        int headPlace = 0;     // 0=left, 1=right
        int effectiveHead = headNum;
        switch (dismode) {
            case 0: panelMode = 1; headPlace = 0; break;
            case 1: panelMode = 0; headPlace = 1; break;
            case 2: panelMode = 1; effectiveHead = -1; break;
            case 3: panelMode = 0; effectiveHead = -1; break;
            case 4: panelMode = 1; headPlace = 1; break;
            case 5: panelMode = 0; headPlace = 0; break;
            default: panelMode = 0; headPlace = 0; break;
        }
        // Find role name for title if head is shown
        std::string title;
        if (effectiveHead >= 0) {
            title = state_->roleNameByHead(effectiveHead);
        }
        const auto sentences = splitUtf8Sentences(text);
        for (const auto& s : sentences) {
            // Skip empty sentences (Pascal: only keep non-empty lines)
            bool allBlank = true;
            for (const auto& ch : s) {
                if (ch != ' ' && ch != '\t' && ch != '\r' && ch != '\n') {
                    allBlank = false;
                    break;
                }
            }
            if (allBlank) { continue; }
            const auto lines = wrapUtf8Lines(s, 30);
            bool waitNext = true;
            while (waitNext && running) {
                SDL_Event ev;
                while (SDL_PollEvent(&ev)) {
                    if (ev.type == SDL_EVENT_QUIT) {
                        running = false;
                        waitNext = false;
                        break;
                    }
                    if (ev.type == SDL_EVENT_KEY_DOWN) {
                        const SDL_Keycode k = ev.key.key;
                        if (k == SDLK_RETURN || k == SDLK_SPACE || k == SDLK_ESCAPE || k == SDLK_Z || k == SDLK_X) {
                            waitNext = false;
                            break;
                        }
                    }
                }
                drawBlockingPanel(title, lines, panelMode, false, 0, effectiveHead, headPlace);
                SDL_Delay(16);
            }
            if (!running) {
                break;
            }
        }
    });

    state_->setGetItemCallback([&](const std::string& itemName, int amount) {
        std::string label = amount >= 0 ? "得到物品" : "失去物品";
        std::string line1 = itemName;
        std::string line2 = "数量: " + std::to_string(amount >= 0 ? amount : -amount);
        std::vector<std::string> lines = { line1, line2 };
        bool waitNext = true;
        while (waitNext && running) {
            SDL_Event ev;
            while (SDL_PollEvent(&ev)) {
                if (ev.type == SDL_EVENT_QUIT) {
                    running = false;
                    waitNext = false;
                    break;
                }
                if (ev.type == SDL_EVENT_KEY_DOWN) {
                    const SDL_Keycode k = ev.key.key;
                    if (k == SDLK_RETURN || k == SDLK_SPACE || k == SDLK_ESCAPE || k == SDLK_Z || k == SDLK_X) {
                        waitNext = false;
                        break;
                    }
                }
            }
            drawBlockingPanel(label, lines, 2, false, 0);
            SDL_Delay(16);
        }
        return true;
    });

    state_->setYesNoCallback([&](const std::string& title, const std::string& text, bool defaultYes) {
        int sel = defaultYes ? 1 : 0;
        bool waiting = true;
        while (waiting && running) {
            SDL_Event ev;
            while (SDL_PollEvent(&ev)) {
                if (ev.type == SDL_EVENT_QUIT) {
                    running = false;
                    waiting = false;
                    break;
                }
                if (ev.type == SDL_EVENT_KEY_DOWN) {
                    const SDL_Keycode k = ev.key.key;
                    if (k == SDLK_LEFT || k == SDLK_A || k == SDLK_UP || k == SDLK_W) {
                        sel = 0;
                    } else if (k == SDLK_RIGHT || k == SDLK_D || k == SDLK_DOWN || k == SDLK_S) {
                        sel = 1;
                    } else if (k == SDLK_RETURN || k == SDLK_SPACE || k == SDLK_Z) {
                        waiting = false;
                        break;
                    } else if (k == SDLK_ESCAPE || k == SDLK_X) {
                        sel = defaultYes ? 1 : 0;
                        waiting = false;
                        break;
                    }
                }
            }
            auto lines = wrapUtf8Lines(text.empty() ? "请选择" : text, 30);
            drawBlockingPanel(title.empty() ? "事件选择" : title, lines, 2, true, sel);
            SDL_Delay(16);
        }
        return sel == 1;
    });

    // Extended instruction callbacks
    state_->setWaitKeyCallback([&]() -> int {
        while (running) {
            SDL_Event ev;
            while (SDL_PollEvent(&ev)) {
                if (ev.type == SDL_EVENT_QUIT) { running = false; return 0; }
                if (ev.type == SDL_EVENT_KEY_DOWN) {
                    int key = static_cast<int>(ev.key.key);
                    // Map arrow keys to Pascal SDL1 codes
                    if (ev.key.key == SDLK_LEFT) return 154;
                    if (ev.key.key == SDLK_RIGHT) return 156;
                    if (ev.key.key == SDLK_UP) return 158;
                    if (ev.key.key == SDLK_DOWN) return 152;
                    return key;
                }
            }
            SDL_Delay(16);
        }
        return 0;
    });

    state_->setDelayCallback([&](int ms) {
        if (ms > 0 && ms < 30000) { SDL_Delay(static_cast<Uint32>(ms)); }
    });

    state_->setMenuSelectCallback([&](int mx, int my, const std::vector<std::string>& items) -> int {
        if (items.empty()) return 0;
        int sel = 0;
        bool waiting = true;
        while (waiting && running) {
            SDL_Event ev;
            while (SDL_PollEvent(&ev)) {
                if (ev.type == SDL_EVENT_QUIT) { running = false; waiting = false; break; }
                if (ev.type == SDL_EVENT_KEY_DOWN) {
                    if (ev.key.key == SDLK_UP || ev.key.key == SDLK_W) {
                        sel = (sel - 1 + static_cast<int>(items.size())) % static_cast<int>(items.size());
                    } else if (ev.key.key == SDLK_DOWN || ev.key.key == SDLK_S) {
                        sel = (sel + 1) % static_cast<int>(items.size());
                    } else if (ev.key.key == SDLK_RETURN || ev.key.key == SDLK_SPACE || ev.key.key == SDLK_Z) {
                        waiting = false; break;
                    } else if (ev.key.key == SDLK_ESCAPE || ev.key.key == SDLK_X) {
                        sel = 0; waiting = false; break;
                    }
                }
            }
            // Render menu: blit frame as background, then overlay menu
            {
                int ww = kRenderWidth, wh = kRenderHeight;
                SDL_GetWindowSize(window, &ww, &wh);
                if (ww <= 0 || wh <= 0) { ww = kRenderWidth; wh = kRenderHeight; }
                SDL_SetRenderTarget(renderer, nullptr);
                SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
                SDL_RenderClear(renderer);
                if (useFixedRender && frameTexture) {
                    const float scx = static_cast<float>(ww) / static_cast<float>(kRenderWidth);
                    const float scy = static_cast<float>(wh) / static_cast<float>(kRenderHeight);
                    const float sc = std::min(scx, scy);
                    const float outW = static_cast<float>(kRenderWidth) * sc;
                    const float outH = static_cast<float>(kRenderHeight) * sc;
                    SDL_FRect dst{(static_cast<float>(ww) - outW) * 0.5f, (static_cast<float>(wh) - outH) * 0.5f, outW, outH};
                    SDL_RenderTexture(renderer, frameTexture, nullptr, &dst);
                }
                SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
                const float sx = static_cast<float>(mx) * kPascalScale;
                const float sy = static_cast<float>(my) * kPascalScale;
                const float mw = 180.0f;
                const float mh = static_cast<float>(items.size()) * 26.0f + 12.0f;
                SDL_FRect bg{sx, sy, mw, mh};
                SDL_SetRenderDrawColor(renderer, 0, 0, 0, 180);
                SDL_RenderFillRect(renderer, &bg);
                SDL_SetRenderDrawColor(renderer, 236, 216, 142, 240);
                SDL_RenderRect(renderer, &bg);
                if (hasFont) {
                    for (int i = 0; i < static_cast<int>(items.size()); ++i) {
                        const int ty = static_cast<int>(sy + 6.0f + i * 26.0f);
                        if (i == sel) {
                            overlay.draw(renderer, items[static_cast<std::size_t>(i)],
                                static_cast<int>(sx + 10.0f), ty, 255, 200, 80);
                        } else {
                            overlay.draw(renderer, items[static_cast<std::size_t>(i)],
                                static_cast<int>(sx + 10.0f), ty, 160, 160, 160);
                        }
                    }
                }
                SDL_RenderPresent(renderer);
            }
            SDL_Delay(16);
        }
        return sel;
    });

    state_->setDrawStringCallback([&](const std::string& text, int x, int y, int color) {
        if (!hasFont) return;
        SDL_SetRenderTarget(renderer, frameTexture);
        // Use a simple white color for now; color could be mapped to Pascal palette
        overlay.draw(renderer, text, static_cast<int>(x * kPascalScale), static_cast<int>(y * kPascalScale));
        SDL_SetRenderTarget(renderer, nullptr);
    });

    state_->setDrawRectCallback([&](int x, int y, int w, int h) {
        SDL_SetRenderTarget(renderer, frameTexture);
        SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);
        SDL_FRect rect{x * kPascalScale, y * kPascalScale, w * kPascalScale, h * kPascalScale};
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 180);
        SDL_RenderFillRect(renderer, &rect);
        SDL_SetRenderDrawColor(renderer, 236, 216, 142, 200);
        SDL_RenderRect(renderer, &rect);
        SDL_SetRenderTarget(renderer, nullptr);
    });

    state_->setDrawPicCallback([&](int type, int picNum, int x, int y) {
        // type 1 = head portrait
        if (type == 1) {
            SDL_Texture* headTex = loadHeadTexture(picNum);
            if (headTex) {
                SDL_SetRenderTarget(renderer, frameTexture);
                float texW = 0.0f, texH = 0.0f;
                SDL_GetTextureSize(headTex, &texW, &texH);
                SDL_FRect dst{x * kPascalScale, y * kPascalScale, texW, texH};
                SDL_RenderTexture(renderer, headTex, nullptr, &dst);
                SDL_SetRenderTarget(renderer, nullptr);
            }
        }
        // type 0 = map pic, type 2 = external pic — not yet implemented
    });
    
    // Color definitions matching Pascal ColColor scheme:
    // Value colors (data/numbers) - bright yellow/orange
    constexpr uint8_t colValueR = 255, colValueG = 200, colValueB = 80;
    // Label colors (text labels) - dark gray/beige
    constexpr uint8_t colLabelR = 192, colLabelG = 160, colLabelB = 128;
    // Alternate colors (HP type, special indicators) - light blue
    constexpr uint8_t colAltR = 100, colAltG = 200, colAltB = 255;
    
    SDL_Texture* titleOpenTexture = nullptr;
    bool titleOpenTextureTried = false;
    std::string titleOpenDebug;
    SDL_Texture* teleportMapTexture = nullptr;
    bool teleportMapBuilt = false;
    std::mt19937 rng(static_cast<std::mt19937::result_type>(std::chrono::steady_clock::now().time_since_epoch().count()));

    struct CloudSprite {
        int pic = 0;
        float x = 0.0f;
        float y = 0.0f;
        float speedX = 0.0f;
        float speedY = 0.0f;
        std::uint8_t alpha = 80;
    };
    std::vector<CloudSprite> clouds(24);

    auto getSavePath = [&appPath](int slot) -> std::string {
        std::ostringstream oss;
        oss << appPath << "/save/r" << slot << ".grp";
        return oss.str();
    };

    auto getFileModTime = [](const std::string& path) -> std::string {
        try {
            const auto lastWriteTime = std::filesystem::last_write_time(path);
            const auto sctp = std::chrono::time_point_cast<std::chrono::system_clock::duration>(
                lastWriteTime - std::filesystem::file_time_type::clock::now() + std::chrono::system_clock::now());
            const auto time = std::chrono::system_clock::to_time_t(sctp);
            std::tm* tmPtr = std::localtime(&time);
            if (!tmPtr) return "";
            
            std::ostringstream oss;
            oss << std::put_time(tmPtr, "%Y-%m-%d %H:%M");
            return oss.str();
        } catch (...) {
            return "";
        }
    };

    auto resetCloud = [&](CloudSprite& cloud, bool randomX) {
        std::uniform_int_distribution<int> picDist(0, 9);
        std::uniform_real_distribution<float> posXDist(0.0f, 17280.0f);
        std::uniform_real_distribution<float> posYDist(0.0f, 8640.0f);
        std::uniform_real_distribution<float> speedDist(1.0f, 3.5f);
        std::uniform_int_distribution<int> alphaDist(36, 96);
        cloud.pic = picDist(rng);
        cloud.x = randomX ? posXDist(rng) : 0.0f;
        cloud.y = posYDist(rng);
        cloud.speedX = speedDist(rng);
        cloud.speedY = 0.0f;
        cloud.alpha = static_cast<std::uint8_t>(alphaDist(rng));
    };

    for (auto& cloud : clouds) {
        resetCloud(cloud, true);
    }

    auto loadTitleOpenTexture = [&]() -> SDL_Texture* {
        if (titleOpenTexture || titleOpenTextureTried) {
            return titleOpenTexture;
        }
        titleOpenTextureTried = true;

        const std::string absPath = appPath + "/resource/open.png";
        const std::string relPath = "resource/open.png";
        SDL_Surface* surface = nullptr;
        std::string loadedPath;

        auto tryLoadPng = [](const std::string& path) -> SDL_Surface* {
            SDL_IOStream* stream = SDL_IOFromFile(path.c_str(), "rb");
            if (!stream) {
                return nullptr;
            }
            return SDL_LoadPNG_IO(stream, true);
        };

        surface = tryLoadPng(absPath);
        if (surface) {
            loadedPath = absPath;
        }
        if (!surface) {
            surface = tryLoadPng(relPath);
            if (surface) {
                loadedPath = relPath;
            }
        }
        if (!surface) {
            titleOpenDebug = "open圖載入失敗：未找到 resource/open.png";
            return nullptr;
        }

        if (surface->w > 8192 || surface->h > 8192) {
            std::ostringstream oss;
            oss << "open圖尺寸過大: " << surface->w << "x" << surface->h << "，可能超過GPU紋理限制";
            titleOpenDebug = oss.str();
        } else {
            std::ostringstream oss;
            oss << "open圖已載入 " << surface->w << "x" << surface->h << " @ " << loadedPath;
            titleOpenDebug = oss.str();
        }

        titleOpenTexture = SDL_CreateTextureFromSurface(renderer, surface);
        if (!titleOpenTexture) {
            std::ostringstream oss;
            oss << "open圖建紋理失敗(" << surface->w << "x" << surface->h << "): " << SDL_GetError();
            titleOpenDebug = oss.str();
        }
        SDL_DestroySurface(surface);
        return titleOpenTexture;
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

    // Draw a rounded-corner semi-transparent rectangle matching Pascal's DrawRectangle.
    // Parameters are in Pascal coordinate space (800x450) and will be scaled.
    auto drawMenuRect = [&](int px, int py, int pw, int ph) {
        const float x = px * kPascalScale;
        const float y = py * kPascalScale;
        const float w = pw * kPascalScale;
        const float h = ph * kPascalScale;
        // Semi-transparent black fill (alpha ~50% = 127)
        SDL_FRect bg{x, y, w + 1.0f, h + 1.0f};
        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 127);
        SDL_RenderFillRect(renderer, &bg);
        // White frame border with gradient alpha (matching Pascal's DrawRectangle)
        // Top and bottom edges
        for (float fi = 0; fi <= w; fi += 1.0f) {
            const float a = 250.0f - std::abs(fi / w + 0.0f - 1.0f) * 150.0f;
            const auto alpha = static_cast<uint8_t>(std::max(80.0f, std::min(250.0f, a)));
            SDL_SetRenderDrawColor(renderer, 255, 255, 255, alpha);
            SDL_RenderPoint(renderer, x + fi, y);
            const float a2 = 250.0f - std::abs(fi / w + 1.0f - 1.0f) * 150.0f;
            const auto alpha2 = static_cast<uint8_t>(std::max(80.0f, std::min(250.0f, a2)));
            SDL_SetRenderDrawColor(renderer, 255, 255, 255, alpha2);
            SDL_RenderPoint(renderer, x + fi, y + h);
        }
        // Left and right edges
        for (float fi = 1; fi < h; fi += 1.0f) {
            const float a = 250.0f - std::abs(0.0f + fi / h - 1.0f) * 150.0f;
            const auto alpha = static_cast<uint8_t>(std::max(80.0f, std::min(250.0f, a)));
            SDL_SetRenderDrawColor(renderer, 255, 255, 255, alpha);
            SDL_RenderPoint(renderer, x, y + fi);
            const float a2 = 250.0f - std::abs(1.0f + fi / h - 1.0f) * 150.0f;
            const auto alpha2 = static_cast<uint8_t>(std::max(80.0f, std::min(250.0f, a2)));
            SDL_SetRenderDrawColor(renderer, 255, 255, 255, alpha2);
            SDL_RenderPoint(renderer, x + w, y + fi);
        }
    };

    // Draw a vertical menu list matching Pascal's ShowCommonMenu.
    // px,py,pw are Pascal coords; items are menu strings; sel is selected index.
    // Selected: ColColor($64/$66) ≈ bright yellow; Unselected: ColColor($5/$7) ≈ dim gray.
    auto drawPascalMenuList = [&](int px, int py, int pw, const std::vector<std::string>& mitems, int sel) {
        const int max = static_cast<int>(mitems.size()) - 1;
        const int ph = max * 22 + 28;
        drawMenuRect(px, py, pw, ph);
        if (!hasFont) return;
        // Selected text: bright gold; Unselected: dim white/gray
        constexpr uint8_t selR = 255, selG = 215, selB = 0;
        constexpr uint8_t nrmR = 176, nrmG = 176, nrmB = 176;
        for (int i = 0; i < static_cast<int>(mitems.size()); ++i) {
            const int tx = static_cast<int>((px + 3) * kPascalScale);
            const int ty = static_cast<int>((py + 2 + 22 * i) * kPascalScale);
            if (i == sel) {
                overlay.draw(renderer, mitems[static_cast<std::size_t>(i)], tx, ty, selR, selG, selB);
            } else {
                overlay.draw(renderer, mitems[static_cast<std::size_t>(i)], tx, ty, nrmR, nrmG, nrmB);
            }
        }
    };

    // Draw a title text with small background rect (Pascal DrawTextWithRect).
    auto drawTitleWithRect = [&](const std::string& text, int px, int py, int pw) {
        drawMenuRect(px, py, pw, 25);
        if (hasFont) {
            const int tx = static_cast<int>((px + 3) * kPascalScale);
            const int ty = static_cast<int>((py + 2) * kPascalScale);
            overlay.draw(renderer, text, tx, ty, 200, 200, 240);
        }
    };

    // Get Pascal coordinates for a given menu page.
    // Returns {x, y, w} or {-1,-1,-1} for pages with custom rendering.
    auto getMenuPageCoords = [](MainMenuState::Page p) -> std::array<int, 3> {
        switch (p) {
            case MainMenuState::Page::Root:       return {27, 30, 46};
            case MainMenuState::Page::System:     return {80, 30, 46};
            case MainMenuState::Page::LoadSlots:  return {133, 30, 267};
            case MainMenuState::Page::SaveSlots:  return {133, 30, 267};
            case MainMenuState::Page::QuitConfirm:return {133, 30, 80};
            case MainMenuState::Page::Medical:    return {80, 65, 140};
            case MainMenuState::Page::Detox:      return {80, 65, 140};
            case MainMenuState::Page::ItemType:   return {80, 30, 87};
            case MainMenuState::Page::ItemList:   return {80, 55, 180};
            case MainMenuState::Page::ItemTarget: return {230, 65, 140};
            case MainMenuState::Page::Status:     return {10, 65, 85};
            case MainMenuState::Page::LeaveTeam:  return {80, 65, 140};
            case MainMenuState::Page::Teleport:   return {-1, -1, -1};
            case MainMenuState::Page::ItemBrowse: return {-1, -1, -1};
            case MainMenuState::Page::StatusDetail: return {-1, -1, -1};
            case MainMenuState::Page::Title:      return {-1, -1, -1};
            default:                              return {-1, -1, -1};
        }
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

    auto slotName = [](int slot) -> std::string {
        static const std::array<const char*, 10> kCnDigits = {
            "一", "二", "三", "四", "五", "六", "七", "八", "九", "十"};
        if (slot >= 1 && slot <= 10) {
            return std::string("進度") + kCnDigits[static_cast<std::size_t>(slot - 1)];
        }
        return std::string("進度") + std::to_string(slot);
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
                    const std::string savePath = getSavePath(i);
                    const bool ex = std::filesystem::exists(savePath);
                    std::string itemStr = slotName(i);
                    if (ex) {
                        const std::string modTime = getFileModTime(savePath);
                        itemStr += " [" + modTime + "]";
                    } else {
                        itemStr += " - -- - -- - --";
                    }
                    items.push_back(itemStr);
                }
                {
                    const std::string savePath = getSavePath(11);
                    const bool ex = std::filesystem::exists(savePath);
                    std::string itemStr = "自動檔";
                    if (ex) {
                        const std::string modTime = getFileModTime(savePath);
                        itemStr += " [" + modTime + "]";
                    } else {
                        itemStr += " - -- - -- - --";
                    }
                    items.push_back(itemStr);
                }
                break;
            case MainMenuState::Page::SaveSlots:
                for (int i = 1; i <= 10; ++i) {
                    const std::string savePath = getSavePath(i);
                    const bool ex = std::filesystem::exists(savePath);
                    std::string itemStr = slotName(i);
                    if (ex) {
                        const std::string modTime = getFileModTime(savePath);
                        itemStr += " [" + modTime + "]";
                    } else {
                        itemStr += " - -- - -- - --";
                    }
                    items.push_back(itemStr);
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
                    items.push_back("返回");
                } else {
                    items.push_back("（無角色）");
                }
                break;
            case MainMenuState::Page::LeaveTeam:
                items = buildTeamLines(false, false);
                break;
            case MainMenuState::Page::ItemType:
                items = {"全部物品", "劇情物品", "神兵寶甲", "武功秘笈", "靈丹妙藥", "傷人暗器", "整理物品"};
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
                // Match Pascal Start menu hierarchy: New / Load / Exit.
                items = {"新遊戲", "載入進度", "離開"};
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
                        menu.setStatus("讀取" + slotName(slot) + "成功");
                        menu.open = false;
                    } else {
                        menu.setStatus("讀取" + slotName(slot) + "失敗");
                    }
                }
                break;
            case MainMenuState::Page::SaveSlots:
                if (index >= 0 && index <= 9) {
                    const int slot = index + 1;
                    if (state_->saveR(slot)) {
                        menu.setStatus("存檔" + slotName(slot) + "成功");
                    } else {
                        menu.setStatus("存檔" + slotName(slot) + "失敗");
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
                // Pascal: 0=全部(type 100/all), 1=劇情(0), 2=神兵(1), 3=秘笈(2), 4=靈丹(3), 5=暗器(4), 6=整理
                if (index >= 0 && index <= 5) {
                    const int typeFilter = (index == 0) ? 100 : (index - 1);  // 100 = show all
                    menu.selectedItemType = typeFilter;
                    menu.itemBrowseRow = 0;
                    menu.itemBrowseList.clear();
                    
                    // Build the item browse list
                    for (int i = 0; i < state_->itemListCount(); ++i) {
                        const int inum = state_->itemListNumber(i);
                        const int amount = state_->itemListAmount(i);
                        if (inum >= 0 && amount > 0) {
                            const int t = state_->itemType(inum);
                            if (typeFilter == 100 || t == typeFilter) {
                                menu.itemBrowseList.push_back(inum);
                            }
                        }
                    }
                    
                    if (menu.itemBrowseList.empty()) {
                        menu.setStatus("此分類無物品");
                    } else {
                        menu.itemBrowseCols = 14;  // 14 columns per row like Pascal original
                        menu.itemBrowseRows = (menu.itemBrowseList.size() + menu.itemBrowseCols - 1) / menu.itemBrowseCols;
                        menu.enter(MainMenuState::Page::ItemBrowse);
                    }
                } else if (index == 6) {
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
                } else if (index == 1) {
                    menu.enter(MainMenuState::Page::LoadSlots);
                } else if (index == 2) {
                    running = false;
                }
                break;
            default:
                break;
        }
    };

    SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_BLEND);

    while (running) {
        const auto frameNow = std::chrono::steady_clock::now();
        const auto frameMs = std::chrono::duration_cast<std::chrono::milliseconds>(frameNow - begin).count();
        const int palettePhase = static_cast<int>((frameMs / 200) % 8);
        mainGrpCache.applyPaletteRotation(0xE0, 8, palettePhase);

        for (auto& cloud : clouds) {
            cloud.x += cloud.speedX;
            cloud.y += cloud.speedY;
            if (cloud.x > 17279.0f || cloud.x < 0.0f || cloud.y > 8639.0f || cloud.y < 0.0f) {
                resetCloud(cloud, false);
            }
        }

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
                            // Pascal style: x,y = cursor within visible 14x5 grid, itemStartIndex = scroll offset
                            if (menu.page == MainMenuState::Page::ItemBrowse) {
                                const int cols = menu.itemBrowseCols;
                                constexpr int visRows = 5;
                                const int totalItems = static_cast<int>(menu.itemBrowseList.size());
                                // itemBrowseRow stores cursor within visible area (linear: y*cols+x)
                                int cx = menu.itemBrowseRow % cols;
                                int cy = menu.itemBrowseRow / cols;

                                if (e.key.key == SDLK_DOWN) {
                                    cy += 1;
                                    if (cy >= visRows) {
                                        cy = visRows - 1;
                                        // scroll down if more items below
                                        if (menu.itemStartIndex + cols * visRows < totalItems) {
                                            menu.itemStartIndex += cols;
                                        }
                                    }
                                } else if (e.key.key == SDLK_UP) {
                                    cy -= 1;
                                    if (cy < 0) {
                                        cy = 0;
                                        if (menu.itemStartIndex > 0) {
                                            menu.itemStartIndex -= cols;
                                        }
                                    }
                                } else if (e.key.key == SDLK_RIGHT) {
                                    cx += 1;
                                    if (cx >= cols) cx = 0;
                                } else if (e.key.key == SDLK_LEFT) {
                                    cx -= 1;
                                    if (cx < 0) cx = cols - 1;
                                } else if (e.key.key == SDLK_PAGEDOWN) {
                                    menu.itemStartIndex += cols * visRows;
                                    if (menu.itemStartIndex + cols * visRows > totalItems && totalItems > cols * visRows) {
                                        menu.itemStartIndex = ((totalItems - 1) / cols - visRows + 1) * cols;
                                        if (menu.itemStartIndex < 0) menu.itemStartIndex = 0;
                                    }
                                } else if (e.key.key == SDLK_PAGEUP) {
                                    menu.itemStartIndex -= cols * visRows;
                                    if (menu.itemStartIndex < 0) menu.itemStartIndex = 0;
                                } else if (e.key.key == SDLK_ESCAPE) {
                                    menu.back();
                                    break;
                                } else if (e.key.key == SDLK_RETURN || e.key.key == SDLK_SPACE) {
                                    const int absIdx = menu.itemStartIndex + cy * cols + cx;
                                    if (absIdx >= 0 && absIdx < totalItems) {
                                        menu.selectedItemNumber = menu.itemBrowseList[static_cast<std::size_t>(absIdx)];
                                        const int t = state_->itemType(menu.selectedItemNumber);
                                        if (t == 1 || t == 2 || t == 3) {
                                            menu.enter(MainMenuState::Page::ItemTarget);
                                        } else if (t == 0) {
                                            menu.setStatus(state_->useStoryItem(menu.selectedItemNumber));
                                        }
                                    }
                                    break;
                                }
                                menu.itemBrowseRow = cy * cols + cx;
                                break;
                            }

                            // Teleport map: Esc to go back, Enter/Space/Click handled per-scene
                            if (menu.page == MainMenuState::Page::Teleport) {
                                if (e.key.key == SDLK_ESCAPE) {
                                    menu.back();
                                } else if (e.key.key == SDLK_RETURN || e.key.key == SDLK_SPACE) {
                                    if (menu.teleportSelectedScene >= 0) {
                                        if (state_->teleportToScene(menu.teleportSelectedScene)) {
                                            menu.setStatus("已傳送到 " + state_->getSceneName(menu.teleportSelectedScene));
                                            menu.open = false;
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
                                if (menu.page != MainMenuState::Page::Title) {
                                    menu.back();
                                }
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

                            if (keyUp || keyDown || keyLeft || keyRight) {
                                if (state_->canWalkOnMap(x, y)) {
                                    state_->setMapPosition(x, y);
                                    mStep += 1;
                                    if (mStep > 6) {
                                        mStep = 1;
                                    }
                                    // Auto-trigger scene entry after each step (matches Pascal CheckEntrance)
                                    if (state_->tryEnterScene()) {
                                        const int eventId = state_->tryTriggerCurrentSceneEvent();
                                        if (eventId >= 0) {
                                            menu.setStatus("觸發第3類事件 #" + std::to_string(eventId));
                                        }
                                    }
                                } else {
                                    (void)state_->canWalkOnMap(state_->mapX(), state_->mapY());
                                }
                            }
                            if (e.key.key == SDLK_RETURN || e.key.key == SDLK_SPACE) {
                                if (state_->tryEnterScene()) {
                                    const int eventId = state_->tryTriggerCurrentSceneEvent();
                                    if (eventId >= 0) {
                                        menu.setStatus("觸發第3類事件 #" + std::to_string(eventId));
                                    }
                                }
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
                                sStep += 1;
                                if (sStep > 6) {
                                    sStep = 1;
                                }
                                if (state_->tryLeaveSceneAtCurrentPosition()) {
                                    // Left scene via exit tile, stop scene-only processing for this key.
                                    break;
                                }
                                const int eventId = state_->tryTriggerCurrentSceneEvent();
                                if (eventId >= 0) {
                                    menu.setStatus("觸發第3類事件 #" + std::to_string(eventId));
                                }
                            }

                            if (e.key.key == SDLK_ESCAPE) {
                                menu.resetToRoot();
                            } else if (e.key.key == SDLK_RETURN || e.key.key == SDLK_SPACE) {
                                const int eventId = state_->tryTriggerFacingSceneEvent();
                                if (eventId >= 0) {
                                    menu.setStatus("觸發第1類事件 #" + std::to_string(eventId));
                                }
                            }
                        }
                    }
                    break;
                case SDL_EVENT_MOUSE_BUTTON_DOWN:
                case SDL_EVENT_MOUSE_BUTTON_UP:
                    state_->setInputState(state_->currentKey(), static_cast<int>(e.button.button), state_->mouseX(), state_->mouseY());
                    if (e.type == SDL_EVENT_MOUSE_BUTTON_UP && menu.open && menu.page == MainMenuState::Page::Teleport) {
                        if (e.button.button == 1 && menu.teleportSelectedScene >= 0) {
                            // Left click on a scene dot — teleport
                            if (state_->teleportToScene(menu.teleportSelectedScene)) {
                                menu.setStatus("已傳送到 " + state_->getSceneName(menu.teleportSelectedScene));
                                menu.open = false;
                            }
                        } else if (e.button.button == 3) {
                            // Right click — go back
                            menu.back();
                        }
                    }
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

                    const int building = state_->buildingAt(i1, i2) / 2;
                    if (building > 0) {
                        const TileHeader h = mainGrpCache.headerFor(building);
                        const int width = h.valid ? h.width : 36;
                        const int height = h.valid ? h.height : 18;
                        const int yoffset = h.valid ? h.ys : 0;
                        int c = ((i1 + i2) - (width + 35) / 36 - (yoffset - height + 1) / 9) * 1024 + i2;
                        builds.push_back(BuildDraw{i1, i2, building, c});
                    }
                }
            }

            std::sort(builds.begin(), builds.end(), [](const BuildDraw& a, const BuildDraw& b) {
                return a.sortKey < b.sortKey;
            });

            const int actorSortKey = (mapCX + mapCY) * 1024 + mapCY;
            bool actorDrawn = false;
            const int actorTile = (state_->inShip() != 0)
                ? (3714 + mFace * 4 + ((mStep + 1) / 2))
                : (2501 + mFace * 7 + mStep);

            auto drawActor = [&]() {
                if (!mainGrpCache.renderTile(actorTile, centerX, centerY)) {
                    SDL_FRect roleRect{static_cast<float>(centerX - 6), static_cast<float>(centerY - 18), 12.0f, 18.0f};
                    if (state_->inShip() != 0) {
                        SDL_SetRenderDrawColor(renderer, 190, 140, 70, 255);
                    } else {
                        SDL_SetRenderDrawColor(renderer, 250, 240, 80, 255);
                    }
                    SDL_RenderFillRect(renderer, &roleRect);
                }
            };

            for (const auto& b : builds) {
                if (!actorDrawn && actorSortKey <= b.sortKey) {
                    drawActor();
                    actorDrawn = true;
                }
                const auto pos = getPositionOnScreen(b.mapX, b.mapY, mapCX, mapCY, centerX, centerY);
                if (!mainGrpCache.renderTile(b.tile, pos.first, pos.second)) {
                    SDL_Texture* t = texCache.loadMMapTexture(b.tile);
                    if (t) {
                        SDL_FRect r{static_cast<float>(pos.first), static_cast<float>(pos.second), 36.0f, 18.0f};
                        SDL_RenderTexture(renderer, t, nullptr, &r);
                    }
                }
            }

            if (!actorDrawn) {
                drawActor();
            }

            for (const auto& cloud : clouds) {
                const int drawX = static_cast<int>(cloud.x - (-static_cast<float>(mapCX) * 18.0f + static_cast<float>(mapCY) * 18.0f + 8640.0f - static_cast<float>(centerX)));
                const int drawY = static_cast<int>(cloud.y - (static_cast<float>(mapCX) * 9.0f + static_cast<float>(mapCY) * 9.0f + 9.0f - static_cast<float>(centerY)));
                cloudGrpCache.renderTile(cloud.pic, drawX, drawY);
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

                    const int groundHeight = state_->getSData(sceneId, 4, x, y);
                    const int groundTile = state_->getSData(sceneId, 0, x, y) / 2;
                    if (groundTile > 0 && groundHeight <= 0) {
                        if (!sceneGrpCache.renderTile(groundTile, pos.first, pos.second)) {
                            SDL_FRect r{static_cast<float>(pos.first), static_cast<float>(pos.second), 36.0f, 18.0f};
                            mapColor(renderer, groundTile, 0);
                            SDL_RenderFillRect(renderer, &r);
                        }
                    }
                }
            }

            for (int sum = -sumRegion; sum <= sumRegion + 10; ++sum) {
                for (int i = -widthRegion; i <= widthRegion; ++i) {
                    const int x = sx + i + (sum / 2);
                    const int y = sy - i + (sum - sum / 2);
                    const auto pos = getPositionOnScreen(x, y, sx, sy, centerX, centerY);
                    if (x < 0 || x > 63 || y < 0 || y > 63 || sceneId < 0) {
                        continue;
                    }

                    const int height1 = state_->getSData(sceneId, 4, x, y);
                    const int height2 = state_->getSData(sceneId, 5, x, y);
                    const int groundTile = state_->getSData(sceneId, 0, x, y) / 2;
                    const int buildingTile = state_->getSData(sceneId, 1, x, y) / 2;
                    const int upperTile = state_->getSData(sceneId, 2, x, y) / 2;
                    const int eventIndex = state_->getSData(sceneId, 3, x, y);

                    if (groundTile > 0 && height1 > 0) {
                        if (!sceneGrpCache.renderTile(groundTile, pos.first, pos.second)) {
                            SDL_FRect r{static_cast<float>(pos.first), static_cast<float>(pos.second), 36.0f, 18.0f};
                            mapColor(renderer, groundTile, 0);
                            SDL_RenderFillRect(renderer, &r);
                        }
                    }

                    if (buildingTile > 0) {
                        if (!sceneGrpCache.renderTile(buildingTile, pos.first, pos.second - height1)) {
                            SDL_FRect r{static_cast<float>(pos.first), static_cast<float>(pos.second - height1), 36.0f, 18.0f};
                            mapColor(renderer, buildingTile, 1);
                            SDL_RenderFillRect(renderer, &r);
                        }
                    }

                    // Insert role between building and upper/event layers so foreground tiles
                    // can still occlude the actor as in original scene masking behaviour.
                    if (x == sx && y == sy) {
                        const int roleTile = 2501 + state_->sceneFace() * 7 + sStep;
                        if (!sceneGrpCache.renderTile(roleTile, pos.first, pos.second - height1)) {
                            SDL_FRect roleRect{static_cast<float>(pos.first - 4), static_cast<float>(pos.second - 14 - height1), 8.0f, 14.0f};
                            SDL_SetRenderDrawColor(renderer, 250, 240, 80, 255);
                            SDL_RenderFillRect(renderer, &roleRect);
                        }
                    }

                    if (upperTile > 0) {
                        if (!sceneGrpCache.renderTile(upperTile, pos.first, pos.second - height2)) {
                            SDL_FRect r{static_cast<float>(pos.first), static_cast<float>(pos.second - height2), 36.0f, 18.0f};
                            mapColor(renderer, upperTile, 2);
                            SDL_RenderFillRect(renderer, &r);
                        }
                    }

                    if (eventIndex >= 0) {
                        const int eventTile = state_->getDData(sceneId, eventIndex, 5) / 2;
                        if (eventTile > 0) {
                            if (!sceneGrpCache.renderTile(eventTile, pos.first, pos.second - height1)) {
                                SDL_FRect r{static_cast<float>(pos.first), static_cast<float>(pos.second - height1), 36.0f, 18.0f};
                                mapColor(renderer, eventTile, 3);
                                SDL_RenderFillRect(renderer, &r);
                            }
                        }
                    }
                }
            }

            // Scene animation: update event layer tile indices
            if (sceneId >= 0) {
                for (int eventIdx = 0; eventIdx < 200; ++eventIdx) {
                    const int startTile = state_->getDData(sceneId, eventIdx, 7);
                    const int endTile = state_->getDData(sceneId, eventIdx, 6);
                    // If startTile < endTile, this event has animation
                    if (startTile < endTile) {
                        int currentTile = state_->getDData(sceneId, eventIdx, 5);
                        currentTile += 2;  // Move to next animation frame (step of 2 like in Pascal)
                        if (currentTile > endTile) {
                            currentTile = startTile;  // Loop back to start
                        }
                        state_->setDData(sceneId, eventIdx, 5, currentTile);
                    }
                }
            }
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
                    << "  [Esc:離開  Enter/Space:保留]";
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

            if (menu.page == MainMenuState::Page::Title) {
                // Keep background: don't clear screen, just draw the title image + menu on top
                if (SDL_Texture* openTexture = loadTitleOpenTexture()) {
                    float texW = 0.0f;
                    float texH = 0.0f;
                    SDL_GetTextureSize(openTexture, &texW, &texH);
                    const float scale = std::min(static_cast<float>(ww) / texW, static_cast<float>(wh) / texH);
                    const float drawW = texW * scale;
                    const float drawH = texH * scale;
                    SDL_FRect bgRect{
                        (static_cast<float>(ww) - drawW) * 0.5f,
                        (static_cast<float>(wh) - drawH) * 0.5f,
                        drawW,
                        drawH};
                    SDL_RenderTexture(renderer, openTexture, nullptr, &bgRect);
                }
                if (hasFont && !titleOpenDebug.empty()) {
                    overlay.draw(renderer, titleOpenDebug, 12, wh - 26);
                }

                const float menuW = 220.0f;
                const float titleHeaderH = 16.0f;
                const float titleItemH = 30.0f;
                const float menuH = titleHeaderH + static_cast<float>(items.size()) * titleItemH + 16.0f;
                SDL_FRect menuBg{
                    (static_cast<float>(ww) - menuW) * 0.5f,
                    (static_cast<float>(wh) - menuH) * 0.5f,
                    menuW,
                    menuH};
                SDL_SetRenderDrawColor(renderer, 0, 0, 0, 180);
                SDL_RenderFillRect(renderer, &menuBg);
                SDL_FRect menuFrame{menuBg.x - 1.0f, menuBg.y - 1.0f, menuBg.w + 2.0f, menuBg.h + 2.0f};
                SDL_SetRenderDrawColor(renderer, 230, 230, 230, 220);
                SDL_RenderRect(renderer, &menuFrame);

                for (int i = 0; i < static_cast<int>(items.size()); ++i) {
                    const float itemY = menuBg.y + titleHeaderH + static_cast<float>(i) * titleItemH;
                    if (i == menu.selected) {
                        SDL_FRect selectedBg{menuBg.x + 10.0f, itemY - 4.0f, menuBg.w - 20.0f, 24.0f};
                        SDL_SetRenderDrawColor(renderer, 220, 170, 40, 210);
                        SDL_RenderFillRect(renderer, &selectedBg);
                    }
                    if (hasFont) {
                        const int textX = static_cast<int>(menuBg.x + menuBg.w * 0.5f - 42.0f);
                        overlay.draw(renderer, items[static_cast<std::size_t>(i)], textX, static_cast<int>(itemY));
                    }
                }

                presentFrame();
                continue;
            }

            if (menu.page == MainMenuState::Page::StatusDetail) {
                // Draw parent menus: Root menu + Status title + Status team list
                drawPascalMenuList(27, 30, 46, {"醫療", "解毒", "物品", "狀態", "離隊", "傳送", "系統"}, 3);
                drawTitleWithRect("查看隊員狀態", 10, 30, 132);
                // Pascal: ShowStatus(rnum, 100, 65) → scaled
                // Pascal: DrawRectangle(screen, x, y, 525, 315, ...)
                drawMenuRect(100, 65, 525, 315);

                if (menu.selectedRole >= 0) {
                    const int r = menu.selectedRole;
                    const int bx = static_cast<int>(100 * kPascalScale);
                    const int by = static_cast<int>(65 * kPascalScale);

                    // Head portrait at (x+60, y+80) matching Pascal DrawHeadPic
                    const int headNum = state_->roleHeadNum(r);
                    if (SDL_Texture* head = loadHeadTexture(headNum)) {
                        float texW = 0.0f;
                        float texH = 0.0f;
                        SDL_GetTextureSize(head, &texW, &texH);
                        const float maxW = 60.0f;
                        const float maxH = 60.0f;
                        const float hscale = std::min(maxW / texW, maxH / texH);
                        const float drawW = texW * hscale;
                        const float drawH = texH * hscale;
                        SDL_FRect headRect{
                            static_cast<float>(bx + 60) - drawW * 0.5f,
                            static_cast<float>(by + 80) - drawH * 0.5f,
                            drawW, drawH};
                        SDL_RenderTexture(renderer, head, nullptr, &headRect);
                    }

                    if (hasFont) {
                        // Name centered at (x+88, y+85)
                        const std::string roleName = state_->getRoleName(r);
                        const int nameDrawLen = state_->drawLength(roleName);
                        overlay.draw(renderer, roleName, bx + 88 - nameDrawLen * 5, by + 85,
                                     colValueR, colValueG, colValueB);

                        // Left column labels at x+10, y+110+i*21
                        const std::array<const char*, 6> leftLabels = {
                            "等級", "生命", "內力", "體力", "經驗", "升級"};
                        for (int i = 0; i < 6; ++i) {
                            overlay.draw(renderer, leftLabels[static_cast<std::size_t>(i)],
                                         bx + 10, by + 110 + i * 21, colLabelR, colLabelG, colLabelB);
                        }

                        // Level value at x+110, y+110
                        {
                            std::ostringstream os;
                            os << std::setw(4) << state_->roleLevel(r);
                            overlay.draw(renderer, os.str(), bx + 110, by + 110, colValueR, colValueG, colValueB);
                        }
                        // HP at x+60, y+131 - color varies by hurt
                        {
                            const int hurt = state_->roleHurt(r);
                            uint8_t hpR = colValueR, hpG = colValueG, hpB = colValueB;
                            if (hurt >= 67) { hpR = 220; hpG = 50; hpB = 50; }
                            else if (hurt >= 34) { hpR = 230; hpG = 180; hpB = 50; }
                            std::ostringstream os;
                            os << std::setw(4) << state_->roleCurrentHp(r);
                            overlay.draw(renderer, os.str(), bx + 60, by + 131, hpR, hpG, hpB);
                            overlay.draw(renderer, "/", bx + 100, by + 131, colLabelR, colLabelG, colLabelB);
                            // MaxHP color varies by poison
                            const int poison = state_->rolePoison(r);
                            uint8_t mhR = colLabelR, mhG = colLabelG, mhB = colLabelB;
                            if (poison >= 67) { mhR = 100; mhG = 200; mhB = 50; }
                            else if (poison >= 34) { mhR = 140; mhG = 200; mhB = 100; }
                            std::ostringstream os2;
                            os2 << std::setw(4) << state_->roleMaxHp(r);
                            overlay.draw(renderer, os2.str(), bx + 110, by + 131, mhR, mhG, mhB);
                        }
                        // MP at x+60, y+152 - color varies by mpType
                        {
                            const int mpType = state_->getRoleData(r, 40);
                            uint8_t mpR = colValueR, mpG = colValueG, mpB = colValueB;
                            if (mpType == 0) { mpR = 148; mpG = 103; mpB = 189; }       // 陰 - purple
                            else if (mpType == 1) { mpR = colValueR; mpG = colValueG; mpB = colValueB; }  // 陽 - normal
                            else { mpR = colLabelR; mpG = colLabelG; mpB = colLabelB; }  // 调和
                            std::ostringstream os;
                            os << std::setw(4) << state_->roleCurrentMp(r) << "/" << std::setw(4) << state_->roleMaxMp(r);
                            overlay.draw(renderer, os.str(), bx + 60, by + 152, mpR, mpG, mpB);
                        }
                        // PhyPower at x+60, y+173
                        {
                            std::ostringstream os;
                            os << std::setw(4) << state_->rolePhyPower(r) << "/" << std::setw(4) << 100;
                            overlay.draw(renderer, os.str(), bx + 60, by + 173, colValueR, colValueG, colValueB);
                        }
                        // Exp at x+100, y+194
                        {
                            std::ostringstream os;
                            os << std::setw(5) << state_->roleCurrentExp(r);
                            overlay.draw(renderer, os.str(), bx + 100, by + 194, colValueR, colValueG, colValueB);
                        }
                        // LevelUp exp at x+100, y+215
                        {
                            std::ostringstream os;
                            os << std::setw(5) << state_->roleExpForItem(r);
                            overlay.draw(renderer, os.str(), bx + 100, by + 215, colValueR, colValueG, colValueB);
                        }

                        // Mid column: combat stats at x+180, y+5+i*21, values at x+280
                        const std::array<const char*, 11> midLabels = {
                            "攻擊", "防禦", "輕功", "醫療能力", "用毒能力",
                            "解毒能力", "拳掌功夫", "御劍能力", "耍刀技巧", "特殊兵器", "暗器技巧"};
                        const std::array<int, 11> midValues = {
                            state_->roleAttack(r), state_->roleDefence(r), state_->roleSpeed(r),
                            state_->roleMedcine(r), state_->roleUsePoi(r), state_->roleMedPoi(r),
                            state_->roleFist(r), state_->roleSword(r), state_->roleKnife(r),
                            state_->roleUnusual(r), state_->roleHidWeapon(r)};
                        for (int i = 0; i < 11; ++i) {
                            overlay.draw(renderer, midLabels[static_cast<std::size_t>(i)],
                                         bx + 180, by + 5 + i * 21, colLabelR, colLabelG, colLabelB);
                            std::ostringstream os;
                            os << std::setw(4) << midValues[static_cast<std::size_t>(i)];
                            overlay.draw(renderer, os.str(), bx + 280, by + 5 + i * 21, colValueR, colValueG, colValueB);
                        }

                        // Right column: magic at x+360, y+5
                        overlay.draw(renderer, "所會武功", bx + 360, by + 5, colLabelR, colLabelG, colLabelB);
                        int magicRow = 0;
                        for (int i = 0; i < 10; ++i) {
                            const int magicId = state_->roleMagic(r, i);
                            if (magicId <= 0) { continue; }
                            const int my = by + 26 + magicRow * 21;
                            overlay.draw(renderer, state_->getMagicName(magicId), bx + 360, my, colValueR, colValueG, colValueB);
                            std::ostringstream os;
                            os << std::setw(3) << (state_->roleMagicLevel(r, i) / 100 + 1);
                            overlay.draw(renderer, os.str(), bx + 480, my, colLabelR, colLabelG, colLabelB);
                            ++magicRow;
                        }
                        if (magicRow == 0) {
                            overlay.draw(renderer, "（無武功）", bx + 360, by + 26);
                        }

                        // Equipment at x+180,y+240 and Practice at x+360,y+240
                        overlay.draw(renderer, "裝備物品", bx + 180, by + 240, colLabelR, colLabelG, colLabelB);
                        overlay.draw(renderer, "修煉物品", bx + 360, by + 240, colLabelR, colLabelG, colLabelB);
                        const int eq0 = state_->roleEquip(r, 0);
                        const int eq1 = state_->roleEquip(r, 1);
                        const int prac = state_->rolePracticeBook(r);
                        overlay.draw(renderer, eq0 >= 0 ? state_->getItemName(eq0) : "", bx + 190, by + 261, colValueR, colValueG, colValueB);
                        overlay.draw(renderer, eq1 >= 0 ? state_->getItemName(eq1) : "", bx + 190, by + 282, colValueR, colValueG, colValueB);
                        if (prac >= 0) {
                            overlay.draw(renderer, state_->getItemName(prac), bx + 370, by + 261, colValueR, colValueG, colValueB);
                            // Practice book exp: expForBook / needexp
                            std::ostringstream os;
                            os << std::setw(5) << state_->roleExpForBook(r);
                            overlay.draw(renderer, os.str(), bx + 380, by + 282, colLabelR, colLabelG, colLabelB);
                        }

                        overlay.draw(renderer, "[Enter/Esc:返回]", bx + 10, by + 296);
                    }
                }

                presentFrame();
                continue;
            }
            
            // Special rendering for ItemBrowse page - matching Pascal ShowMenuItem layout
            if (menu.page == MainMenuState::Page::ItemBrowse) {
                // Draw parent menus: Root menu + ItemType menu
                drawPascalMenuList(27, 30, 46, {"醫療", "解毒", "物品", "狀態", "離隊", "傳送", "系統"}, 2);
                const int cols = menu.itemBrowseCols;  // 14
                constexpr int visRows = 5;
                constexpr int cellSize = 42;
                const int totalItems = static_cast<int>(menu.itemBrowseList.size());
                const int w = cols * cellSize + 8;  // Pascal: w := col * 42 + 8
                auto getItemAmount = [&](int itemId) -> int {
                    for (int i = 0; i < state_->itemListCount(); ++i) {
                        if (state_->itemListNumber(i) == itemId) {
                            return state_->itemListAmount(i);
                        }
                    }
                    return 0;
                };

                // Panel origin (110, 30) in Pascal's 800x450 coordinate space, scaled by 1.2
                const int ox = static_cast<int>(110 * kPascalScale);
                const int scaledCellSize = static_cast<int>(cellSize * kPascalScale);
                const int scaledW = static_cast<int>(w * kPascalScale);

                // Header bar (110, 30, w, 25): item name + amount
                drawMenuRect(110, 30, w, 25);

                // Description bar (110, 60, w, 25)
                drawMenuRect(110, 60, w, 25);

                // Grid area (110, 90, w, 218)
                drawMenuRect(110, 90, w, 218);

                // Bottom bar (110, 313, w, 25): item type + user
                drawMenuRect(110, 313, w, 25);

                // Cursor position within visible grid
                const int cx = menu.itemBrowseRow % cols;
                const int cy = menu.itemBrowseRow / cols;
                const int absIdx = menu.itemStartIndex + cy * cols + cx;

                // Draw item icons in 14x5 grid
                for (int gy = 0; gy < visRows; ++gy) {
                    for (int gx = 0; gx < cols; ++gx) {
                        const int idx = menu.itemStartIndex + gy * cols + gx;
                        if (idx >= totalItems || idx < 0) continue;
                        const int itemId = menu.itemBrowseList[static_cast<std::size_t>(idx)];
                        const float xPos = static_cast<float>(ox + static_cast<int>(5 * kPascalScale) + gx * scaledCellSize);
                        const float yPos = static_cast<float>(static_cast<int>(95 * kPascalScale) + gy * scaledCellSize);

                        // Draw item icon PNG
                        const std::string fullPath = appPath + "/item/" + std::to_string(itemId) + ".png";
                        SDL_IOStream* src = SDL_IOFromFile(fullPath.c_str(), "rb");
                        if (src) {
                            SDL_Surface* surface = SDL_LoadPNG_IO(src, true);
                            if (surface) {
                                SDL_Texture* texture = SDL_CreateTextureFromSurface(renderer, surface);
                                if (texture) {
                                    const float imgScale = std::min(
                                        static_cast<float>(scaledCellSize - 4) / static_cast<float>(surface->w),
                                        static_cast<float>(scaledCellSize - 4) / static_cast<float>(surface->h));
                                    const float dw = surface->w * imgScale;
                                    const float dh = surface->h * imgScale;
                                    // Dim non-selected items like Pascal (shadow=25, alpha=15)
                                    if (gy == cy && gx == cx) {
                                        SDL_SetTextureAlphaMod(texture, 255);
                                    } else {
                                        SDL_SetTextureAlphaMod(texture, 180);
                                    }
                                    SDL_FRect imgRect{xPos + (scaledCellSize - dw) * 0.5f, yPos + (scaledCellSize - dh) * 0.5f, dw, dh};
                                    SDL_RenderTexture(renderer, texture, nullptr, &imgRect);
                                    SDL_DestroyTexture(texture);
                                }
                                SDL_DestroySurface(surface);
                            }
                        }
                    }
                }

                // Draw cursor frame (white rectangle around selected cell)
                {
                    const float fx = static_cast<float>(ox + static_cast<int>(5 * kPascalScale) + cx * scaledCellSize);
                    const float fy = static_cast<float>(static_cast<int>(95 * kPascalScale) + cy * scaledCellSize);
                    SDL_FRect cursorRect{fx, fy, static_cast<float>(scaledCellSize), static_cast<float>(scaledCellSize)};
                    SDL_SetRenderDrawColor(renderer, 255, 255, 255, 240);
                    SDL_RenderRect(renderer, &cursorRect);
                }

                // Fill header & bottom with selected item info
                if (absIdx >= 0 && absIdx < totalItems && hasFont) {
                    const int itemId = menu.itemBrowseList[static_cast<std::size_t>(absIdx)];
                    const int amount = getItemAmount(itemId);
                    const std::string itemName = state_->getItemName(itemId);
                    const std::string intro = state_->getItemIntroduction(itemId);
                    const int itemType = state_->itemType(itemId);

                    // Item name centered in header bar
                    const int nameLen = state_->drawLength(itemName);
                    overlay.draw(renderer, itemName, ox + scaledW / 2 - nameLen * 5, static_cast<int>(32 * kPascalScale), colLabelR, colLabelG, colLabelB);
                    // Amount at right of header
                    {
                        std::ostringstream os;
                        os << std::setw(5) << amount;
                        overlay.draw(renderer, os.str(), ox + scaledW - 80, static_cast<int>(32 * kPascalScale), colValueR, colValueG, colValueB);
                    }

                    // Introduction centered in desc bar
                    if (!intro.empty()) {
                        const int introLen = state_->drawLength(intro);
                        overlay.draw(renderer, intro, ox + scaledW / 2 - introLen * 5, static_cast<int>(62 * kPascalScale), colValueR, colValueG, colValueB);
                    }

                    // Bottom bar: item type + user
                    static const std::array<const char*, 5> typeNames = {
                        "劇情物品", "神兵寶甲", "武功秘笈", "靈丹妙藥", "傷人暗器"};
                    if (itemType >= 0 && itemType < 5) {
                        overlay.draw(renderer, typeNames[static_cast<std::size_t>(itemType)], ox + static_cast<int>(7 * kPascalScale), static_cast<int>(315 * kPascalScale), colLabelR, colLabelG, colLabelB);
                    }
                    const int user = state_->itemUser(itemId);
                    if (user >= 0) {
                        overlay.draw(renderer, "使用人：", ox + static_cast<int>(97 * kPascalScale), static_cast<int>(315 * kPascalScale), colLabelR, colLabelG, colLabelB);
                        overlay.draw(renderer, state_->getRoleName(user), ox + static_cast<int>(187 * kPascalScale), static_cast<int>(315 * kPascalScale), colValueR, colValueG, colValueB);
                    }

                    // Attribute area below bottom bar - Pascal: (110, 344, w, dynamic)
                    // 6 columns x 95px per column
                    if (itemType > 0) {
                        const std::array<const char*, 23> words2 = {
                            "生命", "生命", "中毒", "體力", "內力", "內力", "內力",
                            "攻擊", "輕功", "防禦", "醫療", "用毒", "解毒", "抗毒",
                            "拳掌", "御劍", "耍刀", "特殊", "暗器", "武學", "品德", "左右", "帶毒"};
                        const std::array<const char*, 13> words3 = {
                            "內力", "內力", "攻擊", "輕功", "用毒", "醫療", "解毒",
                            "拳掌", "御劍", "耍刀", "特殊", "暗器", "資質"};

                        // Count non-zero add stats
                        int addCount = 0;
                        for (int i = 0; i < 23; ++i) {
                            if (i == 4) {
                                if (state_->getItemData(itemId, 52) == 2) addCount++;
                            } else if (state_->getItemData(itemId, 45 + i) != 0) {
                                addCount++;
                            }
                        }
                        int needCount = 0;
                        for (int i = 0; i < 13; ++i) {
                            if (i == 0) {
                                const int nmt = state_->getItemData(itemId, 80);
                                if (nmt == 0 || nmt == 1) needCount++;
                            } else if (state_->getItemData(itemId, 69 + i) != 0) {
                                needCount++;
                            }
                        }

                        if (addCount + needCount > 0) {
                            const int attrRows = (addCount + 5) / 6 + (needCount + 5) / 6;
                            const float attrH = static_cast<float>(attrRows * 20 + 5);
                            drawMenuRect(110, 344, w, static_cast<int>(attrH));

                            // Draw add-stats in 6 columns
                            int idx2 = 0;
                            for (int i = 0; i < 23; ++i) {
                                int v = state_->getItemData(itemId, 45 + i);
                                bool show = false;
                                if (i == 4) {
                                    if (state_->getItemData(itemId, 52) == 2) show = true;
                                } else if (v != 0) {
                                    show = true;
                                }
                                if (!show) continue;

                                std::string valStr;
                                if (i == 4) {
                                    switch (state_->getItemData(itemId, 52)) {
                                        case 0: valStr = "    陰"; break;
                                        case 1: valStr = "    陽"; break;
                                        case 2: valStr = "  調和"; break;
                                        default: valStr = std::to_string(v); break;
                                    }
                                } else {
                                    std::ostringstream os;
                                    os << std::setw(6) << v;
                                    valStr = os.str();
                                }

                                const int drawX = ox + static_cast<int>(7 * kPascalScale) + (idx2 % 6) * static_cast<int>(95 * kPascalScale);
                                const int drawY = (idx2 / 6) * static_cast<int>(20 * kPascalScale) + static_cast<int>(346 * kPascalScale);
                                overlay.draw(renderer, words2[static_cast<std::size_t>(i)], drawX, drawY, colValueR, colValueG, colValueB);
                                overlay.draw(renderer, valStr, drawX + 20, drawY, colLabelR, colLabelG, colLabelB);
                                idx2++;
                            }

                            // Draw need-stats
                            const int needBaseRow = (addCount + 5) / 6;
                            int idx3 = 0;
                            for (int i = 0; i < 13; ++i) {
                                int v = state_->getItemData(itemId, 69 + i);
                                bool show = false;
                                if (i == 0) {
                                    const int nmt = state_->getItemData(itemId, 80);
                                    if (nmt == 0 || nmt == 1) show = true;
                                } else if (v != 0) {
                                    show = true;
                                }
                                if (!show) continue;

                                std::string valStr;
                                if (i == 0) {
                                    switch (state_->getItemData(itemId, 80)) {
                                        case 0: valStr = "    陰"; break;
                                        case 1: valStr = "    陽"; break;
                                        default: valStr = std::to_string(v); break;
                                    }
                                } else {
                                    std::ostringstream os;
                                    os << std::setw(6) << v;
                                    valStr = os.str();
                                }

                                const int drawX = ox + static_cast<int>(7 * kPascalScale) + (idx3 % 6) * static_cast<int>(95 * kPascalScale);
                                const int drawY = (needBaseRow + idx3 / 6) * static_cast<int>(20 * kPascalScale) + static_cast<int>(346 * kPascalScale);
                                overlay.draw(renderer, words3[static_cast<std::size_t>(i)], drawX, drawY, 148, 103, 189);
                                overlay.draw(renderer, valStr, drawX + 20, drawY, colLabelR, colLabelG, colLabelB);
                                idx3++;
                            }
                        }
                    }
                }

                if (hasFont) {
                    overlay.draw(renderer, "[方向鍵:選擇  PgUp/PgDn:翻頁  Enter:使用  Esc:返回]", ox, static_cast<int>(440 * kPascalScale));
                }

                presentFrame();
                continue;
            }

            // Special rendering for Teleport page - miniature world map with scene dots
            if (menu.page == MainMenuState::Page::Teleport) {
                // Draw dark overlay
                SDL_FRect fullScreen{0, 0, static_cast<float>(ww), static_cast<float>(wh)};
                SDL_SetRenderDrawColor(renderer, 0, 0, 0, 200);
                SDL_RenderFillRect(renderer, &fullScreen);

                // Miniature map: isometric projection of 480x480 world
                // Pascal formula: x1 = center_x - (x - y), y1 = (x + y) / 2
                const int mapCenterX = ww / 2;

                // Draw earth tiles as single-pixel dots (simplified mini-map)
                // Cache the miniature map as a texture for efficiency
                if (!teleportMapBuilt && state_->sceneAmount() > 0) {
                    // Build minimap texture (960 x 480 to fit isometric projection)
                    teleportMapTexture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, ww, wh);
                    if (teleportMapTexture) {
                        SDL_SetTextureBlendMode(teleportMapTexture, SDL_BLENDMODE_BLEND);
                        SDL_SetRenderTarget(renderer, teleportMapTexture);
                        SDL_SetRenderDrawColor(renderer, 0, 0, 0, 0);
                        SDL_RenderClear(renderer);

                        for (int mx = 0; mx < 480; ++mx) {
                            for (int my = 0; my < 480; ++my) {
                                const int x1 = mapCenterX - (mx - my);
                                const int y1 = (mx + my) / 2;
                                if (x1 < 0 || x1 >= ww || y1 < 0 || y1 >= wh) continue;
                                const int earth = state_->earthAt(mx, my) / 2;
                                // Use mapColor-style coloring
                                const auto b = static_cast<std::uint8_t>(earth & 0xFF);
                                SDL_SetRenderDrawColor(renderer,
                                    static_cast<std::uint8_t>(20 + (b % 80)),
                                    static_cast<std::uint8_t>(80 + (b % 120)),
                                    static_cast<std::uint8_t>(20 + (b % 60)),
                                    255);
                                SDL_RenderPoint(renderer, static_cast<float>(x1), static_cast<float>(y1));
                            }
                        }

                        SDL_SetRenderTarget(renderer, useFixedRender ? frameTexture : nullptr);
                        teleportMapBuilt = true;
                    }
                }

                // Draw cached minimap
                if (teleportMapTexture) {
                    SDL_RenderTexture(renderer, teleportMapTexture, nullptr, &fullScreen);
                }

                // Get mouse position in render-space coordinates
                float rawMx = 0, rawMy = 0;
                SDL_GetMouseState(&rawMx, &rawMy);
                int renderMx = static_cast<int>(rawMx);
                int renderMy = static_cast<int>(rawMy);
                if (useFixedRender) {
                    int winW = 0, winH = 0;
                    SDL_GetWindowSize(window, &winW, &winH);
                    if (winW > 0 && winH > 0) {
                        const float sx2 = static_cast<float>(winW) / static_cast<float>(kRenderWidth);
                        const float sy2 = static_cast<float>(winH) / static_cast<float>(kRenderHeight);
                        const float sc = std::min(sx2, sy2);
                        const float offX = (static_cast<float>(winW) - static_cast<float>(kRenderWidth) * sc) * 0.5f;
                        const float offY = (static_cast<float>(winH) - static_cast<float>(kRenderHeight) * sc) * 0.5f;
                        renderMx = static_cast<int>((rawMx - offX) / sc);
                        renderMy = static_cast<int>((rawMy - offY) / sc);
                    }
                }

                // Draw scene entrance dots and detect hover
                menu.teleportSelectedScene = -1;
                int selX2 = 0, selY2 = 0;
                for (int i = 0; i < state_->sceneAmount(); ++i) {
                    const int ex = state_->getSceneData(i, 11);  // MainEntranceX1
                    const int ey = state_->getSceneData(i, 10);  // MainEntranceY1
                    if (ex <= 0 || ey <= 0) continue;
                    const int dotX = mapCenterX - (ex - ey);
                    const int dotY = (ex + ey) / 2;
                    // Draw white dot
                    SDL_FRect dot{static_cast<float>(dotX), static_cast<float>(dotY), 5.0f, 5.0f};
                    SDL_SetRenderDrawColor(renderer, 255, 255, 255, 180);
                    SDL_RenderFillRect(renderer, &dot);
                    // Check if mouse is over this dot
                    if (renderMx >= dotX && renderMx < dotX + 5 && renderMy >= dotY && renderMy < dotY + 5) {
                        menu.teleportSelectedScene = i;
                        selX2 = dotX;
                        selY2 = dotY;
                    }
                }

                // Draw player position as red dot
                {
                    const int px = state_->mapX();
                    const int py = state_->mapY();
                    const int playerDotX = mapCenterX - (px - py);
                    const int playerDotY = (px + py) / 2;
                    SDL_FRect playerDot{static_cast<float>(playerDotX), static_cast<float>(playerDotY), 5.0f, 5.0f};
                    SDL_SetRenderDrawColor(renderer, 255, 0, 0, 220);
                    SDL_RenderFillRect(renderer, &playerDot);
                }

                // If hovering over a scene, highlight it and show name
                if (menu.teleportSelectedScene >= 0 && hasFont) {
                    SDL_FRect hlDot{static_cast<float>(selX2), static_cast<float>(selY2), 5.0f, 5.0f};
                    SDL_SetRenderDrawColor(renderer, 255, 255, 0, 255);
                    SDL_RenderFillRect(renderer, &hlDot);
                    const std::string sceneName = state_->getSceneName(menu.teleportSelectedScene);
                    // Draw name with background to the right of the dot
                    const int nameLen = state_->drawLength(sceneName);
                    SDL_FRect nameBg{static_cast<float>(selX2 + 7), static_cast<float>(selY2 - 5),
                                     static_cast<float>(nameLen * 10 + 8), 20.0f};
                    SDL_SetRenderDrawColor(renderer, 0, 0, 0, 180);
                    SDL_RenderFillRect(renderer, &nameBg);
                    overlay.draw(renderer, sceneName, selX2 + 11, selY2 - 3, colValueR, colValueG, colValueB);
                }

                if (hasFont) {
                    overlay.draw(renderer, "[滑鼠移動:選擇場景  左鍵:傳送  右鍵/Esc:返回]", 10, wh - 22);
                }

                presentFrame();
                continue;
            }

            // === Pascal-style multi-level menu rendering ===
            // Draw all parent menus in the stack first, then the current page.
            // This matches Pascal where parent menu remains visible under child.

            // Helper: build items for a specific page (without side effects)
            auto buildPageItems = [&](MainMenuState::Page pg) -> std::vector<std::string> {
                switch (pg) {
                    case MainMenuState::Page::Root:
                        return {"醫療", "解毒", "物品", "狀態", "離隊", "傳送", "系統"};
                    case MainMenuState::Page::System: {
                        const bool fs = (SDL_GetWindowFlags(window) & SDL_WINDOW_FULLSCREEN) != 0;
                        return {"讀取", "存檔", fs ? "窗口" : "全屏", "離開"};
                    }
                    case MainMenuState::Page::QuitConfirm:
                        return {"取消", "確認", "腳本"};
                    case MainMenuState::Page::ItemType:
                        return {"全部物品", "劇情物品", "神兵寶甲", "武功秘笈", "靈丹妙藥", "傷人暗器", "整理物品"};
                    case MainMenuState::Page::Medical:
                    case MainMenuState::Page::Detox:
                    case MainMenuState::Page::Status:
                    case MainMenuState::Page::LeaveTeam:
                    case MainMenuState::Page::ItemTarget: {
                        // Build team names
                        std::vector<std::string> tl;
                        for (int i = 0; i < KysState::kTeamSize; ++i) {
                            const int role = state_->getTeam(i);
                            if (role < 0) continue;
                            tl.push_back(state_->getRoleName(role));
                        }
                        if (tl.empty()) tl.push_back("（無隊友）");
                        return tl;
                    }
                    default:
                        return {};
                }
            };

            // Draw parent menus from the stack (they stay visible behind)
            for (std::size_t si = 0; si < menu.stack.size(); ++si) {
                const auto pg = menu.stack[si];
                const auto coords = getMenuPageCoords(pg);
                if (coords[0] < 0) continue;
                // For stack pages, the selected item is unknown (already navigated away),
                // so highlight the item that was chosen (approximated by the NEXT page in stack or current).
                // We find which item was chosen by looking at the child page.
                MainMenuState::Page childPage = (si + 1 < menu.stack.size()) ? menu.stack[si + 1] : menu.page;
                int highlightIdx = -1;
                // Map child pages to parent item indices
                if (pg == MainMenuState::Page::Root) {
                    if (childPage == MainMenuState::Page::Medical) highlightIdx = 0;
                    else if (childPage == MainMenuState::Page::Detox) highlightIdx = 1;
                    else if (childPage == MainMenuState::Page::ItemType || childPage == MainMenuState::Page::ItemBrowse) highlightIdx = 2;
                    else if (childPage == MainMenuState::Page::Status || childPage == MainMenuState::Page::StatusDetail) highlightIdx = 3;
                    else if (childPage == MainMenuState::Page::LeaveTeam) highlightIdx = 4;
                    else if (childPage == MainMenuState::Page::Teleport) highlightIdx = 5;
                    else if (childPage == MainMenuState::Page::System) highlightIdx = 6;
                }
                if (pg == MainMenuState::Page::System) {
                    if (childPage == MainMenuState::Page::LoadSlots) highlightIdx = 0;
                    else if (childPage == MainMenuState::Page::SaveSlots) highlightIdx = 1;
                    else if (childPage == MainMenuState::Page::QuitConfirm) highlightIdx = 3;
                }
                auto parentItems = buildPageItems(pg);
                if (!parentItems.empty()) {
                    drawPascalMenuList(coords[0], coords[1], coords[2], parentItems, highlightIdx);
                }

                // Draw title bar for sub-pages that have one
                if (pg == MainMenuState::Page::Root) {
                    if (childPage == MainMenuState::Page::Medical || childPage == MainMenuState::Page::ItemTarget)
                        drawTitleWithRect("隊員醫療能力", 80, 30, 132);
                    else if (childPage == MainMenuState::Page::Detox)
                        drawTitleWithRect("隊員解毒能力", 80, 30, 132);
                    else if (childPage == MainMenuState::Page::Status || childPage == MainMenuState::Page::StatusDetail)
                        drawTitleWithRect("查看隊員狀態", 10, 30, 132);
                    else if (childPage == MainMenuState::Page::LeaveTeam)
                        drawTitleWithRect("要求誰離隊？", 80, 30, 132);
                }
                // When Medical/Detox navigates to ItemTarget, draw second title
                if (pg == MainMenuState::Page::Medical && childPage == MainMenuState::Page::ItemTarget) {
                    drawTitleWithRect("隊員目前生命", 230, 30, 132);
                }
                if (pg == MainMenuState::Page::Detox && childPage == MainMenuState::Page::ItemTarget) {
                    drawTitleWithRect("隊員中毒程度", 230, 30, 132);
                }
            }

            // Draw current page
            const auto curCoords = getMenuPageCoords(menu.page);
            if (curCoords[0] >= 0 && !items.empty()) {
                drawPascalMenuList(curCoords[0], curCoords[1], curCoords[2], items, menu.selected);
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

    for (auto& kv : headTextureCache) {
        if (kv.second) {
            SDL_DestroyTexture(kv.second);
        }
    }
    headTextureCache.clear();
    missingHeadTexture.clear();

    if (titleOpenTexture) {
        SDL_DestroyTexture(titleOpenTexture);
        titleOpenTexture = nullptr;
    }

    if (teleportMapTexture) {
        SDL_DestroyTexture(teleportMapTexture);
        teleportMapTexture = nullptr;
    }

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
