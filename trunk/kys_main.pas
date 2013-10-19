unit kys_main;

{$IFDEF fpc}
//{$MODE Delphi}
{$ELSE}

{$ENDIF}

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

{$IFDEF fpc}
  LMessages,
  LConvEncoding,
  LCLType,
  LCLIntf,
  FileUtil,
{$ELSE}
  Windows,
{$ENDIF}
  kys_type,
  SysUtils,
  Dialogs,
  Math,
  SDL_TTF,
  SDL_image,
  SDL,
  lua52,
  iniFiles,
  gl,
  glext,
  bass,
  zlib,
  ziputils,
  unzip;

//程序重要子程
procedure Run;
procedure Quit;
procedure SetMODVersion;
procedure ReadFiles;

//游戏开始画面, 行走等
procedure Start;
procedure StartAmi;
function InitialRole: boolean;
procedure LoadR(num: integer);
procedure SaveR(num: integer);
function WaitAnyKey: integer;
procedure Walk;
function CanWalk(x, y: integer): boolean;
function CheckEntrance: boolean;
procedure UpdateScenceAmi;
function WalkInScence(Open: integer): integer;
procedure findway(x1, y1: integer);
procedure Moveman(x1, y1, x2, y2: integer);
procedure ShowScenceName(snum: integer);
function CanWalkInScence(x, y: integer): boolean; overload;
function CanWalkInScence(x1, y1, x, y: integer): boolean; overload;
procedure CheckEvent1;
procedure CheckEvent3;

//选单子程
function CommonMenu(x, y, w, max: integer; menustring: array of WideString): integer; overload;
function CommonMenu(x, y, w, max, default: integer; menustring: array of WideString): integer; overload;
function CommonMenu(x, y, w, max: integer; menustring, menuengstring: array of WideString): integer; overload;
function CommonMenu(x, y, w, max, default: integer; menustring, menuengstring: array of WideString): integer; overload;
function CommonMenu(x, y, w, max, default: integer; menustring, menuengstring: array of WideString;
  fn: TPInt1): integer; overload;
procedure ShowCommonMenu(x, y, w, max, menu: integer; menustring: array of WideString); overload;
procedure ShowCommonMenu(x, y, w, max, menu: integer; menustring, menuengstring: array of WideString); overload;
function CommonScrollMenu(x, y, w, max, maxshow: integer; menustring: array of WideString): integer; overload;
function CommonScrollMenu(x, y, w, max, maxshow: integer; menustring, menuengstring: array of WideString): integer;
  overload;
procedure ShowCommonScrollMenu(x, y, w, max, maxshow, menu, menutop: integer;
  menustring, menuengstring: array of WideString);
function CommonMenu2(x, y, w: integer; menustring: array of WideString): integer;
procedure ShowCommonMenu2(x, y, w, menu: integer; menustring: array of WideString);
function SelectOneTeamMember(x, y: integer; str: string; list1, list2: integer): integer;
procedure MenuEsc;
procedure ShowMenu(menu: integer);
procedure MenuMedcine;
procedure MenuMedPoision;
function MenuItem: boolean;
function ReadItemList(ItemType: integer): integer;
procedure ReSort;
procedure ShowMenuItem(row, col, x, y, atlu: integer);
procedure DrawItemFrame(x, y: integer);
procedure UseItem(inum: integer);
function CanEquip(rnum, inum: integer): boolean;
procedure MenuStatus;
procedure ShowStatusByTeam(tnum: integer);
procedure ShowStatus(rnum: integer); overload;
procedure ShowStatus(rnum, x, y: integer); overload;
procedure MenuLeave;
procedure MenuSystem;
procedure ShowMenuSystem(menu: integer);
procedure MenuLoad;
function MenuLoadAtBeginning: integer;
procedure MenuSave;
procedure MenuQuit;

//医疗, 解毒, 使用物品的效果等
function EffectMedcine(role1, role2: integer): integer;
function EffectMedPoison(role1, role2: integer): integer;
procedure EatOneItem(rnum, inum: integer);

//事件系统
procedure CallEvent(num: integer);

//云的初始化和再次出现
procedure CloudCreate(num: integer);
procedure CloudCreateOnSide(num: integer);

function IsCave(snum: integer): boolean;

function round(x: real): integer;
procedure swap(var x, y: uint32); overload;
procedure UpdateAllScreen;
procedure CleanKeyValue;
procedure GetMousePosition(var x, y: integer; x0, y0: integer; yp: integer = 0);

implementation

uses
  kys_script,
  kys_event,
  kys_engine,
  kys_battle,
  kys_draw;

//初始化字体, 音效, 视频, 启动游戏

procedure Run;
begin

