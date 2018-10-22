unit kysfunctions;

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
  Windows,
  math,
  Dialogs,
  SDL,
  SDL_TTF,
  SDL_mixer,
  SDL_image,
  iniFiles;

type

  TPosition = record
    x, y: integer;
  end;

  TRect = record
    x, y, w, h: integer;
  end;

  TItemList = record
    Number, Amount: Smallint;
  end;

  TCallType = (Element, Address);

  //以下所有类型均有两种引用方式：按照别名引用；按照短整数数组引用

  TRole = record
    case TCallType of
      Element:
      (ListNum, HeadNum, IncLife, UnUse: Smallint;
        Name, Nick: array[0..9] of char;
        Sexual, Level: Smallint;
        Exp: Uint16;
        CurrentHP, MaxHP, Hurt, Poision, PhyPower: Smallint;
        ExpForItem: Uint16;
        Equip: array[0..1] of Smallint;
        AmiFrameNum, AmiDelay, SoundDealy: array[0..4] of smallint;
        MPType, CurrentMP, MaxMP: Smallint;
        Attack, Speed, Defence, Medcine, UsePoi, MedPoi, DefPoi, Fist, Sword, Knife, Unusual, HidWeapon: Smallint;
        Knowledge, Ethics, AttPoi, AttTwice, Repute, Aptitude, PracticeBook: Smallint;
        ExpForBook: Uint16;
        Magic, MagLevel: array[0..9] of smallint;
        TakingItem, TakingItemAmount: array[0..3] of smallint);
      Address:
      (Data: array[0..90] of Smallint);
  end;

  TItem = record
    case TCallType of
      Element:
      (ListNum: Smallint;
        Name, Name1: array[0..19] of char;
        Introduction: array[0..29] of char;
        Magic, AmiNum, User, EquipType, ShowIntro, ItemType, UnKnow5, UnKnow6, UnKnow7: Smallint;
        AddCurrentHP, AddMaxHP, AddPoi, AddPhyPower, ChangeMPType, AddCurrentMP, AddMaxMP: Smallint;
        AddAttack, AddSpeed, AddDefence, AddMedcine, AddUsePoi, AddMedPoi, AddDefPoi: Smallint;
        AddFist, AddSword, AddKnife, AddUnusual, AddHidWeapon, AddKnowledge, AddEthics, AddAttTwice, AddAttPoi: Smallint;
        OnlyPracRole, NeedMPType, NeedMP, NeedAttack, NeedSpeed, NeedUsePoi, NeedMedcine, NeedMedPoi: Smallint;
        NeedFist, NeedSword, NeedKnife, NeedUnusual, NeedHidWeapon, NeedAptitude: Smallint;
        NeedExp, NeedExpForItem, NeedMaterial: Smallint;
        GetItem, NeedMatAmount: array[0..4] of Smallint);
      Address:
      (Data: array[0..94] of Smallint);
  end;

  TScence = record
    case TCallType of
      Element:
      (ListNum: Smallint;
        Name: array[0..9] of char;
        ExitMusic, EntranceMusic: Smallint;
        JumpScence, EnCondition: Smallint;
        MainEntranceY1, MainEntranceX1, MainEntranceY2, MainEntranceX2: Smallint;
        EntranceY, EntranceX: Smallint;
        ExitY, ExitX: array[0..2] of Smallint;
        JumpY1, JumpX1, JumpY2, JumpX2: Smallint);
      Address:
      (Data: array[0..25] of Smallint);
  end;

  TMagic = record
    case TCallType of
      Element:
      (ListNum: Smallint;
        Name: array[0..9] of char;
        UnKnow: array[0..4] of Smallint;
        SoundNum, MagicType, AmiNum, HurtType, AttAreaType, NeedMP, Poision: Smallint;
        Attack, MoveDistance, AttDistance, AddMP, HurtMP: array[0..9] of Smallint);
      Address:
      (Data: array[0..67] of Smallint);
  end;

  TShop = record
    case TCallType of
      Element:
      (Item, Amount, Price: array[0..4] of Smallint);
      Address:
      (Data: array[0..14] of Smallint);
  end;

  TBattleRole = record
    case TCallType of
      Element:
      (rnum, Team, Y, X, Face, Dead, Step, Acted: Smallint;
        Pic, ShowNumber, UnUse1, UnUse2, UnUse3, ExpGot, Auto: Smallint);
      Address:
      (Data: array[0..14] of Smallint);
  end;


  //程序重要子程
procedure Run;
procedure Quit;
procedure LoadR(num: integer);
procedure SaveR(num: integer);
function WaitAnyKey: integer;

//音频子程
procedure PlayMP3(MusicNum, times: integer); overload;
procedure PlayMP3(filename: pchar; times: integer); overload;
procedure StopMP3;
procedure PlaySound(SoundNum, times: integer); overload;
procedure PlaySound(SoundNum: integer); overload;
procedure PlaySound(filename: pchar; times: integer); overload;

//基本绘图子程
function getpixel(surface: PSDL_Surface; x: integer; y: integer): Uint32;
procedure putpixel(surface_: PSDL_Surface; x: integer; y: integer; pixel: Uint32);
procedure drawscreenpixel(x, y: integer; color: Uint32);
procedure display_bmp(file_name: PChar; x, y: integer);
procedure display_img(file_name: PChar; x, y: integer);
function ColColor(num: integer): Uint32;

//画RLE8图片的子程
procedure DrawRLE8Pic(num, px, py: Integer; Pidx: Pinteger; Ppic: PByte; RectArea: TRect; Image: PChar; Shadow: Integer);
function GetPositionOnScreen(x, y, CenterX, CenterY: integer): TPosition;
procedure DrawTitlePic(imgnum, px, py: integer);
function JudgeInScreen(px, py, w, h, xs, ys: integer): boolean; overload;
function JudgeInScreen(px, py, w, h, xs, ys, xx, yy, xw, yh: integer): boolean; overload;
procedure DrawMPic(num, px, py: integer);
procedure DrawSPic(num, px, py, x, y, w, h: integer);
procedure DrawHeadPic(num, px, py: integer);
function InitialBField: boolean;
procedure DrawBPic(num, px, py, shadow: integer);
procedure DrawBPicInRect(num, px, py, shadow, x, y, w, h: integer);
procedure InitialBPic(num, px, py: integer);
procedure DrawEPic(num, px, py: integer);
procedure DrawFPic(num, px, py: integer);

//绘制整个屏幕的子程
procedure Redraw;
procedure DrawMMap;
procedure DrawScence;
procedure DrawScenceWithoutRole(x, y: integer);
procedure DrawRoleOnScence(x, y: integer);
procedure InitialSPic(num, px, py, x, y, w, h: integer);
procedure InitialScence();
procedure UpdateScence(xs, ys: integer);
procedure LoadScencePart(x, y: integer);
procedure LoadBfieldPart(x, y: integer);
procedure DrawBfieldWithoutRole(x, y: integer);
procedure DrawWholeBField;
procedure DrawRoleOnBfield(x, y: integer);
procedure InitialWholeBField;
procedure DrawBFieldWithCursor(step: integer);
procedure DrawBFieldWithEft(Epicnum: integer);
procedure DrawBFieldWithAction(bnum, Apicnum: integer);

//显示文字的子程
procedure DrawText(sur: PSDL_Surface; word: PUint16; x_pos, y_pos: integer; color: Uint32);
procedure DrawEngText(sur: PSDL_Surface; word: PUint16; x_pos, y_pos: integer; color: Uint32);
procedure DrawShadowText(word: PUint16; x_pos, y_pos: integer; color1, color2: Uint32);
procedure DrawEngShadowText(word: PUint16; x_pos, y_pos: integer; color1, color2: Uint32);
procedure DrawBig5Text(sur: PSDL_Surface; str: PChar; x_pos, y_pos: integer; color: Uint32);
procedure DrawBig5ShadowText(word: pchar; x_pos, y_pos: integer; color1, color2: Uint32);
function Big5ToUnicode(str: PChar): widestring;
function UnicodeToBig5(str: PWideChar): string;
procedure DrawTextWithRect(word: puint16; x, y, w: integer; color1, color2: uint32);
procedure DrawRectangle(x, y, w, h: integer; colorin, colorframe: Uint32; alphe: integer);
procedure DrawRectangleWithoutFrame(x, y, w, h: integer; colorin: Uint32; alphe: integer);

//游戏开始画面, 行走等
procedure Start;
procedure StartAmi;
procedure ReadFiles;
procedure InitialRole;
procedure Walk;
function CanWalk(x, y: integer): boolean;
procedure CheckEntrance;
function InScence(open: integer): integer;
procedure ShowScenceName(snum: integer);
function CanWalkInScence(x, y: integer): boolean;
procedure CheckEvent3;

//选单子程
function CommonMenu(x, y, w, max: integer): integer;
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
function MenuItem: boolean;
function ReadItemList(ItemType: integer): integer;
procedure ShowMenuItem(row, col, x, y, atlu: integer);
procedure DrawItemFrame(x, y: integer);
procedure UseItem(inum: integer);
function CanEquip(rnum, inum: integer): boolean;
procedure MenuLeave;
procedure MenuStatus;
procedure ShowStatus(rnum: integer);
procedure MenuSystem;
procedure ShowMenuSystem(menu: integer);
procedure MenuLoad;
procedure MenuLoadAtBeginning;
procedure MenuSave;
procedure MenuQuit;

//医疗, 解毒, 使用物品的效果等
procedure EffectMedcine(role1, role2: integer);
procedure EffectMedPoision(role1, role2: integer);
procedure EatOneItem(rnum, inum: integer);

//事件系统
//在英文中, instruct通常不作为名词, swimmingfish在他的一份反汇编文件中大量使用
//这个词表示"指令", 所以这里仍保留这种用法
procedure CallEvent(num: integer);
procedure instruct_0;
procedure instruct_1(talknum, headnum, dismode: integer);
procedure instruct_2(inum, amount: integer);
procedure ReArrangeItem;
procedure instruct_3(list: array of integer);
function instruct_4(inum, jump1, jump2: integer): integer;
function instruct_5(jump1, jump2: integer): integer;
function instruct_6(battlenum, jump1, jump2, getexp: integer): integer;
procedure instruct_8(musicnum: integer);
function instruct_9(jump1, jump2: integer): integer;
procedure instruct_10(rnum: integer);
function instruct_11(jump1, jump2: integer): integer;
procedure instruct_12;
procedure instruct_13;
procedure instruct_14;
procedure instruct_15;
function instruct_16(rnum, jump1, jump2: integer): integer;
procedure instruct_17(list: array of integer);
function instruct_18(inum, jump1, jump2: integer): integer;
procedure instruct_19(x, y: integer);
function instruct_20(jump1, jump2: integer): integer;
procedure instruct_21(rnum: integer);
procedure instruct_22;
procedure instruct_23(rnum, Poision: integer);
procedure instruct_24;
procedure instruct_25(x1, y1, x2, y2: integer);
procedure instruct_26(snum, enum, add1, add2, add3: integer);
procedure instruct_27(enum, beginpic, endpic: integer);
function instruct_28(rnum, e1, e2, jump1, jump2: integer): integer;
function instruct_29(rnum, r1, r2, jump1, jump2: integer): integer;
procedure instruct_30(x1, y1, x2, y2: integer);
function instruct_31(moneynum, jump1, jump2: integer): integer;
procedure instruct_32(inum, amount: integer);
procedure instruct_33(rnum, magicnum, dismode: integer);
procedure instruct_34(rnum, iq: integer);
procedure instruct_35(rnum, magiclistnum, magicnum, exp: integer);
function instruct_36(sexual, jump1, jump2: integer): integer;
procedure instruct_37(Ethics: integer);
procedure instruct_38(snum, layernum, oldpic, newpic: integer);
procedure instruct_39(snum: integer);
procedure instruct_40(director: integer);
procedure instruct_41(rnum, inum, amount: integer);
function instruct_42(jump1, jump2: integer): integer;
function instruct_43(inum, jump1, jump2: integer): integer;
procedure instruct_44(enum1, beginpic1, endpic1, enum2, beginpic2, endpic2: integer);
procedure instruct_45(rnum, speed: integer);
procedure instruct_46(rnum, mp: integer);
procedure instruct_47(rnum, attack: integer);
procedure instruct_48(rnum, hp: integer);
procedure instruct_49(rnum, MPpro: integer);
function instruct_50(list: array of integer): integer;
procedure instruct_51;
procedure instruct_52;
procedure instruct_53;
procedure instruct_54;
function instruct_55(enum, value, jump1, jump2: integer): integer;
procedure instruct_56(Repute: integer);
procedure instruct_58;
procedure instruct_59;
function instruct_60(snum, enum, pic, jump1, jump2: integer): integer;
procedure instruct_62;
procedure EndAmi;
procedure instruct_63(rnum, sexual: integer);
procedure instruct_64;
procedure instruct_66(musicnum: integer);
procedure instruct_67(Soundnum: integer);
function e_GetValue(bit, t, x: integer): integer;
function instruct_50e(code, e1, e2, e3, e4, e5, e6: integer): integer;

//战斗
//从游戏文件的命名来看, 应是'war'这个词的缩写,
//但实际上战斗的规模很小, 使用'battle'显然更合适
function Battle(battlenum, getexp: integer): boolean;
function SelectTeamMembers: integer;
procedure ShowMultiMenu(max, menu, status: integer);
procedure BattleMainControl;
procedure ReArrangeBRole;
function BattleStatus: integer;
function BattleMenu(bnum: integer): integer;
procedure ShowBMenu(MenuStatus, menu, max: integer);
procedure CalMoveAbility;
procedure Move(bnum: integer);
procedure MoveAmination(bnum: integer);
function SelectAim(bnum, step: integer): boolean;
function SelectDirector(bnum: integer): boolean;
procedure SeekPath(x, y, step: integer);
procedure CalCanSelect(bnum, mode: integer);
procedure Attack(bnum: integer);
procedure AttackAction(bnum, mnum, level: integer);
function SelectMagic(rnum: integer): integer;
procedure ShowMagicMenu(menustatus, menu, max: integer);
procedure SetAminationPosition(mode, step: integer);
procedure PlayMagicAmination(bnum, enum: integer);
procedure CalHurtRole(bnum, mnum, level: integer);
function CalHurtValue(bnum1, bnum2, mnum, level: integer): integer;
procedure ShowHurtValue(mode: integer);
procedure CalPoiHurtLife;
procedure ClearDeadRolePic;
procedure ShowSimpleStatus(rnum, x, y: integer);
procedure Wait(bnum: integer);
procedure RestoreRoleStatus;
procedure AddExp;
procedure CheckLevelUp;
procedure LevelUp(bnum: integer);
procedure CheckBook;
function CalRNum(team: integer): integer;
procedure BattleMenuItem(bnum: integer);
procedure UsePoision(bnum: integer);
procedure PlayActionAmination(bnum, mode: integer);
procedure Medcine(bnum: integer);
procedure MedPoision(bnum: integer);
procedure UseHiddenWeapen(bnum, inum: integer);
procedure Rest(bnum: integer);

procedure AutoBattle(bnum: integer);
procedure AutoUseItem(bnum, list: integer);

implementation

var

  CHINESE_FONT: PAnsiChar = 'resource\kaiu.ttf';
  CHINESE_FONT_SIZE: integer = 20;
  ENGLISH_FONT: PAnsiChar = 'resource\consola.ttf';
  ENGLISH_FONT_SIZE: integer = 18;

  CENTER_X: integer = 320;
  CENTER_Y: integer = 220;

  //以下为常数表, 其中多数可以由ini文件改变

  ITEM_BEGIN_PIC: integer = 3501; //物品起始图片
  BEGIN_EVENT: integer = 691; //初始事件
  BEGIN_SCENCE: integer = 70; //初始场景
  BEGIN_Sx: integer = 20; //初始坐标(程序中的x, y与游戏中是相反的, 这是早期的遗留问题)
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

  MaxProList: array[43..58] of integer = (100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 100, 1);
  //最大攻击值~最大左右互博值

  LIFE_HURT: integer = 10; //伤害值比例

  //以下3个常数实际并未使用, 不能由ini文件指定
  NOVEL_BOOK: integer = 144; //天书起始编码(因偷懒并未使用)
  MAX_HEAD_NUM: integer = 189; //有专有头像的最大人物编号, 仅用于对话指令
  BEGIN_WALKPIC: integer = 2500; //起始的行走贴图(并未使用)


  MPic, SPic, WPic, EPic: array[0..5000000] of byte;
  MIdx, SIdx, WIdx, EIdx: array[0..10000] of integer;
  FPic: array[0..1000000] of byte;
  FIdx: array[0..300] of integer;
  HPic: array[0..2000000] of byte;
  HIdx: array[0..500] of integer;
  //以上为贴图的内容及索引
  Earth, Surface, Building, BuildX, BuildY, Entrance: array[0..479, 0..479] of smallint;
  //主地图数据
  ACol: array[0..768] of byte;
  //默认调色板数据
  InShip, Useless1, Mx, My, Sx, Sy, MFace, ShipX, ShipY, ShipX1, ShipY1, ShipFace: Smallint;
  TeamList: array[0..5] of Smallint;
  RItemList: array of TItemList;

  MStep, Still: integer;
  //主地图坐标, 方向, 步数, 是否处于静止
  Cx, Cy, SFace, SStep: integer;
  //场景内坐标, 场景中心点, 方向, 步数
  CurScence, CurEvent, CurItem, CurrentBattle, Where: integer;
  //当前场景, 事件(在场景中的事件号), 使用物品, 战斗
  //where: 0-主地图, 1-场景, 2-战场, 3-开头画面
  SaveNum: integer;
  //存档号, 未使用
  RRole: array[0..600] of TRole;
  RItem: array[0..500] of TItem;
  RScence: array[0..200] of TScence;
  RMagic: array[0..200] of TMagic;
  RShop: array[0..10] of TShop;
  //R文件数据, 均远大于原有容量

  ItemList: array[0..500] of smallint;

  SData: array[0..400, 0..5, 0..63, 0..63] of smallint;
  DData: array[0..400, 0..199, 0..10] of smallint;
  //S, D文件数据
  //Scence1, SData[CurScence, 1, , Scence3, Scence4, Scence5, Scence6, Scence7, Scence8: array[0..63, 0..63] of smallint;
  //当前场景数据
  //0-地面, 1-建筑, 2-物品, 3-事件, 4-建筑高度, 5-物品高度
  ScenceImg: array[0..2303, 0..1151] of Uint32;
  //场景的图形映像. 实时重画场景效率较低, 故首先生成映像, 需要时载入
  //ScenceD: array[0..199, 0..10] of smallint;
  //当前场景事件
  BFieldImg: array[0..2303, 0..1151] of Uint32;
  //战场图形映像
  BField: array[0..7, 0..63, 0..63] of smallint;
  //战场数据
  //0-地面, 1-建筑, 2-人物, 3-可否被选中, 4-攻击范围, 5, 6 ,7-未使用
  WarSta: array[0..$5D] of smallint;
  //战场数据, 即war.sta文件的映像
  BRole: array[0..99] of TBattleRole;
  //战场人物属性
  //0-人物序号, 1-敌我, 2, 3-坐标, 4-面对方向, 5-是否仍在战场, 6-可移动步数, 7-是否行动完毕,
  //8-贴图(未使用), 9-头上显示数字, 10, 11, 12-未使用, 13-已获得经验, 14-是否自动战斗
  BRoleAmount: integer;
  //战场人物总数
  Bx, By, Ax, Ay: integer;
  //当前人物坐标, 选择目标的坐标
  Bstatus: integer;
  //战斗状态, 0-继续, 1-胜利, 2-失败

  LeaveList: array[0..99] of smallint;
  EffectList: array[0..199] of smallint;
  LevelUpList: array[0..99] of smallint;
  MatchList: array[0..99, 0..2] of smallint;
  //各类列表, 前四个从文件读入

  fullscreen: integer;
  //是否全屏

  screen: PSDL_Surface;
  //主画面
  event: TSDL_Event;
  //事件
  Font, EngFont: PTTF_Font;
  TextColor: TSDL_Color;
  text: PSDL_Surface;
  //字体

  Music: PMix_Music;
  Sound: PMix_Chunk;
  //声音
  ExitScenceMusicNum: integer;
  //离开场景的音乐
  MusicName: string;

  MenuString, MenuEngString: array of widestring;
  //选单所使用的字符串

  x50: array[-$8000..$7FFF] of smallint;
  //扩充指令50所使用的变量

//初始化字体, 音效, 视频, 启动游戏

