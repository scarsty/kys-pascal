unit kys_littlegame;

//{$MODE Delphi}

interface
uses
  SysUtils,

{$IFDEF fpc}
  LCLIntf, LCLType, LMessages, FileUtil,
{$ELSE}
  Windows,
{$ENDIF}

  Math,
  Dialogs,
  StrUtils,
  SDL,
  SDL_TTF,
  sdl_gfx,
  //SDL_mixer,
  SDL_image,
  kys_engine,
  kys_main;
function Acupuncture(n: integer): boolean;
function ShotEagle(aim, chance: integer): boolean;
function Poetry(talknum, chance, c, Count: integer): boolean;
function Lamp(c, beginpic, whitecount, chance: integer): boolean;
function rotoSpellPicture(num, chance: integer): boolean;
function FemaleSnake: integer;
function movesnake(Edest: integer): integer;
procedure randomsnake;
//special function in VB,equal to "if... then... else endif"
function iif(Condition: boolean; TrueReturn, FalseReturn: integer): integer;


var
  background, snakepic, Weipic: tpic;
  femalepic: array[0..7] of tpic;
  EatFemale: integer;
implementation
uses kys_event;
function FemaleSnake: integer;

var
  iskey: boolean;
  //MaxX,MaxY: integer;
  //x, y :integer ;
  timelong, ori_time, now: uint32;
  //flag: boolean;
  i, j, grp, delay: integer;
begin
  Result := 0;
  EatFemale := 0;
  if (FileExistsUTF8(AppPath + GAME_file) { *Converted from FileExists*  }) then
  begin
    grp := fileopen(AppPath + GAME_file, fmopenread);
    background := GetPngPic(grp, 4);
    snakepic := GetPngPic(grp, 5);
    Weipic := GetPngPic(grp, 6);
    for i := 0 to 7 do
      femalepic[i] := GetPngPic(grp, 7 + i);
    fileclose(grp);
  end;
  dest := 1;
  for i := 0 to 16 - 1 do
    for j := 0 to 10 - 1 do
      drawpngpic(background, 40 * i, 40 * j, 0);

  //original length
  setlength(snake, 8);
  snake[0].x := 1;
  snake[0].y := 0;
  drawpngpic(Weipic, 40 * snake[0].x, 40 * snake[0].y, 0);
  for i := 1 to length(snake) - 1 do
  begin
    snake[i].x := 0;
    snake[i].y := 0;
    drawpngpic(snakepic, 40 * snake[i].x, 40 * snake[i].y, 0);
  end;
  randomsnake;

  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  ori_time := sdl_getticks;
  iskey := True;
  event.key.keysym.sym := SDLK_DOWN;
  delay := 120;
  if getpetskill(4, 2) then delay := 150;
  while SDL_PollEvent(@event) >= 0 do
  begin

    now := sdl_getticks;

    if (now - ori_time) >= delay then
    begin
      ori_time := sdl_getticks;
      if movesnake(dest) = 1 then
      begin
        waitanykey();
        break;
      end;
    end;
    case event.type_ of
      SDL_QUITEV:
      begin
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then
          Quit;
      end;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYDOWN:
      begin
        //now := sdl_getticks;
        //if (now - ori_time)>=100 then
        if iskey = True then
        begin
          //ori_time := sdl_getticks;
          iskey := False;
          case event.key.keysym.sym of
            SDLK_DOWN:
            begin
              if movesnake(2) = 1 then
              begin
                waitanykey();
                break;
              end;
            end;
            SDLK_UP:
            begin
              if movesnake(0) = 1 then
              begin
                waitanykey();
                break;
              end;
            end;
            SDLK_LEFT:
            begin
              if movesnake(3) = 1 then
              begin
                waitanykey();
                break;
              end;
            end;
            SDLK_RIGHT:
            begin
              if movesnake(1) = 1 then
              begin
                waitanykey();
                break;
              end;
            end;
            SDLK_kp2:
            begin
              if movesnake(2) = 1 then
              begin
                waitanykey();
                break;
              end;
            end;
            SDLK_kp8:
            begin
              if movesnake(0) = 1 then
              begin
                waitanykey();
                break;
              end;
            end;
            SDLK_kp4:
            begin
              if movesnake(3) = 1 then
              begin
                waitanykey();
                break;
              end;
            end;
            SDLK_kp6:
            begin
              if movesnake(1) = 1 then
              begin
                waitanykey();
                break;
              end;
            end;
          end;
        end;
      end;
      SDL_KEYUP:
      begin
        iskey := True;
      end;
    end;
  end;
  //waitanykey;
  sdl_freesurface(background.pic);
  sdl_freesurface(snakepic.pic);
  sdl_freesurface(Weipic.pic);
  for i := 0 to 7 do
    sdl_freesurface(femalepic[i].pic);
  Result := eatfemale;
end;


function movesnake(Edest: integer): integer;
var
  //shift=edest
  i, j, k, l: integer;
begin
  for i := length(snake) - 1 downto 1 do
    snake[i] := snake[i - 1];
  Result := 0;
  l := 5; //吃到食物后增加的长度
  //get female
  if (snake[0].x = RANX) and (snake[0].y = RANY) then
  begin
    if eatfemale >= 7 then l := 1;
    setlength(snake, length(snake) + l);
    Inc(EatFemale);
    for i := 1 to l do
    begin
      snake[length(snake) - i].x := snake[length(snake) - (l + 1)].x;
      snake[length(snake) - i].y := snake[length(snake) - (l + 1)].y;
    end;
    drawpngpic(snakepic, 40 * RANX, 40 * RANY, 0);
    randomsnake;
  end;
  //useless
  if abs(dest - Edest) = 2 then
    Edest := dest;
  case Edest of
    0:
    begin
      snake[0].y := iif(snake[0].y >= 0, snake[0].y - 1, 9);
    end;
    1:
    begin
      snake[0].x := IIf(snake[0].x < 15, snake[0].x + 1, 15);
    end;
    2:
    begin
      snake[0].y := IIf(snake[0].y < 9, snake[0].y + 1, 9);
    end;
    3:
    begin
      snake[0].x := IIf(snake[0].x >= 0, snake[0].x - 1, 15);
    end;
  end;

  drawpngpic(background, 40 * snake[length(snake) - 1].x, 40 * snake[length(snake) - 1].y, 0);
  drawpngpic(Weipic, 40 * snake[0].x, 40 * snake[0].y, 0);

  drawpngpic(snakepic, 40 * snake[1].x, 40 * snake[1].y, 0);

  //judge lose
  //if (snake[0].x > 32) or (snake[0].y > 20) then
  //   messagedlg('Are you sure to quit?', mtConfirmation, [mbOk, mbCancel], 0);
  for i := 1 to length(snake) - 1 do
  begin
    if ((snake[0].x = snake[i].x) and (snake[0].y = snake[i].y)) or (snake[0].x < 0) or
      (snake[0].x >= 16) or (snake[0].y < 0) or (snake[0].y >= 16) then
    begin //waitanykey;
      Result := 1;
    end;
  end;
  dest := Edest;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
end;

function iif(Condition: boolean; TrueReturn, FalseReturn: integer): integer;
begin
  if Condition then
    Result := TrueReturn
  else
    Result := FalseReturn;
end;

procedure randomsnake;
var
  i, j: integer;
begin
  j := 0;
  while (j <= 0) do
  begin
    j := 1;
    RANX := random(16);
    RANY := random(10);
    for i := 0 to length(snake) - 1 do
    begin
      if (RanX = snake[i].x) and (RanY = snake[i].y) then
      begin
        j := j - 1;
      end;
    end;
  end;
  if (eatfemale < 7) then
    drawpngpic(femalepic[EatFemale], 40 * RANX, 40 * RANY, 0)
  else
    drawpngpic(femalepic[7], 40 * RANX, 40 * RANY, 0);
  //messagedlg('Are you sure to quit?', mtConfirmation, [mbOk, mbCancel], 0);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
