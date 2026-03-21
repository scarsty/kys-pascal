#include "kys_state.hpp"
#include "resource_loader.hpp"
#include "sdl_runtime.hpp"

#include <iostream>
#include <memory>
#include <string>

int main(int argc, char** argv) {
    if (argc < 3) {
        std::cerr << "Usage:\n"
                  << "  kys_save_tool <appPath> load <slot>\n"
                  << "  kys_save_tool <appPath> save <slot>\n"
                  << "  kys_save_tool <appPath> resource-scan <png_tile_mode>\n"
                  << "  kys_save_tool <appPath> script-api-list (disabled)\n"
                  << "  kys_save_tool <appPath> script-run <lua_file> [function] [slot] (disabled)\n"
                  << "  kys_save_tool <appPath> sdl-loop [milliseconds, 0=run until close]\n";
        return 1;
    }

    const std::string appPath = argv[1];
    const std::string action = argv[2];

    if (action == "resource-scan") {
        if (argc < 4) {
            std::cerr << "resource-scan requires <png_tile_mode>\n";
            return 6;
        }
        const int pngTileMode = std::stoi(argv[3]);
        kys::ResourceLoader loader(appPath);
        loader.setPngTileMode(pngTileMode);
        const auto s = loader.readTilesSummary();
        std::cout << "resource summary"
                  << " m=" << s.mPicAmount << "(" << s.mFrames << ")"
                  << " s=" << s.sPicAmount << "(" << s.sFrames << ")"
                  << " b=" << s.bPicAmount << "(" << s.bFrames << ")"
                  << " e=" << s.ePicAmount << "(" << s.eFrames << ")"
                  << " c=" << s.cPicAmount << "(" << s.cFrames << ")"
                  << " h=" << s.hPicAmount
                  << "\n";
        return 0;
    }

    if (action == "script-api-list") {
        std::cerr << "script bridge is disabled in this build\n";
        return 7;
    }

    if (action == "script-run") {
        (void)argc;
        std::cerr << "script bridge is disabled in this build\n";
        return 8;
    }

    if (action == "sdl-loop") {
        const int ms = argc >= 4 ? std::stoi(argv[3]) : 0;
        auto state = std::make_unique<kys::KysState>(appPath);
        (void)state->loadR(0);
        (void)state->loadWorldData();
        kys::SdlRuntime runtime(state.get(), appPath);
        const int rc = runtime.runLoop(ms);
        std::cout << "sdl rc=" << rc << "\n";
        return rc;
    }

    if (argc < 4) {
        std::cerr << "load/save requires <slot>\n";
        return 1;
    }

    const int slot = std::stoi(argv[3]);

    auto state = std::make_unique<kys::KysState>(appPath);

    if (action == "load") {
        if (!state->loadR(slot)) {
            std::cerr << "Load failed for slot " << slot << "\n";
            return 2;
        }
        std::cout << "Load success. sceneAmount=" << state->sceneAmount()
                  << " where=" << state->where()
                  << " curScene=" << state->currentScene() << "\n";
        return 0;
    }

    if (action == "save") {
        if (!state->loadR(slot)) {
            std::cerr << "Preload before save failed for slot " << slot << "\n";
            return 3;
        }
        if (!state->saveR(slot)) {
            std::cerr << "Save failed for slot " << slot << "\n";
            return 4;
        }
        std::cout << "Save success for slot " << slot << "\n";
        return 0;
    }

    std::cerr << "Unknown action: " << action << "\n";
    return 5;
}
