#include "kys_type.h"
#include <SDL3/SDL.h>
#include <emscripten.h>

extern "C"
{
EMSCRIPTEN_KEEPALIVE void web_resize(int width, int height)
{
    if (window)
    {
        SDL_SetWindowSize(window, width, height);
    }
}

EMSCRIPTEN_KEEPALIVE void web_back()
{
    SDL_Event key{ };
    key.type = SDL_EVENT_KEY_DOWN;
    key.key.key = SDLK_ESCAPE;
    SDL_PushEvent(&key);
    key.type = SDL_EVENT_KEY_UP;
    SDL_PushEvent(&key);
}
}