end;

function showarrow(arrowpic: psdl_surface; x, y, step: integer; degree: double): double;
var
  angle, r, x1, y1: double;
  srcrect: TSDL_Rect;
  dstrect: TSDL_Rect;
  newarrowpic: psdl_surface;
begin
  r := Math.Power(2 * Math.Power(arrowpic.h div 2, 2), 0.5);
  if (degree > 90) or (degree < -90) then
  begin
    angle := Math.ArcTan2((screen.h - y), x - screen.w div 2);
    degree := -(90 - Math.RadToDeg(angle));
  end;

  angle := Math.degtorad(abs(degree) - 45);
  x1 := r * cos(abs(angle));

  newarrowpic := sdl_gfx.rotozoomSurface(arrowpic, degree, 1, 1);
  dstrect.x := round((screen.w div 2) - abs(x1) - step * sin(degtorad(degree)));
  dstrect.y := round(screen.h - abs(x1) - step * cos(degtorad(degree)));
  dstrect.w := newarrowpic.w;
  dstrect.h := newarrowpic.h;
  SDL_SetColorKey(newarrowpic, SDL_SRCCOLORKEY, 0);
  // SDL_BlitSurface(bg, @dstrect, screen, @dstrect);
  SDL_BlitSurface(newarrowpic, nil, screen, @dstrect);
  sdl_freesurface(newarrowpic);
  Result := degree;
  // SDL_UpdateRect2(screen, dstrect.x, dstrect.y, dstrect.w, dstrect.h);
end;

function showbow(bowpic: psdl_surface; x, y: integer; degree: double): double;
var
  angle, r, x1, y1: double;
  srcrect: TSDL_Rect;
  dstrect: TSDL_Rect;
  newbowpic: psdl_surface;
begin
  r := Math.Power(2 * Math.Power(bowpic.h div 2, 2), 0.5);
  if (degree > 90) or (degree < -90) then
  begin
    angle := Math.ArcTan2((screen.h - y), x - screen.w div 2);
    degree := -(90 - Math.RadToDeg(angle));
  end;
  angle := Math.degtorad(abs(degree) - 45);
  x1 := r * cos(abs(angle));

  newbowpic := sdl_gfx.rotozoomSurface(bowpic, degree, 1, 1);
  dstrect.x := round((screen.w div 2) - abs(x1));
  dstrect.y := round(screen.h - abs(x1));
  dstrect.w := newbowpic.w;
  dstrect.h := newbowpic.h;
  SDL_SetColorKey(newbowpic, SDL_SRCCOLORKEY, 0);
  // if bowstate=1 then SDL_BlitSurface(bg, @dstrect, screen, @dstrect);
  SDL_BlitSurface(newbowpic, nil, screen, @dstrect);
  sdl_freesurface(newbowpic);
  Result := degree;
  // SDL_UpdateRect2(screen, dstrect.x, dstrect.y, dstrect.w, dstrect.h);
end;

procedure showeagle(eaglepic: psdl_surface; birdx: integer);
var
  angle, degree, r, x1, y1: double;
  srcrect: TSDL_Rect;
  dstrect: TSDL_Rect;
  newbowpic: psdl_surface;
begin

  dstrect.x := 0;
  dstrect.y := 20;
  dstrect.w := screen.w;
  dstrect.h := eaglepic.h;
  //SDL_SetColorKey(newbowpic, SDL_SRCCOLORKEY, 0);
  //SDL_BlitSurface(bg, @dstrect, screen, @dstrect);
  dstrect.x := birdx - eaglepic.w div 2;
  dstrect.y := 20;
  dstrect.w := eaglepic.w;
  dstrect.h := eaglepic.h;
  SDL_BlitSurface(eaglepic, nil, screen, @dstrect);

end;

function CheckGoal(birdx, arrowstep: integer; degree: double): boolean;
var
  r, angle, x1: double;
  x, y: integer;
begin
  r := Math.Power(2 * Math.Power(50, 2), 0.5);
  //  angle := math.ArcTan2((screen.h - y), x - screen.w div 2);
  //degree := -(90 - math.RadToDeg(angle));
  angle := Math.degtorad(abs(degree) - 45);
  x1 := r * cos(abs(angle));
  x := round((screen.w div 2) - arrowstep * sin(degtorad(degree)) - 100 * sin(degtorad(degree)));
  y := round(screen.h - arrowstep * cos(degtorad(degree)) - 100 * cos(degtorad(degree)));
  Result := False;
  //drawrectangle(x-2,y-2,5,5,255,255,100);
  //drawrectangle(birdx-30,50,60,20,255,255,100);
  if (x > birdx - 20) and (x < birdx + 20) and (y > 35) and (y < 65) then
    Result := True;

end;

function ShotEagle(aim, chance: integer): boolean;
var
  birdspeed, birdstep, birdx, goal: integer;
  srcrect: TSDL_Rect;
  dstrect: TSDL_Rect;
  GamePic: Tpic;
  arrowpic: PSDL_Surface;
  EaglePic: array[0..1] of array[0..3] of PSDL_Surface;
  BowPic: array[0..1] of PSDL_Surface;
  bombpic: array[0..11] of PSDL_Surface;
  word: WideString;
  degree, arrowdegree: double;
  arrowspeed, arrowstep, i, i1, bombnum, j, len, grp, idx, readystate: integer; //accu is a value to accurate
  time: uint32;
