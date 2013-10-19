unit kys_draw;

//{$mode delphi}

interface

uses
  SysUtils,
{$IFDEF fpc}
  LMessages,
  LConvEncoding,
  LCLType,
  LCLIntf,
  FileUtil,
{$ELSE}
  Windows,
{$ENDIF}
  Math,
  Dialogs,
  SDL_TTF,
  SDL_image,
  SDL_gfx,
  SDL,
  glext,
  gl,
  bassmidi,
  bass,
  ziputils,
  unzip,
  kys_main,
  kys_type;

//画单个图片的子程
procedure DrawTitlePic(imgnum, px, py: integer);
procedure DrawMPic(num, px, py: integer; Framenum: integer = -1); overload;
procedure DrawMPic(num, px, py, shadow, alpha: integer; mixColor: Uint32; mixAlpha: integer;
  Framenum: integer = -1); overload;
procedure DrawSPic(num, px, py: integer); overload;
procedure DrawSPic(num, px, py, x, y, w, h: integer); overload;
procedure DrawSPic(num, px, py, shadow, alpha, depth: integer; mixColor: Uint32; mixAlpha: integer); overload;
procedure InitialSPic(num, px, py, x, y, w, h: integer); overload;
procedure InitialSPic(num, px, py, x, y, w, h, needBlock, depth: integer); overload;
procedure InitialSPic(num, px, py, x, y, w, h, needBlock, depth, temp: integer); overload;
procedure DrawHeadPic(num, px, py: integer); overload;
procedure DrawHeadPic(num, px, py: integer; scr: PSDL_Surface); overload;
procedure DrawHeadPic(num, px, py, shadow, alpha, depth: integer; mixColor: Uint32; mixAlpha: integer); overload;
procedure DrawBPic(num, px, py, shadow: integer); overload;
procedure DrawBPic(num, px, py, shadow, alpha, depth: integer; mixColor: Uint32; mixAlpha: integer); overload;
procedure DrawBPicInRect(num, px, py, shadow, x, y, w, h: integer);
procedure InitialBPic(num, px, py: integer); overload;
procedure InitialBPic(num, px, py, needBlock, depth: integer); overload;
procedure DrawEPic(num, px, py: integer); overload;
procedure DrawEPic(num, px, py, shadow, alpha, depth: integer; mixColor: Uint32; mixAlpha: integer); overload;
procedure DrawFPic(num, px, py, index: integer); overload;
procedure DrawFPic(num, px, py, index, shadow, alpha, depth: integer; mixColor: Uint32; mixAlpha: integer); overload;
procedure DrawCPic(num, px, py, shadow, alpha: integer; mixColor: Uint32; mixAlpha: integer);

//绘制整个屏幕的子程
procedure Redraw(WriteFresh: integer = 0);
procedure WriteFreshScreen(x, y, w, h: integer);
procedure ReadFreshScreen(x, y, w, h: integer);
procedure DrawMMap;
procedure DrawScence;
procedure DrawScenceWithoutRole(x, y: integer);
procedure DrawRoleOnScence(x, y: integer);
procedure ExpandGroundOnImg();
procedure InitialScence(); overload;
procedure InitialScence(Visible: integer); overload;
function CalBlock(x, y: integer): integer;
procedure CalPosOnImage(i1, i2: integer; var x, y: integer);
procedure CalLTPosOnImageByCenter(i1, i2: integer; var x, y: integer);
procedure InitialScenceOnePosition(i1, i2, x1, y1, w, h, depth, temp: integer);
procedure UpdateScence(xs, ys: integer);
procedure LoadScencePart(x, y: integer);
procedure DrawWholeBField(needProgress: integer = 1);
procedure DrawBfieldWithoutRole(x, y: integer);
procedure DrawRoleOnBfield(x, y: integer; MixColor: Uint32 = 0; MixAlpha: integer = 0; Alpha: integer = 75);
procedure InitialBFieldImage;
procedure InitialBFieldPosition(i1, i2, depth: integer);
procedure LoadBfieldPart(x, y: integer);
procedure LoadBFieldPart2(x, y, alpha: integer);
procedure DrawBFieldWithCursor(step: integer);
procedure DrawBFieldWithEft(Epicnum: integer); overload;
procedure DrawBFieldWithEft(Epicnum, beginpic, endpic, bnum: integer; MixColor: Uint32); overload;
procedure DrawBFieldWithEft(Epicnum, beginpic, endpic, curlevel, bnum, forteam, flash: integer;
  MixColor: Uint32); overload;
procedure DrawBFieldWithAction(bnum, Apicnum: integer);

procedure DrawClouds;

procedure DrawProgress;


implementation

uses
  kys_engine;

//显示title.grp的内容(即开始的选单)

procedure DrawTitlePic(imgnum, px, py: integer);
var
  len, grp, idx: integer;
  BufferIdx: TIntArray;
  BufferPic: TByteArray;
begin
  if PNG_TILE > 0 then
  begin
    if imgnum <= high(TitlePNGIndex) then
      DrawPNGTile(TitlePNGIndex[imgnum], 0, nil, screen, px, py);
  end;
  if PNG_TILE = 0 then
  begin
    len := LoadIdxGrp('resource/title.idx', 'resource/title.grp', BufferIdx, BufferPic);
    if imgnum < len then
      DrawRLE8Pic(@ACol[0], imgnum, px, py, @BufferIdx[0], @BufferPic[0], nil, nil, 0, 0, 0, 0);
  end;
end;

//显示主地图贴图

procedure DrawMPic(num, px, py: integer; Framenum: integer = -1); overload;
begin
  DrawMPic(num, px, py, 0, 0, 0, 0, Framenum);
end;

//显示主地图贴图

procedure DrawMPic(num, px, py, shadow, alpha: integer; mixColor: Uint32; mixAlpha: integer;
  Framenum: integer = -1); overload;
var
  NeedGRP: integer;
begin
  if (num >= 0) and (num < MPicAmount) then
  begin
    NeedGRP := 0;
    if (PNG_TILE > 0) then
    begin
      if MPNGIndex[num].UseGRP = 0 then
      begin
        if Framenum = -1 then
          Framenum := SDL_GetTicks div 200 + random(3);
        if (num = 1377) or (num = 1388) or (num = 1404) or (num = 1417) then
          Framenum := SDL_GetTicks div 200;
        //瀑布场景的闪烁需要
        //DrawPNGTile(MPNGIndex[num], Framenum, nil, screen, px, py, shadow)
        DrawPNGTile(MPNGIndex[num], Framenum, nil, screen, px, py, shadow, alpha, mixColor, mixAlpha,
          0, nil, 0, 0, 0, 0, 0);
      end
      else
        NeedGRP := 1;
    end;
    if (PNG_TILE = 0) or (NeedGRP = 1) then
    begin
      DrawRLE8Pic(@ACol[0], num, px, py, @Midx[0], @Mpic[0], nil, nil, 0, 0, 0, shadow, alpha,
        nil, nil, 0, 0, 0, 4096, mixColor, mixAlpha);
    end;
  end;
end;

//显示场景图片

procedure DrawSPic(num, px, py: integer); overload;
begin
  DrawSPic(num, px, py, 0, 0, 0, 0);
end;

procedure DrawSPic(num, px, py, x, y, w, h: integer); overload;
var
  Area: TSDL_Rect;
