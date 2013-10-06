unit kys_main;

//{$MODE Delphi}

{
 All Heros in Kam Yung's Stories - The Replicated Edition
 
 Created by S.weyl in 2008 May.
 No Copyright (C) reserved.
 
 You can build it by Delphi with JEDI-SDL support.
 
 This resouce code file which is not perfect so far,
 can be modified and rebuilt freely,
 or translate it to another programming language.
 But please keep this section when you want to spread a new vision. Thanks.
 Note: it must not be a good idea to use this as a pascal paradigm.

}

{
 任何人获得这份代码之后, 均可以自由增删功能, 重新
 编译, 或译为其他语言. 但请保留本段文字.
}

interface

uses
  SysUtils,
{$IFDEF fpc}
  LCLIntf, LCLType, LMessages, LConvEncoding, FileUtil,
{$ELSE}
  Windows,
{$ENDIF}
  Math,
  Dialogs,
  SDL,
  SDL_TTF,
  //SDL_mixer,
  SDL_image,
  iniFiles,
  Lua52,
  bass;
type

  TPosition = record
    x, y: integer;
  end;

  TRect = record
    x, y, w, h: integer;
  end;

  TPic = record
    x, y, black: integer;
    pic: psdl_surface;
  end;

  TItemList = record
    Number, Amount: smallint;
  end;

  TCloud = record
    Picnum: integer;
    Shadow: integer;
    Alpha: integer;
    MixColor: Uint32;
    MixAlpha: integer;
    Positionx, Positiony, Speedx, Speedy: integer;
  end;

  TCallType = (Element, Address);

  //以下所有类型均有两种引用方式：按照别名引用；按照短整数数组引用

  TRole = record
    case TCallType of
      Element: (ListNum, HeadNum, IncLife, UnUse: smallint;
        Name, Nick: array[0..9] of char;
        Sexual, Level: smallint;
        Exp: Uint16;
        CurrentHP, MaxHP, Hurt, Poision, PhyPower: smallint;
        ExpForItem: Uint16;
        Equip: array[0..4] of smallint;
        Gongti: smallint;
        TeamState: smallint;
        Angry: smallint;
        GongtiExam: Uint16;
        Moveable, AddSkillPoint, PetAmount: smallint;
        Impression, Reset, difficulty: smallint;
        SoundDealy: array[0..1] of smallint;
        MPType, CurrentMP, MaxMP: smallint;
        Attack, Speed, Defence, Medcine, UsePoi, MedPoi, DefPoi, Fist, Sword, Knife, Unusual, HidWeapon: smallint;
        Knowledge, Ethics, AttPoi, AttTwice, Repute, Aptitude, PracticeBook: smallint;
        ExpForBook: Uint16;
        Magic, MagLevel: array[0..9] of smallint;
        TakingItem, TakingItemAmount: array[0..3] of smallint);
      Address: (Data: array[0..90] of smallint);
  end;

  TItem = record
    case TCallType of
      Element: (ListNum: smallint;
        Name: array[0..19] of char;
        ExpOfMagic: smallint;
        SetNum, BattleEffect, WineEffect, needSex: smallint;
        unuse: array[0..4] of smallint;
        Introduction: array[0..29] of char;
        Magic, AmiNum, User, EquipType, ShowIntro, ItemType, inventory, price, EventNum: smallint;
        AddCurrentHP, AddMaxHP, AddPoi, AddPhyPower, ChangeMPType, AddCurrentMP, AddMaxMP: smallint;
        AddAttack, AddSpeed, AddDefence, AddMedcine, AddUsePoi, AddMedPoi, AddDefPoi: smallint;
        AddFist, AddSword, AddKnife, AddUnusual, AddHidWeapon, AddKnowledge, AddEthics,
        AddAttTwice, AddAttPoi: smallint;
        OnlyPracRole, NeedMPType, NeedMP, NeedAttack, NeedSpeed, NeedUsePoi, NeedMedcine, NeedMedPoi: smallint;
        NeedFist, NeedSword, NeedKnife, NeedUnusual, NeedHidWeapon, NeedAptitude: smallint;
        NeedExp, Count, Rate: smallint;
        NeedItem, NeedMatAmount: array[0..4] of smallint);
      Address: (Data: array[0..94] of smallint);
  end;

  TScene = record
    case TCallType of
      Element: (ListNum: smallint;
        Name: array[0..9] of char;
        ExitMusic, EntranceMusic: smallint;
        Pallet, EnCondition: smallint;
        MainEntranceY1, MainEntranceX1, MainEntranceY2, MainEntranceX2: smallint;
        EntranceY, EntranceX: smallint;
        ExitY, ExitX: array[0..2] of smallint;
        Mapmode, mapnum, useless3, useless4: smallint);
      Address: (Data: array[0..25] of smallint);
  end;

  TMagic = record
    case TCallType of
      Element: (ListNum: smallint;
        Name: array[0..9] of char;
        Useless, NeedHP, MinStep, bigami, EventNum: smallint;
        SoundNum, MagicType, AmiNum, HurtType, AttAreaType, NeedMP, Poision: smallint;
        MinHurt, MaxHurt, HurtModulus, AttackModulus, MPModulus, SpeedModulus, WeaponModulus,
        NeedProgress, AddMpScale, AddHpScale: smallint;
        MoveDistance, AttDistance: array[0..9] of smallint;
        AddHP, AddMP, AddAtt, AddDef, AddSpd: array[0..2] of smallint;
        MinPeg, MaxPeg, MinInjury, MaxInjury, AddMedcine, AddUsePoi, AddMedPoi, AddDefPoi: smallint;
        AddFist, AddSword, AddKnife, AddUnusual, AddHidWeapon, BattleState: smallint;
        NeedExp: array[0..2] of smallint;
        MaxLevel: smallint;
        Introduction: array[0..59] of char;);
      Address: (Data: array[0..110] of smallint);
  end;

  TShop = record
    case TCallType of
      Element: (Item: array[0..17] of smallint);
      Address: (Data: array[0..17] of smallint);
  end;

  TBattleRole = record
    case TCallType of
      Element: (rnum, Team, Y, X, Face, Dead, Step, Acted: smallint;
        Pic, ShowNumber, Progress, Round, speed: smallint;
        ExpGot, Auto, Show, wait, frozen, killed, Knowledge, LifeAdd: smallint;
        AddAtt, AddDef, AddSpd, AddStep, AddDodge, PerfectDodge: smallint);
      Address: (Data: array[0..26] of smallint);
  end;

  //战场数据, 即war.sta文件的映像
  TWarSta = record
    case TcallType of
      Element: (BattleNum: smallint;
        BattleName: array[0..9] of byte;
        battlemap, exp, battlemusic: smallint;
        mate, automate, mate_x, mate_y: array[0..11] of smallint;
        enemy, enemy_x, enemy_y: array[0..29] of smallint;
        BoutEvent, OperationEvent: smallint;
        GetKongfu: array[0..2] of smallint;
        GetItems: array[0..2] of smallint;
        GetMoney: smallint);
      Address: (Data: array[0..155] of smallint;)
  end;

  //各种战场特效
  TBRoleColor = record
    case tcalltype of
      Element: (green, red, yellow, blue, gray: integer;)
  end;



//程序重要子程
procedure Run;
procedure Quit;

//游戏开始画面, 行走等
procedure Start;
procedure StartAmi;
procedure ReadFiles;
function InitialRole: boolean;
procedure LoadR(num: integer);
procedure SaveR(num: integer);
function WaitAnyKey: integer; overload;
procedure WaitAnyKey(keycode, x, y: psmallint); overload;
procedure Walk;
function CanWalk(x, y: integer): boolean;
//procedure CheckEntrance;
function CheckEntrance: boolean;
function InScene(Open: integer): integer;
procedure ShowSceneName(snum: integer);
function CanWalkInScene(x, y: integer): boolean; overload;
function CanWalkInScene(x1, y1, x, y: integer): boolean; overload;
procedure CheckEvent3;
procedure ShowRandomAttribute(ran: boolean);
function RandomAttribute: boolean;
procedure ReSetEntrance;
function StadySkillMenu(x, y, w: integer): integer;

//选单子程
function CommonMenu(x, y, w, max: integer): integer; overload;
function CommonMenu(x, y, w, max, default: integer): integer; overload;
procedure ShowCommonMenu(x, y, w, max, menu: integer);
function CommonScrollMenu(x, y, w, max, maxshow: integer): integer;
procedure ShowCommonScrollMenu(x, y, w, max, maxshow, menu, menutop: integer);
function CommonMenu2(x, y, w: integer): integer;
procedure ShowCommonMenu2(x, y, w, menu: integer);
function SelectOneTeamMember(x, y: integer; str: string; list1, list2: integer): integer;
procedure MenuEsc;
procedure ShowMenu(menu: integer);
procedure MenuMedcine;
procedure MenuMedPoision;
function MenuItem(menu: integer): boolean;
function ReadItemList(ItemType: integer): integer;
procedure ShowMenuItem(row, col, x, y, atlu: integer);
procedure DrawItemFrame(x, y: integer);
procedure UseItem(inum: integer);
function CanEquip(rnum, inum: integer): boolean;
procedure MenuStatus;
procedure ShowStatus(rnum: integer);
//procedure MenuLeave;
procedure MenuSystem;
procedure ShowMenuSystem(menu: integer);
procedure MenuLoad;
function MenuLoadAtBeginning: boolean;
procedure MenuSave;
procedure MenuQuit;
procedure XorCount(Data: pbyte; xornum: byte; length: integer);
procedure MenuDifficult;
function TitleCommonScrollMenu(word: puint16; color1, color2: uint32; tx, ty, tw, max, maxshow: integer): integer;
procedure ShowTitleCommonScrollMenu(word: puint16; color1, color2: uint32;
  tx, ty, tw, max, maxshow, menu, menutop: integer);



//医疗, 解毒, 使用物品的效果等
procedure EffectMedcine(role1, role2: integer);
procedure EffectMedPoision(role1, role2: integer);
procedure EatOneItem(rnum, inum: integer);

//事件系统
procedure CallEvent(num: integer);
procedure ShowSaveSuccess;
procedure CheckHotkey(key: cardinal);
procedure FourPets;
function PetStatus(r: integer): boolean;
procedure ShowPetStatus(r, p: integer);
procedure DrawFrame(x, y, w: integer; color: Uint32);
procedure PetLearnSkill(r, s: integer);
procedure ResistTheater;
procedure ShowSkillMenu(menu: integer);

//云的初始化和再次出现
procedure CloudCreate(num: integer);
procedure CloudCreateOnSide(num: integer);



//以下用于与delphi兼容
{$IFDEF fpc}

{$ELSE}
function FileExistsUTF8(filename: PChar): boolean; overload;
function FileExistsUTF8(filename: string): boolean; overload;
function UTF8Decode(str: WideString): WideString;
{$ENDIF}


var
  HW: integer = 0;
  CHINESE_FONT: PAnsiChar = 'resource/Chinese.ttf';
  CHINESE_FONT_SIZE: integer = 20;
  ENGLISH_FONT: PAnsiChar = 'resource/English.ttf';
  ENGLISH_FONT_SIZE: integer = 18;
  CENTER_X: integer = 320;
  CENTER_Y: integer = 220;
  //文件名定义
  KDEF_IDX: PAnsiChar = 'resource/kdef.idx';
  KDEF_GRP: PAnsiChar = 'resource/kdef.grp';
  TALK_IDX: PAnsiChar = 'resource/talk.idx';
  TALK_GRP: PAnsiChar = 'resource/talk.grp';
  NAME_IDX: PAnsiChar = 'resource/name.idx';
  NAME_GRP: PAnsiChar = 'resource/name.grp';
  ITEMS_file: PAnsiChar = 'resource/items.Pic';
  HEADS_file: PAnsiChar = 'resource/heads.Pic';
  BackGround_file: PAnsiChar = 'resource/BackGround.Pic';
  GAME_file: PAnsiChar = 'resource/Game.Pic';
  MOVIE_file: PAnsiChar = 'resource/Begin.pic';
  Scene_file: PAnsiChar = 'resource/Scene.pic';
  Skill_file: PAnsiChar = 'resource/Skill.pic';
  //使用50指令时是否自动刷新屏幕，0为自动刷新
  AutoRefresh: integer = 0;

  //以下为常数表, 其中多数可以由ini文件改变
  ITEM_BEGIN_PIC: integer = 3501; //物品起始图片
  BEGIN_EVENT: integer = 691; //初始事件
  BEGIN_Scene: integer = 70; //初始场景
  BEGIN_Sx: integer = 20; //初始坐标(程序中的x, y与游戏中是相反的, 这是早期的遗留问题)
  BEGIN_Sy: integer = 19; //初始坐标
  SOFTSTAR_BEGIN_TALK: integer = 2547; //软体娃娃对话的开始编号
  SOFTSTAR_NUM_TALK: integer = 18; //软体娃娃的对话数量
  MAX_PHYSICAL_POWER: integer = 100; //最大体力
  MONEY_ID: integer = 0; //银两的物品代码
  COMPASS_ID: integer = 1; //罗盘的物品代码
  MAP_ID: integer = 303; //地图的物品代码
  BEGIN_LEAVE_EVENT: integer = 950; //起始离队事件
  BEGIN_BATTLE_ROLE_PIC: integer = 2553; //人物起始战斗贴图
  MAX_LEVEL: integer = 30; //最大等级
  MAX_WEAPON_MATCH: integer = 7; //'武功武器配合'组合的数量
  MIN_KNOWLEDGE: integer = 0; //最低有效武学常识
  MAX_ITEM_AMOUNT: integer = 300; //最大物品数量
  MAX_HP: integer = 999; //最大生命
  MAX_MP: integer = 999; //最大内功
  Showanimation: integer = 0;
  MaxProList: array[43..58] of integer = (200, 200, 200, 200, 200, 200, 200, 200, 200, 200,
    200, 200, 100, 100, 100, 1);
  //最大攻击值~最大左右互博值
  SoundVolume: integer = 32;
  LIFE_HURT: integer = 10; //伤害值比例
  Debug: integer = 0;
  //以下3个常数实际并未使用, 不能由ini文件指定
  BEGIN_WALKPIC: integer = 2500; //起始的行走贴图(并未使用)
  gametime: smallint = 0;
  Warsta: Twarsta;
  MPic, SPic, WPic: array of byte;
  MIdx, SIdx, WIdx: array of integer;
  // HPic: array[0..2000000] of byte;
  // HIdx: array[0..500] of integer;
  //以上为贴图的内容及索引
  Earth, Surface, Building, BuildX, BuildY, Entrance: array[0..479, 0..479] of smallint;
  //主地图数据
  ACol: array[0..768] of byte;
  Col: array[0..3] of array[0..767] of byte;
  //默认调色板数据
  InShip, Useless1, Mx, My, Sx, Sy, MFace, ShipX, ShipY, ShipFace: smallint;
  TeamList: array[0..5] of smallint;
  RItemList: array of TItemList;
  isbattle: boolean = False;
  MStep, Still: integer;
  //主地图坐标, 方向, 步数, 是否处于静止
  Cx, Cy, SFace, SStep: integer;
  //场景内坐标, 场景中心点, 方向, 步数
  CurScene, CurItem, CurEvent, CurMagic, CurrentBattle, Where: integer;
  //当前场景, 事件(在场景中的事件号), 使用物品, 战斗
  //where: 0-主地图, 1-场景, 2-战场, 3-开头画面
  SaveNum: integer;
  //存档号, 未使用
  RRole: array of TRole;
  RItem: array of TItem;
  RScene: array of TScene;
  RMagic: array of TMagic;
  RShop: array of TShop;
  //R文件数据, 均远大于原有容量
  ItemList: array[0..500] of smallint;
  SData: array of array[0..5, 0..63, 0..63] of smallint;
  DData: array of array[0..199, 0..10] of smallint;
  //S, D文件数据
  //Scene1, SData[CurScene, 1, , Scene3, Scene4, Scene5, Scene6, Scene7, Scene8: array[0..63, 0..63] of smallint;
  //当前场景数据
  //0-地面, 1-建筑, 2-物品, 3-事件, 4-建筑高度, 5-物品高度
  SceneImg: array[0..2303, 0..1151] of Uint32;
  MaskArray: array[0..2303, 0..1151] of byte;
  ScenePic: array of Tpic;
  build: psdl_surface;
  //场景的图形映像. 实时重画场景效率较低, 故首先生成映像, 需要时载入
  //SceneD: array[0..199, 0..10] of smallint;
  //当前场景事件
  BFieldImg: array[0..2303, 0..1151] of Uint32;
  //战场图形映像
  BField: array[0..7, 0..63, 0..63] of smallint;
  //战场数据
  //0-地面, 1-建筑, 2-人物, 3-可否被选中, 4-攻击范围, 5, 6 ,7-未使用
  BRole: array[0..41] of TBattleRole;
  //战场人物属性
  //0-人物序号, 1-敌我, 2, 3-坐标, 4-面对方向, 5-是否仍在战场, 6-可移动步数, 7-是否行动完毕,
  //8-贴图(未使用), 9-头上显示数字, 10, 11, 12-未使用, 13-已获得经验, 14-是否自动战斗
  BRoleAmount: integer;
  //战场人物总数
  Bx, By, Ax, Ay: integer;
  //当前人物坐标, 选择目标的坐标
  Bstatus: integer;
  //战斗状态, 0-继续, 1-胜利, 2-失败
  maxspeed: integer;
  //LeaveList: array[0..99] of smallint;
  //EffectList: array[0..199] of smallint;
  LevelUpList: array[0..99] of smallint;
  //MatchList: array[0..99, 0..2] of smallint;
  //各类列表, 前四个从文件读入
  Water: integer;
  //是否水下
  snow: integer;
  //是否飘雪
  rain: integer;
  //是否下雨
  fog: boolean;
  //是否有雾
  showblackscreen: boolean;
  //是否山洞
  snowalpha: array[0..439] of array[0..639] of byte;
  BattleMode: integer;
  fullscreen: integer;
  //是否全屏
  Simple: integer = 0;

  STATE_PIC, BEGIN_PIC, MAGIC_PIC, SYSTEM_PIC, MAP_PIC, SKILL_PIC: Tpic;
  MENUITEM_PIC, MENUESC_PIC, MenuescBack_PIC, battlepic, TEAMMATE_PIC: Tpic;
  PROGRESS_PIC, MATESIGN_PIC, SELECTEDMATE_PIC, ENEMYSIGN_PIC, SELECTEDENEMY_PIC, DEATH_PIC: Tpic;
  NowPROGRESS_PIC, angryprogress_pic, angrycollect_pic, angryfull_pic, Maker_Pic: Tpic;

  Head_Pic: array of Tpic;
  SkillPIC: array of Tpic;

  //option exp in snake
  snake: array of tposition;
  RANX, RANY: integer;
  dest: integer;


  ITEM_PIC: array of Tpic;
  screen, prescreen, realscreen: PSDL_Surface;
  //主画面
  event: TSDL_Event;
  //事件
  Font, EngFont: PTTF_Font;
  TextColor: TSDL_Color;
  Text: PSDL_Surface;
  //字体
  ExitSceneMusicNum: integer;
  //离开场景的音乐
  MusicName: string;

  MenuString, MenuEngString: array of WideString;
  //选单所使用的字符串

  x50: array[-$8000..$7FFF] of smallint;
  //扩充指令50所使用的变量
  lua_script: Plua_State;
  //游戏里的小游戏用到的数组
  GameArray: array of array of integer;
  GameSpeed: integer = 10;
  MusicVolume: integer = 64;
  //Music: array[0..99] of PMix_music;
  // ESound: array[0..99] of PMix_Chunk;
  // ASound: array[0..99] of PMix_Chunk;
  Music: array[0..109] of HSTREAM;
  ESound: array[0..186] of HSAMPLE;
  ASound: array[0..99] of HSAMPLE;
  nowmusic: integer;

  //战斗用变量
  CurBRole: integer; //当前战斗人物
  ShowMR: boolean = True;
  now2: uint32 = 0;
  time: smallint = -1;
  timeevent: smallint = -1;
  //定时、定时事件
  rs: integer = 0;
  //随机事件
  RandomEvent: smallint = 0;
  randomcount: integer = 0;
  Kys_ini: TIniFile;
  Effect: integer;
  HighLight: boolean = False; //高亮

  //暂存主角武功
  magicTemp: array[0..9] of smallint;
  magicLvTemp: array[0..9] of smallint;

  green: integer = 0;
  red: integer = 0;
  yellow: integer = 0;
  blue: integer = 0;
  gray: integer = 0;

  versionstr: string = '  demo   '; //版本号
  FWay: array[0..479, 0..479] of smallint;
  linex, liney: array[0..480 * 480 - 1] of smallint;
  nowstep: integer;
  SetNum: array[1..5] of array[0..3] of smallint;

  AppPath: string = '';
  RegionRect: TRect;

  CLOUD_AMOUNT: integer = 60; //云的数量
  Cloud: array of TCloud;

  CPic: array[0..100000] of byte;
  CIdx: array[0..20] of integer;

  GLHR: integer = 1; //是否使用OPENGL绘图
  SMOOTH: integer = 1; //平滑设置 0-完全不平滑, 1-仅标准分辨率不平滑, 2-任何时候都使用平滑
  ScreenFlag: Uint32;
  RESOLUTIONX: integer;
  RESOLUTIONY: integer;


implementation

uses kys_event, kys_battle, kys_littlegame, kys_engine, kys_script;




//初始化字体, 音效, 视频, 启动游戏

procedure Run;
var
  p, p1: PChar;
  title: string;
begin