begin
  if GetPetSkill(4, 2) then chance := chance * 2;
  arrowspeed := 6;
  goal := 0;
  arrowstep := 0;
  degree := 0;
  arrowdegree := 0;
  time := 0;
  readystate := 1;
  bombnum := -1;
  if (FileExistsUTF8(AppPath + GAME_file) { *Converted from FileExists*  }) then
  begin
    grp := fileopen(AppPath + GAME_file, fmopenread);

    Gamepic := GetPngPic(grp, 1);

    for i := 0 to 7 do
    begin
      EaglePic[i div 4][i mod 4] := SDL_CreateRGBSurface(screen.flags, 86, 65, 32, $FF0000, $FF00, $0FF, 0);
      srcrect.x := (i mod 4) * 86;
      srcrect.y := (i div 4) * 65;
      srcrect.w := 86;
      srcrect.h := 65;
      SDL_BlitSurface(Gamepic.pic, @srcrect, EaglePic[i div 4][i mod 4], nil);
      SDL_SetColorKey(EaglePic[i div 4][i mod 4], SDL_RLEACCEL or SDL_SRCCOLORKEY,
        getpixel(EaglePic[i div 4][i mod 4], 0, 0));
    end;
    for i := 0 to 1 do
    begin
      BowPic[i] := SDL_CreateRGBSurface(screen.flags, 220, 220, 32, $FF0000, $FF00, $0FF, 0);
      srcrect.x := i * 220;
      srcrect.y := 130;
      srcrect.w := 220;
      srcrect.h := 110;
      SDL_SetColorKey(BowPic[i], SDL_RLEACCEL or SDL_SRCCOLORKEY, 0);
      SDL_BlitSurface(Gamepic.pic, @srcrect, BowPic[i], nil);
    end;
    for i := 0 to 11 do
    begin
      BombPic[i] := SDL_CreateRGBSurface(screen.flags, 95, 88, 32, $FF0000, $FF00, $0FF, 0);
      srcrect.x := (i mod 6) * 95;
      srcrect.y := (i div 6) * 88 + 240;
      srcrect.w := 95;
      srcrect.h := 88;
      SDL_SetColorKey(BombPic[i], SDL_RLEACCEL or SDL_SRCCOLORKEY, 0);
      SDL_BlitSurface(Gamepic.pic, @srcrect, BombPic[i], nil);
    end;
    srcrect.x := 440;
    srcrect.y := 130;
    srcrect.w := 200;
    srcrect.h := 100;
    arrowpic := SDL_CreateRGBSurface(screen.flags, 200, 200, 32, $FF0000, $FF00, $0FF, 0);
    SDL_SetColorKey(arrowpic, SDL_RLEACCEL or SDL_SRCCOLORKEY, 0);
    SDL_BlitSurface(Gamepic.pic, @srcrect, arrowpic, nil);

    SDL_FreeSurface(gamepic.pic);
    Gamepic := GetPngPic(grp, 2);
    fileclose(grp);
  end;
  drawpngpic(Gamepic, 0, 0, 0);
  degree := showbow(bowpic[readystate], 320, 0, degree);
  birdspeed := round(power(-1, random(2))) * (20 + (random(30)));
  birdx := (420 - (EaglePic[0][0].w div 2)) + sign(birdspeed) * (-320);
  birdstep := 0;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  while SDL_PollEvent(@event) >= 0 do
  begin
    drawpngpic(Gamepic, 0, 0, 0);
    if goal >= aim then
    begin
      Result := True;
      waitanykey();
      break;
    end;
    if chance < 0 then
    begin
      Result := False;
      break;
    end;
    drawrectangle(5 - 1, 415 - 1, 75 + 2, 20 + 2, 0, $FFFFFF, 30);
    showeagle(EaglePic[1 - (1 + sign(birdspeed)) div 2][birdstep], birdx);
    if bombnum = -1 then
    begin
      time := time + 1;
      if (arrowstep > 0) and (time mod arrowspeed = 0) then
      begin
        arrowstep := arrowstep + 15;
      end;
      if (readystate = 0) and (time mod 10 = 0) then
      begin
        arrowspeed := arrowspeed - 1;
        if arrowspeed <= 1 then
        begin
          arrowspeed := 1;
          //   readystate := 1;
          //  arrowstep := arrowstep + arrowspeed ;
        end;
      end;

      if (readystate = 0) or (arrowstep > 0) then
      begin
        arrowdegree := showarrow(arrowpic, round(event.button.x / (RealScreen.w / screen.w)),
          round(event.button.y / (RealScreen.h / screen.h)), arrowstep, arrowdegree);
        drawrectangle(5, 415, (6 - arrowspeed) * 15, 20, $330000 * (6 - arrowspeed), $330000 * (6 - arrowspeed), 100);
        if checkgoaL(birdx, arrowstep, arrowdegree) then
        begin
          bombnum := 0;

        end;

        if round(arrowstep * (sqrt(2)) - 200) > screen.h then
        begin
          arrowstep := 0;
          arrowspeed := 6;
        end;
      end;
      // drawrectanglewithoutframe(5,420,(6-arrowspeed)*15,30,colcolor(0,15),100);

      if time mod 3 = 0 then
      begin
        birdx := birdx + birdspeed;
        birdstep := birdstep + 1;
        if birdstep > 3 then birdstep := 0;
        if ((sign(birdspeed) = 1) and (birdx - (EaglePic[0][0].w div 2) > screen.w + 20)) or
          ((sign(birdspeed) = -1) and (birdx + (EaglePic[0][0].w div 2) < 0)) then
        begin
          birdspeed := round(power(-1, random(2))) * (20 + (random(30)));
          birdx := (420 - (EaglePic[0][0].w div 2)) + sign(birdspeed) * (-320);
          birdstep := 0;
        end;

      end;

    end
    else
    begin
      if bombnum > 11 then
      begin
        arrowstep := 0;
        arrowspeed := 6;
        birdspeed := round(power(-1, random(2))) * (20 + (random(30)));
        birdx := (420 - (EaglePic[0][0].w div 2)) + sign(birdspeed) * (-320);
        birdstep := 0;
        bombnum := -1;
        Inc(goal);
      end
      else
      begin
        dstrect.x := birdx - bombpic[bombnum].w div 2;
        dstrect.y := 70 - bombpic[bombnum].h div 2;
        dstrect.w := bombpic[bombnum].w;
        dstrect.h := bombpic[bombnum].h;
        SDL_BlitSurface(bombpic[bombnum], nil, screen, @dstrect);
        Inc(bombnum);
        sdl_delay((20 * gamespeed) div 10);
      end;
    end;

    showbow(bowpic[readystate], round(event.button.x / (RealScreen.w / screen.w)),
      round(event.button.y / (RealScreen.h / screen.h)), degree);
    word := UTF8Decode('得分：');
    drawshadowtext(@word[1], 500, 415, colcolor(0, 255), colcolor(0, 111));
    word := UTF8Decode('機會：');
    drawshadowtext(@word[1], 500, 393, colcolor(0, 255), colcolor(0, 111));
    word := UTF8Decode('目標：');
    drawshadowtext(@word[1], 500, 371, colcolor(0, 255), colcolor(0, 111));
    word := IntToStr(goal);
    drawshadowtext(@word[1], 570, 415, colcolor(0, 255), colcolor(0, 111));
    word := IntToStr(chance);
    drawshadowtext(@word[1], 570, 393, colcolor(0, 255), colcolor(0, 111));
    word := IntToStr(aim);
    drawshadowtext(@word[1], 570, 371, colcolor(0, 255), colcolor(0, 111));

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
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) then
        begin
          degree := degree + 1;
          showbow(bowpic[readystate], round(event.button.x / (RealScreen.w / screen.w)),
            round(event.button.y / (RealScreen.h / screen.h)), degree);
          if arrowstep <= 0 then arrowdegree := degree;
        end;
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_kp6) then
        begin
          degree := degree - 1;
          showbow(bowpic[readystate], round(event.button.x / (RealScreen.w / screen.w)),
            round(event.button.y / (RealScreen.h / screen.h)), degree);
          if arrowstep <= 0 then arrowdegree := degree;
        end;
        if event.key.keysym.sym = sdlk_space then
        begin
          if (arrowstep <= 0) and (readystate = 1) then
          begin
            readystate := 0;

            degree := showbow(bowpic[readystate], round(event.button.x / (RealScreen.w / screen.w)),
              round(event.button.y / (RealScreen.h / screen.h)), degree);
            //  showbow(Gamepic,bowpic[readystate], round(event.button.x / (RealScreen.w / screen.w)), round(event.button.y / (RealScreen.h / screen.h)),readystate);

          end;
        end;
      end;

      SDL_KEYUP:
      begin
        if event.key.keysym.sym = sdlk_space then
        begin
          if (arrowstep <= 0) and (readystate = 0) then
          begin
            readystate := 1;
            Dec(chance);
            arrowstep := arrowstep + arrowspeed;
            degree := showbow(bowpic[readystate], round(event.button.x / (RealScreen.w / screen.w)),
              round(event.button.y / (RealScreen.h / screen.h)), degree);
            //  showbow(Gamepic,bowpic[readystate], round(event.button.x / (RealScreen.w / screen.w)), round(event.button.y / (RealScreen.h / screen.h)),readystate);
          end;
        end;
        if event.key.keysym.sym = sdlk_escape then
        begin
          Result := False;
          break;
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if event.button.button = sdl_button_left then
          if (arrowstep <= 0) and (readystate = 0) then
          begin
            readystate := 1;
            Dec(chance);
            arrowstep := arrowstep + arrowspeed;
            degree := showbow(bowpic[readystate], round(event.button.x / (RealScreen.w / screen.w)),
              round(event.button.y / (RealScreen.h / screen.h)), 180);
            //      showbow(Gamepic,bowpic[readystate], round(event.button.x / (RealScreen.w / screen.w)), round(event.button.y / (RealScreen.h / screen.h)),readystate);
          end;
      end;
      SDL_MOUSEBUTTONDOWN:
      begin
        if event.button.button = sdl_button_left then
          if (arrowstep <= 0) and (readystate = 1) then
          begin
            readystate := 0;

            degree := showbow(bowpic[readystate], round(event.button.x / (RealScreen.w / screen.w)),
              round(event.button.y / (RealScreen.h / screen.h)), 180);
            //  showbow(Gamepic,bowpic[readystate], round(event.button.x / (RealScreen.w / screen.w)), round(event.button.y / (RealScreen.h / screen.h)),readystate);
          end;
      end;
      SDL_MOUSEMOTION:
      begin
        degree := showbow(bowpic[readystate], round(event.button.x / (RealScreen.w / screen.w)),
          round(event.button.y / (RealScreen.h / screen.h)), 180);

      end;
    end;
    if arrowstep <= 0 then arrowdegree := degree;
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    sdl_delay((5 * GameSpeed) div 10);
  end;

  for i := 0 to 7 do
  begin
    if EaglePic[i div 4][i mod 4] <> nil then
      SDL_FreeSurface(EaglePic[i div 4][i mod 4]);
  end;
  for i := 0 to 1 do
  begin
    if BowPic[i] <> nil then
      SDL_FreeSurface(BowPic[i]);
  end;
  for i := 0 to 11 do
  begin
    if Bombpic[i] <> nil then
      SDL_FreeSurface(Bombpic[i]);
  end;
  SDL_FreeSurface(arrowpic);
  SDL_FreeSurface(gamepic.pic);
