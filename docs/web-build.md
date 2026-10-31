# 本地苍龙网页构建

`web/build.ps1` 默认以 **`work/kys-dragon/`** 为完整游戏资源来源，输出到
`web/dist/`。`work/` 和 `web/dist/` 均被 Git 忽略；代码、脚本与本文档可以提交，
游戏数据、生成图片与源稿不提交。

```text
work/
  kys-dragon/
    kysmod.ini
    resource/
      title-menu.webp
      open.png
      kdef.idx
      kdef.grp
      ...
    save/          # ranger.idx、ranger.grp、allsin.grp、alldef.grp 模板
    cc/
    fight/
    head/
    list/
    music/
    sound/
  art/kys-dragon/
    title-menu-source.webp
    title-menu.prompt.txt
  kys-dragon-source.json
```

## 数据来源

当前本地树从较早的 `tmp/runtime/kys-Dragon` 建立，**没有使用已修复事件的
golden 数据作为基底**。`resource/kdef.idx`、`resource/kdef.grp` 和四个初始
存档模板逐字节保留较早版本；不复制该目录里的玩家存档或 Lua 脚本。
这个版本不包含修复版数据的剧情改动。

旧 runtime 依赖共享资源，所以另外补齐了七个支持文件：四个 `cc/*.txt`、
`resource/chinese.ttf`、`resource/eng.ttf` 和 `music/mid.sf2`。这些文件来自已有
资源副本，未从该副本取事件或存档。各文件来源与初始化哈希记录在本地的
`work/kys-dragon-source.json`。

`kysmod.ini` 追加 `[rules] profile=dragon_dos12`，默认 `growth_mode=original`、
`growth_max_priority=stats`。它控制引擎规则，不修改事件数据。

后续直接编辑 `work/kys-dragon`。构建不会重新复制 runtime、同步 golden、
下载资源或自动修复事件。目录不存在时会报错；在其他机器上需要自行准备这份
完整资源树。也可通过 `-GameData <目录>` 显式选择另一棵完整资源树。

## 书法菜单图片

`resource/title-menu.webp` 是 **quality 80** 的透明 WebP，含三个 672 × 160
像素的横排，依次为「重新開始」「載入進度」「離開遊戲」。每行按 84 × 20
逻辑像素显示；网页渲染器保留 8 倍源分辨率用于实际显示。
普通和选中状态对同一笔迹着色，保持两种状态的轮廓一致。

选用的源稿由内置图像生成工具生成，采用有粗细变化、收锋和少量飞白的毛笔字。
原始生成提示保存在 `work/art/kys-dragon/title-menu.prompt.txt`；源稿留作重制母版，
不会打包到游戏中。重新裁切、缩放并编码运行时图片：

```powershell
python tools/prepare_title_menu.py work/art/kys-dragon/title-menu-source.webp work/kys-dragon/resource/title-menu.webp
```

打包器仅从传入的游戏目录读取资源，不再从 `web/assets` 注入图片。
已有 WebP 直接打包；其他独立 PNG 按 quality 80 转为 WebP，保留透明通道。
解码器按内容识别格式，因此这类 PNG 的游戏内路径仍保持原名。

## 构建

在仓库根目录执行完整构建：

```powershell
./web/build.ps1
```

依赖路径沿用脚本中的本地默认值，也可通过 `-EmsdkRoot`、`-WasmDeps`、
`-MlccDir`、`-VcpkgRoot` 指定。Python 依赖见 `web/requirements.txt`。

只改本地图片或数据、已有 JS/Wasm 时，可跳过编译和工具链准备：

```powershell
./web/build.ps1 -PackageOnly
```

该命令同样默认读取 `work/kys-dragon`。每次打包重新生成带内容哈希的资源包与
清单；浏览器刷新后加载新版本，已有 IndexedDB 玩家存档继续保留。