{$IFDEF UNIX}
  AppPath := ExtractFilePath(ParamStr(0));
{$ELSE}
  AppPath := '';
{$ENDIF}

  ReadFiles;

  SetMODVersion;

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
  //Mix_OpenAudio(MIX_DEFAULT_FREQUENCY, MIX_DEFAULT_FORMAT, 2, 16384);
  SoundFlag := 0;
  if SOUND3D = 1 then
    SoundFlag := BASS_DEVICE_3D or SoundFlag;
  BASS_Init(-1, 22050, SoundFlag, 0, nil);

  //初始化视频系统
  Randomize;
  //SDL_Init(SDL_INIT_VIDEO);
  if (SDL_Init(SDL_INIT_VIDEO) < 0) then
  begin
    MessageBox(0, PChar(Format('Couldn''t initialize SDL : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
    SDL_Quit;
    exit;
  end;

  SDL_WM_SetIcon(IMG_Load(PChar(AppPath + 'resource/icon.png')), 0);

  ScreenFlag := SDL_SWSURFACE or SDL_RESIZABLE
  {SDL_HWSURFACE or SDL_HWACCEL or SDL_ANYFORMAT or SDL_ASYNCBLIT or SDL_FULLSCREEN};
  if GLHR = 1 then
  begin
    ScreenFlag := SDL_OPENGL or SDL_RESIZABLE;
    SDL_GL_SetAttribute(SDL_GL_RED_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_GREEN_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_BLUE_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 8);
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
  end
  else
  begin
    HARDWARE_BLIT := 0;
  end;

  if HARDWARE_BLIT = 1 then
    ScreenFlag := ScreenFlag or SDL_HWSURFACE or SDL_HWACCEL;

  RealScreen := SDL_SetVideoMode(RESOLUTIONX, RESOLUTIONY, 32, ScreenFlag);
  RMask := $FF0000;
  GMask := $FF00;
  BMask := $FF;
  AMask := $FFFFFFFF - RMask - GMask - BMask;
  screen := SDL_CreateRGBSurface(ScreenFlag, CENTER_X * 2, CENTER_Y * 2, 32, RMask, GMask, BMask, 0);
  prescreen := SDL_CreateRGBSurface(ScreenFlag, CENTER_X * 2, CENTER_Y * 2, 32, RMask, GMask, BMask, 0);
  //prescreen := SDL_DisplayFormat(screen);
  freshscreen := SDL_CreateRGBSurface(ScreenFlag, CENTER_X * 2, CENTER_Y * 2, 32, RMask, GMask, BMask, 0);

  ImageWidth := (36 * 32 + CENTER_X) * 2;
  ImageHeight := (18 * 32 + CENTER_Y) * 2;

  ImgScence := SDL_CreateRGBSurface(screen.flags, ImageWidth, ImageHeight, 32, RMask, GMask, BMask, 0);
  //ImgScence := SDL_DisplayFormat(ImgScence);
  ImgScenceBack := SDL_CreateRGBSurface(screen.flags, ImageWidth, ImageHeight, 32, RMask, GMask, BMask, 0);
  ImgBField := SDL_CreateRGBSurface(screen.flags, ImageWidth, ImageHeight, 32, RMask, GMask, BMask, 0);
  ImgBBuild := SDL_CreateRGBSurface(screen.flags, ImageWidth, ImageHeight, 32, RMask, GMask, BMask, 0);
  SDL_SetColorKey(ImgScenceBack, SDL_SRCCOLORKEY, 1);
  SDL_SetColorKey(ImgBBuild, SDL_SRCCOLORKEY, 1);
  setlength(BlockImg, ImageWidth * ImageHeight);
  setlength(BlockImg2, ImageWidth * ImageHeight);
  {if GLHR = 1 then
  begin
    glBindTexture(GL_TEXTURE_2D, TextureID);
    glGenTextures(1, @TextureID);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, screen.w, screen.h, 0, GL_BGRA, GL_UNSIGNED_BYTE, prescreen.pixels);
  end;}

  if (RealScreen = nil) then
  begin
    MessageBox(0, PChar(Format('Couldn''t set 640x480x8 video mode : %s', [SDL_GetError])),
      'Error', MB_OK or MB_ICONHAND);
    SDL_Quit;
    halt(1);
  end;

  SDL_WM_SetCaption(PChar(TitleString), 's.weyl');

  InitialScript;
  InitialMusic;

  mutex := SDL_CreateMutex();

  Start;

  Quit;

end;

//关闭所有已打开的资源, 退出

procedure Quit;
begin
  FreeAllSurface;
  DestroyScript;
  TTF_CloseFont(font);
  TTF_CloseFont(engfont);
  TTF_Quit;
  SDL_DestroyMutex(mutex);
  SDL_Quit;
  BASS_Free;
  halt(1);
  exit;

end;

procedure SetMODVersion;
var
  filename: string;
  Kys_ini: TIniFile;
begin

  Setlength(Music, 24);
  Setlength(Esound, 53);
  Setlength(Asound, 25);
  StartMusic := 16;
  TitleString := 'All Heros in Kam Yung''s Stories - Replicated Edition';
  OpenPicPosition.x := CENTER_X - 320;
  OpenPicPosition.y := CENTER_Y - 220;
  TitlePosition.x := OpenPicPosition.x + 275;
  TitlePosition.y := OpenPicPosition.y + 125;
  //0-原版,
  //11-小猪闯江湖, 12-苍龙逐日, 13-金庸水浒传(未包含)
  //21-天书奇侠, 22-菠萝三国(含资料片), 23-笑梦游记, 24-前传(未包含)
  //31-再战江湖,
  //41-PTT
  //51-魏征
  //62-红颜录解密

  case MODVersion of
    0:
    begin

    end;
    11:
    begin
      TitleString := 'All Heros in Kam Yung''s Stories - A Pig';
      TitlePosition.y := 270;
      OpenPicPosition.y := OpenPicPosition.y + 20;
      CENTER_Y := 240;
    end;
    12:
    begin
      TitleString := 'All Heros in Kam Yung''s Stories - We Are Dragons';
      Setlength(Asound, 37);
      TitlePosition.x := 100;
      TitlePosition.y := 270;
    end;
    21:
    begin
      TitleString := 'All Heros in Kam Yung''s Stories - Books';
      TitlePosition.x := 275;
      TitlePosition.y := 285;
      Setlength(Esound, 59);
    end;
    22:
    begin
      TitleString := 'Why I have to go after a pineapple in the period of Three Kingdoms??';
      MAX_ITEM_AMOUNT := 456;
      Setlength(Music, 38);
      StartMusic := 37;
      CENTER_Y := 240;
    end;
    23:
    begin
      TitleString := 'All Heros in Kam Yung''s Stories - Four Dreams';
      //TitlePosition.x := 275;
      TitlePosition.y := 165;
      Setlength(Music, 25);
      Setlength(Esound, 84);
      StartMusic := 24;
      CENTER_Y := 240;
    end;
    31:
    begin
      TitleString := 'All Heros in Kam Yung''s Stories - Wider Rivers and Deeper Lakes';
      Setlength(Esound, 99);
      Setlength(Asound, 71);
    end;
    41:
    begin
      TitleString := 'All Heros in Kam Yung''s Stories - Here is PTT';
      TitlePosition.y := 255;
      OpenPicPosition.y := OpenPicPosition.y + 20;
      CENTER_Y := 240;
    end;
    51:
    begin
      TitleString := 'All Heros in Kam Yung''s Stories - An Prime Minister of Tang';
      //CHINESE_FONT_SIZE:= 16;
      //ENGLISH_FONT_SIZE:= 15;
    end;
    62:
    begin
      TitleString := 'All Heros in Kam Yung''s Stories - All for You';
      MAX_ITEM_AMOUNT := 968;
      CENTER_Y := 240;
      Setlength(Music, 195);
      BEGIN_WALKPIC := 5697;
    end;
  end;

{$IFDEF fpc}
  Filename := AppPath + 'kysmod.ini';
{$ELSE}
  Filename := ExtractFilePath(ParamStr(0)) + 'kysmod.ini';
{$ENDIF}
  Kys_ini := TIniFile.Create(filename);
  try
    RESOLUTIONX := Kys_ini.ReadInteger('system', 'RESOLUTIONX', CENTER_X * 2);
    RESOLUTIONY := Kys_ini.ReadInteger('system', 'RESOLUTIONY', CENTER_Y * 2);
  finally
    Kys_ini.Free;
  end;

end;

//读取必须的文件

procedure ReadFiles;
var
  grp, idx, tnum, len, col, i, k: integer;
  filename: string;
  Kys_ini: TIniFile;
  LoadPNGTilesThread: PSDL_Thread;
begin

{$IFDEF fpc}
  Filename := AppPath + 'kysmod.ini';
{$ELSE}
  Filename := ExtractFilePath(ParamStr(0)) + 'kysmod.ini';
{$ENDIF}
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
    BEGIN_WALKPIC := Kys_ini.ReadInteger('constant', 'BEGIN_WALKPIC', 2501);
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
    POISON_HURT := Kys_ini.ReadInteger('constant', 'POISON_HURT', 10);
    MED_LIFE := Kys_ini.ReadInteger('constant', 'MED_LIFE', 4);
    NOVEL_BOOK := Kys_ini.ReadInteger('constant', 'NOVEL_BOOK', 144);
    MAX_ADD_PRO := Kys_ini.ReadInteger('constant', 'MAX_ADD_PRO', 0);

    BATTLE_SPEED := Kys_ini.ReadInteger('system', 'BATTLE_SPEED', 10);
    WALK_SPEED := Kys_ini.ReadInteger('system', 'WALK_SPEED', 10);
    WALK_SPEED2 := Kys_ini.ReadInteger('system', 'WALK_SPEED2', WALK_SPEED);
    HARDWARE_BLIT := Kys_ini.ReadInteger('system', 'HARDWARE_BLIT', 1);
    SMOOTH := Kys_ini.ReadInteger('system', 'SMOOTH', 1);
    GLHR := Kys_ini.ReadInteger('system', 'GLHR', 1);
    CENTER_X := Kys_ini.ReadInteger('system', 'CENTER_X', 320);
    CENTER_Y := Kys_ini.ReadInteger('system', 'CENTER_Y', 220);
    RESOLUTIONX := Kys_ini.ReadInteger('system', 'RESOLUTIONX', CENTER_X * 2);
    RESOLUTIONY := Kys_ini.ReadInteger('system', 'RESOLUTIONY', CENTER_Y * 2);
    VOLUME := Kys_ini.ReadInteger('music', 'VOLUME', 30);
    VOLUMEWAV := Kys_ini.ReadInteger('music', 'VOLUMEWAV', 30);
    SOUND3D := Kys_ini.ReadInteger('music', 'SOUND3D', 1);
    MMAPAMI := Kys_ini.ReadInteger('system', 'MMAPAMI', 1);
    SCENCEAMI := Kys_ini.ReadInteger('system', 'SCENCEAMI', 2);
    SEMIREAL := Kys_ini.ReadInteger('system', 'SEMIREAL', 0);
    MODVersion := Kys_ini.ReadInteger('system', 'MODVersion', 0);
    CHINESE_FONT_SIZE := Kys_ini.ReadInteger('system', 'CHINESE_FONT_SIZE', 20);
    ENGLISH_FONT_SIZE := Kys_ini.ReadInteger('system', 'ENGLISH_FONT_SIZE', 19);
    KDEF_SCRIPT := Kys_ini.ReadInteger('system', 'KDEF_SCRIPT', 0);
    NIGHT_EFFECT := Kys_ini.ReadInteger('system', 'NIGHT_EFFECT', 0);
    EXIT_GAME := Kys_ini.ReadInteger('system', 'EXIT_GAME', 0);
    PNG_TILE := Kys_ini.ReadInteger('system', 'PNG_TILE', 0);
    TRY_FIND_GRP := Kys_ini.ReadInteger('system', 'TRY_FIND_GRP', 0);

    if (not FileExists(AppPath + 'resource/mmap/index.ka')) and
      (not FileExists(AppPath + 'resource/mmap.imz')) then
      PNG_TILE := 0;

    for i := 43 to 58 do
    begin
      MaxProList[i] := Kys_ini.ReadInteger('constant', 'MaxProList' + IntToStr(i), 100);
    end;

    if LIFE_HURT = 0 then
      LIFE_HURT := 1;
    if POISON_HURT = 0 then
      POISON_HURT := 1;

  finally
    Kys_ini.Free;
  end;

  ReadFileToBuffer(@ACol[0], AppPath + 'resource/mmap.col', 768, 0);
  move(ACol[0], ACol1[0], 768);
  move(ACol[0], ACol2[0], 768);

  ReadFileToBuffer(@Earth[0, 0], AppPath + 'resource/earth.002', 480 * 480 * 2, 0);
  ReadFileToBuffer(@surface[0, 0], AppPath + 'resource/surface.002', 480 * 480 * 2, 0);
  ReadFileToBuffer(@Building[0, 0], AppPath + 'resource/building.002', 480 * 480 * 2, 0);
  ReadFileToBuffer(@Buildx[0, 0], AppPath + 'resource/Buildx.002', 480 * 480 * 2, 0);
  ReadFileToBuffer(@Buildy[0, 0], AppPath + 'resource/Buildy.002', 480 * 480 * 2, 0);

  ReadFileToBuffer(@leavelist[0], AppPath + 'list/leave.bin', 200, 0);
  ReadFileToBuffer(@effectlist[0], AppPath + 'list/effect.bin', 200, 0);
  ReadFileToBuffer(@leveluplist[0], AppPath + 'list/levelup.bin', 200, 0);

  ReadFileToBuffer(@matchlist[0], AppPath + 'list/match.bin', MAX_WEAPON_MATCH * 3 * 2, 0);

  LoadIdxGrp('resource/kdef.idx', 'resource/kdef.grp', KIdx, KDef);
  LoadIdxGrp('resource/talk.idx', 'resource/talk.grp', TIdx, TDef);

end;

//Main game.
//显示开头画面

procedure Start;
var
  menu, menup, i, col, i1, i2, x, y, k: integer;
  Selected: boolean;
begin
  PlayMP3(StartMusic, -1);

  where := 3;
  Redraw;

  if PNG_TILE > 0 then
  begin
    LoadPNGTiles('resource/title', TitlePNGIndex, TitlePNGTile, 1);
    DrawTitlePic(8, TitlePosition.x, TitlePosition.y + 20);
  end;

  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

  ReadTiles;

  begin_time := random(1440);
  now_time := begin_time;

  for i1 := 0 to 479 do
    for i2 := 0 to 479 do
      Entrance[i1, i2] := -1;

  SDL_EnableKeyRepeat(0, 10);
  MStep := 0;
  FULLSCREEN := 0;
  menu := 0;
  SetLength(Cloud, CLOUD_AMOUNT);
  for i := 0 to CLOUD_AMOUNT - 1 do
  begin
    CloudCreate(i);
  end;

  x := TitlePosition.x;
  y := TitlePosition.y;
  Redraw;
  DrawTitlePic(0, x, y);
  DrawTitlePic(menu + 1, x, y + menu * 20);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

  //事件等待
  Selected := False;
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    CheckBasicEvent;
    case event.type_ of //键盘事件
      SDL_KEYUP:
      begin
        if ((event.key.keysym.sym = SDLK_RETURN) or (event.key.keysym.sym = SDLK_SPACE)) then
        begin
          Selected := True;
        end;
        //按下方向键上
        if event.key.keysym.sym = SDLK_UP then
        begin
          menu := menu - 1;
          if menu < 0 then
            menu := 2;
          DrawTitlePic(0, x, y);
          DrawTitlePic(menu + 1, x, y + menu * 20);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
        //按下方向键下
        if event.key.keysym.sym = SDLK_DOWN then
        begin
          menu := menu + 1;
          if menu > 2 then
            menu := 0;
          DrawTitlePic(0, x, y);
          DrawTitlePic(menu + 1, x, y + menu * 20);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
      end;
      //按下鼠标(UP表示抬起按键才执行)
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = SDL_BUTTON_LEFT) and (round(event.button.x / (RealScreen.w / screen.w)) > x) and
          (round(event.button.x / (RealScreen.w / screen.w)) < x + 80) and
          (round(event.button.y / (RealScreen.h / screen.h)) > y) and
          (round(event.button.y / (RealScreen.h / screen.h)) < y + 60) then
        begin
          Selected := True;
        end;
      end;
      //鼠标移动
      SDL_MOUSEMOTION:
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
            DrawTitlePic(0, x, y);
            DrawTitlePic(menu + 1, x, y + menu * 20);
            SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          end;
        end;
      end;
    end;
    if Selected then
    begin
      case menu of
        2:
          break;
        1:
        begin
          if MenuLoadAtBeginning >= 0 then
          begin
            //redraw;
            //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            CurEvent := -1; //when CurEvent=-1, Draw scence by Sx, Sy. Or by Cx, Cy.
            if where = 1 then
            begin
              WalkInScence(0);
            end;
            Walk;
            //menu := -1;
          end;
        end;
        0:
        begin
          Selected := InitialRole;
          if Selected then
          begin
            CurScence := BEGIN_SCENCE;
            CurEvent := -1;
            WalkInScence(1);
            Walk;
            //menu := -1;
          end;
        end;
      end;
      Redraw;
      DrawTitlePic(0, x, y);
      DrawTitlePic(menu + 1, x, y + menu * 20);
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      Selected := False;
    end;
  end;

end;

//开头字幕

procedure StartAmi;
var
  x, y, i, len: integer;
  str: WideString;
  p: integer;
begin
  instruct_14;
  Redraw;
  i := FileOpen(PChar(AppPath + 'list/start.txt'), fmOpenRead);
  len := FileSeek(i, 0, 2);
  FileSeek(i, 0, 0);
  setlength(str, len + 1);
  FileRead(i, str[1], len);
  FileClose(i);
  p := 1;
  x := 30;
  y := 80;
  DrawRectangleWithoutFrame(screen, 0, 0, CENTER_X * 2, CENTER_Y * 2, 0, 60);
  for i := 1 to len + 1 do
  begin
    if str[i] = widechar(10) then
      str[i] := ' ';
    if str[i] = widechar(13) then
    begin
      str[i] := widechar(0);
      DrawShadowText(screen, @str[p], x, y, ColColor($FF), ColColor($FF));
      p := i + 1;
      y := y + 25;
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    end;
    if str[i] = widechar($2A) then
    begin
      str[i] := ' ';
      y := 80;
      Redraw;
      WaitAnyKey;
      DrawRectangleWithoutFrame(screen, 0, 50, CENTER_X * 2, CENTER_Y * 2 - 100, 0, 60);
    end;
  end;
  WaitAnyKey;
  instruct_14;
  //instruct_13;

end;

//初始化主角属性

function InitialRole: boolean;
var
  i: integer;
  p: array[0..14] of integer;
  str, str0: WideString;
  str1, str2, tempname: string;
{$IFDEF fpc}
  Name, homename: string;
{$ELSE}
  Name, homename: WideString;
{$ENDIF}
  p0, p1: PChar;
  named: boolean;
begin
  LoadR(0);
  //显示输入姓名的对话框
  //form1.ShowModal;
  //str := form1.edit1.text;
  str1 := '請以繁體中文輸入主角之姓名，選定屬性後按Enter, Esc或滑鼠按鍵     ';
  //name := InputBox('Enter name', str1, '我是主角');
  where := 3;
  tempname := '我是主角';
  homename := '主角的家';
  named := InputQuery('Enter name', str1, ansistring(tempname));
  Name := tempname;

  if named then
  begin
    if Name = '' then
    begin
      Name := ' ';
    end;

{$IFDEF fpc}
    str1 := UTF8ToCP950(Name);
    if (length(str1) in [1..7]) and (Name <> ' ') then
      homename := Name + '居';
    str2 := UTF8ToCP950(homename);
{$ELSE}
    str1 := UnicodeToBig5(@Name[1]);
    if (length(str1[1]) in [1..7]) and (Name <> ' ') then
      homename := Name + '居';
    str2 := UnicodeToBig5(@homename[1]);
{$ENDIF}
    p0 := @Rrole[0].Name;
    p1 := @str1[1];
    for i := 0 to 4 do
      Rrole[0].Data[4 + i] := 0;
    for i := 0 to 7 do
    begin
      (p0 + i)^ := (p1 + i)^;
    end;

    if (MODVersion <> 22) and (MODVersion <> 11) and (MODVersion <> 12) then
    begin
      p0 := @Rscence[BEGIN_SCENCE].Name;
      p1 := @str2[1];
      for i := 0 to 4 do
        Rscence[BEGIN_SCENCE].Data[1 + i] := 0;
      for i := 0 to 8 do
      begin
        (p0 + i)^ := (p1 + i)^;
      end;
    end;

    Redraw;

    str := (' 資質');
    repeat
      if MODVersion <> 21 then
      begin
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

      end;

      Rrole[0].Aptitude := 1 + random(100);

      if MODVersion = 0 then
      begin
        Rrole[0].Magic[0] := 1;
        if random(100) < 70 then
          Rrole[0].Magic[0] := random(93);
      end;
      if MODVersion = 31 then
        Rrole[0].Ethics := random(50) + random(50);

      if MODVersion = 41 then
      begin
        Rrole[0].Magic[0] := 0;
      end;

      Redraw;
      ShowStatus(0);
      DrawShadowText(screen, @str[1], 30, CENTER_Y + 111, ColColor($23), ColColor($21));
      str0 := format('%4d', [Rrole[0].Aptitude]);
      DrawEngShadowText(screen, @str0[1], 150, CENTER_Y + 111, ColColor($66), ColColor($63));
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      i := WaitAnyKey;
    until (i = SDLK_ESCAPE) or (i = SDLK_RETURN);

    if MODVersion = 0 then
    begin
      if Name = 'TXDX尊使' then
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

        Rrole[0].Aptitude := 100;
        Rrole[0].Magic[0] := 62;
        Rrole[0].MagLevel[0] := 800;

        Rmagic[62].Attack[9] := 2000;

        Ritem[93].Magic := 26;
        Ritem[66].OnlyPracRole := -1;
        Ritem[79].OnlyPracRole := -1;

        instruct_32(82, 1);
        instruct_32(74, 1);

      end;
      Rrole[13].Magic[1] := 91;
    end;

    if MODVersion = 22 then
    begin
      if Name = 'k小邪' then
      begin
        Rrole[0].MaxHP := 50;
        Rrole[0].CurrentHP := 50;
        Rrole[0].MaxMP := 50;
        Rrole[0].CurrentMP := 50;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 150;
        Rrole[0].Speed := 150;
        Rrole[0].Defence := 130;
        Rrole[0].Medcine := 130;
        Rrole[0].UsePoi := 130;
        Rrole[0].MedPoi := 130;
        Rrole[0].Fist := 130;
        Rrole[0].Sword := 130;
        Rrole[0].Knife := 130;
        Rrole[0].Unusual := 130;
        Rrole[0].HidWeapon := 130;

        Rrole[0].Aptitude := 100;

        Rrole[0].Knowledge := 85;

        Rrole[0].Magic[0] := 94;
        Rrole[0].MagLevel[0] := 850;
        Rrole[0].Magic[1] := 93;

        Rrole[0].AttPoi := 0;
      end;

      if Name = '龍吟星落' then
      begin
        Rrole[0].MaxHP := 150;
        Rrole[0].CurrentHP := 120;
        Rrole[0].MaxMP := 150;
        Rrole[0].CurrentMP := 220;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 130;
        Rrole[0].Speed := 130;
        Rrole[0].Defence := 130;
        Rrole[0].Medcine := 130;
        Rrole[0].UsePoi := 130;
        Rrole[0].MedPoi := 130;
        Rrole[0].Fist := 130;
        Rrole[0].Sword := 130;
        Rrole[0].Knife := 130;
        Rrole[0].Unusual := 130;
        Rrole[0].HidWeapon := 130;

        Rrole[0].Aptitude := 100;

        Rrole[0].Knowledge := 0;

        Rrole[0].Magic[0] := 168;
        Rrole[0].Magic[1] := 169;
        Rrole[0].Magic[2] := 170;
        Rrole[0].Magic[3] := 171;
        Rrole[0].Magic[4] := 172;
      end;

      if Name = '小隨' then
      begin
        Rrole[0].MaxHP := 150;
        Rrole[0].CurrentHP := 120;
        Rrole[0].MaxMP := 150;
        Rrole[0].CurrentMP := 220;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 130;
        Rrole[0].Speed := 130;
        Rrole[0].Defence := 130;
        Rrole[0].Medcine := 130;
        Rrole[0].UsePoi := 130;
        Rrole[0].MedPoi := 130;
        Rrole[0].Fist := 130;
        Rrole[0].Sword := 130;
        Rrole[0].Knife := 130;
        Rrole[0].Unusual := 130;
        Rrole[0].HidWeapon := 130;

        Rrole[0].Aptitude := 100;

        Rrole[0].Knowledge := 0;

        Rrole[0].Magic[0] := 94;
        Rrole[0].MagLevel[0] := 850;

        Rrole[0].AttTwice := 1;
      end;

      if Name = '破大俠' then
      begin
        Rrole[0].MaxHP := 1150;
        Rrole[0].CurrentHP := 1120;
        Rrole[0].MaxMP := 1150;
        Rrole[0].CurrentMP := 1220;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 230;
        Rrole[0].Speed := 230;
        Rrole[0].Defence := 230;
        Rrole[0].Medcine := 230;
        Rrole[0].UsePoi := 230;
        Rrole[0].MedPoi := 230;
        Rrole[0].Fist := 230;
        Rrole[0].Sword := 230;
        Rrole[0].Knife := 230;
        Rrole[0].Unusual := 230;
        Rrole[0].HidWeapon := 230;

        Rrole[0].Aptitude := 100;

        Rrole[0].Knowledge := 100;

        Rrole[0].Magic[0] := 168;
        Rrole[0].Magic[1] := 169;
        Rrole[0].Magic[2] := 170;
        Rrole[0].Magic[3] := 171;
        Rrole[0].Magic[4] := 172;
        Rrole[0].Magic[5] := 94;

        //rrole[0].AttTwice := 1;
      end;

      if Name = '鳳凰' then
      begin
        Rrole[0].MaxHP := 250;
        Rrole[0].CurrentHP := 50;
        Rrole[0].MaxMP := 250;
        Rrole[0].CurrentMP := 50;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;
        Rrole[0].Aptitude := 100;
        for i := 1 to 14 do
        begin
          Rrole[i].MaxHP := 500;
          Rrole[i].CurrentHP := 500;
          Rrole[i].MaxMP := 500;
          Rrole[i].CurrentMP := 500;
          Rrole[i].MPType := 2;
          Rrole[i].IncLife := 30;

          Rrole[i].Attack := 300;
          Rrole[i].Speed := 100;
          Rrole[i].Defence := 130;
          Rrole[i].Medcine := 130;
          Rrole[i].UsePoi := 130;
          Rrole[i].MedPoi := 130;
          Rrole[i].Fist := 130;
          Rrole[i].Sword := 130;
          Rrole[i].Knife := 130;
          Rrole[i].Unusual := 130;
          Rrole[i].HidWeapon := 130;

          Rrole[i].Aptitude := 100;
        end;
      end;
    end;

    if MODVersion = 23 then
    begin
      if Name = '小小豬' then
      begin
        Rrole[0].MaxHP := 10;
        Rrole[0].CurrentHP := 10;
        Rrole[0].MaxMP := 50;
        Rrole[0].CurrentMP := 50;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 10;
        Rrole[0].Speed := 10;
        Rrole[0].Defence := 30;
        Rrole[0].Medcine := 30;
        Rrole[0].UsePoi := 30;
        Rrole[0].MedPoi := 30;
        Rrole[0].Fist := 30;
        Rrole[0].Sword := 30;
        Rrole[0].Knife := 30;
        Rrole[0].Unusual := 30;
        Rrole[0].HidWeapon := 30;

        Rrole[0].Aptitude := 100;

        Rrole[0].Knowledge := 0;

        Rrole[0].Magic[0] := 27;
        Rrole[0].MagLevel[0] := 850;
        Rrole[0].Magic[1] := 37;
        Rrole[0].MagLevel[1] := 850;
        Rrole[0].Magic[2] := 94;
        Rrole[0].MagLevel[2] := 850;
        Rrole[0].Magic[3] := 62;
        Rrole[0].MagLevel[3] := 850;

        Rrole[0].AttPoi := 0;
      end;

      if Name = 'k小邪' then
      begin
        Rrole[0].MaxHP := 150;
        Rrole[0].CurrentHP := 120;
        Rrole[0].MaxMP := 150;
        Rrole[0].CurrentMP := 220;
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

        Rrole[0].Aptitude := 100;

        Rrole[0].Knowledge := 0;

        Rrole[0].Magic[0] := 27;
        Rrole[0].MagLevel[0] := 850;

        Rrole[0].AttPoi := 70;

        Rrole[0].Magic[1] := 15;

        for i := 0 to 9 do
        begin
          Rmagic[15].Attack[i] := 1400;
          Rmagic[16].Attack[i] := 1400;
          Rmagic[17].Attack[i] := 1000;
          Rmagic[15].AttDistance[i] := 6;
          Rmagic[16].AttDistance[i] := 4;
          Rmagic[17].AttDistance[i] := 8;
        end;
      end;

      if Name = '南宮夢' then
      begin
        Rrole[0].MaxHP := 500;
        Rrole[0].CurrentHP := 500;
        Rrole[0].MaxMP := 500;
        Rrole[0].CurrentMP := 500;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 70;
        Rrole[0].Speed := 90;
        Rrole[0].Defence := 30;
        Rrole[0].Medcine := 30;
        Rrole[0].UsePoi := 30;
        Rrole[0].MedPoi := 30;
        Rrole[0].Fist := 30;
        Rrole[0].Sword := 60;
        Rrole[0].Knife := 30;
        Rrole[0].Unusual := 30;
        Rrole[0].HidWeapon := 30;

        Rrole[0].Aptitude := 100;

        Rrole[0].Knowledge := 0;

        Rrole[0].Magic[0] := 37;
        Rrole[0].MagLevel[0] := 890;

        Rmagic[37].AttAreaType := 3;
        Rmagic[37].MoveDistance[9] := 4;
        Rmagic[37].AttDistance[9] := 4;
      end;

      if Name = '游客' then
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

        Rrole[0].Aptitude := 100;

        Rrole[0].Knowledge := 0;

        Rrole[0].Magic[0] := 94;
        Rrole[0].MagLevel[0] := 850;

        Rrole[0].AttTwice := 1;
      end;

      if Name = '飛蟲王' then
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

        Rrole[0].Aptitude := 100;

        Rrole[0].Knowledge := 60;

        Rrole[0].Magic[0] := 62;
        Rrole[0].MagLevel[0] := 850;

        Rrole[0].AttPoi := 95;
      end;

      if Name = '破劍式' then
      begin
        Rrole[0].MaxHP := 499;
        Rrole[0].CurrentHP := 499;
        Rrole[0].MaxMP := 499;
        Rrole[0].CurrentMP := 499;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 5;

        Rrole[0].Attack := 90;
        Rrole[0].Speed := 90;
        Rrole[0].Defence := 90;
        Rrole[0].Medcine := 90;
        Rrole[0].UsePoi := 90;
        Rrole[0].MedPoi := 90;
        Rrole[0].Fist := 90;
        Rrole[0].Sword := 90;
        Rrole[0].Knife := 90;
        Rrole[0].Unusual := 90;
        Rrole[0].HidWeapon := 90;

        Rrole[0].Aptitude := 100;

        Rrole[0].Knowledge := 0;

        Rrole[0].Magic[0] := 27;
        Rrole[0].MagLevel[0] := 899;
        Rrole[0].Magic[1] := 37;
        Rrole[0].MagLevel[1] := 899;
        Rrole[0].Magic[2] := 94;
        Rrole[0].MagLevel[2] := 899;
        Rrole[0].Magic[3] := 62;
        Rrole[0].MagLevel[3] := 899;

        Rrole[0].AttPoi := 90;
      end;

      if Name = '9523' then
      begin
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 10;
        Rrole[0].Speed := 10;
        Rrole[0].Defence := 30;
        Rrole[0].Medcine := 30;
        Rrole[0].UsePoi := 30;
        Rrole[0].MedPoi := 30;
        Rrole[0].Fist := 30;
        Rrole[0].Sword := 30;
        Rrole[0].Knife := 30;
        Rrole[0].Unusual := 30;
        Rrole[0].HidWeapon := 30;

        Rrole[0].Aptitude := 100;

        for i := 0 to 9 do
        begin
          Rmagic[15].Attack[i] := 1400;
          Rmagic[16].Attack[i] := 1400;
          Rmagic[17].Attack[i] := 1000;
          Rmagic[15].AttDistance[i] := 6;
          Rmagic[16].AttDistance[i] := 4;
          Rmagic[17].AttDistance[i] := 8;
        end;

        Rrole[0].Magic[0] := 15;
        Rrole[0].Magic[1] := 16;
        Rrole[0].Magic[2] := 17;
      end;

      if Name = '鳳凰ice' then
      begin
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;
        Rrole[0].Aptitude := 100;
        for i := 0 to 99 do
        begin
          if leavelist[i] > 0 then
          begin
            Rrole[leavelist[i]].IncLife := 30;
            Rrole[leavelist[i]].MPType := 2;
            Rrole[leavelist[i]].Attack := 90;
            Rrole[leavelist[i]].Aptitude := 95;
          end;
        end;
      end;
      Rrole[401] := Rrole[0];
      Rrole[402] := Rrole[0];
      Rrole[403] := Rrole[0];
      Rrole[404] := Rrole[0];
    end;

    if MODVersion = 11 then
    begin
      if Name = '小小豬' then
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

        Rrole[0].Aptitude := 100;
        Rrole[0].Ethics := 90;
        //rrole[0].Magic[0] := 62;
        //rrole[0].MagLevel[0] := 800;

        //rmagic[62].Attack[9] := 2000;

        //ritem[93].Magic := 26;
        //ritem[66].OnlyPracRole := -1;
        //ritem[79].OnlyPracRole := -1;

        //instruct_32(82, 1);
        //instruct_32(74, 1);

      end;

      if Name = '晴空飛雪' then
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

        Rrole[0].Aptitude := 100;

        //rrole[0].Magic[0] := 62;
        //rrole[0].MagLevel[0] := 800;

        //rmagic[62].Attack[9] := 2000;

        //ritem[93].Magic := 26;
        //ritem[66].OnlyPracRole := -1;
        //ritem[79].OnlyPracRole := -1;

        instruct_32(19, 10000);
        //instruct_32(74, 1);

      end;
    end;

    if MODVersion = 12 then
    begin
      if Name = '小小豬' then
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

        Rrole[0].Aptitude := 100;
      end;
      if Name = '見賢思齊' then
      begin
        Rrole[0].MaxHP := 50;
        Rrole[0].CurrentHP := 50;
        Rrole[0].MaxMP := 50;
        Rrole[0].CurrentMP := 50;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 60;
        Rrole[0].Speed := 30;
        Rrole[0].Defence := 60;
        Rrole[0].Medcine := 30;
        Rrole[0].UsePoi := 30;
        Rrole[0].MedPoi := 30;
        Rrole[0].Fist := 30;
        Rrole[0].Sword := 30;
        Rrole[0].Knife := 30;
        Rrole[0].Unusual := 30;
        Rrole[0].HidWeapon := 30;

        Rrole[0].Aptitude := 45;
      end;
    end;

    if MODVersion = 31 then
    begin
      if Name = '南宮夢' then
      begin
        Rrole[0].MaxHP := 50;
        Rrole[0].CurrentHP := 50;
        Rrole[0].MaxMP := 50;
        Rrole[0].CurrentMP := 50;
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 10;

        Rrole[0].Attack := 300;
        Rrole[0].Speed := 30;
        Rrole[0].Defence := 300;
        Rrole[0].Medcine := 300;
        Rrole[0].UsePoi := 30;
        Rrole[0].MedPoi := 30;
        Rrole[0].Fist := 30;
        Rrole[0].Sword := 300;
        Rrole[0].Knife := 30;
        Rrole[0].Unusual := 30;
        Rrole[0].HidWeapon := 300;

        Rrole[0].Aptitude := 100;
        Rrole[0].Ethics := 95;
      end;
    end;

    if MODVersion = 41 then
    begin
      if Name = 'leo' then
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

        Rrole[0].Aptitude := 100;
      end;
    end;

    if MODVersion = 21 then
    begin
      if (Name = '古天奇') or (Name = '青狼火花') then
      begin
        Rrole[0].MPType := 2;
        Rrole[0].IncLife := 20;
        Rrole[0].Aptitude := 100;
      end;
    end;

    ShowStatus(0);
    DrawShadowText(screen, @str[1], 30, CENTER_Y + 111, ColColor($23), ColColor($21));
    str0 := format('%4d', [Rrole[0].Aptitude]);
    DrawEngShadowText(screen, @str0[1], 150, CENTER_Y + 111, ColColor($66), ColColor($63));
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

    StartAmi;
  end;
  //EndAmi;
  Result := named;

end;

//读入存档, 如为0则读入起始存档

procedure LoadR(num: integer);
var
  filename: string;
  idx, grp, i1, i2, len, ScenceAmount: integer;
  BasicOffset, RoleOffset, ItemOffset, ScenceOffset, MagicOffset, WeiShopOffset, i: integer;
begin
  SaveNum := num;
  filename := 'r' + IntToStr(num);

  if num = 0 then
    filename := 'ranger';
  idx := FileOpen(AppPath + 'save/ranger.idx', fmopenread);
  grp := FileOpen(AppPath + 'save/' + filename + '.grp', fmopenread);

  FileRead(idx, RoleOffset, 4);
  FileRead(idx, ItemOffset, 4);
  FileRead(idx, ScenceOffset, 4);
  FileRead(idx, MagicOffset, 4);
  FileRead(idx, WeiShopOffset, 4);
  FileRead(idx, len, 4);
  FileSeek(grp, 0, 0);

  FileRead(grp, Inship, 2);
  FileRead(grp, UseLess1, 2);
  FileRead(grp, My, 2);
  FileRead(grp, Mx, 2);
  FileRead(grp, Sy, 2);
  FileRead(grp, Sx, 2);
  FileRead(grp, Mface, 2);
  FileRead(grp, shipx, 2);
  FileRead(grp, shipy, 2);
  FileRead(grp, shipx1, 2);
  FileRead(grp, shipy1, 2);
  FileRead(grp, shipface, 2);
  FileRead(grp, teamlist[0], 2 * 6);
  if MODVersion = 62 then
    FileSeek(grp, 24, 1);

  Setlength(RItemlist, MAX_ITEM_AMOUNT);
  for i := 0 to MAX_ITEM_AMOUNT - 1 do
  begin
    RItemlist[i].Number := -1;
    RItemlist[i].Amount := 0;
  end;
  FileRead(grp, Ritemlist[0], sizeof(Titemlist) * MAX_ITEM_AMOUNT);

  FileRead(grp, Rrole[0], ItemOffset - RoleOffset);
  FileRead(grp, Ritem[0], ScenceOffset - ItemOffset);
  FileRead(grp, Rscence[0], MagicOffset - ScenceOffset);
  FileRead(grp, Rmagic[0], WeiShopOffset - MagicOffset);
  FileRead(grp, Rshop[0], len - WeiShopOffset);
  FileClose(idx);
  FileClose(grp);

  //初始化入口

  ScenceAmount := (MagicOffset - ScenceOffset) div 52;
  for i := 0 to ScenceAmount - 1 do
  begin
    if (Rscence[i].MainEntranceX1 >= 0) and (Rscence[i].MainEntranceX1 < 480) and
      (Rscence[i].MainEntranceY1 >= 0) and (Rscence[i].MainEntranceY1 < 480) then
      Entrance[Rscence[i].MainEntranceX1, Rscence[i].MainEntranceY1] := i;
    if (Rscence[i].MainEntranceX2 >= 0) and (Rscence[i].MainEntranceX2 < 480) and
      (Rscence[i].MainEntranceY2 >= 0) and (Rscence[i].MainEntranceY2 < 480) then
      Entrance[Rscence[i].MainEntranceX2, Rscence[i].MainEntranceY2] := i;
  end;
  //showmessage(inttostr(useless1));
  if UseLess1 > 0 then
  begin
    CurScence := UseLess1 - 1;
    where := 1;
  end
  else
  begin
    CurScence := -1;
    where := 0;
  end;

  filename := 's' + IntToStr(num);
  if num = 0 then
    filename := 'allsin';
  grp := FileOpen(AppPath + 'save/' + filename + '.grp', fmopenread);
  FileRead(grp, Sdata[0, 0, 0, 0], ScenceAmount * 64 * 64 * 6 * 2);
  FileClose(grp);
  filename := 'd' + IntToStr(num);
  if num = 0 then
    filename := 'alldef';
  grp := FileOpen(AppPath + 'save/' + filename + '.grp', fmopenread);
  FileRead(grp, Ddata[0, 0, 0], ScenceAmount * 200 * 11 * 2);
  FileClose(grp);

end;

//存档

procedure SaveR(num: integer);
var
  filename: string;
  idx, grp, i1, i2, length, ScenceAmount: integer;
  BasicOffset, RoleOffset, ItemOffset, ScenceOffset, MagicOffset, WeiShopOffset, i: integer;
begin
  SaveNum := num;
  filename := 'r' + IntToStr(num);

  if num = 0 then
    filename := 'ranger';
  idx := FileOpen(AppPath + 'save/ranger.idx', fmopenread);
  grp := filecreate(AppPath + 'save/' + filename + '.grp', fmopenreadwrite);
  BasicOffset := 0;
  FileRead(idx, RoleOffset, 4);
  FileRead(idx, ItemOffset, 4);
  FileRead(idx, ScenceOffset, 4);
  FileRead(idx, MagicOffset, 4);
  FileRead(idx, WeiShopOffset, 4);
  FileRead(idx, length, 4);
  FileSeek(grp, 0, 0);
  FileWrite(grp, Inship, 2);

  if Where = 1 then
    UseLess1 := CurScence + 1
  else
    UseLess1 := 0;

  FileWrite(grp, UseLess1, 2);
  FileWrite(grp, My, 2);
  FileWrite(grp, Mx, 2);
  FileWrite(grp, Sy, 2);
  FileWrite(grp, Sx, 2);
  FileWrite(grp, Mface, 2);
  FileWrite(grp, shipx, 2);
  FileWrite(grp, shipy, 2);
  FileWrite(grp, shipx1, 2);
  FileWrite(grp, shipy1, 2);
  FileWrite(grp, shipface, 2);
  FileWrite(grp, teamlist[0], 2 * 6);
  if MODVersion = 62 then
    FileSeek(grp, 24, 1);
  FileWrite(grp, Ritemlist[0], sizeof(Titemlist) * MAX_ITEM_AMOUNT);

  FileWrite(grp, Rrole[0], ItemOffset - RoleOffset);
  FileWrite(grp, Ritem[0], ScenceOffset - ItemOffset);
  FileWrite(grp, Rscence[0], MagicOffset - ScenceOffset);
  FileWrite(grp, Rmagic[0], WeiShopOffset - MagicOffset);
  FileWrite(grp, Rshop[0], length - WeiShopOffset);
  FileClose(idx);
  FileClose(grp);

  ScenceAmount := (MagicOffset - ScenceOffset) div 52;

  filename := 's' + IntToStr(num);
  if num = 0 then
    filename := 'allsin';
  grp := filecreate(AppPath + 'save/' + filename + '.grp');
  FileWrite(grp, Sdata[0, 0, 0, 0], ScenceAmount * 64 * 64 * 6 * 2);
  FileClose(grp);
  filename := 'd' + IntToStr(num);
  if num = 0 then
    filename := 'alldef';
  grp := filecreate(AppPath + 'save/' + filename + '.grp');
  FileWrite(grp, Ddata[0, 0, 0], ScenceAmount * 200 * 11 * 2);
  FileClose(grp);

end;

//等待任意按键

function WaitAnyKey: integer;
begin
  //event.type_ := SDL_NOEVENT;
  event.key.keysym.sym := 0;
  event.button.button := 0;
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    CheckBasicEvent;
    if (event.type_ = SDL_KEYUP) or (event.type_ = SDL_MOUSEBUTTONUP) then
      if (event.key.keysym.sym <> 0) or (event.button.button <> 0) then
        break;
  end;
  Result := event.key.keysym.sym;
  if event.button.button = SDL_BUTTON_RIGHT then
    Result := SDLK_ESCAPE;
  if event.button.button = SDL_BUTTON_LEFT then
    Result := SDLK_RETURN;
  event.key.keysym.sym := 0;
  event.button.button := 0;
end;

//于主地图行走

procedure Walk;
var
  word: array[0..10] of Uint16;
  x, y, walking, speed, Mx1, My1, Mx2, My2, i, stillcount, axp, ayp: integer;
  axp1, ayp1, gotoEntrance, minstep, step, i1, drawed: integer;
  now, next_time, next_time2, next_time3: uint32;
  keystate: PChar;
  pos: Tposition;
begin
  if where >= 3 then
    exit;
  next_time := SDL_GetTicks;
  next_time2 := SDL_GetTicks;
  next_time3 := SDL_GetTicks;

  Mx1 := 0;
  Mx2 := 0;

  Where := 0;
  walking := 0;
  speed := 0;
  DrawMMap;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  SDL_EnableKeyRepeat(50, 30);
  //StopMp3;
  //PlayMp3(16, -1);
  still := 0;
  stillcount := 0;

  //ExecScript('test.txt');
  //事件轮询(并非等待)
  while SDL_PollEvent(@event) >= 0 do
  begin
    //如果当前处于标题画面, 则退出, 用于战斗失败
    if where >= 3 then
    begin
      break;
    end;

    //主地图动态效果
    now := SDL_GetTicks;

    //闪烁效果
    if (integer(now - next_time2) > 0) {and (still =  1)} then
    begin
      ChangeCol;
      next_time2 := now + 200;
      //DrawMMap;
      //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    end;

    //飘云
    if (integer(now - next_time3) > 0) and (MMAPAMI > 0) then
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
      //DrawMMap;
      //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    end;

    //主角动作
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
      next_time := now + 320;
    end;

    CheckBasicEvent;
    case event.type_ of
      //方向键使用压下按键事件, 按下方向设置状态为行走
      SDL_KEYDOWN:
      begin
        if (event.key.keysym.sym = SDLK_LEFT) then
        begin
          MFace := 2;
          walking := 1;
        end;
        if (event.key.keysym.sym = SDLK_RIGHT) then
        begin
          MFace := 1;
          walking := 1;
        end;
        if (event.key.keysym.sym = SDLK_UP) then
        begin
          MFace := 0;
          walking := 1;
        end;
        if (event.key.keysym.sym = SDLK_DOWN) then
        begin
          MFace := 3;
          walking := 1;
        end;
      end;
      //功能键(esc)使用松开按键事件
      SDL_KEYUP:
      begin
        keystate := PChar(SDL_GetKeyState(nil));
        if (puint8(keystate + SDLK_LEFT)^ = 0) and (puint8(keystate + SDLK_RIGHT)^ = 0) and
          (puint8(keystate + SDLK_UP)^ = 0) and (puint8(keystate + SDLK_DOWN)^ = 0) then
        begin
          walking := 0;
          speed := 0;
        end;
        keystate := nil;
          {if event.key.keysym.sym in [sdlk_left, sdlk_right, sdlk_up, sdlk_down] then
          begin
            walking := 0;
          end;}
        if (event.key.keysym.sym = SDLK_ESCAPE) then
        begin
          //event.key.keysym.sym:=0;
          MenuEsc;
          //walking := 0;
        end;
          {if (event.key.keysym.sym = sdlk_return) and (event.key.keysym.modifier = kmod_lalt) then
          begin
            if fullscreen = 1 then
              screen := SDL_SetVideoMode(CENTER_X * 2, CENTER_Y * 2, 32, ScreenFlag)
            else
              screen := SDL_SetVideoMode(CENTER_X * 2, CENTER_Y * 2, 32, SDL_FULLSCREEN);
            fullscreen := 1 - fullscreen;
          end;}
      end;
      SDL_MOUSEMOTION:
      begin
        if (event.button.x < CENTER_X) and (event.button.y < CENTER_Y) then
          Mface := 2;
        if (event.button.x > CENTER_X) and (event.button.y < CENTER_Y) then
          Mface := 0;
        if (event.button.x < CENTER_X) and (event.button.y > CENTER_Y) then
          Mface := 3;
        if (event.button.x > CENTER_X) and (event.button.y > CENTER_Y) then
          Mface := 1;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if event.button.button = SDL_BUTTON_RIGHT then
        begin
          event.button.button := 0;
          //showmessage(inttostr(walking));
          MenuEsc;
          nowstep := -1;
          walking := 0;
        end;
        if event.button.button = SDL_BUTTON_LEFT then
        begin
          walking := 2;
          GetMousePosition(axp, ayp, Mx, My);
          if (ayp >= 0) and (ayp <= 479) and (axp >= 0) and (axp <= 479) {and canWalk(axp, ayp)} then
          begin
            FillChar(Fway[0, 0], sizeof(Fway), -1);
            findway(Mx, My);
            gotoEntrance := -1;
            if Entrance[Axp, Ayp] >= 0 then
            begin
              minstep := 4096;
              for i := 0 to 3 do
              begin
                Axp1 := Axp;
                Ayp1 := Ayp;
                case i of
                  0: Axp1 := Axp - 1;
                  1: Ayp1 := Ayp + 1;
                  2: Ayp1 := Ayp - 1;
                  3: Axp1 := Axp + 1;
                end;
                step := Fway[Axp1, Ayp1];
                if (step >= 0) and (minstep > step) then
                begin
                  gotoEntrance := i;
                  minstep := step;
                end;
              end;
              if gotoEntrance >= 0 then
              begin
                case gotoEntrance of
                  0: Axp := Axp - 1;
                  1: Ayp := Ayp + 1;
                  2: Ayp := Ayp - 1;
                  3: Axp := Axp + 1;
                end;
                gotoEntrance := 3 - gotoEntrance;
              end;
            end;
            findway(Mx, My);
            Moveman(Mx, My, Axp, Ayp);
            nowstep := Fway[Axp, Ayp] - 1;
          end
          else
          begin
            walking := 0;
          end;
        end;
      end;
    end;

    //如果主角正在行走, 则移动主角
    if walking > 0 then
    begin
      still := 0;
      stillcount := 0;
      case walking of
        1:
        begin
          speed := speed + 1;
          Mx1 := Mx;
          My1 := My;
          case mface of
            0: Mx1 := Mx1 - 1;
            1: My1 := My1 + 1;
            2: My1 := My1 - 1;
            3: Mx1 := Mx1 + 1;
          end;
          Mstep := Mstep + 1;
          if Mstep >= 7 then
            Mstep := 1;
          if CanWalk(Mx1, My1) = True then
          begin
            Mx := Mx1;
            My := My1;
          end;
          if (speed <= 1) then
            walking := 0;
        end;
        2:
        begin
          if nowstep < 0 then
          begin
            walking := 0;
            if gotoEntrance >= 0 then
            begin
              Mface := gotoEntrance;
              //CheckEntrance;
            end;
          end
          else
          begin
            still := 0;
            if sign(linex[nowstep] - Mx) < 0 then
              MFace := 0
            else if sign(linex[nowstep] - Mx) > 0 then
              MFace := 3
            else if sign(liney[nowstep] - My) > 0 then
              MFace := 1
            else
              MFace := 2;

            MStep := MStep + 1;

            if MStep >= 7 then
              MStep := 1;
            if (abs(Mx - linex[nowstep]) + abs(My - liney[nowstep]) = 1) and
              CanWalk(linex[nowstep], liney[nowstep]) then
            begin
              Mx := linex[nowstep];
              My := liney[nowstep];
            end
            else
              walking := 0;

            Dec(nowstep);
          end;
        end;
      end;

      //每走一步均重画屏幕, 并检测是否处于某场景入口
      Redraw;
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      if CheckEntrance then
      begin
        walking := 0;
        MStep := 0;
        still := 0;
        stillcount := 0;
        speed := 0;
        if MMAPAMI = 0 then
        begin
          Redraw;
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
      end;

      //SDL_Delay(WALK_SPEED);
    end;

    if where = 1 then
    begin
      WalkInScence(0);
    end;

    event.key.keysym.sym := 0;
    event.button.button := 0;
    //走路时不重复画了
    if walking = 0 then
    begin
      if MMAPAMI > 0 then
      begin
        Redraw;
        GetMousePosition(axp, ayp, Mx, My);
        pos := GetPositionOnScreen(axp, ayp, Mx, My);
        DrawMPic(1, pos.x, pos.y, 0, 50, 0, 0);
        {if not CanWalk(axp, ayp) then
        begin
          if Entrance[axp, ayp] >= 0 then
            DrawMPic(2001, pos.x, pos.y, 0, 75, 0, 0)
          else
            DrawMPic(2001, pos.x, pos.y, 0, 50, 0, 0);
        end;}
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      end;
      SDL_Delay(40); //静止时只需刷新率与最频繁的动态效果相同即可
    end
    else
      SDL_Delay(WALK_SPEED);
  end;

  //SDL_EnableKeyRepeat(0, 10);

end;

//判定主地图某个位置能否行走, 是否变成船

function CanWalk(x, y: integer): boolean;
begin
  if buildx[x, y] = 0 then
    CanWalk := True
  else
    CanWalk := False;
  //canwalk:=true;  //This sentence is used to test.
  if (x <= 0) or (x >= 479) or (y <= 0) or (y >= 479) then
    CanWalk := False;
  if (earth[x, y] = 838) or ((earth[x, y] >= 612) and (earth[x, y] <= 670)) then
    CanWalk := False;
  if ((earth[x, y] >= 358) and (earth[x, y] <= 362)) or ((earth[x, y] >= 506) and (earth[x, y] <= 670)) or
    ((earth[x, y] >= 1016) and (earth[x, y] <= 1022)) then
    InShip := 1
  else
    InShip := 0;

  if MODVersion = 22 then
  begin
    if InShip = 1 then
    begin
      CanWalk := False;
      InShip := 0;
    end;
  end;

end;

//Check able or not to ertrance a scence.
//检测是否处于某入口, 并是否达成进入条件

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
    if (Rscence[snum].EnCondition = 0) then
      Result := True;
    //是否有人轻功超过70
    if (Rscence[snum].EnCondition = 2) then
      for i := 0 to 5 do
        if teamlist[i] >= 0 then
          if Rrole[teamlist[i]].Speed > 70 then
            Result := True;
    if Result = True then
    begin
      instruct_14;
      CurScence := Entrance[x, y];
      SFace := MFace;
      Mface := 3 - Mface;
      SStep := 0;
      Sx := Rscence[CurScence].EntranceX;
      Sy := Rscence[CurScence].EntranceY;
      //如达成条件, 进入场景并初始化场景坐标
      SaveR(6);
      WalkInScence(0);
      event.key.keysym.sym := 0;
      event.button.button := 0;
      //waitanykey;
    end;
    //instruct_13;
  end;
  //result:=canentrance;

end;

procedure UpdateScenceAmi;
begin
  while True do
  begin
    if (where = 1) and (CurEvent < 0) and (not LoadingScence) and (NeedRefreshScence = 1) then
      InitialScence(2);
    if (where < 1) or (where > 2) then
      break;
    SDL_Delay(200);
  end;

end;

//Walk in a scence, the returned value is the scence number when you exit. If it is -1.
//WalkInScence(1) means the new game.
//在内场景行走, 如参数为1表示新游戏

function WalkInScence(Open: integer): integer;
var
  grp, idx, offset, just, i1, i2, x, y, haveAmi, preface, drawed: integer;
  Sx1, Sy1, s, i, walking, Prescence, stillcount, speed, axp, ayp, gotoevent, minstep, axp1, ayp1, step: integer;
  filename: string;
  scencename: WideString;
  now, next_time, next_time2: uint32;
  AmiCount: integer; //场景内动态效果计数
  keystate: PChar;
  UpDate: PSDL_Thread;
  pos: Tposition;
begin

  //LockScence := false;
  next_time := SDL_GetTicks;

  Where := 1;
  walking := 0; // 为0表示静止, 为1表示键盘行走, 为2表示鼠标行走
  just := 0;
  CurEvent := -1;
  AmiCount := 0;
  speed := 0;
  stillcount := 0;
  exitscencemusicnum := Rscence[CurScence].ExitMusic;

  SDL_EnableKeyRepeat(50, 30);

  InitialScence;

  for i := 0 to 199 do
    if (DData[CurScence, i, 7] < DData[CurScence, i, 6]) then
    begin
      DData[CurScence, i, 5] := DData[CurScence, i, 7] + DData[CurScence, i, 8] * 2 mod
        (DData[CurScence, i, 6] - DData[CurScence, i, 7] + 2);
    end;

  if Open = 1 then
  begin
    Sx := BEGIN_Sx;
    Sy := BEGIN_Sy;
    Cx := Sx;
    Cy := Sy;
    CurScenceRolePic := 3445;
    CurEvent := BEGIN_EVENT;
    CallEvent(BEGIN_EVENT);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    CurEvent := -1;
  end;

  SStep := 0;

  DrawScence;
  ShowScenceName(CurScence);
  //是否有第3类事件位于场景入口
  CheckEvent3;

  if SCENCEAMI = 2 then
    UpDate := SDL_CreateThread(@UpdateScenceAmi, nil);
  while (SDL_PollEvent(@event) >= 0) do
  begin
    if where <> 1 then
    begin
      break;
    end;
    if Sx > 63 then
      Sx := 63;
    if Sy > 63 then
      Sy := 63;
    if Sx < 0 then
      Sx := 0;
    if Sy < 0 then
      Sy := 0;
    //场景内动态效果
    now := SDL_GetTicks;
    //next_time:=sdl_getticks;
    if integer(now - next_time) > 0 then
    begin
      haveAmi := 0;
      for i := 0 to 199 do
        if (DData[CurScence, i, 7] < DData[CurScence, i, 6]) {and (AmiCount > (DData[CurScence, i, 8] + 1))} then
        begin
          DData[CurScence, i, 5] := DData[CurScence, i, 5] + 2;
          if DData[CurScence, i, 5] > DData[CurScence, i, 6] then
            DData[CurScence, i, 5] := DData[CurScence, i, 7];
          haveAmi := haveAmi + 1;
        end;
      //if we never consider the change of color panel, there is no need to re-initial scence.
      //if (haveAmi > 0) then
      //if not (IsCave(CurScence)) then
      if SCENCEAMI = 1 then
      begin
        InitialScence(1);
      end;

      if walking = 0 then
        stillcount := stillcount + 1
      else
        stillcount := 0;
      if stillcount >= 20 then
      begin
        SStep := 0;
        stillcount := 0;
      end;

      next_time := now + 200;
      AmiCount := AmiCount + 1;
      ChangeCol;
      //DrawScence;
      //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    end;

    //检查是否位于出口, 如是则退出
    if (((Sx = Rscence[CurScence].ExitX[0]) and (Sy = Rscence[CurScence].ExitY[0])) or
      ((Sx = Rscence[CurScence].ExitX[1]) and (Sy = Rscence[CurScence].ExitY[1])) or
      ((Sx = Rscence[CurScence].ExitX[2]) and (Sy = Rscence[CurScence].ExitY[2]))) then
    begin
      Where := 0;
      Result := -1;
      break;
    end;
    //检查是否位于跳转口, 如是则重新初始化场景
    if ((Sx = Rscence[CurScence].JumpX1) and (Sy = Rscence[CurScence].JumpY1)) and
      (Rscence[CurScence].JumpScence >= 0) then
    begin
      instruct_14;
      PreScence := CurScence;
      CurScence := Rscence[CurScence].JumpScence;
      if Rscence[PreScence].MainEntranceX1 <> 0 then
      begin
        Sx := Rscence[CurScence].EntranceX;
        Sy := Rscence[CurScence].EntranceY;
      end
      else
      begin
        Sx := Rscence[CurScence].JumpX2;
        Sy := Rscence[CurScence].JumpY2;
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
      Walking := 0;
      DrawScence;
      ShowScenceName(CurScence);
      CheckEvent3;

    end;

    CheckBasicEvent;
    case event.type_ of
      SDL_KEYUP:
      begin
        keystate := PChar(SDL_GetKeyState(nil));
        if (puint8(keystate + SDLK_LEFT)^ = 0) and (puint8(keystate + SDLK_RIGHT)^ = 0) and
          (puint8(keystate + SDLK_UP)^ = 0) and (puint8(keystate + SDLK_DOWN)^ = 0) then
        begin
          walking := 0;
          speed := 0;
        end;
        keystate := nil;
        if (event.key.keysym.sym = SDLK_ESCAPE) then
        begin
          MenuEsc;
          walking := 0;
          speed := 0;
          //mousewalking := 0;
        end;
        //按下回车或空格, 检查面对方向是否有第1类事件
        if (event.key.keysym.sym = SDLK_RETURN) or (event.key.keysym.sym = SDLK_SPACE) then
        begin
          CheckEvent1;
        end;
      end;
      SDL_KEYDOWN:
      begin
        if (event.key.keysym.sym = SDLK_LEFT) then
        begin
          SFace := 2;
          walking := 1;
        end;
        if (event.key.keysym.sym = SDLK_RIGHT) then
        begin
          SFace := 1;
          walking := 1;
        end;
        if (event.key.keysym.sym = SDLK_UP) then
        begin
          SFace := 0;
          walking := 1;
        end;
        if (event.key.keysym.sym = SDLK_DOWN) then
        begin
          SFace := 3;
          walking := 1;
        end;
      end;
      {Sdl_mousebuttondown:
        begin
          if event.button.button = sdl_button_left then
          begin
            walking := 2;
          end;
        end;
      Sdl_mousebuttonup:
        begin
          if event.button.button = sdl_button_right then
            menuesc;
          if event.button.button = sdl_button_left then
          begin
            walking := 0;
          end;
          if event.button.button = sdl_button_middle then
            CheckEvent1;
        end;}
      SDL_MOUSEMOTION:
      begin
        if (event.button.x < CENTER_X) and (event.button.y < CENTER_Y) then
          Sface := 2;
        if (event.button.x > CENTER_X) and (event.button.y < CENTER_Y) then
          Sface := 0;
        if (event.button.x < CENTER_X) and (event.button.y > CENTER_Y) then
          Sface := 3;
        if (event.button.x > CENTER_X) and (event.button.y > CENTER_Y) then
          Sface := 1;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if event.button.button = SDL_BUTTON_RIGHT then
        begin
          MenuEsc;
          nowstep := 0;
          walking := 0;
          speed := 0;
          if where = 0 then
          begin
            if Rscence[CurScence].ExitMusic >= 0 then
            begin
              StopMP3;
              PlayMP3(Rscence[CurScence].ExitMusic, -1);
            end;
            Redraw;
            SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            exit;
          end;
        end;
        if event.button.button = SDL_BUTTON_MIDDLE then
        begin
          CheckEvent1;
        end;
        if event.button.button = SDL_BUTTON_LEFT then
        begin
          if walking = 0 then
          begin
            walking := 2;
            GetMousePosition(Axp, Ayp, Sx, Sy, SData[CurScence, 4, Sx, Sy]);
            if (ayp in [0..63]) and (axp in [0..63]) then
            begin
              FillChar(Fway[0, 0], sizeof(Fway), -1);
              findway(Sx, Sy);
              gotoevent := -1;
              if (SData[CurScence, 3, axp, ayp] >= 0) then
              begin
                if abs(Axp - Sx) + Abs(Ayp - Sy) = 1 then
                begin
                  if Axp < Sx then SFace := 0;
                  if Axp > Sx then SFace := 3;
                  if Ayp < Sy then SFace := 2;
                  if Ayp > Sy then SFace := 1;
                  CheckEvent1;
                end
                else
                begin
                  if (not CanWalkInScence(Axp, Ayp)) then
                  begin
                    minstep := 4096;
                    for i := 0 to 3 do
                    begin
                      Axp1 := Axp;
                      Ayp1 := Ayp;
                      case i of
                        0: Axp1 := Axp - 1;
                        1: Ayp1 := Ayp + 1;
                        2: Ayp1 := Ayp - 1;
                        3: Axp1 := Axp + 1;
                      end;
                      step := Fway[Axp1, Ayp1];
                      if (step >= 0) and (minstep > step) then
                      begin
                        gotoEvent := i;
                        minstep := step;
                      end;
                    end;
                    if gotoEvent >= 0 then
                    begin
                      case gotoEvent of
                        0: Axp := Axp - 1;
                        1: Ayp := Ayp + 1;
                        2: Ayp := Ayp - 1;
                        3: Axp := Axp + 1;
                      end;
                      gotoEvent := 3 - gotoEvent;
                    end;
                  end;
                end;
              end;
              Moveman(Sx, Sy, axp, ayp);
              nowstep := Fway[axp, ayp] - 1;
            end
            else
            begin
              walking := 0;
            end;
          end
          else
            walking := 0;
          event.button.button := 0;
        end;
      end;
    end;

    //是否处于行走状态
    if walking > 0 then
    begin
      case walking of
        1:
        begin
          speed := speed + 1;
          stillcount := 0;
            {if walking = 2 then //如果用鼠标则重置方向
            begin
              SDL_GetMouseState2(x, y);
              if (x < CENTER_x) and (y < CENTER_y) then
                Sface := 2;
              if (x > CENTER_x) and (y < CENTER_y) then
                Sface := 0;
              if (x < CENTER_x) and (y > CENTER_y) then
                Sface := 3;
              if (x > CENTER_x) and (y > CENTER_y) then
                Sface := 1;
            end;}
          Sx1 := Sx;
          Sy1 := Sy;
          case Sface of
            0: Sx1 := Sx1 - 1;
            1: Sy1 := Sy1 + 1;
            2: Sy1 := Sy1 - 1;
            3: Sx1 := Sx1 + 1;
          end;
          Sstep := Sstep + 1;
          if Sstep >= 7 then
            Sstep := 1;
          if CanWalkInScence(Sx1, Sy1) = True then
          begin
            Sx := Sx1;
            Sy := Sy1;
          end;

          //一定步数之内一次动一格
          if (speed <= 1) then
          begin
            walking := 0;
            //sdl_delay(20);
          end;
          if event.key.keysym.sym = 0 then
            walking := 0;
        end;
        2:
        begin
          if nowstep >= 0 then
          begin
            if sign(liney[nowstep] - Sy) < 0 then
              SFace := 2
            else if sign(liney[nowstep] - Sy) > 0 then
              sFace := 1
            else if sign(linex[nowstep] - Sx) > 0 then
              SFace := 3
            else
              sFace := 0;

            SStep := SStep + 1;

            if SStep >= 7 then
              SStep := 1;
            if abs(Sx - linex[nowstep]) + abs(Sy - liney[nowstep]) = 1 then
            begin
              Sx := linex[nowstep];
              Sy := liney[nowstep];
            end
            else
              walking := 0;
            Dec(nowstep);
          end
          else
          begin
            walking := 0;
            if gotoEvent >= 0 then
            begin
              Sface := gotoEvent;
              Redraw;
              CheckEvent1;
            end;
          end;
        end;
      end;
      Redraw;
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      CheckEvent3;
      //SDL_Delay(WALK_SPEED2);
    end;

    event.key.keysym.sym := 0;
    event.button.button := 0;

    if walking or speed = 0 then
    begin
      if SCENCEAMI > 0 then
      begin
        Redraw;
        if walking = 0 then
        begin
          GetMousePosition(Axp, Ayp, Sx, Sy, SData[CurScence, 4, Sx, Sy]);
          if (axp >= 0) and (axp < 64) and (ayp >= 0) and (ayp < 64) then
          begin
            pos := GetPositionOnScreen(axp, ayp, Sx, Sy);
            DrawMPic(1, pos.x, pos.y - SData[CurScence, 4, axp, ayp], 0, 50, 0, 0);
            //DrawMPic(1, pos.x, pos.y);
            {if not CanWalkInScence(axp, ayp) then
            begin
              if SData[CurScence, 3, axp, ayp] >= 0 then
                DrawMPic(2001, pos.x, pos.y - SData[CurScence, 4, axp, ayp], 0, 75, 0, 0)
              else
                DrawMPic(2001, pos.x, pos.y - SData[CurScence, 4, axp, ayp], 0, 50, 0, 0);
            end;}
          end;
        end;
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      end;
      SDL_Delay(40);
    end
    else
    begin
      SDL_Delay(WALK_SPEED2);
    end;

  end;

  instruct_14; //黑屏

  //ReDraw;
  //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  //if SCENCEAMI = 2 then
  //SDL_KillThread(UpDate);
  if exitscencemusicnum > 0 then
  begin
    StopMP3;
    PlayMP3(exitscencemusicnum, -1);
  end;

end;

procedure findway(x1, y1: integer);
var
  Xlist: array[0..4096] of smallint;
  Ylist: array[0..4096] of smallint;
  steplist: array[0..4096] of smallint;
  curgrid, totalgrid: integer;
  Bgrid: array[1..4] of integer; //0空位，1可过，2已走过 ,3越界
  Xinc, Yinc: array[1..4] of integer;
  curX, curY, curstep, nextX, nextY: integer;
  i, i1, i2, i3: integer;
  CanWalk: boolean;
begin
  Xinc[1] := 0;
  Xinc[2] := 1;
  Xinc[3] := -1;
  Xinc[4] := 0;
  Yinc[1] := -1;
  Yinc[2] := 0;
  Yinc[3] := 0;
  Yinc[4] := 1;
  curgrid := 0;
  totalgrid := 1;
  Xlist[0] := x1;
  Ylist[0] := y1;
  steplist[0] := 0;
  Fway[x1, y1] := 0;
  while curgrid < totalgrid do
  begin
    curX := Xlist[curgrid];
    curY := Ylist[curgrid];
    curstep := steplist[curgrid];
    //判断当前点四周格子的状况
    case where of
      1:
      begin
        for i := 1 to 4 do
        begin
          nextX := curX + Xinc[i];
          nextY := curY + Yinc[i];
          if (nextX < 0) or (nextX > 63) or (nextY < 0) or (nextY > 63) then
            Bgrid[i] := 3  //越界
          else if Fway[nextX, nextY] >= 0 then
            Bgrid[i] := 2 //已走过
          else if not CanWalkInScence(curx, cury, nextx, nexty) then
            Bgrid[i] := 1   //阻碍
          else
            Bgrid[i] := 0;
        end;
      end;
      0:
      begin
        for i := 1 to 4 do
        begin
          nextX := curX + Xinc[i];
          nextY := curY + Yinc[i];
          if (nextX < 0) or (nextX > 479) or (nextY < 0) or (nextY > 479) then
            Bgrid[i] := 3 //越界
          else if (Entrance[nextx, nexty] >= 0) then
            Bgrid[i] := 6 //入口
          else if Fway[nextX, nextY] >= 0 then
            Bgrid[i] := 2 //已走过
          else if buildx[nextx, nexty] > 0 then
            Bgrid[i] := 1 //阻碍
          else if ((surface[nextx, nexty] >= 1692) and (surface[nextx, nexty] <= 1700)) then
            Bgrid[i] := 1
          else if (earth[nextx, nexty] = 838) or ((earth[nextx, nexty] >= 612) and (earth[nextx, nexty] <= 670)) then
            Bgrid[i] := 1
          else if ((earth[nextx, nexty] >= 358) and (earth[nextx, nexty] <= 362)) or
            ((earth[nextx, nexty] >= 506) and (earth[nextx, nexty] <= 670)) or
            ((earth[nextx, nexty] >= 1016) and (earth[nextx, nexty] <= 1022)) then
          begin
            if (nextx = shipy) and (nexty = shipx) then
              Bgrid[i] := 4 //船
            else if ((surface[nextx, nexty] div 2 >= 863) and (surface[nextx, nexty] div 2 <= 872)) or
              ((surface[nextx, nexty] div 2 >= 852) and (surface[nextx, nexty] div 2 <= 854)) or
              ((surface[nextx, nexty] div 2 >= 858) and (surface[nextx, nexty] div 2 <= 860)) then
              Bgrid[i] := 0 //船
            else
              Bgrid[i] := 5; //水
          end
          else
            Bgrid[i] := 0;
        end;
      end;
      //移动的情况
    end;
    for i := 1 to 4 do
    begin
      CanWalk := False;
      case MODVersion of
        22:
        begin
          if ((inship = 1) and (Bgrid[i] = 5)) or (((Bgrid[i] = 0) or (Bgrid[i] = 4)) and (inship = 0)) then
            CanWalk := True;
        end;
        else
        begin
          if (Bgrid[i] = 0) or (Bgrid[i] = 4) or (Bgrid[i] = 5) or (Bgrid[i] = 7) then
            CanWalk := True;
        end;
      end;
      if CanWalk then
      begin
        Xlist[totalgrid] := curX + Xinc[i];
        Ylist[totalgrid] := curY + Yinc[i];
        steplist[totalgrid] := curstep + 1;
        Fway[Xlist[totalgrid], Ylist[totalgrid]] := steplist[totalgrid];
        totalgrid := totalgrid + 1;
        if totalgrid > 4096 then
          exit;
      end;
    end;
    curgrid := curgrid + 1;
    if (where = 0) and (curX - Mx > 22) and (curY - My > 22) then
      break;
  end;

end;

procedure Moveman(x1, y1, x2, y2: integer);
var
  s, i, i1, i2, a, tempx, tx1, tx2, ty1, ty2, tempy: integer;
  Xinc, Yinc, dir: array[1..4] of integer;
begin
  if Fway[x2, y2] > 0 then
  begin
    Xinc[1] := 0;
    Xinc[2] := 1;
    Xinc[3] := -1;
    Xinc[4] := 0;
    Yinc[1] := -1;
    Yinc[2] := 0;
    Yinc[3] := 0;
    Yinc[4] := 1;
    linex[0] := x2;
    liney[0] := y2;
    for a := 1 to Fway[x2, y2] do
    begin
      for i := 1 to 4 do
      begin
        tempx := linex[a - 1] + Xinc[i];
        tempy := liney[a - 1] + Yinc[i];
        if Fway[tempx, tempy] = Fway[linex[a - 1], liney[a - 1]] - 1 then
        begin
          linex[a] := tempx;
          liney[a] := tempy;
          break;
        end;
      end;
    end;
  end;
end;

procedure ShowScenceName(snum: integer);
var
  scencename: WideString;
begin
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  //显示场景名
  if snum >= 0 then
  begin
    scencename := Big5ToUnicode(@Rscence[snum].Name);
    DrawTextWithRect(screen, @scencename[1], CENTER_X - length(PChar(@Rscence[snum].Name)) * 5 + 7, 100,
      length(PChar(@Rscence[snum].Name)) * 10 + 6, ColColor(7), ColColor(5));

    //改变音乐
    if Rscence[snum].EntranceMusic >= 0 then
    begin
      StopMP3;
      PlayMP3(Rscence[snum].EntranceMusic, -1);
    end;
  end;
  SDL_Delay(500);

end;

//判定场景内某个位置能否行走

function CanWalkInScence(x, y: integer): boolean; overload;
begin
  if (SData[CurScence, 1, x, y] = 0) then
    Result := True
  else
    Result := False;
  if (SData[CurScence, 3, x, y] >= 0) and (Result) and (DData[CurScence, SData[CurScence, 3, x, y], 0] = 1) then
    Result := False;
  //直接判定贴图范围
  if ((SData[CurScence, 0, x, y] >= 358) and (SData[CurScence, 0, x, y] <= 362)) or
    (SData[CurScence, 0, x, y] = 522) or (SData[CurScence, 0, x, y] = 1022) or
    ((SData[CurScence, 0, x, y] >= 1324) and (SData[CurScence, 0, x, y] <= 1330)) or
    (SData[CurScence, 0, x, y] = 1348) then
    Result := False;
  //if SData[CurScence, 0, x, y] = 1358 * 2 then result := true;
  if (MODVersion = 23) and ((SData[CurScence, 1, x, y] = 1358 * 2) or (SData[CurScence, 1, x, y] = 1269 * 2)) then
    Result := True;

end;

function CanWalkInScence(x1, y1, x, y: integer): boolean; overload;
begin
  Result := (abs(SData[CurScence, 4, x, y] - SData[CurScence, 4, x1, y1]) <= 10) and CanWalkInScence(x, y);

end;

//检查是否有第1类事件, 如有则调用

procedure CheckEvent1;
var
  x, y: integer;
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
    if DData[CurScence, CurEvent, 2] >= 0 then
      CallEvent(DData[CurScence, SData[CurScence, 3, x, y], 2]);
  end;
  CurEvent := -1;
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
    //waitanykey;
    CallEvent(DData[CurScence, enum, 4]);
    CurEvent := -1;
  end;
end;

//Menus.
//通用选单, (位置(x, y), 宽度, 最大选项(编号均从0开始))
//使用前必须设置选单使用的字符串组才有效, 字符串组不可越界使用

function CommonMenu(x, y, w, max, default: integer; menustring: array of WideString): integer; overload;
var
  menuengstring: array of WideString;
begin
  setlength(menuengstring, 0);
  Result := CommonMenu(x, y, w, max, default, menustring, menuengstring);
end;

function CommonMenu(x, y, w, max: integer; menustring: array of WideString): integer; overload;
begin
  Result := CommonMenu(x, y, w, max, 0, menustring);
end;

function CommonMenu(x, y, w, max: integer; menustring, menuengstring: array of WideString): integer; overload;
begin
  Result := CommonMenu(x, y, w, max, 0, menustring, menuengstring);
end;

function CommonMenu(x, y, w, max, default: integer; menustring, menuengstring: array of WideString): integer; overload;
var
  menu, menup: integer;
begin
  menu := default;
  WriteFreshScreen(x, y, w + 1, max * 22 + 29);
  ShowCommonMenu(x, y, w, max, menu, menustring, menuengstring);
  SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    CheckBasicEvent;
    case event.type_ of
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = SDLK_DOWN) then
        begin
          menu := menu + 1;
          if menu > max then
            menu := 0;
          ShowCommonMenu(x, y, w, max, menu, menustring, menuengstring);
          SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
        end;
        if (event.key.keysym.sym = SDLK_UP) then
        begin
          menu := menu - 1;
          if menu < 0 then
            menu := max;
          ShowCommonMenu(x, y, w, max, menu, menustring, menuengstring);
          SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
        end;
        if ((event.key.keysym.sym = SDLK_ESCAPE)) {and (where <= 2)} then
        begin
          Result := -1;
          //ReDraw;
          //SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          break;
        end;
        if (event.key.keysym.sym = SDLK_RETURN) or (event.key.keysym.sym = SDLK_SPACE) then
        begin
          Result := menu;
          //Redraw;
          //SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          break;
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = SDL_BUTTON_RIGHT) {and (where <= 2)} then
        begin
          Result := -1;
          //ReDraw;
          //SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          break;
        end;
        if (event.button.button = SDL_BUTTON_LEFT) then
        begin
          if (round(event.button.x / (RealScreen.w / screen.w)) >= x) and
            (round(event.button.x / (RealScreen.w / screen.w)) < x + w) and
            (round(event.button.y / (RealScreen.h / screen.h)) > y) and
            (round(event.button.y / (RealScreen.h / screen.h)) < y + max * 22 + 29) then
          begin
            Result := menu;
            //Redraw;
            //SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
            break;
          end;
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
            ShowCommonMenu(x, y, w, max, menu, menustring, menuengstring);
            SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          end;
        end;
      end;
    end;
  end;

  //清空键盘键和鼠标键值, 避免影响其余部分
  event.key.keysym.sym := 0;
  event.button.button := 0;

