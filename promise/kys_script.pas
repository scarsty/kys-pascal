unit kys_script;

//{$MODE Delphi}

interface

uses
{$IFDEF fpc}
  LConvEncoding, FileUtil,
{$ELSE}
  Windows,
{$ENDIF}
  SysUtils,
  Classes,
  Dialogs,
  Math,
  SDL,
  lua52,
  kys_main,
  kys_event,
  kys_engine,
  kys_littlegame,
  kys_battle;

//初始化脚本配置, 运行脚本
procedure InitialScript;
procedure DestroyScript;
function ExecScript(filename, functionname: PChar): integer;

//具体指令,封装基本指令
function Pause(L: Plua_state): integer; cdecl;
function GetMousePosition(L: Plua_state): integer; cdecl;
function ClearButton(L: Plua_state): integer; cdecl;
function CheckButton(L: Plua_state): integer; cdecl;
function GetButton(L: Plua_state): integer; cdecl;
function GetTime(L: Plua_state): integer; cdecl;
function ExecEvent(L: Plua_state): integer; cdecl;

function Clear(L: Plua_state): integer; cdecl;
function Talk(L: Plua_state): integer; cdecl;
function GetItem(L: Plua_state): integer; cdecl;
function AddItem(L: Plua_state): integer; cdecl;
function ShowString(L: Plua_state): integer; cdecl;
function ShowStringWithBox(L: Plua_state): integer; cdecl;
function Menu(L: Plua_state): integer; cdecl;
function AskYesOrNo(L: Plua_state): integer; cdecl;
function ModifyEvent(L: Plua_state): integer; cdecl;
function UseItem(L: Plua_state): integer; cdecl;
function HaveItem(L: Plua_state): integer; cdecl;
function AnotherGetItem(L: Plua_state): integer; cdecl;
function CompareProInTeam(L: Plua_state): integer; cdecl;
function AllLeave(L: Plua_state): integer; cdecl;
function AskBattle(L: Plua_state): integer; cdecl;
function TryBattle(L: Plua_state): integer; cdecl;
function AskJoin(L: Plua_state): integer; cdecl;
function Join(L: Plua_state): integer; cdecl;
function AskRest(L: Plua_state): integer; cdecl;
function Rest(L: Plua_state): integer; cdecl;
function LightScene(L: Plua_state): integer; cdecl;
function DarkScene(L: Plua_state): integer; cdecl;
function Dead(L: Plua_state): integer; cdecl;
function InTeam(L: Plua_state): integer; cdecl;
function TeamIsFull(L: Plua_state): integer; cdecl;
function LeaveTeam(L: Plua_state): integer; cdecl;
function LearnMagic(L: Plua_state): integer; cdecl;
//function Sprintf(L: Plua_state): integer; cdecl;
function GetMainMapPosition(L: Plua_state): integer; cdecl;
function SetMainMapPosition(L: Plua_state): integer; cdecl;
function GetScenePosition(L: Plua_state): integer; cdecl;
function SetScenePosition(L: Plua_state): integer; cdecl;
function GetSceneFace(L: Plua_state): integer; cdecl;
function SetSceneFace(L: Plua_state): integer; cdecl;
function Delay(L: Plua_state): integer; cdecl;
function DrawRect(L: Plua_state): integer; cdecl;
function MemberAmount(L: Plua_state): integer; cdecl;
function GetMember(L: Plua_state): integer; cdecl;
function PutMember(L: Plua_state): integer; cdecl;
function GetRolePro(L: Plua_state): integer; cdecl;
function PutRolePro(L: Plua_state): integer; cdecl;
function GetItemPro(L: Plua_state): integer; cdecl;
function PutItemPro(L: Plua_state): integer; cdecl;
function GetMagicPro(L: Plua_state): integer; cdecl;
function PutMagicPro(L: Plua_state): integer; cdecl;
function GetScenePro(L: Plua_state): integer; cdecl;
function PutScenePro(L: Plua_state): integer; cdecl;
function GetSceneMapPro(L: Plua_state): integer; cdecl;
function PutSceneMapPro(L: Plua_state): integer; cdecl;
function GetSceneEventPro(L: Plua_state): integer; cdecl;
function PutSceneEventPro(L: Plua_state): integer; cdecl;
function JudgeSceneEvent(L: Plua_state): integer; cdecl;
function PlayMusic(L: Plua_state): integer; cdecl;
function PlayWave(L: Plua_state): integer; cdecl;
function WalkFromTo(L: Plua_state): integer; cdecl;
function SceneFromTo(L: Plua_state): integer; cdecl;
function PlayAnimation(L: Plua_state): integer; cdecl;
function GetNameAsString(L: Plua_state): integer; cdecl;
function ChangeScene(L: Plua_state): integer; cdecl;
function ShowPicture(L: Plua_state): integer; cdecl;
function GetItemList(L: Plua_state): integer; cdecl;
function GetCurrentScene(L: Plua_state): integer; cdecl;
function GetCurrentEvent(L: Plua_state): integer; cdecl;

function GetBattleNumber(L: Plua_state): integer; cdecl;
function SelectOneAim(L: Plua_state): integer; cdecl;
function GetBattlePro(L: Plua_state): integer; cdecl;
function PutBattlePro(L: Plua_state): integer; cdecl;
function PlayAction(L: Plua_state): integer; cdecl;
//function GetRoundNumber(L: Plua_state): integer; cdecl;
function PlayHurtValue(L: Plua_state): integer; cdecl;
function SetAminationLayer(L: Plua_state): integer; cdecl;
function ClearRoleFromBattle(L: Plua_state): integer; cdecl;
function AddRoleIntoBattle(L: Plua_state): integer; cdecl;
function ForceBattleResult(L: Plua_state): integer; cdecl;
function GetAimPosition(L: Plua_state): integer; cdecl;
function GetMagicLv(L: Plua_state): integer; cdecl;
function HaveMagicLv(L: Plua_state): integer; cdecl;
function KGTalk(L: Plua_state): integer; cdecl;
function ReName(L: Plua_state): integer; cdecl;
function PutLine(L: Plua_state): integer; cdecl;
function ShowBanner(L: Plua_state): integer; cdecl;

function SetRandomEvent(L: Plua_state): integer; cdecl;
function SetScenePallet(L: Plua_state): integer; cdecl;
function SetSceneMode(L: Plua_state): integer; cdecl;
function SetTimeEvent(L: Plua_state): integer; cdecl;
function UpdateScreen(L: Plua_state): integer; cdecl;
function shotbird(L: Plua_state): integer; cdecl;
function pintu(L: Plua_state): integer; cdecl;
implementation


procedure InitialScript;
var
  lib: boolean;