end;

function Acupuncture(n: integer): boolean;
var
  AcupunctureList: array[0..1000] of smallint;
  goal, select: array of smallint;
  str: WideString;
  flag: boolean;
  GamePic: Tpic;
  word: WideString;
  r, i, i1, b, j, s, len, grp, idx, menu, col, acunum, trytime, accu, actime, chance: integer;
  //accu is a value to accurate
begin

  chance := 3;
  if GetPetSkill(4, 2) then chance := 6;

  setlength(goal, n);
  setlength(select, n);
  if (FileExistsUTF8(AppPath + GAME_file) { *Converted from FileExists*  }) then
  begin
    grp := fileopen(AppPath + GAME_file, fmopenread);
    Gamepic := GetPngPic(grp, 0);
    fileclose(grp);
  end;
  //read file from bin
  col := fileopen(AppPath + 'list/Acupuncture.bin', fmopenread);
  fileread(col, AcupunctureList[0], 1000);
  fileclose(col);
  redraw;
  //draw person
  DrawRectangle(AcupunctureList[2], AcupunctureList[3], abs(AcupunctureList[4] - AcupunctureList[2]),
    abs(AcupunctureList[5] - AcupunctureList[3]), 0, colcolor(255), 25);
  word := UTF8Decode(' 遊戲規則：**將亮起的穴位按順序點亮**有三次機會');
  if GetPetSkill(4, 2) then word := UTF8Decode(' 遊戲規則：**將亮起的穴位按順序點亮**有五次機會');
  DrawRectangle((AcupunctureList[2] + AcupunctureList[4]) div 2 - 115,
    220 - 60, 250, 115, 0, colcolor(255), 25);
  drawshadowtext(@word[1], (AcupunctureList[2] + AcupunctureList[4]) div 2 - 120,
    220 - 50, colcolor(0, $5), colcolor(0, $7));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  waitanykey;

  drawpngpic(gamepic, 0, 0, 395, 400, AcupunctureList[0], AcupunctureList[1], 0);
  for i := 3 to 499 do
  begin
    if (AcupunctureList[2 * i] = -1) or (AcupunctureList[2 * i + 1] = -1) then
    begin
      acunum := i - 3; //actual num
      break;
    end;
    //draw huge px

    drawpngpic(gamepic, 40, 400, 20, 20, AcupunctureList[2 * i] - 10, AcupunctureList[2 * i + 1] - 10, 0);
  end;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  word := UTF8Decode(' 準備開始');
  DrawRectangle((AcupunctureList[2] + AcupunctureList[4]) div 2 - 45,
    220 - 15, 90, 30, 0, colcolor(255), 25);
  drawshadowtext(@word[1], (AcupunctureList[2] + AcupunctureList[4]) div 2 - 60,
    220 - 10, colcolor(0, $5), colcolor(0, $7));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  waitanykey;
  drawpngpic(gamepic, 0, 0, 395, 400, AcupunctureList[0], AcupunctureList[1], 0);

  drawpngpic(gamepic, 0, 0, 395, 400, AcupunctureList[0], AcupunctureList[1], 0);
  for i := 0 to acunum - 1 do
  begin
    drawpngpic(gamepic, 40, 400, 20, 20, AcupunctureList[2 * (i + 3)] - 10, AcupunctureList[2 * (i + 3) + 1] - 10, 0);
  end;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

  sdl_delay(500);
  //delphi你死去罢！
  drawpngpic(gamepic, 0, 0, 395, 400, AcupunctureList[0], AcupunctureList[1], 0);
  for i := 0 to acunum - 1 do
  begin
    drawpngpic(gamepic, 40, 400, 20, 20, AcupunctureList[2 * (i + 3)] - 10, AcupunctureList[2 * (i + 3) + 1] - 10, 0);

  end;


  for i := 0 to n - 1 do
  begin
    r := random(acunum);
    goal[i] := r;

    drawpngpic(gamepic,
      AcupunctureList[2 * (r + 3)] - 10 - AcupunctureList[0],
      AcupunctureList[2 * (r + 3) + 1] - 10 - AcupunctureList[1],
      20, 20,
      AcupunctureList[2 * (r + 3)] - 10,
      AcupunctureList[2 * (r + 3) + 1] - 10, 0);

    drawpngpic(gamepic, 0, 400, 20, 20, AcupunctureList[2 * (r + 3)] - 10, AcupunctureList[2 * (r + 3) + 1] - 10, 0);

    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h); //showsdl_delay(500);        //delay  300ms
    sdl_delay(800);

    drawpngpic(gamepic,
      AcupunctureList[2 * (r + 3)] - 10 - AcupunctureList[0],
      AcupunctureList[2 * (r + 3) + 1] - 10 - AcupunctureList[1],
      20, 20,
      AcupunctureList[2 * (r + 3)] - 10,
      AcupunctureList[2 * (r + 3) + 1] - 10, 0);

    drawpngpic(gamepic, 40, 400, 20, 20, AcupunctureList[2 * (r + 3)] - 10, AcupunctureList[2 * (r + 3) + 1] - 10, 0);

    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h); //showsdl_delay(500);        //delay  300ms
    sdl_delay(300);

  end;

  accu := 10; //set accurate,extreme. improtan.
  Result := False; //it's surely a symbol 2 show the result
  for trytime := 0 to chance - 1 do
  begin

    redraw;
    //draw person
    DrawRectangle(AcupunctureList[2], AcupunctureList[3], abs(AcupunctureList[4] - AcupunctureList[2]),
      abs(AcupunctureList[5] - AcupunctureList[3]), 0, colcolor(255), 25);
    drawpngpic(gamepic, 0, 0, 395, 400, AcupunctureList[0], AcupunctureList[1], 0);
    for i := 0 to acunum - 1 do
    begin
      drawpngpic(gamepic, 40, 400, 20, 20, AcupunctureList[2 * (i + 3)] - 10,
        AcupunctureList[2 * (i + 3) + 1] - 10, 0);

    end;
    DrawRectangle(AcupunctureList[2], AcupunctureList[3], 17 + (chance + 1) * 20, 28, 0, colcolor(255), 50);
    for i := 0 to chance - 1 do
      DrawRectangle(AcupunctureList[2] + 17 + i * 20,
        AcupunctureList[3] + 2 + 5, 15, 15,
        colcolor($14), colcolor($FF), 0);

    DrawRectangle(AcupunctureList[2] + trytime * 20 + 17,
      AcupunctureList[3] + 2 + 5, 15, 15,
      colcolor($14), colcolor($14), 100);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    s := 0;
    while True do
    begin
      while (SDL_WaitEvent(@event) >= 0) do
      begin
        if (event.type_ = SDL_QUITEV) then
          if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then
            Quit;
        if event.type_ = SDL_VIDEORESIZE then
        begin
          ResizeWindow(event.resize.w, event.resize.h);
        end;
        if (event.type_ = SDL_mousebuttonUP) then
        begin
          for i := 0 to acunum - 1 do
          begin
            if (round(event.button.x / (RealScreen.w / screen.w)) <=
              (AcupunctureList[2 * (i + 3)] + accu)) and (round(event.button.x / (RealScreen.w / screen.w)) >=
              (AcupunctureList[2 * (i + 3)] - accu)) and (round(event.button.y / (RealScreen.h / screen.h)) >=
              (AcupunctureList[2 * (i + 3) + 1] - accu)) and (round(event.button.y / (RealScreen.h / screen.h)) <=
              (AcupunctureList[2 * (i + 3) + 1] + accu)) then
            begin
              select[s] := i;
              s := s + 1;
              drawpngpic(gamepic,
                AcupunctureList[2 * (i + 3)] - 10 - AcupunctureList[0],
                AcupunctureList[2 * (i + 3) + 1] - 10 - AcupunctureList[1],
                20, 20,
                AcupunctureList[2 * (i + 3)] - 10,
                AcupunctureList[2 * (i + 3) + 1] - 10, 0);

              drawpngpic(gamepic, 20, 400, 20, 20, AcupunctureList[2 * (i + 3)] - 10,
                AcupunctureList[2 * (i + 3) + 1] - 10, 0);

              SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
              sdl_delay(200);
              drawpngpic(gamepic,
                AcupunctureList[2 * (i + 3)] - 10 - AcupunctureList[0],
                AcupunctureList[2 * (i + 3) + 1] - 10 - AcupunctureList[1],
                20, 20,
                AcupunctureList[2 * (i + 3)] - 10,
                AcupunctureList[2 * (i + 3) + 1] - 10, 0);

              drawpngpic(gamepic, 40, 400, 20, 20, AcupunctureList[2 * (i + 3)] - 10,
                AcupunctureList[2 * (i + 3) + 1] - 10, 0);
              SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h); //showsdl_delay(500);        //delay  300ms
            end;
          end;
          if select[s - 1] <> goal[s - 1] then break;
          if s > n - 1 then break;
        end;
      end;
      for I1 := 0 to n - 1 do
      begin
        if goal[i1] <> select[i1] then
        begin
          s := 0;
          break;
        end;
      end;
      if s <> 0 then
      begin
        sdl_delay(200);
        word := UTF8Decode(' 挑戰成功');
        DrawRectangle((AcupunctureList[2] + AcupunctureList[4]) div 2 - 45,
          220 - 15, 90, 30, 0, colcolor(255), 25);
        drawshadowtext(@word[1], (AcupunctureList[2] + AcupunctureList[4]) div 2 - 60,
          220 - 10, colcolor(0, $5), colcolor(0, $7));
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        waitanykey;

        Result := True;
        SDL_FreeSurface(Gamepic.pic);
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        exit;
      end;
      sdl_delay(200);
      word := UTF8Decode(' 挑戰失敗');
      DrawRectangle((AcupunctureList[2] + AcupunctureList[4]) div 2 - 45,
        220 - 15, 90, 30, 0, colcolor(255), 25);
      drawshadowtext(@word[1], (AcupunctureList[2] + AcupunctureList[4]) div 2 - 60,
        220 - 10, colcolor(0, $5), colcolor(0, $7));
      SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
      waitanykey;

      break;
    end;
  end;


  sdl_delay(1000);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