end;

//该选单即时产生显示效果, 由函数指定

function CommonMenu(x, y, w, max, default: integer; menustring, menuengstring: array of WideString;
  fn: TPInt1): integer; overload;
var
  menu, menup: integer;
begin
  menu := default;
  //SDL_EnableKeyRepeat(0,10);
  //DrawMMap;
  ShowCommonMenu(x, y, w, max, menu, menustring, menuengstring);
  SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
  fn(menu);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    CheckBasicEvent;
    case event.type_ of
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = SDLK_DOWN) then
        begin
          menu := menu + 1;
          if menu > max then
            menu := 0;
          ShowCommonMenu(x, y, w, max, menu, menustring, menuengstring);
          SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          fn(menu);
        end;
        if (event.key.keysym.sym = SDLK_UP) then
        begin
          menu := menu - 1;
          if menu < 0 then
            menu := max;
          ShowCommonMenu(x, y, w, max, menu, menustring, menuengstring);
          SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          fn(menu);
        end;
        if ((event.key.keysym.sym = SDLK_ESCAPE)) {and (where <= 2)} then
        begin
          Result := -1;
          //ReDraw;
          //SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
          break;
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = SDL_BUTTON_RIGHT) {and (where <= 2)} then
        begin
          Result := -1;
          //ReDraw;
          //SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
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
            ShowCommonMenu(x, y, w, max, menu, menustring, menuengstring);
            SDL_UpdateRect2(screen, x, y, w + 1, max * 22 + 29);
            fn(menu);
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

