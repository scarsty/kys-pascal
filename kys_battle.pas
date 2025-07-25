﻿unit kys_battle;

//{$MODE Delphi}

interface

uses
  SysUtils,
  {$IFDEF fpc}
  LMessages,
  LConvEncoding,
  LCLType,
  LCLIntf,
  {$ELSE}
  Windows,
  {$ENDIF}
  kys_type,
  StrUtils,
  SDL3_TTF,
  SDL3_image,
  SDL3,
  Math,
  kys_main,
  Dialogs;

//战斗
//从游戏文件的命名来看, 应是'war'这个词的缩写,
//但实际上战斗的规模很小, 使用'battle'显然更合适
function Battle(battlenum, getexp: integer): boolean;
function InitialBField: boolean;
procedure InitialBRole(i, rnum, team, x, y: integer);
function SelectTeamMembers: integer;
procedure ShowMultiMenu(max, menu, status: integer; menuString: array of utf8string);
procedure BattleMainControl;
procedure CalMoveAbility;
procedure ReArrangeBRole;
function BattleStatus: integer;
function BattleMenu(bnum: integer): integer;
procedure ShowBMenu(MenuStatus, menu, max: integer);
procedure MoveRole(bnum: integer);
function MoveAmination(bnum: integer): boolean;
function SelectAim(bnum, step: integer; AreaType: integer = 0; AreaRange: integer = 0): boolean;
function SelectDirector(bnum, step: integer): boolean;
//procedure SeekPath(x, y, step: integer);
//function SeekPath2(x, y, step: integer): integer;
procedure SeekPath2(x, y, step, myteam, mode: integer);
procedure CalCanSelect(bnum, mode, step: integer);
procedure Attack(bnum: integer);
procedure AttackAction(bnum, i, mnum, level: integer); overload;
procedure AttackAction(bnum, mnum, level: integer); overload;
procedure ShowMagicName(mnum: integer; mode: integer = 0);
function SelectMagic(rnum: integer): integer;
procedure ShowMagicMenu(MenuStatus, menu, max: integer; menuString, menuEngString: array of utf8string);
procedure SetAminationPosition(mode, step: integer; range: integer = 0); overload;
procedure SetAminationPosition(Bx, By, Ax, Ay, mode, step: integer; range: integer = 0); overload;
procedure PlayMagicAmination(bnum, enum: integer; ForTeam: integer = 0; mode: integer = 0);
procedure CalHurtRole(bnum, mnum, level: integer);
function CalHurtValue(bnum1, bnum2, mnum, level: integer): integer;
function CalHurtValue2(bnum1, bnum2, mnum, level: integer): integer;
procedure ShowHurtValue(mode: integer);
procedure SelectModeColor(mode: integer; var color1, color2: uint32; var str: utf8string; trans: integer = 0);
procedure CalPoiHurtLife;
procedure ClearDeadRolePic;
procedure Wait(bnum: integer);
procedure RestoreRoleStatus;
procedure AddExp;
procedure CheckLevelUp;
procedure LevelUp(bnum: integer);
procedure CheckBook;
function CalRNum(team: integer): integer;
procedure BattleMenuItem(bnum: integer);
procedure UsePoison(bnum: integer);
procedure PlayActionAmination(bnum, mode: integer; mnum: integer = -1);
procedure Medcine(bnum: integer);
procedure MedPoison(bnum: integer);
procedure UseHiddenWeapon(bnum, inum: integer);
procedure Rest(bnum: integer);
function TeamModeMenu: boolean;

procedure AutoBattle(bnum: integer);
procedure AutoUseItem(bnum, list: integer);

procedure TryMoveAttack(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; bnum, mnum, level: integer);
procedure calline(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; curX, curY, bnum, mnum, level: integer);
procedure CalArea(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; curX, curY, bnum, mnum, level: integer);
procedure CalPoint(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; curX, curY, bnum, mnum, level: integer);
procedure calcross(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; curX, curY, bnum, mnum, level: integer);
procedure NearestMove(var Mx1, My1: integer; bnum: integer);
procedure NearestMoveByPro(var Mx1, My1, Ax1, Ay1: integer; bnum, TeamMate, KeepDis, Prolist, MaxMinPro: integer; mode: integer);

var
  movetable: array of TPosition;
  maxdelaypicnum: integer;

implementation

uses
  kys_event,
  kys_engine,
  kys_draw;

//Battle.
//战斗, 返回值为是否胜利
function Battle(battlenum, getexp: integer): boolean;
var
  i, j, num, SelectTeamList, x, y, PreMusic: integer;
  path: utf8string;
begin
  Bstatus := 0;
  CurrentBattle := battlenum;
  BattleRound := 1;
  if InitialBField then
  begin
    //如果未发现自动战斗设定, 则选择人物
    SelectTeamList := SelectTeamMembers;
    for i := 0 to 5 do
    begin
      x := warsta.TeamX[i];
      y := warsta.TeamY[i];
      if SelectTeamList and (1 shl i) > 0 then
      begin
        InitialBRole(BRoleAmount, TeamList[i], 0, x, y);
        BRoleAmount := BRoleAmount + 1;
      end;
    end;
    for i := 0 to 5 do
    begin
      x := warsta.TeamX[i];
      y := warsta.TeamY[i] + 1;
      if (warsta.TeamMate[i] > 0) and (instruct_16(warsta.TeamMate[i], 1, 0) = 0) then
      begin
        InitialBRole(BRoleAmount, warsta.TeamMate[i], 0, x, y);
        BRoleAmount := BRoleAmount + 1;
      end;
    end;
  end;
  instruct_14;
  Where := 2;
  InitialBFieldImage; //初始化场景

  PreMusic := nowmusic;
  StopMP3;
  PlayMP3(warsta.MusicNum, -1);

  //Setlength(AutoMode, BRoleAmount);
  for i := 0 to BRoleAmount - 1 do
    Brole[i].AutoMode := 1;

  //载入战斗所需的额外贴图
  if SEMIREAL = 1 then
  begin
    setlength(BHead, BRoleAmount);
    for i := 0 to BRoleAmount - 1 do
    begin
      if HeadSurface[Rrole[Brole[i].rnum].HeadNum] = nil then
      begin
        HeadSurface[Rrole[Brole[i].rnum].HeadNum] := LoadSurfaceFromFile(AppPath + 'head/' + IntToStr(Rrole[Brole[i].rnum].HeadNum) + '.png');
      end;
      BHead[i] := HeadSurface[Rrole[Brole[i].rnum].HeadNum];
      if BHead[i] = nil then
      begin
        BHead[i] := SDL_CreateSurface(56, 71, SDL_GetPixelFormatForMasks(32, Rmask, Gmask, Bmask, Amask));
        SDL_FillSurfaceRect(BHead[i], nil, 1);
        SDL_SetSurfaceColorKey(BHead[i], True, 1);
        DrawHeadPic(Rrole[Brole[i].rnum].HeadNum, 0, 0, BHead[i]);
      end;
      Brole[i].BHead := i;
    end;
  end;

  if PNG_TILE = 0 then
  begin
    for i := 0 to BRoleAmount - 1 do
    begin
      path := formatfloat('fight/fight000', Rrole[Brole[i].rnum].HeadNum);
      FPicAmount := LoadIdxGrp(path + '.idx', path + '.grp', FIdx[Rrole[Brole[i].rnum].HeadNum], FPic[Rrole[Brole[i].rnum].HeadNum]);
    end;
  end;

  if PNG_TILE > 0 then
  begin
    for i := 0 to BRoleAmount - 1 do
    begin
      path := formatfloat('resource/fight/fight000', Rrole[Brole[i].rnum].HeadNum);
      LoadPNGTiles(path, FPNGIndex[Rrole[Brole[i].rnum].HeadNum], FPNGTile[Rrole[Brole[i].rnum].HeadNum], 1);
      for j := 0 to 3 do
      begin
        num := BEGIN_BATTLE_ROLE_PIC + Rrole[Brole[i].rnum].HeadNum * 4 + j;
        LoadOnePNGTile('resource/wmap/', nil, num, BPNGIndex[num], @BPNGTile[0]);
      end;
      Brole[i].BHead := i;
    end;
  end;

  BattleMainControl;

  RestoreRoleStatus;
  event.key.key := 0;
  event.button.button := 0;

  if (bstatus = 1) or ((bstatus = 2) and (getexp <> 0)) then
  begin
    AddExp;
    CheckLevelUp;
    CheckBook;
  end;

  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

  //释放额外贴图
  if SEMIREAL = 1 then
  begin
    for i := 0 to BRoleAmount - 1 do
    begin
      //SDL_DestroySurface(BHead[i]);
    end;
    setlength(BHead, 0);
  end;

  if PNG_TILE = 1 then
  begin
    for i := 0 to BRoleAmount - 1 do
    begin
      for j := low(FPNGTile[i]) to high(FPNGTile[i]) do
      begin
        SDL_DestroySurface(FPNGTile[i][j]);
        FPNGIndex[i][j].CurPointer := nil;
      end;
    end;
  end;

  if Rscene[CurScene].EntranceMusic >= 0 then
  begin
    StopMP3;
    PlayMP3(Rscene[CurScene].EntranceMusic, -1);
  end
  else
    PlayMP3(PreMusic, -1);

  Where := 1;
  if bstatus = 1 then
    Result := True
  else
    Result := False;
  //SDL_EnableKeyRepeat(50, 30);

end;

//Structure of Bfield arrays:
//0: Ground; 1: Building; 2: Roles(Rrnum);

//Structure of Brole arrays:
//the 1st pointer is "Battle Num";
//The 2nd: 0: rnum, 1: Friend or enemy, 2: y, 3: x, 4: Face, 5: Dead or alive,
//7: Acted, 8: Pic Num, 9: The number, 10, 11, 12: Auto, 13: Exp gotten.
//初始化战场
function InitialBField: boolean;
var
  sta, grp, idx, offset, i, i1, i2, x, y, fieldnum: integer;
begin
  sta := FileOpen(AppPath + 'resource/war.sta', fmopenread);
  offset := currentbattle * sizeof(TWarData);
  FileSeek(sta, offset, 0);
  FileRead(sta, warsta, sizeof(TWarData));
  FileClose(sta);
  fieldnum := warsta.BFieldNum;

  if fieldnum = 0 then
    offset := 0
  else
  begin
    idx := FileOpen(AppPath + 'resource/warfld.idx', fmopenread);
    FileSeek(idx, (fieldnum - 1) * 4, 0);
    FileRead(idx, offset, 4);
    FileClose(idx);
  end;
  grp := FileOpen(AppPath + 'resource/warfld.grp', fmopenread);
  FileSeek(grp, offset, 0);
  FileRead(grp, Bfield[0, 0, 0], 2 * 64 * 64 * 2);
  FileClose(grp);

  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
      Bfield[2, i1, i2] := -1;
  BRoleAmount := 0;
  Result := True;
  //我方自动参战数据
  for i := 0 to 5 do
  begin
    x := warsta.TeamX[i];
    y := warsta.TeamY[i];
    if warsta.AutoTeamMate[i] >= 0 then
    begin
      InitialBRole(BRoleAmount, warsta.AutoTeamMate[i], 0, x, y);
      BRoleAmount := BRoleAmount + 1;
    end;
  end;
  //如没有自动参战人物, 返回假, 激活选择人物
  if BRoleAmount > 0 then
    Result := False;
  for i := 0 to 19 do
  begin
    x := warsta.EnemyX[i];
    y := warsta.EnemyY[i];
    if warsta.Enemy[i] >= 0 then
    begin
      InitialBRole(BRoleAmount, warsta.Enemy[i], 1, x, y);
      BRoleAmount := BRoleAmount + 1;
    end;
  end;

end;

procedure InitialBRole(i, rnum, team, x, y: integer);
begin
  if i in [low(Brole) .. high(Brole)] then
  begin
    Brole[i].rnum := rnum;
    Brole[i].Team := team;
    Brole[i].Y := y;
    Brole[i].X := x;
    if Team = 0 then
      Brole[i].Face := 2;
    if Team <> 0 then
      Brole[i].Face := 1;
    Brole[i].Dead := 0;
    Brole[i].Step := 0;
    Brole[i].Acted := 0;
    Brole[i].ExpGot := 0;
    Brole[i].Auto := 0;
    Brole[i].RealSpeed := 0;
    Brole[i].RealProgress := random(7000);
  end;
end;

//选择人物, 返回值为整型, 按bit表示人物是否参战
function SelectTeamMembers: integer;
var
  i, menu, max, menup: integer;
  menuString: array [0 .. 8] of utf8string;
  str: utf8string;
begin
  Result := 0;
  max := 1;
  menu := 0;
  //setlength(menustring, 7);
  for i := 0 to 5 do
  begin
    if Teamlist[i] >= 0 then
    begin
      menuString[i + 1] := CP950ToUtf8(@Rrole[Teamlist[i]].Name);
      max := max + 1;
    end;
  end;
  menuString[0] := '   全員參戰';
  menuString[max] := '   開始戰鬥';
  str := '選擇參戰人物';
  DrawTextWithRect(str, CENTER_X - 63, 100, 126, ColColor($21), ColColor($23));
  UpdateAllScreen;
  RecordFreshScreen(0, 0, CENTER_X * 2, CENTER_Y * 2);
  ShowMultiMenu(max, 0, 0, menuString);
  //sdl_enablekeyrepeat(50, 30);
  while (SDL_WaitEvent(@event)) do
  begin
    CheckBasicEvent;
    case event.type_ of
      SDL_EVENT_KEY_UP:
      begin
        if ((event.key.key = SDLK_RETURN) or (event.key.key = SDLK_SPACE)) and (menu <> max) then
        begin
          //选中人物则反转对应bit
          if menu > 0 then
            Result := Result xor (1 shl (menu - 1))
          else if Result < round(power(2, (max - 1)) - 1) then
            Result := round(power(2, (max - 1)) - 1)
          else
            Result := 0;
          ShowMultiMenu(max, menu, Result, menuString);
        end;
        if ((event.key.key = SDLK_RETURN) or (event.key.key = SDLK_SPACE)) and (menu = max) then
        begin
          if Result <> 0 then
            break;
        end;
        if (event.key.key = SDLK_UP) then
        begin
          menu := menu - 1;
          if menu < 0 then
            menu := max;
          ShowMultiMenu(max, menu, Result, menuString);
        end;
        if (event.key.key = SDLK_DOWN) then
        begin
          menu := menu + 1;
          if menu > max then
            menu := 0;
          ShowMultiMenu(max, menu, Result, menuString);
        end;
      end;
      SDL_EVENT_MOUSE_BUTTON_UP:
      begin
        if (round(event.button.x / (RESOLUTIONX / screen.w)) >= CENTER_X - 75) and (round(event.button.x / (RESOLUTIONX / screen.w)) < CENTER_X + 75) and (round(event.button.y / (RESOLUTIONY / screen.h)) >= 150) and (round(event.button.y / (RESOLUTIONY / screen.h)) < max * 22 + 178) then
        begin
          if (event.button.button = SDL_BUTTON_LEFT) and (menu <> max) then
          begin
            if menu > 0 then
              Result := Result xor (1 shl (menu - 1))
            else if Result < round(power(2, (max - 1)) - 1) then
              Result := round(power(2, (max - 1)) - 1)
            else
              Result := 0;
            ShowMultiMenu(max, menu, Result, menuString);
          end;
          if (event.button.button = SDL_BUTTON_LEFT) and (menu = max) then
          begin
            if Result <> 0 then
              break;
          end;
        end;
      end;
      SDL_EVENT_MOUSE_MOTION:
      begin
        if (round(event.button.x / (RESOLUTIONX / screen.w)) >= CENTER_X - 75) and (round(event.button.x / (RESOLUTIONX / screen.w)) < CENTER_X + 75) and (round(event.button.y / (RESOLUTIONY / screen.h)) >= 150) and (round(event.button.y / (RESOLUTIONY / screen.h)) < max * 22 + 178) then
        begin
          menup := menu;
          menu := (round(event.button.y / (RESOLUTIONY / screen.h)) - 152) div 22;
          if menup <> menu then
            ShowMultiMenu(max, menu, Result, menuString);
        end;
      end;
    end;
  end;

end;

//显示选择参战人物选单
procedure ShowMultiMenu(max, menu, status: integer; menuString: array of utf8string);
var
  i, x, y: integer;
  str1: utf8string;
