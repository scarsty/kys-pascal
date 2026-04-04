// main.cpp - 程序入口
// 对应 kys.lpr

#include "kys_main.h"
#include <cstdlib>
#include <cstring>

extern int AutoLoadSave;

int main(int argc, char* argv[]) {
    // --autoload N : 自动读取进度N (1-11) 并进入游戏
    for (int i = 1; i < argc - 1; i++) {
        if (strcmp(argv[i], "--autoload") == 0) {
            AutoLoadSave = atoi(argv[i + 1]);
            break;
        }
    }
    Run();
    return 0;
}