{$IFDEF UNIX}
  AppPath := ExtractFilePath(ParamStr(0));
{$ELSE}
  AppPath := '';
{$ENDIF}
  ReadFiles;
  //初始化字体
  TTF_Init();
  font := TTF_OpenFont(PChar(AppPath + CHINESE_FONT), CHINESE_FONT_SIZE);
  engfont := TTF_OpenFont(PChar(AppPath + ENGLISH_FONT), ENGLISH_FONT_SIZE);
  if font = nil then
  begin
    MessageBox(0, PChar(Format('Error:%s!', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
    exit;
  end;

  //初始化音频系统

  //SDL_Init(SDL_INIT_AUDIO);
  //Mix_OpenAudio(MIX_DEFAULT_FREQUENCY, MIX_DEFAULT_FORMAT, 2, 8192);
  BASS_Init(-1, 22050, 0, 0, nil);
  InitialMusic;

  //初始化视频系统
  Randomize;
  if (SDL_Init(SDL_INIT_VIDEO) < 0) then
  begin
    MessageBox(0, PChar(Format('Couldn''t initialize SDL : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
    SDL_Quit;
    exit;
  end;

  //freemem(users[0],sizeof(uint16)*length(users));

  //freemem(user,sizeof(uint16));
  //showmessage(inttostr(RESOLUTIONX));

  SDL_WM_SetIcon(IMG_Load('resource/icon'), 0);
  title := 'The Story Before That Legend v1.22';

  SDL_WM_SetCaption(@title[1], 's.weyl, killer-G');

  InitialScript;

  ScreenFlag := SDL_SWSURFACE or SDL_RESIZABLE {or SDL_ANYFORMAT or SDL_ASYNCBLIT{or SDL_FULLSCREEN};
  if HW = 1 then ScreenFlag := ScreenFlag or SDL_HWSURFACE;
  if GLHR = 1 then
  begin
    ScreenFlag := SDL_OPENGL or SDL_RESIZABLE;
    SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
  end;

  if fullscreen = 0 then
    realscreen := SDL_SetVideoMode(RESOLUTIONX, RESOLUTIONY, 32, ScreenFlag)
  else
    realscreen := SDL_SetVideoMode(Center_X * 2, Center_Y * 2, 32, ScreenFlag or SDL_FULLSCREEN);
  if (realscreen = nil) then
  begin
    MessageBox(0, PChar(Format('Couldn''t set 640x480x8 video mode : %s', [SDL_GetError])),
      'Error', MB_OK or MB_ICONHAND);
    SDL_Quit;
    halt(1);
  end;

  screen := SDL_CreateRGBSurface(ScreenFlag, CENTER_X * 2, CENTER_Y * 2, 32, 0, 0, 0, 1);
  prescreen := SDL_CreateRGBSurface(ScreenFlag, CENTER_X * 2, CENTER_Y * 2, 32, 0, 0, 0, 1);

  start;

  DestroyScript;
  TTF_CloseFont(font);
  TTF_CloseFont(engfont);
  TTF_Quit;
  SDL_Quit;
  halt(1);
  exit;
end;

//关闭所有已打开的资源, 退出

procedure Quit;
begin
  DestroyScript;
  TTF_CloseFont(font);
  TTF_CloseFont(engfont);
  TTF_Quit;
  SDL_Quit;
  halt(1);
  exit;
end;

//开头字幕

procedure StartAmi;
var
  x, y, i, len: integer;
  str: WideString;
  p: integer;
begin
  instruct_14;
  drawrectanglewithoutframe(0, 0, screen.w, screen.h, 0, 100);
  ShowTitle(4545, 28515);
  drawrectanglewithoutframe(0, 0, screen.w, screen.h, 0, 100);
  ShowTitle(4546, 28515);
  instruct_14;
  //instruct_13;
end;

//读取必须的文件

procedure ReadFiles;
var
  grp, idx, tnum, len, c, i, i1, l: integer;
  filename, str: string;
  p: puint16;
  cc: uint16;
begin

{$IFDEF fpc}
  Filename := AppPath + 'kysmod.ini';
{$ELSE}
  Filename := ExtractFilePath(ParamStr(0)) + 'kysmod.ini';
{$ENDIF}

  Kys_ini := TIniFile.Create(filename);

  try

    BEGIN_BATTLE_ROLE_PIC := 1;
    BEGIN_EVENT := 101;
    BEGIN_Scene := 0;
    BEGIN_Sx := 40;
    BEGIN_Sy := 38;
    MAX_PHYSICAL_POWER := 100;
    BEGIN_WALKPIC := 2500;
    MONEY_ID := 0;
    COMPASS_ID := 1;
    MAX_LEVEL := 30;
    MAX_WEAPON_MATCH := 7;
    MIN_KNOWLEDGE := 0;
    MAX_HP := 9999;
    MAX_MP := 9999;
    LIFE_HURT := 10;
    MAP_ID := 303;
    MUSICVOLUME := Kys_ini.ReadInteger('constant', 'MUSIC_VOLUME', 64);
    SoundVolume := Kys_ini.ReadInteger('constant', 'SOUND_VOLUME', 32);
    MAX_ITEM_AMOUNT := 400;
    GAMESPEED := max(1, Kys_ini.ReadInteger('constant', 'GAME_SPEED', 10));
    Simple := Kys_ini.ReadInteger('Set', 'simple', 0);
    Showanimation := Kys_ini.ReadInteger('Set', 'animation', 0);
    Fullscreen := Kys_ini.ReadInteger('Set', 'fullscreen', 0);
    BattleMode := Kys_ini.ReadInteger('Set', 'BattleMode', 0);
    HW := Kys_ini.ReadInteger('Set', 'HW', 0);
    SMOOTH := Kys_ini.ReadInteger('set', 'SMOOTH', 1);
    GLHR := Kys_ini.ReadInteger('set', 'GLHR', 1);
    RESOLUTIONX := Kys_ini.ReadInteger('Set', 'RESOLUTIONX', 640);
    RESOLUTIONY := Kys_ini.ReadInteger('set', 'RESOLUTIONY', 440);
    str := Kys_ini.ReadString('Set', 'debug', '0');
    if (str = '我爱玩前传') or (str = 'I like to play Promise') then debug := 1 else debug := 0;


    MaxProList[58] := 1;
    setlength(ITEM_PIC, MAX_ITEM_AMOUNT);

  finally
    //Kys_ini.Free;
  end;
  //showmessage(booltostr(fileexists(filename)));
  //showmessage(inttostr(max_level));

  if (FileExistsUTF8(AppPath + 'resource/pallet.COL') { *Converted from FileExists*  }) then
  begin
    c := fileopen(AppPath + 'resource/pallet.COL', fmopenread);
    fileread(c, Col[0][0], 4 * 768);
    fileclose(c);
  end;

  resetpallet;
  idx := fileopen(AppPath + 'resource/mmap.idx', fmopenread);
  grp := fileopen(AppPath + 'resource/mmap.grp', fmopenread);
  len := fileseek(grp, 0, 2);
  fileseek(grp, 0, 0);
  setlength(mpic, len);
  fileread(grp, MPic[0], len);
  tnum := fileseek(idx, 0, 2) div 4;
  fileseek(idx, 0, 0);
  setlength(midx, tnum);
  fileread(idx, MIdx[0], tnum * 4);
  fileclose(grp);
  fileclose(idx);

  idx := fileopen(AppPath + 'resource/sdx', fmopenread);
  grp := fileopen(AppPath + 'resource/smp', fmopenread);
  len := fileseek(grp, 0, 2);
  fileseek(grp, 0, 0);
  setlength(spic, len);
  fileread(grp, SPic[0], len);
  tnum := fileseek(idx, 0, 2) div 4;
  fileseek(idx, 0, 0);
  setlength(sidx, tnum);
  fileread(idx, SIdx[0], tnum * 4);
  fileclose(grp);
  fileclose(idx);

  idx := fileopen(AppPath + 'resource/wdx', fmopenread);
  grp := fileopen(AppPath + 'resource/wmp', fmopenread);
  len := fileseek(grp, 0, 2);
  fileseek(grp, 0, 0);
  setlength(wpic, len);
  fileread(grp, WPic[0], len);
  tnum := fileseek(idx, 0, 2) div 4;
  fileseek(idx, 0, 0);
  setlength(widx, tnum);
  fileread(idx, WIdx[0], tnum * 4);
  fileclose(grp);
  fileclose(idx);

  idx := fileopen(AppPath + 'resource/cloud.idx', fmopenread);
  grp := fileopen(AppPath + 'resource/cloud.grp', fmopenread);
  len := fileseek(grp, 0, 2);
  fileseek(grp, 0, 0);
  fileread(grp, CPic[0], len);
  tnum := fileseek(idx, 0, 2) div 4;
  fileseek(idx, 0, 0);
  fileread(idx, CIdx[0], tnum * 4);
  fileclose(grp);
  fileclose(idx);

  { idx := fileopen(AppPath + 'resource/eft.idx', fmopenread);
   grp := fileopen(AppPath + 'resource/eft.grp', fmopenread);
   len := fileseek(grp, 0, 2);
   fileseek(grp, 0, 0);
   fileread(grp, EPic[0], len);
   tnum := fileseek(idx, 0, 2) div 4;
   fileseek(idx, 0, 0);
   fileread(idx, EIdx[0], tnum * 4);
   fileclose(grp);
   fileclose(idx);

  idx := fileopen(AppPath + 'resource/hdgrp.idx', fmopenread);
  grp := fileopen(AppPath + 'resource/hdgrp.grp', fmopenread);
  len := fileseek(grp, 0, 2);
  fileseek(grp, 0, 0);
  fileread(grp, HPic[0], len);
  tnum := fileseek(idx, 0, 2) div 4;
  fileseek(idx, 0, 0);
  fileread(idx, HIdx[0], tnum * 4);
  fileclose(grp);
  fileclose(idx);

                  }

  if (FileExistsUTF8(AppPath + Scene_file) { *Converted from FileExists*  }) then
  begin
    grp := fileopen(AppPath + Scene_file, fmopenread);
    fileseek(grp, 0, 0);
    fileread(grp, len, 4);
    setlength(Scenepic, len);
    for i := 0 to len - 1 do
      ScenePic[i] := getpngpic(grp, i);
    fileclose(grp);
    //Setlength(BGidx, 0);
  end;

  if (FileExistsUTF8(AppPath + Heads_file) { *Converted from FileExists*  }) then
  begin
    grp := fileopen(AppPath + Heads_file, fmopenread);
    fileseek(grp, 0, 0);
    fileread(grp, len, 4);
    setlength(Head_PIC, len);
    for i := 0 to len - 1 do
      Head_Pic[i] := getpngpic(grp, i);
    fileclose(grp);
    //Setlength(BGidx, 0);
  end;

  if (FileExistsUTF8(AppPath + Skill_file) { *Converted from FileExists*  }) then
  begin
    grp := fileopen(AppPath + Skill_file, fmopenread);
    fileseek(grp, 0, 0);
    fileread(grp, len, 4);
    setlength(SkillPIC, len);
    for i := 0 to len - 1 do
      SkillPIC[i] := getpngpic(grp, i);
    fileclose(grp);
    //Setlength(BGidx, 0);
  end;
  if (FileExistsUTF8(AppPath + BACKGROUND_file) { *Converted from FileExists*  }) then
  begin
    grp := fileopen(AppPath + BACKGROUND_file, fmopenread);

    BEGIN_PIC := GetPngPic(grp, 0);
    MAGIC_PIC := GetPngPic(grp, 1);
    STATE_PIC := GetPngPic(grp, 2);
    SYSTEM_PIC := GetPngPic(grp, 3);
    MAP_PIC := GetPngPic(grp, 4);
    SKILL_PIC := GetPngPic(grp, 5);
    MENUESC_PIC := GetPngPic(grp, 6);
    MENUESCBack_PIC := GetPngPic(grp, 7);
    battlePIC := GetPngPic(grp, 8);
    TEAMMATE_PIC := GetPngPic(grp, 9);
    MENUITEM_PIC := GetPngPic(grp, 10);
    PROGRESS_PIC := GetPngPic(grp, 11);
    MATESIGN_PIC := GetPngPic(grp, 12);
    ENEMYSIGN_PIC := GetPngPic(grp, 13);
    SELECTEDENEMY_PIC := GetPngPic(grp, 14);
    SELECTEDMATE_PIC := GetPngPic(grp, 15);
    NowPROGRESS_PIC := GetPngPic(grp, 16);
    angryprogress_pic := GetPngPic(grp, 17);
    angrycollect_pic := GetPngPic(grp, 18);
    angryfull_pic := GetPngPic(grp, 19);
    DEATH_PIC := GetPngPic(grp, 20);
    Maker_Pic := GetPngPic(grp, 21);
    fileclose(grp);
    //Setlength(BGidx, 0);
  end;

  (* STATE_PIC := IMG_Load('resource/state.bok');
   MAGIC_PIC := IMG_Load('resource/magic.bok');
   SYSTEM_PIC := IMG_Load('resource/system.bok');
  *)
  c := fileopen(AppPath + 'resource/earth.002', fmopenread);
  fileread(c, Earth[0, 0], 480 * 480 * 2);
  fileclose(c);
  c := fileopen(AppPath + 'resource/surface.002', fmopenread);
  fileread(c, surface[0, 0], 480 * 480 * 2);
  fileclose(c);
  c := fileopen(AppPath + 'resource/building.002', fmopenread);
  fileread(c, Building[0, 0], 480 * 480 * 2);
  fileclose(c);
  c := fileopen(AppPath + 'resource/buildx.002', fmopenread);
  fileread(c, Buildx[0, 0], 480 * 480 * 2);
  fileclose(c);
  c := fileopen(AppPath + 'resource/buildy.002', fmopenread);
  fileread(c, Buildy[0, 0], 480 * 480 * 2);
  fileclose(c);
  // c := fileopen(AppPath + 'list/leave.bin', fmopenread);
  // fileread(c, leavelist[0], 200);
  // fileclose(c);

  c := fileopen(AppPath + 'list/Set.bin', fmopenread);
  l := sizeof(SetNum);
  fileread(c, SetNum, l);
  fileclose(c);


  c := fileopen(AppPath + 'list/levelup.bin', fmopenread);
  l := sizeof(SetNum);
  fileread(c, leveluplist[0], 200);
  fileclose(c);
  // c := fileopen(AppPath + 'list/match.bin', fmopenread);
  // fileread(c, matchlist[0], MAX_WEAPON_MATCH * 3 * 2);
  // fileclose(c);

end;

//Main game.
//显示开头画面

procedure Start;
var
  menu, menup, i, col, i1, ingame, i2, x, y, len, pic: integer;
  picb: array of byte;
  beginscreen: Psdl_surface;
  dest: tsdl_rect;
begin
  //Acupuncture(2);
  //InitialScript;
  StopMp3;
  PlayMp3(106, -1);
  SDL_EnableKeyRepeat(10, 100);
  ingame := 0;
  PlayBeginningMovie(0, -1);
  //PlayMpeg();
  display_imgfromSurface(BEGIN_PIC, 0, 0);
  MStep := 0;
  // fullscreen := 0;
  where := 3;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  menu := 0;
  Setlength(RItemlist, MAX_ITEM_AMOUNT);
  for i := 0 to MAX_ITEM_AMOUNT - 1 do
  begin
    RItemlist[i].Number := -1;
    RItemlist[i].Amount := 0;
  end;

  SetLength(Cloud, CLOUD_AMOUNT);
  for i := 0 to CLOUD_AMOUNT - 1 do
  begin
    CloudCreate(i);
  end;

  x := 275;
  y := 290;
  //drawrectanglewithoutframe(270, 150, 100, 70, 0, 20);
  drawtitlepic(0, x, y);
  drawtitlepic(menu + 1, x, y + menu * 20);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

  //WoodMan(3);
  //事件等待
  while (ingame = 0) do
  begin
    while (SDL_WaitEvent(@event) >= 0) do
    begin
      if event.type_ = SDL_VIDEORESIZE then
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      //关闭窗口事件
      if event.type_ = SDL_QUITEV then
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then
          Quit;
      //如选择第2项, 则退出(所有编号从0开始)
      if (((event.type_ = SDL_KEYUP) and ((event.key.keysym.sym = sdlk_return) or
        (event.key.keysym.sym = sdlk_space))) or ((event.type_ = SDL_MOUSEBUTTONUP) and
        (event.button.button = sdl_button_left))) and (menu = 2) then
      begin
        ingame := 1;
        Quit;
      end;
      //选择第0项, 重新开始游戏
      if (((event.type_ = SDL_KEYUP) and ((event.key.keysym.sym = sdlk_return) or
        (event.key.keysym.sym = sdlk_space))) or ((event.type_ = SDL_MOUSEBUTTONUP) and
        (event.button.button = sdl_button_left))) and (menu = 0) then
      begin
        if InitialRole then
        begin

          showmr := False;
          CurScene := BEGIN_Scene;
          stopmp3;
          playmp3(RScene[CurScene].ExitMusic, -1);
          InScene(1);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          break;
        end;
        redraw;
        drawtitlepic(0, x, y);
        drawtitlepic(menu + 1, x, y + menu * 20);
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      end;
      //选择第1项, 读入进度
      if (((event.type_ = SDL_KEYUP) and ((event.key.keysym.sym = sdlk_return) or
        (event.key.keysym.sym = sdlk_space))) or ((event.type_ = SDL_MOUSEBUTTONUP) and
        (event.button.button = sdl_button_left) and (round(event.button.x / (RealScreen.w / screen.w)) > x) and
        (round(event.button.x / (RealScreen.w / screen.w)) < x + 80) and
        (round(event.button.y / (RealScreen.h / screen.h)) > y) and
        (round(event.button.y / (RealScreen.h / screen.h)) < y + 60))) and (menu = 1) then
      begin
        showmr := True;

        //LoadR(1);
        if menuloadAtBeginning then
        begin
          //redraw;
          //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          PlayBeginningMovie(26, 0);
          instruct_14;
          event.key.keysym.sym := 0;
          CurEvent := -1;
          break;
          //when CurEvent=-1, Draw Scene by Sx, Sy. Or by Cx, Cy.
        end
        else
        begin
          drawtitlepic(0, x, y);
          drawtitlepic(menu + 1, x, y + menu * 20);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
      end;
      //按下方向键上
      if ((event.type_ = SDL_KEYUP) and ((event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8))) then
      begin
        menu := menu - 1;
        if menu < 0 then
          menu := 2;
        drawtitlepic(0, x, y);
        drawtitlepic(menu + 1, x, y + menu * 20);
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      end;
      //按下方向键下
      if ((event.type_ = SDL_KEYUP) and ((event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2))) then
      begin
        menu := menu + 1;
        if menu > 2 then
          menu := 0;
        drawtitlepic(0, x, y);
        drawtitlepic(menu + 1, x, y + menu * 20);
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      end;
      //鼠标移动
      if (event.type_ = SDL_MOUSEMOTION) then
      begin
        if (round(event.button.x / (RealScreen.w / screen.w)) > x) and
          (round(event.button.x / (RealScreen.w / screen.w)) < x + 80) and
          (round(event.button.y / (RealScreen.h / screen.h)) > y) and
          (round(event.button.y / (RealScreen.h / screen.h)) < y + 60) then
        begin
          menup := menu;
          menu := (round(event.button.y / (RealScreen.h / screen.h)) - y) div 20;
          if menu <> menup then
          begin
            drawtitlepic(0, x, y);
            drawtitlepic(menu + 1, x, y + menu * 20);
            SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          end;
        end
        else menu := -1;
      end;

    end;
    event.key.keysym.sym := 0;
    event.button.button := 0;
    if where = 1 then
    begin
      InScene(0);
    end;
    Walk;
    Redraw;
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  end;

  SDL_EnableKeyRepeat(30, (30 * gamespeed) div 10);
end;

//初始化主角属性

function InitialRole: boolean;
var
  i, battlemode2, x, y, t: integer;
  p: array[0..14] of integer;
  {str,} str0 {, name}: WideString;
  str: string;
  {$IFDEF fpc}
  Name: string;
  {$ELSE}
  Name: WideString;
  {$ENDIF}
  str1: string;
  p0, p1: PChar;
  LanId: word;
  lan: string;
begin
{$IFDEF fpc}
  lanID := 1028;
{$ELSE}
  lanId := GetSystemDefaultLangID;
{$ENDIF}
  battlemode2 := battlemode;
  if (lanId = 2052) or (lanId = 1028) then
  begin
    if lanid = 2052 then
      lan := 'SC';
    if lanId = 1028 then
      lan := 'TC';
  end
  else
    lan := 'E';
  t := 0;
  for i := 1 to 6 do
  begin
    LoadR(i);
    t := max(gametime, t);
  end;
  LoadR(0);
  gametime := max(gametime, t);
  battlemode := battlemode2;
  if battlemode > gametime then
    battlemode := min(gametime, 2);
  where := 3;
  //显示输入姓名的对话框
  //form1.ShowModal;
  //str := form1.edit1.text;
  x := 275;
  y := 250;
  //drawrectanglewithoutframe(270, 150, 100, 70, 0, 20);

  if fullscreen = 1 then
    realscreen := SDL_SetVideoMode(RESOLUTIONX, RESOLUTIONY, 32, ScreenFlag);
  redraw;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  if gametime > 0 then
  begin
    if lan = 'SC' then
    begin
      str1 := '金先生'; //默认名
      str := '請輸入你的名字              ';
    end;
    if lan = 'E' then
    begin
      str1 := '金先生'; //默认名
      str := 'Please input your name in Unicode              ';
    end;
    if lan = 'TC' then
    begin
      str1 := '金先生'; //默认名
      str := '請輸入你的名字              ';
    end;
  end
  else
  begin
    if lan = 'SC' then
    begin
      str1 := '先生'; //默认名
      str := '金先生，請輸入你的名字              ';
    end;
    if lan = 'E' then
    begin
      str1 := '先生'; //默认名
      str := 'Mr.Kam, please input your name in Unicode              ';
    end;
    if lan = 'TC' then
    begin
      str1 := '先生'; //默认名
      str := '金先生，請輸入你的名字              ';
    end;
  end;
  Result := inputquery('Enter name', str, str1);
  if fullscreen = 1 then
  begin
    realscreen := SDL_SetVideoMode(CENTER_X * 2, CENTER_Y * 2, 32, ScreenFlag or SDL_FULLSCREEN);
    redraw;
    drawtitlepic(0, x, y);
    drawtitlepic(1, x, y);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  end;
  if str1 = '' then Result := False;
  if Result then
  begin
    //name := Simplified2Traditional(str1);
    Name := str1;
    if gametime = 0 then
      Name := '金' + Name;
{$IFDEF fpc}
    str1 := UTF8ToCP936(Name);
{$ELSE}
    str1 := unicodetogbk(@Name[1]);
{$ENDIF}
    p0 := @rrole[0].Name;
    p1 := @str1[1];
    for i := 0 to 4 do
      rrole[0].Data[4 + i] := 0;
    for i := 0 to 7 do
    begin
      (p0 + i)^ := (p1 + i)^;
    end;

    redraw;
    Result := RandomAttribute;
    if Result then
    begin //redraw;
      if gametime > 0 then
        MenuDifficult;

      PlayBeginningMovie(26, 0);
      StartAmi;
      //EndAmi;
    end;
  end;

end;

procedure ShowRandomAttribute(ran: boolean);
var
  str, tip, str0: WideString;
begin
  str := UTF8Decode(' 資質');
  tip := UTF8Decode(' 選定屬性後按Y');
  if (ran = True) then
  begin
    Rrole[0].MaxHP := 51 + random(50);
    Rrole[0].CurrentHP := Rrole[0].MaxHP;
    Rrole[0].MaxMP := 51 + random(50);
    Rrole[0].CurrentMP := Rrole[0].MaxMP;
    Rrole[0].MPType := random(2);
    Rrole[0].IncLife := 1 + random(10);

    Rrole[0].Attack := 25 + random(6);
    Rrole[0].Speed := 25 + random(6);
    Rrole[0].Defence := 25 + random(6);
    Rrole[0].Medcine := 25 + random(6);
    Rrole[0].UsePoi := 25 + random(6);
    Rrole[0].MedPoi := 25 + random(6);
    Rrole[0].Fist := 25 + random(6);
    Rrole[0].Sword := 25 + random(6);
    Rrole[0].Knife := 25 + random(6);
    Rrole[0].Unusual := 25 + random(6);
    Rrole[0].HidWeapon := 25 + random(6);

    rrole[0].Aptitude := 1 + random(100);
  end;
  redraw;
  showstatus(0);
  drawshadowtext(@str[1], 30, CENTER_Y + 111, colcolor($21), colcolor($23));
  str0 := format('%4d', [RRole[0].Aptitude]);
  drawengshadowtext(@str0[1], 150, CENTER_Y + 111, colcolor($63), colcolor($66));
  drawshadowtext(@tip[1], 210, CENTER_Y + 111, colcolor($5), colcolor($7));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

end;

function RandomAttribute: boolean;
var
  pwd: WideString;
  keyvalue: integer;
begin
  repeat
    ShowRandomAttribute(True);
    keyvalue := waitanykey;
  until (keyvalue = sdlk_y) or (keyvalue = sdlk_escape);
  if (keyvalue = sdlk_y) then
  begin
    ShowRandomAttribute(False);
    Result := True;
  end
  else
    Result := False;
end;

procedure XorCount(Data: pbyte; xornum: byte; length: integer);
var
  i: integer;
begin
  for i := 0 to length - 1 do
  begin
    Data^ := byte(Data^ xor byte(xornum));
    Inc(Data);
  end;
end;



//读入存档, 如为0则读入起始存档

procedure LoadR(num: integer);
var
  filename1, filename, filename2: string;
  idx, grp, i1, i2, len, len1: integer;
  BasicOffset, RoleOffset, ItemOffset, SceneOffset, MagicOffset, WeiShopOffset, i: integer;
  str: string;
  str1: WideString;
  p1, p0: PChar;
begin
  SaveNum := num;
  filename := 'R' + IntToStr(num);
  filename1 := 'save/' + 'R' + IntToStr(num) + '.grp';

  if num = 0 then
    filename := 'ranger';
  idx := fileopen(AppPath + 'save/ranger.idx', fmopenread);
  grp := fileopen(AppPath + 'save/' + filename + '.grp', fmopenread);

  fileread(idx, RoleOffset, 4);
  fileread(idx, ItemOffset, 4);
  fileread(idx, SceneOffset, 4);
  fileread(idx, MagicOffset, 4);
  fileread(idx, WeiShopOffset, 4);
  fileread(idx, len, 4);

  fileseek(grp, 0, 0);
  fileread(grp, Inship, 2);
  fileread(grp, where, 2);
  fileread(grp, My, 2);
  fileread(grp, Mx, 2);
  fileread(grp, Sy, 2);
  fileread(grp, Sx, 2);
  fileread(grp, Mface, 2);
  fileread(grp, shipx, 2);
  fileread(grp, shipy, 2);
  fileread(grp, time, 2);
  fileread(grp, timeevent, 2);
  fileread(grp, randomevent, 2);
  fileread(grp, Sface, 2);
  fileread(grp, shipface, 2);
  fileread(grp, gametime, 2);
  fileread(grp, teamlist[0], 2 * 6);
  fileread(grp, Ritemlist[0], sizeof(Titemlist) * max_item_amount);

  setlength(RRole, (ItemOffset - RoleOffset) div sizeof(Trole));
  fileread(grp, RRole[0], ItemOffset - RoleOffset);

  setlength(RItem, (SceneOffset - ItemOffset) div sizeof(TItem));
  fileread(grp, RItem[0], SceneOffset - ItemOffset);

  setlength(RScene, (MagicOffset - SceneOffset) div sizeof(TScene));
  fileread(grp, RScene[0], MagicOffset - SceneOffset);

  setlength(RMagic, (WeiShopOffset - MagicOffset) div sizeof(TMagic));
  fileread(grp, RMagic[0], WeiShopOffset - MagicOffset);

  setlength(Rshop, (len - WeiShopOffset) div sizeof(Tshop));
  fileread(grp, Rshop[0], len - WeiShopOffset);

  fileclose(idx);
  fileclose(grp);

  if smallint(where) < 0 then where := 0
  else
  begin
    curScene := where;
    where := 1;
  end;
  //初始化入口
  ReSetEntrance;
  len := length(RScene);
  setlength(Sdata, len);
  setlength(Ddata, len);
  filename := 'S' + IntToStr(num);
  if num = 0 then
    filename := 'Allsin';
  grp := fileopen(AppPath + 'save/' + filename + '.grp', fmopenread);
  fileread(grp, Sdata[0], len * 64 * 64 * 6 * 2);
  fileclose(grp);
  filename := 'D' + IntToStr(num);
  filename2 := 'save/' + 'D' + IntToStr(num) + '.grp';
  if num = 0 then
    filename := 'Alldef';
  grp := fileopen(AppPath + 'save/' + filename + '.grp', fmopenread);
  fileread(grp, Ddata[0], len * 200 * 11 * 2);
  fileclose(grp);
  //gametime := min(gametime, 2);
  if battlemode > min(gametime, 2) then battlemode := min(gametime, 2);
  Max_Level := min(50, 30 + gametime * 10);

end;

//存档

procedure SaveR(num: integer);
var
  filename: string;
  sgrp, dgrp, ridx, rgrp, i1, i2, len, SceneAmount: integer;
  BasicOffset, RoleOffset, ItemOffset, SceneOffset, MagicOffset, WeiShopOffset, i: integer;
  //key: uint16;
  str: WideString;
  Rkey: uint16;
begin
  Rkey := uint16(random($FFFF));

  SaveNum := num;
  filename := 'R' + IntToStr(num);
  if num = 0 then
    filename := 'ranger';
  ridx := fileopen(AppPath + 'save/ranger.idx', fmopenreadwrite);
  rgrp := filecreate(AppPath + 'save/' + filename + '.grp', fmopenreadwrite);
  BasicOffset := 0;
  fileread(ridx, RoleOffset, 4);
  fileread(ridx, ItemOffset, 4);
  fileread(ridx, SceneOffset, 4);
  fileread(ridx, MagicOffset, 4);
  fileread(ridx, WeiShopOffset, 4);
  fileread(ridx, len, 4);
  fileseek(rgrp, 0, 0);
  filewrite(rgrp, Inship, 2);
  if where = 0 then
  begin
    useless1 := -1;
    filewrite(rgrp, useless1, 2);
  end
  else
    filewrite(rgrp, curScene, 2);
  filewrite(rgrp, My, 2);
  filewrite(rgrp, Mx, 2);
  filewrite(rgrp, Sy, 2);
  filewrite(rgrp, Sx, 2);
  filewrite(rgrp, Mface, 2);
  filewrite(rgrp, shipx, 2);
  filewrite(rgrp, shipy, 2);
  filewrite(rgrp, time, 2);
  filewrite(rgrp, timeevent, 2);
  filewrite(rgrp, randomevent, 2);
  filewrite(rgrp, Sface, 2);
  filewrite(rgrp, shipface, 2);
  filewrite(rgrp, gametime, 2);
  filewrite(rgrp, teamlist[0], 2 * 6);
  filewrite(rgrp, Ritemlist[0], sizeof(Titemlist) * max_item_amount);

  filewrite(rgrp, RRole[0], ItemOffset - RoleOffset);
  filewrite(rgrp, RItem[0], SceneOffset - ItemOffset);
  filewrite(rgrp, RScene[0], MagicOffset - SceneOffset);
  filewrite(rgrp, RMagic[0], WeiShopOffset - MagicOffset);
  filewrite(rgrp, Rshop[0], len - WeiShopOffset);
  SceneAmount := length(RScene);

  filename := 'S' + IntToStr(num);
  if num = 0 then
    filename := 'Allsin';
  sgrp := filecreate(AppPath + 'save/' + filename + '.grp');
  filewrite(sgrp, Sdata[0], SceneAmount * 64 * 64 * 6 * 2);

  filename := 'D' + IntToStr(num);
  if num = 0 then
    filename := 'Alldef';
  dgrp := filecreate(AppPath + 'save/' + filename + '.grp');
  filewrite(dgrp, Ddata[0], SceneAmount * 200 * 11 * 2);

  fileclose(dgrp);
  fileclose(sgrp);
  fileclose(rgrp);
  fileclose(ridx);

end;

//等待任意按键

function WaitAnyKey: integer; overload;
begin
  //event.type_ := SDL_NOEVENT;
  event.key.keysym.sym := 0;
  event.button.button := 0;
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    if event.type_ = SDL_VIDEORESIZE then
    begin
      ResizeWindow(event.resize.w, event.resize.h);
    end;
    if (event.type_ = SDL_QUITEV) then
      if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then
        Quit;
    if (event.type_ = SDL_KEYUP) or (event.type_ = SDL_mousebuttonUP) then
      if (event.key.keysym.sym <> 0) or (event.button.button <> 0) then
        break;
  end;
  Result := event.key.keysym.sym;
  event.key.keysym.sym := 0;
  event.button.button := 0;
end;

procedure WaitAnyKey(keycode, x, y: psmallint); overload;
begin
  //event.type_ := SDL_NOEVENT;
  event.key.keysym.sym := 0;
  event.button.button := 0;
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    if event.type_ = SDL_VIDEORESIZE then
    begin
      ResizeWindow(event.resize.w, event.resize.h);
    end;
    if (event.type_ = SDL_QUITEV) then
      if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then
        Quit;
    if (event.type_ = SDL_KEYUP) and (event.key.keysym.sym <> 0) then
    begin
      keycode^ := event.key.keysym.sym;
      break;
    end;
    if (event.type_ = SDL_mousebuttonUP) and (event.button.button <> 0) then
    begin
      keycode^ := -1;
      x^ := round(event.button.x / (RealScreen.w / screen.w));
      y^ := round(event.button.y / (RealScreen.h / screen.h));
      y^ := y^ + 30;
      break;
    end;
  end;
  event.key.keysym.sym := 0;
  event.button.button := 0;
end;

//于主地图行走

procedure Walk;
var
  word: array[0..10] of Uint16;
  x, y, i1, i, Ayp, menu, Axp, walking, Mx1, My1, Mx2, My2, speed, stillcount, needrefresh: integer;
  now, next_time, next_time2, next_time3: uint32;
  keystate: PChar;
begin

  Where := 0;
  next_time := sdl_getticks;
  next_time2 := sdl_getticks;
  next_time3 := sdl_getticks;

  walking := 0;
  resetpallet;
  DrawMMap;
  SDL_EnableKeyRepeat(30, (30 * gamespeed) div 10);
  StopMp3;
  PlayMp3(16, -1);
  still := 0;
  speed := 0;

  event.key.keysym.sym := 0;
  //事件轮询(并非等待)
  while SDL_PollEvent(@event) >= 0 do
  begin
    needrefresh := 0;
    //如果当前处于标题画面, 则退出, 用于战斗失败
    if where >= 3 then
    begin
      break;
    end;
    //主地图动态效果, 实际仅有主角的动作
    now := sdl_getticks;

    //闪烁效果
    if (integer(now - next_time2) > 0) then
    begin
      ChangeCol;
      next_time2 := now + 200;
      //needrefresh := 1;
      //DrawMMap;
    end;

    //飘云
    if (integer(now - next_time3) > 0) then
    begin
      for i := 0 to CLOUD_AMOUNT - 1 do
      begin
        Cloud[i].Positionx := Cloud[i].Positionx + Cloud[i].Speedx;
        Cloud[i].Positiony := Cloud[i].Positiony + Cloud[i].Speedy;
        if (Cloud[i].Positionx > 17279) or (Cloud[i].Positionx < 0) or (Cloud[i].Positiony > 8639) or
          (Cloud[i].Positiony < 0) then
        begin
          CloudCreateOnSide(i);
        end;
      end;
      next_time3 := now + 40;
      //needrefresh := 1;
    end;

    if (integer(now - next_time) > 0) and (Where = 0) then
    begin
      if (walking = 0) then
        stillcount := stillcount + 1
      else
        stillcount := 0;

      if stillcount >= 10 then
      begin
        still := 1;
        mstep := mstep + 1;
        if mstep > 6 then
          mstep := 1;
      end;
      next_time := now + 300;
      //needrefresh := 1;
    end;

    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then
          Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      //方向键使用压下按键事件
      SDL_KEYDOWN:
      begin
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) then
        begin
          MFace := 2;
          walking := 2;
        end;
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_kp6) then
        begin
          MFace := 1;
          walking := 2;
        end;
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          MFace := 0;
          walking := 2;
        end;
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then
        begin
          MFace := 3;
          walking := 2;
        end;
      end;
      //功能键(esc)使用松开按键事件
      SDL_KEYUP:
      begin
        keystate := PChar(SDL_GetKeyState(nil));
        walking := 0;
        if (puint8(keystate + sdlk_left)^ = 0) and (puint8(keystate + sdlk_right)^ = 0) and
          (puint8(keystate + sdlk_up)^ = 0) and (puint8(keystate + sdlk_down)^ = 0) then
        begin
          walking := 0;
          speed := 0;
        end;
          {if event.key.keysym.sym in [sdlk_left, sdlk_right, sdlk_up, sdlk_down] then
          begin
            walking := 0;
          end;}
        if (event.key.keysym.sym = sdlk_escape) then
        begin
          //event.key.keysym.sym:=0;
          newMenuEsc;
          nowstep := -1;
          walking := 0;
        end;
          {if (event.key.keysym.sym = sdlk_f11) then
          begin
            execscript(pchar('script/1.lua'), pchar('f1'));
          end;
          if (event.key.keysym.sym = sdlk_f10) then
          begin
            callevent(1);
          end;}
        if (event.key.keysym.sym = sdlk_f4) then
        begin
          if gametime > 0 then
          begin
            menu := 0;
            setlength(menustring, 2);
            setlength(menuengstring, 0);
            menustring[0] := UTF8Decode(' 回合制');
            menustring[1] := UTF8Decode(' 半即時');
            menu := commonmenu(27, 30, 90, 1, battlemode div 2);
            if menu >= 0 then
            begin
              battlemode := min(2, menu * 2);
              Kys_ini.WriteInteger('set', 'battlemode', battlemode);
            end;
            setlength(Menustring, 0);
          end;
        end;

        if (event.key.keysym.sym = sdlk_f3) then
        begin
          menu := 0;
          setlength(menustring, 2);
          setlength(menuengstring, 0);
          menustring[0] := UTF8Decode(' 天氣特效：開');
          menustring[1] := UTF8Decode(' 天氣特效：關');
          menu := commonmenu(27, 30, 180, 1, effect);
          if menu >= 0 then
          begin
            effect := menu;
            Kys_ini.WriteInteger('set', 'effect', effect);
          end;
          setlength(Menustring, 0);
        end;

        if (event.key.keysym.sym = sdlk_f1) then
        begin
          menu := 0;
          setlength(menustring, 2);
          menustring[0] := UTF8Decode(' 繁體字');
          menustring[1] := UTF8Decode(' 簡體字');
          menu := commonmenu(27, 30, 90, 1, simple);
          if menu >= 0 then
          begin
            simple := menu;
            Kys_ini.WriteInteger('set', 'simple', simple);
          end;
          setlength(Menustring, 0);
        end;

        if (event.key.keysym.sym = sdlk_f2) then
        begin
          menu := 0;
          setlength(menustring, 3);
          menustring[0] := UTF8Decode(' 遊戲速度：快');
          menustring[1] := UTF8Decode(' 遊戲速度：中');
          menustring[2] := UTF8Decode(' 遊戲速度：慢');
          menu := commonmenu(27, 30, 180, 2, min(gamespeed div 10, 2));
          if menu >= 0 then
          begin
            if menu = 0 then gamespeed := 1;
            if menu = 1 then gamespeed := 10;
            if menu = 2 then gamespeed := 20;
            Kys_ini.WriteInteger('constant', 'game_speed', gamespeed);
          end;
          setlength(Menustring, 0);
        end;

        if (event.key.keysym.sym = sdlk_f5) then
        begin
          SwitchFullscreen;
          Kys_ini.WriteInteger('set', 'fullscreen', fullscreen);
        end;
        CheckHotkey(event.key.keysym.sym);
      end;
      //如按下鼠标左键, 设置状态为行走
      //如松开鼠标左键, 设置状态为不行走
      //右键则呼出系统选单
      Sdl_mousebuttonup:
      begin
        if event.button.button = sdl_button_right then
        begin
          event.button.button := 0;
          //showmessage(inttostr(walking));
          newmenuesc;
          nowstep := -1;
          walking := 0;
        end;
      end;
      Sdl_mousebuttondown:
      begin
        if event.button.button = sdl_button_left then
        begin
          walking := 1;
          Axp := MX + (-round(event.button.x / (RealScreen.w / screen.w)) + CENTER_x + 2 *
            round(event.button.y / (RealScreen.h / screen.h)) - 2 * CENTER_y + 18) div 36;
          Ayp := MY + (round(event.button.x / (RealScreen.w / screen.w)) - CENTER_x + 2 *
            round(event.button.y / (RealScreen.h / screen.h)) - 2 * CENTER_y + 18) div 36;
          if (ayp >= 0) and (ayp <= 479) and (axp >= 0) and (axp <= 479) {and canWalk(axp, ayp)} then
          begin
            for i := 0 to 479 do
              for i1 := 0 to 479 do
                Fway[i, i1] := -1;
            findway(MX, MY);
            Moveman(MX, MY, Axp, Ayp);
            nowstep := Fway[Axp, Ayp] - 1;
          end;
        end;
      end;
    end;

    if walking = 2 then
    begin
      speed := speed + 1;
      still := 0;
      stillcount := 0;
      Mx1 := Mx;
      My1 := My;
      case mface of
        0: Mx1 := Mx1 - 1;
        1: My1 := My1 + 1;
        2: My1 := My1 - 1;
        3: Mx1 := Mx1 + 1;
      end;
      Mstep := Mstep + 1;
      if Mstep > 6 then
        Mstep := 1;
      if canwalk(Mx1, My1) = True then
      begin
        Mx := Mx1;
        My := My1;
      end;
      if (speed <= 1) then
        walking := 0;
      if inship = 1 then
      begin
        shipx := my;
        shipy := mx;
      end;
      //每走一步均重画屏幕, 并检测是否处于某场景入口
      DrawMMap;
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      if CheckEntrance then
        walking := 0;
      //needrefresh := 1;
    end;

    if (nowstep < 0) and (walking = 1) then
      walking := 0;

    if (nowstep >= 0) and (walking = 1) then
    begin
      still := 0;
      if sign(linex[nowstep] - Mx) < 0 then
        MFace := 0
      else if sign(linex[nowstep] - Mx) > 0 then
        MFace := 3
      else if sign(liney[nowstep] - My) > 0 then
        MFace := 1
      else MFace := 2;
      MStep := 6 - nowstep mod 6;

      Mx := linex[nowstep];
      My := liney[nowstep];

      Dec(nowstep);

      if inship = 1 then
      begin
        shipx := my;
        shipy := mx;
      end;
      if (shipy = mx) and (shipx = my) then
      begin
        inship := 1;
      end;

      //每走一步均重画屏幕, 并检测是否处于某场景入口
      DrawMMap;
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      if CheckEntrance then
        walking := 0;
    end;

    SDL_Delay((10 * GameSpeed) div 10);

    if walking = 0 then
    begin
      DrawMMap;
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    end;

    event.key.keysym.sym := 0;
    event.button.button := 0;

  end;

  SDL_EnableKeyRepeat(0, 10);

end;


//判定主地图某个位置能否行走, 是否变成船
//function in kys_main.pas

function CanWalk(x, y: integer): boolean;
begin
  if buildx[x, y] = 0 then
    canwalk := True
  else
    canwalk := False;
  //canwalk:=true;  //This sentence is used to test.
  if (x <= 0) or (x >= 479) or (y <= 0) or (y >= 479) or ((surface[x, y] >= 1692) and (surface[x, y] <= 1700)) then
    canwalk := False;
  if (earth[x, y] = 838) or ((earth[x, y] >= 612) and (earth[x, y] <= 670)) then
    canwalk := False;
  if ((earth[x, y] >= 358) and (earth[x, y] <= 362)) or ((earth[x, y] >= 506) and (earth[x, y] <= 670)) or
    ((earth[x, y] >= 1016) and (earth[x, y] <= 1022)) then
  begin
    if (Inship = 1) then //isship
    begin
      if (earth[x, y] = 838) or ((earth[x, y] >= 612) and (earth[x, y] <= 670)) then
      begin
        canwalk := False;
      end
      else if ((surface[x, y] >= 1746) and (surface[x, y] <= 1788)) then
      begin
        canwalk := False;
      end
      else
        canwalk := True;
    end

    else
    if (x = shipy) and (y = shipx) then //touch ship?
    begin
      canwalk := True;
      InShip := 1;
    end
    else
      canwalk := False;
  end
  else
  begin
    if (Inship = 1) then //isboat??
    begin
      shipy := Mx; //arrrive
      shipx := My;
      shipface := Mface;
    end;
    InShip := 0;
  end;
  if ((surface[x, y] div 2 >= 863) and (surface[x, y] div 2 <= 872)) or
    ((surface[x, y] div 2 >= 852) and (surface[x, y] div 2 <= 854)) or
    ((surface[x, y] div 2 >= 858) and (surface[x, y] div 2 <= 860)) then
    canwalk := True;
end;

//Check able or not to ertrance a Scene.
//检测是否处于某入口, 并是否达成进入条件

{procedure CheckEntrance;
var
  x, y, i, snum: integer;
  CanEntrance: boolean;
begin
  x := Mx;
  y := My;
  case Mface of
    0: x := x - 1;
    1: y := y + 1;
    2: y := y - 1;
    3: x := x + 1;
  end;
  if (Entrance[x, y] >= 0) then
  begin
    canentrance := false;
    snum := entrance[x, y];
    if (RScene[snum].EnCondition = 0) then
      canentrance := true;
    //是否有人轻功超过70
    if (RScene[snum].EnCondition = 2) then
      for i := 0 to length(rrole) - 1 do
        if rrole[i].TeamState in [1, 2] then
          if GetRoleSpeed(i, true) >= 70 then
            canentrance := true;
    if canentrance = true then
    begin
      instruct_14;
      CurScene := Entrance[x, y];
      SFace := MFace;
      Mface := 3 - Mface;
      SStep := 0;
      Sx := RScene[CurScene].EntranceX;
      Sy := RScene[CurScene].EntranceY;
      //如达成条件, 进入场景并初始化场景坐标
      SaveR(6);
      InScene(0);

      //waitanykey;
    end;
    //instruct_13;
  end;

end;}

function CheckEntrance: boolean;
var
  x, y, i, snum: integer;
  //CanEntrance: boolean;
begin
  x := Mx;
  y := My;
  case Mface of
    0: x := x - 1;
    1: y := y + 1;
    2: y := y - 1;
    3: x := x + 1;
  end;
  Result := False;
  if (Entrance[x, y] >= 0) then
  begin
    Result := False;
    snum := entrance[x, y];
    if (RScene[snum].EnCondition = 0) then
      Result := True;
    //是否有人轻功超过70
    if (RScene[snum].EnCondition = 2) then
    begin
      for i := 0 to length(rrole) - 1 do
        if rrole[i].TeamState in [1, 2] then
          if GetRoleSpeed(i, True) >= 70 then
            Result := True;
      //showmessage(inttostr(Rrole[teamlist[0]].Speed));
    end;
    if Result = True then
    begin
      instruct_14;
      CurScene := Entrance[x, y];
      SFace := MFace;
      Mface := 3 - Mface;
      SStep := 1;
      Sx := RScene[CurScene].EntranceX;
      Sy := RScene[CurScene].EntranceY;
      //如达成条件, 进入场景并初始化场景坐标
      SaveR(6);
      InScene(0);
      event.key.keysym.sym := 0;
      event.button.button := 0;
      //waitanykey;
    end;
    //instruct_13;
  end;
  //result:=canentrance;

end;

{
procedure UpdateSceneAmi;
var
  now, next_time: uint32;
  i: integer;
begin

  next_time:=sdl_getticks;
  now:=sdl_getticks;
  while true do
  begin
    now:=sdl_getticks;
    if now>=next_time then
    begin
      LockScene:=true;
      for i:=0 to 199 do
      if DData[CurScene, [i,6]<>DData[CurScene, [i,7] then
      begin
        if (DData[CurScene, [i,5]<5498) or (DData[CurScene, [i,5]>5692) then
        begin
          DData[CurScene, [i,5]:=DData[CurScene, [i,5]+2;
          if DData[CurScene, [i,5]>DData[CurScene, [i,6] then DData[CurScene, [i,5]:=DData[CurScene, [i,7];
          updateScene(DData[CurScene, [i,10],DData[CurScene, [i,9]);
        end;
      end;
      //initialScene;
      sdl_delay(10);
      next_time:=next_time+200;
      LockScene:=false;
    end;
  end;

end;}

//Walk in a Scene, the returned value is the Scene number when you exit. If it is -1.
//InScene(1) means the new game.
//在内场景行走, 如参数为1表示新游戏

function InScene(Open: integer): integer;
var
  grp, idx, offset, axp, ayp, just, i3, i1, i2, x, y, old: integer;
  Sx1, Sy1, updatearea, r, s, i, menu, walking, PreScene: integer;
  filename: string;
  Scenename: WideString;
  now, next_time, next_time2: uint32;
  //UpDate: PSDL_Thread;
begin
  //UpDate:=SDL_CreateThread(@UpdateSceneAmi, nil);
  //LockScene:=false;
  next_time := sdl_getticks;
  next_time2 := next_time + 800;

  nowstep := -1;
  updatearea := 0;
  Where := 1;
  now2 := 0;
  resetpallet;
  walking := 0;
  just := 0;
  CurEvent := -1;
  SDL_EnableKeyRepeat(30, (30 * gamespeed) div 10);
  InitialScene;

  if Open = 1 then
  begin
    Sx := BEGIN_Sx;
    Sy := BEGIN_Sy;
    Cx := Sx;
    Cy := Sy;
    CurEvent := BEGIN_EVENT;
    DrawScene;
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    Callevent(BEGIN_EVENT);
    CurEvent := -1;

  end;

  DrawScene;
  ShowSceneName(CurScene);
  //是否有第3类事件位于场景入口
  CheckEvent3;
  i3 := 0;
  Rs := 0;
  while (SDL_PollEvent(@event) >= 0) do
  begin

    // i3:=i3+1;
    // if i3>12 then i3:=0;

    if where >= 3 then
    begin
      break;
    end;
    if where = 0 then
    begin
      exit;
    end;
    if sx > 63 then
      sx := 63;
    if sy > 63 then
      sy := 63;
    if sx < 0 then
      sx := 0;
    if sy < 0 then
      sy := 0;
    //场景内动态效果
    now := sdl_getticks;
    // if i3=0 then

    //next_time:=sdl_getticks;

    //检查是否位于出口, 如是则退出
    if (((sx = RScene[CurScene].ExitX[0]) and (sy = RScene[CurScene].ExitY[0])) or
      ((sx = RScene[CurScene].ExitX[1]) and (sy = RScene[CurScene].ExitY[1])) or
      ((sx = RScene[CurScene].ExitX[2]) and (sy = RScene[CurScene].ExitY[2]))) then
    begin
      nowstep := -1;
      ReSetEntrance;
      Where := 0;
      resetpallet;
      Result := -1;
      break;
    end
    else if integer(now - next_time) > 0 then
    begin

      if (water >= 0) then
      begin
        Inc(water, 6);
        if (water > 180) then water := 0;
      end;
      if Showanimation = 0 then
      begin
        for i := 0 to 199 do
          if ((DData[CurScene, i, 8] <> 0) or (abs(DData[CurScene, i, 7]) < abs(DData[CurScene, i, 6]))) then
          begin
            //屏蔽了旗子的动态效果, 因贴图太大不好处理
            old := DData[CurScene, i, 5];
            DData[CurScene, i, 5] := DData[CurScene, i, 5] + 2 * sign(DData[CurScene, i, 5]);
            if abs(DData[CurScene, i, 5]) > abs(DData[CurScene, i, 6]) then
              DData[CurScene, i, 5] := DData[CurScene, i, 7];
            updateScene(DData[CurScene, i, 10], DData[CurScene, i, 9], old, DData[CurScene, i, 5]);
          end;
      end;
      if time >= 0 then
      begin
        if integer(now - next_time2) > 0 then
        begin
          if (timeevent > 0) then
          begin
            time := time - 1;
          end;
          if time < 0 then
          begin
            callevent(timeevent);
          end;
          next_time2 := now + 1000;
        end;
      end;
      next_time := now + 200;
      rs := 0;
      DrawScene;
      rs := 1;
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    end;

    //是否处于行走状态, 参考Walk
    if walking = 1 then
    begin
      if nowstep >= 0 then
      begin
        if sign(linex[nowstep] - Sy) < 0 then
          SFace := 2
        else if sign(linex[nowstep] - Sy) > 0 then
          sFace := 1
        else if sign(liney[nowstep] - SX) > 0 then
          SFace := 3
        else sFace := 0;

        SStep := SStep + 1;

        if SStep >= 7 then SStep := 1;

        // if (SData[CurScene, 3, liney[nowstep], linex[nowstep]] >= 0) and (DData[CurScene, SData[CurScene, 3, liney[nowstep], linex[nowstep]], 4] > 0) then
        // saver(6);

        Sy := linex[nowstep];
        sx := liney[nowstep];
        Redraw;
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

        rs := 1;
        SDL_Delay((5 * GameSpeed) div 10);
        if (water < 0) then
        begin
          SDL_Delay((10 * GameSpeed) div 10);
        end;

        DrawScene;
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        CheckEvent3;
        if RandomEvent > 0 then
          if Random(100) = 0 then
          begin
            //  saver(6);
            callevent(RandomEvent);
            nowstep := -1;
          end;
        Dec(nowstep);
      end
      else
      begin
        walking := 0;
        rs := 1;
      end;
    end;

    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then
          Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYUP:
      begin

        rs := 1;
        if (event.key.keysym.sym = sdlk_escape) then
        begin
          newMenuEsc;
          if where = 0 then
          begin
            if RScene[CurScene].ExitMusic >= 0 then
            begin
              stopmp3;
              playmp3(RScene[CurScene].ExitMusic, -1);
            end;
            redraw;
            SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            exit;
          end;
          walking := 0;
        end;
        //检查是否按下Left Alt+Enter, 是则切换全屏/窗口(似乎并不经常有效)
        if (event.key.keysym.sym = sdlk_f5) then
        begin
          SwitchFullscreen;
          Kys_ini.WriteInteger('set', 'fullscreen', fullscreen);
        end;
        //按下回车或空格, 检查面对方向是否有第1类事件
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          x := Sx;
          y := Sy;
          case SFace of
            0: x := x - 1;
            1: y := y + 1;
            2: y := y - 1;
            3: x := x + 1;
          end;
          //如有则调用事件
          if SData[CurScene, 3, x, y] >= 0 then
          begin
            CurEvent := SData[CurScene, 3, x, y];
            walking := 0;
            if DData[CurScene, CurEvent, 2] >= 0 then
            begin
              // SaveR(6);
              callevent(DData[CurScene, SData[CurScene, 3, x, y], 2]);
            end;
          end;
          CurEvent := -1;
        end;

        if (event.key.keysym.sym = sdlk_f4) then
        begin
          if gametime > 0 then
          begin
            menu := 0;
            setlength(Menustring, 0);
            setlength(menustring, 2);
            //showmessage('');
            setlength(menuengstring, 2);
            menustring[0] := UTF8Decode(' 回合制');
            menustring[1] := UTF8Decode(' 半即時');
            menu := commonmenu(27, 30, 90, 1, battlemode div 2);
            if menu >= 0 then
            begin
              battlemode := min(2, menu * 2);
              Kys_ini.WriteInteger('set', 'battlemode', battlemode);
            end;
            setlength(Menustring, 0);
            setlength(menuengstring, 0);
          end;
        end;

        if (event.key.keysym.sym = sdlk_f3) then
        begin
          menu := 0;
          setlength(Menustring, 0);
          setlength(menustring, 2);
          //showmessage('');
          setlength(menuengstring, 2);
          menustring[0] := UTF8Decode(' 天氣特效：開');
          menuengstring[0] := ' ';
          menustring[1] := UTF8Decode(' 天氣特效：關');
          menuengstring[1] := ' ';
          menu := commonmenu(27, 30, 180, 1, effect);
          if menu >= 0 then
          begin
            effect := menu;
            Kys_ini.WriteInteger('set', 'effect', effect);
          end;
          setlength(Menustring, 0);
          setlength(menuengstring, 0);
        end;


        if (event.key.keysym.sym = sdlk_f1) then
        begin
          menu := 0;
          setlength(Menustring, 0);
          setlength(menustring, 2);
          //showmessage('');
          setlength(menuengstring, 2);
          menustring[0] := UTF8Decode(' 繁體字');
          menuengstring[0] := ' ';
          menustring[1] := UTF8Decode(' 簡體字');
          menuengstring[1] := ' ';
          menu := commonmenu(27, 30, 90, 1, simple);
          if menu >= 0 then
          begin
            simple := menu;
            Kys_ini.WriteInteger('set', 'simple', simple);
          end;
          setlength(Menustring, 0);
          setlength(menuengstring, 0);
        end;

        if (event.key.keysym.sym = sdlk_f2) then
        begin
          menu := 0;
          setlength(Menustring, 0);
          setlength(menustring, 3);
          //showmessage('');
          setlength(menuengstring, 3);
          menustring[0] := UTF8Decode(' 遊戲速度：快');
          menuengstring[0] := ' ';
          menustring[1] := UTF8Decode(' 遊戲速度：中');
          menuengstring[1] := ' ';
          menustring[2] := UTF8Decode(' 遊戲速度：慢');
          menuengstring[2] := ' ';
          menu := commonmenu(27, 30, 180, 2, min(gamespeed div 10, 2));
          if menu >= 0 then
          begin
            if menu = 0 then gamespeed := 1;
            if menu = 1 then gamespeed := 10;
            if menu = 2 then gamespeed := 20;
            Kys_ini.WriteInteger('constant', 'game_speed', gamespeed);
          end;
          setlength(Menustring, 0);
          setlength(menuengstring, 0);
        end;

        if (event.key.keysym.sym = sdlk_f6) then
        begin
          saver(6);
          ShowSaveSuccess;
        end;

        CheckHotkey(event.key.keysym.sym);
      end;
      SDL_KEYDOWN:
      begin
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) then
        begin
          SFace := 2;
          SStep := Sstep + 1;
          if SStep = 7 then
            SStep := 1;
          if canwalkinScene(Sx, Sy - 1) = True then
          begin
            //  if (SData[CurScene, 3, sx, sy - 1] >= 0) and (DData[CurScene, SData[CurScene, 3, sx, sy - 1], 4] > 0) then
            //  SaveR(6);
            Sy := Sy - 1;
          end;
        end;
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_KP6) then
        begin
          SFace := 1;
          SStep := Sstep + 1;
          if SStep = 7 then
            SStep := 1;
          if canwalkinScene(Sx, Sy + 1) = True then
          begin
              {if (SData[CurScene, 3, sx, sy + 1] >= 0) and (DData[CurScene, SData[CurScene, 3, sx, sy + 1], 4] > 0) then
                SaveR(6);  }
            Sy := Sy + 1;
          end;
        end;
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          SFace := 0;
          SStep := Sstep + 1;
          if SStep = 7 then
            SStep := 1;
          if canwalkinScene(Sx - 1, Sy) = True then
          begin
          {    if (SData[CurScene, 3, sx - 1, sy] >= 0) and (DData[CurScene, SData[CurScene, 3, sx - 1, sy], 4] > 0) then
                SaveR(6);    }
            Sx := Sx - 1;
          end;
        end;
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then
        begin
          SFace := 3;
          SStep := Sstep + 1;
          if SStep = 7 then
            SStep := 1;
          if canwalkinScene(Sx + 1, Sy) = True then
          begin
          {    if (SData[CurScene, 3, sx + 1, sy] >= 0) and (DData[CurScene, SData[CurScene, 3, sx + 1, sy], 4] > 0) then
                SaveR(6); }
            Sx := Sx + 1;
          end;
        end;
        rs := 1;
        SDL_Delay((5 * GameSpeed) div 10);
        if (water < 0) then
          SDL_Delay((10 * GameSpeed) div 10);
        DrawScene;
        nowstep := -1;
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        CheckEvent3;
        if (RandomEvent > 0) and (Random(100) = 0) then
        begin
          //   saver(6);
          callevent(RandomEvent);
          nowstep := -1;
        end;
      end;
      Sdl_mousebuttonup:
      begin
        if event.button.button = sdl_button_right then
        begin
          newmenuesc;
          nowstep := 0;
          walking := 0;
        end;
        if where = 0 then
        begin
          if RScene[CurScene].ExitMusic >= 0 then
          begin
            stopmp3;
            playmp3(RScene[CurScene].ExitMusic, -1);
          end;
          redraw;
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          exit;
        end
        else if event.button.button = sdl_button_left then
        begin
          if walking = 0 then
          begin
            walking := 1;
            Ayp := (-round(event.button.x / (RealScreen.w / screen.w)) + CENTER_x + 2 *
              (round(event.button.y / (RealScreen.h / screen.h)) + Sdata[curscene, 4, sx, sy]) - 2 * CENTER_y + 18) div 36 + Sx;
            Axp := (round(event.button.x / (RealScreen.w / screen.w)) - CENTER_x + 2 *
              (round(event.button.y / (RealScreen.h / screen.h)) + Sdata[curscene, 4, sx, sy]) - 2 * CENTER_y + 18) div 36 + Sy;
            if (ayp in [0..63]) and (axp in [0..63]) then
            begin
              for i := 0 to 63 do
                for i1 := 0 to 63 do
                  Fway[i, i1] := -1;
              findway(SY, SX);
              Moveman(SY, sx, axp, ayp);
              nowstep := Fway[axp, ayp] - 1;
              rs := 1;
            end
            else
            begin
              walking := 0;
              rs := 1;
            end;
          end;
        end;
      end;
    end;

    if water >= 0 then SDL_Delay((5 * GameSpeed) div 10)

    else SDL_Delay((10 * GameSpeed) div 10);

    event.key.keysym.sym := 0;
    event.button.button := 0;

  end;

  instruct_14; //黑屏
  SDL_EnableKeyRepeat(30, (30 * GameSpeed) div 10);
  //ReDraw;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  if RScene[CurScene].ExitMusic >= 0 then
  begin
    stopmp3;
    playmp3(RScene[CurScene].ExitMusic, -1);
  end;

end;

procedure ShowSceneName(snum: integer);
var
  Scenename: WideString;
  p: pbyte;
  Name: array[0..9] of byte;
  i: integer;
begin
  //显示场景名
  p := @rScene[snum].Name[0];
  for i := 0 to 8 do
  begin
    Name[i] := p^;
    Inc(p);
  end;
  Name[9] := 0;
  Scenename := gbktounicode(@Name[0]);
  drawtextwithrect(@Scenename[1], 320 - length(PChar(@Name)) * 5 + 7, 100, length(PChar(@Name)) *
    10 + 6, colcolor(0, 5), colcolor(0, 7));
  //waitanykey;
  //改变音乐
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  if RScene[snum].EntranceMusic >= 0 then
  begin
    stopmp3;
    playmp3(RScene[snum].EntranceMusic, -1);
  end;
  SDL_Delay((500 * GameSpeed) div 10);

end;

procedure ShowSaveSuccess;
var
  Scenename: WideString;
begin
  //显示场景名
  Scenename := UTF8Decode('  保存成功');
  drawtextwithrect(@Scenename[1], 320 - 50 + 7, 100, 100 + 6, colcolor(0, 5), colcolor(0, 7));
  //waitanykey;
  //改变音乐
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

  waitanykey;

end;
//判定场景内某个位置能否行走

function CanWalkInScene(x, y: integer): boolean; overload;
begin
  Result := True;
  if (SData[CurScene, 1, x, y] <= 0) and (SData[CurScene, 1, x, y] >= -2) then
    Result := True
  else
    Result := False;
  if (abs(SData[CurScene, 4, x, y] - SData[CurScene, 4, sx, sy]) > 10) then
    Result := False;
  if (SData[CurScene, 3, x, y] >= 0) and (Result) and (DData[CurScene, SData[CurScene, 3, x, y], 0] = 1) then
    Result := False;
  //直接判定贴图范围
  if ((SData[CurScene, 0, x, y] >= 358) and (SData[CurScene, 0, x, y] <= 362)) or
    (SData[CurScene, 0, x, y] = 522) or (SData[CurScene, 0, x, y] = 1022) or
    ((SData[CurScene, 0, x, y] >= 1324) and (SData[CurScene, 0, x, y] <= 1330)) or
    (SData[CurScene, 0, x, y] = 1348) then
    Result := False;
  //if SData[CurScene, 0, x, y] = 1358 * 2 then result := true;

end;

function CanWalkInScene(x1, y1, x, y: integer): boolean; overload;
begin
  Result := True;
  if (SData[CurScene, 1, x, y] <= 0) and (SData[CurScene, 1, x, y] >= -2) then
    Result := True
  else
    Result := False;
  if (abs(SData[CurScene, 4, x, y] - SData[CurScene, 4, x1, y1]) > 10) then
    Result := False;
  if (SData[CurScene, 3, x, y] >= 0) and (Result) and (DData[CurScene, SData[CurScene, 3, x, y], 0] = 1) then
    Result := False;
  //直接判定贴图范围
  if ((SData[CurScene, 0, x, y] >= 358) and (SData[CurScene, 0, x, y] <= 362)) or
    (SData[CurScene, 0, x, y] = 522) or (SData[CurScene, 0, x, y] = 1022) or
    ((SData[CurScene, 0, x, y] >= 1324) and (SData[CurScene, 0, x, y] <= 1330)) or
    (SData[CurScene, 0, x, y] = 1348) then
    Result := False;
  //if SData[CurScene, 0, x, y] = 1358 * 2 then result := true;

end;
//检查是否有第3类事件, 如有则调用

procedure CheckEvent3;
var
  enum: integer;
begin
  enum := SData[CurScene, 3, Sx, Sy];
  if (enum >= 0) and (DData[CurScene, enum, 4] > 0) then
  begin
    // saver(5);
    CurEvent := enum;
    //waitanykey;

    nowstep := -1;
    callevent(DData[CurScene, enum, 4]);
    CurEvent := -1;
  end;
end;

//Menus.
//通用选单, (位置(x, y), 宽度, 最大选项(编号均从0开始))
//使用前必须设置选单使用的字符串组才有效, 字符串组不可越界使用

function CommonMenu(x, y, w, max: integer): integer;
var
  menu, menup: integer;
begin
  menu := 0;
  SDL_EnableKeyRepeat(10, 100);
  //DrawMMap;
  showcommonMenu(x, y, w, max, menu);
  SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then
          Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYDown:
      begin
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then
        begin
          menu := menu + 1;
          if menu > max then
            menu := 0;
          showcommonMenu(x, y, w, max, menu);
          SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
        end;
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          menu := menu - 1;
          if menu < 0 then
            menu := max;
          showcommonMenu(x, y, w, max, menu);
          SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
        end;
      end;

      SDL_KEYUP:
      begin
        if ((event.key.keysym.sym = sdlk_escape)) then
        begin
          Result := -1;
          ReDraw;
          SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          break;
        end;
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          Result := menu;
          Redraw;
          SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          break;
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_right) then
        begin
          Result := -1;
          ReDraw;
          SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          break;
        end;
        if (event.button.button = sdl_button_left) then
        begin
          Result := menu;
          Redraw;
          SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          break;
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        if (round(event.button.x / (RealScreen.w / screen.w)) >= x) and
          (round(event.button.x / (RealScreen.w / screen.w)) < x + w) and
          (round(event.button.y / (RealScreen.h / screen.h)) > y) and
          (round(event.button.y / (RealScreen.h / screen.h)) < y + max * 22 + 29) then
        begin
          menup := menu;
          menu := (round(event.button.y / (RealScreen.h / screen.h)) - y - 2) div 22;
          if menu > max then
            menu := max;
          if menu < 0 then
            menu := 0;
          if menup <> menu then
          begin
            showcommonMenu(x, y, w, max, menu);
            SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          end;
        end;
      end;
    end;
  end;
  //清空键盘键和鼠标键值, 避免影响其余部分
  event.key.keysym.sym := 0;
  event.button.button := 0;
  SDL_EnableKeyRepeat(30, 30);
end;

function CommonMenu(x, y, w, max, default: integer): integer; overload;
var
  menu, menup: integer;
begin
  menu := default;
  SDL_EnableKeyRepeat(10, 100);
  //DrawMMap;
  showcommonMenu(x, y, w, max, menu);
  SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then
          Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYDown:
      begin
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then
        begin
          menu := menu + 1;
          if menu > max then
            menu := 0;
          showcommonMenu(x, y, w, max, menu);
          SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
        end;
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          menu := menu - 1;
          if menu < 0 then
            menu := max;
          showcommonMenu(x, y, w, max, menu);
          SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
        end;
      end;

      SDL_KEYUP:
      begin
        if ((event.key.keysym.sym = sdlk_escape)) then
        begin
          Result := -1;
          ReDraw;
          SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          break;
        end;
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          Result := menu;
          //Redraw;
          SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          break;
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_right) then
        begin
          Result := -1;
          ReDraw;
          SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          break;
        end;
        if (event.button.button = sdl_button_left) then
        begin
          Result := menu;
          //Redraw;
          SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          break;
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        if (round(event.button.x / (RealScreen.w / screen.w)) >= x) and
          (round(event.button.x / (RealScreen.w / screen.w)) < x + w) and
          (round(event.button.y / (RealScreen.h / screen.h)) > y) and
          (round(event.button.y / (RealScreen.h / screen.h)) < y + max * 22 + 29) then
        begin
          menup := menu;
          menu := (round(event.button.y / (RealScreen.h / screen.h)) - y - 2) div 22;
          if menu > max then
            menu := max;
          if menu < 0 then
            menu := 0;
          if menup <> menu then
          begin
            showcommonMenu(x, y, w, max, menu);
            SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          end;
        end;
      end;
    end;
  end;
  //清空键盘键和鼠标键值, 避免影响其余部分
  event.key.keysym.sym := 0;
  event.button.button := 0;
  SDL_EnableKeyRepeat(30, 30);

end;

//显示通用选单(位置, 宽度, 最大值)
//这个通用选单包含两个字符串组, 可分别显示中文和英文

procedure ShowCommonMenu(x, y, w, max, menu: integer);
var
  i, p, l: integer;
begin
  redraw;
  DrawRectangle(x, y, w, max * 22 + 28, 0, colcolor(255), 30);
  l := length(Menuengstring);
  if l > 0 then
    p := 1
  else
    p := 0;
  for i := 0 to max do
    if i = menu then
    begin
      drawshadowtext(@menustring[i][1], x - 17, y + 2 + 22 * i, colcolor($64), colcolor($66));
      if (p = 1) and (p < l) then
        drawengshadowtext(@menuengstring[i][1], x + 73, y + 2 + 22 * i, colcolor($64), colcolor($66));
    end
    else
    begin
      drawshadowtext(@menustring[i][1], x - 17, y + 2 + 22 * i, colcolor($5), colcolor($7));
      if (p = 1) and (p < l) then
        drawengshadowtext(@menuengstring[i][1], x + 73, y + 2 + 22 * i, colcolor($5), colcolor($7));
    end;

end;

//卷动选单

function CommonScrollMenu(x, y, w, max, maxshow: integer): integer;
var
  menu, menup, menutop: integer;
begin

  menu := 0;
  menutop := 0;
  SDL_EnableKeyRepeat(10, 100);
  //DrawMMap;
  maxshow := min(max + 1, maxshow);
  showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
  SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then
          Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYdown:
      begin
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then
        begin
          menu := menu + 1;
          if menu - menutop >= maxshow then
          begin
            menutop := menutop + 1;
          end;
          if menu > max then
          begin
            menu := 0;
            menutop := 0;
          end;
          showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
        end;
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          menu := menu - 1;
          if menu <= menutop then
          begin
            menutop := menu;
          end;
          if menu < 0 then
          begin
            menu := max;
            menutop := menu - maxshow + 1;
            if menutop < 0 then menutop := 0;
          end;
          showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
        end;
        if (event.key.keysym.sym = sdlk_pagedown) then
        begin
          menu := menu + maxshow;
          menutop := menutop + maxshow;
          if menu > max then
          begin
            menu := max;
          end;
          if menutop > max - maxshow + 1 then
          begin
            menutop := max - maxshow + 1;
          end;
          showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
        end;
        if (event.key.keysym.sym = sdlk_pageup) then
        begin
          menu := menu - maxshow;
          menutop := menutop - maxshow;
          if menu < 0 then
          begin
            menu := 0;
          end;
          if menutop < 0 then
          begin
            menutop := 0;
          end;
          showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
        end;

      end;

      SDL_KEYup:
      begin
        if ((event.key.keysym.sym = sdlk_escape)) and (where <= 2) then
        begin
          Result := -1;
          ReDraw;
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
          break;
        end;
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          Result := menu;
          Redraw;
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
          break;
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_right) and (where <= 2) then
        begin
          Result := -1;
          ReDraw;
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
          break;
        end;
        if (event.button.button = sdl_button_left) then
        begin
          Result := menu;
          Redraw;
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
          break;
        end;
        if (event.button.button = sdl_button_wheeldown) then
        begin
          menu := menu + 1;
          if menu - menutop >= maxshow then
          begin
            menutop := menutop + 1;
          end;
          if menu > max then
          begin
            menu := 0;
            menutop := 0;
          end;
          showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
        end;
        if (event.button.button = sdl_button_wheelup) then
        begin
          menu := menu - 1;
          if menu <= menutop then
          begin
            menutop := menu;
          end;
          if menu < 0 then
          begin
            menu := max;
            menutop := menu - maxshow + 1;
            if menutop < 0 then
            begin
              menutop := 0;
            end;
          end;
          showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        if (round(event.button.x / (RealScreen.w / screen.w)) >= x) and
          (round(event.button.x / (RealScreen.w / screen.w)) < x + w) and
          (round(event.button.y / (RealScreen.h / screen.h)) > y) and
          (round(event.button.y / (RealScreen.h / screen.h)) < y + max * 22 + 29) then
        begin
          menup := menu;
          menu := (round(event.button.y / (RealScreen.h / screen.h)) - y - 2) div 22 + menutop;
          if menu > max then
            menu := max;
          if menu < 0 then
            menu := 0;
          if menup <> menu then
          begin
            showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
            SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
          end;
        end;
      end;
    end;
  end;
  //清空键盘键和鼠标键值, 避免影响其余部分
  event.key.keysym.sym := 0;
  event.button.button := 0;
  SDL_EnableKeyRepeat(30, 30);

end;

procedure ShowCommonScrollMenu(x, y, w, max, maxshow, menu, menutop: integer);
var
  i, p, m: integer;
begin

  redraw;
  //showmessage(inttostr(y));
  m := min(maxshow, max + 1);
  DrawRectangle(x, y, w, m * 22 + 6, 0, colcolor(255), 30);
  if length(Menuengstring) > 0 then
    p := 1
  else
    p := 0;
  for i := menutop to menutop + m - 1 do
  begin
    if i = menu then
    begin
      drawshadowtext(@menustring[i][1], x - 17, y + 2 + 22 * (i - menutop), colcolor($64), colcolor($66));
      if p = 1 then
        drawengshadowtext(@menuengstring[i][1], x + 73, y + 2 + 22 * (i - menutop), colcolor($64), colcolor($66));
    end
    else
    begin
      drawshadowtext(@menustring[i][1], x - 17, y + 2 + 22 * (i - menutop), colcolor($5), colcolor($7));
      if p = 1 then
        drawengshadowtext(@menuengstring[i][1], x + 73, y + 2 + 22 * (i - menutop), colcolor($5), colcolor($7));
    end;
  end;
end;


//仅有两个选项的横排选单, 为美观使用横排
//此类选单中每个选项限制为两个中文字, 仅适用于提问'继续', '取消'的情况


function CommonMenu2(x, y, w: integer): integer;
var
  menu, menup: integer;
begin
  menu := 0;
  SDL_EnableKeyRepeat(10, 100);
  //DrawMMap;
  redraw;
  showcommonMenu2(x, y, w, menu);
  SDL_UpdateRect2(screen, x, y, w + 1, 29);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then
          Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYDown:
      begin
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_right) or
          (event.key.keysym.sym = sdlk_KP6) or (event.key.keysym.sym = sdlk_KP4) then
        begin
          if menu = 1 then
            menu := 0
          else
            menu := 1;
          redraw;
          showcommonMenu2(x, y, w, menu);
          SDL_UpdateRect2(screen, x, y, w + 1, 29);
        end;
      end;

      SDL_KEYUP:
      begin

        if ((event.key.keysym.sym = sdlk_escape)) and (where <= 2) then
        begin
          Result := -1;
          redraw;
          SDL_UpdateRect2(screen, x, y, w + 1, 29);
          break;
        end;
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          Result := menu;
          redraw;
          SDL_UpdateRect2(screen, x, y, w + 1, 29);
          break;
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_right) and (where <= 2) then
        begin
          Result := -1;
          redraw;
          SDL_UpdateRect2(screen, x, y, w + 1, 29);
          break;
        end;
        if (event.button.button = sdl_button_left) then
        begin
          Result := menu;
          redraw;
          SDL_UpdateRect2(screen, x, y, w + 1, 29);
          break;
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        if (round(event.button.x / (RealScreen.w / screen.w)) >= x) and
          (round(event.button.x / (RealScreen.w / screen.w)) < x + w) and
          (round(event.button.y / (RealScreen.h / screen.h)) > y) and
          (round(event.button.y / (RealScreen.h / screen.h)) < y + 29) then
        begin
          menup := menu;
          menu := (round(event.button.x / (RealScreen.w / screen.w)) - x - 2) div 50;
          if menu > 1 then
            menu := 1;
          if menu < 0 then
            menu := 0;
          if menup <> menu then
          begin
            redraw;
            showcommonMenu2(x, y, w, menu);
            SDL_UpdateRect2(screen, x, y, w + 1, 29);
          end;
        end;
      end;
    end;
  end;
  //清空键盘键和鼠标键值, 避免影响其余部分
  event.key.keysym.sym := 0;
  event.button.button := 0;
  SDL_EnableKeyRepeat(30, 30);

end;

//显示仅有两个选项的横排选单

procedure ShowCommonMenu2(x, y, w, menu: integer);
var
  i, p: integer;
begin
  //ReDraw;
  DrawRectangle(x, y, w, 28, 0, colcolor(255), 30);
  //if length(Menuengstring) > 0 then p := 1 else p := 0;
  for i := 0 to 1 do
    if i = menu then
    begin
      drawshadowtext(@menustring[i][1], x - 17 + i * 50, y + 2, colcolor($64), colcolor($66));
    end
    else
    begin
      drawshadowtext(@menustring[i][1], x - 17 + i * 50, y + 2, colcolor($5), colcolor($7));
    end;

end;

//选择一名队员, 可以附带两个属性显示

function SelectOneTeamMember(x, y: integer; str: string; list1, list2: integer): integer;
var
  i, amount: integer;
begin
  setlength(Menustring, 0);
  setlength(Menustring, 6);
  if str <> '' then
    setlength(Menuengstring, 6)
  else
    setlength(Menuengstring, 0);
  amount := 0;

  for i := 0 to 5 do
  begin
    if Teamlist[i] >= 0 then
    begin
      menustring[i] := gbktounicode(@RRole[Teamlist[i]].Name);
      if str <> '' then
      begin
        menuengstring[i] := format(str, [Rrole[teamlist[i]].Data[list1], Rrole[teamlist[i]].Data[list2]]);
      end;
      amount := amount + 1;
    end;
  end;
  if str = '' then
    Result := commonmenu(x, y, 85, amount - 1)
  else
    Result := commonmenu(x, y, 85 + length(menuengstring[0]) * 10, amount - 1);

end;

//主选单

procedure MenuEsc;
var
  menu, menup: integer;
begin
  menu := 0;
  while menu >= 0 do
  begin
    setlength(Menustring, 0);
    setlength(menustring, 8);
    //showmessage('');
    setlength(menuengstring, 8);
    menustring[0] := UTF8Decode(' 狀態');
    menustring[1] := UTF8Decode(' 物品');
    menustring[2] := UTF8Decode(' 武學');
    menustring[3] := UTF8Decode(' 技能');
    menustring[4] := UTF8Decode(' 內功');
    menustring[5] := UTF8Decode(' 離隊');
    menustring[6] := UTF8Decode(' 系統');
    menustring[7] := UTF8Decode(' 說明');
    menu := commonmenu(27, 30, 46, 7, menu);
    //ShowCommonMenu(15, 15, 75, 3, r);
    //SDL_UpdateRect2(screen, 15, 15, 76, 316);
    case menu of
      0:
      begin
        SelectShowStatus;
        redraw;
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      end;
      1:
      begin
        // MenuItem; redraw;
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      end;
      2:
      begin
        SelectShowMagic;
        redraw;
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      end;
      3:
      begin
        FourPets;
        redraw;
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      end;
      4: ExecScript('test.lua', 'f1');
      5:
      begin
        //  MenuLeave;
        redraw;
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      end;
      6:
      begin
        NewMenuSystem;
        redraw;
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        break;
      end;
      7:
      begin
        ResistTheater;
        redraw;
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      end;
    end;
  end;
  SDL_EnableKeyRepeat(100, 30);

end;

//显示主选单

procedure ShowMenu(menu: integer);
var
  word: array[0..5] of WideString;
  i, max: integer;
begin
  word[0] := UTF8Decode(' 醫療');
  word[1] := UTF8Decode(' 解毒');
  word[2] := UTF8Decode(' 物品');
  word[3] := UTF8Decode(' 狀態');
  word[4] := UTF8Decode(' 離隊');
  word[5] := UTF8Decode(' 系統');
  if where = 0 then
    max := 5
  else
    max := 3;
  ReDraw;
  DrawRectangle(27, 30, 46, max * 22 + 28, 0, colcolor(255), 30);
  //当前所在位置用白色, 其余用黄色
  for i := 0 to max do
    if i = menu then
    begin
      drawtext(screen, @word[i][1], 11, 32 + 22 * i, colcolor($64));
      drawtext(screen, @word[i][1], 10, 32 + 22 * i, colcolor($66));
    end
    else
    begin
      drawtext(screen, @word[i][1], 11, 32 + 22 * i, colcolor($5));
      drawtext(screen, @word[i][1], 10, 32 + 22 * i, colcolor($7));
    end;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

end;

//医疗选单, 需两次选择队员

procedure MenuMedcine;
var
  role1, role2, menu: integer;
  str: WideString;
begin
  str := UTF8Decode(' 隊員醫療能力');
  drawtextwithrect(@str[1], 80, 30, 132, colcolor($21), colcolor($23));
  menu := SelectOneTeamMember(80, 65, '%3d', 46, 0);
  showmenu(0);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  if menu >= 0 then
  begin
    role1 := TeamList[menu];
    str := UTF8Decode(' 隊員目前生命');
    drawtextwithrect(@str[1], 80, 30, 132, colcolor($21), colcolor($23));
    menu := SelectOneTeamMember(80, 65, '%4d/%4d', 17, 18);
    role2 := TeamList[menu];
    if menu >= 0 then
      EffectMedcine(role1, role2);
  end;
  //waitanykey;
  redraw;
  //SDL_UpdateRect2(screen,0,0,screen.w,screen.h);

end;

//解毒选单

procedure MenuMedPoision;
var
  role1, role2, menu: integer;
  str: WideString;
begin
  str := UTF8Decode(' 隊員解毒能力');
  drawtextwithrect(@str[1], 80, 30, 132, colcolor($21), colcolor($23));
  menu := SelectOneTeamMember(80, 65, '%3d', 48, 0);
  showmenu(1);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  if menu >= 0 then
  begin
    role1 := TeamList[menu];
    str := UTF8Decode(' 隊員中毒程度');
    drawtextwithrect(@str[1], 80, 30, 132, colcolor($21), colcolor($23));
    menu := SelectOneTeamMember(80, 65, '%3d', 20, 0);
    role2 := TeamList[menu];
    if menu >= 0 then
      EffectMedPoision(role1, role2);
  end;
  //waitanykey;
  redraw;
  //showmenu(1);
  //SDL_UpdateRect2(screen,0,0,screen.w,screen.h);

end;

//物品选单

function MenuItem(menu: integer): boolean;
var
  point, atlu, x, y, col, row, xp, yp, iamount, max: integer;
  //point似乎未使用, atlu为处于左上角的物品在列表中的序号, x, y为光标位置
  //col, row为总列数和行数
begin
  col := 6;
  row := 3;
  x := 0;
  y := 0;
  atlu := 0;

  if menu = 0 then menu := 101;
  menu := menu - 1;

  iamount := ReadItemList(menu);
  showMenuItem(row, col, x, y, atlu);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  Result := True;
  while (SDL_WaitEvent(@event) >= 0) do
  begin

    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then
          Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then
        begin
          y := y + 1;
          if y < 0 then
            y := 0;
          if (y >= row) then
          begin
            if (ItemList[atlu + col * row] >= 0) then
              atlu := atlu + col;
            y := row - 1;
          end;
          showMenuItem(row, col, x, y, atlu);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          y := y - 1;
          if y < 0 then
          begin
            y := 0;
            if atlu > 0 then
              atlu := atlu - col;
          end;
          showMenuItem(row, col, x, y, atlu);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
        if (event.key.keysym.sym = sdlk_pagedown) then
        begin
          //y := y + row;
          atlu := atlu + col * row;
          if y < 0 then
            y := 0;
          if (ItemList[atlu + col * row] < 0) and (iamount > col * row) then
          begin
            y := y - (iamount - atlu) div col - 1 + row;
            atlu := (iamount div col - row + 1) * col;
            if y >= row then
              y := row - 1;
          end;
          showMenuItem(row, col, x, y, atlu);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
        if (event.key.keysym.sym = sdlk_pageup) then
        begin
          //y := y - row;
          atlu := atlu - col * row;
          if atlu < 0 then
          begin
            y := y + atlu div col;
            atlu := 0;
            if y < 0 then
              y := 0;
          end;
          showMenuItem(row, col, x, y, atlu);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_KP6) then
        begin
          x := x + 1;
          if x >= col then
            x := 0;
          showMenuItem(row, col, x, y, atlu);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) then
        begin
          x := x - 1;
          if x < 0 then
            x := col - 1;
          showMenuItem(row, col, x, y, atlu);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
        if (event.key.keysym.sym = sdlk_escape) then
        begin
          //ShowMenu(2);
          Result := True;
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          break;
        end;
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          // ReDraw;
          CurItem := RItemlist[itemlist[(y * col + x + atlu)]].Number;
          if (where <> 2) and (CurItem >= 0) and (itemlist[(y * col + x + atlu)] >= 0) then
            UseItem(CurItem);

          iamount := ReadItemList(menu);
          //ShowMenu(2);
          showMenuItem(row, col, x, y, atlu);
          if (Ritem[CurItem].ItemType <> 0) and (where <> 2) then Result := True
          else
          begin
            Result := False;
            break;
          end;
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          //  break;
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_right) then
        begin
          //ShowMenu(2);
          Result := False;
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          break;
        end;
        if (event.button.button = sdl_button_left) then
        begin
          //  ReDraw;
          CurItem := RItemlist[itemlist[(y * col + x + atlu)]].Number;
          if (where <> 2) and (CurItem >= 0) and (itemlist[(y * col + x + atlu)] >= 0) then
            UseItem(CurItem);

          iamount := ReadItemList(menu);
          showMenuItem(row, col, x, y, atlu);
          //ShowMenu(2);
          if (Ritem[CurItem].ItemType <> 0) and (where <> 2) then Result := True
          else
          begin
            Result := False;
            break;
          end;
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          //  break;
        end;
        if (event.button.button = sdl_button_wheeldown) then
        begin
          y := y + 1;
          if y < 0 then
            y := 0;
          if (y >= row) then
          begin
            if (ItemList[atlu + col * row] >= 0) then
              atlu := atlu + col;
            y := row - 1;
          end;
          showMenuItem(row, col, x, y, atlu);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
        if (event.button.button = sdl_button_wheelup) then
        begin
          y := y - 1;
          if y < 0 then
          begin
            y := 0;
            if atlu > 0 then
              atlu := atlu - col;
          end;
          showMenuItem(row, col, x, y, atlu);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        if (round(event.button.x / (RealScreen.w / screen.w)) < 122) then
        begin
          //   result := false;
          if where <> 2 then break;
        end;
        if (round(event.button.x / (RealScreen.w / screen.w)) >= 110) and
          (round(event.button.x / (RealScreen.w / screen.w)) < 612) and
          (round(event.button.y / (RealScreen.h / screen.h)) > 90) and
          (round(event.button.y / (RealScreen.h / screen.h)) < 316) then
        begin
          xp := x;
          yp := y;
          x := (round(event.button.x / (RealScreen.w / screen.w)) - 115) div 82;
          y := (round(event.button.y / (RealScreen.h / screen.h)) - 95) div 82;
          if x >= col then
            x := col - 1;
          if y >= row then
            y := row - 1;
          if x < 0 then
            x := 0;
          if y < 0 then
            y := 0;
          //鼠标移动时仅在x, y发生变化时才重画
          if (x <> xp) or (y <> yp) then
          begin
            showMenuItem(row, col, x, y, atlu);
            SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          end;
        end;
        if (round(event.button.x / (RealScreen.w / screen.w)) >= 110) and
          (round(event.button.x / (RealScreen.w / screen.w)) < 612) and
          (round(event.button.y / (RealScreen.h / screen.h)) > 312) then
        begin
          //atlu := atlu+col;
          y := y + 1;
          if y < 0 then
            y := 0;
          if (y >= row) then
          begin
            if (ItemList[atlu + col * row] >= 0) then
              atlu := atlu + col;
            y := row - 1;
          end;
          showMenuItem(row, col, x, y, atlu);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
        if (round(event.button.x / (RealScreen.w / screen.w)) >= 110) and
          (round(event.button.x / (RealScreen.w / screen.w)) < 612) and
          (round(event.button.y / (RealScreen.h / screen.h)) < 90) then
        begin
          if atlu > 0 then
            atlu := atlu - col;
          showMenuItem(row, col, x, y, atlu);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
      end;
    end;
  end;
  //SDL_UpdateRect2(screen,0,0,screen.w,screen.h);

end;

//读物品列表, 主要是战斗中需屏蔽一部分物品
//利用一个不可能用到的数值（100），表示读取所有物品

function ReadItemList(ItemType: integer): integer;
var
  i, p: integer;
begin
  p := 0;
  for i := 0 to length(ItemList) - 1 do
    ItemList[i] := -1;
  for i := 0 to MAX_ITEM_AMOUNT - 1 do
  begin
    if (RItemlist[i].Number >= 0) then
    begin
      if where = 2 then
      begin
        if (Ritem[RItemlist[i].Number].ItemType = 3) or (Ritem[RItemlist[i].Number].ItemType = 4) then
        begin
          Itemlist[p] := i;
          p := p + 1;
        end;
      end
      else if (Ritem[RItemlist[i].Number].ItemType = ItemType) or (ItemType = 100) then
      begin
        Itemlist[p] := i;
        p := p + 1;
      end;
    end;
  end;
  Result := p;

end;

//显示物品选单

procedure ShowMenuItem(row, col, x, y, atlu: integer);
var
  item, i, i1, i2, len, len2, len3, listnum: integer;
  str: WideString;
  words: array[0..10] of WideString;
  words2: array[0..22] of WideString;
  words3: array[0..13] of WideString;
  p2: array[0..22] of integer;
  p3: array[0..13] of integer;
begin
  words[0] := UTF8Decode(' 劇情物品');
  words[1] := UTF8Decode(' 神兵寶甲');
  words[2] := UTF8Decode(' 武功秘笈');
  words[3] := UTF8Decode(' 靈丹妙藥');
  words[4] := UTF8Decode(' 傷人暗器');
  words2[0] := UTF8Decode(' 生命');
  words2[1] := UTF8Decode(' 生命');
  words2[2] := UTF8Decode(' 中毒');
  words2[3] := UTF8Decode(' 體力');
  words2[4] := UTF8Decode(' 內力');
  words2[5] := UTF8Decode(' 內力');
  words2[6] := UTF8Decode(' 內力');
  words2[7] := UTF8Decode(' 攻擊');
  words2[8] := UTF8Decode(' 輕功');
  words2[9] := UTF8Decode(' 防禦');
  words2[10] := UTF8Decode(' 醫療');
  words2[11] := UTF8Decode(' 用毒');
  words2[12] := UTF8Decode(' 解毒');
  words2[13] := UTF8Decode(' 抗毒');
  words2[14] := UTF8Decode(' 拳掌');
  words2[15] := UTF8Decode(' 御劍');
  words2[16] := UTF8Decode(' 耍刀');
  words2[17] := UTF8Decode(' 奇門');
  words2[18] := UTF8Decode(' 暗器');
  words2[19] := UTF8Decode(' 武學');
  words2[20] := UTF8Decode(' 品德');
  words2[21] := UTF8Decode(' 左右');
  words2[22] := UTF8Decode(' 帶毒');

  words3[0] := UTF8Decode(' 內力');
  words3[1] := UTF8Decode(' 內力');
  words3[2] := UTF8Decode(' 攻擊');
  words3[3] := UTF8Decode(' 輕功');
  words3[4] := UTF8Decode(' 用毒');
  words3[5] := UTF8Decode(' 醫療');
  words3[6] := UTF8Decode(' 解毒');
  words3[7] := UTF8Decode(' 拳掌');
  words3[8] := UTF8Decode(' 御劍');
  words3[9] := UTF8Decode(' 耍刀');
  words3[10] := UTF8Decode(' 奇門');
  words3[11] := UTF8Decode(' 暗器');
  words3[12] := UTF8Decode(' 資質');
  words3[13] := UTF8Decode(' 性別');

  if where = 2 then
  begin
    redraw;
  end
  else
    display_imgFromSurface(MENUITEM_PIC, 110, 0, 110, 0, 530, 440);
  //ReDraw;
  drawrectangle(110 + 12, 16, 499, 25, 0, colcolor(0, 255), 40);
  drawrectangle(110 + 12, 46, 499, 25, 0, colcolor(0, 255), 40);
  drawrectangle(110 + 12, 76, 499, 252, 0, colcolor(0, 255), 40);
  drawrectangle(110 + 12, 335, 499, 86, 0, colcolor(0, 255), 40);
  //i:=0;
  for i1 := 0 to row - 1 do
    for i2 := 0 to col - 1 do
    begin
      listnum := ItemList[i1 * col + i2 + atlu];
      if (RItemlist[listnum].Number >= 0) and (listnum < MAX_ITEM_AMOUNT) and (listnum >= 0) then
      begin
        DrawItemPic(RItemlist[listnum].Number, i2 * 82 + 12 + 115, i1 * 82 + 95 - 14);
        //DrawMPic(ITEM_BEGIN_PIC + RItemlist[listnum].Number, i2 * 42 + 115, i1 * 42 + 95);
      end;
    end;
  listnum := itemlist[y * col + x + atlu];
  item := RItemlist[listnum].Number;

  if (RItemlist[listnum].Amount > 0) and (listnum < MAX_ITEM_AMOUNT) and (listnum >= 0) then
  begin
    str := format('%5d', [RItemlist[listnum].Amount]);
    drawengshadowtext(@str[1], 431 + 62 + 12, 32 - 14, colcolor(0, $64), colcolor(0, $66));
    len := length(PChar(@Ritem[item].Name));
    drawgbkshadowtext(@RItem[item].Name, 357 - len * 5 + 12, 32 - 14, colcolor(0, $21), colcolor(0, $23));
    len := length(PChar(@Ritem[item].Introduction));
    drawgbkshadowtext(@RItem[item].Introduction, 357 - len * 5 + 12, 62 - 14, colcolor(0, $5), colcolor(0, $7));
    drawshadowtext(@words[Ritem[item].ItemType, 1], 97 + 12, 315 + 36 - 14, colcolor(0, $21), colcolor(0, $23));
    //如有人使用则显示
    if RItem[item].User >= 0 then
    begin
      str := UTF8Decode(' 使用人：');
      drawshadowtext(@str[1], 187 + 12, 315, colcolor(0, $21), colcolor(0, $23));
      drawgbkshadowtext(@rrole[RItem[item].User].Name, 277 + 12, 315 + 36 - 14, colcolor(0, $64), colcolor(0, $66));
    end;
    //如是罗盘则显示坐标
    if item = COMPASS_ID then
    begin
      str := UTF8Decode(' 你的位置：');
      drawshadowtext(@str[1], 187 + 12, 315 + 36 - 14, colcolor(0, $21), colcolor(0, $23));
      str := format('%3d, %3d', [My, Mx]);
      drawengshadowtext(@str[1], 300 + 12, 315 + 36 - 14, colcolor(0, $64), colcolor(0, $66));
      str := UTF8Decode(' 船的位置：');
      drawshadowtext(@str[1], 387 + 12, 315 + 36 - 14, colcolor(0, $21), colcolor(0, $23));
      str := format('%3d, %3d', [Shipx, shipy]);
      drawengshadowtext(@str[1], 500 + 12, 315 + 36 - 14, colcolor(0, $64), colcolor(0, $66));
    end;
  end;

  if (RItemlist[listnum].Amount > 0) and (listnum < MAX_ITEM_AMOUNT) and (listnum >= 0) and
    (ritem[item].ItemType > 0) then
  begin
    len2 := 0;
    for i := 0 to 22 do
    begin
      p2[i] := 0;
      if (ritem[item].Data[45 + i] <> 0) and (i <> 4) then
      begin
        p2[i] := 1;
        len2 := len2 + 1;
      end;
    end;
    if ritem[item].ChangeMPType in [0..2] then
    begin
      p2[4] := 1;
      len2 := len2 + 1;
    end;

    len3 := 0;
    for i := 0 to 12 do
    begin
      p3[i] := 0;
      if (ritem[item].Data[69 + i] <> 0) and (i <> 0) then
      begin
        p3[i] := 1;
        len3 := len3 + 1;
      end;
    end;
    if (ritem[item].NeedMPType in [0, 1]) and (ritem[item].ItemType <> 3) and
      (ritem[item].ItemType <> 0) and (ritem[item].ItemType <> 4) then
    begin
      p3[0] := 1;
      len3 := len3 + 1;
    end;
    if (ritem[item].needSex in [0..2]) and (ritem[item].ItemType <> 3) and (ritem[item].ItemType <> 0) and
      (ritem[item].ItemType <> 4) then
    begin
      p3[13] := 1;
      len3 := len3 + 1;
    end;

    if len2 + len3 > 0 then
      //   drawrectangle(110+12, 344 + 36-14, 499, 20 * ((len2 + 2) div 3 + (len3 + 2) div 3) + 5, 0, colcolor(255), 30);

      i1 := 0;
    for i := 0 to 22 do
    begin
      if (p2[i] = 1) then
      begin

        if i = 4 then
          case ritem[item].ChangeMPType of
            0: str := UTF8Decode(' 陽');
            1: str := UTF8Decode(' 陰');
            2: str := UTF8Decode(' 調和');
          end
        else if ritem[item].Data[45 + i] > 0 then
          str := '+' + format('%d', [ritem[item].Data[45 + i]])
        else str := format('%d', [ritem[item].Data[45 + i]]);

        drawshadowtext(@words2[i][1], 97 + i1 mod 5 * 98 + 12, i1 div 5 * 20 + 355, colcolor(0, $5), colcolor(0, $7));
        drawshadowtext(@str[1], 147 + i1 mod 5 * 98 + 12, i1 div 5 * 20 + 355, colcolor(0, $64), colcolor(0, $66));
        i1 := i1 + 1;
      end;
    end;



    i1 := 0;
    for i := 0 to 13 do
    begin
      if (p3[i] = 1) then
      begin

        if i = 0 then
          case ritem[item].NeedMPType of
            0: str := UTF8Decode(' 陽');
            1: str := UTF8Decode(' 陰');
            2: str := UTF8Decode(' 調和');
          end
        else if i = 13 then
          case ritem[item].needSex of
            0: str := UTF8Decode(' 男');
            1: str := UTF8Decode(' 女');
            2: str := UTF8Decode(' 自宫');
          end
        else if ritem[item].Data[69 + i] > 0 then
          str := UTF8Decode(' ') + format('%d', [ritem[item].Data[69 + i]])
        else str := format('%d', [ritem[item].Data[69 + i]]);

        drawshadowtext(@words3[i][1], 97 + i1 mod 5 * 98 + 12, ((len2 + 4) div 5 + i1 div 5) *
          20 + 355, colcolor(0, $FF), colcolor(0, $50));
        drawshadowtext(@str[1], 147 + i1 mod 5 * 98 + 12, ((len2 + 4) div 5 + i1 div 5) *
          20 + 355, colcolor(0, $64), colcolor(0, $66));
        i1 := i1 + 1;
      end;
    end;

    if (ritem[item].BattleEffect > 0) then
    begin
      case ritem[item].BattleEffect of
        1: str := UTF8Decode('裝備特效：體力不減');
        2: str := UTF8Decode('裝備特效：女性武功威力加成');
        3: str := UTF8Decode('裝備特效：飲酒功效加倍');
        4: str := UTF8Decode('裝備特效：隨機傷害轉移');
        5: str := UTF8Decode('裝備特效：隨機傷害反噬');
        6: str := UTF8Decode('裝備特效：內傷免疫');
        7: str := UTF8Decode('裝備特效：殺傷體力');
        8: str := UTF8Decode('裝備特效：增加閃躲幾率');
        9: str := UTF8Decode('裝備特效：攻擊力隨等级循环增减');
        10: str := UTF8Decode('裝備特效：內力消耗減少');
        11: str := UTF8Decode('裝備特效：每回合恢復生命');
        12: str := UTF8Decode('裝備特效：負面狀態免疫');
        13: str := UTF8Decode('裝備特效：全部武功威力加成');
        14: str := UTF8Decode('裝備特效：隨機二次攻擊');
        15: str := UTF8Decode('裝備特效：拳掌武功威力加成');
        16: str := UTF8Decode('裝備特效：劍術武功威力加成');
        17: str := UTF8Decode('裝備特效：刀法武功威力加成');
        18: str := UTF8Decode('裝備特效：奇門武功威力加成');
        19: str := UTF8Decode('裝備特效：增加內傷幾率');
        20: str := UTF8Decode('裝備特效：增加封穴幾率');
        21: str := UTF8Decode('裝備特效：攻擊微量吸血');
        22: str := UTF8Decode('裝備特效：攻擊距離增加');
        23: str := UTF8Decode('裝備特效：每回合恢復內力');
        24: str := UTF8Decode('裝備特效：使用暗器距離增加');
        25: str := UTF8Decode('裝備特效：附加殺傷吸收內力');
      end;
      drawshadowtext(@str[1], 97 + 12, ((len2 + 4) div 5 + (i1 + 4) div 5) * 20 + 355,
        colcolor(0, $5), colcolor(0, $7));
    end;
  end;

  drawItemframe(x, y);

end;

//画白色边框作为物品选单的光标

procedure DrawItemFrame(x, y: integer);
var
  i: integer;
begin
  for i := 0 to 79 do
  begin
    putpixel(screen, x * 82 + 115 + 12 + i, y * 82 + 97 - 14, colcolor(0, 255));
    putpixel(screen, x * 82 + 115 + 12 + i, y * 82 + 91 + 81 - 14, colcolor(0, 255));
    putpixel(screen, x * 82 + 117 + 12, y * 82 + 95 + i - 14, colcolor(0, 255));
    putpixel(screen, x * 82 + 111 + 12 + 81, y * 82 + 95 + i - 14, colcolor(0, 255));

    putpixel(screen, x * 82 + 115 + 12 + i, y * 82 + 96 - 14, colcolor(0, 255));
    putpixel(screen, x * 82 + 115 + 12 + i, y * 82 + 92 + 81 - 14, colcolor(0, 255));
    putpixel(screen, x * 82 + 116 + 12, y * 82 + 95 + i - 14, colcolor(0, 255));
    putpixel(screen, x * 82 + 112 + 12 + 81, y * 82 + 95 + i - 14, colcolor(0, 255));

    putpixel(screen, x * 82 + 115 + 12 + i, y * 82 + 95 - 14, colcolor(0, 255));
    putpixel(screen, x * 82 + 115 + 12 + i, y * 82 + 93 + 81 - 14, colcolor(0, 255));
    putpixel(screen, x * 82 + 115 + 12, y * 82 + 95 + i - 14, colcolor(0, 255));
    putpixel(screen, x * 82 + 113 + 12 + 81, y * 82 + 95 + i - 14, colcolor(0, 255));
  end;

end;

//使用物品

procedure UseItem(inum: integer);
var
  x, y, menu, rnum, p: integer;
  str, str1: WideString;
begin
  CurItem := inum;
  if inum = MAP_ID then
  begin
    Showmap;
    exit;
  end;

  case RItem[inum].ItemType of
    0: //剧情物品
    begin
      //如某属性大于0, 直接调用事件
      if ritem[inum].EventNum > 0 then
        callevent(ritem[inum].EventNum)
      else
      begin
        if where = 1 then
        begin
          x := Sx;
          y := Sy;
          case SFace of
            0: x := x - 1;
            1: y := y + 1;
            2: y := y - 1;
            3: x := x + 1;
          end;
          //如面向位置有第2类事件则调用
          if SData[CurScene, 3, x, y] >= 0 then
          begin
            CurEvent := SData[CurScene, 3, x, y];
            if DData[CurScene, SData[CurScene, 3, x, y], 3] >= 0 then
            begin
              //  SaveR(6);
              callevent(DData[CurScene, SData[CurScene, 3, x, y], 3]);
            end;
          end;
          CurEvent := -1;
        end;
      end;
    end;
    1: //装备
    begin
      menu := 1;
      if menu = 1 then
      begin
        menu := SelectItemUser(inum);
        if menu >= 0 then
        begin
          rnum := menu;
          p := Ritem[inum].EquipType;
          if canequip(rnum, inum) then
          begin
            if Rrole[rnum].Equip[p] >= 0 then
            begin
              if Ritem[Rrole[rnum].Equip[p]].Magic > 0 then
              begin
                Ritem[Rrole[rnum].Equip[p]].ExpOfMagic := GetMagicLevel(rnum, Ritem[Rrole[rnum].Equip[p]].Magic);
                StudyMagic(rnum, Ritem[Rrole[rnum].Equip[p]].Magic, 0, 0, 1);
              end;
              Dec(Rrole[rnum].MaxHP, Ritem[Rrole[rnum].Equip[p]].AddMaxHP);
              Dec(Rrole[rnum].CurrentHP, Ritem[Rrole[rnum].Equip[p]].AddMaxHP);
              Dec(Rrole[rnum].MaxMP, Ritem[Rrole[rnum].Equip[p]].AddMaxMP);
              Dec(Rrole[rnum].CurrentMP, Ritem[Rrole[rnum].Equip[p]].AddMaxMP);
              instruct_32(Rrole[rnum].Equip[p], 1);
            end;
            instruct_32(inum, -1);
            Rrole[rnum].Equip[p] := inum;

            if Ritem[Rrole[rnum].Equip[p]].Magic > 0 then
              StudyMagic(rnum, 0, Ritem[Rrole[rnum].Equip[p]].Magic, Ritem[Rrole[rnum].Equip[p]].ExpOfMagic, 1);

            Inc(Rrole[rnum].MaxHP, Ritem[Rrole[rnum].Equip[p]].AddMaxHP);
            Inc(Rrole[rnum].CurrentHP, Ritem[Rrole[rnum].Equip[p]].AddMaxHP);
            Inc(Rrole[rnum].MaxMP, Ritem[Rrole[rnum].Equip[p]].AddMaxMP);
            Inc(Rrole[rnum].CurrentMP, Ritem[Rrole[rnum].Equip[p]].AddMaxMP);
            Rrole[rnum].CurrentMP := max(1, Rrole[rnum].CurrentMP);
            Rrole[rnum].CurrentHP := max(1, Rrole[rnum].CurrentHP);
          end
          else
          begin
            str := UTF8Decode('　　　　　此人不適合裝備此物品');
            drawshadowtext(@str[1], 162, 391, colcolor(0, 5), colcolor(0, 7));
            SDL_UpdateRect2(screen, 140, 391, 500, 25);
            waitanykey;
            //redraw;
          end;
        end;
      end;
    end;
    2: //秘笈
    begin
      menu := 1;
      if menu = 1 then
      begin
        menu := SelectItemUser(inum);
        if menu >= 0 then
        begin
          rnum := menu;
          if canequip(rnum, inum) then
          begin
            if Rrole[rnum].PracticeBook <> inum then
            begin
              if Rrole[rnum].PracticeBook >= 0 then
                instruct_32(Rrole[rnum].PracticeBook, 1);
              instruct_32(inum, -1);
              Rrole[rnum].PracticeBook := inum;
              Rrole[rnum].ExpForBook := 0;
            end;
          end
          else
          begin
            str := UTF8Decode('　　　　　此人不適合修煉此秘笈');
            drawshadowtext(@str[1], 162, 391, colcolor(0, 5), colcolor(0, 7));
            SDL_UpdateRect2(screen, 140, 391, 500, 25);
            waitanykey;
            // redraw;
          end;
        end;
      end;
    end;

    3:
    begin
      if ritem[inum].EventNum <= 0 then
        SelectItemUser(inum)
      else
        callevent(ritem[inum].EventNum);
    end;
    4: //不处理暗器类物品
    begin
      //if where<>3 then break;
    end;
  end;

end;

//能否装备

function CanEquip(rnum, inum: integer): boolean;
var
  i, r, Aptitude: integer;
begin

  //判断是否符合
  //注意这里对'所需属性'为负值时均添加原版类似资质的处理

  Result := True;

  if (Ritem[inum].needSex >= 0) and (Ritem[inum].needSex <> Rrole[rnum].Sexual) then
    Result := False;
  if sign(Ritem[inum].NeedMP) * Rrole[rnum].CurrentMP < Ritem[inum].NeedMP then
    Result := False;
  if sign(Ritem[inum].NeedAttack) * GetRoleAttack(rnum, False) < Ritem[inum].NeedAttack then
    Result := False;
  if sign(Ritem[inum].NeedSpeed) * GetRoleSpeed(rnum, False) < Ritem[inum].NeedSpeed then
    Result := False;
  if sign(Ritem[inum].NeedUsePoi) * GetRoleUsePoi(rnum, False) < Ritem[inum].NeedUsepoi then
    Result := False;
  if sign(Ritem[inum].NeedMedcine) * GetRoleMedcine(rnum, False) < Ritem[inum].NeedMedcine then
    Result := False;
  if sign(Ritem[inum].NeedMedPoi) * GetRoleMedPoi(rnum, False) < Ritem[inum].NeedMedPoi then
    Result := False;
  if sign(Ritem[inum].NeedFist) * GetRoleFist(rnum, False) < Ritem[inum].NeedFist then
    Result := False;
  if sign(Ritem[inum].NeedSword) * GetRoleSword(rnum, False) < Ritem[inum].NeedSword then
    Result := False;
  if sign(Ritem[inum].NeedKnife) * GetRoleKnife(rnum, False) < Ritem[inum].NeedKnife then
    Result := False;
  if sign(Ritem[inum].NeedUnusual) * GetRoleUnusual(rnum, False) < Ritem[inum].NeedUnusual then
    Result := False;
  if sign(Ritem[inum].NeedHidWeapon) * GetRoleHidWeapon(rnum, False) < Ritem[inum].NeedHidWeapon then
    Result := False;

  if CheckEquipSet(Rrole[rnum].equip[0], Rrole[rnum].equip[1], Rrole[rnum].equip[2], Rrole[rnum].equip[3]) = 2 then
    Aptitude := 100
  else Aptitude := Rrole[rnum].Aptitude;

  if sign(Ritem[inum].NeedAptitude) * Aptitude < Ritem[inum].NeedAptitude then
    Result := False;

  //内力性质
  if (rrole[rnum].MPType < 2) and (Ritem[inum].NeedMPType < 2) then
    if rrole[rnum].MPType <> Ritem[inum].NeedMPType then
      Result := False;

  //如有专用人物, 前面的都作废
  if (Ritem[inum].OnlyPracRole >= 0) and (Result = True) then
    if (Ritem[inum].OnlyPracRole = rnum) then
      Result := True
    else
      Result := False;

  //如已有10种武功, 且物品也能练出武功, 则结果为假
  r := 0;
  if ritem[inum].Magic > 0 then
  begin
    for i := 0 to 9 do
      if Rrole[rnum].Magic[i] > 0 then
        r := r + 1;
    if (r >= 10) and (ritem[inum].Magic > 0) then
      Result := False;

    for i := 0 to 9 do
      if Rrole[rnum].Magic[i] = ritem[inum].Magic then
      begin
        Result := True;
        break;
      end;

    //若该武功已经练至顶级则结果为假
    if (getmagiclevel(rnum, ritem[inum].Magic) >= 0) and (Rmagic[ritem[inum].Magic].MagicType = 5) then
      Result := False
    else if (getmagiclevel(rnum, ritem[inum].Magic) >= 900) then
      Result := False;

  end;

end;

//查看状态选单

procedure MenuStatus;
var
  str: WideString;
  menu: integer;
begin
  str := UTF8Decode(' 查看隊員狀態');
  drawtextwithrect(@str[1], 80, 30, 132, colcolor($21), colcolor($23));
  menu := SelectOneTeamMember(80, 65, '%3d', 15, 0);
  if menu >= 0 then
  begin
    ShowStatus(TeamList[menu]);
    waitanykey;
    redraw;
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  end;

end;

//显示状态

procedure ShowStatus(rnum: integer);
var
  i, n, magicnum, Aptitude, mlevel, needexp, x, y: integer;
  p: array[0..10] of integer;
  addatk, adddef, addspeed: integer;
  str: WideString;
  strs: array[0..21] of WideString;
  color1, color2: uint32;
  Name: WideString;
begin
  strs[0] := UTF8Decode(' 等級');
  strs[1] := UTF8Decode(' 生命');
  strs[2] := UTF8Decode(' 內力');
  strs[3] := UTF8Decode(' 體力');
  strs[4] := UTF8Decode(' 經驗');
  strs[5] := UTF8Decode(' 升級');
  strs[6] := UTF8Decode(' 攻擊');
  strs[7] := UTF8Decode(' 防禦');
  strs[8] := UTF8Decode(' 輕功');
  strs[9] := UTF8Decode(' 醫療能力');
  strs[10] := UTF8Decode(' 用毒能力');
  strs[11] := UTF8Decode(' 解毒能力');
  strs[12] := UTF8Decode(' 拳掌功夫');
  strs[13] := UTF8Decode(' 御劍能力');
  strs[14] := UTF8Decode(' 耍刀技巧');
  strs[15] := UTF8Decode(' 奇門兵器');
  strs[16] := UTF8Decode(' 暗器技巧');
  strs[17] := UTF8Decode(' 裝備物品');
  strs[18] := UTF8Decode(' 修煉物品');
  strs[19] := UTF8Decode(' 所會武功');
  strs[20] := UTF8Decode(' 受傷');
  strs[21] := UTF8Decode(' 中毒');
  p[0] := 43;
  p[1] := 45;
  p[2] := 44;
  p[3] := 46;
  p[4] := 47;
  p[5] := 48;
  p[6] := 50;
  p[7] := 51;
  p[8] := 52;
  p[9] := 53;
  p[10] := 54;
  Redraw;
  x := 40;
  y := CENTER_Y - 160;

  DrawRectangle(x, y, 560, 315, 0, colcolor(255), 50);
  //显示头像
  drawheadpic(Rrole[rnum].HeadNum, x + 60, y + 80);
  //显示姓名
  Name := gbktounicode(@Rrole[rnum].Name);
  drawshadowtext(@Name[1], x + 68 - length(PChar(@Rrole[rnum].Name)) * 5, y + 85, colcolor($64), colcolor($66));
  //显示所需字符
  for i := 0 to 5 do
    drawshadowtext(@strs[i, 1], x - 10, y + 110 + 21 * i, colcolor($21), colcolor($23));
  for i := 6 to 16 do
    drawshadowtext(@strs[i, 1], x + 160, y + 5 + 21 * (i - 6), colcolor($64), colcolor($66));
  drawshadowtext(@strs[19, 1], x + 360, y + 5, colcolor($21), colcolor($23));

  addatk := 0;
  adddef := 0;
  addspeed := 0;
  for n := 0 to 3 do
  begin
    if rrole[rnum].Equip[n] >= 0 then
    begin
      addatk := addatk + ritem[rrole[rnum].Equip[n]].AddAttack;
      adddef := adddef + ritem[rrole[rnum].Equip[n]].AddDefence;
      addspeed := addspeed + ritem[rrole[rnum].Equip[n]].AddSpeed;
    end;

  end;

  //攻击, 防御, 轻功
  //单独处理是因为显示顺序和存储顺序不同
  str := format('%4d', [Rrole[rnum].Attack + addatk]);
  drawengshadowtext(@str[1], x + 300, y + 5 + 21 * 0, colcolor($5), colcolor($7));
  str := format('%4d', [Rrole[rnum].Defence + adddef]);
  drawengshadowtext(@str[1], x + 300, y + 5 + 21 * 1, colcolor($5), colcolor($7));
  str := format('%4d', [Rrole[rnum].Speed + addspeed]);
  drawengshadowtext(@str[1], x + 300, y + 5 + 21 * 2, colcolor($5), colcolor($7));

  //其他属性
  str := format('%4d', [Rrole[rnum].Medcine]);
  drawengshadowtext(@str[1], x + 300, y + 5 + 21 * 3, colcolor($5), colcolor($7));

  str := format('%4d', [Rrole[rnum].UsePoi]);
  drawengshadowtext(@str[1], x + 300, y + 5 + 21 * 4, colcolor($5), colcolor($7));

  str := format('%4d', [Rrole[rnum].MedPoi]);
  drawengshadowtext(@str[1], x + 300, y + 5 + 21 * 5, colcolor($5), colcolor($7));

  str := format('%4d', [Rrole[rnum].Fist]);
  drawengshadowtext(@str[1], x + 300, y + 5 + 21 * 6, colcolor($5), colcolor($7));

  str := format('%4d', [Rrole[rnum].Sword]);
  drawengshadowtext(@str[1], x + 300, y + 5 + 21 * 7, colcolor($5), colcolor($7));

  str := format('%4d', [Rrole[rnum].Knife]);
  drawengshadowtext(@str[1], x + 300, y + 5 + 21 * 8, colcolor($5), colcolor($7));

  str := format('%4d', [Rrole[rnum].Unusual]);
  drawengshadowtext(@str[1], x + 300, y + 5 + 21 * 9, colcolor($5), colcolor($7));

  str := format('%4d', [Rrole[rnum].HidWeapon]);
  drawengshadowtext(@str[1], x + 300, y + 5 + 21 * 10, colcolor($5), colcolor($7));

  //武功
  for i := 0 to 9 do
  begin
    magicnum := Rrole[rnum].magic[i];
    if magicnum > 0 then
    begin
      drawgbkshadowtext(@Rmagic[magicnum].Name, x + 360, y + 26 + 21 * i, colcolor($5), colcolor($7));
      str := format('%3d', [Rrole[rnum].MagLevel[i] div 100 + 1]);
      drawengshadowtext(@str[1], x + 520, y + 26 + 21 * i, colcolor($64), colcolor($66));
    end;
  end;
  str := format('%4d', [Rrole[rnum].Level]);
  drawengshadowtext(@str[1], x + 110, y + 110, colcolor($5), colcolor($7));
  //生命值, 在受伤和中毒值不同时使用不同颜色
  case RRole[rnum].Hurt of
    34..66:
    begin
      color1 := colcolor($E);
      color2 := colcolor($10);
    end;
    67..1000:
    begin
      color1 := colcolor($14);
      color2 := colcolor($16);
    end;
    else
    begin
      color1 := colcolor($5);
      color2 := colcolor($7);
    end;
  end;
  str := format('%4d', [RRole[rnum].CurrentHP]);
  drawengshadowtext(@str[1], x + 60, y + 131, color1, color2);

  str := '/';
  drawengshadowtext(@str[1], x + 100, y + 131, colcolor($64), colcolor($66));

  case RRole[rnum].Poision of
    34..66:
    begin
      color1 := colcolor($30);
      color2 := colcolor($32);
    end;
    67..1000:
    begin
      color1 := colcolor($35);
      color2 := colcolor($37);
    end;
    else
    begin
      color1 := colcolor($21);
      color2 := colcolor($23);
    end;
  end;
  str := format('%4d', [RRole[rnum].MaxHP]);
  drawengshadowtext(@str[1], x + 110, y + 131, color1, color2);
  //内力, 依据内力性质使用颜色
  if rrole[rnum].MPType = 1 then
  begin
    color1 := colcolor($4E);
    color2 := colcolor($50);
  end
  else if rrole[rnum].MPType = 0 then
  begin
    color1 := colcolor($5);
    color2 := colcolor($7);
  end
  else
  begin
    color1 := colcolor($63);
    color2 := colcolor($66);
  end;
  str := format('%4d/%4d', [RRole[rnum].CurrentMP, RRole[rnum].MaxMP]);
  drawengshadowtext(@str[1], x + 60, y + 152, color1, color2);
  //体力
  str := format('%4d/%4d', [rrole[rnum].PhyPower, MAX_PHYSICAL_POWER]);
  drawengshadowtext(@str[1], x + 60, y + 173, colcolor($5), colcolor($7));
  //经验
  str := format('%5d', [uint16(Rrole[rnum].Exp)]);
  drawengshadowtext(@str[1], x + 100, y + 194, colcolor($5), colcolor($7));
  if Rrole[rnum].Level = Max_Level then
    str := '='
  else
    str := format('%5d', [uint16(Leveluplist[Rrole[rnum].Level - 1])]);
  drawengshadowtext(@str[1], x + 100, y + 215, colcolor($5), colcolor($7));

  //str:=format('%5d', [Rrole[rnum,21]]);
  //drawengshadowtext(@str[1],150,295,colcolor($7),colcolor($5));

  //drawshadowtext(@strs[20, 1], 30, 341, colcolor($21), colcolor($23));
  //drawshadowtext(@strs[21, 1], 30, 362, colcolor($21), colcolor($23));

  //drawrectanglewithoutframe(100,351,Rrole[rnum,19],10,colcolor($16),50);
  //中毒, 受伤
  //str := format('%4d', [RRole[rnum].Hurt]);
  //drawengshadowtext(@str[1], 150, 341, colcolor($14), colcolor($16));
  //str := format('%4d', [RRole[rnum].Poision]);
  //drawengshadowtext(@str[1], 150, 362, colcolor($35), colcolor($37));

  //装备, 秘笈
  drawshadowtext(@strs[17, 1], x + 160, y + 240, colcolor($21), colcolor($23));
  drawshadowtext(@strs[18, 1], x + 360, y + 240, colcolor($21), colcolor($23));
  if Rrole[rnum].Equip[0] >= 0 then
    drawgbkshadowtext(@Ritem[Rrole[rnum].Equip[0]].Name, x + 170, y + 261, colcolor($5), colcolor($7));
  if Rrole[rnum].Equip[1] >= 0 then
    drawgbkshadowtext(@Ritem[Rrole[rnum].Equip[1]].Name, x + 170, y + 282, colcolor($5), colcolor($7));

  //计算秘笈需要经验
  if Rrole[rnum].PracticeBook >= 0 then
  begin
    mlevel := 1;
    magicnum := Ritem[Rrole[rnum].PracticeBook].Magic;
    if magicnum > 0 then
      for i := 0 to 9 do
        if Rrole[rnum].Magic[i] = magicnum then
        begin
          mlevel := Rrole[rnum].MagLevel[i] div 100 + 1;
          break;
        end;
    if CheckEquipSet(Rrole[rnum].equip[0], Rrole[rnum].equip[1], Rrole[rnum].equip[2], Rrole[rnum].equip[3]) = 2 then
      Aptitude := 100
    else Aptitude := Rrole[rnum].Aptitude;
    if Ritem[Rrole[rnum].PracticeBook].NeedExp > 0 then
      needexp := mlevel * (Ritem[Rrole[rnum].PracticeBook].NeedExp * (8 - Aptitude div 15)) div 2
    else
      needexp := mlevel * (Ritem[Rrole[rnum].PracticeBook].NeedExp * (1 + Aptitude div 15)) div 2;
    drawgbkshadowtext(@Ritem[Rrole[rnum].PracticeBook].Name, x + 370, y + 261, colcolor($5), colcolor($7));
    str := format('%5d/%5d', [uint16(Rrole[rnum].ExpForBook), needexp]);
    if mlevel = 10 then
      str := format('%5d/=', [uint16(Rrole[rnum].ExpForBook)]);
    drawengshadowtext(@str[1], x + 400, y + 282, colcolor($64), colcolor($66));
  end;

  SDL_UpdateRect2(screen, x, y, 561, 316);

end;

//离队选单
             {
procedure MenuLeave;
var
  str: widestring;
  i, menu: integer;
begin
  str := UTF8Decode(' 要求誰離隊？');
  drawtextwithrect(@str[1], 80, 30, 132, colcolor($21), colcolor($23));
  menu := SelectOneTeamMember(80, 65, '%3d', 15, 0);
  if menu >= 0 then
  begin
    for i := 0 to 99 do
      if leavelist[i] = TeamList[menu] then
      begin
        callevent(BEGIN_LEAVE_EVENT + i * 2);
        SDL_EnableKeyRepeat(0, 10);
        break;
      end;
  end;
  redraw;

end;          }

//系统选单

procedure MenuSystem;
var
  i, menu, menup: integer;
begin
  menu := 0;
  showmenusystem(menu);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    if where = 3 then
      break;
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then
          Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then
        begin
          menu := menu + 1;
          if menu > 3 then
            menu := 0;
          showMenusystem(menu);
        end;
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          menu := menu - 1;
          if menu < 0 then
            menu := 3;
          showMenusystem(menu);
        end;
        if (event.key.keysym.sym = sdlk_escape) then
        begin
          redraw;
          SDL_UpdateRect2(screen, 80, 30, 47, 95);
          break;
        end;
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          case menu of
            3:
            begin
              MenuQuit;
            end;
            1:
            begin
              MenuSave;
            end;
            0:
            begin
              Menuload;
            end;
            2:
            begin
              SwitchFullscreen;
              Kys_ini.WriteInteger('set', 'fullscreen', fullscreen);
              break;
            end;
          end;
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_right) then
        begin
          redraw;
          SDL_UpdateRect2(screen, 80, 30, 47, 95);
          break;
        end;
        if (event.button.button = sdl_button_left) then
          case menu of
            3:
            begin
              MenuQuit;
            end;
            1:
            begin
              MenuSave;
            end;
            0:
            begin
              Menuload;
            end;
            2:
            begin
              SwitchFullscreen;
              Kys_ini.WriteInteger('set', 'fullscreen', fullscreen);
              break;
            end;
          end;
      end;
      SDL_MOUSEMOTION:
      begin
        if (round(event.button.x / (RealScreen.w / screen.w)) >= 80) and
          (round(event.button.x / (RealScreen.w / screen.w)) < 127) and
          (round(event.button.y / (RealScreen.h / screen.h)) > 47) and
          (round(event.button.y / (RealScreen.h / screen.h)) < 120) then
        begin
          menup := menu;
          menu := (round(event.button.y / (RealScreen.h / screen.h)) - 32) div 22;
          if menu > 3 then
            menu := 3;
          if menu < 0 then
            menu := 0;
          if menup <> menu then
            showMenusystem(menu);
        end;
      end;
    end;
  end;

end;

//显示系统选单

procedure ShowMenuSystem(menu: integer);
var
  word: array[0..3] of WideString;
  i: integer;
begin
  word[0] := UTF8Decode(' 讀取');
  word[1] := UTF8Decode(' 存檔');
  word[2] := UTF8Decode(' 全屏');
  word[3] := UTF8Decode(' 離開');
  if fullscreen = 1 then
    word[2] := UTF8Decode(' 窗口');
  ReDraw;
  DrawRectangle(80, 30, 46, 92, 0, colcolor(255), 30);
  for i := 0 to 3 do
    if i = menu then
    begin
      drawtext(screen, @word[i][1], 64, 32 + 22 * i, colcolor($64));
      drawtext(screen, @word[i][1], 63, 32 + 22 * i, colcolor($66));
    end
    else
    begin
      drawtext(screen, @word[i][1], 64, 32 + 22 * i, colcolor($5));
      drawtext(screen, @word[i][1], 63, 32 + 22 * i, colcolor($7));
    end;
  SDL_UpdateRect2(screen, 80, 30, 47, 93);

end;

//读档选单

procedure MenuLoad;
var
  menu, i: integer;
begin
  setlength(Menustring, 0);
  setlength(menustring, 5);
  setlength(Menuengstring, 0);
  menustring[0] := UTF8Decode(' 進度一');
  menustring[1] := UTF8Decode(' 進度二');
  menustring[2] := UTF8Decode(' 進度三');
  menustring[3] := UTF8Decode(' 進度四');
  menustring[4] := UTF8Decode(' 進度五');
  menu := commonmenu(133, 30, 67, 4);
  if menu >= 0 then
  begin
    LoadR(menu + 1);
    if where = 1 then
    begin
      JmpScene(curScene, sy, sx);
    end;
    Redraw;
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    ShowMenu(5);
    ShowMenusystem(0);
  end;

end;

//特殊的读档选单, 仅用在开始时读档

function MenuLoadAtBeginning: boolean;
var
  menu: integer;
begin
  Redraw;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  setlength(Menustring, 0);
  setlength(menustring, 6);
  setlength(Menuengstring, 0);
  menustring[0] := UTF8Decode(' 載入進度一');
  menustring[1] := UTF8Decode(' 載入進度二');
  menustring[2] := UTF8Decode(' 載入進度三');
  menustring[3] := UTF8Decode(' 載入進度四');
  menustring[4] := UTF8Decode(' 載入進度五');
  menustring[5] := UTF8Decode(' 載入自動檔');
  menu := commonmenu(265, 280, 107, 5);
  Result := False;
  if menu >= 0 then
  begin
    Result := True;
    LoadR(menu + 1);

  end;
  //femalesnake;
end;

//存档选单

procedure MenuSave;
var
  menu: integer;
begin
  setlength(Menustring, 0);
  setlength(menustring, 5);
  menustring[0] := UTF8Decode(' 進度一');
  menustring[1] := UTF8Decode(' 進度二');
  menustring[2] := UTF8Decode(' 進度三');
  menustring[3] := UTF8Decode(' 進度四');
  menustring[4] := UTF8Decode(' 進度五');
  menu := commonmenu(133, 30, 67, 4);
  if menu >= 0 then
    SaveR(menu + 1);

end;

//退出选单

procedure MenuQuit;
var
  menu: integer;
begin
  setlength(Menustring, 0);
  setlength(menustring, 2);
  menustring[0] := UTF8Decode(' 取消');
  menustring[1] := UTF8Decode(' 確定');
  menu := commonmenu(133, 30, 45, 1);
  if menu = 1 then
  begin
    Quit;
  end;

end;

//医疗的效果

procedure EffectMedcine(role1, role2: integer);
var
  word: WideString;
  addlife: integer;
begin
  if Rrole[role1].PhyPower < 50 then exit;
  addlife := GetRoleMedcine(role1, True) * (10 - Rrole[role2].Hurt div 15) div 10;
  if Rrole[role2].Hurt - GetRoleMedcine(role1, True) > 20 then
    addlife := 0;
  Rrole[role2].Hurt := Rrole[role2].Hurt - addlife div LIFE_HURT;
  if RRole[role2].Hurt < 0 then
    RRole[role2].Hurt := 0;
  if addlife > RRole[role2].MaxHP - Rrole[role2].CurrentHP then
    addlife := RRole[role2].MaxHP - Rrole[role2].CurrentHP;
  Rrole[role2].CurrentHP := Rrole[role2].CurrentHP + addlife;
  if addlife > 0 then
    if (not GetEquipState(role1, 1)) and (not GetGongtiState(role1, 1)) then
      Rrole[role1].PhyPower := Rrole[role1].PhyPower - 3;

end;

//解毒的效果

procedure EffectMedPoision(role1, role2: integer);
var
  word: WideString;
  minuspoi: integer;
begin
  if Rrole[role1].PhyPower < 50 then exit;
  minuspoi := GetRoleMedPoi(role1, True);
  if minuspoi < (Rrole[role2].Poision div 2) then
    minuspoi := 0
  else if minuspoi > Rrole[role2].Poision then
    minuspoi := Rrole[role2].Poision;
  Rrole[role2].Poision := Rrole[role2].Poision - minuspoi;

  if minuspoi > 0 then
    if (not GetEquipState(role1, 1)) and (not GetGongtiState(role1, 1)) then
      Rrole[role1].PhyPower := Rrole[role1].PhyPower - 3;
end;

//使用物品的效果
//练成秘笈的效果

procedure EatOneItem(rnum, inum: integer);
var
  i, p, l, x, y: integer;
  word: array[0..23] of WideString;
  addvalue, rolelist: array[0..23] of integer;
  str: WideString;
begin

  word[0] := UTF8Decode(' 增加生命');
  word[1] := UTF8Decode(' 增加生命最大值');
  word[2] := UTF8Decode(' 中毒程度');
  word[3] := UTF8Decode(' 增加體力');
  word[4] := UTF8Decode(' 內力門路改变為');
  word[5] := UTF8Decode(' 增加內力');
  word[6] := UTF8Decode(' 增加內力最大值');
  word[7] := UTF8Decode(' 增加攻擊力');
  word[8] := UTF8Decode(' 增加輕功');
  word[9] := UTF8Decode(' 增加防禦力');
  word[10] := UTF8Decode(' 增加醫療能力');
  word[11] := UTF8Decode(' 增加用毒能力');
  word[12] := UTF8Decode(' 增加解毒能力');
  word[13] := UTF8Decode(' 增加抗毒能力');
  word[14] := UTF8Decode(' 增加拳掌能力');
  word[15] := UTF8Decode(' 增加御劍能力');
  word[16] := UTF8Decode(' 增加耍刀能力');
  word[17] := UTF8Decode(' 增加奇門兵器');
  word[18] := UTF8Decode(' 增加暗器技巧');
  word[19] := UTF8Decode(' 增加武學常識');
  word[20] := UTF8Decode(' 增加品德指數');
  word[21] := UTF8Decode(' 習得左右互搏');
  word[22] := UTF8Decode(' 增加攻擊帶毒');
  word[23] := UTF8Decode(' 受傷程度');
  rolelist[0] := 17;
  rolelist[1] := 18;
  rolelist[2] := 20;
  rolelist[3] := 21;
  rolelist[4] := 40;
  rolelist[5] := 41;
  rolelist[6] := 42;
  rolelist[7] := 43;
  rolelist[8] := 44;
  rolelist[9] := 45;
  rolelist[10] := 46;
  rolelist[11] := 47;
  rolelist[12] := 48;
  rolelist[13] := 49;
  rolelist[14] := 50;
  rolelist[15] := 51;
  rolelist[16] := 52;
  rolelist[17] := 53;
  rolelist[18] := 54;
  rolelist[19] := 55;
  rolelist[20] := 56;
  rolelist[21] := 58;
  rolelist[22] := 57;
  rolelist[23] := 19;
  //rolelist:=(17,18,20,21,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,58,57);
  for i := 0 to 22 do
  begin
    addvalue[i] := Ritem[inum].Data[45 + i];
  end;
  //减少受伤
  addvalue[23] := -(addvalue[0] div LIFE_HURT);

  if -addvalue[23] > rrole[rnum].Data[19] then
    addvalue[23] := -rrole[rnum].Data[19];

  //增加生命, 内力最大值的处理
  if addvalue[1] + rrole[rnum].Data[18] > MAX_HP then
    addvalue[1] := MAX_HP - rrole[rnum].Data[18];
  if addvalue[6] + rrole[rnum].Data[42] > MAX_MP then
    addvalue[6] := MAX_MP - rrole[rnum].Data[42];
  if addvalue[1] + rrole[rnum].Data[18] < 0 then
    addvalue[1] := -rrole[rnum].Data[18];
  if addvalue[6] + rrole[rnum].Data[42] < 0 then
    addvalue[6] := -rrole[rnum].Data[42];

  for i := 7 to 22 do
  begin
    if addvalue[i] + rrole[rnum].Data[rolelist[i]] > maxprolist[rolelist[i]] then
      addvalue[i] := maxprolist[rolelist[i]] - rrole[rnum].Data[rolelist[i]];
    if addvalue[i] + rrole[rnum].Data[rolelist[i]] < 0 then
      addvalue[i] := -rrole[rnum].Data[rolelist[i]];
  end;
  //生命不能超过最大值
  if addvalue[0] + rrole[rnum].Data[17] > addvalue[1] + rrole[rnum].Data[18] then
    addvalue[0] := addvalue[1] + rrole[rnum].Data[18] - rrole[rnum].Data[17];
  //中毒不能小于0
  if addvalue[2] + rrole[rnum].Data[20] < 0 then
    addvalue[2] := -rrole[rnum].Data[20];
  //体力不能超过100
  if addvalue[3] + rrole[rnum].Data[21] > MAX_PHYSICAL_POWER then
    addvalue[3] := MAX_PHYSICAL_POWER - rrole[rnum].Data[21];
  //内力不能超过最大值
  if addvalue[5] + rrole[rnum].Data[41] > addvalue[6] + rrole[rnum].Data[42] then
    addvalue[5] := addvalue[6] + rrole[rnum].Data[42] - rrole[rnum].Data[41];
  p := 0;
  for i := 0 to 23 do
  begin
    if (i <> 4) and (i <> 21) and (addvalue[i] <> 0) then
      p := p + 1;
  end;
  if (addvalue[4] >= 0) and (rrole[rnum].Data[40] <> 2) then
    p := p + 1;
  if (addvalue[21] = 1) and (rrole[rnum].Data[58] <> 1) then
    p := p + 1;

  if where = 2 then
    ShowSimpleStatus(rnum, 320, 50);
  if (where = 2) or (Ritem[inum].ItemType = 3) then
  begin
    DrawRectangle(100 + (1 - (where div 2)) * 180, 70, 200, 25, 0, colcolor(255), 55);
    str := UTF8Decode(' 服用');
    if Ritem[inum].ItemType = 2 then
      str := UTF8Decode(' 練成');
    Drawshadowtext(@str[1], 83 + (1 - (where div 2)) * 180, 72, colcolor($21), colcolor($23));
    Drawgbkshadowtext(@Ritem[inum].Name, 143 + (1 - (where div 2)) * 180, 72, colcolor($64), colcolor($66));
    //如果增加的项超过11个, 分两列显示
    if p < 11 then
    begin
      l := p;
      Drawrectangle(100 + (1 - (where div 2)) * 180, 100, 200, 22 * l + 25, 0, colcolor($FF), 55);
    end
    else
    begin
      l := p div 2 + 1;
      Drawrectangle(100 + (1 - (where div 2)) * 180, 100, 400, 22 * l + 25, 0, colcolor($FF), 55);
    end;
    drawgbkshadowtext(@rrole[rnum].Data[4], 83 + (1 - (where div 2)) * 180, 102, colcolor($21), colcolor($23));
    str := UTF8Decode(' 未增加屬性');
    if p = 0 then
      drawshadowtext(@str[1], 163 + (1 - (where div 2)) * 180, 102, colcolor(5), colcolor(7));
    p := 0;
  end;
  for i := 0 to 23 do
  begin
    if p < l then
    begin
      x := 0;
      y := 0;
    end
    else
    begin
      x := 200;
      y := -l * 22;
    end;
    if (i <> 4) and (i <> 21) and (addvalue[i] <> 0) then
    begin
      rrole[rnum].Data[rolelist[i]] := rrole[rnum].Data[rolelist[i]] + addvalue[i];
      if (where = 2) or (Ritem[inum].ItemType = 3) then
      begin
        drawshadowtext(@word[i, 1], 83 + x + (1 - (where div 2)) * 180, 124 + y + p * 22, colcolor(5), colcolor(7));
        str := format('%4d', [addvalue[i]]);
        drawengshadowtext(@str[1], 243 + x + (1 - (where div 2)) * 180, 124 + y + p * 22,
          colcolor($64), colcolor($66));

      end;

      p := p + 1;
    end;
    //对内力性质特殊处理
    if (i = 4) and (addvalue[i] >= 0) and (rrole[rnum].Data[40] <> 2) then
    begin
      if (rrole[rnum].Data[rolelist[i]] <> 2) then rrole[rnum].Data[rolelist[i]] := addvalue[i];
      if addvalue[i] = 0 then str := word[i] + UTF8Decode(' 陽性')
      else if addvalue[i] = 1 then str := word[i] + UTF8Decode(' 陰性')
      else str := word[i] + UTF8Decode(' 調和');
      drawshadowtext(@str[1], 83 + x + (1 - (where div 2)) * 180, 124 + y + p * 22, colcolor(5), colcolor(7));
      p := p + 1;
    end;
    //对左右互搏特殊处理
    if (i = 21) and (addvalue[i] = 1) then
    begin
      if rrole[rnum].Data[rolelist[i]] <> 1 then
      begin
        rrole[rnum].Data[rolelist[i]] := 1;
        if (where = 2) or (Ritem[inum].ItemType <> 3) then
        begin
          drawshadowtext(@word[i, 1], 83 + (1 - (where div 2)) * 180 + x, 124 + y + p * 22, colcolor(5), colcolor(7));
        end;
        p := p + 1;
      end;
    end;
  end;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

end;

//Event.
//事件系统

procedure CallEvent(num: integer);
var
  e: array of smallint;
  i, idx, grp, offset, length, p: integer;
  check: boolean;
  cc: uint16;
begin
  //CurEvent:=num;
  Cx := Sx;
  Cy := Sy;
  Sstep := 0;
  //SDL_EnableKeyRepeat(0, 10);
  idx := fileopen(AppPath + 'resource/kdef.idx', fmopenread);
  grp := fileopen(AppPath + 'resource/kdef.grp', fmopenread);
  if num = 0 then
  begin
    offset := 0;
    fileread(idx, length, 4);
  end
  else
  begin
    fileseek(idx, (num - 1) * 4, 0);
    fileread(idx, offset, 4);
    fileread(idx, length, 4);
  end;
  length := (length - offset) div 2;
  setlength(e, length + 1);
  fileseek(grp, offset, 0);
  fileread(grp, e[0], length * 2);
  fileclose(idx);
  fileclose(grp);
  i := 0;

  //普通事件写成子程, 需跳转事件写成函数
  while e[i] >= 0 do
  begin
    //SDL_EnableKeyRepeat(0, 10);
    case e[i] of
      0:
      begin
        i := i + 1;
        instruct_0;
        continue;
      end;
      1:
      begin
        instruct_1(e[i + 1], e[i + 2], e[i + 3]);
        i := i + 4;
      end;
      2:
      begin
        instruct_2(e[i + 1], e[i + 2]);
        i := i + 3;
      end;
      3:
      begin
        instruct_3([e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5], e[i + 6], e[i + 7],
          e[i + 8], e[i + 9], e[i + 10], e[i + 11], e[i + 12], e[i + 13]]);
        i := i + 14;
      end;
      4:
      begin
        i := i + instruct_4(e[i + 1], e[i + 2], e[i + 3]);
        i := i + 4;
      end;
      5:
      begin
        i := i + instruct_5(e[i + 1], e[i + 2]);
        i := i + 3;
      end;
      6:
      begin
        i := i + instruct_6(e[i + 1], e[i + 2], e[i + 3], e[i + 4]);
        i := i + 5;
      end;
      7: //Break the event.
      begin
        break;
      end;
      8:
      begin
        instruct_8(e[i + 1]);
        i := i + 2;
      end;
      9:
      begin
        i := i + instruct_9(e[i + 1], e[i + 2]);
        i := i + 3;
      end;
      10:
      begin
        instruct_10(e[i + 1]);
        i := i + 2;
      end;
      11:
      begin
        i := i + instruct_11(e[i + 1], e[i + 2]);
        i := i + 3;
      end;
      12:
      begin
        instruct_12;
        i := i + 1;
      end;
      13:
      begin
        instruct_13;
        i := i + 1;
      end;
      14:
      begin
        instruct_14;
        i := i + 1;
      end;
      15:
      begin
        instruct_15;
        i := i + 1;
        break;
      end;
      16:
      begin
        i := i + instruct_16(e[i + 1], e[i + 2], e[i + 3]);
        i := i + 4;
      end;
      17:
      begin
        instruct_17([e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5]]);
        i := i + 6;
      end;
      18:
      begin
        i := i + instruct_18(e[i + 1], e[i + 2], e[i + 3]);
        i := i + 4;
      end;
      19:
      begin
        instruct_19(e[i + 1], e[i + 2]);
        i := i + 3;
      end;
      20:
      begin
        i := i + instruct_20(e[i + 1], e[i + 2]);
        i := i + 3;
      end;
      21:
      begin
        instruct_21(e[i + 1]);
        i := i + 2;
      end;
      22:
      begin
        instruct_22;
        i := i + 1;
      end;
      23:
      begin
        instruct_23(e[i + 1], e[i + 2]);
        i := i + 3;
      end;
      24:
      begin
        instruct_24;
        i := i + 1;
      end;
      25:
      begin
        instruct_25(e[i + 1], e[i + 2], e[i + 3], e[i + 4]);
        i := i + 5;
      end;
      26:
      begin
        instruct_26(e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5]);
        i := i + 6;
      end;
      27:
      begin
        instruct_27(e[i + 1], e[i + 2], e[i + 3]);
        i := i + 4;
      end;
      28:
      begin
        i := i + instruct_28(e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5]);
        i := i + 6;
      end;
      29:
      begin
        i := i + instruct_29(e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5]);
        i := i + 6;
      end;
      30:
      begin
        instruct_30(e[i + 1], e[i + 2], e[i + 3], e[i + 4]);
        i := i + 5;
      end;
      31:
      begin
        i := i + instruct_31(e[i + 1], e[i + 2], e[i + 3]);
        i := i + 4;
      end;
      32:
      begin
        instruct_32(e[i + 1], e[i + 2]);
        i := i + 3;
      end;
      33:
      begin
        instruct_33(e[i + 1], e[i + 2], e[i + 3]);
        i := i + 4;
      end;
      34:
      begin
        instruct_34(e[i + 1], e[i + 2]);
        i := i + 3;
      end;
      35:
      begin
        instruct_35(e[i + 1], e[i + 2], e[i + 3], e[i + 4]);
        i := i + 5;
      end;
      36:
      begin
        i := i + instruct_36(e[i + 1], e[i + 2], e[i + 3]);
        i := i + 4;
      end;
      37:
      begin
        instruct_37(e[i + 1]);
        i := i + 2;
      end;
      38:
      begin
        instruct_38(e[i + 1], e[i + 2], e[i + 3], e[i + 4]);
        i := i + 5;
      end;
      39:
      begin
        instruct_39(e[i + 1]);
        i := i + 2;
      end;
      40:
      begin
        instruct_40(e[i + 1]);
        i := i + 2;
      end;
      41:
      begin
        instruct_41(e[i + 1], e[i + 2], e[i + 3]);
        i := i + 4;
      end;
      42:
      begin
        i := i + instruct_42(e[i + 1], e[i + 2]);
        i := i + 3;
      end;
      43:
      begin
        i := i + instruct_43(e[i + 1], e[i + 2], e[i + 3]);
        i := i + 4;
      end;
      44:
      begin
        instruct_44(e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5], e[i + 6]);
        i := i + 7;
      end;
      45:
      begin
        instruct_45(e[i + 1], e[i + 2]);
        i := i + 3;
      end;
      46:
      begin
        instruct_46(e[i + 1], e[i + 2]);
        i := i + 3;
      end;
      47:
      begin
        instruct_47(e[i + 1], e[i + 2]);
        i := i + 3;
      end;
      48:
      begin
        instruct_48(e[i + 1], e[i + 2]);
        i := i + 3;
      end;
      49:
      begin
        instruct_49(e[i + 1], e[i + 2]);
        i := i + 3;
      end;
      50:
      begin
        p := instruct_50([e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5], e[i + 6], e[i + 7]]);
        i := i + 8;
        if p < 622592 then
          i := i + p
        else
          e[i + ((p + 32768) div 655360) - 1] := p mod 655360;
      end;
      51:
      begin
        instruct_51;
        i := i + 1;
      end;
      52:
      begin
        instruct_52;
        i := i + 1;
      end;
      53:
      begin
        instruct_53;
        i := i + 1;
      end;
      54:
      begin
        instruct_54;
        i := i + 1;
      end;
      55:
      begin
        i := i + instruct_55(e[i + 1], e[i + 2], e[i + 3], e[i + 4]);
        i := i + 5;
      end;
      56:
      begin
        instruct_56(e[i + 1]);
        i := i + 2;
      end;
      57:
      begin
        i := i + 1;
      end;
      58:
      begin
        instruct_58;
        i := i + 1;
      end;
      59:
      begin
        instruct_59;
        i := i + 1;
      end;
      60:
      begin
        i := i + instruct_60(e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5]);
        i := i + 6;
      end;
      61:
      begin
        i := i + e[i + 1];
        i := i + 3;
      end;
      62:
      begin
        instruct_62;
        i := i + 1;
        break;
      end;
      63:
      begin
        instruct_63(e[i + 1], e[i + 2]);
        i := i + 3;
      end;
      64:
      begin
        instruct_64;
        i := i + 1;
      end;
      65:
      begin
        i := i + 1;
      end;
      66:
      begin
        instruct_66(e[i + 1]);
        i := i + 2;
      end;
      67:
      begin
        instruct_67(e[i + 1]);
        i := i + 2;
      end;
      68:
      begin
        NewTalk(e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5], e[i + 6], e[i + 7]);
        i := i + 8;
      end;
      69:
      begin
        ReSetName(e[i + 1], e[i + 2], e[i + 3]);
        i := i + 4;
      end;
      70:
      begin
        ShowTiTle(e[i + 1], e[i + 2]);
        i := i + 3;
      end;
      71:
      begin
        JmpScene(e[i + 1], e[i + 2], e[i + 3]);
        i := i + 4;
      end;
    end;

  end;

  event.key.keysym.sym := 0;
  event.button.button := 0;

  //InitialScene;
  //if where <> 2 then CurEvent := -1;
  //redraw;
  //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  // SDL_EnableKeyRepeat(30, 30);