begin
  x := CENTER_X - 105;
  y := 150;
  LoadFreshScreen(x + 30, y, 151, max * 22 + 29);
  str1 := '參戰';
  DrawRectangle(screen, x + 30, y, 150, max * 22 + 28, 0, ColColor(255), 50);
  for i := 0 to max do
    if i = menu then
    begin
      DrawShadowText(screen, menuString[i], x + 33, y + 3 + 22 * i, ColColor($64), ColColor($66));
      if ((status and (1 shl (i - 1))) > 0) and (i > 0) and (i < max) then
        DrawShadowText(screen, str1, x + 133, y + 3 + 22 * i, ColColor($64), ColColor($66));
    end
    else
    begin
      DrawShadowText(screen, menuString[i], x + 33, y + 3 + 22 * i, ColColor($5), ColColor($7));
      if ((status and (1 shl (i - 1))) > 0) and (i > 0) and (i < max) then
        DrawShadowText(screen, str1, x + 133, y + 3 + 22 * i, ColColor($21), ColColor($23));
    end;
  SDL_UpdateRect2(screen, x + 30, y, 151, max * 22 + 29);
  //UpdateAllScreen;
end;

//战斗主控制
procedure BattleMainControl;
var
  i, j, act: integer;
  tempBrole: TBattleRole;
  delaytime: uint32;
  ProgressThread: PSDL_Thread;
begin

  delaytime := 5; //毫秒
  //ProgressThread := SDL_CreateThread(@ShowProgress, nil);
  //战斗未分出胜负则继续
  Bx := Brole[0].X;
  By := Brole[0].Y;

  while BStatus = 0 do
  begin
    CalMoveAbility; //计算移动能力
    if SEMIREAL = 0 then
      ReArrangeBRole; //排列角色顺序
    ClearDeadRolePic; //清除阵亡角色

    //是否已行动, 显示数字清空
    for i := 0 to BRoleAmount - 1 do
    begin
      Brole[i].Acted := 0;
      Brole[i].ShowNumber := 0;
    end;
    //效果层清空
    FillChar(BField[4, 0, 0], sizeof(BField[4]), 0);

    if SEMIREAL = 1 then
    begin
      //将不含进度条的图形画入快速重载入屏幕
      DrawBField(0);
      RecordFreshScreen(0, 0, screen.w, screen.h);
      DrawProgress;
      act := 0;
      while SDL_PollEvent(@event) or True do
      begin
        for i := 0 to BRoleAmount - 1 do
        begin
          Brole[i].RealProgress := Brole[i].RealProgress + Brole[i].RealSpeed;
          if Brole[i].RealProgress >= 10000 then
          begin
            Brole[i].RealProgress := Brole[i].RealProgress - 10000;
            act := 1;
            break;
          end;
        end;
        if act = 1 then
          break;
        LoadFreshScreen(0, 0, screen.w, screen.h);
        DrawProgress;
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        SDL_Delay(delaytime);
        CheckBasicEvent;
      end;
    end;

    if SEMIREAL = 0 then
      i := 0;

    while ((i < BRoleAmount) and (Bstatus = 0)) do
    begin
      while (SDL_PollEvent(@event) or True) do
      begin
        CheckBasicEvent;
        if (event.key.key = SDLK_ESCAPE) or (event.button.button = SDL_BUTTON_RIGHT) then
        begin
          Brole[i].Auto := 0;
          //AutoMode[i]:=-1;
          event.button.button := 0;
          event.key.key := 0;
        end;
        break;
      end;
      //战场序号保存至变量28005
      x50[28005] := i;
      //为我方且未阵亡, 非自动战斗, 则显示选单
      if (Brole[i].Dead = 0) then
      begin
        //当前人物位置作为屏幕中心
        Bx := Brole[i].X;
        By := Brole[i].Y;
        Redraw;
        if (Brole[i].Team = 0) and (Brole[i].Auto = 0) then
        begin
          if Brole[i].Acted = 0 then
          begin
            tempBrole := Brole[i]; //记录一个临时人物信息, 用于恢复位置
          end;
          case BattleMenu(i) of
            0: MoveRole(i);
            1: Attack(i);
            2: UsePoison(i);
            3: MedPoison(i);
            4: Medcine(i);
            5: BattleMenuItem(i);
            6:
            begin
              Wait(i);
            end;
            7:
            begin
              //ShowStatus(Brole[i].rnum);
              //waitanykey;
              MenuStatus;
            end;
            8: Rest(i);
            9:
            begin
              if MODVersion = 51 then
                CallEvent(1077)
              else
              begin
                if TeamModeMenu then
                  for j := 0 to BRoleAmount - 1 do
                    if (Brole[j].Team = 0) and (Brole[j].Dead = 0) then
                      Brole[j].Auto := sign(Brole[j].AutoMode);
              end;
              //Brole[i].Acted := 0;
            end;
            else
            begin
              if tempbrole.rnum = Brole[i].rnum then
              begin
                Bfield[2, tempBrole.X, tempBrole.Y] := i;
                Bfield[2, Brole[i].X, Brole[i].Y] := -1;
                Brole[i] := tempBrole;
              end;
            end;
          end;
        end
        else
        begin
          AutoBattle(i);
          Brole[i].Acted := 1;
        end;
      end
      else
        Brole[i].Acted := 1;

      ClearDeadRolePic;
      Redraw;
      Bstatus := BattleStatus;

      if Brole[i].Acted = 1 then
      begin
        i := i + 1;
        if SEMIREAL = 1 then
          break;
      end;
    end;
    BattleRound := BattleRound + 1;
    CalPoiHurtLife; //计算中毒损血
  end;

end;

//按轻功重排人物(未考虑装备)
procedure ReArrangeBRole;
var
  i, i1, i2, x: integer;
  temp: TBattleRole;
begin
  //随机数使轻功相同角色的可能顺序不同
  for i1 := 0 to BRoleAmount - 2 do
    for i2 := i1 + 1 to BRoleAmount - 1 do
    begin
      if Rrole[Brole[i1].rnum].Speed * 10 + random(10) < Rrole[Brole[i2].rnum].Speed * 10 + random(10) then
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
  for i := 0 to BRoleAmount - 1 do
  begin
    rnum := Brole[i].rnum;
    addspeed := 0;
    if Rrole[rnum].Equip[0] >= 0 then
      addspeed := addspeed + Ritem[Rrole[rnum].Equip[0]].AddSpeed;
    if Rrole[rnum].Equip[1] >= 0 then
      addspeed := addspeed + Ritem[Rrole[rnum].Equip[1]].AddSpeed;
    Brole[i].Step := (Rrole[Brole[i].rnum].Speed + addspeed) div 15;
    if Brole[i].Step > 15 then
      Brole[i].Step := 15;

    if SEMIREAL = 1 then
    begin
      Brole[i].RealSpeed := trunc((Rrole[rnum].Speed + addspeed) / (log10(MaxProList[44]) - 1)) - Rrole[rnum].Hurt div 10 - Rrole[rnum].Poison div 30;
      if Brole[i].RealSpeed > 200 then
        Brole[i].RealSpeed := 200 + (Brole[i].RealSpeed - 200) div 3;
      if Brole[i].Step > 7 then
        Brole[i].Step := 7;
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
  for i := 0 to BRoleAmount - 1 do
  begin
    if (Brole[i].Team = 0) and (Brole[i].Dead = 0) then
      sum0 := sum0 + 1;
    if (Brole[i].Team = 1) and (Brole[i].Dead = 0) then
      sum1 := sum1 + 1;
  end;

  if (sum0 > 0) and (sum1 > 0) then
    Result := 0;
  if (sum0 >= 0) and (sum1 = 0) then
    Result := 1;
  if (sum0 = 0) and (sum1 > 0) then
    Result := 2;

end;

//战斗主选单, menustatus按bit保存可用项
function BattleMenu(bnum: integer): integer;
var
  i, p, MenuStatus, menu, max, rnum, menup: integer;
  realmenu: array [0 .. 9] of integer;
  str: utf8string;
begin
  MenuStatus := $3E0;
  max := 4;
  //for i:=0 to 9 do
  rnum := Brole[bnum].rnum;
  //移动是否可用
  if Brole[bnum].Step > 0 then
  begin
    MenuStatus := MenuStatus or 1;
    max := max + 1;
  end;

  //can not attack when phisical<10
  //攻击是否可用
  if Rrole[rnum].PhyPower >= 10 then
  begin
    p := 0;
    for i := 0 to 9 do
    begin
      if Rrole[rnum].Magic[i] > 0 then
      begin
        p := 1;
        break;
      end;
    end;
    if p > 0 then
    begin
      MenuStatus := MenuStatus or 2;
      max := max + 1;
    end;
  end;
  //用毒是否可用
  if (Rrole[rnum].UsePoi > 0) and (Rrole[rnum].PhyPower >= 30) then
  begin
    MenuStatus := MenuStatus or 4;
    max := max + 1;
  end;
  //解毒是否可用
  if (Rrole[rnum].MedPoi > 0) and (Rrole[rnum].PhyPower >= 50) then
  begin
    MenuStatus := MenuStatus or 8;
    max := max + 1;
  end;
  //医疗是否可用
  if (Rrole[rnum].Medcine > 0) and (Rrole[rnum].PhyPower >= 50) then
  begin
    MenuStatus := MenuStatus or 16;
    max := max + 1;
  end;

  //等待是否可用
  if SEMIREAL = 1 then
  begin
    MenuStatus := MenuStatus - 64;
    max := max - 1;
  end;

  Redraw;
  ShowSimpleStatus(Brole[bnum].rnum, CENTER_X + 100, 50);
  str := format('回合%d', [BattleRound]);
  DrawTextWithRect(screen, str, 160, 50, DrawLength(str) * 10 + 6, ColColor($21), ColColor($23));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  menu := 0;

  ShowBMenu(MenuStatus, menu, max);

  //SDL_UpdateRect2(screen,0,0,screen.w,screen.h);
  while (SDL_WaitEvent(@event)) do
  begin
    CheckBasicEvent;
    case event.type_ of
      SDL_EVENT_KEY_UP:
      begin
        if (event.key.key = SDLK_RETURN) or (event.key.key = SDLK_SPACE) then
        begin
          break;
        end;
        if (event.key.key = SDLK_ESCAPE) then
        begin
          menu := -1;
          break;
        end;
        if (event.key.key = SDLK_UP) then
        begin
          menu := menu - 1;
          if menu < 0 then
            menu := max;
          ShowBMenu(MenuStatus, menu, max);
        end;
        if (event.key.key = SDLK_DOWN) then
        begin
          menu := menu + 1;
          if menu > max then
            menu := 0;
          ShowBMenu(MenuStatus, menu, max);
        end;
        {if (event.key.key = sdlk_return) and (event.key.key.modifier = kmod_lalt) then
          begin
          if fullscreen = 1 then
          screen := SDL_SetVideoMode(CENTER_X * 2, CENTER_Y * 2, 32, ScreenFlag)
          else
          screen := SDL_SetVideoMode(CENTER_X * 2, CENTER_Y * 2, 32, SDL_FULLSCREEN);
          fullscreen := 1 - fullscreen;
          end;}
      end;
      SDL_EVENT_MOUSE_BUTTON_UP:
      begin
        if (event.button.button = SDL_BUTTON_LEFT) and (round(event.button.x / (RESOLUTIONX / screen.w)) >= 100) and (round(event.button.x / (RESOLUTIONX / screen.w)) < 147) and (round(event.button.y / (RESOLUTIONY / screen.h)) >= 50) and (round(event.button.y / (RESOLUTIONY / screen.h)) < max * 22 + 78) then
          break;
        if (event.button.button = SDL_BUTTON_RIGHT) then
        begin
          menu := -1;
          break;
        end;
      end;
      SDL_EVENT_MOUSE_MOTION:
      begin
        if (round(event.button.x / (RESOLUTIONX / screen.w)) >= 100) and (round(event.button.x / (RESOLUTIONX / screen.w)) < 147) and (round(event.button.y / (RESOLUTIONY / screen.h)) >= 50) and (round(event.button.y / (RESOLUTIONY / screen.h)) < max * 22 + 78) then
        begin
          menup := menu;
          menu := (round(event.button.y / (RESOLUTIONY / screen.h)) - 52) div 22;
          if menu > max then
            menu := max;
          if menu < 0 then
            menu := 0;
          if menup <> menu then
            ShowBMenu(MenuStatus, menu, max);
        end;
      end;
    end;
  end;
  //result:=0;
  p := 0;
  for i := 0 to 9 do
  begin
    if (MenuStatus and (1 shl i)) > 0 then
    begin
      p := p + 1;
      if p > menu then
        break;
    end;
  end;
  Result := i;
  if menu = -1 then
    Result := -1;
end;

//显示战斗主选单
procedure ShowBMenu(MenuStatus, menu, max: integer);
var
  i, p: integer;
  word: array [0 .. 9] of utf8string;
begin

  word[0] := '移動';
  word[1] := '攻擊';
  word[2] := '用毒';
  word[3] := '解毒';
  word[4] := '醫療';
  word[5] := '物品';
  word[6] := '等待';
  word[7] := '狀態';
  word[8] := '休息';
  word[9] := '自動';

  Redraw;

  DrawRectangle(screen, 100, 50, 47, max * 22 + 28, 0, ColColor(255), 50);
  p := 0;
  for i := 0 to 9 do
  begin
    if (p = menu) and ((MenuStatus and (1 shl i) > 0)) then
    begin
      DrawShadowText(screen, word[i], 103, 53 + 22 * p, ColColor($66), ColColor($64));
      p := p + 1;
    end
    else if (p <> menu) and ((MenuStatus and (1 shl i) > 0)) then
    begin
      DrawShadowText(screen, word[i], 103, 53 + 22 * p, ColColor($23), ColColor($21));
      p := p + 1;
    end;
  end;
  SDL_UpdateRect2(screen, 100, 50, 48, max * 22 + 29);

end;

//移动
procedure MoveRole(bnum: integer);
var
  s, i: integer;
begin
  //showmessage(inttostr(brole[bnum].Step));
  CalCanSelect(bnum, 0, Brole[bnum].Step);
  if SelectAim(bnum, Brole[bnum].Step) then
  begin
    MoveAmination(bnum);
  end;

end;

//移动动画

{procedure MoveAmination(bnum: integer);
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
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
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
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  i := i + s;
  end;
  Brole[bnum].X := Bx;
  Brole[bnum].Y := By;
  Bfield[2, Bx, By] := bnum;

  end;}
{var
  s, i, tempx, tempy, index, totalstep: integer;
  begin
  tempx := Ax;
  tempy := Ay;
  totalstep := brole[bnum].Step;
  index := Bfield[5, tempx, tempy];
  Setlength(movetable, totalstep - index + 1);
  SeekPath2(tempx, tempy, totalstep - index + 1);

  for i := 0 to totalstep - index - 1 do
  begin
  if (movetable[i].x > Bx) and (movetable[i].y = By) then
  Brole[bnum].Face := 3
  else if (movetable[i].x < Bx) and (movetable[i].y = By) then
  Brole[bnum].Face := 0
  else if (movetable[i].x = Bx) and (movetable[i].y > By) then
  Brole[bnum].Face := 1
  else if (movetable[i].x = Bx) and (movetable[i].y < By) then
  Brole[bnum].Face := 2;

  if Bfield[2, Bx, By] = bnum then Bfield[2, Bx, By] := -1;
  Bx := movetable[i].x;
  By := movetable[i].y;
  if Bfield[2, Bx, By] = -1 then Bfield[2, Bx, By] := bnum;
  Redraw;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  SDL_delay(30);
  end;
  Brole[bnum].X := Bx;
  Brole[bnum].Y := By;
  Bfield[2, Bx, By] := bnum;
  brole[bnum].Step := index;

  end;}

function MoveAmination(bnum: integer): boolean;
var
  s, i, a, tempx, tempy: integer;
  Xinc, Yinc: array [1 .. 4] of integer;
  linebx, lineby: array [0 .. 4096] of smallint;
  seekError: boolean;
begin
  Result := abs(Ax - Bx) + abs(Ay - By) > 0;
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
    linebx[0] := Bx;
    lineby[0] := By;
    linebx[Bfield[3, Ax, Ay]] := Ax;
    lineby[Bfield[3, Ax, Ay]] := Ay;
    a := Bfield[3, Ax, Ay] - 1;
    while a >= 0 do
    begin
      seekError := True;
      for i := 1 to 4 do
      begin
        tempx := linebx[a + 1] + Xinc[i];
        tempy := lineby[a + 1] + Yinc[i];
        if Bfield[3, tempx, tempy] = Bfield[3, linebx[a + 1], lineby[a + 1]] - 1 then
        begin
          linebx[a] := tempx;
          lineby[a] := tempy;
          seekError := False;
          if (Bfield[7, tempx, tempy] = 0) or ((Bfield[7, tempx, tempy] = 1) and (tempx = Ax) and (tempy = Ay)) then
            break;
        end;
      end;
      //如果发现寻路错误则跳出
      if seekError then
      begin
        Result := False;
        exit;
      end;
      Dec(a);
    end;

    a := 1;
    while (SDL_PollEvent(@event) or True) do
    begin
      CheckBasicEvent;
      if (Brole[bnum].Step = 0) or ((Bx = Ax) and (By = Ay)) then
        break;
      if sign(linebx[a] - Bx) > 0 then
        Brole[bnum].Face := 3
      else if sign(linebx[a] - Bx) < 0 then
        Brole[bnum].Face := 0
      else if sign(lineby[a] - By) < 0 then
        Brole[bnum].Face := 2
      else
        Brole[bnum].Face := 1;
      if Bfield[2, Bx, By] = bnum then
        Bfield[2, Bx, By] := -1;
      Bx := linebx[a];
      By := lineby[a];
      if Bfield[2, Bx, By] = -1 then
        Bfield[2, Bx, By] := bnum;
      Inc(a);
      Dec(Brole[bnum].Step);
      Redraw;
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      SDL_Delay(BATTLE_SPEED);
    end;

    Brole[bnum].X := Bx;
    Brole[bnum].Y := By;
    Brole[bnum].Acted := 2; //2表示移动过
  end;

