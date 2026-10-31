#include "kys_presenter.h"
#include "kys_type.h"

#include <algorithm>
#include <cmath>
#include <map>
#include <memory>
#include <string>
#include <tuple>
#include <unordered_map>
#include <variant>
#include <vector>

namespace Presentation
{
namespace
{
struct Image
{
    SDL_Surface* surface = nullptr;
    SDL_Texture* texture = nullptr;

    ~Image()
    {
        SDL_DestroyTexture(texture);
        SDL_DestroySurface(surface);
    }

    SDL_Texture* get(SDL_Renderer* renderer)
    {
        if (!texture)
        {
            texture = SDL_CreateTextureFromSurface(renderer, surface);
        }
        SDL_ScaleMode scaleMode = SDL_SCALEMODE_LINEAR;
        if (screenTex)
        {
            SDL_GetTextureScaleMode(screenTex, &scaleMode);
        }
        SDL_SetTextureScaleMode(texture, scaleMode);
        return texture;
    }
};

using ImagePtr = std::shared_ptr<Image>;

ImagePtr copyImage(SDL_Surface* surface)
{
    auto image = std::make_shared<Image>();
    image->surface = SDL_DuplicateSurface(surface);
    // Modulation is applied once when replaying the recorded blit.
    SDL_SetSurfaceColorMod(image->surface, 255, 255, 255);
    SDL_SetSurfaceAlphaMod(image->surface, 255);
    return image;
}

struct Glyph
{
    TTF_Font* font;
    std::string text;
    SDL_Color color;
};

struct Blit
{
    ImagePtr image;
    SDL_Rect source;
    SDL_BlendMode blend;
    SDL_Color modulation;
};

struct Command
{
    SDL_Rect destination;
    SDL_Rect clip;
    std::variant<Glyph, Blit, SDL_Color> operation;
};

struct Frame
{
    ImagePtr base;
    std::vector<Command> commands;
    ImagePtr pixelPatch;
};

std::unordered_map<SDL_Surface*, Frame> frames;
Frame* screenFrame = nullptr;
std::map<std::pair<TTF_Font*, int>, TTF_Font*> scaledFonts;
std::map<std::tuple<TTF_Font*, int, std::string>, ImagePtr> glyphs;
int outputWidth = 0, outputHeight = 0;

Frame& frameFor(SDL_Surface* surface)
{
    auto& frame = frames[surface];
    if (!frame.base)
    {
        frame.base = copyImage(surface);
    }
    if (surface == screen)
    {
        screenFrame = &frame;
    }
    return frame;
}

// Keep visible fragments only. Flat snapshots prevent repeated menu restores
// from retaining a tree of previous frames.
void cover(Frame& frame, const SDL_Rect& rect)
{
    std::vector<Command> visible;
    visible.reserve(frame.commands.size());
    for (const auto& command : frame.commands)
    {
        SDL_Rect overlap;
        const auto& b = command.clip;
        if (!SDL_GetRectIntersection(&b, &rect, &overlap))
        {
            visible.push_back(command);
            continue;
        }
        SDL_Rect fragments[] = {
            { b.x, b.y, b.w, overlap.y - b.y },
            { b.x, overlap.y + overlap.h, b.w, b.y + b.h - overlap.y - overlap.h },
            { b.x, overlap.y, overlap.x - b.x, overlap.h },
            { overlap.x + overlap.w, overlap.y, b.x + b.w - overlap.x - overlap.w, overlap.h }
        };
        for (const auto& fragment : fragments)
        {
            if (fragment.w > 0 && fragment.h > 0)
            {
                auto copy = command;
                copy.clip = fragment;
                visible.push_back(std::move(copy));
            }
        }
    }
    frame.commands = std::move(visible);
    frame.pixelPatch.reset();
}

SDL_Color surfaceColor(SDL_Surface* surface, Uint32 color)
{
    SDL_Color result;
    SDL_GetRGBA(color, SDL_GetPixelFormatDetails(surface->format), SDL_GetSurfacePalette(surface),
        &result.r, &result.g, &result.b, &result.a);
    return result;
}

SDL_FRect scaledRect(const SDL_Rect& rect, float sx, float sy)
{
    return { std::round(rect.x * sx), std::round(rect.y * sy),
        std::round((rect.x + rect.w) * sx) - std::round(rect.x * sx),
        std::round((rect.y + rect.h) * sy) - std::round(rect.y * sy) };
}

void clearFontCache()
{
    glyphs.clear();
    for (auto& [key, font] : scaledFonts)
    {
        TTF_CloseFont(font);
    }
    scaledFonts.clear();
}

void renderFrame(SDL_Renderer* renderer, const Frame& frame, float sx, float sy)
{
    SDL_Texture* base = frame.base->get(renderer);
    SDL_SetTextureBlendMode(base, SDL_BLENDMODE_NONE);
    SDL_RenderTexture(renderer, base, nullptr, nullptr);
    for (const auto& command : frame.commands)
    {
        auto scaledClip = scaledRect(command.clip, sx, sy);
        SDL_Rect clip = { static_cast<int>(scaledClip.x), static_cast<int>(scaledClip.y),
            static_cast<int>(scaledClip.w), static_cast<int>(scaledClip.h) };
        SDL_SetRenderClipRect(renderer, &clip);
        SDL_FRect destination = scaledRect(command.destination, sx, sy);
        if (const auto* draw = std::get_if<Glyph>(&command.operation))
        {
            int size = std::max(1, static_cast<int>(std::lround(TTF_GetFontSize(draw->font) * sy)));
            auto& image = glyphs[{ draw->font, size, draw->text }];
            if (!image)
            {
                auto& font = scaledFonts[{ draw->font, size }];
                if (!font)
                {
                    font = TTF_CopyFont(draw->font);
                    TTF_SetFontSize(font, static_cast<float>(size));
                }
                image = std::make_shared<Image>();
                image->surface = TTF_RenderText_Blended(font, draw->text.c_str(), draw->text.size(), { 255, 255, 255, 255 });
            }
            if (image->surface)
            {
                SDL_Texture* texture = image->get(renderer);
                SDL_SetTextureColorMod(texture, draw->color.r, draw->color.g, draw->color.b);
                SDL_SetTextureAlphaMod(texture, draw->color.a);
                SDL_SetTextureBlendMode(texture, SDL_BLENDMODE_BLEND);
                destination.w = static_cast<float>(image->surface->w);
                destination.h = static_cast<float>(image->surface->h);
                SDL_RenderTexture(renderer, texture, nullptr, &destination);
            }
        }
        else if (const auto* draw = std::get_if<Blit>(&command.operation))
        {
            SDL_Texture* texture = draw->image->get(renderer);
            SDL_SetTextureBlendMode(texture, draw->blend);
            SDL_SetTextureColorMod(texture, draw->modulation.r, draw->modulation.g, draw->modulation.b);
            SDL_SetTextureAlphaMod(texture, draw->modulation.a);
            SDL_FRect source = { static_cast<float>(draw->source.x), static_cast<float>(draw->source.y),
                static_cast<float>(draw->source.w), static_cast<float>(draw->source.h) };
            SDL_RenderTexture(renderer, texture, &source, &destination);
        }
        else if (const auto* color = std::get_if<SDL_Color>(&command.operation))
        {
            SDL_SetRenderDrawBlendMode(renderer, SDL_BLENDMODE_NONE);
            SDL_SetRenderDrawColor(renderer, color->r, color->g, color->b, color->a);
            SDL_RenderFillRect(renderer, &destination);
        }
    }
    SDL_SetRenderClipRect(renderer, nullptr);
}
}    //namespace

bool blit(SDL_Surface* source, const SDL_Rect* sourceRect, SDL_Surface* target, SDL_Rect* targetRect)
{
    auto from = frames.find(source);
    auto saved = from != frames.end() ? std::make_unique<Frame>(from->second) : nullptr;
    if (saved)
    {
        from->second.pixelPatch.reset();
    }
    if (source && target && (saved || (target == screen && screenFrame)))
    {
        SDL_Rect src = sourceRect ? *sourceRect : SDL_Rect{ 0, 0, source->w, source->h };
        SDL_Rect dst = { targetRect ? targetRect->x : 0, targetRect ? targetRect->y : 0, src.w, src.h };
        SDL_Rect bounds;
        SDL_GetSurfaceClipRect(target, &bounds);
        if (SDL_GetRectIntersection(&dst, &bounds, &bounds))
        {
            auto& frame = frameFor(target);
            if (saved)
            {
                cover(frame, bounds);
                frame.commands.push_back({ dst, bounds, Blit{ saved->base, src, SDL_BLENDMODE_NONE, { 255, 255, 255, 255 } } });
                int dx = dst.x - src.x, dy = dst.y - src.y;
                for (auto command : saved->commands)
                {
                    command.clip.x += dx;
                    command.clip.y += dy;
                    if (SDL_GetRectIntersection(&command.clip, &bounds, &command.clip))
                    {
                        command.destination.x += dx;
                        command.destination.y += dy;
                        frame.commands.push_back(std::move(command));
                    }
                }
            }
            else
            {
                SDL_BlendMode blend;
                SDL_Color modulation;
                SDL_GetSurfaceBlendMode(source, &blend);
                SDL_GetSurfaceColorMod(source, &modulation.r, &modulation.g, &modulation.b);
                SDL_GetSurfaceAlphaMod(source, &modulation.a);
                if (blend == SDL_BLENDMODE_NONE)
                {
                    cover(frame, bounds);
                }
                frame.commands.push_back({ dst, bounds, Blit{ copyImage(source), src, blend, modulation } });
            }
            frame.pixelPatch.reset();
        }
    }
    else if (target && frames.contains(target))
    {
        clear(target);
    }
    return SDL_BlitSurface(source, sourceRect, target, targetRect);
}

bool blitScaled(SDL_Surface* source, const SDL_Rect* sourceRect, SDL_Surface* target, const SDL_Rect* targetRect)
{
    if (source && target && targetRect)
    {
        SDL_Rect src = sourceRect ? *sourceRect : SDL_Rect{ 0, 0, source->w, source->h };
        SDL_Rect bounds;
        SDL_GetSurfaceClipRect(target, &bounds);
        if (SDL_GetRectIntersection(targetRect, &bounds, &bounds))
        {
            auto& frame = frameFor(target);
            SDL_BlendMode blend;
            SDL_Color modulation;
            SDL_GetSurfaceBlendMode(source, &blend);
            SDL_GetSurfaceColorMod(source, &modulation.r, &modulation.g, &modulation.b);
            SDL_GetSurfaceAlphaMod(source, &modulation.a);
            if (blend == SDL_BLENDMODE_NONE) cover(frame, bounds);
            frame.commands.push_back({ *targetRect, bounds, Blit{ copyImage(source), src, blend, modulation } });
            frame.pixelPatch.reset();
        }
    }
    return SDL_BlitSurfaceScaled(source, sourceRect, target, targetRect, SDL_SCALEMODE_LINEAR);
}

bool fill(SDL_Surface* target, const SDL_Rect* rect, Uint32 color)
{
    if (target)
    {
        SDL_Rect bounds = rect ? *rect : SDL_Rect{ 0, 0, target->w, target->h };
        SDL_Rect clip;
        SDL_GetSurfaceClipRect(target, &clip);
        if (bounds.x <= 0 && bounds.y <= 0 && bounds.x + bounds.w >= target->w && bounds.y + bounds.h >= target->h
            && clip.x == 0 && clip.y == 0 && clip.w == target->w && clip.h == target->h)
        {
            clear(target);
        }
        else if (auto found = frames.find(target); found != frames.end())
        {
            if (SDL_GetRectIntersection(&clip, &bounds, &bounds))
            {
                cover(found->second, bounds);
                found->second.commands.push_back({ bounds, bounds, surfaceColor(target, color) });
            }
        }
    }
    return SDL_FillSurfaceRect(target, rect, color);
}

void pixel(SDL_Surface* target, int x, int y, Uint32 color)
{
    if (target != screen || !screenFrame)
    {
        return;
    }
    auto& frame = *screenFrame;
    if (!frame.pixelPatch)
    {
        frame.pixelPatch = std::make_shared<Image>();
        frame.pixelPatch->surface = SDL_CreateSurface(target->w, target->h, SDL_PIXELFORMAT_ARGB8888);
        SDL_FillSurfaceRect(frame.pixelPatch->surface, nullptr, 0);
        SDL_Rect bounds = { 0, 0, target->w, target->h };
        frame.commands.push_back({ bounds, bounds, Blit{ frame.pixelPatch, bounds, SDL_BLENDMODE_BLEND, { 255, 255, 255, 255 } } });
    }
    auto* patch = frame.pixelPatch->surface;
    SDL_Color rgba = surfaceColor(target, color);
    auto* row = reinterpret_cast<Uint32*>(static_cast<Uint8*>(patch->pixels) + y * patch->pitch);
    row[x] = SDL_MapSurfaceRGBA(patch, rgba.r, rgba.g, rgba.b, rgba.a);
}

void glyph(TTF_Font* font, const char* text, int x, int y, SDL_Color color)
{
    auto& frame = frameFor(screen);
    frame.pixelPatch.reset();
    int width = 0, height = 0;
    TTF_GetStringSize(font, text, 0, &width, &height);
    SDL_Rect bounds = { x, y, width, height };
    frame.commands.push_back({ bounds, bounds, Glyph{ font, text, color } });
}

void clear(SDL_Surface* target)
{
    if (target == screen)
    {
        screenFrame = nullptr;
    }
    frames.erase(target);
}

void destroy(SDL_Surface* surface)
{
    clear(surface);
    SDL_DestroySurface(surface);
}

void shutdown()
{
    screenFrame = nullptr;
    frames.clear();
    clearFontCache();
}

bool present(SDL_Renderer* renderer)
{
    if (!screenFrame)
    {
        return false;
    }
    int width, height;
    SDL_GetRenderOutputSize(renderer, &width, &height);
    if (width != outputWidth || height != outputHeight)
    {
        clearFontCache();
        outputWidth = width;
        outputHeight = height;
    }
    renderFrame(renderer, *screenFrame, static_cast<float>(width) / screen->w,
        static_cast<float>(height) / screen->h);
    screenFrame->pixelPatch.reset();
    return true;
}
}    //namespace Presentation
