// main.cpp - 程序入口
// 对应 kys.lpr

#include "kys_main.h"
#include <cstdlib>
#include <cstring>

#include "SDL3/SDL_main.h"

extern "C" int Run(int argc, char* argv[])
{
    (void)argc;
    (void)argv;
    ::Run();
    return 0;
}

int main(int argc, char* argv[])
{
    (void)argc;
    (void)argv;
    Run();
    return 0;
}
