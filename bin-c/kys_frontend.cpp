#include "kys_frontend.h"
#include "kys_type.h"
#include <cstdlib>

int GameRandom()
{
    if (!Headless())
    {
        return std::rand();
    }
    HeadlessRandomState = HeadlessRandomState * 1664525u + 1013904223u;
    return static_cast<int>(HeadlessRandomState >> 1);
}

int ScreenWidth() { return screen ? screen->w : CENTER_X * 2; }
int ScreenHeight() { return screen ? screen->h : CENTER_Y * 2; }
