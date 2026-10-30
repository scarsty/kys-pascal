#include "kys_web.h"
#include "kys_engine.h"
#include "kys_type.h"
#include <SDL3/SDL.h>
#include <emscripten.h>

// clang-format off
EM_ASYNC_JS(int, BrowserEnterText, (char* buffer, int capacity), {
    const text = await Module.inputText(UTF8ToString(buffer));
    if (text === null)
    {
        return 0;
    }
    stringToUTF8(text, buffer, capacity);
    return 1;
});
// clang-format on

bool WebEnterString(std::string& text)
{
    char buffer[1024]{ };
    text.copy(buffer, sizeof(buffer) - 1);
    if (!BrowserEnterText(buffer, sizeof(buffer)))
    {
        return false;
    }
    text = buffer;
    return true;
}

extern "C"
{
EMSCRIPTEN_KEEPALIVE void web_resize(int width, int height)
{
    if (window)
    {
        SDL_SetWindowSize(window, width, height);
        ResizeWindow(width, height);
    }
}

EMSCRIPTEN_KEEPALIVE void web_back()
{
    SDL_ResetKeyboard();
    SDL_Event key{ };
    key.type = SDL_EVENT_KEY_DOWN;
    key.key.key = SDLK_ESCAPE;
    SDL_PushEvent(&key);
    key.type = SDL_EVENT_KEY_UP;
    SDL_PushEvent(&key);
}

EMSCRIPTEN_KEEPALIVE void web_clear_keys()
{
    SDL_ResetKeyboard();
}
}