end;

function Lamp(c, beginpic, whitecount, chance: integer): boolean;
var
  x, y, r, temp, i, pic2, pic3, menu: integer;
begin
  if GetPetSkill(4, 2) then Dec(c);
  r := c;
  x := (screen.w - (c * 50)) div 2;
  y := (screen.h - (r * 50)) div 2;
  pic2 := beginpic + 1;
  pic3 := beginpic + 2;
  menu := 0;
  setlength(gamearray, 1);
  setlength(gamearray[0], c * r);
  for i := 0 to c * r - 1 do
    gamearray[0][i] := beginpic;
  for i := 0 to whitecount - 1 do
  begin
    temp := random(c * r);
    while temp = beginpic do
      temp := random(c * r);
    gamearray[0][temp] := pic2;
  end;
  drawrectanglewithoutframe(x - 10, y - 10, c * 50 + 20, r * 50 + 20, 0, 60);
  for i := 0 to c * r - 1 do
  begin
    drawSpic(gamearray[0][i], x + (i mod c) * 50, y + (i div c) * 50, x + (i mod c) * 50, y + (i div c) * 50, 51, 51);
    if menu = i then
      drawSpic(pic3, x + (menu mod c) * 50, y + (menu div c) * 50, x + (i mod c) * 50, y + (i div c) * 50, 51, 51);
  end;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
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
      SDL_MOUSEMOTION:
      begin
        if (round(event.button.x / (RealScreen.w / screen.w)) > x) and
          (round(event.button.x / (RealScreen.w / screen.w)) < x + 50 * c) and
          (round(event.button.y / (RealScreen.h / screen.h)) > y) and
          (round(event.button.y / (RealScreen.h / screen.h)) < y + 50 * r) then

          menu := ((round(event.button.x / (RealScreen.w / screen.w)) - x) div 50) +
            (((round(event.button.y / (RealScreen.h / screen.h)) - y) div 50) * c);
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if event.button.button = sdl_button_left then
        begin
          if (round(event.button.x / (RealScreen.w / screen.w)) > x) and
            (round(event.button.x / (RealScreen.w / screen.w)) < x + 50 * c) and
            (round(event.button.y / (RealScreen.h / screen.h)) > y) and
            (round(event.button.y / (RealScreen.h / screen.h)) < y + 50 * r) then

            menu := ((round(event.button.x / (RealScreen.w / screen.w)) - x) div 50) +
              (((round(event.button.y / (RealScreen.h / screen.h)) - y) div 50) * c);
          if gamearray[0][menu] = beginpic then temp := pic2
          else temp := beginpic;
          gamearray[0][menu] := temp;
          if (menu mod c) > 0 then
          begin
            if gamearray[0][menu - 1] = beginpic then temp := pic2
            else temp := beginpic;
            gamearray[0][menu - 1] := temp;
          end;
          if (menu mod c) < c - 1 then
          begin
            if gamearray[0][menu + 1] = beginpic then temp := pic2
            else temp := beginpic;
            gamearray[0][menu + 1] := temp;
          end;
          if (menu div c) > 0 then
          begin
            if gamearray[0][menu - c] = beginpic then temp := pic2
            else temp := beginpic;
            gamearray[0][menu - c] := temp;
          end;
          if (menu div c) < r - 1 then
          begin
            if gamearray[0][menu + c] = beginpic then temp := pic2
            else temp := beginpic;
            gamearray[0][menu + c] := temp;
          end;
        end;
      end;
      SDL_KEYUP:
      begin
        if event.key.keysym.sym = sdlk_escape then
        begin
          Result := False;
          break;
        end;
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then menu := menu - c;
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then menu := menu + c;
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) then menu := menu - 1;
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_kp6) then menu := menu + 1;
        if menu < 0 then menu := menu + c * r;
        if menu > c * r - 1 then menu := menu - c * r;
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          if gamearray[0][menu] = beginpic then temp := pic2
          else temp := beginpic;
          gamearray[0][menu] := temp;
          if (menu mod c) > 0 then
          begin
            if gamearray[0][menu - 1] = beginpic then temp := pic2
            else temp := beginpic;
            gamearray[0][menu - 1] := temp;
          end;
          if (menu mod c) < c - 1 then
          begin
            if gamearray[0][menu + 1] = beginpic then temp := pic2
            else temp := beginpic;
            gamearray[0][menu + 1] := temp;
          end;
          if (menu div c) > 0 then
          begin
            if gamearray[0][menu - c] = beginpic then temp := pic2
            else temp := beginpic;
            gamearray[0][menu - c] := temp;
          end;
          if (menu div c) < r - 1 then
          begin
            if gamearray[0][menu + c] = beginpic then temp := pic2
            else temp := beginpic;
            gamearray[0][menu + c] := temp;
          end;
        end;
      end;

    end;
    for i := 0 to c * r - 1 do
    begin
      drawSpic(gamearray[0][i], x + (i mod c) * 50, y + (i div c) * 50, x + (i mod c) * 50,
        y + (i div c) * 50, 51, 51);
      if menu = i then
        drawSpic(pic3, x + (menu mod c) * 50, y + (menu div c) * 50, x + (i mod c) * 50, y + (i div c) * 50, 51, 51);
    end;
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    Result := True;
    for i := 0 to c * r - 1 do
    begin
      if gamearray[0][i] <> gamearray[0][0] then
        Result := False;
    end;
    if Result = True then
    begin
      sdl_delay(1000);
      break;
    end;
  end;