end;

procedure FourPets;
var
  r, i, r1: integer;
begin
  //setlength(Menuengstring, 4);
  r := 0;
  display_imgFromSurface(SKILL_PIC, 0, 0);
  ShowPetStatus(r + 1, 0);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  SDL_EnableKeyRepeat(10, 100);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then
          Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYDOWN:
      begin
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then
        begin
          r := r + 1;
          if r >= Rrole[0].PetAmount then
            r := 0;
          ShowPetStatus(r + 1, 0);
        end;
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          r := r - 1;
          if r < 0 then
            r := Rrole[0].PetAmount - 1;
          ShowPetStatus(r + 1, 0);
        end;
      end;

      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = sdlk_escape) then
        begin
          break;
        end;
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          if PetStatus(r + 1) = False then
            break;
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_right) then
        begin
          break;
        end;
        if (event.button.button = sdl_button_left) then
        begin
          if (round(event.button.x / (RealScreen.w / screen.w)) >= 10) and
            (round(event.button.x / (RealScreen.w / screen.w)) < 90) and
            (round(event.button.y / (RealScreen.h / screen.h)) > 20) and
            (round(event.button.y / (RealScreen.h / screen.h)) < (Rrole[0].PetAmount * 23) + 20) then
          begin
            r1 := r;
            r := (round(event.button.y / (RealScreen.h / screen.h)) - 20) div 23;
            //鼠标移动时仅在x, y发生变化时才重画
            if (r <> r1) then
            begin
              if PetStatus(r + 1) = False then
                break;
              //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
          end;
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        if (round(event.button.x / (RealScreen.w / screen.w)) < 120) then
        begin
          if (round(event.button.x / (RealScreen.w / screen.w)) >= 10) and
            (round(event.button.x / (RealScreen.w / screen.w)) < 90) and
            (round(event.button.y / (RealScreen.h / screen.h)) >= 20) and
            (round(event.button.y / (RealScreen.h / screen.h)) < (Rrole[0].PetAmount * 23) + 20) then
          begin
            r1 := r;
            r := (round(event.button.y / (RealScreen.h / screen.h)) - 20) div 23;
            //鼠标移动时仅在x, y发生变化时才重画
            if (r <> r1) then
            begin
              ShowPetStatus(r + 1, 0);
              //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
          end;
        end
        else //鼠标移动时仅在x, y发生变化时才重画

        if PetStatus(r + 1) = False then
          break;
      end;
    end;
  end;
  //r := CommonMenu(80, 30, 75, 3, r);
  //ShowCommonMenu(15, 15, 75, 3, r);
  //SDL_UpdateRect2(screen, 15, 15, 76, 316);
  SDL_EnableKeyRepeat(30, (30 * gamespeed) div 10);

