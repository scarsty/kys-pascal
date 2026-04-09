// main.cpp - 程序入口
// 对应 kys.lpr

#include "kys_main.h"
#include "kys_type.h"
#include <cstdlib>
#include <cstring>

#include "SDL3/SDL_main.h"

int main(int argc, char* argv[])
{
    (void)argv;
    if (argc == 2)
    {
        CellPhone = 1;
    }
    Run();
    return 0;
}
