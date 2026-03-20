#include "kys_state.hpp"
#include "resource_loader.hpp"
#include "script_bridge.hpp"
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
                  << "  kys_save_tool <appPath> script-api-list\n"
                  << "  kys_save_tool <appPath> script-run <lua_file> [function] [slot]\n"
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
        auto state = std::make_unique<kys::KysState>(appPath);
        kys::ScriptBridge bridge;
        bridge.attachState(state.get());
        if (!bridge.initialize()) {
            std::cerr << "script bridge init failed\n";
            return 7;
        }
        std::cout << "lua_backend=" << (bridge.hasLuaBackend() ? 1 : 0)
                  << " api_count=" << bridge.registeredApi().size() << "\n";
        for (const auto& n : bridge.registeredApi()) {
            std::cout << n << "\n";
        }
        return 0;
    }

    if (action == "script-run") {
        if (argc < 4) {
            std::cerr << "script-run requires <lua_file> [function] [slot]\n";
            return 8;
        }
        const std::string luaFile = argv[3];
        const std::string fn = argc >= 5 ? argv[4] : "";
        const int slot = argc >= 6 ? std::stoi(argv[5]) : 0;

        auto state = std::make_unique<kys::KysState>(appPath);
        (void)state->loadR(slot);

        kys::ScriptBridge bridge;
        bridge.attachState(state.get());
        if (!bridge.initialize()) {
            std::cerr << "script bridge init failed\n";
            return 7;
        }
        const int rc = bridge.execScript(luaFile, fn);
        std::cout << "script rc=" << rc << "\n";
        return rc;
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