end;

procedure ShowSkillMenu(menu: integer);
var
  i: integer;
begin
  display_imgFromSurface(SKILL_PIC, 10, 10, 10, 10, 110, 180);
  setlength(Menustring, 0);
  setlength(Menustring, 5);
  Menustring[0] := gbktounicode(@rrole[1].Name[0]);
  Menustring[1] := gbktounicode(@rrole[2].Name[0]);
  Menustring[2] := gbktounicode(@rrole[3].Name[0]);
  Menustring[3] := gbktounicode(@rrole[4].Name[0]);
  Menustring[4] := gbktounicode(@rrole[5].Name[0]);
  drawrectangle(15, 16, 100, rrole[0].PetAmount * 23 + 10, 0, colcolor(0, 255), 40);
  for I := 0 to Rrole[0].PetAmount - 1 do
  begin
    if i = menu then
    begin
      drawtext(screen, @Menustring[i][1], 5, 20 + 23 * i, colcolor($64));
      drawtext(screen, @Menustring[i][1], 6, 20 + 23 * i, colcolor($66));
    end
    else
    begin
      drawtext(screen, @Menustring[i][1], 5, 20 + 23 * i, colcolor($5));
      drawtext(screen, @Menustring[i][1], 6, 20 + 23 * i, colcolor($7));
    end;
  end;
  //  SDL_UpdateRect2(screen, 0, 0, 120, 440);
