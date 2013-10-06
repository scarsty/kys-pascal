unit kys_battle;

//{$MODE Delphi}

interface

uses
  SysUtils,

{$IFDEF fpc}
  LCLIntf, LCLType, LMessages, FileUtil,
{$ELSE}
  Windows,
{$ENDIF}

  StrUtils,
  Math,
  Dialogs,
  SDL,
  SDL_TTF,
  //SDL_mixer,
  SDL_image,
  kys_main;

//战斗
//从游戏文件的命名来看, 应是'war'这个词的缩写,
//但实际上战斗的规模很小, 使用'battle'显然更合适
function Battle(battlenum, getexp: integer): boolean;
function InitialBField: boolean;
function SelectTeamMembers: integer;
procedure ShowMultiMenu(max, menu, status: integer);
procedure BattleMainControl;
procedure OldBattleMainControl;
function CountProgress: integer;
procedure CalMoveAbility;
procedure ReArrangeBRole;
function BattleStatus: integer;
function BattleMenu(bnum: integer): integer;
procedure ShowBMenu(MenuStatus, menu, max: integer);
procedure ShowBMenu2(MenuStatus, menu, max, bnum: integer);
procedure MoveRole(bnum: integer);
procedure MoveAmination(bnum: integer);
procedure collect(bnum: integer);
function Selectshowstatus(bnum: integer): boolean;
function SelectAim(bnum, step: integer): boolean;
function SelectRange(bnum, AttAreaType, step, range: integer): boolean;
function SelectDirector(bnum, AttAreaType, step, range: integer): boolean;
function SelectCross(bnum, AttAreaType, step, range: integer): boolean;
function SelectFar(bnum, mnum, level: integer): boolean;

procedure SeekPath(x, y, step: integer);
procedure SeekPath2(x, y, step, myteam, mode: integer);
procedure CalCanSelect(bnum, mode, step: integer);
procedure Attack(bnum: integer);
procedure AttackAction(bnum, mnum, level: integer);
procedure ShowMagicName(mnum: integer);
function SelectMagic(bnum: integer): integer;
procedure ShowMagicMenu(bnum, menustatus, menu, max: integer);
procedure SetAminationPosition(mode, step, range: integer);
procedure PlayMagicAmination(bnum, bigami, enum, level: integer);
procedure CalHurtRole(bnum, mnum, level: integer);
function CalHurtValue(bnum1, bnum2, mnum, level: integer): integer;
procedure ShowHurtValue(mode: integer); overload;
procedure ShowHurtValue(sign, color1, color2: integer); overload;
procedure ShowHurtValue(str: WideString; color1, color2: integer); overload;
procedure CalPoiHurtLife(bnum: integer);
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
procedure MedFrozen(bnum: integer);
procedure MedPoision(bnum: integer);
procedure UseHiddenWeapen(bnum, inum: integer);
procedure Rest(bnum: integer);
procedure showprogress;
procedure AutoBattle(bnum: integer);
procedure AutoUseItem(bnum, list: integer);
procedure PetEffect;
procedure AutoBattle2(bnum: integer);
procedure trymoveattack(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; bnum, mnum, level: integer);
procedure calline(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; curX, curY, bnum, mnum, level: integer);
procedure calarea(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; curX, curY, bnum, mnum, level: integer);
procedure calNewline(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; curX, curY, bnum, mnum, level: integer);
procedure calpoint(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; curX, curY, bnum, mnum, level: integer);
procedure calcross(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; curX, curY, bnum, mnum, level: integer);
procedure caldirdiamond(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; curX, curY, bnum, mnum, level: integer);
procedure caldirangle(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; curX, curY, bnum, mnum, level: integer);
procedure calfar(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; curX, curY, bnum, mnum, level: integer);
procedure nearestmove(var Mx, My: integer; bnum: integer);
procedure farthestmove(var Mx, My: integer; bnum: integer);
procedure trymovecure(var Mx1, My1, Ax1, Ay1: integer; bnum: integer);
procedure cureaction(bnum: integer);
procedure ShowModeMenu(menu: integer);
function SelectAutoMode: integer;
procedure ShowTeamModeMenu(menu: integer);
function TeamModeMenu: boolean;
procedure Auto(bnum: integer);
function SelectLine(bnum, AttAreaType, step, range: integer): boolean;
function CalNewHurtValue(lv, min, max, Proportion: integer): integer;
function ReMoveHurt(bnum, AttackBnum: integer): smallint;
function RetortHurt(bnum, AttackBnum: integer): smallint;
procedure Hiddenaction(bnum, inum: integer);
procedure trymoveHidden(var Mx1, My1, Ax1, Ay1: integer; bnum, inum: integer);
procedure trymoveUsePoi(var Mx1, My1, Ax1, Ay1: integer; bnum: integer);
procedure UsePoiaction(bnum: integer);
procedure trymoveMedPoi(var Mx1, My1, Ax1, Ay1: integer; bnum: integer);
procedure MedPoiaction(bnum: integer);

implementation

uses kys_event, kys_engine, kys_script;

//Battle.
//战斗, 返回值为是否胜利

function Battle(battlenum, getexp: integer): boolean;
var
  i, i1, SelectTeamList, W, x, b, y: integer;
  word: WideString;
begin
  for i := 0 to length(brole) - 1 do
    Brole[i].Show := 1;
  isbattle := True;
  Bstatus := 0;
  b := 0;
  W := WHERE;
  CurrentBattle := battlenum;
  if InitialBField then
  begin
    //如果未发现自动战斗设定, 则选择人物
    SelectTeamList := SelectTeamMembers;
    BRoleAmount := 0;
    for i := 0 to length(warsta.mate) - 1 do
    begin
      if SelectTeamList and (1 shl (i + 1)) > 0 then
      begin
        y := warsta.mate_x[b];
        x := warsta.mate_y[b];
        Brole[BRoleAmount].rnum := TeamList[i];
        Brole[BRoleAmount].Team := 0;
        Brole[BRoleAmount].Y := y;
        Brole[BRoleAmount].X := x;
        Brole[BRoleAmount].Face := 2;
        if Brole[BRoleAmount].rnum = -1 then
        begin
          Brole[BRoleAmount].Dead := 1;
          Brole[BRoleAmount].Show := 1;
        end
        else
        begin
          Brole[BRoleAmount].Dead := 0;
          Brole[BRoleAmount].Show := 0;
        end;
        Brole[BRoleAmount].Step := 0;
        Brole[BRoleAmount].Acted := 0;
        Brole[BRoleAmount].ExpGot := 0;
        Brole[BRoleAmount].Auto := -1;
        Brole[BRoleAmount].Show := 0;
        Brole[BRoleAmount].Progress := 0;
        Brole[BRoleAmount].Round := 0;
        Brole[BRoleAmount].wait := 0;
        Brole[BRoleAmount].frozen := 0;
        Brole[BRoleAmount].killed := 0;
        Brole[BRoleAmount].Knowledge := 0;
        Brole[BRoleAmount].AddAtt := 0;
        Brole[BRoleAmount].AddDef := 0;
        Brole[BRoleAmount].AddSpd := 0;
        Brole[BRoleAmount].AddDodge := 0;
        Brole[BRoleAmount].AddStep := 0;
        Brole[BRoleAmount].PerfectDodge := 0;
        b := b + 1;
        BRoleAmount := BRoleAmount + 1;
      end;
    end;
    for i := 0 to length(warsta.mate) - 1 do
    begin
      if (warsta.mate[i] > 0) and (rrole[warsta.mate[i]].TeamState <> 1) then
      begin
        y := warsta.mate_x[b];
        x := warsta.mate_y[b];
        Brole[BRoleAmount].rnum := warsta.mate[i];
        Brole[BRoleAmount].Team := 0;
        Brole[BRoleAmount].Y := y;
        Brole[BRoleAmount].X := x;
        Brole[BRoleAmount].Face := 2;
        if Brole[BRoleAmount].rnum = -1 then
        begin
          Brole[BRoleAmount].Dead := 1;
          Brole[BRoleAmount].Show := 1;
        end
        else
        begin
          Brole[BRoleAmount].Dead := 0;
          Brole[BRoleAmount].Show := 0;
        end;
        Brole[BRoleAmount].Step := 0;
        Brole[BRoleAmount].Acted := 0;
        Brole[BRoleAmount].ExpGot := 0;
        Brole[BRoleAmount].Auto := -1;
        Brole[BRoleAmount].Show := 0;
        Brole[BRoleAmount].Progress := 0;
        Brole[BRoleAmount].Round := 0;
        Brole[BRoleAmount].wait := 0;
        Brole[BRoleAmount].frozen := 0;
        Brole[BRoleAmount].killed := 0;
        Brole[BRoleAmount].Knowledge := 0;
        Brole[BRoleAmount].AddAtt := 0;
        Brole[BRoleAmount].AddDef := 0;
        Brole[BRoleAmount].AddSpd := 0;
        Brole[BRoleAmount].AddDodge := 0;
        Brole[BRoleAmount].AddStep := 0;
        Brole[BRoleAmount].PerfectDodge := 0;
        b := b + 1;
        BRoleAmount := BRoleAmount + 1;
      end;
    end;
  end;
  instruct_14;
  Where := 2;
  resetpallet;
  initialwholeBfield; //初始化场景

  stopMP3;
  playmp3(warsta.battlemusic, -1);
  CurBrole := 0;

  if battlemode > 0 then
    BattleMainControl
  else
    OldBattleMainControl;
  // callevent(warsta.OperationEvent);
  RestoreRoleStatus;

  if (bstatus = 1) then
    word := UTF8Decode(' 戰鬥勝利')
  else word := UTF8Decode(' 戰鬥失敗');
  drawtextwithrect(@word[1], centER_x - 20, 55, 90, colcolor(0, 5), colcolor(0, 7));
  waitanykey;
  redraw;
  if (bstatus = 1) or ((bstatus = 2) and (getexp <> 0)) then
  begin
    for i := 0 to length(brole) - 1 do
    begin
      Brole[i].Progress := 0;
    end;
    if (bstatus = 1) then PetEffect;
    AddExp;
    CheckLevelUp;
    CheckBook;
  end;

  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

  if RScene[CurScene].EntranceMusic >= 0 then
  begin
    stopmp3;
    playmp3(RScene[CurScene].EntranceMusic, -1);
  end;

  Where := W;
  resetpallet;
  if bstatus = 1 then Result := True
  else Result := False;
  isbattle := False;
  SDL_EnableKeyRepeat(30, (30 * GameSpeed) div 10);
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
  sta, grp, autocount, idx, offset, l, i, i1, i2, x, y, fieldnum: integer;
  p: puint16;
  cc: uint16;
begin
  sta := fileopen(AppPath + 'resource/war.sta', fmopenread);
  offset := fileseek(sta, 0, 2);
  if offset < currentbattle * sizeof(warsta) then currentbattle := 0;
  l := sizeof(warsta);
  offset := currentbattle * l;
  fileseek(sta, offset, 0);
  fileread(sta, warsta, l);
  fileclose(sta);

  fieldnum := warsta.battlemap;
  if fieldnum = 0 then offset := 0
  else
  begin
    idx := fileopen(AppPath + 'resource/warfld.idx', fmopenread);
    fileseek(idx, (fieldnum - 1) * 4, 0);
    fileread(idx, offset, 4);
    fileclose(idx);
  end;
  grp := fileopen(AppPath + 'resource/warfld.grp', fmopenread);
  fileseek(grp, offset, 0);
  fileread(grp, Bfield[0, 0, 0], 2 * 64 * 64 * 2);
  fileclose(grp);
  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      Bfield[2, i1, i2] := -1;
      Bfield[5, i1, i2] := -1;
      Bfield[4, i1, i2] := -1;
    end;
  BRoleAmount := 0;
  Result := True;
  for i := 0 to length(Brole) - 1 do
  begin
    Brole[i].Team := 1;
    Brole[i].rnum := -1;
  end;
  autocount := 0;

  //我方自动参战数据
  for i := 0 to length(warsta.mate) - 1 do
  begin
    y := warsta.mate_x[i];
    x := warsta.mate_y[i];
    Brole[BRoleAmount].rnum := warsta.automate[i];
    Brole[BRoleAmount].Team := 0;
    Brole[BRoleAmount].Y := y;
    Brole[BRoleAmount].X := x;
    Brole[BRoleAmount].Face := 2;
    if Brole[BRoleAmount].rnum = -1 then
    begin
      Brole[BRoleAmount].Dead := 1;
      Brole[BRoleAmount].Show := 1;
    end
    else
    begin
      Brole[BRoleAmount].Dead := 0;
      Brole[BRoleAmount].Show := 0;
      Inc(autocount);
    end;
    Brole[BRoleAmount].Step := 0;
    Brole[BRoleAmount].Acted := 0;
    Brole[BRoleAmount].ExpGot := 0;
    Brole[BRoleAmount].Auto := -1;
    Brole[BRoleAmount].Progress := 0;
    Brole[BRoleAmount].Round := 0;
    Brole[BRoleAmount].wait := 0;
    Brole[BRoleAmount].frozen := 0;
    Brole[BRoleAmount].killed := 0;
    Brole[BRoleAmount].Knowledge := 0;
    Brole[BRoleAmount].AddAtt := 0;
    Brole[BRoleAmount].AddDef := 0;
    Brole[BRoleAmount].AddSpd := 0;
    Brole[BRoleAmount].AddDodge := 0;
    Brole[BRoleAmount].AddStep := 0;
    Brole[BRoleAmount].PerfectDodge := 0;
    BRoleAmount := BRoleAmount + 1;
  end;
  //如没有自动参战人物, 返回假, 激活选择人物
  if autocount > 0 then Result := False;
  for i := 0 to length(warsta.enemy) - 1 do
  begin
    y := warsta.enemy_x[i];
    x := warsta.enemy_y[i];
    Brole[BRoleAmount].rnum := warsta.enemy[i];
    Brole[BRoleAmount].Team := 1;
    Brole[BRoleAmount].Y := y;
    Brole[BRoleAmount].X := x;
    Brole[BRoleAmount].Face := 1;
    if Brole[BRoleAmount].rnum = -1 then
    begin
      Brole[BRoleAmount].Dead := 1;
      Brole[BRoleAmount].Show := 1;
    end
    else
    begin
      Brole[BRoleAmount].Dead := 0;
      Brole[BRoleAmount].Show := 0;
    end;
    Brole[BRoleAmount].Step := 0;
    Brole[BRoleAmount].Acted := 0;
    Brole[BRoleAmount].ExpGot := 0;
    Brole[BRoleAmount].Auto := -1;
    Brole[BRoleAmount].Show := 0;
    Brole[BRoleAmount].Progress := 0;
    Brole[BRoleAmount].Round := 0;
    Brole[BRoleAmount].wait := 0;
    Brole[BRoleAmount].frozen := 0;
    Brole[BRoleAmount].killed := 0;
    Brole[BRoleAmount].Knowledge := 0;
    Brole[BRoleAmount].AddAtt := 0;
    Brole[BRoleAmount].AddDef := 0;
    Brole[BRoleAmount].AddSpd := 0;
    Brole[BRoleAmount].AddDodge := 0;
    Brole[BRoleAmount].AddStep := 0;
    Brole[BRoleAmount].PerfectDodge := 0;
    BRoleAmount := BRoleAmount + 1;
  end;

end;

//选择人物, 返回值为整型, 按bit表示人物是否参战

function SelectTeamMembers: integer;
var
  i, menu, max, menup: integer;
begin
  Result := 0;
  max := 1;
  menu := 0;
  setlength(Menustring, 0);
  setlength(menustring, 8);
  menustring[0] := UTF8Decode('    全員出戰');
  for i := 0 to 5 do
  begin
    if Teamlist[i] >= 0 then
    begin
      menustring[i + 1] := gbktoUnicode(@RRole[Teamlist[i]].Name);
      max := max + 1;
    end;
  end;
  menustring[max] := UTF8Decode('    開始戰鬥');
  ShowMultiMenu(max, 0, 0);
  SDL_EnableKeyRepeat(10, 100);
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYUP:
      begin
        if ((event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space)) and
          (menu <> max) and (menu <> 0) then
        begin
          //选中人物则反转对应bit
          Result := Result xor (1 shl menu);
          ShowMultiMenu(max, menu, Result);
        end;
        if ((event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space)) and (menu = 0) then
        begin
          //选中人物则反转对应bit
          for i := 0 to 5 do
          begin
            if Teamlist[i] >= 0 then
            begin
              Result := Result xor (1 shl (i + 1));
            end;
          end;
          ShowMultiMenu(max, menu, Result);
        end;
        if ((event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space)) and (menu = max) then
        begin
          if Result <> 0 then break;
        end;
      end;

      SDL_KEYDOWN:
      begin
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          menu := menu - 1;
          if menu < 0 then menu := max;
          ShowMultiMenu(max, menu, Result);
        end;
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then
        begin
          menu := menu + 1;
          if menu > max then menu := 0;
          ShowMultiMenu(max, menu, Result);
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_left) and (menu <> max) and (menu <> 0) then
        begin
          Result := Result xor (1 shl menu);
          ShowMultiMenu(max, menu, Result);
        end;
        if (event.button.button = sdl_button_left) and (menu = max) then
        begin
          if Result <> 0 then break;
        end;
        if (event.button.button = sdl_button_left) and (menu = 0) then
        begin
          for i := 0 to 5 do
          begin
            if Teamlist[i] >= 0 then
            begin
              Result := Result xor (1 shl (i + 1));
            end;
          end;
          ShowMultiMenu(max, menu, Result);
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        if (round(event.button.x / (RealScreen.w / screen.w)) >= CENTER_X - 75) and
          (round(event.button.x / (RealScreen.w / screen.w)) < CENTER_X + 75) and
          (round(event.button.y / (RealScreen.h / screen.h)) >= 100) and
          (round(event.button.y / (RealScreen.h / screen.h)) < max * 22 + 128) then
        begin
          menup := menu;
          menu := (round(event.button.y / (RealScreen.h / screen.h)) - 102) div 22;
          if menup <> menu then ShowMultiMenu(max, menu, Result);
        end;
      end;
    end;
  end;
  SDL_EnableKeyRepeat(100, 30);
end;

//显示选择参战人物选单

procedure ShowMultiMenu(max, menu, status: integer);
var
  i, x, y: integer;
  str, str1, str2: WideString;
begin
  x := CENTER_X - 105;
  y := 100;
  ReDraw;

  str := UTF8Decode(' 選擇參與戰鬥之人物');
  str1 := UTF8Decode(' 參戰');
  //Drawtextwithrect(@str[1],x,y-35,200,colcolor($23),colcolor($21));
  DrawRectangle(x + 30, y, 150, max * 22 + 28, 0, colcolor(0, 255), 30);
  for i := 0 to max do
    if i = menu then
    begin
      drawshadowtext(@menustring[i][1], x + 13, y + 3 + 22 * i, colcolor(0, $64), colcolor(0, $66));
      if (status and (1 shl i)) > 0 then
        drawshadowtext(@str1[1], x + 113, y + 3 + 22 * i, colcolor(0, $64), colcolor(0, $66));
    end
    else
    begin
      drawshadowtext(@menustring[i][1], x + 13, y + 3 + 22 * i, colcolor(0, $5), colcolor(0, $7));
      if (status and (1 shl i)) > 0 then
        drawshadowtext(@str1[1], x + 113, y + 3 + 22 * i, colcolor(0, $21), colcolor(0, $23));
    end;
  SDL_UpdateRect2(screen, x + 30, y, 151, max * 22 + 28 + 1);
end;

function CountProgress: integer;
var
  i, n: integer;
  a, b: double;
begin
  b := 1;
  Result := -1;
  for i := 0 to length(Brole) - 1 do
  begin
    if (Brole[i].rnum >= 0) and (Brole[i].Dead = 0) and (Brole[i].wait = 0) then
    begin
      if BRole[i].Progress mod 300 + trunc(Brole[i].speed / 15) >= 299 then
      begin
        a := (300 - (brole[i].Progress mod 300)) / 15;
        b := min(a, b);
        Result := i;
        break;
      end;
    end;
  end;

  for i := 0 to length(Brole) - 1 do
  begin
    if (Brole[i].rnum >= 0) and (Brole[i].Dead = 0) and (Brole[i].frozen > 0) then
    begin
      Dec(Brole[i].frozen, trunc(b * (Brole[i].speed / 15)) div 3);
    end
    else if (Brole[i].rnum >= 0) and (Brole[i].Dead = 0) and (Brole[i].wait = 0) then
    begin
      Brole[i].frozen := 0;
      n := BRole[i].Progress div 300;
      Inc(BRole[i].Progress, trunc(b * (Brole[i].speed / 15)));
      if BRole[i].Progress div 300 > n then BRole[i].Progress := n * 300 + 299;
      if i = Result then BRole[i].Progress := n * 300 + 299;
    end;
  end;
  showprogress;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

end;

//战斗主控制

procedure BattleMainControl;
var
  i, n, i1, i2, add, a, k: integer;
  word: WideString;
begin
  //redraw;
  CalMoveAbility; //计算移动能力
  ReArrangeBRole;
  Bx := Brole[0].X;
  By := Brole[0].Y;
  for i := 0 to length(Brole) - 1 do
  begin
    brole[i].Round := 0;
  end;
  callevent(warsta.BoutEvent);
  for i := 0 to length(Brole) - 1 do
  begin
    brole[i].Round := 1;
    brole[i].LifeAdd := 0;
  end;
  //redraw;
  //战斗未分出胜负则继续
  while BStatus = 0 do
  begin

    redraw;
    i := CountProgress;

    if (i >= 0) then
    begin

      CurBrole := i;
      //当前人物位置作为屏幕中心
      Brole[i].Acted := 0;
      callevent(warsta.BoutEvent);
      Bx := Brole[i].X;
      By := Brole[i].Y;
      if BStatus > 0 then break;

      redraw;
      showprogress;
      for i1 := 0 to 63 do
      begin
        for i2 := 0 to 63 do
        begin
          bfield[4, i1, i2] := 0;
        end;
      end;


      while (SDL_PollEvent(@event) >= 0) do
      begin
        if event.type_ = SDL_VIDEORESIZE then
        begin
          ResizeWindow(event.resize.w, event.resize.h);
        end;
        if (event.type_ = SDL_QUITEV) then
          if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then Quit;
        if (event.key.keysym.sym = sdlk_Escape) or (event.button.button = sdl_button_right) then
        begin
          brole[i].Auto := -1;
          //AutoMode[i]:=-1;
          event.button.button := 0;
          event.key.keysym.sym := 0;
        end;
        break;
      end;
      //战场序号保存至变量28005
      x50[28005] := i;


      //为我方且未阵亡, 非自动战斗, 则显示选单
      if (Brole[i].Dead = 0) and (Brole[i].rnum >= 0) and (Brole[i].Acted = 0) then
      begin
        CurBrole := i;

        if Brole[i].lifeAdd = 0 then
        begin
          Brole[i].AddAtt := max(0, Brole[i].AddAtt - 1);
          Brole[i].AddDef := max(0, Brole[i].AddDef - 1);
          Brole[i].AddSpd := max(0, Brole[i].AddSpd - 1);
          Brole[i].AddDodge := max(0, Brole[i].AddDodge - 1);
          Brole[i].AddStep := max(0, Brole[i].AddStep - 1);
          Brole[i].PerfectDodge := max(0, Brole[i].PerfectDodge - 1);
          //状态11，自动回血
          if (GetEquipState(Brole[i].rnum, 11)) or (GetGongtiState(Brole[i].rnum, 11)) then
          begin
            add := 0;
            add := Rrole[Brole[i].rnum].MaxHP div 10;
            if Rrole[Brole[i].rnum].MaxHP < Rrole[Brole[i].rnum].CurrentHP + add then
              add := Rrole[Brole[i].rnum].MaxHP - Rrole[Brole[i].rnum].CurrentHP;
            for a := 0 to length(brole) - 1 do
              Brole[a].ShowNumber := -1;
            Brole[i].ShowNumber := add;
            if add > 0 then ShowHurtValue(3);
            Rrole[Brole[i].rnum].CurrentHP := Rrole[Brole[i].rnum].CurrentHP + add;
          end;
          //状态23，自动回内
          if (GetEquipState(Brole[i].rnum, 23)) or (GetGongtiState(Brole[i].rnum, 23)) then
          begin
            add := 0;
            add := Rrole[Brole[i].rnum].MaxMP div 20;
            if Rrole[Brole[i].rnum].MaxMP < Rrole[Brole[i].rnum].CurrentMP + add then
              add := Rrole[Brole[i].rnum].MaxMP - Rrole[Brole[i].rnum].CurrentMP;
            for a := 0 to length(brole) - 1 do
              Brole[a].ShowNumber := -1;
            Brole[i].ShowNumber := add;
            if add > 0 then
              ShowHurtValue(1, colcolor(0, $50), colcolor(0, $53));
            Rrole[Brole[i].rnum].CurrentMP := Rrole[Brole[i].rnum].CurrentMP + add;
          end;
          CalPoiHurtLife(i); //计算中毒损血
          Brole[i].lifeAdd := 1;
        end;

        if (Brole[i].Team = 0) and (Brole[i].Auto = -1) and (Brole[i].wait = 0) then
        begin
          while (Brole[i].Acted = 0) and (Brole[i].Auto = -1) and (Brole[i].wait = 0) do
          begin
            for i1 := 0 to 63 do
            begin
              for i2 := 0 to 63 do
              begin
                bfield[4, i1, i2] := 0;
              end;
            end;
            case BattleMenu(i) of
              0: MoveRole(i);
              1: Attack(i);
              2: UsePoision(i);
              3: MedPoision(i);
              4: Medcine(i);
              5: MedFrozen(i);
              6: Collect(i);
              7: BattleMenuItem(i);
              8: Wait(i);
              9: Selectshowstatus(i);
              10: Rest(i);
              11: Auto(i);
            end;
          end;
        end
        else
        begin
          AutoBattle2(i);
          Brole[i].Acted := 1;
        end;
      end
      else if Brole[i].Acted = 1 then
      begin
        Brole[i].Progress := Brole[i].Progress - 300;
        showprogress;
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        sdl_delay(500);
      end
      else
      begin
        Brole[i].Acted := 1;
      end;
      ClearDeadRolePic;
      Bstatus := BattleStatus;
      if Brole[i].Acted = 1 then
      begin
        // if Brole[i].Dead = 0 then
        callevent(warsta.OperationEvent);
        Inc(Brole[i].Round);
        Brole[i].LifeAdd := 0;
      end;

      for i1 := 0 to 63 do
      begin
        for i2 := 0 to 63 do
        begin
          bfield[4, i1, i2] := 0;
        end;
      end;
      redraw;
      showprogress;
      x50[28101] := broleamount;
      CalMoveAbility;
      for k := 0 to length(Brole) - 1 do
      begin
        if (brole[k].wait = 1) and (k <> i) then
        begin
          brole[k].wait := 0;
          break;
        end;
      end;
      //showmessage(inttostr(i));

    end;
    // CallEvent(402);
    sdl_delay((maxspeed * GameSpeed) div 1000);
  end;

end; //战斗主控制

procedure OldBattleMainControl;
var
  i, n, a, add: integer;
  word: WideString;
begin
  //redraw;
  for i := 0 to length(brole) - 1 do
  begin
    Brole[i].lifeAdd := 0;
  end;
  //战斗未分出胜负则继续
  while BStatus = 0 do
  begin
    CalMoveAbility; //计算移动能力
    ReArrangeBRole; //排列角色顺序

    ClearDeadRolePic; //清除阵亡角色

    //是否已行动, 显示数字清空

    Bx := Brole[0].X;
    By := Brole[0].Y;
    for i := 0 to length(brole) - 1 do
    begin
      Brole[i].Acted := 0;
      Brole[i].ShowNumber := 0;
    end;
    callevent(warsta.BoutEvent);

    for i := 0 to length(brole) - 1 do
    begin
      Inc(Brole[i].Round);
    end;

    i := 0;
    while (i < length(brole)) and (Bstatus = 0) do
    begin

      if (brole[i].rnum < 0) or (brole[i].dead <> 0) then
      begin
        Inc(i);
        continue;
      end;
      CurBrole := i;
      //当前人物位置作为屏幕中心
      Bx := Brole[i].X;
      By := Brole[i].Y;
      redraw;
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);


      if Brole[i].lifeAdd = 0 then
      begin
        Brole[i].AddAtt := max(0, Brole[i].AddAtt - 1);
        Brole[i].AddDef := max(0, Brole[i].AddDef - 1);
        Brole[i].AddSpd := max(0, Brole[i].AddSpd - 1);
        Brole[i].AddDodge := max(0, Brole[i].AddDodge - 1);
        Brole[i].AddStep := max(0, Brole[i].AddStep - 1);
        Brole[i].PerfectDodge := max(0, Brole[i].PerfectDodge - 1);
        //状态11，自动回血
        if (GetEquipState(Brole[i].rnum, 11)) or (GetGongtiState(Brole[i].rnum, 11)) then
        begin
          add := 0;
          add := Rrole[Brole[i].rnum].MaxHP div 10;
          if Rrole[Brole[i].rnum].MaxHP < Rrole[Brole[i].rnum].CurrentHP + add then
            add := Rrole[Brole[i].rnum].MaxHP - Rrole[Brole[i].rnum].CurrentHP;
          for a := 0 to length(brole) - 1 do
            Brole[a].ShowNumber := -1;
          Brole[i].ShowNumber := add;
          if add > 0 then ShowHurtValue(3);
          Rrole[Brole[i].rnum].CurrentHP := Rrole[Brole[i].rnum].CurrentHP + add;
        end;
        //状态23，自动回内
        if (GetEquipState(Brole[i].rnum, 23)) or (GetGongtiState(Brole[i].rnum, 23)) then
        begin
          add := 0;
          add := Rrole[Brole[i].rnum].MaxMP div 20;
          if Rrole[Brole[i].rnum].MaxMP < Rrole[Brole[i].rnum].CurrentMP + add then
            add := Rrole[Brole[i].rnum].MaxMP - Rrole[Brole[i].rnum].CurrentMP;
          for a := 0 to length(brole) - 1 do
            Brole[a].ShowNumber := -1;
          Brole[i].ShowNumber := add;
          if add > 0 then
            ShowHurtValue(1, colcolor(0, $50), colcolor(0, $53));
          Rrole[Brole[i].rnum].CurrentMP := Rrole[Brole[i].rnum].CurrentMP + add;
        end;
        CalPoiHurtLife(i); //计算中毒损血
        Brole[i].lifeAdd := 1;
      end;
      while (SDL_PollEvent(@event) >= 0) do
      begin
        if event.type_ = SDL_VIDEORESIZE then
        begin
          ResizeWindow(event.resize.w, event.resize.h);
        end;
        if (event.type_ = SDL_QUITEV) then
          if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then Quit;
        if (event.key.keysym.sym = sdlk_Escape) or (event.button.button = sdl_button_right) then
        begin
          brole[i].Auto := -1;
          //AutoMode[i]:=-1;
          event.button.button := 0;
          event.key.keysym.sym := 0;
        end;
        break;
      end;
      //战场序号保存至变量28005
      x50[28005] := i;



      //为我方且未阵亡, 非自动战斗, 则显示选单
      if Brole[i].frozen >= 100 then
      begin
        Brole[i].Acted := 1;
        Dec(Brole[i].frozen, 100);
      end
      else if (Brole[i].Dead = 0) and (Brole[i].Acted = 0) then
      begin
        Brole[i].frozen := 0;
        if (Brole[i].Team = 0) and (Brole[i].Auto = -1) then
        begin
          case BattleMenu(i) of
            0: MoveRole(i);
            1: Attack(i);
            2: UsePoision(i);
            3: MedPoision(i);
            4: Medcine(i);
            5: MedFrozen(i);
            6: Collect(i);
            7: BattleMenuItem(i);
            8: Wait(i);
            9: Selectshowstatus(i);
            10: Rest(i);
            11: Auto(i);
          end;
        end
        else
        begin
          AutoBattle2(i);
          Brole[i].Acted := 1;
        end;
      end
      else if Brole[i].Acted = 1 then
      begin
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        //sdl_delay((200 * gamespeed) div 10);
      end
      else
      begin
        Brole[i].Acted := 1;
      end;
      ClearDeadRolePic;
      Bstatus := BattleStatus;
      if Brole[i].Acted = 1 then
      begin
        Brole[i].lifeAdd := 0;
        // if Brole[i].Dead = 0 then
        callevent(warsta.OperationEvent);
        i := i + 1;
      end;
      redraw;
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      sdl_delay((200 * gamespeed) div 10);
      //showmessage(inttostr(i));
    end;
    x50[28101] := broleamount;
    // CallEvent(402);

  end;

end;

procedure showprogress;
var
  i, i1, i2, temp, s1, s2, x, y: integer;
  b: array of integer;