end;

function SelectPoetry(wx1, wy1, c, Count, len, menu, chance: integer): integer;
var
  w: uint16;
  menu1, i, r1, row: integer;
begin
  r1 := Count div c;
  row := len div c;
  menu1 := 0;
  for i := 0 to Count - 1 do
  begin
    if i = menu1 then
      drawrectangle(wx1 + (i mod c) * 40 + 11, wy1 + (i div c) * 40 - 9, 39, 39, 0, colcolor(0, 5), 0)
    else
      drawrectangle(wx1 + (i mod c) * 40 + 11, wy1 + (i div c) * 40 - 9, 39, 39, 0, colcolor(0, 255), 0);
  end;
  SDL_UpdateRect2(screen, 0, 0, 640, 440);

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
      SDL_MOUSEMOTION:
      begin
        if (round(event.button.x / (RealScreen.w / screen.w)) > (wx1 - 11)) and
          (round(event.button.x / (RealScreen.w / screen.w)) < (wx1 - 11) + 40 * c) and
          (round(event.button.y / (RealScreen.h / screen.h)) > (wy1 - 9)) and
          (round(event.button.y / (RealScreen.h / screen.h)) < (wy1 - 9) + 40 * r1) then

          menu1 := ((round(event.button.x / (RealScreen.w / screen.w)) - wx1 - 11) div 40) +
            (((round(event.button.y / (RealScreen.h / screen.h)) - wy1 + 9)) div 40) * c;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if event.button.button = sdl_button_left then
        begin
          if (round(event.button.x / (RealScreen.w / screen.w)) > (wx1 - 11)) and
            (round(event.button.x / (RealScreen.w / screen.w)) < (wx1 - 11) + 40 * c) and
            (round(event.button.y / (RealScreen.h / screen.h)) > (wy1 - 9)) and
            (round(event.button.y / (RealScreen.h / screen.h)) < (wy1 - 9) + 40 * r1) then

            menu1 := ((round(event.button.x / (RealScreen.w / screen.w)) - wx1 - 11) div 40) +
              (((round(event.button.y / (RealScreen.h / screen.h)) - wy1 + 9)) div 40) * c;
          if (menu1 < Count) and (menu < length(gamearray[1])) then
          begin
            w := gamearray[1][menu];
            gamearray[1][menu] := gamearray[2][menu1];
            gamearray[2][menu1] := w;
            Inc(chance, -1);
          end;
        end;
        break;
      end;
      SDL_KEYUP:
      begin
        if event.key.keysym.sym = sdlk_escape then
          break;
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then menu1 := menu1 - c;
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then menu1 := menu1 + c;
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) then menu1 := menu1 - 1;
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_kp6) then menu1 := menu1 + 1;
        if menu1 < 0 then menu1 := menu1 + Count;
        if menu1 > Count - 1 then menu1 := menu1 - Count;
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          if (menu1 < Count) and (menu < length(gamearray[1])) then
          begin
            w := gamearray[1][menu];
            gamearray[1][menu] := gamearray[2][menu1];
            gamearray[2][menu1] := w;
            Inc(chance, -1);
            break;
          end;
        end;
      end;
    end;
    for i := 0 to Count - 1 do
    begin
      if i = menu1 then
        drawrectangle(wx1 + (i mod c) * 40 + 11, wy1 + (i div c) * 40 - 9, 39, 39, 0, colcolor(0, 5), 0)
      else
        drawrectangle(wx1 + (i mod c) * 40 + 11, wy1 + (i div c) * 40 - 9, 39, 39, 0, colcolor(0, 255), 0);
    end;
    SDL_UpdateRect2(screen, 0, 0, 640, 440);
  end;
  Result := chance;

end;

function Poetry(talknum, chance, c, Count: integer): boolean;
var
  wx, wy, wx1, wy1, x, y, w, h, row, r1, i, n, len, idx, grp, menu, menu1, offset: integer;
  wd: array[0..1] of smallint;
  poet, t: puint16;
  talkarray: array of byte;
  str: WideString;