end;

function PetStatus(r: integer): boolean;
var
  i, menu, menup, p: integer;
  x, y, w: integer;
begin
  x := 100 + 40;
  y := 180 - 60;
  w := 50;
  p := 0;
  Result := False;

  menu := 0;
  ShowPetStatus(r, menu);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then
          Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_KP6) then
        begin
          menu := menu + 1;
          if menu >= 5 then
            menu := 0;
          Result := True;
          ShowPetStatus(r, menu);
        end;
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) then
        begin
          menu := menu - 1;
          if menu < 0 then
            menu := 4;
          Result := True;
          ShowPetStatus(r, menu);
        end;
        if (event.key.keysym.sym = sdlk_escape) then
        begin
          break;
        end;
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          PetLearnSkill(r, menu);
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_right) then
        begin
          Result := False;
          break;
        end;
        if (event.button.button = sdl_button_left) then
        begin
          if (round(event.button.x / (RealScreen.w / screen.w)) >= x) and
            (round(event.button.x / (RealScreen.w / screen.w)) < x + w * 5) and
            (round(event.button.y / (RealScreen.h / screen.h)) > y) and
            (round(event.button.y / (RealScreen.h / screen.h)) < y * 5) then
          begin
            menup := menu;
            menu := (round(event.button.x / (RealScreen.w / screen.w)) - x) div w;
            //鼠标移动时仅在x, y发生变化时才重画
            if (menu <> menup) then
            begin
              Result := False;
              showPetStatus(r, menu);
              //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
          end;
          PetLearnSkill(r, menu);
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        if (round(event.button.x / (RealScreen.w / screen.w)) < 120) then
        begin
          Result := True;
          break;
        end
        else if (round(event.button.x / (RealScreen.w / screen.w)) >= x) and
          (round(event.button.x / (RealScreen.w / screen.w)) < x + w * 5) and
          (round(event.button.y / (RealScreen.h / screen.h)) > y) and
          (round(event.button.y / (RealScreen.h / screen.h)) < y * 5) then
        begin
          menup := menu;
          menu := (round(event.button.x / (RealScreen.w / screen.w)) - x) div w;
          Result := False;
          //鼠标移动时仅在x, y发生变化时才重画
          if (menu <> menup) then
          begin
            showPetStatus(r, menu);
            //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          end;
        end;
      end;
    end;
  end;

