unit kys_type;

//{$MODE delphi}

interface

uses
  SDL,
  SDL_TTF,
  bass,
  bassmidi,
  Classes,
  lua52;

type
  TPosition = record
    x, y: integer;
  end;

  TItemList = record
    Number, Amount: smallint;
  end;

  TPInt1 = procedure(i: integer);

  PPSDL_Surface = ^PSDL_Surface;

  TPNGIndex = record
    Num, Frame, x, y, Loaded, UseGRP: smallint;
    CurPointer: PPSDL_Surface;
  end;

  TPNGIndexArray = array of TPNGIndex;

  TSurfaceArray = array of PSDL_Surface;

  TIntArray = array of integer;
  TByteArray = array of byte;

  {TRole = TRoleRedFace;
  TItem = TItemRedFace;
  TMagic = TMagicRedFace;
  TWarData = TWarDataRedFace;}

  //以下所有类型均有两种引用方式: 按照别名引用, 按照短整数数组引用
  //在该文件中定义不同MOD中的数据类型, main文件中指定
  TCallType = (Element, Address);

  TRole = record
    case TCallType of
      Element: (ListNum, HeadNum, IncLife, UnUse: smallint;
        Name, Nick: array[0..9] of char;
        Sexual, Level: smallint;
        Exp: word;
        CurrentHP, MaxHP, Hurt, Poison, PhyPower: smallint;
        ExpForItem: word;
        Equip: array[0..1] of smallint;
        AmiFrameNum, AmiDelay, SoundDealy: array[0..4] of smallint;
        MPType, CurrentMP, MaxMP: smallint;
        Attack, Speed, Defence, Medcine, UsePoi, MedPoi, DefPoi, Fist, Sword, Knife, Unusual, HidWeapon: smallint;
        Knowledge, Ethics, AttPoi, AttTwice, Repute, Aptitude, PracticeBook: smallint;
        ExpForBook: word;
        Magic, MagLevel: array[0..9] of smallint;
        TakingItem, TakingItemAmount: array[0..3] of smallint);
      Address: (Data: array[0..90] of smallint);
  end;

  TItem = record
    case TCallType of
      Element: (ListNum: smallint;
        Name, Name1: array[0..19] of char;
        Introduction: array[0..29] of char;
        Magic, AmiNum, User, EquipType, ShowIntro, ItemType, UnKnow5, UnKnow6, UnKnow7: smallint;
        AddCurrentHP, AddMaxHP, AddPoi, AddPhyPower, ChangeMPType, AddCurrentMP, AddMaxMP: smallint;
        AddAttack, AddSpeed, AddDefence, AddMedcine, AddUsePoi, AddMedPoi, AddDefPoi: smallint;
        AddFist, AddSword, AddKnife, AddUnusual, AddHidWeapon, AddKnowledge, AddEthics,
        AddAttTwice, AddAttPoi: smallint;
        OnlyPracRole, NeedMPType, NeedMP, NeedAttack, NeedSpeed, NeedUsePoi, NeedMedcine, NeedMedPoi: smallint;
        NeedFist, NeedSword, NeedKnife, NeedUnusual, NeedHidWeapon, NeedAptitude: smallint;
        NeedExp, NeedExpForItem, NeedMaterial: smallint;
        GetItem, NeedMatAmount: array[0..4] of smallint);
      Address: (Data: array[0..94] of smallint);
  end;

  TScence = record
    case TCallType of
      Element: (ListNum: smallint;
        Name: array[0..9] of char;
        ExitMusic, EntranceMusic: smallint;
        JumpScence, EnCondition: smallint;
        MainEntranceY1, MainEntranceX1, MainEntranceY2, MainEntranceX2: smallint;
        EntranceY, EntranceX: smallint;
        ExitY, ExitX: array[0..2] of smallint;
        JumpY1, JumpX1, JumpY2, JumpX2: smallint);
      Address: (Data: array[0..25] of smallint);
  end;

  TMagic = record
    case TCallType of
      Element: (ListNum: smallint;
        Name: array[0..9] of char;
        UnKnow: array[0..4] of smallint;
        SoundNum, MagicType, AmiNum, HurtType, AttAreaType, NeedMP, Poison: smallint;
        Attack, MoveDistance, AttDistance, AddMP, HurtMP: array[0..9] of smallint);
      Address: (Data: array[0..67] of smallint);
  end;

  TShop = record
    case TCallType of
      Element: (Item, Amount, Price: array[0..4] of smallint);
      Address: (Data: array[0..14] of smallint);
  end;

  TBattleRole = record
    case TCallType of
      Element: (rnum, Team, Y, X, Face, Dead, Step, Acted: smallint;
        Pic, ShowNumber, UnUse1, UnUse2, UnUse3, ExpGot, Auto: smallint;
        RealSpeed, RealProgress, BHead, AutoMode: smallint);
      Address: (Data: array[0..18] of smallint);
  end;

  TCol = record
    r, g, b: byte;
  end;

  TCloud = record
    Picnum: integer;
    Shadow: integer;
    Alpha: integer;
    mixColor: uint32;
    mixAlpha: integer;
    Positionx, Positiony, Speedx, Speedy: integer;
  end;

  TWarData = record
    case TCallType of
      Element: (Warnum: smallint;
        Name: array[0..9] of char;
        BFieldNum, ExpGot, MusicNum: smallint;
        TeamMate, AutoTeamMate, TeamY, TeamX: array[0..5] of smallint;
        Enemy, EnemyY, EnemyX: array[0..19] of smallint);
      Address: (Data: array[0..$5C] of smallint);
  end;

  TRoleRedFace = record
    case TCallType of
      Element: (ListNum, HeadNum, IncLife, UnUse: smallint;
        Name, Nick: array[0..9] of char;
        Sexual, Level: smallint;
        Exp: word;
        CurrentHP, MaxHP, Hurt, Poison, PhyPower: smallint;
        ExpForItem: word;
        Equip: array[0..1] of smallint;
        AmiFrameNum, AmiDelay, SoundDealy: array[0..4] of smallint;
        MPType, CurrentMP, MaxMP: smallint;
        Attack, Speed, Defence, Medcine, UsePoi, MedPoi, DefPoi, Fist, Sword, Knife, Unusual, HidWeapon: smallint;
        Knowledge, Ethics, AttPoi, AttTwice, Repute, Aptitude, PracticeBook: smallint;
        ExpForBook: word;
        //Magic, MagLevel: array[0..9] of smallint;
        Magic, MagLevel: array[0..39] of smallint;
        TakingItem, TakingItemAmount: array[0..3] of smallint;
        UnKnow: array[0..9] of smallint);
      Address: (Data: array[0..160] of smallint);
  end;

  TItemRedFace = record
    case TCallType of
      Element: (//ListNum: smallint;
        Name: array[0..19] of char;
        Introduction: array[0..29] of char;
        Magic, AmiNum, User, EquipType, ShowIntro, ItemType, UnKnow5, UnKnow6, UnKnow7: smallint;
        AddCurrentHP, AddMaxHP, AddPoi, AddPhyPower, ChangeMPType, AddCurrentMP, AddMaxMP: smallint;
        AddAttack, AddSpeed, AddDefence, AddMedcine, AddUsePoi, AddMedPoi, AddDefPoi: smallint;
        AddFist, AddSword, AddKnife, AddUnusual, AddHidWeapon, AddKnowledge, AddEthics,
        AddAttTwice, AddAttPoi: smallint;
        OnlyPracRole, NeedMPType, NeedMP, NeedAttack, NeedSpeed, NeedUsePoi, NeedMedcine, NeedMedPoi: smallint;
        NeedFist, NeedSword, NeedKnife, NeedUnusual, NeedHidWeapon, NeedAptitude: smallint;
        NeedExp, NeedExpForItem, NeedMaterial: smallint;
        GetItem, NeedMatAmount: array[0..4] of smallint;
        Unkown: array[0..10] of smallint);
      Address: (Data: array[11..105] of smallint);
  end;

  TMagicRedFace = record
    case TCallType of
      Element: (//ListNum: smallint;
        Name: array[0..9] of char;
        UnKnow: array[0..4] of smallint;
        SoundNum, MagicType, AmiNum, HurtType, AttAreaType, NeedMP, Poison: smallint;
        Attack, MoveDistance, AttDistance, AddMP, HurtMP: array[0..9] of smallint;
        UnKnow1: array[0..20] of smallint);
      Address: (Data: array[0..67] of smallint);
  end;

  TWarDataRedFace = record
    case TCallType of
      Element: (Warnum: smallint;
        Name: array[0..9] of char;
        BFieldNum, ExpGot, MusicNum: smallint;
        //TeamMate, TeamY, TeamX: array [0..11] of smallint;
        //AutoTeamMate, AutoTeamY, AutoTeamX: array [0..29] of smallint;
        AutoTeamMate, AutoTeamY, AutoTeamX: array[0..11] of smallint;
        TeamMate, TeamY, TeamX: array[0..29] of smallint;
        Enemy, EnemyY, EnemyX: array[0..99] of smallint);
      Address: (Data: array[0..$5D] of smallint);
  end;