begin
  if (num >= 0) and (num < SPicAmount) then
  begin
    Area.x := x;
    Area.y := y;
    Area.w := w;
    Area.h := h;
    if num = 1941 then
    begin
      num := 0;
      py := py - 50;
    end;
    if PNG_TILE > 0 then
      DrawPNGTile(SPNGIndex[num], 0, @Area, screen, px, py)
    else
    begin
      DrawRLE8Pic(@ACol[0], num, px, py, @SIdx[0], @SPic[0], @Area, nil, 0, 0, 0, 0);
    end;
  end;
end;

//画考虑遮挡的内场景

procedure DrawSPic(num, px, py, shadow, alpha, depth: integer; mixColor: Uint32; mixAlpha: integer); overload;
begin
  if (num >= 0) and (num < SPicAmount) then
  begin
    if num = 1941 then
    begin
      num := 0;
      py := py - 50;
    end;
    if PNG_TILE > 0 then
      DrawPNGTile(SPNGIndex[num], 0, nil, screen, px, py, shadow, alpha, mixColor, mixAlpha,
        depth, @BlockImg[0], ImageWidth, ImageHeight, sizeof(BlockImg[0]), BlockScreen.x, BlockScreen.y)
    else
    begin
      DrawRLE8Pic(@ACol[0], num, px, py, @SIdx[0], @SPic[0], nil, nil, 0, 0, 0, shadow, alpha,
        @BlockImg[0], @BlockScreen, ImageWidth, ImageHeight, sizeof(BlockImg[0]), depth, mixColor, mixAlpha);
    end;
  end;

end;

//将场景图片信息画到映像

procedure InitialSPic(num, px, py, x, y, w, h: integer); overload;
begin
  InitialSPic(num, px, py, x, y, w, h, 0, 0, 0);

end;

//画到映像并记录深度数据

procedure InitialSPic(num, px, py, x, y, w, h, needBlock, depth: integer); overload;
begin
  InitialSPic(num, px, py, x, y, w, h, needBlock, depth, 0);

end;

procedure InitialSPic(num, px, py, x, y, w, h, needBlock, depth, temp: integer); overload;
var
  Area: TSDL_Rect;
  pImg: PSDL_Surface;
  pBlock: PChar;
begin
  if temp = 0 then
  begin
    pImg := ImgScence;
    pBlock := @BlockImg[0];
  end
  else
  begin
    pImg := ImgScenceBack;
    pBlock := @BlockImg2[0];
  end;
  if (num >= 0) and (num < SPicAmount) then
  begin
    if x + w > ImageWidth then
      w := ImageWidth - x - 1;
    if y + h > ImageHeight then
      h := ImageHeight - y - 1;
    Area.x := x;
    Area.y := y;
    Area.w := w;
    Area.h := h;
    if num = 1941 then
    begin
      num := 0;
      py := py - 50;
    end;
    if (PNG_TILE > 0) then
    begin
      if temp <> 1 then
        LoadOnePNGTile('resource/smap/', nil, num, SPNGIndex[num], @SPNGTile[0]);
      DrawPNGTile(SPNGIndex[num], SDL_GetTicks div 300, @Area, pImg, px, py);
      if needBlock <> 0 then
      begin
        SetPNGTileBlock(SPNGIndex[num], px, py, depth, pBlock, ImageWidth, ImageHeight, sizeof(BlockImg[0]));
      end;
    end
    else
    begin
      if needBlock <> 0 then
      begin
        DrawRLE8Pic(@ACol[0], num, px, py, @SIdx[0], @SPic[0], @Area, pImg, ImageWidth, ImageHeight,
          sizeof(BlockImg[0]), 0, 0, pBlock, nil, 0, 0, 0, depth, 0, 0);
      end
      else
        DrawRLE8Pic(@ACol[0], num, px, py, @SIdx[0], @SPic[0], @Area, pImg, ImageWidth,
          ImageHeight, sizeof(BlockImg[0]), 0);
    end;
  end;
end;

//显示头像, 优先考虑'.head/'目录下的png图片

procedure DrawHeadPic(num, px, py: integer); overload;
begin
  DrawHeadPic(num, px, py, 0, 0, 0, 0, 0);
end;

procedure DrawHeadPic(num, px, py: integer; scr: PSDL_Surface); overload;
var
  image: PSDL_Surface;
  dest: TSDL_Rect;
  str: string;
  Area: TSDL_Rect;
  offset: integer;
  y: smallint;
begin
  str := AppPath + 'head/' + IntToStr(num) + '.png';
  if FileExistsUTF8(str) then
  begin
    image := IMG_Load(PChar(str));
    dest.x := px;
    dest.y := py;
    SDL_BlitSurface(image, nil, scr, @dest);
    SDL_FreeSurface(image);
  end
  else
  begin
    Area.x := 0;
    Area.y := 0;
    Area.w := scr.w;
    Area.h := scr.h;
    offset := 0;
    if num > 0 then
      offset := HIdx[num - 1];
    y := Psmallint(@HPic[offset + 6])^;
    //showmessage(inttostr(y));
    if (num >= 0) and (num < HPicAmount) then
      DrawRLE8Pic(@ACol1[0], num, px, py + y, @HIdx[0], @HPic[0], @Area, scr, scr.w, scr.h, 0,
        0, 0, nil, nil, 0, 0, 0, 0, 0, 0);
  end;
end;

procedure DrawHeadPic(num, px, py, shadow, alpha, depth: integer; mixColor: Uint32; mixAlpha: integer); overload;
var
  len, grp, idx: integer;
  str: string;
begin
  str := AppPath + 'head/' + IntToStr(num) + '.png';
  if FileExistsUTF8(str) { *Converted from FileExists*  } then
    display_img(@str[1], px, py - 60)
  else
  begin
    if (num >= 0) and (num < HPicAmount) then
      DrawRLE8Pic(@ACol1[0], num, px, py, @HIdx[0], @HPic[0], nil, nil, 0, 0, 0, shadow, alpha,
        nil, nil, 0, 0, 0, depth, mixColor, mixAlpha);
  end;

end;

//显示战场图片

procedure DrawBPic(num, px, py, shadow: integer); overload;
begin
  DrawBPic(num, px, py, shadow, 0, 0, 0, 0);

end;

//用于画带透明度和遮挡的战场图

procedure DrawBPic(num, px, py, shadow, alpha, depth: integer; mixColor: Uint32; mixAlpha: integer); overload;
begin
  if (num > 0) and (num < BPicAmount) then
  begin
    if PNG_TILE > 0 then
    begin
      //LoadOnePNGTile('resource/wmap/', num, BPNGIndex[num], @BPNGTile[0]);
      DrawPNGTile(BPNGIndex[num], 0, nil, screen, px, py, shadow, alpha, mixColor, mixAlpha,
        depth, @BlockImg2[0], ImageWidth, ImageHeight, sizeof(BlockImg2[0]), BlockScreen.x, BlockScreen.y);
    end
    else
    begin
      DrawRLE8Pic(@ACol[0], num, px, py, @WIdx[0], @WPic[0], nil, nil, 0, 0, 0, shadow, alpha,
        @BlockImg2[0], @BlockScreen, ImageWidth, ImageHeight, sizeof(BlockImg2[0]), depth, mixColor, mixAlpha);
    end;
  end;

end;

//仅在某区域显示战场图