end;

procedure ShowPetStatus(r, p: integer);
var
  i, x, y, w, col1, col2: integer;
  words: array[1..5, 0..4] of WideString;
  str: WideString;
begin
  ShowSkillMenu(r - 1);
  x := 100;
  y := 180;
  w := 50;
  //writeln(p);
  words[1, 0] := UTF8Decode(' 修武： 30％幾率在戰鬥後把對手武功整理出秘笈。');
  words[1, 1] := UTF8Decode(' 伴讀：') + gbktounicode(@rrole[0].Name[0]) + UTF8Decode('戰鬥經驗增加。');
  words[1, 2] := UTF8Decode(' 通武： 60％幾率在戰鬥後把對手武功整理出秘笈。');
  words[1, 3] := UTF8Decode(' 鑽研： 我方全員戰鬥經驗增加。');
  words[1, 4] := UTF8Decode(' 精武： 100％幾率把戰鬥後把對手武功整理出秘笈。');

  words[2, 0] := UTF8Decode(' 斂財： 戰鬥後增加銀兩收入。');
  words[2, 1] := UTF8Decode(' 話術： 從居民口中打探劇情線索。');
  words[2, 2] := UTF8Decode(' 神偷： 戰鬥後偷得對手隨身物品，裝備。');
  words[2, 3] := UTF8Decode(' 劃價： 城市交易打折扣。');
  words[2, 4] := UTF8Decode(' 通靈： 商店能購買隱藏寶物。');

  words[3, 0] := UTF8Decode(' 收集： 收集藥材與普通食材。');
  words[3, 1] := UTF8Decode(' 釀酒： 在酒窖耗費金錢與普通食材釀制各種酒。');
  words[3, 2] := UTF8Decode(' 食神： 收集珍贵材料。');
  words[3, 3] := UTF8Decode(' 煎藥： 在藥爐耗費金錢與藥材製造回復體內，解毒之*丹藥。');
  words[3, 4] := UTF8Decode(' 神丹： 在藥爐耗費金錢，特殊藥材煉製改變體質之丹*藥，可以隨時改變自身體質練功。');

  words[4, 0] := UTF8Decode(' 搜刮： 收集硝石和普通礦石。');
  words[4, 1] := UTF8Decode(' 淬毒： 在煉鐵爐耗費金錢、普通礦石、藥材製造帶毒*暗器。');
  words[4, 2] := UTF8Decode(' 機關： 機關難度降低。');
  words[4, 3] := UTF8Decode(' 鑄師： 在煉鐵爐將防具升級為寶甲。');
  words[4, 4] := UTF8Decode(' 神兵： 在煉鐵爐將兵器升級為神兵。');

  words[5, 0] := UTF8Decode(' 刺探： 戰鬥中可觀看敵人完整狀態。');
  words[5, 1] := UTF8Decode(' 鼓舞：') + gbktounicode(@rrole[0].Name[0]) + UTF8Decode('戰鬥中首先行動。');
  words[5, 2] := UTF8Decode(' 博愛： 醫療解毒可作用到附近三格内隊友。');
  words[5, 3] := UTF8Decode(' 激勵： 戰鬥中我方成員首先移動。');
  words[5, 4] := UTF8Decode(' 光環： 功體特效可作用到附近三格内隊友。');

  display_imgFromSurface(SKILL_PIC, 120, 0, 120, 0, 520, 440);
  // DrawRectangle(40, 60, 560, 315, 0, colcolor(255), 40);
  DrawHeadPic(r, 100 + 40, 150 - 60);

  if Rrole[r].Magic[p] > 0 then
  begin
    Rrole[r].Magic[p] := 1;
    str := UTF8Decode(' 已習得');
    col1 := colcolor(255);
    col2 := colcolor(255);
  end
  else
  begin
    str := UTF8Decode(' 未習得');
    col1 := $808080;
    col2 := $808080;
  end;
  DrawShadowText(@str[1], 90 + 40, 320 - 60, col1, col2);
  str := UTF8Decode(' 剩餘技能點數：');
  rrole[0].AddSkillPoint := min(rrole[0].AddSkillPoint, 10);
  DrawShadowText(@str[1], 180 + 40, 130 - 60, colcolor(0, 5), colcolor(0, 7));
  str := format('%3d', [rrole[0].AddSkillPoint + rrole[0].level - rrole[1].Magic[0] -
    rrole[2].Magic[0] - rrole[3].Magic[0] - rrole[4].Magic[0] - rrole[5].Magic[0] -
    (rrole[1].Magic[1] + rrole[2].Magic[1] + rrole[3].Magic[1] + rrole[4].Magic[1] + rrole[5].Magic[1]) *
    2 - (rrole[1].Magic[2] + rrole[2].Magic[2] + rrole[3].Magic[2] + rrole[4].Magic[2] + rrole[5].Magic[2]) *
    3 - (rrole[1].Magic[3] + rrole[2].Magic[3] + rrole[3].Magic[3] + rrole[4].Magic[3] + rrole[5].Magic[3]) *
    4 - (rrole[1].Magic[4] + rrole[2].Magic[4] + rrole[3].Magic[4] + rrole[4].Magic[4] + rrole[5].Magic[4]) * 5]);
  DrawShadowText(@str[1], 180 + 140 + 40, 130 - 60, colcolor(0, 5), colcolor(0, 7));

  for i := 0 to 4 do
  begin
    if Rrole[r].Magic[i] > 0 then
    begin
      DrawPngPic(SkillPic[(r - 1) * 5 + i], i * w + x + 40, y - 60, 0);
    end
    else
    begin
      drawframe(i * w + x + 1 + 40, y + 1 - 60, 39, colcolor(0, 0));
    end;
  end;

  drawframe(p * w + x + 40, y - 60, 41, colcolor(255));
  DrawShadowText(@words[r, p, 1], 90 + 20, 230 - 60, colcolor(0, 255), colcolor(0, 255));

  str := UTF8Decode(' 所需技能點數：');

  DrawShadowText(@str[1], 90 + 20, 290 - 60, colcolor(0, 5), colcolor(0, 7));

  str := format('%3d', [p + 1]);
  DrawShadowText(@str[1], 90 + 20 + 140, 290 - 60, colcolor(0, 5), colcolor(0, 7));

  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

