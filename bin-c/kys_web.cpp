#include "kys_web.h"
#include "kys_engine.h"
#include "kys_type.h"
#include <SDL3/SDL.h>
#include <emscripten.h>

namespace
{
int pendingTrack = -1;
int pendingTimes = -1;
int pendingFromBeginning = 1;
}    //namespace

void WebLoading(const char* label)
{
    EM_ASM({ Module.beginLoading(UTF8ToString($0)); }, label);
    // Give the browser a paint opportunity before CPU scene preparation.
    emscripten_sleep(20);
}

bool WebMusicReady(int track)
{
    return EM_ASM_INT({ return Module.prepareMusic($0) ? 1 : 0; }, track) != 0;
}

void WebDeferMusic(int track, int times, int fromBeginning)
{
    pendingTrack = track;
    pendingTimes = times;
    pendingFromBeginning = fromBeginning;
}

void WebCancelMusic()
{
    pendingTrack = -1;
}

void WebPollMusic()
{
    if (pendingTrack >= 0 && WebMusicReady(pendingTrack))
    {
        int track = pendingTrack;
        pendingTrack = -1;
        PlayMP3(track, pendingTimes, pendingFromBeginning);
    }
}

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