procedure DrawBPicInRect(num, px, py, shadow, x, y, w, h: integer);
var
  Area: TSDL_Rect;
begin
  if (num > 0) and (num < BPicAmount) then
  begin
    Area.x := x;
    Area.y := y;
    Area.w := w;
    Area.h := h;
    if PNG_TILE > 0 then
    begin
      //LoadOnePNGTile('resource/wmap/', num, BPNGIndex[num], @BPNGTile[0]);
      DrawPNGTile(BPNGIndex[num], 0, @Area, screen, px, py);
    end
    else
    begin
      DrawRLE8Pic(@ACol[0], num, px, py, @WIdx[0], @WPic[0], @Area, nil, 0, 0, 0, shadow);
    end;
  end;
end;

//将战场图片画到映像

procedure InitialBPic(num, px, py: integer); overload;
begin
  InitialBPic(num, px, py, 0, 0);
end;

//画到映像并记录深度

procedure InitialBPic(num, px, py, needBlock, depth: integer); overload;
var
  pImg: PSDL_Surface;
begin
  if (num > 0) and (num < BPicAmount) then
  begin
    if PNG_TILE > 0 then
    begin
      LoadOnePNGTile('resource/wmap/', nil, num, BPNGIndex[num], @BPNGTile[0]);
      if needBlock <> 0 then
      begin
        SetPNGTileBlock(BPNGIndex[num], px, py, depth, @BlockImg[0], ImageWidth, ImageHeight, sizeof(BlockImg[0]));
        pImg := ImgBBuild;
      end
      else
        pImg := ImgBfield;
      DrawPNGTile(BPNGIndex[num], 0, nil, pImg, px, py);
    end
    else
    begin
      if needBlock <> 0 then
        DrawRLE8Pic(@ACol[0], num, px, py, @WIdx[0], @WPic[0], nil, ImgBBuild, ImageWidth, ImageHeight,
          sizeof(BlockImg2[0]), 0, 0, @BlockImg2[0], nil, 0, 0, 0, depth, 0, 0)
      else
        DrawRLE8Pic(@ACol[0], num, px, py, @WIdx[0], @WPic[0], nil, ImgBfield, ImageWidth,
          ImageHeight, sizeof(BlockImg2[0]), 0);
    end;
  end;
end;

//显示效果图片

procedure DrawEPic(num, px, py: integer); overload;
begin
  DrawEPic(num, px, py, 0, 0, 0, 0, 0);

end;

procedure DrawEPic(num, px, py, shadow, alpha, depth: integer; mixColor: Uint32; mixAlpha: integer); overload;
begin
  if (num >= 0) and (num < EPicAmount) then
  begin
    if PNG_TILE > 0 then
    begin
      DrawPNGTile(EPNGIndex[num], 0, nil, screen, px, py, shadow, alpha, mixColor, mixAlpha,
        depth, nil, 0, 0, 0, 0, 0);
    end;
    if PNG_TILE = 0 then
    begin
      DrawRLE8Pic(@ACol[0], num, px, py, @EIdx[0], @EPic[0], nil, nil, 0, 0, 0, shadow, alpha,
        nil, nil, 0, 0, 0, depth, mixColor, mixAlpha);
    end;
  end;
end;

//显示人物动作图片

procedure DrawFPic(num, px, py, index: integer); overload;
begin
  DrawFPic(num, px, py, 0, 0, 0, 0, 0, index);

end;

//用于画带透明度和遮挡的人物动作图片

procedure DrawFPic(num, px, py, index, shadow, alpha, depth: integer; mixColor: Uint32; mixAlpha: integer); overload;
begin
  case PNG_TILE of
    1, 2:
    begin
      if (index >= 0) and (index < BRoleAmount) then
        if (num >= Low(FPNGIndex[index])) and (num <= High(FPNGIndex[index])) then
          DrawPNGTile(FPNGIndex[index][num], 0, nil, screen, px, py, shadow, alpha, mixColor, mixAlpha,
            depth, @BlockImg2[0], ImageWidth, ImageHeight, sizeof(BlockImg2[0]), BlockScreen.x, BlockScreen.y);
    end;
    0:
    begin
      if num < FPicAmount then
        DrawRLE8Pic(@ACol[0], num, px, py, @FIdx[0], @FPic[0], nil, nil, 0, 0, 0, shadow,
          alpha, @BlockImg2[0], @BlockScreen, ImageWidth, ImageHeight, sizeof(BlockImg2[0]),
          depth, mixColor, mixAlpha);
    end;
  end;
end;

//主地图上画云

procedure DrawCPic(num, px, py, shadow, alpha: integer; mixColor: Uint32; mixAlpha: integer);
begin
  if PNG_TILE > 0 then
  begin
    DrawPNGTile(CPNGIndex[num], 0, nil, screen, px, py, shadow, alpha, mixColor, MixAlpha);
  end;
  if PNG_TILE = 0 then
  begin
    DrawRLE8Pic(@ACol1[0], num, px, py, @CIdx[0], @CPic[0], nil, nil, 0, 0, 0, shadow, alpha,
      nil, nil, 0, 0, 0, 0, mixColor, mixAlpha);
  end;
end;

//重画屏幕

procedure Redraw(WriteFresh: integer = 0);
begin
  case where of
    0: DrawMMap;
    1: DrawScence;
    2: DrawWholeBField;
    3:
    begin
      SDL_FillRect(screen, nil, 0);
      display_img(PChar(AppPath + 'resource/open.png'), OpenPicPosition.x, OpenPicPosition.y);
    end;
    4:
    begin
      SDL_FillRect(screen, nil, 0);
      display_img(PChar(AppPath + 'resource/dead.png'), OpenPicPosition.x, OpenPicPosition.y);
    end;
  end;
  if WriteFresh = 1 then
    SDL_BlitSurface(screen, nil, freshscreen, nil);
end;

//以下两个函数用于需要连续几个相同帧时的快速重绘

procedure WriteFreshScreen(x, y, w, h: integer);
var
  dest: TSDL_Rect;
begin
  dest.x := x;
  dest.y := y;
  dest.w := w;
  dest.h := h;
  SDL_BlitSurface(screen, @dest, freshscreen, @dest);
end;

procedure ReadFreshScreen(x, y, w, h: integer);
var
  dest: TSDL_Rect;
begin
  dest.x := x;
  dest.y := y;
  dest.w := w;
  dest.h := h;
  SDL_BlitSurface(freshscreen, @dest, screen, @dest);
end;


//显示主地图场景于屏幕

{procedure DrawMMap;
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
      end
      else
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
              DrawMPic(2501 + MFace * 7 + MStep, CENTER_X, CENTER_Y)
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
  //SDL_UpdateRect2(screen, 0,0,screen.w,screen.h);

end;}


//注意: 按照主地图的定义, 以下排序方式应该是准确的, 但是原版有些地方的引用建筑值设置不正确, 效果并不好