end;

//选择目标
function SelectAim(bnum, step: integer; AreaType: integer = 0; AreaRange: integer = 0): boolean;
var
  Axp, Ayp: integer;
begin
  Ax := Bx;
  Ay := By;
  BattleSelecting := True;
  Redraw;
  SetAminationPosition(AreaType, step, AreaRange);
  DrawBFieldWithCursor(step);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  while (SDL_WaitEvent(@event)) do
  begin
    CheckBasicEvent;
    case event.type_ of
      SDL_EVENT_KEY_UP:
      begin
        if (event.key.key = SDLK_RETURN) or (event.key.key = SDLK_SPACE) then
        begin
          if (Ax >= 0) and (Ax <= 63) and (Ay >= 0) and (Ay <= 63) and (abs(Ax - Bx) + abs(Ay - By) <= step) and (Bfield[3, Ax, Ay] >= 0) then
          begin
            Result := True;
            x50[28927] := 1;
            break;
          end;
        end;
        if (event.key.key = SDLK_ESCAPE) then
        begin
          Result := False;
          x50[28927] := 0;
          break;
        end;
      end;
      SDL_EVENT_KEY_DOWN:
      begin
        Axp := Ax;
        Ayp := Ay;
        case event.key.key of
          SDLK_LEFT: Ay := Ay - 1;
          SDLK_RIGHT: Ay := Ay + 1;
          SDLK_DOWN: Ax := Ax + 1;
          SDLK_UP: Ax := Ax - 1;
        end;
        if (abs(Ax - Bx) + abs(Ay - By) > step) or (Bfield[3, Ax, Ay] < 0) or (Ax < 0) or (Ax > 63) or (Ay < 0) or (Ay > 63) then
        begin
          Ax := Axp;
          Ay := Ayp;
        end;
        event.key.key := 0;
      end;
      SDL_EVENT_MOUSE_BUTTON_UP:
      begin
        if (event.button.button = SDL_BUTTON_LEFT) then
        begin
          Result := True;
          break;
        end;
        if (event.button.button = SDL_BUTTON_RIGHT) then
        begin
          Result := False;
          break;
        end;
      end;
      SDL_EVENT_MOUSE_MOTION:
      begin
        Axp := (-round(event.button.x / (RESOLUTIONX / screen.w)) + CENTER_X + 2 * round(event.button.y / (RESOLUTIONY / screen.h)) - 2 * CENTER_Y + 18) div 36 + Bx;
        Ayp := (round(event.button.x / (RESOLUTIONX / screen.w)) - CENTER_X + 2 * round(event.button.y / (RESOLUTIONY / screen.h)) - 2 * CENTER_Y + 18) div 36 + By;
        if (abs(Axp - Bx) + abs(Ayp - By) <= step) and (Bfield[3, Axp, Ayp] >= 0) then
        begin
          Ax := Axp;
          Ay := Ayp;
        end;
      end;
    end;
    SetAminationPosition(AreaType, step, AreaRange);
    DrawBFieldWithCursor(step);
    if Bfield[2, Ax, Ay] >= 0 then
      ShowSimpleStatus(Brole[Bfield[2, Ax, Ay]].rnum, CENTER_X + 100, 50);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  end;
  BattleSelecting := False;
end;

{function SelectAim(bnum, step: integer): boolean;
  var
  Axp, Ayp: integer;
  begin
  Ax := Bx;
  Ay := By;
  //DrawBFieldWithCursor(0, step, 0);
  showsimpleStatus(Brole[Bfield[2, AX, AY]].rnum, 330, 330);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  SDL_EnableKeyRepeat(10, 100);
  while (SDL_PollEvent(@event) or true) do
  begin
  CheckBasicEvent;
  case event.type_ of
  SDL_EVENT_KEY_UP:
  begin
  if (event.key.key = sdlk_return) or (event.key.key = sdlk_space) then
  begin
  result := true;
  x50[28927] := 1;
  break;
  end;
  if (event.key.key = sdlk_escape) then
  begin
  result := false;
  x50[28927] := 0;
  break;
  end;
  end;
  SDL_EVENT_KEY_DOWN:
  begin
  if (event.key.key = sdlk_left) or (event.key.key = sdlk_kp4) then
  begin
  Ay := Ay - 1;
  if (abs(Ax - Bx) + abs(Ay - By) > step) or (Bfield[3, Ax, Ay] < 0) then Ay := Ay + 1;
  end;
  if (event.key.key = sdlk_right) or (event.key.key = sdlk_kp6) then
  begin
  Ay := Ay + 1;
  if (abs(Ax - Bx) + abs(Ay - By) > step) or (Bfield[3, Ax, Ay] < 0) then Ay := Ay - 1;
  end;
  if (event.key.key = sdlk_down) or (event.key.key = sdlk_kp2) then
  begin
  Ax := Ax + 1;
  if (abs(Ax - Bx) + abs(Ay - By) > step) or (Bfield[3, Ax, Ay] < 0) then Ax := Ax - 1;
  end;
  if (event.key.key = sdlk_up) or (event.key.key = sdlk_kp8) then
  begin
  Ax := Ax - 1;
  if (abs(Ax - Bx) + abs(Ay - By) > step) or (Bfield[3, Ax, Ay] < 0) then Ax := Ax + 1;
  end;
  DrawBFieldWithCursor(0, step, 0);
  if (Bfield[2, AX, AY] >= 0) and (Brole[Bfield[2, AX, AY]].Dead = 0) then
  showsimpleStatus(Brole[Bfield[2, AX, AY]].rnum, 330, 330);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  end;
  SDL_EVENT_MOUSE_BUTTON_UP:
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
  SDL_EVENT_MOUSE_MOTION:
  begin
  Axp := (-round(event.button.x/(resolutionx / screen.w)) + CENTER_x + 2 * round(event.button.y/(resolutiony / screen.h)) - 2 * CENTER_y + 18) div 36 + Bx;
  Ayp := (round(event.button.x/(resolutionx / screen.w)) - CENTER_x + 2 * round(event.button.y/(resolutiony / screen.h)) - 2 * CENTER_y + 18) div 36 + By;
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
  if (rrole[brole[Bfield[2, AX, AY]].rnum].Poison > 0) or (rrole[brole[Bfield[2, AX, AY]].rnum].Hurt > 0) then
  begin
  showsimpleStatus(Brole[Bfield[2, AX, AY]].rnum, 330, 330);
  SDL_UpdateRect2(screen, 352, 394 - 77, 58, 60);
  end;
  end;
  event.key.key := 0;
  event.button.button := 0;
  sdl_delay((20 * GameSpeed) div 10);
  end;
  event.key.key := 0;
  event.button.button := 0;
  end;}

//选择方向
function SelectDirector(bnum, step: integer): boolean;
var
  str: utf8string;
begin
  Ax := Bx;
  Ay := By;
  BattleSelecting := True;
  case Brole[bnum].Face of
    0: Ax := Ax - 1;
    1: Ay := Ay + 1;
    2: Ay := Ay - 1;
    3: Ax := Ax + 1;
  end;

  SetAminationPosition(1, step);
  DrawBFieldWithCursor(-1);

  str := '選擇攻擊方向';
  DrawTextWithRect(screen, str, 280, 200, 125, ColColor($23), ColColor($21));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  Result := False;
  while (SDL_WaitEvent(@event)) do
  begin
    CheckBasicEvent;
    case event.type_ of
      SDL_EVENT_KEY_UP:
      begin
        if (event.key.key = SDLK_ESCAPE) then
        begin
          Result := False;
          break;
        end;
        if (event.key.key = SDLK_LEFT) then
        begin
          Ay := By - 1;
          Ax := Bx;
        end;
        if (event.key.key = SDLK_RIGHT) then
        begin
          Ay := By + 1;
          Ax := Bx;
        end;
        if (event.key.key = SDLK_DOWN) then
        begin
          Ax := Bx + 1;
          Ay := By;
        end;
        if (event.key.key = SDLK_UP) then
        begin
          Ax := Bx - 1;
          Ay := By;
        end;
        if (event.key.key = SDLK_RETURN) or (event.key.key = SDLK_SPACE) then
        begin
          if (Ax <> Bx) or (Ay <> By) then
          begin
            Result := True;
            break;
          end;
        end;
      end;
      SDL_EVENT_MOUSE_BUTTON_UP:
      begin
        if (event.button.button = SDL_BUTTON_RIGHT) then
        begin
          Result := False;
          break;
        end;
        if (event.button.button = SDL_BUTTON_LEFT) then
        begin
          if (Ax <> Bx) or (Ay <> By) then
          begin
            Result := True;
            break;
          end;
        end;
      end;
      SDL_EVENT_MOUSE_MOTION:
      begin
        //按照所点击位置设置方向
        Ax := Bx;
        Ay := By;
        if (round(event.button.x / (RESOLUTIONX / screen.w)) < CENTER_X) and (round(event.button.y / (RESOLUTIONY / screen.h)) < CENTER_Y) then
          Ay := By - 1;
        if (round(event.button.x / (RESOLUTIONX / screen.w)) < CENTER_X) and (round(event.button.y / (RESOLUTIONY / screen.h)) >= CENTER_Y) then
          Ax := Bx + 1;
        if (round(event.button.x / (RESOLUTIONX / screen.w)) >= CENTER_X) and (round(event.button.y / (RESOLUTIONY / screen.h)) < CENTER_Y) then
          Ax := Bx - 1;
        if (round(event.button.x / (RESOLUTIONX / screen.w)) >= CENTER_X) and (round(event.button.y / (RESOLUTIONY / screen.h)) >= CENTER_Y) then
          Ay := By + 1;
      end;
    end;
    SetAminationPosition(1, step);
    DrawBFieldWithCursor(-1);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  end;
  BattleSelecting := False;
end;

//计算可以被选中的位置
//利用递归确定

{procedure SeekPath(x, y, step: integer);
  begin
  if step > 0 then
  begin
  step := step - 1;
  if Bfield[3, x, y] = 0 then
  begin
  if Bfield[5, x, y] < step then
  Bfield[5, x, y] := step;
  if Bfield[3, x + 1, y] = 0 then
  begin
  SeekPath(x + 1, y, step);
  end;
  if Bfield[3, x, y + 1] = 0 then
  begin
  SeekPath(x, y + 1, step);
  end;
  if Bfield[3, x - 1, y] = 0 then
  begin
  SeekPath(x - 1, y, step);
  end;
  if Bfield[3, x, y - 1] = 0 then
  begin
  SeekPath(x, y - 1, step);
  end;
  end;
  end;

  end;}

//寻找某一地点坐标是否在移动范围之内, 递归算法

{function SeekPath2(x, y, step: integer): integer;
  var
  i: integer;
  begin
  i := 0;
  if step > 0 then
  begin
  step := step - 1;
  if Bfield[5, x, y] >= 0 then
  begin
  if (x = Bx) and (y = By) then
  begin
  i := 1;
  end
  else
  begin
  if (Bfield[5, x + 1, y] = Bfield[5, x, y] + 1) and (i = 0) then
  begin
  i := SeekPath2(x + 1, y, step);
  if i = 1 then
  begin
  movetable[step - 1].x := x;
  movetable[step - 1].y := y;
  end;
  end;
  if (Bfield[5, x, y + 1] = Bfield[5, x, y] + 1) and (i = 0) then
  begin
  i := SeekPath2(x, y + 1, step);
  if i = 1 then
  begin
  movetable[step - 1].x := x;
  movetable[step - 1].y := y;
  end;
  end;
  if (Bfield[5, x - 1, y] = Bfield[5, x, y] + 1) and (i = 0) then
  begin
  i := SeekPath2(x - 1, y, step);
  if i = 1 then
  begin
  movetable[step - 1].x := x;
  movetable[step - 1].y := y;
  end;
  end;
  if (Bfield[5, x, y - 1] = Bfield[5, x, y] + 1) and (i = 0) then
  begin
  i := SeekPath2(x, y - 1, step);
  if i = 1 then
  begin
  movetable[step - 1].x := x;
  movetable[step - 1].y := y;
  end;
  end;
  end;
  end;
  end;
  if i = 1 then
  result := 1
  else
  result := 0;

  end;}

//计算可以被选中的位置
//利用队列
//移动过程中, 旁边有敌人, 则不能继续移动
procedure SeekPath2(x, y, step, myteam, mode: integer);
var
  Xlist: array [0 .. 4096] of integer;
  Ylist: array [0 .. 4096] of integer;
  steplist: array [0 .. 4096] of integer;
  curgrid, totalgrid: integer;
  Bgrid: array [1 .. 4] of integer; //0空位, 1建筑, 2友军, 3敌军, 4出界, 5已走过, 6水面, 7敌人身旁, 8首次无法达到(由第6层标记)
  Xinc, Yinc: array [1 .. 4] of integer;
  curX, curY, curstep, nextX, nextY, nextnextX, nextnextY: integer;
  i, j, minBeside: integer;
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
        Bgrid[i] := 0;

        nextX := curX + Xinc[i];
        nextY := curY + Yinc[i];
        if (nextX < 0) or (nextX > 63) or (nextY < 0) or (nextY > 63) then
          Bgrid[i] := 4
        else if Bfield[3, nextX, nextY] >= 0 then
          Bgrid[i] := 5
        else if Bfield[1, nextX, nextY] > 0 then
          Bgrid[i] := 1
        else if (Bfield[2, nextX, nextY] >= 0) and (Brole[Bfield[2, nextX, nextY]].Dead = 0) then
        begin
          if Brole[Bfield[2, nextX, nextY]].Team = myteam then
            Bgrid[i] := 2
          else
            Bgrid[i] := 3;
        end
        else if ((Bfield[0, nextX, nextY] div 2 >= 179) and (Bfield[0, nextX, nextY] div 2 <= 190)) or (Bfield[0, nextX, nextY] div 2 = 261) or (Bfield[0, nextX, nextY] div 2 = 511) or ((Bfield[0, nextX, nextY] div 2 >= 224) and (Bfield[0, nextX, nextY] div 2 <= 232)) or ((Bfield[0, nextX, nextY] div 2 >= 662) and (Bfield[0, nextX, nextY] div 2 <= 674)) then
          Bgrid[i] := 6
        else if Bfield[6, nextX, nextY] < 0 then
          Bgrid[i] := 8
        else
        begin
          Bgrid[i] := 0;
        end;
        for j := 1 to 4 do
        begin
          nextnextX := nextX + Xinc[j];
          nextnextY := nextY + Yinc[j];
          if (nextnextX >= 0) and (nextnextX < 63) and (nextnextY >= 0) and (nextnextY < 63) then
            if (Bfield[2, nextnextX, nextnextY] >= 0) and (Brole[Bfield[2, nextnextX, nextnextY]].Dead = 0) and (Brole[Bfield[2, nextnextX, nextnextY]].Team <> myteam) then
            begin
              BField[7, nextX, nextY] := 1;
            end;
        end;
      end;

      //移动的情况
      //若为初始位置, 不考虑旁边是敌军的情况
      //在移动过程中, 旁边没有敌军的情况下才继续移动
      if mode = 0 then
      begin
        if (curstep = 0) or ((Bgrid[1] <> 3) and (Bgrid[2] <> 3) and (Bgrid[3] <> 3) and (Bgrid[4] <> 3)) then
        begin
          for i := 1 to 4 do
          begin
            if (Bgrid[i] = 0) then
            begin
              Xlist[totalgrid] := curX + Xinc[i];
              Ylist[totalgrid] := curY + Yinc[i];
              steplist[totalgrid] := curstep + 1;
              Bfield[3, Xlist[totalgrid], Ylist[totalgrid]] := steplist[totalgrid];
              //if (Bgrid[i] = 3) then Bfield[3, Xlist[totalgrid], Ylist[totalgrid]] := step;
              //showmessage(inttostr(steplist[totalgrid]));
              totalgrid := totalgrid + 1;
            end;
          end;
        end;
      end
      else
        //非移动的情况, 攻击, 医疗等
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

