# 《金庸群侠传》pascal复刻版
<img src='https://raw.githubusercontent.com/scarsty/kys-pascal/master/open.png' />

<img src='https://raw.githubusercontent.com/scarsty/kys-pascal/master/2.png' />

原DOS下面的经典游戏《金庸群侠传》pascal复刻版。

通过改变工作目录的方式，可以运行大部分MOD。

## cpp版本

**为区别于全新的kys-cpp，本项目的AI移植版命名为kys-pascal-c。**

因为还是有老玩家有兴趣玩这些古老的MOD，但是pascal确实太不方便了，所以就有了用AI翻译一个cpp版本的想法。

与后来发布的全新的kys-cpp不同，这个版本只是AI按照1:1的方式将pascal代码转换成c++。所以可以认为相当于C+class+stl，基本是面向过程的代码组织，没有使用什么设计模式。除了怀旧，也不建议研究。

目前所有流程都已经完成，基本可以正常游戏，也可以支持50指令，可能有潜在bug。

如果你真的想研究一些金庸群侠传MOD的技术，我仍旧推荐你去研究kys-cpp，因为它的设计更合理，代码更清晰，性能更好。

就本工程而言，cpp的工具链更完备，所以如果以后要加新功能，会在cpp版本上进行开发。如果发现了功能缺失，也可以让AI很快地移植过来。

## 如何编译

### 资源文件

首先下载游戏本体，其中包含了Windows版本的exe文件和dll文件以及资源文件：<https://pan.baidu.com/s/1nv9R5rz>。

注意大部分是商业性质的素材，禁止使用其盈利。

### pascal版本

SDL3的pas文件请从<https://github.com/PascalGameDevelopment/SDL3-for-Pascal>获取。其他外部库的文件均已经自带。

安装Lazarus，如果你对命令行熟悉可以只安装fpc，推荐使用最新版。CodeTyphon也可以。

使用Delphi社区版也可以编译，但不推荐。

不在Windows下面编译则需要安装运行库，用brew（Mac），apt-get（Ubuntu）之类安装sdl3，sdl3-ttf，sdl3-mixer，lua等相关sdl库。
如果lua库不能自动安装，则需要自己编译。

检查lua52.pas的开头部分指定的库文件名字，如果与现有的不同则修改。

### 关于pascal版的Android版本

以下是配置指引，但是由于pascal的工具链不太完善，Lazarus的官方版的Android编辑非常复杂，用CodeTyphon也只简单一点点。除此之外，还需下载对应系统的运行库，供链接时使用。因此不再建议研究。

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

### cpp版本

建议使用Visual Studio打开sln文件直接编译，缺失的文件在作者的另一个项目mlcc里面。其他用到的开源库请使用vcpkg编译，或者从SDL的官网下载预编译版本。

因为使用到midi功能，SDL3-mixer可能需要自己加上fluidSynth的支持并编译，如需要播放mp3最好加上mpg123，建议使用vcpkg。


## 字符串的处理

在Delphi和Lazarus中默认的字符串编码不同，但是可以强制设置。故目前在pascal版本中和cpp版本中都强制设置为utf-8编码，

即显示时仅使用utf-8，存档和资源维持Big5编码。不再使用widestring和widechar。

## 注意

除了用于怀旧和运行较老的mod之外，均不建议使用。

很多设计现在来看很冗余，因此也不推荐深入研究此源码。

建议改用c++版：<https://github.com/scarsty/kys-cpp>。

## 关于feature/cpp-migration-fixes分支

基本全是AI将pascal代码转换成c++，名字都是AI自己起的。

目前完成的功能：

- 主地图和内景行走
- 对话
- 物品和状态的界面基本正常
- 剧情跑不通
- 不能正常开始新游戏
- 战斗能画出战场，操作不正常

但是由于AI喜欢使用各种设计模式，故代码可读性非常差。因此不建议研究这个分支，除非你想看看AI是怎么写代码的。后来的移植是要求AI不要增加任何设计模式的，所以移植比较顺利。让AI转语言还是比较容易的。