procedure ShowCommonMenu(x, y, w, max, menu: integer; menustring: array of WideString); overload;
var
  menuengstring: array of WideString;
begin
  setlength(menuengstring, 0);
  ShowCommonMenu(x, y, w, max, menu, menustring, menuengstring);
end;

procedure ShowCommonMenu(x, y, w, max, menu: integer; menustring, menuengstring: array of WideString); overload;
var
  i, p: integer;
  temp: PSDL_Surface;
begin
  ReadFreshScreen(x, y, w + 1, max * 22 + 29);
  DrawRectangle(screen, x, y, w, max * 22 + 28, 0, ColColor(255), 30);
  if (length(Menuengstring) > 0) and (length(Menustring) = length(Menuengstring)) then
    p := 1
  else
    p := 0;
  for i := 0 to min(max, length(Menustring) - 1) do
    if i = menu then
    begin
      DrawShadowText(screen, @menustring[i][1], x - 17, y + 2 + 22 * i, ColColor($66), ColColor($64));
      if p = 1 then
        DrawEngShadowText(screen, @menuengstring[i][1], x + 93, y + 2 + 22 * i, ColColor($66), ColColor($64));
    end
    else
    begin
      DrawShadowText(screen, @menustring[i][1], x - 17, y + 2 + 22 * i, ColColor($7), ColColor($5));
      if p = 1 then
        DrawEngShadowText(screen, @menuengstring[i][1], x + 93, y + 2 + 22 * i, ColColor($7), ColColor($5));
    end;