begin
  if GetPetSkill(4, 2) then chance := chance * 2;
  x := 20;
  y := 20;
  wy := 160;
  wy1 := 300;
  menu := 0;
  menu1 := 0;
  wd[1] := 0;
  idx := fileopen(AppPath + TALK_IDX, fmopenread);
  grp := fileopen(AppPath + TALK_GRP, fmopenread);
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
  for i := 0 to len - 1 do
  begin
    talkarray[i] := talkarray[i] xor $FF;
    if (talkarray[i] = $FF) then
      talkarray[i] := 0;
  end;
  setlength(gamearray, 3);
  talkarray[len] := byte(0);
  poet := puint16(@talkarray[0]);
  len := len div 2;
  setlength(gamearray[0], len); //读取的字
  setlength(gamearray[1], len); //显示的字
  setlength(gamearray[2], Count); //答案
  for i := 0 to len - 1 do
  begin
    gamearray[1][i] := 0;
    gamearray[0][i] := 0;
  end;
  for i := 0 to Count - 1 do
  begin
    gamearray[2][i] := $2020;
  end;
  for i := 0 to len - 1 do
  begin
    t := poet;
    Inc(t, i);
    gamearray[0][i] := t^;
    n := random(len - 1);
    while gamearray[1][n] <> 0 do
      n := random(len);
    gamearray[1][n] := gamearray[0][i];
  end;
  row := len div c;
  r1 := row;
  redraw;
  drawrectanglewithoutframe(x, y, 600, 400, 0, 60);

  wx := center_X - c * 20 - 12;
  wx1 := center_X - (Count div r1) * 20 - 12;
  drawrectangle(wx1 + 11, wy1 - 9, (Count div r1) * 40 - 1, r1 * 40 - 1, 0, colcolor(0, 255), 0);
  drawrectangle(wx + 11, wy - 9, c * 40 - 1, row * 40 - 1, 0, colcolor(0, 255), 0);
  drawrectangle(center_X - c * 20 - 1, y + 15, c * 40 - 1, 39, 0, colcolor(0, 255), 0);

  for i := 0 to len - 1 do
  begin
    wd[0] := gamearray[1][i];
    drawgbkShadowText(PChar(@wd[0]), wx + (i mod c) * 40, wy + (i div c) * 40, colcolor(0, 5), colcolor(0, 7));
  end;
  for i := 0 to Count - 1 do
  begin
    wd[0] := gamearray[2][i];
    drawgbkShadowText(PChar(@wd[0]), wx1 + (i mod (Count div r1)) * 40, wy1 + (i div (Count div r1)) * 40,
      colcolor(0, 5), colcolor(0, 7));
  end;
  drawrectangle(wx + (menu mod c) * 40 + 11, wy + (menu div c) * 40 - 9, 39, 39, 0, colcolor(0, 255), 0);

  str := UTF8Decode('機會：');
  drawShadowText(puint16(str), wx + 10, y + 25, colcolor(0, 5), colcolor(0, 7));
  str := IntToStr(chance);
  drawShadowText(puint16(str), wx + 80, y + 25, colcolor(0, 5), colcolor(0, 7));

  SDL_UpdateRect2(screen, 0, 0, 640, 440);
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
        if event.key.keysym.sym = sdlk_escape then
        begin
          Result := False;
          exit;
        end;
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then menu := menu - c;
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then menu := menu + c;
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) then menu := menu - 1;
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_kp6) then menu := menu + 1;
        if menu < 0 then menu := menu + c * row;
        if menu > c * row - 1 then menu := menu - c * row;
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin

          chance := SelectPoetry(wx1, wy1, (Count div r1), Count, len, menu, chance);
          SDL_UpdateRect2(screen, 0, 0, 640, 440);

        end;
      end;
      SDL_MOUSEMOTION:
      begin
        if (round(event.button.x / (RealScreen.w / screen.w)) > (wx - 11)) and
          (round(event.button.x / (RealScreen.w / screen.w)) < (wx - 11) + 40 * c) and
          (round(event.button.y / (RealScreen.h / screen.h)) > (wy - 9)) and
          (round(event.button.y / (RealScreen.h / screen.h)) < (wy - 9) + 40 * row) then
          menu := ((round(event.button.x / (RealScreen.w / screen.w)) - wx - 11) div 40) +
            (((round(event.button.y / (RealScreen.h / screen.h)) - wy + 9)) div 40) * c;
      end;
      SDL_MOUSEBUTTONUP:
        if event.button.button = sdl_button_left then
        begin
          if (round(event.button.x / (RealScreen.w / screen.w)) > (wx - 11)) and
            (round(event.button.x / (RealScreen.w / screen.w)) < (wx - 11) + 40 * c) and
            (round(event.button.y / (RealScreen.h / screen.h)) > (wy - 9)) and
            (round(event.button.y / (RealScreen.h / screen.h)) < (wy - 9) + 40 * r1) then
            menu := ((round(event.button.x / (RealScreen.w / screen.w)) - wx - 11) div 40) +
              (((round(event.button.y / (RealScreen.h / screen.h)) - wy + 9)) div 40) * c;
          chance := SelectPoetry(wx1, wy1, (Count div r1), Count, len, menu, chance);
          SDL_UpdateRect2(screen, 0, 0, 640, 440);
        end;
    end;
    redraw;
    drawrectanglewithoutframe(x, y, 600, 400, 0, 60);
    drawrectangle(wx1 + 11, wy1 - 9, (Count div r1) * 40 - 1, r1 * 40 - 1, 0, colcolor(0, 255), 0);
    drawrectangle(wx + 11, wy - 9, c * 40 - 1, row * 40 - 1, 0, colcolor(0, 255), 0);
    drawrectangle(center_X - c * 20 - 1, y + 15, c * 40 - 1, 39, 0, colcolor(0, 255), 0);

    for i := 0 to len - 1 do
    begin
      wd[0] := gamearray[1][i];
      drawgbkShadowText(PChar(@wd[0]), wx + (i mod c) * 40, wy + (i div c) * 40, colcolor(0, 5), colcolor(0, 7));
    end;
    for i := 0 to Count - 1 do
    begin
      wd[0] := gamearray[2][i];
      drawgbkShadowText(PChar(@wd[0]), wx1 + (i mod (Count div r1)) * 40, wy1 +
        (i div (Count div r1)) * 40, colcolor(0, 5), colcolor(0, 7));
    end;
    drawrectangle(wx + (menu mod c) * 40 + 11, wy + (menu div c) * 40 - 9, 39, 39, 0, colcolor(0, 255), 0);
    str := ('機會：');
    drawShadowText(puint16(str), wx + 10, y + 25, colcolor(0, 5), colcolor(0, 7));
    str := IntToStr(chance);
    drawShadowText(puint16(str), wx + 80, y + 25, colcolor(0, 5), colcolor(0, 7));

    SDL_UpdateRect2(screen, 0, 0, 640, 440);
    Result := True;
    for i := 0 to Count - 1 do
    begin
      if gamearray[0][i] <> gamearray[2][i] then
      begin
        Result := False;
        break;
      end;
    end;
    if Result = True then
    begin
      sdl_delay(1000);
      setlength(gamearray, 0);
      break;
    end;

    if chance = 0 then
    begin
      sdl_delay(1000);
      Result := True;
      for i := 0 to Count - 1 do
      begin
        if gamearray[0][i] <> gamearray[2][i] then
        begin
          Result := False;
          setlength(gamearray, 0);
          break;
        end;
      end;
      break;
    end;
  end;
end;

procedure ExchangePic(p1, p2: integer);
var
  t: smallint;
begin
  t := gamearray[0][p1];
  gamearray[0][p1] := gamearray[0][p2];
  gamearray[0][p2] := t;
  t := gamearray[1][p1];
  gamearray[1][p1] := gamearray[1][p2];
  gamearray[1][p2] := t;
end;

function rotoSpellPicture(num, chance: integer): boolean;
var
  x, y, w, h, i1, i2, i, j, x1, y1, r, right, menu, grp, idx, len, menu1, menu2: integer;
  temp, littlegamepic: psdl_surface;
  gamepic: tpic;
  filename: string;
  word1, word: WideString;
  srcrect: tsdl_rect;
  drect: tsdl_rect;
  pic: array[0..3] of array[0..24] of psdl_surface;