{procedure CalCanSelect(bnum, mode: integer);
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
  end;}
{var
  i1, i2: integer;
  begin
  for i1 := 0 to 63 do
  begin
  for i2 := 0 to 63 do
  begin
  Bfield[3, i1, i2] := 0;
  //mode为0表示移动, 这时建筑和有人物(不包括自己)的位置不可选
  if mode = 0 then
  begin
  Bfield[5, i1, i2] := -1; //对范围内移动标记设置为-1
  if (Bfield[0, i1, i2] = 179 * 2) or (Bfield[0, i1, i2] = 511 * 2) then Bfield[3, i1, i2] := -1;
  if Bfield[1, i1, i2] > 0 then Bfield[3, i1, i2] := -1;
  if Bfield[2, i1, i2] >= 0 then Bfield[3, i1, i2] := -1;
  if Bfield[2, i1, i2] = bnum then Bfield[3, i1, i2] := 0;
  end;
  end;
  end;
  if mode = 0 then
  begin
  //递归算法的问题, 步数+1参与计算
  //移动标记的处理
  SeekPath(Brole[bnum].X, Brole[bnum].Y, Brole[bnum].Step + 1);
  for i1 := 0 to 63 do
  begin
  for i2 := 0 to 63 do
  begin
  if Bfield[5, i1, i2] = -1 then
  Bfield[3, i1, i2] := 1;
  end;
  end;
  end;

  end;}

procedure CalCanSelect(bnum, mode, step: integer);
var
  i, i1, i2, step0: integer;
begin
  if mode = 0 then
  begin
    FillChar(Bfield[3, 0, 0], sizeof(Bfield[3]), -1);
    FillChar(Bfield[7, 0, 0], sizeof(Bfield[7]), 0); //第7层标记敌人身旁的位置
    if Brole[bnum].Acted = 0 then
      FillChar(Bfield[6, 0, 0], sizeof(Bfield[6]), 0); //第6层标记第一次不能走到的位置, 小于0表示不能到达
    Bfield[3, Brole[bnum].X, Brole[bnum].Y] := 0;
    SeekPath2(Brole[bnum].X, Brole[bnum].Y, Step, Brole[bnum].Team, mode);
    if Brole[bnum].Acted = 0 then
      move(Bfield[3, 0, 0], Bfield[6, 0, 0], sizeof(Bfield[3])); //保存第一次可以走到的位置, 后续的移动只能在此范围
    {else
      for i1 := 0 to 63 do
      for i2 := 0 to 63 do
      begin
      if Bfield[6, i1, i2] = -1 then
      Bfield[3, i1, i2] := -1;
      end;}
  end;

  if mode = 1 then
  begin
    {FillChar(Bfield[3, 0, 0], 4096 * 2, -1);
      for i1 := max(Brole[bnum].X - step, 0) to min(Brole[bnum].X + step, 63) do
      begin
      step0 := abs(i1 - Brole[bnum].X);
      for i2 := max(Brole[bnum].Y - step + step0, 0) to min(Brole[bnum].Y + step - step0, 63) do
      begin
      Bfield[3, i1, i2] := 0;
      end;
      end;}
    for i1 := 0 to 63 do
      for i2 := 0 to 63 do
      begin
        Bfield[3, i1, i2] := -1;
        if abs(i1 - Brole[bnum].X) + abs(i2 - Brole[bnum].Y) <= step then
          Bfield[3, i1, i2] := 0;
      end;
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

//攻击
procedure Attack(bnum: integer);
var
  rnum, i, mnum, level, step, i1: integer;
begin
  rnum := Brole[bnum].rnum;

  while True do
  begin
    i := SelectMagic(rnum);
    if i < 0 then
      break;
    mnum := Rrole[rnum].Magic[i];
    level := Rrole[rnum].MagLevel[i] div 100 + 1;

    if i >= 0 then
      //依据攻击范围进一步选择
      case Rmagic[mnum].AttAreaType of
        0, 3:
        begin
          //CalCanSelect(bnum, 1);
          step := Rmagic[mnum].MoveDistance[level - 1];
          CalCanSelect(bnum, 1, step);
          if SelectAim(bnum, step, Rmagic[mnum].AttAreaType, Rmagic[mnum].AttDistance[level - 1]) then
          begin
            //SetAminationPosition(Rmagic[mnum].AttAreaType, Rmagic[mnum].MoveDistance[level - 1],
            //Rmagic[mnum].AttDistance[level - 1]);
            Brole[bnum].Acted := 1;
          end;
        end;
        1:
        begin
          if SelectDirector(bnum, Rmagic[mnum].MoveDistance[level - 1]) then
          begin
            //SetAminationPosition(Rmagic[mnum].AttAreaType, Rmagic[mnum].MoveDistance[level - 1],
            //Rmagic[mnum].AttDistance[level - 1]);
            Brole[bnum].Acted := 1;
          end;
        end;
        2:
        begin
          SetAminationPosition(Rmagic[mnum].AttAreaType, Rmagic[mnum].MoveDistance[level - 1], Rmagic[mnum].AttDistance[level - 1]);
          DrawBFieldWithCursor(-1);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          i1 := 0;
          while (i1 <> SDLK_RETURN) and (i1 <> SDLK_SPACE) and (i1 <> SDLK_ESCAPE) do
          begin
            i1 := WaitAnyKey;
          end;
          if (i1 <> SDLK_ESCAPE) then
          begin
            Brole[bnum].Acted := 1;
          end;
        end;
      end;
    if Brole[bnum].Acted = 1 then
      break;
  end;
  //如果行动成功, 武功等级增加, 播放效果
  AttackAction(bnum, i, mnum, level);

end;

procedure AttackAction(bnum, i, mnum, level: integer); overload;
var
  rnum, i1: integer;
begin
  rnum := Brole[bnum].rnum;
  if Brole[bnum].Acted = 1 then
  begin
    for i1 := 0 to sign(Rrole[rnum].AttTwice) do
    begin
      Rrole[rnum].MagLevel[i] := Rrole[rnum].MagLevel[i] + random(2) + 1;
      if Rrole[rnum].MagLevel[i] > 999 then
        Rrole[rnum].MagLevel[i] := 999;
      if Rmagic[mnum].UnKnow[4] > 0 then
        CallEvent(Rmagic[mnum].UnKnow[4])
      else
        AttackAction(bnum, mnum, level);
    end;
  end;
end;

//攻击效果, 保持与之前的兼容不修改名字
procedure AttackAction(bnum, mnum, level: integer); overload;
begin
  ShowMagicName(mnum);
  PlayActionAmination(bnum, Rmagic[mnum].MagicType, mnum);
  PlayMagicAmination(bnum, Rmagic[mnum].AmiNum); //武功效果
  CalHurtRole(bnum, mnum, level); //计算被打到的人物
  ShowHurtValue(Rmagic[mnum].HurtType); //显示数字

end;

//mode = 1 means the hidden weapon.
procedure ShowMagicName(mnum: integer; mode: integer = 0);
var
  l: integer;
  str: utf8string;
begin
  Redraw;
  str := CP950ToUtf8(@Rmagic[mnum].Name);
  if mode = 1 then
    str := CP950ToUtf8(@Ritem[mnum].Name);
  l := drawlength(str);
  DrawTextWithRect(screen, str, CENTER_X - l * 5, CENTER_Y - 150, l * 10 + 7, ColColor($14), ColColor($16));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  SDL_Delay(500);

end;

//选择武功
function SelectMagic(rnum: integer): integer;
var
  i, p, MenuStatus, max, menu, menup: integer;
  menuString, menuEngString: array [0 .. 9] of utf8string;
begin
  MenuStatus := 0;
  max := 0;
  //setlength(menustring, 10);
  //setlength(menuengstring, 10);
  for i := 0 to 9 do
  begin
    if Rrole[rnum].Magic[i] > 0 then
    begin
      MenuStatus := MenuStatus or (1 shl i);
      menuString[i] := cp950toutf8(@Rmagic[Rrole[rnum].Magic[i]].Name);
      menuEngString[i] := format('%3d', [Rrole[rnum].MagLevel[i] div 100 + 1]);
      max := max + 1;
    end;
  end;
  max := max - 1;

  Redraw;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  menu := 0;
  ShowMagicMenu(MenuStatus, menu, max, menuString, menuEngString);
  //SDL_UpdateRect2(screen,0,0,screen.w,screen.h);
  Result := 0;
  while (SDL_WaitEvent(@event)) do
  begin
    CheckBasicEvent;
    case event.type_ of
      SDL_EVENT_KEY_UP:
      begin
        if (event.key.key = SDLK_RETURN) or (event.key.key = SDLK_SPACE) then
        begin
          break;
        end;
        if (event.key.key = SDLK_ESCAPE) then
        begin
          Result := -1;
          break;
        end;
        if (event.key.key = SDLK_UP) then
        begin
          menu := menu - 1;
          if menu < 0 then
            menu := max;
          ShowMagicMenu(MenuStatus, menu, max, menuString, menuEngString);
        end;
        if (event.key.key = SDLK_DOWN) then
        begin
          menu := menu + 1;
          if menu > max then
            menu := 0;
          ShowMagicMenu(MenuStatus, menu, max, menuString, menuEngString);
        end;
      end;
      SDL_EVENT_MOUSE_BUTTON_UP:
      begin
        if (event.button.button = SDL_BUTTON_LEFT) then
        begin
          break;
        end;
        if (event.button.button = SDL_BUTTON_RIGHT) then
        begin
          Result := -1;
          break;
        end;
      end;
      SDL_EVENT_MOUSE_MOTION:
      begin
        if (round(event.button.x / (RESOLUTIONX / screen.w)) >= 100) and (round(event.button.x / (RESOLUTIONX / screen.w)) < 267) and (round(event.button.y / (RESOLUTIONY / screen.h)) >= 50) and (round(event.button.y / (RESOLUTIONY / screen.h)) < max * 22 + 78) then
        begin
          menup := menu;
          menu := (round(event.button.y / (RESOLUTIONY / screen.h)) - 52) div 22;
          if menu > max then
            menu := max;
          if menu < 0 then
            menu := 0;
          if menup <> menu then
            ShowMagicMenu(MenuStatus, menu, max, menuString, menuEngString);
        end;
      end;
    end;
  end;
  //result:=0;
  if Result >= 0 then
  begin
    p := 0;
    for i := 0 to 9 do
    begin
      if (MenuStatus and (1 shl i)) > 0 then
      begin
        p := p + 1;
        if p > menu then
          break;
      end;
    end;
    Result := i;
  end;

end;

//显示武功选单
procedure ShowMagicMenu(MenuStatus, menu, max: integer; menuString, menuEngString: array of utf8string);
var
  i, p: integer;
begin
  Redraw;
  DrawRectangle(screen, 100, 50, 167, max * 22 + 28, 0, ColColor(255), 30);
  p := 0;
  for i := 0 to 9 do
  begin
    if (p = menu) and ((MenuStatus and (1 shl i) > 0)) then
    begin
      DrawShadowText(screen, menuString[i], 103, 53 + 22 * p, ColColor($66), ColColor($64));
      DrawEngShadowText(screen, menuEngString[i], 223, 53 + 22 * p, ColColor($66), ColColor($64));
      p := p + 1;
    end
    else if (p <> menu) and ((MenuStatus and (1 shl i) > 0)) then
    begin
      DrawShadowText(screen, menuString[i], 103, 53 + 22 * p, ColColor($23), ColColor($21));
      DrawEngShadowText(screen, menuEngString[i], 223, 53 + 22 * p, ColColor($23), ColColor($21));
      p := p + 1;
    end;
  end;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

end;

//设定攻击范围
procedure SetAminationPosition(mode, step: integer; range: integer = 0); overload;
begin
  SetAminationPosition(Bx, By, Ax, Ay, mode, step, range);
end;

procedure SetAminationPosition(Bx, By, Ax, Ay, mode, step: integer; range: integer = 0); overload;
var
  i, i1, i2: integer;
begin
  FillChar(Bfield[4, 0, 0], sizeof(Bfield[4]), 0);
  //按攻击类型
  case mode of
    0:
    begin
      Bfield[4, Ax, Ay] := 1;
    end;
    3:
    begin
      for i1 := max(Ax - range, 0) to min(Ax + range, 63) do
        for i2 := max(Ay - range, 0) to min(Ay + range, 63) do
          Bfield[4, i1, i2] := (abs(i1 - Bx) + abs(i2 - By)) * 1 + random(24) + 1;
    end;
    1:
    begin
      i := 1;
      i1 := sign(Ax - Bx);
      i2 := sign(Ay - By);
      if i1 > 0 then
        step := min(63 - Bx, step);
      if i2 > 0 then
        step := min(63 - By, step);
      if i1 < 0 then
        step := min(Bx, step);
      if i2 < 0 then
        step := min(By, step);
      if (i1 = 0) and (i2 = 0) then
        step := 0;
      while i <= step do
      begin
        Bfield[4, Bx + i1 * i, By + i2 * i] := i * 2;
        i := i + 1;
      end;
    end;
    2:
    begin
      for i1 := max(Bx - step, 0) to min(Bx + step, 63) do
        Bfield[4, i1, By] := abs(i1 - Bx) * 2;
      for i2 := max(By - step, 0) to min(By + step, 63) do
        Bfield[4, Bx, i2] := abs(i2 - By) * 2;
    end;
  end;
  case mode of
    0: maxdelaypicnum := 1;
    3: maxdelaypicnum := 24;
    1: maxdelaypicnum := step * 4;
    2: maxdelaypicnum := step * 4;
  end;

end;

//显示武功效果, forTeam: 行动目标为队友
//mode: 决定闪烁颜色, 与showhurtvalue相同
procedure PlayMagicAmination(bnum, enum: integer; ForTeam: integer = 0; mode: integer = 0);
var
  beginpic, i, endpic, x, y, z, min, max, i1, i2: integer;
  posA, posB: TPosition;
  color1, color2: uint32;
  str: utf8string;
begin
  SelectModeColor(mode, color1, color2, str, 1);
  min := 1000;
  max := 0;
  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      if Bfield[4, i1, i2] > 0 then
      begin
        if Bfield[4, i1, i2] > max then
          max := Bfield[4, i1, i2];
        if Bfield[4, i1, i2] < min then
          min := Bfield[4, i1, i2];
      end;
    end;

  beginpic := 0;
  //含音效
  posA := GetPositionOnScreen(Ax, Ay, CENTER_X, CENTER_Y);
  posB := GetPositionOnScreen(Bx, By, CENTER_X, CENTER_Y);
  x := posA.x - posB.x;
  y := posB.y - posA.y;
  z := -((Ax + Ay) - (Bx + By)) * 9;
  playsoundE(enum, 0, x, y, z);
  //playsoundE(enum, 0, x, y, z);
  for i := 0 to enum - 1 do
    beginpic := beginpic + effectlist[i];
  endpic := beginpic + effectlist[enum] - 1;

  {for i := beginpic to endpic do
    begin
    DrawBFieldWithEft(i);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    sdl_delay(20);
    end;}
  i := beginpic;
  while (SDL_PollEvent(@event) or True) do
  begin
    CheckBasicEvent;
    DrawBFieldWithEft(i, beginpic, endpic, min, bnum, forteam, 1, $FFFFFFFF);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    SDL_Delay(BATTLE_SPEED);
    i := i + 1;
    if i > endpic + max - min then
      break;
  end;
  Brole[bnum].Pic := 0;
end;

//判断是否有非行动方角色在攻击范围之内
procedure CalHurtRole(bnum, mnum, level: integer);
var
  i, rnum, hurt, addpoi, mp: integer;