begin
  if battlemode = 0 then exit;
  x := 250;
  y := 30;
  setlength(b, length(brole));
  for i := 0 to length(brole) - 1 do
  begin
    b[i] := i;
  end;
  for i1 := 0 to length(brole) - 2 do
  begin
    for i2 := i1 + 1 to length(brole) - 1 do
    begin
      s1 := 0;
      s2 := 0;
      if (Brole[i1].rnum > -1) and (Brole[i2].rnum > -1) then
      begin
        s1 := Brole[i1].Progress mod 300;
        s2 := Brole[i2].Progress mod 300;
      end;
      if (s1 > s2) then
      begin
        temp := b[i1];
        b[i1] := b[i2];
        b[i2] := temp;
      end;
    end;
  end;
  drawpngpic(PROGRESS_PIC, x, y, 0);
  for i := 0 to length(b) - 1 do
  begin
    if (Brole[b[i]].rnum >= 0) and (Brole[b[i]].Dead = 0) then
    begin
      if Brole[b[i]].Team = 0 then
      begin
        if Bfield[4, BRole[b[i]].X, BRole[b[i]].y] > 0 then
          drawpngpic(SELECTEDMATE_PIC, 20 + (BRole[b[i]].Progress) mod 300 + x, y, 0)
        else
          drawpngpic(MATESIGN_PIC, 20 + (BRole[b[i]].Progress) mod 300 + x, y, 0);
        ZoomPic(Head_Pic[rrole[Brole[b[i]].rnum].headnum].pic, 0, 20 + (BRole[b[i]].Progress) mod
          300 + x - 10, y - 30, 29, 30);
      end
      else
      begin
        if Bfield[4, BRole[b[i]].X, BRole[b[i]].y] > 0 then
          drawpngpic(SELECTEDENEMY_PIC, 20 + (BRole[b[i]].Progress) mod 300 + x, y, 0)
        else
          drawpngpic(ENEMYSIGN_PIC, 20 + (BRole[b[i]].Progress) mod 300 + x, y, 0);
        ZoomPic(Head_Pic[rrole[Brole[b[i]].rnum].headnum].pic, 0, 20 + (BRole[b[i]].Progress) mod
          300 + x - 10, y + 30, 29, 30);
      end;
    end;
  end;
end;

//按轻功重排人物(未考虑装备)

procedure ReArrangeBRole;
var
  i, n, n1, i1, i2, x, t, s1, s2: integer;
  temp: TBattleRole;
begin
  i1 := 0;
  i2 := 1;
  for i1 := 0 to length(brole) - 2 do
    for i2 := i1 + 1 to length(brole) - 1 do
    begin
      s1 := 0;
      s2 := 0;
      if (Brole[i1].rnum > -1) and (Brole[i1].Dead = 0) then
      begin
        s1 := GetRoleSpeed(Brole[i1].rnum, True);
        if CheckEquipSet(Rrole[Brole[i1].rnum].Equip[0], Rrole[Brole[i1].rnum].Equip[1],
          Rrole[Brole[i1].rnum].Equip[2], Rrole[Brole[i1].rnum].Equip[3]) = 5 then
          s1 := s1 + 30;
      end;
      if (Brole[i2].rnum > -1) and (Brole[i2].Dead = 0) then
      begin
        s2 := GetRoleSpeed(Brole[i2].rnum, True);
        if CheckEquipSet(Rrole[Brole[i2].rnum].Equip[0], Rrole[Brole[i2].rnum].Equip[1],
          Rrole[Brole[i2].rnum].Equip[2], Rrole[Brole[i2].rnum].Equip[3]) = 5 then
          s2 := s2 + 30;
      end;
      if (not ((GetPetSkill(5, 1) and (brole[i1].rnum = 0)) or (GetPetSkill(5, 3) and
        (brole[i1].Team = 0)))) and
        ((s1 < s2) or ((GetPetSkill(5, 1) and (brole[i2].rnum = 0)) or
        (GetPetSkill(5, 3) and (brole[i2].Team = 0)))) then
      begin
        temp := Brole[i1];
        Brole[i1] := Brole[i2];
        Brole[i2] := temp;
      end;
    end;



  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      Bfield[2, i1, i2] := -1;
      Bfield[5, i1, i2] := -1;
    end;
  n := 0;
  for i := 0 to length(brole) - 1 do
  begin
    if (Brole[i].Dead = 0) and (Brole[i].rnum >= 0) then
    begin
      Inc(n);
    end;
  end;
  n1 := 0;
  for i := 0 to length(brole) - 1 do
  begin
    if (Brole[i].rnum >= 0) then
    begin
      if (Brole[i].Dead = 0) then
      begin
        Bfield[2, Brole[i].X, Brole[i].Y] := i;
        Bfield[5, Brole[i].X, Brole[i].Y] := -1;
        if battlemode > 0 then
          Brole[i].Progress := (n - n1) * 5;
        Inc(n1);
      end
      else
      begin
        Bfield[2, Brole[i].X, Brole[i].Y] := -1;
        Bfield[5, Brole[i].X, Brole[i].Y] := i;
      end;
    end;
  end;
  i2 := 0;
  if (battlemode > 0) then
    for i1 := 0 to length(brole) - 1 do
      if ((GetPetSkill(5, 1) and (brole[i1].rnum = 0)) or (GetPetSkill(5, 3) and (brole[i1].Team = 0))) then
      begin
        Brole[i1].Progress := 299 - i2 * 5;
        i2 := i2 + 1;
      end;
end;

//计算可移动步数(考虑装备)

procedure CalMoveAbility;
var
  i, rnum, addspeed: integer;
begin
  maxspeed := 0;
  for i := 0 to length(brole) - 1 do
  begin
    rnum := Brole[i].rnum;
    if rnum > -1 then
    begin

      addspeed := 0;

      if CheckEquipSet(Rrole[rnum].Equip[0], Rrole[rnum].Equip[1], Rrole[rnum].Equip[2], Rrole[rnum].Equip[3]) = 5 then
        Inc(addspeed, 30);
      Brole[i].speed := (GetRoleSpeed(Brole[i].rnum, True) + addspeed);
      if (Brole[i].wait = 0) then Brole[i].Step := Brole[i].speed div 15 + min(1, Brole[i].AddStep) * 3;
      if Brole[i].AddSpd > 0 then
      begin
        Brole[i].speed := trunc(Brole[i].speed * 1.4);
        if GetEquipState(brole[i].rnum, 3) or GetGongtiState(brole[i].rnum, 3) then //饮酒功效加倍
          Brole[i].speed := trunc(Brole[i].speed * 1.4);
      end;
      maxspeed := max(maxspeed, Brole[i].speed);
      if rrole[rnum].Moveable > 0 then Brole[i].Step := 0;
    end;
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
  for i := 0 to length(brole) - 1 do
  begin
    if (Brole[i].Team = 0) and (brole[i].rnum >= 0) and (Brole[i].Dead = 0) then
      sum0 := sum0 + 1;
    if (Brole[i].Team = 1) and (brole[i].rnum >= 0) and (Brole[i].Dead = 0) then
      sum1 := sum1 + 1;
  end;

  if (sum0 > 0) and (sum1 > 0) then Result := 0;
  if (sum0 >= 0) and (sum1 = 0) then Result := 1;
  if (sum0 = 0) and (sum1 > 0) then Result := 2;

end;

//战斗主选单, menustatus按bit保存可用项

function BattleMenu(bnum: integer): integer;
var
  i, p, menustatus, menu, max, rnum, menup, i1, lv, i2: integer;
  realmenu: array[0..10] of integer;
  word: WideString;
  str: string;
begin

  menustatus := $F80;
  max := 4;
  //for i:=0 to 9 do
  rnum := brole[bnum].rnum;
  //移动是否可用
  if brole[bnum].Step > 0 then
  begin
    menustatus := menustatus or 1;
    max := max + 1;
  end;
  SDL_EnableKeyRepeat(10, 100);
  //can not attack when phisical<10
  //攻击是否可用
  if rrole[rnum].PhyPower >= 10 then
  begin
    p := 0;
    for i := 0 to 9 do
    begin
      if (rrole[rnum].Magic[i] > 0) and (rmagic[rrole[rnum].Magic[i]].NeedMP <= rrole[rnum].CurrentMP) then
      begin
        lv := Rrole[Brole[bnum].rnum].MagLevel[i] div 100;
        if ((Brole[bnum].Progress + 1) div 3 >= (rmagic[rrole[rnum].Magic[i]].NeedProgress * 10) *
          lv + 100) or (BattleMode = 0) or (rrole[rnum].Angry = 100) then
        begin
          p := 1;
          break;
        end;
      end;
    end;
    if p > 0 then
    begin
      menustatus := menustatus or 2;
      max := max + 1;
    end;
  end;
  //用毒是否可用
  if (GetRoleUsePoi(rnum, True) > 0) and (rrole[rnum].PhyPower >= 30) then
  begin
    menustatus := menustatus or 4;
    max := max + 1;
  end;
  //解毒是否可用
  if (GetRoleMedPoi(rnum, True) > 0) and (rrole[rnum].PhyPower >= 50) then
  begin
    menustatus := menustatus or 8;
    max := max + 1;
  end;
  //医疗是否可用
  if (GetRoleMedcine(rnum, True) > 0) and (rrole[rnum].PhyPower >= 50) then
  begin
    menustatus := menustatus or 16;
    max := max + 1;
  end;
  //解穴是否可用
  if (Rrole[rnum].CurrentMP + (GetRoleMedcine(rnum, True) * 5) > 200) and (rrole[rnum].PhyPower >= 50) then
  begin
    menustatus := menustatus or 32;
    max := max + 1;
  end;
  if (BattleMode > 0) then
  begin
    menustatus := menustatus or 64;
    max := max + 1;
  end;

  ReDraw;
  DrawRectangle(10, 50, 80, 28, 0, colcolor(0, 255), 30);
  str := '第' + IntToStr(brole[bnum].Round) + '回';
  //word := GBKtoUnicode(@str[1]);
  word := UTF8Decode(' ' + str);
  DrawShadowText(@word[1], 10 - 17, 50 + 2, colcolor(0, 5), colcolor(0, 7));
  ShowSimpleStatus(brole[bnum].rnum, 30, 330);
  showprogress;
  menu := 0;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  showbmenu(menustatus, menu, max);
  //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  //SDL_UpdateRect2(screen,0,0,screen.w,screen.h);
  while (SDL_PollEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          break;
        end;
      end;
      SDL_KEYDOWN:
      begin
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          menu := menu - 1;
          if menu < 0 then menu := max;
          //ShowSimpleStatus(brole[bnum].rnum, 30, 330);
          //showprogress;
          showbmenu(menustatus, menu, max);
        end;
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then
        begin
          menu := menu + 1;
          if menu > max then menu := 0;
          //ShowSimpleStatus(brole[bnum].rnum, 30, 330);
          //showprogress;
          showbmenu(menustatus, menu, max);
        end;
        if (event.key.keysym.sym = sdlk_f5) then
        begin
          SwitchFullscreen;
          Kys_ini.WriteInteger('set', 'fullscreen', fullscreen);
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_left) then
          break;
      end;
      SDL_MOUSEMOTION:
      begin
        if (round(event.button.x / (RealScreen.w / screen.w)) >= 100) and
          (round(event.button.x / (RealScreen.w / screen.w)) < 147) and
          (round(event.button.y / (RealScreen.h / screen.h)) >= 50 - 22) and
          (round(event.button.y / (RealScreen.h / screen.h)) < max * 22 + 78 - 22) then
        begin
          menup := menu;
          menu := (round(event.button.y / (RealScreen.h / screen.h)) - 52 + 22) div 22;
          if menu > max then menu := max;
          if menu < 0 then menu := 0;
          if menup <> menu then
          begin
            //ShowSimpleStatus(brole[bnum].rnum, 30, 330);
            //showprogress;
            showbmenu(menustatus, menu, max);
          end;
        end;
      end;
    end;

    if (rrole[brole[bnum].rnum].Poision > 0) or (rrole[brole[bnum].rnum].Hurt > 0) then
    begin
      ShowSimpleStatus(brole[bnum].rnum, 30, 330);
      SDL_UpdateRect2(screen, 52, 394 - 77, 58, 60);
    end;
    event.key.keysym.sym := 0;
    event.button.button := 0;
    sdl_delay((20 * GameSpeed) div 10);
  end;
  event.key.keysym.sym := 0;
  event.button.button := 0;
  //result:=0;
  p := 0;
  for i := 0 to 11 do
  begin
    if (menustatus and (1 shl i)) > 0 then
    begin
      p := p + 1;
      if p > menu then break;
    end;
  end;
  Result := i;
  SDL_EnableKeyRepeat(100, 30);
end;

//显示战斗主选单

procedure ShowBMenu(MenuStatus, menu, max: integer);
var
  i, p: integer;
  word: array[0..11] of WideString;
begin
  word[0] := UTF8Decode(' 移動');
  word[1] := UTF8Decode(' 武學');
  word[2] := UTF8Decode(' 用毒');
  word[3] := UTF8Decode(' 解毒');
  word[4] := UTF8Decode(' 醫療');
  word[5] := UTF8Decode(' 解穴');
  word[6] := UTF8Decode(' 聚氣');
  word[7] := UTF8Decode(' 物品');
  word[8] := UTF8Decode(' 等待');
  word[9] := UTF8Decode(' 狀態');
  word[10] := UTF8Decode(' 休息');
  word[11] := UTF8Decode(' 自動');

  redraw;

  DrawRectangle(100, 50 - 22, 47, max * 22 + 28, 0, colcolor(255), 30);
  p := 0;
  for i := 0 to 11 do
  begin
    if (p = menu) and ((menustatus and (1 shl i) > 0)) then
    begin
      drawshadowtext(@word[i][1], 83, 53 - 22 + 22 * p, colcolor($64), colcolor($66));
      p := p + 1;
    end
    else if (p <> menu) and ((menustatus and (1 shl i) > 0)) then
    begin
      drawshadowtext(@word[i][1], 83, 53 - 22 + 22 * p, colcolor($21), colcolor($23));
      p := p + 1;
    end;
  end;
  SDL_UpdateRect2(screen, 100, 50 - 22, 48, max * 22 + 29);
end;

procedure ShowBMenu2(MenuStatus, menu, max, bnum: integer);
var
  i, p: integer;
  word: array[0..11] of WideString;
begin
  word[0] := UTF8Decode(' 移動');
  word[1] := UTF8Decode(' 武學');
  word[2] := UTF8Decode(' 用毒');
  word[3] := UTF8Decode(' 解毒');
  word[4] := UTF8Decode(' 醫療');
  word[5] := UTF8Decode(' 解穴');
  word[6] := UTF8Decode(' 聚氣');
  word[7] := UTF8Decode(' 物品');
  word[8] := UTF8Decode(' 等待');
  word[9] := UTF8Decode(' 狀態');
  word[10] := UTF8Decode(' 休息');
  word[11] := UTF8Decode(' 自動');

  redraw;

  ShowSimpleStatus(brole[bnum].rnum, 30, 330);
  showprogress;
  DrawRectangle(100, 50 - 22, 47, max * 22 + 28, 0, colcolor(255), 30);
  p := 0;
  for i := 0 to 11 do
  begin
    if (p = menu) and ((menustatus and (1 shl i) > 0)) then
    begin
      drawshadowtext(@word[i][1], 83, 53 - 22 + 22 * p, colcolor($64), colcolor($66));
      p := p + 1;
    end
    else if (p <> menu) and ((menustatus and (1 shl i) > 0)) then
    begin
      drawshadowtext(@word[i][1], 83, 53 - 22 + 22 * p, colcolor($21), colcolor($23));
      p := p + 1;
    end;
  end;
  SDL_UpdateRect2(screen, 100, 50 - 22, 48, max * 22 + 29);
end;

//移动

procedure MoveRole(bnum: integer);
var
  s, i: integer;
begin
  CalCanSelect(bnum, 0, brole[bnum].Step);
  if SelectAim(bnum, brole[bnum].Step) then
    MoveAmination(bnum);

end;

//移动动画

procedure MoveAmination(bnum: integer);
var
  s, i, a, tempx, tempy: integer;
  Xinc, Yinc: array[1..4] of integer;
begin
  if Bfield[3, Ax, Ay] > 0 then
  begin
    Xinc[1] := 1;
    Xinc[2] := -1;
    Xinc[3] := 0;
    Xinc[4] := 0;
    Yinc[1] := 0;
    Yinc[2] := 0;
    Yinc[3] := 1;
    Yinc[4] := -1;
    linex[0] := Bx;
    liney[0] := By;
    linex[Bfield[3, Ax, Ay]] := Ax;
    liney[Bfield[3, Ax, Ay]] := Ay;
    a := Bfield[3, Ax, Ay] - 1;
    while a >= 0 do
    begin
      for i := 1 to 4 do
      begin
        tempx := linex[a + 1] + Xinc[i];
        tempy := liney[a + 1] + Yinc[i];
        if Bfield[3, tempx, tempy] = Bfield[3, linex[a + 1], liney[a + 1]] - 1 then
        begin
          linex[a] := tempx;
          liney[a] := tempy;
          break;
        end;
      end;
      Dec(a);
    end;
    a := 1;
    while not ((Brole[bnum].Step = 0) or ((Bx = Ax) and (By = Ay))) do
    begin
      if sign(linex[a] - Bx) > 0 then
        Brole[bnum].Face := 3
      else if sign(linex[a] - Bx) < 0 then
        Brole[bnum].Face := 0
      else if sign(liney[a] - By) < 0 then
        Brole[bnum].Face := 2
      else Brole[bnum].Face := 1;
      if Bfield[2, Bx, By] = bnum then Bfield[2, Bx, By] := -1;
      Bx := linex[a];
      By := liney[a];
      if Bfield[2, Bx, By] = -1 then Bfield[2, Bx, By] := bnum;
      Inc(a);
      Dec(Brole[bnum].Step);
      Redraw;
      showprogress;
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      sdl_delay((gamespeed * 20) div 10);

    end;

    Brole[bnum].X := Bx;
    Brole[bnum].Y := By;

  end;

end;

//选择查看状态的目标

function Selectshowstatus(bnum: integer): boolean;
var
  Axp, Ayp, rnum, step, range, i, i1, i2, AttAreaType: integer;
begin
  Ax := Bx;
  Ay := By;
  step := 64;
  range := 0;
  AttAreaType := 0;
  CalCanSelect(bnum, 2, 64);
  DrawBFieldWithCursor(AttAreaType, step, range);
  rnum := Brole[Bfield[2, Ax, Ay]].rnum;
  ShowSimpleStatus(rnum, 330, 330);
  showprogress;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  while (SDL_PollEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          if Bfield[2, Ax, Ay] >= 0 then
          begin
            if Brole[Bfield[2, Ax, Ay]].Dead = 0 then
            begin
              if GetPetSkill(5, 0) or (Brole[Bfield[2, Ax, Ay]].Team = 0) then
              begin
                rnum := Brole[Bfield[2, Ax, Ay]].rnum;
                newshowstatus(rnum);
                NewShowMagic(rnum);
                waitanykey();
                redraw;
                ShowSimpleStatus(rnum, 330, 330);
              end;
            end;
            SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          end;
        end;
        if (event.key.keysym.sym = sdlk_escape) then
        begin
          Result := False;
          break;
        end;
      end;
      SDL_KEYDown:
      begin
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) then
        begin
          Ay := Ay - 1;
          if (abs(Ax - Bx) + abs(Ay - By) > step) then Ay := Ay + 1;
        end;
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_KP6) then
        begin
          Ay := Ay + 1;
          if (abs(Ax - Bx) + abs(Ay - By) > step) then Ay := Ay - 1;
        end;
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then
        begin
          Ax := Ax + 1;
          if (abs(Ax - Bx) + abs(Ay - By) > step) then Ax := Ax - 1;
        end;
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          Ax := Ax - 1;
          if (abs(Ax - Bx) + abs(Ay - By) > step) then Ax := Ax + 1;
        end;
        DrawBFieldWithCursor(AttAreaType, step, range);
        if (Bfield[2, Ax, Ay] >= 0) then
        begin
          if Brole[Bfield[2, Ax, Ay]].Dead = 0 then
          begin
            rnum := Brole[Bfield[2, Ax, Ay]].rnum;
            ShowSimpleStatus(rnum, 330, 330);
          end;
        end;
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_left) then
        begin
          if Bfield[2, Ax, Ay] >= 0 then
          begin
            if Brole[Bfield[2, Ax, Ay]].Dead = 0 then
            begin
              if GetPetSkill(5, 0) or (Brole[Bfield[2, Ax, Ay]].Team = 0) then
              begin
                rnum := Brole[Bfield[2, Ax, Ay]].rnum;
                newshowstatus(rnum);
                NewShowMagic(rnum);
                waitanykey();
                redraw;
                ShowSimpleStatus(rnum, 330, 330);
              end;
            end;
            SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          end;
        end;
        if (event.button.button = sdl_button_right) then
        begin
          Result := False;
          break;
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        Axp := (-round(event.button.x / (RealScreen.w / screen.w)) + CENTER_x + 2 *
          round(event.button.y / (RealScreen.h / screen.h)) - 2 * CENTER_y + 18) div 36 + Bx;
        Ayp := (round(event.button.x / (RealScreen.w / screen.w)) - CENTER_x + 2 *
          round(event.button.y / (RealScreen.h / screen.h)) - 2 * CENTER_y + 18) div 36 + By;
        if (abs(Axp - Bx) + abs(Ayp - By) <= step) then
        begin
          Ax := Axp;
          Ay := Ayp;
          DrawBFieldWithCursor(AttAreaType, step, range);

          if (Bfield[2, Ax, Ay] >= 0) then
          begin
            if Brole[Bfield[2, Ax, Ay]].Dead = 0 then
            begin
              rnum := Brole[Bfield[2, Ax, Ay]].rnum;
              ShowSimpleStatus(rnum, 330, 330);
            end;
          end;
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
      end;
    end;
    if (Bfield[2, Ax, Ay] >= 0) then
    begin
      if Brole[Bfield[2, Ax, Ay]].Dead = 0 then
      begin
        rnum := Brole[Bfield[2, Ax, Ay]].rnum;
        ShowSimpleStatus(rnum, 330, 330);
        SDL_UpdateRect2(screen, 352, 394 - 77, 58, 60);
      end;
    end;
    event.key.keysym.sym := 0;
    event.button.button := 0;
    sdl_delay((20 * GameSpeed) div 10);
  end;
  event.key.keysym.sym := 0;
  event.button.button := 0;
end;

//选择点

function SelectAim(bnum, step: integer): boolean;
var
  Axp, Ayp: integer;
begin
  Ax := Bx;
  Ay := By;
  DrawBFieldWithCursor(0, step, 0);
  showsimpleStatus(Brole[Bfield[2, AX, AY]].rnum, 330, 330);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  SDL_EnableKeyRepeat(10, 100);
  while (SDL_PollEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          Result := True;
          x50[28927] := 1;
          break;
        end;
        if (event.key.keysym.sym = sdlk_escape) then
        begin
          Result := False;
          x50[28927] := 0;
          break;
        end;
      end;
      SDL_KEYDOWN:
      begin
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) then
        begin
          Ay := Ay - 1;
          if (abs(Ax - Bx) + abs(Ay - By) > step) or (Bfield[3, Ax, Ay] < 0) then Ay := Ay + 1;
        end;
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_kp6) then
        begin
          Ay := Ay + 1;
          if (abs(Ax - Bx) + abs(Ay - By) > step) or (Bfield[3, Ax, Ay] < 0) then Ay := Ay - 1;
        end;
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then
        begin
          Ax := Ax + 1;
          if (abs(Ax - Bx) + abs(Ay - By) > step) or (Bfield[3, Ax, Ay] < 0) then Ax := Ax - 1;
        end;
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          Ax := Ax - 1;
          if (abs(Ax - Bx) + abs(Ay - By) > step) or (Bfield[3, Ax, Ay] < 0) then Ax := Ax + 1;
        end;
        DrawBFieldWithCursor(0, step, 0);
        if (Bfield[2, AX, AY] >= 0) and (Brole[Bfield[2, AX, AY]].Dead = 0) then
          showsimpleStatus(Brole[Bfield[2, AX, AY]].rnum, 330, 330);
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_left) then
        begin
          Result := True;
          break;
        end;
        if (event.button.button = sdl_button_right) then
        begin
          Result := False;
          break;
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        Axp := (-round(event.button.x / (RealScreen.w / screen.w)) + CENTER_x + 2 *
          round(event.button.y / (RealScreen.h / screen.h)) - 2 * CENTER_y + 18) div 36 + Bx;
        Ayp := (round(event.button.x / (RealScreen.w / screen.w)) - CENTER_x + 2 *
          round(event.button.y / (RealScreen.h / screen.h)) - 2 * CENTER_y + 18) div 36 + By;
        if (abs(Axp - Bx) + abs(Ayp - By) <= step) and (Bfield[3, Ax, Ay] >= 0) then
        begin
          Ax := Axp;
          Ay := Ayp;
          DrawBFieldWithCursor(0, step, 0);
          if (Bfield[2, AX, AY] >= 0) and (Brole[Bfield[2, Ax, Ay]].Dead = 0) then
            showsimpleStatus(Brole[Bfield[2, AX, AY]].rnum, 330, 330);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
      end;
    end;
    if (Bfield[2, AX, AY] >= 0) and (Brole[Bfield[2, AX, AY]].Dead = 0) then
    begin
      if (rrole[brole[Bfield[2, AX, AY]].rnum].Poision > 0) or (rrole[brole[Bfield[2, AX, AY]].rnum].Hurt > 0) then
      begin
        showsimpleStatus(Brole[Bfield[2, AX, AY]].rnum, 330, 330);
        SDL_UpdateRect2(screen, 352, 394 - 77, 58, 60);
      end;
    end;
    event.key.keysym.sym := 0;
    event.button.button := 0;
    sdl_delay((20 * GameSpeed) div 10);
  end;
  event.key.keysym.sym := 0;
  event.button.button := 0;
end;

//选择原地

function SelectCross(bnum, AttAreaType, step, range: integer): boolean;
var
  Axp, Ayp: integer;
begin
  Ax := Bx;
  Ay := By;
  DrawBFieldWithCursor(AttAreaType, step, range);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  while (SDL_PollEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          Result := True;
          break;
        end;
        if (event.key.keysym.sym = sdlk_escape) then
        begin
          Result := False;
          break;
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_left) then
        begin
          Result := True;
          break;
        end;
        if (event.button.button = sdl_button_right) then
        begin
          Result := False;
          break;
        end;
      end;
    end;
    event.key.keysym.sym := 0;
    event.button.button := 0;
    sdl_delay((20 * GameSpeed) div 10);
  end;
  event.key.keysym.sym := 0;
  event.button.button := 0;

end;

//目标系点叉菱方型、原地系菱方型

function SelectRange(bnum, AttAreaType, step, range: integer): boolean;
var
  Axp, Ayp: integer;
begin
  Ax := Bx;
  Ay := By;
  DrawBFieldWithCursor(AttAreaType, step, range);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

  while (SDL_PollEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          Result := True;
          x50[28927] := 1;
          break;
        end;
        if (event.key.keysym.sym = sdlk_escape) then
        begin
          Result := False;
          x50[28927] := 0;
          break;
        end;
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) then
        begin
          Ay := Ay - 1;
          if (abs(Ax - Bx) + abs(Ay - By) > step) then Ay := Ay + 1;
        end;
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_kp6) then
        begin
          Ay := Ay + 1;
          if (abs(Ax - Bx) + abs(Ay - By) > step) then Ay := Ay - 1;
        end;
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then
        begin
          Ax := Ax + 1;
          if (abs(Ax - Bx) + abs(Ay - By) > step) then Ax := Ax - 1;
        end;
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          Ax := Ax - 1;
          if (abs(Ax - Bx) + abs(Ay - By) > step) then Ax := Ax + 1;
        end;
        DrawBFieldWithCursor(AttAreaType, step, range);
        if (Bfield[2, AX, AY] >= 0) and (Bfield[2, AX, AY] <> bnum) then
          showsimpleStatus(Brole[Bfield[2, AX, AY]].rnum, 330, 330);
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_left) then
        begin
          Result := True;
          break;
        end;
        if (event.button.button = sdl_button_right) then
        begin
          Result := False;
          break;
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        Axp := (-round(event.button.x / (RealScreen.w / screen.w)) + CENTER_x + 2 *
          round(event.button.y / (RealScreen.h / screen.h)) - 2 * CENTER_y + 18) div 36 + Bx;
        Ayp := (round(event.button.x / (RealScreen.w / screen.w)) - CENTER_x + 2 *
          round(event.button.y / (RealScreen.h / screen.h)) - 2 * CENTER_y + 18) div 36 + By;
        if (abs(Axp - Bx) + abs(Ayp - By) <= step) then
        begin
          Ax := Axp;
          Ay := Ayp;
          DrawBFieldWithCursor(AttAreaType, step, range);
          if (Bfield[2, AX, AY] >= 0) and (Bfield[2, AX, AY] <> bnum) then
            showsimpleStatus(Brole[Bfield[2, AX, AY]].rnum, 330, 330);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
      end;

    end;

    if (Bfield[2, AX, AY] >= 0) and (Bfield[2, AX, AY] <> bnum) then
    begin
      if (rrole[brole[Bfield[2, AX, AY]].rnum].Poision > 0) or (rrole[brole[Bfield[2, AX, AY]].rnum].Hurt > 0) then
      begin
        showsimpleStatus(Brole[Bfield[2, AX, AY]].rnum, 330, 330);
        SDL_UpdateRect2(screen, 352, 394 - 77, 58, 60);
      end;
    end;
    event.key.keysym.sym := 0;
    event.button.button := 0;
    sdl_delay((20 * GameSpeed) div 10);
  end;
  event.key.keysym.sym := 0;
  event.button.button := 0;

end;

//选择远程

function SelectFar(bnum, mnum, level: integer): boolean;
var
  Axp, Ayp: integer;
  AttAreaType, step, range, minstep: integer;
begin

  step := Rmagic[mnum].MoveDistance[level - 1];

  if CheckEquipSet(Rrole[Brole[bnum].rnum].equip[0], Rrole[Brole[bnum].rnum].equip[1],
    Rrole[Brole[bnum].rnum].equip[2], Rrole[Brole[bnum].rnum].equip[3]) = 1 then
    Inc(step, 1);
  if GetEquipState(Brole[bnum].rnum, 22) or GetGongtiState(Brole[bnum].rnum, 22) then //增加攻击距离
    Inc(step, 1);
  range := Rmagic[mnum].AttDistance[level - 1];
  AttAreaType := Rmagic[mnum].AttAreaType;

  minstep := Rmagic[mnum].MinStep;

  Ax := Bx - minstep - 1;
  Ay := By;
  DrawBFieldWithCursor(AttAreaType, step, range);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  while (SDL_PollEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          Result := True;
          x50[28927] := 1;
          break;
        end;
        if (event.key.keysym.sym = sdlk_escape) then
        begin
          Result := False;
          x50[28927] := 0;
          break;
        end;
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) then
        begin
          Ay := Ay - 1;
          if (abs(Ax - Bx) + abs(Ay - By) > step) then Ay := Ay + 1;
          if (abs(Ax - Bx) + abs(Ay - By) <= minstep) then
            if Ax >= Bx then Ax := Ax + 1
            else Ax := Ax - 1;
          DrawBFieldWithCursor(AttAreaType, step, range);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_kp6) then
        begin
          Ay := Ay + 1;
          if (abs(Ax - Bx) + abs(Ay - By) > step) then Ay := Ay - 1;
          if (abs(Ax - Bx) + abs(Ay - By) <= minstep) then
            if Ax > Bx then Ax := Ax + 1
            else Ax := Ax - 1;
          DrawBFieldWithCursor(AttAreaType, step, range);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then
        begin
          Ax := Ax + 1;
          if (abs(Ax - Bx) + abs(Ay - By) > step) then Ax := Ax - 1;
          if (abs(Ax - Bx) + abs(Ay - By) <= minstep) then
            if Ay >= By then Ay := Ay + 1
            else Ay := Ay - 1;
          DrawBFieldWithCursor(AttAreaType, step, range);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          Ax := Ax - 1;
          if (abs(Ax - Bx) + abs(Ay - By) > step) then Ax := Ax + 1;
          if (abs(Ax - Bx) + abs(Ay - By) <= minstep) then
            if Ay > By then Ay := Ay + 1
            else Ay := Ay - 1;
          DrawBFieldWithCursor(AttAreaType, step, range);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_left) then
        begin
          Result := True;
          break;
        end;
        if (event.button.button = sdl_button_right) then
        begin
          Result := False;
          break;
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        Axp := (-round(event.button.x / (RealScreen.w / screen.w)) + CENTER_x + 2 *
          round(event.button.y / (RealScreen.h / screen.h)) - 2 * CENTER_y + 18) div 36 + Bx;
        Ayp := (round(event.button.x / (RealScreen.w / screen.w)) - CENTER_x + 2 *
          round(event.button.y / (RealScreen.h / screen.h)) - 2 * CENTER_y + 18) div 36 + By;
        if (abs(Axp - Bx) + abs(Ayp - By) <= step) and (abs(Axp - Bx) + abs(Ayp - By) > minstep) then
        begin
          Ax := Axp;
          Ay := Ayp;
          DrawBFieldWithCursor(AttAreaType, step, range);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
      end;
    end;
    event.key.keysym.sym := 0;
    event.button.button := 0;
    sdl_delay((20 * GameSpeed) div 10);
  end;
  event.key.keysym.sym := 0;
  event.button.button := 0;