end;

//卷动选单

function CommonScrollMenu(x, y, w, max, maxshow: integer; menustring: array of WideString): integer; overload;
var
  menuengstring: array of WideString;
begin
  setlength(menuengstring, 0);
  Result := CommonScrollMenu(x, y, w, max, maxshow, menustring, menuengstring);
end;

function CommonScrollMenu(x, y, w, max, maxshow: integer; menustring, menuengstring: array of WideString): integer;
  overload;
var
  menu, menup, menutop: integer;
begin
  menu := 0;
  menutop := 0;
  //SDL_EnableKeyRepeat(0,10);
  //DrawMMap;
  WriteFreshScreen(x, y, w + 1, max * 22 + 29);
  ShowCommonScrollMenu(x, y, w, max, maxshow, menu, menutop, menustring, menuengstring);
  SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    CheckBasicEvent;
    case event.type_ of
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = SDLK_DOWN) then
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
          ShowCommonScrollMenu(x, y, w, max, maxshow, menu, menutop, menustring, menuengstring);
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
        end;
        if (event.key.keysym.sym = SDLK_UP) then
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
          ShowCommonScrollMenu(x, y, w, max, maxshow, menu, menutop, menustring, menuengstring);
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
        end;
        if (event.key.keysym.sym = SDLK_PAGEDOWN) then
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
          ShowCommonScrollMenu(x, y, w, max, maxshow, menu, menutop, menustring, menuengstring);
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
        end;
        if (event.key.keysym.sym = SDLK_PAGEUP) then
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
          ShowCommonScrollMenu(x, y, w, max, maxshow, menu, menutop, menustring, menuengstring);
          SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
        end;
        if ((event.key.keysym.sym = SDLK_ESCAPE)) and (where <= 2) then
        begin
          Result := -1;
          //ReDraw;
          //SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
          break;
        end;
        if (event.key.keysym.sym = SDLK_RETURN) or (event.key.keysym.sym = SDLK_SPACE) then
        begin
          Result := menu;
          //Redraw;
          //SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
          break;
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = SDL_BUTTON_RIGHT) and (where <= 2) then
        begin
          Result := -1;
          //ReDraw;
          //SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
          break;
        end;
        if (event.button.button = SDL_BUTTON_LEFT) then
        begin
          if (round(event.button.x / (RealScreen.w / screen.w)) >= x) and
            (round(event.button.x / (RealScreen.w / screen.w)) < x + w) and
            (round(event.button.y / (RealScreen.h / screen.h)) > y) and
            (round(event.button.y / (RealScreen.h / screen.h)) < y + max * 22 + 29) then
          begin
            Result := menu;
            //Redraw;
            //SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
            break;
          end;
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
          ShowCommonScrollMenu(x, y, w, max, maxshow, menu, menutop, menustring, menuengstring);
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
          end;
          ShowCommonScrollMenu(x, y, w, max, maxshow, menu, menutop, menustring, menuengstring);
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
            ShowCommonScrollMenu(x, y, w, max, maxshow, menu, menutop, menustring, menuengstring);
            SDL_UpdateRect2(screen, x, y, w + 1, maxshow * 22 + 29);
          end;
        end;
      end;
    end;
  end;
  //清空键盘键和鼠标键值, 避免影响其余部分
  event.key.keysym.sym := 0;
  event.button.button := 0;

end;

procedure ShowCommonScrollMenu(x, y, w, max, maxshow, menu, menutop: integer;
  menustring, menuengstring: array of WideString);
var
  i, p: integer;
begin
  ReadFreshScreen(x, y, w + 1, max * 22 + 29);
  if max + 1 < maxshow then
    maxshow := max + 1;
  DrawRectangle(screen, x, y, w, maxshow * 22 + 6, 0, ColColor(255), 30);
  if (length(Menuengstring) > 0) and (length(Menustring) = length(Menuengstring)) then
    p := 1
  else
    p := 0;
  for i := menutop to menutop + maxshow - 1 do
    if (i = menu) and (i < length(menustring)) then
    begin
      DrawShadowText(screen, @menustring[i][1], x - 17, y + 2 + 22 * (i - menutop), ColColor($66), ColColor($64));
      if p = 1 then
        DrawEngShadowText(screen, @menuengstring[i][1], x + 93, y + 2 + 22 * (i - menutop),
          ColColor($66), ColColor($64));
    end
    else
    begin
      DrawShadowText(screen, @menustring[i][1], x - 17, y + 2 + 22 * (i - menutop), ColColor($7), ColColor($5));
      if p = 1 then
        DrawEngShadowText(screen, @menuengstring[i][1], x + 93, y + 2 + 22 * (i - menutop),
          ColColor($7), ColColor($5));
    end;

end;

//仅有两个选项的横排选单, 为美观使用横排
//此类选单中每个选项限制为两个中文字, 仅适用于提问'继续', '取消'的情况

function CommonMenu2(x, y, w: integer; menustring: array of WideString): integer;
var
  menu, menup: integer;
begin
  menu := 0;
  //SDL_EnableKeyRepeat(0,10);
  //DrawMMap;
  WriteFreshScreen(x, y, w + 1, 29);
  ShowCommonMenu2(x, y, w, menu, menustring);
  SDL_UpdateRect2(screen, x, y, w + 1, 29);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    CheckBasicEvent;
    case event.type_ of
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = SDLK_LEFT) or (event.key.keysym.sym = SDLK_RIGHT) then
        begin
          if menu = 1 then
            menu := 0
          else
            menu := 1;
          ShowCommonMenu2(x, y, w, menu, menustring);
          SDL_UpdateRect2(screen, x, y, w + 1, 29);
        end;
        if ((event.key.keysym.sym = SDLK_ESCAPE)) and (where <= 2) then
        begin
          Result := -1;
          //ReDraw;
          //SDL_UpdateRect2(screen, x, y, w + 1, 29);
          break;
        end;
        if (event.key.keysym.sym = SDLK_RETURN) or (event.key.keysym.sym = SDLK_SPACE) then
        begin
          Result := menu;
          //Redraw;
          //SDL_UpdateRect2(screen, x, y, w + 1, 29);
          break;
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = SDL_BUTTON_RIGHT) and (where <= 2) then
        begin
          Result := -1;
          //ReDraw;
          //SDL_UpdateRect2(screen, x, y, w + 1, 29);
          break;
        end;
        if (event.button.button = SDL_BUTTON_LEFT) then
        begin
          if (round(event.button.x / (RealScreen.w / screen.w)) >= x) and
            (round(event.button.x / (RealScreen.w / screen.w)) < x + w) and
            (round(event.button.y / (RealScreen.h / screen.h)) > y) and
            (round(event.button.y / (RealScreen.h / screen.h)) < y + 29) then
          begin
            Result := menu;
            //Redraw;
            //SDL_UpdateRect2(screen, x, y, w + 1, 29);
            break;
          end;
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
            ShowCommonMenu2(x, y, w, menu, menustring);
            SDL_UpdateRect2(screen, x, y, w + 1, 29);
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

procedure ShowCommonMenu2(x, y, w, menu: integer; menustring: array of WideString);
var
  i, p: integer;
begin
  ReadFreshScreen(x, y, w + 1, 29);
  DrawRectangle(screen, x, y, w, 28, 0, ColColor(255), 30);
  //if length(Menuengstring) > 0 then p := 1 else p := 0;
  for i := 0 to 1 do
    if i = menu then
    begin
      DrawShadowText(screen, @menustring[i][1], x - 17 + i * 50, y + 2, ColColor($66), ColColor($64));
    end
    else
    begin
      DrawShadowText(screen, @menustring[i][1], x - 17 + i * 50, y + 2, ColColor($7), ColColor($5));
    end;

end;

//选择一名队员, 可以附带两个属性显示

function SelectOneTeamMember(x, y: integer; str: string; list1, list2: integer): integer;
var
  i, amount: integer;
  menustring, menuengstring: array of WideString;
begin
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
      menustring[i] := Big5ToUnicode(@Rrole[Teamlist[i]].Name);
      if str <> '' then
      begin
        menuengstring[i] := format(str, [Rrole[teamlist[i]].Data[list1], Rrole[teamlist[i]].Data[list2]]);
      end;
      amount := amount + 1;
    end;
  end;
  if str = '' then
    Result := CommonMenu(x, y, 105, amount - 1, menustring, menuengstring)
  else
    Result := CommonMenu(x, y, 105 + length(menuengstring[0]) * 10, amount - 1, menustring, menuengstring);

end;

//主选单

procedure MenuEsc;
var
  word: array[0..5] of WideString;
  i: integer;
begin
  word[0] := (' 醫療');
  word[1] := (' 解毒');
  word[2] := (' 物品');
  word[3] := (' 狀態');
  word[4] := (' 離隊');
  word[5] := (' 系統');
  if MODVersion = 22 then
    word[4] := (' 特殊');

  i := 0;
  while i >= 0 do
  begin
    i := CommonMenu(27, 30, 46, 5, i, word);
    case i of
      0: MenuMedcine;
      1: MenuMedPoision;
      2: MenuItem;
      5: MenuSystem;
      4: MenuLeave;
      3:
      begin
        if MODVersion = 51 then
        begin
          //ReFreshScreen;
          CallEvent(1092);
          Redraw;
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end
        else
          MenuStatus;
      end;
    end;
    Redraw;
    SDL_UpdateRect2(screen, 80, 0, screen.w - 80, screen.h);
    if where = 3 then
      break;
  end;
  Redraw;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

  {SDL_EnableKeyRepeat(0, 0);
  //DrawMMap;
  showMenu(menu);
  //SDL_EventState(SDL_KEYDOWN,SDL_IGNORE);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    if where >= 3 then
    begin
      break;
    end;
    CheckBasicEvent;
    case event.type_ of
      SDL_KEYUP:
        begin
          if (event.key.keysym.sym = sdlk_down) then
          begin
            menu := menu + 1;
            if menu > 5 - 0 * 2 then
              menu := 0;
            showMenu(menu);
          end;
          if (event.key.keysym.sym = sdlk_up) then
          begin
            menu := menu - 1;
            if menu < 0 then
              menu := 5 - 0 * 2;
            showMenu(menu);
          end;
          if (event.key.keysym.sym = sdlk_escape) then
          begin
            ReDraw;
            SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
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
            SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            break;
          end;
          if event.button.button = sdl_button_left then
          begin
            if (round(event.button.y / (RealScreen.h / screen.h)) > 32) and (round(event.button.y / (RealScreen.h / screen.h)) < 32 + 22 * (6 - 0 * 2))
              and (round(event.button.x / (RealScreen.w / screen.w)) > 27) and (round(event.button.x / (RealScreen.w / screen.w)) < 27 + 46) then
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
          if (round(event.button.y / (RealScreen.h / screen.h)) > 32) and (round(event.button.y / (RealScreen.h / screen.h)) < 32 + 22 * 6)
            and (round(event.button.x / (RealScreen.w / screen.w)) > 27) and (round(event.button.x / (RealScreen.w / screen.w)) < 27 + 46) then
          begin
            menup := menu;
            menu := (round(event.button.y / (RealScreen.h / screen.h)) - 32) div 22;
            if menu > 5 - 0 * 2 then
              menu := 5 - 0 * 2;
            if menu < 0 then
              menu := 0;
            if menup <> menu then
              showmenu(menu);
          end;
        end;

    end;
  end;
  event.key.keysym.sym := 0;
  event.button.button := 0;
  SDL_EnableKeyRepeat(50, 30);}

end;

//显示主选单

procedure ShowMenu(menu: integer);
var
  word: array[0..5] of WideString;
  i, max: integer;
begin
  word[0] := (' 醫療');
  word[1] := (' 解毒');
  word[2] := (' 物品');
  word[3] := (' 狀態');
  word[4] := (' 離隊');
  word[5] := (' 系統');
  if MODVersion = 22 then
    word[4] := (' 特殊');
  if where = 0 then
    max := 5
  else
    max := 5;
  //ReadFreshScreen(27, 30, 47, max * 22 + 29);
  Redraw;
  DrawRectangle(screen, 27, 30, 46, max * 22 + 28, 0, ColColor(255), 30);
  //当前所在位置用白色, 其余用黄色
  for i := 0 to max do
    if i = menu then
    begin
      //drawtext(screen, @word[i][1], 11, 32 + 22 * i, colcolor($66));
      DrawShadowText(screen, @word[i][1], 10, 32 + 22 * i, ColColor($66), ColColor($64));
    end
    else
    begin
      //drawtext(screen, @word[i][1], 11, 32 + 22 * i, colcolor($7));
      DrawShadowText(screen, @word[i][1], 10, 32 + 22 * i, ColColor($7), ColColor($5));
    end;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

end;

//医疗选单, 需两次选择队员

procedure MenuMedcine;
var
  role1, role2, menu: integer;
  str: WideString;
begin
  str := (' 隊員醫療能力');
  DrawTextWithRect(screen, @str[1], 80, 30, 132, ColColor($23), ColColor($21));
  menu := SelectOneTeamMember(80, 65, '%4d', 46, 0);
  //ShowMenu(0);
  //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  if menu >= 0 then
  begin
    role1 := TeamList[menu];
    str := (' 隊員目前生命');
    DrawTextWithRect(screen, @str[1], 230, 30, 132, ColColor($23), ColColor($21));
    menu := SelectOneTeamMember(230, 65, '%4d/%4d', 17, 18);
    role2 := TeamList[menu];
    if menu >= 0 then
      EffectMedcine(role1, role2);
  end;
  //waitanykey;
  //ReFreshScreen;
  //SDL_UpdateRect2(screen,0,0,screen.w,screen.h);