begin
  Lua_script := luaL_newstate;
  luaL_openlibs(Lua_script);
  luaopen_base(Lua_script);
  luaopen_table(Lua_script);
  luaopen_math(Lua_script);
  luaopen_string(Lua_script);

  lua_register(Lua_script, 'pause', Pause);
  lua_register(Lua_script, 'getmouseposition', GetMousePosition);
  lua_register(Lua_script, 'clearbutton', ClearButton);
  lua_register(Lua_script, 'checkbutton', CheckButton);
  lua_register(Lua_script, 'getbutton', GetButton);
  lua_register(Lua_script, 'gettime', GetTime);
  lua_register(Lua_script, 'execevent', ExecEvent);
  lua_register(Lua_script, 'updatescreen', UpdateScreen);


  lua_register(Lua_script, 'clear', Clear);
  lua_register(Lua_script, 'talk', Talk);
  lua_register(Lua_script, 'getitem', GetItem);
  lua_register(Lua_script, 'additem', AddItem);
  lua_register(Lua_script, 'showstring', ShowString);
  lua_register(Lua_script, 'showstringwithbox', ShowStringWithBox);
  lua_register(Lua_script, 'menu', Menu);
  lua_register(Lua_script, 'askyesorno', AskYesOrNo);
  lua_register(Lua_script, 'modifyevent', ModifyEvent);
  lua_register(Lua_script, 'useitem', UseItem);
  lua_register(Lua_script, 'haveitem', HaveItem);
  lua_register(Lua_script, 'anothergetitem', AnotherGetItem);
  lua_register(Lua_script, 'compareprointeam', CompareProInTeam);
  lua_register(Lua_script, 'allleave', AllLeave);
  lua_register(Lua_script, 'askbattle', AskBattle);
  lua_register(Lua_script, 'trybattle', TryBattle);
  lua_register(Lua_script, 'askjoin', AskJoin);
  lua_register(Lua_script, 'join', Join);
  lua_register(Lua_script, 'askrest', AskRest);
  lua_register(Lua_script, 'rest', Rest);
  lua_register(Lua_script, 'lightScene', LightScene);
  lua_register(Lua_script, 'darkScene', DarkScene);
  lua_register(Lua_script, 'dead', Dead);
  lua_register(Lua_script, 'inteam', InTeam);
  lua_register(Lua_script, 'teamisfull', TeamIsFull);
  lua_register(Lua_script, 'leaveteam', LeaveTeam);
  lua_register(Lua_script, 'learnmagic', LearnMagic);
  //lua_register(Lua_script, 'sprintf', Sprintf);
  lua_register(Lua_script, 'getmainmapposition', GetMainMapPosition);
  lua_register(Lua_script, 'setmainmapposition', SetMainMapPosition);
  lua_register(Lua_script, 'getSceneposition', GetScenePosition);
  lua_register(Lua_script, 'setSceneposition', SetScenePosition);
  lua_register(Lua_script, 'getSceneface', GetSceneFace);
  lua_register(Lua_script, 'setSceneface', SetSceneFace);
  lua_register(Lua_script, 'delay', Delay);
  lua_register(Lua_script, 'drawrect', DrawRect);
  lua_register(Lua_script, 'memberamount', MemberAmount);
  lua_register(Lua_script, 'getmember', GetMember);
  lua_register(Lua_script, 'putmember', PutMember);
  lua_register(Lua_script, 'getrolepro', GetRolePro);
  lua_register(Lua_script, 'putrolepro', PutRolePro);
  lua_register(Lua_script, 'getitempro', GetItemPro);
  lua_register(Lua_script, 'putitempro', PutItemPro);
  lua_register(Lua_script, 'getmagicpro', GetMagicPro);
  lua_register(Lua_script, 'putmagicpro', PutMagicPro);
  lua_register(Lua_script, 'getScenepro', GetScenePro);
  lua_register(Lua_script, 'putScenepro', PutScenePro);
  lua_register(Lua_script, 'getScenemappro', GetSceneMapPro);
  lua_register(Lua_script, 'putScenemappro', PutSceneMapPro);
  lua_register(Lua_script, 'getSceneeventpro', GetSceneEventPro);
  lua_register(Lua_script, 'putSceneeventpro', PutSceneEventPro);
  lua_register(Lua_script, 'judgeSceneevent', JudgeSceneEvent);
  lua_register(Lua_script, 'playmusic', PlayMusic);
  lua_register(Lua_script, 'playwave', PlayWave);
  lua_register(Lua_script, 'walkfromto', WalkFromTo);
  lua_register(Lua_script, 'Scenefromto', SceneFromTo);
  lua_register(Lua_script, 'playanimation', PlayAnimation);
  lua_register(Lua_script, 'getnameasstring', GetNameAsString);
  lua_register(Lua_script, 'changeScene', ChangeScene);
  lua_register(Lua_script, 'showpicture', ShowPicture);
  lua_register(Lua_script, 'getitemlist', GetItemList);
  lua_register(Lua_script, 'getcurrentScene', GetCurrentScene);
  lua_register(Lua_script, 'getcurrentevent', GetCurrentEvent);
  lua_register(Lua_script, 'getaimposition', GetAimPosition);
  lua_register(Lua_script, 'getbattlenumber', GetBattleNumber);
  lua_register(Lua_script, 'selectoneaim', SelectOneAim);
  lua_register(Lua_script, 'getbattlepro', GetBattlePro);
  lua_register(Lua_script, 'putbattlepro', PutBattlePro);
  lua_register(Lua_script, 'playaction', PlayAction);
  lua_register(Lua_script, 'playhurtvalue', PlayHurtValue);
  lua_register(Lua_script, 'setaminationlayer', SetAminationLayer);
  lua_register(Lua_script, 'clearrolefrombattle', ClearRoleFromBattle);
  lua_register(Lua_script, 'addroleintobattle', AddRoleIntoBattle);
  lua_register(Lua_script, 'forcebattleresult', ForceBattleResult);
  lua_register(Lua_script, 'getmagiclv', GetMagicLv);
  lua_register(Lua_script, 'havemagiclv', HaveMagicLv);
  lua_register(Lua_script, 'newtalk', KGTalk);
  lua_register(Lua_script, 'rename', ReName);
  lua_register(Lua_script, 'putline', PutLine);
  lua_register(Lua_script, 'showtitle', ShowBanner);
  lua_register(Lua_script, 'setrandomevent', SetRandomEvent);
  lua_register(Lua_script, 'setScenepallet', SetScenePallet);
  lua_register(Lua_script, 'setScenemode', SetSceneMode);
  lua_register(Lua_script, 'settimeevent', SetTimeEvent);
  lua_register(Lua_script, 'shotbird', Shotbird);
  lua_register(Lua_script, 'pintu', pintu);
end;


procedure DestroyScript;
begin
  lua_close(Lua_script);
end;


function ExecScript(filename, functionname: PChar): integer;
var
  Script: string;
  key, filename1: string;
  h: integer;
  len, lenkey: integer;
  p1, p2: pbyte;
  i1: integer;
  p: PChar;
begin
  key := '鐵血丹心論壇出品，www.txdx.net 原著：金庸';
  filename1 := filename;
  //if encrypt = 1 then filename1 := changefileext(filename1, '.enc');
  if FileExistsUTF8(AppPath + filename1) { *Converted from FileExists*  } then
  begin
    h := fileopen(AppPath + filename1, fmopenread);
    len := fileseek(h, 0, 2);
    setlength(Script, len);
    fileseek(h, 0, 0);
    fileread(h, Script[1], len);
    fileclose(h);
   { if encrypt = 1 then
    begin
      lenkey := length(key);
      p1 := @key[1];
      p2 := @script[1];
      for h := 0 to len - 1 do
      begin
        p2^ := p2^ xor p1^;
        inc(p2);
        inc(p1);
        if (h mod lenkey) = 0 then p1 := @key[1];
      end;   }
  end;
  //writeln(script);
  i1 := 0;
  p := @script[1];
  while p^ <> char(0) do
  begin
    if p^ = char(39) then
      i1 := 1 - i1;
    if (i1 = 0) and ((integer(p^) in [65..90])) then
      Inc(p^, 32);
    Inc(p);
  end;
{$IFDEF UNIX}
  Script := LowerCase(Script);
{$ELSE}
{$IFDEF FPC}
  Script := LowerCase(Script);
{$ELSE}
  Script := UTF8ToAnsi(LowerCase(Script));
{$ENDIF}
{$ENDIF}
  lual_loadbuffer(Lua_script, @script[1], length(script), 'code');
  lua_pcall(Lua_script, 0, 0, 0);
  //lua_dofile(Lua_script,pchar(filename[1]));
  lua_getglobal(Lua_script, functionname);
  //lua_dostring(Lua_script,'f2()');
  Result := lua_pcall(Lua_script, 0, 1, 0);
  //writeln(filename);
  //writeln(result);