end;

//选择方向

function SelectDirector(bnum, AttAreaType, step, range: integer): boolean;
var
  str: WideString;
begin
  Ax := Bx - 1;
  Ay := By;
  //str := UTF8Decode(' 選擇攻擊方向');
  //Drawtextwithrect(@str[1], 280, 200, 125, colcolor($23), colcolor($21));
  DrawBFieldWithCursor(AttAreaType, step, range);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  Result := False;
  while (SDL_PollEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = sdlk_escape) then
        begin
          break;
        end;
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          if (Ax <> Bx) or (Ay <> By) then Result := True;
          break;
        end;
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) then
        begin
          Ay := By - 1;
          Ax := Bx;
          DrawBFieldWithCursor(AttAreaType, step, range);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_kp6) then
        begin
          Ay := By + 1;
          Ax := Bx;
          DrawBFieldWithCursor(AttAreaType, step, range);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then
        begin
          Ax := Bx + 1;
          Ay := By;
          DrawBFieldWithCursor(AttAreaType, step, range);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          Ax := Bx - 1;
          Ay := By;
          DrawBFieldWithCursor(AttAreaType, step, range);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
      end;
      Sdl_mousebuttonup:
      begin
        if event.button.button = sdl_button_right then
        begin
          Result := False;
          break;
        end;
        //按照所点击位置设置方向
        if event.button.button = sdl_button_left then
        begin
          if (round(event.button.x / (RealScreen.w / screen.w)) < CENTER_x) and
            (round(event.button.y / (RealScreen.h / screen.h)) < CENTER_y) then
          begin
            Ay := By - 1;
            Ax := Bx;
            Result := True;
            break;
          end;
          if (round(event.button.x / (RealScreen.w / screen.w)) < CENTER_x) and
            (round(event.button.y / (RealScreen.h / screen.h)) >= CENTER_y) then
          begin
            Ax := Bx + 1;
            Ay := By;
            Result := True;
            break;
          end;
          if (round(event.button.x / (RealScreen.w / screen.w)) >= CENTER_x) and
            (round(event.button.y / (RealScreen.h / screen.h)) < CENTER_y) then
          begin
            Ax := Bx - 1;
            Ay := By;
            Result := True;
            break;
          end;
          if (round(event.button.x / (RealScreen.w / screen.w)) >= CENTER_x) and
            (round(event.button.y / (RealScreen.h / screen.h)) >= CENTER_y) then
          begin
            Ay := By + 1;
            Ax := Bx;
            Result := True;
            break;
          end;
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        if (round(event.button.x / (RealScreen.w / screen.w)) < CENTER_x) and
          (round(event.button.y / (RealScreen.h / screen.h)) < CENTER_y) then
        begin
          Ay := By - 1;
          Ax := Bx;
        end;
        if (round(event.button.x / (RealScreen.w / screen.w)) < CENTER_x) and
          (round(event.button.y / (RealScreen.h / screen.h)) >= CENTER_y) then
        begin
          Ax := Bx + 1;
          Ay := By;
        end;
        if (round(event.button.x / (RealScreen.w / screen.w)) >= CENTER_x) and
          (round(event.button.y / (RealScreen.h / screen.h)) < CENTER_y) then
        begin
          Ax := Bx - 1;
          Ay := By;
        end;
        if (round(event.button.x / (RealScreen.w / screen.w)) >= CENTER_x) and
          (round(event.button.y / (RealScreen.h / screen.h)) >= CENTER_y) then
        begin
          Ay := By + 1;
          Ax := Bx;
        end;
        DrawBFieldWithCursor(AttAreaType, step, range);
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

      end;
    end;
    event.key.keysym.sym := 0;
    event.button.button := 0;
    sdl_delay((20 * GameSpeed) div 10);
  end;
  event.key.keysym.sym := 0;
  event.button.button := 0;
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

//计算可以被选中的位置
//利用队列
//移动过程中，旁边有敌人，则不能继续移动

procedure SeekPath2(x, y, step, myteam, mode: integer);

var
  Xlist: array[0..4096] of integer;
  Ylist: array[0..4096] of integer;
  steplist: array[0..4096] of integer;
  curgrid, totalgrid: integer;
  Bgrid: array[1..4] of integer; //0空位，1建筑，2友军，3敌军，4出界，5已走过 ，6水面
  Xinc, Yinc: array[1..4] of integer;
  curX, curY, curstep, nextX, nextY: integer;
  i: integer;

begin
  Xinc[1] := 1;
  Xinc[2] := -1;
  Xinc[3] := 0;
  Xinc[4] := 0;
  Yinc[1] := 0;
  Yinc[2] := 0;
  Yinc[3] := 1;
  Yinc[4] := -1;
  curgrid := 0;
  totalgrid := 0;
  Xlist[totalgrid] := x;
  Ylist[totalgrid] := y;
  steplist[totalgrid] := 0;
  totalgrid := totalgrid + 1;
  while curgrid < totalgrid do
  begin
    curX := Xlist[curgrid];
    curY := Ylist[curgrid];
    curstep := steplist[curgrid];
    if curstep < step then
    begin
      //判断当前点四周格子的状况
      for i := 1 to 4 do
      begin
        nextX := curX + Xinc[i];
        nextY := curY + Yinc[i];
        if (nextX < 0) or (nextX > 63) or (nextY < 0) or (nextY > 63) then
          Bgrid[i] := 4
        else if Bfield[3, nextX, nextY] >= 0 then
          Bgrid[i] := 5
        else if Bfield[1, nextX, nextY] > 0 then
          Bgrid[i] := 1
        else if (Bfield[2, nextX, nextY] >= 0) and (BRole[Bfield[2, nextX, nextY]].Dead = 0) then
        begin
          if BRole[Bfield[2, nextX, nextY]].Team = myteam then
            Bgrid[i] := 2
          else
            Bgrid[i] := 3;
        end
        else if ((Bfield[0, nextX, nextY] div 2 >= 179) and (Bfield[0, nextX, nextY] div 2 <= 190)) or
          (Bfield[0, nextX, nextY] div 2 = 261) or (Bfield[0, nextX, nextY] div 2 = 511) or
          ((Bfield[0, nextX, nextY] div 2 >= 224) and (Bfield[0, nextX, nextY] div 2 <= 232)) or
          ((Bfield[0, nextX, nextY] div 2 >= 662) and (Bfield[0, nextX, nextY] div 2 <= 674)) then
          Bgrid[i] := 6
        else
          Bgrid[i] := 0;
      end;

      //移动的情况
      //若为初始位置，不考虑旁边是敌军的情况
      //在移动过程中，旁边没有敌军的情况下才继续移动
      if mode = 0 then
      begin
        if (curstep = 0) or ((Bgrid[1] <> 3) and (Bgrid[2] <> 3) and (Bgrid[3] <> 3) and (Bgrid[4] <> 3)) then
        begin
          for i := 1 to 4 do
          begin
            if Bgrid[i] = 0 then
            begin
              Xlist[totalgrid] := curX + Xinc[i];
              Ylist[totalgrid] := curY + Yinc[i];
              steplist[totalgrid] := curstep + 1;
              Bfield[3, Xlist[totalgrid], Ylist[totalgrid]] := steplist[totalgrid];
              totalgrid := totalgrid + 1;
            end;
          end;
        end;
      end
      else
        //非移动的情况，攻击、医疗等
      begin
        for i := 1 to 4 do
        begin
          if (Bgrid[i] = 0) or (Bgrid[i] = 2) or ((Bgrid[i] = 3)) then
          begin
            Xlist[totalgrid] := curX + Xinc[i];
            Ylist[totalgrid] := curY + Yinc[i];
            steplist[totalgrid] := curstep + 1;
            Bfield[3, Xlist[totalgrid], Ylist[totalgrid]] := steplist[totalgrid];
            totalgrid := totalgrid + 1;
          end;
        end;
      end;
    end;
    curgrid := curgrid + 1;
  end;

end;

//初始化范围
//mode=0移动，1攻击用毒医疗等，2查看状态

procedure CalCanSelect(bnum, mode, step: integer);
var
  i, i1, i2: integer;
begin

  if mode = 0 then
  begin
    for i1 := 0 to 63 do
      for i2 := 0 to 63 do
        Bfield[3, i1, i2] := -1;

    Bfield[3, Brole[bnum].X, Brole[bnum].Y] := 0;
    SeekPath2(Brole[bnum].X, Brole[bnum].Y, Step, Brole[bnum].Team, mode);
  end;

  if mode = 1 then
    for i1 := 0 to 63 do
      for i2 := 0 to 63 do
      begin
        Bfield[3, i1, i2] := -1;
        if abs(i1 - Brole[bnum].X) + abs(i2 - Brole[bnum].Y) <= step then
          Bfield[3, i1, i2] := 0;
      end;

  if mode = 2 then
    for i1 := 0 to 63 do
      for i2 := 0 to 63 do
      begin
        Bfield[3, i1, i2] := -1;
        if Bfield[2, i1, i2] >= 0 then
          Bfield[3, i1, i2] := 0;
      end;

end;

//无定向直线

function SelectLine(bnum, AttAreaType, step, range: integer): boolean;
var
  Axp, Ayp: integer;
begin
  Ax := Bx;
  Ay := By;
  DrawBFieldWithCursor(AttAreaType, step, range);

  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  while (SDL_PollEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          Result := True;
          x50[28927] := 1;
          break;
        end;
        if (event.key.keysym.sym = sdlk_escape) then
        begin
          Result := False;
          x50[28927] := 0;
          break;
        end;
      end;
      SDL_KEYDown:
      begin
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) then
        begin
          Ay := Ay - 1;
          if (abs(Ax - Bx) + abs(Ay - By) > step) then Ay := Ay + 1;
        end;
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_kp6) then
        begin
          Ay := Ay + 1;
          if (abs(Ax - Bx) + abs(Ay - By) > step) then Ay := Ay - 1;
        end;
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then
        begin
          Ax := Ax + 1;
          if (abs(Ax - Bx) + abs(Ay - By) > step) then Ax := Ax - 1;
        end;
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          Ax := Ax - 1;
          if (abs(Ax - Bx) + abs(Ay - By) > step) then Ax := Ax + 1;
        end;
        DrawBFieldWithCursor(AttAreaType, step, range);
        if (Bfield[2, AX, AY] >= 0) and (Bfield[2, AX, AY] <> bnum) then
          showsimpleStatus(Brole[Bfield[2, AX, AY]].rnum, 330, 330);
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_left) then
        begin
          Result := True;
          break;
        end;
        if (event.button.button = sdl_button_right) then
        begin
          Result := False;
          break;
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        Axp := (-round(event.button.x / (RealScreen.w / screen.w)) + CENTER_x + 2 *
          round(event.button.y / (RealScreen.h / screen.h)) - 2 * CENTER_y + 18) div 36 + Bx;
        Ayp := (round(event.button.x / (RealScreen.w / screen.w)) - CENTER_x + 2 *
          round(event.button.y / (RealScreen.h / screen.h)) - 2 * CENTER_y + 18) div 36 + By;
        if (abs(Axp - Bx) + abs(Ayp - By) <= step) then
        begin
          Ax := Axp;
          Ay := Ayp;
          DrawBFieldWithCursor(AttAreaType, step, range);
          if (Bfield[2, AX, AY] >= 0) and (Bfield[2, AX, AY] <> bnum) then
            showsimpleStatus(Brole[Bfield[2, AX, AY]].rnum, 330, 330);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
      end;
    end;
    if (Bfield[2, AX, AY] >= 0) and (Bfield[2, AX, AY] <> bnum) then
    begin
      if (rrole[brole[Bfield[2, AX, AY]].rnum].Poision > 0) or (rrole[brole[Bfield[2, AX, AY]].rnum].Hurt > 0) then
      begin
        showsimpleStatus(Brole[Bfield[2, AX, AY]].rnum, 330, 330);
        SDL_UpdateRect2(screen, 352, 394 - 77, 58, 60);
      end;
    end;
    event.key.keysym.sym := 0;
    event.button.button := 0;
    sdl_delay((20 * GameSpeed) div 10);
  end;
  event.key.keysym.sym := 0;
  event.button.button := 0;

end;
{
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
 }

//攻击

procedure Attack(bnum: integer);
var
  rnum, i, mnum, l1, level, step, range, AttAreaType, i1, i2, twice, temp: integer;
  str: string;
  str1: WideString;
begin
  rnum := brole[bnum].rnum;
  i := SelectMagic(bnum);
  if i < 0 then exit;
  mnum := Rrole[rnum].Magic[i];
  if (Rmagic[mnum].MagicType = 5) then
  begin
    setlength(Menustring, 0);
    setlength(menustring, 3);
    menustring[0] := UTF8Decode('  是');
    menustring[1] := UTF8Decode('  否');
    menustring[2] := UTF8Decode(' 是否設置功體為') + gbktoUnicode(@Rmagic[mnum].Name[0]) + UTF8Decode('？');
    drawtextwithrect(@menustring[2][1], CENTER_X - length(menustring[2]) * 10 + 120,
      CENTER_Y - 85, length(menustring[2]) * 20 - 10, colcolor(0, 5), colcolor(0, 7));
    if commonmenu2(CENTER_X + 45, CENTER_Y - 50, 98) = 0 then
    begin
      SetGongti(rnum, mnum);
      //  ShowMagicName(mnum);
      for i1 := 0 to 63 do
        for i2 := 0 to 63 do
          Bfield[4, i1, i2] := 0;
      Bfield[4, brole[bnum].x, brole[bnum].y] := 1;
      playsound(rmagic[mnum].SoundNum, 0);
      ax := brole[bnum].x;
      ay := brole[bnum].y;
      PlayActionAmination(bnum, Rmagic[mnum].MagicType); //动画效果
      PlayMagicAmination(bnum, Rmagic[mnum].bigami, Rmagic[mnum].AmiNum, 10); //武功效果
      Bfield[4, brole[bnum].x, brole[bnum].y] := -1;
      if battlemode > 0 then
      begin
        brole[bnum].speed := GetRoleSpeed(rnum, True);
        if CheckEquipSet(Rrole[rnum].Equip[0], Rrole[rnum].Equip[1], Rrole[rnum].Equip[2],
          Rrole[rnum].Equip[3]) = 5 then
          Inc(brole[bnum].speed, 30);
      end;
    end;
    exit;
  end;
  level := Rrole[rnum].MagLevel[i] div 100 + 1;
  CurMagic := mnum;
  x50[28928] := mnum;
  x50[28929] := i;
  x50[28100] := i;

  if i >= 0 then
    //依据攻击范围进一步选择
    step := Rmagic[mnum].MoveDistance[level - 1];
  if CheckEquipSet(Rrole[rnum].equip[0], Rrole[rnum].equip[1], Rrole[rnum].equip[2], Rrole[rnum].equip[3]) = 1 then
    Inc(step, 1);
  if GetEquipState(rnum, 22) or GetGongtiState(rnum, 22) then //增加攻击距离
    Inc(step, 1);
  range := Rmagic[mnum].AttDistance[level - 1];

  AttAreaType := Rmagic[mnum].AttAreaType;
  CalCanSelect(bnum, 1, step);
  case Rmagic[mnum].AttAreaType of
    0, 3:
    begin
      if SelectRange(bnum, AttAreaType, step, range) then
      begin
        SetAminationPosition(AttAreaType, step, range);
        Brole[bnum].Acted := 1;
      end;
    end;
    1, 4, 5:
    begin
      if SelectDirector(bnum, AttAreaType, step, range) then
      begin
        SetAminationPosition(AttAreaType, step, range);
        Brole[bnum].Acted := 1;
      end;
    end;
    2:
    begin
      if SelectCross(bnum, AttAreaType, step, range) then
      begin
        SetAminationPosition(AttAreaType, step, range);
        Brole[bnum].Acted := 1;
      end;
    end;
    6:
    begin
      if SelectFar(bnum, mnum, level) then
      begin
        SetAminationPosition(AttAreaType, step, range);
        Brole[bnum].Acted := 1;
      end;
    end;
    7:
    begin
      if SelectLine(bnum, AttAreaType, step, range) then
      begin
        SetAminationPosition(AttAreaType, step, range);
        Brole[bnum].Acted := 1;
      end;
    end;
    8:
    begin
      //    SetAminationPosition(AttAreaType, step, range);

      calcanselect(bnum, 1, step);
      //if (Brole[bnum].Team = 0) and (brole[bnum].Auto = -1) then
      selectaim(bnum, step);
      Brole[bnum].Acted := 1;
    end;
  end;
  //如果行动成功, 武功等级增加, 播放效果
  Rrole[rnum].AttTwice := 0;
  if (GetEquipState(rnum, 14) or (GetGongtiState(rnum, 14))) and (random(100) > 30) then Rrole[rnum].AttTwice := 1;
  if Brole[bnum].Acted = 1 then
  begin
    for i1 := 0 to Rrole[rnum].Atttwice do
    begin

      if rmagic[mnum].NeedMP > rrole[rnum].CurrentMP then break;
      if rmagic[mnum].EventNum > 0 then
      begin
        //rmagic[mnum].UnKnow[4] := strtoint(InputBox('Enter name', 'ssss', '10'));
        //  execscript(pchar('script/SpecialMagic' + inttostr(rmagic[mnum].UnKnow[4]) + '.lua'), pchar('f' + inttostr(rmagic[mnum].UnKnow[4])));
        Callevent(rmagic[mnum].EventNum);
        if rmagic[mnum].NeedMP * level > rrole[rnum].CurrentMP then
        begin
          level := rrole[rnum].CurrentMP div rmagic[mnum].NeedMP;
        end;
        rrole[rnum].CurrentMP := rrole[rnum].CurrentMP - rmagic[mnum].NeedMP * level;
        rrole[rnum].CurrentHP := rrole[rnum].CurrentHP - ((rmagic[mnum].NeedMP * level) * rrole[rnum].Hurt) div 100;

        if RRole[rnum].CurrentHP < 0 then RRole[rnum].CurrentHP := 0;
        if rrole[rnum].CurrentMP < 0 then rrole[rnum].CurrentMP := 0;
      end
      else AttackAction(bnum, mnum, level);

      l1 := Rrole[rnum].MagLevel[i] div 100;
      Rrole[rnum].MagLevel[i] := Rrole[rnum].MagLevel[i] + 2;
      if Rrole[rnum].MagLevel[i] > 999 then Rrole[rnum].MagLevel[i] := 999;
      if l1 < Rrole[rnum].MagLevel[i] div 100 then
      begin
        Rrole[rnum].Fist := min(Rrole[rnum].Fist + Rmagic[Rrole[rnum].Magic[i]].AddFist, 200);
        Rrole[rnum].Sword := min(Rrole[rnum].Sword + Rmagic[Rrole[rnum].Magic[i]].AddSword, 200);
        Rrole[rnum].Knife := min(Rrole[rnum].Knife + Rmagic[Rrole[rnum].Magic[i]].AddKnife, 200);
        Rrole[rnum].Unusual := min(Rrole[rnum].Unusual + Rmagic[Rrole[rnum].Magic[i]].AddUnusual, 200);
        if Rrole[rnum].MagLevel[i] div 100 >= 9 then
          if Rrole[rnum].PracticeBook >= 0 then
            if Ritem[Rrole[rnum].PracticeBook].Magic = Rrole[rnum].Magic[i] then
            begin
              instruct_32(Rrole[rnum].PracticeBook, 1);
              Rrole[rnum].PracticeBook := -1;
              Rrole[rnum].ExpForBook := 0;
            end;
        redraw;
        DrawRectangle(220, 70 - 30, 200, 25, 0, colcolor(255), 25);
        str := (' 升為' + IntToStr(Rrole[rnum].MagLevel[i] div 100 + 1) + '級');
        //str1 := GBKtoUnicode(@str[1]);
        str1 := UTF8Decode(str);
        Drawshadowtext(@str1[1], 303, 72 - 30, colcolor($21), colcolor($23));
        Drawgbkshadowtext(@Rmagic[Rrole[rnum].Magic[i]].Name, 203, 72 - 30, colcolor($64), colcolor($66));
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        waitanykey;
        redraw;
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      end;
      ClearDeadRolePic;
    end;
  end;
  //showmessage(inttostr(rrole[0].atttwice));

end;

//攻击效果

procedure AttackAction(bnum, mnum, level: integer);
var
  needprogress, step, range, AttAreaType, twice, t1, ax1, ay1: integer;
begin
  //if (Brole[bnum].Team = 0) and (Brole[bnum].Auto = -1) then ShowMagicName(mnum);


  if (Brole[bnum].Team <> 0) then
  begin
    //依据攻击范围进一步选择
    step := Rmagic[mnum].MoveDistance[level - 1];
    if CheckEquipSet(Rrole[Brole[bnum].rnum].equip[0], Rrole[Brole[bnum].rnum].equip[1],
      Rrole[Brole[bnum].rnum].equip[2], Rrole[Brole[bnum].rnum].equip[3]) = 1 then
      Inc(step, 1);
    if GetEquipState(Brole[bnum].rnum, 22) or GetGongtiState(Brole[bnum].rnum, 22) then //增加攻击距离
      Inc(step, 1);
    range := Rmagic[mnum].AttDistance[level - 1];
    AttAreaType := Rmagic[mnum].AttAreaType;
    CalCanSelect(bnum, 1, step);
    DrawBFieldWithCursor(AttAreaType, step, range);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    t1 := sdl_getticks;
    while sdl_getticks < t1 + 1000 do
    begin
    end;
  end;


  playsound(rmagic[mnum].SoundNum, 0);
  PlayActionAmination(bnum, Rmagic[mnum].MagicType); //动画效果
  PlayMagicAmination(bnum, Rmagic[mnum].bigami, Rmagic[mnum].AmiNum, level); //武功效果
  CalHurtRole(bnum, mnum, level); //计算被打到的人物
  twice := 1;
  if Rrole[Brole[bnum].rnum].AttTwice = 1 then twice := 2;
  if ((BRole[bnum].Progress + 1) div 3 < ((rmagic[mnum].NeedProgress * 10 * level) + 100) div twice) and
    (rrole[Brole[bnum].rnum].angry = 100) and (battlemode > 1) then
  begin
    needprogress := ((rmagic[mnum].NeedProgress * 10 * level) + 100) * 3 - 1;
    rrole[Brole[bnum].rnum].angry := 100 - (((needprogress - BRole[bnum].Progress) * 100) div needprogress) div twice;
    BRole[bnum].Progress := 0;
  end
  else
    BRole[bnum].Progress := BRole[bnum].Progress - (((rmagic[mnum].NeedProgress * 10 * level) + 100) * 3 -
      1) div twice;
  BRole[bnum].Progress := max(BRole[bnum].Progress, 0);
end;

procedure ShowMagicName(mnum: integer);
var
  l: integer;
  str: WideString;
begin
  Redraw;
  str := gbktounicode(@Rmagic[mnum].Name);
  str := MidStr(str, 1, 6);
  l := length(str);
  drawtextwithrect(@str[1], CENTER_X - l * 10, CENTER_Y - 150, l * 20 - 14, colcolor($14), colcolor($16));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  //Sdl_Delay((500 * GameSpeed) div 10);
  waitanykey;

end;

//选择武功

function SelectMagic(bnum: integer): integer;
var
  i, p, lv, menustatus, mnum, max, menu, menup: integer;
