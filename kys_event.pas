unit kys_event;

//{$MODE Delphi}

interface

uses
  SysUtils,
  {$IFDEF fpc}
  LConvEncoding,
  LCLType,
  LCLIntf,
  {$ELSE}
  Windows,
  {$ENDIF}
  SDL3_image,
  SDL3,
  Math,
  StrUtils,
  Classes,
  Dialogs;

//事件系统
//在英文中, instruct通常不作为名词, swimmingfish在他的一份反汇编文件中大量使用
//这个词表示"指令", 所以这里仍保留这种用法
procedure instruct_0;
function ReadTalk(talknum: integer): utf8string;
procedure talk_1(talkstr: utf8string; headnum, dismode: integer);
procedure instruct_1(talknum, headnum, dismode: integer);
procedure instruct_2(inum, amount: integer);
procedure ReArrangeItem(sort: integer = 0);
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
procedure instruct_23(rnum, Poison: integer);
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
procedure instruct_47(rnum, Attack: integer);
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
procedure DivideName(fullname: utf8string; var surname, givenname: utf8string);
function ReplaceStr(const S, Srch, Replace: utf8string): utf8string;
procedure NewTalk(headnum, talknum, namenum, place, showhead, color, frame: integer; content: utf8string = ''; disname: utf8string = '');
function EnterNumber(MinValue, MaxValue, x, y: integer; Default: integer = 0): smallint;
function EnterString(var str: utf8string; x, y, w, h: integer): bool;
procedure SetAttribute(rnum, selecttype, modlevel, minlevel, maxlevel: integer);

implementation

uses
  kys_script,
  kys_engine,
  kys_battle,
  kys_draw,
  kys_main,
  kys_type;

//事件系统
//事件指令含义请参阅其他相关文献
//场景重绘一般来说仅重绘可见部分, 当事件中转移了画面位置需要全重绘
procedure instruct_0;
begin
  if NeedRefreshScene = 1 then
  begin
    InitialScene(1);
    NeedRefreshScene := 0;
  end;
  Redraw;
  //SDL_UpdateRect2(screen,0,0,screen.w,screen.h);
  //EndAmi;
end;

function ReadTalk(talknum: integer): utf8string;
var
  idx, grp, offset, len, i, p, l, headx, heady, diagx, diagy, key: integer;
  talkarray: array of byte;
begin
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
  end;
  Result := CP950toutf8(@talkarray[0]);
end;

procedure talk_1(talkstr: utf8string; headnum, dismode: integer);
var
  idx, grp, offset, len, i, p, l, headx, heady, diagx, diagy, key: integer;
  Name: utf8string;
  Lines, Lines2: array of utf8string;
  color: uint32;