end;



function Pause(L: Plua_state): integer; cdecl;
begin
  lua_pushnumber(L, waitanykey);
  Result := 1;

end;


function GetMousePosition(L: Plua_state): integer; cdecl;
var
  x, y: integer;
begin
  SDL_PollEvent(@event);
  sdl_getmousestate(x, y);
  lua_pushnumber(L, x);
  lua_pushnumber(L, y);
  Result := 2;

end;

function ClearButton(L: Plua_state): integer; cdecl;
begin
  //event.type_ := 0;
  event.key.keysym.sym := 0;
  event.button.button := 0;
  Result := 0;

end;

//检查按键
//event.key.keysym.sym = 1 when mouse motion.

function CheckButton(L: Plua_state): integer; cdecl;
var
  t: integer;
begin
  SDL_PollEvent(@event);
  if (event.button.button > 0) then
  begin
    t := 1;
  end
  else
  begin
    t := 0;
  end;
  lua_pushnumber(L, t);
  sdl_delay((10 * GameSpeed) div 10);
  Result := 1;

end;

function GetButton(L: Plua_state): integer; cdecl;
var
  t: integer;
begin
  lua_pushnumber(L, event.key.keysym.sym);
  lua_pushnumber(L, event.button.button);
  Result := 2;

end;

function ExecEvent(L: Plua_state): integer; cdecl;
var
  n, e, i: integer;
begin
  n := lua_gettop(L);
  e := floor(lua_tonumber(L, -n));
  for i := 0 to n - 2 do
  begin
    x50[$7100 + i] := floor(lua_tonumber(L, -n + 1 + i));
  end;
  callevent(e);
  Result := 0;

end;

//获取当前时间

function GetTime(L: Plua_state): integer; cdecl;
var
  t: integer;
begin
  t := floor(time * 86400);
  lua_pushnumber(L, t);
  Result := 1;

end;

function Clear(L: Plua_state): integer; cdecl;
begin
  Redraw;
  Result := 0;

end;

function Talk(L: Plua_state): integer; cdecl;
var
  rnum, dismode: integer;
  content: WideString;
  len, headx, heady, diagx, diagy, Width, line, w1, l1, i: integer;
  str: WideString;
begin
  rnum := floor(lua_tonumber(L, -3));
  dismode := floor(lua_tonumber(L, -2));
  content := lua_tostring(L, -1);

  Width := 48;
  line := 4;

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
  drawrectanglewithoutframe(0, diagy - 10, 640, 120, 0, 40);
  if headx > 0 then
    drawheadpic(rnum, headx, heady);
  len := length(content);

  w1 := 0;
  l1 := 0;
  for i := 1 to len do
  begin
    if content[i] <> '*' then
    begin
      str := content[i];
      drawshadowtext(@str[1], diagx + w1 * 10, diagy + l1 * 22, colcolor($FF), colcolor($0));
      if integer(str[1]) < 128 then
        w1 := w1 + 1
      else
        w1 := w1 + 2;
      if w1 >= Width then
      begin
        w1 := 0;
        l1 := l1 + 1;
      end;
    end
    else
    begin
      w1 := 0;
      l1 := l1 + 1;
    end;
    if (l1 >= 4) and (i < len) then
    begin
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      WaitAnyKey;
      Redraw;
      drawrectanglewithoutframe(0, diagy - 10, 640, 120, 0, 40);
      if headx > 0 then
        drawheadpic(rnum, headx, heady);
      w1 := 0;
      l1 := 0;
    end;
  end;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  waitanykey;
  redraw;
  Result := 0;

end;

function GetItem(L: Plua_state): integer; cdecl;
var
  inum, amount: integer;
begin
  //writeln(lua_gettop(L));
  inum := floor(lua_tonumber(L, -2));
  amount := floor(lua_tonumber(L, -1));
  instruct_2(inum, amount);
  Result := 0;

end;

function AddItem(L: Plua_state): integer; cdecl;
var
  inum, amount: integer;
begin
  //writeln(lua_gettop(L));
  inum := floor(lua_tonumber(L, -2));
  amount := floor(lua_tonumber(L, -1));
  instruct_32(inum, amount);
  Result := 0;

end;

function ShowString(L: Plua_state): integer; cdecl;
var
  x, y, n, c1, c2: integer;
  str: WideString;
begin
  n := lua_gettop(L);
  if n = 5 then
  begin
    x := floor(lua_tonumber(L, -5));
    y := floor(lua_tonumber(L, -4));
    str := ' ' + lua_tostring(L, -3);
    c1 := floor(lua_tonumber(L, -2));
    c2 := floor(lua_tonumber(L, -1));
  end
  else
  begin
    c1 := 5;
    c2 := 7;
    x := floor(lua_tonumber(L, -3));
    y := floor(lua_tonumber(L, -2));
    str := ' ' + lua_tostring(L, -1);
  end;
  DrawShadowText(@str[1], x, y, colcolor(c1), colcolor(c2));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  Result := 0;

end;

function ShowStringWithBox(L: Plua_state): integer; cdecl;
var
  x, y, i, w, h, wt: integer;
  str: WideString;
begin
  x := floor(lua_tonumber(L, -3));
  y := floor(lua_tonumber(L, -2));
  str := ' ' + lua_tostring(L, -1);
  h := 1;
  w := 0;
  wt := 0;
  for i := 1 to length(str) do
  begin
    wt := wt + 1;
    if integer(str[i]) > 128 then
      wt := wt + 1;
    if str[i] = '*' then
    begin
      h := h + 1;
      wt := 0;
    end;
    if wt > w then
      w := wt;
  end;
  DrawRectangle(x + 17, y - 2, w * 10 + 25, h * 22 + 5, 0, colcolor(255), 30);
  DrawShadowText(@str[1], x, y, colcolor(5), colcolor(7));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  Result := 0;

end;

function Menu(L: Plua_state): integer; cdecl;
var
  menu, x, y, w, n, m, i: integer;
  p: WideString;
begin

  setlength(Menustring, 0);
  n := floor(lua_tonumber(L, -5));
  setlength(menustring, n);
  setlength(menuengstring, 0);

  for i := 0 to n - 1 do
  begin
    lua_pushnumber(L, i + 1);
    lua_gettable(L, -2);
    p := lua_tostring(L, -1);
    if p[1] = ' ' then
      menustring[i] := p
    else
      menustring[i] := ' ' + p;
    lua_pop(L, 1);
  end;

  w := floor(lua_tonumber(L, -2));
  y := floor(lua_tonumber(L, -3));
  x := floor(lua_tonumber(L, -4));
  lua_pushnumber(L, CommonScrollMenu(x, y, w, n - 1, 10));
  Result := 1;

end;

function AskYesOrNo(L: Plua_state): integer; cdecl;
var
  x, y: integer;
begin

  setlength(Menustring, 0);
  setlength(menustring, 2);
  menustring[0] := UTF8Decode(' 否');
  menustring[1] := UTF8Decode(' 是');
  y := floor(lua_tonumber(L, -2));
  x := floor(lua_tonumber(L, -1));
  lua_pushnumber(L, CommonMenu2(x, y, 78));
  Result := 1;
  //writeln(result);

end;

function ModifyEvent(L: Plua_state): integer; cdecl;
var
  x: array of integer;
  i, n: integer;
begin
  n := lua_gettop(L);
  setlength(x, n);
  for i := 0 to n - 1 do
  begin
    x[i] := floor(lua_tonumber(L, -(n - i)));
  end;
  if n = 13 then
    instruct_3(x);
  if n = 4 then
  begin
    if x[0] = -2 then
      x[0] := CurScene;
    if x[1] = -2 then
      x[1] := CurEvent;
    Ddata[x[0], x[1], x[2]] := x[3];
  end;
  Result := 0;

