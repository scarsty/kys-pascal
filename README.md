#用Object Pascal和SDL实现的DOS游戏《金庸群侠传》的重制版。
#如何编译
首先在Downloads部分下载游戏本体，其中包含了源代码，Windows版本的exe文件和dll文件，可以直接运行。使用Lazarus可以直接编译。但是压缩包中的源码一般会比较旧，最新的需要用svn来获取。

安装fpc（任何方法均可），如果你对命令行熟悉可以不安装Lazarus，我推荐安装。

不在Windows下面编译则需要安装运行库，用brew（Mac），apt-get（Ubuntu）之类安装sdl，sdl-mixer，sdl-ttf，sdl-image，smpeg，lua等相关sdl库。

如果lua库不能自动安装5.2版，下载lua5.2库自行编译，需要编译成支持i386的库。

检查lua52的开头部分指定的库文件名字，如果与现有的不同则修改。

在Windows，Mac，Ubuntu（我目前只试过这个Linux发行版）下面，库文件配置正确时，均可以用fpc直接编译通过。

#注意
因为衍生版本《金庸水浒传》代码的完备程度已经超过这个版本，故本工程暂时停止更新。