begin
  rnum := Brole[bnum].rnum;
  Rrole[rnum].PhyPower := Rrole[rnum].PhyPower - 3;
  if Rrole[rnum].CurrentMP < Rmagic[mnum].NeedMP * ((level + 1) div 2) then
    level := Rrole[rnum].CurrentMP div Rmagic[mnum].NeedMP * 2;
  if level > 10 then
    level := 10;
  Rrole[rnum].CurrentMP := Rrole[rnum].CurrentMP - Rmagic[mnum].NeedMP * ((level + 1) div 2);
  for i := 0 to BRoleAmount - 1 do
  begin
    Brole[i].ShowNumber := -1;
    if (Bfield[4, Brole[i].X, Brole[i].Y] <> 0) and (Brole[bnum].Team <> Brole[i].Team) and (Brole[i].Dead = 0) then
    begin
      //生命伤害
      if (Rmagic[mnum].HurtType = 0) then
      begin
        hurt := CalHurtValue(bnum, i, mnum, level);
        Brole[i].ShowNumber := hurt;
        //受伤
        Rrole[Brole[i].rnum].CurrentHP := Rrole[Brole[i].rnum].CurrentHP - hurt;
        Rrole[Brole[i].rnum].Hurt := Rrole[Brole[i].rnum].Hurt + hurt div LIFE_HURT;
        if Rrole[Brole[i].rnum].Hurt > 99 then
          Rrole[Brole[i].rnum].Hurt := 99;
        Brole[bnum].ExpGot := Brole[bnum].ExpGot + hurt div 2;
        if Rrole[Brole[i].rnum].CurrentHP <= 0 then
          Brole[bnum].ExpGot := Brole[bnum].ExpGot + hurt div 2;
        if Brole[bnum].ExpGot < 0 then
          Brole[bnum].ExpGot := 32767;
      end;
      //内力伤害
      if (Rmagic[mnum].HurtType = 1) then
      begin
        hurt := Rmagic[mnum].HurtMP[level - 1] + random(5) - random(5);
        Brole[i].ShowNumber := hurt;
        Rrole[Brole[i].rnum].CurrentMP := Rrole[Brole[i].rnum].CurrentMP - hurt;
        if Rrole[Brole[i].rnum].CurrentMP <= 0 then
          Rrole[Brole[i].rnum].CurrentMP := 0;
        //增加己方内力及最大值
        Rrole[rnum].CurrentMP := Rrole[rnum].CurrentMP + hurt;
        Brole[bnum].ExpGot := Brole[bnum].ExpGot + hurt;
        Rrole[rnum].MaxMP := Rrole[rnum].MaxMP + random(hurt div 2);
        if Rrole[rnum].MaxMP > MAX_MP then
          Rrole[rnum].MaxMP := MAX_MP;
        if Rrole[rnum].CurrentMP > Rrole[rnum].MaxMP then
          Rrole[rnum].CurrentMP := Rrole[rnum].MaxMP;
      end;
      //中毒
      addpoi := Rrole[rnum].AttPoi div 5 + Rmagic[mnum].Poison * level div 2 * (100 - Rrole[Brole[i].rnum].DefPoi) div 100;
      if addpoi + Rrole[Brole[i].rnum].Poison > 99 then
        addpoi := 99 - Rrole[Brole[i].rnum].Poison;
      if addpoi < 0 then
        addpoi := 0;
      if Rrole[Brole[i].rnum].DefPoi >= 99 then
        addpoi := 0;
      Rrole[Brole[i].rnum].Poison := Rrole[Brole[i].rnum].Poison + addpoi;
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
  for i := 0 to BRoleAmount - 1 do
  begin
    if (Brole[i].Team = Brole[bnum1].Team) and (Brole[i].Dead = 0) and (Rrole[Brole[i].rnum].Knowledge > MIN_KNOWLEDGE) then
      k1 := k1 + Rrole[Brole[i].rnum].Knowledge;
    if (Brole[i].Team = Brole[bnum2].Team) and (Brole[i].Dead = 0) and (Rrole[Brole[i].rnum].Knowledge > MIN_KNOWLEDGE) then
      k2 := k2 + Rrole[Brole[i].rnum].Knowledge;
  end;
  rnum1 := Brole[bnum1].rnum;
  rnum2 := Brole[bnum2].rnum;
  if level > 0 then
    mhurt := Rmagic[mnum].Attack[level - 1]
  else
    mhurt := 0;

  att := Rrole[rnum1].Attack + k1 * 3 div 2 + mhurt div 3;
  def := Rrole[rnum2].Defence * 2 + k2 * 3;

  case Rmagic[mnum].MagicType of
    1:
    begin
      att := att + Rrole[rnum1].Fist;
      def := def + Rrole[rnum2].Fist;
    end;
    2:
    begin
      att := att + Rrole[rnum1].Sword;
      def := def + Rrole[rnum2].Sword;
    end;
    3:
    begin
      att := att + Rrole[rnum1].Knife;
      def := def + Rrole[rnum2].Knife;
    end;
    4:
    begin
      att := att + Rrole[rnum1].Unusual;
      def := def + Rrole[rnum2].Unusual;
    end;
  end;

  //攻击, 防御按伤害的折扣
  att := att * (100 - Rrole[rnum1].Hurt div 2) div 100;
  def := def * (100 - Rrole[rnum2].Hurt div 2) div 100;

  //如果有武器增加攻击, 检查配合列表
  if Rrole[rnum1].Equip[0] >= 0 then
  begin
    att := att + Ritem[Rrole[rnum1].Equip[0]].AddAttack;
    for i := 0 to MAX_WEAPON_MATCH - 1 do
    begin
      if (Rrole[rnum1].Equip[0] = matchlist[i, 0]) and (mnum = matchlist[i, 1]) then
      begin
        att := att + matchlist[i, 2] * 2 div 3;
        break;
      end;
    end;
  end;
  //防具增加攻击
  if Rrole[rnum1].Equip[1] >= 0 then
    att := att + Ritem[Rrole[rnum1].Equip[1]].AddAttack;
  //武器, 防具增加防御
  if Rrole[rnum2].Equip[0] >= 0 then
    def := def + Ritem[Rrole[rnum2].Equip[0]].AddDefence;
  if Rrole[rnum2].Equip[1] >= 0 then
    def := def + Ritem[Rrole[rnum2].Equip[1]].AddDefence;
  //showmessage(inttostr(att)+' '+inttostr(def));
  Result := att - def + random(20) - random(20);
  dis := abs(Brole[bnum1].X - Brole[bnum2].X) + abs(Brole[bnum1].Y - Brole[bnum2].Y);
  if dis > 10 then
    dis := 10;

  Result := max(Result, att div 10 + random(10) - random(10));
  Result := Result * (100 - (dis - 1) * 3) div 100;
  if (Result <= 0) or (level <= 0) then
    Result := random(10) + 1;
  if (Result > 9999) then
    Result := 9999;
  //showmessage(inttostr(result));

end;

//AI专用
function CalHurtValue2(bnum1, bnum2, mnum, level: integer): integer;
begin
  Result := CalHurtValue(bnum1, bnum2, mnum, level);
  if Result >= Rrole[Brole[bnum2].rnum].CurrentHP then
    Result := Result * 3 div 2;
  if Rmagic[mnum].HurtType = 1 then
    Result := (Rmagic[mnum].HurtMP[level - 1] * 3) div 2;
end;

//选择颜色
//0红色, 2绿色, 4蓝色, 3黄色, 1紫色
procedure SelectModeColor(mode: integer; var color1, color2: uint32; var str: utf8string; trans: integer = 0);
var
  tempcolor: TSDL_Color;
begin
  case mode of
    0:
    begin
      color1 := ColColor($10);
      color2 := ColColor($14);
      str := '-%d';
    end;
    1:
    begin
      color1 := ColColor($50);
      color2 := ColColor($53);
      str := '-%d';
    end;
    2:
    begin
      color1 := ColColor($30);
      color2 := ColColor($32);
      str := '+%d';
    end;
    3:
    begin
      color1 := ColColor($7);
      color2 := ColColor($5);
      str := '+%d';
    end;
    4:
    begin
      color1 := ColColor($91);
      color2 := ColColor($93);
      str := '-%d';
    end;
  end;
  if trans = 1 then
  begin
    tempcolor := (TSDL_Color(color1));
    color1 := SDL_MapSurfaceRGB(screen, tempcolor.r, tempcolor.g, tempcolor.b);
  end;
end;

//显示数字
procedure ShowHurtValue(mode: integer);
var
  i, i1, x, y: integer;
  color1, color2: uint32;
  word: array of utf8string;
  str: utf8string;
  pos: TPosition;
begin
  SelectModeColor(mode, color1, color2, str);
  setlength(word, BRoleAmount);
  for i := 0 to BRoleAmount - 1 do
  begin
    if Brole[i].ShowNumber > 0 then
    begin
      //x := -(Brole[i].X - Bx) * 18 + (Brole[i].Y - By) * 18 + CENTER_X - 10;
      //y := (Brole[i].X - Bx) * 9 + (Brole[i].Y - By) * 9 + CENTER_Y - 40;
      word[i] := format(str, [Brole[i].ShowNumber]);
    end;
    Brole[i].ShowNumber := -1;
  end;
  i1 := 0;
  while SDL_PollEvent(@event) or True do
  begin
    CheckBasicEvent;
    Redraw;
    for i := 0 to BRoleAmount - 1 do
    begin
      x := -(Brole[i].X - Bx) * 18 + (Brole[i].Y - By) * 18 + CENTER_X - 10;
      y := (Brole[i].X - Bx) * 9 + (Brole[i].Y - By) * 9 + CENTER_Y - 40;
      if word[i] <> '' then
        DrawEngShadowText(screen, word[i], x, y - i1 * 2, color1, color2);
      //showmessage(word[i]);
    end;
    SDL_Delay(BATTLE_SPEED);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    i1 := i1 + 1;
    if i1 > 10 then
      break;
  end;
  Redraw;

end;

//计算中毒减少的生命
procedure CalPoiHurtLife;
var
  i: integer;
  p: boolean;
begin
  p := False;
  for i := 0 to BRoleAmount - 1 do
  begin
    Brole[i].ShowNumber := -1;
    if (Rrole[Brole[i].rnum].Poison > 0) and (Brole[i].Dead = 0) and (Brole[i].Acted = 1) then
    begin
      if POISON_HURT <> 0 then
        Rrole[Brole[i].rnum].CurrentHP := Rrole[Brole[i].rnum].CurrentHP - Rrole[Brole[i].rnum].Poison div POISON_HURT - 1;
      if Rrole[Brole[i].rnum].CurrentHP <= 0 then
        Rrole[Brole[i].rnum].CurrentHP := 1;
      //Brole[i].ShowNumber := Rrole[Brole[i].rnum, 20] div 2+1;
      //p := true;
    end;
  end;
  //if p then showhurtvalue(0);

end;

//设置生命低于0的人物为已阵亡, 主要是清除所占的位置
procedure ClearDeadRolePic;
var
  i, i1, i2, rnum: integer;
  pos: TPosition;
  needeffect: boolean;
begin
  //检测是否需要效果
  needeffect := False;
  for i := 0 to BRoleAmount - 1 do
  begin
    if (Rrole[Brole[i].rnum].CurrentHP <= 0) and (Brole[i].Dead = 0) then
    begin
      needeffect := True;
      break;
    end;
  end;
  //撤退渐变效果
  i := 0;
  while (SDL_PollEvent(@event) or True) and needeffect do
  begin
    CheckBasicEvent;
    DrawBfieldWithoutRole(Bx, By);
    for i1 := 0 to 63 do
      for i2 := 0 to 63 do
      begin
        if (Bfield[2, i1, i2] >= 0) and (Brole[Bfield[2, i1, i2]].Dead = 0) then
        begin
          rnum := Brole[Bfield[2, i1, i2]].rnum;
          if Rrole[rnum].CurrentHP <= 0 then
          begin
            DrawRoleOnBfield(i1, i2, 0, i, i shl 8 + 75);
          end
          else
            DrawRoleOnBfield(i1, i2);
        end;
      end;
    DrawProgress;
    UpdateAllScreen;
    SDL_Delay(BATTLE_SPEED div 2);
    i := i + 5;
    if i > 100 then
      break;
  end;
  for i := 0 to BRoleAmount - 1 do
  begin
    if Rrole[Brole[i].rnum].CurrentHP <= 0 then
    begin
      //pos := GetPositionOnScreen(Brole[i].X, Brole[i].Y, Bx, By);
      //DrawBPic2(Rrole[Brole[i].rnum].HeadNum * 4 + Brole[i].Face + BEGIN_BATTLE_ROLE_PIC, pos.x, pos.y, 0, 75, Brole[i].X + Brole[i].Y, $FFFFFFFF, 50);
      Brole[i].Dead := 1;
      bfield[2, Brole[i].X, Brole[i].Y] := -1;
      //bmount
    end;
  end;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  //sdl_delay(1000);
  for i := 0 to BRoleAmount - 1 do
    if Brole[i].Dead = 0 then
      bfield[2, Brole[i].X, Brole[i].Y] := i;

end;

//等待, 似乎不太完善
procedure Wait(bnum: integer);
var
  i, i1, i2, x: integer;
begin
  Brole[bnum].Acted := 0;
  Brole[BRoleAmount] := Brole[bnum];

  for i := bnum to BRoleAmount - 1 do
  begin
    Brole[i] := Brole[i + 1];
  end;

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
      Rrole[rnum].CurrentHP := Rrole[rnum].CurrentHP + Rrole[rnum].MaxHP div 2;
      if Rrole[rnum].CurrentHP <= 0 then
        Rrole[rnum].CurrentHP := 1;
      if Rrole[rnum].CurrentHP > Rrole[rnum].MaxHP then
        Rrole[rnum].CurrentHP := Rrole[rnum].MaxHP;
      Rrole[rnum].CurrentMP := Rrole[rnum].CurrentMP + Rrole[rnum].MaxMP div 20;
      if Rrole[rnum].CurrentMP > Rrole[rnum].MaxMP then
        Rrole[rnum].CurrentMP := Rrole[rnum].MaxMP;
      Rrole[rnum].PhyPower := Rrole[rnum].PhyPower + MAX_PHYSICAL_POWER div 10;
      if Rrole[rnum].PhyPower > MAX_PHYSICAL_POWER then
        Rrole[rnum].PhyPower := MAX_PHYSICAL_POWER;
    end
    else
    begin
      Rrole[rnum].Hurt := 0;
      Rrole[rnum].Poison := 0;
      Rrole[rnum].CurrentHP := Rrole[rnum].MaxHP;
      Rrole[rnum].CurrentMP := Rrole[rnum].MaxMP;
      Rrole[rnum].PhyPower := MAX_PHYSICAL_POWER * 9 div 10;
    end;
  end;

end;

//增加经验
procedure AddExp;
var
  i, rnum, basicvalue, amount, p, pmax: integer;
  str: utf8string;
begin
  pmax := 65535;
  amount := CalRNum(0);
  for i := 0 to BRoleAmount - 1 do
  begin
    rnum := Brole[i].rnum;
    basicvalue := Brole[i].ExpGot;
    p := min(Rrole[rnum].Exp + basicvalue, pmax);
    Rrole[rnum].Exp := p;
    p := min(Rrole[rnum].ExpForBook + basicvalue div 5 * 4, pmax);
    Rrole[rnum].ExpForBook := p;
    p := min(Rrole[rnum].ExpForItem + basicvalue div 5 * 3, pmax);
    Rrole[rnum].ExpForItem := p;

    if amount > 0 then
      basicvalue := warsta.ExpGot div amount
    else
      basicvalue := 0;
    //设置问题，菠萝的基本经验过低
    if MODVersion = 22 then
      basicvalue := basicvalue * 30;
    if (Brole[i].Team = 0) and (Brole[i].Dead = 0) then
    begin
      p := min(Rrole[rnum].Exp + basicvalue, pmax);
      Rrole[rnum].Exp := p;
      p := min(Rrole[rnum].ExpForBook + basicvalue div 5 * 4, pmax);
      Rrole[rnum].ExpForBook := p;
      p := min(Rrole[rnum].ExpForItem + basicvalue div 5 * 3, pmax);
      Rrole[rnum].ExpForItem := p;
      ShowSimpleStatus(rnum, 100, 50);
      DrawRectangle(screen, 100, 235, 145, 25, 0, ColColor(255), 50);
      str := '得經驗';
      DrawShadowText(screen, str, 103, 237, ColColor($23), ColColor($21));
      str := format('%5d', [Brole[i].ExpGot + basicvalue]);
      DrawEngShadowText(screen, str, 188, 237, ColColor($66), ColColor($64));
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      Redraw;
      WaitAnyKey;
    end;

  end;

end;

//检查是否能够升级
procedure CheckLevelUp;
var
  i, rnum: integer;
begin
  RecordFreshScreen(0, 0, screen.w, screen.h);
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
  str: utf8string;
begin

  rnum := Brole[bnum].rnum;
  Rrole[rnum].MaxHP := Rrole[rnum].MaxHP + Rrole[rnum].IncLife * 3 + random(6);
  Rrole[rnum].MaxHP := min(Rrole[rnum].MaxHP, MAX_HP);
  Rrole[rnum].CurrentHP := Rrole[rnum].MaxHP;

  add := Rrole[rnum].Aptitude div 15 + 1;
  if MAX_ADD_PRO = 0 then
    add := random(add) + 1;

  Rrole[rnum].MaxMP := Rrole[rnum].MaxMP + (9 - add) * 3;
  Rrole[rnum].MaxMP := min(Rrole[rnum].MaxMP, MAX_MP);
  Rrole[rnum].CurrentMP := Rrole[rnum].MaxMP;

  Rrole[rnum].Attack := Rrole[rnum].Attack + add;
  Rrole[rnum].Speed := Rrole[rnum].Speed + add;
  Rrole[rnum].Defence := Rrole[rnum].Defence + add;

  for i := 46 to 54 do
  begin
    if Rrole[rnum].Data[i] > 0 then
      Rrole[rnum].Data[i] := Rrole[rnum].Data[i] + random(3) + 1;
  end;
  for i := 43 to 58 do
  begin
    Rrole[rnum].Data[i] := min(Rrole[rnum].Data[i], MaxProList[i]);
  end;

  Rrole[rnum].PhyPower := MAX_PHYSICAL_POWER;
  Rrole[rnum].Hurt := 0;
  Rrole[rnum].Poison := 0;

  if Brole[bnum].Team = 0 then
  begin
    ShowStatus(rnum);
    str := '昇級';
    DrawTextWithRect(screen, str, 58, CENTER_Y - 150, 46, ColColor($23), ColColor($21));
    WaitAnyKey;
  end;

