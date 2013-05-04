unit kys_event;

//{$MODE Delphi}

interface

uses
  SysUtils,
{$IFDEF fpc}
  LMessages, LConvEncoding,
  LCLType, LCLIntf, {$ELSE}
  Windows,
{$ENDIF}
  StrUtils,
  SDL_TTF,
  SDL_mixer,
  SDL_image,
  SDL,
  math,
  kys_main, Dialogs;

//事件系统
//在英文中, instruct通常不作为名词, swimmingfish在他的一份反汇编文件中大量使用
//这个词表示"指令", 所以这里仍保留这种用法
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
procedure instruct_44e(enum1, beginpic1, endpic1, enum2, beginpic2, enum3, beginpic3: integer);
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
function instruct_55(enum, Value, jump1, jump2: integer): integer;
procedure instruct_56(Repute: integer);
procedure instruct_58;
procedure instruct_57;
procedure instruct_59;
function instruct_60(snum, enum, pic, jump1, jump2: integer): integer;
function instruct_61(jump1, jump2: integer): integer;
procedure instruct_62(enum1, beginpic1, endpic1, enum2, beginpic2, endpic2: integer);
procedure EndAmi;
procedure instruct_63(rnum, sexual: integer);
procedure instruct_64;
procedure instruct_66(musicnum: integer);
procedure instruct_67(Soundnum: integer);
function e_GetValue(bit, t, x: integer): integer;
function CutRegion(x: integer): integer;
function instruct_50e(code, e1, e2, e3, e4, e5, e6: integer): integer;
function HaveMagic(person, mnum, lv: integer): boolean;
procedure StudyMagic(rnum, magicnum, newmagicnum, level, dismode: integer);
procedure NewTalk(headnum, talknum, namenum, place, showhead, color, frame: integer);

implementation

uses kys_script, kys_engine, kys_battle, kys_draw;

//事件系统
//事件指令含义请参阅其他相关文献

procedure instruct_0;
begin

  redraw;
  //SDL_UpdateRect2(screen,0,0,screen.w,screen.h);

end;

procedure instruct_1(talknum, headnum, dismode: integer);
var
  idx, grp, offset, len, i, p, l, headx, heady, diagx, diagy, key: integer;
  talkarray: array of byte;
  Name: WideString;
begin
  {if MODVersion = 62 then
  begin
    NewTalk(headnum, talknum, -1, 1, 1, $ffffffff, 0);
    exit;
  end;}

  case dismode of
    0:
      begin
        headx := 40;
        heady := 85;
        diagx := 100;
        diagy := 30;
      end;
    1:
      begin
        headx := 546;
        heady := CENTER_Y * 2 - 75;
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
        heady := CENTER_Y * 2 - 75;
        diagx := 100;
        diagy := CENTER_Y * 2 - 130;
      end;
    4:
      begin
        headx := 546;
        heady := 85;
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

  len := 0;
  if talknum = 0 then
  begin
    offset := 0;
    len := TIdx[0];
  end
  else
  begin
    offset := TIdx[talknum - 1];
    len := TIdx[talknum] - offset;
  end;
  setlength(talkarray, len + 1);
  move(TDef[offset], talkarray[0], len);

  drawrectanglewithoutframe(screen, 0, diagy - 10, 640, 120, 0, 40);
  if headx > 0 then
    drawheadpic(headnum, headx, heady);
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
  talkarray[len - 1] := $20;
  p := 0;
  l := 0;
  for i := 0 to len do
  begin
    if (talkarray[i] = 0) {or ((i mod 48 = 0) and (i > 0))} then
    begin
      drawbig5shadowtext(screen, @talkarray[p], diagx, diagy + l * 22, colcolor($FF), colcolor($0));
      p := i + 1;
      l := l + 1;
      if (l >= 4) and (i < len) then
      begin
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        repeat
          key := WaitAnyKey;
        until (key <> sdlk_left) and (key <> sdlk_right) and (key <> sdlk_up) and (key <> sdlk_down);
        Redraw;
        drawrectanglewithoutframe(screen, 0, diagy - 10, 640, 120, 0, 40);
        if headx > 0 then
          drawheadpic(headnum, headx, heady);
        l := 0;
      end;
    end;
  end;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  repeat
    key := WaitAnyKey;
  until (key <> sdlk_left) and (key <> sdlk_right) and (key <> sdlk_up) and (key <> sdlk_down);
  redraw;

end;

//得到物品可显示数量, 数量为负显示失去物品

procedure instruct_2(inum, amount: integer);
var
  x: integer;
  word: WideString;
begin
  instruct_32(inum, amount);
  x := CENTER_X;
  if where = 2 then
    x := 190;

  DrawRectangle(screen, x - 85, 98, 170, 76, 0, colcolor(255), 30);
  //DrawMPic(ITEM_BEGIN_PIC + inum, x - 20, 100);
  if amount >= 0 then
    word := (' 得到物品')
  else
    word := (' 失去物品');
  drawshadowtext(screen, @word[1], x - 100, 100, colcolor($23), colcolor($21));
  drawbig5shadowtext(screen, @RItem[inum].Name, x - 100, 125, colcolor($7), colcolor($5));
  word := (' 數量');
  drawshadowtext(screen, @word[1], x - 100, 150, colcolor($66), colcolor($64));
  word := format(' %5d', [amount]);
  drawengshadowtext(screen, @word[1], x - 0, 150, colcolor($66), colcolor($64));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  waitanykey;
  redraw;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

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
    else
    begin
      RItemList[i].Number := -1;
      RItemList[i].Amount := 0;
    end;
  end;

end;

//改变事件, 如在当前场景需重置场景
//在需改变贴图较多时效率较低

procedure instruct_3(list: array of integer);
var
  i, i1, i2, curPic, preEventPic: integer;
  ModifyS: boolean;
begin
  curPic := DData[CurScence, CurEvent, 5];
  if list[0] = -2 then
    list[0] := CurScence;
  if list[1] = -2 then
    list[1] := CurEvent;
  if list[11] = -2 then
    list[11] := Ddata[list[0], list[1], 9];
  if list[12] = -2 then
    list[12] := Ddata[list[0], list[1], 10];
  preEventPic := DData[list[0], list[1], 5];
  //这里应该是原本z文件的bug, 如果不处于当前场景, 在连坐标值一起修改时, 并不会同时
  //对S数据进行修改. 而<苍龙逐日>中有几条语句无意中符合了这个bug而造成正确的结果
  ModifyS := True;
  if ((MODVersion = 12) or (MODVersion = 31)) and (list[0] <> CurScence) then
    ModifyS := False;
  if ModifyS then
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

  if DData[CurScence, CurEvent, 5] <> curPic then
  begin
    InitialScence(1);
    //redraw;
    //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  end;
  if (list[0] = CurScence) and (preEventPic <> DData[list[0], list[1], 5]) then
  begin
    NeedRefreshScence := 1;
  end;
end;

//是否使用了某剧情物品

function instruct_4(inum, jump1, jump2: integer): integer;
begin
  if inum = CurItem then
    Result := jump1
  else
    Result := jump2;

end;

//询问是否战斗

function instruct_5(jump1, jump2: integer): integer;
var
  menu: integer;
  menustring: array[0..2] of WideString;
begin
  //setlength(menustring, 3);
  menustring[0] := (' 取消');
  menustring[1] := (' 戰鬥');
  menustring[2] := (' 是否與之戰鬥？');
  drawtextwithrect(screen, @menustring[2][1], CENTER_X - 75, CENTER_Y - 85, 150, colcolor(7), colcolor(5));
  menu := commonmenu2(CENTER_X - 49, CENTER_Y - 50, 98, menustring);
  if menu = 1 then
    Result := jump1
  else
    Result := jump2;
  redraw;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

end;

//战斗

