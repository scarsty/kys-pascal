# 《金庸群侠传》复刻版
<img src='https://raw.githubusercontent.com/scarsty/kys-pascal/master/open.png' />

<img src='https://raw.githubusercontent.com/scarsty/kys-pascal/master/2.png' />

原DOS下面的经典游戏《金庸群侠传》pascal复刻版。

通过改变工作目录的方式，可以运行大部分MOD。

## 如何编译
SDL3的pas文件请从<https://github.com/PascalGameDevelopment/SDL3-for-Pascal>获取。其他外部库的文件均已经自带。

首先下载游戏本体，其中包含了Windows版本的exe文件和dll文件以及资源文件：<https://pan.baidu.com/s/1nv9R5rz>。

注意大部分是商业性质的素材，禁止使用其盈利。

安装Lazarus，如果你对命令行熟悉可以只安装fpc，推荐使用最新版。CodeTyphon也可以。

使用Delphi社区版也可以编译，但不推荐。

不在Windows下面编译则需要安装运行库，用brew（Mac），apt-get（Ubuntu）之类安装sdl3，sdl3-ttf，sdl3-image，lua等相关sdl库。
如果lua库不能自动安装，则需要自己编译。

检查lua52.pas的开头部分指定的库文件名字，如果与现有的不同则修改。

已包含Android的工程。

sdl-mixer早期版本存在导致程序崩溃的bug，在最新版中似乎已经修复，但仍存在不少小的bug，故这里使用bass作为音频库。

## 字符串的处理

Delphi和Free Pascal对宽字符串和可变长度字符串的赋值处理不同，为了二者的行为一致，进行了一次清理。

即显示时仅使用utf-8，存档维持Big5编码。不再使用widestring和widechar。

## 关于Android版本

使用CodeTyphon来配置交叉编译器比较简单，除此之外，还需下载对应系统的运行库，供链接时使用。

在Android目录里包含一个批处理文件，在安装了Android Studio和CodeTyphon后可以用于编译出so文件和打包apk。

SDL一般是在java部分调用SDL_main这个函数，可以查找以下两个部分，修改对应的地方即可。

```java
    protected String getMainFunction() {
        return "Run";    //原为SDL_main
    }

    protected String[] getLibraries() {
        return new String[] {
            "SDL3",
            ///...
            "kys"    //原为main
        };
    }
```

## 注意

除了用于怀旧和运行较老的mod之外，均不建议使用。

很多设计现在来看很冗余，因此也不推荐深入研究此源码。

建议改用c++版：<https://github.com/scarsty/kys-cpp>。