end;

function UseItem(L: Plua_state): integer; cdecl;
var
  inum, temp: integer;
begin
  //write(curitem);
  inum := floor(lua_tonumber(L, -1));
  temp := 0;
  if inum = CurItem then
    temp := 1;
  lua_pushnumber(L, temp);
  Result := 1;

end;

function HaveItem(L: Plua_state): integer; cdecl;
var
  inum, n, i: integer;
begin
  inum := floor(lua_tonumber(L, -1));
  for i := 0 to MAX_ITEM_AMOUNT do
  begin
    if RItemlist[i].Number = inum then
    begin
      n := RItemlist[i].Amount;
      break;
    end;
  end;
  lua_pushnumber(L, n);
  Result := 1;

end;

//非队友得到物品

function AnotherGetItem(L: Plua_state): integer; cdecl;
begin
  instruct_41(floor(lua_tonumber(L, -3)), floor(lua_tonumber(L, -2)), floor(lua_tonumber(L, -1)));
  Result := 0;

end;

//队伍中某属性等于某值的人数

function CompareProInTeam(L: Plua_state): integer; cdecl;
var
  n, i: integer;
begin
  n := 0;
  for i := 0 to 5 do
  begin
    if Rrole[TeamList[i]].Data[floor(lua_tonumber(L, -2))] = floor(lua_tonumber(L, -1)) then
      n := n + 1;
  end;

  lua_pushnumber(L, n);
  Result := 1;

end;

function AllLeave(L: Plua_state): integer; cdecl;
begin
  instruct_59;
  Result := 0;
end;

function AskBattle(L: Plua_state): integer; cdecl;
begin
  lua_pushnumber(L, instruct_5(1, 0));
  Result := 1;

end;

function TryBattle(L: Plua_state): integer; cdecl;
var
  t: integer;
begin
  if battle(floor(lua_tonumber(L, -2)), floor(lua_tonumber(L, -1))) then
    t := 1
  else
    t := 0;
  lua_pushnumber(L, t);
  Result := 1;

end;

function AskJoin(L: Plua_state): integer; cdecl;
begin
  lua_pushnumber(L, instruct_9(1, 0));
  Result := 1;

end;

function Join(L: Plua_state): integer; cdecl;
begin
  instruct_10(floor(lua_tonumber(L, -1)));
  Result := 0;

end;

function AskRest(L: Plua_state): integer; cdecl;
begin
  lua_pushnumber(L, instruct_11(1, 0));
  Result := 1;

end;

function Rest(L: Plua_state): integer; cdecl;
begin
  instruct_12;
  Result := 0;

end;

function LightScene(L: Plua_state): integer; cdecl;
begin
  instruct_13;
  Result := 0;

end;

function DarkScene(L: Plua_state): integer; cdecl;
begin
  instruct_14;
  Result := 0;

end;

function Dead(L: Plua_state): integer; cdecl;
begin
  instruct_15;
  Result := 0;

end;

function InTeam(L: Plua_state): integer; cdecl;
begin
  lua_pushnumber(L, instruct_16(floor(lua_tonumber(L, -1)), 1, 0));
  Result := 1;

end;

function TeamIsFull(L: Plua_state): integer; cdecl;
begin
  lua_pushnumber(L, instruct_20(1, 0));
  Result := 1;

end;

function LeaveTeam(L: Plua_state): integer; cdecl;
begin
  instruct_21(floor(lua_tonumber(L, -1)));
  Result := 0;

end;

function LearnMagic(L: Plua_state): integer; cdecl;
var
  n, i, m: integer;
  x: array of integer;
begin
  n := lua_gettop(L);
  setlength(x, n);
  for i := 0 to n - 1 do
  begin
    x[i] := floor(lua_tonumber(L, -(n - i)));
  end;
  if n = 2 then
  begin
    instruct_33(x[0], x[1], 0);
  end;
  if n = 3 then
  begin
    StudyMagic(x[0], 0, x[1], x[2], 0);
  end;
  if n = 4 then
  begin
    StudyMagic(x[0], x[1], x[2], x[3], 0);
  end;
  if n = 5 then
  begin
    StudyMagic(x[0], x[1], x[2], x[3], x[4]);
  end;
  Result := 0;

end;

//获取主地图坐标

function GetMainMapPosition(L: Plua_state): integer; cdecl;
begin
  lua_pushnumber(L, My);
  lua_pushnumber(L, Mx);
  Result := 2;
end;

//改变主地图坐标

function SetMainMapPosition(L: Plua_state): integer; cdecl;
begin
  Mx := floor(lua_tonumber(L, -1));
  My := floor(lua_tonumber(L, -2));
  Result := 0;
end;

//获取场景坐标

function GetScenePosition(L: Plua_state): integer; cdecl;
begin
  lua_pushnumber(L, Sy);
  lua_pushnumber(L, Sx);
  Result := 2;
end;

//改变场景坐标

function SetScenePosition(L: Plua_state): integer; cdecl;
begin
  Sx := floor(lua_tonumber(L, -1));
  Sy := floor(lua_tonumber(L, -2));
  Result := 0;
end;

function GetSceneFace(L: Plua_state): integer; cdecl;
begin
  lua_pushnumber(L, SFace);
  Result := 1;
end;

function SetSceneFace(L: Plua_state): integer; cdecl;
begin
  Sface := floor(lua_tonumber(L, -1));
  Result := 0;
end;

//延时

function Delay(L: Plua_state): integer; cdecl;
begin
  sdl_delay(floor(lua_tonumber(L, -1)));
  Result := 0;
end;

//绘制矩形

function DrawRect(L: Plua_state): integer; cdecl;
var
  n, i: integer;
  x: array of integer;
begin
  n := lua_gettop(L);
  setlength(x, n);
  for i := 0 to n - 1 do
  begin
    x[i] := floor(lua_tonumber(L, -(n - i)));
  end;
  Result := 0;
  if n = 7 then
    DrawRectangle(x[0], x[1], x[2], x[3], colcolor(x[4]), colcolor(x[5]), x[6]);
  if n = 6 then
    DrawRectangleWithoutFrame(x[0], x[1], x[2], x[3], colcolor(x[4]), x[5]);
  Result := 0;

end;

//队伍人数

function MemberAmount(L: Plua_state): integer; cdecl;
var
  n, i: integer;
begin
  n := 0;
  for i := 0 to 5 do
  begin
    if TeamList[i] >= 0 then
      n := n + 1;
  end;

  lua_pushnumber(L, n);
  Result := 1;

end;

//读队伍信息

function GetMember(L: Plua_state): integer; cdecl;
begin
  lua_pushnumber(L, TeamList[floor(lua_tonumber(L, -1))]);
  Result := 1;

end;

//写队伍信息

function PutMember(L: Plua_state): integer; cdecl;
begin
  TeamList[floor(lua_tonumber(L, -1))] := floor(lua_tonumber(L, -2));
  Result := 0;

end;

//读人物信息

function GetRolePro(L: Plua_state): integer; cdecl;
begin
  lua_pushnumber(L, Rrole[floor(lua_tonumber(L, -2))].Data[floor(lua_tonumber(L, -1))]);
  Result := 1;

end;

//写人物信息

function PutRolePro(L: Plua_state): integer; cdecl;
begin
  Rrole[floor(lua_tonumber(L, -2))].Data[floor(lua_tonumber(L, -1))] := floor(lua_tonumber(L, -3));
  Result := 0;

end;

//读物品信息