begin
  menustatus := 0;
  max := 0;
  setlength(menustring, 0);
  setlength(menuengstring, 0);
  SDL_EnableKeyRepeat(10, 100);
  for i := 0 to 9 do
  begin
    mnum := Rrole[Brole[bnum].rnum].Magic[i];
    if (mnum > 0) then
    begin
      if (rmagic[mnum].MagicType <> 5) then
      begin
        if (rmagic[mnum].NeedMP <= Rrole[Brole[bnum].rnum].CurrentMP) then
        begin
          lv := Rrole[Brole[bnum].rnum].MagLevel[i] div 100;
          if ((Brole[bnum].Progress + 1) div 3 >= (rmagic[mnum].NeedProgress * 10) * lv + 100) or
            (BattleMode = 0) or (rrole[Brole[bnum].rnum].Angry = 100) then
          begin
            setlength(menustring, i + 1);
            setlength(menuengstring, i + 1);
            menustatus := menustatus or (1 shl i);
            menustring[i] := UTF8Decode(' ');
            menuengstring[i] := UTF8Decode(' ');
            menustring[i] := gbktoUnicode(@Rmagic[Rrole[Brole[bnum].rnum].Magic[i]].Name[0]);
            menuengstring[i] := format('%3d', [Rrole[Brole[bnum].rnum].MagLevel[i] div 100 + 1]);
            max := max + 1;
          end;
        end;
      end
      else
      begin
        setlength(menustring, i + 1);
        setlength(menuengstring, i + 1);
        menustatus := menustatus or (1 shl i);
        menustring[i] := UTF8Decode(' ');
        menuengstring[i] := UTF8Decode(' ');
        menustring[i] := gbktoUnicode(@Rmagic[Rrole[Brole[bnum].rnum].Magic[i]].Name[0]);
        menuengstring[i] := format('%3d', [Rrole[Brole[bnum].rnum].MagLevel[i] div 100 + 1]);
        max := max + 1;
      end;
    end;
  end;
  max := max - 1;

  ReDraw;
  // SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  menu := 0;
  showmagicmenu(bnum, menustatus, menu, max);
  //SDL_UpdateRect2(screen,0,0,screen.w,screen.h);
  while (SDL_PollEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          break;
        end;
        if (event.key.keysym.sym = sdlk_escape) then
        begin
          menu := -1;
          break;
        end;
      end;
      SDL_KEYDOWN:
      begin
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          menu := menu - 1;
          if menu < 0 then menu := max;
          showmagicmenu(bnum, menustatus, menu, max);
        end;
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then
        begin
          menu := menu + 1;
          if menu > max then menu := 0;
          showmagicmenu(bnum, menustatus, menu, max);
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
          menu := -1;
          break;
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        if (round(event.button.x / (RealScreen.w / screen.w)) >= 100) and
          (round(event.button.x / (RealScreen.w / screen.w)) < 267) and
          (round(event.button.y / (RealScreen.h / screen.h)) >= 50) and
          (round(event.button.y / (RealScreen.h / screen.h)) < max * 22 + 78) then
        begin
          menup := menu;
          menu := (round(event.button.y / (RealScreen.h / screen.h)) - 52) div 22;
          if menu > max then menu := max;
          if menu < 0 then menu := 0;
          if menup <> menu then showmagicmenu(bnum, menustatus, menu, max);
        end;
      end;
    end;
    event.key.keysym.sym := 0;
    event.button.button := 0;
    sdl_delay((20 * GameSpeed) div 10);
  end;
  event.key.keysym.sym := 0;
  event.button.button := 0;

  Result := menu;
  if Result >= 0 then
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
    Result := i;
  end;

  SDL_EnableKeyRepeat(100, 30);

end;

//显示武功选单

procedure ShowMagicMenu(bnum, menustatus, menu, max: integer);
var
  i, p: integer;
begin
  redraw;
  DrawRectangle(100, 50, 167, max * 22 + 28, 0, colcolor(255), 30);
  p := 0;
  for i := 0 to 9 do
  begin
    if (p <> menu) and ((menustatus and (1 shl i) > 0)) then
    begin
      if (rmagic[rrole[brole[bnum].rnum].Magic[i]].MagicType = 5) then
        drawshadowtext(@menustring[i][1], 83, 53 + 22 * p, colcolor($5), colcolor($7))
      else
      begin
        drawshadowtext(@menustring[i][1], 83, 53 + 22 * p, colcolor($21), colcolor($23));
        drawengshadowtext(@menuengstring[i][1], 223, 53 + 22 * p, colcolor($21), colcolor($23));
      end;
      p := p + 1;
    end
    else if (p = menu) and ((menustatus and (1 shl i) > 0)) then
    begin
      drawshadowtext(@menustring[i][1], 83, 53 + 22 * p, colcolor($64), colcolor($66));
      if (rmagic[rrole[brole[bnum].rnum].Magic[i]].MagicType <> 5) then
        drawengshadowtext(@menuengstring[i][1], 223, 53 + 22 * p, colcolor($64), colcolor($66));
      p := p + 1;
    end;
  end;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

end;

//设定攻击范围

procedure SetAminationPosition(mode, step, range: integer);
var
  i, i1, i2: integer;
begin
  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      Bfield[4, i1, i2] := 0;
      //按攻击类型判断是否在范围内
      case mode of
        0, 6: //目标系点型、目标系十型、目标系菱型、原地系菱型、远程
        begin
          if (abs(i1 - Ax) + abs(i2 - Ay)) <= range then
          begin
            Bfield[4, i1, i2] := 1;
          end;
        end;
        3: //目标系方型、原地系方型
        begin
          if (abs(i1 - Ax) <= range) and (abs(i2 - Ay) <= range) then Bfield[4, i1, i2] := 1;
        end;
        1: //方向系线型
        begin
          if ((i1 = Bx) or (i2 = By)) and (sign(Ax - Bx) = sign(i1 - Bx)) and (abs(i1 - Bx) <= step) and
            (sign(Ay - By) = sign(i2 - By)) and (abs(i2 - By) <= step) then
            Bfield[4, i1, i2] := 1;
        end;
        2: //原地系十型、原地系叉型、原地系米型
        begin
          if (abs(i1 - Bx) = abs(i2 - By)) and (abs(i1 - Bx) <= range) or
            ((i1 = Bx) and (abs(i2 - By) <= step)) or ((i2 = By) and (abs(i1 - Bx) <= step)) then Bfield[4, i1, i2] := 1;
          if ((i1 = Bx) and (i2 = By)) then Bfield[4, i1, i2] := 1;
          ax := bx;
          ay := by;
        end;
        4: //方向系菱型
        begin
          if ((abs(i1 - Bx) + abs(i2 - By) <= step) and (abs(i1 - Bx) <> abs(i2 - By))) and
            ((((i1 - Bx) * (Ax - Bx) > 0) and (abs(i1 - Bx) > abs(i2 - By))) or
            (((i2 - By) * (Ay - By) > 0) and (abs(i1 - Bx) < abs(i2 - By)))) then Bfield[4, i1, i2] := 1;
        end;
        5: //方向系角型
        begin
          if ((abs(i1 - Bx) <= step) and (abs(i2 - By) <= step) and (abs(i1 - Bx) <> abs(i2 - By))) and
            ((((i1 - Bx) * (Ax - Bx) > 0) and (abs(i1 - Bx) > abs(i2 - By))) or
            (((i2 - By) * (Ay - By) > 0) and (abs(i1 - Bx) < abs(i2 - By)))) then Bfield[4, i1, i2] := 1;
        end;

        7: //无定向直线
        begin
          if not ((i1 = bx) and (i2 = by)) and (abs(i1 - Bx) + abs(i2 - By) <= step) then
          begin
            if ((abs(i1 - Bx) <= abs(ax - Bx)) and (abs(i2 - By) <= abs(ay - By))) then
            begin
              if (abs(ax - bx) > abs(ay - by)) and (((i1 - bx) / (ax - bx)) > 0) and
                (i2 = Round(((i1 - bx) * (ay - by)) / (ax - bx)) + by) then
              begin
                Bfield[4, i1, i2] := 1;
              end
              else if (abs(ax - bx) <= abs(ay - by)) and (((i2 - by) / (ay - by)) > 0) and
                (i1 = Round(((i2 - by) * (ax - bx)) / (ay - by)) + bx) then
              begin
                Bfield[4, i1, i2] := 1;
              end;
            end;
          end;
        end;
      end;
    end;

end;

//显示武功效果

procedure PlayMagicAmination(bnum, bigami, enum, level: integer);
var
  i, grp, Count, len: integer;
  filename, fn: string;
  dest, dest1: TSDL_Rect;
begin
  //含音效

  filename := format('%3d', [enum]);

  for i := 1 to length(filename) do
    if filename[i] = ' ' then filename[i] := '0';
  //fn := 'eft/eft' + filename + '.pic';

  if (FileExistsUTF8(AppPath + 'eft/eft' + filename + '.pic') { *Converted from FileExists*  }) then
  begin

    grp := fileopen(AppPath + 'eft/eft' + filename + '.pic', fmopenread);

    dest.x := 0;
    dest.y := 0;
    fileseek(grp, 0, 0);
    fileread(grp, Count, 4);

    for i := 0 to Count - 1 do
    begin
      DrawBFieldWithEft(grp, i, bigami, level);
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    end;
    fileclose(grp);
  end;

end;

//判断是否有非行动方角色在攻击范围之内

procedure CalHurtRole(bnum, mnum, level: integer);
var
  i, frozen, rnum, dodge, bang, hurt, addpoi, needmp, n, hurtmp, hurt1, addmpvalue, addhpvalue, injury, angry: integer;
begin
  dodge := 0;
  //战斗状态
  //1 体力不减
  //2 女性武功加成
  //3 饮酒功效加倍
  //4 转移伤害
  //5 反弹伤害
  //6 内伤免疫
  //7 杀伤体力
  //8 闪躲+30%
  //9 攻击力随机增减50%或正常
  //10 内功消耗-20%
  //11 回合回复生命
  //12 负面状态免疫
  //13 全部武功加成
  //14 左右互博
  //15 拳掌加成
  //16 御剑加成
  //17 耍刀加成
  //18 特殊加成
  //19 增加内伤几率
  //20 增加封穴几率
  //21 吸血
  //22 攻击距离+1
  //23 回合回复内力
  //24 暗器距离+1
  //25 吸杀内力
  addhpvalue := 0;
  addmpvalue := 0;
  rnum := brole[bnum].rnum;
  for i := 0 to length(brole) - 1 do
    Brole[i].ShowNumber := -1;

  if RRole[rnum].CurrentMP < rmagic[mnum].NeedMP * level then level := RRole[rnum].CurrentMP div rmagic[mnum].NeedMP;
  if level > 10 then level := 10;
  needmp := rmagic[mnum].NeedMP * level;

  for i := 0 to length(brole) - 1 do
  begin
    if (brole[i].Dead = 0) and (brole[i].rnum >= 0) then
    begin
      if (Bfield[4, Brole[i].X, Brole[i].Y] <> 0) and (Brole[bnum].Team <> Brole[i].Team) and
        (Brole[i].Dead = 0) and (bnum <> i) then
      begin
        bang := 0;
        dodge := min(1, brole[i].AddDodge) * 30; //增加闪躲率状态
        if brole[i].PerfectDodge > 0 then dodge := 100;
        hurt := CalHurtValue(bnum, i, mnum, level);

        if (brole[bnum].Team = 0) and (battlemode > 0) then
        begin
          Inc(hurt, (hurt * Rmagic[mnum].NeedProgress * level) div 20);
        end;
        hurt := (hurt * (400 + Rrole[brole[i].rnum].Hurt)) div 400;
        hurt := (hurt * (400 - Rrole[rnum].Hurt)) div 400;

        //增加伤害状态
        if brole[bnum].AddAtt > 0 then
        begin
          hurt := trunc(hurt * 1.4);
          if GetEquipState(rnum, 3) or GetGongtiState(rnum, 3) then //饮酒功效加倍
            hurt := trunc(hurt * 1.4);
        end;
        //增加防御状态
        if brole[i].AddDef > 0 then
        begin
          hurt := trunc(hurt * 0.6);
          if GetEquipState(brole[i].rnum, 3) or GetGongtiState(brole[i].rnum, 3) then //饮酒功效加倍
            hurt := trunc(hurt * 0.6);
        end;

        //生命伤害
        if (rmagic[mnum].HurtType = 0) then
        begin
          //某些状态增加伤害   15-18 加成某类型，13 加成所有，2 女性加成所有
          if (GetGongtiState(rnum, 14 + rmagic[mnum].MagicType)) or (GetGongtiState(rnum, 13)) or
            ((GetEquipState(rnum, 2) or (GetGongtiState(rnum, 2))) and (rrole[rnum].sexual = 1)) or
            GetEquipState(rnum, 14 + rmagic[mnum].MagicType) or GetEquipState(rnum, 13) then
          begin
            hurt := trunc(hurt * 1.3);
          end;
          //某些状态增加闪躲率   8 增加50%闪躲率
          if GetEquipState(brole[i].rnum, 8) or (GetGongtiState(brole[i].rnum, 8)) then Inc(dodge, 30);
          //某些状态伤害改变   9 随机增减50%或不变
          if GetEquipState(rnum, 9) or (GetGongtiState(rnum, 9)) then
            hurt := trunc((hurt * (7 + ((Rrole[rnum].level - 1) mod 10))) / 10);
          n := i;
          //转换伤害对象  4 乾坤大挪移 5斗转星移
          if GetEquipState(brole[i].rnum, 4) or (GetGongtiState(brole[i].rnum, 4)) then n := ReMoveHurt(i, bnum);
          if GetEquipState(brole[i].rnum, 5) or (GetGongtiState(brole[i].rnum, 5)) then n := RetortHurt(i, bnum);

          //计算愤怒值
          if battlemode > 1 then
          begin
            bang := bang + Rrole[rnum].Angry div 5; //根据愤怒值计算暴击率
            dodge := dodge + Rrole[Brole[n].rnum].Angry div 10; //根据愤怒值计算闪躲率
            bang := min(bang, 100);
            dodge := min(dodge, 100);
            angry := (hurt * 50) div Rrole[Brole[n].rnum].MaxHP;
            if angry <= 0 then
              angry := 1;
            Rrole[Brole[n].rnum].Angry := Rrole[Brole[n].rnum].Angry + angry;
            Rrole[Brole[n].rnum].Angry := min(Rrole[Brole[n].rnum].Angry, 100);
          end;
          if random(100) < bang - 1 then hurt := trunc(hurt * 1.3);
          if random(100) < dodge then hurt := 0;
          Brole[n].ShowNumber := hurt;
          hurt := min(Rrole[Brole[n].rnum].CurrentHP, hurt);
          Rrole[Brole[n].rnum].CurrentHP := max(0, Rrole[Brole[n].rnum].CurrentHP - hurt);
          if Rrole[Brole[n].rnum].CurrentHP <= 0 then
          begin
            Inc(Brole[bnum].killed);
            Brole[bnum].ExpGot := Brole[bnum].ExpGot + Rrole[Brole[n].rnum].Level * 10;
          end;
        end
        else if (rmagic[mnum].HurtType = 1) then
        begin
          //某些状态增加伤害   15-18 加成某类型，13 加成所有，2 女性加成所有
          if (GetGongtiState(rnum, 15 + rmagic[mnum].MagicType)) or (GetGongtiState(rnum, 13)) or
            ((GetEquipState(rnum, 2) or (GetGongtiState(rnum, 2))) and (rrole[rnum].sexual = 1)) or
            GetEquipState(rnum, 15 + rmagic[mnum].MagicType) or GetEquipState(rnum, 13) then
          begin
            hurt := trunc(hurt * 1.3);
          end;
          //某些状态增加闪躲率   8 增加50%闪躲率
          if GetEquipState(brole[i].rnum, 8) or (GetGongtiState(brole[i].rnum, 8)) then Inc(dodge, 30);
          //某些状态伤害改变   9 随机增减50%或不变
          if GetEquipState(rnum, 9) or (GetGongtiState(rnum, 9)) then
            hurt := trunc(hurt * (1 + ((random(3) - 1) * 0.5)));
          n := i;
          //转换伤害对象  4 乾坤大挪移 5斗转星移
          if GetEquipState(brole[i].rnum, 4) or (GetGongtiState(brole[i].rnum, 4)) then n := ReMoveHurt(i, bnum);
          if GetEquipState(brole[i].rnum, 5) or (GetGongtiState(brole[i].rnum, 5)) then n := RetortHurt(i, bnum);

          //计算愤怒值
          if battlemode > 1 then
          begin
            bang := bang + Rrole[rnum].Angry div 5; //根据愤怒值计算暴击率
            dodge := dodge + Rrole[Brole[n].rnum].Angry div 10; //根据愤怒值计算闪躲率
            bang := min(bang, 100);
            dodge := min(dodge, 100);
            angry := (hurt * 50) div Rrole[Brole[n].rnum].MaxHP;
            if angry <= 0 then
              angry := 1;
            Rrole[Brole[n].rnum].Angry := Rrole[Brole[n].rnum].Angry + angry;
            Rrole[Brole[n].rnum].Angry := min(Rrole[Brole[n].rnum].Angry, 100);
          end;
          if random(100) < bang - 1 then hurt := trunc(hurt * 1.3);
          if random(100) < dodge then hurt := 0;
          Brole[n].ShowNumber := hurt;
          hurt := min(Rrole[Brole[n].rnum].CurrentMP, hurt);
          Rrole[Brole[n].rnum].CurrentMP := max(0, Rrole[Brole[n].rnum].CurrentMP - hurt);

        end;


        //增加己方内力
        addmpvalue := addmpvalue + (rmagic[mnum].AddMpScale * hurt) div 100;
        //如功体有吸内力效果
        if (rrole[rnum].Gongti > 0) and (rmagic[rrole[rnum].Gongti].NeedExp[
          rmagic[rrole[rnum].Gongti].MaxLevel] <= GetMagicLevel(rnum, rrole[rnum].Gongti)) and
          (rmagic[rrole[rnum].Gongti].AddMpScale > 0) then
        begin
          hurtmp := (hurt * rmagic[rrole[rnum].Gongti].AddMpScale) div 100;
          if (hurtmp > Rrole[Brole[i].rnum].CurrentMP) then hurt := hurtmp - Rrole[Brole[i].rnum].CurrentMP;
          //增加己方内力
          Rrole[Brole[i].rnum].CurrentMP := max(0, Rrole[Brole[i].rnum].CurrentMP - hurtmp);
          addmpvalue := addmpvalue + hurtmp;
        end;


        //增加己方生命
        addhpvalue := addhpvalue + (rmagic[mnum].AddHpScale * hurt) div 100;
        //如装备有吸血效果
        if GetEquipState(rnum, 21) or GetGongtiState(rnum, 21) then
          addhpvalue := addhpvalue + hurt div 10;
        //如功体有吸血效果
        if (rrole[rnum].Gongti > 0) and (rmagic[rrole[rnum].Gongti].MaxLevel =
          GetGongtiLevel(rnum, rrole[rnum].Gongti)) and (rmagic[rrole[rnum].Gongti].AddHpScale > 0) then
          addhpvalue := addhpvalue + (rmagic[mnum].AddHpScale * hurt) div 100;

        if hurt > 0 then
        begin
          //中毒，某些状态免疫   12 免除所有负面状态 ,套装4 免除所有负面状态
          if (not GetGongtiState(Brole[n].rnum, 12)) and (not GetEquipState(Brole[n].rnum, 12)) and
            (CheckEquipSet(Rrole[Brole[n].rnum].equip[0], Rrole[Brole[n].rnum].equip[1], Rrole[Brole[n].rnum].equip[2],
            Rrole[Brole[n].rnum].equip[3]) <> 4) then
          begin
            addpoi := GetroleAttPoi(rnum, True) + rmagic[mnum].Poision * level - GetRoleDefPoi(Brole[n].rnum, True);
            if addpoi + rrole[Brole[n].rnum].Poision > 99 then addpoi := 99 - rrole[Brole[n].rnum].Poision;
            if addpoi < 0 then addpoi := 0;
            if GetRoleDefPoi(Brole[n].rnum, True) >= 99 then addpoi := 0;
            rrole[Brole[n].rnum].Poision := rrole[Brole[n].rnum].Poision + addpoi;
          end;

          //内伤 ，某些状态免疫   12 免除所有负面状态，6 免除内伤  ,套装4 免除所有负面状态
          if (not GetGongtiState(Brole[n].rnum, 12)) and (not GetEquipState(Brole[n].rnum, 12)) and
            (CheckEquipSet(Rrole[Brole[n].rnum].equip[0], Rrole[Brole[n].rnum].equip[1], Rrole[Brole[n].rnum].equip[2],
            Rrole[Brole[n].rnum].equip[3]) <> 4) and (not GetGongtiState(Brole[n].rnum, 6)) and
            (not GetEquipState(Brole[n].rnum, 6)) then
          begin
            injury := ((rmagic[mnum].MaxInjury - rmagic[mnum].MinInjury) * (level - 1)) div 9 + rmagic[mnum].MinInjury;
            //内伤 ，某些状态增加内伤率   19增加内伤率  套装3必然内伤
            if GetEquipState(rnum, 19) or (GetGongtiState(rnum, 19)) then injury := injury + 30;
            if CheckEquipSet(Rrole[rnum].equip[0], Rrole[rnum].equip[1], Rrole[rnum].equip[2],
              Rrole[rnum].equip[3]) = 3 then
              injury := 100;
            if random(100) < injury then Inc(rrole[Brole[n].rnum].Hurt, round(hurt / 10));
            if rrole[Brole[n].rnum].Hurt > 100 then rrole[Brole[n].rnum].Hurt := 100;
          end;


          //封穴 ，某些状态免疫   12 免除所有负面状态 ,套装4 免除所有负面状态
          if (not GetGongtiState(Brole[n].rnum, 12)) and (not GetEquipState(Brole[n].rnum, 12)) and
            (CheckEquipSet(Rrole[Brole[n].rnum].equip[0], Rrole[Brole[n].rnum].equip[1], Rrole[Brole[n].rnum].equip[2],
            Rrole[Brole[n].rnum].equip[3]) <> 4) then
          begin
            frozen := ((rmagic[mnum].MaxPeg - rmagic[mnum].MinPeg) * (level - 1)) div 9 + rmagic[mnum].MinPeg;
            //封穴 ，某些状态增加封穴率   20增加封穴率
            if GetEquipState(rnum, 20) or (GetGongtiState(rnum, 20)) then frozen := frozen + 10;
            if random(100) < frozen then
            begin
              frozen := round(((rrole[rnum].CurrentMP - (rrole[brole[n].rnum].CurrentMP div 2)) /
                (rrole[brole[n].rnum].CurrentMP + 1)) * 200);
              Inc(Brole[n].frozen, frozen);
            end;
            Brole[n].frozen := min(500, Brole[n].frozen);
          end;

          //某些状态杀伤体力  7 杀伤体力
          if (GetGongtiState(rnum, 7)) or GetEquipState(rnum, 7) then
          begin
            Rrole[Brole[n].rnum].PhyPower := Rrole[Brole[n].rnum].PhyPower - 5;
            if Rrole[Brole[n].rnum].PhyPower <= 0 then Rrole[Brole[n].rnum].PhyPower := 0;
          end;

          //某些状态吸杀内力  25 吸杀内力
          if (GetGongtiState(rnum, 25)) or GetEquipState(rnum, 25) then
          begin
            hurtmp := hurt div 10;
            if (hurtmp > Rrole[Brole[n].rnum].CurrentMP) then hurtmp := hurtmp - Rrole[Brole[n].rnum].CurrentMP;
            //增加己方内力
            Rrole[Brole[n].rnum].CurrentMP := max(0, Rrole[Brole[n].rnum].CurrentMP - hurtmp);
            addmpvalue := addmpvalue + hurtmp;
          end;
        end;
      end;
    end;
  end;
  ShowHurtValue(rmagic[mnum].HurtType); //显示数字


  //某些状态耗费内力减少  10 耗费内力-20%
  if GetEquipState(rnum, 10) or (GetGongtiState(rnum, 10)) then needmp := (needmp * 4) div 5;
  if Rrole[rnum].AttTwice = 1 then needmp := needmp div 2;
  RRole[rnum].CurrentMP := RRole[rnum].CurrentMP - needmp;
  RRole[rnum].CurrentHP := RRole[rnum].CurrentHP - (needmp * RRole[rnum].Hurt) div 100;

  //某些状态不耗费体力  1 不耗费体力
  if (not GetGongtiState(rnum, 1)) and (not GetEquipState(rnum, 1)) then
    rrole[rnum].PhyPower := rrole[rnum].PhyPower - 3;

  //消耗自身生命
  RRole[rnum].CurrentHP := RRole[rnum].CurrentHP - rmagic[mnum].NeedHP * ((level + 1) div 2);
  if RRole[rnum].CurrentHP < 0 then RRole[rnum].CurrentHP := 0;
  if RRole[rnum].CurrentHP > RRole[rnum].MaxHP then RRole[rnum].CurrentHP := RRole[rnum].MaxHP;

  //攻击者增加1愤怒值
  if (battlemode > 1) then
  begin
    Rrole[rnum].Angry := Rrole[rnum].Angry + 1;
    if Rrole[rnum].Angry > 100 then Rrole[rnum].Angry := 100;
  end;
  //增加己方内力
  if (addmpvalue > 0) then
  begin
    Brole[bnum].ShowNumber := addmpvalue;
    RRole[rnum].CurrentMP := RRole[rnum].CurrentMP + addmpvalue;
    RRole[rnum].CurrentMP := min(RRole[rnum].MaxMP, RRole[rnum].CurrentMP);
    ShowHurtValue(1, colcolor(0, $50), colcolor(0, $53));
  end;
  //增加己方生命
  if (addhpvalue > 0) then
  begin
    Brole[bnum].ShowNumber := addhpvalue;
    RRole[rnum].CurrentHP := RRole[rnum].CurrentHP + addhpvalue;
    RRole[rnum].CurrentHP := min(RRole[rnum].MaxHP, RRole[rnum].CurrentHP);
    ShowHurtValue(3);
  end;

end;

//乾坤大挪移的效果

function ReMoveHurt(bnum, AttackBnum: integer): smallint;
var
  i1, i2, x, y, i, n, realhurt: integer;
  str: WideString;
  temp: array of integer;
begin
  str := UTF8Decode(' 轉移');
  Result := bnum;
  setlength(temp, 0);
  n := 0;
  if (Random(100) < 30 + Rrole[Brole[bnum].rnum].Aptitude div 5) then
  begin
    for i := 0 to length(brole) - 1 do
      if (brole[i].Dead = 0) and (brole[i].rnum >= 0) and (i <> bnum) and
        (i <> Attackbnum) and (brole[i].Team <> brole[bnum].Team) and
        ((abs(brole[i].X - brole[bnum].X) + abs(brole[i].Y - brole[bnum].Y)) <= 5) then
      begin
        setlength(temp, n + 1);
        temp[n] := i;
        Inc(n);
      end;
    if n > 0 then
    begin
      i := temp[random(n)];
      Result := i;
      x := -(Brole[bnum].X - Bx) * 18 + (Brole[bnum].Y - By) * 18 + CENTER_X - 10;
      y := (Brole[bnum].X - Bx) * 9 + (Brole[bnum].Y - By) * 9 + CENTER_Y - 60;
      for i1 := 0 to 10 do
      begin
        redraw;
        drawshadowtext(@str[1], x - 30, y - i1 * 2, colcolor(0, $10), colcolor(0, $14));
        sdl_delay((20 * GameSpeed) div 10);
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      end;
    end;
  end;
end;

// 反弹攻击

function RetortHurt(bnum, AttackBnum: integer): smallint;
var
  i1, i2, x, y, i, realhurt: integer;
  str: WideString;
begin
  str := UTF8Decode(' 反噬');
  Result := bnum;
  if (Random(100) < 30 + Rrole[Brole[bnum].rnum].Aptitude div 5) then
  begin
    Result := AttackBnum;
    x := -(Brole[bnum].X - Bx) * 18 + (Brole[bnum].Y - By) * 18 + CENTER_X - 10;
    y := (Brole[bnum].X - Bx) * 9 + (Brole[bnum].Y - By) * 9 + CENTER_Y - 60;
    for i1 := 0 to 10 do
    begin
      redraw;
      drawshadowtext(@str[1], x - 30, y - i1 * 2, colcolor(0, $10), colcolor(0, $14));
      sdl_delay((20 * GameSpeed) div 10);
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    end;
  end;
end;

//计算伤害值, 所谓“武功威力3”即武功威力成长值，1000为基准，大于1000则越高级增长速度越快，反之增长速度越慢

function CalNewHurtValue(lv, min, max, Proportion: integer): integer;
var
  p, n: double;
begin
  if proportion = 0 then proportion := 100;
  p := Proportion / 1000;
  n := Power((max - min), 1 / p) / 9;
  Result := round(Power((lv * n), p)) + min;
end;

function CalHurtValue(bnum1, bnum2, mnum, level: integer): integer;
var
  i, rnum1, l1, c, rnum2, mhurt, p, def, mp1, mp2, addatt, att, spd2, wpn2, spd1, wpn1, k1,
  k2, knowledge, dis: integer;
  a1, s1, m1, w1: double;
begin
  //计算双方武学常识
  k1 := 0;
  k2 := 0;
  l1 := 0;
  c := 0;
  for i := 0 to length(brole) - 1 do
  begin
    if (Brole[i].Team = brole[bnum1].Team) and (Brole[i].Dead = 0) and (Brole[i].Knowledge > MIN_KNOWLEDGE) then
      k1 := k1 + Brole[i].Knowledge;
    if (Brole[i].Team = brole[bnum2].Team) and (Brole[i].Dead = 0) and (Brole[i].Knowledge > MIN_KNOWLEDGE) then
      k2 := k2 + Brole[i].Knowledge;
    if (Brole[i].Team = 0) and (Brole[i].rnum >= 0) then
    begin
      Inc(l1, Rrole[Brole[i].rnum].Level);
      Inc(c);
    end;
  end;
  if c = 0 then
    l1 := rrole[0].Level
  else
    l1 := l1 div c;
  if (brole[bnum1].Team <> 0) then k1 := k1 + l1 * rrole[0].difficulty div 50;
  if (brole[bnum2].Team <> 0) then k2 := k2 + l1 * rrole[0].difficulty div 50;
  knowledge := k1 - k2;
  knowledge := min(k1 - k2, 100);
  knowledge := max(k1 - k2, -100);

  rnum1 := Brole[bnum1].rnum;
  rnum2 := Brole[bnum2].rnum;
  // mhurt := Rmagic[mnum].Attack[level - 1];
  mhurt := (CalNewHurtValue(level - 1, Rmagic[mnum].MinHurt, Rmagic[mnum].MaxHurt,
    Rmagic[mnum].HurtModulus) * (100 + (knowledge * 4) div 5)) div 100;

  p := Rmagic[mnum].AttackModulus * 6 + Rmagic[mnum].MPModulus + Rmagic[mnum].SpeedModulus *
    2 + Rmagic[mnum].WeaponModulus * 2;
  att := GetRoleAttack(rnum1, True) + 1;
  def := GetRoleDefence(rnum2, True) + 1;




  case Rmagic[mnum].MagicType of
    0: begin wpn1 := 0; wpn2 := 0; end;
    1: begin wpn1 := GetRoleFist(rnum1, True) + 1; wpn2 := GetRoleFist(rnum2, True) + 1; end;
    2: begin wpn1 := GetRoleSword(rnum1, True) + 1; wpn2 := GetRoleSword(rnum2, True) + 1; end;
    3: begin wpn1 := GetRoleKnife(rnum1, True) + 1; wpn2 := GetRoleKnife(rnum2, True) + 1; end;
    4: begin wpn1 := GetRoleUnusual(rnum1, True) + 1; wpn2 := GetRoleUnusual(rnum2, True) + 1; end;
  end;
  mp1 := Rrole[rnum1].CurrentMP + 1;
  mp2 := Rrole[rnum2].CurrentMP + 1;

  spd1 := GetRoleSpeed(rnum1, True) + 1;
  spd2 := GetRoleSpeed(rnum2, True) + 1;
  if CheckEquipSet(Rrole[rnum1].Equip[0], Rrole[rnum1].Equip[1], Rrole[rnum1].Equip[2], Rrole[rnum1].Equip[3]) = 5 then
  begin
    Inc(att, 50);
    Inc(spd1, 30);
  end;
  if CheckEquipSet(Rrole[rnum2].Equip[0], Rrole[rnum2].Equip[1], Rrole[rnum2].Equip[2], Rrole[rnum2].Equip[3]) = 5 then
  begin
    Inc(def, -25);
    Inc(spd2, 30);
  end;


  //showmessage(inttostr(att)+' '+inttostr(def));
  Result := 0;
  att := max(att, 1);
  def := max(def, 1);
  spd1 := max(spd1, 1);
  wpn1 := max(wpn1, 1);
  mp1 := max(mp1, 1);
  spd2 := max(spd2, 1);
  wpn2 := max(wpn2, 1);
  mp2 := max(mp2, 1);
  a1 := att - def;
  s1 := spd1 - spd2;
  w1 := wpn1 - wpn2;
  m1 := mp1 - mp2;
  if a1 < 5 then a1 := 5;
  if w1 < 5 then w1 := 5;
  if s1 < 5 then s1 := 5;
  if m1 < 5 then m1 := 5;
  a1 := min((a1 / att), 1);
  w1 := min((w1 / wpn1), 1);
  s1 := min((s1 / spd1), 1);
  m1 := min((m1 / mp1), 1);
  if p > 0 then
  begin
    if Rmagic[mnum].AttackModulus > 0 then
      Result := Result + trunc(mhurt * a1 * (Rmagic[mnum].AttackModulus * 3 * 2 / p));
    if Rmagic[mnum].MPModulus > 0 then
      Result := Result + trunc(mhurt * m1 * (Rmagic[mnum].MPModulus / p));
    if Rmagic[mnum].SpeedModulus > 0 then
      Result := Result + trunc(mhurt * s1 * (Rmagic[mnum].SpeedModulus * 2 / p));
    if Rmagic[mnum].WeaponModulus > 0 then
      Result := Result + trunc(mhurt * w1 * (Rmagic[mnum].WeaponModulus * 2 / p));
  end;
  Result := Result + random(10) - random(10);
  if Result < mhurt div 20 then
    Result := mhurt div 20 + random(5) - random(5);

  Result := Result;
  dis := abs(brole[bnum1].X - brole[bnum2].X) + abs(brole[bnum1].Y - brole[bnum2].Y);
  if dis > 10 then dis := 10;
  Result := Result * (100 - (dis - 1) * 3) div 100;
  if (Result <= 0) or (level <= 0) then
    Result := random(10) + 1;
  if (Result > 9999) then
    Result := 9999;

end;

//0: red. 1: purple, 2: green
//显示数字

procedure ShowHurtValue(mode: integer); overload;
var
  i: integer;
  color1, color2: uint32;
begin
  color1 := 0;
  color2 := 0;
  case mode of
    0:
    begin
      color1 := colcolor(0, $10);
      color2 := colcolor(0, $14);
      i := -1;
    end;
    1:
    begin
      color1 := colcolor(0, $50);
      color2 := colcolor(0, $53);
      i := -1;
    end;
    2:
    begin
      color1 := colcolor(0, $30);
      color2 := colcolor(0, $32);
      i := -1;
    end;
    3:
    begin
      color1 := colcolor(0, $5);
      color2 := colcolor(0, $7);
      i := 1;
    end;
    4:
    begin
      color1 := colcolor(0, $91);
      color2 := colcolor(0, $93);
      i := -1;
    end;
  end;
  ShowHurtValue(i, color1, color2);

end;

procedure ShowHurtValue(sign, color1, color2: integer); overload;
var
  i, i1, x, a, y: integer;
  word: array of WideString;
  str: string;
begin
  a := 0;
  str := '+%d';
  if sign < 0 then
    str := '-%d';

  setlength(word, length(brole));
  for i := 0 to length(brole) - 1 do
  begin
    if (Brole[i].ShowNumber >= 0) and (Brole[i].Dead = 0) and (Brole[i].rnum >= 0) then
    begin
      //x := -(Brole[i].X - Bx) * 18 + (Brole[i].Y - By) * 18 + CENTER_X - 10;
      //y := (Brole[i].X - Bx) * 9 + (Brole[i].Y - By) * 9 + CENTER_Y - 40;
      if Brole[i].ShowNumber = 0 then word[i] := 'Miss'
      else word[i] := format(str, [Brole[i].ShowNumber]);
    end
    else
      word[i] := '0';
  end;
  for i1 := 0 to 10 do
  begin
    redraw;
    for i := 0 to length(brole) - 1 do
    begin
      if (Brole[i].ShowNumber >= 0) and (Brole[i].Dead = 0) and (Brole[i].rnum >= 0) then
      begin
        x := -(Brole[i].X - Bx) * 18 + (Brole[i].Y - By) * 18 + CENTER_X - 10;
        y := (Brole[i].X - Bx) * 9 + (Brole[i].Y - By) * 9 + CENTER_Y - 60;
        drawengshadowtext(@word[i, 1], x, y - i1 * 2, color1, color2);
      end;
    end;
    sdl_delay((20 * GameSpeed) div 10);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  end;
  redraw;
  for i := 0 to length(brole) - 1 do
  begin
    Brole[i].ShowNumber := -1;
  end;
  redraw;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
end;

procedure ShowHurtValue(str: WideString; color1, color2: integer); overload;
var
  i, i1, x, a, y: integer;
  word: array of WideString;
begin
  a := 0;
  for i1 := 0 to 10 do
  begin
    redraw;
    for i := 0 to length(brole) - 1 do
    begin
      if (Brole[i].ShowNumber >= 0) and (Brole[i].Dead = 0) and (Brole[i].rnum >= 0) then
      begin
        x := -(Brole[i].X - Bx) * 18 + (Brole[i].Y - By) * 18 + CENTER_X - 10;
        y := (Brole[i].X - Bx) * 9 + (Brole[i].Y - By) * 9 + CENTER_Y - 60;
        drawshadowtext(@str[1], x - 20, y - i1 * 2, color1, color2);
      end;
    end;
    sdl_delay((25 * GameSpeed) div 10);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  end;
  redraw;
  for i := 0 to length(brole) - 1 do
  begin
    Brole[i].ShowNumber := -1;
  end;
  redraw;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
end;

//计算中毒减少的生命

procedure CalPoiHurtLife(bnum: integer);
var
  i, hurt: integer;
  p: boolean;
begin
  p := False;
  for i := 0 to length(brole) - 1 do
  begin
    Brole[i].ShowNumber := -1;
  end;

  if (Rrole[Brole[bnum].rnum].Poision > 0) and (Brole[bnum].Dead = 0) then
  begin
    hurt := Rrole[Brole[bnum].rnum].CurrentHP * Rrole[Brole[bnum].rnum].Poision div 200;
    Rrole[Brole[bnum].rnum].CurrentHP := Rrole[Brole[bnum].rnum].CurrentHP - hurt;
    Rrole[Brole[bnum].rnum].CurrentHP := max(Rrole[Brole[bnum].rnum].CurrentHP, 1);
    if hurt > 0 then
    begin
      Brole[bnum].ShowNumber := hurt;
      //p := true;
      showhurtvalue(2);
    end;
  end;
  if (Rrole[Brole[bnum].rnum].Hurt > 0) and (Brole[bnum].Dead = 0) then
  begin
    Brole[bnum].ShowNumber := Rrole[Brole[bnum].rnum].Hurt;
    //p := true;
    showhurtvalue(UTF8Decode('內傷'), colcolor(0, $10), colcolor(0, $14));
  end;
  if (Brole[bnum].frozen > 100) and (Brole[bnum].Dead = 0) then
  begin
    Brole[bnum].ShowNumber := Brole[bnum].frozen;
    //p := true;
    showhurtvalue(UTF8Decode('封穴'), colcolor(0, $64), colcolor(0, $66));
  end;
  if (Brole[bnum].AddAtt > 0) and (Brole[bnum].Dead = 0) then
  begin
    Brole[bnum].ShowNumber := Brole[bnum].frozen;
    //p := true;
    showhurtvalue(UTF8Decode('金剛'), colcolor(0, $5), colcolor(0, $7));
  end;
  if (Brole[bnum].AddSpd > 0) and (Brole[bnum].Dead = 0) then
  begin
    Brole[bnum].ShowNumber := Brole[bnum].frozen;
    //p := true;
    showhurtvalue(UTF8Decode('飛仙'), colcolor(0, $5), colcolor(0, $7));
  end;
  if (Brole[bnum].AddDef > 0) and (Brole[bnum].Dead = 0) then
  begin
    Brole[bnum].ShowNumber := Brole[bnum].frozen;
    //p := true;
    showhurtvalue(UTF8Decode('忘憂'), colcolor(0, $5), colcolor(0, $7));
  end;
  if (Brole[bnum].AddStep > 0) and (Brole[bnum].Dead = 0) then
  begin
    Brole[bnum].ShowNumber := Brole[bnum].frozen;
    //p := true;
    showhurtvalue(UTF8Decode('神行'), colcolor(0, $5), colcolor(0, $7));
  end;

  if (Brole[bnum].PerfectDodge > 0) and (Brole[bnum].Dead = 0) then
  begin
    Brole[bnum].ShowNumber := Brole[bnum].frozen;
    //p := true;
    showhurtvalue(UTF8Decode('迷蹤'), colcolor(0, $5), colcolor(0, $7));
  end
  else if (Brole[bnum].AddDodge > 0) and (Brole[bnum].Dead = 0) then
  begin
    Brole[bnum].ShowNumber := Brole[bnum].frozen;
    //p := true;
    showhurtvalue(UTF8Decode('閃身'), colcolor(0, $5), colcolor(0, $7));
  end;
end;

//设置生命低于0的人物为已阵亡, 主要是清除所占的位置

procedure ClearDeadRolePic;
var
  i: integer;
begin
  for i := 0 to length(brole) - 1 do
  begin
    if (brole[i].rnum >= 0) and (Rrole[Brole[i].rnum].CurrentHP <= 0) then
    begin
      Brole[i].Dead := 1;
      Brole[i].Show := 1;
      bfield[5, Brole[i].X, Brole[i].Y] := i;
      bfield[2, Brole[i].X, Brole[i].Y] := -1;
      //bmount
    end;
  end;
  for i := 0 to length(brole) - 1 do
    if Brole[i].Dead = 0 then
    begin
      bfield[2, Brole[i].X, Brole[i].Y] := i;
      bfield[5, Brole[i].X, Brole[i].Y] := -1;

    end;
end;

//显示简单状态(x, y表示位置)

procedure ShowSimpleStatus(rnum, x, y: integer);
var
  i, bnum, n, l, c: integer;
  p: array[0..10] of integer;
  eft: array of integer;
  str: WideString;
  strs: WideString;
  color1, color2: uint32;
  nt, nt2: longint;
begin
  strs := UTF8Decode(' 等級');
  y := y - 20;
  DrawRectangle(x, y, 300, 115, 0, colcolor(255), 30);
  drawpngpic(battlepic, x, y, 0);

  c := 0;
  setlength(eft, 0);
  for i := 0 to length(brole) - 1 do
    if brole[i].rnum = rnum then
    begin
      bnum := i;
      break;
    end;
  if Rrole[rnum].Poision > 0 then
  begin
    Inc(c);
    setlength(eft, c);
    eft[c - 1] := 0;
  end;
  if Rrole[rnum].Hurt > 0 then
  begin
    Inc(c);
    setlength(eft, c);
    eft[c - 1] := 1;
  end;
  if Brole[bnum].frozen > 0 then
  begin
    Inc(c);
    setlength(eft, c);
    eft[c - 1] := 2;
  end;
  if c > 0 then
  begin
    nt := sdl_getticks();
    nt2 := nt div 10;
    nt := nt2 mod 200 * c;
    nt2 := (nt div 100) mod 2;

    if (nt < 200) then
    begin
      case eft[0] of
        0: green := ((Rrole[rnum].Poision) * (100 * nt2 + trunc(power(-1, nt2)) * (nt mod 100))) div 100;
        1: red := ((Rrole[rnum].Hurt) * (100 * nt2 + trunc(power(-1, nt2)) * (nt mod 100))) div 100;
        2: gray := ((Brole[bnum].frozen) * (100 * nt2 + trunc(power(-1, nt2)) * (nt mod 100))) div 500;
      end;
    end
    else if (nt < 400) then
    begin
      case eft[1] of
        0: green := ((Rrole[rnum].Poision) * (100 * nt2 + trunc(power(-1, nt2)) * (nt mod 100))) div 150;
        1: red := ((Rrole[rnum].Hurt) * (100 * nt2 + trunc(power(-1, nt2)) * (nt mod 100))) div 150;
        2: gray := ((Brole[bnum].frozen) * (100 * nt2 + trunc(power(-1, nt2)) * (nt mod 100))) div 500;
      end;
    end
    else if (nt < 600) then
    begin
      case eft[2] of
        0: green := ((Rrole[rnum].Poision) * (100 * nt2 + trunc(power(-1, nt2)) * (nt mod 100))) div 100;
        1: red := ((Rrole[rnum].Hurt) * (100 * nt2 + trunc(power(-1, nt2)) * (nt mod 100))) div 100;
        2: gray := ((Brole[bnum].frozen) * (100 * nt2 + trunc(power(-1, nt2)) * (nt mod 100))) div 500;
      end;
    end;
  end;
  drawheadpic(Rrole[rnum].HeadNum, x + 22, y + 64);
  str := gbktounicode(@rrole[rnum].Name);
  UpdateHPMP(rnum, x + 77, y + 5);
  green := 0;
  red := 0;
  gray := 0;
  drawshadowtext(@str[1], x + 30 - length(PChar(@rrole[rnum].Name)) * 5, y + 69, colcolor($63), colcolor($66));
  drawshadowtext(@strs[1], x + 77, y + 5, colcolor($21), colcolor($23));
  if (battlemode > 0) then
  begin
    for i := 0 to length(brole) - 1 do
    begin
      if Brole[i].rnum = rnum then
      begin
        for n := 0 to (brole[i].Progress + 1) div 300 - 1 do
        begin
          drawpngpic(nowprogress_pic, n * 25 + x + 170, y + 5, 0);
        end;
      end;
    end;
    if (battlemode = 2) then
    begin
      drawpngpic(angryprogress_pic, x, y, 0);
      if Rrole[rnum].Angry < 100 then
        drawpngpic(angrycollect_pic, 0, 0, 27 + Rrole[rnum].Angry, angrycollect_pic.pic.h, x, y, 0)
      else
        drawpngpic(angryfull_pic, x, y, 0);
    end;
  end;
  str := format('%d', [Rrole[rnum].Level]);
  drawengshadowtext(@str[1], x + 143, y + 5, colcolor($5), colcolor($7));

  //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

end;

//等待, 似乎不太完善

procedure Wait(bnum: integer);
var
  i, i1, i2, x: integer;
  Temp: Tbattlerole;
begin
  if battlemode > 0 then
  begin
    Brole[bnum].wait := 1;
  end
  else
  begin
    temp := Brole[bnum];

    for i := bnum to length(brole) - 2 do
      Brole[i] := Brole[i + 1];
    Brole[length(brole) - 1] := temp;
    for i := 0 to length(brole) - 1 do
    begin
      if Brole[i].Dead = 0 then
        Bfield[2, Brole[i].X, Brole[i].Y] := i
      else
        Bfield[2, Brole[i].X, Brole[i].Y] := -1;
    end;

  end;
end;

procedure collect(bnum: integer);
begin
  BRole[bnum].Acted := 1;
  BRole[bnum].Progress := BRole[bnum].Progress + 1;
  if BRole[bnum].Progress >= 1500 then BRole[bnum].Progress := 1200;
end;

//战斗结束恢复人物状态

procedure RestoreRoleStatus;
var
  i, rnum: integer;
begin
  for i := 0 to length(brole) - 1 do
  begin
    rnum := Brole[i].rnum;
    if rnum >= 0 then
    begin
      //我方恢复部分生命, 内力; 敌方恢复全部
      if Rrole[rnum].TeamState in [1, 2] then
      begin
        RRole[rnum].CurrentHP := RRole[rnum].CurrentHP + RRole[rnum].MaxHP div 2;
        if RRole[rnum].CurrentHP <= 0 then RRole[rnum].CurrentHP := 1;
        if RRole[rnum].CurrentHP > RRole[rnum].MaxHP then RRole[rnum].CurrentHP := RRole[rnum].MaxHP;
        RRole[rnum].CurrentMP := RRole[rnum].CurrentMP + RRole[rnum].MaxMP div 20;
        if RRole[rnum].CurrentMP > RRole[rnum].MaxMP then RRole[rnum].CurrentMP := RRole[rnum].MaxMP;
        rrole[rnum].PhyPower := rrole[rnum].PhyPower + MAX_PHYSICAL_POWER div 10;
        if rrole[rnum].PhyPower > MAX_PHYSICAL_POWER then rrole[rnum].PhyPower := MAX_PHYSICAL_POWER;
      end
      else
      begin
        RRole[rnum].Angry := 0;
        RRole[rnum].Hurt := 0;
        RRole[rnum].Poision := 0;
        RRole[rnum].CurrentHP := RRole[rnum].MaxHP;
        RRole[rnum].CurrentMP := RRole[rnum].MaxMP;
        rrole[rnum].PhyPower := MAX_PHYSICAL_POWER * 9 div 10;
      end;
    end;
  end;
end;

//增加经验

procedure AddExp;
var
  i, rnum, basicvalue, amount, levels: integer;
  add, additem: integer;
  str: WideString;
begin
  levels := 0;
  amount := 0;
  for i := 0 to length(Brole) - 1 do
  begin
    if (Brole[i].Team = 0) and (Brole[i].Dead = 0) and (Brole[i].rnum >= 0) and (Brole[i].rnum < length(rrole)) then
    begin
      levels := levels + Rrole[Brole[i].rnum].Level;
      amount := amount + 1;
    end;
  end;
  for i := 0 to length(Brole) - 1 do
  begin
    if (Brole[i].rnum >= 0) and (Brole[i].rnum < length(rrole)) then
    begin
      rnum := Brole[i].rnum;
      if (Brole[i].Team = 0) then
      begin
        basicvalue := Brole[i].ExpGot;
        additem := 0;
        if Brole[i].Dead = 0 then
        begin
          if amount = 1 then
            Inc(basicvalue, warsta.exp)
          else if levels > 0 then
            Inc(basicvalue, trunc((1 - Rrole[rnum].Level / levels) / (amount - 1) * warsta.exp));
        end;
        add := basicvalue;
        additem := basicvalue div 5 * 4;
        if GetPetSkill(1, 3) then
        begin
          add := trunc(basicvalue * 1.5);
          additem := trunc(basicvalue * 1.5);
        end
        else if GetPetSkill(1, 1) and (Brole[i].rnum = 0) then
        begin
          add := trunc(basicvalue * 1.5);
          additem := trunc(basicvalue * 1.5);
        end;
        Rrole[rnum].Exp := Rrole[rnum].Exp + add;
        Rrole[rnum].Exp := min(Rrole[rnum].Exp, 50000);

        if not ((Rrole[rnum].PracticeBook >= 0) and (ritem[Rrole[rnum].PracticeBook].Magic >= 0) and
          (rmagic[ritem[Rrole[rnum].PracticeBook].Magic].MagicType = 5)) then
          Rrole[rnum].GongtiExam := Rrole[rnum].GongtiExam + add * 4 div 5;
        Rrole[rnum].GongtiExam := min(Rrole[rnum].GongtiExam, 50000);

        Rrole[rnum].ExpForBook := Rrole[rnum].ExpForBook + additem;
        //    Rrole[rnum].ExpForItem := Rrole[rnum].ExpForItem + basicvalue div 5 * 3;
        DrawRectangle(100, 235, 145, 25, 0, colcolor(255), 25);
        str := UTF8Decode(' 得經驗');
        Drawshadowtext(@str[1], 83, 237, colcolor($21), colcolor($23));
        str := format('%5d', [Brole[i].ExpGot + add]);
        Drawengshadowtext(@str[1], 188, 237, colcolor($64), colcolor($66));
        ShowSimpleStatus(rnum, 30, 50);
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        while (SDL_PollEvent(@event) >= 0) do
        begin
          case event.type_ of
            SDL_QUITEV:
              if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then Quit;
            SDL_VIDEORESIZE:
            begin
              ResizeWindow(event.resize.w, event.resize.h);
            end;
            SDL_KEYUP:
              if event.key.keysym.sym > 0 then break;
            SDL_MouseButtonUP:
              if event.button.button > 0 then break;
          end;
          if (rrole[rnum].Poision > 0) or (rrole[rnum].Hurt > 0) then
          begin
            ShowSimpleStatus(rnum, 30, 50);
            SDL_UpdateRect2(screen, 52, 114 - 77, 58, 60);
          end;
          event.key.keysym.sym := 0;
          event.button.button := 0;
          sdl_delay((20 * GameSpeed) div 10);
        end;
        event.key.keysym.sym := 0;
        event.button.button := 0;
      end;
      Redraw;
    end;
  end;
end;

//检查是否能够升级

procedure CheckLevelUp;
var
  i, rnum: integer;
begin
  for i := 0 to length(brole) - 1 do
  begin
    if Brole[i].Team = 0 then
    begin
      rnum := Brole[i].rnum;
      if rnum >= 0 then
        while (Rrole[rnum].Level < MAX_LEVEL) and (uint16(Rrole[rnum].Exp) >=
            uint16(LevelUplist[Rrole[rnum].Level - 1])) do
        begin
          Rrole[rnum].Exp := Rrole[rnum].Exp - LevelUplist[Rrole[rnum].Level - 1];
          Rrole[rnum].Level := Rrole[rnum].Level + 1;
          LevelUp(i);
        end;
    end;
  end;

end;

//升级, 如是我方人物显示状态

procedure LevelUp(bnum: integer);
var
  i, rnum, add: integer;
  str: WideString;
begin
  rnum := brole[bnum].rnum;
  if rnum >= 0 then
  begin
    RRole[rnum].MaxHP := RRole[rnum].MaxHP + (150 - RRole[rnum].Aptitude) div 10 + random(3) + 1;
    if RRole[rnum].MaxHP > MAX_HP then RRole[rnum].MaxHP := MAX_HP;
    RRole[rnum].CurrentHP := RRole[rnum].MaxHP;

    RRole[rnum].MaxMP := RRole[rnum].MaxMP + (150 - RRole[rnum].Aptitude) div 10 + random(3) + 1;
    if RRole[rnum].MaxMP > MAX_MP then RRole[rnum].MaxMP := MAX_MP;
    RRole[rnum].CurrentMP := RRole[rnum].MaxMP;

    RRole[rnum].Attack := RRole[rnum].Attack + Rrole[rnum].Level mod 2;
    Rrole[rnum].Speed := Rrole[rnum].Speed + Rrole[rnum].Level mod 2;
    Rrole[rnum].Defence := Rrole[rnum].Defence + Rrole[rnum].Level mod 2;

    if GetRoleMedcine(rnum, False) >= 20 then Inc(Rrole[rnum].Medcine, 1);
    if GetRoleUsePoi(rnum, False) >= 20 then Inc(Rrole[rnum].UsePoi, 1);
    if GetRoleMedPoi(rnum, False) >= 20 then Inc(Rrole[rnum].MedPoi, 1);
    if GetRoleFist(rnum, False) >= 20 then Inc(Rrole[rnum].Fist, 1);
    if GetRoleSword(rnum, False) >= 20 then Inc(Rrole[rnum].Sword, 1);
    if GetRoleKnife(rnum, False) >= 20 then Inc(Rrole[rnum].Knife, 1);
    if GetRoleUnusual(rnum, False) >= 20 then Inc(Rrole[rnum].Unusual, 1);
    if GetRoleHidWeapon(rnum, False) >= 20 then Inc(Rrole[rnum].HidWeapon, 1);

    RRole[rnum].PhyPower := MAX_PHYSICAL_POWER;
    RRole[rnum].Hurt := 0;
    RRole[rnum].Poision := 0;
    for i := 43 to 54 do
      Rrole[rnum].Data[i] := min(Rrole[rnum].Data[i], MaxProList[i]);
    if Brole[bnum].Team = 0 then
    begin
      redraw;
      NewShowStatus(rnum);
      //str := ' 升級';
      //Drawshadowtext(@str[1], 195, 94, colcolor($21), colcolor($23));
      //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      //waitanykey;
    end;
  end;

end;

//检查身上秘笈

procedure CheckBook;
var
  i, i1, i2, Aptitude, p, rnum, inum, mnum, mlevel, needexp, needitem, needitemamount, itemamount: integer;
  str: WideString;
begin
  for i := 0 to length(brole) - 1 do
  begin
    rnum := Brole[i].rnum;
    if rnum >= 0 then
    begin
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
        if CheckEquipSet(Rrole[rnum].equip[0], Rrole[rnum].equip[1], Rrole[rnum].equip[2],
          Rrole[rnum].equip[3]) = 2 then
          Aptitude := 100
        else Aptitude := Rrole[rnum].Aptitude;
        if Ritem[inum].NeedExp > 0 then needexp := mlevel * (Ritem[inum].NeedExp * (8 - Aptitude div 15)) div 2
        else needexp := mlevel * ((-Ritem[inum].NeedExp) * (1 + Aptitude div 15)) div 2;

        while (Rrole[rnum].PracticeBook >= 0) and (Rrole[rnum].ExpForBook >= needexp) and (mlevel < 10) do
        begin
          if (Rmagic[mnum].MagicType = 5) and (mlevel > 1) then break;
          redraw;
          EatOneItem(rnum, inum);

          if mnum > 0 then
          begin
            instruct_33(rnum, mnum, 1);
            str := IntToStr(getmagiclevel(rnum, mnum) div 100 + 1);
            DrawRectangle(100, 70 - 30, 200, 25, 0, colcolor(255), 25);

            Drawshadowtext(@str[1], 240, 72 - 30, colcolor($64), colcolor($66));
            str := UTF8Decode(' 升為   級');
            Drawshadowtext(@str[1], 183, 72 - 30, colcolor($21), colcolor($23));
            Drawgbkshadowtext(@Rmagic[mnum].Name, 83, 72 - 30, colcolor($64), colcolor($66));
            SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            waitanykey;


            mlevel := getmagiclevel(rnum, mnum) div 100 + 1;


            redraw;
          end;
          Rrole[rnum].ExpForBook := Rrole[rnum].ExpForBook - needexp;
          if Ritem[inum].NeedExp > 0 then needexp := mlevel * (Ritem[inum].NeedExp * (8 - Aptitude div 15)) div 2
          else needexp := mlevel * ((-Ritem[inum].NeedExp) * (1 + Aptitude div 15)) div 2;
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          //ShowStatus(rnum);
          //waitanykey;
          if (GetMagicLevel(rnum, mnum) >= 900) or (Rmagic[mnum].MagicType = 5) then
          begin
            Rrole[rnum].PracticeBook := -1;
            instruct_32(inum, 1);
          end;
        end;
      end;
    end;
  end;

end;

//统计一方人数

function CalRNum(team: integer): integer;
var
  i: integer;
begin
  Result := 0;
  for i := 0 to length(brole) - 1 do
  begin
    if (Brole[i].rnum > -1) and (Brole[i].Team = team) and (Brole[i].Dead = 0) then Result := Result + 1;
  end;

end;

//战斗中物品选单

procedure BattleMenuItem(bnum: integer);
var
  rnum, inum, mode: integer;
  str: WideString;
begin
  CurItem := -1;
  MenuItem(3);
  inum := CurItem;
  if inum < 0 then exit;
  rnum := brole[bnum].rnum;
  mode := Ritem[inum].ItemType;
  case mode of
    3:
    begin
      Ax := brole[bnum].X;
      Ay := brole[bnum].Y;
      if ritem[inum].EventNum <= 0 then
      begin
        redraw;
        EatOneItem(rnum, inum);
        instruct_32(inum, -1);
        Brole[bnum].Acted := 1;
        waitanykey;
        BRole[bnum].Progress := BRole[bnum].Progress - 240;
      end
      else
      begin
        callevent(ritem[inum].EventNum);
      end;
    end;
    4:
    begin
      UseHiddenWeapen(bnum, inum);
    end;
  end;
end;

//动作动画

procedure PlayActionAmination(bnum, mode: integer);
var
  d1, d2, dm, rnum, i1, i, Count, grp, beginpic, endpic, idx, tnum, len: integer;
  filename, fn, modestr, rolestr: string;
begin
  d1 := Ax - Bx;
  d2 := Ay - By;
  dm := abs(d1) - abs(d2);
  if (dm > 0) then
    if d1 < 0 then Brole[bnum].Face := 0 else Brole[bnum].Face := 3
  else if (dm < 0) then
    if d2 < 0 then Brole[bnum].Face := 2 else Brole[bnum].Face := 1;

  Redraw;
  rnum := brole[bnum].rnum;

  rolestr := format('%3d', [rrole[rnum].HeadNum]);
  for i := 1 to length(rolestr) do
    if rolestr[i] = ' ' then rolestr[i] := '0';

  modestr := format('%2d', [mode]);
  for i := 1 to length(modestr) do
    if modestr[i] = ' ' then modestr[i] := '0';

  filename := 'fight/' + rolestr + '/' + modestr;
  if (FileExistsUTF8(AppPath + filename + '.pic') { *Converted from FileExists*  }) then
  begin
    grp := fileopen(AppPath + filename + '.pic', fmopenread);
    fileseek(grp, 0, 0);
    fileread(grp, Count, 4);

    beginpic := Brole[bnum].Face * (Count div 4);
    endpic := beginpic + (Count div 4) - 1;

    for i := beginpic to endpic do
    begin
      DrawBfieldWithAction(grp, bnum, i);
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      sdl_delay((40 * GameSpeed) div 10);
    end;
    fileclose(grp);
  end
  else
  begin
    for i1 := 0 to 4 do
    begin
      modestr := format('%2d', [i1]);
      for i := 1 to length(modestr) do
        if modestr[i] = ' ' then modestr[i] := '0';

      filename := 'fight/' + rolestr + '/' + modestr;
      if (FileExistsUTF8(AppPath + filename + '.pic') { *Converted from FileExists*  }) then
      begin
        grp := fileopen(AppPath + filename + '.pic', fmopenread);
        fileseek(grp, 0, 0);
        fileread(grp, Count, 4);

        beginpic := Brole[bnum].Face * (Count div 4);
        endpic := beginpic + (Count div 4) - 1;

        for i := beginpic to endpic do
        begin
          DrawBfieldWithAction(grp, bnum, i);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          sdl_delay((40 * GameSpeed) div 10);
        end;
        fileclose(grp);
        break;
      end;
    end;
  end;
end;

//用毒

procedure UsePoision(bnum: integer);
var
  rnum, bnum1, rnum1, poi, step, addpoi: integer;
  select: boolean;
begin
  rnum := brole[bnum].rnum;
  poi := GetRoleUsePoi(rnum, True);
  step := poi div 15 + 1;
  calcanselect(bnum, 1, step);
  if (Brole[bnum].Team = 0) and (brole[bnum].Auto = -1) then
    select := selectaim(bnum, step);
  if (bfield[2, Ax, Ay] >= 0) and (select = True) then
  begin
    bnum1 := bfield[2, Ax, Ay];
    if brole[bnum1].Team <> Brole[bnum].Team then
    begin
      //转换伤害对象  4 乾坤大挪移 5斗转星移
      if GetEquipState(brole[bnum1].rnum, 4) or (GetGongtiState(brole[bnum1].rnum, 4)) then
        bnum1 := ReMoveHurt(bnum1, bnum);
      if GetEquipState(brole[bnum1].rnum, 5) or (GetGongtiState(brole[bnum1].rnum, 5)) then
        bnum1 := RetortHurt(bnum1, bnum);
      Brole[bnum].Acted := 1;
      if (not GetEquipState(rnum, 1)) and (not GetGongtiState(rnum, 1)) then
        rrole[rnum].PhyPower := rrole[rnum].PhyPower - 3;
      rnum1 := brole[bnum1].rnum;
      addpoi := GetRoleUsePoi(rnum, True) div 3 - GetRoleDefPoi(rnum1, True) div 4;
      if addpoi < 0 then addpoi := 0;
      addpoi := min(addpoi, GetRoleUsePoi(rnum, True) - rrole[rnum1].Poision);

      if brole[bnum].Team = 0 then
        addpoi := addpoi * (200 - rrole[0].difficulty) div 200;
      if brole[bnum].Team = 1 then
        addpoi := addpoi * (200 + rrole[0].difficulty) div 200;

      if brole[bnum1].PerfectDodge > 0 then addpoi := 0;

      if GetGongtiState(Brole[bnum1].rnum, 12) or GetEquipState(Brole[bnum1].rnum, 12) or
        (CheckEquipSet(Rrole[Brole[bnum1].rnum].equip[0], Rrole[Brole[bnum1].rnum].equip[1],
        Rrole[Brole[bnum1].rnum].equip[2], Rrole[Brole[bnum1].rnum].equip[3]) = 4) then
        addpoi := 0;

      if addpoi > 0 then Inc(Brole[bnum].ExpGot, max(0, addpoi div 5));

      rrole[rnum1].Poision := rrole[rnum1].Poision + addpoi;
      brole[bnum1].ShowNumber := addpoi;
      SetAminationPosition(0, 0, 0);
      playsound(34, 0);
      PlayActionAmination(bnum, 0);
      PlayMagicAmination(bnum, 0, 34, 0);
      ShowHurtValue(2);
      BRole[bnum].Progress := BRole[bnum].Progress - 240;
    end;
  end;
end;

//医疗

procedure Medcine(bnum: integer);
var
  rnum, bnum1, rnum1, med, step, i, addlife: integer;
  select: boolean;
begin
  rnum := brole[bnum].rnum;
  med := GetRoleMedcine(rnum, True);
  step := med div 15 + 1;
  select := True;
  calcanselect(bnum, 1, step);
  if (Brole[bnum].Team = 0) and (brole[bnum].Auto = -1) then
    select := selectaim(bnum, step)
  else
  begin
    Ax := Bx;
    Ay := By;
  end;
  if (bfield[2, Ax, Ay] >= 0) and (select = True) then
  begin
    bnum1 := bfield[2, Ax, Ay];
    if brole[bnum1].Team = Brole[bnum].Team then
    begin
      Brole[bnum].Acted := 1;
      if (not GetEquipState(rnum, 1)) and (not GetGongtiState(rnum, 1)) then
        rrole[rnum].PhyPower := rrole[rnum].PhyPower - 5;
      rnum1 := brole[bnum1].rnum;
      addlife := GetRoleMedcine(rnum, True) * (10 - Rrole[rnum1].Hurt div 15) div 10; //calculate the value
      if Rrole[rnum1].Hurt - GetRoleMedcine(rnum, True) > 20 then addlife := 0;
      if addlife < 0 then addlife := 0;
      addlife := min(addlife, rrole[rnum1].MaxHP - rrole[rnum1].CurrentHP);

      if addlife > 0 then Inc(Brole[bnum].ExpGot, max(0, addlife div 5));
      Inc(Brole[bnum].ExpGot, max(0, addlife div 10));

      rrole[rnum1].CurrentHP := rrole[rnum1].CurrentHP + addlife;
      Rrole[rnum1].Hurt := Rrole[rnum1].Hurt - addlife div LIFE_HURT;
      if Rrole[rnum1].Hurt < 0 then Rrole[rnum1].Hurt := 0;
      brole[bnum1].ShowNumber := addlife;
      SetAminationPosition(0, 0, 0);
      if getpetskill(5, 2) then
      begin
        for i := 0 to length(brole) - 1 do
        begin
          if (brole[i].Dead = 0) and (brole[i].rnum >= 0) and (i <> bnum1) and
            (brole[i].Team = brole[bnum1].Team) and (brole[i].X in
            [brole[bnum1].X - 3..brole[bnum1].X + 3]) and (brole[i].Y in [brole[bnum1].Y - 3..brole[bnum1].Y + 3]) then
          begin
            addlife := 0;
            rnum1 := brole[i].rnum;
            addlife := GetRoleMedcine(rnum, True) * (10 - Rrole[rnum1].Hurt div 15) div 10; //calculate the value
            if Rrole[rnum1].Hurt - GetRoleMedcine(rnum, True) > 20 then addlife := 0;
            if addlife < 0 then addlife := 0;
            addlife := min(addlife, rrole[rnum1].MaxHP - rrole[rnum1].CurrentHP);

            if addlife > 0 then Inc(Brole[bnum].ExpGot, max(0, addlife div 10));

            rrole[rnum1].CurrentHP := rrole[rnum1].CurrentHP + addlife;
            Rrole[rnum1].Hurt := Rrole[rnum1].Hurt - addlife div LIFE_HURT;
            if Rrole[rnum1].Hurt < 0 then Rrole[rnum1].Hurt := 0;
            brole[i].ShowNumber := addlife;

            Bfield[4, brole[i].X, brole[i].Y] := 1;
          end;
        end;
      end;
      playsound(31, 0);
      PlayActionAmination(bnum, 0);
      PlayMagicAmination(bnum, 0, 31, 0);
      ShowHurtValue(3);
      BRole[bnum].Progress := BRole[bnum].Progress - 240;
    end;
  end;
end;

//解穴

procedure MedFrozen(bnum: integer);
var
  rnum, bnum1, rnum1, med, step, addlife: integer;
  select: boolean;
begin
  rnum := brole[bnum].rnum;
  med := Rrole[rnum].CurrentMP;
  step := med div 200 + 1;
  calcanselect(bnum, 1, step);
  if (Brole[bnum].Team = 0) and (brole[bnum].Auto = -1) then
    select := selectaim(bnum, step)
  else
  begin
    Ax := Bx;
    Ay := By;
  end;
  if (bfield[2, Ax, Ay] >= 0) and (select = True) then
  begin
    bnum1 := bfield[2, Ax, Ay];
    if brole[bnum1].Team = Brole[bnum].Team then
    begin
      Brole[bnum].Acted := 1;
      if (not GetEquipState(rnum, 1)) and (not GetGongtiState(rnum, 1)) then
        rrole[rnum].PhyPower := rrole[rnum].PhyPower - 5;
      rnum1 := brole[bnum1].rnum;
      addlife := min((Rrole[rnum].CurrentMP + GetRoleMedcine(rnum, True) * 5) div 3, brole[bnum1].frozen);
      Dec(brole[bnum1].frozen, addlife);
      brole[bnum1].frozen := max(0, brole[bnum1].frozen);
      brole[bnum1].ShowNumber := addlife;
      SetAminationPosition(0, 0, 0);
      playsound(32, 0);
      PlayActionAmination(bnum, 0);
      PlayMagicAmination(bnum, 0, 32, 0);
      ShowHurtValue(4);
      BRole[bnum].Progress := BRole[bnum].Progress - 240;
    end;
  end;
end;



//解毒

procedure MedPoision(bnum: integer);
var
  rnum, bnum1, i, rnum1, medpoi, step, minuspoi: integer;
  select: boolean;
begin
  rnum := brole[bnum].rnum;
  medpoi := GetRoleMedPoi(rnum, True);
  step := medpoi div 15 + 1;
  calcanselect(bnum, 1, step);
  if (Brole[bnum].Team = 0) and (brole[bnum].Auto = -1) then
    select := selectaim(bnum, step)
  else
  begin
    Ax := Bx;
    Ay := By;
  end;
  if (bfield[2, Ax, Ay] >= 0) and (select = True) then
  begin
    bnum1 := bfield[2, Ax, Ay];
    if brole[bnum1].Team = Brole[bnum].Team then
    begin
      Brole[bnum].Acted := 1;
      if (not GetEquipState(rnum, 1)) and (not GetGongtiState(rnum, 1)) then
        rrole[rnum].PhyPower := rrole[rnum].PhyPower - 5;
      rnum1 := brole[bnum1].rnum;
      minuspoi := GetRoleMedPoi(rnum, True);

      if minuspoi < (Rrole[rnum1].Poision div 2) then
        minuspoi := 0
      else if minuspoi > Rrole[rnum1].Poision then
        minuspoi := Rrole[rnum1].Poision;

      if minuspoi < 0 then minuspoi := 0;
      minuspoi := min(minuspoi, rrole[rnum1].Poision);
      if minuspoi > 0 then Inc(Brole[bnum].ExpGot, max(0, minuspoi div 5));

      rrole[rnum1].Poision := rrole[rnum1].Poision - minuspoi;
      brole[bnum1].ShowNumber := minuspoi;
      SetAminationPosition(0, 0, 0);
      if getpetskill(5, 2) then
      begin
        for i := 0 to length(brole) - 1 do
        begin
          if (brole[i].Dead = 0) and (brole[i].rnum >= 0) and (i <> bnum1) and
            (brole[i].Team = brole[bnum1].Team) and (brole[i].X in
            [brole[bnum1].X - 3..brole[bnum1].X + 3]) and (brole[i].Y in [brole[bnum1].Y - 3..brole[bnum1].Y + 3]) then
          begin
            rnum1 := brole[i].rnum;
            minuspoi := GetRoleMedPoi(rnum, True);

            if minuspoi < (Rrole[rnum1].Poision div 2) then
              minuspoi := 0
            else if minuspoi > Rrole[rnum1].Poision then
              minuspoi := Rrole[rnum1].Poision;

            if minuspoi < 0 then minuspoi := 0;
            minuspoi := min(minuspoi, rrole[rnum1].Poision);
            if minuspoi > 0 then Inc(Brole[bnum].ExpGot, max(0, minuspoi div 5));

            rrole[rnum1].Poision := rrole[rnum1].Poision - minuspoi;
            brole[i].ShowNumber := minuspoi;

            Bfield[4, brole[i].X, brole[i].Y] := 1;
          end;
        end;
      end;
      playsound(33, 0);
      PlayActionAmination(bnum, 0);
      PlayMagicAmination(bnum, 0, 33, 0);
      ShowHurtValue(4);
      BRole[bnum].Progress := BRole[bnum].Progress - 240;
    end;
  end;
end;

//使用暗器

procedure UseHiddenWeapen(bnum, inum: integer);
var
  rnum, i, bnum1, rnum1, hidden, step, poi, hurt: integer;
  select: boolean;
begin
  rnum := brole[bnum].rnum;
  hidden := GetRoleHidWeapon(rnum, True);
  step := hidden div 15 + 1;

  if (GetEquipState(Brole[bnum].rnum, 24)) or (GetGongtiState(Brole[bnum].rnum, 24)) then
    Inc(step);

  calcanselect(bnum, 1, step);
  if ritem[inum].EventNum > 0 then
    callevent(ritem[inum].EventNum)
  else
  begin
    event.key.keysym.sym := 0;
    event.button.button := 0;
    if (Brole[bnum].Team = 0) and (brole[bnum].Auto = -1) then
      select := selectaim(bnum, step);
    if (bfield[2, Ax, Ay] >= 0) and (select = True) and (brole[bfield[2, Ax, Ay]].Team <> 0) then
    begin

      bnum1 := bfield[2, Ax, Ay];
      if brole[bnum1].Team <> Brole[bnum].Team then
      begin
        Brole[bnum].Acted := 1;
        instruct_32(inum, -1);
        rnum1 := brole[bnum1].rnum;

        if brole[bnum1].PerfectDodge > 0 then
        begin
          hurt := 0;
        end
        else
        begin
          hurt := -(hidden * ritem[inum].AddCurrentHP) div 100;
          hurt := max(hurt, 25);

          if brole[bnum].Team = 0 then
            hurt := hurt * (200 - rrole[0].difficulty) div 200;
          if brole[bnum].Team = 1 then
            hurt := hurt * (200 + rrole[0].difficulty) div 200;

          rrole[rnum1].CurrentHP := rrole[rnum1].CurrentHP - hurt;
          poi := max(0, (hidden * ritem[inum].AddPoi) div 100 - GetRoleDefPoi(rnum1, True));

          if brole[bnum].Team = 0 then
            poi := poi * (200 - rrole[0].difficulty) div 200;
          if brole[bnum].Team = 1 then
            poi := poi * (200 + rrole[0].difficulty) div 200;

          if GetGongtiState(Brole[bnum1].rnum, 12) or GetEquipState(Brole[bnum1].rnum, 12) or
            (CheckEquipSet(Rrole[Brole[bnum1].rnum].equip[0], Rrole[Brole[bnum1].rnum].equip[1],
            Rrole[Brole[bnum1].rnum].equip[2], Rrole[Brole[bnum1].rnum].equip[3]) = 4) then
            poi := 0;

          rrole[rnum1].Poision := rrole[rnum1].Poision + poi;

        end;
        brole[bnum1].ShowNumber := hurt;
        SetAminationPosition(0, 0, 0);
        playsound(ritem[inum].AmiNum, 0);
        PlayActionAmination(bnum, 0);
        PlayMagicAmination(bnum, 0, ritem[inum].AmiNum, 0);
        ShowHurtValue(0);
        BRole[bnum].Progress := BRole[bnum].Progress - 240;
        ClearDeadRolePic;
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

  RRole[rnum].CurrentHP := RRole[rnum].CurrentHP + ((100 - RRole[rnum].Hurt) * Rrole[rnum].MaxHP) div 2000;
  if RRole[rnum].CurrentHP > RRole[rnum].MaxHP then RRole[rnum].CurrentHP := RRole[rnum].MaxHP;
  RRole[rnum].CurrentMP := RRole[rnum].CurrentMP + ((100 - RRole[rnum].Hurt) * Rrole[rnum].MaxMP) div 2000;
  if RRole[rnum].CurrentMP > RRole[rnum].MaxMP then RRole[rnum].CurrentMP := RRole[rnum].MaxMP;
  rrole[rnum].PhyPower := rrole[rnum].PhyPower + ((100 - RRole[rnum].Hurt) * MAX_PHYSICAL_POWER) div 2000;
  if rrole[rnum].PhyPower > MAX_PHYSICAL_POWER then rrole[rnum].PhyPower := MAX_PHYSICAL_POWER;
  BRole[bnum].Progress := BRole[bnum].Progress - 240;
  BRole[bnum].Progress := BRole[bnum].Progress + ((BRole[bnum].Step * 120) div max(1, (BRole[bnum].speed div 15)));
end;

//The AI.

procedure AutoBattle(bnum: integer);
var
  i, p, a, h, temp, rnum, inum, eneamount, aim, mnum, level, Ax1, Ay1, i1, i2, step, step1, dis0, dis: integer;
  str: WideString;
begin
  rnum := brole[bnum].rnum;
  showsimplestatus(rnum, 30, 330);
  sdl_delay(350);
  //showmessage('');
  //Life is less than 20%, 70% probality to medcine or eat a pill.
  //生命低于20%, 70%可能医疗或吃药
  if (Brole[bnum].Acted = 0) and (RRole[rnum].CurrentHP < RRole[rnum].MaxHP div 5) then
  begin
    if random(100) < 70 then
    begin
      //医疗大于50, 且体力大于50才对自身医疗
      if (GetRoleMedcine(rnum, True) >= 50) and (rrole[rnum].PhyPower >= 50) and (random(100) < 50) then
      begin
        medcine(bnum);
      end
      else
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
    for i := 0 to length(brole) - 1 do
    begin
      if (Brole[bnum].Team <> Brole[i].Team) and (Brole[i].rnum >= 0) and (Brole[i].Dead = 0) then
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
    CalCanSelect(bnum, 0, Brole[bnum].step);
    dis0 := abs(Ax1 - Bx) + abs(Ay1 - By);
    for i1 := min(Ax1, Bx) to max(Ax1, Bx) do
      for i2 := min(Ay1, By) to max(Ay1, By) do
      begin
        if Bfield[3, i1, i2] >= 0 then
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
    if Bfield[3, Ax, Ay] >= 0 then MoveAmination(bnum);
    Ax := Brole[i].X;
    Ay := Brole[i].Y;

    //Try to attack it. select the best WUGONG.
    //使用目前最强的武功攻击
    p := 0;
    a := 0;
    temp := 0;
    h := 0;
    for i1 := 0 to 9 do
    begin
      mnum := Rrole[rnum].Magic[i1];
      if mnum > 0 then
      begin
        a := a + 1;
        level := Rrole[rnum].MagLevel[i1] div 100 + 1;
        if RRole[rnum].CurrentMP < rmagic[mnum].NeedMP * level then
          level := RRole[rnum].CurrentMP div rmagic[mnum].NeedMP;
        if level > 10 then level := 10;
        if level < 0 then level := 1;
        if level = 0 then continue;
        h := CalNewHurtValue(level - 1, Rmagic[mnum].MinHurt, Rmagic[mnum].MaxHurt, Rmagic[mnum].HurtModulus);
        if h > temp then
        begin
          p := i1;
          temp := h;
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
          if CheckEquipSet(Rrole[rnum].equip[0], Rrole[rnum].equip[1], Rrole[rnum].equip[2],
            Rrole[rnum].equip[3]) = 1 then
            Inc(a, 1);
          if GetEquipState(rnum, 22) or GetGongtiState(rnum, 22) then //增加攻击距离
            Inc(a, 1);
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
    if CheckEquipSet(Rrole[rnum].equip[0], Rrole[rnum].equip[1], Rrole[rnum].equip[2], Rrole[rnum].equip[3]) = 1 then
      Inc(step, 1);
    if GetEquipState(rnum, 22) or GetGongtiState(rnum, 22) then //增加攻击距离
      Inc(step, 1);
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
            if (abs(i1 - Ax) <= step1) and (abs(i2 - Ay) <= step1) and
              (abs(i1 - Bx) + abs(i2 - By) <= step + step1) then
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
        SetAminationPosition(Rmagic[mnum].AttAreaType, step, step1)
      else
        SetAminationPosition(Rmagic[mnum].AttAreaType, step, step1);

      if bfield[4, Ax, Ay] <> 0 then
      begin
        Rrole[rnum].AttTwice := 0;
        if (GetEquipState(rnum, 14) or (GetGongtiState(rnum, 14))) and (random(100) > 30) then
          Rrole[rnum].AttTwice := 1;
        Brole[bnum].Acted := 1;
        for i1 := 0 to Rrole[rnum].AttTwice do
        begin
          Rrole[rnum].MagLevel[p] := Rrole[rnum].MagLevel[p] + 2;
          if Rrole[rnum].MagLevel[p] > 999 then Rrole[rnum].MagLevel[p] := 999;
          if rmagic[mnum].EventNum > 0 then callevent(rmagic[mnum].EventNum)
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
      if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then Quit;
    if (event.key.keysym.sym = sdlk_Escape) then
    begin
      brole[bnum].Auto := -1;
    end;
  end;
end;

//自动使用list的值最大的物品

procedure AutoUseItem(bnum, list: integer);
var
  i, p, temp, rnum, inum: integer;
  str: WideString;
begin
  rnum := brole[bnum].rnum;
  if Brole[bnum].Team <> 0 then
  begin
    temp := 0;
    p := -1;
    for i := 0 to 3 do
    begin
      if (Rrole[rnum].TakingItem[i] >= 0) and (ritem[Rrole[rnum].TakingItem[i]].EventNum <= 0) then
      begin
        if ritem[Rrole[rnum].TakingItem[i]].Data[list] > temp then
        begin
          temp := ritem[Rrole[rnum].TakingItem[i]].Data[list];
          p := i;
        end;
      end;
    end;
  end
  else
  begin
    temp := 0;
    p := -1;
    for i := 0 to MAX_ITEM_AMOUNT - 1 do
    begin
      if (RItemList[i].Amount > 0) and (ritem[RItemList[i].Number].ItemType = 3) and
        (ritem[RItemList[i].Number].EventNum <= 0) then
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
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    EatOneItem(rnum, inum);
    BRole[bnum].Progress := BRole[bnum].Progress - 240;
    if Brole[bnum].Team <> 0 then
      instruct_41(rnum, rrole[rnum].TakingItem[p], -1)
    else
      instruct_32(RItemList[p].Number, -1);
    Brole[bnum].Acted := 1;
    sdl_delay(750);
  end;

end;

//自动战斗AI，小小猪更改

procedure AutoBattle2(bnum: integer);
var
  i, p, a, temp, rnum, inum, eneamount, aim, mnum, l1, level, Ax1, h, Ay1, i1, i2, step, step1, dis0, dis: integer;
  Cmnum, Cmlevel, Cmtype, Cmdis, Cmrange: integer;
  p1, Cmnum1, Cmlevel1, Cmtype1, Cmdis1, Cmrange1: integer;
  Mx, My, Mx1, My1, tempmaxhurt, maxhurt, tempminHP: integer;
  str, str1: WideString;
  words: string;
begin

  rnum := brole[bnum].rnum;
  if brole[bnum].Team = 0 then showsimplestatus(rnum, 30, 330)
  else showsimplestatus(rnum, 30, 330);
  sdl_delay(350);
  //showmessage('');
  //Life is less than 20%, 70% probality to medcine or eat a pill.
  //生命低于20%, 70%可能医疗或吃药
  if (Brole[bnum].Acted = 0) and (RRole[rnum].CurrentHP < RRole[rnum].MaxHP div 5) then
  begin
    if (Brole[bnum].Team <> 0) or ((Brole[bnum].Team = 0) and (Brole[bnum].Auto > 0)) then
    begin
      if random(100) < 70 then
      begin
        farthestmove(Mx, My, bnum);
        Ax := Mx;
        Ay := My;
        MoveAmination(bnum);
        //医疗大于50, 且体力大于50才对自身医疗
        if (GetRoleMedcine(rnum, True) >= 50) and (rrole[rnum].PhyPower >= 50) and (random(100) < 50) then
        begin
          medcine(bnum);
        end
        else if (Brole[bnum].Team <> 0) or ((Brole[bnum].Team = 0) and (Brole[bnum].Auto = 1)) then
        begin
          // if can't medcine, eat the item which can add the most life on its body.
          //无法医疗则选择身上加生命最多的药品, 我方从物品栏选择
          AutoUseItem(bnum, 45);
        end;
      end;
    end;
  end;

  //MP is less than 20%, 60% probality to eat a pill.
  //内力低于20%, 60%可能吃药
  if (Brole[bnum].Acted = 0) and (RRole[rnum].CurrentMP < RRole[rnum].MaxMP div 5) then
  begin
    if (Brole[bnum].Team <> 0) or ((Brole[bnum].Team = 0) and (Brole[bnum].Auto = 1)) then
    begin
      if random(100) < 60 then
      begin
        farthestmove(Mx, My, bnum);
        Ax := Mx;
        Ay := My;
        MoveAmination(bnum);
        AutoUseItem(bnum, 50);
      end;
    end;
  end;

  //Physical power is less than 20%, 80% probality to eat a pill.
  //体力低于20%, 80%可能吃药
  if (Brole[bnum].Acted = 0) and (rrole[rnum].PhyPower < MAX_PHYSICAL_POWER div 5) then
  begin
    if (Brole[bnum].Team <> 0) or ((Brole[bnum].Team = 0) and (Brole[bnum].Auto = 1)) then
    begin
      if random(100) < 80 then
      begin
        farthestmove(Mx, My, bnum);
        Ax := Mx;
        Ay := My;
        MoveAmination(bnum);
        AutoUseItem(bnum, 48);
      end;
    end;
  end;

  //自身医疗大于60，寻找生命低于50％的队友进行医疗
  if (Brole[bnum].Acted = 0) and (GetRoleMedcine(rnum, True) >= 60) and (rrole[rnum].PhyPower > 50) then
  begin
    if (Brole[bnum].Team <> 0) or ((Brole[bnum].Team = 0) and (Brole[bnum].Auto > 0)) then
    begin
      Mx1 := -1;
      Ax1 := -1;
      trymovecure(Mx1, My1, Ax1, Ay1, bnum);
      if Ax1 <> -1 then
      begin
        //移动
        Ax := Mx1;
        Ay := My1;
        MoveAmination(bnum);

        //医疗
        Ax := Ax1;
        Ay := Ay1;
        cureaction(bnum);
        Brole[bnum].Acted := 1;
      end;
    end;
  end;

  //尝试攻击
  if (Brole[bnum].Acted = 0) and (rrole[rnum].PhyPower >= 10) then
  begin
    Mx := -1;
    Ax := -1;
    mnum := 0;
    Cmlevel := 0;
    Cmtype := 0;
    Cmdis := 0;
    Cmrange := 0;

    p := 0;
    a := 0;
    tempmaxhurt := 0;
    maxhurt := 0;
    for i := 0 to 9 do
    begin
      mnum := Rrole[rnum].Magic[i];
      if mnum <= 0 then break;
      if rmagic[rrole[rnum].Magic[i]].MagicType = 5 then continue;
      if rmagic[rrole[rnum].Magic[i]].EventNum > 0 then continue;
      a := a + 1;
      level := Rrole[rnum].MagLevel[i] div 100 + 1;
      if rmagic[mnum].NeedMP > 0 then level := min(RRole[rnum].CurrentMP div rmagic[mnum].NeedMP, level);
      if level > 10 then level := 10;
      if level = 0 then continue;

      for i1 := 0 to 63 do
        for i2 := 0 to 63 do
          Bfield[3, i1, i2] := -1;

      Bfield[3, Brole[bnum].X, Brole[bnum].Y] := 0;

      trymoveattack(Mx1, My1, Ax1, Ay1, tempmaxhurt, bnum, mnum, level);
      if (tempmaxhurt > maxhurt) then
      begin
        p := i;
        Cmnum := mnum;
        Cmtype := rmagic[mnum].AttAreaType;
        Cmdis := rmagic[mnum].MoveDistance[level - 1];
        if CheckEquipSet(Rrole[rnum].equip[0], Rrole[rnum].equip[1], Rrole[rnum].equip[2],
          Rrole[rnum].equip[3]) = 1 then
          Inc(Cmdis, 1);
        if GetEquipState(rnum, 22) or GetGongtiState(rnum, 22) then //增加攻击距离
          Inc(Cmdis, 1);
        Cmrange := rmagic[mnum].AttDistance[level - 1];
        Mx := Mx1;
        My := My1;
        Ax := Ax1;
        Ay := Ay1;
        cmlevel := level;
        maxhurt := tempmaxhurt;
      end;
    end;
    //移动并攻击
    if (AX <> -1) and (MX <> -1) then
    begin
      //移动

      if ((Brole[bnum].Progress + 1) div 3 < (rmagic[Cmnum].NeedProgress * 10) * cmlevel + 100) and
        (BattleMode > 0) and (rrole[rnum].Angry < 100) and (Brole[bnum].Team = 0) then
      begin
        nearestmove(Mx, My, bnum);
        MoveAmination(bnum);
        Ax := Mx;
        Ay := My;
        collect(bnum);
      end
      else
      begin
        Ax1 := Ax;
        Ay1 := Ay;
        Ax := Mx;
        Ay := My;
        MoveAmination(bnum);

        //攻击
        Ax := Ax1;
        Ay := Ay1;
        SetAminationPosition(Rmagic[Cmnum].AttAreaType, Cmdis, Cmrange);
        Brole[bnum].Acted := 1;

        Rrole[rnum].AttTwice := 0;
        if (GetEquipState(rnum, 14) or (GetGongtiState(rnum, 14))) and (random(100) > 30) then
          Rrole[rnum].AttTwice := 1;
        for i1 := 0 to Rrole[rnum].AttTwice do
        begin
          if Rmagic[Rrole[rnum].Magic[p]].NeedMP > Rrole[rnum].CurrentMP then break;

          if rmagic[Cmnum].EventNum > 0 then callevent(rmagic[Cmnum].EventNum)
          else AttackAction(bnum, Cmnum, cmlevel);


          l1 := Rrole[rnum].MagLevel[p] div 100;

          if Rmagic[Rrole[rnum].Magic[p]].MagicType <> 5 then Rrole[rnum].MagLevel[p] := Rrole[rnum].MagLevel[p] + 2;

          if Rrole[rnum].MagLevel[p] > 999 then Rrole[rnum].MagLevel[p] := 999;
          if (l1 < Rrole[rnum].MagLevel[p] div 100) and (Brole[bnum].Team = 0) then
          begin
            Rrole[rnum].Fist := min(Rrole[rnum].Fist + Rmagic[Rrole[rnum].Magic[p]].AddFist, 200);
            Rrole[rnum].Sword := min(Rrole[rnum].Sword + Rmagic[Rrole[rnum].Magic[p]].AddSword, 200);
            Rrole[rnum].Knife := min(Rrole[rnum].Knife + Rmagic[Rrole[rnum].Magic[p]].AddKnife, 200);
            Rrole[rnum].Unusual := min(Rrole[rnum].Unusual + Rmagic[Rrole[rnum].Magic[p]].AddUnusual, 200);
            if Rrole[rnum].MagLevel[i] div 100 >= 9 then
              if Rrole[rnum].PracticeBook >= 0 then
                if Ritem[Rrole[rnum].PracticeBook].Magic = Rrole[rnum].Magic[p] then
                begin
                  instruct_32(Rrole[rnum].PracticeBook, 1);
                  Rrole[rnum].PracticeBook := -1;
                  Rrole[rnum].ExpForBook := 0;
                end;
            redraw;
            DrawRectangle(220, 70 - 30, 200, 25, 0, colcolor(255), 25);
            words := UTF8Decode(' 升為' + IntToStr(Rrole[rnum].MagLevel[p] div 100 + 1) + '級');
            str1 := GBKtoUnicode(@words[1]);
            Drawshadowtext(@str1[1], 303, 72 - 30, colcolor($21), colcolor($23));
            Drawgbkshadowtext(@Rmagic[Rrole[rnum].Magic[p]].Name, 203, 72 - 30, colcolor($64), colcolor($66));
            SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            sdl_delay(50 * gamespeed);
            redraw;
            SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          end;
          ClearDeadRolePic;
        end;
      end;
    end;
  end;

  //暗器大于30找人打
  if (Brole[bnum].Acted = 0) and (GetRoleHidWeapon(rnum, True) >= 30) then
  begin
    if (Brole[bnum].Team <> 0) or ((Brole[bnum].Team = 0) and (Brole[bnum].Auto > 0)) then
    begin
      Mx1 := -1;
      Ax1 := -1;
      for h := 0 to 3 do
        if (Rrole[Brole[bnum].rnum].TakingItem[h] > -1) and
          (Rrole[Brole[bnum].rnum].TakingItemAmount[h] > 0) and
          (Ritem[Rrole[Brole[bnum].rnum].TakingItem[h]].ItemType = 4) then
        begin
          inum := Rrole[Brole[bnum].rnum].TakingItem[h];
          trymoveHidden(Mx1, My1, Ax1, Ay1, bnum, inum);
          if Ax1 <> -1 then
          begin
            //移动
            Ax := Mx1;
            Ay := My1;
            MoveAmination(bnum);
            //放暗器
            Ax := Ax1;
            Ay := Ay1;
            Hiddenaction(bnum, inum);
            //Brole[bnum].Acted := 1;
          end;
        end;
    end;
  end;



  //自身用毒大于20，寻找敌人放毒
  if (Brole[bnum].Acted = 0) and (GetRoleUsePoi(rnum, True) >= 20) and (rrole[rnum].PhyPower > 30) then
  begin
    if (Brole[bnum].Team <> 0) or (Brole[bnum].Team = 0) then
    begin
      Mx1 := -1;
      Ax1 := -1;
      trymoveUsepoi(Mx1, My1, Ax1, Ay1, bnum);
      if Ax1 <> -1 then
      begin
        //移动
        Ax := Mx1;
        Ay := My1;
        MoveAmination(bnum);

        //医疗
        Ax := Ax1;
        Ay := Ay1;
        Usepoiaction(bnum);
        //Brole[bnum].Acted := 1;
      end;
    end;
  end;

  //自身解毒大于20，寻找队友解毒
  if (Brole[bnum].Acted = 0) and (GetRoleMedPoi(rnum, True) >= 20) and (rrole[rnum].PhyPower > 50) then
  begin
    if (Brole[bnum].Team <> 0) or ((Brole[bnum].Team = 0) and (Brole[bnum].Auto > 0)) then
    begin
      Mx1 := -1;
      Ax1 := -1;
      trymoveMedpoi(Mx1, My1, Ax1, Ay1, bnum);
      if Ax1 <> -1 then
      begin
        //移动
        Ax := Mx1;
        Ay := My1;
        MoveAmination(bnum);

        //解毒
        Ax := Ax1;
        Ay := Ay1;
        Medpoiaction(bnum);
        //Brole[bnum].Acted := 1;
      end;
    end;
  end;


  //If all other actions fail, rest.
  //如果上面行动全部失败，则移动到离敌人最近的地方，休息
  if Brole[bnum].Acted = 0 then
  begin
    nearestmove(Mx, My, bnum);
    MoveAmination(bnum);
    Ax := Mx;
    Ay := My;
    if (BRole[bnum].Progress < 1200) and (battlemode > 0) then collect(bnum)
    else rest(bnum);
  end;

  //检查是否有esc被按下

  if (event.type_ = SDL_QUITEV) then
    if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then Quit;
  if (event.key.keysym.sym = sdlk_Escape) or (event.button.button = sdl_button_right) then
  begin
    brole[bnum].Auto := -1;
    event.key.keysym.sym := 0;
    event.button.button := 0;
  end;
end;

//尝试移动并攻击，step为最大移动步数
//武功已经事先选好，distance为武功距离，range为武功范围，AttAreaType为武功类型
//尝试每一个可以移动到的点，考察在该点攻击的情况，选择最合适的目标点

procedure trymoveattack(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; bnum, mnum, level: integer);
var
  Xlist: array[0..4096] of integer;
  Ylist: array[0..4096] of integer;
  steplist: array[0..4096] of integer;
  curgrid, totalgrid: integer;
  Bgrid: array[1..4] of integer; //0空位，1建筑，2友军，3敌军，4出界，5已走过
  Xinc, Yinc: array[1..4] of integer;
  curX, curY, curstep, nextX, nextY: integer;
  i, i1, i2, eneamount, aim: integer;
  tempX, tempY, tempdis: integer;
  step, distance, range, AttAreaType, myteam: integer;
begin
  step := brole[bnum].Step;
  distance := rmagic[mnum].MoveDistance[level - 1];
  if CheckEquipSet(Rrole[Brole[bnum].rnum].equip[0], Rrole[Brole[bnum].rnum].equip[1],
    Rrole[Brole[bnum].rnum].equip[2], Rrole[Brole[bnum].rnum].equip[3]) = 1 then
    Inc(distance, 1);
  if GetEquipState(Brole[bnum].rnum, 22) or GetGongtiState(Brole[bnum].rnum, 22) then //增加攻击距离
    Inc(distance, 1);

  range := rmagic[mnum].AttDistance[level - 1];
  AttAreaType := rmagic[mnum].AttAreaType;
  myteam := brole[bnum].Team;

  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
      Bfield[3, i1, i2] := -1;
  Bfield[3, Brole[bnum].X, Brole[bnum].Y] := 0;
  Mx1 := -1;
  My1 := -1;
  Xinc[1] := 1;
  Xinc[2] := -1;
  Xinc[3] := 0;
  Xinc[4] := 0;
  Yinc[1] := 0;
  Yinc[2] := 0;
  Yinc[3] := 1;
  Yinc[4] := -1;
  curgrid := 0;
  totalgrid := 0;
  Xlist[totalgrid] := Bx;
  Ylist[totalgrid] := By;
  steplist[totalgrid] := 0;
  totalgrid := totalgrid + 1;
  while curgrid < totalgrid do
  begin
    curX := Xlist[curgrid];
    curY := Ylist[curgrid];

    //根据武功类型不同，分别计算
    case AttAreaType of
      0:
        calpoint(Mx1, My1, Ax1, Ay1, tempmaxhurt, curX, curY, bnum, mnum, level);
      1:
        calline(Mx1, My1, Ax1, Ay1, tempmaxhurt, curX, curY, bnum, mnum, level);
      2:
        calcross(Mx1, My1, Ax1, Ay1, tempmaxhurt, curX, curY, bnum, mnum, level);
      3:
        calarea(Mx1, My1, Ax1, Ay1, tempmaxhurt, curX, curY, bnum, mnum, level);
      4:
        caldirdiamond(Mx1, My1, Ax1, Ay1, tempmaxhurt, curX, curY, bnum, mnum, level);
      5:
        caldirangle(Mx1, My1, Ax1, Ay1, tempmaxhurt, curX, curY, bnum, mnum, level);
      6:
        calfar(Mx1, My1, Ax1, Ay1, tempmaxhurt, curX, curY, bnum, mnum, level);
      7:
        calNewLine(Mx1, My1, Ax1, Ay1, tempmaxhurt, curX, curY, bnum, mnum, level);

    end;

    curstep := steplist[curgrid];
    if curstep < step then
    begin
      //判断当前点四周格子的状况
      for i := 1 to 4 do
      begin
        nextX := curX + Xinc[i];
        nextY := curY + Yinc[i];
        if (nextX < 0) or (nextX > 63) or (nextY < 0) or (nextY > 63) then
          Bgrid[i] := 4
        else if Bfield[3, nextX, nextY] >= 0 then
          Bgrid[i] := 5
        else if Bfield[1, nextX, nextY] > 0 then
          Bgrid[i] := 1
        else if Bfield[2, nextX, nextY] >= 0 then
        begin
          if BRole[Bfield[2, nextX, nextY]].Team = myteam then
            Bgrid[i] := 2
          else
            Bgrid[i] := 3;
        end
        else if ((Bfield[0, nextX, nextY] div 2 >= 179) and (Bfield[0, nextX, nextY] div 2 <= 190)) or
          (Bfield[0, nextX, nextY] div 2 = 261) or (Bfield[0, nextX, nextY] div 2 = 511) or
          ((Bfield[0, nextX, nextY] div 2 >= 224) and (Bfield[0, nextX, nextY] div 2 <= 232)) or
          ((Bfield[0, nextX, nextY] div 2 >= 662) and (Bfield[0, nextX, nextY] div 2 <= 674)) then
          Bgrid[i] := 6
        else
          Bgrid[i] := 0;
      end;

      if (curstep = 0) or ((Bgrid[1] <> 3) and (Bgrid[2] <> 3) and (Bgrid[3] <> 3) and (Bgrid[4] <> 3)) then
      begin
        for i := 1 to 4 do
        begin
          if Bgrid[i] = 0 then
          begin
            Xlist[totalgrid] := curX + Xinc[i];
            Ylist[totalgrid] := curY + Yinc[i];
            steplist[totalgrid] := curstep + 1;
            Bfield[3, Xlist[totalgrid], Ylist[totalgrid]] := steplist[totalgrid];
            totalgrid := totalgrid + 1;
          end;
        end;
      end;

    end;
    curgrid := curgrid + 1;
  end;

  //无论怎样移动，也无法攻击到敌人，则随机选择一个敌人，并向他移动
 { if (Mx1=-1) and (tempmaxhurt=0) then
  begin
    //不攻击
    Ax1:=-1;

    //在敌方随机选择一个人物
    eneamount := Calrnum(1 - myteam);
    aim := random(eneamount) + 1;
    //showmessage(inttostr(eneamount));
    for i := 0 to length(brole) - 1 do
    begin
      if (myteam <> Brole[i].Team) and (Brole[i].Dead = 0) then
      begin
        aim := aim - 1;
        if aim <= 0 then break;
      end;
    end;

    //把移动目标点设在到离目标人物最近的地方
    nextX:=Brole[i].X;
    nextY:=Brole[i].Y;
    tempdis:=abs(nextX-Bx)+abs(nextY-By);
    for curgrid := totalgrid-1 downto 0 do
      begin
        tempX:=Xlist[curgrid];
        tempY:=Ylist[curgrid];
        if abs(nextX-tempX)+abs(nextY-tempY)<tempdis then
        begin
          Mx:=tempX;
          My:=tempY;
          tempdis:=abs(nextX-tempX)+abs(nextY-tempY);
        end;
      end;

  end;    }
end;

//线型攻击的情况，分四个方向考虑，分别计算伤血量

procedure calline(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; curX, curY, bnum, mnum, level: integer);
var
  i, tempX, tempY, ebnum, rnum, tempHP, temphurt: integer;
  distance, range, AttAreaType, myteam: integer;
begin
  distance := rmagic[mnum].MoveDistance[level - 1];
  if CheckEquipSet(Rrole[brole[bnum].rnum].equip[0], Rrole[brole[bnum].rnum].equip[1],
    Rrole[brole[bnum].rnum].equip[2], Rrole[brole[bnum].rnum].equip[3]) = 1 then
    Inc(distance, 1);
  if GetEquipState(Brole[bnum].rnum, 22) or GetGongtiState(Brole[bnum].rnum, 22) then //增加攻击距离
    Inc(distance, 1);

  range := rmagic[mnum].AttDistance[level - 1];
  AttAreaType := rmagic[mnum].AttAreaType;
  myteam := brole[bnum].Team;

  temphurt := 0;
  for i := curX - 1 downto curX - distance do
  begin
    ebnum := Bfield[2, i, curY];
    if (ebnum >= 0) and (Brole[ebnum].Dead = 0) and (Brole[ebnum].Team <> myteam) then
    begin
      temphurt := temphurt + CalHurtValue(bnum, ebnum, mnum, level);
    end;
  end;
  if temphurt > tempmaxhurt then
  begin
    tempmaxhurt := temphurt;
    Mx1 := curX;
    My1 := curY;
    Ax1 := curX - 1;
    Ay1 := curY;
  end;

  temphurt := 0;
  for i := curX + 1 to curX + distance do
  begin
    ebnum := Bfield[2, i, curY];
    if (ebnum >= 0) and (Brole[ebnum].Dead = 0) and (Brole[ebnum].Team <> myteam) then
    begin
      temphurt := temphurt + CalHurtValue(bnum, ebnum, mnum, level);
    end;
  end;
  if temphurt > tempmaxhurt then
  begin
    tempmaxhurt := temphurt;
    Mx1 := curX;
    My1 := curY;
    Ax1 := curX + 1;
    Ay1 := curY;
  end;

  temphurt := 0;
  for i := curY - 1 downto curY - distance do
  begin
    ebnum := Bfield[2, curX, i];
    if (ebnum >= 0) and (Brole[ebnum].Dead = 0) and (Brole[ebnum].Team <> myteam) then
    begin
      temphurt := temphurt + CalHurtValue(bnum, ebnum, mnum, level);
    end;
  end;
  if temphurt > tempmaxhurt then
  begin
    tempmaxhurt := temphurt;
    Mx1 := curX;
    My1 := curY;
    Ax1 := curX;
    Ay1 := curY - 1;
  end;

  temphurt := 0;
  for i := curY + 1 to curY + distance do
  begin
    ebnum := Bfield[2, curX, i];
    if (ebnum >= 0) and (Brole[ebnum].Dead = 0) and (Brole[ebnum].Team <> myteam) then
    begin
      temphurt := temphurt + CalHurtValue(bnum, ebnum, mnum, level);
    end;
  end;
  if temphurt > tempmaxhurt then
  begin
    tempmaxhurt := temphurt;
    Mx1 := curX;
    My1 := curY;
    Ax1 := curX;
    Ay1 := curY + 1;
  end;
end;

//无定向方向

procedure calNewline(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; curX, curY, bnum, mnum, level: integer);
var
  i, j, k, m, n, tempX, tempY, temphurt: integer;
  distance, range, AttAreaType, myteam: integer;
begin
  distance := rmagic[mnum].MoveDistance[level - 1];
  if CheckEquipSet(Rrole[Brole[bnum].rnum].equip[0], Rrole[Brole[bnum].rnum].equip[1],
    Rrole[Brole[bnum].rnum].equip[2], Rrole[Brole[bnum].rnum].equip[3]) = 1 then
    Inc(distance, 1);
  if GetEquipState(Brole[bnum].rnum, 22) or GetGongtiState(Brole[bnum].rnum, 22) then //增加攻击距离
    Inc(distance, 1);

  range := rmagic[mnum].AttDistance[level - 1];
  AttAreaType := rmagic[mnum].AttAreaType;
  myteam := brole[bnum].Team;

  for i := curX - distance to curX + distance do
  begin
    m := (distance - sign(i - curX) * (i - curX));
    for j := curY - m to curY + m do
    begin
      temphurt := 0;
      for k := 0 to length(brole) - 1 do
      begin
        if (myteam <> Brole[k].Team) and (Brole[k].rnum >= 0) and (Brole[k].Dead = 0) then
        begin
          tempX := Brole[k].X;
          tempY := Brole[k].Y;
          if (abs(tempX - curX) + abs(tempY - cury) <= distance) then
          begin
            if ((abs(tempX - curX) <= abs(i - curX)) and (abs(tempY - cury) <= abs(j - cury))) then
            begin
              if (abs(i - curX) > abs(j - cury)) and (((tempX - curx) / (i - curx)) > 0) and
                (tempY = Round(((tempX - curx) * (j - cury)) / (i - curx)) + cury) then
                temphurt := temphurt + CalHurtValue(bnum, k, mnum, level)

              else if (abs(i - curX) < abs(j - cury)) and (((tempy - cury) / (j - cury)) > 0) and
                (tempx = Round(((tempy - cury) * (i - curx)) / (j - cury)) + curx) then
                temphurt := temphurt + CalHurtValue(bnum, k, mnum, level);
            end;
          end;
          if temphurt > tempmaxhurt then
          begin
            Ax1 := i;
            Ay1 := j;
            Mx1 := curX;
            My1 := curY;
            tempmaxhurt := temphurt;
          end;
        end;
      end;
    end;
  end;
end;

//方向系菱型

procedure caldirdiamond(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; curX, curY, bnum, mnum, level: integer);
var
  i, tempX, tempY: integer;
  temphurt: array[1..4] of integer;
  distance, range, AttAreaType, myteam: integer;
begin
  distance := rmagic[mnum].MoveDistance[level - 1];
  range := rmagic[mnum].AttDistance[level - 1];
  if CheckEquipSet(Rrole[Brole[bnum].rnum].equip[0], Rrole[Brole[bnum].rnum].equip[1],
    Rrole[Brole[bnum].rnum].equip[2], Rrole[Brole[bnum].rnum].equip[3]) = 1 then
    Inc(distance, 1);
  if GetEquipState(Brole[bnum].rnum, 22) or GetGongtiState(Brole[bnum].rnum, 22) then //增加攻击距离
    Inc(distance, 1);

  AttAreaType := rmagic[mnum].AttAreaType;
  myteam := brole[bnum].Team;

  temphurt[1] := 0;
  temphurt[2] := 0;
  temphurt[3] := 0;
  temphurt[4] := 0;

  for i := 0 to length(brole) - 1 do
  begin
    if (myteam <> Brole[i].Team) and (Brole[i].Dead = 0) and (Brole[i].rnum >= 0) then
    begin
      tempX := Brole[i].X;
      tempY := Brole[i].Y;
      if (abs(tempX - curX) + abs(tempY - curY) <= distance) and (abs(tempX - curX) <> abs(tempY - curY)) then
      begin
        if (tempX - curX > 0) and (abs(tempX - curX) > abs(tempY - curY)) then
        begin
          temphurt[1] := temphurt[1] + CalHurtValue(bnum, i, mnum, level);
        end
        else
        if (tempX - curX < 0) and (abs(tempX - curX) > abs(tempY - curY)) then
        begin
          temphurt[2] := temphurt[2] + CalHurtValue(bnum, i, mnum, level);
        end
        else
        if (tempY - curY > 0) and (abs(tempX - curX) < abs(tempY - curY)) then
        begin
          temphurt[3] := temphurt[3] + CalHurtValue(bnum, i, mnum, level);
        end
        else
        if (tempY - curY < 0) and (abs(tempX - curX) < abs(tempY - curY)) then
        begin
          temphurt[4] := temphurt[4] + CalHurtValue(bnum, i, mnum, level);
        end;
      end;
    end;
  end;

  if temphurt[1] > tempmaxhurt then
  begin
    tempmaxhurt := temphurt[1];
    Mx1 := curX;
    My1 := curY;
    Ax1 := curX + 1;
    Ay1 := curY;
  end;
  if temphurt[2] > tempmaxhurt then
  begin
    tempmaxhurt := temphurt[2];
    Mx1 := curX;
    My1 := curY;
    Ax1 := curX - 1;
    Ay1 := curY;
  end;
  if temphurt[3] > tempmaxhurt then
  begin
    tempmaxhurt := temphurt[3];
    Mx1 := curX;
    My1 := curY;
    Ax1 := curX;
    Ay1 := curY + 1;
  end;
  if temphurt[4] > tempmaxhurt then
  begin
    tempmaxhurt := temphurt[4];
    Mx1 := curX;
    My1 := curY;
    Ax1 := curX;
    Ay1 := curY - 1;
  end;
end;

//方向系角型

procedure caldirangle(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; curX, curY, bnum, mnum, level: integer);
var
  i, tempX, tempY: integer;
  temphurt: array[1..4] of integer;
  distance, range, AttAreaType, myteam: integer;
begin
  distance := rmagic[mnum].MoveDistance[level - 1];
  if CheckEquipSet(Rrole[Brole[bnum].rnum].equip[0], Rrole[Brole[bnum].rnum].equip[1],
    Rrole[Brole[bnum].rnum].equip[2], Rrole[Brole[bnum].rnum].equip[3]) = 1 then
    Inc(distance, 1);
  if GetEquipState(Brole[bnum].rnum, 22) or GetGongtiState(Brole[bnum].rnum, 22) then //增加攻击距离
    Inc(distance, 1);

  range := rmagic[mnum].AttDistance[level - 1];
  AttAreaType := rmagic[mnum].AttAreaType;
  myteam := brole[bnum].Team;

  temphurt[1] := 0;
  temphurt[2] := 0;
  temphurt[3] := 0;
  temphurt[4] := 0;

  for i := 0 to length(brole) - 1 do
  begin
    if (myteam <> Brole[i].Team) and (brole[i].rnum >= 0) and (Brole[i].Dead = 0) then
    begin
      tempX := Brole[i].X;
      tempY := Brole[i].Y;
      if (abs(tempX - curX) <= distance) and (abs(tempY - curY) <= distance) and
        (abs(tempX - curX) <> abs(tempY - curY)) then
      begin
        if (tempX - curX > 0) and (abs(tempX - curX) > abs(tempY - curY)) then
        begin
          temphurt[1] := temphurt[1] + CalHurtValue(bnum, i, mnum, level);
        end
        else
        if (tempX - curX < 0) and (abs(tempX - curX) > abs(tempY - curY)) then
        begin
          temphurt[2] := temphurt[2] + CalHurtValue(bnum, i, mnum, level);
        end
        else
        if (tempY - curY > 0) and (abs(tempX - curX) < abs(tempY - curY)) then
        begin
          temphurt[3] := temphurt[3] + CalHurtValue(bnum, i, mnum, level);
        end
        else
        if (tempY - curY < 0) and (abs(tempX - curX) < abs(tempY - curY)) then
        begin
          temphurt[4] := temphurt[4] + CalHurtValue(bnum, i, mnum, level);
        end;
      end;
    end;
  end;

  if temphurt[1] > tempmaxhurt then
  begin
    tempmaxhurt := temphurt[1];
    Mx1 := curX;
    My1 := curY;
    Ax1 := curX + 1;
    Ay1 := curY;
  end;
  if temphurt[2] > tempmaxhurt then
  begin
    tempmaxhurt := temphurt[2];
    Mx1 := curX;
    My1 := curY;
    Ax1 := curX - 1;
    Ay1 := curY;
  end;
  if temphurt[3] > tempmaxhurt then
  begin
    tempmaxhurt := temphurt[3];
    Mx1 := curX;
    My1 := curY;
    Ax1 := curX;
    Ay1 := curY + 1;
  end;
  if temphurt[4] > tempmaxhurt then
  begin
    tempmaxhurt := temphurt[4];
    Mx1 := curX;
    My1 := curY;
    Ax1 := curX;
    Ay1 := curY - 1;
  end;
end;

//目标系方、原地系方

procedure calarea(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; curX, curY, bnum, mnum, level: integer);
var
  i, j, k, m, n, tempX, tempY, temphurt: integer;
  distance, range, AttAreaType, myteam: integer;
begin
  distance := rmagic[mnum].MoveDistance[level - 1];
  if CheckEquipSet(Rrole[Brole[bnum].rnum].equip[0], Rrole[Brole[bnum].rnum].equip[1],
    Rrole[Brole[bnum].rnum].equip[2], Rrole[Brole[bnum].rnum].equip[3]) = 1 then
    Inc(distance, 1);
  if GetEquipState(Brole[bnum].rnum, 22) or GetGongtiState(Brole[bnum].rnum, 22) then //增加攻击距离
    Inc(distance, 1);

  range := rmagic[mnum].AttDistance[level - 1];
  AttAreaType := rmagic[mnum].AttAreaType;
  myteam := brole[bnum].Team;

  for i := curX - distance to curX + distance do
  begin
    m := (distance - sign(i - curX) * (i - curX));
    for j := curY - m to curY + m do
    begin
      temphurt := 0;
      for k := 0 to length(brole) - 1 do
      begin
        if (myteam <> Brole[k].Team) and (Brole[k].rnum >= 0) and (Brole[k].Dead = 0) then
        begin
          tempX := Brole[k].X;
          tempY := Brole[k].Y;
          if (abs(tempX - i) <= range) and (abs(tempY - j) <= range) then
          begin
            temphurt := temphurt + CalHurtValue(bnum, k, mnum, level);
          end;
        end;
      end;
      if temphurt > tempmaxhurt then
      begin
        Ax1 := i;
        Ay1 := j;
        Mx1 := curX;
        My1 := curY;
        tempmaxhurt := temphurt;
      end;
    end;
  end;
end;

//目标系点十菱，原地系菱

procedure calpoint(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; curX, curY, bnum, mnum, level: integer);
var
  i, j, k, m, n, tempX, tempY, temphurt, ebnum, ernum, tempHP: integer;
  distance, range, AttAreaType, myteam: integer;
begin
  distance := rmagic[mnum].MoveDistance[level - 1];
  if CheckEquipSet(Rrole[Brole[bnum].rnum].equip[0], Rrole[Brole[bnum].rnum].equip[1],
    Rrole[Brole[bnum].rnum].equip[2], Rrole[Brole[bnum].rnum].equip[3]) = 1 then
    Inc(distance, 1);
  if GetEquipState(Brole[bnum].rnum, 22) or GetGongtiState(Brole[bnum].rnum, 22) then //增加攻击距离
    Inc(distance, 1);

  range := rmagic[mnum].AttDistance[level - 1];
  AttAreaType := rmagic[mnum].AttAreaType;
  myteam := brole[bnum].Team;

  for i := curX - distance to curX + distance do
  begin
    m := (distance - sign(i - curX) * (i - curX));
    for j := curY - m to curY + m do
    begin
      temphurt := 0;
      for k := 0 to length(brole) - 1 do
      begin
        if (myteam <> Brole[k].Team) and (Brole[k].rnum >= 0) and (Brole[k].Dead = 0) then
        begin
          tempX := Brole[k].X;
          tempY := Brole[k].Y;
          if abs(tempX - i) + abs(tempY - j) <= range then
          begin
            temphurt := temphurt + CalHurtValue(bnum, k, mnum, level);
          end;
        end;
      end;
      if temphurt > tempmaxhurt then
      begin
        Ax1 := i;
        Ay1 := j;
        Mx1 := curX;
        My1 := curY;
        tempmaxhurt := temphurt;
      end;
    end;
  end;
end;

//原地系十叉米

procedure calcross(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; curX, curY, bnum, mnum, level: integer);
var
  i, tempX, tempY, temphurt, ebnum, rnum: integer;
  distance, range, AttAreaType, myteam: integer;
begin
  distance := rmagic[mnum].MoveDistance[level - 1];
  if CheckEquipSet(Rrole[brole[bnum].rnum].equip[0], Rrole[brole[bnum].rnum].equip[1],
    Rrole[brole[bnum].rnum].equip[2], Rrole[brole[bnum].rnum].equip[3]) = 1 then
    Inc(distance, 1);
  if GetEquipState(Brole[bnum].rnum, 22) or GetGongtiState(Brole[bnum].rnum, 22) then //增加攻击距离
    Inc(distance, 1);

  range := rmagic[mnum].AttDistance[level - 1];
  AttAreaType := rmagic[mnum].AttAreaType;
  myteam := brole[bnum].Team;

  temphurt := 0;
  for i := -range to range do
  begin
    ebnum := Bfield[2, curX + i, curY + i];
    if (ebnum >= 0) and (Brole[ebnum].Dead = 0) and (Brole[ebnum].Team <> myteam) then
    begin
      temphurt := temphurt + CalHurtValue(bnum, ebnum, mnum, level);
    end;
  end;

  for i := -range to range do
  begin
    bnum := Bfield[2, curX + i, curY - i];
    if (bnum >= 0) and (Brole[bnum].Dead = 0) and (Brole[bnum].Team <> myteam) then
    begin
      temphurt := temphurt + CalHurtValue(bnum, ebnum, mnum, level);
    end;
  end;

  for i := curX - distance to curX + distance do
  begin
    bnum := Bfield[2, i, curY];
    if (bnum >= 0) and (Brole[bnum].Dead = 0) and (Brole[bnum].Team <> myteam) then
    begin
      temphurt := temphurt + CalHurtValue(bnum, ebnum, mnum, level);
    end;
  end;

  for i := curY - distance to curY + distance do
  begin
    bnum := Bfield[2, curX, i];
    if (bnum >= 0) and (Brole[bnum].Dead = 0) and (Brole[bnum].Team <> myteam) then
    begin
      temphurt := temphurt + CalHurtValue(bnum, ebnum, mnum, level);
    end;
  end;

  if temphurt > tempmaxhurt then
  begin
    tempmaxhurt := temphurt;
    Mx1 := curX;
    My1 := curY;
    Ax1 := curX;
    Ay1 := curY;
  end;
end;

//远程系

procedure calfar(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; curX, curY, bnum, mnum, level: integer);
var
  i, j, k, m, n, tempX, tempY, temphurt: integer;
  minstep: integer;
  distance, range, AttAreaType, myteam: integer;
begin
  distance := rmagic[mnum].MoveDistance[level - 1];
  if CheckEquipSet(Rrole[Brole[bnum].rnum].equip[0], Rrole[Brole[bnum].rnum].equip[1],
    Rrole[Brole[bnum].rnum].equip[2], Rrole[Brole[bnum].rnum].equip[3]) = 1 then
    Inc(distance, 1);
  if GetEquipState(Brole[bnum].rnum, 22) or GetGongtiState(Brole[bnum].rnum, 22) then //增加攻击距离
    Inc(distance, 1);

  range := rmagic[mnum].AttDistance[level - 1];
  AttAreaType := rmagic[mnum].AttAreaType;
  myteam := brole[bnum].Team;
  minstep := rmagic[mnum].MinStep;

  for i := curX - distance to curX + distance do
  begin
    m := (distance - sign(i - curX) * (i - curX));
    for j := curY - m to curY + m do
    begin
      if abs(j - curY) + abs(i - curX) <= minstep then continue;
      temphurt := 0;
      for k := 0 to length(brole) - 1 do
      begin
        if (myteam <> Brole[k].Team) and (Brole[k].rnum >= 0) and (Brole[k].Dead = 0) then
        begin
          tempX := Brole[k].X;
          tempY := Brole[k].Y;
          if abs(tempX - i) + abs(tempY - j) <= range then
          begin
            temphurt := temphurt + CalHurtValue(bnum, k, mnum, level);
          end;
        end;
      end;
      if temphurt > tempmaxhurt then
      begin
        Ax1 := i;
        Ay1 := j;
        Mx1 := curX;
        My1 := curY;
        tempmaxhurt := temphurt;
      end;
    end;
  end;
end;

//移动到离最近的敌人最近的地方

procedure nearestmove(var Mx, My: integer; bnum: integer);
var
  i, i1, i2, tempdis, mindis: integer;
  aimX, aimY: integer;
  step, myteam: integer;

  Xlist: array[0..4096] of integer;
  Ylist: array[0..4096] of integer;
  steplist: array[0..4096] of integer;
  curgrid, totalgrid: integer;
  Bgrid: array[1..4] of integer; //0空位，1建筑，2友军，3敌军，4出界，5已走过
  Xinc, Yinc: array[1..4] of integer;
  curX, curY, curstep, nextX, nextY: integer;

begin
  myteam := brole[bnum].Team;
  mindis := 9999;

  //选择一个最近的敌人
  for i := 0 to length(brole) - 1 do
  begin
    if (myteam <> Brole[i].Team) and (brole[i].rnum >= 0) and (Brole[i].Dead = 0) then
    begin
      tempdis := abs(Brole[i].X - Bx) + abs(Brole[i].Y - By);
      if tempdis < mindis then
      begin
        mindis := tempdis;
        aX := Brole[i].X;
        aY := Brole[i].Y;
      end;
    end;
  end;

  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
      Bfield[3, i1, i2] := -1;
  Bfield[3, Brole[bnum].X, Brole[bnum].Y] := 0;

  step := brole[bnum].Step;
  Mx := Bx;
  My := By;
  Xinc[1] := 1;
  Xinc[2] := -1;
  Xinc[3] := 0;
  Xinc[4] := 0;
  Yinc[1] := 0;
  Yinc[2] := 0;
  Yinc[3] := 1;
  Yinc[4] := -1;
  curgrid := 0;
  totalgrid := 0;
  Xlist[totalgrid] := Bx;
  Ylist[totalgrid] := By;
  steplist[totalgrid] := 0;
  totalgrid := totalgrid + 1;
  while curgrid < totalgrid do
  begin
    curX := Xlist[curgrid];
    curY := Ylist[curgrid];
    curstep := steplist[curgrid];

    //判断当前点四周格子的状况
    for i := 1 to 4 do
    begin
      nextX := curX + Xinc[i];
      nextY := curY + Yinc[i];
      if (nextX < 0) or (nextX > 63) or (nextY < 0) or (nextY > 63) then
        Bgrid[i] := 4
      else if Bfield[3, nextX, nextY] >= 0 then
        Bgrid[i] := 5
      else if Bfield[1, nextX, nextY] > 0 then
        Bgrid[i] := 1
      else if Bfield[2, nextX, nextY] >= 0 then
      begin
        if BRole[Bfield[2, nextX, nextY]].Team = myteam then
          Bgrid[i] := 2
        else
          Bgrid[i] := 3;
      end
      else if ((Bfield[0, nextX, nextY] div 2 >= 179) and (Bfield[0, nextX, nextY] div 2 <= 190)) or
        (Bfield[0, nextX, nextY] div 2 = 261) or (Bfield[0, nextX, nextY] div 2 = 511) or
        ((Bfield[0, nextX, nextY] div 2 >= 224) and (Bfield[0, nextX, nextY] div 2 <= 232)) or
        ((Bfield[0, nextX, nextY] div 2 >= 662) and (Bfield[0, nextX, nextY] div 2 <= 674)) then
        Bgrid[i] := 6
      else
        Bgrid[i] := 0;
    end;


    for i := 1 to 4 do
    begin
      if (Bgrid[i] = 0) then
      begin
        Xlist[totalgrid] := curX + Xinc[i];
        Ylist[totalgrid] := curY + Yinc[i];
        steplist[totalgrid] := curstep + 1;
        Bfield[3, Xlist[totalgrid], Ylist[totalgrid]] := steplist[totalgrid];
        totalgrid := totalgrid + 1;
      end;
    end;
    curgrid := curgrid + 1;
  end;
  aimX := AX;
  aimY := Ay;
  mindis := 9999;
  for i := 1 to 4 do
  begin
    i1 := AX + Xinc[i];
    i2 := AY + Yinc[i];
    tempdis := Bfield[3, i1, i2];
    if (tempdis > 0) and (mindis > tempdis) then
    begin
      mindis := tempdis;
      aimX := i1;
      aimy := i2;
    end;
  end;
  Ax := aimX;
  AY := aimY;
end;

//移动到离敌人最远的地方（与每一个敌人的距离之和最大）

procedure farthestmove(var Mx, My: integer; bnum: integer);
var
  i, i1, i2, k, tempdis, maxdis: integer;
  aimX, aimY: integer;
  step, myteam: integer;

  Xlist: array[0..4096] of integer;
  Ylist: array[0..4096] of integer;
  steplist: array[0..4096] of integer;
  curgrid, totalgrid: integer;
  Bgrid: array[1..4] of integer; //0空位，1建筑，2友军，3敌军，4出界，5已走过
  Xinc, Yinc: array[1..4] of integer;
  curX, curY, curstep, nextX, nextY: integer;

begin
  step := brole[bnum].Step;
  myteam := brole[bnum].Team;
  maxdis := 0;

  Mx := Bx;
  My := By;
  Xinc[1] := 1;
  Xinc[2] := -1;
  Xinc[3] := 0;
  Xinc[4] := 0;
  Yinc[1] := 0;
  Yinc[2] := 0;
  Yinc[3] := 1;
  Yinc[4] := -1;
  curgrid := 0;
  totalgrid := 0;
  Xlist[totalgrid] := Bx;
  Ylist[totalgrid] := By;
  steplist[totalgrid] := 0;
  totalgrid := totalgrid + 1;

  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
      Bfield[3, i1, i2] := -1;
  Bfield[3, Brole[bnum].X, Brole[bnum].Y] := 0;

  while curgrid < totalgrid do
  begin
    curX := Xlist[curgrid];
    curY := Ylist[curgrid];
    tempdis := 0;
    for k := 0 to length(brole) - 1 do
    begin
      if (brole[k].Team <> myteam) and (brole[k].rnum >= 0) and (brole[k].Dead = 0) then
        tempdis := tempdis + abs(curX - brole[k].X) + abs(curY - brole[k].Y);
    end;
    if tempdis > maxdis then
    begin
      maxdis := tempdis;
      Mx := curX;
      My := curY;
    end;

    curstep := steplist[curgrid];
    if curstep < step then
    begin
      //判断当前点四周格子的状况
      for i := 1 to 4 do
      begin
        nextX := curX + Xinc[i];
        nextY := curY + Yinc[i];
        if (nextX < 0) or (nextX > 63) or (nextY < 0) or (nextY > 63) then
          Bgrid[i] := 4
        else if Bfield[3, nextX, nextY] >= 0 then
          Bgrid[i] := 5
        else if Bfield[1, nextX, nextY] > 0 then
          Bgrid[i] := 1
        else if Bfield[2, nextX, nextY] >= 0 then
        begin
          if BRole[Bfield[2, nextX, nextY]].Team = myteam then
            Bgrid[i] := 2
          else
            Bgrid[i] := 3;
        end
        else if ((Bfield[0, nextX, nextY] div 2 >= 179) and (Bfield[0, nextX, nextY] div 2 <= 190)) or
          (Bfield[0, nextX, nextY] div 2 = 261) or (Bfield[0, nextX, nextY] div 2 = 511) or
          ((Bfield[0, nextX, nextY] div 2 >= 224) and (Bfield[0, nextX, nextY] div 2 <= 232)) or
          ((Bfield[0, nextX, nextY] div 2 >= 662) and (Bfield[0, nextX, nextY] div 2 <= 674)) then
          Bgrid[i] := 6
        else

          Bgrid[i] := 0;
      end;

      if (curstep = 0) or ((Bgrid[1] <> 3) and (Bgrid[2] <> 3) and (Bgrid[3] <> 3) and (Bgrid[4] <> 3)) then
      begin
        for i := 1 to 4 do
        begin
          if Bgrid[i] = 0 then
          begin
            Xlist[totalgrid] := curX + Xinc[i];
            Ylist[totalgrid] := curY + Yinc[i];
            steplist[totalgrid] := curstep + 1;
            Bfield[3, Xlist[totalgrid], Ylist[totalgrid]] := steplist[totalgrid];
            totalgrid := totalgrid + 1;
          end;
        end;
      end;

    end;
    curgrid := curgrid + 1;
  end;
end;

//在可医疗范围内，寻找生命不足一半的生命最少的友军，

procedure trymovecure(var Mx1, My1, Ax1, Ay1: integer; bnum: integer);
var
  Xlist: array[0..4096] of integer;
  Ylist: array[0..4096] of integer;
  steplist: array[0..4096] of integer;
  curgrid, totalgrid: integer;
  Bgrid: array[1..4] of integer; //0空位，1建筑，2友军，3敌军，4出界，5已走过,6水面
  Xinc, Yinc: array[1..4] of integer;
  curX, curY, curstep, nextX, nextY: integer;
  i, i1, i2, eneamount, aim: integer;
  tempX, tempY, tempdis: integer;
  step, myteam, curedis, rnum: integer;
  tempminHP: integer;

begin
  step := brole[bnum].Step;
  myteam := brole[bnum].Team;
  curedis := GetRoleMedcine(brole[bnum].rnum, True) div 15 + 1;

  tempminHP := MAX_HP;

  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
      Bfield[3, i1, i2] := -1;
  Bfield[3, Brole[bnum].X, Brole[bnum].Y] := 0;

  Xinc[1] := 1;
  Xinc[2] := -1;
  Xinc[3] := 0;
  Xinc[4] := 0;
  Yinc[1] := 0;
  Yinc[2] := 0;
  Yinc[3] := 1;
  Yinc[4] := -1;
  curgrid := 0;
  totalgrid := 0;
  Xlist[totalgrid] := Bx;
  Ylist[totalgrid] := By;
  steplist[totalgrid] := 0;
  totalgrid := totalgrid + 1;
  while curgrid < totalgrid do
  begin
    curX := Xlist[curgrid];
    curY := Ylist[curgrid];

    for i := 0 to length(brole) - 1 do
    begin
      rnum := brole[i].rnum;
      if (brole[i].Team = myteam) and (brole[i].rnum >= 0) and (brole[i].dead = 0) and
        (abs(brole[i].X - curX) + abs(brole[i].Y - curY) < curedis) and (rrole[rnum].CurrentHP < rrole[rnum].MaxHP div 2) then
      begin
        if Rrole[rnum].Hurt - GetRoleMedcine(rnum, True) <= 20 then
        begin
          if (GetRoleMedcine(brole[bnum].rnum, True) * (10 - Rrole[rnum].Hurt div 15) div 10) < tempminHP then
          begin
            tempminHP := GetRoleMedcine(brole[bnum].rnum, True) * (10 - Rrole[rnum].Hurt div 15) div 10;
            Mx1 := curX;
            My1 := curY;
            Ax1 := brole[i].X;
            Ay1 := brole[i].Y;
          end;
        end;
      end;
    end;

    curstep := steplist[curgrid];
    if curstep < step then
    begin
      //判断当前点四周格子的状况
      for i := 1 to 4 do
      begin
        nextX := curX + Xinc[i];
        nextY := curY + Yinc[i];
        if (nextX < 0) or (nextX > 63) or (nextY < 0) or (nextY > 63) then
          Bgrid[i] := 4
        else if Bfield[3, nextX, nextY] >= 0 then
          Bgrid[i] := 5
        else if Bfield[1, nextX, nextY] > 0 then
          Bgrid[i] := 1
        else if ((Bfield[0, nextX, nextY] div 2 >= 179) and (Bfield[0, nextX, nextY] div 2 <= 190)) or
          (Bfield[0, nextX, nextY] div 2 = 261) or (Bfield[0, nextX, nextY] div 2 = 511) or
          ((Bfield[0, nextX, nextY] div 2 >= 224) and (Bfield[0, nextX, nextY] div 2 <= 232)) or
          ((Bfield[0, nextX, nextY] div 2 >= 662) and (Bfield[0, nextX, nextY] div 2 <= 674)) then
          Bgrid[i] := 6
        else if Bfield[2, nextX, nextY] >= 0 then
        begin
          if BRole[Bfield[2, nextX, nextY]].Team = myteam then
            Bgrid[i] := 2
          else
            Bgrid[i] := 3;
        end
        else
          Bgrid[i] := 0;
      end;

      if (curstep = 0) or ((Bgrid[1] <> 3) and (Bgrid[2] <> 3) and (Bgrid[3] <> 3) and (Bgrid[4] <> 3)) then
      begin
        for i := 1 to 4 do
        begin
          if Bgrid[i] = 0 then
          begin
            Xlist[totalgrid] := curX + Xinc[i];
            Ylist[totalgrid] := curY + Yinc[i];
            steplist[totalgrid] := curstep + 1;
            Bfield[3, Xlist[totalgrid], Ylist[totalgrid]] := steplist[totalgrid];
            totalgrid := totalgrid + 1;
          end;
        end;
      end;
    end;
    curgrid := curgrid + 1;
  end;
end;

procedure cureaction(bnum: integer);
var
  rnum, i, bnum1, rnum1, addlife: integer;
begin
  rnum := Brole[bnum].rnum;
  if (not GetEquipState(rnum, 1)) and (not GetGongtiState(rnum, 1)) then
    rrole[rnum].PhyPower := rrole[rnum].PhyPower - 5;
  bnum1 := bfield[2, Ax, Ay];
  rnum1 := brole[bnum1].rnum;
  addlife := GetRoleMedcine(rnum, True) * (10 - Rrole[rnum1].Hurt div 15) div 10; //calculate the value

  if Rrole[rnum1].Hurt - GetRoleMedcine(rnum, True) > 20 then
    addlife := 0;
  if addlife < 0 then addlife := 0;
  addlife := min(addlife, rrole[rnum1].MaxHP - rrole[rnum1].CurrentHP);

  if addlife > 0 then Inc(Brole[bnum].ExpGot, max(0, addlife div 5));

  rrole[rnum1].CurrentHP := rrole[rnum1].CurrentHP + addlife;
  Rrole[rnum1].Hurt := Rrole[rnum1].Hurt - addlife div LIFE_HURT;
  if Rrole[rnum1].Hurt < 0 then Rrole[rnum1].Hurt := 0;
  brole[bnum1].ShowNumber := addlife;
  SetAminationPosition(0, 0, 0);

  if getpetskill(5, 2) and (brole[bnum].Team = 0) then
  begin
    for i := 0 to length(brole) - 1 do
    begin
      if (brole[i].Dead = 0) and (brole[i].rnum >= 0) and (i <> bnum1) and
        (brole[i].Team = brole[bnum1].Team) and (brole[i].X in [brole[bnum1].X - 3..brole[bnum1].X + 3]) and
        (brole[i].Y in [brole[bnum1].Y - 3..brole[bnum1].Y + 3]) then
      begin
        addlife := 0;
        rnum1 := brole[i].rnum;
        addlife := GetRoleMedcine(rnum, True) * (10 - Rrole[rnum1].Hurt div 15) div 10; //calculate the value
        if Rrole[rnum1].Hurt - GetRoleMedcine(rnum, True) > 20 then addlife := 0;
        if addlife < 0 then addlife := 0;
        addlife := min(addlife, rrole[rnum1].MaxHP - rrole[rnum1].CurrentHP);

        if addlife > 0 then Inc(Brole[bnum].ExpGot, max(0, addlife div 10));

        rrole[rnum1].CurrentHP := rrole[rnum1].CurrentHP + addlife;
        Rrole[rnum1].Hurt := Rrole[rnum1].Hurt - addlife div LIFE_HURT;
        if Rrole[rnum1].Hurt < 0 then Rrole[rnum1].Hurt := 0;
        brole[i].ShowNumber := addlife;

        Bfield[4, brole[i].X, brole[i].Y] := 1;
      end;
    end;
  end;

  playsound(31, 0);
  PlayActionAmination(bnum, 0);
  PlayMagicAmination(bnum, 0, 31, 0);
  Dec(brole[bnum].Progress, 240);
  ShowHurtValue(3);
end;

procedure PetEffect;
var
  kf, i, n: integer;
  word1: WideString;
begin
  if GetPetSkill(3, 0) then
  begin
    n := random(100);
    if n < 60 then
    begin
      word1 := UTF8Decode(' 林廚子收集藥材成功');
      drawtextwithrect(@word1[1], centER_x - 70, 55, 190, colcolor(0, 5), colcolor(0, 7));
      waitanykey;
      instruct_2(291, 5);
      redraw;
    end;
    n := random(100);
    if n < 60 then
    begin
      word1 := UTF8Decode(' 林廚子收集食材成功');
      drawtextwithrect(@word1[1], centER_x - 70, 55, 190, colcolor(0, 5), colcolor(0, 7));
      waitanykey;
      instruct_2(269, 5);
      redraw;
    end;
  end;
  if GetPetSkill(3, 2) then
  begin
    n := random(100);
    if n < 30 then
    begin
      word1 := UTF8Decode(' 林廚子收集材料成功');
      drawtextwithrect(@word1[1], centER_x - 70, 55, 190, colcolor(0, 5), colcolor(0, 7));
      waitanykey;
      n := random(18);
      n := n + 270;
      instruct_2(n, 1);
      redraw;
    end;
  end;
  if GetPetSkill(4, 0) then
  begin
    n := random(100);
    if n < 60 then
    begin
      word1 := UTF8Decode(' 孔八拉搜刮礦石成功');
      drawtextwithrect(@word1[1], centER_x - 70, 55, 190, colcolor(0, 5), colcolor(0, 7));
      waitanykey;
      instruct_2(267, 5);
      redraw;
    end;
    n := random(100);
    if n < 60 then
    begin
      word1 := UTF8Decode(' 孔八拉搜刮硝石成功');
      drawtextwithrect(@word1[1], centER_x - 70, 55, 190, colcolor(0, 5), colcolor(0, 7));
      waitanykey;
      instruct_2(268, 5);
      redraw;
    end;
  end;
  if GetPetSkill(1, 0) or GetPetSkill(1, 2) or GetPetSkill(1, 4) then
  begin
    if GetPetSkill(1, 4) then kf := 100
    else if GetPetSkill(1, 2) then kf := 60
    else if GetPetSkill(1, 0) then kf := 30;
    word1 := UTF8Decode(' 阿賢記錄武功成功');
    for i := 0 to length(warsta.GetKongfu) - 1 do
    begin
      if (warsta.GetKongfu[i] > -1) then
      begin
        n := random(100);
        if n < kf then
        begin
          drawtextwithrect(@word1[1], centER_x - 60, 55, 170, colcolor(0, 5), colcolor(0, 7));
          waitanykey;
          instruct_2(warsta.GetKongfu[i], 1);
          redraw;
        end;
      end;
    end;
  end;
  if GetPetSkill(2, 2) then
  begin
    kf := 50;
    word1 := UTF8Decode(' 阿醜偷竊物品成功');
    for i := 0 to length(warsta.GetItems) - 1 do
    begin
      if (warsta.GetItems[i] > -1) then
      begin
        n := random(100);
        if n < kf then
        begin
          drawtextwithrect(@word1[1], centER_x - 60, 55, 170, colcolor(0, 5), colcolor(0, 7));
          waitanykey;
          instruct_2(warsta.GetItems[i], 1);
          redraw;
        end;
      end;
    end;
  end;
  if GetPetSkill(2, 0) then
  begin
    word1 := UTF8Decode(' 阿醜偷竊金錢成功');
    n := warsta.GetMoney div 2 + random(warsta.GetMoney div 2);
    if n > 0 then
    begin
      drawtextwithrect(@word1[1], centER_x - 60, 55, 170, colcolor(0, 5), colcolor(0, 7));
      waitanykey;
      instruct_2(Money_ID, n);
      redraw;
    end;
  end;
end;


//显示模式选单

function SelectAutoMode: integer;
var
  i, p, menustatus, max, menu, menup: integer;
begin
  menustatus := 0;
  max := 0;
  setlength(Menustring, 0);
  setlength(menustring, 3);
  setlength(menuengstring, 0);
  //SDL_EnableKeyRepeat(20, 100);
  menustring[0] := UTF8Decode(' 瘋子型');
  menustring[1] := UTF8Decode(' 傻子型');
  menustring[2] := UTF8Decode(' 呆子型');

  redraw;


  SDL_UpdateRect2(screen, 169, 100, screen.w, screen.h);
  menu := 0;
  showModemenu(menu);
  //SDL_UpdateRect2(screen,0,0,screen.w,screen.h);
  while (SDL_PollEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          break;
        end;
        if (event.key.keysym.sym = sdlk_escape) then
        begin
          menu := -1;
          break;
        end;
      end;
      SDL_KEYDOWN:
      begin
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          menu := menu - 1;
          if menu < 0 then menu := 2;
          showModemenu(menu);
        end;
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then
        begin
          menu := menu + 1;
          if menu > 2 then menu := 0;
          showModemenu(menu);
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_left) and (menu <> -1) then
        begin
          break;
        end;
        if (event.button.button = sdl_button_right) then
        begin
          menu := -1;
          break;
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        if (round(event.button.x / (RealScreen.w / screen.w)) >= 100) and
          (round(event.button.x / (RealScreen.w / screen.w)) < 267) and
          (round(event.button.y / (RealScreen.h / screen.h)) >= 100) and
          (round(event.button.y / (RealScreen.h / screen.h)) < 3 * 22 + 100) then
        begin
          menup := menu;
          menu := (round(event.button.y / (RealScreen.h / screen.h)) - 103) div 22;
          if menu > 2 then menu := 2;
          if menu < 0 then menu := 0;
          if menup <> menu then showModemenu(menu);
        end
        else menu := -1;
      end;
    end;
    event.key.keysym.sym := 0;
    event.button.button := 0;
    sdl_delay((20 * GameSpeed) div 10);
  end;
  event.key.keysym.sym := 0;
  event.button.button := 0;

  Result := menu;
  redraw;
  setlength(menustring, 0);
  setlength(menuengstring, 0);
  //SDL_EnableKeyRepeat(30,35);
end;

//显示模式选单

procedure ShowModeMenu(menu: integer);
var
  i, x, y: integer;
begin

  x := 157;
  y := 100;

  redraw;


  DrawRectangle(x, y, 75, 74, 0, colcolor(255), 30);
  for i := 0 to 2 do
  begin
    if (i = menu) then
    begin
      drawshadowtext(@menustring[i][1], x - 17, y + 3 + 22 * i, colcolor($64), colcolor($66));
    end
    else
    begin
      drawshadowtext(@menustring[i][1], x - 17, y + 3 + 22 * i, colcolor($21), colcolor($23));
    end;
  end;
  SDL_UpdateRect2(screen, x, y, 169, 96);

end;

function TeamModeMenu: boolean;
var
  menup, x, y, w, menu, i, amount: integer;
  a, b: array of smallint;
  //b用来记录原来状态以复位。
begin
  x := 154;
  y := 100;
  w := 190;
  //SDL_EnableKeyRepeat(20, 100);
  Result := True;
  amount := 0;
  for i := 0 to length(brole) - 1 do
  begin
    if (Brole[i].Team = 0) and (brole[i].rnum >= 0) and (Brole[i].Dead = 0) then
    begin
      amount := amount + 1;
      setlength(a, amount);
      setlength(b, amount);
      a[amount - 1] := i;
      b[amount - 1] := Brole[i].Auto;
    end;
  end;
  menu := 0;
  showTeamModemenu(menu);
  while (SDL_PollEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          break;
        end;
        if (event.key.keysym.sym = sdlk_escape) then
        begin
          for i := 0 to amount - 1 do
            Brole[a[i]].Auto := b[i];
          Result := False;
          break;
        end;
      end;
      SDL_KEYDOWN:
      begin
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          menu := menu - 1;
          if menu = -1 then menu := -2;
          if menu = -3 then menu := amount - 1;
          showTeamModemenu(menu);
        end;
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then
        begin
          menu := menu + 1;
          if menu = amount then menu := -2;
          if menu = -1 then menu := 0;
          showTeamModemenu(menu);
        end;
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) then
        begin
          Brole[a[menu]].Auto := Brole[a[menu]].Auto - 1;

          if Brole[a[menu]].Auto < -1 then Brole[a[menu]].Auto := 2;
          showTeamModemenu(menu);
        end;
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_kp6) then
        begin
          Brole[a[menu]].Auto := Brole[a[menu]].Auto + 1;
          if Brole[a[menu]].Auto > 2 then Brole[a[menu]].Auto := -1;
          showTeamModemenu(menu);
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_left) then
        begin
          if (menu > -1) then
          begin
            Brole[a[menu]].Auto := Brole[a[menu]].Auto + 1;
            if Brole[a[menu]].Auto > 2 then Brole[a[menu]].Auto := -1;
            showTeamModemenu(menu);
          end
          else if (menu = -2) then
          begin
            break;
          end;
        end;
        if (event.button.button = sdl_button_right) then
        begin
          for i := 0 to amount - 1 do
            Brole[a[i]].Auto := b[i]; Result := False;
          break;
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        if (round(event.button.x / (RealScreen.w / screen.w)) >= x) and
          (round(event.button.x / (RealScreen.w / screen.w)) < x + w) and
          (round(event.button.y / (RealScreen.h / screen.h)) >= y) and
          (round(event.button.y / (RealScreen.h / screen.h)) < (amount + 1) * 22 + y) then
        begin
          menup := menu;
          //showmessage(inttostr(amount));
          menu := (round(event.button.y / (RealScreen.h / screen.h)) - y) div 22;
          if menu < 0 then menu := 0;
          if menu >= amount then menu := -2;
          if menup <> menu then showTeamModemenu(menu);
        end
        else menu := -1;
      end;
    end;

    event.key.keysym.sym := 0;
    event.button.button := 0;
    sdl_delay((20 * GameSpeed) div 10);
  end;
  event.key.keysym.sym := 0;
  event.button.button := 0;
  //SDL_EnableKeyRepeat(30,35);
  redraw;