end;

//检查身上秘笈
procedure CheckBook;
var
  i, j, i1, i2, p, rnum, inum, mnum, mlevel, needexp, needitem, needitemamount, itemamount, maxtimes, times: integer;
  str: utf8string;
  eat: boolean;
  ap: integer;
begin
  for i := 0 to BRoleAmount - 1 do
  begin
    rnum := Brole[i].rnum;
    inum := Rrole[rnum].PracticeBook;
    if inum >= 0 then
    begin
      mlevel := 0;
      mnum := Ritem[inum].Magic;
      if mnum > 0 then
        for i1 := 0 to 9 do
          if Rrole[rnum].Magic[i1] = mnum then
          begin
            mlevel := Rrole[rnum].MagLevel[i1] div 100 + 1;
            break;
          end;
      p := 0;
      times := 0;
      ap := 7 - Rrole[rnum].Aptitude div 15;
      //如果可以练出武功则计算次数
      if mnum > 0 then
      begin
        while (mlevel < 10) do
        begin
          needexp := mlevel * Ritem[inum].NeedExp * ap;
          if mlevel = 0 then
            needexp := Ritem[inum].NeedExp * ap;
          //writeln(Rrole[rnum].ExpForBook,',',needexp,',',mlevel,',',p);
          if (Rrole[rnum].ExpForBook >= needexp) and (mlevel < 10) then
          begin
            Rrole[rnum].ExpForBook := Rrole[rnum].ExpForBook - needexp;
            if mnum > 0 then
            begin
              instruct_33(rnum, mnum, 1);
              mlevel := mlevel + 1;
              times := times + 1;
            end;
            p := p + 1;
            if (p >= 10) or (mlevel > 10) then
              break;
            {if (mnum <= 0) and not eat then
              begin
              WaitAnyKey;
              break;
              end;}
            //ShowStatus(rnum);
            //waitanykey;
          end
          else
            break;
        end;
        if times > 0 then
        begin
          Redraw;
          EatOneItem(rnum, inum, times);
          WaitAnyKey;
        end;
      end
      else
      begin
        times := Rrole[rnum].ExpForBook div max(1, Ritem[inum].NeedExp * ap);
        if times > 0 then
        begin
          Redraw;
          Rrole[rnum].ExpForBook := Rrole[rnum].ExpForBook - Ritem[inum].NeedExp * ap * EatOneItem(rnum, inum, times);
          WaitAnyKey;
        end;
      end;

      {if (Rrole[rnum].ExpForBook >= needexp) and (mlevel < 10) then
        begin
        redraw;
        EatOneItem(rnum, inum);
        waitanykey;
        redraw;
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

        if mnum > 0 then
        instruct_33(rnum, mnum, 1);
        Rrole[rnum].ExpForBook := 0;
        //ShowStatus(rnum);
        //waitanykey;
        end;}
      //是否能够炼出物品
      if (Rrole[rnum].ExpForItem >= Ritem[inum].NeedExpForItem) and (Ritem[inum].NeedExpForItem > 0) and (Brole[i].Team = 0) then
      begin
        Redraw;
        p := 0;
        for i2 := 0 to 4 do
        begin
          if Ritem[inum].GetItem[i2] >= 0 then
            p := p + 1;
        end;
        p := random(p);
        needitem := Ritem[inum].NeedMaterial;
        if Ritem[inum].GetItem[p] >= 0 then
        begin
          needitemamount := Ritem[inum].NeedMatAmount[p];
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
            DrawRectangle(screen, 115, 63, 145, 25, 0, ColColor(255), 50);
            str := '製藥成功';
            DrawShadowText(screen, str, 147, 65, ColColor($23), ColColor($21));

            instruct_2(Ritem[inum].GetItem[p], 1 + random(5));
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
  Result := 0;
  for i := 0 to BRoleAmount - 1 do
  begin
    if (Brole[i].Team = team) and (Brole[i].Dead = 0) then
      Result := Result + 1;
  end;

end;

//战斗中物品选单
procedure BattleMenuItem(bnum: integer);
var
  rnum, inum, mode: integer;
  str: utf8string;
begin
  if MenuItem then
  begin
    inum := CurItem;
    rnum := Brole[bnum].rnum;
    mode := Ritem[inum].ItemType;
    case mode of
      3:
      begin
        EatOneItem(rnum, inum);
        instruct_32(inum, -1);
        Brole[bnum].Acted := 1;
        WaitAnyKey;
      end;
      4:
      begin
        UseHiddenWeapon(bnum, inum);
      end;
    end;
  end;

end;

//动作动画
procedure PlayActionAmination(bnum, mode: integer; mnum: integer = -1);
var
  d1, d2, dm, rnum, i, beginpic, endpic, idx, grp, tnum, len, spic, Ax1, Ay1: integer;
  filename: utf8string;
begin
  Ax1 := Ax;
  Ay1 := Ay;
  //方向至少朝向一个将被打中的敌人
  for i := 0 to BRoleAmount - 1 do
  begin
    if (Brole[i].Team <> Brole[bnum].Team) and (Brole[i].Dead = 0) and (Bfield[4, Brole[i].X, Brole[i].Y] > 0) then
    begin
      Ax1 := Brole[i].X;
      Ay1 := Brole[i].Y;
      break;
    end;
  end;
  d1 := Ax1 - Bx;
  d2 := Ay1 - By;
  dm := abs(d1) - abs(d2);
  if (d1 <> 0) or (d2 <> 0) then
    if (dm >= 0) then
      if d1 < 0 then
        Brole[bnum].Face := 0
      else
        Brole[bnum].Face := 3
    else if d2 < 0 then
      Brole[bnum].Face := 2
    else
      Brole[bnum].Face := 1;

  Redraw;
  rnum := Brole[bnum].rnum;
  if Rrole[rnum].AmiFrameNum[mode] > 0 then
  begin
    beginpic := 0;
    for i := 0 to 4 do
    begin
      if i >= mode then
        break;
      beginpic := beginpic + Rrole[rnum].AmiFrameNum[i] * 4;
    end;
    beginpic := beginpic + Brole[bnum].Face * Rrole[rnum].AmiFrameNum[mode];
    endpic := beginpic + Rrole[rnum].AmiFrameNum[mode] - 1;
    if (beginpic < 0) or (beginpic > endpic) then
    begin
      beginpic := 0;
      endpic := 0;
    end;
    filename := formatfloat('fight/fight000', Rrole[rnum].HeadNum);
    FPicAmount := LoadIdxGrp(filename + '.idx', filename + '.grp', FIdx[Rrole[rnum].HeadNum], FPic[Rrole[rnum].HeadNum]);

    //if PNG_TILE = 1 then
    //LoadPNGTiles('resource/' + filename + '/', FPNGIndex, FPNGTile, 1);

    spic := beginpic + Rrole[rnum].SoundDealy[mode] - 1;
    //PlaySound2(rmagic[mnum].SoundNum, 0);
    i := beginpic;
    while (SDL_PollEvent(@event) or True) do
    begin
      CheckBasicEvent;
      DrawBFieldWithAction(bnum, i);
      if (i = spic) and (mnum >= 0) then
        PlaySoundA(Rmagic[mnum].SoundNum, 0);
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      SDL_Delay(BATTLE_SPEED);
      i := i + 1;
      if i > endpic then
      begin
        //RecordFreshScreen(0, 0, screen.w, screen.h);
        Brole[bnum].Pic := endpic;
        break;
      end;
    end;
  end;

end;

//用毒
procedure UsePoison(bnum: integer);
var
  rnum, bnum1, rnum1, poi, step, addpoi, i, minDefPoi: integer;
  select: boolean;
begin
  //calcanselect(bnum, 1);
  rnum := Brole[bnum].rnum;
  bnum1 := -1;
  poi := Rrole[rnum].UsePoi;
  step := poi div 15 + 1;
  if step > 15 then
    step := 15;
  CalCanSelect(bnum, 1, step);
  select := False;
  if (Brole[bnum].Team = 0) and (Brole[bnum].Auto = 0) then
    select := SelectAim(bnum, step)
  else
  begin
    minDefPoi := MaxProList[49];
    //showmessage(inttostr(mindefpoi));
    for i := 0 to BRoleAmount - 1 do
    begin
      if (Brole[i].Dead = 0) and (Brole[i].Team <> Brole[bnum].Team) then
      begin
        if (Rrole[Brole[i].rnum].DefPoi <= minDefPoi) and (Rrole[Brole[i].rnum].Poison < 99) and (Bfield[3, Brole[i].X, Brole[i].Y] >= 0) then
        begin
          //bnum1 := i;
          minDefPoi := Rrole[Brole[i].rnum].DefPoi;
          //showmessage(inttostr(mindefpoi));
          Select := True;
          Ax := Brole[i].X;
          Ay := Brole[i].Y;
        end;
      end;
    end;
  end;
  if (bfield[2, Ax, Ay] >= 0) and (select = True) then
  begin
    Brole[bnum].Acted := 1;
    Rrole[rnum].PhyPower := Rrole[rnum].PhyPower - 3;
    bnum1 := bfield[2, Ax, Ay];
    if Brole[bnum1].Team <> Brole[bnum].Team then
    begin
      rnum1 := Brole[bnum1].rnum;
      addpoi := Rrole[rnum].UsePoi div 3 - Rrole[rnum1].DefPoi div 4;
      if addpoi < 0 then
        addpoi := 0;
      if addpoi + Rrole[rnum1].Poison > 99 then
        addpoi := 99 - Rrole[rnum1].Poison;
      Rrole[rnum1].Poison := Rrole[rnum1].Poison + addpoi;
      Brole[bnum1].ShowNumber := addpoi;
      Brole[bnum1].ExpGot := Brole[bnum1].ExpGot + addpoi;
      SetAminationPosition(0, 0);
      PlayActionAmination(bnum, 0);
      PlayMagicAmination(bnum, 30, 0, 2);
      ShowHurtValue(2);
    end;
  end;
end;

//医疗
procedure Medcine(bnum: integer);
var
  rnum, bnum1, rnum1, med, step, addlife, minHP, i, minushurt: integer;
  select: boolean;
begin
  //calcanselect(bnum, 1);
  rnum := Brole[bnum].rnum;
  med := Rrole[rnum].Medcine;
  step := min(med div 15 + 1, 15);

  CalCanSelect(bnum, 1, step);
  select := False;
  if (Brole[bnum].Team = 0) and (Brole[bnum].Auto = 0) then
    select := SelectAim(bnum, step)
  else
  begin
    {minHP := Max_HP;
      //showmessage(inttostr(mindefpoi));
      for i := 0 to BRoleAmount - 1 do
      begin
      if (Brole[i].Dead = 0) and (Brole[i].Team = Brole[bnum].Team) then
      begin
      if (Rrole[Brole[i].rnum].CurrentHP <= minHP)
      and (Rrole[Brole[i].rnum].CurrentHP < Rrole[Brole[i].rnum].MaxHP * 2 div 3)
      and (Bfield[3, Brole[i].X, Brole[i].Y] >= 0) then
      begin
      //bnum1 := i;
      minHP := Rrole[Brole[i].rnum].CurrentHP;
      //showmessage(inttostr(mindefpoi));
      Select := True;
      Ax := Brole[i].X;
      Ay := Brole[i].Y;
      end;
      end;
      end;}
    if Bfield[3, Ax, Ay] >= 0 then
      select := True;
  end;
  if (bfield[2, Ax, Ay] >= 0) and (select = True) then
  begin
    Brole[bnum].Acted := 1;
    Rrole[rnum].PhyPower := Rrole[rnum].PhyPower - 5;
    bnum1 := bfield[2, Ax, Ay];
    if Brole[bnum1].Team = Brole[bnum].Team then
    begin
      rnum1 := Brole[bnum1].rnum;
      addlife := EffectMedcine(rnum, rnum1);

      Brole[bnum1].ShowNumber := addlife;
      Brole[bnum1].ExpGot := Brole[bnum1].ExpGot + addlife;
      SetAminationPosition(0, 0);
      PlayActionAmination(bnum, 0);
      PlayMagicAmination(bnum, 0, 1, 3);
      ShowHurtValue(3);
    end;
  end;

end;

//解毒
procedure MedPoison(bnum: integer);
var
  rnum, bnum1, rnum1, medpoi, step, minuspoi: integer;
  select: boolean;
begin
  //calcanselect(bnum, 1);
  rnum := Brole[bnum].rnum;
  medpoi := Rrole[rnum].MedPoi;
  step := min(medpoi div 15 + 1, 15);

  CalCanSelect(bnum, 1, step);
  select := False;
  if (Brole[bnum].Team = 0) and (Brole[bnum].Auto = 0) then
    select := SelectAim(bnum, step)
  else
  begin
    if Bfield[3, Ax, Ay] >= 0 then
      select := True;
  end;
  if (bfield[2, Ax, Ay] >= 0) and (select = True) then
  begin
    Brole[bnum].Acted := 1;
    Rrole[rnum].PhyPower := Rrole[rnum].PhyPower - 5;
    bnum1 := bfield[2, Ax, Ay];
    if Brole[bnum1].Team = Brole[bnum].Team then
    begin
      rnum1 := Brole[bnum1].rnum;
      minuspoi := EffectMedPoison(rnum, rnum1);

      Brole[bnum1].ShowNumber := minuspoi;
      Brole[bnum1].ExpGot := Brole[bnum1].ExpGot + minuspoi;
      SetAminationPosition(0, 0);
      PlayActionAmination(bnum, 0);
      PlayMagicAmination(bnum, 36, 1, 4);
      ShowHurtValue(4);
    end;
  end;

end;

//使用暗器
procedure UseHiddenWeapon(bnum, inum: integer);
var
  rnum, bnum1, rnum1, hidden, step, hurt, poison, i, maxhurt, eventnum: integer;
  select: boolean;
begin
  //calcanselect(bnum, 1);
  rnum := Brole[bnum].rnum;
  hidden := Rrole[rnum].HidWeapon;
  step := hidden div 15 + 1;
  CalCanSelect(bnum, 1, step);
  select := False;
  if inum < 0 then
    eventnum := -1
  else
    eventnum := Ritem[inum].UnKnow7;
  if eventnum > 0 then
    CallEvent(eventnum)
  else
  begin
    if (Brole[bnum].Team = 0) and (Brole[bnum].Auto = 0) then
      select := SelectAim(bnum, step)
    else
    begin
      if Bfield[3, Ax, Ay] >= 0 then
      begin
        select := True;
      end;
    end;
    if (bfield[2, Ax, Ay] >= 0) and (select = True) and (Brole[bfield[2, Ax, Ay]].Team <> Brole[bnum].Team) then
    begin
      //如果自动, 选择伤害最大的暗器
      if (Brole[bnum].Team = 0) and (Brole[bnum].Auto <> 0) then
      begin
        inum := -1;
        maxhurt := 0;
        for i := 0 to MAX_ITEM_AMOUNT - 1 do
        begin
          if (RItemList[i].Amount > 0) and (RItemList[i].Number >= 0) then
            if (Ritem[RItemList[i].Number].ItemType = 4) and (Ritem[RItemList[i].Number].AddCurrentHP < maxhurt) then
            begin
              maxhurt := Ritem[RItemList[i].Number].AddCurrentHP;
              inum := RItemList[i].Number;
            end;
        end;
      end;
      if (Brole[bnum].Team <> 0) then
      begin
        begin
          inum := -1;
          maxhurt := 0;
          for i := 0 to 3 do
          begin
            if (Rrole[rnum].TakingItemAmount[i] > 0) and (Rrole[rnum].TakingItem[i] >= 0) then
              if (Ritem[Rrole[rnum].TakingItem[i]].ItemType = 4) and (Ritem[Rrole[rnum].TakingItem[i]].AddCurrentHP < maxhurt) then
              begin
                maxhurt := Ritem[RItemList[i].Number].AddCurrentHP;
                inum := RItemList[i].Number;
              end;
          end;
        end;
      end;

      if inum >= 0 then
      begin
        Brole[bnum].Acted := 1;
        if Brole[bnum].Team = 0 then
          instruct_32(inum, -1)
        else
          instruct_41(rnum, inum, -1);

        bnum1 := bfield[2, Ax, Ay];
        if Brole[bnum1].Team <> Brole[bnum].Team then
        begin
          rnum1 := Brole[bnum1].rnum;
          hurt := Rrole[rnum].HidWeapon div 2 - Ritem[inum].AddCurrentHP div 3 - Rrole[rnum1].HidWeapon;
          hurt := max(hurt * (Rrole[rnum1].Hurt div 33 + 1), 1 + random(10));
          Rrole[rnum1].CurrentHP := Rrole[rnum1].CurrentHP - hurt;
          Brole[bnum1].ShowNumber := hurt;
          Brole[bnum1].ExpGot := Brole[bnum1].ExpGot + hurt;
          Rrole[rnum1].Hurt := min(Rrole[rnum1].Hurt + hurt div LIFE_HURT, 99);
          Rrole[rnum1].Poison := min(Rrole[rnum1].Poison + Ritem[inum].AddPoi * (100 - Rrole[rnum1].DefPoi) div 100, 99);
          SetAminationPosition(0, 0);
          ShowMagicName(inum, 1);
          PlayActionAmination(bnum, 0);
          PlayMagicAmination(bnum, Ritem[inum].AmiNum);
          ShowHurtValue(0);
        end;
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
  rnum := Brole[bnum].rnum;
  Rrole[rnum].CurrentHP := min(Rrole[rnum].CurrentHP + (5 + Brole[bnum].Step) * Rrole[rnum].MaxHP div 200, Rrole[rnum].MaxHP);
  Rrole[rnum].CurrentMP := min(Rrole[rnum].CurrentMP + (5 + Brole[bnum].Step) * Rrole[rnum].MaxMP div 200, Rrole[rnum].MaxMP);
  Rrole[rnum].PhyPower := min(Rrole[rnum].PhyPower + (5 + Brole[bnum].Step) * MAX_PHYSICAL_POWER div 200, MAX_PHYSICAL_POWER);