begin
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

  DrawRectangleWithoutFrame(screen, 0, diagy - 10, CENTER_X * 2, 120, 0, 60);

  if headx > 0 then
    DrawHeadPic(headnum, headx, heady);

  talkstr := talkstr + #0;
  len := length(talkstr);
  p := 1;
  i := 1;
  l := 0;
  while i <= len do
  begin
    if (talkstr[i] = #$2A) then
    begin
      setlength(Lines, length(Lines) + 1);
      Lines[length(Lines) - 1] := copy(talkstr, p, i - p);
      p := i + 1;
      l := 0;
      //i := i + 1;
    end
    else
    if byte(talkstr[i]) >= $e0 then
    begin
      l := l + 2;
    end
    else
    begin
      l := l + 1;
    end;
    i := i + utf8follow(talkstr[i]);
    if (l >= 48) then
    begin
      setlength(Lines, length(Lines) + 1);
      Lines[length(Lines) - 1] := copy(talkstr, p, i - p);
      p := i;
      l := 0;
    end;
  end;
  if (l >= 0) then
  begin
    setlength(Lines, length(Lines) + 1);
    Lines[length(Lines) - 1] := copy(talkstr, p, len - p);
  end;
  //这里过于复杂，干脆在最后去掉空行
  for i := 0 to length(Lines) - 1 do
  begin
    if length(Lines[i]) > 0 then
    begin
      setlength(Lines2, length(Lines2) + 1);
      Lines2[length(Lines2) - 1] := Lines[i];
    end;
  end;
  Lines := lines2;
  //talkstr[len-1] := #$20;
  p := 1;
  l := 0;
  for i := 0 to length(Lines) - 1 do
  begin
    DrawShadowText(screen, Lines[i], diagx + 20, diagy + l * 22, ColColor($FF), ColColor($0));
    p := i + 1;
    l := l + 1;
    if (l >= 4) and (i < length(Lines) - 1) then
    begin
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      repeat
        key := WaitAnyKey;
      until (key <> SDLK_LEFT) and (key <> SDLK_RIGHT) and (key <> SDLK_UP) and (key <> SDLK_DOWN);
      Redraw;
      DrawRectangleWithoutFrame(screen, 0, diagy - 10, CENTER_X * 2, 120, 0, 60);
      if headx > 0 then
        DrawHeadPic(headnum, headx, heady);
      l := 0;
    end;
  end;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  repeat
    key := WaitAnyKey;
  until (key <> SDLK_LEFT) and (key <> SDLK_RIGHT) and (key <> SDLK_UP) and (key <> SDLK_DOWN);
  Redraw;

end;

procedure instruct_1(talknum, headnum, dismode: integer);
var
  talkstr, Name: utf8string;
  color: uint32;
begin
  talkstr := ReadTalk(talknum);
  talk_1(talkstr, headnum, dismode);
end;

//得到物品可显示数量, 数量为负显示失去物品
procedure instruct_2(inum, amount: integer);
var
  x: integer;
  word: utf8string;
begin
  instruct_32(inum, amount);
  x := CENTER_X;
  if where = 2 then
    x := 190;

  DrawRectangle(screen, x - 85, 98, 170, 76, 0, ColColor(255), 50);
  //DrawMPic(ITEM_BEGIN_PIC + inum, x - 20, 100);
  if amount >= 0 then
    word := '得到物品'
  else
    word := '失去物品';
  DrawShadowText(screen, word, x - 80, 100, ColColor($21), ColColor($23));
  DrawBig5ShadowText(screen, @Ritem[inum].Name, x - 80, 125, ColColor($5), ColColor($7));
  word := '數量';
  DrawShadowText(screen, word, x - 80, 150, ColColor($64), ColColor($66));
  word := format(' %5d', [amount]);
  DrawEngShadowText(screen, word, x - 0, 150, ColColor($64), ColColor($66));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  WaitAnyKey;
  Redraw;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

end;

//重排物品，清除为0的物品
//合并同类物品（空间换时间）
procedure ReArrangeItem(sort: integer = 0);
var
  i, j, p: integer;
  item, amount: array of integer;
begin
  p := 0;
  setlength(item, MAX_ITEM_AMOUNT);
  setlength(amount, high(Ritem) + 1);
  fillchar(amount[0], sizeof(amount[0]) * length(amount), 0);
  for i := 0 to MAX_ITEM_AMOUNT - 1 do
  begin
    if (RItemList[i].Number >= 0) and (RItemList[i].Amount > 0) then
    begin
      if amount[RItemList[i].Number] = 0 then
      begin
        item[p] := RItemList[i].Number;
        amount[RItemList[i].Number] := RItemList[i].Amount;
        p := p + 1;
      end
      else
        amount[RItemList[i].Number] := amount[RItemList[i].Number] + RItemList[i].Amount;
    end;
  end;

  if sort = 0 then
  begin
    for i := 0 to MAX_ITEM_AMOUNT - 1 do
    begin
      if i < p then
      begin
        RItemList[i].Number := item[i];
        RItemList[i].Amount := amount[item[i]];
      end
      else
      begin
        RItemList[i].Number := -1;
        RItemList[i].Amount := 0;
      end;
    end;
  end
  else
  begin
    for i := 0 to MAX_ITEM_AMOUNT - 1 do
    begin
      RItemList[i].Number := -1;
      RItemList[i].Amount := 0;
    end;
    j := 0;
    for i := 0 to length(amount) - 1 do
    begin
      if amount[i] > 0 then
      begin
        RItemList[j].Number := i;
        RItemList[j].Amount := amount[i];
        j := j + 1;
      end;
    end;
  end;
end;

//改变事件, 如在当前场景需重置场景
//在需改变贴图较多时效率较低
procedure instruct_3(list: array of integer);
var
  i, i1, i2, {curPic,} preEventPic: integer;
  ModifyS: boolean;
begin
  //curPic := DData[CurScene, CurEvent, 5];
  if list[0] = -2 then
    list[0] := CurScene;
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
  if ((MODVersion = 12) or (MODVersion = 31)) and (list[0] <> CurScene) then
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
  //if list[0] = CurScene then
  Sdata[list[0], 3, Ddata[list[0], list[1], 10], Ddata[list[0], list[1], 9]] := list[1];

  {if DData[CurScene, CurEvent, 5] <> curPic then
    begin
    InitialScene(1);
    Redraw;
    //SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    end;}
  if (list[0] = CurScene) and (preEventPic <> DData[list[0], list[1], 5]) then
  begin
    NeedRefreshScene := 1;
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
  menuString: array [0 .. 2] of utf8string;
begin
  //setlength(menustring, 3);
  menuString[0] := '取消';
  menuString[1] := '戰鬥';
  menuString[2] := '是否與之戰鬥？';
  DrawTextWithRect(screen, menuString[2], CENTER_X - 75, CENTER_Y - 85, 150, ColColor(5), ColColor(7));
  menu := CommonMenu2(CENTER_X - 49, CENTER_Y - 50, 98, menuString);
  if menu = 1 then
    Result := jump1
  else
    Result := jump2;
  Redraw;
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
  exitscenemusicnum := musicnum;
end;

//询问是否加入
function instruct_9(jump1, jump2: integer): integer;
var
  menu: integer;
  menuString: array [0 .. 2] of utf8string;
begin
  //setlength(menustring, 3);
  menuString[0] := '取消';
  menuString[1] := '要求';
  menuString[2] := '是否要求加入？';
  DrawTextWithRect(screen, menuString[2], CENTER_X - 75, CENTER_Y - 85, 150, ColColor(5), ColColor(7));
  menu := CommonMenu2(CENTER_X - 49, CENTER_Y - 50, 98, menuString);
  if menu = 1 then
    Result := jump1
  else
    Result := jump2;
  Redraw;
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
  menuString: array [0 .. 2] of utf8string;
begin
  //setlength(menustring, 3);
  menuString[0] := ' 否';
  menuString[1] := ' 是';
  menuString[2] := '是否需要住宿？';
  if MODVersion <> 0 then
    menuString[2] := '请選擇是或者否';
  DrawTextWithRect(screen, menuString[2], CENTER_X - 75, CENTER_Y - 85, 150, ColColor(5), ColColor(7));
  menu := CommonMenu2(CENTER_X - 49, CENTER_Y - 50, 98, menuString);
  if menu = 1 then
    Result := jump1
  else
    Result := jump2;
  Redraw;
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
      if not ((Rrole[rnum].Hurt > 33) or (Rrole[rnum].Poison > 0)) then
      begin
        Rrole[rnum].CurrentHP := Rrole[rnum].MaxHP;
        Rrole[rnum].CurrentMP := Rrole[rnum].MaxMP;
        Rrole[rnum].PhyPower := MAX_PHYSICAL_POWER;
        Rrole[rnum].Hurt := Rrole[rnum].Hurt - 33;
        if (Rrole[rnum].Hurt < 0) then
          Rrole[rnum].Hurt := 0;
        Rrole[rnum].Poison := Rrole[rnum].Poison - 33;
        if (Rrole[rnum].Poison < 0) then
          Rrole[rnum].Poison := 0;
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
  //DData[CurScene, [i1,i2]:=Ddata[CurScene,i1,i2];
  InitialScene(0);
  NeedRefreshScene := 0;
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
  str: utf8string;
begin
  where := 4;
  Redraw;
  str := ' 勝敗乃兵家常事，但是……';
  DrawShadowText(screen, str, CENTER_X - 120, 340, ColColor(255), ColColor(255));
  str := ' 地球上又多了一失蹤人口';
  DrawShadowText(screen, str, CENTER_X - 110, 370, ColColor(255), ColColor(255));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  WaitAnyKey;
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
    list[0] := CurScene;
  sdata[list[0], list[1], list[3], list[2]] := list[4];
  if list[0] = CurScene then
    NeedRefreshScene := 1;

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
  InitialScene(0);
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
  newlist: array [0 .. 5] of integer;
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
      Rrole[Teamlist[i]].CurrentMP := 0;
end;

procedure instruct_23(rnum, Poison: integer);
begin
  Rrole[rnum].UsePoi := Poison;
end;

//Black the screen when fail in battle.
//Note: never be used, leave it as blank.
procedure instruct_24;
begin
end;

//Note: never display the leading role.
//This will be improved when I have a better method.
//场景移动
procedure instruct_25(x1, y1, x2, y2: integer);
var
  i, s: integer;
begin
  if NeedRefreshScene = 1 then
  begin
    InitialScene(0);
    NeedRefreshScene := 0;
  end;
  s := sign(x2 - x1);
  i := x1 + s;
  if s <> 0 then
    while (SDL_PollEvent(@event) or True) do
    begin
      CheckBasicEvent;
      SDL_Delay(50);
      DrawSceneWithoutRole(y1, i);
      //showmessage(inttostr(i));
      DrawRoleOnScene(y1, i);
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      i := i + s;
      //showmessage(inttostr(s*(x2-i)));
      if (s * (x2 - i) < 0) then
        break;
    end;
  s := sign(y2 - y1);
  i := y1 + s;
  if s <> 0 then
    while (SDL_PollEvent(@event) or True) do
    begin
      CheckBasicEvent;
      SDL_Delay(50);
      DrawSceneWithoutRole(i, x2);
      //showmessage(inttostr(i));
      DrawRoleOnScene(i, x2);
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
    snum := CurScene;
  ddata[snum, enum, 2] := ddata[snum, enum, 2] + add1;
  ddata[snum, enum, 3] := ddata[snum, enum, 3] + add2;
  ddata[snum, enum, 4] := ddata[snum, enum, 4] + add3;
  if snum = CurScene then
  begin
    InitialScene(0);
    NeedRefreshScene := 0;
  end;
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
    while SDL_PollEvent(@event) or True do
    begin
      CheckBasicEvent;
      CurSceneRolePic := i div 2;
      SDL_Delay(20);
      //DData[CurScene, CurEvent, 5] := -1;
      DrawScene;
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      i := i + 1;
      if i > endpic then
        break;
    end;
  end
  else
  begin
    i := beginpic;
    while SDL_PollEvent(@event) or True do
    begin
      CheckBasicEvent;
      DData[CurScene, enum, 5] := i;
      DData[CurScene, enum, 6] := i;
      DData[CurScene, enum, 7] := i;
      //UpdateScene(DData[CurScene, enum, 10], DData[CurScene, enum, 9]);
      InitialScene(1);
      SDL_Delay(20);
      DrawScene;
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      i := i + 1;
      if i > endpic then
        break;
    end;
    //DData[CurScene, enum, 5] := DData[CurScene, enum, 7];
    //InitialScene(1);
  end;

end;

function instruct_28(rnum, e1, e2, jump1, jump2: integer): integer;
begin
  Result := jump2;
  if (Rrole[rnum].Ethics >= e1) and (Rrole[rnum].Ethics <= e2) then
    Result := jump1;
end;

function instruct_29(rnum, r1, r2, jump1, jump2: integer): integer;
begin
  Result := jump2;
  if (Rrole[rnum].Attack >= r1) and (Rrole[rnum].Attack <= r2) then
    Result := jump1;
  if MODVersion = 41 then
    if (Rrole[rnum].Attack >= r1) then
      Result := jump1;
end;

//主角走动
procedure instruct_30(x1, y1, x2, y2: integer);
var
  s: integer;
begin
  if NeedRefreshScene = 1 then
  begin
    InitialScene(0);
    NeedRefreshScene := 0;
  end;
  s := sign(x2 - x1);
  Sy := x1 + s;
  if s > 0 then
    Sface := 1;
  if s < 0 then
    Sface := 2;
  if s <> 0 then
    while SDL_PollEvent(@event) or True do
    begin
      CheckBasicEvent;
      SDL_Delay(50);
      DrawSceneWithoutRole(Sx, Sy);
      SStep := SStep + 1;
      if SStep >= 7 then
        SStep := 1;
      CurSceneRolePic := BEGIN_WALKPIC + SFace * 7 + SStep;
      DrawRoleOnScene(Sx, Sy);
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
    while SDL_PollEvent(@event) or True do
    begin
      CheckBasicEvent;
      SDL_Delay(50);
      DrawSceneWithoutRole(Sx, Sy);
      SStep := SStep + 1;
      if SStep >= 7 then
        SStep := 1;
      CurSceneRolePic := BEGIN_WALKPIC + SFace * 7 + SStep;
      DrawRoleOnScene(Sx, Sy);
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
  CurSceneRolePic := 2501 + SFace * 7 + SStep;
  DrawSceneWithoutRole(Sx, Sy);
  DrawRoleOnScene(Sx, Sy);
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
  if Amount <> 0 then
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
end;

//学到武功, 如果已有武功则升级, 如果已满10个不会洗武功
procedure instruct_33(rnum, magicnum, dismode: integer);
var
  i: integer;
  word: utf8string;
begin
  for i := 0 to 9 do
  begin
    if (Rrole[rnum].Magic[i] <= 0) or (Rrole[rnum].Magic[i] = magicnum) then
    begin
      if Rrole[rnum].Magic[i] > 0 then
        Rrole[rnum].Maglevel[i] := Rrole[rnum].Maglevel[i] + 100;
      Rrole[rnum].Magic[i] := magicnum;
      if Rrole[rnum].MagLevel[i] > 999 then
        Rrole[rnum].Maglevel[i] := 999;
      break;
    end;
  end;
  //if i = 10 then rrole[rnum].data[i+63] := magicnum;
  if dismode = 0 then
  begin
    DrawRectangle(screen, CENTER_X - 75, 98, 145, 76, 0, ColColor(255), 50);
    word := '學會';
    DrawShadowText(screen, word, CENTER_X - 70, 125, ColColor($5), ColColor($7));
    DrawBig5ShadowText(screen, @Rrole[rnum].Name, CENTER_X - 70, 100, ColColor($21), ColColor($23));
    DrawBig5ShadowText(screen, @Rmagic[magicnum].Name, CENTER_X - 70, 150, ColColor($64), ColColor($66));
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    WaitAnyKey;
    Redraw;
  end;
end;

procedure instruct_34(rnum, iq: integer);
var
  word: utf8string;
begin
  if Rrole[rnum].Aptitude + iq <= 100 then
  begin
    Rrole[rnum].Aptitude := Rrole[rnum].Aptitude + iq;
  end
  else
  begin
    iq := 100 - Rrole[rnum].Aptitude;
    Rrole[rnum].Aptitude := 100;
  end;
  if iq > 0 then
  begin
    DrawRectangle(screen, CENTER_X - 75, 98, 145, 51, 0, ColColor(255), 50);
    word := '資質增加';
    DrawShadowText(screen, word, CENTER_X - 70, 125, ColColor($5), ColColor($7));
    DrawBig5ShadowText(screen, @Rrole[rnum].Name, CENTER_X - 70, 100, ColColor($21), ColColor($23));
    word := format('%3d', [iq]);
    DrawEngShadowText(screen, word, CENTER_X + 30, 125, ColColor($64), ColColor($66));
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    WaitAnyKey;
    Redraw;
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
      if Rrole[rnum].Magic[i] <= 0 then
      begin
        Rrole[rnum].Magic[i] := magicnum;
        Rrole[rnum].MagLevel[i] := exp;
        break;
      end;
    end;
    if i = 10 then
    begin
      Rrole[rnum].Magic[0] := magicnum;
      Rrole[rnum].MagLevel[i] := exp;
    end;
  end
  else
  begin
    Rrole[rnum].Magic[magiclistnum] := magicnum;
    Rrole[rnum].MagLevel[magiclistnum] := exp;
  end;
end;

function instruct_36(sexual, jump1, jump2: integer): integer;
begin
  Result := jump2;
  if Rrole[0].Sexual = sexual then
    Result := jump1;
  if sexual > 255 then
    if x50[$7000] = 0 then
      Result := jump1
    else
      Result := jump2;
end;

procedure instruct_37(Ethics: integer);
begin
  Rrole[0].Ethics := Rrole[0].Ethics + ethics;
  if Rrole[0].Ethics > 100 then
    Rrole[0].Ethics := 100;
  if Rrole[0].Ethics < 0 then
    Rrole[0].Ethics := 0;
end;

procedure instruct_38(snum, layernum, oldpic, newpic: integer);
var
  i1, i2: integer;
begin
  if snum = -2 then
    snum := CurScene;
  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      if Sdata[snum, layernum, i1, i2] = oldpic then
        Sdata[snum, layernum, i1, i2] := newpic;
    end;
  if snum = CurScene then
  begin
    InitialScene(0);
    NeedRefreshScene := 0;
  end;
end;

procedure instruct_39(snum: integer);
begin
  Rscene[snum].EnCondition := 0;
end;

procedure instruct_40(director: integer);
begin
  Sface := director;
  CurSceneRolePic := 2500 + SFace * 7 + 1;
  DrawScene;
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
  if enum1 = -1 then enum1 := curevent;
  SData[CurScene, 3, DData[CurScene, enum1, 10], DData[CurScene, enum1, 9]] := enum1;
  if enum2 = -1 then enum2 := curevent;
  SData[CurScene, 3, DData[CurScene, enum2, 10], DData[CurScene, enum2, 9]] := enum2;
  i := 0;
  while SDL_PollEvent(@event) or True do
  begin
    CheckBasicEvent;
    DData[CurScene, enum1, 5] := beginpic1 + i;
    DData[CurScene, enum2, 5] := beginpic2 + i;
    //UpdateScene(DData[CurScene, enum1, 10], DData[CurScene, enum1, 9]);
    //UpdateScene(DData[CurScene, enum2, 10], DData[CurScene, enum2, 9]);
    InitialScene(1);
    SDL_Delay(20);
    //DrawSceneWithoutRole(Sx, Sy);
    DrawScene;
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    i := i + 1;
    if i > endpic1 - beginpic1 then
      break;
  end;
  //SData[CurScene, 3, DData[CurScene, [enum,10],DData[CurScene, [enum,9]]:=-1;
end;

procedure instruct_44e(enum1, beginpic1, endpic1, enum2, beginpic2, enum3, beginpic3: integer);
var
  i: integer;
begin
  SData[CurScene, 3, DData[CurScene, enum1, 10], DData[CurScene, enum1, 9]] := enum1;
  SData[CurScene, 3, DData[CurScene, enum2, 10], DData[CurScene, enum2, 9]] := enum2;
  SData[CurScene, 3, DData[CurScene, enum3, 10], DData[CurScene, enum3, 9]] := enum3;
  i := 0;
  while SDL_PollEvent(@event) or True do
  begin
    CheckBasicEvent;
    DData[CurScene, enum1, 5] := beginpic1 + i;
    DData[CurScene, enum2, 5] := beginpic2 + i;
    DData[CurScene, enum3, 5] := beginpic3 + i;
    //UpdateScene(DData[CurScene, enum1, 10], DData[CurScene, enum1, 9]);
    //UpdateScene(DData[CurScene, enum2, 10], DData[CurScene, enum2, 9]);
    InitialScene(1);
    SDL_Delay(20);
    //writeln(1);
    //DrawSceneWithoutRole(Sx, Sy);
    DrawScene;
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    i := i + 1;
    if i > endpic1 - beginpic1 then
      break;
  end;
  //SData[CurScene, 3, DData[CurScene, [enum,10],DData[CurScene, [enum,9]]:=-1;
end;

procedure instruct_45(rnum, speed: integer);
var
  word: utf8string;
begin
  Rrole[rnum].Speed := Rrole[rnum].Speed + speed;
  DrawRectangle(screen, CENTER_X - 75, 98, 145, 51, 0, ColColor(255), 50);
  word := '輕功增加';
  DrawShadowText(screen, word, CENTER_X - 70, 125, ColColor($5), ColColor($7));
  DrawBig5ShadowText(screen, @Rrole[rnum].Name, CENTER_X - 70, 100, ColColor($21), ColColor($23));
  word := format('%4d', [speed]);
  DrawEngShadowText(screen, word, CENTER_X + 20, 125, ColColor($64), ColColor($66));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  WaitAnyKey;
  Redraw;
end;

procedure instruct_46(rnum, mp: integer);
var
  word: utf8string;
begin
  Rrole[rnum].MaxMP := Rrole[rnum].MaxMP + mp;
  Rrole[rnum].CurrentMP := Rrole[rnum].MaxMP;
  DrawRectangle(screen, CENTER_X - 75, 98, 145, 51, 0, ColColor(255), 50);
  word := '內力增加';
  DrawShadowText(screen, word, CENTER_X - 70, 125, ColColor($5), ColColor($7));
  DrawBig5ShadowText(screen, @Rrole[rnum].Name, CENTER_X - 70, 100, ColColor($21), ColColor($23));
  word := format('%4d', [mp]);
  DrawEngShadowText(screen, word, CENTER_X + 20, 125, ColColor($64), ColColor($66));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  WaitAnyKey;
  Redraw;
end;

procedure instruct_47(rnum, Attack: integer);
var
  word: utf8string;
begin
  Rrole[rnum].Attack := Rrole[rnum].Attack + Attack;
  DrawRectangle(screen, CENTER_X - 75, 98, 145, 51, 0, ColColor(255), 50);
  word := '武力增加';
  DrawShadowText(screen, word, CENTER_X - 70, 125, ColColor($5), ColColor($7));
  DrawBig5ShadowText(screen, @Rrole[rnum].Name, CENTER_X - 70, 100, ColColor($21), ColColor($23));
  word := format('%4d', [Attack]);
  DrawEngShadowText(screen, word, CENTER_X + 20, 125, ColColor($64), ColColor($66));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  WaitAnyKey;
  Redraw;
end;

procedure instruct_48(rnum, hp: integer);
var
  word: utf8string;
begin
  Rrole[rnum].MaxHP := Rrole[rnum].MaxHP + hp;
  Rrole[rnum].CurrentHP := Rrole[rnum].MaxHP;
  DrawRectangle(screen, CENTER_X - 75, 98, 145, 51, 0, ColColor(255), 50);
  word := '生命增加';
  DrawShadowText(screen, word, CENTER_X - 70, 125, ColColor($5), ColColor($7));
  DrawBig5ShadowText(screen, @Rrole[rnum].Name, CENTER_X - 70, 100, ColColor($21), ColColor($23));
  word := format('%4d', [hp]);
  DrawEngShadowText(screen, word[1], CENTER_X + 20, 125, ColColor($64), ColColor($66));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  WaitAnyKey;
  Redraw;
end;

procedure instruct_49(rnum, MPpro: integer);
begin
  Rrole[rnum].MPType := MPpro;
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
  word: utf8string;
begin
  DrawRectangle(screen, CENTER_X - 110, 98, 220, 26, 0, ColColor(255), 50);
  word := '你的品德指數為：';
  DrawShadowText(screen, word, CENTER_X - 105, 100, ColColor($5), ColColor($7));
  word := format('%3d', [Rrole[0].Ethics]);
  DrawEngShadowText(screen, word, CENTER_X + 65, 100, ColColor($64), ColColor($66));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  WaitAnyKey;
  Redraw;
end;

procedure instruct_53;
var
  word: utf8string;
begin
  DrawRectangle(screen, CENTER_X - 110, 98, 220, 26, 0, ColColor(255), 50);
  word := '你的聲望指數為：';
  DrawShadowText(screen, word, CENTER_X - 105, 100, ColColor($5), ColColor($7));
  word := format('%3d', [Rrole[0].Repute]);
  DrawEngShadowText(screen, word, CENTER_X + 65, 100, ColColor($64), ColColor($66));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  WaitAnyKey;
  Redraw;
end;

//Open all scenes.
//Note: in primary game, some scenes are set to different entrancing condition.
procedure instruct_54;
var
  i: integer;
begin
  for i := 0 to 100 do
  begin
    Rscene[i].EnCondition := 0;
  end;
  Rscene[2].EnCondition := 2;
  Rscene[38].EnCondition := 2;
  Rscene[75].EnCondition := 1;
  Rscene[80].EnCondition := 1;
end;

//Judge the event number.
function instruct_55(enum, Value, jump1, jump2: integer): integer;
begin
  Result := jump2;
  if DData[CurScene, enum, 2] = Value then
    Result := jump1;
end;

//Add repute.
//声望刚刚超过200时家里出现请帖
procedure instruct_56(Repute: integer);
begin
  Rrole[0].Repute := Rrole[0].Repute + repute;
  if (Rrole[0].Repute > 200) and (Rrole[0].Repute - repute <= 200) then
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
    DData[CurScene, [enum1,5]:=beginpic1+i;
    DData[CurScene, [enum2,5]:=beginpic2+i;
    UpdateScene(DData[CurScene, [enum1,10],DData[CurScene, [enum1,9]);
    UpdateScene(DData[CurScene, [enum2,10],DData[CurScene, [enum2,9]);
    sdl_delay(20);
    DrawSceneByCenter(Sx,Sy);
    DrawScene;
    SDL_UpdateRect2(screen,0,0,screen.w,screen.h);
    end;}
  instruct_27(-1, 3832 * 2, 3844 * 2);
  instruct_44e(2, 3845 * 2, 3873 * 2, 3, 3874 * 2, 4, 3903 * 2);
end;

procedure instruct_58;
var
  i, p: integer;
const
  headarray: array [0 .. 29] of integer = (8, 21, 23, 31, 32, 43, 7, 11, 14, 20, 33, 34, 10, 12, 19, 22, 56, 68, 13, 55, 62, 67, 70, 71, 26, 57, 60, 64, 3, 69);
begin
  for i := 0 to 14 do
  begin
    p := random(2);
    instruct_1(2854 + i * 2 + p, headarray[i * 2 + p], random(2) * 4 + random(2));
    if not (Battle(102 + i * 2 + p, 0)) then
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
    snum := CurScene;
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
    if Ddata[CurScene, i, 5] <> 4664 then
    begin
      Result := jump2;
    end;
  end;
end;

procedure instruct_62(enum1, beginpic1, endpic1, enum2, beginpic2, endpic2: integer);
var
  i: integer;
  str: utf8string;
begin
  CurSceneRolePic := -1;
  instruct_44(enum1, beginpic1, endpic1, enum2, beginpic2, endpic2);
  where := 3;
  Redraw;
  EndAmi;
  //display_img('end.png', 0, 0);
  //where := 3;
end;

procedure EndAmi;
var
  x, y, i, len: integer;
  str: utf8string;
  p: integer;
  tempscr: PSDL_Surface;
  dest: TSDL_Rect;
begin
  instruct_14;
  Redraw;
  i := FileOpen(AppPath + 'list/end.txt', fmOpenRead);
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
      DrawShadowText(screen, str[p], x, y, ColColor($FF), ColColor($FF));
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
      DrawRectangleWithoutFrame(screen, 0, 0, CENTER_X * 2, CENTER_Y * 2, 0, 60);
    end;
  end;
  WaitAnyKey;
  instruct_14;

  i := 0;
  tempscr := img_load(putf8char(AppPath + 'resource/end.png'));
  while SDL_PollEvent(@event) or True do
  begin
    CheckBasicEvent;
    if i mod 5 = 0 then
    begin
      dest.x := 0;
      dest.y := i;
      SDL_BlitSurface(tempscr, nil, screen, @dest);
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      SDL_Delay(20);
    end;
    i := i - 1;
    if i < CENTER_Y * 2 - tempscr.h then
      break;
  end;
  SDL_DestroySurface(tempscr);
  WaitAnyKey;

end;

//Set sexual.
procedure instruct_63(rnum, sexual: integer);
begin
  Rrole[rnum].Sexual := sexual;
end;

//韦小宝的商店
procedure instruct_64;
var
  i, amount, shopnum, menu, price: integer;
  list: array [0 .. 4] of integer;
  menuString, menuEngString: array [0 .. 4] of utf8string;
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
      menuString[amount] := cp950toutf8(@Ritem[Rshop[shopnum].Item[i]].Name);
      menuEngString[amount] := format('%10d', [Rshop[shopnum].Price[i]]);
      list[amount] := i;
      amount := amount + 1;
    end;
  end;
  instruct_1($B9E, $6F, 0);
  if amount >= 1 then
  begin
    menu := CommonMenu(CENTER_X - 120, 150, 105 + length(menuEngString[0]) * 10, amount - 1, menuString, menuEngString);
    Redraw;
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
  StopMP3;
  PlayMP3(musicnum, -1);
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
  Result := x;
  if (x >= $8000) or (x < -$8000) then
    Result := (x + $8000) mod $10000 - $8000;
end;

//Expanded 50 instructs.
function instruct_50e(code, e1, e2, e3, e4, e5, e6: integer): integer;
var
  i, t1, grp, idx, offset, len, i1, i2: integer;
  p, p1, p2: putf8char;
  str: utf8string;
  word, word1: utf8string;
  menuString, menuEngString: array of utf8string;
  got: bool;
begin
  Result := 0;
  //message('50e: %d %d %d %d %d %d %d', [code, e1, e2,e3, e4, e5, e6]);
  case code of
    0: //Give a value to a papameter.
    begin
      x50[e1] := e2;
    end;
    1: //Give a value to one member in parameter group.
    begin
      t1 := e3 + e_GetValue(0, e1, e4);
      t1 := CutRegion(t1);
      x50[t1] := e_GetValue(1, e1, e5);
      if e2 = 1 then
        x50[t1] := x50[t1] and $FF;
    end;
    2: //Get the value of one member in parameter group.
    begin
      t1 := e3 + e_GetValue(0, e1, e4);
      t1 := CutRegion(t1);
      x50[e5] := x50[t1];
      if e2 = 1 then
        x50[t1] := x50[t1] and $FF;
    end;
    3: //Basic calculations.
    begin
      t1 := e_GetValue(0, e1, e5);
      case e2 of
        0: x50[e3] := x50[e4] + t1;
        1: x50[e3] := x50[e4] - t1;
        2: x50[e3] := x50[e4] * t1;
        3:
          if t1 <> 0 then
            x50[e3] := x50[e4] div t1;
        4:
          if t1 <> 0 then
            x50[e3] := x50[e4] mod t1;
        5:
          if t1 <> 0 then
            x50[e3] := uint16(x50[e4]) div t1;
      end;
    end;
    4: //Judge the parameter.
    begin
      x50[$7000] := 0;
      t1 := e_GetValue(0, e1, e4);
      case e2 of
        0:
          if not (x50[e3] < t1) then
            x50[$7000] := 1;
        1:
          if not (x50[e3] <= t1) then
            x50[$7000] := 1;
        2:
          if not (x50[e3] = t1) then
            x50[$7000] := 1;
        3:
          if not (x50[e3] <> t1) then
            x50[$7000] := 1;
        4:
          if not (x50[e3] >= t1) then
            x50[$7000] := 1;
        5:
          if not (x50[e3] > t1) then
            x50[$7000] := 1;
        6: x50[$7000] := 0;
        7: x50[$7000] := 1;
      end;
    end;
    5: //Zero all parameters.
    begin
      fillchar(x50[low(x50)], sizeof(x50), 0);
    end;
    8: //Read talk to string.
    begin
      t1 := e_GetValue(0, e1, e2);
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
      p1 := p;
      for i := 0 to len - 2 do //最后一位为0, 不处理
      begin
        p^ := utf8char(byte(p^) xor $FF);
        p := p + 1;
      end;
      p^ := utf8char(0);
      //x50[e3+i]:=0;
    end;
    9: //Format the string.
    begin
      e4 := e_GetValue(0, e1, e4);
      p := @x50[e2];
      p1 := @x50[e3];
      str := utf8string(p1);
      str := format(str, [e4]);
      p2 := @str[1];
      for i := 0 to length(str) do
      begin
        p^ := str[i + 1];
        p := p + 1;
      end;
    end;
    10: //Get the length of a string.
    begin
      x50[e2] := length(putf8char(@x50[e1]));
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
      e3 := e_GetValue(0, e1, e3);
      p := @x50[e2];
      for i := 0 to e3 div 2 do
      begin
        p^ := ' ';
        p := p + 1;
      end;
      p^ := utf8char(0);
    end;
    16: //Write R data.
    begin
      e3 := e_GetValue(0, e1, e3);
      e4 := e_GetValue(1, e1, e4);
      e5 := e_GetValue(2, e1, e5);
      if e3 >= 0 then
      begin
        case e2 of
          0: Rrole[e3].Data[e4 div 2] := e5;
          1: Ritem[e3].Data[e4 div 2] := e5;
          2: Rscene[e3].Data[e4 div 2] := e5;
          3: Rmagic[e3].Data[e4 div 2] := e5;
          4: Rshop[e3].Data[e4 div 2] := e5;
        end;
      end;
    end;
    17: //Read R data.
    begin
      e3 := e_GetValue(0, e1, e3);
      e4 := e_GetValue(1, e1, e4);
      if e3 >= 0 then
      begin
        case e2 of
          0: x50[e5] := Rrole[e3].Data[e4 div 2];
          1: x50[e5] := Ritem[e3].Data[e4 div 2];
          2: x50[e5] := Rscene[e3].Data[e4 div 2];
          3: x50[e5] := Rmagic[e3].Data[e4 div 2];
          4: x50[e5] := Rshop[e3].Data[e4 div 2];
        end;
      end;
    end;
    18: //Write team data.
    begin
      e2 := e_GetValue(0, e1, e2);
      e3 := e_GetValue(1, e1, e3);
      TeamList[e2] := e3;
      //showmessage(inttostr(e3));
    end;
    19: //Read team data.
    begin
      e2 := e_GetValue(0, e1, e2);
      x50[e3] := TeamList[e2];
    end;
    20: //Get the amount of one item.
    begin
      e2 := e_GetValue(0, e1, e2);
      x50[e3] := 0;
      for i := 0 to MAX_ITEM_AMOUNT - 1 do
        if RItemList[i].Number = e2 then
        begin
          x50[e3] := RItemList[i].Amount;
          break;
        end;
    end;
    21: //Write event in scene.
    begin
      e2 := e_GetValue(0, e1, e2);
      e3 := e_GetValue(1, e1, e3);
      e4 := e_GetValue(2, e1, e4);
      e5 := e_GetValue(3, e1, e5);
      Ddata[e2, e3, e4] := e5;
      //if e2=CurScene then DData[CurScene, [e3,e4]:=e5;
      //InitialScene;
      //Redraw;
      //SDL_UpdateRect2(screen,0,0,screen.w,screen.h);
    end;
    22:
    begin
      e2 := e_GetValue(0, e1, e2);
      e3 := e_GetValue(1, e1, e3);
      e4 := e_GetValue(2, e1, e4);
      x50[e5] := Ddata[e2, e3, e4];
    end;
    23:
    begin
      e2 := e_GetValue(0, e1, e2);
      e3 := e_GetValue(1, e1, e3);
      e4 := e_GetValue(2, e1, e4);
      e5 := e_GetValue(3, e1, e5);
      e6 := e_GetValue(4, e1, e6);
      Sdata[e2, e3, e5, e4] := e6;
      //if e2=CurScene then SData[CurScene, 3, e5,e4]:=e6;;
      //InitialScene;
      //Redraw;
      //SDL_UpdateRect2(screen,0,0,screen.w,screen.h);
    end;
    24:
    begin
      e2 := e_GetValue(0, e1, e2);
      e3 := e_GetValue(1, e1, e3);
      e4 := e_GetValue(2, e1, e4);
      e5 := e_GetValue(3, e1, e5);
      x50[e6] := Sdata[e2, e3, e5, e4];
      //showmessage(inttostr(sface));
    end;
    25:
    begin
      e5 := e_GetValue(0, e1, e5);
      e6 := e_GetValue(1, e1, e6);
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
          PWord(@Acol[e6])^ := e5;
          PWord(@Acol1[e6])^ := e5;
          PWord(@Acol2[e6])^ := e5;
          //Acol2[e6] := e5 mod 256;
          //Acol2[e6 + 1] := e5 div 256;
        end;
        $01D295E:
        begin
          CurScene := e5;
        end;
      end;
      //redraw;
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    end;
    26:
    begin
      e6 := e_GetValue(0, e1, e6);
      t1 := uint16(e3) + uint16(e4) * $10000 + uint(e6);
      i := uint16(e3) + uint16(e4) * $10000;
      case t1 of
        $1D295E: x50[e5] := CurScene;
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
        $1C0B90: x50[e5] := SDL_GetTicks div 55 mod 65536;
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
      e3 := e_GetValue(0, e1, e3);
      p := @x50[e4];
      if e3 >= 0 then
      begin
        case e2 of
          0: p1 := @Rrole[e3].Name;
          1: p1 := @Ritem[e3].Name;
          2: p1 := @Rscene[e3].Name;
          3: p1 := @Rmagic[e3].Name;
        end;
        len := min(10, length(p1));
        for i := 0 to len - 1 do
        begin
          p^ := (p1 + i)^;
          Inc(p);
        end;
      end;
      if len mod 2 = 1 then
      begin
        p^ := char($20);
        Inc(p);
      end;
      p^ := char(0);
      //(p + len + 2)^ := char(0);
    end;
    28: //Get the battle number.
    begin
      x50[e1] := x50[28005];
    end;
    29: //Select aim.
    begin
      e2 := e_GetValue(0, e1, e2);
      e3 := e_GetValue(1, e1, e3);
      if e5 = 0 then
      begin
        //showmessage('IN CASE');
        SelectAim(e2, e3);
      end;
      x50[e4] := bfield[2, Ax, Ay];
    end;
    30: //Read battle properties.
    begin
      e2 := e_GetValue(0, e1, e2);
      e3 := e_GetValue(1, e1, e3);
      x50[e4] := Brole[e2].Data[e3 div 2];
    end;
    31: //Write battle properties.
    begin
      e2 := e_GetValue(0, e1, e2);
      e3 := e_GetValue(1, e1, e3);
      e4 := e_GetValue(2, e1, e4);
      Brole[e2].Data[e3 div 2] := e4;
    end;
    32: //Modify next instruct.
    begin
      e3 := e_GetValue(0, e1, e3);
      Result := 655360 * (e3 + 1) + x50[e2];
      p5032pos := e3;
      p5032value := x50[e2];
      //showmessage(inttostr(result));
    end;
    33: //Draw a string.
    begin
      e3 := e_GetValue(0, e1, e3);
      e4 := e_GetValue(1, e1, e4);
      e5 := e_GetValue(2, e1, e5);
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
          DrawBig5ShadowText(screen, p1, e3 - 2, e4 + 22 * i - 3, ColColor(e5 and $FF), ColColor((e5 and $FF00) shl 8));
          i := i + 1;
          p1 := p + 1;
        end;
        p := p + 1;
      end;
      DrawBig5ShadowText(screen, p1, e3 - 2, e4 + 22 * i - 3, ColColor(e5 and $FF), ColColor((e5 and $FF00) shl 8));
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      //waitanykey;
    end;
    34: //Draw a rectangle as background.
    begin
      e2 := e_GetValue(0, e1, e2);
      e3 := e_GetValue(1, e1, e3);
      e4 := e_GetValue(2, e1, e4);
      e5 := e_GetValue(3, e1, e5);
      DrawRectangle(screen, e2, e3, e4, e5, 0, ColColor($FF), 50);
      //SDL_UpdateRect2(screen,e1,e2,e3+1,e4+1);
    end;
    35: //Pause and wait a key.
    begin
      i := WaitAnyKey;
      x50[e1] := i;
      case i of
        SDLK_LEFT: x50[e1] := 154;
        SDLK_RIGHT: x50[e1] := 156;
        SDLK_UP: x50[e1] := 158;
        SDLK_DOWN: x50[e1] := 152;
      end;
    end;
    36: //Draw a string with background then pause, if the key pressed is 'Y' then jump=0.
    begin
      e3 := e_GetValue(0, e1, e3);
      e4 := e_GetValue(1, e1, e4);
      e5 := e_GetValue(2, e1, e5);
      //word := cp950toutf8(@x50[e2]);
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
      DrawRectangle(screen, e3, e4, i2 * 10 + 25, i1 * 22 + 5, 0, ColColor(255), 50);
      p := @x50[e2];
      p1 := p;
      i := 0;
      while byte(p^) > 0 do
      begin
        if byte(p^) = $2A then
        begin
          p^ := char(0);
          DrawBig5ShadowText(screen, p1, e3 + 3, e4 + 22 * i + 2, ColColor(e5 and $FF), ColColor((e5 and $FF00) shl 8));
          i := i + 1;
          p1 := p + 1;
        end;
        p := p + 1;
      end;
      DrawBig5ShadowText(screen, p1, e3 + 3, e4 + 22 * i + 2, ColColor(e5 and $FF), ColColor((e5 and $FF00) shl 8));
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      i := WaitAnyKey;
      if i = SDLK_Y then
        x50[$7000] := 0
      else
        x50[$7000] := 1;
      //redraw;
    end;
    37: //Delay.
    begin
      e2 := e_GetValue(0, e1, e2);
      SDL_Delay(e2);
    end;
    38: //Get a number randomly.
    begin
      e2 := e_GetValue(0, e1, e2);
      x50[e3] := random(e2);
    end;
    39: //Show a menu to select.
    begin
      e2 := e_GetValue(0, e1, e2);
      e5 := e_GetValue(1, e1, e5);
      e6 := e_GetValue(2, e1, e6);
      setlength(menuString, e2);
      setlength(menuEngString, 0);
      t1 := 0;
      for i := 0 to e2 - 1 do
      begin
        menuString[i] := cp950toutf8(@x50[x50[e3 + i]]);
        i1 := length(putf8char(@x50[x50[e3 + i]]));
        if i1 > t1 then
          t1 := i1;
      end;
      x50[e4] := CommonMenu(e5, e6, t1 * 10 + 5, e2 - 1, menuString) + 1;
    end;
    40: //Show a scroll menu to select.
    begin
      e2 := e_GetValue(0, e1, e2);
      e5 := e_GetValue(1, e1, e5);
      e6 := e_GetValue(2, e1, e6);
      setlength(menuString, e2);
      setlength(menuEngString, 0);
      i2 := 0;
      for i := 0 to e2 - 1 do
      begin
        menuString[i] := cp950toutf8(@x50[x50[e3 + i]]);
        i1 := length(putf8char(@x50[x50[e3 + i]]));
        if i1 > i2 then
          i2 := i1;
      end;
      t1 := (e1 shr 8) and $FF;
      if t1 = 0 then
        t1 := 5;
      //某些旧MOD中, x可能需要减掉10来对齐(不处理了)
      x50[e4] := CommonScrollMenu(e5, e6, i2 * 10 + 5, e2 - 1, t1, menuString) + 1;
    end;
    41: //Draw a picture.
    begin
      e3 := e_GetValue(0, e1, e3);
      e4 := e_GetValue(1, e1, e4);
      e5 := e_GetValue(2, e1, e5);
      case e2 of
        0:
        begin
          if (where <> 1) or ((ModVersion = 22) and (CurEvent = -1)) then
            DrawMPic(e5 div 2, e3, e4)
          else
            DrawSPic(e5 div 2, e3, e4, 0, 0, screen.w, screen.h);
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
      e2 := e_GetValue(0, e1, e2);
      e3 := e_GetValue(0, e1, e3);
      Mx := e3;
      My := e2;
    end;
    43: //Call another event.
    begin
      //message('50 43 to %d', [e2]);
      e2 := e_GetValue(0, e1, e2);
      e3 := e_GetValue(1, e1, e3);
      e4 := e_GetValue(2, e1, e4);
      e5 := e_GetValue(3, e1, e5);
      e6 := e_GetValue(4, e1, e6);
      x50[$7100] := e3;
      x50[$7101] := e4;
      x50[$7102] := e5;
      x50[$7103] := e6;
      if e2 = 202 then //得到物品
      begin
        if e5 = 0 then
          instruct_2(e3, e4)
        else
          instruct_32(e3, e4);
      end
      else if e2 = 201 then //新对话
        NewTalk(e3, e4, e5, e6 mod 100, (e6 mod 100) div 10, e6 div 100, 0)
      else if (e2 = 176) and (MODVersion = 22) then //菠萝三国输入数字
      begin
        x50[10032] := EnterNumber(0, 32767, CENTER_X, CENTER_Y - 100);
        x50[$7000] := 0;
        Redraw;
      end
      else
        CallEvent(e2);
    end;
    44: //Play amination.
    begin
      e2 := e_GetValue(0, e1, e2);
      e3 := e_GetValue(1, e1, e3);
      e4 := e_GetValue(2, e1, e4);
      PlayActionAmination(e2, e3);
      PlayMagicAmination(e2, e4);
    end;
    45: //Show values.
    begin
      e2 := e_GetValue(0, e1, e2);
      ShowHurtValue(e2);
    end;
    46: //Set effect layer.
    begin
      e2 := e_GetValue(0, e1, e2);
      e3 := e_GetValue(1, e1, e3);
      e4 := e_GetValue(2, e1, e4);
      e5 := e_GetValue(3, e1, e5);
      e6 := e_GetValue(4, e1, e6);
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
      if FULLSCREEN = 0 then
        messagebox(0, @str[1], 'KYS Windows', MB_OK);
    end;
    49: //In PE files, you can't call any procedure as your wish.
    begin
    end;
    50: //Enter name for items, magics and roles.
    begin
      e2 := e_GetValue(0, e1, e2);
      e3 := e_GetValue(1, e1, e3);
      e4 := e_GetValue(2, e1, e4);
      e5 := e_GetValue(3, e1, e5);
      //e2 := 0;
      //e5 := 10;
      case e2 of
        0: p := @Rrole[e3].Name[0];
        1: p := @Ritem[e3].Name[0];
        2: p := @Rmagic[e3].Name[0];
        3: p := @Rscene[e3].Name[0];
      end;
      //ShowMessage(IntToStr(e4));
      word1 := CP950ToUTF8(p);
      word := '請輸入名字：';
      DrawTextWithRect(word, CENTER_X - 133, CENTER_Y - 30, 266, ColColor($21), ColColor($23));
      got := EnterString(word, CENTER_X - 43, CENTER_Y + 10, 86, 20);
      if got then
      begin
        str := UTF8ToCP950(word);
        p1 := @str[1];
        for i := 0 to min(e5, length(p1)) - 1 do
          (p + i)^ := (p1 + i)^;
      end;
    end;
    51: //Enter a number.
    begin
      x50[e1] := EnterNumber(0, 32767, CENTER_X, CENTER_Y - 100);
      ;
    end;
    52: //Judge someone grasp some mggic.
    begin
      e2 := e_GetValue(0, e1, e2);
      e3 := e_GetValue(1, e1, e3);
      e4 := e_GetValue(2, e1, e4);
      x50[$7000] := 1;
      if (HaveMagic(e2, e3, e4) = True) then
        x50[$7000] := 0;
    end;
    60: //Call scripts.
    begin
      e2 := e_GetValue(0, e1, e2);
      e3 := e_GetValue(1, e1, e3);
      ExecScript(putf8char('script/' + IntToStr(e2) + '.lua'), putf8char('f' + IntToStr(e3)));
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
    if (Rrole[person].Magic[i] = mnum) then
      if (Rrole[person].MagLevel[i] >= lv) then
        Result := True;
end;

procedure StudyMagic(rnum, magicnum, newmagicnum, level, dismode: integer);
var
  i: integer;
  word: utf8string;
begin
  for i := 0 to 9 do
  begin
    if (Rrole[rnum].Magic[i] = magicnum) or (Rrole[rnum].Magic[i] = newmagicnum) then
    begin
      if level <> -2 then
        Rrole[rnum].Maglevel[i] := Rrole[rnum].Maglevel[i] + level * 100;
      Rrole[rnum].Magic[i] := newmagicnum;
      if Rrole[rnum].MagLevel[i] > 999 then
        Rrole[rnum].Maglevel[i] := 999;
      break;
    end;
  end;
  //if i = 10 then rrole[rnum].data[i+63] := magicnum;
  if dismode = 0 then
  begin
    DrawRectangle(screen, CENTER_X - 75, 98, 145, 76, 0, ColColor(255), 30);
    word := ' 學會';
    DrawShadowText(screen, word, CENTER_X - 90, 125, ColColor($5), ColColor($7));
    DrawBig5ShadowText(screen, @Rrole[rnum].Name, CENTER_X - 90, 100, ColColor($21), ColColor($23));
    DrawBig5ShadowText(screen, @Rmagic[newmagicnum].Name, CENTER_X - 90, 150, ColColor($64), ColColor($66));
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    WaitAnyKey;
    Redraw;
  end;
end;


procedure DivideName(fullname: utf8string; var surname, givenname: utf8string);
var
  surname2: TStringList;
  len, i, hysur: integer;
begin
  len := drawLength(fullname);
  case len of
    1, 2:
    begin
      surname := '';
      givenname := fullname;
    end;
    3, 4:
    begin
      surname := midstr(fullname, 1, 3);
      givenname := midstr(fullname, 4, 3);
    end;
    5, 6:
    begin
      surname2 := TStringList.Create;
      surname2.Add('歐陽');
      surname2.Add('太史');
      surname2.Add('端木');
      surname2.Add('上官');
      surname2.Add('司馬');
      surname2.Add('東方');
      surname2.Add('獨孤');
      surname2.Add('南宮');
      surname2.Add('萬俟');
      surname2.Add('聞人');
      surname2.Add('夏侯');
      surname2.Add('諸葛');
      surname2.Add('尉遲');
      surname2.Add('公羊');
      surname2.Add('赫連');
      surname2.Add('澹台');
      surname2.Add('皇甫');
      surname2.Add('宗政');
      surname2.Add('濮陽');
      surname2.Add('公冶');
      surname2.Add('太叔');
      surname2.Add('申屠');
      surname2.Add('公孫');
      surname2.Add('慕容');
      surname2.Add('仲孫');
      surname2.Add('鍾離');
      surname2.Add('長孫');
      surname2.Add('宇文');
      surname2.Add('司徒');
      surname2.Add('鮮於');
      surname2.Add('司空');
      surname2.Add('閭丘');
      surname2.Add('子車');
      surname2.Add('亓官');
      surname2.Add('司寇');
      surname2.Add('巫馬');
      surname2.Add('公西');
      surname2.Add('顓孫');
      surname2.Add('壤駟');
      surname2.Add('公良');
      surname2.Add('漆雕');
      surname2.Add('樂正');
      surname2.Add('宰父');
      surname2.Add('穀梁');
      surname2.Add('拓跋');
      surname2.Add('夾穀');
      surname2.Add('軒轅');
      surname2.Add('令狐');
      surname2.Add('段幹');
      surname2.Add('百裏');
      surname2.Add('呼延');
      surname2.Add('東郭');
      surname2.Add('南門');
      surname2.Add('羊舌');
      surname2.Add('微生');
      surname2.Add('公戶');
      surname2.Add('公玉');
      surname2.Add('公儀');
      surname2.Add('梁丘');
      surname2.Add('公仲');
      surname2.Add('公上');
      surname2.Add('公門');
      surname2.Add('公山');
      surname2.Add('公堅');
      surname2.Add('左丘');
      surname2.Add('公伯');
      surname2.Add('西門');
      surname2.Add('公祖');
      surname2.Add('第五');
      surname2.Add('公乘');
      surname2.Add('貫丘');
      surname2.Add('公皙');
      surname2.Add('南榮');
      surname2.Add('東裏');
      surname2.Add('東宮');
      surname2.Add('仲長');
      surname2.Add('子書');
      surname2.Add('子桑');
      surname2.Add('即墨');
      surname2.Add('達奚');
      surname2.Add('褚師');
      surname2.Add('第二');
      surname := midstr(fullname, 1, 6);
      hysur := 0;
      for i := 0 to surname2.Count - 1 do
      begin
        if surname = surname2.Strings[i] then
        begin
          hysur := 1;
          break;
        end;
      end;
      if hysur = 1 then
      begin
        givenname := midstr(fullname, 7, 3);
      end
      else
      begin
        surname := midstr(fullname, 1, 3);
        givenname := midstr(fullname, 4, 6);
      end;
      surname2.Free;
    end;
    else
    begin
      surname := midstr(fullname, 1, 6);
      givenname := midstr(fullname, 7, Length(fullname) - 6);
    end;
  end;
  //writeln(len, ',', fullname, ',', surname, ',', givenname);
end;

function ReplaceStr(const S, Srch, Replace: utf8string): utf8string;
var
  i: integer;
  Source: utf8string;
begin
  Source := S;
  Result := '';
  repeat
    //i := Pos(UpperCase(Srch), UpperCase(Source));
    i := Pos(Srch, Source);
    if i > 0 then
    begin
      Result := Result + Copy(Source, 1, i - 1) + Replace;
      Source := Copy(Source, i + Length(Srch), MaxInt);
    end
    else
      Result := Result + Source;
  until i <= 0;
end;

procedure NewTalk(headnum, talknum, namenum, place, showhead, color, frame: integer; content: utf8string = ''; disname: utf8string = '');
var
  FileHandle, Offset, len, I, I2, ix, iy, xtemp, a, len_utf8: integer;
  Frame_X, Frame_Y, Frame_W, Frame_H, Head_X, Head_Y, Head_W, Head_H, Name_X, Name_Y, Name_W, Name_H, Talk_X, Talk_Y, Talk_W, Talk_H, MaxCol: integer;
  ForeGroundCol, BackGroundCol: byte;
  DrawForeGroundCol, DrawBackGroundCol: cardinal;
  Talk, Name, SurName, GivenName: array of byte;
  {$IFDEF fpc}
  FullNameUTF8Str, SurNameUTF8Str, GivenNameUTF8Str: utf8string;
  {$ENDIF}
  FullNameStr, SurNameStr, GivenNameStr, TalkStr, NameStr, TempStr: utf8string;
  Changed: boolean;
  HeadNumR: integer; //用于重定头像的对应人物, 以正确读取名字
  skipSync: boolean = False;
const
  NameIdxFile = 'resource/name.idx';
  NameGrpFile = 'resource/name.grp';
  TalkIdxFile = 'resource/talk.idx';
  TalkGrpFile = 'resource/talk.grp';
  RowSpacing = 25; //行距
  ColSpacing = 20; //列距
  MaxRow = 5;
  NameColSpacing = 20; //名字列距
  FullNameCode: utf8string = '&&';
  SurNameCode: utf8string = '$$';
  GivenNameCode: utf8string = '%%';
  WaitAnyKeyCode: utf8string = '@@';
  DelayCode: utf8string = '##';
  NextLineCode: utf8string = '**';
  ChangeColorCode: utf8string = '^';
  ExpressionMin: integer = 412;
  ExpressionMax: integer = 429;
begin
  MaxCol := 25;
  MaxCol := trunc((CENTER_X * 2 - (768 - MaxCol * ColSpacing)) / ColSpacing);
  // *********设置位置、宽高、颜色等数据*********//
  //对话框边框位置
  Frame_X := 50;
  Frame_Y := CENTER_Y * 2 - 180;

  //对话字串位置及列数、行数
  Talk_X := Frame_X + 50;
  Talk_Y := Frame_Y + 35;
  Talk_W := MaxCol;
  Talk_H := MaxRow;
  Name_X := Talk_X;
  Name_Y := Frame_Y + 7;

  if place > 2 then
    place := 5 - place;

  if place = 0 then //头像在左
  begin
    //头像位置
    Head_X := 30;
    Head_Y := CENTER_Y * 2 - 120;
    //名字位置
  end
  else if place = 1 then //头像在右
  begin
    Head_X := CENTER_X * 2 - 200;
    Head_Y := CENTER_Y * 2 - 120;
    Talk_X := 30;
    Name_X := Talk_X;
    Name_Y := Frame_Y + 7;
  end
  else if place = 2 then
  begin
    Talk_X := Frame_X + 70;
  end;

  //特殊颜色值
  case color of
    0: color := 28515;
    1: color := 28421;
    2: color := 28435;
    3: color := 28563;
    4: color := 28466;
    5: color := 28450;
  end;

  //前景、背景颜色
  ForeGroundCol := color and $FF;
  BackGroundCol := (color and $FF00) shr 8;
  // ******************************************//
  //如果talknum小于0, 则读取x50中的内容
  if content = '' then
  begin
    if (talknum >= 0) then
    begin
      talkstr := ReadTalk(talknum);
    end
    else
    begin
      if (-talknum >= low(x50)) and (-talknum <= high(x50)) then
        TalkStr := putf8char(@x50[-talknum])
      else
        TalkStr := '';
    end;
  end
  else
    TalkStr := content;
  TalkStr := ' ' + TalkStr;
  // ******************************************//

  // *****************读取名字*****************//
  if disname = '' then
  begin
    if namenum > 0 then
    begin
      Namestr := ReadTalk(namenum);
    end;

    HeadNumR := HeadNum;
    if (HeadNum >= ExpressionMin) and (HeadNum <= ExpressionMax) then
      HeadNumR := 0;

    {if MODVersion = 13 then
      begin
      if HeadNum = 0 then HeadNum := 434;
      end;}

    if NameNum = -2 then
    begin
      for I := 0 to length(Rrole) - 1 do
      begin
        if (Rrole[i].HeadNum = HeadNumR) or ((i = 0) and (HeadNumR = 0)) then
        begin
          len := 20;
          setlength(Name, len + 1);
          Move(Rrole[i].Name[0], Name[0], len);
          Name[len] := 0;
          break;
        end;
      end;
    end;

    if (namenum = -2) then
      NameStr := cp950toutf8(@Name[0])
    else if (namenum = -1) or (namenum = 0) then
      NameStr := '';
    //if {(MODVersion in [0, 31]) and} (namenum = 0) then
    //  NameStr := cp950toutf8(Rrole[0].Name);
  end
  else
    NameStr := disname;

  //if Length(NameStr) > 10 then
  //begin
  //NameStr := '';
  //HeadNum := -1;
  //end;
  // ******************************************//

  // *****************分析名字*****************//
  setlength(Name, 20);
  Move(Rrole[0].Name[0], Name[0], 20);
  //FullNameStr := CP950ToUTF8(putf8char(@Name[0]));
  FullNameStr := cp950toutf8(@Name[0]);

  {$IFDEF fpc}
  //FullNameUTF8Str := UTF8Encode(FullNameStr);
  {$ELSE}
  //DivideName(FullNameStr, SurNameStr, GivenNameStr);
  {$ENDIF}

  // ******************************************//

  // ***************替换对话字符串*************//
  //TalkStr := ReplaceStr(TalkStr, '＜'), utf8decode('^4');
  //替换字符串中的姓名
  if (Pos(FullNameCode, TalkStr) > 0) then
    TalkStr := ReplaceStr(TalkStr, FullNameCode, FullNameStr);
  SurNameStr := '';
  GivenNameStr := '';
  if (Pos(SurNameCode, TalkStr) > 0) or (Pos(GivenNameCode, TalkStr) > 0) then
  begin
    //DivideName(FullNameStr, SurNameStr, GivenNameStr);
    //SurNameStr := SurNameUTF8Str;
    //GivenNameStr := GivenNameUTF8Str;
    TalkStr := ReplaceStr(TalkStr, SurNameCode, SurNameStr);
    TalkStr := ReplaceStr(TalkStr, GivenNameCode, GivenNameStr);
  end;

  // ******************************************//

  // *****************显示对话*****************//

  //SetRolePic(0);
  Redraw;
  //RecordFreshScreen;

  DrawForeGroundCol := ColColor(ForeGroundCol);
  DrawBackGroundCol := ColColor(BackGroundCol);
  len := length(TalkStr);
  I := 1;
  CleanKeyValue;
  while (True) do
  begin
    //显示背景
    //display_img('resource/talk.png', Frame_X, Frame_Y);
    //LoadFreshScreen;
    //DrawTPic(25, 0, Frame_Y - 60, nil, 0,30,0,0,0.75,0.75);
    redraw;
    DrawRectangleWithoutFrame(screen, 0, Frame_Y, CENTER_X * 2, 170, 0, 40);
    //显示头像
    if (showhead = 0) and (HeadNum >= 0) then
    begin
      DrawHeadPic(HeadNum, Head_X, Head_Y);
    end;
    //显示名字
    if (NameStr <> '') or (showhead <> 0) then
    begin
      DrawShadowText(NameStr, Name_X + 0, Name_Y, ColColor(5), ColColor(7));
    end;
    UpdateAllScreen;
    //显示对话
    ix := 0;
    iy := 0;
    skipSync := False;
    while SDL_PollEvent(@event) or True do
    begin
      CheckBasicEvent;
      //部分功能
      if ((event.type_ = SDL_EVENT_KEY_UP) and (event.key.key = SDLK_ESCAPE)) or ((event.type_ = SDL_EVENT_MOUSE_BUTTON_UP) and (event.button.button = SDL_BUTTON_RIGHT)) then
      begin
        skipSync := True;
        SkipTalk := 1;
        //CleanKeyValue;
        break;
      end;
      if ((event.type_ = SDL_EVENT_KEY_UP) and ((event.key.key = SDLK_RETURN) or (event.key.key = SDLK_SPACE))) or ((event.type_ = SDL_EVENT_MOUSE_BUTTON_UP) and (event.button.button = SDL_BUTTON_LEFT)) then
      begin
        skipSync := True;
        SkipTalk := 0;
      end;
      //if SkipTalk = 1 then
      //break;
      if not ((ix < Talk_W) and (iy < Talk_H) and (I <= len)) then
        break;
      //检查是否等待按键
      if midstr(talkstr, I, length(WaitAnyKeyCode)) = WaitAnyKeyCode then
      begin
        Inc(I, length(TempStr));
        //updateallscreen;
        WaitAnyKey;
        Continue;
      end;
      //检查是否延时
      if midstr(talkstr, I, length(DelayCode)) = DelayCode then
      begin
        Inc(I, length(DelayCode));
        //updateallscreen;
        SDL_Delay(500);
        Continue;
      end;
      //检查是否换行
      if midstr(talkstr, I, length(NextLineCode)) = NextLineCode then
      begin
        //当恰好处于换行位置时的处理(屏蔽, 未处理)
        //if I mod Talk_W <> 1 then
        //begin
        Inc(iy);
        ix := 0;
        //end;
        Inc(I, length(NextLineCode));
        if iy >= Talk_H then
        begin
          if I <= len then
          begin
            WaitAnyKey;
          end;
          //LoadFreshScreen;;
          break;
        end;
        Continue;
      end;
      //检查是否更换颜色
      Changed := False;
      for I2 := 0 to 5 do
        if midstr(talkstr, I, length(ChangeColorCode) + 1) = ChangeColorCode + IntToStr(I2) then
        begin
          DrawBackGroundCol := ColColor($6F);
          case I2 of
            0: DrawForeGroundCol := ColColor($63);
            1: DrawForeGroundCol := ColColor($05);
            2: DrawForeGroundCol := ColColor($13);
            3: DrawForeGroundCol := ColColor($93);
            4: DrawForeGroundCol := ColColor($32);
            5: DrawForeGroundCol := ColColor($22);
          end;
          Inc(I, length(ChangeColorCode) + 1);
          Changed := True; //更换颜色
          break;
        end;
      if Changed = True then
      begin
        continue;
      end;
      //检查是否换回默认颜色
      if midstr(talkstr, I, length(ChangeColorCode) * 2) = ChangeColorCode + ChangeColorCode then
      begin
        DrawBackGroundCol := ColColor(BackGroundCol);
        DrawForeGroundCol := ColColor(ForeGroundCol);
        Inc(I, length(ChangeColorCode) * 2);
        Continue;
      end;
      //写字符
      if I <= len then
      begin
        tempstr := TalkStr[I];
        len_utf8 := utf8follow(TalkStr[I]);
        tempstr := midstr(talkstr, i, len_utf8);
        tempstr := tempstr + utf8char(0);
        xtemp := Talk_X + ColSpacing * ix;
        //调整半角字符的位置
        if uint16(tempstr[1]) < $1000 then
          xtemp := xtemp + 5;
        DrawShadowText(TempStr, xtemp, Talk_Y + RowSpacing * iy, DrawForeGroundCol, DrawBackGroundCol);
      end;
      Inc(I, length(tempstr) - 1);
      if (not skipSync) and (SkipTalk = 0) then
      begin
        SDL_Delay(5); //每个字符间都延时
        UpdateAllScreen;
      end;
      Inc(ix);
      if (ix >= Talk_W) or (iy >= Talk_H) then
      begin
        ix := 0;
        Inc(iy);
        if iy >= Talk_H then
        begin
          if I - 1 <= len then
          begin
            UpdateAllScreen;
            if (SkipTalk = 0) then
            begin
              WaitAnyKey;
              if skipSync then
                WaitAnyKey;
              skipSync := False;
            end;
          end;
          UpdateAllScreen;
          //LoadFreshScreen;
          break;
        end;
      end;
    end;
    if I > len then
      break;
    //if SkipTalk = 1 then
    //break;
  end;
  //FreeFreshScreen;
  UpdateAllScreen;
  if SkipTalk = 0 then
  begin
    WaitAnyKey;
    if skipSync then
      WaitAnyKey;
  end;
  //Redraw;
  // ******************************************//

end;

//输入数字, 最小值, 最大值, 坐标x, y. 当结果被范围修正时有提示.
function EnterNumber(MinValue, MaxValue, x, y: integer; Default: integer = 0): smallint;
var
  Value, i, menu, sure, pvalue, pmenu, highButton: integer;
  str: array [0 .. 13] of utf8string;
  color: uint32;
  strv, strr: utf8string;
  //tempscr: psdl_surface;
  Button: array [0 .. 13] of TSDL_Rect;
begin
  CleanKeyValue;
  Value := default;
  MinValue := max(-32768, MinValue);
  MaxValue := min(32767, MaxValue);
  //13个按钮的位置和大小
  for i := 0 to 9 do
  begin
    str[i] := IntToStr(i);
    Button[i].x := x + (i + 2) mod 3 * 35 + 20;
    Button[i].y := y + (3 - (i + 2) div 3) * 30 + 50;
    Button[i].w := 25;
    Button[i].h := 23;
  end;
  str[10] := '  ±';
  Button[10].x := x + 20;
  Button[10].y := y + 140;
  Button[10].w := 60;
  Button[10].h := 23;
  str[11] := '←';
  Button[11].x := x + 125;
  Button[11].y := y + 50;
  Button[11].w := 35;
  Button[11].h := 23;
  str[12] := 'AC';
  Button[12].x := x + 125;
  Button[12].y := y + 80;
  Button[12].w := 35;
  Button[12].h := 23;
  str[13] := 'OK';
  Button[13].x := x + 125;
  Button[13].y := y + 110;
  Button[13].w := 35;
  Button[13].h := 53;
  //Redraw;
  //SetFontSize(32, 30);
  DrawRectangle(screen, x, y, 180, 180, 0, ColColor(255), 50);
  DrawRectangle(screen, x + 20, y + 10, 140, 23, 0, ColColor(255), 75);
  highButton := high(Button);
  for i := 0 to highButton do
  begin
    DrawRectangle(screen, Button[i].x, Button[i].y, Button[i].w, Button[i].h, 0, ColColor(255), 50);
  end;
  UpdateAllScreen;
  RecordFreshScreen(x, y, 181, 181);
  strv := format('%d~%d', [MinValue, MaxValue]);
  DrawTextWithRect(strv, x, y - 35, DrawLength(strv) * 10 + 7, ColColor($21), ColColor($27));
  //在循环中写字体是为了字体分层模式容易处理
  menu := -1;
  sure := 0; //1-键盘按下, 2-鼠标按下
  pvalue := -1;
  pmenu := -1;
  while SDL_PollEvent(@event) or True do
  begin
    CheckBasicEvent;
    case event.type_ of
      SDL_EVENT_KEY_UP:
      begin
        case event.key.key of
          SDLK_0 .. SDLK_9: menu := event.key.key - SDLK_0;
          SDLK_KP_1 .. SDLK_KP_9: menu := event.key.key - SDLK_KP_1 + 1;
          SDLK_KP_0: menu := 0;
          SDLK_MINUS, SDLK_KP_MINUS: menu := 10;
          SDLK_DELETE: menu := 12;
          SDLK_RETURN, SDLK_SPACE, SDLK_KP_ENTER: menu := highButton;
        end;
        sure := 1;
      end;
      SDL_EVENT_MOUSE_MOTION:
      begin
        menu := -1;
        for i := 0 to high(button) do
        begin
          if MouseInRegion(Button[i].x, Button[i].y, Button[i].w, Button[i].h) then
          begin
            menu := i;
            break;
          end;
        end;
      end;
      SDL_EVENT_MOUSE_BUTTON_UP:
      begin
        case event.button.button of
          SDL_BUTTON_LEFT:
          begin
            menu := -1;
            for i := 0 to highButton do
            begin
              if MouseInRegion(Button[i].x, Button[i].y, Button[i].w, Button[i].h) then
              begin
                menu := i;
                break;
              end;
            end;
            if (menu >= 0) and (menu <= highButton) then
              sure := 2;
          end;
        end;
      end;
    end;
    //画界面
    if (Value <> pvalue) or (menu <> pmenu) then
    begin
      LoadFreshScreen(x, y, 181, 181);
      strv := format('%6d', [Value]);
      DrawShadowText(strv, x + 80, y + 10, ColColor($64), ColColor($66));
      if (menu >= 0) and (menu <= highButton) then
      begin
        DrawRectangle(screen, Button[menu].x, Button[menu].y, Button[menu].w, Button[menu].h, ColColor(20 * i + random(20)), ColColor(255), 50);
      end;
      for i := 0 to highButton do
      begin
        DrawShadowText(str[i], Button[i].x + 8, Button[i].y + Button[i].h div 2 - 11, ColColor(5), ColColor(7));
      end;
      UpdateAllScreen;
      pvalue := Value;
      pmenu := menu;
    end;
    CleanKeyValue;
    //计算数值变化
    if sure > 0 then
    begin
      case menu of
        0 .. 9:
          if Value * 10 < 1E5 then
            Value := 10 * Value + menu;
        10: Value := -Value;
        11: Value := Value div 10;
        12: Value := 0;
        else
          if menu = highButton then
            break;
      end;
      if sure = 1 then
        menu := -1;
    end;
    sure := 0;
    SDL_Delay(25);
  end;
  Result := RegionParameter(Value, MinValue, MaxValue);
  //Redraw;
  if Result <> Value then
  begin
    Redraw;
    UpdateAllScreen;
    strv := format('依據範圍自動調整為%d！', [Result]);
    DrawTextWithRect(strv, x, y, DrawLength(strv) * 10 + 7, ColColor($64), ColColor($66));
    WaitAnyKey;
  end;
  CleanKeyValue;
  //FreeFreshScreen;
end;

function EnterString(var str: utf8string; x, y, w, h: integer): bool;
var
  r: TSDL_Rect;
  l: integer;
  i: uint32;
  str2: utf8string;
begin
  r.x := x;
  r.y := y;
  r.w := w;
  r.h := h;
  SDL_StartTextInput(window);
  SDL_SetTextInputArea(window, @r, 0);
  while True do
  begin
    i := i + 1;
    Redraw;
    str2 := str;
    if (i mod 16 < 8) then str2 := str2 + '_';
    DrawTextWithRect(str2, x, y, w, ColColor($66), ColColor($63));
    SDL_UpdateRect2(screen, x, y, w, h);
    SDL_PollEvent(@event);
    CheckBasicEvent;
    case event.type_ of
      SDL_EVENT_TEXT_INPUT:
      begin
        str := str + event.Text.Text;
      end;
      SDL_EVENT_MOUSE_BUTTON_UP:
      begin
        if (event.button.button = SDL_BUTTON_RIGHT) then
        begin
          Result := False;
          break;
        end;
      end;
      SDL_EVENT_KEY_UP:
      begin
        if event.key.key = SDLK_RETURN then
        begin
          Result := True;
          break;
        end;
        if event.key.key = SDLK_ESCAPE then
        begin
          Result := False;
          break;
        end;
        if event.key.key = SDLK_BACKSPACE then
        begin
          l := length(str);
          if (l >= 3) and (byte(str[l]) >= 128) then
          begin
            setlength(str, l - 3);
          end
          else if (l >= 1) then
          begin
            setlength(str, l - 1);
          end;
        end;
      end;
    end;
    SDL_Delay(16);
  end;
  SDL_StopTextInput(window);
end;

procedure SetAttribute(rnum, selecttype, modlevel, minlevel, maxlevel: integer);
begin

end;

end.
