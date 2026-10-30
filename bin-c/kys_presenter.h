#pragma once

#include <SDL3/SDL.h>
#include <SDL3_ttf/SDL_ttf.h>

// The software surfaces retain the game's logical pixels. The web presenter
// replays UI operations at display resolution, including saved menu backgrounds.
namespace Presentation
{
#ifdef __EMSCRIPTEN__
bool blit(SDL_Surface* source, const SDL_Rect* sourceRect, SDL_Surface* target, SDL_Rect* targetRect);
bool fill(SDL_Surface* target, const SDL_Rect* rect, Uint32 color);
void pixel(SDL_Surface* target, int x, int y, Uint32 color);
void glyph(TTF_Font* font, const char* text, int x, int y, SDL_Color color);
void clear(SDL_Surface* target);
void destroy(SDL_Surface* surface);
void shutdown();
bool present(SDL_Renderer* renderer);
#else
inline bool blit(SDL_Surface* source, const SDL_Rect* sourceRect, SDL_Surface* target, SDL_Rect* targetRect)
{
    return SDL_BlitSurface(source, sourceRect, target, targetRect);
}

inline bool fill(SDL_Surface* target, const SDL_Rect* rect, Uint32 color)
{
    return SDL_FillSurfaceRect(target, rect, color);
}

inline void pixel(SDL_Surface*, int, int, Uint32) { }

inline void glyph(TTF_Font*, const char*, int, int, SDL_Color) { }

inline void clear(SDL_Surface*) { }

inline void destroy(SDL_Surface* surface)
{
    SDL_DestroySurface(surface);
}

inline void shutdown() { }

inline bool present(SDL_Renderer*)
{
    return false;
}
#endif
}    //namespace Presentation