var

  MODVersion: integer = 0;
  //0-原版,
  //11-小猪闯江湖, 12-苍龙逐日, 13-金庸水浒传(未包含)
  //21-天书奇侠, 22-菠萝三国(含资料片), 23-笑梦游记, 24-前传(未包含)
  //31-再战江湖,
  //41-PTT
  //51-魏征
  //62-红颜录解密

  //初始值
  TitleString: string;

  CHINESE_FONT: PAnsiChar = 'resource/chinese.ttf';
  CHINESE_FONT_SIZE: integer = 20;
  ENGLISH_FONT: PAnsiChar = 'resource/eng.ttf';
  ENGLISH_FONT_SIZE: integer = 19;

  CENTER_X: integer = 320;
  CENTER_Y: integer = 220;

  AppPath: string; //程序的路径

  //游戏本身的常量
  //以下为常数表, 其中多数可以由ini文件改变

  ITEM_BEGIN_PIC: integer = 3501; //物品起始图片
  BEGIN_EVENT: integer = 691; //初始事件
  BEGIN_SCENCE: integer = 70; //初始场景
  BEGIN_Sx: integer = 20; //初始坐标
  //程序中的x, y与修改器所见是相反的, 所有游戏数据均是先Y后X, 这样在读取主地图时可以在直接读文件后用先x后y的情况引用
  //实际上无论怎样定义都会造成在一部分情况必须是先y后x, 这与计算机中矩阵的存储顺序有关
  //这里使用的顺序是类似数学中的右旋坐标系而非计算机中的左旋坐标系
  BEGIN_Sy: integer = 19; //初始坐标
  SOFTSTAR_BEGIN_TALK: integer = 2547; //软体娃娃对话的开始编号
  SOFTSTAR_NUM_TALK: integer = 18; //软体娃娃的对话数量
  MAX_PHYSICAL_POWER: integer = 100; //最大体力
  MONEY_ID: integer = 174; //银两的物品代码
  COMPASS_ID: integer = 182; //罗盘的物品代码
  BEGIN_LEAVE_EVENT: integer = 950; //起始离队事件
  BEGIN_BATTLE_ROLE_PIC: integer = 2553; //人物起始战斗贴图
  MAX_LEVEL: integer = 30; //最大等级
  MAX_WEAPON_MATCH: integer = 7; //'武功武器配合'组合的数量
  MIN_KNOWLEDGE: integer = 80; //最低有效武学常识
  MAX_ITEM_AMOUNT: integer = 200; //最大物品数量
  MAX_HP: integer = 999; //最大生命
  MAX_MP: integer = 999; //最大内功
  MaxProList: array[43..58] of integer = (100, 100, 100, 100, 100, 100, 100, 100, 100, 100,
    100, 100, 100, 100, 100, 1);
  //最大攻击值~最大左右互博值
  LIFE_HURT: integer = 10; //伤害值比例
  POISON_HURT: integer = 10; //中毒损血比例
  MED_LIFE: integer = 4; //医疗增加生命比例
  MAX_ADD_PRO: integer = 0; //是否升级最大化攻击属性
  //以下3个常数实际并未使用, 不能由ini文件指定
  NOVEL_BOOK: integer = 144; //天书起始编码(因偷懒并未使用)
  MAX_HEAD_NUM: integer = 189; //有专有头像的最大人物编号, 仅用于对话指令
  BEGIN_WALKPIC: integer = 2501; //场景内行走贴图起始值


  //游戏数据
  ACol: array[0..768] of byte;
  ACol1: array[0..768] of byte;
  ACol2: array[0..768] of byte;
  //默认调色板数据, 第一个色调及顺序变化, 第二个仅色调变化, 第三个不可变

  Earth, Surface, Building, BuildX, BuildY, Entrance: array[0..479, 0..479] of smallint;
  //主地图数据
  InShip, Useless1, Mx, My, Sx, Sy, MFace, ShipX, ShipY, ShipX1, ShipY1, ShipFace: smallint;
  TeamList: array[0..5] of smallint;
  RItemList: array of TItemList;
  Rrole: array[0..2031] of TRole;
  Ritem: array[0..724] of TItem;
  Rscence: array[0..200] of TScence;
  Rmagic: array[0..998] of TMagic;
  RShop: array[0..10] of TShop;
  //R文件数据, 均远大于原有容量

  SData: array[0..400, 0..5, 0..63, 0..63] of smallint;
  DData: array[0..400, 0..199, 0..10] of smallint;
  //S, D文件数据
  //Scence1, SData[CurScence, 1, , Scence3, Scence4, Scence5, Scence6, Scence7, Scence8: array[0..63, 0..63] of smallint;
  //当前场景数据
  //0-地面, 1-建筑, 2-物品, 3-事件, 4-建筑高度, 5-物品高度

  BField: array[0..7, 0..63, 0..63] of smallint;
  //战场数据
  //0-地面, 1-建筑, 2-人物, 3-可否被选中, 4-攻击范围, 5, 6 ,7-未使用
  //补充 6-标记第一次移动时不能到达的位置 7-标记敌人身边
  //WarSta: array[0..$5D] of smallint;
  WarSta: TWarData;
  //战场数据, 即war.sta文件的映像

  LeaveList: array[0..99] of smallint;
  EffectList: array[0..199] of smallint;
  LevelUpList: array[0..99] of smallint;
  MatchList: array[0..99, 0..2] of smallint;
  //各类列表, 前四个从文件读入


  //SDL使用的主要数据
  event: TSDL_Event;
  //事件
  Font, EngFont: PTTF_Font;
  //字体

  //视频部分设置
  PNG_TILE: integer = 1; //使用PNG贴图
  TRY_FIND_GRP: integer = 1; //当找不到PNG贴图时, 会试图寻找GRP中的图
  BIG_PNG_TILE: integer = 0;
  FULLSCREEN: integer; //是否全屏
  RESOLUTIONX, RESOLUTIONY: integer;
  HARDWARE_BLIT: integer; //是否使用硬件绘图
  GLHR: integer = 1; //是否使用OPENGL拉伸
  SMOOTH: integer = 1; //平滑设置 0-完全不平滑, 1-仅标准分辨率不平滑, 2-任何时候都使用平滑
  GL_TEXTURE: integer = 0; //全部使用gl纹理, 仅在使用png贴图时有效

  ScreenFlag: uint32;
  screen, prescreen, freshscreen, RealScreen: PSDL_Surface;
  //主画面, 手动双缓冲画面, 用于菜单/事件中快速重画的画面, 实际屏幕
  ImgScence, ImgScenceBack, ImgBField, ImgBBuild: PSDL_Surface;
  //重画场景和战场的图形映像. 实时重画场景效率较低, 故首先生成映像, 需要时载入
  //Img1在场景中用于副线程动态效果, Img2在战场用于仅保存建筑层以方便快速载入
  BlockImg, BlockImg2: array of smallint;
  BlockScreen: TPosition;
  //场景和战场的遮挡信息, 前者不会记录地板数据, 该值实际由绘图顺序决定

  MPicAmount, SPicAmount, BPicAmount, EPicAmount, CPicAmount, FPicAmount, HPicAmount: integer;

  //以下是各类贴图内容与索引
  //云的贴图内容及索引
  MPic, SPic, WPic, EPic, FPic, HPic, CPic, KDef, TDef: TByteArray;
  MIdx, SIdx, WIdx, EIdx, Fidx, HIdx, CIdx, KIdx, TIdx: TIntArray;

  MPNGTile: TSurfaceArray;
  SPNGTile: TSurfaceArray;
  BPNGTile: TSurfaceArray;
  EPNGTile: TSurfaceArray;
  CPNGTile: TSurfaceArray;
  TitlePNGTile: TSurfaceArray;
  FPNGTile: array of TSurfaceArray;

  MPNGIndex: TPNGIndexArray;
  SPNGIndex: TPNGIndexArray;
  BPNGIndex: TPNGIndexArray;
  EPNGIndex: TPNGIndexArray;
  CPNGIndex: TPNGIndexArray;
  TitlePNGIndex: TPNGIndexArray;
  FPNGIndex: array of TPNGIndexArray;

  MSurface: PSDL_Surface;
  SSurface: PSDL_Surface;
  BHead: array of PSDL_Surface; //半即时用于画头像

  //音频部分设置
  VOLUME, VOLUMEWAV, SOUND3D: integer; //音乐音量 音效音量 是否启用3D音效
  SoundFlag: longword;

  Music: array of HSTREAM;
  ESound: array of HSAMPLE;
  ASound: array of HSAMPLE;

  StartMusic: integer;
  ExitScenceMusicNum: integer; //离开场景的音乐
  nowmusic: integer = -1; //正在播放的音乐
  //MusicName: string;


  //事件和脚本部分
  x50: array[-$8000..$7FFF] of smallint;
  //扩充指令50所使用的变量
  KDEF_SCRIPT: integer = 0; //使用脚本处理事件
  lua_script: Plua_state; //lua脚本
  CurScenceRolePic: integer; //主角场景内当前贴图编号, 引入该常量主要用途是25指令事件号为-1的情况
  NeedRefreshScence: integer = 1; //是否需要刷新场景, 用于事件中和副线程


  //游戏体验设置
  CLOUD_AMOUNT: integer = 60; //云的数量
  Cloud: array of TCloud;

  WALK_SPEED, WALK_SPEED2, BATTLE_SPEED: integer; //行走时的主延时, 如果觉得行走速度慢可以修改这里.
  MMAPAMI: integer; //主地图动态效果
  SCENCEAMI: integer; //场景内动态效果的处理方式: 0-关闭, 1-打开, 2-用另一线程处理, 当明显内场景速度拖慢时可以尝试2
  //updating screen should be in main thread, so this is too complicable.
  SEMIREAL: integer = 0; //半即時
  NIGHT_EFFECT: integer = 0; //是否使用白昼和黑夜效果
  EXIT_GAME: integer = 1; //退出时的提问方式

  //其他
  mutex: PSDL_Mutex;
  ChangeColorList: array[0..1, 0..20] of uint32; //替换色表, 无用
  AskingQuit: boolean = False; //是否正在提问退出
  begin_time: integer; //游戏开始时间, 单位为分钟, 0~1439
  now_time: real;
  LoadingScence: boolean = False; //是否正在载入场景

  //游戏开场时的设置
  TitlePosition: TPosition;
  OpenPicPosition: TPosition;


  //游戏内部运行时使用的数据
  MStep, Still: integer;
  //主地图步数, 是否处于静止
  Cx, Cy, SFace, SStep: integer;
  //场景内坐标, 场景中心点, 方向, 步数
  CurScence, CurEvent, CurItem, CurrentBattle, Where: integer;
  //当前场景, 事件(在场景中的事件号), 使用物品, 战斗
  //where: 0-主地图, 1-场景, 2-战场, 3-开头画面
  SaveNum: integer;
  //存档号, 未使用
  Brole: array[0..99] of TBattleRole;
  //战场人物属性
  //0-人物序号, 1-敌我, 2, 3-坐标, 4-面对方向, 5-是否仍在战场, 6-可移动步数, 7-是否行动完毕,
  //8-贴图(未使用), 9-头上显示数字, 10, 11, 12-未使用, 13-已获得经验, 14-是否自动战斗
  BRoleAmount: integer;
  //战场人物总数
  //AutoMode: array of integer;
  Bx, By, Ax, Ay: integer;
  //当前人物坐标, 选择目标的坐标
  Bstatus: integer;
  //战斗状态, 0-继续, 1-胜利, 2-失败

  //寻路使用的变量表
  linex, liney: array[0..480 * 480 - 1] of smallint;
  nowstep: integer;
  Fway: array[0..479, 0..479] of integer;

  ItemList: array[0..500] of smallint; //物品显示使用的列表

  //RegionRect: TSDL_Rect; //全局重画范围, 无用
  RMask, GMask, BMask, AMask: uint32; //色值蒙版, 注意透明蒙版在创建RGB表面时需设为0

  EXPAND_GROUND: integer = 1;
  ExGround: array[-64..127, -64..127] of smallint;  //用来使场景边缘的显示效果改善
  ImageWidth, ImageHeight: smallint;

implementation

end.
