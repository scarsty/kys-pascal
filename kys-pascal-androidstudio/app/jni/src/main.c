#include "SDL.h"
#include "kys_pig3.h"
#include <android/log.h>

int main(int args,char** argv)
{
    __android_log_print(ANDROID_LOG_INFO,"pascal", "%s", "running?");
    Run();
    return 0;
}