end;

procedure ShowTeamModeMenu(menu: integer);
var
  i, amount, x, y, w, h: integer;
  modestring: array[-1..2] of WideString;
  namestr: array of WideString;
  str: WideString;
  a: array of smallint;
begin
  amount := 0;
  x := 154;
  y := 100;
  w := 190;
  modestring[0] := UTF8Decode(' 瘋子型');
  modestring[1] := UTF8Decode(' 傻子型');
  modestring[2] := UTF8Decode(' 呆子型');
  modestring[-1] := UTF8Decode(' 手动');
  str := UTF8Decode('  确定');
  for i := 0 to length(brole) - 1 do
  begin
    if (Brole[i].Team = 0) and (brole[i].rnum >= 0) and (Brole[i].Dead = 0) then
    begin
      amount := amount + 1;
      setlength(namestr, amount);
      setlength(a, amount);
      namestr[amount - 1] := UTF8Decode(' ') + gbktounicode(@rrole[brole[i].rnum].Name[0]);
      a[amount - 1] := Brole[i].Auto;
    end;
  end;
  h := amount * 22 + 32;

  redraw;

  DrawRectangle(x, y, w, h, 0, colcolor(255), 30);
  for i := 0 to amount - 1 do
  begin
    if (i = menu) then
    begin
      drawshadowtext(@namestr[i][1], x - 17, y + 3 + 22 * i, colcolor($64), colcolor($66));
      //SDL_UpdateRect2(screen, x, y,w+2, h+2);
      drawshadowtext(@modestring[a[i]][1], x + 100 - 17, y + 3 + 22 * i, colcolor($64), colcolor($66));
      //SDL_UpdateRect2(screen, x, y,w+2, h+2);
    end
    else
    begin
      drawshadowtext(@namestr[i][1], x - 17, y + 3 + 22 * i, colcolor($21), colcolor($23));
      //SDL_UpdateRect2(screen, x, y,w+2, h+2);
      drawshadowtext(@modestring[a[i]][1], x + 100 - 17, y + 3 + 22 * i, colcolor($21), colcolor($23));
      //SDL_UpdateRect2(screen, x, y,w+2, h+2);
    end;

  end;
  if menu = -2 then
    drawshadowtext(@str[1], x - 17, y + 3 + 22 * amount, colcolor($64), colcolor($66))
  else
    drawshadowtext(@str[1], x - 17, y + 3 + 22 * amount, colcolor($21), colcolor($23));
  SDL_UpdateRect2(screen, x, y, w + 2, h + 2);