function instruct_6(battlenum, jump1, jump2, getexp: integer): integer;
begin
  Result := jump2;
  if Battle(battlenum, getexp) then
    Result := jump1;

end;

procedure instruct_8(musicnum: integer);
begin
  exitscencemusicnum := musicnum;
end;

//询问是否加入

function instruct_9(jump1, jump2: integer): integer;
var
  menu: integer;
  menustring: array[0..2] of WideString;
begin
  //setlength(menustring, 3);
  menustring[0] := (' 取消');
  menustring[1] := (' 要求');
  menustring[2] := (' 是否要求加入？');
  drawtextwithrect(screen, @menustring[2][1], CENTER_X - 75, CENTER_Y - 85, 150, colcolor(7), colcolor(5));
  menu := commonmenu2(CENTER_X - 49, CENTER_Y - 50, 98, menustring);
  if menu = 1 then
    Result := jump1
  else
    Result := jump2;
  redraw;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

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
        if (Rrole[rnum].TakingItem[i1] >= 0) and (Rrole[rnum].TakingItemAmount[i1] <= 0) then
          Rrole[rnum].TakingItemAmount[i1] := 1;
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
  menustring: array[0..2] of WideString;
begin
  //setlength(menustring, 3);
  menustring[0] := ('  否');
  menustring[1] := ('  是');
  menustring[2] := (' 是否需要住宿？');
  if MODVersion <> 0 then
    menustring[2] := (' 请選擇是或者否');
  drawtextwithrect(screen, @menustring[2][1], CENTER_X - 75, CENTER_Y - 85, 150, colcolor(7), colcolor(5));
  menu := commonmenu2(CENTER_X - 49, CENTER_Y - 50, 98, menustring);
  if menu = 1 then
    Result := jump1
  else
    Result := jump2;
  redraw;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

end;

//住宿

procedure instruct_12;
var
  i, rnum: integer;
begin
  for i := 0 to 5 do
  begin
    rnum := Teamlist[i];
    if rnum >= 0 then
      if not ((RRole[rnum].Hurt > 33) or (RRole[rnum].Poison > 0)) then
      begin
        RRole[rnum].CurrentHP := RRole[rnum].MaxHP;
        RRole[rnum].CurrentMP := RRole[rnum].MaxMP;
        RRole[rnum].PhyPower := MAX_PHYSICAL_POWER;
        RRole[rnum].Hurt := RRole[rnum].Hurt - 33;
        if (RRole[rnum].Hurt < 0) then
          RRole[rnum].Hurt := 0;
        RRole[rnum].Poison := RRole[rnum].Poison - 33;
        if (RRole[rnum].Poison < 0) then
          RRole[rnum].Poison := 0;
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
  NeedRefreshScence := 0;
  for i := 0 to 5 do
  begin
    //Sdl_Delay(5);
    Redraw;
    DrawRectangleWithoutFrame(screen, 0, 0, screen.w, screen.h, 0, 100 - i * 20);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  end;
end;

//黑屏

procedure instruct_14;
var
  i: integer;
begin
  for i := 0 to 5 do
  begin
    //Redraw;
    //Sdl_Delay(2);
    DrawRectangleWithoutFrame(screen, 0, 0, screen.w, screen.h, 0, i * 20);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  end;
end;

//失败画面

procedure instruct_15;
var
  i: integer;
  str: WideString;
begin
  where := 4;
  redraw;
  str := (' 勝敗乃兵家常事，但是……');
  drawshadowtext(screen, @str[1], CENTER_X - 120, 340, colcolor(255), colcolor(255));
  str := (' 地球上又多了一失蹤人口');
  drawshadowtext(screen, @str[1], CENTER_X - 110, 370, colcolor(255), colcolor(255));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  waitanykey;
end;

function instruct_16(rnum, jump1, jump2: integer): integer;
var
  i: integer;
begin
  Result := jump2;
  for i := 0 to 5 do
  begin
    if Teamlist[i] = rnum then
    begin
      Result := jump1;
      break;
    end;
  end;
end;

procedure instruct_17(list: array of integer);
var
  i1, i2: integer;
begin
  if list[0] = -2 then
    list[0] := CurScence;
  sdata[list[0], list[1], list[3], list[2]] := list[4];
  if list[0] = CurScence then
    NeedRefreshScence := 1;

end;

function instruct_18(inum, jump1, jump2: integer): integer;
var
  i: integer;
begin
  Result := jump2;
  for i := 0 to MAX_ITEM_AMOUNT - 1 do
  begin
    if RItemList[i].Number = inum then
    begin
      Result := jump1;
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
  Result := jump1;
  for i := 0 to 5 do
  begin
    if TeamList[i] < 0 then
    begin
      Result := jump2;
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
    if Teamlist[i] >= 0 then
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
    while (SDL_PollEvent(@event) >= 0) do
    begin
      CheckBasicEvent;
      sdl_delay(50);
      DrawScenceWithoutRole(y1, i);
      //showmessage(inttostr(i));
      DrawRoleOnScence(y1, i);
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      i := i + s;
      //showmessage(inttostr(s*(x2-i)));
      if (s * (x2 - i) < 0) then
        break;
    end;
  s := sign(y2 - y1);
  i := y1 + s;
  if s <> 0 then
    while (SDL_PollEvent(@event) >= 0) do
    begin
      CheckBasicEvent;
      sdl_delay(50);
      DrawScenceWithoutRole(i, x2);
      //showmessage(inttostr(i));
      DrawRoleOnScence(i, x2);
      //Redraw;
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      i := i + s;
      if (s * (y2 - i) < 0) then
        break;
    end;
  Cx := y2;
  Cy := x2;
  //SSx:=0;
  //SSy:=0;
  //showmessage(inttostr(ssx*100+ssy));
end;

procedure instruct_26(snum, enum, add1, add2, add3: integer);
begin
  if snum = -2 then
    snum := CurScence;
  ddata[snum, enum, 2] := ddata[snum, enum, 2] + add1;
  ddata[snum, enum, 3] := ddata[snum, enum, 3] + add2;
  ddata[snum, enum, 4] := ddata[snum, enum, 4] + add3;
  if snum = CurScence then
    InitialScence(1);

end;

//Note: of course an more effective engine can take place of it.
//动画, 至今仍不完善

procedure instruct_27(enum, beginpic, endpic: integer);
var
  i, xpoint, ypoint, tempPic: integer;
  //AboutMainRole: boolean;
begin
  //AboutMainRole := false;
  if enum = -1 then
  begin
    i := beginpic;
    while SDL_PollEvent(@event) >= 0 do
    begin
      CheckBasicEvent;
      CurScenceRolePic := i div 2;
      sdl_delay(20);
      //DData[CurScence, CurEvent, 5] := -1;
      DrawScence;
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      i := i + 1;
      if i > endpic then
        break;
    end;
  end
  else
  begin
    i := beginpic;
    while SDL_PollEvent(@event) >= 0 do
    begin
      CheckBasicEvent;
      DData[CurScence, enum, 5] := i;
      DData[CurScence, enum, 6] := i;
      DData[CurScence, enum, 7] := i;
      //UpdateScence(DData[CurScence, enum, 10], DData[CurScence, enum, 9]);
      InitialScence(1);
      sdl_delay(20);
      DrawScence;
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      i := i + 1;
      if i > endpic then
        break;
    end;
    //DData[CurScence, enum, 5] := DData[CurScence, enum, 7];
    //InitialScence(1);
  end;

end;

function instruct_28(rnum, e1, e2, jump1, jump2: integer): integer;
begin
  Result := jump2;
  if (rrole[rnum].Ethics >= e1) and (rrole[rnum].Ethics <= e2) then
    Result := jump1;
end;