end;

procedure DrawFrame(x, y, w: integer; color: Uint32);
var
  i: integer;
begin
  for i := 0 to w do
  begin
    putpixel(screen, x + i, y, color);
    putpixel(screen, x + i, y + w, color);
    putpixel(screen, x, y + i, color);
    putpixel(screen, x + w, y + i, color);
  end;

end;

procedure PetLearnSkill(r, s: integer);
var
  menu, x, y, w: integer;
begin
  x := 100;
  y := 180;
  w := 50;
  if (rrole[r].Magic[s] = 0) then
  begin
    setlength(Menustring, 0);
    setlength(Menustring, 2);
    menustring[0] := UTF8Decode(' 學習');
    menustring[1] := UTF8Decode(' 取消');


    if ((s = 0) or (rrole[r].Magic[s - 1] > 0)) and
      (s < (rrole[0].AddSkillPoint + rrole[0].level - rrole[1].Magic[0] - rrole[2].Magic[0] -
      rrole[3].Magic[0] - rrole[4].Magic[0] - rrole[5].Magic[0] - (rrole[1].Magic[1] +
      rrole[2].Magic[1] + rrole[3].Magic[1] + rrole[4].Magic[1] + rrole[5].Magic[1]) * 2 -
      (rrole[1].Magic[2] + rrole[2].Magic[2] + rrole[3].Magic[2] + rrole[4].Magic[2] + rrole[5].Magic[2]) *
      3 - (rrole[1].Magic[3] + rrole[2].Magic[3] + rrole[3].Magic[3] + rrole[4].Magic[3] + rrole[5].Magic[3]) *
      4 - (rrole[1].Magic[4] + rrole[2].Magic[4] + rrole[3].Magic[4] + rrole[4].Magic[4] +
      rrole[5].Magic[4]) * 5)) then
      if StadySkillMenu(x + 30 + w * s, y + 18, 98) = 0 then
      begin
        rrole[r].Magic[s] := 1;
        // rrole[r].Attack := rrole[r].Attack - rrole[r].MagLevel[s];
      end;
  end;
  setlength(Menustring, 0);
  showPetStatus(r, s);