function GetItemPro(L: Plua_state): integer; cdecl;
begin
  lua_pushnumber(L, Ritem[floor(lua_tonumber(L, -2))].Data[floor(lua_tonumber(L, -1))]);
  Result := 1;

end;

//写物品信息

function PutItemPro(L: Plua_state): integer; cdecl;
begin
  Ritem[floor(lua_tonumber(L, -2))].Data[floor(lua_tonumber(L, -1))] := floor(lua_tonumber(L, -3));
  Result := 0;

end;

//读武功信息

function GetMagicPro(L: Plua_state): integer; cdecl;
begin
  lua_pushnumber(L, Rmagic[floor(lua_tonumber(L, -2))].Data[floor(lua_tonumber(L, -1))]);
  Result := 1;

end;

//写武功信息

function PutMagicPro(L: Plua_state): integer; cdecl;
begin
  Rmagic[floor(lua_tonumber(L, -2))].Data[floor(lua_tonumber(L, -1))] := floor(lua_tonumber(L, -3));
  Result := 0;

end;

//读场景信息

function GetScenePro(L: Plua_state): integer; cdecl;
begin
  lua_pushnumber(L, RScene[floor(lua_tonumber(L, -2))].Data[floor(lua_tonumber(L, -1))]);
  Result := 1;

end;

//写场景信息

function PutScenePro(L: Plua_state): integer; cdecl;
begin
  RScene[floor(lua_tonumber(L, -2))].Data[floor(lua_tonumber(L, -1))] := floor(lua_tonumber(L, -3));
  Result := 0;

end;

//读场景图信息

function GetSceneMapPro(L: Plua_state): integer; cdecl;
begin
  lua_pushnumber(L, sdata[floor(lua_tonumber(L, -4)), floor(lua_tonumber(L, -3)),
    floor(lua_tonumber(L, -2)), floor(lua_tonumber(L, -1))]);
  Result := 1;

end;

//写场景图信息

function PutSceneMapPro(L: Plua_state): integer; cdecl;
begin
  sdata[floor(lua_tonumber(L, -4)), floor(lua_tonumber(L, -3)), floor(lua_tonumber(L, -2)),
    floor(lua_tonumber(L, -1))] := floor(lua_tonumber(L, -5));
  Result := 0;

end;

//读场景事件信息

function GetSceneEventPro(L: Plua_state): integer; cdecl;
begin
  lua_pushnumber(L, ddata[floor(lua_tonumber(L, -3)), floor(lua_tonumber(L, -2)), floor(lua_tonumber(L, -1))]);
  Result := 1;

end;

//写场景事件信息

function PutSceneEventPro(L: Plua_state): integer; cdecl;
begin
  ddata[floor(lua_tonumber(L, -3)), floor(lua_tonumber(L, -2)), floor(lua_tonumber(L, -1))] :=
    floor(lua_tonumber(L, -4));
  Result := 0;

end;

function JudgeSceneEvent(L: Plua_state): integer; cdecl;
var
  t: integer;
begin
  t := 0;
  if DData[CurScene, floor(lua_tonumber(L, -3)), 2 + floor(lua_tonumber(L, -2))] = floor(lua_tonumber(L, -1)) then
    t := 1;
  lua_pushnumber(L, t);
  Result := 1;
end;

function PlayMusic(L: Plua_state): integer; cdecl;
begin
  instruct_66(floor(lua_tonumber(L, -1)));
  Result := 0;
end;

function PlayWave(L: Plua_state): integer; cdecl;
begin
  instruct_67(floor(lua_tonumber(L, -1)));
  Result := 0;
end;

function WalkFromTo(L: Plua_state): integer; cdecl;
var
  x1, x2, y1, y2: integer;
begin
  x1 := floor(lua_tonumber(L, -4));
  y1 := floor(lua_tonumber(L, -3));
  x2 := floor(lua_tonumber(L, -2));
  y2 := floor(lua_tonumber(L, -1));
  instruct_30(x1, y1, x2, y2);
  Result := 0;

end;

function SceneFromTo(L: Plua_state): integer; cdecl;
var
  x1, x2, y1, y2: integer;
begin
  x1 := floor(lua_tonumber(L, -4));
  y1 := floor(lua_tonumber(L, -3));
  x2 := floor(lua_tonumber(L, -2));
  y2 := floor(lua_tonumber(L, -1));
  instruct_25(x1, x2, y1, y2);
  Result := 0;

end;

function PlayAnimation(L: Plua_state): integer; cdecl;
var
  t, i1, i2: integer;
begin
  t := floor(lua_tonumber(L, -3));
  i1 := floor(lua_tonumber(L, -2));
  i2 := floor(lua_tonumber(L, -1));
  instruct_27(t, i1, i2);
  Result := 0;

end;

function GetNameAsString(L: Plua_state): integer; cdecl;
var
  str: string;
  typenum, num: integer;
  p1: PChar;
begin
  typenum := floor(lua_tonumber(L, -2));
  num := floor(lua_tonumber(L, -1));
  case typenum of
    0: p1 := @Rrole[num].Name;
    1: p1 := @Ritem[num].Name;
    2: p1 := @RScene[num].Name;
    3: p1 := @Rmagic[num].Name;
  end;
  str := gbktounicode(p1);
  lua_pushstring(L, @str[1]);
  Result := 1;

end;

function ChangeScene(L: Plua_state): integer; cdecl;
var
  x, y, n: integer;
begin
  n := lua_gettop(L);
  CurScene := floor(lua_tonumber(L, -n));
  if n = 1 then
  begin
    x := RScene[CurScene].EntranceX;
    y := RScene[CurScene].EntranceY;
  end
  else
  begin
    x := floor(lua_tonumber(L, -n + 1));
    y := floor(lua_tonumber(L, -n + 2));
  end;
  Cx := x + Cx - Sx;
  Cy := y + Cy - Sy;
  Sx := x;
  Sy := y;
  instruct_14;
  InitialScene;
  DrawScene;
  instruct_13;
  ShowSceneName(CurScene);
  CheckEvent3;
  Result := 0;

end;

function ShowPicture(L: Plua_state): integer; cdecl;
var
  t, p, n, x, y: integer;
begin
  n := lua_gettop(L);
  x := floor(lua_tonumber(L, -2));
  y := floor(lua_tonumber(L, -1));
  if n = 4 then
  begin
    t := floor(lua_tonumber(L, -4));
    p := floor(lua_tonumber(L, -3));
    case t of
      0: DrawMPic(p, x, y, 0);
      1: DrawSPic(p, x, y, 0, 0, screen.w, screen.h);
      2: DrawBPic(p, x, y, 0);
      3: DrawHeadPic(p, x, y);
      // 4: DrawEPic(p, x, y);
      //5:
    end;
  end;
  if n = 3 then
  begin
    display_img(lua_tostring(L, -3), x, y);
  end;
  Result := 0;

end;

function GetItemList(L: Plua_state): integer; cdecl;
var
  i: integer;
begin
  i := floor(lua_tonumber(L, -1));
  lua_pushnumber(L, RItemList[i].Number);
  lua_pushnumber(L, RItemList[i].Amount);
  Result := 2;
end;

function GetCurrentScene(L: Plua_state): integer; cdecl;
begin
  lua_pushnumber(L, CurScene);
  Result := 1;

end;

function GetCurrentEvent(L: Plua_state): integer; cdecl;
begin
  lua_pushnumber(L, CurEvent);
  Result := 1;

end;

//取得战斗序号

function GetBattleNumber(L: Plua_state): integer; cdecl;
var
  n, i, rnum, t: integer;
begin
  n := lua_gettop(L);
  if n = 0 then
    lua_pushnumber(L, x50[28005]);
  if n = 1 then
  begin
    rnum := floor(lua_tonumber(L, -1));
    t := -1;
    for i := 0 to length(brole) - 1 do
    begin
      if Brole[i].rnum = rnum then
      begin
        t := i;
        break;
      end;
    end;
    lua_pushnumber(L, t);
  end;
  Result := 1;