function instruct_29(rnum, r1, r2, jump1, jump2: integer): integer;
begin
  Result := jump2;
  if (rrole[rnum].Attack >= r1) and (rrole[rnum].Attack <= r2) then
    Result := jump1;
  if MODVersion = 41 then
    if (rrole[rnum].Attack >= r1) then
      Result := jump1;
end;

procedure instruct_30(x1, y1, x2, y2: integer);
var
  s: integer;
begin
  s := sign(x2 - x1);
  Sy := x1 + s;
  if s > 0 then
    Sface := 1;
  if s < 0 then
    Sface := 2;
  if s <> 0 then
    while SDL_PollEvent(@event) >= 0 do
    begin
      CheckBasicEvent;
      sdl_delay(50);
      DrawScenceWithoutRole(Sx, Sy);
      SStep := SStep + 1;
      if SStep >= 7 then
        SStep := 1;
      CurScenceRolePic := BeginScenceRolePic + SFace * 7 + SStep;
      DrawRoleOnScence(Sx, Sy);
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      Sy := Sy + s;
      if s * (x2 - Sy) < 0 then
        break;
    end;
  s := sign(y2 - y1);
  Sx := y1 + s;
  if s > 0 then
    Sface := 3;
  if s < 0 then
    Sface := 0;
  if s <> 0 then
    while SDL_PollEvent(@event) >= 0 do
    begin
      CheckBasicEvent;
      sdl_delay(50);
      DrawScenceWithoutRole(Sx, Sy);
      SStep := SStep + 1;
      if SStep >= 7 then
        SStep := 1;
      CurScenceRolePic := BeginScenceRolePic + SFace * 7 + SStep;
      DrawRoleOnScence(Sx, Sy);
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      Sx := Sx + s;
      if s * (y2 - Sx) < 0 then
        break;
    end;
  Sx := y2;
  Sy := x2;
  SStep := 0;
  Cx := Sx;
  Cy := Sy;
  CurScenceRolePic := 2501 + SFace * 7 + SStep;
  DrawScenceWithoutRole(Sx, Sy);
  DrawRoleOnScence(Sx, Sy);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
end;

function instruct_31(moneynum, jump1, jump2: integer): integer;
var
  i: integer;
begin
  Result := jump2;
  for i := 0 to MAX_ITEM_AMOUNT - 1 do
  begin
    if (RItemList[i].Number = MONEY_ID) and (RItemList[i].Amount >= moneynum) then
    begin
      Result := jump1;
      break;
    end;
  end;
end;

procedure instruct_32(inum, amount: integer);
var
  i: integer;
begin
  i := 0;
  while (RItemList[i].Number >= 0) and (i < MAX_ITEM_AMOUNT) do
  begin
    if (RItemList[i].Number = inum) then
    begin
      RItemList[i].Amount := RItemList[i].Amount + amount;
      if (RItemList[i].Amount < 0) and (amount >= 0) then
        RItemList[i].Amount := 32767;
      if (RItemList[i].Amount < 0) and (amount < 0) then
        RItemList[i].Amount := 0;
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
  word: WideString;
begin
  for i := 0 to 9 do
  begin
    if (RRole[rnum].Magic[i] <= 0) or (RRole[rnum].Magic[i] = magicnum) then
    begin
      if RRole[rnum].Magic[i] > 0 then
        RRole[rnum].Maglevel[i] := RRole[rnum].Maglevel[i] + 100;
      RRole[rnum].Magic[i] := magicnum;
      if RRole[rnum].MagLevel[i] > 999 then
        RRole[rnum].Maglevel[i] := 999;
      break;
    end;
  end;
  //if i = 10 then rrole[rnum].data[i+63] := magicnum;
  if dismode = 0 then
  begin
    DrawRectangle(screen, CENTER_X - 75, 98, 145, 76, 0, colcolor(255), 30);
    word := (' 學會');
    drawshadowtext(screen, @word[1], CENTER_X - 90, 125, colcolor($7), colcolor($5));
    drawbig5shadowtext(screen, @rrole[rnum].Name, CENTER_X - 90, 100, colcolor($23), colcolor($21));
    drawbig5shadowtext(screen, @Rmagic[magicnum].Name, CENTER_X - 90, 150, colcolor($66), colcolor($64));
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    waitanykey;
    redraw;
  end;
end;

procedure instruct_34(rnum, iq: integer);
var
  word: WideString;
begin
  if RRole[rnum].Aptitude + iq <= 100 then
  begin
    RRole[rnum].Aptitude := RRole[rnum].Aptitude + iq;
  end
  else
  begin
    iq := 100 - RRole[rnum].Aptitude;
    RRole[rnum].Aptitude := 100;
  end;
  if iq > 0 then
  begin
    DrawRectangle(screen, CENTER_X - 75, 98, 145, 51, 0, colcolor(255), 30);
    word := (' 資質增加');
    drawshadowtext(screen, @word[1], CENTER_X - 90, 125, colcolor($7), colcolor($5));
    drawbig5shadowtext(screen, @rrole[rnum].Name, CENTER_X - 90, 100, colcolor($23), colcolor($21));
    word := format('%3d', [iq]);
    drawengshadowtext(screen, @word[1], CENTER_X + 30, 125, colcolor($66), colcolor($64));
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
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
  else
  begin
    RRole[rnum].Magic[magiclistnum] := magicnum;
    RRole[rnum].MagLevel[magiclistnum] := exp;
  end;
end;

function instruct_36(sexual, jump1, jump2: integer): integer;
begin
  Result := jump2;
  if rrole[0].Sexual = sexual then
    Result := jump1;
  if sexual > 255 then
    if x50[$7000] = 0 then
      Result := jump1
    else
      Result := jump2;
end;

procedure instruct_37(Ethics: integer);
begin
  RRole[0].Ethics := RRole[0].Ethics + ethics;
  if RRole[0].Ethics > 100 then
    RRole[0].Ethics := 100;
  if RRole[0].Ethics < 0 then
    RRole[0].Ethics := 0;
end;

procedure instruct_38(snum, layernum, oldpic, newpic: integer);
var
  i1, i2: integer;
begin
  if snum = -2 then
    snum := CurScence;
  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      if Sdata[snum, layernum, i1, i2] = oldpic then
        Sdata[snum, layernum, i1, i2] := newpic;
    end;
  if snum = CurScence then
    NeedRefreshScence := 1;
end;

procedure instruct_39(snum: integer);
begin
  Rscence[snum].EnCondition := 0;
end;

procedure instruct_40(director: integer);
begin
  Sface := director;
  CurScenceRolePic := 2500 + SFace * 7 + 1;
  DrawScence;
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
  Result := jump2;
  for i := 0 to 5 do
  begin
    if Teamlist[i] >= 0 then
      if Rrole[Teamlist[i]].Sexual = 1 then
      begin
        Result := jump1;
        break;
      end;
  end;
end;

function instruct_43(inum, jump1, jump2: integer): integer;
var
  i: integer;
begin
  Result := instruct_18(inum, jump1, jump2);
end;

procedure instruct_44(enum1, beginpic1, endpic1, enum2, beginpic2, endpic2: integer);
var
  i: integer;
begin
  SData[CurScence, 3, DData[CurScence, enum1, 10], DData[CurScence, enum1, 9]] := enum1;
  SData[CurScence, 3, DData[CurScence, enum2, 10], DData[CurScence, enum2, 9]] := enum2;
  i := 0;
  while SDL_PollEvent(@event) >= 0 do
  begin
    CheckBasicEvent;
    DData[CurScence, enum1, 5] := beginpic1 + i;
    DData[CurScence, enum2, 5] := beginpic2 + i;
    //UpdateScence(DData[CurScence, enum1, 10], DData[CurScence, enum1, 9]);
    //UpdateScence(DData[CurScence, enum2, 10], DData[CurScence, enum2, 9]);
    InitialScence(1);
    sdl_delay(20);
    //DrawScenceWithoutRole(Sx, Sy);
    DrawScence;
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    i := i + 1;
    if i > endpic1 - beginpic1 then
      break;
  end;
  //SData[CurScence, 3, DData[CurScence, [enum,10],DData[CurScence, [enum,9]]:=-1;