begin
  setlength(gamearray, 2);
  setlength(gamearray[0], 25);
  setlength(gamearray[1], 25);
  menu := 0;
  menu2 := -1;
  x := 150;
  y := 5;
  w := 410;
  h := 440;
  right := 0;
  if GetPetSkill(4, 2) then chance := chance * 2;
  if (FileExistsUTF8(AppPath + GAME_file) { *Converted from FileExists*  }) then
  begin
    grp := fileopen(AppPath + GAME_file, fmopenread);

    Gamepic := GetPngPic(grp, num + 3);
    fileclose(grp);
  end;
  for i := 0 to 24 do
  begin
    gamearray[0][i] := -1;
    gamearray[1][i] := random(4);

  end;
  for i := 0 to 24 do
  begin
    while True do
    begin
      r := random(25);
      if (gamearray[0][r] = -1) then
      begin
        gamearray[0][r] := i;
        break;
      end;
    end;
  end;

  for i := 0 to 24 do
  begin
    for j := 0 to 3 do
    begin
      temp := SDL_CreateRGBSurface(screen.flags, 80, 80, 32, $FF0000, $FF00, $0FF, 0);
      pic[j][i] := SDL_CreateRGBSurface(screen.flags, 80, 80, 32, $FF0000, $FF00, $0FF, 0);
      srcrect.x := (i mod 5) * 80;
      srcrect.y := (i div 5) * 80;
      srcrect.w := 80;
      srcrect.h := 80;
      SDL_BlitSurface(Gamepic.pic, @srcrect, temp, nil);

      for i1 := 0 to 79 do
        for i2 := 0 to 79 do
        begin
          case j of
            0: putpixel(pic[j][i], i1, i2, getpixel(temp, i1, i2));
            1: putpixel(pic[j][i], i1, i2, getpixel(temp, i2, 79 - i1));
            2: putpixel(pic[j][i], i1, i2, getpixel(temp, 79 - i1, 79 - i2));
            3: putpixel(pic[j][i], i1, i2, getpixel(temp, 79 - i2, i1));
          end;
        end;
      sdl_freesurface(temp);
    end;
  end;
  littlegamepic := rotozoomsurfacexy(gamepic.pic, 0, 0.3, 0.3, 0);
  sdl_freesurface(gamepic.pic);

  redraw;
  drawrectangle(x - 5, y - 5, w, h, 0, colcolor(255), 100);
  for i := 0 to 24 do
  begin
    srcrect.x := (i mod 5) * 80 + x;
    srcrect.y := (i div 5) * 80 + y + 30;
    srcrect.w := 80;
    srcrect.h := 80;
    SDL_BlitSurface(pic[0][i], nil, screen, @srcrect);
  end;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  sdl_delay(2000);


  drawrectangle(x - 5, y - 5, w, h, 0, colcolor(255), 100);
  for i := 0 to 24 do
  begin
    srcrect.x := (i mod 5) * 80 + x;
    srcrect.y := (i div 5) * 80 + y + 30;
    srcrect.w := 80;
    srcrect.h := 80;
    SDL_BlitSurface(pic[gamearray[1][i]][gamearray[0][i]], nil, screen, @srcrect);
  end;
  if menu2 > -1 then
    drawrectangle((menu2 mod 5) * 80 + x, (menu2 div 5) * 80 + y + 30, 80, 80, 0, colcolor($64), 0);
  if menu > -1 then
    drawrectangle((menu mod 5) * 80 + x, (menu div 5) * 80 + y + 30, 80, 80, 0, colcolor($255), 0);
  word := UTF8Decode('機會');
  word1 := UTF8Decode('命中');
  drawshadowtext(@word[1], x + 5, y + 5, colcolor(5), colcolor(7));
  drawshadowtext(@word1[1], x + 200, y + 5, colcolor(5), colcolor(7));
  word := IntToStr(chance);
  word1 := IntToStr(right);
  drawshadowtext(@word[1], x + 55, y + 5, colcolor(5), colcolor(7));
  drawshadowtext(@word1[1], x + 250, y + 5, colcolor(5), colcolor(7));
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

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
        menu1 := menu;
        if event.key.keysym.sym = sdlk_escape then
        begin
          if menu2 > -1 then
          begin
            menu2 := -1;
          end
          else
          begin
            Result := False;
            break;
          end;
        end;
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then menu := menu - 5;
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then menu := menu + 5;
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) then menu := menu - 1;
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_kp6) then menu := menu + 1;
        if menu > 24 then menu := menu - 25;
        if menu < 0 then menu := menu + 25;
        if menu1 > -1 then
        begin
          srcrect.x := (menu1 mod 5) * 80 + x;
          srcrect.y := (menu1 div 5) * 80 + y + 30;
          srcrect.w := 80;
          srcrect.h := 80;
          SDL_BlitSurface(pic[gamearray[1][menu1]][gamearray[0][menu1]], nil, screen, @srcrect);
        end;
        if (event.key.keysym.sym = sdlk_space) then
        begin
          if menu2 > -1 then
          begin
            exchangepic(menu, menu2);
            menu2 := -1;
            chance := chance - 1;
          end
          else if menu > -1 then menu2 := menu;
        end;
        if (event.key.keysym.sym = sdlk_return) then
        begin
          Inc(gamearray[1][menu]);
          if gamearray[1][menu] > 3 then gamearray[1][menu] := 0;
          srcrect.x := (menu mod 5) * 80 + x;
          srcrect.y := (menu div 5) * 80 + y + 30;
          srcrect.w := 80;
          srcrect.h := 80;
          SDL_BlitSurface(pic[gamearray[1][menu]][gamearray[0][menu]], nil, screen, @srcrect);
        end;
      end;

      SDL_MOUSEMOTION:
      begin
        if menu > -1 then menu1 := menu;
        if (round(event.button.x / (RealScreen.w / screen.w)) > x) and
          (round(event.button.x / (RealScreen.w / screen.w)) < x - 5 + w) and
          (round(event.button.y / (RealScreen.h / screen.h)) > y) and
          (round(event.button.y / (RealScreen.h / screen.h)) < y - 5 + h) then
        begin
          menu := ((round(event.button.x / (RealScreen.w / screen.w)) - x) div 80) +
            ((round(event.button.y / (RealScreen.h / screen.h)) - y - 30) div 80) * 5;
          if menu > 24 then menu := -1;
          if menu <> menu1 then
          begin
            if menu1 > -1 then
            begin
              srcrect.x := (menu1 mod 5) * 80 + x;
              srcrect.y := (menu1 div 5) * 80 + y + 30;
              srcrect.w := 80;
              srcrect.h := 80;
              SDL_BlitSurface(pic[gamearray[1][menu1]][gamearray[0][menu1]], nil, screen, @srcrect);
            end;
          end;
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if event.button.button = sdl_button_right then
        begin
          if menu2 > -1 then
          begin
            menu2 := -1;
          end
          else
          begin
            Inc(gamearray[1][menu]);
            if gamearray[1][menu] > 3 then gamearray[1][menu] := 0;

            srcrect.x := (menu mod 5) * 80 + x;
            srcrect.y := (menu div 5) * 80 + y + 30;
            srcrect.w := 80;
            srcrect.h := 80;
            SDL_BlitSurface(pic[gamearray[1][menu]][gamearray[0][menu]], nil, screen, @srcrect);
          end;
        end;
        if event.button.button = sdl_button_left then
        begin
          if menu2 > -1 then
          begin
            exchangepic(menu, menu2);
            menu2 := -1;
            chance := chance - 1;
          end
          else if menu > -1 then menu2 := menu;
        end;
      end;
    end;


    right := 0;
    for i := 0 to 24 do
    begin
      if (gamearray[0][i] = i) and (gamearray[1][i] = 0) then
        right := right + 1;
    end;
    drawrectangle(x - 5, y - 5, w, h, 0, colcolor(255), 100);
    drawrectangle(x - 5 - 140, y - 5, 130, 130, 0, colcolor(255), 100);
    srcrect.x := x - 140;
    srcrect.y := y;
    srcrect.w := 120;
    srcrect.h := 120;
    SDL_BlitSurface(littlegamepic, nil, screen, @srcrect);

    for i := 0 to 24 do
    begin
      srcrect.x := (i mod 5) * 80 + x;
      srcrect.y := (i div 5) * 80 + y + 30;
      srcrect.w := 80;
      srcrect.h := 80;
      SDL_BlitSurface(pic[gamearray[1][i]][gamearray[0][i]], nil, screen, @srcrect);
    end;
    if menu2 > -1 then
      drawrectangle((menu2 mod 5) * 80 + x, (menu2 div 5) * 80 + y + 30, 80, 80, 0, colcolor($64), 0);
    if menu > -1 then
      drawrectangle((menu mod 5) * 80 + x, (menu div 5) * 80 + y + 30, 80, 80, 0, colcolor($255), 0);
    word := UTF8Decode('機會');
    word1 := UTF8Decode('命中');
    drawshadowtext(@word[1], x + 5, y + 5, colcolor(5), colcolor(7));
    drawshadowtext(@word1[1], x + 200, y + 5, colcolor(5), colcolor(7));
    word := IntToStr(chance);
    word1 := IntToStr(right);
    drawshadowtext(@word[1], x + 55, y + 5, colcolor(5), colcolor(7));
    drawshadowtext(@word1[1], x + 250, y + 5, colcolor(5), colcolor(7));
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);


    if right = 25 then Result := True
    else Result := False;
    if Result then
    begin
      sdl_delay(700);
      waitanykey();
      break;
    end
    else if chance = 0 then
    begin
      sdl_delay(700);
      waitanykey();
      break;
    end;
  end;
  setlength(gamearray, 0);
  for i := 0 to 24 do
  begin
    for j := 0 to 3 do
    begin
      sdl_freesurface(pic[j][i]);
    end;
  end;
  sdl_freesurface(littlegamepic);
end;

end.