end;

procedure Auto(bnum: integer);
var
  a, i, menu: integer;
begin
  setlength(Menustring, 0);
  setlength(menustring, 2);
  menustring[1] := UTF8Decode(' 單人');
  menustring[0] := UTF8Decode(' 全體');
  menu := commonmenu2(157, 100, 98);
  SDL_EnableKeyRepeat(20, 100);
  if menu = -1 then
    exit;

  //redraw;
  //SDL_UpdateRect2(screen, 157, 50, 100, 35);

  if menu = 1 then Brole[bnum].Auto := SelectAutoMode;
  if menu = 0 then
    if not TeamModeMenu then exit;

  if Brole[bnum].Auto = -1 then
  begin
    exit;
  end
  else
  begin
    if Brole[bnum].Auto > -1 then
    begin
      AutoBattle2(bnum);
      Brole[bnum].Acted := 1;
    end;
  end;

end;

//在可医疗范围内，寻找生命不足一半的生命最少的友军，

procedure trymoveHidden(var Mx1, My1, Ax1, Ay1: integer; bnum, inum: integer);
var
  Xlist: array[0..4096] of integer;
  Ylist: array[0..4096] of integer;
  steplist: array[0..4096] of integer;
  curgrid, totalgrid: integer;
  Bgrid: array[1..4] of integer; //0空位，1建筑，2友军，3敌军，4出界，5已走过
  Xinc, Yinc: array[1..4] of integer;
  curX, curY, curstep, nextX, nextY: integer;
  i, i1, i2, eneamount, aim: integer;
  tempX, tempY, tempdis: integer;
  step, myteam, rnum: integer;
  tempminHP, hidden, hurt: integer;