end;

procedure instruct_44e(enum1, beginpic1, endpic1, enum2, beginpic2, enum3, beginpic3: integer);
var
  i: integer;
begin
  SData[CurScence, 3, DData[CurScence, enum1, 10], DData[CurScence, enum1, 9]] := enum1;
  SData[CurScence, 3, DData[CurScence, enum2, 10], DData[CurScence, enum2, 9]] := enum2;
  SData[CurScence, 3, DData[CurScence, enum3, 10], DData[CurScence, enum3, 9]] := enum3;
  i := 0;
  while SDL_PollEvent(@event) >= 0 do
  begin
    CheckBasicEvent;
    DData[CurScence, enum1, 5] := beginpic1 + i;
    DData[CurScence, enum2, 5] := beginpic2 + i;
    DData[CurScence, enum3, 5] := beginpic3 + i;
    //UpdateScence(DData[CurScence, enum1, 10], DData[CurScence, enum1, 9]);
    //UpdateScence(DData[CurScence, enum2, 10], DData[CurScence, enum2, 9]);
    InitialScence(1);
    sdl_delay(20);
    //DrawScenceWithoutRole(Sx, Sy);
    DrawScence;
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    i := i + 1;
    if i > endpic1 - beginpic1 then
      break;
  end;
  //SData[CurScence, 3, DData[CurScence, [enum,10],DData[CurScence, [enum,9]]:=-1;
end;

procedure instruct_45(rnum, speed: integer);
var
  word: WideString;
begin
  RRole[rnum].Speed := RRole[rnum].Speed + speed;
  DrawRectangle(screen, CENTER_X - 75, 98, 145, 51, 0, colcolor(255), 30);
  word := (' 輕功增加');
  drawshadowtext(screen, @word[1], CENTER_X - 90, 125, colcolor($7), colcolor($5));
  drawbig5shadowtext(screen, @rrole[rnum].Name, CENTER_X - 90, 100, colcolor($23), colcolor($21));
  word := format('%4d', [speed]);
  drawengshadowtext(screen, @word[1], CENTER_X + 20, 125, colcolor($66), colcolor($64));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  waitanykey;
  redraw;
end;

procedure instruct_46(rnum, mp: integer);
var
  word: WideString;
begin
  RRole[rnum].MaxMP := RRole[rnum].MaxMP + mp;
  RRole[rnum].CurrentMP := RRole[rnum].MaxMP;
  DrawRectangle(screen, CENTER_X - 75, 98, 145, 51, 0, colcolor(255), 30);
  word := (' 內力增加');
  drawshadowtext(screen, @word[1], CENTER_X - 90, 125, colcolor($7), colcolor($5));
  drawbig5shadowtext(screen, @rrole[rnum].Name, CENTER_X - 90, 100, colcolor($23), colcolor($21));
  word := format('%4d', [mp]);
  drawengshadowtext(screen, @word[1], CENTER_X + 20, 125, colcolor($66), colcolor($64));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  waitanykey;
  redraw;
end;

procedure instruct_47(rnum, attack: integer);
var
  word: WideString;
begin
  RRole[rnum].Attack := RRole[rnum].Attack + attack;
  DrawRectangle(screen, CENTER_X - 75, 98, 145, 51, 0, colcolor(255), 30);
  word := (' 武力增加');
  drawshadowtext(screen, @word[1], CENTER_X - 90, 125, colcolor($7), colcolor($5));
  drawbig5shadowtext(screen, @rrole[rnum].Name, CENTER_X - 90, 100, colcolor($23), colcolor($21));
  word := format('%4d', [attack]);
  drawengshadowtext(screen, @word[1], CENTER_X + 20, 125, colcolor($66), colcolor($64));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  waitanykey;
  redraw;
end;

procedure instruct_48(rnum, hp: integer);
var
  word: WideString;
begin
  RRole[rnum].MaxHP := RRole[rnum].MaxHP + hp;
  RRole[rnum].CurrentHP := RRole[rnum].MaxHP;
  DrawRectangle(screen, CENTER_X - 75, 98, 145, 51, 0, colcolor(255), 30);
  word := (' 生命增加');
  drawshadowtext(screen, @word[1], CENTER_X - 90, 125, colcolor($7), colcolor($5));
  drawbig5shadowtext(screen, @rrole[rnum].Name, CENTER_X - 90, 100, colcolor($23), colcolor($21));
  word := format('%4d', [hp]);
  drawengshadowtext(screen, @word[1], CENTER_X + 20, 125, colcolor($66), colcolor($64));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
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
  Result := 0;
  if (list[0] > 128) or (MODVersion = 11) then
  begin
    Result := list[6];
    p := 0;
    for i := 0 to 4 do
    begin
      p := p + instruct_18(list[i], 1, 0);
    end;
    if p = 5 then
      Result := list[5];
  end
  else
  begin
    Result := instruct_50e(list[0], list[1], list[2], list[3], list[4], list[5], list[6]);
  end;
end;

procedure instruct_51;
begin
  instruct_1(SOFTSTAR_BEGIN_TALK + random(SOFTSTAR_NUM_TALK), $72, 0);
end;

procedure instruct_52;
var
  word: WideString;
begin
  DrawRectangle(screen, CENTER_X - 110, 98, 220, 26, 0, colcolor(255), 30);
  word := (' 你的品德指數為：');
  drawshadowtext(screen, @word[1], CENTER_X - 125, 100, colcolor($7), colcolor($5));
  word := format('%3d', [rrole[0].Ethics]);
  drawengshadowtext(screen, @word[1], CENTER_X + 65, 100, colcolor($66), colcolor($64));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  waitanykey;
  redraw;
end;

procedure instruct_53;
var
  word: WideString;
begin
  DrawRectangle(screen, CENTER_X - 110, 98, 220, 26, 0, colcolor(255), 30);
  word := (' 你的聲望指數為：');
  drawshadowtext(screen, @word[1], CENTER_X - 125, 100, colcolor($7), colcolor($5));
  word := format('%3d', [rrole[0].Repute]);
  drawengshadowtext(screen, @word[1], CENTER_X + 65, 100, colcolor($66), colcolor($64));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
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

function instruct_55(enum, Value, jump1, jump2: integer): integer;
begin
  Result := jump2;
  if DData[CurScence, enum, 2] = Value then
    Result := jump1;
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

procedure instruct_57;
var
  i: integer;