{procedure DrawMMap;
var
  i1, i2, i, sum, x, y, k, j1, j2, BAmount, mini1, mini2, swaptemp, a, b, col: integer;
  temp, tempindex: array[0..479, 0..479] of smallint;
  width, height: smallint;
  pos: TPosition;
  List, ListIndex, BuildingPic: array[0..10000] of integer;
  BuildingPos: array[0..10000] of TPosition;
begin
  if (SDL_MustLock(screen)) then
  begin
    if (SDL_LockSurface(screen) < 0) then
    begin
      MessageBox(0, PChar(Format('Can''t lock screen : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
  end;

  for i1 := 0 to 479 do
    for i2 := 0 to 479 do
    begin
    temp[i1, i2] := -1;
      tempindex[i1, i2] := -1;
    end;

  mini1 := Mx - 16 - 14;
  mini2 := My - 16 - 15;
  k := 0;
  for sum := -29 to 41 do
    for i := -16 to 16 do
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
      end
      else
        DrawMPic(0, pos.x, pos.y);

      if building[i1, i2] > 0 then
      begin
        List[k] := k;
        ListIndex[k] := k;
        BuildingPos[k].x := i1;
        BuildingPos[k].y := i2;
        BuildingPic[k] := building[i1, i2] div 2;
        temp[i1, i2] := k;
        for j1 := i1 downto mini1 do
        begin
          for j2 := i2 downto mini2 do
          begin
            if j1 + j2 < Mx + My - 29 then
              continue;
            if (BuildX[j1, j2] = i2) and (BuildY[j1, j2] = i1) then
            begin
              tempindex[j1, j2] := k;
            end;
          end;
        end;
        k := k + 1;
      end;
      if (i1 = Mx) and (i2 = My) then
      begin
        List[k] := k;
        ListIndex[k] := k;
        BuildingPos[k].x := i1;
        BuildingPos[k].y := i2;
        temp[i1, i2] := k;
        tempindex[i1, i2] := k;
        if InShip = 0 then
          if still = 0 then
            BuildingPic[k] := 2501 + MFace * 7 + MStep
          else
            BuildingPic[k] := 2528 + Mface * 6 + MStep
          else
            BuildingPic[k] := 3714 + MFace * 4 + (MStep + 1) div 2;
        k := k + 1;
      end;
    end;
  BAmount := k;

  for sum := -29 to 41 do
  begin
    for i := -16 to 16 do
    begin
      i1 := Mx + i + (sum div 2);
      i2 := My - i + (sum - sum div 2);
      if temp[i1, i2] < 0 then
      begin
        continue;
      end;
      for j1 := i1 downto mini1 do
      begin
        for j2 := i2 downto mini2 do
        begin
          if j1 + j2 < Mx + My - 29 then
            continue;
          b := temp[i1, i2];
          a := tempindex[j1, j2];
          if (ListIndex[b] < ListIndex[a]) and (a < BAmount) then
          begin
            swaptemp := List[ListIndex[a]];
            for k := ListIndex[a] downto ListIndex[b] + 1 do
              List[k] := List[k - 1];
            List[ListIndex[b]] := swaptemp;
            for k := 0 to BAmount - 1 do
            begin
              ListIndex[List[k]] := k;
            end;
          end;
        end;
      end;
    end;
  end;

  for i := 0 to BAmount - 1 do
  begin
    x := BuildingPos[List[i]].x;
    y := BuildingPos[List[i]].y;
    Pos := GetPositionOnScreen(x, y, Mx, My);
    DrawMPic(BuildingPic[List[i]], pos.x, pos.y);
  end;

  DrawClouds;

  if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;
  //SDL_UpdateRect2(screen, 0,0,screen.w,screen.h);

end;}

procedure DrawMMap;
var
  i1, i2, i, sum, x, y, k, c, widthregion, sumregion, num: integer;
  temp: array[0..479, 0..479] of smallint;
  Width, Height, yoffset: smallint;
  pos: TPosition;
  BuildingList: array[0..2000] of TPosition;
  CenterList: array[0..2000] of integer;
  tempscr, tempscr1: PSDL_Surface;
  dest: TSDL_Rect;
begin
  {if BIG_PNG_TILE = 1 then
  begin
    SDL_FillRect(screen, nil, 0);
    dest.x := (-Mx * 18 + My * 18 + 8640 - CENTER_X) div 2;
    dest.y := (Mx * 9 + My * 9 + 18 - CENTER_Y) div 2;
    //dest.x := 8640 div 2;
    //dest.y := 4320 div 2;
    dest.w := CENTER_X;
    dest.h := CENTER_Y;
    tempscr := SDL_CreateRGBSurface(screen.flags, CENTER_X, CENTER_Y, 32, 0, 0, 0, 0);
    SDL_BlitSurface(MMapSurface, @dest, tempscr, nil);
    tempscr1 := sdl_gfx.zoomSurface(tempscr, 2, 2, 0);
    SDL_BlitSurface(tempscr1, nil, screen, nil);
    SDL_FreeSurface(tempscr);
    SDL_FreeSurface(tempscr1);
  end;}
  //由上到下绘制, 先绘制地面和表面, 同时计算出现的建筑数
  k := 0;
  widthregion := CENTER_X div 36 + 3;
  sumregion := CENTER_Y div 9 + 2;
  for sum := -sumregion to sumregion + 15 do
    for i := -Widthregion to Widthregion do
    begin
      if k >= High(CenterList) then
        break;
      i1 := Mx + i + (sum div 2);
      i2 := My - i + (sum - sum div 2);
      Pos := GetPositionOnScreen(i1, i2, Mx, My);
      if (i1 >= 0) and (i1 < 480) and (i2 >= 0) and (i2 < 480) then
      begin
        if (BIG_PNG_TILE = 0) then
        begin
          DrawMPic(earth[i1, i2] div 2, pos.x, pos.y);
          if surface[i1, i2] > 0 then
            DrawMPic(surface[i1, i2] div 2, pos.x, pos.y);
        end;

        temp[i1, i2] := 0;
        if building[i1, i2] <> 0 then
          temp[i1, i2] := building[i1, i2];
        //将主角的位置计入建筑
        if (i1 = Mx) and (i2 = My) then
        begin
          if (InShip = 0) then
            if still = 0 then
              temp[i1, i2] := 2501 + MFace * 7 + MStep
            else
              temp[i1, i2] := 2528 + Mface * 6 + MStep
          else
            temp[i1, i2] := 3715 + MFace * 4 + (MStep + 1) div 2;
          temp[i1, i2] := temp[i1, i2] * 2;
        end;
        num := temp[i1, i2] div 2;
        if (num > 0) and (num < MPicAmount) then
        begin
          BuildingList[k].x := i1;
          BuildingList[k].y := i2;
          if PNG_TILE > 0 then
          begin
            if MPNGIndex[num].CurPointer <> nil then
            begin
              if MPNGIndex[num].CurPointer^ <> nil then
              begin
                Width := MPNGIndex[num].CurPointer^.w;
                Height := MPNGIndex[num].CurPointer^.h;
                yoffset := MPNGIndex[num].y;
              end;
            end;
          end
          else
          begin
            Width := smallint(Mpic[MIdx[num - 1]]);
            Height := smallint(Mpic[MIdx[num - 1] + 2]);
            yoffset := smallint(Mpic[MIdx[num - 1] + 6]);
          end;
          //根据图片的宽度计算图的中点的坐标和作为排序依据
          CenterList[k] := (i1 + i2) - (Width + 35) div 36 - (yoffset - Height + 1) div 9;
          if (i1 = Mx) and (i2 = My) then
            CenterList[k] := i1 + i2;
          k := k + 1;
        end;
      end
      else
        DrawMPic(0, pos.x, pos.y);
    end;
  //按照中点坐标排序
  for i1 := 0 to k - 2 do
    for i2 := i1 + 1 to k - 1 do
    begin
      if CenterList[i1] > CenterList[i2] then
      begin
        pos := BuildingList[i1];
        BuildingList[i1] := BuildingList[i2];
        BuildingList[i2] := pos;
        c := CenterList[i1];
        CenterList[i1] := CenterList[i2];
        CenterList[i2] := c;
      end;
    end;
  for i := 0 to k - 1 do
  begin
    x := BuildingList[i].x;
    y := BuildingList[i].y;
    Pos := GetPositionOnScreen(x, y, Mx, My);
    DrawMPic(temp[x, y] div 2, pos.x, pos.y);
  end;
  DrawClouds;

end;


//画场景到屏幕

procedure DrawScence;
var
  i1, i2, x, y, xpoint, ypoint: integer;
begin
  //先画无主角的场景, 再画主角
  //如在事件中, 则以Cx, Cy为中心, 否则以主角坐标为中心

  if (CurEvent < 0) then
  begin
    DrawScenceWithoutRole(Sx, Sy);
    CurScenceRolePic := BEGIN_WALKPIC + SFace * 7 + SStep;
    DrawRoleOnScence(Sx, Sy);
  end
  else
  begin
    DrawScenceWithoutRole(Cx, Cy);
    if (DData[CurScence, CurEvent, 10] = Sx) and (DData[CurScence, CurEvent, 9] = Sy) then
    begin
      if DData[CurScence, CurEvent, 5] <= 0 then
      begin
        DrawRoleOnScence(Cx, Cy);
      end;
    end
    else
      DrawRoleOnScence(Cx, Cy);
  end;

end;

//画不含主角的场景(与DrawScenceByCenter相同)

procedure DrawScenceWithoutRole(x, y: integer);
var
  x1, y1: integer;
begin
  CalLTPosOnImageByCenter(x, y, x1, y1);
  LoadScencePart(x1, y1);
end;

//画主角于场景

procedure DrawRoleOnScence(x, y: integer);
var
  depth: integer;
  pos: TPosition;
begin
  pos := GetPositionOnScreen(Sx, Sy, x, y);
  DrawSPic(CurScenceRolePic, pos.x, pos.y - SData[CurScence, 4, Sx, Sy], 0, 100, CalBlock(Sx, Sy), 0, 0);

end;

procedure ExpandGroundOnImg();
var
  i1, i2, x, y, num: integer;
begin
  if EXPAND_GROUND <> 0 then
  begin
    fillchar(ExGround, sizeof(ExGround), 0);
    for i1 := 0 to 63 do
      for i2 := 0 to 63 do
      begin
        case where of
          1: ExGround[i1, i2] := SData[CurScence, 0, i1, i2];
          2: ExGround[i1, i2] := Bfield[0, i1, i2];
        end;
      end;
    for i1 := 31 downto -64 do
      for i2 := 0 to 63 do
      begin
        if ExGround[i1, i2] <= 0 then ExGround[i1, i2] := ExGround[i1 + 1, i2];
      end;
    for i1 := 32 to 127 do
      for i2 := 0 to 63 do
      begin
        if ExGround[i1, i2] <= 0 then ExGround[i1, i2] := ExGround[i1 - 1, i2];
      end;
    for i1 := -64 to 127 do
      for i2 := 31 downto -64 do
      begin
        if ExGround[i1, i2] <= 0 then ExGround[i1, i2] := ExGround[i1, i2 + 1];
      end;
    for i1 := -64 to 127 do
      for i2 := 32 to 127 do
      begin
        if ExGround[i1, i2] <= 0 then ExGround[i1, i2] := ExGround[i1, i2 - 1];
      end;
    for i1 := -64 to 127 do
      for i2 := -64 to 127 do
      begin
        CalPosOnImage(i1, i2, x, y);
        num := ExGround[i1, i2] div 2;
        case where of
          1: InitialSPic(num, x, y, 0, 0, ImageWidth, ImageHeight, 0, 0, 0);
          2: InitialBPic(num, x, y, 0, 0);
        end;
      end;
  end;
end;

//Save the image informations of the whole scence.
//生成场景映像

procedure InitialScence(); overload;
begin
  InitialScence(0);

end;

//如参数不为0, 仅修改可见部分的场景映像. 参数为0与无参数相同

procedure InitialScence(Visible: integer); overload;
var
  i1, i2, x, y, x1, y1, w, h: integer;
  pos: TPosition;
  mini, maxi, num, onback: integer;
  dest: TSDL_Rect;
begin
  SDL_LockMutex(mutex);
  LoadingScence := True;
  if Visible = 0 then
  begin
    x1 := 0;
    y1 := 0;
    w := ImageWidth;
    h := ImageHeight;
    SDL_FillRect(ImgScence, nil, 0);
    SDL_FillRect(ImgScenceBack, nil, 1);
    ExpandGroundOnImg();
  end
  else
  begin
    if CurEvent >= 0 then
    begin
      CalLTPosOnImageByCenter(Cx, Cy, x1, y1);
    end
    else
    begin
      CalLTPosOnImageByCenter(Sx, Sy, x1, y1);
    end;
    w := screen.w;
    h := screen.h;
  end;

  if (Visible > 0) and (where = 1) then
    onback := 1
  else
    onback := 0;

  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      CalPosOnImage(i1, i2, x, y);
      if SData[CurScence, 4, i1, i2] <= 0 then
      begin
        num := SData[CurScence, 0, i1, i2] div 2;
        if num > 0 then
          InitialSPic(num, x, y, x1, y1, w, h, 1, 0, onback);
      end;
    end;
  for mini := 0 to 63 do
  begin
    InitialScenceOnePosition(mini, mini, x1, y1, w, h, CalBlock(mini, mini), onback);
    for maxi := mini + 1 to 63 do
    begin
      InitialScenceOnePosition(maxi, mini, x1, y1, w, h, CalBlock(maxi, mini), onback);
      InitialScenceOnePosition(mini, maxi, x1, y1, w, h, CalBlock(mini, maxi), onback);
    end;
  end;

  if (Visible > 0) and (where = 1) and (x1 >= 0) and (y1 >= 0) then
  begin
    //遮挡值仅更新主角附近的即可
    CalPosOnImage(Sx, Sy, x, y);
    x := x - 36;
    y := y - 100;
    for i1 := x to x + 72 do
      //for i2:=y to y+100 do
    begin
      num := i1 * ImageHeight + y;
      //blockImg[num]:=blockImg2[num];
      move(BlockImg2[num], BlockImg[num], 200);
    end;
    //Move(BlockImg2[0], BlockImg[0], sizeof(BlockImg[0])*length(BlockImg));
    dest.x := x1;
    dest.y := y1;
    dest.w := w;
    dest.h := h;
    SDL_BlitSurface(ImgScenceBack, @dest, ImgScence, @dest);
  end;
  LoadingScence := False;
  SDL_UnLockMutex(mutex);
end;

function CalBlock(x, y: integer): integer;
begin
  //Result := 128 * min(x, y) + abs(x - y);
  //Result := 8192 - (x - 64) * (x - 64) - (y - 64) * (y - 64);
  Result := 128 * (x + y) + y;
end;

procedure CalPosOnImage(i1, i2: integer; var x, y: integer);
begin
  x := -i1 * 18 + i2 * 18 + ImageWidth div 2;
  y := i1 * 9 + i2 * 9 + 9 + CENTER_Y;
end;

procedure CalLTPosOnImageByCenter(i1, i2: integer; var x, y: integer);
begin
  x := -i1 * 18 + i2 * 18 + ImageWidth div 2 - CENTER_X;
  y := i1 * 9 + i2 * 9 + 9;
end;


//上面函数的子程

procedure InitialScenceOnePosition(i1, i2, x1, y1, w, h, depth, temp: integer);
var
  i, x, y, num: integer;
begin
  CalPosOnImage(i1, i2, x, y);
  //InitialSPic2(SData[CurScence, 0, i1, i2] div 2, x, y, x1, y1, w, h, 1);
  if SData[CurScence, 4, i1, i2] > 0 then
  begin
    num := SData[CurScence, 0, i1, i2] div 2;
    InitialSPic(num, x, y, x1, y1, w, h, 1, depth, temp);
  end;
  if (SData[CurScence, 1, i1, i2] > 0) {and (SData[CurScence, 4, i1, i2] > 0)} then
  begin
    num := SData[CurScence, 1, i1, i2] div 2;
    InitialSPic(num, x, y - SData[CurScence, 4, i1, i2], x1, y1, w, h, 1, depth, temp);
  end;
  if (SData[CurScence, 2, i1, i2] > 0) then
  begin
    num := SData[CurScence, 2, i1, i2] div 2;
    InitialSPic(num, x, y - SData[CurScence, 5, i1, i2], x1, y1, w, h, 1, depth, temp);
  end;
  if (SData[CurScence, 3, i1, i2] >= 0) then
  begin
    num := DData[CurScence, SData[CurScence, 3, i1, i2], 5] div 2;
    if num > 0 then
    begin
      for i := DData[CurScence, SData[CurScence, 3, i1, i2], 7] div 2
        to DData[CurScence, SData[CurScence, 3, i1, i2], 6] div 2 do
        if (temp = 0) and (PNG_TILE > 0) then
          LoadOnePNGTile('resource/smap/', nil, i, SPNGIndex[i], @SPNGTile[0]);
      if SCENCEAMI = 2 then
        InitialSPic(num, x, y - SData[CurScence, 4, i1, i2], x1, y1, w, h, 1, depth, temp);
    end;
  end;
  //if (i1 = Sx) and (i2 = Sy) then
  //InitialSPic(2501 + SFace * 7 + SStep, x, y - SData[CurScence, 4, Sx, Sy], x1, y1, w, h);
end;

//更改场景映像, 用于动画, 场景内动态效果

procedure UpdateScence(xs, ys: integer);
var
  i1, i2, x, y: integer;
  num, offset: integer;
  xp, yp, w, h: smallint;
begin
  xp := -xs * 18 + ys * 18 + 1151;
  yp := xs * 9 + ys * 9 + 250;
  //如在事件中直接给定更新范围
  if CurEvent < 0 then
  begin
    num := DData[CurScence, SData[CurScence, 3, xs, ys], 5] div 2;
    if num > 0 then
      offset := SIdx[num - 1];
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
  //计算贴图高度和宽度作为更新范围
  offset := max(h div 18, w div 36);
  for i1 := xs - offset to xs + 5 do
    for i2 := ys - offset to ys + 5 do
    begin
      x := -i1 * 18 + i2 * 18 + 1151;
      y := i1 * 9 + i2 * 9 + 9 + 250;
      InitialSPic(SData[CurScence, 0, i1, i2] div 2, x, y, xp, yp, w, h);
      if (i1 < 0) or (i2 < 0) or (i1 > 63) or (i2 > 63) then
        InitialSPic(0, x, y, xp, yp, w, h)
      else
      begin
        //InitialSPic(SData[CurScence, 0, i1,i2] div 2,x,y,xp,yp,w,h);
        if (SData[CurScence, 1, i1, i2] > 0) then
          InitialSPic(SData[CurScence, 1, i1, i2] div 2, x, y - SData[CurScence, 4, i1, i2], xp, yp, w, h);
        //if (i1=Sx) and (i2=Sy) then
        //InitialSPic(BEGIN_WALKPIC+SFace*7+SStep,x,y-SData[CurScence, 4, i1,i2],0,0,2304,1152);
        if (SData[CurScence, 2, i1, i2] > 0) then
          InitialSPic(SData[CurScence, 2, i1, i2] div 2, x, y - SData[CurScence, 5, i1, i2], xp, yp, w, h);
        if (SData[CurScence, 3, i1, i2] >= 0) and (DData[CurScence, SData[CurScence, 3, i1, i2], 5] > 0) then
          InitialSPic(DData[CurScence, SData[CurScence, 3, i1, i2], 5] div 2, x, y -
            SData[CurScence, 4, i1, i2], xp, yp, w, h);
        //if (i1=RScence[CurScence*26+15]) and (i2=RScence[CurScence*26+14]) then
        //DrawSPic(0,-(i1-Sx)*18+(i2-Sy)*18+CENTER_X,(i1-Sx)*9+(i2-Sy)*9+CENTER_Y);
        //if (i1=Sx) and (i2=Sy) then DrawSPic(2501+SFace*7+SStep,CENTER_X,CENTER_Y-SData[CurScence, 4, i1,i2]);
      end;
    end;

end;

//将场景映像画到屏幕并载入遮挡数据

procedure LoadScencePart(x, y: integer);
var
  i1, i2: integer;
  dest, dest2: TSDL_Rect;
begin
  dest.x := x;
  dest.y := y;
  dest.w := screen.w;
  dest.h := screen.h;
  dest2.x := 0;
  dest2.y := 0;
  dest2.w := screen.w;
  dest2.h := screen.h;
  BlockScreen.x := x;
  BlockScreen.y := y;
  //if (x < 0) or (x >= 2304 - CENTER_X * 2) then
  //SDL_FillRect(screen, nil, 0);
  SDL_BlitSurface(ImgScence, @dest, screen, nil);

end;

//画战场

procedure DrawWholeBField(needProgress: integer = 1);
var
  i, i1, i2: integer;
begin
  {if (SDL_MustLock(screen)) then
  begin
    if (SDL_LockSurface(screen) < 0) then
    begin
      MessageBox(0, PChar(Format('Can''t lock screen : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
  end;}
  DrawBfieldWithoutRole(Bx, By);

  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      if (Bfield[2, i1, i2] >= 0) and (Brole[Bfield[2, i1, i2]].Dead = 0) then
        DrawRoleOnBfield(i1, i2);
    end;

  if needProgress = 1 then
    DrawProgress;
  //BfieldDrawn := 1;
  {if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;}
end;

//画不含主角的战场

procedure DrawBfieldWithoutRole(x, y: integer);
var
  x1, y1: integer;
begin
  CalLTPosOnImageByCenter(x, y, x1, y1);
  LoadBfieldPart(x1, y1);
end;

//画战场上人物, 需更新人物身前的遮挡

procedure DrawRoleOnBfield(x, y: integer; MixColor: Uint32 = 0; MixAlpha: integer = 0; Alpha: integer = 75);
var
  i1, i2, xpoint, ypoint, depth: integer;
  pos, pos1: Tposition;
begin
  pos := GetPositionOnScreen(x, y, Bx, By);
  //for i1 := x - 1 to x + 10 do
  //for i2 := y - 1 to y + 10 do
  //begin
  //if (i1 = x) and (i2 = y) then
  //if BRole[Bfield[2, x, y]].ShowNumber < 0 then
  //DrawBPic2(Rrole[Brole[Bfield[2, x, y]].rnum].HeadNum * 4 + Brole[Bfield[2, x, y]].Face + BEGIN_BATTLE_ROLE_PIC, pos.x, pos.y, 0, 75, x + y, $00FF0000, 50)
  //else
  depth := CalBlock(x, y);
  if MODVersion = 62 then
  begin
    DrawBPic(Rrole[Brole[Bfield[2, x, y]].rnum].ListNum * 4 + Brole[Bfield[2, x, y]].Face + BEGIN_BATTLE_ROLE_PIC,
      pos.x, pos.y, 0, Alpha, depth, MixColor, MixAlpha);
    exit;
  end;
  DrawBPic(Rrole[Brole[Bfield[2, x, y]].rnum].HeadNum * 4 + Brole[Bfield[2, x, y]].Face + BEGIN_BATTLE_ROLE_PIC,
    pos.x, pos.y, 0, Alpha, depth, MixColor, MixAlpha);

  //if (Bfield[1, i1, i2] > 0) then
  {begin
    pos1 := GetPositionOnScreen(i1, i2, Bx, By);
    DrawBPicInRect(Bfield[1, i1, i2] div 2, pos1.x, pos1.y, 0, pos.x - 20, pos.y - 60, 40, 60);
    if (Bfield[2, i1, i2] >= 0) and (Brole[Bfield[2, i1, i2]].Dead = 0) then
      DrawBPicInRect(Rrole[Brole[Bfield[2, x, y]].rnum].HeadNum * 4 + Brole[Bfield[2, i1, i2]].Face + BEGIN_BATTLE_ROLE_PIC, pos1.x, pos1.y, 0, pos.x - 20, pos.y - 60, 40, 60);
  end;}

end;

//初始化战场映像

procedure InitialBFieldImage;
var
  sumi, i1, i2: integer;
begin
  FillChar(BlockImg2[0], sizeof(BlockImg2[0]) * length(BlockImg2), -1);
  SDL_FillRect(ImgBField, nil, 0);
  SDL_FillRect(ImgBBuild, nil, 1);
  ExpandGroundOnImg();
  for sumi := 0 to 126 do
  begin
    //InitialBFieldPosition(mini, mini, CalBlock(mini, mini));
    for i1 := 63 downto 0 do
    begin
      //InitialBFieldPosition(maxi, mini, CalBlock(maxi, mini));
      //InitialBFieldPosition(mini, maxi, CalBlock(mini, maxi));
      i2 := sumi - i1;
      if (i2 >= 0) and (i2 <= 63) then
        InitialBFieldPosition(i1, i2, CalBlock(i1, i2));
    end;
  end;

end;

procedure InitialBFieldPosition(i1, i2, depth: integer);
var
  x, y: integer;
begin
  if (i1 < 0) or (i2 < 0) or (i1 > 63) or (i2 > 63) then
  begin
    //InitialBPic(0, x, y, 0, 0);
  end
  else
  begin
    CalPosOnImage(i1, i2, x, y);
    if EXPAND_GROUND = 0 then
      InitialBPic(bfield[0, i1, i2] div 2, x, y, 0, 0);
    if (bfield[1, i1, i2] > 0) then
    begin
      InitialBPic(bfield[1, i1, i2] div 2, x, y, 1, depth);
    end;
  end;
end;

//将战场映像画到屏幕并载入遮挡数据

procedure LoadBfieldPart(x, y: integer);
var
  i1, i2: integer;
  dest: TSDL_Rect;
begin
  dest.x := x;
  dest.y := y;
  dest.w := screen.w;
  dest.h := screen.h;
  BlockScreen.x := x;
  BlockScreen.y := y;
  //if (x < 0) or (x >= 2304 - CENTER_X * 2) then
  //SDL_FillRect(screen, nil, 0);
  SDL_BlitSurface(ImgBfield, @dest, screen, nil);
  LoadBFieldPart2(x, y, 0);
  //SDL_BlitSurface(ImgBBuild, @dest, screen, nil);

end;

//直接载入建筑层Surface, 将战场分成两部分是为绘制带光标战场时可以单独载入建筑层

procedure LoadBFieldPart2(x, y, alpha: integer);
var
  i1, i2: integer;
  pix, colorin: Uint32;
  pix1, pix2, pix3, pix4, color1, color2, color3, color4: byte;
  dest: TSDL_Rect;
begin
  dest.x := x;
  dest.y := y;
  dest.w := screen.w;
  dest.h := screen.h;
  SDL_SetAlpha(ImgBBuild, SDL_SRCALPHA, 255 - alpha * 255 div 100);
  SDL_BlitSurface(ImgBBuild, @dest, screen, nil);
  //SDL_SetAlpha(ImgBBuild, SDL_SRCALPHA, 255);
  {for i1 := 0 to screen.w - 1 do
    for i2 := 0 to screen.h - 1 do
      if (x + i1 >= 0) and (y + i2 >= 0) and (x + i1 < 2304) and (y + i2 < 1152) and (BlockScreen[i1 * screen.h + i2] > 0) then
      begin
        pix := getpixel(Img, x + i1, y + i2);
        if alpha <> 0 then
        begin
          colorin := getpixel(screen, i1, i2);
          pix1 := pix and $FF;
          color1 := colorin and $FF;
          pix2 := pix shr 8 and $FF;
          color2 := colorin shr 8 and $FF;
          pix3 := pix shr 16 and $FF;
          color3 := colorin shr 16 and $FF;
          pix4 := pix shr 24 and $FF;
          color4 := colorin shr 24 and $FF;
          pix1 := (alpha * color1 + (100 - alpha) * pix1) div 100;
          pix2 := (alpha * color2 + (100 - alpha) * pix2) div 100;
          pix3 := (alpha * color3 + (100 - alpha) * pix3) div 100;
          pix4 := (alpha * color4 + (100 - alpha) * pix4) div 100;
          pix := pix1 + pix2 shl 8 + pix3 shl 16 + pix4 shl 24;
        end;
        putpixel(screen, i1, i2, pix);
      end;}

end;

//画带光标的子程
//此子程效率不高- has been improved

procedure DrawBFieldWithCursor(step: integer);
var
  i, i1, i2, bnum, depth, x, y: integer;
  pos: TPosition;
begin
  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
      if Bfield[0, i1, i2] > 0 then
      begin
        pos := GetPositionOnScreen(i1, i2, Bx, By);
        if {(i1 = Ax) and (i2 = Ay)}  Bfield[4, i1, i2] > 0 then
          //DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 0, 0, 0, $FFFFFFFF, 20)
          DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 1)
        else if (BField[3, i1, i2] >= 0) and (abs(i1 - Bx) + abs(i2 - By) <= step) then
          DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 0)
        else
          DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 0, 0, 0, 0, 33);
        {if (i1 = Ax) and (i2 = Ay) then
          DrawMPic(1, pos.x, pos.y);}
      end;
  CalLTPosOnImageByCenter(Bx, By, x, y);
  LoadBFieldPart2(x, y, 35);

  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      pos := GetPositionOnScreen(i1, i2, Bx, By);
      bnum := Bfield[2, i1, i2];
      if (bnum >= 0) and (Brole[bnum].Dead = 0) then
      begin
        if (Brole[bnum].Team <> Brole[Bfield[2, Bx, By]].Team) and (Bfield[4, i1, i2] > 0) then
          DrawBPic(Rrole[Brole[bnum].rnum].HeadNum * 4 + Brole[bnum].Face + BEGIN_BATTLE_ROLE_PIC,
            pos.x, pos.y, 0, 75, CalBlock(i1, i2), $FFFFFFFF, 20)
        else
          DrawBPic(Rrole[Brole[bnum].rnum].HeadNum * 4 + Brole[bnum].Face + BEGIN_BATTLE_ROLE_PIC,
            pos.x, pos.y, 0, 75, CalBlock(i1, i2), 0, 0);

      end;
    end;
  DrawProgress;

end;

//画带效果的战场

procedure DrawBFieldWithEft(Epicnum: integer); overload;
var
  i, i1, i2: integer;
  pos: TPosition;
begin
  {if (SDL_MustLock(screen)) then
  begin
    if (SDL_LockSurface(screen) < 0) then
    begin
      MessageBox(0, PChar(Format('Can''t lock screen : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
  end;}
  DrawBfieldWithoutRole(Bx, By);

  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      pos := GetPositionOnScreen(i1, i2, Bx, By);
      if (Bfield[2, i1, i2] >= 0) and (Brole[Bfield[2, i1, i2]].Dead = 0) then
        DrawRoleOnBfield(i1, i2);
      if Bfield[4, i1, i2] > 0 then
        DrawEPic(Epicnum, pos.x, pos.y, 0, 25, 0, 0, 0);
    end;
  DrawProgress;
  //BFieldDrawn := 1;
  {if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;}

end;

procedure DrawBFieldWithEft(Epicnum, beginpic, endpic, bnum: integer; MixColor: Uint32); overload;
var
  i, i1, i2: integer;
  pos: TPosition;
begin
  DrawBfieldWithoutRole(Bx, By);

  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      pos := GetPositionOnScreen(i1, i2, Bx, By);
      if (Bfield[2, i1, i2] >= 0) and (Brole[Bfield[2, i1, i2]].Dead = 0) then
        DrawRoleOnBfield(i1, i2, 0, 50);
      if (Bfield[4, i1, i2] > 0) and (Epicnum - Bfield[4, i1, i2] + 1 >= beginpic) and
        (Epicnum - Bfield[4, i1, i2] + 1 <= endpic) then
        DrawEPic(Epicnum - Bfield[4, i1, i2] + 1, pos.x, pos.y, 0, 25, 0, 0, 0);
    end;
  DrawProgress;

end;

procedure DrawBFieldWithEft(Epicnum, beginpic, endpic, curlevel, bnum, forteam, flash: integer;
  MixColor: Uint32); overload;
var
  k, i1, i2: integer;
  pos: TPosition;
begin
  DrawBfieldWithoutRole(Bx, By);
  //ReadFreshScreen(0, 0, screen.w, screen.h);
  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      pos := GetPositionOnScreen(i1, i2, Bx, By);
      k := Bfield[2, i1, i2];
      if (k >= 0) and (Brole[k].Dead = 0) then
      begin
        flash := 0;
        if (Bfield[4, Brole[k].X, Brole[k].Y] > 0) then
        begin
          if forteam = 0 then
          begin
            if (Brole[bnum].Team <> Brole[k].Team) then
              flash := 1;
          end
          else
          begin
            if (Brole[bnum].Team = Brole[k].Team) then
              flash := 1;
          end;
        end;
        //行动人物的动作停留在最后一帧
        if (bnum = k) and (Brole[bnum].pic > 0) then
          DrawFPic(Brole[bnum].pic, pos.x, pos.y, Brole[bnum].Bhead, 0, 75, CalBlock(i1, i2),
            mixColor, flash * (10 + random(40)))
        else
          DrawRoleOnBfield(i1, i2, MixColor, flash * (10 + random(40)));
      end;
      if (Bfield[4, i1, i2] > 0) {and (Bfield[1, i1, i2] = 0)} then
      begin
        k := Epicnum + curlevel - Bfield[4, i1, i2];
        if (k >= beginpic) and (k <= endpic) then
        begin
          DrawEPic(k, pos.x, pos.y, 0, 25{ shl 8 + 75}, CalBlock(i1, i2), 0, 0);
        end;
      end;
    end;
  DrawProgress;
end;

//画带人物动作的战场

procedure DrawBFieldWithAction(bnum, Apicnum: integer);
var
  i, i1, i2: integer;
  pos: TPosition;
begin
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
        DrawFPic(apicnum, pos.x, pos.y, Brole[bnum].Bhead, 0, 75, CalBlock(i1, i2), 0, 0);
      end;
    end;
  DrawProgress;

end;


//绘制云

procedure DrawClouds;
var
  i, x, y: integer;
begin
  for i := 0 to CLOUD_AMOUNT - 1 do
  begin
    x := Cloud[i].Positionx - (-Mx * 18 + My * 18 + 8640 - CENTER_X);
    y := Cloud[i].Positiony - (Mx * 9 + My * 9 + 9 - CENTER_Y);
    DrawCPic(Cloud[i].Picnum, x, y, Cloud[i].Shadow, Cloud[i].Alpha, Cloud[i].MixColor, Cloud[i].MixAlpha);
  end;

end;

//显示半即时进度

procedure DrawProgress;
var
  i, j, x, y, curHead, temp: integer;
  dest: TSDL_Rect;
  range, p: array of integer;
  tempscr: PSDL_Surface;
begin
  if SEMIREAL = 1 then
  begin
    x := 50;
    y := CENTER_Y * 2 - 80;
    dest.y := y;
    DrawRectangleWithoutFrame(screen, 0, CENTER_Y * 2 - 50, CENTER_X * 2, 50, 0, 50);
    if length(BHead) = BRoleAmount then
    begin
      setlength(range, BRoleAmount);
      setlength(p, BRoleAmount);
      curHead := 0;
      for i := 0 to BRoleAmount - 1 do
      begin
        range[i] := i;
        p[i] := Brole[i].RealProgress * 500 {* CENTER_X div 320} div 10000;
      end;
      for i := 0 to BRoleAmount - 2 do
        for j := i + 1 to BRoleAmount - 1 do
        begin
          if p[i] <= p[j] then
          begin
            temp := p[i];
            p[i] := p[j];
            p[j] := temp;
            temp := range[i];
            range[i] := range[j];
            range[j] := temp;
          end;
        end;

      for i := 0 to BRoleAmount - 1 do
        if Brole[range[i]].Dead = 0 then
        begin
          //p := Brole[range[i]].RealProgress * 500 div 10000;
          dest.x := p[i] + x;
          if BHead[Brole[range[i]].BHead] <> nil then
          begin
            tempscr := BHead[Brole[range[i]].BHead];
            SDL_BlitSurface(tempscr, nil, screen, @dest);
            {if (BField[4, Brole[range[i]].X, Brole[range[i]].Y] > 0)
              and (Brole[BField[2, Bx, By]].Team <> Brole[range[i]].Team) then
              DrawRectangleWithoutFrame(screen, dest.x, dest.y, tempscr.w, tempscr.h,
                SDL_MapRGB(screen.format, 200, 2, 0), 40);}
          end;
        end;
    end;
  end;

end;

end.