end;

//获取光标位置

function GetAimPosition(L: Plua_state): integer; cdecl;
begin
  lua_pushnumber(L, Ax);
  lua_pushnumber(L, Ay);
  Result := 2;
end;

//选择目标

function SelectOneAim(L: Plua_state): integer; cdecl;
begin
  if floor(lua_tonumber(L, -1)) = 0 then
    selectaim(floor(lua_tonumber(L, -3)), floor(lua_tonumber(L, -2)));
  lua_pushnumber(L, bfield[2, Ax, Ay]);
  Result := 1;
end;

//取战斗属性

function GetBattlePro(L: Plua_state): integer; cdecl;
begin
  lua_pushnumber(L, Brole[floor(lua_tonumber(L, -2))].Data[floor(lua_tonumber(L, -1))]);
  Result := 1;

end;

//写战斗属性

function PutBattlePro(L: Plua_state): integer; cdecl;
begin
  Brole[floor(lua_tonumber(L, -2))].Data[floor(lua_tonumber(L, -1))] := floor(lua_tonumber(L, -3));
  Result := 0;

end;

function PlayAction(L: Plua_state): integer; cdecl;
var
  n, bnum, mtype, enum, big, lv: integer;
begin
  n := lua_gettop(L);
  big := 0;
  lv := 0;
  if n = 3 then
  begin
    bnum := floor(lua_tonumber(L, -3));
    mtype := floor(lua_tonumber(L, -2));
    enum := floor(lua_tonumber(L, -1));
  end
  else if n = 4 then
  begin
    bnum := floor(lua_tonumber(L, -4));
    mtype := floor(lua_tonumber(L, -3));
    enum := floor(lua_tonumber(L, -2));
    big := floor(lua_tonumber(L, -1));
  end
  else
  begin
    bnum := floor(lua_tonumber(L, -5));
    mtype := floor(lua_tonumber(L, -4));
    enum := floor(lua_tonumber(L, -3));
    big := floor(lua_tonumber(L, -2));
    lv := floor(lua_tonumber(L, -1));
  end;
  playActionAmination(bnum, mtype);
  playMagicAmination(bnum, big, enum, lv);
  Result := 0;

end;

//function GetRoundNumber(L: Plua_state): integer; cdecl;

function PlayHurtValue(L: Plua_state): integer; cdecl;
var
  mode: integer;
begin
  mode := floor(lua_tonumber(L, -1));
  showhurtvalue(mode);
  Result := 0;

end;

function SetAminationLayer(L: Plua_state): integer; cdecl;
var
  x, y, w, h, t, i1, i2: integer;
begin
  x := floor(lua_tonumber(L, -5));
  y := floor(lua_tonumber(L, -4));
  w := floor(lua_tonumber(L, -3));
  h := floor(lua_tonumber(L, -2));
  t := floor(lua_tonumber(L, -1));

  for i1 := x to x + w - 1 do
    for i2 := y to y + h - 1 do
      bfield[4, i1, i2] := t;

  Result := 0;

end;

function ClearRoleFromBattle(L: Plua_state): integer; cdecl;
var
  t: integer;
begin
  t := floor(lua_tonumber(L, -1));
  Brole[t].Dead := 1;
  Result := 0;

end;

function AddRoleIntoBattle(L: Plua_state): integer; cdecl;
var
  rnum, team, x, y, bnum: integer;
begin
  bnum := broleamount;
  broleamount := broleamount + 1;
  team := floor(lua_tonumber(L, -4));
  rnum := floor(lua_tonumber(L, -3));
  x := floor(lua_tonumber(L, -2));
  y := floor(lua_tonumber(L, -1));

  Brole[bnum].rnum := rnum;
  Brole[bnum].Team := team;
  Brole[bnum].X := x;
  Brole[bnum].Y := y;
  Brole[bnum].Face := 1;
  Brole[bnum].Dead := 0;
  Brole[bnum].Step := 0;
  Brole[bnum].Acted := 1;
  Brole[bnum].ShowNumber := -1;
  Brole[bnum].ExpGot := 0;

  lua_pushnumber(L, bnum);
  Result := 1;

end;

//强制设置战斗结果

function ForceBattleResult(L: Plua_state): integer; cdecl;
begin
  Bstatus := floor(lua_tonumber(L, -1));
  Result := 0;
end;



function GetMagicLv(L: Plua_state): integer; cdecl;
begin
  lua_pushnumber(L, getmagiclevel(floor(lua_tonumber(L, -2)), floor(lua_tonumber(L, -1))));
  Result := 1;
end;


function HaveMagicLv(L: Plua_state): integer; cdecl;
var
  h: boolean;
begin
  h := havemagic(floor(lua_tonumber(L, -3)), floor(lua_tonumber(L, -2)), floor(lua_tonumber(L, -1)));
  if h then lua_pushnumber(L, 1)
  else lua_pushnumber(L, 0);
  Result := 1;
end;

function KGTalk(L: Plua_state): integer; cdecl;
var
  frame, alen, headnum, namenum, place, showhead, color, newcolor, color1, color2, nh, nw,
  ch, c1, r1, n, namelen, i, t1, grp, idx, offset, len, i1, i2, face, c, nx, ny, hx, hy, hw,
  hh, x, y, w, h, cell, row: integer;
  np3, np, np1, np2, tp, p1, ap: PChar;
  actorarray, name1, name2, namearray: array of byte;
  pword: array[0..1] of Uint16;
  str, Name: string;
  namestr: WideString;
  wd: string;