begin
  rnum := brole[bnum].rnum;
  hidden := GetRoleHidWeapon(rnum, True);
  myteam := brole[bnum].Team;

  tempminHP := 9999;

  hurt := -(hidden * ritem[inum].AddCurrentHP) div 100;
  step := hidden div 15 + 1;
  if (GetEquipState(Brole[bnum].rnum, 24)) or (GetGongtiState(Brole[bnum].rnum, 24)) then
    Inc(step);
  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
      Bfield[3, i1, i2] := -1;
  Bfield[3, Brole[bnum].X, Brole[bnum].Y] := 0;

  Xinc[1] := 1;
  Xinc[2] := -1;
  Xinc[3] := 0;
  Xinc[4] := 0;
  Yinc[1] := 0;
  Yinc[2] := 0;
  Yinc[3] := 1;
  Yinc[4] := -1;
  curgrid := 0;
  totalgrid := 0;
  Xlist[totalgrid] := Bx;
  Ylist[totalgrid] := By;
  steplist[totalgrid] := 0;
  totalgrid := totalgrid + 1;
  while curgrid < totalgrid do
  begin
    curX := Xlist[curgrid];
    curY := Ylist[curgrid];

    for i := 0 to length(brole) - 1 do
    begin
      rnum := brole[i].rnum;
      if (brole[i].Team <> myteam) and (brole[i].rnum >= 0) and (brole[i].dead = 0) and
        (abs(brole[i].X - curX) + abs(brole[i].Y - curY) < step) then
      begin
        if (rrole[rnum].CurrentHP - hurt < tempminHP) then
        begin
          tempminHP := rrole[rnum].CurrentHP - hurt;
          Mx1 := curX;
          My1 := curY;
          Ax1 := brole[i].X;
          Ay1 := brole[i].Y;
        end;
      end;
    end;

    curstep := steplist[curgrid];
    if curstep < step then
    begin
      //判断当前点四周格子的状况
      for i := 1 to 4 do
      begin
        nextX := curX + Xinc[i];
        nextY := curY + Yinc[i];
        if (nextX < 0) or (nextX > 63) or (nextY < 0) or (nextY > 63) then
          Bgrid[i] := 4
        else if Bfield[3, nextX, nextY] >= 0 then
          Bgrid[i] := 5
        else if Bfield[1, nextX, nextY] > 0 then
          Bgrid[i] := 1
        else if Bfield[2, nextX, nextY] >= 0 then
        begin
          if BRole[Bfield[2, nextX, nextY]].Team = myteam then
            Bgrid[i] := 2
          else
            Bgrid[i] := 3;
        end
        else if ((Bfield[0, nextX, nextY] div 2 >= 179) and (Bfield[0, nextX, nextY] div 2 <= 190)) or
          (Bfield[0, nextX, nextY] div 2 = 261) or (Bfield[0, nextX, nextY] div 2 = 511) or
          ((Bfield[0, nextX, nextY] div 2 >= 224) and (Bfield[0, nextX, nextY] div 2 <= 232)) or
          ((Bfield[0, nextX, nextY] div 2 >= 662) and (Bfield[0, nextX, nextY] div 2 <= 674)) then
          Bgrid[i] := 6
        else
          Bgrid[i] := 0;
      end;

      if (curstep = 0) or ((Bgrid[1] <> 3) and (Bgrid[2] <> 3) and (Bgrid[3] <> 3) and (Bgrid[4] <> 3)) then
      begin
        for i := 1 to 4 do
        begin
          if Bgrid[i] = 0 then
          begin
            Xlist[totalgrid] := curX + Xinc[i];
            Ylist[totalgrid] := curY + Yinc[i];
            steplist[totalgrid] := curstep + 1;
            Bfield[3, Xlist[totalgrid], Ylist[totalgrid]] := steplist[totalgrid];
            totalgrid := totalgrid + 1;
          end;
        end;
      end;
    end;
    curgrid := curgrid + 1;
  end;