end;

//解毒选单

procedure MenuMedPoision;
var
  role1, role2, menu: integer;
  str: WideString;
begin
  str := (' 隊員解毒能力');
  DrawTextWithRect(screen, @str[1], 80, 30, 132, ColColor($23), ColColor($21));
  menu := SelectOneTeamMember(80, 65, '%4d', 48, 0);
  //ShowMenu(1);
  //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  if menu >= 0 then
  begin
    role1 := TeamList[menu];
    str := (' 隊員中毒程度');
    DrawTextWithRect(screen, @str[1], 230, 30, 132, ColColor($23), ColColor($21));
    menu := SelectOneTeamMember(230, 65, '%4d', 20, 0);
    role2 := TeamList[menu];
    if menu >= 0 then
      EffectMedPoison(role1, role2);
  end;
  //waitanykey;
  //ReFreshScreen;
  //showmenu(1);
  //SDL_UpdateRect2(screen,0,0,screen.w,screen.h);

end;

//物品选单

function MenuItem: boolean;
var
  point, atlu, x, y, col, row, xp, yp, iamount, menu, max, i, xm, ym: integer;
  //point似乎未使用, atlu为处于左上角的物品在列表中的序号, x, y为光标位置
  //col, row为总列数和行数
  menustring: array of WideString;
begin
  col := 9;
  row := 5;
  x := 0;
  y := 0;

  //setlength(Menuengstring, 0);
  case where of
    0, 1:
    begin
      max := 6;
      setlength(menustring, max + 1);
      menustring[0] := (' 全部物品');
      menustring[1] := (' 劇情物品');
      menustring[2] := (' 神兵寶甲');
      menustring[3] := (' 武功秘笈');
      menustring[4] := (' 靈丹妙藥');
      menustring[5] := (' 傷人暗器');
      menustring[6] := (' 整理物品');
      xm := 80;
      ym := 30;
    end;
    2:
    begin
      max := 1;
      setlength(menustring, max + 1);
      menustring[0] := (' 靈丹妙藥');
      menustring[1] := (' 傷人暗器');
      xm := 150;
      ym := 150;
    end;
  end;

  menu := 0;
  while menu >= 0 do
  begin
    menu := CommonMenu(xm, ym, 87, max, menu, menustring);

    case where of
      0, 1:
      begin
        if menu = 0 then
          i := 100
        else
          i := menu - 1;
      end;
      2:
      begin
        if menu >= 0 then
          i := menu + 3;
      end;
    end;

    if menu < 0 then
      Result := False;
    if menu = 6 then
    begin
      ReSort;
      Redraw;
    end;

    if (menu >= 0) and (menu < 6) then
    begin
      Redraw;
      WriteFreshScreen(0, 0, screen.w, screen.h);
      iamount := ReadItemList(i);
      atlu := 0;
      ShowMenuItem(row, col, x, y, atlu);
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      while (SDL_WaitEvent(@event) >= 0) do
      begin
        CheckBasicEvent;
        case event.type_ of
          SDL_KEYUP:
          begin
            if (event.key.keysym.sym = SDLK_DOWN) then
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
              ShowMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
            if (event.key.keysym.sym = SDLK_UP) then
            begin
              y := y - 1;
              if y < 0 then
              begin
                y := 0;
                if atlu > 0 then
                  atlu := atlu - col;
              end;
              ShowMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
            if (event.key.keysym.sym = SDLK_PAGEDOWN) then
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
              ShowMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
            if (event.key.keysym.sym = SDLK_PAGEUP) then
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
              ShowMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
            if (event.key.keysym.sym = SDLK_RIGHT) then
            begin
              x := x + 1;
              if x >= col then
                x := 0;
              ShowMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
            if (event.key.keysym.sym = SDLK_LEFT) then
            begin
              x := x - 1;
              if x < 0 then
                x := col - 1;
              ShowMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
            if (event.key.keysym.sym = SDLK_ESCAPE) then
            begin
              //ReDraw;
              //ShowMenu(2);
              Result := False;
              //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
              break;
            end;
            if (event.key.keysym.sym = SDLK_RETURN) or (event.key.keysym.sym = SDLK_SPACE) then
            begin
              //ReDraw;
              CurItem := RItemlist[itemlist[(y * col + x + atlu)]].Number;
              if (where <> 2) and (CurItem >= 0) and (itemlist[(y * col + x + atlu)] >= 0) then
                UseItem(CurItem);
              //ShowMenu(2);
              Result := True;
              //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
              break;
            end;
          end;
          SDL_MOUSEBUTTONUP:
          begin
            if (event.button.button = SDL_BUTTON_RIGHT) then
            begin
              //ReDraw;
              //ShowMenu(2);
              Result := False;
              //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
              break;
            end;
            if (event.button.button = SDL_BUTTON_LEFT) then
            begin
              if (round(event.button.x / (RealScreen.w / screen.w)) >= 110) and
                (round(event.button.x / (RealScreen.w / screen.w)) < 496) and
                (round(event.button.y / (RealScreen.h / screen.h)) > 90) and
                (round(event.button.y / (RealScreen.h / screen.h)) < 308) then
              begin
                //ReDraw;
                CurItem := RItemlist[itemlist[(y * col + x + atlu)]].Number;
                if (where <> 2) and (CurItem >= 0) and (itemlist[(y * col + x + atlu)] >= 0) then
                  UseItem(CurItem);
                //ShowMenu(2);
                Result := True;
                //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
                break;
              end;
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
              ShowMenuItem(row, col, x, y, atlu);
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
              ShowMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
          end;
          SDL_MOUSEMOTION:
          begin
            if (round(event.button.x / (RealScreen.w / screen.w)) >= 110) and
              (round(event.button.x / (RealScreen.w / screen.w)) < 496) and
              (round(event.button.y / (RealScreen.h / screen.h)) > 90) and
              (round(event.button.y / (RealScreen.h / screen.h)) < 308) then
            begin
              xp := x;
              yp := y;
              x := (round(event.button.x / (RealScreen.w / screen.w)) - 115) div 42;
              y := (round(event.button.y / (RealScreen.h / screen.h)) - 95) div 42;
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
                ShowMenuItem(row, col, x, y, atlu);
                SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
              end;
            end;
            if (round(event.button.x / (RealScreen.w / screen.w)) >= 110) and
              (round(event.button.x / (RealScreen.w / screen.w)) < 496) and
              (round(event.button.y / (RealScreen.h / screen.h)) > 308) then
            begin
              //atlu := atlu+col;
              if (ItemList[atlu + col * row] >= 0) then
                atlu := atlu + col;
              ShowMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
            if (round(event.button.x / (RealScreen.w / screen.w)) >= 110) and
              (round(event.button.x / (RealScreen.w / screen.w)) < 496) and
              (round(event.button.y / (RealScreen.h / screen.h)) < 90) then
            begin
              if atlu > 0 then
                atlu := atlu - col;
              ShowMenuItem(row, col, x, y, atlu);
              SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
          end;
        end;
      end;
    end;
    Redraw;
    if where = 2 then
      break;
    ShowMenu(2);
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
      if (Ritem[RItemlist[i].Number].ItemType = ItemType) or (ItemType = 100) then
      begin
        Itemlist[p] := i;
        p := p + 1;
      end;
    end;
  end;
  Result := p;

end;

procedure ReSort;
var
  amount, i, j, inum: smallint;
begin
  for I := 0 to MAX_ITEM_AMOUNT - 2 do
  begin
    for J := MAX_ITEM_AMOUNT - 1 downto i + 1 do
    begin
      if (Ritemlist[j].Number < Ritemlist[j - 1].Number) and (Ritemlist[j].Number > -1) then
      begin
        amount := Ritemlist[j].Amount;
        inum := Ritemlist[j].Number;
        Ritemlist[j].Amount := Ritemlist[j - 1].Amount;
        Ritemlist[j].Number := Ritemlist[j - 1].Number;
        Ritemlist[j - 1].Amount := amount;
        Ritemlist[j - 1].Number := inum;
      end;
    end;
  end;
  //ReArrangeItem;
end;

//显示物品选单

procedure ShowMenuItem(row, col, x, y, atlu: integer);
var
  item, i, i1, i2, len, len2, len3, listnum: integer;
  str: WideString;
  words: array[0..10] of WideString;
  words2: array[0..22] of WideString;
  words3: array[0..12] of WideString;
  p2: array[0..22] of integer;
  p3: array[0..12] of integer;
  color1, color2: integer;
begin
  words[0] := (' 劇情物品');
  words[1] := (' 神兵寶甲');
  words[2] := (' 武功秘笈');
  words[3] := (' 靈丹妙藥');
  words[4] := (' 傷人暗器');
  words2[0] := (' 生命');
  words2[1] := (' 生命');
  words2[2] := (' 中毒');
  words2[3] := (' 體力');
  words2[4] := (' 內力');
  words2[5] := (' 內力');
  words2[6] := (' 內力');
  words2[7] := (' 攻擊');
  words2[8] := (' 輕功');
  words2[9] := (' 防禦');
  words2[10] := (' 醫療');
  words2[11] := (' 用毒');
  words2[12] := (' 解毒');
  words2[13] := (' 抗毒');
  words2[14] := (' 拳掌');
  words2[15] := (' 御劍');
  words2[16] := (' 耍刀');
  words2[17] := (' 特殊');
  words2[18] := (' 暗器');
  words2[19] := (' 武學');
  words2[20] := (' 品德');
  words2[21] := (' 左右');
  words2[22] := (' 帶毒');

  words3[0] := (' 內力');
  words3[1] := (' 內力');
  words3[2] := (' 攻擊');
  words3[3] := (' 輕功');
  words3[4] := (' 用毒');
  words3[5] := (' 醫療');
  words3[6] := (' 解毒');
  words3[7] := (' 拳掌');
  words3[8] := (' 御劍');
  words3[9] := (' 耍刀');
  words3[10] := (' 特殊');
  words3[11] := (' 暗器');
  words3[12] := (' 資質');

  if MODVersion = 22 then
  begin
    words2[7] := (' 武力');
    words2[8] := (' 移動');
    words2[14] := (' 火系');
    words2[15] := (' 水系');
    words2[16] := (' 雷系');
    words2[17] := (' 土系');
    words2[18] := (' 射擊');

    words3[2] := (' 武力');
    words3[3] := (' 移動');
    words3[7] := (' 火系');
    words3[8] := (' 水系');
    words3[9] := (' 雷系');
    words3[10] := (' 土系');
    words3[11] := (' 射擊');
    words3[12] := (' 智力');
  end;

  ReadFreshScreen(0, 0, screen.w, screen.h);
  DrawRectangle(screen, 110, 30, 386, 25, 0, ColColor(255), 30);
  DrawRectangle(screen, 110, 60, 386, 25, 0, ColColor(255), 30);
  DrawRectangle(screen, 110, 90, 386, 218, 0, ColColor(255), 30);
  DrawRectangle(screen, 110, 313, 386, 25, 0, ColColor(255), 30);
  //i:=0;
  for i1 := 0 to row - 1 do
    for i2 := 0 to col - 1 do
    begin
      listnum := ItemList[i1 * col + i2 + atlu];
      if (RItemlist[listnum].Number >= 0) and (listnum < MAX_ITEM_AMOUNT) and (listnum >= 0) then
      begin
        if (i1 = y) and (i2 = x) then
          DrawMPic(ITEM_BEGIN_PIC + RItemlist[listnum].Number, i2 * 42 + 115, i1 * 42 + 95, 0, 0, 0, 0)
        else
          DrawMPic(ITEM_BEGIN_PIC + RItemlist[listnum].Number, i2 * 42 + 115, i1 * 42 + 95, 0, 25, 0, 15);
      end;
    end;
  listnum := itemlist[y * col + x + atlu];
  if (listnum >= 0) and (listnum < MAX_ITEM_AMOUNT) then
    item := RItemlist[listnum].Number
  else
    item := -1;

  if (RItemlist[listnum].Amount > 0) and (listnum < MAX_ITEM_AMOUNT) and (listnum >= 0) then
  begin
    str := format('%5d', [RItemlist[listnum].Amount]);
    DrawEngText(screen, @str[1], 431, 32, ColColor($64));
    DrawEngText(screen, @str[1], 430, 32, ColColor($66));
    len := length(PChar(@Ritem[item].Name));
    DrawBig5Text(screen, @Ritem[item].Name, 286 - len * 5, 32, ColColor($21));
    DrawBig5Text(screen, @Ritem[item].Name, 285 - len * 5, 32, ColColor($23));
    len := length(PChar(@Ritem[item].Introduction));
    DrawBig5Text(screen, @Ritem[item].Introduction, 286 - len * 5, 62, ColColor($5));
    DrawBig5Text(screen, @Ritem[item].Introduction, 285 - len * 5, 62, ColColor($7));
    DrawShadowText(screen, @words[Ritem[item].ItemType, 1], 97, 315, ColColor($23), ColColor($21));
    //如有人使用则显示
    if Ritem[item].User >= 0 then
    begin
      str := (' 使用人：');
      DrawShadowText(screen, @str[1], 187, 315, ColColor($23), ColColor($21));
      DrawBig5ShadowText(screen, @Rrole[Ritem[item].User].Name, 277, 315, ColColor($66), ColColor($64));
    end;
    //如是罗盘则显示坐标
    if item = COMPASS_ID then
    begin
      str := (' 你的位置：');
      DrawShadowText(screen, @str[1], 187, 315, ColColor($23), ColColor($21));
      str := format('%3d, %3d', [My, Mx]);
      DrawEngShadowText(screen, @str[1], 317, 315, ColColor($66), ColColor($64));
    end;
  end;

  if (item >= 0) and (Ritem[item].ItemType > 0) then
  begin
    len2 := 0;
    for i := 0 to 22 do
    begin
      p2[i] := 0;
      if (Ritem[item].Data[45 + i] <> 0) and (i <> 4) then
      begin
        p2[i] := 1;
        len2 := len2 + 1;
      end;
    end;
    if Ritem[item].ChangeMPType = 2 then
    begin
      p2[4] := 1;
      len2 := len2 + 1;
    end;

    len3 := 0;
    for i := 0 to 12 do
    begin
      p3[i] := 0;
      if (Ritem[item].Data[69 + i] <> 0) and (i <> 0) then
      begin
        p3[i] := 1;
        len3 := len3 + 1;
      end;
    end;
    if (Ritem[item].NeedMPType in [0, 1]) and (Ritem[item].ItemType <> 3) then
    begin
      p3[0] := 1;
      len3 := len3 + 1;
    end;

    if len2 + len3 > 0 then
      DrawRectangle(screen, 110, 344, 386, 20 * ((len2 + 2) div 3 + (len3 + 2) div 3) + 5, 0, ColColor(255), 30);

    i1 := 0;
    for i := 0 to 22 do
    begin
      if (p2[i] = 1) then
      begin
        str := format('%6d', [Ritem[item].Data[45 + i]]);
        if i = 4 then
          case Ritem[item].ChangeMPType of
            0: str := ('    陰');
            1: str := ('    陽');
            2: str := ('  調和');
          end;
        if (i = 0) or (i = 5) then
        begin
          color1 := ColColor($10);
          color2 := ColColor($13);
        end
        else
        begin
          color1 := ColColor($64);
          color2 := ColColor($66);
        end;
        DrawShadowText(screen, @words2[i][1], 97 + i1 mod 3 * 130, i1 div 3 * 20 + 346, ColColor($7), ColColor($5));
        DrawShadowText(screen, @str[1], 147 + i1 mod 3 * 130, i1 div 3 * 20 + 346, color1, color2);
        i1 := i1 + 1;
      end;
    end;

    i1 := 0;
    for i := 0 to 12 do
    begin
      if (p3[i] = 1) then
      begin
        str := format('%6d', [Ritem[item].Data[69 + i]]);
        if i = 0 then
          case Ritem[item].NeedMPType of
            0: str := ('    陰');
            1: str := ('    陽');
            2: str := ('  調和');
          end;
        if (i = 1) then
        begin
          color1 := ColColor($10);
          color2 := ColColor($13);
        end
        else
        begin
          color1 := ColColor($64);
          color2 := ColColor($66);
        end;
        DrawShadowText(screen, @words3[i][1], 97 + i1 mod 3 * 130, ((len2 + 2) div 3 + i1 div 3) *
          20 + 346, ColColor($50), ColColor($4E));
        DrawShadowText(screen, @str[1], 147 + i1 mod 3 * 130, ((len2 + 2) div 3 + i1 div 3) *
          20 + 346, color1, color2);
        i1 := i1 + 1;
      end;
    end;
  end;

  DrawItemFrame(x, y);

end;

//画白色边框作为物品选单的光标

procedure DrawItemFrame(x, y: integer);
var
  i, xp, yp, d: integer;
  t: byte;
begin
  xp := 110;
  yp := 60;
  d := 42;
  for i := 0 to 39 do
  begin
    t := 250 - i * 3;
    putpixel(screen, x * d + 6 + i + xp, y * d + 36 + yp, SDL_MapRGB(screen.format, t, t, t));
    putpixel(screen, x * d + 6 + 39 - i + xp, y * d + 36 + 39 + yp, SDL_MapRGB(screen.format, t, t, t));
    putpixel(screen, x * d + 6 + xp, y * d + 36 + i + yp, SDL_MapRGB(screen.format, t, t, t));
    putpixel(screen, x * d + 6 + 39 + xp, y * d + 36 + 39 - i + yp, SDL_MapRGB(screen.format, t, t, t));
  end;

end;

//使用物品

procedure UseItem(inum: integer);
var
  x, y, menu, rnum, p: integer;
  str, str1: WideString;
  menustring: array of WideString;