begin

  n := lua_gettop(L);

  if n = 7 then
  begin
    frame := 0;
    headnum := floor(lua_tonumber(L, -7));
    str := lua_tostring(L, -6);
    Name := lua_tostring(L, -5);
    place := floor(lua_tonumber(L, -4));
    showhead := floor(lua_tonumber(L, -3));
    frame := floor(lua_tonumber(L, -2));
    color := floor(lua_tonumber(L, -1));
    case color of
      0: color := 28515;
      1: color := 28421;
      2: color := 28435;
      3: color := 28563;
      4: color := 28466;
      5: color := 28450;
    end;
  end
  else if n = 8 then
  begin
    headnum := floor(lua_tonumber(L, -8));
    str := lua_tostring(L, -7);
    Name := lua_tostring(L, -6);
    place := floor(lua_tonumber(L, -5));
    showhead := floor(lua_tonumber(L, -4));
    frame := floor(lua_tonumber(L, -3));
    color1 := floor(lua_tonumber(L, -2));
    color2 := floor(lua_tonumber(L, -1));
    color := uint16(color1 or uint16(color2 shl 8));
  end;
  str := (str + #0);
  frame := colcolor(frame);
  pword[1] := 0;
  face := 4900;
  color1 := color and $FF;
  color2 := uint16((color shr 8) and $FF);
  x := 68;
  y := 320;
  w := 511;
  h := 109;
  nw := 86;
  nh := 28;
  hx := 68;
  hy := 257;
  hw := 57;
  hh := 59;
  nx := 129;
  ny := 288;
  row := 5;
  cell := 25;
  if place = 1 then
  begin
    hx := 522;
    nx := 432;
  end;
  //read talk
  namenum := -2;
  //read name
  try
    namenum := StrToInt(Name);
    if namenum > 0 then
    begin
      idx := fileopen(AppPath + NAME_IDX, fmopenread);
      grp := fileopen(AppPath + NAME_GRP, fmopenread);
      fileseek(idx, (namenum - 1) * 4, 0);
      fileread(idx, offset, 4);
      fileread(idx, namelen, 4);

      namelen := (namelen - offset);

      setlength(namearray, namelen + 1);
      fileseek(grp, offset, 0);
      fileread(grp, namearray[0], namelen);
      fileclose(idx);
      fileclose(grp);
      for i := 0 to namelen - 2 do
      begin
        namearray[i] := namearray[i] xor $FF;
        if (namearray[i] = $2A) then
          namearray[i] := 0;
      end;
      namearray[i] := 0;
      np := @namearray[0];
    end
    else if namenum = -2 then
    begin
      for i := 0 to length(rrole) - 1 do
      begin
        if Rrole[i].HeadNum = headnum then
        begin
          p1 := @Rrole[i].Name;
          namelen := length(p1) + 2;
          setlength(namearray, namelen);
          np := @namearray[0];
          for n := 0 to namelen - 3 do
          begin
            (np + n)^ := (p1 + n)^;
            if (p1 + n)^ = char(0) then break;
          end;
          (np + n)^ := char(0);
          (np + n + 1)^ := char(0);
          break;
        end;
      end;
    end;
  except
    namestr := Simplified2Traditional(WideString(Name));
    Name := unicodetogbk(@namestr[1]);
    np := @Name[1];
  end;
  p1 := @Rrole[0].Name;
  alen := length(p1) + 2;
  setlength(actorarray, alen);
  ap := @actorarray[0];
  for n := 0 to alen - 1 do
  begin
    (ap + n)^ := (p1 + n)^;
    if (p1 + n)^ = char(0) then break;
  end;
  (ap + n)^ := char($0);
  (ap + n + 1)^ := char(0);




  if alen = 6 then
  begin
    setlength(name1, 4);
    np1 := @name1[0];
    np1^ := ap^;
    (np1 + 1)^ := (ap + 1)^;
    (np1 + 2)^ := char(0);
    (np1 + 3)^ := char(0);
    setlength(name2, 4);
    np2 := @name2[0];
    np2^ := ap^;
    for i := 0 to length(name2) - 1 do
      (np2 + i)^ := (ap + i + 2)^;
  end
  else if alen > 8 then
  begin
    setlength(name1, 6);
    np1 := @name1[0];
    np1^ := ap^;
    (np1 + 1)^ := (ap + 1)^;
    (np1 + 2)^ := (ap + 2)^;
    (np1 + 3)^ := (ap + 3)^;
    (np1 + 4)^ := char(0);
    (np1 + 5)^ := char(0);
    setlength(name2, 6);
    np2 := @name2[0];
    for i := 0 to length(name2) - 1 do
      (np2 + i)^ := (ap + i + 4)^;
  end
  else if alen = 8 then
  begin
    if ((puint16(ap)^ = $6EAB) and ((puint16(ap + 2)^ = $63AE))) or
      ((puint16(ap)^ = $E8A6) and ((puint16(ap + 2)^ = $F9AA))) or ((puint16(ap)^ = $46AA) and
      ((puint16(ap + 2)^ = $E8A4))) or ((puint16(ap)^ = $4FA5) and ((puint16(ap + 2)^ = $B0AA))) or
      ((puint16(ap)^ = $7DBC) and ((puint16(ap + 2)^ = $65AE))) or ((puint16(ap)^ = $71A5) and
      ((puint16(ap + 2)^ = $A8B0))) or ((puint16(ap)^ = $D1BD) and ((puint16(ap + 2)^ = $AFB8))) or
      ((puint16(ap)^ = $71A5) and ((puint16(ap + 2)^ = $C5AA))) or ((puint16(ap)^ = $D3A4) and
      ((puint16(ap + 2)^ = $76A5))) or ((puint16(ap)^ = $BDA4) and ((puint16(ap + 2)^ = $5DAE))) or
      ((puint16(ap)^ = $DABC) and ((puint16(ap + 2)^ = $A7B6))) or ((puint16(ap)^ = $43AD) and
      ((puint16(ap + 2)^ = $DFAB))) or ((puint16(ap)^ = $71A5) and ((puint16(ap + 2)^ = $7BAE))) or
      ((puint16(ap)^ = $B9A7) and ((puint16(ap + 2)^ = $43C3))) or ((puint16(ap)^ = $61B0) and
      ((puint16(ap + 2)^ = $D5C1))) or ((puint16(ap)^ = $74A6) and ((puint16(ap + 2)^ = $E5A4))) or
      ((puint16(ap)^ = $DDA9) and ((puint16(ap + 2)^ = $5BB6))) then
    begin
      setlength(name1, 6);
      np1 := @name1[0];
      np1^ := ap^;
      (np1 + 1)^ := (ap + 1)^;
      (np1 + 2)^ := (ap + 2)^;
      (np1 + 3)^ := (ap + 3)^;
      (np1 + 4)^ := char(0);
      (np1 + 5)^ := char(0);
      setlength(name2, 4);
      np2 := @name2[0];
      for i := 0 to length(name2) - 1 do
        (np2 + i)^ := (ap + i + 4)^;
    end
    else
    begin
      setlength(name1, 4);
      np1 := @name1[0];
      np1^ := ap^;
      (np1 + 1)^ := (ap + 1)^;
      (np1 + 2)^ := char(0);
      (np1 + 3)^ := char(0);
      setlength(name2, 6);
      np2 := @name2[0];
      for i := 0 to length(name2) - 1 do
        (np2 + i)^ := (ap + i + 2)^;
    end;
  end;

  setlength(wd, 0);
  i := 0;
  while i < length(str) do
  begin
    setlength(wd, length(wd) + 1);
    wd[length(wd) - 1] := str[i];
    if (integer(str[i]) in [$81..$FE]) and (integer(str[i + 1]) <> $7E) then
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

  tp := @wd[1];
  ch := 0;

  while ((puint16(tp + ch))^ and $FF <> 0) and ((puint16(tp + ch))^ and $FF00 <> 0) do
  begin
    c1 := 0;
    r1 := 0;
    redraw;
    DrawRectangle(x, y, w, h, frame, $FFFFFF, 60);
    if showhead = 0 then
    begin
      DrawRectangle(hx, hy, hw, hh, frame, $FFFFFF, 60);
      DrawHeadPic(headnum, hx, hy + 57);
    end;
    if namenum <> 0 then
    begin
      DrawRectangle(nx, ny, nw, nh, frame, $FFFFFF, 60);
      namelen := length(np);
      DrawgbkShadowText(np, nx + 20 - namelen * 9 div 2, ny + 4, colcolor($63), colcolor($70));
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
          color2 := smallint((newcolor shr 8) and $FF);
        end
        else if pword[0] = $2323 then //## 延时
        begin
          sdl_delay((500 * GameSpeed) div 10);
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
          waitanykey;
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
            DrawgbkShadowText(@pword[0], x - 14 + CHINESE_FONT_SIZE * c1, y + 4 + CHINESE_FONT_SIZE *
              r1, colcolor(color1), colcolor(color2));
            Inc(c1);
            if c1 = cell then
            begin
              c1 := 0;
              Inc(r1);
              if r1 = row then
              begin
                SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
                waitanykey;
                c1 := 0;
                r1 := 0;
                redraw;
                DrawRectangle(x, y, w, h, frame, $FFFFFF, 60);
                if showhead = 0 then
                begin
                  DrawRectangle(hx, hy, hw, hh, frame, $FFFFFF, 60);
                  DrawHeadPic(headnum, hx, hy + 57);
                end;
                if namenum <> 0 then
                begin
                  DrawRectangle(nx, ny, nw, nh, frame, $FFFFFF, 60);
                  namelen := length(np);
                  DrawgbkShadowText(np, nx + 20 - namelen * 9 div 2, ny + 4, colcolor($63), colcolor($70));
                end;
              end;
            end;
          end;
        end
        else //显示文字
        begin
          DrawGBKShadowText(@pword[0], x - 14 + CHINESE_FONT_SIZE * c1, y + 4 + CHINESE_FONT_SIZE *
            r1, colcolor(color1), colcolor(color2));
          Inc(c1);
          if c1 = cell then
          begin
            c1 := 0;
            Inc(r1);
          end;
        end;
      end
      else break;
    end;
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    waitanykey;
    if (pword[0] and $FF = 0) or (pword[0] and $FF00 = 0) then break;
  end;
  redraw;
  Result := 0;
  setlength(wd, 0);
  setlength(str, 0);
end;


function ReName(L: Plua_state): integer; cdecl;
var
  inum, t: integer;
  NewName: string;
  len, i: integer;
  words: WideString;
  p: PChar;
  str1: WideString;
begin
  inum := floor(lua_tonumber(L, -2));
  t := floor(lua_tonumber(L, -3));
  NewName := lua_tostring(L, -1);

{$IFDEF fpc}
  str1 := UTF8Decode(CP936ToUTF8(NewName));
{$ELSE}
  len := MultiByteToWideChar(936, 0, PChar(NewName), -1, nil, 0);
  setlength(str1, len - 1);
  MultiByteToWideChar(936, 0, PChar(NewName), length(NewName), pwidechar(str1), len + 1);
{$ENDIF}



  words := Simplified2Traditional(str1);
  NewName := unicodetogbk(@words[1]);
  case t of
    0: p := @RRole[inum].Name; //人物
    1: p := @RItem[inum].Name; //物品
    2: p := @RScene[inum].Name; //场景
    3: p := @RMagic[inum].Name; //武功
    4: p := @RItem[inum].Introduction; //物品说明
  end;

  for i := 0 to length(NewName) - 1 do
  begin
    (p + i)^ := (PChar(NewName) + i)^;
  end;
  (p + i)^ := char(0);

  Result := 0;

end;



function PutLine(L: Plua_state): integer; cdecl;
var
  x1, x2, y1, y2, color, w: integer;
begin
  x1 := floor(lua_tonumber(L, -6));
  y1 := floor(lua_tonumber(L, -5));
  x2 := floor(lua_tonumber(L, -4));
  y2 := floor(lua_tonumber(L, -3));
  color := floor(lua_tonumber(L, -2));
  w := floor(lua_tonumber(L, -1));
  DrawLine(x1, y1, x2, y2, colcolor(color), w);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

  Result := 0;

end;

function ShowBanner(L: Plua_state): integer; cdecl;
var
  x1, y1, ch, color1, color2, color, c1, r1, n, namelen, i, t1, grp, idx, offset, len, i1,
  i2, face, c, x, y, w, h, cell, row: integer;
  tp: PChar;
  str: string;
  pword: array[0..1] of Uint16;
  wd: string;
begin

  str := lua_tostring(L, -2);
  color := floor(lua_tonumber(L, -1));
  str := str + #0;
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
  color2 := (color shr 0) and $FF;
  x := 0;
  y := 30;
  w := 640;
  h := 109;
  row := 5;
  cell := 25;
  //read talk

  puint16(tp + length(tp))^ := uint16(0);
  pword[1] := 0;
  ch := 0;
  if length(tp) > cell * 2 then
  begin
    x1 := 300 - cell * 10;
  end
  else x1 := 300 - length(tp) * 5;
  if ((length(tp) div 2) > cell * row) then
  begin
    y1 := y + (h div 2) - 50;
  end
  else y1 := y + (h div 2) - 10 - ((length(tp) div 2) div cell) * 10;

  setlength(wd, 0);
  i := 0;
  while i < length(str) do
  begin
    setlength(wd, length(wd) + 1);
    wd[length(wd) - 1] := str[i];
    if (integer(str[i]) in [$81..$FE]) and (integer(str[i + 1]) <> $7E) then
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
  tp := @wd[1];
  while ((puint16(tp + ch))^ shl 8 <> 0) and ((puint16(tp + ch))^ shr 8 <> 0) do
  begin
    redraw;
    c1 := 0;
    r1 := 0;
    DrawRectangleWithoutFrame(x, y, w, h, 0, 40);
    while r1 < row do
    begin
      pword[0] := (puint16(tp + ch))^;
      if (pword[0] shr 8 <> 0) and (pword[0] shl 8 <> 0) then
      begin
        ch := ch + 2;

        //显示文字
        DrawGBKShadowText(@pword[0], x1 + CHINESE_FONT_SIZE * c1, y1 + CHINESE_FONT_SIZE *
          r1, colcolor(color1), colcolor(color2));
        Inc(c1);
        if c1 = cell then
        begin
          c1 := 0;
          Inc(r1);
          DrawRectangleWithoutFrame(x, y + h + 11 * (r1 - 1) + 1, w, 10, 0, 40);
        end;
      end
      else break;
    end;
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    waitanykey;
  end;
  redraw;
  Result := 0;
  setlength(wd, 0);
  setlength(str, 0);
end;
//设置场景环境

function SetSceneMode(L: Plua_state): integer; cdecl;
var
  MapMode, SceneNum: integer;
begin
  MapMode := floor(lua_tonumber(L, -1));

  SceneNum := floor(lua_tonumber(L, -2));
  if SceneNum < 0 then SceneNum := curScene;

  RScene[SceneNum].Mapmode := Mapmode;

  Result := 0;

end;
//设置场景调色板

function SetScenePallet(L: Plua_state): integer; cdecl;
var
  MapCol, SceneNum: integer;
begin
  MapCol := floor(lua_tonumber(L, -1));

  SceneNum := floor(lua_tonumber(L, -2));
  if SceneNum < 0 then SceneNum := curScene;

  RScene[SceneNum].Pallet := MapCol;

  Result := 0;

end;
//设置定时事件

function SetTimeEvent(L: Plua_state): integer; cdecl;
var
  Settime, time_event: integer;
begin
  timeevent := floor(lua_tonumber(L, -1));

  Settime := floor(lua_tonumber(L, -2));
  if (Settime <= 0) or (time_event <= 0) then
  begin
    Settime := -1;
    time_event := -1;
  end;

  time := SetTime;
  TimeEvent := time_event;

  Result := 0;

end;
//设置随机事件

function SetRandomEvent(L: Plua_state): integer; cdecl;
var
  Random_event: integer;
begin
  Random_Event := floor(lua_tonumber(L, -1));
  if Random_Event <= 0 then
  begin
    Random_Event := -1;
  end;
  RandomEvent := Random_Event;
  Result := 0;

end;

function UpdateScreen(L: Plua_state): integer; cdecl;
var
  n, i: integer;
  x: array of integer;
begin
  n := lua_gettop(L);
  setlength(x, n);
  for i := 0 to n - 1 do
  begin
    x[i] := floor(lua_tonumber(L, -(n - i)));
  end;
  SDL_UpdateRect2(screen, x[0], x[1], x[2], x[3]);
  Result := 0;

end;

function shotbird(L: Plua_state): integer; cdecl;
var
  aim, chance, r: integer;
begin
  chance := floor(lua_tonumber(L, -1));
  aim := floor(lua_tonumber(L, -2));
  r := 0;
  if shoteagle(aim, chance) then
  begin
    r := 1;
  end;
  lua_pushnumber(L, r);
  Result := 1;

end;


function pintu(L: Plua_state): integer; cdecl;
var
  num, chance, r: integer;
begin
  chance := floor(lua_tonumber(L, -1));
  num := floor(lua_tonumber(L, -2));
  r := 0;
  if rotospellpicture(num, chance) then
  begin
    r := 1;
  end;
  lua_pushnumber(L, r);
  Result := 1;

end;

end.