procedure Run;
begin
  //初始化字体
  TTF_Init();
  font := TTF_OpenFont(CHINESE_FONT, CHINESE_FONT_SIZE);
  engfont := TTF_OpenFont(ENGLISH_FONT, ENGLISH_FONT_SIZE);
  if font = nil then
  begin
    MessageBox(0, PChar(Format('Error:%s!', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
    exit;
  end;

  //初始化视频系统
  Randomize;
  if (SDL_Init(SDL_INIT_VIDEO) < 0) then
  begin
    MessageBox(0, PChar(Format('Couldn''t initialize SDL : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
    SDL_Quit;
    exit;
  end;

  //初始化音频系统
  SDL_Init(SDL_INIT_AUDIO);
  Mix_OpenAudio(MIX_DEFAULT_FREQUENCY, MIX_DEFAULT_FORMAT, 2, 4096);
  music := nil;
  SDL_WM_SetIcon(IMG_Load('resource\icon.png'), 0);
  screen := SDL_SetVideoMode(CENTER_X * 2, CENTER_Y * 2, 32, SDL_SWSURFACE {or SDL_DOUBLEBUF {or SDL_FULLSCREEN});

  if (screen = nil) then
  begin
    MessageBox(0, PChar(Format('Couldn''t set 640x480x8 video mode : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
    SDL_Quit;
    halt(1);
  end;

  SDL_WM_SetCaption('All Heros in Kam Yung''s Stories - Replicated Edition', 's.weyl');

  start;

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
  TTF_CloseFont(font);
  TTF_CloseFont(engfont);
  TTF_Quit;
  SDL_Quit;
  halt(1);
  exit;
end;

//播放mp3音乐

procedure PlayMP3(MusicNum, times: integer); overload;
var
  str: string;
begin
  str := 'music\' + inttostr(musicnum) + '.mp3';
  if fileexists(pchar(str)) then
  begin
    Music := Mix_LoadMUS(pchar(str));
    Mix_volumemusic(MIX_MAX_VOLUME div 3);
    Mix_PlayMusic(music, times);
  end;
end;

procedure PlayMP3(filename: pchar; times: integer); overload;
begin
  if fileexists(filename) then
  begin
    Music := Mix_LoadMUS(filename);
    Mix_volumemusic(MIX_MAX_VOLUME div 3);
    Mix_PlayMusic(music, times);
  end;
end;

//停止当前播放的音乐

procedure StopMP3;
begin
  if music <> nil then
  begin
    Mix_HaltMusic;
    Mix_FreeMusic(music);
  end;
  //  Mix_HaltMusic;
  music := nil;
  //Mix_CloseAudio;
end;

//播放wav音效

procedure PlaySound(SoundNum, times: integer); overload;
var
  i: integer;
  str: string;
begin
  str := 'sound\e' + format('%2d', [soundnum]) + '.wav';
  for i := 1 to length(str) do
    if str[i] = ' ' then str[i] := '0';
  if fileexists(pchar(str)) then
  begin
    sound := Mix_LoadWav(pchar(str));
    Mix_PlayChannel(-1, sound, times);
  end;
end;

procedure PlaySound(SoundNum: integer); overload;
var
  i: integer;
  str: string;
begin
  str := 'sound\e' + format('%2d', [soundnum]) + '.wav';
  for i := 1 to length(str) do
    if str[i] = ' ' then str[i] := '0';
  if fileexists(pchar(str)) then
  begin
    sound := Mix_LoadWav(pchar(str));
    Mix_PlayChannel(-1, sound, 0);
  end;
end;

procedure PlaySound(filename: pchar; times: integer); overload;
begin
  if fileexists(filename) then
  begin
    Sound := Mix_LoadWav(filename);
    Mix_PlayChannel(-1, sound, times);
  end;
end;

//读入存档, 如为0则读入起始存档

procedure LoadR(num: integer);
var
  filename: string;
  idx, grp, i1, i2, len, ScenceAmount: integer;
  BasicOffset, RoleOffset, ItemOffset, ScenceOffset, MagicOffset, WeiShopOffset, i: integer;
begin
  SaveNum := num;
  filename := 'R' + inttostr(num);

  if num = 0 then filename := 'ranger';
  idx := fileopen('save\ranger.idx', fmopenread);
  grp := fileopen('save\' + filename + '.grp', fmopenread);

  fileread(idx, RoleOffset, 4);
  fileread(idx, ItemOffset, 4);
  fileread(idx, ScenceOffset, 4);
  fileread(idx, MagicOffset, 4);
  fileread(idx, WeiShopOffset, 4);
  fileread(idx, len, 4);
  fileseek(grp, 0, 0);

  fileread(grp, Inship, 2);
  fileread(grp, UseLess1, 2);
  fileread(grp, My, 2);
  fileread(grp, Mx, 2);
  fileread(grp, Sy, 2);
  fileread(grp, Sx, 2);
  fileread(grp, Mface, 2);
  fileread(grp, shipx, 2);
  fileread(grp, shipy, 2);
  fileread(grp, shipx1, 2);
  fileread(grp, shipy1, 2);
  fileread(grp, shipface, 2);
  fileread(grp, teamlist[0], 2 * 6);
  fileread(grp, Ritemlist[0], sizeof(Titemlist) * max_item_amount);
  fileread(grp, RRole[0], ItemOffset - RoleOffset);
  fileread(grp, RItem[0], ScenceOffset - ItemOffset);
  fileread(grp, RScence[0], MagicOffset - ScenceOffset);
  fileread(grp, RMagic[0], WeiShopOffset - MagicOffset);
  fileread(grp, Rshop[0], len - WeiShopOffset);
  fileclose(idx);
  fileclose(grp);

  //初始化入口

  ScenceAmount := (MagicOffset - ScenceOffset) div 52;
  for i := 0 to ScenceAmount - 1 do
  begin
    Entrance[RScence[i].MainEntranceX1, RScence[i].MainEntranceY1] := i;
    Entrance[RScence[i].MainEntranceX2, RScence[i].MainEntranceY2] := i;
  end;

  filename := 'S' + inttostr(num);
  if num = 0 then filename := 'Allsin';
  grp := fileopen('save\' + filename + '.grp', fmopenread);
  fileread(grp, Sdata, ScenceAmount * 64 * 64 * 6 * 2);
  fileclose(grp);
  filename := 'D' + inttostr(num);
  if num = 0 then filename := 'Alldef';
  grp := fileopen('save\' + filename + '.grp', fmopenread);
  fileread(grp, Ddata, ScenceAmount * 200 * 11 * 2);
  fileclose(grp);

end;

//存档

procedure SaveR(num: integer);
var
  filename: string;
  idx, grp, i1, i2, length, ScenceAmount: integer;
  BasicOffset, RoleOffset, ItemOffset, ScenceOffset, MagicOffset, WeiShopOffset, i: integer;
begin
  SaveNum := num;
  filename := 'R' + inttostr(num);

  if num = 0 then filename := 'ranger';
  idx := fileopen('save\ranger.idx', fmopenread);
  grp := filecreate('save\' + filename + '.grp', fmopenreadwrite);
  BasicOffset := 0;
  fileread(idx, RoleOffset, 4);
  fileread(idx, ItemOffset, 4);
  fileread(idx, ScenceOffset, 4);
  fileread(idx, MagicOffset, 4);
  fileread(idx, WeiShopOffset, 4);
  fileread(idx, length, 4);
  fileseek(grp, 0, 0);
  filewrite(grp, Inship, 2);
  filewrite(grp, UseLess1, 2);
  filewrite(grp, My, 2);
  filewrite(grp, Mx, 2);
  filewrite(grp, Sy, 2);
  filewrite(grp, Sx, 2);
  filewrite(grp, Mface, 2);
  filewrite(grp, shipx, 2);
  filewrite(grp, shipy, 2);
  filewrite(grp, shipx1, 2);
  filewrite(grp, shipy1, 2);
  filewrite(grp, shipface, 2);
  filewrite(grp, teamlist[0], 2 * 6);
  filewrite(grp, Ritemlist[0], sizeof(Titemlist) * max_item_amount);

  filewrite(grp, RRole[0], ItemOffset - RoleOffset);
  filewrite(grp, RItem[0], ScenceOffset - ItemOffset);
  filewrite(grp, RScence[0], MagicOffset - ScenceOffset);
  filewrite(grp, RMagic[0], WeiShopOffset - MagicOffset);
  filewrite(grp, Rshop[0], length - WeiShopOffset);
  fileclose(idx);
  fileclose(grp);

  ScenceAmount := (MagicOffset - ScenceOffset) div 52;

  filename := 'S' + inttostr(num);
  if num = 0 then filename := 'Allsin';
  grp := filecreate('save\' + filename + '.grp');
  filewrite(grp, Sdata, ScenceAmount * 64 * 64 * 6 * 2);
  fileclose(grp);
  filename := 'D' + inttostr(num);
  if num = 0 then filename := 'Alldef';
  grp := filecreate('save\' + filename + '.grp');
  filewrite(grp, Ddata, ScenceAmount * 200 * 11 * 2);
  fileclose(grp);

end;

//等待任意按键

function WaitAnyKey: integer;
begin
  //event.type_ := SDL_NOEVENT;
  event.key.keysym.sym := 0;
  event.button.button := 0;
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    if (event.type_ = SDL_QUITEV) then
      if messagedlg('Are you sure to quit?', mtConfirmation, [mbOk, mbCancel], 0) = idOK then Quit;
    if (event.type_ = SDL_KEYUP) or (event.type_ = SDL_mousebuttonUP) then
      if (event.key.keysym.sym <> 0) or (event.button.button <> 0) then break;
  end;
  result := event.key.keysym.sym;
  event.key.keysym.sym := 0;
  event.button.button := 0;
end;

//获取某像素信息

function getpixel(surface: PSDL_Surface; x: integer; y: integer): Uint32;
type
  TByteArray = array[0..2] of Byte;
  PByteArray = ^TByteArray;
var
  bpp: integer;
  p: PInteger;
begin
  if (x >= 0) and (x < screen.w) and (y >= 0) and (y < screen.h) then
  begin
    bpp := surface.format.BytesPerPixel;
    // Here p is the address to the pixel we want to retrieve
    p := Pointer(Uint32(surface.pixels) + y * surface.pitch + x * bpp);
    case bpp of
      1:
        result := LongWord(p^);
      2:
        result := PUint16(p)^;
      3:
        if (SDL_BYTEORDER = SDL_BIG_ENDIAN) then
          result := PByteArray(p)[0] shl 16 or PByteArray(p)[1] shl 8 or PByteArray(p)[2]
        else
          result := PByteArray(p)[0] or PByteArray(p)[1] shl 8 or PByteArray(p)[2] shl 16;
      4:
        result := PUint32(p)^;
    else
      result := 0; // shouldn't happen, but avoids warnings
    end;
  end;

end;

//画像素

procedure putpixel(surface_: PSDL_Surface; x: integer; y: integer; pixel: Uint32);
type
  TByteArray = array[0..2] of Byte;
  PByteArray = ^TByteArray;
var
  bpp: integer;
  p: PInteger;
begin
  if (x >= 0) and (x < screen.w) and (y >= 0) and (y < screen.h) then
  begin
    bpp := surface_.format.BytesPerPixel;
    // Here p is the address to the pixel we want to set
    p := Pointer(Uint32(surface_.pixels) + y * surface_.pitch + x * bpp);

    case bpp of
      1:
        LongWord(p^) := pixel;
      2:
        PUint16(p)^ := pixel;
      3:
        if (SDL_BYTEORDER = SDL_BIG_ENDIAN) then
        begin
          PByteArray(p)[0] := (pixel shr 16) and $FF;
          PByteArray(p)[1] := (pixel shr 8) and $FF;
          PByteArray(p)[2] := pixel and $FF;
        end
        else
        begin
          PByteArray(p)[0] := pixel and $FF;
          PByteArray(p)[1] := (pixel shr 8) and $FF;
          PByteArray(p)[2] := (pixel shr 16) and $FF;
        end;
      4:
        PUint32(p)^ := pixel;
    end;
  end;

end;

//画一个点

procedure drawscreenpixel(x, y: integer; color: Uint32);
begin
  (* Map the color yellow to this display (R := $ff, G := $FF, B := $00)
     Note:  If the display is palettized, you must set the palette first.
  *)
  if (SDL_MustLock(screen)) then
  begin
    if (SDL_LockSurface(screen) < 0) then
    begin
      MessageBox(0, PChar(Format('Can''t lock screen : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
  end;

  putpixel(screen, x, y, color);

  if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;
  // Update just the part of the display that we've changed
  SDL_UpdateRect(screen, x, y, 1, 1);
end;

//显示bmp文件

procedure display_bmp(file_name: PChar; x, y: integer);
var
  image: PSDL_Surface;
  dest: TSDL_Rect;
begin
  if fileexists(file_name) then
  begin
    image := SDL_LoadBMP(file_name);
    if (image = nil) then
    begin
      MessageBox(0, PChar(Format('Couldn''t load %s : %s', [file_name, SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
    dest.x := x;
    dest.y := y;
    if (SDL_BlitSurface(image, nil, screen, @dest) < 0) then
      MessageBox(0, PChar(Format('BlitSurface error : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
    //SDL_UpdateRect(screen, 0, 0, image.w, image.h);
    SDL_FreeSurface(image);
  end;
end;

//显示tif, png, jpg等格式图片

procedure display_img(file_name: PChar; x, y: integer);
var
  image: PSDL_Surface;
  dest: TSDL_Rect;
begin
  if fileexists(file_name) then
  begin
    image := IMG_Load(file_name);
    if (image = nil) then
    begin
      MessageBox(0, PChar(Format('Couldn''t load %s : %s',
        [file_name, SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
    dest.x := x;
    dest.y := y;
    if (SDL_BlitSurface(image, nil, screen, @dest) < 0) then
      MessageBox(0, PChar(Format('BlitSurface error : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
    //SDL_UpdateRect(screen, 0, 0, image.w, image.h);
    SDL_FreeSurface(image);
  end;
end;

//取调色板的颜色, 视频系统是32位色, 但很多时候仍需要原调色板的颜色

function ColColor(num: integer): Uint32;
begin
  colcolor := SDL_mapRGB(screen.format, Acol[num * 3 + 2] * 4, Acol[num * 3 + 1] * 4, Acol[num * 3] * 4);
end;

//RLE8图片绘制子程，所有相关子程均对此封装

procedure DrawRLE8Pic(num, px, py: integer; Pidx: Pinteger; Ppic: PByte; RectArea: TRect; Image: PChar; shadow: integer);
var
  w, h, xs, ys: smallint;
  offset, length, p: integer;
  l, l1, ix, iy: Byte;
begin
  if num = 0 then offset := 0
  else begin
    inc(Pidx, num - 1);
    offset := Pidx^;
  end;

  Inc(Ppic, offset);
  w := Psmallint((Ppic))^;
  Inc(Ppic, 2);
  h := Psmallint((Ppic))^;
  Inc(Ppic, 2);
  xs := Psmallint((Ppic))^;
  Inc(Ppic, 2);
  ys := Psmallint((Ppic))^;
  Inc(Ppic, 2);
  if JudgeInScreen(px, py, w, h, xs, ys, RectArea.x, RectArea.y, RectArea.w, RectArea.h) then
  begin
    for iy := 1 to h do
    begin
      l := Ppic^;
      inc(Ppic, 1);
      w := 1;
      p := 0;
      for ix := 1 to l do
      begin
        l1 := Ppic^;
        inc(Ppic);
        if p = 0 then
        begin
          w := w + l1;
          p := 1;
        end else
          if p = 1 then
          begin
            p := 2 + l1;
          end else
            if p > 2 then
            begin
              p := p - 1;
              if (w - xs + px >= RectArea.x) and (iy - ys + py >= RectArea.y) and (w - xs + px < RectArea.x + RectArea.w) and (iy - ys + py < RectArea.y + RectArea.h) then
              begin
                if image = nil then
                  putpixel(screen, w - xs + px, iy - ys + py, sdl_maprgb(screen.format, ACol[l1 * 3] * (4 + shadow), ACol[l1 * 3 + 1] * (4 + shadow), ACol[l1 * 3 + 2] * (4 + shadow)))
                else
                  Pint(image + ((w - xs + px) * 1152 + (iy - ys + py)) * 4)^ := sdl_maprgb(screen.format, ACol[l1 * 3] * (4 + shadow), ACol[l1 * 3 + 1] * (4 + shadow), ACol[l1 * 3 + 2] * (4 + shadow));
              end;
              w := w + 1;
              if p = 2 then
              begin
                p := 0;
              end;
            end;
      end;
    end;
  end;
end;

//获取游戏中坐标在屏幕上的位置

function GetPositionOnScreen(x, y, CenterX, CenterY: integer): TPosition;
begin
  result.x := -(x - CenterX) * 18 + (y - CenterY) * 18 + CENTER_X;
  result.y := (x - CenterX) * 9 + (y - CenterY) * 9 + CENTER_Y;
end;

//显示title.grp的内容(即开始的选单)

procedure DrawTitlePic(imgnum, px, py: integer);
var
  len, grp, idx: integer;
  Area: TRect;
  BufferIdx: array[0..100] of integer;
  BufferPic: array[0..20000] of Byte;
begin
  grp := fileopen('resource\title.grp', fmopenread);
  idx := fileopen('resource\title.idx', fmopenread);

  len := fileseek(idx, 0, 2);
  fileseek(idx, 0, 0);
  fileread(idx, BufferIdx[0], len);
  len := fileseek(grp, 0, 2);
  fileseek(grp, 0, 0);
  fileread(grp, BufferPic[0], len);

  fileclose(grp);
  fileclose(idx);

  Area.x := 0;
  Area.y := 0;
  Area.w := screen.w;
  Area.h := screen.h;
  DrawRLE8Pic(imgnum, px, py, @BufferIdx[0], @BufferPic[0], Area, nil, 0);

end;

//显示场景图片

procedure DrawSPic(num, px, py, x, y, w, h: integer);
var
  Area: TRect;
begin
  Area.x := x;
  Area.y := y;
  Area.w := w;
  Area.h := h;
  DrawRLE8Pic(num, px, py, @SIdx[0], @SPic[0], Area, nil, 0);

end;

//将场景图片信息写入映像

procedure InitialSPic(num, px, py, x, y, w, h: integer);
var
  Area: TRect;
begin
  if x + w > 2303 then w := 2303 - x;
  if y + h > 2303 then h := 2303 - y;
  Area.x := x;
  Area.y := y;
  Area.w := w;
  Area.h := h;
  DrawRLE8Pic(num, px, py, @SIdx[0], @SPic[0], Area, @ScenceImg[0], 0);

end;

//判断像素是否在屏幕内

function JudgeInScreen(px, py, w, h, xs, ys: integer): boolean; overload;
begin
  result := false;
  if (px - xs + w >= 0) and (px - xs < screen.w)
    and (py - ys + h >= 0) and (py - ys < screen.h) then
    Result := true;

end;

//判断像素是否在指定范围内(重载)

function JudgeInScreen(px, py, w, h, xs, ys, xx, yy, xw, yh: integer): boolean; overload;
begin
  result := false;
  if (px - xs + w >= xx) and (px - xs < xx + xw)
    and (py - ys + h >= yy) and (py - ys < yy + yh) then
    Result := true;

end;

//显示主地图贴图

procedure DrawMPic(num, px, py: integer);
var
  Area: Trect;
begin
  Area.x := 0;
  Area.y := 0;
  Area.w := screen.w;
  Area.h := screen.h;
  DrawRLE8Pic(num, px, py, @Midx[0], @Mpic[0], Area, nil, 0);

end;

//显示头像, 优先考虑'.head\'目录下的png图片

procedure DrawHeadPic(num, px, py: integer);
var
  len, grp, idx: integer;
  Area: TRect;
  str: string;
begin
  str := 'head\' + inttostr(num) + '.png';
  if fileexists(str) then display_img(@str[1], px, py - 60)
  else begin
    Area.x := 0;
    Area.y := 0;
    Area.w := screen.w;
    Area.h := screen.h;
    DrawRLE8Pic(num, px, py, @HIdx[0], @HPic[0], Area, nil, 0);
  end;

end;

//显示战场图片

procedure DrawBPic(num, px, py, shadow: integer);
var
  Area: TRect;
begin
  Area.x := 0;
  Area.y := 0;
  Area.w := screen.w;
  Area.h := screen.h;
  DrawRLE8Pic(num, px, py, @WIdx[0], @WPic[0], Area, nil, shadow);

end;

//仅在某区域显示战场图片

procedure DrawBPicInRect(num, px, py, shadow, x, y, w, h: integer);
var
  Area: TRect;
begin
  Area.x := x;
  Area.y := y;
  Area.w := w;
  Area.h := h;
  DrawRLE8Pic(num, px, py, @WIdx[0], @WPic[0], Area, nil, shadow);

end;

//将战场图片画到映像

procedure InitialBPic(num, px, py: integer);
var
  Area: TRect;
begin
  Area.x := 0;
  Area.y := 0;
  Area.w := 2304;
  Area.h := 1152;
  DrawRLE8Pic(num, px, py, @WIdx[0], @WPic[0], Area, @BFieldImg[0], 0);

end;

//显示效果图片

procedure DrawEPic(num, px, py: integer);
var
  Area: TRect;
begin
  Area.x := 0;
  Area.y := 0;
  Area.w := screen.w;
  Area.h := screen.h;
  DrawRLE8Pic(num, px, py, @EIdx[0], @EPic[0], Area, nil, 0);

end;

//显示人物动作图片

procedure DrawFPic(num, px, py: integer);
var
  Area: TRect;
begin
  Area.x := 0;
  Area.y := 0;
  Area.w := screen.w;
  Area.h := screen.h;
  DrawRLE8Pic(num, px, py, @FIdx[0], @FPic[0], Area, nil, 0);

end;

//显示unicode中文文字

procedure DrawText(sur: PSDL_Surface; word: PUint16; x_pos, y_pos: integer; color: Uint32);
var
  dest: TSDL_Rect;
  len, i: integer;
  pword: array[0..2] of Uint16;
begin
  //len := length(word);
  pword[0] := 32;
  pword[2] := 0;

  dest.x := x_pos;
  while word^ > 0 do
  begin
    pword[1] := word^;
    inc(word);
    if pword[1] > 128 then
    begin
      text := TTF_RenderUNICODE_blended(font, @pword[0], TSDL_Color(Color));
      //dest.x := x_pos;
      dest.x := x_pos - 10;
      dest.y := y_pos;
      SDL_BlitSurface(text, nil, sur, @dest);
      x_pos := x_pos + 20;
    end
    else begin
      //if pword[1] <> 20 then
      begin
        text := TTF_RenderUNICODE_blended(engfont, @pword[1], TSDL_Color(Color));
        //showmessage(inttostr(pword[1]));
        dest.x := x_pos + 10;
        dest.y := y_pos + 4;
        SDL_BlitSurface(text, nil, sur, @dest);
      end;
      x_pos := x_pos + 10;
    end;
    SDL_FreeSurface(text);
  end;

end;

//显示英文

procedure DrawEngText(sur: PSDL_Surface; word: PUint16; x_pos, y_pos: integer; color: Uint32);
var
  dest: TSDL_Rect;
begin
  text := TTF_RenderUNICODE_blended(engfont, word, TSDL_Color(Color));
  dest.x := x_pos;
  dest.y := y_pos + 4;
  SDL_BlitSurface(text, nil, sur, @dest);
  SDL_FreeSurface(text);

end;

//显示unicode中文阴影文字, 即将同样内容显示2次, 间隔1像素

procedure DrawShadowText(word: PUint16; x_pos, y_pos: integer; color1, color2: Uint32);
begin
  DrawText(screen, word, x_pos + 1, y_pos, color2);
  DrawText(screen, word, x_pos, y_pos, color1);

end;

//显示英文阴影文字

procedure DrawEngShadowText(word: PUint16; x_pos, y_pos: integer; color1, color2: Uint32);
begin
  DrawEngText(screen, word, x_pos + 1, y_pos, color2);
  DrawEngText(screen, word, x_pos, y_pos, color1);

end;

//显示big5文字

procedure DrawBig5Text(sur: PSDL_Surface; str: PChar; x_pos, y_pos: integer; color: Uint32);
var
  len: integer;
  words: widestring;
begin
  len := MultiByteToWideChar(950, 0, PChar(str), -1, nil, 0);
  setlength(words, len - 1);
  MultiByteToWideChar(950, 0, PChar(str), length(str), pwidechar(words), len + 1);
  words := ' ' + words;
  drawtext(screen, @words[1], x_pos, y_pos, color);

end;

//unicode转为big5, 仅用于输入姓名

function UnicodeToBig5(str: PWideChar): string;
var
  len: integer;
begin
  len := WideCharToMultiByte(950, 0, PWideChar(str), -1, nil, 0, nil, nil);
  setlength(result, len + 1);
  WideCharToMultiByte(950, 0, PWideChar(str), -1, pchar(result), len + 1, nil, nil);

end;

//big5转为unicode

function Big5ToUnicode(str: PChar): widestring;
var
  len: integer;
begin
  len := MultiByteToWideChar(950, 0, PChar(str), -1, nil, 0);
  setlength(result, len - 1);
  MultiByteToWideChar(950, 0, PChar(str), length(str), pwidechar(result), len + 1);
  result := ' ' + result;

end;

//显示big5阴影文字

procedure DrawBig5ShadowText(word: pchar; x_pos, y_pos: integer; color1, color2: Uint32);
var
  len: integer;
  words: widestring;
begin
  len := MultiByteToWideChar(950, 0, PChar(word), -1, nil, 0);
  setlength(words, len - 1);
  MultiByteToWideChar(950, 0, PChar(word), length(word), pwidechar(words), len + 1);
  words := ' ' + words;
  DrawText(screen, @words[1], x_pos + 1, y_pos, color2);
  DrawText(screen, @words[1], x_pos, y_pos, color1);

end;

//显示带边框的文字, 仅用于unicode, 需自定义宽度

procedure DrawTextWithRect(word: puint16; x, y, w: integer; color1, color2: uint32);
var
  len: integer;
  p: pchar;
begin
  DrawRectangle(x, y, w, 28, 0, colcolor(255), 30);
  DrawShadowText(word, x - 17, y + 2, color1, color2);
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);

end;

//显示主地图场景于屏幕

procedure DrawMMap;
var
  i1, i2, i, sum, x, y: integer;
  temp: array[0..479, 0..479] of smallint;
  pos: TPosition;
begin
  if (SDL_MustLock(screen)) then
  begin
    if (SDL_LockSurface(screen) < 0) then
    begin
      MessageBox(0, PChar(Format('Can''t lock screen : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
  end;

  //由上到下绘制, 先绘制中心点靠上的建筑
  for sum := -29 to 40 do
    for i := -15 to 15 do
    begin
      i1 := Mx + i + (sum div 2);
      i2 := My - i + (sum - sum div 2);
      Pos := GetPositionOnScreen(i1, i2, Mx, My);
      if (i1 >= 0) and (i1 < 480) and (i2 >= 0) and (i2 < 480) then
      begin
        if (sum >= -27) and (sum <= 28) and (i >= -9) and (i <= 9) then
        begin
          DrawMPic(earth[i1, i2] div 2, pos.x, pos.y);
          if surface[i1, i2] > 0 then
            DrawMPic(surface[i1, i2] div 2, pos.x, pos.y);
        end;
        temp[i1, i2] := building[i1, i2];
      end else
        DrawMPic(0, pos.x, pos.y);

    end;
  for sum := -29 to 40 do
    for i := -15 to 15 do
    begin
      i1 := Mx + i + (sum div 2);
      i2 := My - i + (sum - sum div 2);
      if (i1 >= 0) and (i1 < 480) and (i2 >= 0) and (i2 < 480) then
      begin
        x := buildy[i1, i2];
        y := buildx[i1, i2];
        Pos := GetPositionOnScreen(x, y, Mx, My);
        if (buildx[i1, i2] > 0) and (((buildx[i1 - 1, i2 - 1] <> buildx[i1, i2]) and (buildx[i1 + 1, i2 + 1] <> buildx[i1, i2]))
          or ((buildy[i1 - 1, i2 - 1] <> buildy[i1, i2]) and (buildy[i1 + 1, i2 + 1] <> buildy[i1, i2]))) then
        begin

          if temp[x, y] > 0 then
          begin
            DrawMPic(building[x, y] div 2, pos.x, pos.y);
            temp[x, y] := 0;
          end;
        end;

        //如在水面上则绘制船的贴图
        if (i1 = Mx) and (i2 = My) then
          if (InShip = 0) then
            if still = 0 then
              DrawMPic(2500 + MFace * 7 + MStep, CENTER_X, CENTER_Y)
            else
              DrawMPic(2528 + Mface * 6 + MStep, CENTER_X, CENTER_Y)
          else
            DrawMPic(3714 + MFace * 4 + (MStep + 1) div 2, CENTER_X, CENTER_Y);
        if (temp[i1, i2] > 0) and (buildx[i1, i2] = i2) then
        begin
          DrawMPic(building[i1, i2] div 2, pos.x, pos.y);
          temp[i1, i2] := 0;
        end;
      end;

    end;

  if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;
  //SDL_UpdateRect(screen, 0,0,screen.w,screen.h);

end;

//判定主地图某个位置能否行走, 是否变成船

function CanWalk(x, y: integer): boolean;
begin
  if buildx[x, y] = 0 then
    canwalk := true
  else
    canwalk := false;
  //canwalk:=true;  //This sentence is used to test.
  if (x <= 0) or (x >= 479) or (y <= 0) or (y >= 479) then
    canwalk := false;
  if (earth[x, y] = 838) or ((earth[x, y] >= 612) and (earth[x, y] <= 670)) then canwalk := false;
  if ((earth[x, y] >= 358) and (earth[x, y] <= 362))
    or ((earth[x, y] >= 506) and (earth[x, y] <= 670))
    or ((earth[x, y] >= 1016) and (earth[x, y] <= 1022)) then
    InShip := 1
  else
    InShip := 0;
  //canwalk:=true;
end;

//判定场景内某个位置能否行走

function CanWalkInScence(x, y: integer): boolean;
begin
  if (SData[CurScence, 1, x, y] = 0) then
    result := true
  else
    result := false;
  if (SData[CurScence, 3, x, y] >= 0) and (result) and (DData[CurScence, SData[CurScence, 3, x, y], 0] = 1) then
    result := false;
  //直接判定贴图范围
  if ((SData[CurScence, 0, x, y] >= 358) and (SData[CurScence, 0, x, y] <= 362))
    or (SData[CurScence, 0, x, y] = 522) or (SData[CurScence, 0, x, y] = 1022)
    or ((SData[CurScence, 0, x, y] >= 1324) and (SData[CurScence, 0, x, y] <= 1330))
    or (SData[CurScence, 0, x, y] = 1348) then
    result := false;
  //if SData[CurScence, 0, x, y] = 1358 * 2 then result := true;

end;

//将场景映像画到屏幕

procedure LoadScencePart(x, y: integer);
var
  i1, i2: integer;
begin
  for i1 := 0 to screen.w - 1 do
    for i2 := 0 to screen.h - 1 do
      if (x + i1 >= 0) and (y + i2 >= 0) and (x + i1 < 2304) and (y + i2 < 1152) then
        putpixel(screen, i1, i2, scenceimg[x + i1, y + i2])
      else
        putpixel(screen, i1, i2, 0);

end;

//将战场映像画到屏幕

procedure LoadBFieldPart(x, y: integer);
var
  i1, i2: integer;
begin
  for i1 := 0 to screen.w - 1 do
    for i2 := 0 to screen.h - 1 do
      if (x + i1 >= 0) and (y + i2 >= 0) and (x + i1 < 2304) and (y + i2 < 1152) then
        putpixel(screen, i1, i2, Bfieldimg[x + i1, y + i2])
      else
        putpixel(screen, i1, i2, 0);

end;

//画场景到屏幕

procedure DrawScence;
var
  i1, i2, x, y, xpoint, ypoint: integer;
begin
  if (SDL_MustLock(screen)) then
  begin
    if (SDL_LockSurface(screen) < 0) then
    begin
      MessageBox(0, PChar(Format('Can''t lock screen : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
  end;

  //先画无主角的场景, 再画主角
  //如在事件中, 则以Cx, Cy为中心, 否则以主角坐标为中心
  if (CurEvent < 0) then
  begin
    DrawScenceWithoutRole(Sx, Sy);
    DrawRoleOnScence(Sx, Sy);
  end else
  begin
    DrawScenceWithoutRole(Cx, Cy);
    if (DData[CurScence, CurEvent, 10] = Sx) and (DData[CurScence, CurEvent, 9] = Sy) then
    begin
      if DData[CurScence, CurEvent, 5] <= 0 then
      begin
        DrawRoleOnScence(Cx, Cy);
      end;
    end else
      DrawRoleOnScence(Cx, Cy);
  end;

  if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;
  //SDL_UpdateRect(screen, 0,0,screen.w,screen.h);

end;

//画不含主角的场景(与DrawScenceByCenter相同)

procedure DrawScenceWithoutRole(x, y: integer);
var
  i1, i2, xpoint, ypoint: integer;
begin
  if (SDL_MustLock(screen)) then
  begin
    if (SDL_LockSurface(screen) < 0) then
    begin
      MessageBox(0, PChar(Format('Can''t lock screen : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
  end;

  loadScencePart(-x * 18 + y * 18 + 1151 - CENTER_X, x * 9 + y * 9 + 9 - CENTER_Y);

  if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;
  //SDL_UpdateRect(screen, 0,0,screen.w,screen.h);

end;

//画不含主角的战场

procedure DrawBFieldWithoutRole(x, y: integer);
var
  i1, i2, xpoint, ypoint: integer;
begin
  if (SDL_MustLock(screen)) then
  begin
    if (SDL_LockSurface(screen) < 0) then
    begin
      MessageBox(0, PChar(Format('Can''t lock screen : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
  end;

  loadBfieldPart(-x * 18 + y * 18 + 1151 - CENTER_X, x * 9 + y * 9 + 9 - CENTER_Y);

  if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;
  //SDL_UpdateRect(screen, 0,0,screen.w,screen.h);

end;

//画主角于场景

procedure DrawRoleOnScence(x, y: integer);
var
  i1, i2, xpoint, ypoint: integer;
  pos, pos1: TPosition;
begin
  if (SDL_MustLock(screen)) then
  begin
    if (SDL_LockSurface(screen) < 0) then
    begin
      MessageBox(0, PChar(Format('Can''t lock screen : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
  end;
  pos := getpositiononscreen(Sx, Sy, x, y);
  DrawSPic(2500 + SFace * 7 + SStep, pos.x, pos.y - SData[CurScence, 4, Sx, Sy], pos.x - 20, pos.y - 60 - SData[CurScence, 4, Sx, Sy], 40, 60);
  //重画主角附近的部分, 考虑遮挡
  for i1 := Sx - 1 to Sx + 10 do
    for i2 := Sy - 1 to Sy + 10 do
    begin
      pos1 := getpositiononscreen(i1, i2, x, y);
      if (i1 > Sx) and (i2 > Sy) then
        DrawSPic(SData[CurScence, 0, i1, i2] div 2, pos1.x, pos1.y, pos.x - 20, pos.y - 60 - SData[CurScence, 4, Sx, Sy], 40, 60);
      if (SData[CurScence, 1, i1, i2] > 0) and ((i2 > Sy) or (i1 > Sx)) then
        DrawSPic(SData[CurScence, 1, i1, i2] div 2, pos1.x, pos1.y - SData[CurScence, 4, i1, i2], pos.x - 20, pos.y - 60 - SData[CurScence, 4, Sx, Sy], 40, 60);
      if (SData[CurScence, 2, i1, i2] > 0) and ((i2 > Sy) or (i1 > Sx)) then
        DrawSPic(SData[CurScence, 2, i1, i2] div 2, pos1.x, pos1.y - SData[CurScence, 5, i1, i2], pos.x - 20, pos.y - 60 - SData[CurScence, 4, Sx, Sy], 40, 60);
      if (SData[CurScence, 3, i1, i2] >= 0) and ((i2 > Sy) or (i1 > Sx)) and (DData[CurScence, SData[CurScence, 3, i1, i2], 5] > 0) then
        DrawSPic(DData[CurScence, SData[CurScence, 3, i1, i2], 5] div 2, pos1.x, pos1.y - SData[CurScence, 4, i1, i2], pos.x - 20, pos.y - 60 - SData[CurScence, 4, Sx, Sy], 40, 60);
    end;

  if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;

end;

//画带边框矩形, (x坐标, y坐标, 宽, 高, 内部颜色, 边框颜色, 透明度)

procedure DrawRectangle(x, y, w, h: integer; colorin, colorframe: Uint32; alphe: integer);
var
  i1, i2, l1, l2, l3, l4: integer;
  pix, pix1, pix2, pix3, pix4, color1, color2, color3, color4: Uint32;
begin
  if (SDL_MustLock(screen)) then
  begin
    SDL_LockSurface(screen);
  end;
  for i1 := x to x + w do
    for i2 := y to y + h do
    begin
      l1 := (i1 - x) + (i2 - y);
      l2 := -(i1 - x - w) + (i2 - y);
      l3 := (i1 - x) - (i2 - y - h);
      l4 := -(i1 - x - w) - (i2 - y - h);
      if (l1 >= 4) and (l2 >= 4) and (l3 >= 4) and (l4 >= 4) then
      begin
        pix := getpixel(screen, i1, i2);
        pix1 := pix and $FF; color1 := colorin and $FF;
        pix2 := pix shr 8 and $FF; color2 := colorin shr 8 and $FF;
        pix3 := pix shr 16 and $FF; color3 := colorin shr 16 and $FF;
        pix4 := pix shr 24 and $FF; color4 := colorin shr 24 and $FF;
        pix1 := (alphe * color1 + (100 - alphe) * pix1) div 100;
        pix2 := (alphe * color2 + (100 - alphe) * pix2) div 100;
        pix3 := (alphe * color3 + (100 - alphe) * pix3) div 100;
        pix4 := (alphe * color4 + (100 - alphe) * pix4) div 100;
        pix := pix1 + pix2 shl 8 + pix3 shl 16 + pix4 shl 24;
        putpixel(screen, i1, i2, pix);
      end;
      if (((l1 >= 4) and (l2 >= 4) and (l3 >= 4) and (l4 >= 4) and ((i1 = x) or (i1 = x + w) or (i2 = y) or (i2 = y + h)))
        or ((l1 = 4) or (l2 = 4) or (l3 = 4) or (l4 = 4))) then
      begin
        putpixel(screen, i1, i2, colorframe);
      end;
    end;
  if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;

end;

//画不含边框的矩形, 用于对话和黑屏

procedure DrawRectangleWithoutFrame(x, y, w, h: integer; colorin: Uint32; alphe: integer);
var
  i1, i2: integer;
  pix, pix1, pix2, pix3, pix4, color1, color2, color3, color4: Uint32;
begin
  if (SDL_MustLock(screen)) then
  begin
    SDL_LockSurface(screen);
  end;
  for i1 := x to x + w do
    for i2 := y to y + h do
    begin
      pix := getpixel(screen, i1, i2);
      pix1 := pix and $FF; color1 := colorin and $FF;
      pix2 := pix shr 8 and $FF; color2 := colorin shr 8 and $FF;
      pix3 := pix shr 16 and $FF; color3 := colorin shr 16 and $FF;
      pix4 := pix shr 24 and $FF; color4 := colorin shr 24 and $FF;
      pix1 := (alphe * color1 + (100 - alphe) * pix1) div 100;
      pix2 := (alphe * color2 + (100 - alphe) * pix2) div 100;
      pix3 := (alphe * color3 + (100 - alphe) * pix3) div 100;
      pix4 := (alphe * color4 + (100 - alphe) * pix4) div 100;
      pix := pix1 + pix2 shl 8 + pix3 shl 16 + pix4 shl 24;
      putpixel(screen, i1, i2, pix);
    end;
  if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;

end;

//重画屏幕, sdl_updaterect(screen,0,0,screen.w,screen.h)可显示

procedure Redraw;
begin
  case where of
    0: DrawMMap;
    1: DrawScence;
    2: DrawWholeBField;
    3: display_img('resource\open.png', 0, 0);
  end;

end;

//Save the image informations of the whole scence.
//生成场景映像

procedure InitialScence();
var
  i1, i2, x, y: integer;
  pos: TPosition;
begin
  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      x := -i1 * 18 + i2 * 18 + 1151;
      y := i1 * 9 + i2 * 9 + 9;
      InitialSPic(SData[CurScence, 0, i1, i2] div 2, x, y, 0, 0, 2304, 1152);
      if (SData[CurScence, 1, i1, i2] > 0) then
        InitialSPic(SData[CurScence, 1, i1, i2] div 2, x, y - SData[CurScence, 4, i1, i2], 0, 0, 2304, 1152);
      if (SData[CurScence, 2, i1, i2] > 0) then
        InitialSPic(SData[CurScence, 2, i1, i2] div 2, x, y - SData[CurScence, 5, i1, i2], 0, 0, 2304, 1152);
      if (SData[CurScence, 3, i1, i2] >= 0) and (DData[CurScence, SData[CurScence, 3, i1, i2], 5] > 0) then
        InitialSPic(DData[CurScence, SData[CurScence, 3, i1, i2], 5] div 2, x, y - SData[CurScence, 4, i1, i2], 0, 0, 2304, 1152);
    end;

end;

//更改场景映像, 用于动画, 场景内动态效果

procedure UpdateScence(xs, ys: integer);
var
  i1, i2, x, y: integer;
  num, offset: integer;
  xp, yp, w, h: smallint;
begin
  xp := -xs * 18 + ys * 18 + 1151;
  yp := xs * 9 + ys * 9;
  //如在事件中, 直接给定更新范围
  if CurEvent < 0 then
  begin
    num := DData[CurScence, SData[CurScence, 3, xs, ys], 5] div 2;
    if num > 0 then offset := SIdx[num - 1];
    xp := xp - (SPic[offset + 4] + 256 * SPic[offset + 5]) - 3;
    yp := yp - (SPic[offset + 6] + 256 * SPic[offset + 7]) - 3 - SData[CurScence, 4, xs, ys];
    w := (SPic[offset] + 256 * SPic[offset + 1]) + 20;
    h := (SPic[offset + 2] + 256 * SPic[offset + 3]) + 6;
  end;
  if (CurEvent >= 0) or (num <= 0) then
  begin
    xp := xp - 30;
    yp := yp - 120;
    w := 100;
    h := 130;
  end;
  //计算贴图高度和宽度, 作为更新范围
  offset := max(h div 18, w div 36);
  for i1 := xs - offset to xs + 5 do
    for i2 := ys - offset to ys + 5 do
    begin
      x := -i1 * 18 + i2 * 18 + 1151;
      y := i1 * 9 + i2 * 9 + 9;
      InitialSPic(SData[CurScence, 0, i1, i2] div 2, x, y, xp, yp, w, h);
      if (i1 < 0) or (i2 < 0) or (i1 > 63) or (i2 > 63) then InitialSPic(0, x, y, xp, yp, w, h)
      else begin
        //InitialSPic(SData[CurScence, 0, i1,i2] div 2,x,y,xp,yp,w,h);
        if (SData[CurScence, 1, i1, i2] > 0) then
          InitialSPic(SData[CurScence, 1, i1, i2] div 2, x, y - SData[CurScence, 4, i1, i2], xp, yp, w, h);
        //if (i1=Sx) and (i2=Sy) then
          //InitialSPic(BEGIN_WALKPIC+SFace*7+SStep,x,y-SData[CurScence, 4, i1,i2],0,0,2304,1152);
        if (SData[CurScence, 2, i1, i2] > 0) then
          InitialSPic(SData[CurScence, 2, i1, i2] div 2, x, y - SData[CurScence, 5, i1, i2], xp, yp, w, h);
        if (SData[CurScence, 3, i1, i2] >= 0) and (DData[CurScence, SData[CurScence, 3, i1, i2], 5] > 0) then
          InitialSPic(DData[CurScence, SData[CurScence, 3, i1, i2], 5] div 2, x, y - SData[CurScence, 4, i1, i2], xp, yp, w, h);
        //if (i1=RScence[CurScence*26+15]) and (i2=RScence[CurScence*26+14]) then
          //DrawSPic(0,-(i1-Sx)*18+(i2-Sy)*18+CENTER_X,(i1-Sx)*9+(i2-Sy)*9+CENTER_Y);
        //if (i1=Sx) and (i2=Sy) then DrawSPic(2500+SFace*7+SStep,CENTER_X,CENTER_Y-SData[CurScence, 4, i1,i2]);
      end;
    end;

end;

//读取必须的文件

procedure ReadFiles;
var
  grp, idx, tnum, len, col, i: integer;
  filename: string;
  Kys_ini: TIniFile;

begin
  Filename := ExtractFilePath(Paramstr(0)) + 'kysmod.ini';
  Kys_ini := TIniFile.Create(filename);

  try
    ITEM_BEGIN_PIC := Kys_ini.ReadInteger('constant', 'ITEM_BEGIN_PIC', 3501);
    MAX_HEAD_NUM := Kys_ini.ReadInteger('constant', 'MAX_HEAD_NUM', 189);
    BEGIN_EVENT := Kys_ini.ReadInteger('constant', 'BEGIN_EVENT', 691);
    BEGIN_SCENCE := Kys_ini.ReadInteger('constant', 'BEGIN_SCENCE', 70);
    BEGIN_Sx := Kys_ini.ReadInteger('constant', 'BEGIN_Sx', 20);
    BEGIN_Sy := Kys_ini.ReadInteger('constant', 'BEGIN_Sy', 19);
    SOFTSTAR_BEGIN_TALK := Kys_ini.ReadInteger('constant', 'SOFTSTAR_BEGIN_TALK', 2547);
    SOFTSTAR_NUM_TALK := Kys_ini.ReadInteger('constant', 'SOFTSTAR_NUM_TALK', 18);
    MAX_PHYSICAL_POWER := Kys_ini.ReadInteger('constant', 'MAX_PHYSICAL_POWER', 100);
    BEGIN_WALKPIC := Kys_ini.ReadInteger('constant', 'BEGIN_WALKPIC', 2500);
    MONEY_ID := Kys_ini.ReadInteger('constant', 'MONEY_ID', 174);
    COMPASS_ID := Kys_ini.ReadInteger('constant', 'COMPASS_ID', 182);
    BEGIN_LEAVE_EVENT := Kys_ini.ReadInteger('constant', 'BEGIN_LEAVE_EVENT', 950);
    BEGIN_BATTLE_ROLE_PIC := Kys_ini.ReadInteger('constant', 'BEGIN_BATTLE_ROLE_PIC', 2553);
    MAX_LEVEL := Kys_ini.ReadInteger('constant', 'MAX_LEVEL', 30);
    MAX_WEAPON_MATCH := Kys_ini.ReadInteger('constant', 'MAX_WEAPON_MATCH', 7);
    MIN_KNOWLEDGE := Kys_ini.ReadInteger('constant', 'MIN_KNOWLEDGE', 80);
    MAX_HP := Kys_ini.ReadInteger('constant', 'MAX_HP', 999);
    MAX_MP := Kys_ini.ReadInteger('constant', 'MAX_MP', 999);
    LIFE_HURT := Kys_ini.ReadInteger('constant', 'LIFE_HURT', 10);
    NOVEL_BOOK := Kys_ini.ReadInteger('constant', 'NOVEL_BOOK', 144);

    for i := 43 to 58 do
    begin
      MaxProList[i] := Kys_ini.ReadInteger('constant', 'MaxProList' + inttostr(i), 100);
    end;

  finally
    Kys_ini.Free;
  end;
  //showmessage(booltostr(fileexists(filename)));
  //showmessage(inttostr(max_level));

  col := fileopen('resource\mmap.col', fmopenread);
  fileread(col, ACol[0], 768);
  fileclose(col);

  idx := fileopen('resource\mmap.idx', fmopenread);
  grp := fileopen('resource\mmap.grp', fmopenread);
  len := fileseek(grp, 0, 2);
  fileseek(grp, 0, 0);
  fileread(grp, MPic[0], len);
  tnum := fileseek(idx, 0, 2) div 4;
  fileseek(idx, 0, 0);
  fileread(idx, MIdx[0], tnum * 4);
  fileclose(grp);
  fileclose(idx);

  idx := fileopen('resource\sdx', fmopenread);
  grp := fileopen('resource\smp', fmopenread);
  len := fileseek(grp, 0, 2);
  fileseek(grp, 0, 0);
  fileread(grp, SPic[0], len);
  tnum := fileseek(idx, 0, 2) div 4;
  fileseek(idx, 0, 0);
  fileread(idx, SIdx[0], tnum * 4);
  fileclose(grp);
  fileclose(idx);

  idx := fileopen('resource\wdx', fmopenread);
  grp := fileopen('resource\wmp', fmopenread);
  len := fileseek(grp, 0, 2);
  fileseek(grp, 0, 0);
  fileread(grp, WPic[0], len);
  tnum := fileseek(idx, 0, 2) div 4;
  fileseek(idx, 0, 0);
  fileread(idx, WIdx[0], tnum * 4);
  fileclose(grp);
  fileclose(idx);

  idx := fileopen('resource\eft.idx', fmopenread);
  grp := fileopen('resource\eft.grp', fmopenread);
  len := fileseek(grp, 0, 2);
  fileseek(grp, 0, 0);
  fileread(grp, EPic[0], len);
  tnum := fileseek(idx, 0, 2) div 4;
  fileseek(idx, 0, 0);
  fileread(idx, EIdx[0], tnum * 4);
  fileclose(grp);
  fileclose(idx);

  idx := fileopen('resource\hdgrp.idx', fmopenread);
  grp := fileopen('resource\hdgrp.grp', fmopenread);
  len := fileseek(grp, 0, 2);
  fileseek(grp, 0, 0);
  fileread(grp, HPic[0], len);
  tnum := fileseek(idx, 0, 2) div 4;
  fileseek(idx, 0, 0);
  fileread(idx, HIdx[0], tnum * 4);
  fileclose(grp);
  fileclose(idx);


  col := fileopen('resource\earth.002', fmopenread);
  fileread(col, Earth[0, 0], 480 * 480 * 2);
  fileclose(col);
  col := fileopen('resource\surface.002', fmopenread);
  fileread(col, surface[0, 0], 480 * 480 * 2);
  fileclose(col);
  col := fileopen('resource\building.002', fmopenread);
  fileread(col, Building[0, 0], 480 * 480 * 2);
  fileclose(col);
  col := fileopen('resource\buildx.002', fmopenread);
  fileread(col, Buildx[0, 0], 480 * 480 * 2);
  fileclose(col);
  col := fileopen('resource\buildy.002', fmopenread);
  fileread(col, Buildy[0, 0], 480 * 480 * 2);
  fileclose(col);
  col := fileopen('list\leave.bin', fmopenread);
  fileread(col, leavelist[0], 200);
  fileclose(col);
  col := fileopen('list\effect.bin', fmopenread);
  fileread(col, effectlist[0], 200);
  fileclose(col);
  col := fileopen('list\levelup.bin', fmopenread);
  fileread(col, leveluplist[0], 200);
  fileclose(col);
  col := fileopen('list\match.bin', fmopenread);
  fileread(col, matchlist[0], MAX_WEAPON_MATCH * 3 * 2);
  fileclose(col);

end;

//Main game.
//显示开头画面

procedure Start;
var
  menu, menup, i, col, i1, i2, x, y: integer;
begin
  ReadFiles;

  for i1 := 0 to 479 do
    for i2 := 0 to 479 do
      Entrance[i1, i2] := -1;

  display_img('resource\open.png', 0, 0);

  SDL_EnableKeyRepeat(0, 10);
  MStep := 1;

  fullscreen := 0;

  where := 3;
  menu := 0;
  Setlength(RItemlist, MAX_ITEM_AMOUNT);
  for i := 0 to MAX_ITEM_AMOUNT - 1 do
  begin
    RItemlist[i].Number := -1;
    RItemlist[i].Amount := 0;
  end;

  x := 275;
  y := 250;
  //drawrectanglewithoutframe(270, 150, 100, 70, 0, 20);
  drawtitlepic(0, x, y);
  drawtitlepic(menu + 1, x, y + menu * 20);
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);
  //PlayMp3(1, -1);

  //事件等待
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    case event.type_ of
      //关闭窗口事件
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOk, mbCancel], 0) = idOK then Quit;
      //键盘事件
      SDL_KEYUP:
        begin
          //如选择第2项, 则退出(所有编号从0开始)
          if ((event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space)) and (menu = 2) then
          begin
            break;
          end;
          //选择第0项, 重新开始游戏
          if ((event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space)) and (menu = 0) then
          begin
            InitialRole;
            CurScence := BEGIN_SCENCE;
            Inscence(1);
            Sdl_UpdateRect(screen, 0, 0, screen.w, screen.h);
            walk;
            menu := 1;
            drawtitlepic(0, x, y);
            drawtitlepic(menu + 1, x, y + menu * 20);
          end;
          //选择第一项, 读入进度
          if ((event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space)) and (menu = 1) then
          begin
            //LoadR(1);
            menuloadAtBeginning;
            redraw;
            Sdl_UpdateRect(screen, 0, 0, screen.w, screen.h);
            CurEvent := -1; //when CurEvent=-1, Draw scence by Sx, Sy. Or by Cx, Cy.
            Walk;
            menu := 1;
            drawtitlepic(0, x, y);
            drawtitlepic(menu + 1, x, y + menu * 20);
            SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
          end;
          //按下方向键上
          if event.key.keysym.sym = sdlk_up then
          begin
            menu := menu - 1;
            if menu < 0 then menu := 2;
            drawtitlepic(0, x, y);
            drawtitlepic(menu + 1, x, y + menu * 20);
            SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
          end;
          //按下方向键下
          if event.key.keysym.sym = sdlk_down then
          begin
            menu := menu + 1;
            if menu > 2 then menu := 0;
            drawtitlepic(0, x, y);
            drawtitlepic(menu + 1, x, y + menu * 20);
            SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
          end;
        end;
      //按下鼠标(UP表示抬起按键才执行)
      SDL_MOUSEBUTTONUP:
        begin
          if (event.button.button = sdl_button_left) then
          begin
            case menu of
              2:
                break;
              1:
                begin
                  menuloadAtBeginning;
                  redraw;
                  Sdl_UpdateRect(screen, 0, 0, screen.w, screen.h);
                  CurEvent := -1; //when CurEvent=-1, Draw scence by Sx, Sy. Or by Cx, Cy.
                  Walk;
                  menu := 1;
                  drawtitlepic(0, x, y);
                  drawtitlepic(menu + 1, x, y + menu * 20);
                  SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
                end;
              0:
                begin
                  InitialRole;
                  CurScence := BEGIN_SCENCE;
                  CurEvent := -1;
                  Inscence(1);
                  Sdl_UpdateRect(screen, 0, 0, screen.w, screen.h);
                  walk;
                  menu := 1;
                  drawtitlepic(0, x, y);
                  drawtitlepic(menu + 1, x, y + menu * 20);
                end;
            end;
          end;
        end;
      //鼠标移动
      SDL_MOUSEMOTION:
        begin
          if (event.button.x > x) and (event.button.x < x + 80) and (event.button.y > y) and (event.button.y < y + 60) then
          begin
            menup := menu;
            menu := (event.button.y - y) div 20;
            if menu <> menup then
            begin
              drawtitlepic(0, x, y);
              drawtitlepic(menu + 1, x, y + menu * 20);
              SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
            end;
          end;
        end;
    end;
  end;

end;

//初始化主角属性

procedure InitialRole;
var
  i: integer;
  p: array[0..14] of integer;
  str, str0, name: widestring;
  str1: string;
  p0, p1: Pchar;
begin
  LoadR(0);
  //显示输入姓名的对话框
  //form1.ShowModal;
  //str := form1.edit1.text;
  str := '請以繁體中文輸入主角之姓名，選定屬性後按Esc              ';
  name := InputBox('Enter name', str, '我是主角');
  str1 := unicodetobig5(@name[1]);
  p0 := @rrole[0].Name;
  p1 := @str1[1];
  for i := 0 to 4 do
    rrole[0].Data[4 + i] := 0;
  for i := 0 to 7 do
  begin
    (p0 + i)^ := (p1 + i)^;
  end;
  redraw;

  str := ' 資質';
  repeat
    Rrole[0].MaxHP := 25 + random(26);
    Rrole[0].CurrentHP := Rrole[0].MaxHP;
    Rrole[0].MaxMP := 25 + random(26);
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
    redraw;
    showstatus(0);
    drawshadowtext(@str[1], 30, CENTER_Y + 111, colcolor($23), colcolor($21));
    str0 := format('%4d', [RRole[0].Aptitude]);
    drawengshadowtext(@str0[1], 150, CENTER_Y + 111, colcolor($66), colcolor($63));
    sdl_updaterect(screen, 0, 0, screen.w, screen.h);
  until waitanykey = sdlk_escape;

  if name = 'TXDX尊使' then
  begin
    Rrole[0].MaxHP := 50;
    Rrole[0].CurrentHP := 50;
    Rrole[0].MaxMP := 50;
    Rrole[0].CurrentMP := 50;
    Rrole[0].MPType := 2;
    Rrole[0].IncLife := 10;

    Rrole[0].Attack := 30;
    Rrole[0].Speed := 30;
    Rrole[0].Defence := 30;
    Rrole[0].Medcine := 30;
    Rrole[0].UsePoi := 30;
    Rrole[0].MedPoi := 30;
    Rrole[0].Fist := 30;
    Rrole[0].Sword := 30;
    Rrole[0].Knife := 30;
    Rrole[0].Unusual := 30;
    Rrole[0].HidWeapon := 30;

    rrole[0].Aptitude := 100;
    rrole[0].Magic[0] := 62;
    rrole[0].MagLevel[0] := 800;

    rmagic[62].Attack[9] := 2000;

    ritem[93].Magic := 26;
    ritem[66].OnlyPracRole := -1;
    ritem[79].OnlyPracRole := -1;

    instruct_32(82, 1);
    instruct_32(74, 1);

  end;

  //redraw;
  showstatus(0);
  drawshadowtext(@str[1], 30, CENTER_Y + 111, colcolor($23), colcolor($21));
  str0 := format('%4d', [RRole[0].Aptitude]);
  drawengshadowtext(@str0[1], 150, CENTER_Y + 111, colcolor($66), colcolor($63));
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);

  StartAmi;
  //EndAmi;

end;

procedure StartAmi;
var
  x, y, i, len: integer;
  str: WideString;
  p: integer;
begin
  instruct_14;
  redraw;
  i := fileopen('list\start.txt', fmOpenRead);
  len := fileseek(i, 0, 2);
  fileseek(i, 0, 0);
  setlength(str, len + 1);
  fileread(i, str[1], len);
  fileclose(i);
  p := 1;
  x := 30;
  y := 80;
  drawrectanglewithoutframe(0, 50, CENTER_X * 2, CENTER_Y * 2 - 100, 0, 60);
  for i := 1 to len + 1 do
  begin
    if str[i] = widechar(10) then str[i] := ' ';
    if str[i] = widechar(13) then
    begin
      str[i] := widechar(0);
      drawshadowtext(@str[p], x, y, colcolor($FF), colcolor($FF));
      p := i + 1;
      y := y + 25;
      sdl_updaterect(screen, 0, 0, screen.w, screen.h);
    end;
    if str[i] = widechar($2A) then
    begin
      str[i] := ' ';
      y := 80;
      redraw;
      waitanykey;
      drawrectanglewithoutframe(0, 50, CENTER_X * 2, CENTER_Y * 2 - 100, 0, 60);
    end;
  end;
  waitanykey;
  instruct_14;
  //instruct_13;

end;

//于主地图行走

procedure Walk;
var
  word: array[0..10] of Uint16;
  x, y, walking, Mx1, My1, Mx2, My2: integer;
  now, next_time: uint32;
begin
  next_time := sdl_getticks;
  Where := 0;
  walking := 0;
  DrawMMap;
  SDL_EnableKeyRepeat(50, 30);
  StopMp3;
  PlayMp3(16, -1);
  still := 0;
  //事件轮询(并非等待)
  while SDL_PollEvent(@event) >= 0 do
  begin
    //如果当前处于标题画面, 则退出, 用于战斗失败
    if where >= 3 then
    begin
      break;
    end;
    //主地图动态效果, 实际仅有主角的动作
    now := sdl_getticks;

    if (integer(now - next_time) > 0) and (Where = 0) then
    begin
      if (Mx2 = Mx) and (My2 = My) then
      begin
        still := 1;
        mstep := mstep + 1;
        if mstep > 6 then mstep := 1;
      end;
      Mx2 := Mx;
      My2 := My;
      if still = 1 then
        next_time := now + 500
      else
        next_time := now + 2000;

      DrawMMap;
      SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
      //else next_time:=next_time
    end;
    //如果主角正在行走, 则依据鼠标位置移动主角, 仅用于使用鼠标行走
    if walking = 1 then
    begin
      still := 0;
      sdl_getmousestate(x, y);
      if (x < CENTER_x) and (y < CENTER_y) then Mface := 2;
      if (x > CENTER_x) and (y < CENTER_y) then Mface := 0;
      if (x < CENTER_x) and (y > CENTER_y) then Mface := 3;
      if (x > CENTER_x) and (y > CENTER_y) then Mface := 1;
      Mx1 := Mx;
      My1 := My;
      case mface of
        0: Mx1 := Mx1 - 1;
        1: My1 := My1 + 1;
        2: My1 := My1 - 1;
        3: Mx1 := Mx1 + 1;
      end;
      Mstep := Mstep + 1;
      if Mstep > 7 then Mstep := 1;
      if canwalk(Mx1, My1) = true then
      begin
        Mx := Mx1;
        My := My1;
      end;
      //每走一步均重画屏幕, 并检测是否处于某场景入口
      DrawMMap;
      //sdl_delay(5);
      SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
      CheckEntrance;
    end;

    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOk, mbCancel], 0) = idOK then Quit;
      //方向键使用压下按键事件
      SDL_KEYDOWN:
        begin
          if (event.key.keysym.sym = sdlk_left) then
          begin
            still := 0;
            MFace := 2;
            MStep := Mstep + 1;
            if MStep > 7 then MStep := 1;
            if canwalk(Mx, My - 1) = true
              then
            begin
              My := My - 1;
            end;
            DrawMMap;
            //sdl_delay(5);
            SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
            CheckEntrance;
          end;
          if (event.key.keysym.sym = sdlk_right) then
          begin
            still := 0;
            MFace := 1;
            MStep := Mstep + 1;
            if MStep > 7 then MStep := 1;
            if canwalk(Mx, My + 1) = true
              then
            begin
              My := My + 1;
            end;
            DrawMMap;
            //sdl_delay(5);
            SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
            CheckEntrance;
          end;
          if (event.key.keysym.sym = sdlk_up) then
          begin
            still := 0;
            MFace := 0;
            MStep := Mstep + 1;
            if MStep > 7 then MStep := 1;
            if canwalk(Mx - 1, My) = true
              then
            begin
              Mx := Mx - 1;
            end;
            DrawMMap;
            //sdl_delay(5);
            SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
            CheckEntrance;
          end;
          if (event.key.keysym.sym = sdlk_down) then
          begin
            still := 0;
            MFace := 3;
            MStep := Mstep + 1;
            if MStep > 7 then MStep := 1;
            if canwalk(Mx + 1, My) = true
              then
            begin
              Mx := Mx + 1;
            end;
            DrawMMap;
            //sdl_delay(5);
            SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
            CheckEntrance;
          end;
        end;
      //功能键(esc)使用松开按键事件
      SDL_KEYUP:
        begin
          if (event.key.keysym.sym = sdlk_escape) then
          begin
            //event.key.keysym.sym:=0;
            MenuEsc;
            walking := 0;
          end;
          if (event.key.keysym.sym = sdlk_return) and (event.key.keysym.modifier = kmod_lalt) then
          begin
            if fullscreen = 1 then
              screen := SDL_SetVideoMode(CENTER_X * 2, CENTER_Y * 2, 32, SDL_HWSURFACE or SDL_DOUBLEBUF or SDL_ANYFORMAT)
            else
              screen := SDL_SetVideoMode(CENTER_X * 2, CENTER_Y * 2, 32, SDL_FULLSCREEN);
            fullscreen := 1 - fullscreen;
          end;
        end;
      //如按下鼠标左键, 设置状态为行走
      Sdl_mousebuttondown:
        begin
          if event.button.button = sdl_button_left then
          begin
            walking := 1;
          end;
        end;
      //如松开鼠标左键, 设置状态为不行走
      //右键则呼出系统选单
      Sdl_mousebuttonup:
        begin
          if event.button.button = sdl_button_right then menuesc;
          if event.button.button = sdl_button_left then
          begin
            walking := 0;
          end;
        end;
    end;
    SDL_Delay(9);
    event.key.keysym.sym := 0;

  end;

  SDL_EnableKeyRepeat(0, 10);

end;

//Check able or not to ertrance a scence.
//检测是否处于某入口, 并是否达成进入条件

procedure CheckEntrance;
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
    if (RScence[snum].EnCondition = 0) then canentrance := true;
    //是否有人轻功超过70
    if (RScence[snum].EnCondition = 2) then
      for i := 0 to 5 do
        if teamlist[i] >= 0 then
          if Rrole[teamlist[i]].Speed > 70 then
            canentrance := true;
    if canentrance = true then
    begin
      instruct_14;
      CurScence := Entrance[x, y];
      SFace := MFace;
      Mface := 3 - Mface;
      SStep := 1;
      Sx := RScence[CurScence].EntranceX;
      Sy := RScence[CurScence].EntranceY;
      //如达成条件, 进入场景并初始化场景坐标
      InScence(0);
      waitanykey;
    end;
    //instruct_13;
  end;

end;

{
procedure UpdateScenceAmi;
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
      LockScence:=true;
      for i:=0 to 199 do
      if DData[CurScence, [i,6]<>DData[CurScence, [i,7] then
      begin
        if (DData[CurScence, [i,5]<5498) or (DData[CurScence, [i,5]>5692) then
        begin
          DData[CurScence, [i,5]:=DData[CurScence, [i,5]+2;
          if DData[CurScence, [i,5]>DData[CurScence, [i,6] then DData[CurScence, [i,5]:=DData[CurScence, [i,7];
          updatescence(DData[CurScence, [i,10],DData[CurScence, [i,9]);
        end;
      end;
      //initialscence;
      sdl_delay(10);
      next_time:=next_time+200;
      LockScence:=false;
    end;
  end;

end;}

//Walk in a scence, the returned value is the scence number when you exit. If it is -1.
//InScence(1) means the new game.
//在内场景行走, 如参数为1表示新游戏

function InScence(open: integer): integer;
var
  grp, idx, offset, just, i1, i2, x, y: integer;
  Sx1, Sy1, s, i, walking, Prescence: integer;
  filename: string;
  scencename: widestring;
  now, next_time: uint32;
  //UpDate: PSDL_Thread;
begin
  //UpDate:=SDL_CreateThread(@UpdateScenceAmi, nil);
  //LockScence:=false;
  next_time := sdl_getticks;
  Where := 1;
  walking := 0;
  just := 0;
  CurEvent := -1;
  SDL_EnableKeyRepeat(50, 30);

  InitialScence;
  if open = 1 then
  begin
    Sx := BEGIN_Sx;
    Sy := BEGIN_Sy;
    Cx := Sx;
    Cy := Sy;
    DrawScence;
    CurEvent := 0;
    SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
    Callevent(BEGIN_EVENT);
    CurEvent := -1;

  end;

  Drawscence;
  ShowScenceName(CurScence);
  //是否有第3类事件位于场景入口
  CheckEvent3;

  while (SDL_PollEvent(@event) >= 0) do
  begin
    if where >= 3 then
    begin
      break;
    end;
    if sx > 63 then sx := 63;
    if sy > 63 then sy := 63;
    if sx < 0 then sx := 0;
    if sy < 0 then sy := 0;
    //场景内动态效果
    now := sdl_getticks;
    //next_time:=sdl_getticks;
    if integer(now - next_time) > 0 then
    begin
      for i := 0 to 199 do
        if (DData[CurScence, i, 8] > 0) or (DData[CurScence, i, 7] < DData[CurScence, i, 6]) then
        begin
          //屏蔽了旗子的动态效果, 因贴图太大不好处理
          if (DData[CurScence, i, 5] < 5498) or (DData[CurScence, i, 5] > 5692) then
          begin
            DData[CurScence, i, 5] := DData[CurScence, i, 5] + 2;
            if DData[CurScence, i, 5] > DData[CurScence, i, 6] then DData[CurScence, i, 5] := DData[CurScence, i, 7];
            updatescence(DData[CurScence, i, 10], DData[CurScence, i, 9]);
          end;
        end;
      next_time := now + 200;
      DrawScence;
      SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
    end;

    //检查是否位于出口, 如是则退出
    if (((sx = RScence[CurScence].ExitX[0]) and (sy = RScence[CurScence].ExitY[0]))
      or ((sx = RScence[CurScence].ExitX[1]) and (sy = RScence[CurScence].ExitY[1]))
      or ((sx = RScence[CurScence].ExitX[2]) and (sy = RScence[CurScence].ExitY[2]))) then
    begin
      Where := 0;
      result := -1;
      break;
    end;
    //检查是否位于跳转口, 如是则重新初始化场景
    if ((sx = RScence[CurScence].JumpX1) and (sy = RScence[CurScence].JumpY1)) and (RScence[CurScence].JumpScence >= 0) then
    begin
      instruct_14;
      PreScence := CurScence;
      CurScence := Rscence[CurScence].JumpScence;
      if RScence[PreScence].MainEntranceX1 <> 0 then
      begin
        Sx := RScence[CurScence].EntranceX;
        Sy := RScence[CurScence].EntranceY;
      end
      else begin
        Sx := RScence[CurScence].JumpX2;
        Sy := RScence[CurScence].JumpY2;
      end;
      {if Sx = 0 then
      begin
        Sx := RScence[CurScence].JumpX2;
        Sy := RScence[CurScence].JumpY2;
      end;
      if Sx = 0 then
      begin
        Sx := RScence[CurScence].EntranceX;
        Sy := RScence[CurScence].EntranceY;
      end;}

      InitialScence;
      Drawscence;
      ShowScenceName(CurScence);
      CheckEvent3;

    end;

    //是否处于行走状态, 参考Walk
    if walking = 1 then
    begin
      sdl_getmousestate(x, y);
      if (x < CENTER_x) and (y < CENTER_y) then Sface := 2;
      if (x > CENTER_x) and (y < CENTER_y) then Sface := 0;
      if (x < CENTER_x) and (y > CENTER_y) then Sface := 3;
      if (x > CENTER_x) and (y > CENTER_y) then Sface := 1;
      Sx1 := Sx;
      Sy1 := Sy;
      case Sface of
        0: Sx1 := Sx1 - 1;
        1: Sy1 := Sy1 + 1;
        2: Sy1 := Sy1 - 1;
        3: Sx1 := Sx1 + 1;
      end;
      Sstep := Sstep + 1;
      if Sstep = 8 then Sstep := 1;
      if canwalkInScence(Sx1, Sy1) = true then
      begin
        Sx := Sx1;
        Sy := Sy1;

      end;
      DrawScence;
      SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
      CheckEvent3;
    end;

    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOk, mbCancel], 0) = idOK then Quit;
      SDL_KEYUP:
        begin
          if (event.key.keysym.sym = sdlk_escape) then
          begin
            MenuEsc;
            walking := 0;
          end;
          //检查是否按下Left Alt+Enter, 是则切换全屏/窗口(似乎并不经常有效)
          if (event.key.keysym.sym = sdlk_return) and (event.key.keysym.modifier = kmod_lalt) then
          begin
            if fullscreen = 1 then
              screen := SDL_SetVideoMode(CENTER_X * 2, CENTER_Y * 2, 32, SDL_HWSURFACE or SDL_DOUBLEBUF or SDL_ANYFORMAT)
            else
              screen := SDL_SetVideoMode(CENTER_X * 2, CENTER_Y * 2, 32, SDL_FULLSCREEN);
            fullscreen := 1 - fullscreen;
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
            if SData[CurScence, 3, x, y] >= 0 then
            begin
              CurEvent := SData[CurScence, 3, x, y];
              walking := 0;
              if DData[CurScence, CurEvent, 2] >= 0 then
                callevent(DData[CurScence, SData[CurScence, 3, x, y], 2]);
            end;
            CurEvent := -1;
          end;

        end;
      SDL_KEYDOWN:
        begin
          if (event.key.keysym.sym = sdlk_left) then
          begin
            SFace := 2;
            SStep := Sstep + 1;
            if SStep = 8 then SStep := 1;
            if canwalkinscence(Sx, Sy - 1) = true
              then
            begin
              Sy := Sy - 1;
            end;
            DrawScence;
            SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
            CheckEvent3;
          end;
          if (event.key.keysym.sym = sdlk_right) then
          begin
            SFace := 1;
            SStep := Sstep + 1;
            if SStep = 8 then SStep := 1;
            if canwalkinscence(Sx, Sy + 1) = true
              then
            begin
              Sy := Sy + 1;
            end;
            DrawScence;
            SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
            CheckEvent3;
          end;
          if (event.key.keysym.sym = sdlk_up) then
          begin
            SFace := 0;
            SStep := Sstep + 1;
            if SStep = 8 then SStep := 1;
            if canwalkinscence(Sx - 1, Sy) = true
              then
            begin
              Sx := Sx - 1;
            end;
            DrawScence;
            SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
            CheckEvent3;
          end;
          if (event.key.keysym.sym = sdlk_down) then
          begin
            SFace := 3;
            SStep := Sstep + 1;
            if SStep = 8 then SStep := 1;
            if canwalkinscence(Sx + 1, Sy) = true then
            begin
              Sx := Sx + 1;
            end;
            DrawScence;
            SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
            CheckEvent3;
          end;
        end;
      Sdl_mousebuttondown:
        begin
          if event.button.button = sdl_button_left then
          begin
            walking := 1;
          end;
        end;
      Sdl_mousebuttonup:
        begin
          if event.button.button = sdl_button_right then menuesc;
          if event.button.button = sdl_button_left then
          begin
            walking := 0;
          end;
        end;
    end;
    sdl_delay(10);
    event.key.keysym.sym := 0;

  end;

  instruct_14; //黑屏

  ReDraw;
  SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
  if Rscence[CurScence].ExitMusic >= 0 then
  begin
    stopmp3;
    playmp3(Rscence[CurScence].ExitMusic, -1);
  end;

end;

procedure ShowScenceName(snum: integer);
var
  scencename: widestring;
begin
  SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
  //显示场景名
  scencename := big5tounicode(@rscence[snum].Name);
  drawtextwithrect(@scencename[1], 320 - length(pchar(@rscence[snum].Name)) * 5 + 7, 100, length(pchar(@rscence[snum].Name)) * 10 + 6, colcolor(7), colcolor(5));
  //waitanykey;
  //改变音乐
  if Rscence[snum].EntranceMusic >= 0 then
  begin
    stopmp3;
    playmp3(Rscence[snum].EntranceMusic, -1);
  end;
  SDL_Delay(500);

end;

//检查是否有第3类事件, 如有则调用

procedure CheckEvent3;
var
  enum: integer;
begin
  enum := SData[CurScence, 3, Sx, Sy];
  if (DData[CurScence, enum, 4] > 0) and (enum >= 0) then
  begin
    CurEvent := enum;
    waitanykey;
    callevent(DData[CurScence, enum, 4]);
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
  //SDL_EnableKeyRepeat(0,10);
  //DrawMMap;
  showcommonMenu(x, y, w, max, menu);
  SDL_UpdateRect(screen, x, y, w + 1, max * 22 + 29);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOk, mbCancel], 0) = idOK then Quit;
      SDL_KEYUP:
        begin
          if (event.key.keysym.sym = sdlk_down) then
          begin
            menu := menu + 1;
            if menu > max then menu := 0;
            showcommonMenu(x, y, w, max, menu);
            SDL_UpdateRect(screen, x, y, w + 1, max * 22 + 29);
          end;
          if (event.key.keysym.sym = sdlk_up) then
          begin
            menu := menu - 1;
            if menu < 0 then menu := max;
            showcommonMenu(x, y, w, max, menu);
            SDL_UpdateRect(screen, x, y, w + 1, max * 22 + 29);
          end;
          if ((event.key.keysym.sym = sdlk_escape)) and (where <= 2) then
          begin
            result := -1;
            ReDraw;
            SDL_UpdateRect(screen, x, y, w + 1, max * 22 + 29);
            break;
          end;
          if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
          begin
            result := menu;
            Redraw;
            SDL_UpdateRect(screen, x, y, w + 1, max * 22 + 29);
            break;
          end;
        end;
      SDL_MOUSEBUTTONUP:
        begin
          if (event.button.button = sdl_button_right) and (where <= 2) then
          begin
            result := -1;
            ReDraw;
            SDL_UpdateRect(screen, x, y, w + 1, max * 22 + 29);
            break;
          end;
          if (event.button.button = sdl_button_left) then
          begin
            result := menu;
            Redraw;
            SDL_UpdateRect(screen, x, y, w + 1, max * 22 + 29);
            break;
          end;
        end;
      SDL_MOUSEMOTION:
        begin
          if (event.button.x >= x) and (event.button.x < x + w) and (event.button.y > y) and (event.button.y < y + max * 22 + 29) then
          begin
            menup := menu;
            menu := (event.button.y - y - 2) div 22;
            if menu > max then menu := max;
            if menu < 0 then menu := 0;
            if menup <> menu then
            begin
              showcommonMenu(x, y, w, max, menu);
              SDL_UpdateRect(screen, x, y, w + 1, max * 22 + 29);
            end;
          end;
        end;
    end;
  end;
  //清空键盘键和鼠标键值, 避免影响其余部分
  event.key.keysym.sym := 0;
  event.button.button := 0;

end;

//显示通用选单(位置, 宽度, 最大值)
//这个通用选单包含两个字符串组, 可分别显示中文和英文

procedure ShowCommonMenu(x, y, w, max, menu: integer);
var
  i, p: integer;
begin
  redraw;
  DrawRectangle(x, y, w, max * 22 + 28, 0, colcolor(255), 30);
  if length(Menuengstring) > 0 then p := 1 else p := 0;
  for i := 0 to max do
    if i = menu then
    begin
      drawshadowtext(@menustring[i][1], x - 17, y + 2 + 22 * i, colcolor($66), colcolor($64));
      if p = 1 then
        drawengshadowtext(@menuengstring[i][1], x + 73, y + 2 + 22 * i, colcolor($66), colcolor($64));
    end
    else begin
      drawshadowtext(@menustring[i][1], x - 17, y + 2 + 22 * i, colcolor($7), colcolor($5));
      if p = 1 then
        drawengshadowtext(@menuengstring[i][1], x + 73, y + 2 + 22 * i, colcolor($7), colcolor($5));
    end;

end;

//卷动选单

function CommonScrollMenu(x, y, w, max, maxshow: integer): integer;
var
  menu, menup, menutop: integer;
begin
  menu := 0;
  menutop := 0;
  //SDL_EnableKeyRepeat(0,10);
  //DrawMMap;
  showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
  SDL_UpdateRect(screen, x, y, w + 1, maxshow * 22 + 29);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOk, mbCancel], 0) = idOK then Quit;
      SDL_KEYUP:
        begin
          if (event.key.keysym.sym = sdlk_down) then
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
            SDL_UpdateRect(screen, x, y, w + 1, maxshow * 22 + 29);
          end;
          if (event.key.keysym.sym = sdlk_up) then
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
            end;
            showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
            SDL_UpdateRect(screen, x, y, w + 1, maxshow * 22 + 29);
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
            SDL_UpdateRect(screen, x, y, w + 1, maxshow * 22 + 29);
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
            SDL_UpdateRect(screen, x, y, w + 1, maxshow * 22 + 29);
          end;
          if ((event.key.keysym.sym = sdlk_escape)) and (where <= 2) then
          begin
            result := -1;
            ReDraw;
            SDL_UpdateRect(screen, x, y, w + 1, maxshow * 22 + 29);
            break;
          end;
          if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
          begin
            result := menu;
            Redraw;
            SDL_UpdateRect(screen, x, y, w + 1, maxshow * 22 + 29);
            break;
          end;
        end;
      SDL_MOUSEBUTTONUP:
        begin
          if (event.button.button = sdl_button_right) and (where <= 2) then
          begin
            result := -1;
            ReDraw;
            SDL_UpdateRect(screen, x, y, w + 1, maxshow * 22 + 29);
            break;
          end;
          if (event.button.button = sdl_button_left) then
          begin
            result := menu;
            Redraw;
            SDL_UpdateRect(screen, x, y, w + 1, maxshow * 22 + 29);
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
            SDL_UpdateRect(screen, x, y, w + 1, maxshow * 22 + 29);
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
            end;
            showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
            SDL_UpdateRect(screen, x, y, w + 1, maxshow * 22 + 29);
          end;
        end;
      SDL_MOUSEMOTION:
        begin
          if (event.button.x >= x) and (event.button.x < x + w) and (event.button.y > y) and (event.button.y < y + max * 22 + 29) then
          begin
            menup := menu;
            menu := (event.button.y - y - 2) div 22 + menutop;
            if menu > max then menu := max;
            if menu < 0 then menu := 0;
            if menup <> menu then
            begin
              showcommonscrollMenu(x, y, w, max, maxshow, menu, menutop);
              SDL_UpdateRect(screen, x, y, w + 1, maxshow * 22 + 29);
            end;
          end;
        end;
    end;
  end;
  //清空键盘键和鼠标键值, 避免影响其余部分
  event.key.keysym.sym := 0;
  event.button.button := 0;

end;


procedure ShowCommonScrollMenu(x, y, w, max, maxshow, menu, menutop: integer);
var
  i, p: integer;
begin
  redraw;
  //showmessage(inttostr(y));
  if max + 1 < maxshow then maxshow := max + 1;
  DrawRectangle(x, y, w, maxshow * 22 + 6, 0, colcolor(255), 30);
  if length(Menuengstring) > 0 then p := 1 else p := 0;
  for i := menutop to menutop + maxshow - 1 do
    if i = menu then
    begin
      drawshadowtext(@menustring[i][1], x - 17, y + 2 + 22 * (i - menutop), colcolor($66), colcolor($64));
      if p = 1 then
        drawengshadowtext(@menuengstring[i][1], x + 73, y + 2 + 22 * (i - menutop), colcolor($66), colcolor($64));
    end
    else begin
      drawshadowtext(@menustring[i][1], x - 17, y + 2 + 22 * (i - menutop), colcolor($7), colcolor($5));
      if p = 1 then
        drawengshadowtext(@menuengstring[i][1], x + 73, y + 2 + 22 * (i - menutop), colcolor($7), colcolor($5));
    end;

end;

//仅有两个选项的横排选单, 为美观使用横排
//此类选单中每个选项限制为两个中文字, 仅适用于提问'继续', '取消'的情况

function CommonMenu2(x, y, w: integer): integer;
var
  menu, menup: integer;
begin
  menu := 0;
  //SDL_EnableKeyRepeat(0,10);
  //DrawMMap;
  showcommonMenu2(x, y, w, menu);
  SDL_UpdateRect(screen, x, y, w + 1, 29);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOk, mbCancel], 0) = idOK then Quit;
      SDL_KEYUP:
        begin
          if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_right) then
          begin
            if menu = 1 then menu := 0 else menu := 1;
            showcommonMenu2(x, y, w, menu);
            SDL_UpdateRect(screen, x, y, w + 1, 29);
          end;
          if ((event.key.keysym.sym = sdlk_escape)) and (where <= 2) then
          begin
            result := -1;
            ReDraw;
            SDL_UpdateRect(screen, x, y, w + 1, 29);
            break;
          end;
          if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
          begin
            result := menu;
            Redraw;
            SDL_UpdateRect(screen, x, y, w + 1, 29);
            break;
          end;
        end;
      SDL_MOUSEBUTTONUP:
        begin
          if (event.button.button = sdl_button_right) and (where <= 2) then
          begin
            result := -1;
            ReDraw;
            SDL_UpdateRect(screen, x, y, w + 1, 29);
            break;
          end;
          if (event.button.button = sdl_button_left) then
          begin
            result := menu;
            Redraw;
            SDL_UpdateRect(screen, x, y, w + 1, 29);
            break;
          end;
        end;
      SDL_MOUSEMOTION:
        begin
          if (event.button.x >= x) and (event.button.x < x + w) and (event.button.y > y) and (event.button.y < y + 29) then
          begin
            menup := menu;
            menu := (event.button.x - x - 2) div 50;
            if menu > 1 then menu := 1;
            if menu < 0 then menu := 0;
            if menup <> menu then
            begin
              showcommonMenu2(x, y, w, menu);
              SDL_UpdateRect(screen, x, y, w + 1, 29);
            end;
          end;
        end;
    end;
  end;
  //清空键盘键和鼠标键值, 避免影响其余部分
  event.key.keysym.sym := 0;
  event.button.button := 0;

end;

//显示仅有两个选项的横排选单

procedure ShowCommonMenu2(x, y, w, menu: integer);
var
  i, p: integer;
begin
  redraw;
  DrawRectangle(x, y, w, 28, 0, colcolor(255), 30);
  //if length(Menuengstring) > 0 then p := 1 else p := 0;
  for i := 0 to 1 do
    if i = menu then
    begin
      drawshadowtext(@menustring[i][1], x - 17 + i * 50, y + 2, colcolor($66), colcolor($64));
    end
    else begin
      drawshadowtext(@menustring[i][1], x - 17 + i * 50, y + 2, colcolor($7), colcolor($5));
    end;

end;


//选择一名队员, 可以附带两个属性显示

function SelectOneTeamMember(x, y: integer; str: string; list1, list2: integer): integer;
var
  i, amount: integer;
begin
  setlength(Menustring, 6);
  if str <> '' then setlength(Menuengstring, 6) else setlength(Menuengstring, 0);
  amount := 0;

  for i := 0 to 5 do
  begin
    if Teamlist[i] >= 0 then
    begin
      menustring[i] := Big5toUnicode(@RRole[Teamlist[i]].Name);
      if str <> '' then
      begin
        menuengstring[i] := format(str, [Rrole[teamlist[i]].data[list1], Rrole[teamlist[i]].data[list2]]);
      end;
      amount := amount + 1;
    end;
  end;
  if str = '' then result := commonmenu(x, y, 85, amount - 1)
  else result := commonmenu(x, y, 85 + length(menuengstring[0]) * 10, amount - 1);

end;

//主选单

procedure MenuEsc;
var
  menu, menup: integer;
begin
  menu := 0;
  SDL_EnableKeyRepeat(0, 0);
  //DrawMMap;
  showMenu(menu);
  //SDL_EventState(SDL_KEYDOWN,SDL_IGNORE);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    if where >= 3 then
    begin
      break;
    end;
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOk, mbCancel], 0) = idOK then Quit;
      SDL_KEYUP:
        begin
          if (event.key.keysym.sym = sdlk_down) then
          begin
            menu := menu + 1;
            if menu > 5 - where * 2 then menu := 0;
            showMenu(menu);
          end;
          if (event.key.keysym.sym = sdlk_up) then
          begin
            menu := menu - 1;
            if menu < 0 then menu := 5 - where * 2;
            showMenu(menu);
          end;
          if (event.key.keysym.sym = sdlk_escape) then
          begin
            ReDraw;
            SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
            break;
          end;
          if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
          begin
            case menu of
              0: MenuMedcine;
              1: MenuMedPoision;
              2: MenuItem;
              5: MenuSystem;
              4: MenuLeave;
              3: MenuStatus;
            end;
            showmenu(menu);
          end;
        end;
      SDL_MOUSEBUTTONUP:
        begin
          if event.button.button = sdl_button_right then
          begin
            ReDraw;
            SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
            break;
          end;
          if event.button.button = sdl_button_left then
          begin
            if (event.button.y > 32) and (event.button.y < 32 + 22 * (6 - where * 2)) and (event.button.x > 27) and (event.button.x < 27 + 46) then
            begin
              showmenu(menu);
              case menu of
                0: MenuMedcine;
                1: MenuMedPoision;
                2: MenuItem;
                5: MenuSystem;
                4: MenuLeave;
                3: MenuStatus;
              end;
              showmenu(menu);
            end;
          end;
        end;
      SDL_MOUSEMOTION:
        begin
          if (event.button.y > 32) and (event.button.y < 32 + 22 * 6) and (event.button.x > 27) and (event.button.x < 27 + 46) then
          begin
            menup := menu;
            menu := (event.button.y - 32) div 22;
            if menu > 5 - where * 2 then menu := 5 - where * 2;
            if menu < 0 then menu := 0;
            if menup <> menu then showmenu(menu);
          end;
        end;

    end;
  end;
  event.key.keysym.sym := 0;
  event.button.button := 0;
  SDL_EnableKeyRepeat(50, 30);

end;

//显示主选单

procedure ShowMenu(menu: integer);
var
  word: array[0..5] of Widestring;
  i, max: integer;
begin
  Word[0] := ' 醫療';
  Word[1] := ' 解毒';
  Word[2] := ' 物品';
  Word[3] := ' 狀態';
  Word[4] := ' 離隊';
  Word[5] := ' 系統';
  if where = 0 then max := 5 else max := 3;
  ReDraw;
  DrawRectangle(27, 30, 46, max * 22 + 28, 0, colcolor(255), 30);
  //当前所在位置用白色, 其余用黄色
  for i := 0 to max do
    if i = menu then
    begin
      drawtext(screen, @word[i][1], 11, 32 + 22 * i, colcolor($64));
      drawtext(screen, @word[i][1], 10, 32 + 22 * i, colcolor($66));
    end
    else begin
      drawtext(screen, @word[i][1], 11, 32 + 22 * i, colcolor($5));
      drawtext(screen, @word[i][1], 10, 32 + 22 * i, colcolor($7));
    end;
  SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);

end;

//医疗选单, 需两次选择队员

procedure MenuMedcine;
var
  role1, role2, menu: integer;
  str: widestring;
begin
  str := ' 隊員醫療能力';
  drawtextwithrect(@str[1], 80, 30, 132, colcolor($23), colcolor($21));
  menu := SelectOneTeamMember(80, 65, '%3d', 46, 0);
  showmenu(0);
  SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
  if menu >= 0 then
  begin
    role1 := TeamList[menu];
    str := ' 隊員目前生命';
    drawtextwithrect(@str[1], 80, 30, 132, colcolor($23), colcolor($21));
    menu := SelectOneTeamMember(80, 65, '%4d/%4d', 17, 18);
    role2 := TeamList[menu];
    if menu >= 0 then
      EffectMedcine(role1, role2);
  end;
  //waitanykey;
  redraw;
  //SDL_UpdateRect(screen,0,0,screen.w,screen.h);

end;

//解毒选单

procedure MenuMedPoision;
var
  role1, role2, menu: integer;
  str: widestring;
begin
  str := ' 隊員解毒能力';
  drawtextwithrect(@str[1], 80, 30, 132, colcolor($23), colcolor($21));
  menu := SelectOneTeamMember(80, 65, '%3d', 48, 0);
  showmenu(1);
  SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
  if menu >= 0 then
  begin
    role1 := TeamList[menu];
    str := ' 隊員中毒程度';
    drawtextwithrect(@str[1], 80, 30, 132, colcolor($23), colcolor($21));
    menu := SelectOneTeamMember(80, 65, '%3d', 20, 0);
    role2 := TeamList[menu];
    if menu >= 0 then
      EffectMedPoision(role1, role2);
  end;
  //waitanykey;
  redraw;
  //showmenu(1);
  //SDL_UpdateRect(screen,0,0,screen.w,screen.h);

end;

//物品选单

function MenuItem: boolean;
var
  point, atlu, x, y, col, row, xp, yp, iamount, menu, max: integer;
  //point似乎未使用, atlu为处于左上角的物品在列表中的序号, x, y为光标位置
  //col, row为总列数和行数
begin
  col := 9;
  row := 5;
  x := 0;
  y := 0;
  atlu := 0;
  setlength(Menuengstring, 0);
  case where of
    0, 1:
      begin
        max := 5;
        setlength(menustring, max + 1);
        menustring[0] := ' 全部物品';
        menustring[1] := ' 劇情物品';
        menustring[2] := ' 神兵寶甲';
        menustring[3] := ' 武功秘笈';
        menustring[4] := ' 靈丹妙藥';
        menustring[5] := ' 傷人暗器';
        menu := commonmenu(80, 30, 87, max);
        if menu = 0 then menu := 101;
        menu := menu - 1;
      end;
    2:
      begin
        max := 1;
        setlength(menustring, max + 1);
        menustring[0] := ' 靈丹妙藥';
        menustring[1] := ' 傷人暗器';
        menu := commonmenu(150, 150, 87, max);
        if menu >= 0 then menu := menu + 3;
      end;
  end;

  if menu < 0 then result := false;

  if menu >= 0 then
  begin
    iamount := ReadItemList(menu);
    showMenuItem(row, col, x, y, atlu);
    SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
    while (SDL_WaitEvent(@event) >= 0) do
    begin
      case event.type_ of
        SDL_QUITEV:
          if messagedlg('Are you sure to quit?', mtConfirmation, [mbOk, mbCancel], 0) = idOK then Quit;
        SDL_KEYUP:
          begin
            if (event.key.keysym.sym = sdlk_down) then
            begin
              y := y + 1;
              if y < 0 then y := 0;
              if (y >= row) then
              begin
                if (ItemList[atlu + col * row] >= 0) then atlu := atlu + col;
                y := row - 1;
              end;
              showMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
            end;
            if (event.key.keysym.sym = sdlk_up) then
            begin
              y := y - 1;
              if y < 0 then
              begin
                y := 0;
                if atlu > 0 then atlu := atlu - col;
              end;
              showMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
            end;
            if (event.key.keysym.sym = sdlk_pagedown) then
            begin
              //y := y + row;
              atlu := atlu + col * row;
              if y < 0 then y := 0;
              if (ItemList[atlu + col * row] < 0) and (iamount > col * row) then
              begin
                y := y - (iamount - atlu) div col - 1 + row;
                atlu := (iamount div col - row + 1) * col;
                if y >= row then y := row - 1;
              end;
              showMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
            end;
            if (event.key.keysym.sym = sdlk_pageup) then
            begin
              //y := y - row;
              atlu := atlu - col * row;
              if atlu < 0 then
              begin
                y := y + atlu div col;
                atlu := 0;
                if y < 0 then y := 0;
              end;
              showMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
            end;
            if (event.key.keysym.sym = sdlk_right) then
            begin
              x := x + 1;
              if x >= col then x := 0;
              showMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
            end;
            if (event.key.keysym.sym = sdlk_left) then
            begin
              x := x - 1;
              if x < 0 then x := col - 1;
              showMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
            end;
            if (event.key.keysym.sym = sdlk_escape) then
            begin
              ReDraw;
              //ShowMenu(2);
              result := false;
              SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
              break;
            end;
            if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
            begin
              ReDraw;
              CurItem := RItemlist[itemlist[(y * col + x + atlu)]].Number;
              if (where <> 2) and (CurItem >= 0) and (itemlist[(y * col + x + atlu)] >= 0) then
                UseItem(CurItem);
              //ShowMenu(2);
              result := true;
              SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
              break;
            end;
          end;
        SDL_MOUSEBUTTONUP:
          begin
            if (event.button.button = sdl_button_right) then
            begin
              ReDraw;
              //ShowMenu(2);
              result := false;
              SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
              break;
            end;
            if (event.button.button = sdl_button_left) then
            begin
              ReDraw;
              CurItem := RItemlist[itemlist[(y * col + x + atlu)]].Number;
              if (where <> 2) and (CurItem >= 0) and (itemlist[(y * col + x + atlu)] >= 0) then
                UseItem(CurItem);
              //ShowMenu(2);
              result := true;
              SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
              break;
            end;
            if (event.button.button = sdl_button_wheeldown) then
            begin
              y := y + 1;
              if y < 0 then y := 0;
              if (y >= row) then
              begin
                if (ItemList[atlu + col * 5] >= 0) then atlu := atlu + col;
                y := row - 1;
              end;
              showMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
            end;
            if (event.button.button = sdl_button_wheelup) then
            begin
              y := y - 1;
              if y < 0 then
              begin
                y := 0;
                if atlu > 0 then atlu := atlu - col;
              end;
              showMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
            end;
          end;
        SDL_MOUSEMOTION:
          begin
            if (event.button.x >= 110) and (event.button.x < 496) and (event.button.y > 90) and (event.button.y < 308) then
            begin
              xp := x;
              yp := y;
              x := (event.button.x - 115) div 42;
              y := (event.button.y - 95) div 42;
              if x >= col then x := col - 1;
              if y >= row then y := row - 1;
              if x < 0 then x := 0;
              if y < 0 then y := 0;
              //鼠标移动时仅在x, y发生变化时才重画
              if (x <> xp) or (y <> yp) then
              begin
                showMenuItem(row, col, x, y, atlu);
                SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
              end;
            end;
            if (event.button.x >= 110) and (event.button.x < 496) and (event.button.y > 308) then
            begin
              //atlu := atlu+col;
              if (ItemList[atlu + col * 5] >= 0) then atlu := atlu + col;
              showMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
            end;
            if (event.button.x >= 110) and (event.button.x < 496) and (event.button.y < 90) then
            begin
              if atlu > 0 then atlu := atlu - col;
              showMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
            end;
          end;
      end;
    end;
  end;
  //SDL_UpdateRect(screen,0,0,screen.w,screen.h);

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
      if (Ritem[RItemlist[i].Number].ItemType = ItemType) or (ItemType = 100) then
      begin
        Itemlist[p] := i;
        p := p + 1;
      end;
    end;
  end;
  result := p;

end;

//显示物品选单

procedure ShowMenuItem(row, col, x, y, atlu: integer);
var
  item, i, i1, i2, len, len2, len3, listnum: integer;
  str: widestring;
  words: array[0..10] of widestring;
  words2: array[0..22] of widestring;
  words3: array[0..12] of widestring;
  p2: array[0..22] of integer;
  p3: array[0..12] of integer;
begin
  words[0] := ' 劇情物品';
  words[1] := ' 神兵寶甲';
  words[2] := ' 武功秘笈';
  words[3] := ' 靈丹妙藥';
  words[4] := ' 傷人暗器';
  words2[0] := ' 生命'; words2[1] := ' 生命'; words2[2] := ' 中毒';
  words2[3] := ' 體力'; words2[4] := ' 內力'; words2[5] := ' 內力';
  words2[6] := ' 內力'; words2[7] := ' 攻擊'; words2[8] := ' 輕功';
  words2[9] := ' 防禦'; words2[10] := ' 醫療'; words2[11] := ' 用毒';
  words2[12] := ' 解毒'; words2[13] := ' 抗毒'; words2[14] := ' 拳掌';
  words2[15] := ' 御劍'; words2[16] := ' 耍刀'; words2[17] := ' 特殊';
  words2[18] := ' 暗器'; words2[19] := ' 武學'; words2[20] := ' 品德';
  words2[21] := ' 左右'; words2[22] := ' 帶毒';

  words3[0] := ' 內力'; words3[1] := ' 內力'; words3[2] := ' 攻擊';
  words3[3] := ' 輕功'; words3[4] := ' 用毒'; words3[5] := ' 醫療';
  words3[6] := ' 解毒'; words3[7] := ' 拳掌'; words3[8] := ' 御劍';
  words3[9] := ' 耍刀'; words3[10] := ' 特殊'; words3[11] := ' 暗器';
  words3[12] := ' 資質';


  ReDraw;
  drawrectangle(110, 30, 386, 25, 0, colcolor(255), 30);
  drawrectangle(110, 60, 386, 25, 0, colcolor(255), 30);
  drawrectangle(110, 90, 386, 218, 0, colcolor(255), 30);
  drawrectangle(110, 313, 386, 25, 0, colcolor(255), 30);
  //i:=0;
  for i1 := 0 to row - 1 do
    for i2 := 0 to col - 1 do
    begin
      listnum := ItemList[i1 * col + i2 + atlu];
      if (RItemlist[listnum].Number >= 0) and (listnum < MAX_ITEM_AMOUNT) and (listnum >= 0) then
      begin
        DrawMPic(ITEM_BEGIN_PIC + RItemlist[listnum].Number, i2 * 42 + 115, i1 * 42 + 95);
      end;
    end;
  listnum := itemlist[y * col + x + atlu];
  item := RItemlist[listnum].Number;

  if (RItemlist[listnum].Amount > 0) and (listnum < MAX_ITEM_AMOUNT) and (listnum >= 0) then
  begin
    str := format('%5d', [RItemlist[listnum].Amount]);
    drawengtext(screen, @str[1], 431, 32, colcolor($64));
    drawengtext(screen, @str[1], 430, 32, colcolor($66));
    len := length(pchar(@Ritem[item].Name));
    drawbig5text(screen, @RItem[item].Name, 296 - len * 5, 32, colcolor($21));
    drawbig5text(screen, @RItem[item].Name, 295 - len * 5, 32, colcolor($23));
    len := length(pchar(@Ritem[item].Introduction));
    drawbig5text(screen, @RItem[item].Introduction, 296 - len * 5, 62, colcolor($5));
    drawbig5text(screen, @RItem[item].Introduction, 295 - len * 5, 62, colcolor($7));
    drawshadowtext(@words[Ritem[item].ItemType, 1], 97, 315, colcolor($23), colcolor($21));
    //如有人使用则显示
    if RItem[item].User >= 0 then
    begin
      str := ' 使用人：';
      drawshadowtext(@str[1], 187, 315, colcolor($23), colcolor($21));
      drawbig5shadowtext(@rrole[RItem[item].User].Name, 277, 315, colcolor($66), colcolor($64));
    end;
    //如是罗盘则显示坐标
    if item = COMPASS_ID then
    begin
      str := ' 你的位置：';
      drawshadowtext(@str[1], 187, 315, colcolor($23), colcolor($21));
      str := format('%3d, %3d', [My, Mx]);
      drawengshadowtext(@str[1], 317, 315, colcolor($66), colcolor($64));
    end;
  end;


  if (item >= 0) and (ritem[item].ItemType > 0) then
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
    if ritem[item].ChangeMPType = 2 then
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
    if (ritem[item].NeedMPType in [0, 1]) and (ritem[item].ItemType <> 3) then
    begin
      p3[0] := 1;
      len3 := len3 + 1;
    end;

    if len2 + len3 > 0 then
      drawrectangle(110, 344, 386, 20 * ((len2 + 2) div 3 + (len3 + 2) div 3) + 5, 0, colcolor(255), 30);

    i1 := 0;
    for i := 0 to 22 do
    begin
      if (p2[i] = 1) then
      begin
        str := format('%6d', [ritem[item].Data[45 + i]]);
        if i = 4 then
          case ritem[item].ChangeMPType of
            0: str := '    陰';
            1: str := '    陽';
            2: str := '  調和';
          end;

        drawshadowtext(@words2[i][1], 97 + i1 mod 3 * 130, i1 div 3 * 20 + 346, colcolor($7), colcolor($5));
        drawshadowtext(@str[1], 147 + i1 mod 3 * 130, i1 div 3 * 20 + 346, colcolor($66), colcolor($64));
        i1 := i1 + 1;
      end;
    end;

    i1 := 0;
    for i := 0 to 12 do
    begin
      if (p3[i] = 1) then
      begin
        str := format('%6d', [ritem[item].Data[69 + i]]);
        if i = 0 then
          case ritem[item].NeedMPType of
            0: str := '    陰';
            1: str := '    陽';
            2: str := '  調和';
          end;

        drawshadowtext(@words3[i][1], 97 + i1 mod 3 * 130, ((len2 + 2) div 3 + i1 div 3) * 20 + 346, colcolor($50), colcolor($4E));
        drawshadowtext(@str[1], 147 + i1 mod 3 * 130, ((len2 + 2) div 3 + i1 div 3) * 20 + 346, colcolor($66), colcolor($64));
        i1 := i1 + 1;
      end;
    end;
  end;

  drawItemframe(x, y);

end;

//画白色边框作为物品选单的光标

procedure DrawItemFrame(x, y: integer);
var
  i: integer;
begin
  for i := 0 to 39 do
  begin
    putpixel(screen, x * 42 + 116 + i, y * 42 + 96, colcolor(255));
    putpixel(screen, x * 42 + 116 + i, y * 42 + 96 + 39, colcolor(255));
    putpixel(screen, x * 42 + 116, y * 42 + 96 + i, colcolor(255));
    putpixel(screen, x * 42 + 116 + 39, y * 42 + 96 + i, colcolor(255));
  end;

end;

//使用物品

procedure UseItem(inum: integer);
var
  x, y, menu, rnum, p: integer;
  str, str1: widestring;
begin
  CurItem := inum;

  case RItem[inum].ItemType of
    0: //剧情物品
      begin
        //如某属性大于0, 直接调用事件
        if ritem[inum].UnKnow7 > 0 then
          callevent(ritem[inum].UnKnow7)
        else begin
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
            if SData[CurScence, 3, x, y] >= 0 then
            begin
              CurEvent := SData[CurScence, 3, x, y];
              if DData[CurScence, SData[CurScence, 3, x, y], 3] >= 0 then
                callevent(DData[CurScence, SData[CurScence, 3, x, y], 3]);
            end;
            CurEvent := -1;
          end;
        end;
      end;
    1: //装备
      begin
        menu := 1;
        if Ritem[inum].User >= 0 then
        begin
          setlength(menustring, 2);
          menustring[0] := ' 取消';
          menustring[1] := ' 繼續';
          str := ' 此物品正有人裝備，是否繼續？';
          drawtextwithrect(@str[1], 80, 30, 285, colcolor(7), colcolor(5));
          menu := commonmenu(80, 65, 45, 1);
        end;
        if menu = 1 then
        begin
          str := ' 誰要裝備';
          str1 := big5tounicode(@Ritem[inum].Name);
          drawtextwithrect(@str[1], 80, 30, length(str1) * 22 + 80, colcolor($23), colcolor($21));
          drawshadowtext(@str1[1], 160, 32, colcolor($66), colcolor($64));
          SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
          menu := SelectOneTeamMember(80, 65, '', 0, 0);
          if menu >= 0 then
          begin
            rnum := Teamlist[menu];
            p := Ritem[inum].EquipType;
            if (p < 0) or (p > 1) then p := 0;
            if canequip(rnum, inum) then
            begin
              if Ritem[inum].User >= 0 then Rrole[Ritem[inum].User].Equip[p] := -1;
              if Rrole[rnum].Equip[p] >= 0 then Ritem[RRole[rnum].Equip[p]].User := -1;
              Rrole[rnum].Equip[p] := inum;
              Ritem[inum].User := rnum;
            end else
            begin
              str := ' 此人不適合裝備此物品';
              drawtextwithrect(@str[1], 80, 30, 205, colcolor($66), colcolor($64));
              waitanykey;
              redraw;
              //SDL_UpdateRect(screen,0,0,screen.w,screen.h);
            end;
          end;
        end;
      end;
    2: //秘笈
      begin
        menu := 1;
        if Ritem[inum].User >= 0 then
        begin
          setlength(menustring, 2);
          menustring[0] := ' 取消';
          menustring[1] := ' 繼續';
          str := ' 此秘笈正有人修煉，是否繼續？';
          drawtextwithrect(@str[1], 80, 30, 285, colcolor(7), colcolor(5));
          menu := commonmenu(80, 65, 45, 1);
        end;
        if menu = 1 then
        begin
          str := ' 誰要修煉';
          str1 := big5tounicode(@Ritem[inum].Name);
          drawtextwithrect(@str[1], 80, 30, length(str1) * 22 + 80, colcolor($23), colcolor($21));
          drawshadowtext(@str1[1], 160, 32, colcolor($66), colcolor($64));
          SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
          menu := SelectOneTeamMember(80, 65, '', 0, 0);
          if menu >= 0 then
          begin
            rnum := TeamList[menu];
            if canequip(rnum, inum) then
            begin
              if Ritem[inum].User >= 0 then Rrole[Ritem[inum].User].PracticeBook := -1;
              if Rrole[rnum].PracticeBook >= 0 then Ritem[RRole[rnum].PracticeBook].User := -1;
              Rrole[rnum].PracticeBook := inum;
              Ritem[inum].User := rnum;
              if (inum in [78, 93]) then rrole[rnum].Sexual := 2;
            end else
            begin
              str := ' 此人不適合修煉此秘笈';
              drawtextwithrect(@str[1], 80, 30, 205, colcolor($66), colcolor($64));
              waitanykey;
              redraw;
              //SDL_UpdateRect(screen,0,0,screen.w,screen.h);
            end;
          end;
        end;
      end;
    3: //药品
      begin
        if where <> 2 then
        begin
          str := ' 誰要服用';
          str1 := big5tounicode(@Ritem[inum].Name);
          drawtextwithrect(@str[1], 80, 30, length(str1) * 22 + 80, colcolor($23), colcolor($21));
          drawshadowtext(@str1[1], 160, 32, colcolor($66), colcolor($64));
          SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
          menu := SelectOneTeamMember(80, 65, '', 0, 0);
          rnum := TeamList[menu];
        end;
        if menu >= 0 then
        begin
          redraw;
          EatOneItem(rnum, inum);
          instruct_32(inum, -1);
          waitanykey;
        end;
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
  i, r: integer;
begin

  //判断是否符合
  //注意这里对'所需属性'为负值时均添加原版类似资质的处理

  result := true;

  if sign(Ritem[inum].NeedMP) * Rrole[rnum].CurrentMP < Ritem[inum].NeedMP then result := false;
  if sign(Ritem[inum].NeedAttack) * Rrole[rnum].Attack < Ritem[inum].NeedAttack then result := false;
  if sign(Ritem[inum].NeedSpeed) * Rrole[rnum].Speed < Ritem[inum].NeedSpeed then result := false;
  if sign(Ritem[inum].NeedUsePoi) * Rrole[rnum].UsePoi < Ritem[inum].NeedUsepoi then result := false;
  if sign(Ritem[inum].NeedMedcine) * Rrole[rnum].Medcine < Ritem[inum].NeedMedcine then result := false;
  if sign(Ritem[inum].NeedMedPoi) * Rrole[rnum].MedPoi < Ritem[inum].NeedMedPoi then result := false;
  if sign(Ritem[inum].NeedFist) * Rrole[rnum].Fist < Ritem[inum].NeedFist then result := false;
  if sign(Ritem[inum].NeedSword) * Rrole[rnum].Sword < Ritem[inum].NeedSword then result := false;
  if sign(Ritem[inum].NeedKnife) * Rrole[rnum].Knife < Ritem[inum].NeedKnife then result := false;
  if sign(Ritem[inum].NeedUnusual) * Rrole[rnum].Unusual < Ritem[inum].NeedUnusual then result := false;
  if sign(Ritem[inum].NeedHidWeapon) * Rrole[rnum].HidWeapon < Ritem[inum].NeedHidWeapon then result := false;
  if sign(Ritem[inum].NeedAptitude) * Rrole[rnum].Aptitude < Ritem[inum].NeedAptitude then result := false;

  //内力性质
  if (rrole[rnum].MPType < 2) and (Ritem[inum].NeedMPType < 2) then
    if rrole[rnum].MPType <> Ritem[inum].NeedMPType then result := false;

  //如有专用人物, 前面的都作废
  if (Ritem[inum].OnlyPracRole >= 0) and (result = true) then
    if (Ritem[inum].OnlyPracRole = rnum) then result := true else result := false;

  //如已有10种武功, 且物品也能练出武功, 则结果为假
  r := 0;
  for i := 0 to 9 do
    if Rrole[rnum].Magic[i] > 0 then r := r + 1;
  if (r >= 10) and (ritem[inum].Magic > 0) then result := false;

  for i := 0 to 9 do
    if Rrole[rnum].Magic[i] = ritem[inum].Magic then
    begin
      result := true;
      break;
    end;

end;

//查看状态选单

procedure MenuStatus;
var
  str: widestring;
  menu: integer;
begin
  str := ' 查看隊員狀態';
  drawtextwithrect(@str[1], 80, 30, 132, colcolor($23), colcolor($21));
  menu := SelectOneTeamMember(80, 65, '%3d', 15, 0);
  if menu >= 0 then
  begin
    ShowStatus(TeamList[menu]);
    waitanykey;
    redraw;
    SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);
  end;

end;

//显示状态

procedure ShowStatus(rnum: integer);
var
  i, magicnum, mlevel, needexp, x, y: integer;
  p: array[0..10] of integer;
  addatk, adddef, addspeed: integer;
  str: widestring;
  strs: array[0..21] of widestring;
  color1, color2: uint32;
  name: widestring;
begin
  strs[0] := ' 等級';
  strs[1] := ' 生命';
  strs[2] := ' 內力';
  strs[3] := ' 體力';
  strs[4] := ' 經驗';
  strs[5] := ' 升級';
  strs[6] := ' 攻擊';
  strs[7] := ' 防禦';
  strs[8] := ' 輕功';
  strs[9] := ' 醫療能力';
  strs[10] := ' 用毒能力';
  strs[11] := ' 解毒能力';
  strs[12] := ' 拳掌功夫';
  strs[13] := ' 御劍能力';
  strs[14] := ' 耍刀技巧';
  strs[15] := ' 特殊兵器';
  strs[16] := ' 暗器技巧';
  strs[17] := ' 裝備物品';
  strs[18] := ' 修煉物品';
  strs[19] := ' 所會武功';
  strs[20] := ' 受傷';
  strs[21] := ' 中毒';
  p[0] := 43; p[1] := 45; p[2] := 44; p[3] := 46; p[4] := 47;
  p[5] := 48; p[6] := 50; p[7] := 51; p[8] := 52; p[9] := 53; p[10] := 54;
  Redraw;
  x := 40;
  y := CENTER_Y - 160;
  DrawRectangle(x, y, 560, 315, 0, colcolor(255), 50);
  //显示头像
  drawheadpic(Rrole[rnum].HeadNum, x + 60, y + 80);
  //显示姓名
  name := big5tounicode(@Rrole[rnum].Name);
  drawshadowtext(@name[1], x + 68 - length(pchar(@Rrole[rnum].Name)) * 5, y + 85, colcolor($66), colcolor($63));
  //显示所需字符
  for i := 0 to 5 do
    drawshadowtext(@strs[i, 1], x - 10, y + 110 + 21 * i, colcolor($23), colcolor($21));
  for i := 6 to 16 do
    drawshadowtext(@strs[i, 1], x + 160, y + 5 + 21 * (i - 6), colcolor($66), colcolor($63));
  drawshadowtext(@strs[19, 1], x + 360, y + 5, colcolor($23), colcolor($21));

  addatk := 0;
  adddef := 0;
  addspeed := 0;
  if rrole[rnum].Equip[0] >= 0 then
  begin
    addatk := addatk + ritem[rrole[rnum].Equip[0]].AddAttack;
    adddef := adddef + ritem[rrole[rnum].Equip[0]].AddDefence;
    addspeed := addspeed + ritem[rrole[rnum].Equip[0]].AddSpeed;
  end;

  if rrole[rnum].Equip[1] >= 0 then
  begin
    addatk := addatk + ritem[rrole[rnum].Equip[1]].AddAttack;
    adddef := adddef + ritem[rrole[rnum].Equip[1]].AddDefence;
    addspeed := addspeed + ritem[rrole[rnum].Equip[1]].AddSpeed;
  end;

  //攻击, 防御, 轻功
  //单独处理是因为显示顺序和存储顺序不同
  str := format('%4d', [Rrole[rnum].Attack + addatk]);
  drawengshadowtext(@str[1], x + 300, y + 5 + 21 * 0, colcolor($7), colcolor($5));
  str := format('%4d', [Rrole[rnum].Defence + adddef]);
  drawengshadowtext(@str[1], x + 300, y + 5 + 21 * 1, colcolor($7), colcolor($5));
  str := format('%4d', [Rrole[rnum].Speed + addspeed]);
  drawengshadowtext(@str[1], x + 300, y + 5 + 21 * 2, colcolor($7), colcolor($5));

  //其他属性
  str := format('%4d', [Rrole[rnum].Medcine]);
  drawengshadowtext(@str[1], x + 300, y + 5 + 21 * 3, colcolor($7), colcolor($5));

  str := format('%4d', [Rrole[rnum].UsePoi]);
  drawengshadowtext(@str[1], x + 300, y + 5 + 21 * 4, colcolor($7), colcolor($5));

  str := format('%4d', [Rrole[rnum].MedPoi]);
  drawengshadowtext(@str[1], x + 300, y + 5 + 21 * 5, colcolor($7), colcolor($5));

  str := format('%4d', [Rrole[rnum].Fist]);
  drawengshadowtext(@str[1], x + 300, y + 5 + 21 * 6, colcolor($7), colcolor($5));

  str := format('%4d', [Rrole[rnum].Sword]);
  drawengshadowtext(@str[1], x + 300, y + 5 + 21 * 7, colcolor($7), colcolor($5));

  str := format('%4d', [Rrole[rnum].Knife]);
  drawengshadowtext(@str[1], x + 300, y + 5 + 21 * 8, colcolor($7), colcolor($5));

  str := format('%4d', [Rrole[rnum].Unusual]);
  drawengshadowtext(@str[1], x + 300, y + 5 + 21 * 9, colcolor($7), colcolor($5));

  str := format('%4d', [Rrole[rnum].HidWeapon]);
  drawengshadowtext(@str[1], x + 300, y + 5 + 21 * 10, colcolor($7), colcolor($5));

  //武功
  for i := 0 to 9 do
  begin
    magicnum := Rrole[rnum].magic[i];
    if magicnum > 0 then
    begin
      drawbig5shadowtext(@Rmagic[magicnum].Name, x + 360, y + 26 + 21 * i, colcolor($7), colcolor($5));
      str := format('%3d', [Rrole[rnum].MagLevel[i] div 100 + 1]);
      drawengshadowtext(@str[1], x + 520, y + 26 + 21 * i, colcolor($66), colcolor($64));
    end;
  end;
  str := format('%4d', [Rrole[rnum].Level]);
  drawengshadowtext(@str[1], x + 110, y + 110, colcolor($7), colcolor($5));
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
      color1 := colcolor($7);
      color2 := colcolor($5);
    end;
  end;
  str := format('%4d', [RRole[rnum].CurrentHP]);
  drawengshadowtext(@str[1], x + 60, y + 131, color1, color2);

  str := '/';
  drawengshadowtext(@str[1], x + 100, y + 131, colcolor($66), colcolor($63));

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
      color1 := colcolor($23);
      color2 := colcolor($21);
    end;
  end;
  str := format('%4d', [RRole[rnum].MaxHP]);
  drawengshadowtext(@str[1], x + 110, y + 131, color1, color2);
  //内力, 依据内力性质使用颜色
  if rrole[rnum].MPType = 0 then
  begin
    color1 := colcolor($50);
    color2 := colcolor($4E);
  end else
    if rrole[rnum].MPType = 1 then
    begin
      color1 := colcolor($7);
      color2 := colcolor($5);
    end else
    begin
      color1 := colcolor($66);
      color2 := colcolor($63);
    end;
  str := format('%4d/%4d', [RRole[rnum].CurrentMP, RRole[rnum].MaxMP]);
  drawengshadowtext(@str[1], x + 60, y + 152, color1, color2);
  //体力
  str := format('%4d/%4d', [rrole[rnum].PhyPower, MAX_PHYSICAL_POWER]);
  drawengshadowtext(@str[1], x + 60, y + 173, colcolor($7), colcolor($5));
  //经验
  str := format('%5d', [uint16(Rrole[rnum].Exp)]);
  drawengshadowtext(@str[1], x + 100, y + 194, colcolor($7), colcolor($5));
  str := format('%5d', [uint16(Leveluplist[Rrole[rnum].Level - 1])]);
  drawengshadowtext(@str[1], x + 100, y + 215, colcolor($7), colcolor($5));

  //str:=format('%5d', [Rrole[rnum,21]]);
  //drawengshadowtext(@str[1],150,295,colcolor($7),colcolor($5));

  //drawshadowtext(@strs[20, 1], 30, 341, colcolor($23), colcolor($21));
  //drawshadowtext(@strs[21, 1], 30, 362, colcolor($23), colcolor($21));

  //drawrectanglewithoutframe(100,351,Rrole[rnum,19],10,colcolor($16),50);
  //中毒, 受伤
  //str := format('%4d', [RRole[rnum].Hurt]);
  //drawengshadowtext(@str[1], 150, 341, colcolor($14), colcolor($16));
  //str := format('%4d', [RRole[rnum].Poision]);
  //drawengshadowtext(@str[1], 150, 362, colcolor($35), colcolor($37));

  //装备, 秘笈
  drawshadowtext(@strs[17, 1], x + 160, y + 240, colcolor($23), colcolor($21));
  drawshadowtext(@strs[18, 1], x + 360, y + 240, colcolor($23), colcolor($21));
  if Rrole[rnum].Equip[0] >= 0 then
    drawbig5shadowtext(@Ritem[Rrole[rnum].Equip[0]].Name, x + 170, y + 261, colcolor($7), colcolor($5));
  if Rrole[rnum].Equip[1] >= 0 then
    drawbig5shadowtext(@Ritem[Rrole[rnum].Equip[1]].Name, x + 170, y + 282, colcolor($7), colcolor($5));

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
    needexp := mlevel * Ritem[Rrole[rnum].PracticeBook].NeedExp * (7 - Rrole[rnum].Aptitude div 15);
    drawbig5shadowtext(@Ritem[Rrole[rnum].PracticeBook].Name, x + 370, y + 261, colcolor($7), colcolor($5));
    str := format('%5d/%5d', [uint16(Rrole[rnum].ExpForBook), needexp]);
    if mlevel = 10 then str := format('%5d/=', [uint16(Rrole[rnum].ExpForBook)]);
    drawengshadowtext(@str[1], x + 400, y + 282, colcolor($66), colcolor($63));
  end;

  SDL_UpdateRect(screen, x, y, 561, 316);

end;

//离队选单

procedure MenuLeave;
var
  str: widestring;
  i, menu: integer;
begin
  str := ' 要求誰離隊？';
  drawtextwithrect(@str[1], 80, 30, 132, colcolor($23), colcolor($21));
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

end;

//系统选单

procedure MenuSystem;
var
  i, menu, menup: integer;
begin
  menu := 0;
  showmenusystem(menu);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    if where = 3 then break;
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOk, mbCancel], 0) = idOK then Quit;
      SDL_KEYUP:
        begin
          if (event.key.keysym.sym = sdlk_down) then
          begin
            menu := menu + 1;
            if menu > 3 then menu := 0;
            showMenusystem(menu);
          end;
          if (event.key.keysym.sym = sdlk_up) then
          begin
            menu := menu - 1;
            if menu < 0 then menu := 3;
            showMenusystem(menu);
          end;
          if (event.key.keysym.sym = sdlk_escape) then
          begin
            redraw;
            SDL_UpdateRect(screen, 80, 30, 47, 95);
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
                  if fullscreen = 1 then
                    screen := SDL_SetVideoMode(CENTER_X * 2, CENTER_Y * 2, 32, SDL_HWSURFACE or SDL_DOUBLEBUF or SDL_ANYFORMAT)
                  else
                    screen := SDL_SetVideoMode(CENTER_X * 2, CENTER_Y * 2, 32, SDL_FULLSCREEN);
                  fullscreen := 1 - fullscreen;
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
            SDL_UpdateRect(screen, 80, 30, 47, 95);
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
                  if fullscreen = 1 then
                    screen := SDL_SetVideoMode(CENTER_X * 2, CENTER_Y * 2, 32, SDL_HWSURFACE or SDL_DOUBLEBUF or SDL_ANYFORMAT)
                  else
                    screen := SDL_SetVideoMode(CENTER_X * 2, CENTER_Y * 2, 32, SDL_FULLSCREEN);
                  fullscreen := 1 - fullscreen;
                  break;
                end;
            end;
        end;
      SDL_MOUSEMOTION:
        begin
          if (event.button.x >= 80) and (event.button.x < 127) and (event.button.y > 47) and (event.button.y < 120) then
          begin
            menup := menu;
            menu := (event.button.y - 32) div 22;
            if menu > 3 then menu := 3;
            if menu < 0 then menu := 0;
            if menup <> menu then showMenusystem(menu);
          end;
        end;
    end;
  end;

end;

//显示系统选单

procedure ShowMenuSystem(menu: integer);
var
  word: array[0..3] of Widestring;
  i: integer;
begin
  Word[0] := ' 讀取';
  Word[1] := ' 存檔';
  Word[2] := ' 全屏';
  Word[3] := ' 離開';
  if fullscreen = 1 then Word[2] := ' 窗口';
  ReDraw;
  DrawRectangle(80, 30, 46, 92, 0, colcolor(255), 30);
  for i := 0 to 3 do
    if i = menu then
    begin
      drawtext(screen, @word[i][1], 64, 32 + 22 * i, colcolor($64));
      drawtext(screen, @word[i][1], 63, 32 + 22 * i, colcolor($66));
    end
    else begin
      drawtext(screen, @word[i][1], 64, 32 + 22 * i, colcolor($5));
      drawtext(screen, @word[i][1], 63, 32 + 22 * i, colcolor($7));
    end;
  SDL_UpdateRect(screen, 80, 30, 47, 93);

end;

//读档选单

procedure MenuLoad;
var
  menu: integer;
begin
  setlength(menustring, 5);
  setlength(Menuengstring, 0);
  menustring[0] := ' 進度一';
  menustring[1] := ' 進度二';
  menustring[2] := ' 進度三';
  menustring[3] := ' 進度四';
  menustring[4] := ' 進度五';
  menu := commonmenu(133, 30, 67, 4);
  if menu >= 0 then
  begin
    LoadR(menu + 1);
    Redraw;
    sdl_updaterect(screen, 0, 0, screen.w, screen.h);
    ShowMenu(5);
    ShowMenusystem(0);
  end;

end;

//特殊的读档选单, 仅用在开始时读档

procedure MenuLoadAtBeginning;
var
  menu: integer;
begin
  Redraw;
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);
  setlength(menustring, 5);
  setlength(Menuengstring, 0);
  menustring[0] := ' 載入進度一';
  menustring[1] := ' 載入進度二';
  menustring[2] := ' 載入進度三';
  menustring[3] := ' 載入進度四';
  menustring[4] := ' 載入進度五';
  menu := commonmenu(265, 190, 107, 4);
  if menu >= 0 then
  begin
    LoadR(menu + 1);
    where := 0;
    Redraw;
    sdl_updaterect(screen, 0, 0, screen.w, screen.h);
  end;

end;

//存档选单

procedure MenuSave;
var
  menu: integer;
begin
  setlength(menustring, 5);
  menustring[0] := ' 進度一';
  menustring[1] := ' 進度二';
  menustring[2] := ' 進度三';
  menustring[3] := ' 進度四';
  menustring[4] := ' 進度五';
  menu := commonmenu(133, 30, 67, 4);
  if menu >= 0 then SaveR(menu + 1);

end;

//退出选单

procedure MenuQuit;
var
  menu: integer;
begin
  setlength(menustring, 2);
  menustring[0] := ' 取消';
  menustring[1] := ' 確定';
  menu := commonmenu(133, 30, 45, 1);
  if menu = 1 then
  begin
    Quit;
  end;

end;

//医疗的效果
//未添加体力的需求与消耗

procedure EffectMedcine(role1, role2: integer);
var
  word: widestring;
  addlife: integer;
begin
  addlife := Rrole[role1].Medcine * (10 - Rrole[role2].Hurt div 15) div 10;
  if Rrole[role2].Hurt - Rrole[role1].Medcine > 20 then addlife := 0;
  Rrole[role2].Hurt := Rrole[role2].Hurt - addlife div LIFE_HURT;
  if RRole[role2].Hurt < 0 then RRole[role2].Hurt := 0;
  if addlife > RRole[role2].MaxHP - Rrole[role2].CurrentHP then addlife := RRole[role2].MaxHP - Rrole[role2].CurrentHP;
  Rrole[role2].CurrentHP := Rrole[role2].CurrentHP + addlife;
  DrawRectangle(115, 98, 145, 51, 0, colcolor(255), 30);
  word := ' 增加生命';
  drawshadowtext(@word[1], 100, 125, colcolor($7), colcolor($5));
  drawbig5shadowtext(@rrole[role2].Name, 100, 100, colcolor($23), colcolor($21));
  word := format('%3d', [addlife]);
  drawengshadowtext(@word[1], 220, 125, colcolor($66), colcolor($64));
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);
  waitanykey;
  redraw;

end;

//解毒的效果

procedure EffectMedPoision(role1, role2: integer);
var
  word: widestring;
  minuspoi: integer;
begin
  minuspoi := Rrole[role1].MedPoi;
  if minuspoi > Rrole[role2].Poision then minuspoi := Rrole[role2].Poision;
  Rrole[role2].Poision := Rrole[role2].Poision - minuspoi;
  DrawRectangle(115, 98, 145, 51, 0, colcolor(255), 30);
  word := ' 中毒減少';
  drawshadowtext(@word[1], 100, 125, colcolor($7), colcolor($5));
  drawbig5shadowtext(@rrole[role2].Name, 100, 100, colcolor($23), colcolor($21));
  word := format('%3d', [minuspoi]);
  drawengshadowtext(@word[1], 220, 125, colcolor($66), colcolor($64));
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);
  waitanykey;
  redraw;

end;

//使用物品的效果
//练成秘笈的效果

procedure EatOneItem(rnum, inum: integer);
var
  i, p, l, x, y: integer;
  word: array[0..23] of widestring;
  addvalue, rolelist: array[0..23] of integer;
  str: widestring;
begin

  word[0] := ' 增加生命'; word[1] := ' 增加生命最大值'; word[2] := ' 中毒程度';
  word[3] := ' 增加體力'; word[4] := ' 內力門路陰陽合一'; word[5] := ' 增加內力';
  word[6] := ' 增加內力最大值'; word[7] := ' 增加攻擊力'; word[8] := ' 增加輕功';
  word[9] := ' 增加防禦力'; word[10] := ' 增加醫療能力'; word[11] := ' 增加用毒能力';
  word[12] := ' 增加解毒能力'; word[13] := ' 增加抗毒能力'; word[14] := ' 增加拳掌能力';
  word[15] := ' 增加御劍能力'; word[16] := ' 增加耍刀能力'; word[17] := ' 增加特殊兵器';
  word[18] := ' 增加暗器技巧'; word[19] := ' 增加武學常識'; word[20] := ' 增加品德指數';
  word[21] := ' 習得左右互搏'; word[22] := ' 增加攻擊帶毒'; word[23] := ' 受傷程度';
  rolelist[0] := 17; rolelist[1] := 18; rolelist[2] := 20; rolelist[3] := 21;
  rolelist[4] := 40; rolelist[5] := 41; rolelist[6] := 42; rolelist[7] := 43;
  rolelist[8] := 44; rolelist[9] := 45; rolelist[10] := 46; rolelist[11] := 47;
  rolelist[12] := 48; rolelist[13] := 49; rolelist[14] := 50; rolelist[15] := 51;
  rolelist[16] := 52; rolelist[17] := 53; rolelist[18] := 54; rolelist[19] := 55;
  rolelist[20] := 56; rolelist[21] := 58; rolelist[22] := 57; rolelist[23] := 19;
  //rolelist:=(17,18,20,21,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,58,57);
  for i := 0 to 22 do
  begin
    addvalue[i] := Ritem[inum].data[45 + i];
  end;
  //减少受伤
  addvalue[23] := -(addvalue[0] div LIFE_HURT);

  if - addvalue[23] > rrole[rnum].data[19] then addvalue[23] := -rrole[rnum].data[19];

  //增加生命, 内力最大值的处理
  if addvalue[1] + rrole[rnum].data[18] > MAX_HP then
    addvalue[1] := MAX_HP - rrole[rnum].data[18];
  if addvalue[6] + rrole[rnum].data[42] > MAX_MP then
    addvalue[6] := MAX_MP - rrole[rnum].data[42];
  if addvalue[1] + rrole[rnum].data[18] < 0 then
    addvalue[1] := -rrole[rnum].data[18];
  if addvalue[6] + rrole[rnum].data[42] < 0 then
    addvalue[6] := -rrole[rnum].data[42];

  for i := 7 to 22 do
  begin
    if addvalue[i] + rrole[rnum].data[rolelist[i]] > maxprolist[rolelist[i]] then
      addvalue[i] := maxprolist[rolelist[i]] - rrole[rnum].data[rolelist[i]];
    if addvalue[i] + rrole[rnum].data[rolelist[i]] < 0 then
      addvalue[i] := -rrole[rnum].data[rolelist[i]];
  end;
  //生命不能超过最大值
  if addvalue[0] + rrole[rnum].data[17] > addvalue[1] + rrole[rnum].data[18] then
    addvalue[0] := addvalue[1] + rrole[rnum].data[18] - rrole[rnum].data[17];
  //中毒不能小于0
  if addvalue[2] + rrole[rnum].data[20] < 0 then addvalue[2] := -rrole[rnum].data[20];
  //体力不能超过100
  if addvalue[3] + rrole[rnum].data[21] > MAX_PHYSICAL_POWER then addvalue[3] := MAX_PHYSICAL_POWER - rrole[rnum].data[21];
  //内力不能超过最大值
  if addvalue[5] + rrole[rnum].data[41] > addvalue[6] + rrole[rnum].data[42] then
    addvalue[5] := addvalue[6] + rrole[rnum].data[42] - rrole[rnum].data[41];
  p := 0;
  for i := 0 to 23 do
  begin
    if (i <> 4) and (i <> 21) and (addvalue[i] <> 0) then p := p + 1;
  end;
  if (addvalue[4] = 2) and (rrole[rnum].data[40] <> 2) then p := p + 1;
  if (addvalue[21] = 1) and (rrole[rnum].data[58] <> 1) then p := p + 1;

  ShowSimpleStatus(rnum, 350, 50);
  DrawRectangle(100, 70, 200, 25, 0, colcolor(255), 25);
  str := ' 服用';
  if Ritem[inum].ItemType = 2 then str := ' 練成';
  Drawshadowtext(@str[1], 83, 72, colcolor($23), colcolor($21));
  Drawbig5shadowtext(@Ritem[inum].Name, 143, 72, colcolor($66), colcolor($64));

  //如果增加的项超过11个, 分两列显示
  if p < 11 then
  begin
    l := p;
    Drawrectangle(100, 100, 200, 22 * l + 25, 0, colcolor($FF), 25);
  end else
  begin
    l := p div 2 + 1;
    Drawrectangle(100, 100, 400, 22 * l + 25, 0, colcolor($FF), 25);
  end;
  drawbig5shadowtext(@rrole[rnum].data[4], 83, 102, colcolor($23), colcolor($21));
  str := ' 未增加屬性';
  if p = 0 then drawshadowtext(@str[1], 163, 102, colcolor(7), colcolor(5));
  p := 0;
  for i := 0 to 23 do
  begin
    if p < l then
    begin
      x := 0;
      y := 0;
    end else
    begin
      x := 200;
      y := -l * 22;
    end;
    if (i <> 4) and (i <> 21) and (addvalue[i] <> 0) then
    begin
      rrole[rnum].data[rolelist[i]] := rrole[rnum].data[rolelist[i]] + addvalue[i];
      drawshadowtext(@word[i, 1], 83 + x, 124 + y + p * 22, colcolor(7), colcolor(5));
      str := format('%4d', [addvalue[i]]);
      drawengshadowtext(@str[1], 243 + x, 124 + y + p * 22, colcolor($66), colcolor($64));
      p := p + 1;
    end;
    //对内力性质特殊处理
    if (i = 4) and (addvalue[i] = 2) then
    begin
      if rrole[rnum].data[rolelist[i]] <> 2 then
      begin
        rrole[rnum].data[rolelist[i]] := 2;
        drawshadowtext(@word[i, 1], 83 + x, 124 + y + p * 22, colcolor(7), colcolor(5));
        p := p + 1;
      end;
    end;
    //对左右互搏特殊处理
    if (i = 21) and (addvalue[i] = 1) then
    begin
      if rrole[rnum].data[rolelist[i]] <> 1 then
      begin
        rrole[rnum].data[rolelist[i]] := 1;
        drawshadowtext(@word[i, 1], 83 + x, 124 + y + p * 22, colcolor(7), colcolor(5));
        p := p + 1;
      end;
    end;
  end;
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);

end;

//Event.
//事件系统

procedure CallEvent(num: integer);
var
  e: array of smallint;
  i, idx, grp, offset, length, p: integer;
  check: boolean;
begin
  //CurEvent:=num;
  Cx := Sx;
  Cy := Sy;
  Sstep := 1;
  //SDL_EnableKeyRepeat(0, 10);
  idx := fileopen('resource\kdef.idx', fmopenread);
  grp := fileopen('resource\kdef.grp', fmopenread);
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
          instruct_3([e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5], e[i + 6], e[i + 7], e[i + 8], e[i + 9], e[i + 10], e[i + 11], e[i + 12], e[i + 13]]);
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
          i := i + 1;
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
          if p < 622592 then i := i + p
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
    end;
  end;

  event.key.keysym.sym := 0;
  event.button.button := 0;

  InitialScence;
  //if where <> 2 then CurEvent := -1;
  redraw;
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);
  SDL_EnableKeyRepeat(50, 30);

end;

//事件指令含义请参阅其他相关文献

procedure instruct_0;
begin
  redraw;
  //sdl_updaterect(screen,0,0,screen.w,screen.h);

end;

procedure instruct_1(talknum, headnum, dismode: integer);
var
  idx, grp, offset, len, i, p, l, headx, heady, diagx, diagy: integer;
  talkarray: array of byte;
  name: WideString;
begin
  case dismode of
    0:
      begin
        headx := 40;
        heady := 80;
        diagx := 100;
        diagy := 30;
      end;
    1:
      begin
        headx := 546;
        heady := CENTER_Y * 2 - 80;
        diagx := 10;
        diagy := CENTER_Y * 2 - 130;
      end;
    2:
      begin
        headx := -1;
        heady := -1;
        diagx := 100;
        diagy := 30;
      end;
    5:
      begin
        headx := 40;
        heady := CENTER_Y * 2 - 80;
        diagx := 100;
        diagy := CENTER_Y * 2 - 130;
      end;
    4:
      begin
        headx := 546;
        heady := 80;
        diagx := 10;
        diagy := 30;
      end;
    3:
      begin
        headx := -1;
        heady := -1;
        diagx := 100;
        diagy := CENTER_Y * 2 - 130;
      end;
  end;
  idx := fileopen('resource\talk.idx', fmopenread);
  grp := fileopen('resource\talk.grp', fmopenread);
  if talknum = 0 then
  begin
    offset := 0;
    fileread(idx, len, 4);
  end
  else
  begin
    fileseek(idx, (talknum - 1) * 4, 0);
    fileread(idx, offset, 4);
    fileread(idx, len, 4);
  end;
  len := (len - offset);
  setlength(talkarray, len + 1);
  fileseek(grp, offset, 0);
  fileread(grp, talkarray[0], len);
  fileclose(idx);
  fileclose(grp);
  drawrectanglewithoutframe(0, diagy - 10, 640, 120, 0, 40);
  if headx > 0 then drawheadpic(headnum, headx, heady);
  //if headnum <= MAX_HEAD_NUM then
  //begin
    //name := Big5toUnicode(@rrole[headnum].Name);
    //drawshadowtext(@name[1], headx + 20 - length(name) * 10, heady + 5, colcolor($ff), colcolor($0));
  //end;
  for i := 0 to len - 1 do
  begin
    talkarray[i] := talkarray[i] xor $FF;
    if (talkarray[i] = $2A) then
      talkarray[i] := 0;
  end;
  p := 0;
  l := 0;
  for i := 0 to len do
  begin
    if talkarray[i] = 0 then
    begin
      drawbig5shadowtext(@talkarray[p], diagx, diagy + l * 22, colcolor($FF), colcolor($0));
      p := i + 1;
      l := l + 1;
      if (l >= 4) and (i < len) then
      begin
        sdl_updaterect(screen, 0, 0, screen.w, screen.h);
        WaitAnyKey;
        Redraw;
        drawrectanglewithoutframe(0, diagy - 10, 640, 120, 0, 40);
        if headx > 0 then drawheadpic(headnum, headx, heady);
        l := 0;
      end;
    end;
  end;
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);
  waitanykey;
  redraw;

end;

//得到物品可显示数量, 数量为负显示失去物品

procedure instruct_2(inum, amount: integer);
var
  i, x: integer;
  word: widestring;
begin
  i := 0;
  while (RItemList[i].Number >= 0) and (i < MAX_ITEM_AMOUNT) do
  begin
    if (RItemList[i].Number = inum) then
    begin
      RItemList[i].Amount := RItemList[i].Amount + amount;
      if (RItemList[i].Amount < 0) and (amount >= 0) then RItemList[i].Amount := 32767;
      if (RItemList[i].Amount < 0) and (amount < 0) then RItemList[i].Amount := 0;
      break;
    end;
    i := i + 1;
  end;
  if RItemList[i].number < 0 then
  begin
    RItemList[i].Number := inum;
    RItemList[i].Amount := amount;
  end;

  ReArrangeItem;

  x := CENTER_X;
  if where = 2 then x := 190;

  DrawRectangle(x - 75, 98, 145, 76, 0, colcolor(255), 30);
  if amount >= 0 then
    word := ' 得到物品'
  else
    word := ' 失去物品';
  drawshadowtext(@word[1], x - 90, 100, colcolor($23), colcolor($21));
  drawbig5shadowtext(@RItem[inum].Name, x - 90, 125, colcolor($7), colcolor($5));
  word := ' 數量';
  drawshadowtext(@word[1], x - 90, 150, colcolor($66), colcolor($64));
  word := format(' %5d', [amount]);
  drawengshadowtext(@word[1], x - 5, 150, colcolor($66), colcolor($64));
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);
  waitanykey;
  redraw;
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);

end;

procedure ReArrangeItem;
var
  i, p: integer;
  item, amount: array of integer;
begin
  p := 0;
  setlength(item, MAX_ITEM_AMOUNT);
  setlength(amount, MAX_ITEM_AMOUNT);
  for i := 0 to MAX_ITEM_AMOUNT - 1 do
  begin
    if (RItemList[i].Number >= 0) and (RItemList[i].Amount > 0) then
    begin
      item[p] := RItemList[i].Number;
      amount[p] := RItemList[i].Amount;
      p := p + 1;
    end;
  end;
  for i := 0 to MAX_ITEM_AMOUNT - 1 do
  begin
    if i < p then
    begin
      RItemList[i].Number := item[i];
      RItemList[i].Amount := amount[i];
    end
    else begin
      RItemList[i].Number := -1;
      RItemList[i].Amount := 0;
    end;
  end;

end;

//改变事件, 如在当前场景需重置场景
//在需改变贴图较多时效率较低

procedure instruct_3(list: array of integer);
var
  i, i1, i2: integer;
begin
  if list[0] = -2 then list[0] := CurScence;
  if list[1] = -2 then list[1] := CurEvent;
  if list[11] = -2 then list[11] := Ddata[list[0], list[1], 9];
  if list[12] = -2 then list[12] := Ddata[list[0], list[1], 10];
  //这里应该是原本z文件的bug, 如果不处于当前场景, 在连坐标值一起修改时, 并不会同时
  //对S数据进行修改. 而<苍龙逐日>中有几条语句无意中符合了这个bug而造成正确的结果
  //if list[0] = CurScence then
  Sdata[list[0], 3, Ddata[list[0], list[1], 10], Ddata[list[0], list[1], 9]] := -1;
  for i := 0 to 10 do
  begin
    if list[2 + i] <> -2 then
    begin
      Ddata[list[0], list[1], i] := list[2 + i];
    end;
  end;
  //if list[0] = CurScence then
  Sdata[list[0], 3, Ddata[list[0], list[1], 10], Ddata[list[0], list[1], 9]] := list[1];
  //if list[0] = CurScence then
    //UpdateScence(list[12], list[11]);

end;

//是否使用了某剧情物品

function instruct_4(inum, jump1, jump2: integer): integer;
begin
  if inum = CurItem then
    result := jump1
  else
    result := jump2;

end;

//询问是否战斗

function instruct_5(jump1, jump2: integer): integer;
var
  menu: integer;
begin
  setlength(menustring, 3);
  menustring[0] := ' 取消';
  menustring[1] := ' 戰鬥';
  menustring[2] := ' 是否與之戰鬥？';
  drawtextwithrect(@menustring[2][1], CENTER_X - 75, CENTER_Y - 85, 150, colcolor(7), colcolor(5));
  menu := commonmenu2(CENTER_X - 49, CENTER_Y - 50, 98);
  if menu = 1 then result := jump1 else result := jump2;
  redraw;
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);

end;

//战斗

function instruct_6(battlenum, jump1, jump2, getexp: integer): integer;
begin
  result := jump2;
  if Battle(battlenum, getexp) then
    result := jump1;

end;

//询问是否加入

procedure instruct_8(musicnum: integer);
begin
  exitscencemusicnum := musicnum;
end;

function instruct_9(jump1, jump2: integer): integer;
var
  menu: integer;
begin
  setlength(menustring, 3);
  menustring[0] := ' 取消';
  menustring[1] := ' 要求';
  menustring[2] := ' 是否要求加入？';
  drawtextwithrect(@menustring[2][1], CENTER_X - 75, CENTER_Y - 85, 150, colcolor(7), colcolor(5));
  menu := commonmenu2(CENTER_X - 49, CENTER_Y - 50, 98);
  if menu = 1 then result := jump1 else result := jump2;
  redraw;
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);

end;

//加入队友, 同时得到其身上物品

procedure instruct_10(rnum: integer);
var
  i, i1: integer;
begin
  for i := 0 to 5 do
  begin
    if Teamlist[i] < 0 then
    begin
      Teamlist[i] := rnum;
      for i1 := 0 to 3 do
      begin
        if (Rrole[rnum].TakingItem[i1] >= 0) and (Rrole[rnum].TakingItemAmount[i1] > 0) then
        begin
          instruct_2(Rrole[rnum].TakingItem[i1], Rrole[rnum].TakingItemAmount[i1]);
          Rrole[rnum].TakingItem[i1] := -1;
          Rrole[rnum].TakingItemAmount[i1] := 0;
        end;
      end;
      break;
    end;
  end;

end;

//询问是否住宿

function instruct_11(jump1, jump2: integer): integer;
var
  menu: integer;
begin
  setlength(menustring, 3);
  menustring[0] := ' 否';
  menustring[1] := ' 是';
  menustring[2] := ' 是否需要住宿？';
  drawtextwithrect(@menustring[2][1], CENTER_X - 75, CENTER_Y - 85, 150, colcolor(7), colcolor(5));
  menu := commonmenu2(CENTER_X - 49, CENTER_Y - 50, 98);
  if menu = 1 then result := jump1 else result := jump2;
  redraw;
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);

end;

//住宿

procedure instruct_12;
var
  i, rnum: integer;
begin
  for i := 0 to 5 do
  begin
    rnum := Teamlist[i];
    if not ((RRole[rnum].Hurt > 33) or (RRole[rnum].Poision > 0)) then
    begin
      RRole[rnum].CurrentHP := RRole[rnum].MaxHP;
      RRole[rnum].CurrentMP := RRole[rnum].MaxMP;
      RRole[rnum].PhyPower := MAX_PHYSICAL_POWER;
    end;
  end;

end;

//亮屏, 在亮屏之前重新初始化场景

procedure instruct_13;
var
  i: integer;
begin
  //for i1:=0 to 199 do
  //for i2:=0 to 10 do
    //DData[CurScence, [i1,i2]:=Ddata[CurScence,i1,i2];
  InitialScence;
  for i := 0 to 5 do
  begin
    //Sdl_Delay(5);
    Redraw;
    DrawRectangleWithoutFrame(0, 0, screen.w, screen.h, 0, 100 - i * 20);
    sdl_updaterect(screen, 0, 0, screen.w, screen.h);
  end;
end;

//黑屏

procedure instruct_14;
var
  i: integer;
begin
  for i := 0 to 10 do
  begin
    //Redraw;
    Sdl_Delay(10);
    DrawRectangleWithoutFrame(0, 0, screen.w, screen.h, 0, i * 10);
    sdl_updaterect(screen, 0, 0, screen.w, screen.h);
  end;
end;

//失败画面

procedure instruct_15;
var
  i: integer;
  str: widestring;
begin
  where := 3;
  redraw;
  str := ' 勝敗乃兵家常事，但是…';
  drawshadowtext(@str[1], 50, 330, colcolor(255), colcolor(255));
  str := ' 地球上又多了一失蹤人口';
  drawshadowtext(@str[1], 50, 360, colcolor(255), colcolor(255));
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);
  waitanykey;
end;

function instruct_16(rnum, jump1, jump2: integer): integer;
var
  i: integer;
begin
  result := jump2;
  for i := 0 to 5 do
  begin
    if Teamlist[i] = rnum then
    begin
      result := jump1;
      break;
    end;
  end;
end;

procedure instruct_17(list: array of integer);
var
  i1, i2: integer;
begin
  if list[0] = -2 then list[0] := CurScence;
  sdata[list[0], list[1], list[3], list[2]] := list[4];

end;

function instruct_18(inum, jump1, jump2: integer): integer;
var
  i: integer;
begin
  result := jump2;
  for i := 0 to MAX_ITEM_AMOUNT - 1 do
  begin
    if RItemList[i].Number = inum then
    begin
      result := jump1;
      break;
    end;
  end;
end;

procedure instruct_19(x, y: integer);
begin
  Sx := y;
  Sy := x;
  Cx := Sx;
  Cy := Sy;
  Redraw;
end;

//Judge the team is full or not.

function instruct_20(jump1, jump2: integer): integer;
var
  i: integer;
begin
  result := jump1;
  for i := 0 to 5 do
  begin
    if TeamList[i] < 0 then
    begin
      result := jump2;
      break;
    end;
  end;
end;

procedure instruct_21(rnum: integer);
var
  i, p: integer;
  newlist: array[0..5] of integer;
begin
  p := 0;
  for i := 0 to 5 do
  begin
    newlist[i] := -1;
    if Teamlist[i] <> rnum then
    begin
      newlist[p] := Teamlist[i];
      p := p + 1;
    end;
  end;
  for i := 0 to 5 do
    Teamlist[i] := newlist[i];
end;

procedure instruct_22;
var
  i: integer;
begin
  for i := 0 to 5 do
    RRole[Teamlist[i]].CurrentMP := 0;
end;

procedure instruct_23(rnum, Poision: integer);
begin
  RRole[rnum].UsePoi := Poision;
end;

//Black the screen when fail in battle.
//Note: never be used, leave it as blank.

procedure instruct_24;
begin
end;

//Note: never display the leading role.
//This will be improved when I have a better method.

procedure instruct_25(x1, y1, x2, y2: integer);
var
  i, s: integer;
begin
  s := sign(x2 - x1);
  i := x1 + s;
  //showmessage(inttostr(ssx*100+ssy));
  if s <> 0 then
    while s * (x2 - i) >= 0 do
    begin
      sdl_delay(50);
      DrawScenceWithoutRole(y1, i);
      //showmessage(inttostr(i));
      DrawRoleOnScence(y1, i);
      SDL_updaterect(screen, 0, 0, screen.w, screen.h);
      i := i + s;
      //showmessage(inttostr(s*(x2-i)));
    end;
  s := sign(y2 - y1);
  i := y1 + s;
  if s <> 0 then
    while s * (y2 - i) >= 0 do
    begin
      sdl_delay(50);
      DrawScenceWithoutRole(i, x2);
      //showmessage(inttostr(i));
      DrawRoleOnScence(i, x2);
      //Redraw;
      SDL_updaterect(screen, 0, 0, screen.w, screen.h);
      i := i + s;
    end;
  Cx := y2;
  Cy := x2;
  //SSx:=0;
  //SSy:=0;
  //showmessage(inttostr(ssx*100+ssy));
end;

procedure instruct_26(snum, enum, add1, add2, add3: integer);
begin
  if snum = -2 then snum := CurScence;
  ddata[snum, enum, 2] := ddata[snum, enum, 2] + add1;
  ddata[snum, enum, 3] := ddata[snum, enum, 3] + add2;
  ddata[snum, enum, 4] := ddata[snum, enum, 4] + add3;

end;

//Note: of course an more effective engine can take place of it.
//动画, 至今仍不完善

procedure instruct_27(enum, beginpic, endpic: integer);
var
  i, xpoint, ypoint: integer;
  AboutMainRole: boolean;
begin
  AboutMainRole := false;
  if enum = -1 then
  begin
    enum := CurEvent;
    if SData[CurScence, 3, Sx, Sy] >= 0 then
      enum := SData[CurScence, 3, Sx, Sy];
    AboutMainRole := true;
  end;
  if enum = SData[CurScence, 3, Sx, Sy] then AboutMainRole := true;
  SData[CurScence, 3, DData[CurScence, enum, 10], DData[CurScence, enum, 9]] := enum;
  for i := beginpic to endpic do
  begin
    DData[CurScence, enum, 5] := i;
    UpdateScence(DData[CurScence, enum, 10], DData[CurScence, enum, 9]);
    sdl_delay(20);
    DrawScenceWithoutRole(Sx, Sy);
    if not (AboutMainRole) then
      DrawRoleOnScence(Sx, Sy);
    //showmessage(inttostr(enum+100*CurEvent));
    SDL_updaterect(screen, 0, 0, screen.w, screen.h);
  end;
  //showmessage(inttostr(Sx+100*Sy));
  //showmessage(inttostr(DData[CurScence, [enum,10]+100*DData[CurScence, [enum,9]));
  DData[CurScence, enum, 5] := DData[CurScence, enum, 7];
  UpdateScence(DData[CurScence, enum, 10], DData[CurScence, enum, 9]);
end;

function instruct_28(rnum, e1, e2, jump1, jump2: integer): integer;
begin
  result := jump2;
  if (rrole[rnum].Ethics >= e1) and (rrole[rnum].Ethics <= e2) then result := jump1;
end;

function instruct_29(rnum, r1, r2, jump1, jump2: integer): integer;
begin
  result := jump2;
  if (rrole[rnum].Attack >= r1) and (rrole[rnum].Attack <= r2) then result := jump1;
end;

procedure instruct_30(x1, y1, x2, y2: integer);
var
  s: integer;
begin
  s := sign(x2 - x1);
  Sy := x1 + s;
  if s > 0 then Sface := 1;
  if s < 0 then Sface := 2;
  if s <> 0 then
    while s * (x2 - Sy) >= 0 do
    begin
      sdl_delay(50);
      DrawScenceWithoutRole(Sx, Sy);
      SStep := SStep + 1;
      if SStep >= 8 then SStep := 1;
      DrawRoleOnScence(Sx, Sy);
      SDL_updaterect(screen, 0, 0, screen.w, screen.h);
      Sy := Sy + s;
    end;
  s := sign(y2 - y1);
  Sx := y1 + s;
  if s > 0 then Sface := 3;
  if s < 0 then Sface := 0;
  if s <> 0 then
    while s * (y2 - Sx) >= 0 do
    begin
      sdl_delay(50);
      DrawScenceWithoutRole(Sx, Sy);
      SStep := SStep + 1;
      if SStep >= 8 then SStep := 1;
      DrawRoleOnScence(Sx, Sy);
      SDL_updaterect(screen, 0, 0, screen.w, screen.h);
      Sx := Sx + s;
    end;
  Sx := y2;
  Sy := x2;
  SStep := 1;
  Cx := Sx;
  Cy := Sy;
end;

function instruct_31(moneynum, jump1, jump2: integer): integer;
var
  i: integer;
begin
  result := jump2;
  for i := 0 to MAX_ITEM_AMOUNT - 1 do
  begin
    if (RItemList[i].Number = MONEY_ID) and (RItemList[i].Amount >= moneynum) then
    begin
      result := jump1;
      break;
    end;
  end;
end;

procedure instruct_32(inum, amount: integer);
var
  i: integer;
  word: widestring;
begin
  i := 0;
  while (RItemList[i].Number >= 0) and (i < MAX_ITEM_AMOUNT) do
  begin
    if (RItemList[i].Number = inum) then
    begin
      RItemList[i].Amount := RItemList[i].Amount + amount;
      if (RItemList[i].Amount < 0) and (amount >= 0) then RItemList[i].Amount := 32767;
      if (RItemList[i].Amount < 0) and (amount < 0) then RItemList[i].Amount := 0;
      break;
    end;
    i := i + 1;
  end;
  if RItemList[i].Number < 0 then
  begin
    RItemList[i].Number := inum;
    RItemList[i].Amount := amount;
  end;
  ReArrangeItem;
end;

//学到武功, 如果已有武功则升级, 如果已满10个不会洗武功

procedure instruct_33(rnum, magicnum, dismode: integer);
var
  i: integer;
  word: widestring;
begin
  for i := 0 to 9 do
  begin
    if (RRole[rnum].Magic[i] <= 0) or (RRole[rnum].Magic[i] = magicnum) then
    begin
      if RRole[rnum].Magic[i] > 0 then RRole[rnum].Maglevel[i] := RRole[rnum].Maglevel[i] + 100;
      RRole[rnum].Magic[i] := magicnum;
      if RRole[rnum].MagLevel[i] > 999 then RRole[rnum].Maglevel[i] := 999;
      break;
    end;
  end;
  //if i = 10 then rrole[rnum].data[i+63] := magicnum;
  if dismode = 0 then
  begin
    DrawRectangle(CENTER_X - 75, 98, 145, 76, 0, colcolor(255), 30);
    word := ' 學會';
    drawshadowtext(@word[1], CENTER_X - 90, 125, colcolor($7), colcolor($5));
    drawbig5shadowtext(@rrole[rnum].Name, CENTER_X - 90, 100, colcolor($23), colcolor($21));
    drawbig5shadowtext(@Rmagic[magicnum].Name, CENTER_X - 90, 150, colcolor($66), colcolor($64));
    sdl_updaterect(screen, 0, 0, screen.w, screen.h);
    waitanykey;
    redraw;
  end;
end;

procedure instruct_34(rnum, iq: integer);
var
  word: widestring;
begin
  if RRole[rnum].Aptitude + iq <= 100 then
  begin
    RRole[rnum].Aptitude := RRole[rnum].Aptitude + iq;
  end
  else begin
    iq := 100 - RRole[rnum].Aptitude;
    RRole[rnum].Aptitude := 100;
  end;
  if iq > 0 then
  begin
    DrawRectangle(CENTER_X - 75, 98, 145, 51, 0, colcolor(255), 30);
    word := ' 資質增加';
    drawshadowtext(@word[1], CENTER_X - 90, 125, colcolor($7), colcolor($5));
    drawbig5shadowtext(@rrole[rnum].Name, CENTER_X - 90, 100, colcolor($23), colcolor($21));
    word := format('%3d', [iq]);
    drawengshadowtext(@word[1], CENTER_X + 30, 125, colcolor($66), colcolor($64));
    sdl_updaterect(screen, 0, 0, screen.w, screen.h);
    waitanykey;
    redraw;
  end;
end;

procedure instruct_35(rnum, magiclistnum, magicnum, exp: integer);
var
  i: integer;
begin
  if (magiclistnum < 0) or (magiclistnum > 9) then
  begin
    for i := 0 to 9 do
    begin
      if RRole[rnum].Magic[i] <= 0 then
      begin
        RRole[rnum].Magic[i] := magicnum;
        RRole[rnum].MagLevel[i] := exp;
        break;
      end;
    end;
    if i = 10 then
    begin
      RRole[rnum].Magic[0] := magicnum;
      RRole[rnum].MagLevel[i] := exp;
    end;
  end
  else begin
    RRole[rnum].Magic[magiclistnum] := magicnum;
    RRole[rnum].MagLevel[magiclistnum] := exp;
  end;
end;

function instruct_36(sexual, jump1, jump2: integer): integer;
begin
  result := jump2;
  if rrole[0].Sexual = sexual then result := jump1;
  if sexual > 255 then
    if x50[$7000] = 0 then result := jump1 else result := jump2;
end;

procedure instruct_37(Ethics: integer);
begin
  RRole[0].Ethics := RRole[0].Ethics + ethics;
  if RRole[0].Ethics > 100 then RRole[0].Ethics := 100;
  if RRole[0].Ethics < 0 then RRole[0].Ethics := 0;
end;

procedure instruct_38(snum, layernum, oldpic, newpic: integer);
var
  i1, i2: integer;
begin
  if snum = -2 then snum := CurScence;
  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      if Sdata[snum, layernum, i1, i2] = oldpic then Sdata[snum, layernum, i1, i2] := newpic;
    end;
end;

procedure instruct_39(snum: integer);
begin
  Rscence[snum].EnCondition := 0;
end;

procedure instruct_40(director: integer);
begin
  Sface := director;
end;

procedure instruct_41(rnum, inum, amount: integer);
var
  i, p: integer;
begin
  p := 0;
  for i := 0 to 3 do
  begin
    if Rrole[rnum].TakingItem[i] = inum then
    begin
      Rrole[rnum].TakingItemAmount[i] := Rrole[rnum].TakingItemAmount[i] + amount;
      p := 1;
      break;
    end;
  end;
  if p = 0 then
  begin
    for i := 0 to 3 do
    begin
      if Rrole[rnum].TakingItem[i] = -1 then
      begin
        Rrole[rnum].TakingItem[i] := inum;
        Rrole[rnum].TakingItemAmount[i] := amount;
        break;
      end;
    end;
  end;
  for i := 0 to 3 do
  begin
    if Rrole[rnum].TakingItemAmount[i] <= 0 then
    begin
      Rrole[rnum].TakingItem[i] := -1;
      Rrole[rnum].TakingItemAmount[i] := 0;
    end;
  end;

end;

function instruct_42(jump1, jump2: integer): integer;
var
  i: integer;
begin
  result := jump2;
  for i := 0 to 5 do
  begin
    if Rrole[Teamlist[i]].Sexual = 1 then
    begin
      result := jump1;
      break;
    end;
  end;
end;

function instruct_43(inum, jump1, jump2: integer): integer;
var
  i: integer;
begin
  result := jump2;
  for i := 0 to MAX_ITEM_AMOUNT - 1 do
    if RItemList[i].Number = inum then
    begin
      result := jump1;
      break;
    end;
end;

procedure instruct_44(enum1, beginpic1, endpic1, enum2, beginpic2, endpic2: integer);
var
  i: integer;
begin
  SData[CurScence, 3, DData[CurScence, enum1, 10], DData[CurScence, enum1, 9]] := enum1;
  SData[CurScence, 3, DData[CurScence, enum2, 10], DData[CurScence, enum2, 9]] := enum2;
  for i := 0 to endpic1 - beginpic1 do
  begin
    DData[CurScence, enum1, 5] := beginpic1 + i;
    DData[CurScence, enum2, 5] := beginpic2 + i;
    UpdateScence(DData[CurScence, enum1, 10], DData[CurScence, enum1, 9]);
    UpdateScence(DData[CurScence, enum2, 10], DData[CurScence, enum2, 9]);
    sdl_delay(20);
    DrawScenceWithoutRole(Sx, Sy);
    DrawScence;
    SDL_updaterect(screen, 0, 0, screen.w, screen.h);
  end;
  //SData[CurScence, 3, DData[CurScence, [enum,10],DData[CurScence, [enum,9]]:=-1;
end;

procedure instruct_45(rnum, speed: integer);
var
  word: widestring;
begin
  RRole[rnum].Speed := RRole[rnum].Speed + speed;
  DrawRectangle(CENTER_X - 75, 98, 145, 51, 0, colcolor(255), 30);
  word := ' 輕功增加';
  drawshadowtext(@word[1], CENTER_X - 90, 125, colcolor($7), colcolor($5));
  drawbig5shadowtext(@rrole[rnum].Name, CENTER_X - 90, 100, colcolor($23), colcolor($21));
  word := format('%4d', [speed]);
  drawengshadowtext(@word[1], CENTER_X + 20, 125, colcolor($66), colcolor($64));
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);
  waitanykey;
  redraw;
end;

procedure instruct_46(rnum, mp: integer);
var
  word: widestring;
begin
  RRole[rnum].MaxMP := RRole[rnum].MaxMP + mp;
  RRole[rnum].CurrentMP := RRole[rnum].MaxMP;
  DrawRectangle(CENTER_X - 75, 98, 145, 51, 0, colcolor(255), 30);
  word := ' 內力增加';
  drawshadowtext(@word[1], CENTER_X - 90, 125, colcolor($7), colcolor($5));
  drawbig5shadowtext(@rrole[rnum].Name, CENTER_X - 90, 100, colcolor($23), colcolor($21));
  word := format('%4d', [mp]);
  drawengshadowtext(@word[1], CENTER_X + 20, 125, colcolor($66), colcolor($64));
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);
  waitanykey;
  redraw;
end;

procedure instruct_47(rnum, attack: integer);
var
  word: widestring;
begin
  RRole[rnum].Attack := RRole[rnum].Attack + attack;
  DrawRectangle(CENTER_X - 75, 98, 145, 51, 0, colcolor(255), 30);
  word := ' 武力增加';
  drawshadowtext(@word[1], CENTER_X - 90, 125, colcolor($7), colcolor($5));
  drawbig5shadowtext(@rrole[rnum].Name, CENTER_X - 90, 100, colcolor($23), colcolor($21));
  word := format('%4d', [attack]);
  drawengshadowtext(@word[1], CENTER_X + 20, 125, colcolor($66), colcolor($64));
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);
  waitanykey;
  redraw;
end;

procedure instruct_48(rnum, hp: integer);
var
  word: widestring;
begin
  RRole[rnum].MaxHP := RRole[rnum].MaxHP + hp;
  RRole[rnum].CurrentHP := RRole[rnum].MaxHP;
  DrawRectangle(CENTER_X - 75, 98, 145, 51, 0, colcolor(255), 30);
  word := ' 生命增加';
  drawshadowtext(@word[1], CENTER_X - 90, 125, colcolor($7), colcolor($5));
  drawbig5shadowtext(@rrole[rnum].Name, CENTER_X - 90, 100, colcolor($23), colcolor($21));
  word := format('%4d', [hp]);
  drawengshadowtext(@word[1], CENTER_X + 20, 125, colcolor($66), colcolor($64));
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);
  waitanykey;
  redraw;
end;

procedure instruct_49(rnum, MPpro: integer);
begin
  RRole[rnum].MPType := MPpro;
end;

function instruct_50(list: array of integer): integer;
var
  i, p: integer;
  //instruct_50e: function (list1: array of integer): Integer;
begin
  result := 0;
  if list[0] <= 128 then
  begin
    //instruct_50e:='';
    result := instruct_50e(list[0], list[1], list[2], list[3], list[4], list[5], list[6]);
  end
  else begin
    result := list[6];
    p := 0;
    for i := 0 to 4 do
    begin
      p := p + instruct_18(list[i], 1, 0);
    end;
    if p = 5 then result := list[5];
  end;
end;

procedure instruct_51;
begin
  instruct_1(SOFTSTAR_BEGIN_TALK + random(SOFTSTAR_NUM_TALK), $72, 0);
end;

procedure instruct_52;
var
  word: widestring;
begin
  DrawRectangle(CENTER_X - 110, 98, 220, 26, 0, colcolor(255), 30);
  word := ' 你的品德指數為：';
  drawshadowtext(@word[1], CENTER_X - 125, 100, colcolor($7), colcolor($5));
  word := format('%3d', [rrole[0].Ethics]);
  drawengshadowtext(@word[1], CENTER_X + 65, 100, colcolor($66), colcolor($64));
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);
  waitanykey;
  redraw;
end;

procedure instruct_53;
var
  word: widestring;
begin
  DrawRectangle(CENTER_X - 110, 98, 220, 26, 0, colcolor(255), 30);
  word := ' 你的聲望指數為：';
  drawshadowtext(@word[1], CENTER_X - 125, 100, colcolor($7), colcolor($5));
  word := format('%3d', [rrole[0].Repute]);
  drawengshadowtext(@word[1], CENTER_X + 65, 100, colcolor($66), colcolor($64));
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);
  waitanykey;
  redraw;
end;

//Open all scences.
//Note: in primary game, some scences are set to different entrancing condition.

procedure instruct_54;
var
  i: integer;
begin
  for i := 0 to 100 do
  begin
    Rscence[i].EnCondition := 0;
  end;
  Rscence[2].EnCondition := 2;
  Rscence[38].EnCondition := 2;
  Rscence[75].EnCondition := 1;
  Rscence[80].EnCondition := 1;
end;

//Judge the event number.

function instruct_55(enum, value, jump1, jump2: integer): integer;
begin
  result := jump2;
  if DData[CurScence, enum, 2] = value then result := jump1;
end;

//Add repute.
//声望刚刚超过200时家里出现请帖

procedure instruct_56(Repute: integer);
begin
  RRole[0].Repute := RRole[0].Repute + repute;
  if (RRole[0].Repute > 200) and (RRole[0].Repute - repute <= 200) then
  begin
    //showmessage('');
    instruct_3([70, 11, 0, 11, $3A4, -1, -1, $1F20, $1F20, $1F20, 0, 18, 21]);
  end;
end;

{procedure instruct_57;
var
  i: integer;
begin
  for i:=0 to endpic1-beginpic1 do
  begin
    DData[CurScence, [enum1,5]:=beginpic1+i;
    DData[CurScence, [enum2,5]:=beginpic2+i;
    UpdateScence(DData[CurScence, [enum1,10],DData[CurScence, [enum1,9]);
    UpdateScence(DData[CurScence, [enum2,10],DData[CurScence, [enum2,9]);
    sdl_delay(20);
    DrawScenceByCenter(Sx,Sy);
    DrawScence;
    SDL_updaterect(screen,0,0,screen.w,screen.h);
  end;
end;}

procedure instruct_58;
var
  i, p: integer;
begin
  for i := 0 to 14 do
  begin
    p := random(2);
    instruct_1(2854 + i * 2 + p, 0, 3);
    if not (battle(102 + i * 2 + p, 0)) then instruct_15;
    instruct_14;
    instruct_13;
    if i mod 3 = 2 then
    begin
      instruct_1(2891, 0, 3);
      instruct_12;
      instruct_14;
      instruct_13;
    end;
  end;
  instruct_1(2884, 0, 3);
  instruct_1(2885, 0, 3);
  instruct_1(2886, 0, 3);
  instruct_1(2887, 0, 3);
  instruct_1(2888, 0, 3);
  instruct_1(2889, 0, 1);
  instruct_2($8F, 1);

end;

//全员离队, 但未清除相关事件

procedure instruct_59;
var
  i: integer;
begin
  for i := 1 to 5 do
    TeamList[i] := -1;

end;

function instruct_60(snum, enum, pic, jump1, jump2: integer): integer;
begin
  result := jump2;
  if snum = -2 then snum := CurScence;
  if Ddata[snum, enum, 5] = pic then result := jump1;
  //showmessage(inttostr(Ddata[snum,enum,5]));
end;

procedure instruct_62;
var
  i: integer;
  str: widestring;
begin
  where := 3;
  redraw;
  EndAmi;
  //display_img('end.png', 0, 0);
  //where := 3;
end;

procedure EndAmi;
var
  x, y, i, len: integer;
  str: WideString;
  p: integer;
begin
  instruct_14;
  redraw;
  i := fileopen('list\end.txt', fmOpenRead);
  len := fileseek(i, 0, 2);
  fileseek(i, 0, 0);
  setlength(str, len + 1);
  fileread(i, str[1], len);
  fileclose(i);
  p := 1;
  x := 30;
  y := 80;
  drawrectanglewithoutframe(0, 50, CENTER_X * 2, CENTER_Y * 2 - 100, 0, 60);
  for i := 1 to len + 1 do
  begin
    if str[i] = widechar(10) then str[i] := ' ';
    if str[i] = widechar(13) then
    begin
      str[i] := widechar(0);
      drawshadowtext(@str[p], x, y, colcolor($FF), colcolor($FF));
      p := i + 1;
      y := y + 25;
      sdl_updaterect(screen, 0, 0, screen.w, screen.h);
    end;
    if str[i] = widechar($2A) then
    begin
      str[i] := ' ';
      y := 80;
      redraw;
      waitanykey;
      drawrectanglewithoutframe(0, 50, CENTER_X * 2, CENTER_Y * 2 - 100, 0, 60);
    end;
  end;
  waitanykey;
  instruct_14;

end;

//Set sexual.

procedure instruct_63(rnum, sexual: integer);
begin
  RRole[rnum].Sexual := sexual;
end;

//韦小宝的商店

procedure instruct_64;
var
  i, amount, shopnum, menu, price: integer;
  list: array[0..4] of integer;
begin
  setlength(Menustring, 5);
  setlength(Menuengstring, 5);
  amount := 0;
  //任选一个商店, 因未写他去其他客栈的指令
  shopnum := random(5);
  //p:=0;
  for i := 0 to 4 do
  begin
    if Rshop[shopnum].Amount[i] > 0 then
    begin
      menustring[amount] := Big5toUnicode(@Ritem[Rshop[shopnum].Item[i]].Name);
      menuengstring[amount] := format('%10d', [Rshop[shopnum].Price[i]]);
      list[amount] := i;
      amount := amount + 1;
    end;
  end;
  instruct_1($B9E, $6F, 0);
  menu := commonmenu(CENTER_X - 100, 150, 85 + length(menuengstring[0]) * 10, amount - 1);
  if menu >= 0 then
  begin
    menu := list[menu];
    price := Rshop[shopnum].Price[menu];
    if instruct_31(price, 1, 0) = 1 then
    begin
      instruct_2(Rshop[shopnum].Item[menu], 1);
      instruct_32(MONEY_ID, -price);
      Rshop[shopnum].Amount[menu] := Rshop[shopnum].Amount[menu] - 1;
      instruct_1($BA0, $6F, 0);
    end else
      instruct_1($B9F, $6F, 0);
  end;
end;

procedure instruct_66(musicnum: integer);
begin
  stopmp3;
  playmp3(musicnum, -1);
end;

procedure instruct_67(Soundnum: integer);
var
  i: integer;
  //Sound: PMIX_Chunk;
  filename: string;
begin
  filename := 'atk' + format('%2d', [soundnum]) + '.wav';
  for i := 1 to length(filename) do
    if filename[i] = ' ' then filename[i] := '0';
  playsound(pchar(filename), 0);
end;

//50指令中获取变量值

function e_GetValue(bit, t, x: integer): integer;
var
  i: integer;
begin
  i := t and (1 shl bit);
  if i = 0 then result := x else result := x50[x];
end;

//Expanded 50 instructs.

function instruct_50e(code, e1, e2, e3, e4, e5, e6: integer): integer;
var
  i, t1, grp, idx, offset, len, i1, i2: integer;
  p, p1: pchar;
  //ps :pstring;
  str: string;
  word: widestring;
begin
  result := 0;
  case code of
    0: //Give a value to a papameter.
      begin
        x50[e1] := e2;
      end;
    1: //Give a value to one member in parameter group.
      begin
        t1 := e3 + e_getvalue(0, e1, e4);
        x50[t1] := e_getvalue(1, e1, e5);
        if e2 = 1 then x50[t1] := x50[t1] and $FF;
      end;
    2: //Get the value of one member in parameter group.
      begin
        t1 := e3 + e_getvalue(0, e1, e4);
        x50[e5] := x50[t1];
        if e2 = 1 then x50[t1] := x50[t1] and $FF;
      end;
    3: //Basic calculations.
      begin
        t1 := e_getvalue(0, e1, e5);
        case e2 of
          0: x50[e3] := x50[e4] + t1;
          1: x50[e3] := x50[e4] - t1;
          2: x50[e3] := x50[e4] * t1;
          3: x50[e3] := x50[e4] div t1;
          4: x50[e3] := x50[e4] mod t1;
          5: x50[e3] := Uint16(x50[e4]) div t1;
        end;
      end;
    4: //Judge the parameter.
      begin
        x50[$7000] := 0;
        t1 := e_getvalue(0, e1, e4);
        case e2 of
          0: if not (x50[e3] < t1) then x50[$7000] := 1;
          1: if not (x50[e3] <= t1) then x50[$7000] := 1;
          2: if not (x50[e3] = t1) then x50[$7000] := 1;
          3: if not (x50[e3] <> t1) then x50[$7000] := 1;
          4: if not (x50[e3] >= t1) then x50[$7000] := 1;
          5: if not (x50[e3] > t1) then x50[$7000] := 1;
          6: x50[$7000] := 0;
          7: x50[$7000] := 1;
        end;
      end;
    5: //Zero all parameters.
      begin
        for i := -$8000 to $7FFF do
          x50[i] := 0;
      end;
    8: //Read talk to string.
      begin
        t1 := e_getvalue(0, e1, e2);
        idx := fileopen('resource\talk.idx', fmopenread);
        grp := fileopen('resource\talk.grp', fmopenread);
        if t1 = 0 then
        begin
          offset := 0;
          fileread(idx, len, 4);
        end
        else
        begin
          fileseek(idx, (t1 - 1) * 4, 0);
          fileread(idx, offset, 4);
          fileread(idx, len, 4);
        end;
        len := (len - offset);
        fileseek(grp, offset, 0);
        fileread(grp, x50[e3], len);
        fileclose(idx);
        fileclose(grp);
        p := @x50[e3];
        for i := 0 to len - 1 do
        begin
          p^ := char(byte(p^) xor $FF);
          p := p + 1;
        end;
        p^ := char(0);
        //x50[e3+i]:=0;
      end;
    9: //Format the string.
      begin
        e4 := e_getvalue(0, e1, e4);
        p := @x50[e2];
        p1 := @x50[e3];
        str := p1;
        str := format(string(p1), [e4]);
        for i := 0 to length(str) do
        begin
          p^ := str[i + 1];
          p := p + 1;
        end;
      end;
    10: //Get the length of a string.
      begin
        x50[e2] := length(pchar(@x50[e1]));
        //showmessage(inttostr(x50[e2]));
      end;
    11: //Combine 2 strings.
      begin
        p := @x50[e1];
        p1 := @x50[e2];
        for i := 0 to length(p1) - 1 do
        begin
          p^ := (p1 + i)^;
          p := p + 1;
        end;
        p1 := @x50[e3];
        for i := 0 to length(p1) do
        begin
          p^ := (p1 + i)^;
          p := p + 1;
        end;
        //p^:=char(0);
      end;
    12: //Build a string with spaces.
      //Note: here the width of one 'space' is the same as one Chinese charactor.
      begin
        e3 := e_getvalue(0, e1, e3);
        p := @x50[e2];
        for i := 0 to e3 do
        begin
          p^ := char($20);
          p := p + 1;
        end;
        p^ := char(0);
      end;
    16: //Write R data.
      begin
        e3 := e_getvalue(0, e1, e3);
        e4 := e_getvalue(1, e1, e4);
        e5 := e_getvalue(2, e1, e5);
        case e2 of
          0: Rrole[e3].Data[e4 div 2] := e5;
          1: Ritem[e3].Data[e4 div 2] := e5;
          2: Rscence[e3].Data[e4 div 2] := e5;
          3: Rmagic[e3].Data[e4 div 2] := e5;
          4: Rshop[e3].Data[e4 div 2] := e5;
        end;
      end;
    17: //Read R data.
      begin
        e3 := e_getvalue(0, e1, e3);
        e4 := e_getvalue(1, e1, e4);
        case e2 of
          0: x50[e5] := Rrole[e3].Data[e4 div 2];
          1: x50[e5] := Ritem[e3].Data[e4 div 2];
          2: x50[e5] := Rscence[e3].Data[e4 div 2];
          3: x50[e5] := Rmagic[e3].Data[e4 div 2];
          4: x50[e5] := Rshop[e3].Data[e4 div 2];
        end;
      end;
    18: //Write team data.
      begin
        e2 := e_getvalue(0, e1, e2);
        e3 := e_getvalue(1, e1, e3);
        TeamList[e2] := e3;
        //showmessage(inttostr(e3));
      end;
    19: //Read team data.
      begin
        e2 := e_getvalue(0, e1, e2);
        x50[e3] := TeamList[e2];
      end;
    20: //Get the amount of one item.
      begin
        e2 := e_getvalue(0, e1, e2);
        x50[e3] := 0;
        for i := 0 to MAX_ITEM_AMOUNT - 1 do
          if RItemList[i].Number = e2 then
          begin
            x50[e3] := RItemList[i].Amount;
            break;
          end;
        //showmessage('rer');
      end;
    21: //Write event in scence.
      begin
        e2 := e_getvalue(0, e1, e2);
        e3 := e_getvalue(1, e1, e3);
        e4 := e_getvalue(2, e1, e4);
        e5 := e_getvalue(3, e1, e5);
        Ddata[e2, e3, e4] := e5;
        //if e2=CurScence then DData[CurScence, [e3,e4]:=e5;
        //InitialScence;
        //Redraw;
        //sdl_updaterect(screen,0,0,screen.w,screen.h);
      end;
    22:
      begin
        e2 := e_getvalue(0, e1, e2);
        e3 := e_getvalue(1, e1, e3);
        e4 := e_getvalue(2, e1, e4);
        x50[e5] := Ddata[e2, e3, e4];
      end;
    23:
      begin
        e2 := e_getvalue(0, e1, e2);
        e3 := e_getvalue(1, e1, e3);
        e4 := e_getvalue(2, e1, e4);
        e5 := e_getvalue(3, e1, e5);
        e6 := e_getvalue(4, e1, e6);
        Sdata[e2, e3, e5, e4] := e6;
        //if e2=CurScence then SData[CurScence, 3, e5,e4]:=e6;;
        //InitialScence;
        //Redraw;
        //sdl_updaterect(screen,0,0,screen.w,screen.h);
      end;
    24:
      begin
        e2 := e_getvalue(0, e1, e2);
        e3 := e_getvalue(1, e1, e3);
        e4 := e_getvalue(2, e1, e4);
        e5 := e_getvalue(3, e1, e5);
        x50[e6] := Sdata[e2, e3, e5, e4];
        //showmessage(inttostr(sface));
      end;
    25:
      begin
        e5 := e_getvalue(0, e1, e5);
        e6 := e_getvalue(1, e1, e6);
        t1 := uint16(e3) + uint16(e4) * $10000 + uint16(e6);
        i := uint16(e3) + uint16(e4) * $10000;
        case t1 of
          $1D295A: Sx := e5;
          $1D295C: Sy := e5;
          //$1D2956: Cx := e5;
          //$1D2958: Cy := e5;
          //$0544f2:
        end;
        case i of
          $18FE2C:
            begin
              if e6 mod 4 <= 1 then
                Ritemlist[e6 div 4].Number := e5
              else
                Ritemlist[e6 div 4].Amount := e5;
            end;
        end;
        case i of
          $051C83:
            begin
              Acol[e6] := e5 mod 256;
              Acol[e6 + 1] := e5 div 256;
            end;
        end;
        //redraw;
        sdl_updaterect(screen, 0, 0, screen.w, screen.h);
      end;
    26:
      begin
        e6 := e_getvalue(0, e1, e6);
        t1 := uint16(e3) + uint16(e4) * $10000 + uint(e6);
        i := uint16(e3) + uint16(e4) * $10000;
        case t1 of
          $1D295E: x50[e5] := CurScence;
          $1D295A: x50[e5] := Sx;
          $1D295C: x50[e5] := Sy;
          $1C0B88: x50[e5] := Mx;
          $1C0B8C: x50[e5] := My;
          //$1D2956: x50[e5] := Cx;
          //$1D2958: x50[e5] := Cy;
          $05B53A: x50[e5] := 1;
          $0544F2: x50[e5] := Sface;
        end;
        if (t1 - $18FE2C >= 0) and (t1 - $18FE2C < 800) then
        begin
          i := t1 - $18FE2C;
          //showmessage(inttostr(e3));
          if i mod 4 <= 1 then
            x50[e5] := Ritemlist[i div 4].Number
          else
            x50[e5] := Ritemlist[i div 4].Amount;
        end;

      end;
    27: //Read name to string.
      begin
        e3 := e_getValue(0, e1, e3);
        p := @x50[e4];
        case e2 of
          0: p1 := @Rrole[e3].Name;
          1: p1 := @Ritem[e3].Name;
          2: p1 := @Rscence[e3].Name;
          3: p1 := @Rmagic[e3].Name;
        end;
        for i := 0 to 9 do
        begin
          (p + i)^ := (p1 + i)^;
          if (p1 + i)^ = char(0) then break;
        end;
        (p + i)^ := char($20);
        (p + i + 1)^ := char(0);
      end;
    28: //Get the battle number.
      begin
        x50[e1] := x50[28005];
      end;
    29: //Select aim.
      begin
        e2 := e_getvalue(0, e1, e2);
        e3 := e_getvalue(1, e1, e3);
        if e5 = 0 then
        begin
          //showmessage('IN CASE');
          selectaim(e2, e3);
        end;
        x50[e4] := bfield[2, Ax, Ay];
      end;
    30: //Read battle properties.
      begin
        e2 := e_getvalue(0, e1, e2);
        e3 := e_getvalue(1, e1, e3);
        x50[e4] := brole[e2].data[e3 div 2];
      end;
    31: //Write battle properties.
      begin
        e2 := e_getvalue(0, e1, e2);
        e3 := e_getvalue(1, e1, e3);
        e4 := e_getvalue(2, e1, e4);
        brole[e2].Data[e3 div 2] := e4;
      end;
    32: //Modify next instruct.
      begin
        e3 := e_getvalue(0, e1, e3);
        result := 655360 * (e3 + 1) + x50[e2];
        //showmessage(inttostr(result));
      end;
    33: //Draw a string.
      begin
        e3 := e_getvalue(0, e1, e3);
        e4 := e_getvalue(1, e1, e4);
        e5 := e_getvalue(2, e1, e5);
        //showmessage(inttostr(e5));
        i := 0;
        t1 := 0;
        p := @x50[e2];
        p1 := p;
        while byte(p^) > 0 do
        begin
          if byte(p^) = $2A then
          begin
            p^ := char(0);
            drawbig5shadowtext(p1, e3 - 22, e4 + 22 * i - 25, colcolor(e5 and $FF), colcolor((e5 and $FF00) shl 8));
            i := i + 1;
            p1 := p + 1;
          end;
          p := p + 1;
        end;
        drawbig5shadowtext(p1, e3 - 22, e4 + 22 - 25, colcolor(e5 and $FF), colcolor((e5 and $FF00) shl 8));
        sdl_updaterect(screen, 0, 0, screen.w, screen.h);
        //waitanykey;
      end;
    34: //Draw a rectangle as background.
      begin
        e2 := e_getvalue(0, e1, e2);
        e3 := e_getvalue(1, e1, e3);
        e4 := e_getvalue(2, e1, e4);
        e5 := e_getvalue(3, e1, e5);
        Drawrectangle(e2, e3, e4, e5, 0, colcolor($FF), 40);
        //sdl_updaterect(screen,e1,e2,e3+1,e4+1);
      end;
    35: //Pause and wait a key.
      begin
        i := waitanykey;
        x50[e1] := i;
        case i of
          sdlk_left: x50[e1] := 154;
          sdlk_right: x50[e1] := 156;
          sdlk_up: x50[e1] := 158;
          sdlk_down: x50[e1] := 152;
        end;
      end;
    36: //Draw a string with background then pause, if the key pressed is 'Y' then jump=0.
      begin
        e3 := e_getvalue(0, e1, e3);
        e4 := e_getvalue(1, e1, e4);
        e5 := e_getvalue(2, e1, e5);
        //word := big5tounicode(@x50[e2]);
        //t1 := length(word);
        //drawtextwithrect(@word[1], e3, e4, t1 * 20 - 15, colcolor(e5 and $FF), colcolor((e5 and $FF00) shl 8));
        p := @x50[e2];
        i1 := 1;
        i2 := 0;
        t1 := 0;
        while byte(p^) > 0 do
        begin
          //showmessage('');
          if byte(p^) = $2A then
          begin
            if t1 > i2 then i2 := t1;
            t1 := 0;
            i1 := i1 + 1;
          end;
          if byte(p^) = $20 then t1 := t1 + 1;
          p := p + 1;
          t1 := t1 + 1;
        end;
        if t1 > i2 then i2 := t1;
        p := p - 1;
        if i1 = 0 then i1 := 1;
        if byte(p^) = $2A then i1 := i1 - 1;
        DrawRectangle(e3, e4, i2 * 10 + 25, i1 * 22 + 5, 0, colcolor(255), 30);
        p := @x50[e2];
        p1 := p;
        i := 0;
        while byte(p^) > 0 do
        begin
          if byte(p^) = $2A then
          begin
            p^ := char(0);
            drawbig5shadowtext(p1, e3 - 17, e4 + 22 * i + 2, colcolor(e5 and $FF), colcolor((e5 and $FF00) shl 8));
            i := i + 1;
            p1 := p + 1;
          end;
          p := p + 1;
        end;
        drawbig5shadowtext(p1, e3 - 17, e4 + 22 * i + 2, colcolor(e5 and $FF), colcolor((e5 and $FF00) shl 8));
        sdl_updaterect(screen, 0, 0, screen.w, screen.h);
        i := waitanykey;
        if i = sdlk_y then x50[$7000] := 0 else x50[$7000] := 1;
        //redraw;
      end;
    37: //Delay.
      begin
        e2 := e_getvalue(0, e1, e2);
        sdl_delay(e2);
      end;
    38: //Get a number randomly.
      begin
        e2 := e_getvalue(0, e1, e2);
        x50[e3] := random(e2);
      end;
    39: //Show a menu to select. The 40th instruct is too complicable, just use the 30th.
      begin
        e2 := e_getvalue(0, e1, e2);
        e5 := e_getvalue(1, e1, e5);
        e6 := e_getvalue(2, e1, e6);
        setlength(menustring, e2);
        setlength(menuengstring, 0);
        t1 := 0;
        for i := 0 to e2 - 1 do
        begin
          menustring[i] := big5tounicode(@x50[x50[e3 + i]]);
          i1 := length(pchar(@x50[x50[e3 + i]]));
          if i1 > t1 then t1 := i1;
        end;
        x50[e4] := commonmenu(e5, e6, t1 * 10 + 3, e2 - 1) + 1;
      end;
    40: //Show a menu to select. The 40th instruct is too complicable, just use the 30th.
      begin
        e2 := e_getvalue(0, e1, e2);
        e5 := e_getvalue(1, e1, e5);
        e6 := e_getvalue(2, e1, e6);
        setlength(menustring, e2);
        setlength(menuengstring, 0);
        i2 := 0;
        for i := 0 to e2 - 1 do
        begin
          menustring[i] := big5tounicode(@x50[x50[e3 + i]]);
          i1 := length(pchar(@x50[x50[e3 + i]]));
          if i1 > i2 then i2 := i1;
        end;
        t1 := (e1 shr 8) and $FF;
        if t1 = 0 then t1 := 5;
        //showmessage(inttostr(t1));
        x50[e4] := commonscrollmenu(e5, e6, i2 * 10 + 3, e2 - 1, t1) + 1;
      end;
    41: //Draw a picture.
      begin
        e3 := e_getvalue(0, e1, e3);
        e4 := e_getvalue(1, e1, e4);
        e5 := e_getvalue(2, e1, e5);
        case e2 of
          0:
            begin
              if where = 1 then DrawSPic(e5 div 2, e3, e4, 0, 0, screen.w, screen.h)
              else DrawMPic(e5 div 2, e3, e4);
            end;
          1: DrawHeadPic(e5, e3, e4);
          2:
            begin
              str := 'pic\' + inttostr(e5) + '.png';
              display_img(@str[1], e3, e4);
            end;
        end;
        sdl_updaterect(screen, 0, 0, screen.w, screen.h);
      end;
    42: //Change the poistion on world map.
      begin
        e2 := e_getvalue(0, e1, e2);
        e3 := e_getvalue(0, e1, e3);
        Mx := e3;
        My := e2;
      end;
    43: //Call another event.
      begin
        e2 := e_getvalue(0, e1, e2);
        e3 := e_getvalue(1, e1, e3);
        e4 := e_getvalue(2, e1, e4);
        e5 := e_getvalue(3, e1, e5);
        e6 := e_getvalue(4, e1, e6);
        x50[$7100] := e3;
        x50[$7101] := e4;
        x50[$7102] := e5;
        x50[$7103] := e6;
        if e2 = 202 then
        begin
          if e5 = 0 then instruct_2(e3, e4) else instruct_32(e3, e4);
        end
        else
          callevent(e2);
        //showmessage(inttostr(e2));
      end;
    44: //Play amination.
      begin
        e2 := e_getvalue(0, e1, e2);
        e3 := e_getvalue(1, e1, e3);
        e4 := e_getvalue(2, e1, e4);
        playActionAmination(e2, e3);
        playMagicAmination(e2, e4);
      end;
    45: //Show values.
      begin
        e2 := e_getvalue(0, e1, e2);
        showhurtvalue(e2);
      end;
    46: //Set effect layer.
      begin
        e2 := e_getvalue(0, e1, e2);
        e3 := e_getvalue(1, e1, e3);
        e4 := e_getvalue(2, e1, e4);
        e5 := e_getvalue(3, e1, e5);
        e6 := e_getvalue(4, e1, e6);
        for i1 := e2 to e2 + e4 - 1 do
          for i2 := e3 to e3 + e5 - 1 do
            bfield[4, i1, i2] := e6;
      end;
    47: //Here no need to re-set the pic.
      begin
      end;
    48: //Show some parameters.
      begin
        str := '';
        for i := e1 to e1 + e2 - 1 do
          str := str + 'x' + inttostr(i) + '=' + inttostr(x50[i]) + char(13) + char(10);
        messagebox(0, @str[1], 'KYS Windows', MB_OK);
      end;
    49: //In PE files, you can't call any procedure as your wish.
      begin
      end;
  end;

end;

//Battle.
//战斗, 返回值为是否胜利

function Battle(battlenum, getexp: integer): boolean;
var
  i, SelectTeamList, x, y: integer;
begin
  Bstatus := 0;
  CurrentBattle := battlenum;
  if InitialBField then
  begin
    //如果未发现自动战斗设定, 则选择人物
    SelectTeamList := SelectTeamMembers;
    for i := 0 to 5 do
    begin
      y := warsta[21 + i];
      x := warsta[27 + i];
      if SelectTeamList and (1 shl i) > 0 then
      begin
        Brole[BRoleAmount].rnum := TeamList[i];
        Brole[BRoleAmount].Team := 0;
        Brole[BRoleAmount].Y := y;
        Brole[BRoleAmount].X := x;
        Brole[BRoleAmount].Face := 2;
        Brole[BRoleAmount].Dead := 0;
        Brole[BRoleAmount].Step := 0;
        Brole[BRoleAmount].Acted := 0;
        Brole[BRoleAmount].ExpGot := 0;
        Brole[BRoleAmount].Auto := 0;
        BRoleAmount := BRoleAmount + 1;
      end;
    end;
    for i := 0 to 5 do
    begin
      y := warsta[21 + i] + 1;
      x := warsta[27 + i];
      if (warsta[9 + i] > 0) and (instruct_16(warsta[9 + i], 1, 0) = 0) then
      begin
        Brole[BRoleAmount].rnum := warsta[9 + i];
        Brole[BRoleAmount].Team := 0;
        Brole[BRoleAmount].Y := y;
        Brole[BRoleAmount].X := x;
        Brole[BRoleAmount].Face := 2;
        Brole[BRoleAmount].Dead := 0;
        Brole[BRoleAmount].Step := 0;
        Brole[BRoleAmount].Acted := 0;
        Brole[BRoleAmount].ExpGot := 0;
        Brole[BRoleAmount].Auto := 0;
        BRoleAmount := BRoleAmount + 1;
      end;
    end;
  end;
  instruct_14;
  Where := 2;
  initialwholeBfield; //初始化场景
  stopMP3;
  playmp3(warsta[8], -1);
  BattleMainControl;

  RestoreRoleStatus;

  if (bstatus = 1) or ((bstatus = 2) and (getexp <> 0)) then
  begin
    AddExp;
    CheckLevelUp;
    CheckBook;
  end;

  sdl_updaterect(screen, 0, 0, screen.w, screen.h);

  if Rscence[CurScence].EntranceMusic >= 0 then
  begin
    stopmp3;
    playmp3(Rscence[CurScence].EntranceMusic, -1);
  end;

  Where := 1;
  if bstatus = 1 then result := true
  else result := false;

end;

//选择人物, 返回值为整型, 按bit表示人物是否参战

function SelectTeamMembers: integer;
var
  i, menu, max, menup: integer;
begin
  result := 0;
  max := 0;
  menu := 0;
  setlength(menustring, 7);
  for i := 0 to 5 do
  begin
    if Teamlist[i] >= 0 then
    begin
      menustring[i] := Big5toUnicode(@RRole[Teamlist[i]].Name);
      max := max + 1;
    end;
  end;
  menustring[max] := '    開始戰鬥';
  ShowMultiMenu(max, 0, 0);
  sdl_enablekeyrepeat(0, 0);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOk, mbCancel], 0) = idOK then Quit;
      SDL_KEYUP:
        begin
          if ((event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space)) and (menu <> max) then
          begin
            //选中人物则反转对应bit
            result := result xor (1 shl menu);
            ShowMultiMenu(max, menu, result);
          end;
          if ((event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space)) and (menu = max) then
          begin
            if result <> 0 then break;
          end;
          if (event.key.keysym.sym = sdlk_up) then
          begin
            menu := menu - 1;
            if menu < 0 then menu := max;
            ShowMultiMenu(max, menu, result);
          end;
          if (event.key.keysym.sym = sdlk_down) then
          begin
            menu := menu + 1;
            if menu > max then menu := 0;
            ShowMultiMenu(max, menu, result);
          end;
        end;
      SDL_MOUSEBUTTONUP:
        begin
          if (event.button.button = sdl_button_left) and (menu <> max) then
          begin
            result := result xor (1 shl menu);
            ShowMultiMenu(max, menu, result);
          end;
          if (event.button.button = sdl_button_left) and (menu = max) then
          begin
            if result <> 0 then break;
          end;
        end;
      SDL_MOUSEMOTION:
        begin
          if (event.button.x >= CENTER_X - 75) and (event.button.x < CENTER_X + 75) and (event.button.y >= 150) and (event.button.y < max * 22 + 178) then
          begin
            menup := menu;
            menu := (event.button.y - 152) div 22;
            if menup <> menu then ShowMultiMenu(max, menu, result);
          end;
        end;
    end;
  end;

end;

//显示选择参战人物选单

procedure ShowMultiMenu(max, menu, status: integer);
var
  i, x, y: integer;
  str, str1, str2: widestring;
begin
  x := CENTER_X - 105;
  y := 150;
  ReDraw;
  str := ' 選擇參與戰鬥之人物';
  str1 := ' 參戰';
  //Drawtextwithrect(@str[1],x,y-35,200,colcolor($23),colcolor($21));
  DrawRectangle(x + 30, y, 150, max * 22 + 28, 0, colcolor(255), 30);
  for i := 0 to max do
    if i = menu then
    begin
      drawshadowtext(@menustring[i][1], x + 13, y + 3 + 22 * i, colcolor($66), colcolor($64));
      if (status and (1 shl i)) > 0 then
        drawshadowtext(@str1[1], x + 113, y + 3 + 22 * i, colcolor($66), colcolor($64));
    end
    else begin
      drawshadowtext(@menustring[i][1], x + 13, y + 3 + 22 * i, colcolor($7), colcolor($5));
      if (status and (1 shl i)) > 0 then
        drawshadowtext(@str1[1], x + 113, y + 3 + 22 * i, colcolor($23), colcolor($21));
    end;
  sdl_updaterect(screen, x + 30, y, 151, max * 22 + 28 + 1);
end;

//Structure of Bfield arrays:
//0: Ground; 1: Building; 2: Roles(Rrnum);

//Structure of Brole arrays:
//the 1st pointer is "Battle Num";
//The 2nd: 0: rnum, 1: Friend or enemy, 2: y, 3: x, 4: Face, 5: Dead or alive,
//         7: Acted, 8: Pic Num, 9: The number, 10, 11, 12: Auto, 13: Exp gotten.
//初始化战场

function InitialBField: boolean;
var
  sta, grp, idx, offset, i, i1, i2, x, y, fieldnum: integer;
begin
  sta := fileopen('resource\war.sta', fmopenread);
  offset := currentbattle * $BA;
  fileseek(sta, offset, 0);
  fileread(sta, warsta, $BA);
  fileclose(sta);
  fieldnum := warsta[6];
  if fieldnum = 0 then offset := 0
  else begin
    idx := fileopen('resource\warfld.idx', fmopenread);
    fileseek(idx, (fieldnum - 1) * 4, 0);
    fileread(idx, offset, 4);
    fileclose(idx);
  end;
  grp := fileopen('resource\warfld.grp', fmopenread);
  fileseek(grp, offset, 0);
  fileread(grp, Bfield[0, 0, 0], 2 * 64 * 64 * 2);
  fileclose(grp);
  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
      Bfield[2, i1, i2] := -1;
  BRoleAmount := 0;
  result := true;
  //我方自动参战数据
  for i := 0 to 5 do
  begin
    y := warsta[21 + i];
    x := warsta[27 + i];
    if warsta[15 + i] >= 0 then
    begin
      Brole[BRoleAmount].rnum := warsta[15 + i];
      Brole[BRoleAmount].Team := 0;
      Brole[BRoleAmount].Y := y;
      Brole[BRoleAmount].X := x;
      Brole[BRoleAmount].Face := 2;
      Brole[BRoleAmount].Dead := 0;
      Brole[BRoleAmount].Step := 0;
      Brole[BRoleAmount].Acted := 0;
      Brole[BRoleAmount].ExpGot := 0;
      Brole[BRoleAmount].Auto := 0;
      BRoleAmount := BRoleAmount + 1;
    end;
  end;
  //如没有自动参战人物, 返回假, 激活选择人物
  if BRoleAmount > 0 then result := False;
  for i := 0 to 19 do
  begin
    y := warsta[53 + i];
    x := warsta[73 + i];
    if warsta[33 + i] >= 0 then
    begin
      Brole[BRoleAmount].rnum := warsta[33 + i];
      Brole[BRoleAmount].Team := 1;
      Brole[BRoleAmount].Y := y;
      Brole[BRoleAmount].X := x;
      Brole[BRoleAmount].Face := 1;
      Brole[BRoleAmount].Dead := 0;
      Brole[BRoleAmount].Step := 0;
      Brole[BRoleAmount].Acted := 0;
      Brole[BRoleAmount].ExpGot := 0;
      Brole[BRoleAmount].Auto := 0;
      BRoleAmount := BRoleAmount + 1;
    end;
  end;

end;

//画战场

procedure DrawWholeBField;
var
  i, i1, i2: integer;
begin
  if (SDL_MustLock(screen)) then
  begin
    if (SDL_LockSurface(screen) < 0) then
    begin
      MessageBox(0, PChar(Format('Can''t lock screen : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
  end;
  DrawBFieldWithoutRole(Bx, By);

  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      if (Bfield[2, i1, i2] >= 0) and (Brole[Bfield[2, i1, i2]].Dead = 0) then
        DrawRoleOnBfield(i1, i2);
    end;
  if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;
end;

//画战场上人物, 需更新人物身前的遮挡

procedure DrawRoleOnBfield(x, y: integer);
var
  i1, i2, xpoint, ypoint: integer;
  pos, pos1: Tposition;
begin
  if (SDL_MustLock(screen)) then
  begin
    if (SDL_LockSurface(screen) < 0) then
    begin
      MessageBox(0, PChar(Format('Can''t lock screen : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
  end;

  pos := GetPositionOnScreen(x, y, Bx, By);
  for i1 := x - 1 to x + 10 do
    for i2 := y - 1 to y + 10 do
    begin
      if (i1 = x) and (i2 = y) then
        DrawBPic(Rrole[Brole[Bfield[2, x, y]].rnum].HeadNum * 4 + Brole[Bfield[2, x, y]].Face + BEGIN_BATTLE_ROLE_PIC, pos.x, pos.y, 0);

      if (Bfield[1, i1, i2] > 0) then
      begin
        pos1 := GetPositionOnScreen(i1, i2, Bx, By);
        DrawBPicInRect(Bfield[1, i1, i2] div 2, pos1.x, pos1.y, 0, pos.x - 20, pos.y - 60, 40, 60);
        if (Bfield[2, i1, i2] >= 0) and (Brole[Bfield[2, i1, i2]].Dead = 0) then
          DrawBPicInRect(Rrole[Brole[Bfield[2, x, y]].rnum].HeadNum * 4 + Brole[Bfield[2, i1, i2]].Face + BEGIN_BATTLE_ROLE_PIC, pos1.x, pos1.y, 0, pos.x - 20, pos.y - 60, 40, 60);
      end;
    end;

  if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;

end;

//初始化战场映像

procedure InitialWholeBField;
var
  i1, i2, x, y: integer;
begin
  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      x := -i1 * 18 + i2 * 18 + 1151;
      y := i1 * 9 + i2 * 9 + 9;
      if (i1 < 0) or (i2 < 0) or (i1 > 63) or (i2 > 63) then InitialBPic(0, x, y)
      else begin
        InitialBPic(bfield[0, i1, i2] div 2, x, y);
        if (bfield[1, i1, i2] > 0) then
          InitialBPic(bfield[1, i1, i2] div 2, x, y);
      end;
    end;

end;

//战斗主控制

procedure BattleMainControl;
var
  i: integer;
begin
  //redraw;
  //战斗未分出胜负则继续
  while BStatus = 0 do
  begin
    CalMoveAbility; //计算移动能力
    ReArrangeBRole; //排列角色顺序

    ClearDeadRolePic; //清除阵亡角色

    //是否已行动, 显示数字清空
    for i := 0 to broleamount - 1 do
    begin
      Brole[i].Acted := 0;
      Brole[i].ShowNumber := 0;
    end;

    i := 0;
    while (i < broleamount) and (Bstatus = 0) do
    begin
      //当前人物位置作为屏幕中心
      Bx := Brole[i].X;
      By := Brole[i].Y;
      redraw;

      //战场序号保存至变量28005
      x50[28005] := i;
      //为我方且未阵亡, 非自动战斗, 则显示选单
      if (Brole[i].Dead = 0) then
      begin
        if (Brole[i].Team = 0) and (Brole[i].Auto = 0) then
        begin
          case BattleMenu(i) of
            0: Move(i);
            1: Attack(i);
            2: UsePoision(i);
            3: MedPoision(i);
            4: Medcine(i);
            5: BattleMenuItem(i);
            6: Wait(i);
            //状态改为仅能查看自己
            7:
              begin
                ShowStatus(Brole[i].rnum);
                waitanykey;
              end;
            8: Rest(i);
            9:
              begin
                Brole[i].Auto := 1;
                AutoBattle(i);
                Brole[i].Acted := 1;
              end;
          end;
        end
        else begin
          AutoBattle(i);
          Brole[i].Acted := 1;
        end;
      end
      else Brole[i].Acted := 1;

      ClearDeadRolePic;
      redraw;
      Bstatus := BattleStatus;

      if Brole[i].Acted = 1 then
        i := i + 1;
      //showmessage(inttostr(i));
    end;
    CalPoiHurtLife; //计算中毒损血

  end;

end;

//按轻功重排人物(未考虑装备)

procedure ReArrangeBRole;
var
  i, i1, i2, x: integer;
  temp: TBattleRole;
begin
  for i1 := 0 to BRoleAmount - 2 do
    for i2 := i1 + 1 to BRoleAmount - 1 do
    begin
      if Rrole[Brole[i1].rnum].Speed < Rrole[Brole[i2].rnum].Speed then
      begin
        temp := Brole[i1];
        Brole[i1] := Brole[i2];
        Brole[i2] := temp;
      end;
    end;

  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
      Bfield[2, i1, i2] := -1;

  for i := 0 to BRoleAmount - 1 do
  begin
    if Brole[i].Dead = 0 then
      Bfield[2, Brole[i].X, Brole[i].Y] := i
    else
      Bfield[2, Brole[i].X, Brole[i].Y] := -1;
  end;

end;

//计算可移动步数(考虑装备)

procedure CalMoveAbility;
var
  i, rnum, addspeed: integer;
begin
  for i := 0 to broleamount - 1 do
  begin
    rnum := Brole[i].rnum;
    addspeed := 0;
    if rrole[rnum].Equip[0] >= 0 then addspeed := addspeed + ritem[rrole[rnum].Equip[0]].AddSpeed;
    if rrole[rnum].Equip[1] >= 0 then addspeed := addspeed + ritem[rrole[rnum].Equip[1]].AddSpeed;
    Brole[i].Step := (Rrole[Brole[i].rnum].Speed + addspeed) div 15;
  end;

end;

//0: Continue; 1: Victory; 2:Failed.
//检查是否有一方全部阵亡

function BattleStatus: integer;
var
  i, sum0, sum1: integer;
begin
  sum0 := 0;
  sum1 := 0;
  for i := 0 to broleamount - 1 do
  begin
    if (Brole[i].Team = 0) and (Brole[i].Dead = 0) then
      sum0 := sum0 + 1;
    if (Brole[i].Team = 1) and (Brole[i].Dead = 0) then
      sum1 := sum1 + 1;
  end;

  if (sum0 > 0) and (sum1 > 0) then result := 0;
  if (sum0 >= 0) and (sum1 = 0) then result := 1;
  if (sum0 = 0) and (sum1 > 0) then result := 2;

end;

//战斗主选单, menustatus按bit保存可用项

function BattleMenu(bnum: integer): integer;
var
  i, p, menustatus, menu, max, rnum, menup: integer;
  realmenu: array[0..9] of integer;
begin
  menustatus := $3E0;
  max := 4;
  //for i:=0 to 9 do
  rnum := brole[bnum].rnum;
  //移动是否可用
  if brole[bnum].Step > 0 then
  begin
    menustatus := menustatus or 1;
    max := max + 1;
  end;

  //can not attack when phisical<10
  //攻击是否可用
  if rrole[rnum].PhyPower >= 10 then
  begin
    p := 0;
    for i := 0 to 9 do
    begin
      if rrole[rnum].Magic[i] > 0 then
      begin
        p := 1;
        break;
      end;
    end;
    if p > 0 then
    begin
      menustatus := menustatus or 2;
      max := max + 1;
    end;
  end;
  //用毒是否可用
  if (Rrole[rnum].UsePoi > 0) and (rrole[rnum].PhyPower >= 30) then
  begin
    menustatus := menustatus or 4;
    max := max + 1;
  end;
  //解毒是否可用
  if (Rrole[rnum].MedPoi > 0) and (rrole[rnum].PhyPower >= 50) then
  begin
    menustatus := menustatus or 8;
    max := max + 1;
  end;
  //医疗是否可用
  if (Rrole[rnum].Medcine > 0) and (rrole[rnum].PhyPower >= 50) then
  begin
    menustatus := menustatus or 16;
    max := max + 1;
  end;

  ReDraw;
  ShowSimpleStatus(brole[bnum].rnum, 350, 50);
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);
  menu := 0;
  showbmenu(menustatus, menu, max);
  //sdl_updaterect(screen,0,0,screen.w,screen.h);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOk, mbCancel], 0) = idOK then Quit;
      SDL_KEYUP:
        begin
          if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
          begin
            break;
          end;
          if (event.key.keysym.sym = sdlk_up) then
          begin
            menu := menu - 1;
            if menu < 0 then menu := max;
            showbmenu(menustatus, menu, max);
          end;
          if (event.key.keysym.sym = sdlk_down) then
          begin
            menu := menu + 1;
            if menu > max then menu := 0;
            showbmenu(menustatus, menu, max);
          end;
          if (event.key.keysym.sym = sdlk_return) and (event.key.keysym.modifier = kmod_lalt) then
          begin
            if fullscreen = 1 then
              screen := SDL_SetVideoMode(CENTER_X * 2, CENTER_Y * 2, 32, SDL_HWSURFACE or SDL_DOUBLEBUF or SDL_ANYFORMAT)
            else
              screen := SDL_SetVideoMode(CENTER_X * 2, CENTER_Y * 2, 32, SDL_FULLSCREEN);
            fullscreen := 1 - fullscreen;
          end;
        end;
      SDL_MOUSEBUTTONUP:
        begin
          if (event.button.button = sdl_button_left) then
            break;
        end;
      SDL_MOUSEMOTION:
        begin
          if (event.button.x >= 100) and (event.button.x < 147) and (event.button.y >= 50) and (event.button.y < max * 22 + 78) then
          begin
            menup := menu;
            menu := (event.button.y - 52) div 22;
            if menu > max then menu := max;
            if menu < 0 then menu := 0;
            if menup <> menu then showbmenu(menustatus, menu, max);
          end;
        end;
    end;
  end;
  //result:=0;
  p := 0;
  for i := 0 to 9 do
  begin
    if (menustatus and (1 shl i)) > 0 then
    begin
      p := p + 1;
      if p > menu then break;
    end;
  end;
  result := i;

end;

//显示战斗主选单

procedure ShowBMenu(MenuStatus, menu, max: integer);
var
  i, p: integer;
  word: array[0..9] of widestring;
begin
  word[0] := ' 移動';
  word[1] := ' 攻擊';
  word[2] := ' 用毒';
  word[3] := ' 解毒';
  word[4] := ' 醫療';
  word[5] := ' 物品';
  word[6] := ' 等待';
  word[7] := ' 狀態';
  word[8] := ' 休息';
  word[9] := ' 自動';
  Redraw;
  DrawRectangle(100, 50, 47, max * 22 + 28, 0, colcolor(255), 30);
  p := 0;
  for i := 0 to 9 do
  begin
    if (p = menu) and ((menustatus and (1 shl i) > 0)) then
    begin
      drawshadowtext(@word[i][1], 83, 53 + 22 * p, colcolor($66), colcolor($64));
      p := p + 1;
    end
    else if (p <> menu) and ((menustatus and (1 shl i) > 0)) then
    begin
      drawshadowtext(@word[i][1], 83, 53 + 22 * p, colcolor($23), colcolor($21));
      p := p + 1;
    end;
  end;
  sdl_updaterect(screen, 100, 50, 48, max * 22 + 29);
end;

//移动

procedure Move(bnum: integer);
var
  s, i: integer;
begin
  CalCanSelect(bnum, 0);
  if SelectAim(bnum, brole[bnum].Step) then
    MoveAmination(bnum);

end;

//移动动画

procedure MoveAmination(bnum: integer);
var
  s, i: integer;
begin
  //CalCanSelect(bnum, 0);
  //if SelectAim(bnum,Brole[bnum,6]) then
  brole[bnum].Step := brole[bnum].Step - abs(Ax - Bx) - abs(Ay - By);
  s := sign(Ax - Bx);
  if s < 0 then Brole[bnum].Face := 0;
  if s > 0 then Brole[bnum].Face := 3;
  i := Bx + s;
  if s <> 0 then
    while s * (Ax - i) >= 0 do
    begin
      sdl_delay(20);
      if Bfield[2, Bx, By] = bnum then Bfield[2, Bx, By] := -1;
      Bx := i;
      if Bfield[2, Bx, By] = -1 then Bfield[2, Bx, By] := bnum;
      Redraw;
      SDL_updaterect(screen, 0, 0, screen.w, screen.h);
      i := i + s;
    end;
  s := sign(Ay - By);
  if s < 0 then Brole[bnum].Face := 2;
  if s > 0 then Brole[bnum].Face := 1;
  i := By + s;
  if s <> 0 then
    while s * (Ay - i) >= 0 do
    begin
      sdl_delay(20);
      if Bfield[2, Bx, By] = bnum then Bfield[2, Bx, By] := -1;
      By := i;
      if Bfield[2, Bx, By] = -1 then Bfield[2, Bx, By] := bnum;
      Redraw;
      SDL_updaterect(screen, 0, 0, screen.w, screen.h);
      i := i + s;
    end;
  Brole[bnum].X := Bx;
  Brole[bnum].Y := By;
  Bfield[2, Bx, By] := bnum;

end;

//选择目标

function SelectAim(bnum, step: integer): boolean;
var
  Axp, Ayp: integer;
begin
  Ax := Bx;
  Ay := By;
  DrawBFieldWithCursor(step);
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOk, mbCancel], 0) = idOK then Quit;
      SDL_KEYUP:
        begin
          if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
          begin
            result := true;
            x50[28927] := 1;
            break;
          end;
          if (event.key.keysym.sym = sdlk_escape) then
          begin
            result := false;
            x50[28927] := 0;
            break;
          end;
          if (event.key.keysym.sym = sdlk_left) then
          begin
            Ay := Ay - 1;
            if (abs(Ax - Bx) + abs(Ay - By) > step) or (Bfield[3, Ax, Ay] <> 0) then Ay := Ay + 1;
            DrawBFieldWithCursor(step);
            sdl_updaterect(screen, 0, 0, screen.w, screen.h);
          end;
          if (event.key.keysym.sym = sdlk_right) then
          begin
            Ay := Ay + 1;
            if (abs(Ax - Bx) + abs(Ay - By) > step) or (Bfield[3, Ax, Ay] <> 0) then Ay := Ay - 1;
            DrawBFieldWithCursor(step);
            sdl_updaterect(screen, 0, 0, screen.w, screen.h);
          end;
          if (event.key.keysym.sym = sdlk_down) then
          begin
            Ax := Ax + 1;
            if (abs(Ax - Bx) + abs(Ay - By) > step) or (Bfield[3, Ax, Ay] <> 0) then Ax := Ax - 1;
            DrawBFieldWithCursor(step);
            sdl_updaterect(screen, 0, 0, screen.w, screen.h);
          end;
          if (event.key.keysym.sym = sdlk_up) then
          begin
            Ax := Ax - 1;
            if (abs(Ax - Bx) + abs(Ay - By) > step) or (Bfield[3, Ax, Ay] <> 0) then Ax := Ax + 1;
            DrawBFieldWithCursor(step);
            sdl_updaterect(screen, 0, 0, screen.w, screen.h);
          end;
        end;
      SDL_MOUSEBUTTONUP:
        begin
          if (event.button.button = sdl_button_left) then
          begin
            result := true;
            break;
          end;
          if (event.button.button = sdl_button_right) then
          begin
            result := false;
            break;
          end;
        end;
      SDL_MOUSEMOTION:
        begin
          Axp := (-event.button.x + CENTER_x + 2 * event.button.y - 2 * CENTER_y + 18) div 36 + Bx;
          Ayp := (event.button.x - CENTER_x + 2 * event.button.y - 2 * CENTER_y + 18) div 36 + By;
          if (abs(Axp - Bx) + abs(Ayp - By) <= step) and (Bfield[3, Axp, Ayp] = 0) then
          begin
            Ax := Axp;
            Ay := Ayp;
            DrawBFieldWithCursor(step);
            sdl_updaterect(screen, 0, 0, screen.w, screen.h);
          end;
        end;
    end;
  end;

end;

//计算可以被选中的位置
//利用递归确定

procedure SeekPath(x, y, step: integer);
begin
  if step > 0 then
  begin
    step := step - 1;
    if Bfield[3, x, y] in [0..step] then
    begin
      Bfield[3, x, y] := step;
      if Bfield[3, x + 1, y] in [0..step] then
      begin
        SeekPath(x + 1, y, step);
      end;
      if Bfield[3, x, y + 1] in [0..step] then
      begin
        SeekPath(x, y + 1, step);
      end;
      if Bfield[3, x - 1, y] in [0..step] then
      begin
        SeekPath(x - 1, y, step);
      end;
      if Bfield[3, x, y - 1] in [0..step] then
      begin
        SeekPath(x, y - 1, step);
      end;
    end;
  end;

end;


procedure CalCanSelect(bnum, mode: integer);
var
  i, i1, i2: integer;
begin
  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      Bfield[3, i1, i2] := 0;
      //mode为0表示移动, 这时建筑和有人物(不包括自己)的位置不可选
      if mode = 0 then
      begin
        if Bfield[1, i1, i2] > 0 then Bfield[3, i1, i2] := -1;
        if Bfield[2, i1, i2] >= 0 then Bfield[3, i1, i2] := -1;
        if Bfield[2, i1, i2] = bnum then Bfield[3, i1, i2] := 0;
      end;
    end;
  if mode = 0 then
  begin
    SeekPath(Brole[bnum].X, Brole[bnum].Y, Brole[bnum].Step + 2);
    //递归算法的问题, 步数+2参与计算
    for i1 := 0 to 63 do
      for i2 := 0 to 63 do
      begin
        if Bfield[3, i1, i2] > 0 then
          Bfield[3, i1, i2] := 0
        else
          Bfield[3, i1, i2] := 1;
      end;
  end;
end;

//画带光标的子程
//此子程效率不高

procedure DrawBFieldWithCursor(step: integer);
var
  i, i1, i2, bnum: integer;
  pos: TPosition;
begin
  if (SDL_MustLock(screen)) then
  begin
    if (SDL_LockSurface(screen) < 0) then
    begin
      MessageBox(0, PChar(Format('Can''t lock screen : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
  end;
  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
      if Bfield[0, i1, i2] > 0 then
      begin
        pos := GetpositionOnScreen(i1, i2, Bx, By);
        if (i1 = Ax) and (i2 = Ay) then
          DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 1)
        else if BField[3, i1, i2] = 0 then
          DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 0)
        else
          DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, -1);
      end;

  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      pos := getpositiononScreen(i1, i2, Bx, By);
      if Bfield[1, i1, i2] > 0 then
        DrawBPic(Bfield[1, i1, i2] div 2, pos.x, pos.y, 0);
      bnum := Bfield[2, i1, i2];
      if (bnum >= 0) and (Brole[bnum].Dead = 0) then
        DrawBPic(Rrole[Brole[bnum].rnum].HeadNum * 4 + Brole[bnum].Face + BEGIN_BATTLE_ROLE_PIC, pos.x, pos.y, 0);
    end;
  if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;

end;

//画带效果的战场

procedure DrawBFieldWithEft(Epicnum: integer);
var
  i, i1, i2: integer;
  pos: TPosition;
begin
  if (SDL_MustLock(screen)) then
  begin
    if (SDL_LockSurface(screen) < 0) then
    begin
      MessageBox(0, PChar(Format('Can''t lock screen : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
  end;
  DrawBfieldWithoutRole(Bx, By);

  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      pos := getpositiononScreen(i1, i2, Bx, By);
      if (Bfield[2, i1, i2] >= 0) and (Brole[Bfield[2, i1, i2]].Dead = 0) then
        DrawRoleOnBField(i1, i2);
      if Bfield[4, i1, i2] > 0 then
        DrawEPic(Epicnum, pos.x, pos.y);
    end;
  if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;

end;

//画带人物动作的战场

procedure DrawBFieldWithAction(bnum, Apicnum: integer);
var
  i, i1, i2: integer;
  pos: TPosition;
begin
  if (SDL_MustLock(screen)) then
  begin
    if (SDL_LockSurface(screen) < 0) then
    begin
      MessageBox(0, PChar(Format('Can''t lock screen : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
  end;
  DrawBfieldWithoutRole(Bx, By);

  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      if (Bfield[2, i1, i2] >= 0) and (Brole[Bfield[2, i1, i2]].Dead = 0) and (Bfield[2, i1, i2] <> bnum) then
      begin
        DrawRoleOnBfield(i1, i2);
      end;
      if (Bfield[2, i1, i2] = bnum) then
      begin
        pos := GetPositionOnScreen(i1, i2, Bx, By);
        DrawFPic(apicnum, pos.x, pos.y);
      end;
    end;
  if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;

end;

//攻击

procedure Attack(bnum: integer);
var
  rnum, i, mnum, level, step, i1: integer;
begin
  rnum := brole[bnum].rnum;
  i := SelectMagic(rnum);
  mnum := Rrole[rnum].Magic[i];
  level := Rrole[rnum].MagLevel[i] div 100 + 1;

  if i >= 0 then
    //依据攻击范围进一步选择
    case Rmagic[mnum].AttAreaType of
      0, 3:
        begin
          CalCanSelect(bnum, 1);
          step := Rmagic[mnum].MoveDistance[level - 1];
          if SelectAim(bnum, step) then
          begin
            SetAminationPosition(Rmagic[mnum].AttAreaType, Rmagic[mnum].AttDistance[level - 1]);
            Brole[bnum].Acted := 1;
          end;
        end;
      1:
        begin
          if SelectDirector(bnum) then
          begin
            SetAminationPosition(Rmagic[mnum].AttAreaType, Rmagic[mnum].MoveDistance[level - 1]);
            Brole[bnum].Acted := 1;
          end;
        end;
      2:
        begin
          SetAminationPosition(Rmagic[mnum].AttAreaType, Rmagic[mnum].MoveDistance[level - 1]);
          Brole[bnum].Acted := 1;
        end;
    end;
  //如果行动成功, 武功等级增加, 播放效果
  if Brole[bnum].Acted = 1 then
  begin
    for i1 := 0 to sign(Rrole[rnum].AttTwice) do
    begin
      Rrole[rnum].MagLevel[i] := Rrole[rnum].MagLevel[i] + random(2) + 1;
      if Rrole[rnum].MagLevel[i] > 999 then Rrole[rnum].MagLevel[i] := 999;
      if rmagic[mnum].UnKnow[4] > 0 then callevent(rmagic[mnum].UnKnow[4])
      else AttackAction(bnum, mnum, level);
    end;
  end;

end;

//攻击效果

procedure AttackAction(bnum, mnum, level: integer);
begin
  PlayActionAmination(bnum, Rmagic[mnum].MagicType); //动画效果
  PlayMagicAmination(bnum, Rmagic[mnum].AmiNum); //武功效果
  CalHurtRole(bnum, mnum, level); //计算被打到的人物
  ShowHurtValue(rmagic[mnum].HurtType); //显示数字

end;

//选择武功

function SelectMagic(rnum: integer): integer;
var
  i, p, menustatus, max, menu, menup: integer;
begin
  menustatus := 0;
  max := 0;
  setlength(menustring, 10);
  setlength(menuengstring, 10);
  for i := 0 to 9 do
  begin
    if Rrole[rnum].Magic[i] > 0 then
    begin
      menustatus := menustatus or (1 shl i);
      menustring[i] := Big5toUnicode(@Rmagic[Rrole[rnum].Magic[i]].Name);
      menuengstring[i] := format('%3d', [Rrole[rnum].MagLevel[i] div 100 + 1]);
      max := max + 1;
    end;
  end;
  max := max - 1;

  ReDraw;
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);
  menu := 0;
  showmagicmenu(menustatus, menu, max);
  //sdl_updaterect(screen,0,0,screen.w,screen.h);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOk, mbCancel], 0) = idOK then Quit;
      SDL_KEYUP:
        begin
          if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
          begin
            break;
          end;
          if (event.key.keysym.sym = sdlk_escape) then
          begin
            result := -1;
            break;
          end;
          if (event.key.keysym.sym = sdlk_up) then
          begin
            menu := menu - 1;
            if menu < 0 then menu := max;
            showmagicmenu(menustatus, menu, max);
          end;
          if (event.key.keysym.sym = sdlk_down) then
          begin
            menu := menu + 1;
            if menu > max then menu := 0;
            showmagicmenu(menustatus, menu, max);
          end;
        end;
      SDL_MOUSEBUTTONUP:
        begin
          if (event.button.button = sdl_button_left) then
          begin
            break;
          end;
          if (event.button.button = sdl_button_right) then
          begin
            result := -1;
            break;
          end;
        end;
      SDL_MOUSEMOTION:
        begin
          if (event.button.x >= 100) and (event.button.x < 267) and (event.button.y >= 50) and (event.button.y < max * 22 + 78) then
          begin
            menup := menu;
            menu := (event.button.y - 52) div 22;
            if menu > max then menu := max;
            if menu < 0 then menu := 0;
            if menup <> menu then showmagicmenu(menustatus, menu, max);
          end;
        end;
    end;
  end;
  //result:=0;
  if result >= 0 then
  begin
    p := 0;
    for i := 0 to 9 do
    begin
      if (menustatus and (1 shl i)) > 0 then
      begin
        p := p + 1;
        if p > menu then break;
      end;
    end;
    result := i;
  end;

end;

//显示武功选单

procedure ShowMagicMenu(menustatus, menu, max: integer);
var
  i, p: integer;
begin
  redraw;
  DrawRectangle(100, 50, 167, max * 22 + 28, 0, colcolor(255), 30);
  p := 0;
  for i := 0 to 9 do
  begin
    if (p = menu) and ((menustatus and (1 shl i) > 0)) then
    begin
      drawshadowtext(@menustring[i][1], 83, 53 + 22 * p, colcolor($66), colcolor($64));
      drawengshadowtext(@menuengstring[i][1], 223, 53 + 22 * p, colcolor($66), colcolor($64));
      p := p + 1;
    end
    else if (p <> menu) and ((menustatus and (1 shl i) > 0)) then
    begin
      drawshadowtext(@menustring[i][1], 83, 53 + 22 * p, colcolor($23), colcolor($21));
      drawengshadowtext(@menuengstring[i][1], 223, 53 + 22 * p, colcolor($23), colcolor($21));
      p := p + 1;
    end;
  end;
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);

end;

//选择方向

function SelectDirector(bnum: integer): boolean;
var
  str: widestring;
begin
  Ax := Bx;
  Ay := By;
  str := ' 選擇攻擊方向';
  Drawtextwithrect(@str[1], 280, 200, 125, colcolor($23), colcolor($21));
  sdl_updaterect(screen, 0, 0, screen.w, screen.h);
  result := false;
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOk, mbCancel], 0) = idOK then Quit;
      SDL_KEYUP:
        begin
          if (event.key.keysym.sym = sdlk_escape) then
          begin
            break;
          end;
          if (event.key.keysym.sym = sdlk_left) then
          begin
            Ay := Ay - 1;
            break;
          end;
          if (event.key.keysym.sym = sdlk_right) then
          begin
            Ay := Ay + 1;
            break;
          end;
          if (event.key.keysym.sym = sdlk_down) then
          begin
            Ax := Ax + 1;
            break;
          end;
          if (event.key.keysym.sym = sdlk_up) then
          begin
            Ax := Ax - 1;
            break;
          end;
        end;
      Sdl_mousebuttonup:
        begin
          if event.button.button = sdl_button_right then break;
          //按照所点击位置设置方向
          if event.button.button = sdl_button_left then
          begin
            if (event.button.x < CENTER_x) and (event.button.y < CENTER_y) then Ay := Ay - 1;
            if (event.button.x < CENTER_x) and (event.button.y >= CENTER_y) then Ax := Ax + 1;
            if (event.button.x >= CENTER_x) and (event.button.y < CENTER_y) then Ax := Ax - 1;
            if (event.button.x >= CENTER_x) and (event.button.y >= CENTER_y) then Ay := Ay + 1;
            break;
          end;
        end;
    end;
  end;
  if (Ax <> Bx) or (Ay <> By) then result := true;

end;

//设定攻击范围

procedure SetAminationPosition(mode, step: integer);
var
  i, i1, i2: integer;
begin
  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      Bfield[4, i1, i2] := 0;
      //按攻击类型判断是否在范围内
      case mode of
        0:
          begin
            if (i1 = Ax) and (i2 = Ay) then Bfield[4, i1, i2] := 1;
          end;
        3:
          begin
            if (abs(i1 - Ax) <= step) and (abs(i2 - Ay) <= step) then Bfield[4, i1, i2] := 1;
          end;
        1:
          begin
            if ((i1 = Bx) or (i2 = By)) and (sign(Ax - Bx) = sign(i1 - Bx)) and (abs(i1 - Bx) <= step) and (sign(Ay - By) = sign(i2 - By)) and (abs(i2 - By) <= step) then
              Bfield[4, i1, i2] := 1;
          end;
        2:
          begin
            if ((i1 = Bx) and (abs(i2 - By) <= step)) or ((i2 = By) and (abs(i1 - Bx) <= step)) then
              Bfield[4, i1, i2] := 1;
            if ((i1 = Bx) and (i2 = By)) then Bfield[4, i1, i2] := 0;
          end;
      end;
    end;

end;

//显示武功效果

procedure PlayMagicAmination(bnum, enum: integer);
var
  beginpic, i, endpic: integer;
begin
  beginpic := 0;
  //含音效
  playsound(enum, 0);
  for i := 0 to enum - 1 do
    beginpic := beginpic + effectlist[i];
  endpic := beginpic + effectlist[enum] - 1;


  for i := beginpic to endpic do
  begin
    DrawBFieldWithEft(i);
    sdl_updaterect(screen, 0, 0, screen.w, screen.h);
    sdl_delay(20);
  end;

end;

//判断是否有非行动方角色在攻击范围之内

procedure CalHurtRole(bnum, mnum, level: integer);
var
  i, rnum, hurt, addpoi, mp: integer;
begin
  rnum := brole[bnum].rnum;
  rrole[rnum].PhyPower := rrole[rnum].PhyPower - 3;
  if RRole[rnum].CurrentMP < rmagic[mnum].NeedMP * ((level + 1) div 2) then level := RRole[rnum].CurrentMP div rmagic[mnum].NeedMP * 2;
  if level > 10 then level := 10;
  RRole[rnum].CurrentMP := RRole[rnum].CurrentMP - rmagic[mnum].NeedMP * ((level + 1) div 2);
  for i := 0 to broleamount - 1 do
  begin
    Brole[i].ShowNumber := -1;
    if (Bfield[4, Brole[i].X, Brole[i].Y] <> 0) and (Brole[bnum].Team <> Brole[i].Team) and (Brole[i].Dead = 0) then
    begin
      //生命伤害
      if (rmagic[mnum].HurtType = 0) then
      begin
        hurt := CalHurtValue(bnum, i, mnum, level);
        Brole[i].ShowNumber := hurt;
        //受伤
        Rrole[Brole[i].rnum].CurrentHP := Rrole[Brole[i].rnum].CurrentHP - hurt;
        Rrole[Brole[i].rnum].Hurt := Rrole[Brole[i].rnum].Hurt + hurt div LIFE_HURT;
        if Rrole[Brole[i].rnum].Hurt > 99 then Rrole[Brole[i].rnum].Hurt := 99;
        Brole[bnum].ExpGot := Brole[bnum].ExpGot + hurt div 2;
        if Rrole[Brole[i].rnum].CurrentHP <= 0 then Brole[bnum].ExpGot := Brole[bnum].ExpGot + hurt div 2;
      end;
      //内力伤害
      if (rmagic[mnum].HurtType = 1) then
      begin
        hurt := rmagic[mnum].HurtMP[level - 1] + random(5) - random(5);
        Brole[i].ShowNumber := hurt;
        Rrole[Brole[i].rnum].CurrentMP := Rrole[Brole[i].rnum].CurrentMP - hurt;
        if Rrole[Brole[i].rnum].CurrentMP <= 0 then Rrole[Brole[i].rnum].CurrentMP := 0;
        //增加己方内力及最大值
        RRole[rnum].CurrentMP := RRole[rnum].CurrentMP + hurt;
        RRole[rnum].MaxMP := RRole[rnum].MaxMP + random(hurt div 2);
        if RRole[rnum].MaxMP > MAX_MP then RRole[rnum].MaxMP := MAX_MP;
        if RRole[rnum].CurrentMP > RRole[rnum].MaxMP then RRole[rnum].CurrentMP := RRole[rnum].MaxMP;
      end;
      //中毒
      addpoi := rrole[rnum].AttPoi div 5 + rmagic[mnum].Poision * level div 2 - rrole[Brole[i].rnum].DefPoi;
      if addpoi + rrole[Brole[i].rnum].Poision > 99 then addpoi := 99 - rrole[Brole[i].rnum].Poision;
      if addpoi < 0 then addpoi := 0;
      if rrole[Brole[i].rnum].DefPoi >= 99 then addpoi := 0;
      rrole[Brole[i].rnum].Poision := rrole[Brole[i].rnum].Poision + addpoi;
    end;
  end;

end;

//计算伤害值, 第一公式如小于0则取一个随机数, 无第二公式

function CalHurtValue(bnum1, bnum2, mnum, level: integer): integer;
var
  i, rnum1, rnum2, mhurt, att, def, k1, k2, dis: integer;
begin
  //计算双方武学常识
  k1 := 0;
  k2 := 0;
  for i := 0 to broleamount - 1 do
  begin
    if (Brole[i].Team = brole[bnum1].Team) and (Brole[i].Dead = 0) and (rrole[Brole[i].rnum].Knowledge > MIN_KNOWLEDGE) then k1 := k1 + rrole[Brole[i].rnum].Knowledge;
    if (Brole[i].Team = brole[bnum2].Team) and (Brole[i].Dead = 0) and (rrole[Brole[i].rnum].Knowledge > MIN_KNOWLEDGE) then k2 := k2 + rrole[Brole[i].rnum].Knowledge;
  end;
  rnum1 := Brole[bnum1].rnum;
  rnum2 := Brole[bnum2].rnum;
  mhurt := Rmagic[mnum].Attack[level - 1];

  att := Rrole[rnum1].Attack + k1 * 3 div 2 + mhurt div 3;
  def := Rrole[rnum2].Defence * 2 + k2 * 3;
  //攻击, 防御按伤害的折扣
  att := att * (100 - Rrole[rnum1].Hurt div 2) div 100;
  def := def * (100 - Rrole[rnum2].Hurt div 2) div 100;

  //如果有武器, 增加攻击, 检查配合列表
  if rrole[rnum1].Equip[0] >= 0 then
  begin
    att := att + ritem[rrole[rnum1].Equip[0]].AddAttack;
    for i := 0 to MAX_WEAPON_MATCH - 1 do
    begin
      if (rrole[rnum1].Equip[0] = matchlist[i, 0]) and (mnum = matchlist[i, 1]) then
      begin
        att := att + matchlist[i, 2] * 2 div 3;
        break;
      end;
    end;
  end;
  //防具增加攻击
  if rrole[rnum1].Equip[1] >= 0 then att := att + ritem[rrole[rnum1].Equip[1]].AddAttack;
  //武器, 防具增加防御
  if rrole[rnum2].Equip[0] >= 0 then def := def + ritem[rrole[rnum2].Equip[0]].AddDefence;
  if rrole[rnum2].Equip[1] >= 0 then def := def + ritem[rrole[rnum2].Equip[1]].AddDefence;
  //showmessage(inttostr(att)+' '+inttostr(def));
  result := att - def + random(20) - random(20);
  dis := abs(brole[bnum1].X - brole[bnum2].X) + abs(brole[bnum1].Y - brole[bnum2].Y);
  if dis > 10 then dis := 10;
  result := result * (100 - (dis - 1) * 3) div 100;
  if (result <= 0) or (level <= 0) then result := random(10) + 1;
  if (result > 9999) then result := 9999;
  //showmessage(inttostr(result));

end;

//0: red. 1: purple, 2: green
//显示数字

procedure ShowHurtValue(mode: integer);
var
  i, i1, x, y: integer;
  color1, color2: uint32;
  word: array of widestring;
  str: string;
begin
  case mode of
    0:
      begin
        color1 := colcolor($10);
        color2 := colcolor($14);
        str := '-%d';
      end;
    1:
      begin
        color1 := colcolor($50);
        color2 := colcolor($53);
        str := '-%d';
      end;
    2:
      begin
        color1 := colcolor($30);
        color2 := colcolor($32);
        str := '+%d';
      end;
    3:
      begin
        color1 := colcolor($7);
        color2 := colcolor($5);
        str := '+%d';
      end;
    4:
      begin
        color1 := colcolor($91);
        color2 := colcolor($93);
        str := '-%d';
      end;
  end;
  setlength(word, broleamount);
  for i := 0 to broleamount - 1 do
  begin
    if Brole[i].ShowNumber > 0 then
    begin
      //x := -(Brole[i].X - Bx) * 18 + (Brole[i].Y - By) * 18 + CENTER_X - 10;
      //y := (Brole[i].X - Bx) * 9 + (Brole[i].Y - By) * 9 + CENTER_Y - 40;
      word[i] := format(str, [Brole[i].ShowNumber]);
    end;
    Brole[i].ShowNumber := -1;
  end;
  for i1 := 0 to 10 do
  begin
    redraw;
    for i := 0 to broleamount - 1 do
    begin
      x := -(Brole[i].X - Bx) * 18 + (Brole[i].Y - By) * 18 + CENTER_X - 10;
      y := (Brole[i].X - Bx) * 9 + (Brole[i].Y - By) * 9 + CENTER_Y - 40;
      drawengshadowtext(@word[i, 1], x, y - i1 * 2, color1, color2);
      sdl_delay(5);
    end;
    sdl_updaterect(screen, 0, 0, screen.w, screen.h);
  end;
  redraw;

end;

//计算中毒减少的生命

procedure CalPoiHurtLife;
var
  i: integer;
  p: boolean;
begin
  p := false;
  for i := 0 to broleamount - 1 do
  begin
    Brole[i].ShowNumber := -1;
    if (Rrole[Brole[i].rnum].Poision > 0) and (Brole[i].Dead = 0) then
    begin
      Rrole[Brole[i].rnum].CurrentHP := Rrole[Brole[i].rnum].CurrentHP - Rrole[Brole[i].rnum].Poision div 10 - 1;
      if Rrole[Brole[i].rnum].CurrentHP <= 0 then Rrole[Brole[i].rnum].CurrentHP := 1;
      //Brole[i].ShowNumber := Rrole[Brole[i].rnum, 20] div 2+1;
      //p := true;
    end;
  end;
  //if p then showhurtvalue(0);

end;

//设置生命低于0的人物为已阵亡, 主要是清除所占的位置

procedure ClearDeadRolePic;
var
  i: integer;
begin
  for i := 0 to broleamount - 1 do
  begin
    if Rrole[Brole[i].rnum].CurrentHP <= 0 then
    begin
      Brole[i].Dead := 1;
      bfield[2, Brole[i].X, Brole[i].Y] := -1;
      //bmount
    end;
  end;
  for i := 0 to broleamount - 1 do
    if Brole[i].Dead = 0 then bfield[2, Brole[i].X, Brole[i].Y] := i;

end;

//显示简单状态(x, y表示位置)

procedure ShowSimpleStatus(rnum, x, y: integer);
var
  i, magicnum: integer;
  p: array[0..10] of integer;
  str: widestring;
  strs: array[0..3] of widestring;
  color1, color2: uint32;
begin
  strs[0] := ' 等級';
  strs[1] := ' 生命';
  strs[2] := ' 內力';
  strs[3] := ' 體力';

  DrawRectangle(x, y, 145, 173, 0, colcolor(255), 30);
  drawheadpic(Rrole[rnum].HeadNum, x + 50, y + 62);
  str := big5tounicode(@rrole[rnum].Name);
  drawshadowtext(@str[1], x + 60 - length(pchar(@rrole[rnum].Name)) * 5, y + 65, colcolor($66), colcolor($63));
  for i := 0 to 3 do
    drawshadowtext(@strs[i, 1], x - 17, y + 86 + 21 * i, colcolor($23), colcolor($21));

  str := format('%9d', [Rrole[rnum].Level]);
  drawengshadowtext(@str[1], x + 50, y + 86, colcolor($7), colcolor($5));

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
      color1 := colcolor($7);
      color2 := colcolor($5);
    end;
  end;
  str := format('%4d', [RRole[rnum].CurrentHP]);
  drawengshadowtext(@str[1], x + 50, y + 107, color1, color2);

  str := '/';
  drawengshadowtext(@str[1], x + 90, y + 107, colcolor($66), colcolor($63));

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
      color1 := colcolor($23);
      color2 := colcolor($21);
    end;
  end;
  str := format('%4d', [RRole[rnum].MaxHP]);
  drawengshadowtext(@str[1], x + 100, y + 107, color1, color2);

  //str:=format('%4d/%4d', [Rrole[rnum,17],Rrole[rnum,18]]);
  //drawengshadowtext(@str[1],x+50,y+107,colcolor($7),colcolor($5));
  if rrole[rnum].MPType = 0 then
  begin
    color1 := colcolor($50);
    color2 := colcolor($4E);
  end else
    if rrole[rnum].MPType = 1 then
    begin
      color1 := colcolor($7);
      color2 := colcolor($5);
    end else
    begin
      color1 := colcolor($66);
      color2 := colcolor($63);
    end;
  str := format('%4d/%4d', [RRole[rnum].CurrentMP, RRole[rnum].MaxMP]);
  drawengshadowtext(@str[1], x + 50, y + 128, color1, color2);
  str := format('%9d', [rrole[rnum].PhyPower]);
  drawengshadowtext(@str[1], x + 50, y + 149, colcolor($7), colcolor($5));

  SDL_UpdateRect(screen, 0, 0, screen.w, screen.h);

end;

//等待, 似乎不太完善

procedure Wait(bnum: integer);
var
  i, i1, i2, x: integer;
begin

  Brole[BroleAmount] := Brole[bnum];

  for i := bnum to BRoleAmount - 1 do
    Brole[i] := Brole[i + 1];

  for i := 0 to BRoleAmount - 1 do
  begin
    if Brole[i].Dead = 0 then
      Bfield[2, Brole[i].X, Brole[i].Y] := i
    else
      Bfield[2, Brole[i].X, Brole[i].Y] := -1;
  end;

end;

//战斗结束恢复人物状态

procedure RestoreRoleStatus;
var
  i, rnum: integer;
begin
  for i := 0 to BRoleAmount - 1 do
  begin
    rnum := Brole[i].rnum;
    //我方恢复部分生命, 内力; 敌方恢复全部
    if Brole[i].Team = 0 then
    begin
      RRole[rnum].CurrentHP := RRole[rnum].CurrentHP + RRole[rnum].MaxHP div 2;
      if RRole[rnum].CurrentHP <= 0 then RRole[rnum].CurrentHP := 1;
      if RRole[rnum].CurrentHP > RRole[rnum].MaxHP then RRole[rnum].CurrentHP := RRole[rnum].MaxHP;
      RRole[rnum].CurrentMP := RRole[rnum].CurrentMP + RRole[rnum].MaxMP div 20;
      if RRole[rnum].CurrentMP > RRole[rnum].MaxMP then RRole[rnum].CurrentMP := RRole[rnum].MaxMP;
      rrole[rnum].PhyPower := rrole[rnum].PhyPower + MAX_PHYSICAL_POWER div 10;
      if rrole[rnum].PhyPower > MAX_PHYSICAL_POWER then rrole[rnum].PhyPower := MAX_PHYSICAL_POWER;
    end else
    begin
      RRole[rnum].Hurt := 0;
      RRole[rnum].Poision := 0;
      RRole[rnum].CurrentHP := RRole[rnum].MaxHP;
      RRole[rnum].CurrentMP := RRole[rnum].MaxMP;
      rrole[rnum].PhyPower := MAX_PHYSICAL_POWER * 9 div 10;
    end;
  end;

end;

//增加经验

procedure AddExp;
var
  i, rnum, basicvalue, amount: integer;
  str: widestring;
begin
  for i := 0 to BRoleAmount - 1 do
  begin
    rnum := Brole[i].rnum;
    Rrole[rnum].Exp := Rrole[rnum].Exp + Brole[i].ExpGot;
    Rrole[rnum].ExpForBook := Rrole[rnum].ExpForBook + Brole[i].ExpGot div 5 * 4;
    Rrole[rnum].ExpForItem := Rrole[rnum].ExpForItem + Brole[i].ExpGot div 5 * 3;
    amount := Calrnum(0);
    if amount > 0 then basicvalue := warsta[7] div amount
    else basicvalue := 0;
    if (Brole[i].Team = 0) and (Brole[i].Dead = 0) then
    begin
      Rrole[rnum].Exp := Rrole[rnum].Exp + basicvalue;
      Rrole[rnum].ExpForBook := Rrole[rnum].ExpForBook + basicvalue div 5 * 4;
      Rrole[rnum].ExpForItem := Rrole[rnum].ExpForItem + basicvalue div 5 * 3;
      ShowSimpleStatus(rnum, 100, 50);
      DrawRectangle(100, 235, 145, 25, 0, colcolor(255), 25);
      str := ' 得經驗';
      Drawshadowtext(@str[1], 83, 237, colcolor($23), colcolor($21));
      str := format('%5d', [Brole[i].ExpGot + basicvalue]);
      Drawengshadowtext(@str[1], 188, 237, colcolor($66), colcolor($64));
      sdl_updaterect(screen, 0, 0, screen.w, screen.h);
      Redraw;
      waitanykey;
    end;

  end;

end;

//检查是否能够升级

procedure CheckLevelUp;
var
  i, rnum: integer;
begin
  for i := 0 to BRoleAmount - 1 do
  begin
    rnum := Brole[i].rnum;
    while (uint16(Rrole[rnum].Exp) >= uint16(LevelUplist[Rrole[rnum].Level - 1])) and (Rrole[rnum].Level < MAX_LEVEL) do
    begin
      Rrole[rnum].Exp := Rrole[rnum].Exp - LevelUplist[Rrole[rnum].Level - 1];
      Rrole[rnum].Level := Rrole[rnum].Level + 1;
      LevelUp(i);
    end;
  end;

end;

//升级, 如是我方人物显示状态

procedure LevelUp(bnum: integer);
var
  i, rnum, add: integer;
  str: widestring;
begin

  rnum := brole[bnum].rnum;
  RRole[rnum].MaxHP := RRole[rnum].MaxHP + Rrole[rnum].IncLife * 3 + random(6);
  if RRole[rnum].MaxHP > MAX_HP then RRole[rnum].MaxHP := MAX_HP;
  RRole[rnum].CurrentHP := RRole[rnum].MaxHP;

  add := Rrole[rnum].Aptitude div 15 + 1;
  add := random(add) + 1;

  RRole[rnum].MaxMP := RRole[rnum].MaxMP + (9 - add) * 3;
  if RRole[rnum].MaxMP > MAX_MP then RRole[rnum].MaxMP := MAX_MP;
  RRole[rnum].CurrentMP := RRole[rnum].MaxMP;

  RRole[rnum].Attack := RRole[rnum].Attack + add;
  Rrole[rnum].Speed := Rrole[rnum].Speed + add;
  Rrole[rnum].Defence := Rrole[rnum].Defence + add;

  for i := 46 to 54 do
  begin
    if rrole[rnum].data[i] > 0 then
      rrole[rnum].data[i] := rrole[rnum].data[i] + random(3) + 1;
  end;
  for i := 43 to 58 do
  begin
    if rrole[rnum].data[i] > maxprolist[i] then
      rrole[rnum].data[i] := maxprolist[i];
  end;

  RRole[rnum].PhyPower := MAX_PHYSICAL_POWER;
  RRole[rnum].Hurt := 0;
  RRole[rnum].Poision := 0;

  if Brole[bnum].Team = 0 then
  begin
    ShowStatus(rnum);
    str := ' 升級';
    Drawtextwithrect(@str[1], 50, CENTER_Y - 150, 46, colcolor($23), colcolor($21));
    waitanykey;
  end;

end;

//检查身上秘笈

procedure CheckBook;
var
  i, i1, i2, p, rnum, inum, mnum, mlevel, needexp, needitem, needitemamount, itemamount: integer;
  str: widestring;
begin
  for i := 0 to BRoleAmount - 1 do
  begin
    rnum := Brole[i].rnum;
    inum := Rrole[rnum].PracticeBook;
    if inum >= 0 then
    begin
      mlevel := 1;
      mnum := Ritem[inum].Magic;
      if mnum > 0 then
        for i1 := 0 to 9 do
          if Rrole[rnum].Magic[i1] = mnum then
          begin
            mlevel := Rrole[rnum].MagLevel[i1] div 100 + 1;
            break;
          end;
      needexp := mlevel * Ritem[inum].NeedExp * (7 - Rrole[rnum].Aptitude div 15);

      if (Rrole[rnum].ExpForBook >= needexp) and (mlevel < 10) then
      begin
        redraw;
        EatOneItem(rnum, inum);
        waitanykey;
        redraw;
        sdl_updaterect(screen, 0, 0, screen.w, screen.h);

        if mnum > 0 then
          instruct_33(rnum, mnum, 1);
        Rrole[rnum].ExpForBook := 0;
        //ShowStatus(rnum);
        //waitanykey;
      end;
      //是否能够炼出物品
      if (Rrole[rnum].ExpForItem >= ritem[inum].NeedExpForItem) and (ritem[inum].NeedExpForItem > 0) and (Brole[i].Team = 0) then
      begin
        redraw;
        p := 0;
        for i2 := 0 to 4 do
        begin
          if ritem[inum].GetItem[i2] >= 0 then p := p + 1;
        end;
        p := random(p);
        needitem := ritem[inum].NeedMaterial;
        if ritem[inum].GetItem[p] >= 0 then
        begin
          needitemamount := ritem[inum].NeedMatAmount[p];
          itemamount := 0;
          for i2 := 0 to MAX_ITEM_AMOUNT - 1 do
            if RItemList[i2].Number = needitem then
            begin
              itemamount := RItemList[i2].Amount;
              break;
            end;
          if needitemamount <= itemamount then
          begin
            ShowSimpleStatus(rnum, 350, 50);
            DrawRectangle(115, 63, 145, 25, 0, colcolor(255), 25);
            str := ' 製藥成功';
            Drawshadowtext(@str[1], 127, 65, colcolor($23), colcolor($21));

            instruct_2(ritem[inum].GetItem[p], 1 + random(5));
            instruct_32(needitem, -needitemamount);
            Rrole[rnum].ExpForItem := 0;
          end;
        end;
        //ShowStatus(rnum);
        //waitanykey;
      end;
    end;
  end;

end;

//统计一方人数

function CalRNum(team: integer): integer;
var
  i: integer;
begin
  result := 0;
  for i := 0 to broleamount - 1 do
  begin
    if (Brole[i].Team = team) and (Brole[i].Dead = 0) then result := result + 1;
  end;

end;

//战斗中物品选单

procedure BattleMenuItem(bnum: integer);
var
  rnum, inum, mode: integer;
  str: widestring;
begin
  if MenuItem then
  begin
    inum := CurItem;
    rnum := brole[bnum].rnum;
    mode := Ritem[inum].ItemType;
    case mode of
      3:
        begin
          EatOneItem(rnum, inum);
          instruct_32(inum, -1);
          Brole[bnum].Acted := 1;
          waitanykey;
        end;
      4:
        begin
          UseHiddenWeapen(bnum, inum);
        end;
    end;
  end;

end;

//动作动画

procedure PlayActionAmination(bnum, mode: integer);
var
  d1, d2, dm, rnum, i, beginpic, endpic, idx, grp, tnum, len: integer;
  filename: string;
begin
  d1 := Ax - Bx;
  d2 := Ay - By;
  dm := abs(d1) - abs(d2);
  if (dm >= 0) then
    if d1 < 0 then Brole[bnum].Face := 0 else Brole[bnum].Face := 3
  else
    if d2 < 0 then Brole[bnum].Face := 2 else Brole[bnum].Face := 1;

  Redraw;
  rnum := brole[bnum].rnum;
  if rrole[rnum].AmiFrameNum[mode] > 0 then
  begin
    beginpic := 0;
    for i := 0 to 4 do
    begin
      if i >= mode then break;
      beginpic := beginpic + rrole[rnum].AmiFrameNum[i] * 4;
    end;
    beginpic := beginpic + Brole[bnum].Face * rrole[rnum].AmiFrameNum[mode];
    endpic := beginpic + rrole[rnum].AmiFrameNum[mode] - 1;

    filename := format('%3d', [rrole[rnum].HeadNum]);

    for i := 1 to length(filename) do
      if filename[i] = ' ' then filename[i] := '0';

    idx := fileopen('fight\fight' + filename + '.idx', fmopenread);
    grp := fileopen('fight\fight' + filename + '.grp', fmopenread);
    len := fileseek(grp, 0, 2);
    fileseek(grp, 0, 0);
    fileread(grp, FPic[0], len);
    tnum := fileseek(idx, 0, 2) div 4;
    fileseek(idx, 0, 0);
    fileread(idx, FIdx[0], tnum * 4);
    fileclose(grp);
    fileclose(idx);

    for i := beginpic to endpic do
    begin
      DrawBfieldWithAction(bnum, i);
      sdl_updaterect(screen, 0, 0, screen.w, screen.h);
      sdl_delay(20);
    end;
  end;

end;

//用毒

procedure UsePoision(bnum: integer);
var
  rnum, bnum1, rnum1, poi, step, addpoi: integer;
  select: boolean;
begin
  calcanselect(bnum, 1);
  rnum := brole[bnum].rnum;
  poi := Rrole[rnum].UsePoi;
  step := poi div 15 + 1;
  if (Brole[bnum].Team = 0) and (brole[bnum].Auto = 0) then
    select := selectaim(bnum, step);
  if (bfield[2, Ax, Ay] >= 0) and (select = true) then
  begin
    Brole[bnum].Acted := 1;
    rrole[rnum].PhyPower := rrole[rnum].PhyPower - 3;
    bnum1 := bfield[2, Ax, Ay];
    if brole[bnum1].Team <> Brole[bnum].Team then
    begin
      rnum1 := brole[bnum1].rnum;
      addpoi := Rrole[rnum].UsePoi div 3 - rrole[rnum1].DefPoi div 4;
      if addpoi < 0 then addpoi := 0;
      if addpoi + rrole[rnum1].Poision > 99 then addpoi := 99 - rrole[rnum1].Poision;
      rrole[rnum1].Poision := rrole[rnum1].Poision + addpoi;
      brole[bnum1].ShowNumber := addpoi;
      SetAminationPosition(0, 0);
      PlayActionAmination(bnum, 0);
      PlayMagicAmination(bnum, 30);
      ShowHurtValue(2);
    end;
  end;
end;

//医疗

procedure Medcine(bnum: integer);
var
  rnum, bnum1, rnum1, med, step, addlife: integer;
  select: boolean;
begin
  calcanselect(bnum, 1);
  rnum := brole[bnum].rnum;
  med := Rrole[rnum].Medcine;
  step := med div 15 + 1;
  if (Brole[bnum].Team = 0) and (brole[bnum].Auto = 0) then
    select := selectaim(bnum, step)
  else
  begin
    Ax := Bx;
    Ay := By;
  end;
  if (bfield[2, Ax, Ay] >= 0) and (select = true) then
  begin
    Brole[bnum].Acted := 1;
    rrole[rnum].PhyPower := rrole[rnum].PhyPower - 5;
    bnum1 := bfield[2, Ax, Ay];
    if brole[bnum1].Team = Brole[bnum].Team then
    begin
      rnum1 := brole[bnum1].rnum;
      addlife := Rrole[rnum].Medcine; //calculate the value
      if addlife < 0 then addlife := 0;
      if addlife + rrole[rnum1].CurrentHP > rrole[rnum1].MaxHP then addlife := rrole[rnum1].MaxHP - rrole[rnum1].CurrentHP;
      rrole[rnum1].CurrentHP := rrole[rnum1].CurrentHP + addlife;
      Rrole[rnum1].Hurt := Rrole[rnum1].Hurt - addlife div LIFE_HURT;
      if Rrole[rnum1].Hurt < 0 then Rrole[rnum1].Hurt := 0;
      brole[bnum1].ShowNumber := addlife;
      SetAminationPosition(0, 0);
      PlayActionAmination(bnum, 0);
      PlayMagicAmination(bnum, 0);
      ShowHurtValue(3);
    end;
  end;

end;

//解毒

procedure MedPoision(bnum: integer);
var
  rnum, bnum1, rnum1, medpoi, step, minuspoi: integer;
  select: boolean;
begin
  calcanselect(bnum, 1);
  rnum := brole[bnum].rnum;
  medpoi := Rrole[rnum].MedPoi;
  step := medpoi div 15 + 1;
  if (Brole[bnum].Team = 0) and (brole[bnum].Auto = 0) then
    select := selectaim(bnum, step)
  else
  begin
    Ax := Bx;
    Ay := By;
  end;
  if (bfield[2, Ax, Ay] >= 0) and (select = true) then
  begin
    Brole[bnum].Acted := 1;
    rrole[rnum].PhyPower := rrole[rnum].PhyPower - 5;
    bnum1 := bfield[2, Ax, Ay];
    if brole[bnum1].Team = Brole[bnum].Team then
    begin
      rnum1 := brole[bnum1].rnum;
      minuspoi := Rrole[rnum].MedPoi;
      if minuspoi < 0 then minuspoi := 0;
      if rrole[rnum1].Poision - minuspoi <= 0 then minuspoi := rrole[rnum1].Poision;
      rrole[rnum1].Poision := rrole[rnum1].Poision - minuspoi;
      brole[bnum1].ShowNumber := minuspoi;
      SetAminationPosition(0, 0);
      PlayActionAmination(bnum, 0);
      PlayMagicAmination(bnum, 36);
      ShowHurtValue(4);
    end;
  end;

end;

//使用暗器

procedure UseHiddenWeapen(bnum, inum: integer);
var
  rnum, bnum1, rnum1, hidden, step, hurt: integer;
  select: boolean;
begin
  calcanselect(bnum, 1);
  rnum := brole[bnum].rnum;
  hidden := rrole[rnum].HidWeapon;
  step := hidden div 15 + 1;
  if ritem[inum].UnKnow7 > 0 then
    callevent(ritem[inum].UnKnow7)
  else begin
    if (Brole[bnum].Team = 0) and (brole[bnum].Auto = 0) then
      select := selectaim(bnum, step);
    if (bfield[2, Ax, Ay] >= 0) and (select = true) and (brole[bfield[2, Ax, Ay]].Team <> 0) then
    begin
      Brole[bnum].Acted := 1;
      instruct_32(inum, -1);
      bnum1 := bfield[2, Ax, Ay];
      if brole[bnum1].Team <> Brole[bnum].Team then
      begin
        rnum1 := brole[bnum1].rnum;
        hurt := rrole[rnum].HidWeapon div 2 - ritem[inum].AddCurrentHP div 3;
        hurt := hurt * (rrole[rnum1].Hurt div 33 + 1);
        if hurt < 0 then hurt := 0;
        rrole[rnum1].CurrentHP := rrole[rnum1].CurrentHP - hurt;
        brole[bnum1].ShowNumber := hurt;
        SetAminationPosition(0, 0);
        PlayActionAmination(bnum, 0);
        PlayMagicAmination(bnum, ritem[inum].AmiNum);
        ShowHurtValue(0);
      end;
    end;
  end;

end;

//休息

procedure Rest(bnum: integer);
var
  rnum: integer;
begin
  Brole[bnum].Acted := 1;
  rnum := brole[bnum].rnum;
  RRole[rnum].CurrentHP := RRole[rnum].CurrentHP + RRole[rnum].MaxHP div 20;
  if RRole[rnum].CurrentHP > RRole[rnum].MaxHP then RRole[rnum].CurrentHP := RRole[rnum].MaxHP;
  RRole[rnum].CurrentMP := RRole[rnum].CurrentMP + RRole[rnum].MaxMP div 20;
  if RRole[rnum].CurrentMP > RRole[rnum].MaxMP then RRole[rnum].CurrentMP := RRole[rnum].MaxMP;
  rrole[rnum].PhyPower := rrole[rnum].PhyPower + MAX_PHYSICAL_POWER div 20;
  if rrole[rnum].PhyPower > MAX_PHYSICAL_POWER then rrole[rnum].PhyPower := MAX_PHYSICAL_POWER;

end;

//The AI.

procedure AutoBattle(bnum: integer);
var
  i, p, a, temp, rnum, inum, eneamount, aim, mnum, level, Ax1, Ay1, i1, i2, step, step1, dis0, dis: integer;
  str: widestring;
begin
  rnum := brole[bnum].rnum;
  showsimplestatus(rnum, 350, 50);
  sdl_delay(450);
  //showmessage('');
  //Life is less than 20%, 70% probality to medcine or eat a pill.
  //生命低于20%, 70%可能医疗或吃药
  if (Brole[bnum].Acted = 0) and (RRole[rnum].CurrentHP < RRole[rnum].MaxHP div 5) then
  begin
    if random(100) < 70 then
    begin
      //医疗大于50, 且体力大于50才对自身医疗
      if (Rrole[rnum].Medcine >= 50) and (rrole[rnum].PhyPower >= 50) and (random(100) < 50) then
      begin
        medcine(bnum);
      end else
      begin
        // if can't medcine, eat the item which can add the most life on its body.
        //无法医疗则选择身上加生命最多的药品, 我方从物品栏选择
        AutoUseItem(bnum, 45);
      end;
    end;
  end;

  //MP is less than 20%, 60% probality to eat a pill.
  //内力低于20%, 60%可能吃药
  if (Brole[bnum].Acted = 0) and (RRole[rnum].CurrentMP < RRole[rnum].MaxMP div 5) then
  begin
    if random(100) < 60 then
    begin
      AutoUseItem(bnum, 50);
    end;
  end;

  //Physical power is less than 20%, 80% probality to eat a pill.
  //体力低于20%, 80%可能吃药
  if (Brole[bnum].Acted = 0) and (rrole[rnum].PhyPower < MAX_PHYSICAL_POWER div 5) then
  begin
    if random(100) < 80 then
    begin
      AutoUseItem(bnum, 48);
    end;
  end;

  //如未能吃药且体力大于10, 则尝试攻击
  if (Brole[bnum].Acted = 0) and (rrole[rnum].PhyPower >= 10) then
  begin
    //在敌方选择一个人物
    eneamount := Calrnum(1 - Brole[bnum].Team);
    aim := random(eneamount) + 1;
    //showmessage(inttostr(eneamount));
    for i := 0 to broleamount - 1 do
    begin
      if (Brole[bnum].Team <> Brole[i].Team) and (Brole[i].Dead = 0) then
      begin
        aim := aim - 1;
        if aim <= 0 then break;
      end;
    end;
    //Seclect one enemy randomly and try to close it.
    //尝试走到离敌人最近的位置
    Ax := Bx;
    Ay := By;
    Ax1 := Brole[i].X;
    Ay1 := Brole[i].Y;
    CalCanSelect(bnum, 0);
    dis0 := abs(Ax1 - Bx) + abs(Ay1 - By);
    for i1 := min(Ax1, Bx) to max(Ax1, Bx) do
      for i2 := min(Ay1, By) to max(Ay1, By) do
      begin
        if Bfield[3, i1, i2] = 0 then
        begin
          dis := abs(Ax1 - i1) + abs(Ay1 - i2);
          if (dis < dis0) and (abs(i1 - Bx) + abs(i2 - By) <= brole[bnum].Step) then
          begin
            Ax := i1;
            Ay := i2;
            dis0 := dis;
          end;
        end;
      end;
    if Bfield[3, Ax, Ay] = 0 then MoveAmination(bnum);
    Ax := Brole[i].X;
    Ay := Brole[i].Y;

    //Try to attack it. select the best WUGONG.
    //使用目前最强的武功攻击
    p := 0;
    a := 0;
    temp := 0;
    for i1 := 0 to 9 do
    begin
      mnum := Rrole[rnum].Magic[i1];
      if mnum > 0 then
      begin
        a := a + 1;
        level := Rrole[rnum].MagLevel[i1] div 100 + 1;
        if RRole[rnum].CurrentMP < rmagic[mnum].NeedMP * ((level + 1) div 2) then level := RRole[rnum].CurrentMP div rmagic[mnum].NeedMP * 2;
        if level > 10 then level := 10;
        if level <= 0 then level := 1;
        if rmagic[mnum].Attack[level - 1] > temp then
        begin
          p := i1;
          temp := rmagic[mnum].Attack[level - 1];
        end;
      end;
    end;
    //5% probility to re-select WUGONG randomly.
    //5%的可能重新选择武功
    if random(100) < 5 then p := random(a);

    //If the most powerful Wugong can't attack the aim,
    //re-select the one which has the longest attatck-distance.
    //如最强武功打不到, 选择攻击距离最远的武功
    if abs(Ax - Bx) + abs(Ay - By) > step then
    begin
      p := 0;
      a := 0;
      temp := 0;
      for i1 := 0 to 9 do
      begin
        mnum := Rrole[rnum].Magic[i1];
        if mnum > 0 then
        begin
          level := Rrole[rnum].MagLevel[i1] div 100 + 1;
          a := rmagic[mnum].MoveDistance[level - 1];
          if rmagic[mnum].AttAreaType = 3 then a := a + rmagic[mnum].AttDistance[level - 1];
          if a > temp then
          begin
            p := i1;
            temp := a;
          end;
        end;
      end;
    end;

    mnum := Rrole[rnum].Magic[p];
    level := Rrole[rnum].MagLevel[p] div 100 + 1;
    step := rmagic[mnum].MoveDistance[level - 1];
    step1 := 0;
    if rmagic[mnum].AttAreaType = 3 then step1 := rmagic[mnum].AttDistance[level - 1];
    if abs(Ax - Bx) + abs(Ay - By) <= step + step1 then
    begin
      //step := Rmagic[mnum, 28+level-1];
      if (rmagic[mnum].AttAreaType = 3) then
      begin
        //step1 := Rmagic[mnum, 38+level-1];
        dis := 0;
        Ax1 := Bx;
        Ay1 := By;
        for i1 := min(Ax, Bx) to max(Ax, Bx) do
          for i2 := min(Ay, By) to max(Ay, By) do
          begin
            if (abs(i1 - Ax) <= step1) and (abs(i2 - Ay) <= step1) and (abs(i1 - Bx) + abs(i2 - By) <= step + step1) then
            begin
              if dis < abs(i1 - Bx) + abs(i2 - By) then
              begin
                dis := abs(i1 - Bx) + abs(i2 - By);
                Ax1 := i1;
                Ay1 := i2;
              end;
            end;
          end;
        Ax := Ax1;
        Ay := Ay1;
      end;
      if Rmagic[mnum].AttAreaType <> 3 then
        SetAminationPosition(Rmagic[mnum].AttAreaType, step)
      else
        SetAminationPosition(Rmagic[mnum].AttAreaType, step1);

      if bfield[4, Ax, Ay] <> 0 then
      begin
        Brole[bnum].Acted := 1;
        for i1 := 0 to sign(Rrole[rnum].AttTwice) do
        begin
          Rrole[rnum].MagLevel[p] := Rrole[rnum].MagLevel[p] + random(2) + 1;
          if Rrole[rnum].MagLevel[p] > 999 then Rrole[rnum].MagLevel[p] := 999;
          if rmagic[mnum].UnKnow[4] > 0 then callevent(rmagic[mnum].UnKnow[4])
          else AttackAction(bnum, mnum, level);
        end;
      end;
    end;
  end;

  //If all other actions fail, rest.
  //如果上面行动全部失败则休息
  if Brole[bnum].Acted = 0 then rest(bnum);

  //检查是否有esc被按下
  if SDL_PollEvent(@event) >= 0 then
  begin
    if (event.type_ = SDL_QUITEV) then
      if messagedlg('Are you sure to quit?', mtConfirmation, [mbOk, mbCancel], 0) = idOK then Quit;
    if (event.key.keysym.sym = sdlk_Escape) then
    begin
      brole[bnum].Auto := 0;
    end;
  end;
end;

//自动使用list的值最大的物品

procedure AutoUseItem(bnum, list: integer);
var
  i, p, temp, rnum, inum: integer;
  str: widestring;
begin
  rnum := brole[bnum].rnum;
  if Brole[bnum].Team <> 0 then
  begin
    temp := 0;
    p := -1;
    for i := 0 to 3 do
    begin
      if Rrole[rnum].TakingItem[i] >= 0 then
      begin
        if ritem[Rrole[rnum].TakingItem[i]].Data[list] > temp then
        begin
          temp := ritem[Rrole[rnum].TakingItem[i]].Data[list];
          p := i;
        end;
      end;
    end;
  end else
  begin
    temp := 0;
    p := -1;
    for i := 0 to MAX_ITEM_AMOUNT - 1 do
    begin
      if (RItemList[i].Amount > 0) and (ritem[RItemList[i].Number].ItemType = 3) then
      begin
        if ritem[RItemList[i].Number].Data[list] > temp then
        begin
          temp := ritem[RItemList[i].Number].Data[list];
          p := i;
        end;
      end;
    end;
  end;

  if p >= 0 then
  begin
    if Brole[bnum].Team <> 0 then
      inum := rrole[rnum].TakingItem[p]
    else
      inum := RItemList[p].Number;
    redraw;
    sdl_updaterect(screen, 0, 0, screen.w, screen.h);
    EatOneItem(rnum, inum);
    if Brole[bnum].Team <> 0 then
      instruct_41(rnum, rrole[rnum].TakingItem[p], -1)
    else
      instruct_32(RItemList[p].Number, -1);
    Brole[bnum].Acted := 1;
    sdl_delay(750);
  end;

end;

end.