begin
  CurItem := inum;
  Redraw;
  case Ritem[inum].ItemType of
    0: //剧情物品
    begin
      //如某属性大于0, 直接调用事件
      if Ritem[inum].UnKnow7 > 0 then
        CallEvent(Ritem[inum].UnKnow7)
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
          if SData[CurScence, 3, x, y] >= 0 then
          begin
            CurEvent := SData[CurScence, 3, x, y];
            if DData[CurScence, SData[CurScence, 3, x, y], 3] >= 0 then
              CallEvent(DData[CurScence, SData[CurScence, 3, x, y], 3]);
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
        Redraw;
        setlength(menustring, 2);
        menustring[0] := (' 取消');
        menustring[1] := (' 繼續');
        str := (' 此物品正有人裝備，是否繼續？');
        DrawTextWithRect(screen, @str[1], 80, 30, 285, ColColor(7), ColColor(5));
        menu := CommonMenu(80, 65, 45, 1, menustring);
      end;
      if menu = 1 then
      begin
        Redraw;
        str := (' 誰要裝備');
        str1 := Big5ToUnicode(@Ritem[inum].Name);
        DrawTextWithRect(screen, @str[1], 80, 30, length(str1) * 22 + 80, ColColor($23), ColColor($21));
        DrawShadowText(screen, @str1[1], 160, 32, ColColor($66), ColColor($64));
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        menu := SelectOneTeamMember(80, 65, '', 0, 0);
        if menu >= 0 then
        begin
          rnum := Teamlist[menu];
          p := Ritem[inum].EquipType;
          if (p < 0) or (p > 1) then
            p := 0;
          if CanEquip(rnum, inum) then
          begin
            if Ritem[inum].User >= 0 then
              Rrole[Ritem[inum].User].Equip[p] := -1;
            if Rrole[rnum].Equip[p] >= 0 then
              Ritem[Rrole[rnum].Equip[p]].User := -1;
            Rrole[rnum].Equip[p] := inum;
            Ritem[inum].User := rnum;
          end
          else
          begin
            str := (' 此人不適合裝備此物品');
            DrawTextWithRect(screen, @str[1], 80, 230, 205, ColColor($66), ColColor($64));
            WaitAnyKey;
            Redraw;
            //SDL_UpdateRect2(screen,0,0,screen.w,screen.h);
          end;
        end;
      end;
    end;
    2: //秘笈
    begin
      menu := 1;
      if Ritem[inum].User >= 0 then
      begin
        Redraw;
        setlength(menustring, 2);
        menustring[0] := (' 取消');
        menustring[1] := (' 繼續');
        str := (' 此秘笈正有人修煉，是否繼續？');
        DrawTextWithRect(screen, @str[1], 80, 30, 285, ColColor(7), ColColor(5));
        menu := CommonMenu(80, 65, 45, 1, menustring);
      end;
      if menu = 1 then
      begin
        Redraw;
        str := (' 誰要修煉');
        str1 := Big5ToUnicode(@Ritem[inum].Name);
        DrawTextWithRect(screen, @str[1], 80, 30, length(str1) * 22 + 80, ColColor($23), ColColor($21));
        DrawShadowText(screen, @str1[1], 160, 32, ColColor($66), ColColor($64));
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        menu := SelectOneTeamMember(80, 65, '', 0, 0);
        if menu >= 0 then
        begin
          rnum := TeamList[menu];
          if CanEquip(rnum, inum) then
          begin
            if Ritem[inum].User >= 0 then
              Rrole[Ritem[inum].User].PracticeBook := -1;
            if Rrole[rnum].PracticeBook >= 0 then
              Ritem[Rrole[rnum].PracticeBook].User := -1;
            Rrole[rnum].PracticeBook := inum;
            Ritem[inum].User := rnum;
              {if (inum in [78, 93]) then
                rrole[rnum].Sexual := 2;}
          end
          else
          begin
            str := (' 此人不適合修煉此秘笈');
            DrawTextWithRect(screen, @str[1], 80, 230, 205, ColColor($66), ColColor($64));
            WaitAnyKey;
            Redraw;
            //SDL_UpdateRect2(screen,0,0,screen.w,screen.h);
          end;
        end;
      end;
    end;
    3: //药品
    begin
      if where <> 2 then
      begin
        str := (' 誰要服用');
        str1 := Big5ToUnicode(@Ritem[inum].Name);
        DrawTextWithRect(screen, @str[1], 80, 30, length(str1) * 22 + 80, ColColor($23), ColColor($21));
        DrawShadowText(screen, @str1[1], 160, 32, ColColor($66), ColColor($64));
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        menu := SelectOneTeamMember(80, 65, '', 0, 0);
        rnum := TeamList[menu];
      end;
      if menu >= 0 then
      begin
        Redraw;
        EatOneItem(rnum, inum);
        instruct_32(inum, -1);
        WaitAnyKey;
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
  menustring: array[0..2] of WideString;
  str: WideString;
begin

  //判断是否符合
  //注意这里对'所需属性'为负值时均添加原版类似资质的处理

  Result := True;

  if sign(Ritem[inum].NeedMP) * Rrole[rnum].CurrentMP < Ritem[inum].NeedMP then
    Result := False;
  if sign(Ritem[inum].NeedAttack) * Rrole[rnum].Attack < Ritem[inum].NeedAttack then
    Result := False;
  if sign(Ritem[inum].NeedSpeed) * Rrole[rnum].Speed < Ritem[inum].NeedSpeed then
    Result := False;
  if sign(Ritem[inum].NeedUsePoi) * Rrole[rnum].UsePoi < Ritem[inum].NeedUsepoi then
    Result := False;
  if sign(Ritem[inum].NeedMedcine) * Rrole[rnum].Medcine < Ritem[inum].NeedMedcine then
    Result := False;
  if sign(Ritem[inum].NeedMedPoi) * Rrole[rnum].MedPoi < Ritem[inum].NeedMedPoi then
    Result := False;
  if sign(Ritem[inum].NeedFist) * Rrole[rnum].Fist < Ritem[inum].NeedFist then
    Result := False;
  if sign(Ritem[inum].NeedSword) * Rrole[rnum].Sword < Ritem[inum].NeedSword then
    Result := False;
  if sign(Ritem[inum].NeedKnife) * Rrole[rnum].Knife < Ritem[inum].NeedKnife then
    Result := False;
  if sign(Ritem[inum].NeedUnusual) * Rrole[rnum].Unusual < Ritem[inum].NeedUnusual then
    Result := False;
  if sign(Ritem[inum].NeedHidWeapon) * Rrole[rnum].HidWeapon < Ritem[inum].NeedHidWeapon then
    Result := False;
  if sign(Ritem[inum].NeedAptitude) * Rrole[rnum].Aptitude < Ritem[inum].NeedAptitude then
    Result := False;

  //内力性质
  if (Rrole[rnum].MPType < 2) and (Ritem[inum].NeedMPType < 2) then
    if Rrole[rnum].MPType <> Ritem[inum].NeedMPType then
      Result := False;

  //如有专用人物, 前面的都作废
  if (Ritem[inum].OnlyPracRole >= 0) and (Result = True) then
    if (Ritem[inum].OnlyPracRole = rnum) then
      Result := True
    else
      Result := False;

  //如已有10种武功, 且物品也能练出武功, 则结果为假
  r := 0;
  for i := 0 to 9 do
    if Rrole[rnum].Magic[i] > 0 then
      r := r + 1;
  if (r >= 10) and (Ritem[inum].Magic > 0) then
    Result := False;

  //如果已有秘籍所练出的武功且小于10级, 则为真
  for i := 0 to 9 do
    if (Rrole[rnum].Magic[i] = Ritem[inum].Magic) and (Rrole[rnum].MagLevel[i] < 900) then
    begin
      Result := True;
      break;
    end;

  //如果以上判定为真, 且属于自宫物品, 则提问, 若选否则为假
  if (inum in [78, 93]) and (Result = True) and (Rrole[rnum].Sexual <> 2) then
  begin
    Redraw;
    menustring[0] := (' 取消');
    menustring[1] := (' 繼續');
    str := (' 是否自宮？');
    DrawTextWithRect(screen, @str[1], 80, 30, 105, ColColor(7), ColColor(5));
    if CommonMenu(80, 65, 45, 1, menustring) = 0 then
      Result := False
    else
      Rrole[rnum].Sexual := 2;
  end;

end;

//查看状态选单

procedure MenuStatus;
var
  str: WideString;
  menu, amount, i: integer;
  menustring, menuengstring: array of WideString;
begin
  str := (' 查看隊員狀態');
  Redraw;
  WriteFreshScreen(0, 0, screen.w, screen.h);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  DrawTextWithRect(screen, @str[1], 10, 30, 132, ColColor($23), ColColor($21));
  setlength(Menustring, 6);
  setlength(Menuengstring, 0);
  amount := 0;

  for i := 0 to 5 do
  begin
    if Teamlist[i] >= 0 then
    begin
      menustring[i] := Big5ToUnicode(@Rrole[Teamlist[i]].Name);
      amount := amount + 1;
    end;
  end;

  menu := CommonMenu(10, 65, 85, amount - 1, 0, menustring, menuengstring, @ShowStatusByTeam);
  Redraw;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  //menu := SelectOneTeamMember(27, 65, '%3d', 15, 0);
  {if menu >= 0 then
  begin
    ShowStatus(TeamList[menu]);
    waitanykey;
    redraw;
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  end;}

end;

//显示状态

procedure ShowStatusByTeam(tnum: integer);
begin
  if TeamList[tnum] >= 0 then
    ShowStatus(TeamList[tnum], 100, 65);
end;

procedure ShowStatus(rnum: integer); overload;
begin
  ShowStatus(rnum, CENTER_X - 273, 65);
end;

procedure ShowStatus(rnum, x, y: integer); overload;
var
  i, magicnum, mlevel, needexp: integer;
  p: array[0..10] of integer;
  addatk, adddef, addspeed: integer;
  str: WideString;
  strs: array[0..21] of WideString;
  color1, color2: uint32;
  Name: WideString;
begin
  strs[0] := (' 等級');
  strs[1] := (' 生命');
  strs[2] := (' 內力');
  strs[3] := (' 體力');
  strs[4] := (' 經驗');
  strs[5] := (' 升級');
  strs[6] := (' 攻擊');
  strs[7] := (' 防禦');
  strs[8] := (' 輕功');
  strs[9] := (' 醫療能力');
  strs[10] := (' 用毒能力');
  strs[11] := (' 解毒能力');
  strs[12] := (' 拳掌功夫');
  strs[13] := (' 御劍能力');
  strs[14] := (' 耍刀技巧');
  strs[15] := (' 特殊兵器');
  strs[16] := (' 暗器技巧');
  strs[17] := (' 裝備物品');
  strs[18] := (' 修煉物品');
  strs[19] := (' 所會武功');
  strs[20] := (' 受傷');
  strs[21] := (' 中毒');

  if MODVersion = 22 then
  begin
    strs[6] := (' 武力');
    strs[8] := (' 移動');
    strs[12] := (' 火系能力');
    strs[13] := (' 水系能力');
    strs[14] := (' 雷系能力');
    strs[15] := (' 土系能力');
    strs[16] := (' 射擊能力');
  end;

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

  ReadFreshScreen(0, 0, screen.w, screen.h);

  DrawRectangle(screen, x, y, 525, 315, 0, ColColor(255), 50);

  //显示头像
  DrawHeadPic(Rrole[rnum].HeadNum, x + 60, y + 80);
  //显示姓名
  Name := Big5ToUnicode(@Rrole[rnum].Name);
  DrawShadowText(screen, @Name[1], x + 68 - length(PChar(@Rrole[rnum].Name)) * 5, y + 85,
    ColColor($66), ColColor($63));
  //显示所需字符
  for i := 0 to 5 do
    DrawShadowText(screen, @strs[i, 1], x - 10, y + 110 + 21 * i, ColColor($23), ColColor($21));
  for i := 6 to 16 do
    DrawShadowText(screen, @strs[i, 1], x + 160, y + 5 + 21 * (i - 6), ColColor($66), ColColor($63));
  DrawShadowText(screen, @strs[19, 1], x + 340, y + 5, ColColor($23), ColColor($21));

  addatk := 0;
  adddef := 0;
  addspeed := 0;
  if Rrole[rnum].Equip[0] >= 0 then
  begin
    addatk := addatk + Ritem[Rrole[rnum].Equip[0]].AddAttack;
    adddef := adddef + Ritem[Rrole[rnum].Equip[0]].AddDefence;
    addspeed := addspeed + Ritem[Rrole[rnum].Equip[0]].AddSpeed;
  end;

  if Rrole[rnum].Equip[1] >= 0 then
  begin
    addatk := addatk + Ritem[Rrole[rnum].Equip[1]].AddAttack;
    adddef := adddef + Ritem[Rrole[rnum].Equip[1]].AddDefence;
    addspeed := addspeed + Ritem[Rrole[rnum].Equip[1]].AddSpeed;
  end;

  //攻击, 防御, 轻功
  //单独处理是因为显示顺序和存储顺序不同
  str := format('%4d', [Rrole[rnum].Attack + addatk]);
  DrawEngShadowText(screen, @str[1], x + 280, y + 5 + 21 * 0, ColColor($7), ColColor($5));
  str := format('%4d', [Rrole[rnum].Defence + adddef]);
  DrawEngShadowText(screen, @str[1], x + 280, y + 5 + 21 * 1, ColColor($7), ColColor($5));
  str := format('%4d', [Rrole[rnum].Speed + addspeed]);
  DrawEngShadowText(screen, @str[1], x + 280, y + 5 + 21 * 2, ColColor($7), ColColor($5));

  //其他属性
  str := format('%4d', [Rrole[rnum].Medcine]);
  DrawEngShadowText(screen, @str[1], x + 280, y + 5 + 21 * 3, ColColor($7), ColColor($5));

  str := format('%4d', [Rrole[rnum].UsePoi]);
  DrawEngShadowText(screen, @str[1], x + 280, y + 5 + 21 * 4, ColColor($7), ColColor($5));

  str := format('%4d', [Rrole[rnum].MedPoi]);
  DrawEngShadowText(screen, @str[1], x + 280, y + 5 + 21 * 5, ColColor($7), ColColor($5));

  str := format('%4d', [Rrole[rnum].Fist]);
  DrawEngShadowText(screen, @str[1], x + 280, y + 5 + 21 * 6, ColColor($7), ColColor($5));

  str := format('%4d', [Rrole[rnum].Sword]);
  DrawEngShadowText(screen, @str[1], x + 280, y + 5 + 21 * 7, ColColor($7), ColColor($5));

  str := format('%4d', [Rrole[rnum].Knife]);
  DrawEngShadowText(screen, @str[1], x + 280, y + 5 + 21 * 8, ColColor($7), ColColor($5));

  str := format('%4d', [Rrole[rnum].Unusual]);
  DrawEngShadowText(screen, @str[1], x + 280, y + 5 + 21 * 9, ColColor($7), ColColor($5));

  str := format('%4d', [Rrole[rnum].HidWeapon]);
  DrawEngShadowText(screen, @str[1], x + 280, y + 5 + 21 * 10, ColColor($7), ColColor($5));

  //武功
  for i := 0 to 9 do
  begin
    magicnum := Rrole[rnum].magic[i];
    if magicnum > 0 then
    begin
      DrawBig5ShadowText(screen, @Rmagic[magicnum].Name, x + 340, y + 26 + 21 * i, ColColor($7), ColColor($5));
      str := format('%3d', [Rrole[rnum].MagLevel[i] div 100 + 1]);
      DrawEngShadowText(screen, @str[1], x + 480, y + 26 + 21 * i, ColColor($66), ColColor($64));
    end;
  end;
  str := format('%4d', [Rrole[rnum].Level]);
  DrawEngShadowText(screen, @str[1], x + 110, y + 110, ColColor($7), ColColor($5));
  //生命值, 在受伤和中毒值不同时使用不同颜色
  case Rrole[rnum].Hurt of
    34..66:
    begin
      color1 := ColColor($E);
      color2 := ColColor($10);
    end;
    67..1000:
    begin
      color1 := ColColor($14);
      color2 := ColColor($16);
    end;
    else
    begin
      color1 := ColColor($7);
      color2 := ColColor($5);
    end;
  end;
  str := format('%4d', [Rrole[rnum].CurrentHP]);
  DrawEngShadowText(screen, @str[1], x + 60, y + 131, color1, color2);

  str := '/';
  DrawEngShadowText(screen, @str[1], x + 100, y + 131, ColColor($66), ColColor($63));

  case Rrole[rnum].Poison of
    34..66:
    begin
      color1 := ColColor($30);
      color2 := ColColor($32);
    end;
    67..1000:
    begin
      color1 := ColColor($35);
      color2 := ColColor($37);
    end;
    else
    begin
      color1 := ColColor($23);
      color2 := ColColor($21);
    end;
  end;
  str := format('%4d', [Rrole[rnum].MaxHP]);
  DrawEngShadowText(screen, @str[1], x + 110, y + 131, color1, color2);
  //内力, 依据内力性质使用颜色
  if Rrole[rnum].MPType = 0 then
  begin
    color1 := ColColor($50);
    color2 := ColColor($4E);
  end
  else if Rrole[rnum].MPType = 1 then
  begin
    color1 := ColColor($7);
    color2 := ColColor($5);
  end
  else
  begin
    color1 := ColColor($66);
    color2 := ColColor($63);
  end;
  str := format('%4d/%4d', [Rrole[rnum].CurrentMP, Rrole[rnum].MaxMP]);
  DrawEngShadowText(screen, @str[1], x + 60, y + 152, color1, color2);
  //体力
  str := format('%4d/%4d', [Rrole[rnum].PhyPower, MAX_PHYSICAL_POWER]);
  DrawEngShadowText(screen, @str[1], x + 60, y + 173, ColColor($7), ColColor($5));
  //经验
  str := format('%5d', [uint16(Rrole[rnum].Exp)]);
  DrawEngShadowText(screen, @str[1], x + 100, y + 194, ColColor($7), ColColor($5));
  str := format('%5d', [uint16(Leveluplist[Rrole[rnum].Level - 1])]);
  DrawEngShadowText(screen, @str[1], x + 100, y + 215, ColColor($7), ColColor($5));

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
  DrawShadowText(screen, @strs[17, 1], x + 160, y + 240, ColColor($23), ColColor($21));
  DrawShadowText(screen, @strs[18, 1], x + 340, y + 240, ColColor($23), ColColor($21));
  if Rrole[rnum].Equip[0] >= 0 then
    DrawBig5ShadowText(screen, @Ritem[Rrole[rnum].Equip[0]].Name, x + 170, y + 261, ColColor($7), ColColor($5));
  if Rrole[rnum].Equip[1] >= 0 then
    DrawBig5ShadowText(screen, @Ritem[Rrole[rnum].Equip[1]].Name, x + 170, y + 282, ColColor($7), ColColor($5));

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
    DrawBig5ShadowText(screen, @Ritem[Rrole[rnum].PracticeBook].Name, x + 350, y + 261, ColColor($7), ColColor($5));
    str := format('%5d/%5d', [uint16(Rrole[rnum].ExpForBook), needexp]);
    if mlevel = 10 then
      str := format('%5d/=', [uint16(Rrole[rnum].ExpForBook)]);
    DrawEngShadowText(screen, @str[1], x + 380, y + 282, ColColor($66), ColColor($63));
  end;

  SDL_UpdateRect2(screen, x, y, 536, 316);

end;

//离队选单

procedure MenuLeave;
var
  str: WideString;
  i, menu: integer;
begin
  if (where = 0) or (MODVersion = 22) then
  begin
    str := (' 要求誰離隊？');
    if MODVersion = 22 then
      str := ' 選擇一個隊友';
    DrawTextWithRect(screen, @str[1], 80, 30, 132, ColColor($23), ColColor($21));
    menu := SelectOneTeamMember(80, 65, '%3d', 15, 0);
    if menu >= 0 then
    begin
      for i := 0 to 99 do
        if leavelist[i] = TeamList[menu] then
        begin
          Redraw;
          CallEvent(BEGIN_LEAVE_EVENT + i * 2);
          //Redraw;
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          //SDL_EnableKeyRepeat(0, 10);
          break;
        end;
    end;
  end
  else
  begin
    str := ' 場景內不可離隊！';
    DrawTextWithRect(screen, @str[1], 80, 30, 172, ColColor($23), ColColor($21));
    WaitAnyKey;
  end;
  Redraw;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
end;

//系统选单

procedure MenuSystem;
var
  word: array[0..3] of WideString;
  i: integer;
begin
  word[0] := (' 讀取');
  word[1] := (' 存檔');
  word[2] := (' 全屏');
  word[3] := (' 離開');
  if FULLSCREEN = 1 then
    word[2] := (' 窗口');

  i := 0;
  while i >= 0 do
  begin
    i := CommonMenu(80, 30, 46, 3, i, word);

    case i of
      3: MenuQuit;
      1: MenuSave;
      0: MenuLoad;
      2:
      begin
        SwitchFullscreen;
        break;
      end;
    end;
    if where = 3 then
      break;
    Redraw;
    SDL_UpdateRect2(screen, 133, 0, screen.w - 133, screen.h);
  end;

end;

{var
  i, menu, menup: integer;
begin
  menu := 0;
  showmenusystem(menu);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    if where = 3 then
      break;
      CheckBasicEvent;
      case event.type_ of
      SDL_KEYUP:
        begin
          if (event.key.keysym.sym = sdlk_down) then
          begin
            menu := menu + 1;
            if menu > 3 then
              menu := 0;
            showMenusystem(menu);
          end;
          if (event.key.keysym.sym = sdlk_up) then
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
                  SwitchFullScreen;
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
                  SwitchFullScreen;
                  break;
                end;
            end;
        end;
      SDL_MOUSEMOTION:
        begin
          if (round(event.button.x / (RealScreen.w / screen.w)) >= 80) and (round(event.button.x / (RealScreen.w / screen.w)) < 127)
            and (round(event.button.y / (RealScreen.h / screen.h)) > 47) and (round(event.button.y / (RealScreen.h / screen.h)) < 120) then
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

end;}

//显示系统选单

procedure ShowMenuSystem(menu: integer);
{var
  word: array[0..3] of Widestring;
  i: integer;}
begin
  {Word[0] := (' 讀取');
  Word[1] := (' 存檔');
  Word[2] := (' 全屏');
  Word[3] := (' 離開');
  if fullscreen = 1 then
    Word[2] := (' 窗口');

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
  SDL_UpdateRect2(screen, 80, 30, 47, 93);}