end;

function TeamModeMenu: boolean;
var
  menup, x, y, w, h, menu, i, amount, xm, ym: integer;
  a: array of smallint;
  tempmode: array of integer;
  modestring: array [0 .. 3] of utf8string;
  namestr: array of utf8string;
  str: utf8string;

  procedure ShowTeamModeMenu();
  var
    i: integer;
  begin
    Redraw;
    DrawRectangle(screen, x, y, w, h, 0, ColColor(255), 50);
    for i := 0 to amount - 1 do
    begin
      if (i = menu) then
      begin
        DrawShadowText(namestr[i], x + 3, y + 3 + 22 * i, ColColor($64), ColColor($66));
        DrawShadowText(modestring[Brole[a[i]].AutoMode], x + 120 - 17, y + 3 + 22 * i, ColColor($64), ColColor($66));
      end
      else
      begin
        DrawShadowText(namestr[i], x + 3, y + 3 + 22 * i, ColColor($21), ColColor($23));
        DrawShadowText(modestring[Brole[a[i]].AutoMode], x + 120 - 17, y + 3 + 22 * i, ColColor($21), ColColor($23));
      end;
    end;
    if menu = -2 then
      DrawShadowText(str, x + 3, y + 3 + 22 * amount, ColColor($64), ColColor($66))
    else
      DrawShadowText(str, x + 3, y + 3 + 22 * amount, ColColor($21), ColColor($23));
    SDL_UpdateRect2(screen, x, y, w + 1, h + 1);
  end;

begin
  x := 160;
  y := 82;
  w := 160;
  //SDL_EnableKeyRepeat(20, 100);
  Result := True;
  amount := 0;
  for i := 0 to BRoleAmount - 1 do
  begin
    if (Brole[i].Team = 0) and (Brole[i].Dead = 0) then
    begin
      amount := amount + 1;
      setlength(namestr, amount);
      setlength(a, amount);
      namestr[amount - 1] := ' ' + cp950toutf8(@Rrole[Brole[i].rnum].Name[0]);
      a[amount - 1] := i;
    end;
  end;
  h := amount * 22 + 28;
  modestring[1] := '全攻';
  modestring[2] := '平衡';
  modestring[3] := '混子';
  modestring[0] := '手動';
  str := ' 確認';

  //RecordFreshScreen(x, y, w + 1, h + 1);
  setlength(tempmode, BRoleAmount);
  for i := 0 to BRoleAmount - 1 do
  begin
    tempmode[i] := Brole[i].AutoMode;
  end;

  menu := 0;
  ShowTeamModeMenu;
  while (SDL_WaitEvent(@event)) do
  begin
    CheckBasicEvent;
    case event.type_ of
      SDL_EVENT_KEY_UP:
      begin
        if (event.key.key = SDLK_RETURN) or (event.key.key = SDLK_SPACE) then
        begin
          break;
        end;
        if (event.key.key = SDLK_ESCAPE) then
        begin
          Result := False;
          break;
        end;
        //end;
        //SDL_EVENT_KEY_DOWN:
        //begin
        if (event.key.key = SDLK_UP) then
        begin
          menu := menu - 1;
          if menu = -1 then
            menu := -2;
          if menu = -3 then
            menu := amount - 1;
          ShowTeamModeMenu;
        end;
        if (event.key.key = SDLK_DOWN) then
        begin
          menu := menu + 1;
          if menu = amount then
            menu := -2;
          if menu = -1 then
            menu := 0;
          ShowTeamModeMenu;
        end;
        if (event.key.key = SDLK_LEFT) then
        begin
          Brole[a[menu]].AutoMode := Brole[a[menu]].AutoMode - 1;
          if Brole[a[menu]].AutoMode < 0 then
            Brole[a[menu]].AutoMode := 3;
          ShowTeamModeMenu;
        end;
        if (event.key.key = SDLK_RIGHT) then
        begin
          Brole[a[menu]].AutoMode := Brole[a[menu]].AutoMode + 1;
          if Brole[a[menu]].AutoMode > 3 then
            Brole[a[menu]].AutoMode := 0;
          ShowTeamModeMenu;
        end;
      end;
      SDL_EVENT_MOUSE_BUTTON_UP:
      begin
        if (event.button.button = SDL_BUTTON_LEFT) then
        begin
          if (menu > -1) then
          begin
            Brole[a[menu]].AutoMode := Brole[a[menu]].AutoMode + 1;
            if Brole[a[menu]].AutoMode > 3 then
              Brole[a[menu]].AutoMode := 0;
            ShowTeamModeMenu;
          end
          else if (menu = -2) then
          begin
            break;
          end;
        end;
        if (event.button.button = SDL_BUTTON_RIGHT) then
        begin
          Result := False;
          break;
        end;
      end;
      SDL_EVENT_MOUSE_MOTION:
      begin
        if MouseInRegion(x, y, w, amount * 22 + 28, xm, ym) then
        begin
          menup := menu;
          menu := (ym - y) div 22;
          if menu < 0 then
            menu := 0;
          if menu >= amount then
            menu := -2;
          if menup <> menu then
            ShowTeamModeMenu;
        end
        else
          menu := -1;
      end;
    end;
    event.key.key := 0;
    event.button.button := 0;
  end;
  //SDL_EnableKeyRepeat(30,30);
  Redraw;
  if Result = False then
    for i := 0 to BRoleAmount - 1 do
      Brole[i].AutoMode := tempmode[i];

end;

//The AI. Some codes were written by little samll pig.
procedure AutoBattle(bnum: integer);
var
  i, p, temp, rnum, inum, eneamount, aim, mnum, level: integer;
  i1, i2, step, step1, dis0, dis: integer;
  Bx1, By1, Ax1, Ay1, curBx1, curBy1, curAx1, curAy1, curMnum, curMaxHurt, curlevel, tempmaxhurt: integer;
  str: utf8string;
begin
  rnum := Brole[bnum].rnum;
  ShowSimpleStatus(rnum, CENTER_X + 100, 50);
  SDL_Delay(450);

  //我方在AI类型为策略(傻子)时才会选择吃药
  if ((Brole[bnum].Team = 0) and (Brole[bnum].AutoMode = 2)) or (Brole[bnum].Team <> 0) then
  begin
    //Life is less than 20%, 70% probality to medcine or eat a pill.
    //生命低于20%, 70%可能医疗或吃药
    if (Brole[bnum].Acted <> 1) and (Rrole[rnum].CurrentHP < Rrole[rnum].MaxHP div 5) then
    begin
      if random(100) < 70 then
      begin
        //医疗大于50, 且体力大于50才对自身医疗
        if (Rrole[rnum].Medcine >= 50) and (Rrole[rnum].PhyPower >= 50) and (random(100) < 50) then
        begin
          Medcine(bnum);
        end
        else
        begin
          //if can't medcine, eat the item which can add the most life on its body.
          //无法医疗则选择身上加生命最多的药品, 我方从物品栏选择
          AutoUseItem(bnum, 45);
        end;
      end;
    end;

    //MP is less than 20%, 60% probality to eat a pill.
    //内力低于20%, 60%可能吃药
    if (Brole[bnum].Acted <> 1) and (Rrole[rnum].CurrentMP < Rrole[rnum].MaxMP div 5) then
    begin
      if random(100) < 60 then
      begin
        AutoUseItem(bnum, 50);
      end;
    end;

    //Physical power is less than 20%, 80% probability to eat a pill.
    //体力低于20%, 80%可能吃药
    if (Brole[bnum].Acted <> 1) and (Rrole[rnum].PhyPower < 20) then
    begin
      if random(100) < 80 then
      begin
        AutoUseItem(bnum, 48);
      end;
    end;
  end;

  //我方在AI类型为策略或者辅助(傻子或呆子)时才会选择医疗, 解毒, 用毒, 暗器
  if ((Brole[bnum].Team = 0) and ((Brole[bnum].AutoMode = 2) {or (Brole[bnum].AutoMode = 3)})) or (Brole[bnum].Team <> 0) then
  begin
    //When Medcine is more than 50, and physical power is more than 70, 50% probability to cure one teammate.
    if (Brole[bnum].Acted <> 1) and (Rrole[rnum].Medcine > 50) and (Rrole[rnum].PhyPower >= 70) then
    begin
      if random(100) < 50 then
      begin
        //showmessage(inttostr(rrole[rnum].UsePoi));
        NearestMoveByPro(Ax, Ay, Ax1, Ay1, bnum, 1, 0, 17, -1, 1);
        if (Ax1 <> -1) then
        begin
          MoveAmination(bnum);
          Ax := Ax1;
          Ay := Ay1;
          Medcine(bnum);
        end;
      end;
    end;

    //When detoxifying is more than 50, and physical power is more than 70, 50% probability to detoxify one teammate.
    if (Brole[bnum].Acted <> 1) and (Rrole[rnum].MedPoi > 50) and (Rrole[rnum].PhyPower >= 70) then
    begin
      if random(100) < 50 then
      begin
        //showmessage(inttostr(rrole[rnum].UsePoi));
        NearestMoveByPro(Ax, Ay, Ax1, Ay1, bnum, 1, 0, 20, 1, 2);
        if (Ax1 <> -1) then
        begin
          MoveAmination(bnum);
          Ax := Ax1;
          Ay := Ay1;
          MedPoison(bnum);
        end;
      end;
    end;

    //When using poison is more than attack, and physical power is more than 60, 50% probability to use poison.
    if (Brole[bnum].Acted <> 1) and (Rrole[rnum].UsePoi > Rrole[rnum].Attack) and (Rrole[rnum].PhyPower >= 60) then
    begin
      if random(100) < 50 then
      begin
        //showmessage(inttostr(rrole[rnum].UsePoi));
        //CalCanSelect(bnum, 0, Brole[bnum].step);
        NearestMoveByPro(Ax, Ay, Ax1, Ay1, bnum, 0, min(Rrole[rnum].UsePoi div 15 + 1, 15), 49, -1, 0);
        if (Ax1 <> -1) then
        begin
          MoveAmination(bnum);
          Ax := Ax1;
          Ay := Ay1;
          UsePoison(bnum);
        end;
      end;
    end;

    //When hidden-weapon is more than attack, and physical power is more than 30, 30% probability to use hidden-weapon.
    if (Brole[bnum].Acted <> 1) and (Rrole[rnum].HidWeapon > Rrole[rnum].Attack) and (Rrole[rnum].PhyPower >= 30) then
    begin
      if random(100) < 100 then
      begin
        NearestMoveByPro(Ax, Ay, Ax1, Ay1, bnum, 0, 1, 17, -1, 0);
        if (Ax1 <> -1) then
        begin
          MoveAmination(bnum);
          Ax := Ax1;
          Ay := Ay1;
          UseHiddenWeapon(bnum, -1);
        end;
      end;
    end;
  end;

  if ((Brole[bnum].Team = 0) and ((Brole[bnum].AutoMode = 1) or (Brole[bnum].AutoMode = 2))) or (Brole[bnum].Team <> 0) then
  begin
    //尝试攻击
    if (Brole[bnum].Acted <> 1) and (Rrole[rnum].PhyPower >= 10) then
    begin
      //Calculate the positon can be reached.
      CalCanSelect(bnum, 0, Brole[bnum].step);
      //for every magic, calcualte the max total hurt.
      //B: the position for moving, A: the positon for attacking
      curBx1 := -1;
      curBy1 := -1;
      curAx1 := -1;
      curAy1 := -1;
      curMnum := -1;
      curMaxHurt := 0;
      curlevel := 0;
      p := -1;
      for i1 := 0 to 9 do
      begin
        mnum := Rrole[rnum].Magic[i1];
        if mnum > 0 then
        begin
          level := Rrole[rnum].MagLevel[i1] div 100 + 1;
          if Rrole[rnum].CurrentMP < Rmagic[mnum].NeedMP * ((level + 1) div 2) then
            level := Rrole[rnum].CurrentMP div Rmagic[mnum].NeedMP * 2;
          if level > 10 then
            level := 10;
          if level <= 0 then
            level := 1;
          TryMoveAttack(Bx1, By1, Ax1, Ay1, tempmaxhurt, bnum, mnum, level);
          if tempmaxhurt > curMaxHurt then
          begin
            curBx1 := Bx1;
            curBy1 := By1;
            curAx1 := Ax1;
            curAy1 := Ay1;
            curMnum := mnum;
            curlevel := level;
            curMaxHurt := tempmaxhurt;
            p := i1;
          end;
        end;
      end;
      //if curMaxHurt = 0 then nearestmove(curBx1, curBy1, bnum);
      //if have selected the postions for moving and attacking, then act
      if curMaxHurt > 0 then
      begin
        Ax := curBx1;
        Ay := curBy1;
        MoveAmination(bnum);
        Ax := curAx1;
        Ay := curAy1;
        mnum := curMnum;
        level := curlevel;
        SetAminationPosition(Rmagic[mnum].AttAreaType, Rmagic[mnum].MoveDistance[level - 1], Rmagic[mnum].AttDistance[level - 1]);
        Brole[bnum].Acted := 1;
        AttackAction(bnum, p, mnum, level);
      end;
    end;
  end;

  {//在敌方选择一个人物
    eneamount := Calrnum(1 - Brole[bnum].Team);
    aim := random(eneamount) + 1;
    //showmessage(inttostr(eneamount));
    for i := 0 to broleamount - 1 do
    begin
    if (Brole[bnum].Team <> Brole[i].Team) and (Brole[i].Dead = 0) then
    begin
    aim := aim - 1;
    if aim <= 0 then
    break;
    //如果有贴身则优先
    if abs(Brole[i].X - Bx) + abs(Brole[i].Y - By) <= 1 then
    break;
    end;
    end;

    //Seclect one enemy randomly and try to close it.
    //尝试走到离敌人最近的位置
    Ax := Bx;
    Ay := By;
    Ax1 := Brole[i].X;
    Ay1 := Brole[i].Y;
    CalCanSelect(bnum, 0, brole[bnum].Step);
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
    if Bfield[3, Ax, Ay] >= 0 then
    MoveAmination(bnum);
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
    if RRole[rnum].CurrentMP < rmagic[mnum].NeedMP * ((level + 1) div 2) then
    level := RRole[rnum].CurrentMP div rmagic[mnum].NeedMP * 2;
    if level > 10 then
    level := 10;
    if level <= 0 then
    level := 1;
    if rmagic[mnum].Attack[level - 1] > temp then
    begin
    p := i1;
    temp := rmagic[mnum].Attack[level - 1];
    end;
    end;
    end;
    //50% probility to re-select WUGONG randomly.
    //50%的可能重新选择武功
    if random(100) < 50 then
    p := random(a);

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
    if rmagic[mnum].AttAreaType = 3 then
    a := a + rmagic[mnum].AttDistance[level - 1];
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
    if rmagic[mnum].AttAreaType = 3 then
    step1 := rmagic[mnum].AttDistance[level - 1];
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
    SetAminationPosition(Rmagic[mnum].AttAreaType, step)
    else
    SetAminationPosition(Rmagic[mnum].AttAreaType, step1);

    if bfield[4, Ax, Ay] <> 0 then
    begin
    Brole[bnum].Acted := 1;
    for i1 := 0 to sign(Rrole[rnum].AttTwice) do
    begin
    Rrole[rnum].MagLevel[p] := Rrole[rnum].MagLevel[p] + random(2) + 1;
    if Rrole[rnum].MagLevel[p] > 999 then
    Rrole[rnum].MagLevel[p] := 999;
    if rmagic[mnum].UnKnow[4] > 0 then
    callevent(rmagic[mnum].UnKnow[4])
    else
    AttackAction(bnum, mnum, level);
    end;
    end;
    end;
    end;}

  //If all other actions fail, try to move closest to the nearest enemy and rest.
  //如果上面行动全部失败, 尽量靠近最近的敌人, 休息

  if Brole[bnum].Acted <> 1 then
  begin
    //CalCanSelect(bnum, 0, Brole[bnum].step);
    if ((Brole[bnum].Team = 0) and ((Brole[bnum].AutoMode = 1) or (Brole[bnum].AutoMode = 2))) or (Brole[bnum].Team <> 0) then
    begin
      NearestMove(Ax, Ay, bnum);
      MoveAmination(bnum);
    end;
    Rest(bnum);
  end;

  //检查是否有esc被按下
  if SDL_PollEvent(@event) or True then
  begin
    CheckBasicEvent;
  end;