begin
  {for i:=0 to endpic1-beginpic1 do
  begin
    DData[CurScence, [enum1,5]:=beginpic1+i;
    DData[CurScence, [enum2,5]:=beginpic2+i;
    UpdateScence(DData[CurScence, [enum1,10],DData[CurScence, [enum1,9]);
    UpdateScence(DData[CurScence, [enum2,10],DData[CurScence, [enum2,9]);
    sdl_delay(20);
    DrawScenceByCenter(Sx,Sy);
    DrawScence;
    SDL_UpdateRect2(screen,0,0,screen.w,screen.h);
  end;}
  instruct_27(-1, 3832 * 2, 3844 * 2);
  instruct_44e(2, 3845 * 2, 3873 * 2, 3, 3874 * 2, 4, 3903 * 2);
end;

procedure instruct_58;
var
  i, p: integer;
const
  headarray: array[0..29] of integer = (8, 21, 23, 31, 32, 43, 7, 11, 14, 20, 33, 34, 10, 12, 19,
    22, 56, 68, 13, 55, 62, 67, 70, 71, 26, 57, 60, 64, 3, 69);
begin
  for i := 0 to 14 do
  begin
    p := random(2);
    instruct_1(2854 + i * 2 + p, headarray[i * 2 + p], random(2) * 4 + random(2));
    if not (battle(102 + i * 2 + p, 0)) then
    begin
      instruct_15;
      break;
    end;
    instruct_14;
    instruct_13;
    if i mod 3 = 2 then
    begin
      instruct_1(2891, 70, 4);
      instruct_12;
      instruct_14;
      instruct_13;
    end;
  end;
  if where <> 3 then
  begin
    instruct_1(2884, 0, 3);
    instruct_1(2885, 0, 3);
    instruct_1(2886, 0, 3);
    instruct_1(2887, 0, 3);
    instruct_1(2888, 0, 3);
    instruct_1(2889, 0, 1);
    instruct_2($8F, 1);
  end;

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
  Result := jump2;
  if snum = -2 then
    snum := CurScence;
  if (Ddata[snum, enum, 5] = pic) or (Ddata[snum, enum, 6] = pic) or (Ddata[snum, enum, 7] = pic) then
    Result := jump1;
  //showmessage(inttostr(Ddata[snum,enum,5]));
end;

function instruct_61(jump1, jump2: integer): integer;
var
  i: integer;
begin
  Result := jump1;
  for i := 11 to 24 do
  begin
    if Ddata[CurScence, i, 5] <> 4664 then
    begin
      Result := jump2;
    end;
  end;
end;

procedure instruct_62(enum1, beginpic1, endpic1, enum2, beginpic2, endpic2: integer);
var
  i: integer;
  str: WideString;
begin
  CurScenceRolePic := -1;
  instruct_44(enum1, beginpic1, endpic1, enum2, beginpic2, endpic2);
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
  i := fileopen(AppPath + 'list/end.txt', fmOpenRead);
  len := fileseek(i, 0, 2);
  fileseek(i, 0, 0);
  setlength(str, len + 1);
  fileread(i, str[1], len);
  fileclose(i);
  p := 1;
  x := 30;
  y := 80;
  drawrectanglewithoutframe(screen, 0, 0, CENTER_X * 2, CENTER_Y * 2, 0, 60);
  for i := 1 to len + 1 do
  begin
    if str[i] = widechar(10) then
      str[i] := ' ';
    if str[i] = widechar(13) then
    begin
      str[i] := widechar(0);
      drawshadowtext(screen, @str[p], x, y, colcolor($FF), colcolor($FF));
      p := i + 1;
      y := y + 25;
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    end;
    if str[i] = widechar($2A) then
    begin
      str[i] := ' ';
      y := 80;
      redraw;
      waitanykey;
      drawrectanglewithoutframe(screen, 0, 0, CENTER_X * 2, CENTER_Y * 2, 0, 60);
    end;
  end;
  waitanykey;
  instruct_14;

  i := 0;
  while SDL_PollEvent(@event) >= 0 do
  begin
    CheckBasicEvent;
    if i mod 5 = 0 then
    begin
      display_img(PChar(AppPath + 'resource/end.png'), 0, i);
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      sdl_delay(20);
    end;
    i := i - 1;
    if i < 440 - 794 then
      break;
  end;
  waitanykey;

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
  menustring, menuengstring: array[0..4] of WideString;
begin
  //setlength(Menustring, 5);
  //setlength(Menuengstring, 5);
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
  if amount >= 1 then
  begin
    menu := commonmenu(CENTER_X - 120, 150, 105 + length(menuengstring[0]) * 10, amount - 1, menustring, menuengstring);
    redraw;
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
      end
      else
        instruct_1($B9F, $6F, 0);
    end;
  end;
end;

procedure instruct_66(musicnum: integer);
begin
  stopmp3;
  playmp3(musicnum, -1);
end;

procedure instruct_67(Soundnum: integer);
begin
  PlaySoundA(Soundnum, 0);
  {if SoundNum in [Low(Asound)..High(Asound)] then
    if Asound[SoundNum] <> nil then
      Mix_PlayChannel(-1, Asound[SoundNum], 0);}
end;

//50指令中获取变量值

function e_GetValue(bit, t, x: integer): integer;
var
  i: integer;
begin
  i := t and (1 shl bit);
  if i = 0 then
    Result := x
  else
    Result := x50[x];
end;

function CutRegion(x: integer): integer;
begin
  if (x >= $8000) or (x < -$8000) then
    Result := (x + $8000) mod $10000 - $8000;
end;

//Expanded 50 instructs.

function instruct_50e(code, e1, e2, e3, e4, e5, e6: integer): integer;
var
  i, t1, grp, idx, offset, len, i1, i2: integer;
  p, p1: PChar;
  //ps :pstring;
  str: string;
  word, word1: WideString;
  menustring, menuengstring: array of WideString;
begin
  Result := 0;
  case code of
    0: //Give a value to a papameter.
      begin
        x50[e1] := e2;
      end;
    1: //Give a value to one member in parameter group.
      begin
        t1 := e3 + e_getvalue(0, e1, e4);
        t1 := CutRegion(t1);
        x50[t1] := e_getvalue(1, e1, e5);
        if e2 = 1 then
          x50[t1] := x50[t1] and $FF;
      end;
    2: //Get the value of one member in parameter group.
      begin
        t1 := e3 + e_getvalue(0, e1, e4);
        t1 := CutRegion(t1);
        x50[e5] := x50[t1];
        if e2 = 1 then
          x50[t1] := x50[t1] and $FF;
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
          0: if not (x50[e3] < t1) then
              x50[$7000] := 1;
          1: if not (x50[e3] <= t1) then
              x50[$7000] := 1;
          2: if not (x50[e3] = t1) then
              x50[$7000] := 1;
          3: if not (x50[e3] <> t1) then
              x50[$7000] := 1;
          4: if not (x50[e3] >= t1) then
              x50[$7000] := 1;
          5: if not (x50[e3] > t1) then
              x50[$7000] := 1;
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
        {idx := fileopen(AppPath + 'resource/talk.idx', fmopenread);
        grp := fileopen(AppPath + 'resource/talk.grp', fmopenread);
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
        //fileread(grp, x50[e3], len);
        fileclose(idx);
        fileclose(grp);}
        len := 0;
        if t1 = 0 then
        begin
          offset := 0;
          len := TIdx[0];
        end
        else
        begin
          offset := TIdx[t1 - 1];
          len := TIdx[t1] - offset;
        end;
        //setlength(talkarray, len + 1);
        move(TDef[offset], x50[e3], len);
        p := @x50[e3];
        for i := 0 to len - 2 do //最后一位为0, 不处理
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
        x50[e2] := length(PChar(@x50[e1]));
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
        if (length(p1) mod 2 = 1) then
        begin
          p^ := char($20);
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
        //SDL_UpdateRect2(screen,0,0,screen.w,screen.h);
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
        //SDL_UpdateRect2(screen,0,0,screen.w,screen.h);
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
          $051C83:
            begin
              puint16(@Acol[e6])^ := e5;
              puint16(@Acol1[e6])^ := e5;
              puint16(@Acol2[e6])^ := e5;
              //Acol2[e6] := e5 mod 256;
              //Acol2[e6 + 1] := e5 div 256;
            end;
          $01D295E:
            begin
              CurScence := e5;
            end;
        end;
        //redraw;
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
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
          $1E6ED6: x50[e5] := x50[28100];
          $556DA: x50[e5] := Ax;
          $556DC: x50[e5] := Ay;
          $1C0B90: x50[e5] := sdl_getticks div 55 mod 65536;
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
        if (t1 >= $1E4A04) and (t1 < $1E6A04) then
        begin
          i := (t1 - $1E4A04) div 2;
          //showmessage(inttostr(e3));
          x50[e5] := Bfield[2, i mod 64, i div 64];
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
          if (p1 + i)^ = char(0) then
            break;
        end;
        (p + i + 1)^ := char($20);
        (p + i + 2)^ := char(0);
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
        x50[e4] := brole[e2].Data[e3 div 2];
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
        Result := 655360 * (e3 + 1) + x50[e2];
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
        //for i := 0 to length(p) do showmessage(inttostr(pbyte(p+i)^));
        while byte(p^) > 0 do
        begin
          if byte(p^) = $2A then
          begin
            p^ := char(0);
            drawbig5shadowtext(screen, p1, e3 - 22, e4 + 22 * i - 3, colcolor(e5 and $FF), colcolor((e5 and $FF00) shl 8));
            i := i + 1;
            p1 := p + 1;
          end;
          p := p + 1;
        end;
        drawbig5shadowtext(screen, p1, e3 - 22, e4 + 22 * i - 3, colcolor(e5 and $FF), colcolor((e5 and $FF00) shl 8));
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        //waitanykey;
      end;
    34: //Draw a rectangle as background.
      begin
        e2 := e_getvalue(0, e1, e2);
        e3 := e_getvalue(1, e1, e3);
        e4 := e_getvalue(2, e1, e4);
        e5 := e_getvalue(3, e1, e5);
        Drawrectangle(screen, e2, e3, e4, e5, 0, colcolor($FF), 40);
        //SDL_UpdateRect2(screen,e1,e2,e3+1,e4+1);
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
        e3 := abs(e3); //该值不应为负, 某些mod中可能写法有误
        while byte(p^) > 0 do
        begin
          //showmessage('');
          if byte(p^) = $2A then
          begin
            if t1 > i2 then
              i2 := t1;
            t1 := 0;
            i1 := i1 + 1;
          end;
          if byte(p^) = $20 then
            t1 := t1 + 1;
          p := p + 1;
          t1 := t1 + 1;
        end;
        if t1 > i2 then
          i2 := t1;
        p := p - 1;
        if i1 = 0 then
          i1 := 1;
        if byte(p^) = $2A then
          i1 := i1 - 1;
        DrawRectangle(screen, e3, e4, i2 * 10 + 25, i1 * 22 + 5, 0, colcolor(255), 30);
        p := @x50[e2];
        p1 := p;
        i := 0;
        while byte(p^) > 0 do
        begin
          if byte(p^) = $2A then
          begin
            p^ := char(0);
            drawbig5shadowtext(screen, p1, e3 - 17, e4 + 22 * i + 2, colcolor(e5 and $FF), colcolor((e5 and $FF00) shl 8));
            i := i + 1;
            p1 := p + 1;
          end;
          p := p + 1;
        end;
        drawbig5shadowtext(screen, p1, e3 - 17, e4 + 22 * i + 2, colcolor(e5 and $FF), colcolor((e5 and $FF00) shl 8));
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        i := waitanykey;
        if i = sdlk_y then
          x50[$7000] := 0
        else
          x50[$7000] := 1;
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
          i1 := length(PChar(@x50[x50[e3 + i]]));
          if i1 > t1 then
            t1 := i1;
        end;
        x50[e4] := commonmenu(e5, e6, t1 * 10 + 5, e2 - 1, menustring) + 1;
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
          i1 := length(PChar(@x50[x50[e3 + i]]));
          if i1 > i2 then
            i2 := i1;
        end;
        t1 := (e1 shr 8) and $FF;
        if t1 = 0 then
          t1 := 5;
        //showmessage(inttostr(t1));
        x50[e4] := commonscrollmenu(e5, e6, i2 * 10 + 5, e2 - 1, t1, menustring) + 1;
      end;
    41: //Draw a picture.
      begin
        e3 := e_getvalue(0, e1, e3);
        e4 := e_getvalue(1, e1, e4);
        e5 := e_getvalue(2, e1, e5);
        case e2 of
          0:
            begin
              if where = 1 then
                DrawSPic(e5 div 2, e3, e4, 0, 0, screen.w, screen.h)
              else
                DrawMPic(e5 div 2, e3, e4);
            end;
          1: DrawHeadPic(e5, e3, e4);
          2:
            begin
              str := AppPath + 'pic/' + IntToStr(e5) + '.png';
              display_img(@str[1], e3, e4);
            end;
        end;
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
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
          if e5 = 0 then
            instruct_2(e3, e4)
          else
            instruct_32(e3, e4);
        end
        else if e2 = 201 then
          NewTalk(e3, e4, e5, e6 mod 100, (e6 mod 100) div 10, e6 div 100, 0)
        else if (e2 = 999) and (MODVersion = 62) then
        begin
          CurScence := e3;
          Sx := e5;
          Sy := e4;
          Cx := Sx;
          Cy := Sy;
          instruct_14;
          InitialScence;
          Drawscence;
          ShowScenceName(CurScence);
          CheckEvent3;
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
          str := str + 'x' + IntToStr(i) + '=' + IntToStr(x50[i]) + char(13) + char(10);
        messagebox(0, @str[1], 'KYS Windows', MB_OK);
      end;
    49: //In PE files, you can't call any procedure as your wish.
      begin
      end;
    50: //Enter name for items, magics and roles.
      begin
        e2 := e_getvalue(0, e1, e2);
        e3 := e_getvalue(1, e1, e3);
        e4 := e_getvalue(2, e1, e4);
        e5 := e_getvalue(3, e1, e5);

        case e2 of
          0: p := @Rrole[e3].Name[0];
          1: p := @Ritem[e3].Name[0];
          2: p := @Rmagic[e3].Name[0];
          3: p := @Rscence[e3].Name[0];
        end;
        ShowMessage(IntToStr(e4));
        word1 := big5tounicode(p);
        word1 := MidStr(word1, 2, length(word1) - 1);
        word := '請輸入名稱              ';
        word := InputBox('Enter name', word, word1);
        str := unicodetobig5(@word[1]);
        p1 := @str[1];
        for i := 0 to e5 - 1 do
          (p + i)^ := (p1 + i)^;
      end;
    51: //Enter a number.
      begin
        while (True) do
        begin
          word := InputBox('输入数量 ',
            '输入数量           ',
            '0');
          try
            i := StrToInt(word);
            break;
          except
            ShowMessage('输入错误，请重新输入！            ');
          end;
        end;
        x50[e1] := i;
      end;
    52: //Judge someone grasp some mggic.
      begin
        e2 := e_getvalue(0, e1, e2);
        e3 := e_getvalue(1, e1, e3);
        e4 := e_getvalue(2, e1, e4);
        x50[$7000] := 1;
        if (HaveMagic(e2, e3, e4) = True) then
          x50[$7000] := 0;
      end;
    60: //Call scripts.
      begin
        e2 := e_getvalue(0, e1, e2);
        e3 := e_getvalue(1, e1, e3);
        execscript(PChar('script/' + IntToStr(e2) + '.lua'), PChar('f' + IntToStr(e3)));
      end;
  end;

end;

//判断某人有否某武功某级

function HaveMagic(person, mnum, lv: integer): boolean;
var
  i: integer;
begin
  Result := False;
  for i := 0 to 9 do
    if (RRole[person].Magic[i] = mnum) then
      if (RRole[person].MagLevel[i] >= lv) then
        Result := True;
end;

procedure StudyMagic(rnum, magicnum, newmagicnum, level, dismode: integer);
var
  i: integer;
  word: WideString;
begin
  for i := 0 to 9 do
  begin
    if (RRole[rnum].Magic[i] = magicnum) or (RRole[rnum].Magic[i] = newmagicnum) then
    begin
      if level <> -2 then
        RRole[rnum].Maglevel[i] := RRole[rnum].Maglevel[i] + level * 100;
      RRole[rnum].Magic[i] := newmagicnum;
      if RRole[rnum].MagLevel[i] > 999 then
        RRole[rnum].Maglevel[i] := 999;
      break;
    end;
  end;
  //if i = 10 then rrole[rnum].data[i+63] := magicnum;
  if dismode = 0 then
  begin
    DrawRectangle(screen, CENTER_X - 75, 98, 145, 76, 0, colcolor(255), 30);
    word := (' 學會');
    drawshadowtext(screen, @word[1], CENTER_X - 90, 125, colcolor($7), colcolor($5));
    drawbig5shadowtext(screen, @rrole[rnum].Name, CENTER_X - 90, 100, colcolor($23), colcolor($21));
    drawbig5shadowtext(screen, @Rmagic[newmagicnum].Name, CENTER_X - 90, 150, colcolor($66), colcolor($64));
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    waitanykey;
    redraw;
  end;
end;

procedure NewTalk(headnum, talknum, namenum, place, showhead, color, frame: integer);
var
  k, alen, newcolor, color1, color2, nh, nw, ch, c1, r1, n, namelen, i, t1, grp, idx: integer;
  offset, len, i1, i2, face, c, nx, ny, hx, hy, hw, hh, x, y, w, h, cell, row: integer;
  np3, np, np1, np2, tp, p1, ap: PChar;
  actorarray, talkarray, namearray, name1, name2: array of byte;
  pword: array[0..1] of Uint16;
  {wd,}str: string;
  temp2: WideString;
  wd: string;
begin
  pword[1] := 0;
  face := 4900;
  case color of
    0: color := 28515;
    1: color := 28421;
    2: color := 28435;
    3: color := 28563;
    4: color := 28466;
    5: color := 28450;
  end;
  color1 := color and $FF;
  color2 := (color shr 8) and $FF;
  x := 68;
  y := 320;
  w := 511;
  h := 109;
  nw := 86;
  nh := 28;
  hx := 68;
  hy := 244;
  hw := 57;
  hh := 72;
  nx := 129;
  ny := 288;
  if showhead = 1 then
    nx := x;

  row := 5;
  cell := 25;
  if place = 1 then
  begin
    hx := 522;
    nx := 431;
    if showhead = 1 then
      nx := x + w - nw;
  end;

  len := 0;
  if talknum = 0 then
  begin
    offset := 0;
    len := TIdx[0];
  end
  else
  begin
    offset := TIdx[talknum - 1];
    len := TIdx[talknum] - offset;
  end;

  setlength(talkarray, len + 1);
  move(TDef[offset], talkarray[0], len);
  for i := 0 to len - 1 do
  begin
    talkarray[i] := talkarray[i] xor $FF;
    if talkarray[i] = 255 then
      talkarray[i] := 0;
  end;
  talkarray[len] := 0;
  tp := @talkarray[0];

  //read name
  if namenum > 0 then
  begin
    namelen := 0;
    if namenum = 0 then
    begin
      offset := 0;
      namelen := TIdx[0];
    end
    else
    begin
      offset := TIdx[namenum - 1];
      namelen := TIdx[namenum] - offset;
    end;

    setlength(namearray, namelen + 1);
    move(TDef[offset], namearray[0], namelen);

    for i := 0 to namelen - 2 do
    begin
      namearray[i] := namearray[i] xor $FF;
      if namearray[i] = 255 then
        namearray[i] := 0;
    end;
    namearray[namelen - 1] := 0;
    np := @namearray[0];
  end
  else if namenum = -2 then
  begin
    for i := 0 to length(rrole) - 1 do
    begin
      if Rrole[i].HeadNum = headnum then
      begin
        p1 := @Rrole[i].Name;
        namelen := 10;
        setlength(namearray, namelen);
        np := @namearray[0];
        for n := 0 to namelen - 1 do
        begin
          (np + n)^ := (p1 + n)^;
          // if (p1 + n)^ = char(0) then break;
        end;
        (np + n)^ := char(0);
        (np + n + 1)^ := char(0);
        break;
      end;
    end;
  end;

  p1 := @Rrole[0].Name;
  alen := length(p1) + 2;
  setlength(actorarray, alen);
  ap := @actorarray[0];
  for n := 0 to alen - 1 do
  begin
    (ap + n)^ := (p1 + n)^;
    if (p1 + n)^ = char(0) then
      break;
  end;
  (ap + n)^ := char($0);
  (ap + n + 1)^ := char(0);

  if alen = 4 then
  begin
    setlength(name1, 3);
    np1 := @name1[0];
    np1^ := ap^;
    (np1 + 1)^ := (ap + 1)^;
    (np1 + 2)^ := char(0);
    setlength(name2, 3);
    np2 := @name2[0];
    np2^ := ap^;
    (np2 + 1)^ := (ap + 1)^;
    (np2 + 2)^ := char(0);
    ;
  end
  else if alen = 6 then
  begin
    setlength(name1, 3);
    np1 := @name1[0];
    np1^ := ap^;
    (np1 + 1)^ := (ap + 1)^;
    (np1 + 2)^ := char(0);
    ;
    setlength(name2, 3);
    np2 := @name2[0];
    np2^ := (ap + 2)^;
    (np2 + 1)^ := (ap + 3)^;
    (np2 + 2)^ := char(0);
  end
  else if alen > 6 then
  begin
    if ((puint16(ap)^ = $6EAB) and ((puint16(ap + 2)^ = $63AE))) or
      ((puint16(ap)^ = $E8A6) and ((puint16(ap + 2)^ = $F9AA))) or
      ((puint16(ap)^ = $46AA) and ((puint16(ap + 2)^ = $E8A4))) or
      ((puint16(ap)^ = $4FA5) and ((puint16(ap + 2)^ = $B0AA))) or
      ((puint16(ap)^ = $7DBC) and ((puint16(ap + 2)^ = $65AE))) or
      ((puint16(ap)^ = $71A5) and ((puint16(ap + 2)^ = $A8B0))) or
      ((puint16(ap)^ = $D1BD) and ((puint16(ap + 2)^ = $AFB8))) or
      ((puint16(ap)^ = $71A5) and ((puint16(ap + 2)^ = $C5AA))) or
      ((puint16(ap)^ = $D3A4) and ((puint16(ap + 2)^ = $76A5))) or
      ((puint16(ap)^ = $BDA4) and ((puint16(ap + 2)^ = $5DAE))) or
      ((puint16(ap)^ = $DABC) and ((puint16(ap + 2)^ = $A7B6))) or
      ((puint16(ap)^ = $43AD) and ((puint16(ap + 2)^ = $DFAB))) or
      ((puint16(ap)^ = $71A5) and ((puint16(ap + 2)^ = $7BAE))) or
      ((puint16(ap)^ = $B9A7) and ((puint16(ap + 2)^ = $43C3))) or
      ((puint16(ap)^ = $61B0) and ((puint16(ap + 2)^ = $D5C1))) or
      ((puint16(ap)^ = $74A6) and ((puint16(ap + 2)^ = $E5A4))) or
      ((puint16(ap)^ = $DDA9) and ((puint16(ap + 2)^ = $5BB6))) then
    begin
      setlength(name1, 5);
      np1 := @name1[0];
      np1^ := ap^;
      (np1 + 1)^ := (ap + 1)^;
      (np1 + 2)^ := (ap + 2)^;
      (np1 + 3)^ := (ap + 3)^;
      (np1 + 4)^ := char(0);
      setlength(name2, alen + 1 - 4);
      np2 := @name2[0];
      for i := 0 to length(name2) - 1 do
        (np2 + i)^ := (ap + i + 4)^;
    end
    else
    begin
      setlength(name1, 3);
      np1 := @name1[0];
      np1^ := ap^;
      (np1 + 1)^ := (ap + 1)^;
      (np1 + 2)^ := char(0);
      setlength(name2, alen + 1 - 2);
      np2 := @name2[0];
      for i := 0 to length(name2) - 1 do
        (np2 + i)^ := (ap + i + 2)^;
    end;
  end;

  str := ' ' + tp;

  setlength(wd, 0);
  i := 0;
  while i < length(str) do
  begin
    setlength(wd, length(wd) + 1);
    wd[length(wd) - 1] := str[i];
    if (integer(str[i]) in [$81..$FE]) {and (integer(str[i + 1]) <> $7E)} then
    begin
      setlength(wd, length(wd) + 1);
      wd[length(wd) - 1] := str[i + 1];
      wd[length(wd) - 2] := str[i];
      Inc(i, 2);
      continue;
    end;
    if (integer(str[i]) in [$20..$7F]) then
    begin
      if str[i] = '^' then
      begin
        if (integer(str[i + 1]) in [$30..$39]) or (str[i + 1] = '^') then
        begin
          setlength(wd, length(wd) + 1);
          wd[length(wd) - 1] := str[i + 1];
          Inc(i, 2);
          continue;
        end;
      end
      else if (str[i] = '*') and (str[i + 1] = '*') then
      begin
        setlength(wd, length(wd) + 1);
        wd[length(wd) - 1] := str[i + 1];
        Inc(i, 2);
        continue;
      end
      else if (str[i] = '&') and (str[i + 1] = '&') then
      begin
        setlength(wd, length(wd) + 1);
        wd[length(wd) - 1] := str[i + 1];
        Inc(i, 2);
        continue;
      end
      else if (str[i] = '#') and (str[i + 1] = '#') then
      begin
        setlength(wd, length(wd) + 1);
        wd[length(wd) - 1] := str[i + 1];
        Inc(i, 2);
        continue;
      end
      else if (str[i] = '@') and (str[i + 1] = '@') then
      begin
        setlength(wd, length(wd) + 1);
        wd[length(wd) - 1] := str[i + 1];
        Inc(i, 2);
        continue;
      end
      else if (str[i] = '$') and (str[i + 1] = '$') then
      begin
        setlength(wd, length(wd) + 1);
        wd[length(wd) - 1] := str[i + 1];
        Inc(i, 2);
        continue;
      end
      else if (str[i] = '%') and (str[i + 1] = '%') then
      begin
        setlength(wd, length(wd) + 1);
        wd[length(wd) - 1] := str[i + 1];
        Inc(i, 2);
        continue;
      end;
      setlength(wd, length(wd) + 1);
      wd[length(wd) - 1] := char($A0 + (smallint(str[i]) - 32));
      wd[length(wd) - 2] := char($A3);
    end;
    Inc(i);
  end;
  tp := @wd[3];

  ch := 0;

  while ((puint16(tp + ch))^ shl 8 <> 0) and ((puint16(tp + ch))^ shr 8 <> 0) do
  begin
    redraw;
    c1 := 0;
    r1 := 0;
    DrawRectangle(screen, x, y, w, h, frame, colcolor($FF), 40);
    if (showhead = 0) or (headnum < 0) then
    begin
      DrawRectangle(screen, hx, hy, hw, hh, frame, colcolor($FF), 40);
      if headnum = 0 then
      begin
        DrawHeadPic(RRole[0].HeadNum, hx, hy + 68);
      end
      else
      begin
        DrawHeadPic(headnum, hx, hy + 68);
      end;
    end;
    if namenum <> 0 then
    begin
      DrawRectangle(screen, nx, ny, nw, nh, frame, colcolor($FF), 40);
      namelen := length(np);
      DrawBig5ShadowText(screen, np, nx + 20 - namelen * 9 div 2, ny + 4, colcolor($63), colcolor($70));
    end;

    while r1 < row do
    begin
      pword[0] := (puint16(tp + ch))^;
      if (pword[0] shr 8 <> 0) and (pword[0] shl 8 <> 0) then
      begin
        ch := ch + 2;
        if (pword[0] and $FF) = $5E then //^^改变文字颜色
        begin
          case smallint((pword[0] and $FF00) shr 8) - $30 of
            0: newcolor := 28515;
            1: newcolor := 28421;
            2: newcolor := 28435;
            3: newcolor := 28563;
            4: newcolor := 28466;
            5: newcolor := 28450;
            64: newcolor := color;
          else
            newcolor := color;
          end;
          color1 := newcolor and $FF;
          color2 := (newcolor shr 8) and $FF;
        end
        else if pword[0] = $2323 then //## 延时
        begin
          sdl_delay(500);
        end
        else if pword[0] = $2A2A then //**换行
        begin
          if c1 > 0 then
            Inc(r1);
          c1 := 0;
        end
        else if pword[0] = $4040 then //@@等待击键
        begin
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          k := waitanykey;
          while (k = sdlk_right) or
            (k = sdlk_left) or
            (k = sdlk_up) or
            (k = sdlk_down) do
          begin
            k := waitanykey;
          end;
        end
        else if (pword[0] = $2626) or (pword[0] = $2525) or (pword[0] = $2424) then
        begin
          case pword[0] of
            $2626: np3 := ap; //&&显示姓名
            $2525: np3 := np2; //%%显示名
            $2424: np3 := np1; //$$显示姓
          end;
          i := 0;
          while (puint16(np3 + i)^ shr 8 <> 0) and (puint16(np3 + i)^ shl 8 <> 0) do
          begin
            pword[0] := puint16(np3 + i)^;
            i := i + 2;
            Drawbig5ShadowText(screen, @pword[0], x - 14 + CHINESE_FONT_SIZE * c1, y + 4 +
              CHINESE_FONT_SIZE * r1, colcolor(color1), colcolor(color2));
            Inc(c1);
            if c1 = cell then
            begin
              c1 := 0;
              Inc(r1);
              if r1 = row then
              begin
                SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
                k := waitanykey;
                while (k = sdlk_right) or
                  (k = sdlk_left) or
                  (k = sdlk_up) or
                  (k = sdlk_down) do
                begin
                  k := waitanykey;
                end;
                c1 := 0;
                r1 := 0;
                redraw;
                DrawRectangle(screen, x, y, w, h, frame, colcolor($FF), 40);
                if (showhead = 0) or (headnum < 0) then
                begin
                  DrawRectangle(screen, hx, hy, hw, hh, frame, colcolor($FF), 40);
                  if headnum = 0 then
                  begin
                    DrawHeadPic(RRole[0].HeadNum, hx, hy + 68);
                  end
                  else
                  begin
                    DrawHeadPic(headnum, hx, hy + 68);
                  end;
                end;
                if namenum <> 0 then
                begin
                  DrawRectangle(screen, nx, ny, nw, nh, frame, colcolor($FF), 40);
                  namelen := length(np);
                  DrawBig5ShadowText(screen, np, nx + 20 - namelen * 9 div 2, ny + 4, colcolor($63), colcolor($70));
                end;
              end;
            end;
          end;
        end
        else //显示文字
        begin
          DrawBig5ShadowText(screen, @pword, x - 14 + CHINESE_FONT_SIZE * c1, y + 4 + CHINESE_FONT_SIZE *
            r1, colcolor(color1), colcolor(color2));
          Inc(c1);
          if c1 = cell then
          begin
            c1 := 0;
            Inc(r1);
          end;
        end;
      end
      else
        break;
    end;
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    k := waitanykey;
    while (k = sdlk_right) or
      (k = sdlk_left) or
      (k = sdlk_up) or
      (k = sdlk_down) do
    begin
      k := waitanykey;
    end;
    if (pword[0] and $FF = 0) or (pword[0] and $FF00 = 0) then
      break;
  end;
  redraw;

  setlength(wd, 0);
  setlength(str, 0);
  setlength(temp2, 0);
end;

end.