end;

procedure Hiddenaction(bnum, inum: integer);
var
  rnum, bnum1, rnum1, poi, addlife, hurt, hidden, i: integer;
begin
  Brole[bnum].Acted := 1;
  instruct_32(inum, -1);
  bnum1 := bfield[2, Ax, Ay];
  rnum1 := brole[bnum1].rnum;
  rnum := brole[bnum].rnum;
  hidden := GetRoleHidWeapon(rnum, True);

  if brole[bnum1].PerfectDodge > 0 then
  begin
    hurt := 0;
  end
  else
  begin
    hurt := -(hidden * ritem[inum].AddCurrentHP) div 100;
    hurt := max(hurt, 25);

    if brole[bnum].Team = 0 then
      hurt := hurt * (200 - rrole[0].difficulty) div 200;
    if brole[bnum].Team = 1 then
      hurt := hurt * (200 + rrole[0].difficulty) div 200;

    rrole[rnum1].CurrentHP := rrole[rnum1].CurrentHP - hurt;
    poi := max(0, (hidden * ritem[inum].AddPoi) div 100 - GetRoleDefPoi(rnum1, True));

    if brole[bnum].Team = 0 then
      poi := poi * (200 - rrole[0].difficulty) div 200;
    if brole[bnum].Team = 1 then
      poi := poi * (200 + rrole[0].difficulty) div 200;

    if GetGongtiState(Brole[bnum1].rnum, 12) or GetEquipState(Brole[bnum1].rnum, 12) or
      (CheckEquipSet(Rrole[Brole[bnum1].rnum].equip[0], Rrole[Brole[bnum1].rnum].equip[1],
      Rrole[Brole[bnum1].rnum].equip[2], Rrole[Brole[bnum1].rnum].equip[3]) = 4) then
      poi := 0;

    rrole[rnum1].Poision := rrole[rnum1].Poision + poi;

  end;

  brole[bnum1].ShowNumber := hurt;
  SetAminationPosition(0, 0, 0);
  playsound(ritem[inum].AmiNum, 0);
  PlayActionAmination(bnum, 0);
  PlayMagicAmination(bnum, 0, ritem[inum].AmiNum, 0);
  ShowHurtValue(0);
  BRole[bnum].Progress := BRole[bnum].Progress - 240;
  ClearDeadRolePic;
end;




procedure trymoveUsePoi(var Mx1, My1, Ax1, Ay1: integer; bnum: integer);
var
  Xlist: array[0..4096] of integer;
  Ylist: array[0..4096] of integer;
  steplist: array[0..4096] of integer;
  curgrid, totalgrid: integer;
  Bgrid: array[1..4] of integer; //0空位，1建筑，2友军，3敌军，4出界，5已走过
  Xinc, Yinc: array[1..4] of integer;
  curX, curY, curstep, nextX, nextY: integer;
  i, i1, i2, eneamount, aim: integer;
  tempX, tempY, tempdis: integer;
  step, myteam, curedis, rnum: integer;
  tempminHP: integer;

begin
  step := brole[bnum].Step;
  myteam := brole[bnum].Team;
  curedis := GetRoleUsePoi(brole[bnum].rnum, True) div 15 + 1;

  tempminHP := 0;

  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
      Bfield[3, i1, i2] := -1;
  Bfield[3, Brole[bnum].X, Brole[bnum].Y] := 0;

  Xinc[1] := 1;
  Xinc[2] := -1;
  Xinc[3] := 0;
  Xinc[4] := 0;
  Yinc[1] := 0;
  Yinc[2] := 0;
  Yinc[3] := 1;
  Yinc[4] := -1;
  curgrid := 0;
  totalgrid := 0;
  Xlist[totalgrid] := Bx;
  Ylist[totalgrid] := By;
  steplist[totalgrid] := 0;
  totalgrid := totalgrid + 1;
  while curgrid < totalgrid do
  begin
    curX := Xlist[curgrid];
    curY := Ylist[curgrid];

    for i := 0 to length(brole) - 1 do
    begin
      rnum := brole[i].rnum;
      if (brole[i].Team <> myteam) and (brole[i].rnum >= 0) and (brole[i].dead = 0) and
        (abs(brole[i].X - curX) + abs(brole[i].Y - curY) < curedis) then
      begin
        if (rrole[rnum].CurrentHP > tempminHP) then
        begin
          tempminHP := rrole[rnum].CurrentHP;
          Mx1 := curX;
          My1 := curY;
          Ax1 := brole[i].X;
          Ay1 := brole[i].Y;
        end;
      end;
    end;

    curstep := steplist[curgrid];
    if curstep < step then
    begin
      //判断当前点四周格子的状况
      for i := 1 to 4 do
      begin
        nextX := curX + Xinc[i];
        nextY := curY + Yinc[i];
        if (nextX < 0) or (nextX > 63) or (nextY < 0) or (nextY > 63) then
          Bgrid[i] := 4
        else if Bfield[3, nextX, nextY] >= 0 then
          Bgrid[i] := 5
        else if Bfield[1, nextX, nextY] > 0 then
          Bgrid[i] := 1
        else if Bfield[2, nextX, nextY] >= 0 then
        begin
          if BRole[Bfield[2, nextX, nextY]].Team = myteam then
            Bgrid[i] := 2
          else
            Bgrid[i] := 3;
        end
        else if ((Bfield[0, nextX, nextY] div 2 >= 179) and (Bfield[0, nextX, nextY] div 2 <= 190)) or
          (Bfield[0, nextX, nextY] div 2 = 261) or (Bfield[0, nextX, nextY] div 2 = 511) or
          ((Bfield[0, nextX, nextY] div 2 >= 224) and (Bfield[0, nextX, nextY] div 2 <= 232)) or
          ((Bfield[0, nextX, nextY] div 2 >= 662) and (Bfield[0, nextX, nextY] div 2 <= 674)) then
          Bgrid[i] := 6
        else
          Bgrid[i] := 0;
      end;

      if (curstep = 0) or ((Bgrid[1] <> 3) and (Bgrid[2] <> 3) and (Bgrid[3] <> 3) and (Bgrid[4] <> 3)) then
      begin
        for i := 1 to 4 do
        begin
          if Bgrid[i] = 0 then
          begin
            Xlist[totalgrid] := curX + Xinc[i];
            Ylist[totalgrid] := curY + Yinc[i];
            steplist[totalgrid] := curstep + 1;
            Bfield[3, Xlist[totalgrid], Ylist[totalgrid]] := steplist[totalgrid];
            totalgrid := totalgrid + 1;
          end;
        end;
      end;
    end;
    curgrid := curgrid + 1;
  end;
end;

procedure UsePoiaction(bnum: integer);
var
  rnum, addpoi, bnum1, rnum1, addlife: integer;
begin
  bnum1 := bfield[2, Ax, Ay];
  if brole[bnum1].Team <> Brole[bnum].Team then
  begin
    Brole[bnum].Acted := 1;
    //转换伤害对象  4 乾坤大挪移 5斗转星移
    if GetEquipState(brole[bnum1].rnum, 4) or (GetGongtiState(brole[bnum1].rnum, 4)) then
      bnum1 := ReMoveHurt(bnum1, bnum);
    if GetEquipState(brole[bnum1].rnum, 5) or (GetGongtiState(brole[bnum1].rnum, 5)) then
      bnum1 := RetortHurt(bnum1, bnum);

    rnum := brole[bnum].rnum;
    if (not GetEquipState(rnum, 1)) and (not GetGongtiState(rnum, 1)) then
      rrole[rnum].PhyPower := rrole[rnum].PhyPower - 3;
    rnum1 := brole[bnum1].rnum;
    addpoi := GetRoleUsePoi(rnum, True) div 3 - GetRoleDefPoi(rnum1, True) div 4;
    if addpoi < 0 then addpoi := 0;

    addpoi := min(addpoi, GetRoleUsePoi(rnum, True) - rrole[rnum1].Poision);

    if brole[bnum].Team = 0 then
      addpoi := addpoi * (200 - rrole[0].difficulty) div 200;
    if brole[bnum].Team = 1 then
      addpoi := addpoi * (200 + rrole[0].difficulty) div 200;

    if brole[bnum1].PerfectDodge > 0 then addpoi := 0;

    if GetGongtiState(Brole[bnum1].rnum, 12) or GetEquipState(Brole[bnum1].rnum, 12) or
      (CheckEquipSet(Rrole[Brole[bnum1].rnum].equip[0], Rrole[Brole[bnum1].rnum].equip[1],
      Rrole[Brole[bnum1].rnum].equip[2], Rrole[Brole[bnum1].rnum].equip[3]) = 4) then
      addpoi := 0;

    if addpoi > 0 then Inc(Brole[bnum].ExpGot, max(0, addpoi div 5));

    rrole[rnum1].Poision := rrole[rnum1].Poision + addpoi;
    brole[bnum1].ShowNumber := addpoi;
    SetAminationPosition(0, 0, 0);
    playsound(34, 0);
    PlayActionAmination(bnum, 0);
    PlayMagicAmination(bnum, 0, 34, 0);
    ShowHurtValue(2);
    BRole[bnum].Progress := BRole[bnum].Progress - 240;
  end;
end;

procedure trymoveMedPoi(var Mx1, My1, Ax1, Ay1: integer; bnum: integer);
var
  Xlist: array[0..4096] of integer;
  Ylist: array[0..4096] of integer;
  steplist: array[0..4096] of integer;
  curgrid, totalgrid: integer;
  Bgrid: array[1..4] of integer; //0空位，1建筑，2友军，3敌军，4出界，5已走过,6水面
  Xinc, Yinc: array[1..4] of integer;
  curX, curY, curstep, nextX, nextY: integer;
  i, i1, i2, eneamount, aim: integer;
  tempX, tempY, tempdis: integer;
  step, myteam, curedis, rnum: integer;
  tempminHP: integer;

begin
  step := brole[bnum].Step;
  myteam := brole[bnum].Team;
  curedis := GetRoleMedPoi(brole[bnum].rnum, True) div 15 + 1;

  tempminHP := 0;

  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
      Bfield[3, i1, i2] := -1;
  Bfield[3, Brole[bnum].X, Brole[bnum].Y] := 0;

  Xinc[1] := 1;
  Xinc[2] := -1;
  Xinc[3] := 0;
  Xinc[4] := 0;
  Yinc[1] := 0;
  Yinc[2] := 0;
  Yinc[3] := 1;
  Yinc[4] := -1;
  curgrid := 0;
  totalgrid := 0;
  Xlist[totalgrid] := Bx;
  Ylist[totalgrid] := By;
  steplist[totalgrid] := 0;
  totalgrid := totalgrid + 1;
  while curgrid < totalgrid do
  begin
    curX := Xlist[curgrid];
    curY := Ylist[curgrid];

    for i := 0 to length(brole) - 1 do
    begin
      rnum := brole[i].rnum;
      if (brole[i].Team = myteam) and (brole[i].rnum >= 0) and (brole[i].dead = 0) and
        (abs(brole[i].X - curX) + abs(brole[i].Y - curY) < curedis) and (rrole[rnum].Poision > 0) then
      begin
        if (rrole[rnum].Poision > tempminHP) then
        begin
          if GetRoleMedPoi(brole[bnum].rnum, True) >= (Rrole[rnum].Poision div 2) then
          begin
            tempminHP := rrole[rnum].Poision;
            Mx1 := curX;
            My1 := curY;
            Ax1 := brole[i].X;
            Ay1 := brole[i].Y;
          end;
        end;
      end;
    end;

    curstep := steplist[curgrid];
    if curstep < step then
    begin
      //判断当前点四周格子的状况
      for i := 1 to 4 do
      begin
        nextX := curX + Xinc[i];
        nextY := curY + Yinc[i];
        if (nextX < 0) or (nextX > 63) or (nextY < 0) or (nextY > 63) then
          Bgrid[i] := 4
        else if Bfield[3, nextX, nextY] >= 0 then
          Bgrid[i] := 5
        else if Bfield[1, nextX, nextY] > 0 then
          Bgrid[i] := 1
        else if ((Bfield[0, nextX, nextY] div 2 >= 179) and (Bfield[0, nextX, nextY] div 2 <= 190)) or
          (Bfield[0, nextX, nextY] div 2 = 261) or (Bfield[0, nextX, nextY] div 2 = 511) or
          ((Bfield[0, nextX, nextY] div 2 >= 224) and (Bfield[0, nextX, nextY] div 2 <= 232)) or
          ((Bfield[0, nextX, nextY] div 2 >= 662) and (Bfield[0, nextX, nextY] div 2 <= 674)) then
          Bgrid[i] := 6
        else if Bfield[2, nextX, nextY] >= 0 then
        begin
          if BRole[Bfield[2, nextX, nextY]].Team = myteam then
            Bgrid[i] := 2
          else
            Bgrid[i] := 3;
        end
        else
          Bgrid[i] := 0;
      end;

      if (curstep = 0) or ((Bgrid[1] <> 3) and (Bgrid[2] <> 3) and (Bgrid[3] <> 3) and (Bgrid[4] <> 3)) then
      begin
        for i := 1 to 4 do
        begin
          if Bgrid[i] = 0 then
          begin
            Xlist[totalgrid] := curX + Xinc[i];
            Ylist[totalgrid] := curY + Yinc[i];
            steplist[totalgrid] := curstep + 1;
            Bfield[3, Xlist[totalgrid], Ylist[totalgrid]] := steplist[totalgrid];
            totalgrid := totalgrid + 1;
          end;
        end;
      end;
    end;
    curgrid := curgrid + 1;
  end;
end;

procedure MedPoiaction(bnum: integer);
var
  rnum, bnum1, rnum1, i, medpoi, step, minuspoi: integer;
  select: boolean;
begin
  rnum := brole[bnum].rnum;
  medpoi := GetRoleMedPoi(rnum, True);
  step := medpoi div 15 + 1;

  bnum1 := bfield[2, Ax, Ay];
  Brole[bnum].Acted := 1;
  if (not GetEquipState(rnum, 1)) and (not GetGongtiState(rnum, 1)) then
    rrole[rnum].PhyPower := rrole[rnum].PhyPower - 5;
  rnum1 := brole[bnum1].rnum;
  minuspoi := GetRoleMedPoi(rnum, True);
  if minuspoi < (Rrole[rnum1].Poision div 2) then
    minuspoi := 0
  else if minuspoi > Rrole[rnum1].Poision then
    minuspoi := Rrole[rnum1].Poision;

  if minuspoi < 0 then minuspoi := 0;
  minuspoi := min(minuspoi, rrole[rnum1].Poision);
  if minuspoi > 0 then Inc(Brole[bnum].ExpGot, max(0, minuspoi div 5));

  if minuspoi < 0 then minuspoi := 0;
  if rrole[rnum1].Poision - minuspoi <= 0 then minuspoi := rrole[rnum1].Poision;
  rrole[rnum1].Poision := rrole[rnum1].Poision - minuspoi;
  brole[bnum1].ShowNumber := minuspoi;
  SetAminationPosition(0, 0, 0);

  if getpetskill(5, 2) and (brole[bnum].Team = 0) then
  begin
    for i := 0 to length(brole) - 1 do
    begin
      if (brole[i].Dead = 0) and (brole[i].rnum >= 0) and (i <> bnum1) and
        (brole[i].Team = brole[bnum1].Team) and (brole[i].X in [brole[bnum1].X - 3..brole[bnum1].X + 3]) and
        (brole[i].Y in [brole[bnum1].Y - 3..brole[bnum1].Y + 3]) then
      begin
        rnum1 := brole[i].rnum;
        minuspoi := GetRoleMedPoi(rnum, True);

        if minuspoi < (Rrole[rnum1].Poision div 2) then
          minuspoi := 0
        else if minuspoi > Rrole[rnum1].Poision then
          minuspoi := Rrole[rnum1].Poision;

        if minuspoi < 0 then minuspoi := 0;
        minuspoi := min(minuspoi, rrole[rnum1].Poision);
        if minuspoi > 0 then Inc(Brole[bnum].ExpGot, max(0, minuspoi div 5));

        rrole[rnum1].Poision := rrole[rnum1].Poision - minuspoi;
        brole[i].ShowNumber := minuspoi;

        Bfield[4, brole[i].X, brole[i].Y] := 1;
      end;
    end;
  end;
  playsound(33, 0);
  PlayActionAmination(bnum, 0);
  PlayMagicAmination(bnum, 0, 33, 0);
  ShowHurtValue(4);
  BRole[bnum].Progress := BRole[bnum].Progress - 240;

end;




end.