end;

//自动使用list的值最大的物品
procedure AutoUseItem(bnum, list: integer);
var
  i, p, temp, rnum, inum: integer;
  str: utf8string;
begin
  rnum := Brole[bnum].rnum;
  if Brole[bnum].Team <> 0 then
  begin
    temp := 10;
    p := -1;
    for i := 0 to 3 do
    begin
      if Rrole[rnum].TakingItem[i] >= 0 then
      begin
        if Ritem[Rrole[rnum].TakingItem[i]].Data[list] > temp then
        begin
          temp := Ritem[Rrole[rnum].TakingItem[i]].Data[list];
          p := i;
        end;
      end;
    end;
  end
  else
  begin
    temp := 10;
    p := -1;
    for i := 0 to MAX_ITEM_AMOUNT - 1 do
    begin
      if (RItemList[i].Amount > 0) and (Ritem[RItemList[i].Number].ItemType = 3) then
      begin
        if Ritem[RItemList[i].Number].Data[list] > temp then
        begin
          temp := Ritem[RItemList[i].Number].Data[list];
          p := i;
        end;
      end;
    end;
  end;

  if p >= 0 then
  begin
    if Brole[bnum].Team <> 0 then
      inum := Rrole[rnum].TakingItem[p]
    else
      inum := RItemList[p].Number;
    Redraw;
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    EatOneItem(rnum, inum);
    if Brole[bnum].Team <> 0 then
      instruct_41(rnum, Rrole[rnum].TakingItem[p], -1)
    else
      instruct_32(RItemList[p].Number, -1);
    Brole[bnum].Acted := 1;
    SDL_Delay(500);
  end;

end;

procedure TryMoveAttack(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; bnum, mnum, level: integer);
var
  curX, curY, curstep, nextX, nextY, dis, dis0, temphurt: integer;
  i, i1, i2, eneamount, aim: integer;
  step, distance, range, AttAreaType, myteam: integer;
  aimHurt: array [0 .. 63, 0 .. 63] of integer;
begin
  step := Brole[bnum].Step;
  Mx1 := -1;
  My1 := -1;
  Ax1 := -1;
  Ay1 := -1;
  tempmaxhurt := -1;
  FillChar(aimHurt[0, 0], sizeof(aimHurt), -1);
  AttAreaType := Rmagic[mnum].AttAreaType;
  distance := Rmagic[mnum].MoveDistance[level - 1];
  range := Rmagic[mnum].AttDistance[level - 1];
  AttAreaType := Rmagic[mnum].AttAreaType;
  myteam := Brole[bnum].Team;

  for curX := 0 to 63 do
    for curY := 0 to 63 do
    begin
      if (Bfield[3, curX, curY] >= 0) and (Bfield[3, curX, curY] <= step) then
      begin
        case AttAreaType of
          0: dis := distance; //calpoint(Mx1, My1, Ax1, Ay1, tempmaxhurt, curX, curY, bnum, mnum, level);
          1: dis := 1; //calline(Mx1, My1, Ax1, Ay1, tempmaxhurt, curX, curY, bnum, mnum, level);
          2: dis := 0; //calcross(Mx1, My1, Ax1, Ay1, tempmaxhurt, curX, curY, bnum, mnum, level);
          3: dis := distance; //calarea(Mx1, My1, Ax1, Ay1, tempmaxhurt, curX, curY, bnum, mnum, level);
          {4:
            caldirdiamond(Mx1, My1, Ax1, Ay1, tempmaxhurt, curX, curY, bnum, mnum, level);
            5:
            caldirangle(Mx1, My1, Ax1, Ay1, tempmaxhurt, curX, curY, bnum, mnum, level);
            6:
            calfar(Mx1, My1, Ax1, Ay1, tempmaxhurt, curX, curY, bnum, mnum, level);}
        end;

        for i1 := max(curX - dis, 0) to min(curX + dis, 63) do
        begin
          dis0 := abs(i1 - curX);
          for i2 := max(curY - dis + dis0, 0) to min(curY + dis - dis0, 63) do
          begin
            if AttAreaType <> 3 then
              SetAminationPosition(curX, curY, i1, i2, AttAreaType, distance, range);

            temphurt := 0;
            if ((AttAreaType = 0) or (AttAreaType = 3)) and (aimHurt[i1, i2] >= 0) then
            begin
              if aimHurt[i1, i2] > 0 then
                temphurt := aimHurt[i1, i2] + random(5) - random(5); //点面类攻击已经计算过的点简单处理
            end
            else
            begin
              for i := 0 to BRoleAmount - 1 do
              begin
                //特别处理面攻击, 因为当面积较大时设置动画位置比较慢
                if (Brole[i].Team <> myteam) and (Brole[i].Dead = 0) and (((AttAreaType <> 3) and (Bfield[4, Brole[i].X, Brole[i].Y] > 0)) or ((AttAreaType = 3) and (abs(i1 - Brole[i].X) <= range) and (abs(i2 - Brole[i].Y) <= range))) then
                begin
                  temphurt := temphurt + CalHurtValue2(bnum, i, mnum, level);
                end;
              end;
              aimHurt[i1, i2] := temphurt;
            end;
            if temphurt > tempmaxhurt then
            begin
              tempmaxhurt := temphurt;
              Mx1 := curX;
              My1 := curY;
              Ax1 := i1;
              Ay1 := i2;
            end;
          end;
        end;
      end;
    end;

  //Bx := tempBx;
  //By := tempBy;
  //Ax := tempAx;
  //Ay := tempAy;

end;

//目标系点十菱, 原地系菱
procedure CalPoint(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; curX, curY, bnum, mnum, level: integer);
var
  i, j, k, m, n, tempX, tempY, temphurt, ebnum, ernum, tempHP: integer;
  distance, range, AttAreaType, myteam: integer;
begin
  distance := Rmagic[mnum].MoveDistance[level - 1];
  range := Rmagic[mnum].AttDistance[level - 1];
  range := 0;
  AttAreaType := Rmagic[mnum].AttAreaType;
  myteam := Brole[bnum].Team;

  for i := curX - distance to curX + distance do
  begin
    m := (distance - sign(i - curX) * (i - curX));
    for j := curY - m to curY + m do
    begin
      temphurt := 0;
      for k := 0 to BRoleAmount - 1 do
      begin
        if (myteam <> Brole[k].Team) and (Brole[k].Dead = 0) then
        begin
          tempX := Brole[k].X;
          tempY := Brole[k].Y;
          if abs(tempX - i) + abs(tempY - j) <= range then
          begin
            temphurt := temphurt + CalHurtValue2(bnum, k, mnum, level);
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

//线型攻击的情况, 分四个方向考虑, 分别计算伤血量
procedure calline(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; curX, curY, bnum, mnum, level: integer);
var
  i, tempX, tempY, ebnum, rnum, tempHP, temphurt: integer;
  distance, range, AttAreaType, myteam: integer;
begin
  distance := Rmagic[mnum].MoveDistance[level - 1];
  range := Rmagic[mnum].AttDistance[level - 1];
  AttAreaType := Rmagic[mnum].AttAreaType;
  myteam := Brole[bnum].Team;
  temphurt := 0;
  for i := curX - 1 downto curX - distance do
  begin
    ebnum := Bfield[2, i, curY];
    if (ebnum >= 0) and (Brole[ebnum].Dead = 0) and (Brole[ebnum].Team <> myteam) then
    begin
      temphurt := temphurt + CalHurtValue2(bnum, ebnum, mnum, level);
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
      temphurt := temphurt + CalHurtValue2(bnum, ebnum, mnum, level);
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
      temphurt := temphurt + CalHurtValue2(bnum, ebnum, mnum, level);
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
      temphurt := temphurt + CalHurtValue2(bnum, ebnum, mnum, level);
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

//原地系十叉米
procedure calcross(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; curX, curY, bnum, mnum, level: integer);
var
  i, tempX, tempY, temphurt, ebnum, rnum: integer;
  distance, range, AttAreaType, myteam: integer;
begin
  distance := Rmagic[mnum].MoveDistance[level - 1];
  range := Rmagic[mnum].AttDistance[level - 1];
  range := 0;
  AttAreaType := Rmagic[mnum].AttAreaType;
  myteam := Brole[bnum].Team;

  temphurt := 0;
  for i := -range to range do
  begin
    ebnum := Bfield[2, curX + i, curY + i];
    if (ebnum >= 0) and (Brole[ebnum].Dead = 0) and (Brole[ebnum].Team <> myteam) then
    begin
      temphurt := temphurt + CalHurtValue2(bnum, ebnum, mnum, level);
    end;
  end;

  for i := -range to range do
  begin
    bnum := Bfield[2, curX + i, curY - i];
    if (bnum >= 0) and (Brole[bnum].Dead = 0) and (Brole[bnum].Team <> myteam) then
    begin
      temphurt := temphurt + CalHurtValue2(bnum, ebnum, mnum, level);
    end;
  end;

  for i := curX - distance to curX + distance do
  begin
    bnum := Bfield[2, i, curY];
    if (bnum >= 0) and (Brole[bnum].Dead = 0) and (Brole[bnum].Team <> myteam) then
    begin
      temphurt := temphurt + CalHurtValue2(bnum, ebnum, mnum, level);
    end;
  end;

  for i := curY - distance to curY + distance do
  begin
    bnum := Bfield[2, curX, i];
    if (bnum >= 0) and (Brole[bnum].Dead = 0) and (Brole[bnum].Team <> myteam) then
    begin
      temphurt := temphurt + CalHurtValue2(bnum, ebnum, mnum, level);
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

//目标系方、原地系方
procedure CalArea(var Mx1, My1, Ax1, Ay1, tempmaxhurt: integer; curX, curY, bnum, mnum, level: integer);
var
  i, j, k, m, n, tempX, tempY, temphurt: integer;
  distance, range, AttAreaType, myteam: integer;
begin
  distance := Rmagic[mnum].MoveDistance[level - 1];
  range := Rmagic[mnum].AttDistance[level - 1];
  AttAreaType := Rmagic[mnum].AttAreaType;
  myteam := Brole[bnum].Team;

  for i := curX - distance to curX + distance do
  begin
    m := (distance - sign(i - curX) * (i - curX));
    for j := curY - m to curY + m do
    begin
      temphurt := 0;
      for k := 0 to BRoleAmount - 1 do
      begin
        if (myteam <> Brole[k].Team) and (Brole[k].Dead = 0) then
        begin
          tempX := Brole[k].X;
          tempY := Brole[k].Y;
          if (abs(tempX - i) <= range) and (abs(tempY - j) <= range) then
          begin
            temphurt := temphurt + CalHurtValue2(bnum, k, mnum, level);
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
procedure NearestMove(var Mx1, My1: integer; bnum: integer);
var
  temp1, temp2: integer;
begin
  NearestMoveByPro(Mx1, My1, temp1, temp2, bnum, 0, 1, 0, 0, 0);

  {myteam := brole[bnum].Team;
    mindis := 9999;
    step := brole[bnum].Step;

    //CalCanSelect(bnum, 0, step);

    Mx1 := Bx;
    My1 := By;
    //选择一个最近的敌人
    for i := 0 to broleamount - 1 do
    begin
    if (myteam <> Brole[i].Team) and (Brole[i].Dead = 0) then
    begin
    tempdis := abs(Brole[i].X - Bx) + abs(Brole[i].Y - By);
    if tempdis < mindis then
    begin
    mindis := tempdis;
    aimX := Brole[i].X;
    aimY := Brole[i].Y;
    end;
    end;
    end;

    for curX := 0 to 63 do
    for curY := 0 to 63 do
    begin
    if Bfield[3, curX, curY] >= 0 then
    begin
    tempdis := abs(curX - aimX) + abs(curY - aimY);
    if tempdis < mindis then
    begin
    mindis := tempdis;
    Mx1 := curX;
    My1 := curY;
    //showmessage(inttostr(mindis));
    end;
    end;
    end;}

end;

//TeamMate: 0-search enemy, 1-search teammate.
//KeepDis: keep steps to the aim. It minimun value is 1. But 0 means itself.
//Prolist: the properties of role.
//MaxMinPro: 1-search max, -1-search min, 0-any.
//mode: 0-nearest only, 1-medcine, 2-解毒
procedure NearestMoveByPro(var Mx1, My1, Ax1, Ay1: integer; bnum, TeamMate, KeepDis, Prolist, MaxMinPro: integer; mode: integer);
var
  i, tempdis, mindis, tempPro, rnum: integer;
  aimX, aimY: integer;
  step, myteam: integer;
  curX, curY: integer;
  select, check: boolean;
begin
  CalCanSelect(bnum, 0, Brole[bnum].step);
  myteam := Brole[bnum].Team;
  mindis := 9999;
  step := Brole[bnum].Step;

  tempPro := 0;
  if MaxMinPro < 0 then
    tempPro := 10000;
  //CalCanSelect(bnum, 0, step);

  select := False;
  if KeepDis < 0 then
    KeepDis := 0;
  //showmessage(inttostr(keepdis));
  Mx1 := Bx;
  My1 := By;
  aimX := -1;
  aimY := -1;

  if (MaxMinPro <> 0) and (Prolist >= low(Rrole[0].Data)) and (Prolist <= high(Rrole[0].Data)) then
  begin
    for i := 0 to BRoleAmount - 1 do
    begin
      rnum := Brole[i].rnum;
      if (((TeamMate = 0) and (myteam <> Brole[i].Team)) or ((TeamMate <> 0) and (myteam = Brole[i].Team))) and (Brole[i].Dead = 0) and (Rrole[rnum].Data[Prolist] * sign(MaxMinPro) > tempPro * sign(MaxMinPro)) then
      begin
        if abs(Brole[i].X - Bx) + abs(Brole[i].Y - By) <= KeepDis + step then
        begin
          check := False;
          case mode of
            0: check := True;
            1:
              if (Rrole[rnum].CurrentHP < Rrole[rnum].MaxHP * 2 div 3) then
                check := True;
            2:
              if (Rrole[rnum].Poison > 33) then
                check := True;
          end;
          if check then
          begin
            aimX := Brole[i].X;
            aimY := Brole[i].Y;
            tempPro := Rrole[Brole[i].rnum].Data[Prolist];
            select := True;
          end;
        end;
      end;
    end;
  end;

  //AI有可能进行两次移动, 即决定辅助类行动失败, 即转为攻击.
  //若目标为敌方,  在移动之后仍会进行二次判断, 有可能行动失败后转为攻击.
  //若为己方(医疗或解毒)先估测失败可能, 如必定失败则不会行动

  //若按属性寻找失败(未指定最大最小, 或者全部在安全距离之外), 则按距离找最近
  if (not select) and (mode = 0) then
  begin
    for i := 0 to BRoleAmount - 1 do
    begin
      if (((TeamMate = 0) and (myteam <> Brole[i].Team)) or ((TeamMate <> 0) and (myteam = Brole[i].Team))) and (Brole[i].Dead = 0) then
      begin
        tempdis := abs(Brole[i].X - Bx) + abs(Brole[i].Y - By);
        if tempdis < mindis then
        begin
          mindis := tempdis;
          aimX := Brole[i].X;
          aimY := Brole[i].Y;
        end;
      end;
    end;
  end;

  KeepDis := min(KeepDis, abs(Bx - aimX) + abs(By - aimY) + step);
  mindis := 9999;

  if aimX > 0 then
  begin
    for curX := 0 to 63 do
      for curY := 0 to 63 do
      begin
        if Bfield[3, curX, curY] >= 0 then
        begin
          tempdis := abs(curX - aimX) + abs(curY - aimY);
          if (tempdis < mindis) and (tempdis >= KeepDis) then
          begin
            mindis := tempdis;
            Mx1 := curX;
            My1 := curY;
          end;
        end;
      end;
  end;
  Ax1 := aimX;
  Ay1 := aimY;
end;

end.