end;

//读档选单

procedure MenuLoad;
var
  menu, nowwhere: integer;
  menustring: array[0..5] of WideString;
begin
  nowwhere := where;
  //setlength(menustring, 6);
  //setlength(Menuengstring, 0);
  menustring[0] := (' 進度一');
  menustring[1] := (' 進度二');
  menustring[2] := (' 進度三');
  menustring[3] := (' 進度四');
  menustring[4] := (' 進度五');
  menustring[5] := (' 自動檔');
  menu := CommonMenu(133, 30, 67, 5, menustring);
  if menu >= 0 then
  begin
    LoadR(menu + 1);
    if where = 1 then
    begin
      InitialScence;
      //Redraw;
      //ShowScenceName(CurScence);
    end;
    Redraw(1);
    if nowwhere = 1 then
      ShowScenceName(CurScence);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  end;
  //edraw;
  ShowMenu(5);
  ShowMenuSystem(0);

end;

//特殊的读档选单, 仅用在开始时读档

function MenuLoadAtBeginning: integer;
var
  menu: integer;
  menustring: array[0..5] of WideString;
begin
  Redraw;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  //setlength(menustring, 6);
  //setlength(Menuengstring, 0);
  menustring[0] := (' 載入進度一');
  menustring[1] := (' 載入進度二');
  menustring[2] := (' 載入進度三');
  menustring[3] := (' 載入進度四');
  menustring[4] := (' 載入進度五');
  menustring[5] := (' 載入自動檔');
  if MODVersion = 23 then
  begin
    menustring[0] := (' 載入夢境一');
    menustring[1] := (' 載入夢境二');
    menustring[2] := (' 載入夢境三');
    menustring[3] := (' 載入夢境四');
    menustring[4] := (' 載入夢境五');
    menustring[5] := (' 最近的夢境');
  end;
  //writeln(pword(@menustring[0][2])^);
  menu := CommonMenu(TitlePosition.x - 10, TitlePosition.y - 20, 107, 5, menustring);
  if menu >= 0 then
  begin
    LoadR(menu + 1);
    //where := 0;
    instruct_14;
    //Redraw;
    //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  end;
  Result := menu;
end;

//存档选单

procedure MenuSave;
var
  menu: integer;
  menustring: array[0..4] of WideString;
begin
  //setlength(menustring, 5);
  //setlength(menuengstring, 0);
  menustring[0] := (' 進度一');
  menustring[1] := (' 進度二');
  menustring[2] := (' 進度三');
  menustring[3] := (' 進度四');
  menustring[4] := (' 進度五');
  menu := CommonMenu(133, 30, 67, 4, menustring);
  if menu >= 0 then
    SaveR(menu + 1);
  //Redraw;
  ShowMenu(5);
  ShowMenuSystem(1);
end;

//退出选单

procedure MenuQuit;
var
  menu: integer;
  str1, str2: string;
  str: WideString;
  menustring: array[0..2] of WideString;
begin
  //setlength(menustring, 3);
  //setlength(menuengstring, 0);
  menustring[0] := (' 取消');
  menustring[1] := (' 確認');
  menustring[2] := (' 腳本');
  menu := CommonMenu(133, 30, 45, 2, menustring);
  if menu = 1 then
  begin
    Where := 3;
    //instruct_14;
    exit;
    //Quit;
  end;

  if menu = 2 then
  begin
    str := '  Script fail!';
    str1 := '';
    str1 := inputbox('Script file number:', str1, '1');
    str2 := '';
    str2 := inputbox('Function name:', str2, 'f1');
    if execscript(PChar(AppPath + 'script/' + str1 + '.lua'), PChar(str2)) <> 0 then
    begin
      DrawTextWithRect(screen, @str[1], 100, 200, 150, $FFFFFFFF, $FFFFFFFF);
      WaitAnyKey;
    end;
  end;
  if menu <> 1 then
  begin
    ShowMenu(5);
    ShowMenuSystem(3);
  end;
end;

//医疗的效果
//未添加体力的需求与消耗

function EffectMedcine(role1, role2: integer): integer;
var
  word: WideString;
  addlife, minushurt: integer;
begin
  addlife := Rrole[role1].Medcine * MED_LIFE * (10 - Rrole[role2].Hurt div 15) div 10;
  if Rrole[role2].Hurt - Rrole[role1].Medcine > 20 then
    addlife := 0;
  minushurt := addlife div LIFE_HURT;
  if minushurt > Rrole[role2].Hurt then
    minushurt := Rrole[role2].Hurt;
  Rrole[role2].Hurt := Rrole[role2].Hurt - minushurt;
  if Rrole[role2].Hurt < 0 then
    Rrole[role2].Hurt := 0;
  if addlife > Rrole[role2].MaxHP - Rrole[role2].CurrentHP then
    addlife := Rrole[role2].MaxHP - Rrole[role2].CurrentHP;
  Rrole[role2].CurrentHP := Rrole[role2].CurrentHP + addlife;
  Result := addlife;

  if where <> 2 then
  begin
    Redraw;
    DrawRectangle(screen, 115, 98, 155, 76, 0, ColColor(255), 30);
    DrawBig5ShadowText(screen, @Rrole[role2].Name, 100, 100, ColColor($23), ColColor($21));
    word := (' 增加生命');
    DrawShadowText(screen, @word[1], 100, 125, ColColor($7), ColColor($5));
    word := format('%4d', [addlife]);
    DrawEngShadowText(screen, @word[1], 220, 125, ColColor($66), ColColor($64));
    word := (' 減少受傷');
    DrawShadowText(screen, @word[1], 100, 150, ColColor($7), ColColor($5));
    word := format('%4d', [minushurt]);
    DrawEngShadowText(screen, @word[1], 220, 150, ColColor($66), ColColor($64));
    ShowSimpleStatus(role2, 350, 50);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    WaitAnyKey;
    Redraw;
  end;

end;

//解毒的效果

function EffectMedPoison(role1, role2: integer): integer;
var
  word: WideString;
  minuspoi: integer;
begin
  minuspoi := Rrole[role1].MedPoi;
  if minuspoi > Rrole[role2].Poison then
    minuspoi := Rrole[role2].Poison;
  Rrole[role2].Poison := Rrole[role2].Poison - minuspoi;
  Result := minuspoi;

  if where <> 2 then
  begin
    Redraw;
    DrawRectangle(screen, 115, 98, 155, 51, 0, ColColor(255), 30);
    word := (' 減少中毒');
    DrawShadowText(screen, @word[1], 100, 125, ColColor($7), ColColor($5));
    DrawBig5ShadowText(screen, @Rrole[role2].Name, 100, 100, ColColor($23), ColColor($21));
    word := format('%4d', [minuspoi]);
    DrawEngShadowText(screen, @word[1], 220, 125, ColColor($66), ColColor($64));
    ShowSimpleStatus(role2, 350, 50);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    WaitAnyKey;
    Redraw;
  end;
end;

//使用物品的效果
//练成秘笈的效果

procedure EatOneItem(rnum, inum: integer);
var
  i, p, l, x, y, twoline: integer;
  word: array[0..23] of WideString;
  addvalue, rolelist: array[0..23] of integer;
  str: WideString;
begin

  word[0] := (' 增加生命');
  word[1] := (' 增加生命最大值');
  word[2] := (' 中毒程度');
  word[3] := (' 增加體力');
  word[4] := (' 內力門路陰陽合一');
  word[5] := (' 增加內力');
  word[6] := (' 增加內力最大值');
  word[7] := (' 增加攻擊力');
  word[8] := (' 增加輕功');
  word[9] := (' 增加防禦力');
  word[10] := (' 增加醫療能力');
  word[11] := (' 增加用毒能力');
  word[12] := (' 增加解毒能力');
  word[13] := (' 增加抗毒能力');
  word[14] := (' 增加拳掌能力');
  word[15] := (' 增加御劍能力');
  word[16] := (' 增加耍刀能力');
  word[17] := (' 增加特殊兵器');
  word[18] := (' 增加暗器技巧');
  word[19] := (' 增加武學常識');
  word[20] := (' 增加品德指數');
  word[21] := (' 習得左右互搏');
  word[22] := (' 增加攻擊帶毒');
  word[23] := (' 受傷程度');

  if MODVersion = 22 then
  begin
    word[7] := (' 增加武力');
    word[8] := (' 增加移動');
    word[14] := (' 增加火系能力');
    word[15] := (' 增加水系能力');
    word[16] := (' 增加雷系能力');
    word[17] := (' 增加土系能力');
    word[18] := (' 增加射擊能力');
  end;

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

  if -addvalue[23] > Rrole[rnum].Data[19] then
    addvalue[23] := -Rrole[rnum].Data[19];

  //增加生命, 内力最大值的处理
  if addvalue[1] + Rrole[rnum].Data[18] > MAX_HP then
    addvalue[1] := MAX_HP - Rrole[rnum].Data[18];
  if addvalue[6] + Rrole[rnum].Data[42] > MAX_MP then
    addvalue[6] := MAX_MP - Rrole[rnum].Data[42];
  if addvalue[1] + Rrole[rnum].Data[18] < 0 then
    addvalue[1] := -Rrole[rnum].Data[18];
  if addvalue[6] + Rrole[rnum].Data[42] < 0 then
    addvalue[6] := -Rrole[rnum].Data[42];

  for i := 7 to 22 do
  begin
    if addvalue[i] + Rrole[rnum].Data[rolelist[i]] > MaxProList[rolelist[i]] then
      addvalue[i] := MaxProList[rolelist[i]] - Rrole[rnum].Data[rolelist[i]];
    if addvalue[i] + Rrole[rnum].Data[rolelist[i]] < 0 then
      addvalue[i] := -Rrole[rnum].Data[rolelist[i]];
  end;
  //生命不能超过最大值
  if addvalue[0] + Rrole[rnum].Data[17] > addvalue[1] + Rrole[rnum].Data[18] then
    addvalue[0] := addvalue[1] + Rrole[rnum].Data[18] - Rrole[rnum].Data[17];
  //中毒不能小于0
  if addvalue[2] + Rrole[rnum].Data[20] < 0 then
    addvalue[2] := -Rrole[rnum].Data[20];
  //体力不能超过100
  if addvalue[3] + Rrole[rnum].Data[21] > MAX_PHYSICAL_POWER then
    addvalue[3] := MAX_PHYSICAL_POWER - Rrole[rnum].Data[21];
  //内力不能超过最大值
  if addvalue[5] + Rrole[rnum].Data[41] > addvalue[6] + Rrole[rnum].Data[42] then
    addvalue[5] := addvalue[6] + Rrole[rnum].Data[42] - Rrole[rnum].Data[41];
  p := 0;
  for i := 0 to 23 do
  begin
    if (i <> 4) and (i <> 21) and (addvalue[i] <> 0) then
      p := p + 1;
  end;
  if (addvalue[4] = 2) and (Rrole[rnum].Data[40] <> 2) then
    p := p + 1;
  if (addvalue[21] = 1) and (Rrole[rnum].Data[58] <> 1) then
    p := p + 1;

  DrawRectangle(screen, 100, 70, 200, 25, 0, ColColor(255), 25);
  str := (' 服用');
  if Ritem[inum].ItemType = 2 then
    str := (' 練成');
  DrawShadowText(screen, @str[1], 83, 72, ColColor($23), ColColor($21));
  DrawBig5ShadowText(screen, @Ritem[inum].Name, 143, 72, ColColor($66), ColColor($64));

  //如果增加的项超过11个, 分两列显示
  if p < 11 then
  begin
    l := p;
    twoline := 0;
    DrawRectangle(screen, 100, 100, 200, 22 * l + 25, 0, ColColor($FF), 25);
  end
  else
  begin
    l := p div 2 + p mod 2;
    twoline := 1;
    DrawRectangle(screen, 20, 100, 400, 22 * l + 25, 0, ColColor($FF), 25);
  end;
  if twoline = 0 then
    x := 83
  else
    x := 3;
  DrawBig5ShadowText(screen, @Rrole[rnum].Data[4], x, 102, ColColor($23), ColColor($21));
  str := (' 未增加屬性');
  if p = 0 then
    DrawShadowText(screen, @str[1], 163, 102, ColColor(7), ColColor(5));
  p := 0;
  for i := 0 to 23 do
  begin
    if twoline = 0 then
    begin
      x := 0;
      y := 0;
    end
    else
    begin
      if p < l then
      begin
        x := -80;
        y := 0;
      end
      else
      begin
        x := 120;
        y := -l * 22;
      end;
    end;
    if (i <> 4) and (i <> 21) and (addvalue[i] <> 0) then
    begin
      Rrole[rnum].Data[rolelist[i]] := Rrole[rnum].Data[rolelist[i]] + addvalue[i];
      DrawShadowText(screen, @word[i, 1], 83 + x, 124 + y + p * 22, ColColor(7), ColColor(5));
      str := format('%4d', [addvalue[i]]);
      DrawEngShadowText(screen, @str[1], 243 + x, 124 + y + p * 22, ColColor($66), ColColor($64));
      p := p + 1;
    end;
    //对内力性质特殊处理
    if (i = 4) and (addvalue[i] = 2) then
    begin
      if Rrole[rnum].Data[rolelist[i]] <> 2 then
      begin
        Rrole[rnum].Data[rolelist[i]] := 2;
        DrawShadowText(screen, @word[i, 1], 83 + x, 124 + y + p * 22, ColColor(7), ColColor(5));
        p := p + 1;
      end;
    end;
    //对左右互搏特殊处理
    if (i = 21) and (addvalue[i] = 1) then
    begin
      if Rrole[rnum].Data[rolelist[i]] <> 1 then
      begin
        Rrole[rnum].Data[rolelist[i]] := 1;
        DrawShadowText(screen, @word[i, 1], 83 + x, 124 + y + p * 22, ColColor(7), ColColor(5));
        p := p + 1;
      end;
    end;
  end;
  x := 350;
  if twoline = 1 then
    x := 440;
  ShowSimpleStatus(rnum, x, 50);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

end;

//Event.
//事件系统

procedure CallEvent(num: integer);
var
  e: array of smallint;
  i, offset, len, p, temppic: integer;
  check: boolean;
  k: array[0..67] of integer;
begin
  //CurEvent:=num;
  {k[61] := 0;  k[25] := 1;  k[13] := 2;  k[2] := 3;  k[58] := 4;  k[59] := 5;  k[38] := 6;  k[37] := 7;
  k[40] := 8;  k[20] := 9;  k[36] := 10;  k[17] := 11;  k[4] := 12;  k[43] := 13;  k[23] := 14;  k[0] := 15;
  k[39] := 16;  k[66] := 17;  k[31] := 18;  k[1] := 19;  k[45] := 20;  k[16] := 21;  k[47] := 22;  k[65] := 23;
  k[53] := 24;  k[21] := 25;  k[22] := 26;  k[30] := 27;  k[5] := 28;  k[55] := 29;  k[48] := 30;  k[44] := 31;
  k[12] := 32;  k[49] := 33;  k[28] := 34;  k[60] := 35;  k[9] := 36;  k[7] := 37;  k[57] := 38;  k[42] := 39;
  k[67] := 40;  k[56] := 41;  k[34] := 42;  k[24] := 43;  k[33] := 44;  k[14] := 45;  k[18] := 46;  k[8] := 47;
  k[50] := 48;  k[11] := 49;  k[52] := 50;  k[15] := 51;  k[46] := 52;  k[32] := 53;  k[27] := 54;  k[6] := 55;
  k[51] := 56;  k[62] := 57;  k[35] := 58;  k[26] := 59;  k[63] := 60;  k[10] := 61;  k[29] := 62;  k[41] := 63;
  k[19] := 64;  k[54] := 65;  k[64] := 66;  k[3] := 67;}
  Cx := Sx;
  Cy := Sy;
  SStep := 0;
  CurScenceRolePic := BEGIN_WALKPIC + SFace * 7;
  //redraw;
  //tempPic := CurScenceRolePic;
  //SDL_EnableKeyRepeat(0, 10);

  NeedRefreshScence := 0;
  if (KDEF_SCRIPT = 0) or (not FileExists(AppPath + 'script/oldevent/oldevent_' + IntToStr(num) + '.lua')) then
  begin
    len := 0;
    if num = 0 then
    begin
      offset := 0;
      len := KIdx[0];
    end
    else
    begin
      offset := KIdx[num - 1];
      len := KIdx[num] - offset;
    end;
    setlength(e, len div 2 + 1);
    move(KDef[offset], e[0], len);
    {if MODVersion = 23 then
    begin
      for i := 0 to length div 2 do
      begin
        if (e[i] <= 67) and (e[i] >= 0) then
          e[i] := k[e[i]];
      end;
    end;}
    i := 0;
    len := length(e);
    if IsConsole then
    begin
      Write('Pointer: ', i, ', Run instruct ', e[i], ' ');
      if e[i] = 50 then
        Write(e[i + 1], ',', e[i + 2], ',', e[i + 3], ',', e[i + 4], ',', e[i + 5], ',', e[i + 6], ',', e[i + 7]);
      writeln;
    end;
    //普通事件写成子程, 需跳转事件写成函数
    while SDL_PollEvent(@event) >= 0 do
    begin
      CheckBasicEvent;
      if (i >= len - 1) then
        break;
      if (e[i] < 0) then
        break;
      case e[i] of
        0:
        begin
          i := i + 1;
          instruct_0;
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
          instruct_57;
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
          i := i + instruct_61(e[i + 1], e[i + 2]);
          i := i + 3;
        end;
        62:
        begin
          instruct_62(e[i + 1], e[i + 2], e[i + 3], e[i + 4], e[i + 5], e[i + 6]);
          i := i + 7;
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
        else
        begin
          i := i + 1;
        end;
      end;
    end;
  end
  else
  begin
    //lua_dofile(Lua_script, AppPath + 'script/oldevent/oldevent_' + inttostr(num));
    //writeln(inttostr(num));
    ExecScript(PChar(AppPath + 'script/oldevent/oldevent_' + IntToStr(num) + '.lua'), nil);
  end;

  //event.key.keysym.sym := 0;
  //event.button.button := 0;
  //CurScenceRolePic := tempPic;;
  //CurScenceRolePic := 2500 + SFace * 7 + 1;
  //事件执行完之后不刷新场景, 是因为有可能在事件本身包含另一事件, 避免频繁刷新
  if NeedRefreshScence = 1 then
  begin
    InitialScence(0);
  end;
  NeedRefreshScence := 1;
  //if where <> 2 then CurEvent := -1;
  if MMAPAMI * SCENCEAMI = 0 then
  begin
    Redraw;
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
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
    with Cloud[num] do
    begin
      Picnum := random(CPicAmount);
      Shadow := 0;
      Alpha := 10 + random(50);
      MixColor := random(256) + random(256) shl 8 + random(256) shl 16 + random(256) shl 24;
      mixAlpha := 10 + random(50);
      Positionx := 0;
      Positiony := random(8640);
      Speedx := 1 + random(3);
      Speedy := 0;
    end;
  end;
end;

function IsCave(snum: integer): boolean;
begin
  Result := snum in [5, 7, 10, 41, 42, 46, 65, 66, 67, 72, 79];
end;


function round(x: real): integer;
begin
  Result := floor(x + 0.5);
end;

procedure swap(var x, y: uint32); overload;
var
  t: uint32;
begin
  t := x;
  x := y;
  y := t;
end;

//刷新全部屏幕
procedure UpdateAllScreen;
begin
  SDL_UpdateRect2(screen, 0, 0, CENTER_X * 2, CENTER_Y * 2);
end;

//清键值
procedure CleanKeyValue;
begin
  event.key.keysym.sym := 0;
  event.button.button := 0;
end;

//换算当前鼠标的位置为人物坐标
procedure GetMousePosition(var x, y: integer; x0, y0: integer; yp: integer = 0);
var
  x1, y1: integer;
begin
  SDL_GetMouseState2(x1, y1);
  x := (-x1 + CENTER_X + 2 * (y1 + yp) - 2 * CENTER_Y + 18) div 36 + x0;
  y := (x1 - CENTER_X + 2 * (y1 + yp) - 2 * CENTER_Y + 18) div 36 + y0;
end;

end.