end;

procedure ResistTheater;
var
  i: integer;
  str: array[0..9] of WideString;
begin

end;

procedure ReSetEntrance;
var
  i1, i2, i: integer;
begin
  for i1 := 0 to 479 do
    for i2 := 0 to 479 do
      Entrance[i1, i2] := -1;
  for i := 0 to length(RScene) - 1 do
  begin
    Entrance[RScene[i].MainEntranceX1, RScene[i].MainEntranceY1] := i;
    Entrance[RScene[i].MainEntranceX2, RScene[i].MainEntranceY2] := i;
  end;
end;

procedure CheckHotkey(key: cardinal);
begin
  //if key = sdlk_escape then exit;

  key := key - sdlk_1;

  if (key >= 0) and (key < 6) then
  begin
    resetpallet(0);
    case key of
      0:
      begin
        SelectShowStatus;
      end;
      1:
      begin
        SelectShowMagic;
      end;
      2:
      begin
        newMenuItem;
      end;
      3:
      begin
        NewMenuTeammate;
      end;
      4:
      begin
        FourPets;
      end;
      5:
      begin
        NewMenuSystem;
      end;
    end;
    resetpallet;
    redraw;
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    event.key.keysym.sym := 0;
    event.button.button := 0;
  end;

end;


function StadySkillMenu(x, y, w: integer): integer;
var
  menu, menup: integer;
begin
  menu := 0;
  SDL_EnableKeyRepeat(10, 100);
  //DrawMMap;
  display_imgFromSurface(SKILL_PIC, x, y, x, y, w + 1, 29);
  showcommonMenu2(x, y, w, menu);
  SDL_UpdateRect2(screen, x, y, w + 1, 29);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then
          Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYDown:
      begin
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_KP4) or
          (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_KP6) then
        begin
          if menu = 1 then
            menu := 0
          else
            menu := 1;
          display_imgFromSurface(SKILL_PIC, x, y, x, y, w + 1, 29);
          showcommonMenu2(x, y, w, menu);
          SDL_UpdateRect2(screen, x, y, w + 1, 29);
        end;
      end;

      SDL_KEYUP:
      begin

        if ((event.key.keysym.sym = sdlk_escape)) and (where <= 2) then
        begin
          Result := -1;
          SDL_UpdateRect2(screen, x, y, w + 1, 29);
          break;
        end;
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          Result := menu;
          SDL_UpdateRect2(screen, x, y, w + 1, 29);
          break;
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_right) and (where <= 2) then
        begin
          Result := -1;
          SDL_UpdateRect2(screen, x, y, w + 1, 29);
          break;
        end;
        if (event.button.button = sdl_button_left) then
        begin
          Result := menu;
          SDL_UpdateRect2(screen, x, y, w + 1, 29);
          break;
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        if (round(event.button.x / (RealScreen.w / screen.w)) >= x) and
          (round(event.button.x / (RealScreen.w / screen.w)) < x + w) and
          (round(event.button.y / (RealScreen.h / screen.h)) > y) and
          (round(event.button.y / (RealScreen.h / screen.h)) < y + 29) then
        begin
          menup := menu;
          menu := (round(event.button.x / (RealScreen.w / screen.w)) - x - 2) div 50;
          if menu > 1 then
            menu := 1;
          if menu < 0 then
            menu := 0;
          if menup <> menu then
          begin
            display_imgFromSurface(SKILL_PIC, x, y, x, y, w + 1, 29);
            showcommonMenu2(x, y, w, menu);
            SDL_UpdateRect2(screen, x, y, w + 1, 29);
          end;
        end;
      end;
    end;
  end;
  //清空键盘键和鼠标键值, 避免影响其余部分
  event.key.keysym.sym := 0;
  event.button.button := 0;
  SDL_EnableKeyRepeat(30, 30);
end;


procedure MenuDifficult;
var
  str: WideString;
  menu: integer;
begin
  str := UTF8Decode(' 選擇難度');
  redraw;
  drawtextwithrect(@str[1], 275, 270, 90, colcolor($21), colcolor($23));
  setlength(Menustring, 0);
  setlength(menustring, 6);
  //showmessage('');
  setlength(menuengstring, 0);
  menustring[0] := UTF8Decode('   極易');
  menustring[1] := UTF8Decode('   容易');
  menustring[2] := UTF8Decode('   中易');
  menustring[3] := UTF8Decode('   中難');
  menustring[4] := UTF8Decode('   困難');
  menustring[5] := UTF8Decode('   極難');
  menu := commonmenu(275, 300, 90, min(gametime, 5));
  if menu >= 0 then
  begin
    rrole[0].difficulty := menu * 20;
  end;

end;


//卷动选单 (带标题)

function TitleCommonScrollMenu(word: puint16; color1, color2: uint32; tx, ty, tw, max, maxshow: integer): integer;
var
  menu, menup, menutop, x, h, y, w: integer;
begin
  menu := 0;
  menutop := 0;
  x := tx;
  y := ty + 30;
  w := tw;

  SDL_EnableKeyRepeat(10, 100);
  //DrawMMap;
  maxshow := min(max + 1, maxshow);
  showTitlecommonscrollMenu(word, color1, color2, tx, ty, tw, max, maxshow, menu, menutop);
  h := min(maxshow * 22 + 29 + 8, screen.h - ty - 1);
  SDL_UpdateRect2(screen, tx, ty, tw + 1, h);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then
          Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYdown:
      begin
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then
        begin
          menu := menu + 1;
          if menu - menutop >= maxshow then
          begin
            menutop := menutop + 1;
          end;
          if menu > max then
          begin
            menu := 0;
            menutop := 0;
          end;
          showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
        end;
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          menu := menu - 1;
          if menu <= menutop then
          begin
            menutop := menu;
          end;
          if menu < 0 then
          begin
            menu := max;
            menutop := menu - maxshow + 1;
            if menutop < 0 then menutop := 0;
          end;
          showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
        end;
        if (event.key.keysym.sym = sdlk_pagedown) then
        begin
          menu := menu + maxshow;
          menutop := menutop + maxshow;
          if menu > max then
          begin
            menu := max;
          end;
          if menutop > max - maxshow + 1 then
          begin
            menutop := max - maxshow + 1;
          end;
          showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
        end;
        if (event.key.keysym.sym = sdlk_pageup) then
        begin
          menu := menu - maxshow;
          menutop := menutop - maxshow;
          if menu < 0 then
          begin
            menu := 0;
          end;
          if menutop < 0 then
          begin
            menutop := 0;
          end;
          showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
        end;

      end;

      SDL_KEYup:
      begin
        if ((event.key.keysym.sym = sdlk_escape)) and (where <= 2) then
        begin
          Result := -1;
          ReDraw;
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
          break;
        end;
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          Result := menu;
          //Redraw;
          //SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
          break;
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_right) and (where <= 2) then
        begin
          Result := -1;
          ReDraw;
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
          break;
        end;
        if (event.button.button = sdl_button_left) then
        begin
          Result := menu;
          // Redraw;
          // SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
          break;
        end;
        if (event.button.button = sdl_button_wheeldown) then
        begin
          menu := menu + 1;
          if menu - menutop >= maxshow then
          begin
            menutop := menutop + 1;
          end;
          if menu > max then
          begin
            menu := 0;
            menutop := 0;
          end;
          showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
        end;
        if (event.button.button = sdl_button_wheelup) then
        begin
          menu := menu - 1;
          if menu <= menutop then
          begin
            menutop := menu;
          end;
          if menu < 0 then
          begin
            menu := max;
            menutop := menu - maxshow + 1;
            if menutop < 0 then
            begin
              menutop := 0;
            end;
          end;
          showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        if (round(event.button.x / (RealScreen.w / screen.w)) >= x) and
          (round(event.button.x / (RealScreen.w / screen.w)) < x + w) and
          (round(event.button.y / (RealScreen.h / screen.h)) > y) and
          (round(event.button.y / (RealScreen.h / screen.h)) < y + max * 22 + 29) then
        begin
          menup := menu;
          menu := (round(event.button.y / (RealScreen.h / screen.h)) - y - 2) div 22 + menutop;
          if menu > max then
            menu := max;
          if menu < 0 then
            menu := 0;
          if menup <> menu then
          begin
            showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
            SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
          end;
        end;
      end;
    end;
  end;
  //清空键盘键和鼠标键值, 避免影响其余部分
  event.key.keysym.sym := 0;
  event.button.button := 0;
  SDL_EnableKeyRepeat(30, 30);
end;




procedure ShowTitleCommonScrollMenu(word: puint16; color1, color2: uint32;
  tx, ty, tw, max, maxshow, menu, menutop: integer);
var
  i, p, m, x, y, w: integer;
begin
  redraw;
  x := tx;
  y := ty + 30;
  w := tw;

  DrawRectangle(tx, ty, tw, 28, 0, colcolor(0, 255), 30);
  DrawShadowText(word, tx - 17, ty + 2, color1, color2);
  //showmessage(inttostr(y));
  m := min(maxshow, max + 1);
  DrawRectangle(x, y, w, m * 22 + 6, 0, colcolor(255), 30);
  if length(Menuengstring) > 0 then
    p := 1
  else
    p := 0;
  for i := menutop to menutop + m - 1 do
  begin
    if i = menu then
    begin
      drawshadowtext(@menustring[i][1], x - 17, y + 2 + 22 * (i - menutop), colcolor($64), colcolor($66));
      if p = 1 then
        drawengshadowtext(@menuengstring[i][1], x + 73, y + 2 + 22 * (i - menutop), colcolor($64), colcolor($66));
    end
    else
    begin
      drawshadowtext(@menustring[i][1], x - 17, y + 2 + 22 * (i - menutop), colcolor($5), colcolor($7));
      if p = 1 then
        drawengshadowtext(@menuengstring[i][1], x + 73, y + 2 + 22 * (i - menutop), colcolor($5), colcolor($7));
    end;
  end;
end;


procedure CloudCreate(num: integer);
begin
  CloudCreateOnSide(num);
  if num in [low(cloud)..high(cloud)] then
    Cloud[num].Positionx := random(17280);

end;

procedure CloudCreateOnSide(num: integer);
begin
  if num in [low(Cloud)..high(Cloud)] then
  begin
    Cloud[num].Picnum := random(9);
    Cloud[num].Shadow := 0;
    Cloud[num].Alpha := random(50) + 25;
    Cloud[num].MixColor := random(256) + random(256) shl 8 + random(256) shl 16 + random(256) shl 24;
    Cloud[num].mixAlpha := random(50);
    Cloud[num].Positionx := 0;
    Cloud[num].Positiony := random(8640);
    Cloud[num].Speedx := 1 + random(3);
    Cloud[num].Speedy := 0;
  end;
end;



//以下用于与delphi兼容
{$IFDEF fpc}

{$ELSE}

function FileExistsUTF8(filename: PChar): boolean; overload;
begin
  Result := FileExists(filename);
end;

function FileExistsUTF8(filename: string): boolean; overload;
begin
  Result := FileExists(filename);
end;

function UTF8Decode(str: WideString): WideString;
begin
  Result := str;
end;
{$ENDIF}

end.
