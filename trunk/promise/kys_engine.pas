unit kys_engine;

//{$MODE Delphi}

interface

uses
  SysUtils,
{$IFDEF fpc}
  LCLIntf, LCLType, LMessages, LConvEncoding, FileUtil,
{$ENDIF}
{$IFDEF mswindows}
  Windows,
{$ENDIF}
  Math,
  Dialogs,
  SDL,
  SDL_TTF,
  //SDL_mixer,
  iniFiles,
  SDL_image,
  smpeg,
  SDL_Gfx,
  kys_battle,
  kys_main,
  bass,
  bassmidi,
  gl, glext;

//音频子程
procedure InitialMusic;
procedure PlayMP3(MusicNum, times: integer); overload;
procedure StopMP3;
procedure PlaySoundE(SoundNum, times: integer); overload;
procedure PlaySoundE(SoundNum: integer); overload;
procedure PlaySound(SoundNum, times: integer); overload;
procedure PlaySoundA(SoundNum, times: integer);

//基本绘图子程
function getpixel(surface: PSDL_Surface; x: integer; y: integer): Uint32;
procedure putpixel(surface_: PSDL_Surface; x: integer; y: integer; pixel: Uint32);
procedure drawscreenpixel(x, y: integer; color: Uint32);
procedure display_bmp(file_name: PChar; x, y: integer);
procedure display_img(file_name: PChar; x, y: integer); overload;
function ColColor(num: integer): Uint32; overload;
function ColColor(colnum, num: integer): Uint32; overload;
procedure DrawLine(x1, y1, x2, y2, color, Width: integer);

//画RLE8图片的子程
function JudgeInScreen(px, py, w, h, xs, ys: integer): boolean; overload;
function JudgeInScreen(px, py, w, h, xs, ys, xx, yy, xw, yh: integer): boolean; overload;
procedure DrawRLE8Pic(num, px, py: integer; Pidx: Pinteger; Ppic: PByte; RectArea: TRect;
  Image: PChar; Shadow: integer); overload;
procedure DrawRLE8Pic(num, px, py: integer; Pidx: Pinteger; Ppic: PByte; RectArea: TRect;
  Image: PChar; Shadow: integer; mask: integer); overload;
procedure DrawRLE8Pic(num, px, py: integer; Pidx: Pinteger; Ppic: PByte; RectArea: TRect;
  Image: PChar; Shadow: integer; mask: integer; colorPanel: PChar); overload;
function GetPositionOnScreen(x, y, CenterX, CenterY: integer): TPosition;
procedure DrawTitlePic(imgnum, px, py: integer);
procedure DrawMPic(num, px, py, mask: integer);
procedure DrawSPic(num, px, py, x, y, w, h: integer); overload;
procedure DrawSPic(num, px, py, x, y, w, h: integer; mask: integer); overload;
procedure DrawSNewPic(num, px, py, x, y, w, h: integer; mask: integer);
procedure InitialSPic(num, px, py, x, y, w, h: integer); overload;
procedure InitialSPic(num, px, py, x, y, w, h, mask: integer); overload;
procedure DrawHeadPic(num, px, py: integer);
procedure DrawBPic(num, px, py, shadow: integer); overload;
procedure DrawBPic(num, px, py, shadow, mask: integer); overload;
procedure DrawBPic(num, x, y, w, h, px, py, shadow: integer); overload;
procedure DrawBPic(num, x, y, w, h, px, py, shadow, mask: integer); overload;
procedure DrawBPicInRect(num, px, py, shadow, x, y, w, h: integer);
procedure InitialBPic(num, px, py: integer); overload;
procedure InitialBPic(num, px, py, x, y, w, h, mask: integer); overload;
procedure DrawBRolePic(num, px, py, shadow, mask: integer); overload;
procedure DrawBRolePic(num, x, y, w, h, px, py, shadow, mask: integer); overload;

//显示文字的子程
function Big5ToUnicode(str: PChar): WideString;
function GBKToUnicode(str: PChar): WideString;
function UnicodeToBig5(str: PWideChar): string;
procedure DrawText(sur: PSDL_Surface; word: PUint16; x_pos, y_pos: integer; color: Uint32);
procedure DrawEngText(sur: PSDL_Surface; word: PUint16; x_pos, y_pos: integer; color: Uint32);
procedure DrawShadowText(word: PUint16; x_pos, y_pos: integer; color1, color2: Uint32);
procedure DrawEngShadowText(word: PUint16; x_pos, y_pos: integer; color1, color2: Uint32);
procedure DrawBig5Text(sur: PSDL_Surface; str: PChar; x_pos, y_pos: integer; color: Uint32);
procedure DrawBig5ShadowText(word: PChar; x_pos, y_pos: integer; color1, color2: Uint32);
procedure DrawGBKText(sur: PSDL_Surface; str: PChar; x_pos, y_pos: integer; color: Uint32);
procedure DrawGBKShadowText(word: PChar; x_pos, y_pos: integer; color1, color2: Uint32);
procedure DrawTextWithRect(word: puint16; x, y, w: integer; color1, color2: uint32);
procedure DrawRectangle(x, y, w, h: integer; colorin, colorframe: Uint32; alphe: integer);
procedure DrawRectangleWithoutFrame(x, y, w, h: integer; colorin: Uint32; alphe: integer);

//绘制整个屏幕的子程
procedure Redraw;
procedure DrawMMap;
procedure DrawScene;
procedure DrawSceneWithoutRole(x, y: integer);
procedure DrawRoleOnScene(x, y: integer);
procedure InitialScene();
procedure UpdateScene(xs, ys, oldpic, newpic: integer);
procedure LoadScenePart(x, y: integer);
procedure DrawWholeBField;
procedure DrawBfieldWithoutRole(x, y: integer);
procedure DrawRoleOnBfield(x, y: integer);
procedure InitialWholeBField;
procedure LoadBfieldPart(x, y: integer);
procedure DrawBFieldWithCursor(AttAreaType, step, range: integer);
procedure DrawBFieldWithEft(f, Epicnum, bigami, level: integer);
procedure DrawBFieldWithAction(f, bnum, Apicnum: integer);

//KG新增的函数
procedure InitNewPic(num, px, py, x, y, w, h: integer); overload;
procedure InitNewPic(num, px, py, x, y, w, h, mask: integer); overload;
procedure NewMenuSystem;
procedure SelectShowStatus;
procedure NewShowStatus(rnum: integer);
procedure SelectShowMagic;
procedure NewShowMagic(rnum: integer);
procedure ShowMagic(rnum, num, x1, y1, w, h: integer; showit: boolean);
procedure display_img(file_name: PChar; x, y, x1, y1, w, h: integer); overload;
procedure display_imgFromSurface(image: PSDL_Surface; x, y, x1, y1, w, h: integer); overload;
procedure display_imgFromSurface(image: PSDL_Surface; x, y: integer); overload;
procedure display_imgFromSurface(image: Tpic; x, y, x1, y1, w, h: integer); overload;
procedure display_imgFromSurface(image: Tpic; x, y: integer); overload;
function InModeMagic(rnum: integer): boolean;
procedure UpdateHpMp(rnum, x, y: integer);
procedure MenuMedcine(rnum: integer); overload;
procedure MenuMedPoision(rnum: integer); overload;
function GetPngPic(filename: string; num: integer): Tpic; overload;
function GetPngPic(f: integer; num: integer): Tpic; overload;
procedure drawPngPic(image: Tpic; x, y, w, h, px, py, mask: integer); overload;
procedure drawPngPic(image: Tpic; px, py, mask: integer); overload;
function ReadPicFromByte(p_byte: Pbyte; size: integer): PSDL_SURFACE;
function Simplified2Traditional(mSimplified: string): string;
function Traditional2Simplified(mTraditional: string): string;
procedure NewShowMenuSystem(menu: integer);
function NewMenuSave: boolean;
procedure NewShowSelect(row, menu: integer; word: array of WideString; Width: integer);
function NewMenuLoad: boolean;
procedure NewMenuVolume;
procedure NewMenuQuit;
procedure DrawItemPic(num, x, y: integer);
procedure ShowMap;
procedure NewMenuEsc;
procedure showNewMenuEsc(menu: integer; positionX, positionY: array of integer);
procedure resetpallet; overload;
procedure resetpallet(num: integer); overload;
function RoRforUInt16(a, n: Uint16): Uint16; //循环左移N位
function RoLforUint16(a, n: Uint16): Uint16; //循环右移N位
function RoRforByte(a: byte; n: Uint16): byte; //循环左移N位
function RoLforByte(a: byte; n: Uint16): byte; //循环右移N位
procedure DrawEftPic(Pic: Tpic; px, py, level: integer);
procedure PlayBeginningMovie(beginnum, endnum: integer);
procedure ZoomPic(scr: Psdl_surface; angle: double; x, y, w, h: integer);
function GetZoomPic(scr: Psdl_surface; angle: double; x, y, w, h: integer): Psdl_surface;
function UnicodeToGBK(str: PWideChar): string;
procedure NewMenuTeammate;
procedure ShowTeammateMenu(TeamListNum, RoleListNum: integer; rlist: psmallint; MaxCount, position: integer);
procedure NewMenuItem;
procedure showNewItemMenu(menu: integer);
function SelectItemUser(inum: integer): smallint;
procedure showSelectItemUser(x, y, inum, menu, max: integer; p: psmallint);
procedure UpdateBattleScene(xs, ys, oldPic, newpic: integer);
procedure Moveman(x1, y1, x2, y2: integer);
procedure findway(x1, y1: integer);

procedure DrawCPic(num, px, py, shadow, alpha: integer; mixColor: Uint32; mixAlpha: integer);
procedure DrawClouds;

procedure ChangeCol;

procedure DrawRLE8Pic3(colorPanel: PChar; num, px, py: integer; Pidx: Pinteger; Ppic: PByte;
  RectArea: PChar; Image: PChar; widthI, heightI, sizeI: integer; shadow, alpha: integer;
  BlockImageW: PChar; BlockScreenR: PChar; widthR, heightR, sizeR: integer; depth: integer;
  mixColor: Uint32; mixAlpha: integer);

procedure SDL_UpdateRect2(scr1: PSDL_Surface; x, y, w, h: integer);
procedure SDL_GetMouseState2(var x, y: integer);
procedure ResizeWindow(w, h: integer);
procedure SwitchFullscreen;


implementation

uses kys_event;
procedure InitialMusic;
var
  i: integer;
  str: string;
  sf: BASS_MIDI_FONT;
  Flag: longword;
begin
  sf.font := BASS_MIDI_FontInit(PChar(AppPath + 'music/mid.sf2'), 0);
  BASS_MIDI_StreamSetFonts(0, sf, 1);
  sf.preset := -1; // use all presets
  sf.bank := 0;
  Flag := 0;
  //if SOUND3D = 1 then
  //Flag := BASS_SAMPLE_3D or Flag;

  for i := low(Music) to high(Music) do
  begin
    str := AppPath + 'music/' + IntToStr(i) + '.mp3';
    if fileexists(PChar(str)) then
    begin
      try
        Music[i] := BASS_StreamCreateFile(False, PChar(str), 0, 0, 0);
      finally

      end;
    end
    else
    begin
      str := AppPath + 'music/' + IntToStr(i) + '.mid';
      if fileexists(PChar(str)) then
      begin
        try
          Music[i] := BASS_MIDI_StreamCreateFile(False, PChar(str), 0, 0, 0, 0);
          BASS_MIDI_StreamSetFonts(Music[i], sf, 1);
          //showmessage(inttostr(Music[i]));
        finally

        end;
      end
      else
        Music[i] := 0;
    end;
    //showmessage(inttostr(music[i]));
  end;

  for i := low(ESound) to high(ESound) do
  begin
    str := AppPath + formatfloat('sound/e00', i) + '.wav';
    if fileexists(PChar(str)) then
      ESound[i] := BASS_SampleLoad(False, PChar(str), 0, 0, 1, Flag)
    else
      ESound[i] := 0;
    //showmessage(inttostr(esound[i]));
  end;
  for i := low(ASound) to high(ASound) do
  begin
    str := AppPath + formatfloat('sound/atk00', i) + '.wav';
    if fileexists(PChar(str)) then
      ASound[i] := BASS_SampleLoad(False, PChar(str), 0, 0, 1, Flag)
    else
      ASound[i] := 0;
  end;

end;

//播放mp3音乐

procedure PlayMP3(MusicNum, times: integer); overload;
var
  repeatable: boolean;
  //nowmusic: HSTREAM;
begin
  if times = -1 then
    repeatable := True
  else
    repeatable := False;
  try
    if (MusicNum in [Low(Music)..High(Music)]) and (MusicVOLUME > 0) then
      if Music[MusicNum] <> 0 then
      begin
        //BASS_ChannelSlideAttribute(Music[nowmusic], BASS_ATTRIB_VOL, 0, 1000);
        if nowmusic in [Low(Music)..High(Music)] then
        begin
          BASS_ChannelStop(Music[nowmusic]);
          BASS_ChannelSetPosition(Music[nowmusic], 0, BASS_POS_BYTE);
        end;
        BASS_ChannelSetAttribute(Music[MusicNum], BASS_ATTRIB_VOL, MusicVOLUME / 128.0);
        {if SOUND3D = 1 then
        begin
          //BASS_SetEAXParameters(EAX_ENVIRONMENT_UNDERWATER, -1, 0, 0);
          BASS_Apply3D();
        end;}

        if repeatable then
          BASS_ChannelFlags(Music[MusicNum], BASS_SAMPLE_LOOP, BASS_SAMPLE_LOOP)
        else
          BASS_ChannelFlags(Music[MusicNum], 0, BASS_SAMPLE_LOOP);
        BASS_ChannelPlay(Music[MusicNum], repeatable);
        nowmusic := musicnum;
      end;
  finally

  end;

end;

{procedure PlayMP3(MusicNum, times: integer);
var
  i: integer;
  str: string;
  sf: BASS_MIDI_FONT;
  repeatable: boolean;
begin
  BASS_StreamFree(Music);
  sf.font := BASS_MIDI_FontInit(PChar(AppPath + 'music/mid.sf2'), 0);
  BASS_MIDI_StreamSetFonts(0, sf, 1);
  sf.preset := -1; // use all presets
  sf.bank := 0;

  str := 'music/' + inttostr(musicnum) + '.mp3';
  if FileExistsUTF8(AppPath + str) then
  begin
    Music := BASS_StreamCreateFile(False, pchar(AppPath + str), 0, 0, 0);
  end
  else
  begin
    str := 'music/' + inttostr(musicnum) + '.mid';
    if FileExistsUTF8(AppPath + str) then
    begin
      Music := BASS_MIDI_StreamCreateFile(false, PChar(AppPath + str), 0, 0, 0, 0);
      BASS_MIDI_StreamSetFonts(Music, sf, 1);
    end
    else
    begin
      Music := 0;
    end;
  end;

  if Music <> 0 then
  begin
    BASS_ChannelSetAttribute(Music, BASS_ATTRIB_VOL, MusicVOLUME / 128.0);
    if times = -1 then
      repeatable := true
    else
      repeatable := false;
    if repeatable then
      BASS_ChannelFlags(Music, BASS_SAMPLE_LOOP, BASS_SAMPLE_LOOP)
    else
      BASS_ChannelFlags(Music, 0, BASS_SAMPLE_LOOP);
    BASS_ChannelPlay(Music, repeatable);
  end;

end;}

//停止当前播放的音乐

procedure StopMP3;
begin
  //BASS_ChannelStop(Music);
  //BASS_ChannelSetPosition(Music, 0, BASS_POS_BYTE);

end;

//播放wav音效

{procedure PlaySound(SoundNum, times: integer); overload;
var
  i: integer;
  str: string;
  ch: HCHANNEL;
  repeatable: boolean;
begin
  BASS_SampleFree(Esound);
  if times = -1 then
    repeatable := true
  else
    repeatable := false;
  str := 'sound/e' + format('%3d', [SoundNum]) + '.wav';
  for i := 0 to length(str) - 1 do
    if str[i] = ' ' then str[i] := '0';
  if FileExistsUTF8(AppPath + str) then
  begin
    Esound := BASS_SampleLoad(FALSE, pchar(AppPath + str), 0, 0, 1, 0);
    ch := BASS_SampleGetChannel(Esound, False);
  end
  else
    Esound := 0;
  if Esound <> 0 then
  begin
    if repeatable then
      BASS_ChannelFlags(ch, BASS_SAMPLE_LOOP, BASS_SAMPLE_LOOP)
    else
      BASS_ChannelFlags(ch, 0, BASS_SAMPLE_LOOP);
    BASS_ChannelSetAttribute(ch, BASS_ATTRIB_VOL, SoundVolume / 100.0);
    BASS_ChannelPlay(ch, repeatable);
  end;
end;

procedure PlaySound(SoundNum: integer); overload;
begin
  PlaySound(SoundNum, 0);
end;
}

procedure PlaySoundE(SoundNum, times: integer); overload;
var
  ch: HCHANNEL;
  repeatable: boolean;
begin
  if times = -1 then
    repeatable := True
  else
    repeatable := False;
  if (SoundNum in [Low(Esound)..High(Esound)]) and (SoundVOLUME > 0) then
    if Esound[SoundNum] <> 0 then
    begin
      //Mix_VolumeChunk(Esound[SoundNum], Volume);
      //Mix_PlayChannel(-1, Esound[SoundNum], 0);
      BASS_SampleStop(Esound[soundnum]);
      ch := BASS_SampleGetChannel(Esound[soundnum], False);
      BASS_ChannelSetAttribute(ch, BASS_ATTRIB_VOL, SoundVolume / 128.0);
      if repeatable then
        BASS_ChannelFlags(ch, BASS_SAMPLE_LOOP, BASS_SAMPLE_LOOP)
      else
        BASS_ChannelFlags(ch, 0, BASS_SAMPLE_LOOP);
      BASS_ChannelPlay(ch, repeatable);
    end;

end;

procedure PlaySoundE(SoundNum: integer); overload;
begin
  PlaySoundE(Soundnum, -1);

end;

procedure PlaySound(SoundNum, times: integer); overload;
begin
  PlaySoundE(Soundnum, times);

end;

procedure PlaySoundA(SoundNum, times: integer);
var
  ch: HCHANNEL;
  repeatable: boolean;
begin
  if times = -1 then
    repeatable := True
  else
    repeatable := False;
  if (SoundNum in [Low(Asound)..High(Asound)]) and (SoundVOLUME > 0) then
    if Asound[SoundNum] <> 0 then
    begin
      //Mix_VolumeChunk(Esound[SoundNum], Volume);
      //Mix_PlayChannel(-1, Esound[SoundNum], 0);
      BASS_SampleStop(Esound[soundnum]);
      ch := BASS_SampleGetChannel(Asound[soundnum], False);
      BASS_ChannelSetAttribute(ch, BASS_ATTRIB_VOL, SoundVOLUME / 128.0);
      if repeatable then
        BASS_ChannelFlags(ch, BASS_SAMPLE_LOOP, BASS_SAMPLE_LOOP)
      else
        BASS_ChannelFlags(ch, 0, BASS_SAMPLE_LOOP);
      BASS_ChannelPlay(ch, repeatable);
    end;

end;

//获取某像素信息

function getpixel(surface: PSDL_Surface; x: integer; y: integer): Uint32;
type
  TByteArray = array[0..2] of byte;
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
        Result := longword(p^);
      2:
        Result := PUint16(p)^;
      3:
        if (SDL_BYTEORDER = SDL_BIG_ENDIAN) then
          Result := PByteArray(p)[0] shl 16 or PByteArray(p)[1] shl 8 or PByteArray(p)[2]
        else
          Result := PByteArray(p)[0] or PByteArray(p)[1] shl 8 or PByteArray(p)[2] shl 16;
      4:
        Result := PUint32(p)^;
      else
        Result := 0; // shouldn't happen, but avoids warnings
    end;
  end;

end;

//画像素

procedure putpixel(surface_: PSDL_Surface; x: integer; y: integer; pixel: Uint32);
type
  TByteArray = array[0..2] of byte;
  PByteArray = ^TByteArray;
var
  bpp: integer;
  p: PInteger;
  regionx1, regiony1, regionx2, regiony2: integer;
begin

  regionx1 := 0;
  regionx2 := screen.w;
  regiony1 := 0;
  regiony2 := screen.h;

{$IFDEF DARWIN}
  {if (RegionRect.w > 0) then
  begin
    regionx1 := RegionRect.x;
    regionx2 := RegionRect.x + RegionRect.w;
    regiony1 := RegionRect.y;
    regiony2 := RegionRect.y + RegionRect.h;
  end;}
{$ENDIF}

  if (x >= regionx1) and (x < regionx2) and (y >= regiony1) and (y < regiony2) then
  begin
    bpp := surface_.format.BytesPerPixel;
    // Here p is the address to the pixel we want to set
    p := Pointer(Uint32(surface_.pixels) + y * surface_.pitch + x * bpp);

    case bpp of
      1:
        longword(p^) := pixel;
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
  SDL_UpdateRect2(screen, x, y, 1, 1);
end;

//显示bmp文件

procedure display_bmp(file_name: PChar; x, y: integer);
var
  image: PSDL_Surface;
  dest: TSDL_Rect;
begin
  if FileExistsUTF8(AppPath + file_name) { *Converted from FileExists*  } then
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
    //SDL_UpdateRect2(screen, 0, 0, image.w, image.h);
    SDL_FreeSurface(image);
  end;
end;

//显示tif, png, jpg等格式图片

procedure display_img(file_name: PChar; x, y, x1, y1, w, h: integer); overload;
var
  image: PSDL_Surface;
  dest, dest1: TSDL_Rect;
begin
  if FileExistsUTF8(AppPath + file_name) { *Converted from FileExists*  } then
  begin
    image := IMG_Load(file_name);
    if (image = nil) then
    begin
      MessageBox(0, PChar(Format('Couldn''t load %s : %s', [file_name, SDL_GetError])),
        'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
    dest.x := x;
    dest.y := y;
    dest1.x := x1;
    dest1.y := y1;
    dest1.w := w;
    dest1.h := h;
    if (SDL_BlitSurface(image, @dest1, screen, @dest) < 0) then
      MessageBox(0, PChar(Format('BlitSurface error : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
    //SDL_UpdateRect2(screen, 0, 0, image.w, image.h);
    SDL_FreeSurface(image);
  end;
end;

//显示tif, png, jpg等格式图片

procedure display_imgFromSurface(image: PSDL_Surface; x, y, x1, y1, w, h: integer); overload;
var
  dest, dest1: TSDL_Rect;
begin

  if (image = nil) then
  begin
    exit;
  end;
  dest.x := x;
  dest.y := y;
  dest1.x := x1;
  dest1.y := y1;
  dest1.w := w;
  dest1.h := h;
  if (SDL_BlitSurface(image, @dest1, screen, @dest) < 0) then
    MessageBox(0, PChar(Format('BlitSurface error : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
  //SDL_UpdateRect2(screen, 0, 0, image.w, image.h);
  //SDL_FreeSurface(image);

end;

procedure display_imgFromSurface(image: Tpic; x, y, x1, y1, w, h: integer); overload;
var
  dest, dest1: TSDL_Rect;
begin

  if (image.pic = nil) then
  begin
    exit;
  end;
  dest.x := x;
  dest.y := y;
  dest1.x := x1;
  dest1.y := y1;
  dest1.w := w;
  dest1.h := h;
  if (SDL_BlitSurface(image.pic, @dest1, screen, @dest) < 0) then
    MessageBox(0, PChar(Format('BlitSurface error : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
  //SDL_UpdateRect2(screen, 0, 0, image.w, image.h);
  //SDL_FreeSurface(image);

end;

procedure display_img(file_name: PChar; x, y: integer); overload;
var
  image: PSDL_Surface;
  dest: TSDL_Rect;
begin
  if FileExistsUTF8(AppPath + file_name) { *Converted from FileExists*  } then
  begin
    image := IMG_Load(file_name);
    if (image = nil) then
    begin
      MessageBox(0, PChar(Format('Couldn''t load %s : %s', [file_name, SDL_GetError])),
        'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
    dest.x := x;
    dest.y := y;
    if (SDL_BlitSurface(image, nil, screen, @dest) < 0) then
      MessageBox(0, PChar(Format('BlitSurface error : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
    //SDL_UpdateRect2(screen, 0, 0, image.w, image.h);
    SDL_FreeSurface(image);
  end;
end;

procedure display_imgFromSurface(image: PSDL_Surface; x, y: integer); overload;
var
  dest: TSDL_Rect;
begin
  if (image = nil) then
  begin
    exit;
  end;
  dest.x := x;
  dest.y := y;
  if (SDL_BlitSurface(image, nil, screen, @dest) < 0) then
    MessageBox(0, PChar(Format('BlitSurface error : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
  //SDL_UpdateRect2(screen, 0, 0, image.w, image.h);
  //SDL_FreeSurface(image);
end;

procedure display_imgFromSurface(image: Tpic; x, y: integer); overload;
var
  dest: TSDL_Rect;
begin
  if (image.pic = nil) then
  begin
    exit;
  end;
  dest.x := x;
  dest.y := y;
  if (SDL_BlitSurface(image.pic, nil, screen, @dest) < 0) then
    MessageBox(0, PChar(Format('BlitSurface error : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
  //SDL_UpdateRect2(screen, 0, 0, image.w, image.h);
  //SDL_FreeSurface(image);
end;

//取调色板的颜色, 视频系统是32位色, 但很多时候仍需要原调色板的颜色

function ColColor(num: integer): Uint32;
begin
  colcolor := SDL_mapRGB(screen.format, Acol[num * 3 + 0] * 4, Acol[num * 3 + 1] * 4, Acol[num * 3 + 2] * 4);

end;

function ColColor(colnum, num: integer): Uint32;
begin
  colcolor := SDL_mapRGB(screen.format, col[colnum][num * 3] * 4, col[colnum][num * 3 + 1] *
    4, col[colnum][num * 3 + 2] * 4);
end;

//判断像素是否在屏幕内

function JudgeInScreen(px, py, w, h, xs, ys: integer): boolean; overload;
begin
  Result := False;
  if (px - xs + w >= 0) and (px - xs < screen.w) and (py - ys + h >= 0) and (py - ys < screen.h) then
    Result := True;

end;

//判断像素是否在指定范围内(重载)

function JudgeInScreen(px, py, w, h, xs, ys, xx, yy, xw, yh: integer): boolean; overload;
begin
  Result := False;
  if (px - xs + w >= xx) and (px - xs < xx + xw) and (py - ys + h >= yy) and (py - ys < yy + yh) then
    Result := True;

end;
//RLE8图片绘制子程，所有相关子程均对此封装

//新增一个参数，代表是否创造或使用遮罩
//0为不处理遮罩，1为创建遮罩，2为使用遮罩  ,3为创建反向遮罩

procedure DrawRLE8Pic(num, px, py: integer; Pidx: Pinteger; Ppic: PByte; RectArea: TRect;
  Image: PChar; Shadow: integer; mask: integer; colorPanel: PChar); overload;
var
  w, h, xs, ys: smallint;
  os, offset, ix, iy, length, p, i1, i2, i, a, b: integer;
  l, l1: byte;
  alphe, pix: Uint32;
  pix1, pix2, pix3, pix4: byte;
begin

  if rs = 0 then
  begin
    randomcount := random(640);
  end;
  if num = 0 then
    offset := 0
  else
  begin
    Inc(Pidx, num - 1);
    offset := Pidx^;
  end;

  Inc(Ppic, offset);
  w := Psmallint((Ppic))^;
  Inc(Ppic, 2);
  h := Psmallint((Ppic))^;
  Inc(Ppic, 2);
  xs := Psmallint((Ppic))^ + 1;
  Inc(Ppic, 2);
  ys := Psmallint((Ppic))^ + 1;
  Inc(Ppic, 2);

  if (px - xs + w < rectarea.x) and (px - xs < rectarea.x) then exit;
  if (px - xs + w > rectarea.x + rectarea.w) and (px - xs > rectarea.x + rectarea.w) then exit;
  if (py - ys + h < rectarea.y) and (py - ys < rectarea.y) then exit;
  if (py - ys + h > rectarea.y + rectarea.h) and (py - ys > rectarea.y + rectarea.h) then exit;
  if mask = 1 then
    for i1 := rectarea.x to rectarea.x + rectarea.w do
      for i2 := rectarea.y to rectarea.y + rectarea.h do
      begin
        MaskArray[i1, i2] := 0;
      end;
  if JudgeInScreen(px, py, w, h, xs, ys, RectArea.x, RectArea.y, RectArea.w, RectArea.h) then
  begin
    for iy := 1 to h do
    begin
      l := Ppic^;
      Inc(Ppic, 1);
      w := 1;
      p := 0;
      for ix := 1 to l do
      begin
        l1 := Ppic^;
        Inc(Ppic);
        if p = 0 then
        begin
          w := w + l1;
          p := 1;
        end
        else if p = 1 then
        begin
          p := 2 + l1;
        end
        else if p > 2 then
        begin
          p := p - 1;
          if (w - xs + px >= RectArea.x) and (iy - ys + py >= RectArea.y) and
            (w - xs + px < RectArea.x + RectArea.w) and (iy - ys + py < RectArea.y + RectArea.h) then
          begin
            if ((mask <> 2) and (mask <> 3)) or (MaskArray[w - xs + px, iy - ys + py] = 1) then
            begin
              if mask = 1 then
                MaskArray[w - xs + px, iy - ys + py] := 1;
              if mask = 3 then
                MaskArray[w - xs + px, iy - ys + py] := 0;

              if image = nil then
              begin
                pix := sdl_maprgb(screen.format, puint8(colorPanel + l1 * 3)^ * (4 + shadow),
                  puint8(colorPanel + l1 * 3 + 1)^ * (4 + shadow), puint8(colorPanel + l1 * 3 + 2)^ * (4 + shadow));
                //    if mask = 1 then  pix :=$ffffff;
                if HighLight then
                begin
                  alphe := 50;
                  pix1 := pix and $FF;
                  pix2 := pix shr 8 and $FF;
                  pix3 := pix shr 16 and $FF;
                  pix4 := pix shr 24 and $FF;
                  pix1 := (alphe * $FF + (100 - alphe) * pix1) div 100;
                  pix2 := (alphe * $FF + (100 - alphe) * pix2) div 100;
                  pix3 := (alphe * $FF + (100 - alphe) * pix3) div 100;
                  pix4 := (alphe * $FF + (100 - alphe) * pix4) div 100;
                  pix := pix1 + pix2 shl 8 + pix3 shl 16 + pix4 shl 24;
                end
                else if Gray > 0 then
                begin
                  pix1 := pix and $FF;
                  pix2 := pix shr 8 and $FF;
                  pix3 := pix shr 16 and $FF;
                  pix4 := pix shr 24 and $FF;
                  pix := (pix1 * 11) div 100 + (pix2 * 59) div 100 + (pix3 * 3) div 10;
                  pix1 := ((100 - gray) * pix1 + gray * pix) div 100;
                  pix2 := ((100 - gray) * pix2 + gray * pix) div 100;
                  pix3 := ((100 - gray) * pix3 + gray * pix) div 100;
                  pix := pix1 + pix1 shl 8 + pix1 shl 16 + pix4 shl 24;
                end
                else if blue > 0 then
                begin
                  pix1 := (pix and $FF);
                  pix2 := ((pix shr 8 and $FF) * (150 - blue)) div 150;
                  pix3 := ((pix shr 16 and $FF) * (150 - blue)) div 150;
                  pix := pix1 + pix2 shl 8 + pix3 shl 16;
                end
                else if red > 0 then
                begin
                  pix1 := ((pix and $FF) * (150 - red)) div 150;
                  pix2 := ((pix shr 8 and $FF) * (150 - red)) div 150;
                  pix3 := (pix shr 16 and $FF);
                  pix := pix1 + pix2 shl 8 + pix3 shl 16;
                end
                else if green > 0 then
                begin
                  pix1 := ((pix and $FF) * (150 - green)) div 150;
                  pix2 := (pix shr 8 and $FF);
                  pix3 := ((pix shr 16 and $FF) * (150 - green)) div 150;
                  pix := pix1 + pix2 shl 8 + pix3 shl 16;
                end
                else if yellow > 0 then
                begin
                  pix1 := ((pix and $FF) * (150 - yellow)) div 150;
                  pix2 := (pix shr 8 and $FF);
                  pix3 := (pix shr 16 and $FF);
                  pix := pix1 + pix2 shl 8 + pix3 shl 16;
                end;
                if (showBlackScreen = True) and (where = 1) then
                begin
                  alphe := snowalpha[iy - ys + py][w - xs + px];
                  if alphe >= 100 then pix := 0
                  else if alphe > 0 then
                  begin
                    pix1 := pix and $FF;
                    pix2 := pix shr 8 and $FF;
                    pix3 := pix shr 16 and $FF;
                    pix4 := pix shr 24 and $FF;
                    pix1 := ((100 - alphe) * pix1) div 100;
                    pix2 := ((100 - alphe) * pix2) div 100;
                    pix3 := ((100 - alphe) * pix3) div 100;
                    pix4 := ((100 - alphe) * pix4) div 100;
                    pix := pix1 + pix2 shl 8 + pix3 shl 16 + pix4 shl 24;
                  end;
                end;

                if (where = 1) and (water >= 0) then
                begin
                  os := (iy - ys + py + water div 3) mod 60;
                  os := snowalpha[0][os];
                  if os > 128 then os := os - 256;
                  putpixel(screen, w - xs + px + os, iy - ys + py, pix);

                  b := (i2 + water div 3) mod 60;

                  b := snowalpha[0][b];
                  if b > 128 then b := b - 256;

                end
                else if (where = 1) and (rain >= 0) then
                begin
                  b := ix + randomcount;
                  if b >= 640 then b := b - 640;
                  b := snowalpha[iy - ys + py][b];
                  alphe := 50;
                  if b = 1 then
                  begin
                    pix1 := pix and $FF;
                    pix2 := pix shr 8 and $FF;
                    pix3 := pix shr 16 and $FF;
                    pix4 := pix shr 24 and $FF;
                    pix1 := (alphe * $FF + (100 - alphe) * pix1) div 100;
                    pix2 := (alphe * $FF + (100 - alphe) * pix2) div 100;
                    pix3 := (alphe * $FF + (100 - alphe) * pix3) div 100;
                    pix4 := (alphe * $FF + (100 - alphe) * pix4) div 100;
                    pix := pix1 + pix2 shl 8 + pix3 shl 16 + pix4 shl 24;
                  end;
                  putpixel(screen, w - xs + px, iy - ys + py, pix);
                end
                else if (where = 1) and (snow >= 0) then
                begin
                  b := ix + randomcount;
                  if b >= 640 then b := b - 640;
                  b := snowalpha[iy - ys + py][b];
                  if b = 1 then pix := colcolor(255);

                  putpixel(screen, w - xs + px, iy - ys + py, pix);
                end
                else if (where = 1) and (fog) then
                begin
                  b := ix + randomcount;
                  if b >= 640 then b := b - 640;
                  alphe := snowalpha[iy - ys + py][b];
                  pix1 := pix and $FF;
                  pix2 := pix shr 8 and $FF;
                  pix3 := pix shr 16 and $FF;
                  pix4 := pix shr 24 and $FF;
                  pix1 := (alphe * $FF + (100 - alphe) * pix1) div 100;
                  pix2 := (alphe * $FF + (100 - alphe) * pix2) div 100;
                  pix3 := (alphe * $FF + (100 - alphe) * pix3) div 100;
                  pix4 := (alphe * $FF + (100 - alphe) * pix4) div 100;
                  pix := pix1 + pix2 shl 8 + pix3 shl 16 + pix4 shl 24;

                  putpixel(screen, w - xs + px, iy - ys + py, pix);
                end
                else
                  putpixel(screen, w - xs + px, iy - ys + py, pix);
              end
              else
                Pint(image + ((w - xs + px) * 1152 + (iy - ys + py)) * 4)^ :=
                  sdl_maprgb(screen.format, puint8(colorPanel + l1 * 3)^ * (4 + shadow), puint8(colorPanel + l1 * 3 + 1)^ *
                  (4 + shadow), puint8(colorPanel + l1 * 3 + 2)^ * (4 + shadow));

            end;
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


procedure DrawRLE8Pic(num, px, py: integer; Pidx: Pinteger; Ppic: PByte; RectArea: TRect;
  Image: PChar; shadow: integer; mask: integer); overload;
begin
  DrawRLE8Pic(num, px, py, Pidx, Ppic, RectArea, Image, shadow, mask, @ACol[0]);
end;



procedure DrawRLE8Pic(num, px, py: integer; Pidx: Pinteger; Ppic: PByte; RectArea: TRect;
  Image: PChar; shadow: integer); overload;
begin
  DrawRLE8Pic(num, px, py, Pidx, Ppic, RectArea, Image, shadow, 0);
end;

//获取游戏中坐标在屏幕上的位置

function GetPositionOnScreen(x, y, CenterX, CenterY: integer): TPosition;
begin
  Result.x := -(x - CenterX) * 18 + (y - CenterY) * 18 + CENTER_X;
  Result.y := (x - CenterX) * 9 + (y - CenterY) * 9 + CENTER_Y;
end;

//显示title.grp的内容(即开始的选单)

procedure DrawTitlePic(imgnum, px, py: integer);
var
  len, grp, idx: integer;
  Area: TRect;
  BufferIdx: array[0..100] of integer;
  BufferPic: array[0..20000] of byte;
begin
  grp := fileopen(AppPath + 'resource/title.grp', fmopenread);
  idx := fileopen(AppPath + 'resource/title.idx', fmopenread);

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
  resetpallet;
  DrawRLE8Pic(imgnum, px, py, @BufferIdx[0], @BufferPic[0], Area, nil, 0);

end;

//显示主地图贴图

procedure DrawMPic(num, px, py, mask: integer);
var
  Area: Trect;
begin
  Area.x := 0;
  Area.y := 0;
  Area.w := screen.w;
  Area.h := screen.h;
  if num < length(midx) then
  begin
    if (num >= 2501) and (num <= 2552) then
      DrawRLE8Pic(num, px, py, @Midx[0], @Mpic[0], Area, nil, 0, mask, @Col[0][0])
    else
      DrawRLE8Pic(num, px, py, @Midx[0], @Mpic[0], Area, nil, 0, mask);
  end;

end;

//显示场景图片

procedure DrawSPic(num, px, py, x, y, w, h: integer); overload;
var
  Area: TRect;
begin
  Area.x := x;
  Area.y := y;
  Area.w := w;
  Area.h := h;
  if num < length(sidx) then
    DrawRLE8Pic(num, px, py, @SIdx[0], @SPic[0], Area, nil, 0);

end;

procedure DrawSPic(num, px, py, x, y, w, h: integer; mask: integer); overload;
var
  Area: TRect;
begin
  Area.x := x;
  Area.y := y;
  Area.w := w;
  Area.h := h;
  if num < length(sidx) then
    DrawRLE8Pic(num, px, py, @SIdx[0], @SPic[0], Area, nil, 0, mask);

end;

procedure DrawSNewPic(num, px, py, x, y, w, h: integer; mask: integer);
var
  i1, i2, bpp, b, x1, y1, alpha, pix: integer;
  image: pansichar;
  p: pUint32;
  c: Uint32;
  pix1, pix2, pix3, col1, col2, col3, col4: byte;
begin

  if num >= 3 then
  begin
    b := 0;
    x1 := px - Scenepic[num].x + 1;
    y1 := py - Scenepic[num].y + 1;
    if (x1 + Scenepic[num].pic.w < x) and (x1 < x) then exit;
    if (x1 + Scenepic[num].pic.w > x + w) and (x1 > x + w) then exit;
    if (y1 + Scenepic[num].pic.h < y) and (y1 < y) then exit;
    if (y1 + Scenepic[num].pic.h > y + h) and (y1 > y + h) then exit;
    if mask = 1 then
      for i1 := x to x + w do
        for i2 := y to y + h do
        begin
          MaskArray[i1, i2] := 0;
        end;
    bpp := Scenepic[num].pic.format.BytesPerPixel;
    for i1 := 0 to Scenepic[num].pic.w - 1 do
      for i2 := 0 to Scenepic[num].pic.h - 1 do
      begin
        if ((x1 + i1) >= x) and ((x1 + i1) <= x + w) and (y1 + i2 >= y) and (y1 + i2 <= y + h) then
          if (MaskArray[x1 + i1, y1 + i2] = 1) or (Mask <= 0) then
          begin
            p := Pointer(Uint32(Scenepic[num].pic.pixels) + i2 * Scenepic[num].pic.pitch + i1 * bpp);
            c := PUint32(p)^;
            p := Pointer(Uint32(screen.pixels) + (y1 + i2) * screen.pitch + (x1 + i1) * bpp);
            pix := PUint32(p)^;

{$IFDEF darwin}
            {pix1 := (pix shr 24) and $FF;
            pix2 := (pix shr 16) and $FF;
            pix3 := (pix shr 8) and $FF;
            if fullscreen = 1 then
            begin}
            pix1 := (pix shr 0) and $FF;
            pix2 := (pix shr 8) and $FF;
            pix3 := (pix shr 16) and $FF;
            //end;
{$ELSE}
            pix1 := (pix shr 16) and $FF;
            pix2 := (pix shr 8) and $FF;
            pix3 := pix and $FF;
{$ENDIF}

            alpha := (c shr 24) and $FF;
            col3 := (c shr 16) and $FF;
            col2 := (c shr 8) and $FF;
            col1 := c and $FF;

            if (where = 1) then
            begin
              if (Rscene[curscene].Pallet = 1) then //调色板1
              begin
                col1 := (69 * col1) div 100;
                col2 := (73 * col2) div 100;
                col3 := (75 * col3) div 100;
              end
              else if (Rscene[curscene].Pallet = 2) then //调色板2
              begin
                col1 := (85 * col1) div 100;
                col2 := (75 * col2) div 100;
                col3 := (30 * col3) div 100;
              end
              else if (Rscene[curscene].Pallet = 3) then //调色板3
              begin
                col1 := (25 * col1) div 100;
                col2 := (68 * col2) div 100;
                col3 := (45 * col3) div 100;
              end;
            end;
            if (alpha = 0) and (Mask = 1) then MaskArray[x1 + i1, y1 + i2] := 1;

            pix1 := (alpha * col1 + (255 - alpha) * pix1) div 255;
            pix2 := (alpha * col2 + (255 - alpha) * pix2) div 255;
            pix3 := (alpha * col3 + (255 - alpha) * pix3) div 255;
            //   c := 0 ;

            p := Pointer(Uint32(screen.pixels) + (y1 + i2) * screen.pitch + (x1 + i1) * bpp);

            if HighLight then //高亮
            begin
              alpha := 50;
              pix1 := (alpha * $FF + (255 - alpha) * pix1) div 100;
              pix2 := (alpha * $FF + (255 - alpha) * pix2) div 100;
              pix3 := (alpha * $FF + (255 - alpha) * pix3) div 100;
            end;

            if (showBlackScreen = True) and (where = 1) then //山洞
            begin
              // alpha := snowalpha[iy - ys + py][w - xs + px];
              alpha := snowalpha[y1 + i2][x1 + i1];
              if alpha >= 100 then pix := 0
              else if alpha > 0 then
              begin
                pix1 := ((100 - alpha) * pix1) div 100;
                pix2 := ((100 - alpha) * pix2) div 100;
                pix3 := ((100 - alpha) * pix3) div 100;
              end;
            end;
            if (where = 1) and (water >= 0) then //扭曲
            begin
              b := (y1 + i2 + water div 3) mod 60;
              b := snowalpha[0][b];
              if b > 128 then b := b - 256;

              p := Pointer(Uint32(screen.pixels) + (y1 + i2) * screen.pitch + (x1 + i1 + b) * bpp);
              pix := PUint32(p)^;

{$IFDEF darwin}
              {pix1 := (pix shr 24) and $FF;
              pix2 := (pix shr 16) and $FF;
              pix3 := (pix shr 8) and $FF;
              if fullscreen = 1 then
              begin}
              pix1 := (pix shr 0) and $FF;
              pix2 := (pix shr 8) and $FF;
              pix3 := (pix shr 16) and $FF;
              //end;
{$ELSE}
              pix1 := (pix shr 16) and $FF;
              pix2 := (pix shr 8) and $FF;
              pix3 := pix and $FF;
{$ENDIF}

              pix1 := (alpha * col1 + (255 - alpha) * pix1) div 255;
              pix2 := (alpha * col2 + (255 - alpha) * pix2) div 255;
              pix3 := (alpha * col3 + (255 - alpha) * pix3) div 255;

            end
            else if (where = 1) and (rain >= 0) then //下雨
            begin
              b := i1 + randomcount;
              if b >= 640 then b := b - 640;
              b := snowalpha[i2 + y1][b];
              alpha := 50;
              if b = 1 then
              begin
                pix1 := (alpha * $FF + (100 - alpha) * pix1) div 100;
                pix2 := (alpha * $FF + (100 - alpha) * pix2) div 100;
                pix3 := (alpha * $FF + (100 - alpha) * pix3) div 100;
              end;
            end
            else if (where = 1) and (snow >= 0) then //下雪
            begin
              b := i1 + randomcount;
              if b >= 640 then b := b - 640;
              b := snowalpha[i2 + y1][b];
              if b = 1 then c := colcolor(255);
            end
            else if (where = 1) and (fog) then //有雾
            begin
              b := i1 + randomcount;
              if b >= 640 then b := b - 640;
              alpha := snowalpha[i2][b];
              pix1 := (alpha * $FF + (100 - alpha) * pix1) div 100;
              pix2 := (alpha * $FF + (100 - alpha) * pix2) div 100;
              pix3 := (alpha * $FF + (100 - alpha) * pix3) div 100;

            end;
{$IFDEF darwin}
            //c := pix1 shl 24 + pix2 shl 16 + pix3 shl 8;
            //if fullscreen = 1 then
            c := pix1 shl 0 + pix2 shl 8 + pix3 shl 16;
{$ELSE}
            c := pix1 shl 16 + pix2 shl 8 + pix3 shl 0;
{$ENDIF}
            PUint32(p)^ := c;

          end;
      end;
  end;

end;

//将场景图片信息写入映像

procedure InitialSPic(num, px, py, x, y, w, h, mask: integer);
var
  Area: TRect;
  i: integer;
  image: pansichar;
begin
  if x + w > 2303 then
    w := 2303 - x;
  if y + h > 1151 then
    h := 1151 - y;
  Area.x := x;
  Area.y := y;
  Area.w := w;
  Area.h := h;
  if num < length(sidx) then
    DrawRLE8Pic(num, px, py, @SIdx[0], @SPic[0], Area, @SceneImg[0], 0, mask);

end;



procedure InitialSPic(num, px, py, x, y, w, h: integer);
begin

  InitialSPic(num, px, py, x, y, w, h, 0);

end;

procedure InitNewPic(num, px, py, x, y, w, h: integer); overload;
begin
  InitNewPic(num, px, py, x, y, w, h, 0);
end;

procedure InitNewPic(num, px, py, x, y, w, h, mask: integer); overload;
var
  i1, i2, bpp, x1, y1, alpha, pix: integer;
  image: pansichar;
  p: pUint32;
  c: Uint32;
  pix1, pix2, pix3, col1, col2, col3: byte;
begin
  if num >= 3 then
  begin
    x1 := px - Scenepic[num].x + 1;
    y1 := py - Scenepic[num].y + 1;
    if (x1 + Scenepic[num].pic.w < x) and (x1 < x) then exit;
    if (x1 + Scenepic[num].pic.w > x + w) and (x1 > x + w) then exit;
    if (y1 + Scenepic[num].pic.h < y) and (y1 < y) then exit;
    if (y1 + Scenepic[num].pic.h > y + h) and (y1 > y + h) then exit;
    bpp := Scenepic[num].pic.format.BytesPerPixel;
    for i1 := 0 to Scenepic[num].pic.w - 1 do
      for i2 := 0 to Scenepic[num].pic.h - 1 do
      begin
        if mask = 1 then MaskArray[x1 + i1, y1 + i2] := 0;
        if ((x1 + i1) >= x) and ((x1 + i1) <= x + w) and (y1 + i2 >= y) and (y1 + i2 <= y + h) then
          if (MaskArray[x1 + i1, y1 + i2] = 1) or (Mask < 2) then
          begin
            p := Pointer(Uint32(Scenepic[num].pic.pixels) + i2 * Scenepic[num].pic.pitch + i1 * bpp);
            c := PUint32(p)^;
            pix := SceneImg[i1 + x1, i2 + y1];
            if c and $FF000000 <> 0 then
            begin

              if mask = 1 then
              begin
                MaskArray[x1 + i1, y1 + i2] := 1;
                SceneImg[i1 + x1, i2 + y1] := 0;
                continue;
              end;
{$IFDEF darwin}
              {pix1 := (pix shr 24) and $FF;
              pix2 := (pix shr 16) and $FF;
              pix3 := (pix shr 8) and $FF;
              if fullscreen = 1 then
              begin}
              pix1 := (pix shr 0) and $FF;
              pix2 := (pix shr 8) and $FF;
              pix3 := (pix shr 16) and $FF;
              //end;
{$ELSE}
              pix1 := (pix shr 16) and $FF;
              pix2 := (pix shr 8) and $FF;
              pix3 := pix and $FF;
{$ENDIF}
              alpha := (c shr 24) and $FF;
              col3 := (c shr 16) and $FF;
              col2 := (c shr 8) and $FF;
              col1 := c and $FF;
              if (where = 1) then
              begin
                if (Rscene[curscene].Pallet = 1) then //调色板1
                begin
                  col1 := (69 * col1) div 100;
                  col2 := (73 * col2) div 100;
                  col3 := (75 * col3) div 100;
                end
                else if (Rscene[curscene].Pallet = 2) then //调色板2
                begin
                  col1 := (85 * col1) div 100;
                  col2 := (75 * col2) div 100;
                  col3 := (30 * col3) div 100;
                end
                else if (Rscene[curscene].Pallet = 3) then //调色板3
                begin
                  col1 := (25 * col1) div 100;
                  col2 := (68 * col2) div 100;
                  col3 := (45 * col3) div 100;
                end;
              end;
              pix1 := (alpha * col1 + (255 - alpha) * pix1) div 255;
              pix2 := (alpha * col2 + (255 - alpha) * pix2) div 255;
              pix3 := (alpha * col3 + (255 - alpha) * pix3) div 255;
{$IFDEF darwin}
              //c := pix1 shl 24 + pix2 shl 16 + pix3 shl 8;
              //if fullscreen = 1 then
              c := pix1 shl 0 + pix2 shl 8 + pix3 shl 16;
{$ELSE}
              c := pix1 shl 16 + pix2 shl 8 + pix3 shl 0;
{$ENDIF}
              // c:=0;
              SceneImg[i1 + x1, i2 + y1] := c;
            end;
          end;
      end;
  end;

end;

//显示头像, 优先考虑'.head\'目录下的png图片

procedure DrawHeadPic(num, px, py: integer);
var
  len, grp, idx, b, bpp, i1, i2, x1, y1, pix, alpha, col: integer;
  p: pUint32;
  c: Uint32;
  pix1, pix2, pix3, col1, col2, col3: byte;
  // Area: TRect;
  // str: string;
begin
  DrawRectangle(px, py - 57, 57, 59, 0, colcolor(255), 0);

  b := 0;
  x1 := px - Head_Pic[num].x + 1;
  y1 := py - Head_Pic[num].y + 1;
  bpp := Head_Pic[num].pic.format.BytesPerPixel;
  for i1 := 0 to Head_Pic[num].pic.w - 1 do
    for i2 := 0 to Head_Pic[num].pic.h - 1 do
    begin
      if ((x1 + i1) >= 0) and ((x1 + i1) <= screen.w) and (y1 + i2 >= 0) and (y1 + i2 <= screen.h) then
      begin
        p := Pointer(Uint32(Head_Pic[num].pic.pixels) + i2 * Head_Pic[num].pic.pitch + i1 * bpp);
        c := PUint32(p)^;
        p := Pointer(Uint32(screen.pixels) + (y1 + i2) * screen.pitch + (x1 + i1) * bpp);
        pix := PUint32(p)^;


{$IFDEF darwin}
        {pix1 := (pix shr 24) and $FF;
        pix2 := (pix shr 16) and $FF;
        pix3 := (pix shr 8) and $FF;
        if fullscreen = 1 then
        begin}
        pix1 := (pix shr 0) and $FF;
        pix2 := (pix shr 8) and $FF;
        pix3 := (pix shr 16) and $FF;
        //end;
{$ELSE}
        pix1 := (pix shr 16) and $FF;
        pix2 := (pix shr 8) and $FF;
        pix3 := (pix shr 0) and $FF;
{$ENDIF}
        alpha := (c shr 24) and $FF;
        col1 := (c shr 16) and $FF;
        col2 := (c shr 8) and $FF;
        col3 := (c shr 0) and $FF;

        //   c := 0 ;

        if Gray > 0 then
        begin
          c := (col1 * 11) div 100 + (col2 * 59) div 100 + (col3 * 3) div 10;
          col1 := ((100 - gray) * col1 + gray * c) div 100;
          col2 := ((100 - gray) * col2 + gray * c) div 100;
          col3 := ((100 - gray) * col3 + gray * c) div 100;
        end
        else if blue > 0 then
        begin
          col1 := col1;
          col2 := (col2 * (150 - blue)) div 150;
          col3 := (col3 * (150 - blue)) div 150;
        end
        else if red > 0 then
        begin
          col1 := (col1 * (150 - red)) div 150;
          col2 := (col2 * (150 - red)) div 150;
          col3 := (col3);
        end
        else if green > 0 then
        begin
          col1 := (col1 * (150 - green)) div 150;
          col2 := col2;
          col3 := (col3 * (150 - green)) div 150;
        end
        else if yellow > 0 then
        begin
          col1 := (col1 * (150 - yellow)) div 150;
          col2 := col2;
          col3 := col3;
        end;


        pix1 := (alpha * col3 + (255 - alpha) * pix1) div 255;
        pix2 := (alpha * col2 + (255 - alpha) * pix2) div 255;
        pix3 := (alpha * col1 + (255 - alpha) * pix3) div 255;
{$IFDEF darwin}
        {c := pix1 shl 24 + pix2 shl 16 + pix3 shl 8;
        if fullscreen = 1 then}
        c := pix1 shl 0 + pix2 shl 8 + pix3 shl 16;
{$ELSE}
        c := pix1 shl 16 + pix2 shl 8 + pix3 shl 0;
{$ENDIF}
        PUint32(p)^ := c;

      end;
    end;

end;

//显示战场图片

procedure DrawBPic(num, px, py, shadow: integer); overload;
var
  Area: TRect;
begin
  Area.x := 0;
  Area.y := 0;
  Area.w := screen.w;
  Area.h := screen.h;
  if num < length(sidx) then
    DrawRLE8Pic(num, px, py, @SIdx[0], @SPic[0], Area, nil, shadow);

end;

procedure DrawBPic(num, px, py, shadow, mask: integer); overload;
var
  Area: TRect;
begin
  Area.x := 0;
  Area.y := 0;
  Area.w := screen.w;
  Area.h := screen.h;
  if num < length(sidx) then
    DrawRLE8Pic(num, px, py, @SIdx[0], @SPic[0], Area, nil, shadow, mask);

end;

procedure DrawBPic(num, x, y, w, h, px, py, shadow: integer); overload;
var
  Area: TRect;
begin
  Area.x := x;
  Area.y := y;
  Area.w := w;
  Area.h := h;
  if num < length(sidx) then
    DrawRLE8Pic(num, px, py, @SIdx[0], @SPic[0], Area, nil, shadow);

end;

procedure DrawBPic(num, x, y, w, h, px, py, shadow, mask: integer); overload;
var
  Area: TRect;
begin
  Area.x := x;
  Area.y := y;
  Area.w := w;
  Area.h := h;
  if num < length(sidx) then
    DrawRLE8Pic(num, px, py, @SIdx[0], @SPic[0], Area, nil, shadow, mask);

end;

procedure DrawBRolePic(num, px, py, shadow, mask: integer); overload;
var
  Area: TRect;
begin
  Area.x := 0;
  Area.y := 0;
  Area.w := screen.w;
  Area.h := screen.h;
  if num < length(widx) then
    DrawRLE8Pic(num, px, py, @WIdx[0], @WPic[0], Area, nil, shadow, mask);

end;

procedure DrawBRolePic(num, x, y, w, h, px, py, shadow, mask: integer); overload;
var
  Area: TRect;
begin
  Area.x := x;
  Area.y := y;
  Area.w := w;
  Area.h := h;
  if num < length(widx) then
    DrawRLE8Pic(num, px, py, @WIdx[0], @WPic[0], Area, nil, shadow, mask);

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
  if num < length(sidx) then
    DrawRLE8Pic(num, px, py, @SIdx[0], @SPic[0], Area, nil, shadow);

end;

//将战场图片画到映像

procedure InitialBPic(num, px, py: integer); overload;
var
  Area: TRect;
begin
  Area.x := 0;
  Area.y := 0;
  Area.w := 2304;
  Area.h := 1152;
  if num < length(sidx) then
    DrawRLE8Pic(num, px, py, @SIdx[0], @SPic[0], Area, @BFieldImg[0], 0);

end;

procedure InitialBPic(num, px, py, x, y, w, h, mask: integer); overload;
var
  Area: TRect;
  i: integer;
  image: pansichar;
begin
  if x + w > 2303 then
    w := 2303 - x;
  if y + h > 1151 then
    h := 1151 - y;
  Area.x := x;
  Area.y := y;
  Area.w := w;
  Area.h := h;
  if num < length(sidx) then
    DrawRLE8Pic(num, px, py, @SIdx[0], @SPic[0], Area, @BFieldImg[0], 0, mask);

end;
//big5转为unicode

function Big5ToUnicode(str: PChar): WideString;
var
  len: integer;
begin
{$IFDEF fpc}
  Result := UTF8Decode(CP950ToUTF8(str));
{$ELSE}
  len := MultiByteToWideChar(950, 0, PChar(str), -1, nil, 0);
  setlength(Result, len - 1);
  MultiByteToWideChar(950, 0, PChar(str), length(str), pwidechar(Result), len + 1);
{$ENDIF}
  Result := ' ' + Result;

end;

function GBKToUnicode(str: PChar): WideString;
var
  len: integer;
  word: string;
begin
  //word := Simplified2Traditional(str);
  // len := MultiByteToWideChar(936, 0, PChar(word), -1, nil, 0);
{$IFDEF fpc}
  Result := UTF8Decode(CP936ToUTF8(str));
{$ELSE}
  len := MultiByteToWideChar(936, 0, PChar(str), -1, nil, 0);
  setlength(Result, len - 1);
  MultiByteToWideChar(936, 0, PChar(str), length(str), pwidechar(Result), len + 1);
{$ENDIF}
  Result := ' ' + Result;

end;

//unicode转为big5, 仅用于输入姓名

function UnicodeToBig5(str: PWideChar): string;
var
  len: integer;
begin
{$IFDEF fpc}
  Result := UTF8ToCP950((str));
{$ELSE}
  len := WideCharToMultiByte(950, 0, PWideChar(str), -1, nil, 0, nil, nil);
  setlength(Result, len + 1);
  WideCharToMultiByte(950, 0, PWideChar(str), -1, PChar(Result), len + 1, nil, nil);
{$ENDIF}
end;

function UnicodeToGBK(str: PWideChar): string;
var
  len: integer;
begin
{$IFDEF fpc}
  Result := UTF8ToCP936((str));
{$ELSE}
  len := WideCharToMultiByte(936, 0, PWideChar(str), -1, nil, 0, nil, nil);
  setlength(Result, len + 1);
  WideCharToMultiByte(936, 0, PWideChar(str), -1, PChar(Result), len + 1, nil, nil);
{$ENDIF}

end;

//显示unicode文字

procedure DrawText(sur: PSDL_Surface; word: PUint16; x_pos, y_pos: integer; color: Uint32);
var
  dest: TSDL_Rect;
  len, i, x, y: integer;
  pword: array[0..2] of Uint16;
  words: string;
  c1, c2, c3, c4: integer;
  t: WideString;
  tempcolor: TSdl_Color;
begin
  //len := length(word);
  //{$IFDEF darwin}
  {tempcolor := TSDL_Color(color shr 8);
  if Fullscreen <> 0 then
  begin
    tempcolor.b := (color shr 0) and $FF;
    tempcolor.g := (color shr 8) and $FF;
    tempcolor.r := (color shr 16) and $FF;
    tempcolor.unused := 0;
  end;}
  //{$ELSE}
  c3 := color and $FF;
  c2 := color shr 8 and $FF;
  c1 := color shr 16 and $FF;
  c4 := color shr 24 and $FF;
  color := c1 + c2 shl 8 + c3 shl 16 + c4 shl 24;
  tempcolor := TSDL_Color(color);
  //{$ENDIF}


  pword[0] := 32;
  pword[2] := 0;
  if SIMPLE = 1 then
  begin
    t := Traditional2Simplified(PwideChar(word));
    word := puint16(t);
  end;
  x := x_pos;
  dest.x := x_pos;
  while word^ > 0 do
  begin
    pword[1] := word^;

    Inc(word);
    if pword[1] > 128 then
    begin
      Text := TTF_RenderUNICODE_blended(font, @pword[0], tempcolor);
      //dest.x := x_pos;
      dest.x := x_pos - 0;
      dest.y := y_pos;
      SDL_BlitSurface(Text, nil, sur, @dest);
      x_pos := x_pos + 20;
    end
    else
    begin
      if (pword[1] = 42) then //如果是*
      begin
        pword[1] := 0;
        x_pos := x;
        y_pos := y_pos + 19;
      end;
      Text := TTF_RenderUNICODE_blended(engfont, @pword[1], tempcolor);

      dest.x := x_pos + 10;
      dest.y := y_pos + 4;
      SDL_BlitSurface(Text, nil, sur, @dest);

      x_pos := x_pos + 10;
    end;
    SDL_FreeSurface(Text);
  end;
end;


//显示英文

procedure DrawEngText(sur: PSDL_Surface; word: PUint16; x_pos, y_pos: integer; color: Uint32);
var
  dest: TSDL_Rect;
  c1, c2, c3, c4: integer;
  tempcolor: TSDL_Color;
begin
  //{$IFDEF darwin}
  {tempcolor := TSDL_Color(color shr 8);
  if Fullscreen <> 0 then
  begin
    tempcolor.b := (color shr 0) and $FF;
    tempcolor.g := (color shr 8) and $FF;
    tempcolor.r := (color shr 16) and $FF;
    tempcolor.unused := 0;
  end;}
  //{$ELSE}
  c3 := color and $FF;
  c2 := color shr 8 and $FF;
  c1 := color shr 16 and $FF;
  c4 := color shr 24 and $FF;
  color := c1 + c2 shl 8 + c3 shl 16 + c4 shl 24;
  tempcolor := TSDL_Color(color);
  //{$ENDIF}

  Text := TTF_RenderUNICODE_blended(engfont, word, tempcolor);
  dest.x := x_pos;
  dest.y := y_pos + 4;
  SDL_BlitSurface(Text, nil, sur, @dest);
  SDL_FreeSurface(Text);

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
  words: WideString;
begin
{$IFDEF fpc}
  words := UTF8Decode(CP950ToUTF8(str));
{$ELSE}
  len := MultiByteToWideChar(950, 0, PChar(str), -1, nil, 0);
  setlength(words, len - 1);
  MultiByteToWideChar(950, 0, PChar(str), length(str), pwidechar(words), len + 1);
{$ENDIF}
  words := ' ' + words;
  //words := Simplified2Traditional(words);
  drawtext(screen, @words[1], x_pos, y_pos, color);

end;

//显示Big5阴影文字

procedure DrawBig5ShadowText(word: PChar; x_pos, y_pos: integer; color1, color2: Uint32);

var
  len: integer;
  words: WideString;
begin
{$IFDEF fpc}
  words := UTF8Decode(CP950ToUTF8(word));
{$ELSE}
  len := MultiByteToWideChar(950, 0, PChar(word), -1, nil, 0);
  setlength(words, len - 1);
  MultiByteToWideChar(950, 0, PChar(word), length(word), pwidechar(words), len + 1);
{$ENDIF}
  words := ' ' + words;
  //words := Simplified2Traditional(words);
  DrawText(screen, @words[1], x_pos + 1, y_pos, color2);
  DrawText(screen, @words[1], x_pos, y_pos, color1);

end;

//显示GBK文字

procedure DrawGBKText(sur: PSDL_Surface; str: PChar; x_pos, y_pos: integer; color: Uint32);
var
  len: integer;
  words: WideString;
begin
  words := gbktounicode(str);
  drawtext(screen, @words[1], x_pos, y_pos, color);

end;

//显示GBK阴影文字

procedure DrawGBKShadowText(word: PChar; x_pos, y_pos: integer; color1, color2: Uint32);
var
  len: integer;
  words: WideString;
begin
  words := gbktounicode(word);
  DrawText(screen, @words[1], x_pos + 1, y_pos, color2);
  DrawText(screen, @words[1], x_pos, y_pos, color1);
end;

//显示带边框的文字, 仅用于unicode, 需自定义宽度

procedure DrawTextWithRect(word: puint16; x, y, w: integer; color1, color2: uint32);
var
  len: integer;
  p: PChar;
begin
  DrawRectangle(x, y, w, 28, 0, colcolor(0, 255), 30);
  DrawShadowText(word, x - 17, y + 2, color1, color2);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

end;

//画线

procedure DrawLine(x1, y1, x2, y2, color, Width: integer);
var
  i, x, y, p, w: integer;
begin
  if x1 > x2 then
  begin
    x := x1;
    x1 := x2;
    x2 := x;
    y := y1;
    y1 := y2;
    y2 := y;
  end;
  x := x2 - x1 - Width;
  y := y2 - y1 - Width;
  if x > 0 then
  begin
    for i := 0 to x - 1 do
    begin
      p := (y * i) div x;
      DrawRectanglewithoutframe(x1 + i, y1 + p, Width, Width, color, 100);
    end;
  end
  else if y > 0 then
  begin
    for i := 0 to y - 1 do
    begin
      p := (x * i) div y;
      DrawRectanglewithoutframe(x1 + i, y1 + p, Width, Width, color, 100);
    end;
  end
  else
  begin
    DrawRectanglewithoutframe(x1 + i, y1 + p, Width, Width, color, 100);
  end;
end;

//画带边框矩形, (x坐标, y坐标, 宽, 高, 内部颜色, 边框颜色, 透明度)

procedure DrawRectangle(x, y, w, h: integer; colorin, colorframe: Uint32; alphe: integer);
var
  i1, i2, l1, l2, l3, l4: integer;
  pix: Uint32;
  pix1, pix2, pix3, pix4, color1, color2, color3, color4: byte;
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
        pix1 := pix and $FF;
        color1 := colorin and $FF;
        pix2 := pix shr 8 and $FF;
        color2 := colorin shr 8 and $FF;
        pix3 := pix shr 16 and $FF;
        color3 := colorin shr 16 and $FF;
        pix4 := pix shr 24 and $FF;
        color4 := colorin shr 24 and $FF;
        pix1 := (alphe * color1 + (100 - alphe) * pix1) div 100;
        pix2 := (alphe * color2 + (100 - alphe) * pix2) div 100;
        pix3 := (alphe * color3 + (100 - alphe) * pix3) div 100;
        pix4 := (alphe * color4 + (100 - alphe) * pix4) div 100;
        pix := pix1 + pix2 shl 8 + pix3 shl 16 + pix4 shl 24;
        putpixel(screen, i1, i2, pix);
      end;
      if (((l1 >= 4) and (l2 >= 4) and (l3 >= 4) and (l4 >= 4) and ((i1 = x) or (i1 = x + w) or
        (i2 = y) or (i2 = y + h))) or ((l1 = 4) or (l2 = 4) or (l3 = 4) or (l4 = 4))) then
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
  pix: Uint32;
  pix1, pix2, pix3, pix4, color1, color2, color3, color4: byte;
begin
  if (SDL_MustLock(screen)) then
  begin
    SDL_LockSurface(screen);
  end;
  for i1 := x to x + w do
    for i2 := y to y + h do
    begin
      pix := getpixel(screen, i1, i2);
      pix1 := pix and $FF;
      color1 := colorin and $FF;
      pix2 := pix shr 8 and $FF;
      color2 := colorin shr 8 and $FF;
      pix3 := pix shr 16 and $FF;
      color3 := colorin shr 16 and $FF;
      pix4 := pix shr 24 and $FF;
      color4 := colorin shr 24 and $FF;
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

//重画屏幕, SDL_UpdateRect2(screen,0,0,screen.w,screen.h)可显示

procedure Redraw;
var
  i: integer;
begin

  case where of
    0: DrawMMap;
    1: DrawScene;
    2: DrawWholeBField;
    3: display_imgfromSurface(BEGIN_PIC.pic, 0, 0);
    4: display_imgfromSurface(DEATH_PIC.pic, 0, 0);
  end;

end;

//显示主地图场景于屏幕

procedure DrawMMap;
var
  i1, i2, i, sum, x, y, k: integer;
  temp: array[0..479, 0..479] of smallint;
  Width, Height: smallint;
  pos: TPosition;
  BuildingList, CenterList: array[0..1000] of TPosition;
begin
  if (SDL_MustLock(screen)) then
  begin
    if (SDL_LockSurface(screen) < 0) then
    begin
      MessageBox(0, PChar(Format('Can''t lock screen : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
  end;
  for i1 := 0 to screen.w do
    for i2 := 0 to screen.h do
    begin
      MaskArray[i1, i2] := 1;
    end;
  //由上到下绘制, 先绘制地面和表面, 同时计算出现的建筑数目


  k := 0;
  for sum := -29 to 41 do
    for i := -16 to 16 do
    begin
      i1 := Mx + i + (sum div 2);
      i2 := My - i + (sum - sum div 2);
      if (i1 >= 0) and (i1 < 480) and (i2 >= 0) and (i2 < 480) then
      begin
        temp[i1, i2] := 0;
        if building[i1, i2] <> 0 then temp[i1, i2] := building[i1, i2];
        //将主角和空船的位置计入建筑
        if (i1 = mx) and (i2 = my) then
        begin
          if (InShip = 0) then
          begin
            if still = 0 then
              temp[i1, i2] := 2501 + MFace * 7 + MStep
            else
              temp[i1, i2] := 2528 + Mface * 6 + MStep;
          end
          else
          begin
            temp[i1, i2] := 3714 + MFace * 4 + (MStep + 1) div 2;
          end;
          temp[i1, i2] := temp[i1, i2] * 2;
        end;
        if (i1 = shipy) and (i2 = shipx) then
        begin
          if (InShip = 0) then
          begin
            temp[i1, i2] := 3715 + ShipFace * 4;
            temp[i1, i2] := temp[i1, i2] * 2;
          end;
        end;
        if temp[i1, i2] > 0 then
        begin
          BuildingList[k].x := i1;
          BuildingList[k].y := i2;
          Width := smallint(Mpic[MIdx[temp[i1, i2] div 2 - 1]]);
          //根据图片的宽度计算图的中点，为避免出现小数，实际是中点坐标的2倍
          CenterList[k].x := i1 * 2 - (Width + 35) div 36 + 1;
          CenterList[k].y := i2 * 2 - (Width + 35) div 36 + 1;
          k := k + 1;
        end;
      end
      else
        DrawMPic(0, pos.x, pos.y, 3);
    end;


  //按照中点坐标排序
  for i1 := 0 to k - 2 do
    for i2 := i1 + 1 to k - 1 do
    begin
      if CenterList[i1].x + CenterList[i1].y > CenterList[i2].x + CenterList[i2].y then
      begin
        pos := BuildingList[i1];
        BuildingList[i1] := BuildingList[i2];
        BuildingList[i2] := pos;
        pos := CenterList[i1];
        CenterList[i1] := CenterList[i2];
        CenterList[i2] := pos;
      end;
    end;
  for i := k - 1 downto 0 do
  begin
    x := BuildingList[i].x;
    y := BuildingList[i].y;
    Pos := GetPositionOnScreen(x, y, Mx, My);
    DrawMPic(temp[x, y] div 2, pos.x, pos.y, 3);
  end;

  k := 0;
  for sum := 41 downto -29 do
    for i := 16 downto -16 do
    begin
      i1 := Mx + i + (sum div 2);
      i2 := My - i + (sum - sum div 2);
      Pos := GetPositionOnScreen(i1, i2, Mx, My);
      if (i1 >= 0) and (i1 < 480) and (i2 >= 0) and (i2 < 480) then
      begin
        if (sum >= -27) and (sum <= 28) and (i >= -9) and (i <= 9) then
        begin
          if surface[i1, i2] > 0 then
            DrawMPic(surface[i1, i2] div 2, pos.x, pos.y, 3);
          DrawMPic(earth[i1, i2] div 2, pos.x, pos.y, 3);
        end;
      end;
    end;

  DrawClouds;

  if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;
  //SDL_UpdateRect2(screen, 0,0,screen.w,screen.h);

end;

//画场景到屏幕

procedure DrawScene;
var
  i1, i2, x, y, xpoint, ypoint: integer;
  dest: tsdl_rect;
  word: WideString;
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
    DrawSceneWithoutRole(Sx, Sy);
    DrawRoleOnScene(Sx, Sy);
  end
  else
  begin
    DrawSceneWithoutRole(Cx, Cy);
    if (DData[CurScene, CurEvent, 10] = Sx) and (DData[CurScene, CurEvent, 9] = Sy) then
    begin
      if (CurEvent <> Begin_Event) then
      begin
        DrawRoleOnScene(cx, cy);
      end;
    end
    else DrawRoleOnScene(cx, cy);
  end;

  if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;
  //SDL_UpdateRect2(screen, 0,0,screen.w,screen.h);
  if time > 0 then
  begin
    word := formatfloat('0', time div 60) + ':' + formatfloat('00', time mod 60);
    drawshadowtext(@word[1], 5, 5, colcolor(0, 5), colcolor(0, 7));
  end;

end;
//画不含主角的场景(与DrawSceneByCenter相同)

procedure DrawSceneWithoutRole(x, y: integer);
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

  loadScenePart(-x * 18 + y * 18 + 1151 - CENTER_X, x * 9 + y * 9 + 9 - CENTER_Y);

  if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;
  //SDL_UpdateRect2(screen, 0,0,screen.w,screen.h);
end;

//画主角于场景

procedure DrawRoleOnScene(x, y: integer);
var
  i1, i2, xpoint, ypoint, i, rolenum: integer;
  pos, pos1: TPosition;
  rect1, rect2: tsdl_Rect;
  //col1, col2, col3, alpha, pix1, pix2, pix3, pix, pix4: cardinal;
begin
  if ShowMR then
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
    DrawSPic(2501 + SFace * 7 + SStep, pos.x, pos.y - SData[CurScene, 4, Sx, Sy], pos.x - 20,
      pos.y - 60 - SData[CurScene, 4, Sx, Sy], 40, 60, 1);

    //重画主角附近的部分, 考虑遮挡
    //以下假设无高度地面不会产生任何对主角的遮挡


    for i1 := 0 to 63 do
      for i2 := 0 to 63 do
      begin
        pos1 := getpositiononscreen(i1, i2, x, y);
        if (i1 in [0..63]) and (i2 in [0..63]) then
        begin
          if (SData[CurScene, 0, i1, i2] > 0) then
            DrawSPic(SData[CurScene, 0, i1, i2] div 2, pos1.x, pos1.y, pos.x - 20, pos.y -
              60 - SData[CurScene, 4, Sx, Sy], 40, 60, 2)
          else if (SData[CurScene, 0, i1, i2] < 0) then
            DrawSNewPic(-SData[CurScene, 0, i1, i2] div 2, pos1.x, pos1.y, pos.x - 20, pos.y -
              60 - SData[CurScene, 4, Sx, Sy], 40, 60, 2);

          if (SData[CurScene, 1, i1, i2] > 0) then
            DrawSPic(SData[CurScene, 1, i1, i2] div 2, pos1.x, pos1.y - SData[CurScene, 4, i1, i2],
              pos.x - 20, pos.y - 60 - SData[CurScene, 4, Sx, Sy], 40, 60, 2)
          else if (SData[CurScene, 1, i1, i2] < 0) then
            DrawSNewPic(-SData[CurScene, 1, i1, i2] div 2, pos1.x, pos1.y - SData[CurScene, 4, i1, i2],
              pos.x - 20, pos.y - 60 - SData[CurScene, 4, Sx, Sy], 40, 60, 2);
          if (i1 = Sx) and (i2 = Sy) then
            DrawSPic(2501 + SFace * 7 + SStep, pos1.x, pos1.y - SData[CurScene, 4, i1, i2],
              pos.x - 20, pos.y - 60 - SData[CurScene, 4, Sx, Sy], 40, 60, 1);

          if (SData[CurScene, 2, i1, i2] > 0) then
            DrawSPic(SData[CurScene, 2, i1, i2] div 2, pos1.x, pos1.y - SData[CurScene, 5, i1, i2],
              pos.x - 20, pos.y - 60 - SData[CurScene, 4, Sx, Sy], 40, 60, 2)
          else if (SData[CurScene, 2, i1, i2] < 0) then
            DrawSNewPic(-SData[CurScene, 2, i1, i2] div 2, pos1.x, pos1.y - SData[CurScene, 5, i1, i2],
              pos.x - 20, pos.y - 60 - SData[CurScene, 4, Sx, Sy], 40, 60, 2);
          if (SData[CurScene, 3, i1, i2] >= 0) then
          begin
            if (DData[CurScene, SData[CurScene, 3, i1, i2], 5] > 0) then
              DrawSPic(DData[CurScene, SData[CurScene, 3, i1, i2], 5] div 2, pos1.x, pos1.y -
                SData[CurScene, 4, i1, i2], pos.x - 20, pos.y - 60 - SData[CurScene, 4, Sx, Sy], 40, 60, 2);
            if (DData[CurScene, SData[CurScene, 3, i1, i2], 5] < 0) then
              DrawSNewPic(-DData[CurScene, SData[CurScene, 3, i1, i2], 5] div 2, pos1.x,
                pos1.y - SData[CurScene, 4, i1, i2], pos.x - 20, pos.y - 60 - SData[CurScene, 4, Sx, Sy], 40, 60, 2);
          end;

        end;
      end;
  end;
  if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;
end;

//Save the image informations of the whole Scene.
//生成场景映像

procedure InitialScene();
var
  i1, i2, i, r, x, y: integer;
  pos: TPosition;
  c: cardinal;
  map: psdl_surface;
  bpp: integer;
  p: PInteger;
  str: string;
begin
  for i1 := 0 to 2303 do
    for i2 := 0 to 1151 do
    begin
      SceneImg[i1, i2] := 0;
    end;
  setscene();

  //画场景贴图的顺序应为先整体画出无高度的地面层，再将其他部分一起画出
  //以下使用的顺序可能在墙壁附近会造成少量的遮挡，在画图中应尽量避免这种状况
  //或者使用更合理的3D的顺序
  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      x := -i1 * 18 + i2 * 18 + 1151;
      y := i1 * 9 + i2 * 9 + 9;
      if SData[CurScene, 0, i1, i2] > 0 then
        InitialSPic(SData[CurScene, 0, i1, i2] div 2, x, y, 0, 0, 2304, 1152)
      else if SData[CurScene, 0, i1, i2] < 0 then
        InitNewPic(-SData[CurScene, 0, i1, i2] div 2, x, y, 0, 0, 2304, 1152);

      if (SData[CurScene, 1, i1, i2] > 0) then
        InitialSPic(SData[CurScene, 1, i1, i2] div 2, x, y - SData[CurScene, 4, i1, i2], 0, 0, 2304, 1152)
      else if SData[CurScene, 1, i1, i2] < 0 then
        InitNewPic(-SData[CurScene, 1, i1, i2] div 2, x, y - SData[CurScene, 4, i1, i2], 0, 0, 2304, 1152);

      if (SData[CurScene, 2, i1, i2] > 0) then
        InitialSPic(SData[CurScene, 2, i1, i2] div 2, x, y - SData[CurScene, 5, i1, i2], 0, 0, 2304, 1152)
      else if (SData[CurScene, 2, i1, i2] < 0) then
        InitNewPic(-SData[CurScene, 2, i1, i2] div 2, x, y - SData[CurScene, 5, i1, i2], 0, 0, 2304, 1152);

      if (SData[CurScene, 3, i1, i2] >= 0) then
      begin
        if DData[CurScene, SData[CurScene, 3, i1, i2], 7] > 0 then
          DData[CurScene, SData[CurScene, 3, i1, i2], 5] := DData[CurScene, SData[CurScene, 3, i1, i2], 7];
        if (DData[CurScene, SData[CurScene, 3, i1, i2], 5] > 0) then
          InitialSPic(DData[CurScene, SData[CurScene, 3, i1, i2], 5] div 2, x, y -
            SData[CurScene, 4, i1, i2], 0, 0, 2304, 1152);

        if DData[CurScene, SData[CurScene, 3, i1, i2], 7] < 0 then
          DData[CurScene, SData[CurScene, 3, i1, i2], 5] := DData[CurScene, SData[CurScene, 3, i1, i2], 7];
        if (DData[CurScene, SData[CurScene, 3, i1, i2], 5] < 0) then
          InitNewPic(-DData[CurScene, SData[CurScene, 3, i1, i2], 5] div 2, x, y -
            SData[CurScene, 4, i1, i2], 0, 0, 2304, 1152);
      end;
    end;

end;

//更改场景映像, 用于动画, 场景内动态效果

procedure UpdateScene(xs, ys, oldPic, newpic: integer);
var
  i1, i2, x, y: integer;
  num, offset: integer;
  xp, yp, xp1, yp1, xp2, yp2, w2, w1, h1, h2, w, h: smallint;
begin

  x := -xs * 18 + ys * 18 + 1151;
  y := xs * 9 + ys * 9 + 9;

  oldpic := oldpic div 2;
  newpic := newpic div 2;
  if oldpic > 0 then
  begin
    offset := SIdx[oldpic - 1];
    xp1 := x - (SPic[offset + 4] + 256 * SPic[offset + 5]);
    yp1 := y - (SPic[offset + 6] + 256 * SPic[offset + 7]) - SData[CurScene, 4, xs, ys];
    w1 := (SPic[offset] + 256 * SPic[offset + 1]);
    h1 := (SPic[offset + 2] + 256 * SPic[offset + 3]);
    //  InitialSPic(oldpic , x, y,  xp, yp, w, h, 1);
  end
  else if oldpic < -1 then
  begin
    xp1 := x - scenepic[-oldpic].x;
    yp1 := y - scenepic[-oldpic].y - SData[CurScene, 4, xs, ys];
    w1 := scenepic[-oldpic].pic.w;
    h1 := scenepic[-oldpic].pic.h;
    // InitNewPic(oldpic , x, y, 0, 0, scenepic[-oldpic].pic.w, scenepic[-oldpic].pic.h, 1);
  end
  else
  begin
    xp1 := x;
    yp1 := y - SData[CurScene, 4, xs, ys];
    w1 := 0;
    h1 := 0;
  end;

  if newpic > 0 then
  begin
    offset := SIdx[newpic - 1];
    xp2 := x - (SPic[offset + 4] + 256 * SPic[offset + 5]);
    yp2 := y - (SPic[offset + 6] + 256 * SPic[offset + 7]) - SData[CurScene, 4, xs, ys];
    w2 := (SPic[offset] + 256 * SPic[offset + 1]);
    h2 := (SPic[offset + 2] + 256 * SPic[offset + 3]);
    //  InitialSPic(oldpic , x, y,  xp, yp, w, h, 1);
  end
  else if newpic < -1 then
  begin
    xp2 := x - scenepic[-newpic].x;
    yp2 := y - scenepic[-newpic].y - SData[CurScene, 4, xs, ys];
    w2 := scenepic[-newpic].pic.w;
    h2 := scenepic[-newpic].pic.h;
    //  InitNewPic(oldpic , x, y, 0, 0, scenepic[-oldpic].pic.w, scenepic[-oldpic].pic.h, 1);
  end
  else
  begin
    xp2 := x;
    yp2 := y - SData[CurScene, 4, xs, ys];
    w2 := 0;
    h2 := 0;
  end;
  xp := min(xp2, xp1) - 1;
  yp := min(yp2, yp1) - 1;
  w := max(xp2 + w2, xp1 + w1) + 3 - xp;
  h := max(yp2 + h2, yp1 + h1) + 3 - yp;

  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      x := -i1 * 18 + i2 * 18 + 1151;
      y := i1 * 9 + i2 * 9 + 9;
      if SData[CurScene, 0, i1, i2] > 0 then
        InitialSPic(SData[CurScene, 0, i1, i2] div 2, x, y, xp, yp, w, h, 0)
      else if SData[CurScene, 0, i1, i2] < 0 then
        InitNewPic(-SData[CurScene, 0, i1, i2] div 2, x, y, xp, yp, w, h, 0);

      if (SData[CurScene, 1, i1, i2] > 0) then
        InitialSPic(SData[CurScene, 1, i1, i2] div 2, x, y - SData[CurScene, 4, i1, i2], xp, yp, w, h, 0)
      else if SData[CurScene, 1, i1, i2] < 0 then
        InitNewPic(-SData[CurScene, 1, i1, i2] div 2, x, y - SData[CurScene, 4, i1, i2], xp, yp, w, h, 0);

      if (SData[CurScene, 2, i1, i2] > 0) then
        InitialSPic(SData[CurScene, 2, i1, i2] div 2, x, y - SData[CurScene, 5, i1, i2], xp, yp, w, h, 0)
      else if (SData[CurScene, 2, i1, i2] < 0) then
        InitNewPic(-SData[CurScene, 2, i1, i2] div 2, x, y - SData[CurScene, 5, i1, i2], xp, yp, w, h, 0);

      if (SData[CurScene, 3, i1, i2] >= 0) then
      begin
        if (DData[CurScene, SData[CurScene, 3, i1, i2], 5] > 0) then
          InitialSPic(DData[CurScene, SData[CurScene, 3, i1, i2], 5] div 2, x, y -
            SData[CurScene, 4, i1, i2], xp, yp, w, h, 0);
        if (DData[CurScene, SData[CurScene, 3, i1, i2], 5] < 0) then
          InitNewPic(-DData[CurScene, SData[CurScene, 3, i1, i2], 5] div 2, x, y -
            SData[CurScene, 4, i1, i2], xp, yp, w, h, 0);
      end;
    end;
end;

//将场景映像画到屏幕

procedure LoadScenePart(x, y: integer);
var
  i1, i2, a, b: integer;
  alphe, pix: Uint32;
  pix1, pix2, pix3, pix4: byte;
begin
  if rs = 0 then
  begin
    randomcount := random(640);
  end;
  for i1 := 0 to screen.w - 1 do
    for i2 := 0 to screen.h - 1 do
    begin
      pix := Sceneimg[x + i1, y + i2];
      if water >= 0 then
      begin
        b := (i2 + water div 3) mod 60;

        b := snowalpha[0][b];
        if b > 128 then b := b - 256;

        pix := Sceneimg[x + i1 - b, y + i2];
      end
      else if snow >= 0 then
      begin
        b := i1 + randomcount;
        if b >= 640 then b := b - 640;
        b := snowalpha[i2][b];
        if b = 1 then pix := colcolor($FF);
      end
      else if fog then
      begin
        b := i1 + randomcount;
        if b >= 640 then b := b - 640;
        alphe := snowalpha[i2][b];
        pix1 := pix and $FF;
        pix2 := pix shr 8 and $FF;
        pix3 := pix shr 16 and $FF;
        pix4 := pix shr 24 and $FF;
        pix1 := (alphe * $FF + (100 - alphe) * pix1) div 100;
        pix2 := (alphe * $FF + (100 - alphe) * pix2) div 100;
        pix3 := (alphe * $FF + (100 - alphe) * pix3) div 100;
        pix4 := (alphe * $FF + (100 - alphe) * pix4) div 100;
        pix := pix1 + pix2 shl 8 + pix3 shl 16 + pix4 shl 24;

      end
      else if rain >= 0 then
      begin
        b := i1 + randomcount;
        if b >= 640 then b := b - 640;
        b := snowalpha[i2][b];
        if b = 1 then
        begin
          alphe := 50;
          pix1 := pix and $FF;
          pix2 := pix shr 8 and $FF;
          pix3 := pix shr 16 and $FF;
          pix4 := pix shr 24 and $FF;
          pix1 := (alphe * $FF + (100 - alphe) * pix1) div 100;
          pix2 := (alphe * $FF + (100 - alphe) * pix2) div 100;
          pix3 := (alphe * $FF + (100 - alphe) * pix3) div 100;
          pix4 := (alphe * $FF + (100 - alphe) * pix4) div 100;
          pix := pix1 + pix2 shl 8 + pix3 shl 16 + pix4 shl 24;
        end;
      end
      else
      if showBlackScreen = True then
      begin
        alphe := snowalpha[i2][i1];
        if alphe >= 100 then pix := 0
        else if alphe > 0 then
        begin
          pix1 := pix and $FF;
          pix2 := pix shr 8 and $FF;
          pix3 := pix shr 16 and $FF;
          pix4 := pix shr 24 and $FF;
          pix1 := ((100 - alphe) * pix1) div 100;
          pix2 := ((100 - alphe) * pix2) div 100;
          pix3 := ((100 - alphe) * pix3) div 100;
          pix4 := ((100 - alphe) * pix4) div 100;
          pix := pix1 + pix2 shl 8 + pix3 shl 16 + pix4 shl 24;
        end;
      end;
      if (x + i1 >= 0) and (y + i2 >= 0) and (x + i1 < 2304) and (y + i2 < 1152) then
        putpixel(screen, i1, i2, pix)
      else
        putpixel(screen, i1, i2, 0);

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
      if (Bfield[2, i1, i2] >= 0) and (Brole[Bfield[2, i1, i2]].rnum >= 0) then
      begin
        if (Brole[Bfield[2, i1, i2]].Show = 0) then
          DrawRoleOnBfield(i1, i2);
      end
      else if (Bfield[5, i1, i2] >= 0) and (Brole[Bfield[5, i1, i2]].rnum >= 0) then
      begin
        if (Brole[Bfield[5, i1, i2]].Show = 0) then
          DrawRoleOnBfield(i1, i2);
      end;
    end;
  if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;

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
  //SDL_UpdateRect2(screen, 0,0,screen.w,screen.h);

end;

//画战场上人物, 需更新人物身前的遮挡

procedure DrawRoleOnBfield(x, y: integer);
var
  i1, i2, w, h, xs, ys, offset, num, xpoint, ypoint: integer;
  pos, pos1: Tposition;
  Ppic: pbyte;
  Pidx: pinteger;
begin
  if (SDL_MustLock(screen)) then
  begin
    if (SDL_LockSurface(screen) < 0) then
    begin
      MessageBox(0, PChar(Format('Can''t lock screen : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
  end;
  if (Bfield[2, x, y] >= 0) then num := Rrole[Brole[Bfield[2, x, y]].rnum].HeadNum * 4 +
      Brole[Bfield[2, x, y]].Face + BEGIN_BATTLE_ROLE_PIC
  else if (Bfield[5, x, y] >= 0) then num := Rrole[Brole[Bfield[5, x, y]].rnum].HeadNum * 4 +
      Brole[Bfield[5, x, y]].Face + BEGIN_BATTLE_ROLE_PIC;
  pidx := @WIdx[0];
  ppic := @WPic[0];
  if num = 0 then
    offset := 0
  else
  begin
    Inc(Pidx, num - 1);
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


  pos := GetPositionOnScreen(x, y, Bx, By);

  if (Bfield[2, x, y] >= 0) then
  begin
    if (Brole[Bfield[2, x, y]].Show = 0) and (Brole[Bfield[2, x, y]].rnum >= 0) then
    begin
      DrawBRolePic(num, pos.x - xs, pos.y - ys, w, h, pos.x, pos.y, 0, 1);
    end;
  end
  else if (Bfield[5, x, y] >= 0) then
  begin
    if (Brole[Bfield[5, x, y]].Show = 0) and (Brole[Bfield[5, x, y]].rnum >= 0) then
      DrawBRolePic(num, pos.x - xs, pos.y - ys, w, h, pos.x, pos.y, 0, 1);
  end;

  for i1 := x to 63 do
    for i2 := y to 63 do
    begin
      pos1 := GetPositionOnScreen(i1, i2, Bx, By);
      if (Bfield[1, i1, i2] > 0) then
      begin
        DrawBPic(Bfield[1, i1, i2] div 2, pos.x - xs, pos.y - ys, w, h, pos1.x, pos1.y, 0, 2);
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
  for i1 := 0 to 2303 do
    for i2 := 0 to 1151 do
      Bfieldimg[i1, i2] := 0;
  for i1 := 0 to 63 do
  begin
    for i2 := 0 to 63 do
    begin
      x := -i1 * 18 + i2 * 18 + 1151;
      y := i1 * 9 + i2 * 9 + 9;
      if (i1 < 0) or (i2 < 0) or (i1 > 63) or (i2 > 63) then
        InitialBPic(0, x, y)
      else
      begin
        InitialBPic(bfield[0, i1, i2] div 2, x, y);
        if (bfield[1, i1, i2] > 0) then
          InitialBPic(bfield[1, i1, i2] div 2, x, y);
      end;
    end;
  end;

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

//画带光标的子程
//此子程效率不高

procedure DrawBFieldWithCursor(AttAreaType, step, range: integer);
var
  i, i1, i2, bnum, minstep: integer;
  x1, y1, x2, x, y, y2, p, w: integer;
  pos: TPosition;
begin
  p := 0;
  redraw;
  if (SDL_MustLock(screen)) then
  begin
    if (SDL_LockSurface(screen) < 0) then
    begin
      MessageBox(0, PChar(Format('Can''t lock screen : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
  end;
  case AttAreaType of
    0: //目标系点型(用于移动、点攻、用毒、医疗等)、目标系十型、目标系菱型、原地系菱型
    begin
      for i1 := 0 to 63 do
        for i2 := 0 to 63 do
        begin
          Bfield[4, i1, i2] := 0;
          pos := GetpositionOnScreen(i1, i2, Bx, By);
          if Bfield[0, i1, i2] > 0 then
          begin
            if (abs(i1 - Ax) + abs(i2 - Ay)) <= range then
            begin
              DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 1);
              Bfield[4, i1, i2] := 1;
            end
            else if (abs(i1 - Bx) + abs(i2 - By) <= step) and (Bfield[3, i1, i2] >= 0) then
              DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 0)
            else
              DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, -1);
          end;
        end;
    end;
    1: //方向系线型
    begin
      for i1 := 0 to 63 do
        for i2 := 0 to 63 do
        begin
          Bfield[4, i1, i2] := 0;
          pos := GetpositionOnScreen(i1, i2, Bx, By);
          if Bfield[0, i1, i2] > 0 then
          begin
            if ((i1 = Bx) and (abs(i2 - By) <= step) and (((i2 - By) * (Ay - By)) > 0)) or
              ((i2 = By) and (abs(i1 - Bx) <= step) and (((i1 - Bx) * (Ax - Bx)) > 0)) then
            begin
              DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 1);
              Bfield[4, i1, i2] := 1;
            end
            else if ((i1 = Bx) and (abs(i2 - By) <= step)) or ((i2 = By) and (abs(i1 - Bx) <= step)) then
              DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 0)
            else
              DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, -1);
          end;
        end;
    end;
    2: //原地系十型、原地系叉型、原地系米型
    begin
      for i1 := 0 to 63 do
        for i2 := 0 to 63 do
        begin
          Bfield[4, i1, i2] := 0;
          pos := GetpositionOnScreen(i1, i2, Bx, By);
          if Bfield[0, i1, i2] > 0 then
          begin
            if ((i1 = Bx) and (abs(i2 - By) <= step)) or ((i2 = By) and (abs(i1 - Bx) <= step)) or
              ((abs(i1 - Bx) = abs(i2 - By)) and (abs(i1 - Bx) <= range)) then
            begin
              DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 1);
              Bfield[4, i1, i2] := 1;
            end
            else
              DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, -1);
          end;
        end;
    end;
    3: //目标系方型、原地系方型
    begin
      for i1 := 0 to 63 do
        for i2 := 0 to 63 do
        begin
          Bfield[4, i1, i2] := 0;
          pos := GetpositionOnScreen(i1, i2, Bx, By);
          if Bfield[0, i1, i2] > 0 then
          begin
            if (abs(i1 - Ax) <= range) and (abs(i2 - Ay) <= range) then
            begin
              DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 1);
              Bfield[4, i1, i2] := 1;
            end
            else if (abs(i1 - Bx) + abs(i2 - By) <= step) and (Bfield[0, i1, i2] >= 0) then
              DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 0)
            else
              DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, -1);
          end;
        end;
    end;
    4: //方向系菱型
    begin
      for i1 := 0 to 63 do
        for i2 := 0 to 63 do
        begin
          Bfield[4, i1, i2] := 0;
          pos := GetpositionOnScreen(i1, i2, Bx, By);
          if Bfield[0, i1, i2] > 0 then
          begin
            if ((abs(i1 - Bx) + abs(i2 - By) <= step) and (abs(i1 - Bx) <> abs(i2 - By))) and
              ((((i1 - Bx) * (Ax - Bx) > 0) and (abs(i1 - Bx) > abs(i2 - By))) or
              (((i2 - By) * (Ay - By) > 0) and (abs(i1 - Bx) < abs(i2 - By)))) then
            begin
              DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 1);
              Bfield[4, i1, i2] := 1;
            end
            else if (abs(i1 - Bx) + abs(i2 - By) <= step) and (abs(i1 - Bx) <> abs(i2 - By)) then
              DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 0)
            else
              DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, -1);
          end;
        end;
    end;
    5: //方向系角型
    begin
      for i1 := 0 to 63 do
        for i2 := 0 to 63 do
        begin
          Bfield[4, i1, i2] := 0;
          pos := GetpositionOnScreen(i1, i2, Bx, By);
          if Bfield[0, i1, i2] > 0 then
          begin
            if ((abs(i1 - Bx) <= step) and (abs(i2 - By) <= step) and (abs(i1 - Bx) <>
              abs(i2 - By))) and ((((i1 - Bx) * (Ax - Bx) > 0) and (abs(i1 - Bx) > abs(i2 - By))) or
              (((i2 - By) * (Ay - By) > 0) and (abs(i1 - Bx) < abs(i2 - By)))) then
            begin
              DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 1);
              Bfield[4, i1, i2] := 1;
            end
            else if (abs(i1 - Bx) <= step) and (abs(i2 - By) <= step) and (abs(i1 - Bx) <> abs(i2 - By)) then
              DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 0)
            else
              DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, -1);
          end;
        end;
    end;
    6: //远程
    begin
      minstep := 3;
      for i1 := 0 to 63 do
        for i2 := 0 to 63 do
        begin
          Bfield[4, i1, i2] := 0;
          pos := GetpositionOnScreen(i1, i2, Bx, By);
          if Bfield[0, i1, i2] > 0 then
          begin
            if (abs(i1 - Ax) + abs(i2 - Ay)) <= range then
            begin
              DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 1);
              Bfield[4, i1, i2] := 1;
            end
            else if (abs(i1 - Bx) + abs(i2 - By) <= step) and (abs(i1 - Bx) + abs(i2 - By) > minstep) and
              (Bfield[3, i1, i2] >= 0) then
              DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 0)
            else
              DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, -1);
          end;
        end;
    end;
    7: //无定向直线
    begin
      for i1 := 0 to 63 do
        for i2 := 0 to 63 do
        begin
          Bfield[4, i1, i2] := 0;
          pos := GetpositionOnScreen(i1, i2, Bx, By);
          if Bfield[0, i1, i2] > 0 then
          begin
            if (i1 = bx) and (i2 = by) then
            begin
              DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 1);
              Bfield[4, i1, i2] := 1;
            end
            else if (abs(i1 - Bx) + abs(i2 - By) <= step) and (Bfield[3, i1, i2] >= 0) then
            begin
              if ((abs(i1 - Bx) <= abs(ax - Bx)) and (abs(i2 - By) <= abs(ay - By))) then
              begin
                if (abs(ax - bx) > abs(ay - by)) and (((i1 - bx) / (ax - bx)) > 0) and
                  (i2 = Round(((i1 - bx) * (ay - by)) / (ax - bx)) + by) then
                begin
                  DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 1);
                  Bfield[4, i1, i2] := 1;
                end
                else if (abs(ax - bx) <= abs(ay - by)) and (((i2 - by) / (ay - by)) > 0) and
                  (i1 = Round(((i2 - by) * (ax - bx)) / (ay - by)) + bx) then
                begin
                  DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 1);
                  Bfield[4, i1, i2] := 1;
                end
                else DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 0);
              end
              else DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 0);
            end
            else
              DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, -1);
          end;
        end;

    end;
  end;

  //看来分两次循环还是有必要的，否则遮挡会有问题
  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      pos := getpositiononScreen(i1, i2, Bx, By);
      if Bfield[1, i1, i2] > 0 then
        DrawBPic(Bfield[1, i1, i2] div 2, pos.x, pos.y, 0, 0);
      bnum := Bfield[2, i1, i2];
      if (bnum >= 0) and (Brole[bnum].Dead = 0) then
      begin
        if Brole[bnum].rnum >= 0 then
        begin
          if (Bfield[4, i1, i2] > 0) and (Brole[bnum].Team <> Brole[Bfield[2, Bx, By]].Team) then
            HighLight := True;
          DrawBRolePic(Rrole[Brole[bnum].rnum].HeadNum * 4 + Brole[bnum].Face + BEGIN_BATTLE_ROLE_PIC,
            pos.x, pos.y, 0, 0);
          HighLight := False;
        end;
      end;
    end;
  if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;
  showprogress;
end;

//画带效果的战场

procedure DrawBFieldWithEft(f, Epicnum, bigami, level: integer);
var
  i, i1, i2, n: integer;
  pos: TPosition;
  image: Tpic;
begin
  if (SDL_MustLock(screen)) then
  begin
    if (SDL_LockSurface(screen) < 0) then
    begin
      MessageBox(0, PChar(Format('Can''t lock screen : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
  end;
  image := getpngpic(f, epicnum);
  DrawBfieldWithoutRole(Bx, By);
  n := 0;

  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      if (Bfield[2, i1, i2] >= 0) and (Brole[Bfield[2, i1, i2]].Show = 0) then
        if (Brole[Bfield[2, i1, i2]].rnum >= 0) then
          DrawRoleOnBfield(i1, i2);
    end;
  if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;
  if bigami = 0 then
  begin
    for i1 := 0 to 63 do
      for i2 := 0 to 63 do
      begin
        pos := getpositiononScreen(i1, i2, Bx, By);
        //if (Effect <> 0) and ((image.pic.w > 120) or (image.pic.h > 120)) and ((i1 + i2) mod 2 = 0) then continue;
        //showmessage(inttostr(image.pic.h)+' ' + inttostr(image.pic.w));
        if Bfield[4, i1, i2] > 0 then
        begin
          //if (i1 mod 2 - i2 mod 2 = 0) or (Eidx[length(Eidx) - 1] >= 0) then
          begin
            Inc(n);
            DrawEftPic(image, pos.x, pos.y, 0);
          end;
          //drawPngPic(image, Eidx, pos.x, pos.y);
        end;
      end;
    n := 300 - n * 3;
    if (image.pic.w > 120) or (image.pic.h > 120) then n := n - 5;
    n := n div 10;
    if n > 0 then
      sdl_delay((n * GameSpeed) div 10);
  end
  else
  begin
    pos := getpositiononScreen(ax, ay, Bx, By);
    if Bfield[4, ax, ay] > 0 then
    begin
      // if (i1 mod 2 - i2 mod 2 = 0) or (Eidx[length(Eidx) - 1] >= 0) then
      DrawEftPic(image, pos.x, pos.y, level);
      //drawPngPic(image, Eidx, pos.x, pos.y);
    end;
    n := (30 + (image.black - 1) * 10);
    sdl_delay(((n + 5) * GameSpeed) div 10);
  end;
  sdl_freesurface(image.pic);

end;

//画带人物动作的战场

procedure DrawBFieldWithAction(f, bnum, Apicnum: integer);
var
  i, i1, i2, ii1, x1, y1, ii2: integer;
  pos1, pos: TPosition;
  image: Tpic;
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
  image := getpngpic(f, Apicnum);

  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      if (Bfield[2, i1, i2] >= 0) and (Brole[Bfield[2, i1, i2]].Show = 0) and (Bfield[2, i1, i2] <> bnum) then
      begin
        if (Brole[Bfield[2, i1, i2]].rnum >= 0) then
          DrawRoleOnBfield(i1, i2);
      end;
      if (Bfield[2, i1, i2] = bnum) then
      begin
        pos1 := GetPositionOnScreen(i1, i2, Bx, By);
        for ii1 := i1 to 63 do
          for ii2 := i2 to 63 do
          begin
            pos := GetPositionOnScreen(ii1, ii2, Bx, By);
            if (i1 = ii1) and (i2 = ii2) then
              drawPngPic(image, pos1.x, pos1.y, 1);
            if (Bfield[1, ii1, ii2] > 0) then
            begin
              DrawBPic(Bfield[1, ii1, ii2] div 2, pos1.x - image.x, pos1.y - image.y, image.pic.w,
                image.pic.h, pos.x, pos.y, 0);
            end;

          end;

      end;
    end;
  if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;
  SDL_FreeSurface(image.pic);

end;

procedure NewShowStatus(rnum: integer);
var
  i, max, x, y, addatk, adddef, addspeed: integer;
  p: array[0..10] of integer;
  strs: array[0..22] of WideString;
  color1, color2: uint32;
  Name: WideString;
  str: WideString;
begin
  max := length(menustring);
  strs[0] := UTF8Decode('  生命');
  strs[1] := UTF8Decode(' 內力');
  strs[2] := UTF8Decode(' 體力');
  strs[3] := UTF8Decode(' 等級');
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
  strs[20] := UTF8Decode(' 内傷');
  strs[21] := UTF8Decode(' 中毒');
  strs[22] := UTF8Decode(' 资质');
  x := 90;
  y := 0;
  display_imgFromSurface(STATE_PIC.pic, 0, 0);
  if isbattle = False then
  begin
    DrawRectangle(15, 15, 90, 10 + max * 22, $0, colcolor(0, 255), 30);
    //当前所在位置用白色, 其余用黄色
    for i := 0 to max - 1 do
      if teamlist[i] = rnum then
      begin
        DrawShadowText(@menustring[i][1], 0, 20 + 22 * i, colcolor(0, $64), colcolor(0, $66));
      end
      else
      begin
        DrawShadowText(@menustring[i][1], 0, 20 + 22 * i, colcolor(0, $5), colcolor(0, $7));
      end;
  end;
  DrawHeadPic(rrole[rnum].HeadNum, 137, 88);
  str := gbkToUnicode(@rrole[rnum].Name);
  DrawShadowText(@str[1], 115, 93, colcolor($64), colcolor($66));

  for i := 3 to 5 do
    drawshadowtext(@strs[i, 1], x + 25, y + 94 + 21 * (i - 2), colcolor(0, $21), colcolor(0, $23));
  for i := 6 to 16 do
    drawshadowtext(@strs[i, 1], x + 25, y + 115 + 21 * (i - 3), colcolor(0, $63), colcolor(0, $66));


  drawshadowtext(@strs[21, 1], x + 25 + 79, y + 115 - 21, colcolor(0, $30), colcolor(0, $32));
  str := IntToStr(rrole[rnum].Poision);
  drawshadowtext(@str[1], x + 25 + 150, y + 115 - 21, colcolor(0, $63), colcolor(0, $66));

  drawshadowtext(@strs[20, 1], x + 30 + 179, y + 115 - 21, colcolor(0, $13), colcolor(0, $16));
  str := IntToStr(rrole[rnum].Hurt);
  drawshadowtext(@str[1], x + 125 + 155, y + 115 - 21, colcolor(0, $63), colcolor(0, $66));

  addatk := 0;
  adddef := 0;
  addspeed := 0;

  for i := 0 to 4 do
  begin
    if rrole[rnum].Equip[i] >= 0 then
    begin
      Inc(addatk, ritem[rrole[rnum].Equip[i]].AddAttack);
      Inc(adddef, ritem[rrole[rnum].Equip[i]].AddDefence);
      Inc(addspeed, ritem[rrole[rnum].Equip[i]].AddSpeed);
    end;

  end;
  if CheckEquipSet(Rrole[rnum].Equip[0], Rrole[rnum].Equip[1], Rrole[rnum].Equip[2], Rrole[rnum].Equip[3]) = 5 then
  begin
    Inc(addatk, 50);
    Inc(addspeed, 30);
    Inc(adddef, -25);
  end;
  //攻击, 防御, 轻功
  //单独处理是因为显示顺序和存储顺序不同
  if (addatk > 0) then str := format('%4d', [GetRoleAttack(rnum, False)]) + '+' + IntToStr(addatk)
  else if (addatk < 0) then str := format('%4d', [GetRoleAttack(rnum, False)]) + '-' + IntToStr(0 - addatk)
  else str := format('%4d', [GetRoleAttack(rnum, False)]);
  drawengshadowtext(@str[1], x + 145, y + 115 + 21 * 3, colcolor($5), colcolor($7));
  if (adddef > 0) then str := format('%4d', [GetRoleDefence(rnum, False)]) + '+' + IntToStr(adddef)
  else if (adddef < 0) then str := format('%4d', [GetRoleDefence(rnum, False)]) + '-' + IntToStr(0 - adddef)
  else str := format('%4d', [GetRoleDefence(rnum, False)]);
  drawengshadowtext(@str[1], x + 145, y + 115 + 21 * 4, colcolor($5), colcolor($7));
  if (addspeed > 0) then str := format('%4d', [GetRoleSpeed(rnum, False)]) + '+' + IntToStr(addspeed)
  else if (addspeed < 0) then str := format('%4d', [GetRoleSpeed(rnum, False)]) + '-' + IntToStr(0 - addspeed)
  else str := format('%4d', [GetRoleSpeed(rnum, False)]);
  drawengshadowtext(@str[1], x + 145, y + 115 + 21 * 5, colcolor($5), colcolor($7));

  //其他属性
  str := format('%4d', [GetRoleMedcine(rnum, True)]);
  drawengshadowtext(@str[1], x + 145, y + 115 + 21 * 6, colcolor($5), colcolor($7));

  str := format('%4d', [GetRoleUsePoi(rnum, True)]);
  drawengshadowtext(@str[1], x + 145, y + 115 + 21 * 7, colcolor($5), colcolor($7));

  str := format('%4d', [GetRoleMedPoi(rnum, True)]);
  drawengshadowtext(@str[1], x + 145, y + 115 + 21 * 8, colcolor($5), colcolor($7));

  str := format('%4d', [GetRoleFist(rnum, True)]);
  drawengshadowtext(@str[1], x + 145, y + 115 + 21 * 9, colcolor($5), colcolor($7));

  str := format('%4d', [GetRoleSword(rnum, True)]);
  drawengshadowtext(@str[1], x + 145, y + 115 + 21 * 10, colcolor($5), colcolor($7));

  str := format('%4d', [GetRoleKnife(rnum, True)]);
  drawengshadowtext(@str[1], x + 145, y + 115 + 21 * 11, colcolor($5), colcolor($7));

  str := format('%4d', [GetRoleUnusual(rnum, True)]);
  drawengshadowtext(@str[1], x + 145, y + 115 + 21 * 12, colcolor($5), colcolor($7));

  str := format('%4d', [GetRoleHidWeapon(rnum, True)]);
  drawengshadowtext(@str[1], x + 145, y + 115 + 21 * 13, colcolor($5), colcolor($7));

  str := format('%4d', [Rrole[rnum].Level]);
  drawengshadowtext(@str[1], x + 145, y + 115, colcolor($5), colcolor($7));

  UpdateHpMp(rnum, x + 80 + 25, y - 85 + 94);

  //经验
  str := format('%5d', [uint16(Rrole[rnum].Exp)]);
  drawengshadowtext(@str[1], x + 135, y + 136, colcolor($5), colcolor($7));

  if Rrole[rnum].Level = Max_Level then
    str := UTF8Decode('    =')
  else
    str := format('%5d', [uint16(Leveluplist[Rrole[rnum].Level - 1])]);
  drawengshadowtext(@str[1], x + 135, y + 157, colcolor($5), colcolor($7));

  str := UTF8Decode(' 武器');
  drawshadowtext(@str[1], x + 200 - 10, y + 115 + 21 * 9, colcolor($5), colcolor($7));
  if (Rrole[rnum].Equip[0] <> -1) then
  begin
    str := gbkToUnicode(@Ritem[Rrole[rnum].Equip[0]].Name);
    DrawItemPic(Rrole[rnum].Equip[0], 411, 144);
  end
  else str := UTF8Decode(' 無');
  drawshadowtext(@str[1], x + 240, y + 115 + 21 * 9, colcolor($63), colcolor($66));

  str := UTF8Decode(' 身披');
  drawshadowtext(@str[1], x + 200 - 10, y + 115 + 21 * 10, colcolor($5), colcolor($7));
  if (Rrole[rnum].Equip[1] <> -1) then
  begin
    str := gbkToUnicode(@Ritem[Rrole[rnum].Equip[1]].Name);
    DrawItemPic(Rrole[rnum].Equip[1], 523, 144);
  end
  else str := UTF8Decode(' 無');
  drawshadowtext(@str[1], x + 240, y + 115 + 21 * 10, colcolor($63), colcolor($66));

  str := UTF8Decode(' 頭戴');
  drawshadowtext(@str[1], x + 200 - 10, y + 115 + 21 * 11, colcolor($5), colcolor($7));
  if (Rrole[rnum].Equip[2] <> -1) then
  begin
    str := gbkToUnicode(@Ritem[Rrole[rnum].Equip[2]].Name);
    DrawItemPic(Rrole[rnum].Equip[2], 466, 42);
  end
  else str := UTF8Decode(' 無');
  drawshadowtext(@str[1], x + 240, y + 115 + 21 * 11, colcolor($63), colcolor($66));

  str := UTF8Decode(' 腳踩');
  drawshadowtext(@str[1], x + 200 - 10, y + 115 + 21 * 12, colcolor($5), colcolor($7));
  if (Rrole[rnum].Equip[3] <> -1) then
  begin
    str := gbkToUnicode(@Ritem[Rrole[rnum].Equip[3]].Name);
    DrawItemPic(Rrole[rnum].Equip[3], 466, 318);
  end
  else str := UTF8Decode(' 無');
  drawshadowtext(@str[1], x + 240, y + 115 + 21 * 12, colcolor($63), colcolor($66));

 { str := Simplified2Traditional('配饰');
  drawshadowtext(@str[1], x + 200, y + 115 + 21 * 13, colcolor($5), colcolor($7));
  if (Rrole[rnum].Equip[4] <> -1) then
  begin
    str := gbkToUnicode(@Ritem[Rrole[rnum].Equip[4]].name);
    DrawItemPic(Rrole[rnum].Equip[4], 523, 143);
  end
  else str := Simplified2Traditional(' 无');
  drawshadowtext(@str[1], x + 240, y + 115 + 21 * 13, colcolor($63), colcolor($66));     }

  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  if isbattle then waitanykey;

end;

//新状态显示画面

procedure SelectShowStatus;
var
  i, menu, menup, max: integer;
  itempicpos: array[0..4] of tpoint;
begin
  SDL_EnableKeyRepeat(10, 100);
  max := 0;
  menu := 0;
  setlength(Menustring, 0);
  setlength(menustring, 7);
  for i := 0 to 5 do
  begin
    if Teamlist[i] >= 0 then
    begin
      menustring[i] := gbktoUnicode(@RRole[Teamlist[i]].Name);
      max := max + 1;
    end;
  end;

  itempicpos[0].X := 411;
  itempicpos[0].Y := 143;
  itempicpos[1].X := 523;
  itempicpos[1].Y := 143;
  itempicpos[2].X := 466;
  itempicpos[2].Y := 42;
  itempicpos[3].X := 466;
  itempicpos[3].Y := 318;
  itempicpos[4].X := 466;
  itempicpos[4].Y := 232;

  //setlength(Menustring, 0);
  setlength(menustring, max);
  NewShowStatus(Teamlist[menu]);
  while (SDL_WaitEvent(@event) >= 0) do
  begin

    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYDOWN:
      begin
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then menu := menu - 1;
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then menu := menu + 1;
        if (menu >= max) then menu := 0;
        if (menu < 0) then menu := max - 1;
        NewShowStatus(teamlist[menu]);
      end;
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = sdlk_escape) then break;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if event.button.button = sdl_button_right then
          break;
        if event.button.button = sdl_button_left then
        begin
          for i := 0 to 4 do
          begin
            if (round(event.button.x / (RealScreen.w / screen.w)) >= itempicpos[i].x) and
              (round(event.button.x / (RealScreen.w / screen.w)) <= itempicpos[i].x + 80) and
              (round(event.button.y / (RealScreen.h / screen.h)) >= itempicpos[i].y) and
              (round(event.button.y / (RealScreen.h / screen.h)) <= itempicpos[i].y + 80) then
            begin
              if Rrole[teamlist[menu]].Equip[i] >= 0 then
              begin
                if Ritem[Rrole[teamlist[menu]].Equip[i]].Magic > 0 then
                begin
                  Ritem[Rrole[teamlist[menu]].Equip[i]].ExpOfMagic :=
                    GetMagicLevel(teamlist[menu], Ritem[Rrole[teamlist[menu]].Equip[i]].Magic);
                  StudyMagic(teamlist[menu], Ritem[Rrole[teamlist[menu]].Equip[i]].Magic, 0, 0, 1);
                end;
                Dec(Rrole[teamlist[menu]].MaxHP, Ritem[Rrole[teamlist[menu]].Equip[i]].AddMaxHP);
                Dec(Rrole[teamlist[menu]].CurrentHP, Ritem[Rrole[teamlist[menu]].Equip[i]].AddMaxHP);
                Dec(Rrole[teamlist[menu]].MaxMP, Ritem[Rrole[teamlist[menu]].Equip[i]].AddMaxMP);
                Dec(Rrole[teamlist[menu]].CurrentMP, Ritem[Rrole[teamlist[menu]].Equip[i]].AddMaxMP);
                Rrole[teamlist[menu]].CurrentMP := Math.max(1, Rrole[teamlist[menu]].CurrentMP);
                Rrole[teamlist[menu]].CurrentHP := Math.max(1, Rrole[teamlist[menu]].CurrentHP);
                instruct_32(rrole[teamlist[menu]].Equip[i], 1);
                rrole[teamlist[menu]].Equip[i] := -1;
                NewShowStatus(teamlist[menu]);
                break;
              end;
            end;
          end;
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        menup := menu;
        if ((round(event.button.x / (RealScreen.w / screen.w)) > 15) and
          (round(event.button.y / (RealScreen.h / screen.h)) > 15) and
          (round(event.button.x / (RealScreen.w / screen.w)) < 105) and
          (round(event.button.y / (RealScreen.h / screen.h)) < 25 + max * 22)) then
        begin
          menu := (round(event.button.y / (RealScreen.h / screen.h)) - 25) div 22;
          if menup <> menu then
            NewShowStatus(teamlist[menu]);
        end;
      end;
    end;
  end;
  SDL_EnableKeyRepeat(30, (30 * GameSpeed) div 10);

end;

//武功画面

procedure NewShowMagic(rnum: integer);
var
  i, max, lv, x, y, Aptitude, addatk, adddef, addspeed: integer;
  p: array[0..10] of integer;
  strs: array[0..1] of WideString;
  color1, color2: uint32;
  Name: WideString;
  str1, str, str2, str3: WideString;
begin
  max := length(menustring);
  strs[0] := UTF8Decode(' 修煉物品');
  strs[1] := UTF8Decode(' 功體經驗');
  x := 90;
  y := 0;
  display_imgFromSurface(MAGIC_PIC.pic, 0, 0);
  if where <> 2 then
  begin
    DrawRectangle(15, 15, 90, 10 + max * 22, $0, colcolor(255), 30);
    //当前所在位置用白色, 其余用黄色
    for i := 0 to max - 1 do
      if teamlist[i] = rnum then
      begin
        DrawShadowText(@menustring[i][1], 0, 20 + 22 * i, colcolor($64), colcolor($66));
      end
      else
      begin
        DrawShadowText(@menustring[i][1], 0, 20 + 22 * i, colcolor($5), colcolor($7));
      end;
  end;
  DrawHeadPic(rrole[rnum].HeadNum, 137, 88);
  str2 := gbktoUnicode(@RRole[rnum].Name);
  DrawShadowText(@str2[1], 115, 93, colcolor($64), colcolor($66));


  if (RRole[rnum].PracticeBook <> -1) then
  begin
    str := gbkToUnicode(@RItem[RRole[rnum].PracticeBook].Name);

    if (RItem[RRole[rnum].PracticeBook].Magic = -1) then
    begin
      if CheckEquipSet(Rrole[rnum].equip[0], Rrole[rnum].equip[1], Rrole[rnum].equip[2], Rrole[rnum].equip[3]) = 2 then
        Aptitude := 100
      else Aptitude := Rrole[rnum].Aptitude;

      if RItem[RRole[rnum].PracticeBook].NeedExp > 0 then
        str1 := IntToStr(RRole[rnum].ExpForBook) + '/' + IntToStr(
          (RItem[RRole[rnum].PracticeBook].NeedExp * (8 - Aptitude div 15)) div 2)
      else
        str1 := IntToStr(RRole[rnum].ExpForBook) + '/' + IntToStr(
          (RItem[RRole[rnum].PracticeBook].NeedExp * (1 + Aptitude div 15)) div 2);

    end
    else
    begin
      lv := GetMagicLevel(rnum, RItem[RRole[rnum].PracticeBook].Magic);
      if (Rmagic[RItem[RRole[rnum].PracticeBook].Magic].MagicType = 5) and (lv >= 0) then
        str1 := IntToStr(RRole[rnum].ExpForBook) + '/='
      else if (lv < 900) then
      begin
        if CheckEquipSet(Rrole[rnum].equip[0], Rrole[rnum].equip[1], Rrole[rnum].equip[2],
          Rrole[rnum].equip[3]) = 2 then
          Aptitude := 100
        else Aptitude := Rrole[rnum].Aptitude;
        if RItem[RRole[rnum].PracticeBook].NeedExp > 0 then
          str1 := IntToStr(RRole[rnum].ExpForBook) + '/' + IntToStr(
            (RItem[RRole[rnum].PracticeBook].NeedExp * (1 + lv div 100) * (8 - Aptitude div 15)) div 2)
        else
        begin
          str1 := IntToStr(RRole[rnum].ExpForBook) + '/' + IntToStr(
            ((-RItem[RRole[rnum].PracticeBook].NeedExp) * (1 + lv div 100) * (1 + Aptitude div 15)) div 2);
        end;
      end
      else
        str1 := IntToStr(RRole[rnum].ExpForBook) + '/=';
    end;
    DrawEngShadowText(@str1[1], x + 137, y + 258, colcolor($64), colcolor($66));
    DrawItemPic(RRole[rnum].PracticeBook, 136, 208);
  end
  else str := UTF8Decode(' 無');
  str3 := IntToStr(RRole[rnum].GongtiExam);
  drawshadowtext(@strs[1, 1], x + 25, y + 184, colcolor($21), colcolor($23));
  drawshadowtext(@strs[0, 1], x + 110, y + 216, colcolor($21), colcolor($23));
  drawEngshadowtext(@str3[1], x + 137, y + 184, colcolor($64), colcolor($66));
  DrawShadowText(@str[1], x + 110, y + 237, colcolor($64), colcolor($66));

  UpdateHpMp(rnum, x + 25, y + 94);
  showmagic(rnum, -1, 0, 0, screen.w, screen.h, True);
end;

procedure UpdateHpMp(rnum, x, y: integer);
var
  strs: array[0..2] of WideString;
  i, color1, color2: integer;
  str: WideString;
begin
  strs[0] := UTF8Decode(' 生命');
  strs[1] := UTF8Decode(' 內力');
  strs[2] := UTF8Decode(' 體力');

  for i := 0 to 2 do
    drawshadowtext(@strs[i, 1], x, y + 21 * (i + 1), colcolor($21), colcolor($23));

  //生命值, 在受伤和中毒值不同时使用不同颜色
  case RRole[rnum].Hurt of
    34..66:
    begin
      color1 := colcolor($10);
      color2 := colcolor($E);
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
  str := format('%4d', [rrole[rnum].CurrentHP]);
  drawengshadowtext(@str[1], x + 125, y + 21, color1, color2);

  str := '/';
  drawengshadowtext(@str[1], x + 165, y + 21, colcolor($63), colcolor($66));

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
  str := format('%4d', [rrole[rnum].MaxHP]);
  drawengshadowtext(@str[1], x + 175, y + 21, color1, color2);
  DrawRectangleWithoutFrame(x + 65, y + 22 + 2, 52, 15, ColColor(0), 30);
  DrawRectangleWithoutFrame(x + 66, y + 22 + 3, (50 * rrole[rnum].CurrentHP) div rrole[rnum].MaxHP, 13, color2, 50);
  DrawRectangleWithoutFrame(x + 66, y + 22 + 11, 50, 5, ColColor(255), 5);
  DrawRectangleWithoutFrame(x + 66, y + 22 + 14, 50, 3, ColColor(255), 3);
  DrawRectangleWithoutFrame(x + 66, y + 22 + 16, 50, 1, ColColor(255), 1);
  //内力, 依据内力性质使用颜色
  if rrole[rnum].MPType = 1 then
  begin
    color1 := colcolor($4E);
    color2 := colcolor($50);
  end
  else
  if rrole[rnum].MPType = 0 then
  begin
    color1 := colcolor($5);
    color2 := colcolor($7);
  end
  else
  begin
    color1 := colcolor($63);
    color2 := colcolor($66);
  end;
  if rrole[rnum].MaxMP > 0 then
  begin
    str := format('%4d/%4d', [RRole[rnum].CurrentMP, rrole[rnum].MaxMP]);
    drawengshadowtext(@str[1], x + 125, y + 21 * 2, color1, color2);
    DrawRectangleWithoutFrame(x + 65, y + 3 + 21 * 2, 52, 15, ColColor(0), 30);
    DrawRectangleWithoutFrame(x + 66, y + 4 + 21 * 2, (50 * rrole[rnum].CurrentMP) div
      rrole[rnum].MaxMP, 13, color2, 50);
    DrawRectangleWithoutFrame(x + 66, y + 12 + 21 * 2, 50, 5, ColColor(255), 5);
    DrawRectangleWithoutFrame(x + 66, y + 15 + 21 * 2, 50, 3, ColColor(255), 3);
    DrawRectangleWithoutFrame(x + 66, y + 17 + 21 * 2, 50, 1, ColColor(255), 1);
  end;
  //体力
  str := format('%4d/%4d', [RRole[rnum].PhyPower, MAX_PHYSICAL_POWER]);
  drawengshadowtext(@str[1], x + 125, y + 21 * 3, colcolor($5), colcolor($7));
  DrawRectangleWithoutFrame(x + 65, y + 2 + 21 * 3, 52, 15, ColColor(0), 30);
  DrawRectangleWithoutFrame(x + 66, y + 3 + 21 * 3, (50 * rrole[rnum].PhyPower) div
    MAX_PHYSICAL_POWER, 13, ColColor($46), 50);
  DrawRectangleWithoutFrame(x + 66, y + 11 + 21 * 3, 50, 5, ColColor(255), 5);
  DrawRectangleWithoutFrame(x + 66, y + 14 + 21 * 3, 50, 3, ColColor(255), 3);
  DrawRectangleWithoutFrame(x + 66, y + 16 + 21 * 3, 50, 1, ColColor(255), 1);
end;

//新武功显示画面

procedure SelectShowMagic;
var
  i, menu, menup, max, num, nump: integer;
begin
  max := 0;
  menu := 0;

  SDL_EnableKeyRepeat(10, 100);
  setlength(Menustring, 0);
  setlength(menustring, 7);
  for i := 0 to 5 do
  begin
    if Teamlist[i] >= 0 then
    begin
      menustring[i] := gbktoUnicode(@RRole[Teamlist[i]].Name);
      max := max + 1;
    end;
  end;
  //setlength(Menustring, 0);
  setlength(menustring, max);
  NewShowMagic(teamlist[menu]);
  while (SDL_WaitEvent(@event) >= 0) do
  begin

    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYDOWN:
      begin
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then menu := menu - 1;
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then menu := menu + 1;
        if (menu >= max) then menu := 0;
        if (menu < 0) then menu := max - 1;
        NewShowMagic(teamlist[menu]);
      end;
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = sdlk_escape) then break;
        NewShowMagic(teamlist[menu]);
        if ((event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space)) then
          if InModeMagic(teamlist[menu]) then break;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if event.button.button = sdl_button_right then
        begin
          if (round(event.button.x / (RealScreen.w / screen.w)) >= 136) and
            (round(event.button.x / (RealScreen.w / screen.w)) <= 216) and
            (round(event.button.y / (RealScreen.h / screen.h)) >= 208) and
            (round(event.button.y / (RealScreen.h / screen.h)) <= 288) then
          begin
            if rrole[teamlist[menu]].PracticeBook >= 0 then
            begin
              instruct_32(rrole[teamlist[menu]].PracticeBook, 1);
              rrole[teamlist[menu]].PracticeBook := -1;
              rrole[teamlist[menu]].ExpForBook := 0;
              NewShowMagic(teamlist[menu]);
            end;
          end
          else
            break;
        end;
        if event.button.button = sdl_button_left then
        begin
          if ((round(event.button.x / (RealScreen.w / screen.w)) > 337) and
            (round(event.button.y / (RealScreen.h / screen.h)) > 57) and
            (round(event.button.x / (RealScreen.w / screen.w)) < (337 + 78)) and
            (round(event.button.y / (RealScreen.h / screen.h)) < 79)) then
          begin
            if (GetRoleMedcine(teamlist[menu], True) >= 20) then
            begin
              MenuMedcine(teamlist[menu]);
            end;
          end;
          if ((round(event.button.x / (RealScreen.w / screen.w)) > 437) and
            (round(event.button.y / (RealScreen.h / screen.h)) > 57) and
            (round(event.button.x / (RealScreen.w / screen.w)) < (437 + 78)) and
            (round(event.button.y / (RealScreen.h / screen.h)) < 79)) then
          begin
            if (GetRoleMedPoi(teamlist[menu], True) >= 20) then
            begin
              MenuMedPoision(teamlist[menu]);
            end;
          end;
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        menup := menu;
        if round(event.button.x / (RealScreen.w / screen.w)) >= 350 then
        begin
          if InModeMagic(teamlist[menu]) then break;
        end
        else if ((round(event.button.x / (RealScreen.w / screen.w)) > 15) and
          (round(event.button.y / (RealScreen.h / screen.h)) > 15) and
          (round(event.button.x / (RealScreen.w / screen.w)) < 105) and
          (round(event.button.y / (RealScreen.h / screen.h)) < 25 + max * 22)) then
        begin
          menu := (round(event.button.y / (RealScreen.h / screen.h)) - 25) div 22;
          if menu <> menup then
          begin
            NewShowMagic(teamlist[menu]);
          end;
        end;
      end;
    end;
  end;

  SDL_EnableKeyRepeat(30, (30 * GameSpeed) div 10);
end;

function InModeMagic(rnum: integer): boolean;
var
  max, i, l, num, nump: integer;
begin
  max := 0;
  i := 0;
  num := 0;
  ShowMagic(rnum, 0, 0, 0, screen.w, screen.h, True);
  for i := 0 to 9 do
  begin
    if (RRole[rnum].Magic[i] > 0) then max := max + 1;
  end;
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYDOWN:
      begin
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
          if ((num <= 5) and (num >= 0)) then
            num := num - 3
          else if (num >= 6) then
            num := num - 2;
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then
        begin
          if ((num <= 5) and (num >= 3)) then
            if (max = 0) then num := num - 3 else num := 6
          else if ((num <= 2) and (num >= 0)) then
            num := num + 3
          else if (num >= 6) then
            num := num + 2;
          if (num < 0) then
            if (max = 0) then num := num + 3 else num := (max div 2) * 2 + 5;
        end;
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_kp6) then
          num := num + 1;
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) then
          num := num - 1;
        if (num < 0) then
          if (max = 0) then num := num + 3 else num := max + 5;
        if (num > max + 5) then
          num := 0;
        ShowMagic(rnum, num, 0, 0, screen.w, screen.h, True);
      end;
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = sdlk_escape) then
        begin
          ShowMagic(rnum, -1, 0, 0, screen.w, screen.h, True);
          Result := False;
          break;
        end;
        if ((event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space)) then
        begin
          if not isbattle then
          begin
            if (num = 0) then
            begin
              if (GetRoleMedcine(rnum, True) >= 20) then
              begin
                MenuMedcine(rnum);
              end;
            end;
            if (num = 1) then
            begin
              if (GetRoleMedPoi(rnum, True) >= 20) then
              begin
                MenuMedPoision(rnum);
              end;
            end;
            if (num > 5) and (RRole[rnum].Magic[num - 6] >= 0) then
            begin
              if (Rmagic[RRole[rnum].Magic[num - 6]].MagicType = 5) then
              begin
                SetGongti(rnum, RRole[rnum].Magic[num - 6]);
                NewShowMagic(rnum);
              end;
            end;
          end;
        end;
      end;

      SDL_MOUSEBUTTONUP:
      begin
        if event.button.button = sdl_button_right then
        begin
          ShowMagic(rnum, -1, 0, 0, screen.w, screen.h, True);
          Result := True;
          break;
        end;
        if event.button.button = sdl_button_left then
        begin
          if not isbattle then
          begin
            if (round(event.button.x / (RealScreen.w / screen.w)) >= 136) and
              (round(event.button.x / (RealScreen.w / screen.w)) <= 136 + 80) and
              (round(event.button.y / (RealScreen.h / screen.h)) >= 208) and
              (round(event.button.y / (RealScreen.h / screen.h)) <= 288) then
            begin
              if Rrole[rnum].PracticeBook > 0 then
              begin
                instruct_32(Rrole[rnum].PracticeBook, 1);
                Rrole[rnum].PracticeBook := -1;
                Rrole[rnum].ExpForBook := 0;
                NewShowMagic(rnum);
                continue;
              end;
            end;
            if num = 0 then
            begin
              if (GetRoleMedcine(rnum, True) >= 20) then
              begin
                MenuMedcine(rnum);
              end;
            end;
            if num = 1 then
            begin
              if (GetRoleMedPoi(rnum, True) >= 20) then
              begin
                MenuMedPoision(rnum);
              end;
            end;
            if (num > 5) and (RRole[rnum].Magic[num - 6] >= 0) then
            begin
              if (Rmagic[RRole[rnum].Magic[num - 6]].MagicType = 5) then
              begin
                SetGongti(rnum, RRole[rnum].Magic[num - 6]);
                NewShowMagic(rnum);
              end;
            end;
          end;
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        if round(event.button.x / (RealScreen.w / screen.w)) <= 116 then
        begin
          Result := False;
          break;
        end;

        nump := num;
        if ((round(event.button.x / (RealScreen.w / screen.w)) > 337) and
          (round(event.button.y / (RealScreen.h / screen.h)) > 57) and
          (round(event.button.x / (RealScreen.w / screen.w)) < (337 + 236)) and
          (round(event.button.y / (RealScreen.h / screen.h)) < 101)) then
        begin
          num := ((round(event.button.y / (RealScreen.h / screen.h)) - 57) div 22) * 3 +
            (round(event.button.x / (RealScreen.w / screen.w)) - 337) div 78;
        end
        else if ((round(event.button.x / (RealScreen.w / screen.w)) > 337) and
          (round(event.button.y / (RealScreen.h / screen.h)) > 124) and
          (round(event.button.x / (RealScreen.w / screen.w)) < (337 + 236)) and
          (round(event.button.y / (RealScreen.h / screen.h)) < 234)) then
        begin
          num := ((round(event.button.y / (RealScreen.h / screen.h)) - 124) div 22) * 2 +
            (round(event.button.x / (RealScreen.w / screen.w)) - 337) div 118 + 6;
        end;
        if nump <> num then
          ShowMagic(rnum, num, 0, 0, screen.w, screen.h, True);
      end;
    end;
  end;

end;

procedure ShowMagic(rnum, num, x1, y1, w, h: integer; showit: boolean);
var
  x, y, i, l, i1, i2: integer;
  skillstr: array[0..5] of WideString;
  magicstr: array[0..9] of WideString;
  lv: array[0..15] of integer;
  lvstr, str, knowmagic, skill: WideString;
  gongti: array of array[0..1] of WideString;
  magstr: array[0..71] of char;
  needmp, needprogress: WideString;
begin
  x := 90;
  y := 0;
  display_imgFromSurface(MAGIC_PIC.pic, x + 247, y + 32, x + 247, y + 32, 276, 408 - y);
  display_imgFromSurface(MAGIC_PIC.pic, x + 30, y + 300, x + 30, y + 300, 300, 140);
  skillstr[0] := UTF8Decode(' 醫療');
  skillstr[1] := UTF8Decode(' 解毒');
  skillstr[2] := UTF8Decode(' 用毒');
  skillstr[3] := UTF8Decode(' 抗毒');
  skillstr[4] := UTF8Decode(' 毒攻');
  skillstr[5] := UTF8Decode(' ');
  setlength(gongti, 16);
  knowmagic := UTF8Decode(' ————所會武功————');
  skill := UTF8Decode(' ————特殊技能————');
  drawshadowtext(@skill[1], x + 247, y + 36, colcolor(0, $21), colcolor(0, $23));

  drawshadowtext(@knowmagic[1], x + 247, y + 102, colcolor(0, $21), colcolor(0, $23));

  if (num < 0) then
  begin
    str := UTF8Decode(' ');
  end
  else if (num = 0) then
  begin
    str := UTF8Decode(' 給本方隊友治療，增*加其生命值，并減少*其受傷值。*耗費體力3');
  end
  else if (num = 1) then
  begin
    str := UTF8Decode(' 給本方隊友解毒，減*中毒值，但對中毒太*深者無法解毒。*耗費體力3');
  end
  else if (num = 2) then
  begin
    str := UTF8Decode(' 用毒使對方中毒，每*回合生命減少，並且*降低對方醫療效果。*耗費體力3');
  end
  else if (num = 3) then
  begin
    str := UTF8Decode(' 抗擊用毒的能力。');
  end
  else if (num = 4) then
  begin
    str := UTF8Decode(' 武學攻擊中帶有的毒*素傷害。');
  end
  else if (num = 5) then
  begin
    str := UTF8Decode(' ');
  end
  else if (num > 5) then
  begin
    if RRole[rnum].Magic[num - 6] > 0 then
    begin
      i1 := 0;
      i2 := 0;
      while Rmagic[RRole[rnum].Magic[num - 6]].Introduction[i1] > char(0) do
      begin
        magstr[i2] := Rmagic[RRole[rnum].Magic[num - 6]].Introduction[i1];
        if (i1 mod 18 = 17) then
        begin
          Inc(i2);
          magstr[i2] := '*';
        end;
        Inc(i1);
        Inc(i2);
      end;
      magstr[i2] := char(0);
      str := gbktoUnicode(@magstr);
    end
    else str := UTF8Decode(' ');
  end;

  if (GetRoleMedcine(rnum, True) >= 20) then
    drawshadowtext(@skillstr[0][1], x + 248 + 78 * (0 mod 3), y + (0 div 3) * 22 + 58,
      colcolor(0, $5), colcolor(0, $7))
  else
    drawshadowtext(@skillstr[0][1], x + 248 + 78 * (0 mod 3), y + (0 div 3) * 22 + 58,
      colcolor(0, $66), colcolor(0, $68));
  lv[0] := (GetRoleMedcine(rnum, True));

  if (GetRoleUsePoi(rnum, True) >= 20) then
    drawshadowtext(@skillstr[2][1], x + 248 + 78 * (2 mod 3), y + (2 div 3) * 22 + 58,
      colcolor(0, $5), colcolor(0, $7))
  else
    drawshadowtext(@skillstr[2][1], x + 248 + 78 * (2 mod 3), y + (2 div 3) * 22 + 58,
      colcolor(0, $66), colcolor(0, $68));
  lv[2] := (GetRoleUsePoi(rnum, True));

  if (GetRoleMedPoi(rnum, True) >= 20) then
    drawshadowtext(@skillstr[1][1], x + 248 + 78 * (1 mod 3), y + (1 div 3) * 22 + 58,
      colcolor(0, $5), colcolor(0, $7))
  else
    drawshadowtext(@skillstr[1][1], x + 248 + 78 * (1 mod 3), y + (1 div 3) * 22 + 58,
      colcolor(0, $66), colcolor(0, $68));
  lv[1] := (GetRoleMedPoi(rnum, True));

  if (GetRoleDefPoi(rnum, True) > 0) then
    drawshadowtext(@skillstr[3][1], x + 248 + 78 * (3 mod 3), y + (3 div 3) * 22 + 58,
      colcolor(0, $5), colcolor(0, $7))
  else
    drawshadowtext(@skillstr[3][1], x + 248 + 78 * (3 mod 3), y + (3 div 3) * 22 + 58,
      colcolor(0, $66), colcolor(0, $68));
  lv[3] := (GetRoleDefPoi(rnum, True));

  if (GetRoleAttPoi(rnum, True) > 0) then
    drawshadowtext(@skillstr[4][1], x + 248 + 78 * (4 mod 3), y + (4 div 3) * 22 + 58,
      colcolor(0, $5), colcolor(0, $7))
  else
    drawshadowtext(@skillstr[4][1], x + 248 + 78 * (4 mod 3), y + (4 div 3) * 22 + 58,
      colcolor(0, $66), colcolor(0, $68));
  lv[4] := GetRoleAttPoi(rnum, True);

  if (RRole[rnum].AttTwice > 0) then
    drawshadowtext(@skillstr[5][1], x + 248 + 78 * (5 mod 3), y + (5 div 3) * 22 + 58,
      colcolor(0, $5), colcolor(0, $7))
  else
    drawshadowtext(@skillstr[5][1], x + 248 + 78 * (5 mod 3), y + (5 div 3) * 22 + 58,
      colcolor(0, $66), colcolor(0, $68));
  lv[5] := 0;
  for i := 0 to 15 do
  begin
    gongti[i][0] := UTF8Decode(' ');
    gongti[i][1] := UTF8Decode(' ');
  end;
  for i := 0 to 9 do
  begin
    if (RRole[rnum].Magic[i] > 0) then
    begin
      magicstr[i] := gbkToUnicode(@RMagic[RRole[rnum].Magic[i]].Name);
    end
    else magicstr[i] := UTF8Decode(' ');
    if (RRole[rnum].Magic[i] = RRole[rnum].Gongti) then
    begin
      drawshadowtext(@magicstr[i][1], x + 248 + 118 * (i mod 2), y + (i div 2) * 22 + 124,
        colcolor(0, 21), colcolor(0, 24));
    end
    else
      drawshadowtext(@magicstr[i][1], x + 248 + 118 * (i mod 2), y + (i div 2) * 22 + 124,
        colcolor(0, $5), colcolor(0, $7));
  end;
  if (num >= 6) then
  begin
    drawshadowtext(@magicstr[num - 6][1], x + 248 + 118 * ((num - 6) mod 2), y + ((num - 6) div 2) *
      22 + 124, colcolor(0, $63), colcolor(0, $66));
    drawshadowtext(@magicstr[num - 6][1], x + 35, y + 260 + 40, colcolor(0, $5), colcolor(0, $7));
    if (magicstr[num - 6] <> ' ') then
    begin
      if rmagic[RRole[rnum].Magic[num - 6]].MagicType = 5 then
      begin
        case getGongtiLevel(rnum, RRole[rnum].Magic[num - 6]) of
          0: lvstr := UTF8Decode(' 熟練');
          1: lvstr := UTF8Decode(' 精純');
          2: lvstr := UTF8Decode(' 化境');
        end;
      end
      else lvstr := format('%3d', [RRole[rnum].Maglevel[num - 6] div 100 + 1]);
      drawshadowtext(@lvstr[1], x + 173, y + 260 + 40, colcolor(0, $5), colcolor(0, $7));
      drawshadowtext(@str[1], x + 35, y + 285 + 40, colcolor(0, $63), colcolor(0, $66));
      if Rmagic[RRole[rnum].Magic[num - 6]].MagicType <> 5 then
      begin
        i1 := RRole[rnum].Maglevel[num - 6] div 100 + 1;
        str := UTF8Decode('***內力');
        drawshadowtext(@str[1], x + 35, y + 285 + 40, colcolor(0, $63), colcolor(0, $66));
        str := '***' + IntToStr((Rmagic[RRole[rnum].Magic[num - 6]].NeedMp) * i1);
        drawshadowtext(@str[1], x + 50 + 35, y + 285 + 40, colcolor(0, $63), colcolor(0, $66));
        if battlemode > 0 then
        begin
          str := UTF8Decode('***行動力');
          drawshadowtext(@str[1], x + 35 + 90, y + 285 + 40, colcolor(0, $63), colcolor(0, $66));
          str := '***' + IntToStr(((Rmagic[RRole[rnum].Magic[num - 6]].NeedProgress * i1) * 10 + 99) div 100 + 1);
          drawshadowtext(@str[1], x + 35 + 90 + 70, y + 285 + 40, colcolor(0, $63), colcolor(0, $66));
        end;
      end;
    end;

    if rmagic[RRole[rnum].Magic[num - 6]].MagicType = 5 then
    begin
      l := getGongtiLevel(rnum, RRole[rnum].Magic[num - 6]);
      i1 := 0;
      if rmagic[RRole[rnum].Magic[num - 6]].AddHp[l] <> 0 then
      begin
        gongti[i1][0] := UTF8Decode(' 生命 ');
        gongti[i1][1] := IntToStr(rmagic[RRole[rnum].Magic[num - 6]].AddHp[l]);
        Inc(i1);
      end;
      if rmagic[RRole[rnum].Magic[num - 6]].AddMp[l] <> 0 then
      begin
        gongti[i1][0] := UTF8Decode(' 內力 ');
        gongti[i1][1] := IntToStr(rmagic[RRole[rnum].Magic[num - 6]].AddMp[l]);
        Inc(i1);
      end;
      if rmagic[RRole[rnum].Magic[num - 6]].AddAtt[l] <> 0 then
      begin
        gongti[i1][0] := UTF8Decode(' 攻擊 ');
        gongti[i1][1] := IntToStr(rmagic[RRole[rnum].Magic[num - 6]].AddAtt[l]);
        Inc(i1);
      end;
      if rmagic[RRole[rnum].Magic[num - 6]].AddDef[l] <> 0 then
      begin
        gongti[i1][0] := UTF8Decode(' 防禦 ');
        gongti[i1][1] := IntToStr(rmagic[RRole[rnum].Magic[num - 6]].AddDef[l]);
        Inc(i1);
      end;
      if rmagic[RRole[rnum].Magic[num - 6]].AddSpd[l] <> 0 then
      begin
        gongti[i1][0] := UTF8Decode(' 輕功 ');
        gongti[i1][1] := IntToStr(rmagic[RRole[rnum].Magic[num - 6]].AddSpd[l]);
        Inc(i1);
      end;
      if l = rmagic[RRole[rnum].Magic[num - 6]].MaxLevel then
      begin
        if rmagic[RRole[rnum].Magic[num - 6]].AddMedcine <> 0 then
        begin
          gongti[i1][0] := UTF8Decode(' 醫療 ');
          gongti[i1][1] := IntToStr(rmagic[RRole[rnum].Magic[num - 6]].AddMedcine);
          Inc(i1);
        end;
        if rmagic[RRole[rnum].Magic[num - 6]].AddUsePoi <> 0 then
        begin
          gongti[i1][0] := UTF8Decode(' 用毒 ');
          gongti[i1][1] := IntToStr(rmagic[RRole[rnum].Magic[num - 6]].AddUsePoi);
          Inc(i1);
        end;
        if rmagic[RRole[rnum].Magic[num - 6]].AddMedPoi <> 0 then
        begin
          gongti[i1][0] := UTF8Decode(' 解毒 ');
          gongti[i1][1] := IntToStr(rmagic[RRole[rnum].Magic[num - 6]].AddMedPoi);
          Inc(i1);
        end;
        if rmagic[RRole[rnum].Magic[num - 6]].AddDefPoi <> 0 then
        begin
          gongti[i1][0] := UTF8Decode(' 抗毒 ');
          gongti[i1][1] := IntToStr(rmagic[RRole[rnum].Magic[num - 6]].AddDefPoi);
          Inc(i1);
        end;
        if rmagic[RRole[rnum].Magic[num - 6]].AddFist <> 0 then
        begin
          gongti[i1][0] := UTF8Decode(' 拳掌 ');
          gongti[i1][1] := IntToStr(rmagic[RRole[rnum].Magic[num - 6]].AddFist);
          Inc(i1);
        end;
        if rmagic[RRole[rnum].Magic[num - 6]].AddSword <> 0 then
        begin
          gongti[i1][0] := UTF8Decode(' 禦劍 ');
          gongti[i1][1] := IntToStr(rmagic[RRole[rnum].Magic[num - 6]].AddSword);
          Inc(i1);
        end;
        if rmagic[RRole[rnum].Magic[num - 6]].AddKnife <> 0 then
        begin
          gongti[i1][0] := UTF8Decode(' 耍刀 ');
          gongti[i1][1] := IntToStr(rmagic[RRole[rnum].Magic[num - 6]].AddKnife);
          Inc(i1);
        end;
        if rmagic[RRole[rnum].Magic[num - 6]].AddUnusual <> 0 then
        begin
          gongti[i1][0] := UTF8Decode(' 奇門 ');
          gongti[i1][1] := IntToStr(rmagic[RRole[rnum].Magic[num - 6]].AddUnusual);
          Inc(i1);
        end;
        if rmagic[RRole[rnum].Magic[num - 6]].AddHidWeapon <> 0 then
        begin
          gongti[i1][0] := UTF8Decode(' 暗器 ');
          gongti[i1][1] := IntToStr(rmagic[RRole[rnum].Magic[num - 6]].AddHidWeapon);
          Inc(i1);
        end;
      end;
      for i2 := 0 to i1 - 1 do
      begin
        drawshadowtext(@gongti[i2][0][1], x + 248 + 118 * (i2 mod 2), y + (i2 div 2) * 22 +
          260, colcolor(0, $5), colcolor(0, $7));
        drawshadowtext(@gongti[i2][1][1], x + 298 + 118 * (i2 mod 2), y + (i2 div 2) * 22 +
          260, colcolor(0, $5), colcolor(0, $7));
      end;

      if (rmagic[RRole[rnum].Magic[num - 6]].BattleState > 0) and
        (l = rmagic[RRole[rnum].Magic[num - 6]].MaxLevel) then
      begin
        case rmagic[RRole[rnum].Magic[num - 6]].BattleState of
          1: str := UTF8Decode(' 體力不減');
          2: str := UTF8Decode(' 女性武功威力加成');
          3: str := UTF8Decode(' 飲酒功效加倍');
          4: str := UTF8Decode(' 隨機傷害轉移');
          5: str := UTF8Decode(' 隨機傷害反噬');
          6: str := UTF8Decode(' 內傷免疫');
          7: str := UTF8Decode(' 殺傷體力');
          8: str := UTF8Decode(' 增加閃躲幾率');
          9: str := UTF8Decode(' 攻擊力隨等级循环增减');
          10: str := UTF8Decode(' 內力消耗減少');
          11: str := UTF8Decode(' 每回合恢復生命');
          12: str := UTF8Decode(' 負面狀態免疫');
          13: str := UTF8Decode(' 全部武功威力加成');
          14: str := UTF8Decode(' 隨機二次攻擊');
          15: str := UTF8Decode(' 拳掌武功威力加成');
          16: str := UTF8Decode(' 劍術武功威力加成');
          17: str := UTF8Decode(' 刀法武功威力加成');
          18: str := UTF8Decode(' 奇門武功威力加成');
          19: str := UTF8Decode(' 增加內傷幾率');
          20: str := UTF8Decode(' 增加封穴幾率');
          21: str := UTF8Decode(' 攻擊微量吸血');
          22: str := UTF8Decode(' 攻擊距離增加');
          23: str := UTF8Decode(' 每回合恢復內力');
          24: str := UTF8Decode(' 使用暗器距離增加');
          25: str := UTF8Decode(' 附加殺傷吸收內力');
        end;

        drawshadowtext(@str[1], x + 248, y + ((i1 + 1) div 2) * 22 + 260, colcolor(0, $64), colcolor(0, $66));
      end;
    end
    else
    begin
      i1 := 0;
      if rmagic[RRole[rnum].Magic[num - 6]].AddHpScale <> 0 then
      begin
        gongti[i1][0] := UTF8Decode(' 嗜血 ');
        gongti[i1][1] := IntToStr(rmagic[RRole[rnum].Magic[num - 6]].AddHpScale) + #$25;
        //   gongti[i1][1] := GBKtoUnicode(@gongti[i1][1][1]);
        Inc(i1);
      end;
      if rmagic[RRole[rnum].Magic[num - 6]].AddMpScale <> 0 then
      begin
        gongti[i1][0] := UTF8Decode(' 吸星 ');
        gongti[i1][1] := IntToStr(rmagic[RRole[rnum].Magic[num - 6]].AddMpScale) + #$25;
        //   gongti[i1][1] := GBKtoUnicode(@gongti[i1][1][1]);
        Inc(i1);
      end;

      i := rmagic[RRole[rnum].Magic[num - 6]].MinPeg + ((RRole[rnum].Maglevel[num - 6] div 100) *
        (rmagic[RRole[rnum].Magic[num - 6]].MaxPeg - rmagic[RRole[rnum].Magic[num - 6]].MinPeg)) div 9;
      if i <> 0 then
      begin
        gongti[i1][0] := UTF8Decode(' 封穴 ');
        gongti[i1][1] := IntToStr(i) + #$25;
        //  gongti[i1][1] := GBKtoUnicode(@gongti[i1][1][1]);
        Inc(i1);
      end;
      i := rmagic[RRole[rnum].Magic[num - 6]].MinInjury + ((RRole[rnum].Maglevel[num - 6] div 100) *
        (rmagic[RRole[rnum].Magic[num - 6]].MaxInjury - rmagic[RRole[rnum].Magic[num - 6]].MinInjury)) div 9;
      if i <> 0 then
      begin
        gongti[i1][0] := UTF8Decode(' 內傷 ');
        gongti[i1][1] := IntToStr(i) + #$25;
        //     gongti[i1][1] := GBKtoUnicode(@gongti[i1][1][1]);
        Inc(i1);
      end;
      i := rmagic[RRole[rnum].Magic[num - 6]].Poision * (1 + RRole[rnum].Maglevel[num - 6] div 100);
      if i <> 0 then
      begin
        gongti[i1][0] := UTF8Decode(' 帶毒 ');
        gongti[i1][1] := IntToStr(i);
        //     gongti[i1][1] := GBKtoUnicode(@gongti[i1][1][1]);
        Inc(i1);
      end;
      for i2 := 0 to i1 - 1 do
      begin
        drawshadowtext(@gongti[i2][0][1], x + 248 + 118 * (i2 mod 2), y + (i2 div 2) * 22 +
          260, colcolor(0, $5), colcolor(0, $7));
        drawengshadowtext(@gongti[i2][1][1], x + 320 + 118 * (i2 mod 2), y + (i2 div 2) *
          22 + 260, colcolor(0, $5), colcolor(0, $7));
      end;

    end;

  end
  else if (num >= 0) then //显示特殊技能的说明文字
  begin
    if ((num < 5)) then //显示医毒解的说明文字
    begin
      drawshadowtext(@skillstr[num][1], x + 248 + 78 * (num mod 3), y + (num div 3) * 22 +
        58, colcolor(0, $63), colcolor(0, $66));
      drawshadowtext(@skillstr[num][1], x + 35, y + 260 + 40, colcolor(0, $5), colcolor(0, $7));
      if (((lv[num] >= 20) and (num < 3)) or ((lv[num] > 0) and (num >= 3))) then
      begin
        lvstr := format('%3d', [lv[num]]);
        drawshadowtext(@lvstr[1], x + 193, y + 260 + 40, colcolor(0, $5), colcolor(0, $7));
      end;
      drawshadowtext(@str[1], x + 35, y + 285 + 40, colcolor(0, $63), colcolor(0, $66));
    end;


    {
    if ((num = 5)) then //显示左右互搏的说明文字
    begin
      drawshadowtext(@skillstr[num][1], x + 248 + 78 * (num mod 3), y + (num div 3) * 22 + 58, colcolor(0,$63), colcolor(0,$66));
      drawshadowtext(@skillstr[num][1], x + 35, y + 260 + 40, colcolor(0,$5), colcolor(0,$7));
      drawshadowtext(@str[1], x + 35, y + 285 + 40, colcolor(0,$63), colcolor(0,$66));
    end; }
  end;
  if (showit = True) then
    SDL_UpdateRect2(screen, x1, y1, w, h);
end;

procedure ShowMedcine(rnum, menu: integer);
var
  i, max, len, x, y: integer;
  Name, hp: array[0..10] of WideString;
  str: WideString;
begin
  x := 338;
  y := 58;
  max := 0;
  len := 9;
  for i := 0 to 5 do
  begin
    if (TeamList[i] <> -1) then
    begin
      Name[i] := gbkToUnicode(@RRole[TeamList[i]].Name);
      hp[i] := format('%4d/%4d', [RRole[TeamList[i]].CurrentHP, RRole[TeamList[i]].MaxHP]);
      max := max + 1;
    end
    else break;
  end;
  display_imgFromSurface(MAGIC_PIC.pic, 334, 32, 334, 32, 476 + len * 11, 408);
  str := UTF8Decode(' ————選擇隊友————');
  drawshadowtext(@str[1], 337, 36, colcolor($21), colcolor($23));
  ;
  //drawtextwithrect(@str[1], 80, 30, 132, colcolor($23), colcolor($21));
  for i := 0 to max - 1 do
  begin

    if (i <> menu) then
    begin
      DrawShadowText(@Name[i][1], x, y + 22 * i, ColColor($5), ColColor($7));
      DrawShadowText(@hp[i][1], x + 90, y + 22 * i, ColColor($5), ColColor($7));
    end
    else
    begin
      DrawShadowText(@Name[i][1], x, y + 22 * i, ColColor($63), ColColor($66));
      DrawShadowText(@hp[i][1], x + 90, y + 22 * i, ColColor($63), ColColor($66));
    end;
  end;
  //SDL_UpdateRect2(screen,334,32,476+len*11 ,408 );
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

end;

procedure MenuMedcine(rnum: integer); overload;
var
  role1, role2, menu, i, menup, x, y, max: integer;
  str: WideString;
begin
  x := 115;
  y := 94;
  ShowMedcine(rnum, 0);
  menu := 0;
  max := 0;
  for i := 0 to 5 do
  begin
    if (TeamList[i] <> -1) then
      max := max + 1
    else break;
  end;
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYDOWN:
      begin
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
          menu := menu - 1;
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then
          menu := menu + 1;
        if (menu < 0) then menu := max - 1;
        if (menu >= max) then menu := 0;
        ShowMedcine(rnum, menu);
      end;
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = sdlk_escape) then
        begin
          ShowMagic(rnum, -1, 0, 0, screen.w, screen.h, True);
          break;
        end;
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          if (menu <> -1) then
          begin
            role2 := TeamList[menu];
            if menu >= 0 then
            begin
              EffectMedcine(rnum, role2);
              display_imgFromSurface(MAGIC_PIC.pic, x + 18, y + 20, x + 18, y + 20, 305, 68);
              UpdateHpMp(rnum, x, y);
              ShowMedcine(rnum, menu);
              SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
          end;
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if event.button.button = sdl_button_right then
        begin
          ShowMagic(rnum, -1, 0, 0, screen.w, screen.h, True);
          break;
        end;
        if event.button.button = sdl_button_left then
        begin
          if (menu <> -1) then
          begin
            role2 := TeamList[menu];
            if menu >= 0 then
            begin
              EffectMedcine(rnum, role2);
              display_imgFromSurface(MAGIC_PIC, x + 18, y + 20, x + 18, y + 20, 305, 68);
              UpdateHpMp(rnum, x, y);
              ShowMedcine(rnum, menu);
              SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
          end
          else
          begin
            ShowMagic(rnum, -1, 0, 0, screen.w, screen.h, True);
            break;
          end;
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        menup := menu;
        if ((round(event.button.x / (RealScreen.w / screen.w)) > 337 + 24) and
          (round(event.button.y / (RealScreen.h / screen.h)) > 57 + 4) and
          (round(event.button.x / (RealScreen.w / screen.w)) < 9 * 11 + 337 + 44) and
          (round(event.button.y / (RealScreen.h / screen.h)) < 57 + 34 + 22 * max)) then
        begin
          menu := (round(event.button.y / (RealScreen.h / screen.h)) - (57 + 4)) div 22;
        end
        else menu := -1;
        if menu <> menup then
          ShowMedcine(rnum, menu);
      end;
    end;
  end;
end;

//解毒选单

procedure ShowMedPoision(rnum, menu: integer);
var
  i, max, len, x, y: integer;
  Name, hp: array[0..10] of WideString;
  str: WideString;
begin
  x := 338;
  y := 58;
  max := 0;
  len := 9;
  for i := 0 to 5 do
  begin
    if (TeamList[i] <> -1) then
    begin
      Name[i] := gbkToUnicode(@RRole[TeamList[i]].Name);
      hp[i] := format('     %4d', [RRole[TeamList[i]].Poision]);
      max := max + 1;
    end
    else break;
  end;
  display_imgFromSurface(MAGIC_PIC, 334, 32, 334, 32, 476 + len * 11, 408);
  str := UTF8Decode(' ————選擇隊友————');
  drawshadowtext(@str[1], 337, 36, colcolor($21), colcolor($23));
  ;
  //drawtextwithrect(@str[1], 80, 30, 132, colcolor($23), colcolor($21));
  for i := 0 to max - 1 do
  begin

    if (i <> menu) then
    begin
      DrawShadowText(@Name[i][1], x, y + 22 * i, ColColor($5), ColColor($7));
      DrawShadowText(@hp[i][1], x + 90, y + 22 * i, ColColor($5), ColColor($7));
    end
    else
    begin
      DrawShadowText(@Name[i][1], x, y + 22 * i, ColColor($63), ColColor($66));
      DrawShadowText(@hp[i][1], x + 90, y + 22 * i, ColColor($63), ColColor($66));
    end;
  end;
  //SDL_UpdateRect2(screen,334,32,476+len*11 ,408 );
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

end;

procedure MenuMedPoision(rnum: integer); overload;
var
  role1, role2, menu, x, y, i, max, menup: integer;
  str: WideString;
begin
  x := 115;
  y := 94;
  ShowMedPoision(rnum, 0);
  menu := 0;
  max := 0;
  for i := 0 to 5 do
  begin
    if (TeamList[i] <> -1) then
      max := max + 1
    else break;
  end;
  while (SDL_WaitEvent(@event) >= 0) do
  begin
    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then Quit;
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYDown:
      begin
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
          menu := menu - 1;
        if (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then
          menu := menu + 1;
        if (menu < 0) then menu := max - 1;
        if (menu >= max) then menu := 0;
        ShowMedPoision(rnum, menu);
      end;
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = sdlk_escape) then
        begin
          ShowMagic(rnum, -1, 0, 0, screen.w, screen.h, True);
          break;
        end;
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          if menu >= 0 then
          begin
            role2 := TeamList[menu];
            EffectMedPoision(rnum, role2);
            display_imgFromSurface(MAGIC_PIC, x + 18, y + 20, x + 18, y + 20, 305, 68);
            UpdateHpMp(rnum, x, y);
            ShowMedPoision(rnum, menu);
            SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          end;
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if event.button.button = sdl_button_right then
        begin
          ShowMagic(rnum, -1, 0, 0, screen.w, screen.h, True);
          break;
        end;
        if event.button.button = sdl_button_left then
        begin
          if (menu <> -1) then
          begin
            role2 := TeamList[menu];
            if menu >= 0 then
            begin
              EffectMedPoision(rnum, role2);
              display_imgFromSurface(MAGIC_PIC, x + 18, y + 20, x + 18, y + 20, 305, 68);
              UpdateHpMp(rnum, x, y);
              ShowMedPoision(rnum, menu);
              SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
            end;
          end
          else
          begin
            ShowMagic(rnum, -1, 0, 0, screen.w, screen.h, True);
            break;
          end;
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        menup := menu;
        if ((round(event.button.x / (RealScreen.w / screen.w)) > 337 + 24) and
          (round(event.button.y / (RealScreen.h / screen.h)) > 57 + 4) and
          (round(event.button.x / (RealScreen.w / screen.w)) < 9 * 11 + 337 + 44) and
          (round(event.button.y / (RealScreen.h / screen.h)) < 57 + 34 + 22 * max)) then
        begin
          menu := (round(event.button.y / (RealScreen.h / screen.h)) - (57 + 4)) div 22;
        end
        else menu := -1;
        if menu <> menup then
          ShowMedPoision(rnum, menu);
      end;
    end;
  end;
end;

//画Png图

function GetPngPic(f: integer; num: integer): Tpic; overload;
var
  address, len: integer;
  picdata: array of byte;
  Count: integer;
begin

  fileseek(f, 0, 0);
  fileread(f, Count, 4);
  fileseek(f, (num + 1) * 4, 0);
  fileread(f, len, 4);
  if num = 0 then
    address := (Count + 1) * 4
  else
  begin
    fileseek(f, num * 4, 0);
    fileread(f, address, 4);
  end;
  len := len - address - 12;
  fileseek(f, address, 0);
  fileread(f, Result.x, 4);
  fileread(f, Result.y, 4);
  fileread(f, Result.black, 4);
  setlength(picdata, len);
  fileread(f, picdata[0], len);
  Result.pic := readpicfrombyte(@picdata[0], len);
end;

function GetPngPic(filename: string; num: integer): Tpic; overload;
var
  address, len: integer;
  Data: array of byte;
  f, Count, beginaddress: integer;
begin
  f := fileopen(AppPath + filename, fmOpenRead);
  fileseek(f, 0, 0);
  fileread(f, Count, 4);
  fileseek(f, (num + 1) * 4, 0);
  fileread(f, len, 4);
  if num = 0 then
    address := (Count + 1) * 4
  else
  begin
    fileseek(f, num * 4, 0);
    fileread(f, address, 4);
  end;
  len := len - address - 12;
  fileseek(f, address, 0);
  fileread(f, Result.x, 4);
  fileread(f, Result.y, 4);
  fileread(f, Result.black, 4);
  setlength(Data, len);
  fileread(f, Data[0], len);
  Result.pic := readpicfrombyte(@Data[0], len);
  fileclose(f);
end;

procedure drawPngPic(image: Tpic; px, py, mask: integer); overload;
begin
  drawPngPic(image, 0, 0, image.pic.w, image.pic.h, px, py, mask);
end;

procedure drawPngPic(image: Tpic; x, y, w, h, px, py, mask: integer); overload;
var
  i1, i2, bpp, b, x1, y1, pix: integer;
  pix1, pix2, pix3, alpha, col1, col2, col3: byte;
  p: pUint32;
  c: Uint32;
begin
  b := 0;
  x1 := px - image.x;
  y1 := py - image.y;
  if mask = 1 then
    for i1 := x1 to x1 + w do
      for i2 := y1 to y1 + h do
      begin
        MaskArray[i1, i2] := 0;
      end;
  bpp := image.pic.format.BytesPerPixel;
  for i1 := 0 to w - 1 do
    for i2 := 0 to h - 1 do
    begin
      if ((y1 + i2) >= 0) and ((y1 + i2) < 440) and ((x1 + i1) >= 0) and ((x1 + i1) < 640) then
        if (MaskArray[x1 + i1, y1 + i2] = 1) or (Mask <= 1) then
        begin
          p := Pointer(Uint32(image.pic.pixels) + (i2 + y) * image.pic.pitch + (i1 + x) * bpp);
          c := PUint32(p)^;
          p := Pointer(Uint32(screen.pixels) + (y1 + i2) * screen.pitch + (x1 + i1) * bpp);
          pix := PUint32(p)^;

{$IFDEF darwin}
          {pix1 := (pix shr 24) and $FF;
          pix2 := (pix shr 16) and $FF;
          pix3 := (pix shr 8) and $FF;
          if fullscreen = 1 then}
          //begin
          pix1 := (pix shr 0) and $FF;
          pix2 := (pix shr 8) and $FF;
          pix3 := (pix shr 16) and $FF;
          //end;
{$ELSE}
          pix1 := (pix shr 16) and $FF;
          pix2 := (pix shr 8) and $FF;
          pix3 := pix and $FF;
{$ENDIF}
          //{$ifdef unix}
          //SDL_getRGB(pix, screen.format, @pix3, @pix2, @pix1);
          //{$else}
          //SDL_getRGB(pix, screen.format, @pix1, @pix2, @pix3);
          //{$endif}
          col1 := c and $FF;
          col2 := (c shr 8) and $FF;
          col3 := (c shr 16) and $FF;
          alpha := (c shr 24) and $FF;

          if (alpha = 0) and (Mask = 1) then MaskArray[x1 + i1, y1 + i2] := 1;

          p := Pointer(Uint32(screen.pixels) + (y1 + i2) * screen.pitch + (x1 + i1) * bpp);

          pix1 := (alpha * col1 + (255 - alpha) * pix1) div 255;
          pix2 := (alpha * col2 + (255 - alpha) * pix2) div 255;
          pix3 := (alpha * col3 + (255 - alpha) * pix3) div 255;

{$IFDEF darwin}
          {c := pix1 shl 24 + pix2 shl 16 + pix3 shl 8;}
          //if fullscreen = 1 then
          c := pix1 shl 0 + pix2 shl 8 + pix3 shl 16;
{$ELSE}
          c := pix1 shl 16 + pix2 shl 8 + pix3 shl 0;
{$ENDIF}
          //{$ifdef unix}
          //c := SDL_MapRGB(screen.format, pix3, pix2, pix1);
          //{$else}
          //c := SDL_MapRGB(screen.format, pix1, pix2, pix3);
          //{$endif}
          PUint32(p)^ := c;
        end;
    end;

end;

function ReadPicFromByte(p_byte: Pbyte; size: integer): Psdl_Surface;
begin
  Result := IMG_Load_RW(SDL_RWFromMem(p_byte, size), 1);
end;

//简体汉字转化成繁体汉字

function Simplified2Traditional(mSimplified: string): string; //返回繁体字符串   //Win98下无效
var
  L: integer;
begin
  L := Length(mSimplified);
  SetLength(Result, L);
{$IFDEF windows}
  LCMapString(GetUserDefaultLCID,
    $04000000, PChar(mSimplified), L, @Result[1], L);
{$ELSE}
  Result := mSimplified;
{$ENDIF}
end; {   Simplified2Traditional   }

//繁体汉字转化成简体汉字

function Traditional2Simplified(mTraditional: string): string; //返回繁体字符串
var
  L: integer;
begin
  L := Length(mTraditional);
  SetLength(Result, L);
{$IFDEF windows}
  LCMapString(GetUserDefaultLCID,
    $02000000, PChar(mTraditional), L, @Result[1], L);
{$ELSE}
  Result := mTraditional;
{$ENDIF}
end; {   Traditional2Simplified   }

procedure NewMenuSystem;
var
  i, menu, menup: integer;
begin
  menu := 0;
  NewshowMenusystem(menu);
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
          menu := menu + 1;
          if menu > 3 then
            menu := 0;
          NewshowMenusystem(menu);
        end;
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          menu := menu - 1;
          if menu < 0 then
            menu := 3;
          NewshowMenusystem(menu);
        end;
      end;
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = sdlk_escape) then
        begin
          redraw;
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          break;
        end;
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          case menu of
            0:
            begin
              if (NewMenuload) then
                break
              else
                NewshowMenusystem(menu);
            end;
            1:
            begin
              if (NewMenuSave) then
                break
              else
                NewshowMenusystem(menu);
            end;
            2:
            begin
              NewMenuVolume;
              NewshowMenusystem(menu);
            end;
            3:
            begin
              NewMenuQuit;
              NewshowMenusystem(menu);
            end;
          end;
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_right) then
        begin
          redraw;
          SDL_UpdateRect2(screen, 112, 25, 668, 390);
          break;
        end;
        if (event.button.button = sdl_button_left) then
          case menu of
            0:
            begin
              if (NewMenuload) then
                break
              else
                NewshowMenusystem(menu);
            end;
            1:
            begin
              if (NewMenuSave) then
                break
              else
                NewshowMenusystem(menu);
            end;
            2:
            begin
              NewMenuVolume;
              NewshowMenusystem(menu);
            end;
            3:
            begin
              NewMenuQuit;
              NewshowMenusystem(menu);
            end;
          end;
      end;
      SDL_MOUSEMOTION:
      begin
        menup := menu;
        if (round(event.button.x / (RealScreen.w / screen.w)) >= 112) and
          (round(event.button.x / (RealScreen.w / screen.w)) < 780) and
          (round(event.button.y / (RealScreen.h / screen.h)) > 25) and
          (round(event.button.y / (RealScreen.h / screen.h)) < 415) then
        begin
          menu := (round(event.button.y / (RealScreen.h / screen.h)) - 25) div 101;
          if menu > 3 then
            menu := 3;
          if menu < 0 then
            menu := 0;
        end
        else
        begin
          menu := -1;
        end;
        if menup <> menu then
          NewshowMenusystem(menu);
      end;
    end;
  end;
  SDL_EnableKeyRepeat(30, (30 * GameSpeed) div 10);
end;

procedure NewShowMenuSystem(menu: integer);
var
  word: array[0..3] of WideString;
  i: integer;
begin
  display_imgFromSurface(SYSTEM_PIC, 0, 0);

  word[0] := UTF8Decode(' ——————————讀取進度——————————');
  word[1] := UTF8Decode(' ——————————保存進度——————————');
  word[2] := UTF8Decode(' ——————————音樂音量——————————');
  word[3] := UTF8Decode(' ——————————退出離開——————————');

  for i := 0 to 3 do
    if i = menu then
    begin
      drawtext(screen, @word[i][1], 113, 25 + 101 * i, colcolor($64));
      drawtext(screen, @word[i][1], 112, 25 + 101 * i, colcolor($66));
    end
    else
    begin
      drawtext(screen, @word[i][1], 113, 25 + 101 * i, colcolor($5));
      drawtext(screen, @word[i][1], 112, 25 + 101 * i, colcolor($7));
    end;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
end;

procedure NewShowSelect(row, menu: integer; word: array of WideString; Width: integer);
var
  i: integer;
begin
  display_imgFromSurface(SYSTEM_PIC, 0, 0);

  for i := 0 to length(word) - 1 do
    if i = menu then
    begin
      drawtext(screen, @word[i][1], 119 + Width * i, 50 + 101 * row, colcolor($64));
      drawtext(screen, @word[i][1], 118 + Width * i, 50 + 101 * row, colcolor($66));
    end
    else
    begin
      drawtext(screen, @word[i][1], 119 + Width * i, 50 + 101 * row, colcolor($5));
      drawtext(screen, @word[i][1], 118 + Width * i, 50 + 101 * row, colcolor($7));
    end;
  SDL_UpdateRect2(screen, 115, 50 + 101 * row, 525, 25);
end;

function NewMenuSave: boolean;
var
  menu: integer;
  menup: integer;
  word: array[0..4] of WideString;
begin
  SDL_EnableKeyRepeat(30, (30 * GameSpeed) div 10);
  Result := False;
  word[0] := UTF8Decode(' 進度一');
  word[1] := UTF8Decode(' 進度二');
  word[2] := UTF8Decode(' 進度三');
  word[3] := UTF8Decode(' 進度四');
  word[4] := UTF8Decode(' 進度五');
  menu := 0;
  NewShowSelect(1, menu, word, 97);
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
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_kp6) then
        begin
          menu := menu + 1;
          if menu > 4 then
            menu := 0;
          NewshowSelect(1, menu, word, 97);
        end;
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) then
        begin
          menu := menu - 1;
          if menu < 0 then
            menu := 4;
          NewshowSelect(1, menu, word, 97);
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
          if menu >= 0 then
          begin
            event.key.keysym.sym := 0;
            SaveR(menu + 1);
            SDL_EnableKeyRepeat(30, (30 * GameSpeed) div 10);
            Result := True;
            break;
          end;
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
          if menu >= 0 then
          begin
            SaveR(menu + 1);
            Result := True;
            break;
          end;
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        menup := menu;
        if (round(event.button.x / (RealScreen.w / screen.w)) >= 112) and
          (round(event.button.x / (RealScreen.w / screen.w)) < 572) and
          (round(event.button.y / (RealScreen.h / screen.h)) > 150) and
          (round(event.button.y / (RealScreen.h / screen.h)) < 180) then
        begin
          menu := (round(event.button.x / (RealScreen.w / screen.w)) - 117) div 97;
          if menu > 4 then
            menu := 4;
          if menu < 0 then
            menu := 0;
        end
        else
        begin
          menu := -1;
        end;
        if menup <> menu then
          NewshowSelect(1, menu, word, 97);
      end;
    end;
  end;
end;

function NewMenuLoad: boolean;
var
  menu: integer;
  menup: integer;
  word: array[0..5] of WideString;
begin
  SDL_EnableKeyRepeat(10, 100);
  Result := False;
  word[0] := UTF8Decode(' 進度一');
  word[1] := UTF8Decode(' 進度二');
  word[2] := UTF8Decode(' 進度三');
  word[3] := UTF8Decode(' 進度四');
  word[4] := UTF8Decode(' 進度五');
  word[5] := UTF8Decode(' 自動檔');
  menu := 0;
  NewShowSelect(0, menu, word, 81);
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
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_kp6) then
        begin
          menu := menu + 1;
          if menu > 5 then
            menu := 0;
          NewShowSelect(0, menu, word, 81);
        end;
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) then
        begin
          menu := menu - 1;
          if menu < 0 then
            menu := 5;
          NewShowSelect(0, menu, word, 81);
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
          if menu >= 0 then
          begin
            LoadR(menu + 1);
            SDL_EnableKeyRepeat(30, (30 * GameSpeed) div 10);
            if where = 1 then
            begin
              event.key.keysym.sym := 0;
              InScene(0);
              //JmpScene(curScene, sy, sx);
            end;
            redraw;
            Result := True;
            break;
          end;
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_right) then
        begin
          break;
        end;
        if (event.button.button = sdl_button_left) then
        begin if menu >= 0 then
          begin
            LoadR(menu + 1);
            if where = 1 then
            begin
              InScene(0);
              //JmpScene(curScene, sy, sx);
            end;
            redraw;
            Result := True;
            break;
          end;
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        menup := menu;
        if (round(event.button.x / (RealScreen.w / screen.w)) >= 112) and
          (round(event.button.x / (RealScreen.w / screen.w)) < 602) and
          (round(event.button.y / (RealScreen.h / screen.h)) > 49) and
          (round(event.button.y / (RealScreen.h / screen.h)) < 129) then
        begin
          menu := (round(event.button.x / (RealScreen.w / screen.w)) - 117) div 81;
          if menu > 5 then
            menu := 5;
          if menu < 0 then
            menu := 0;
        end
        else
        begin
          menu := -1;
        end;
        if menup <> menu then
          NewShowSelect(0, menu, word, 81);
      end;
    end;
  end;
  SDL_EnableKeyRepeat(30, (30 * GameSpeed) div 10);
end;

procedure NewMenuVolume;
var
  menu: integer;
  menup: integer;
  w: integer;
  word: array[0..8] of WideString;

begin

  w := 56;
  word[0] := UTF8Decode(' 零');
  word[1] := UTF8Decode(' 一');
  word[2] := UTF8Decode(' 二');
  word[3] := UTF8Decode(' 三');
  word[4] := UTF8Decode(' 四');
  word[5] := UTF8Decode(' 五');
  word[6] := UTF8Decode(' 六');
  word[7] := UTF8Decode(' 七');
  word[8] := UTF8Decode(' 八');
  SDL_EnableKeyRepeat(10, 100);
  menu := MusicVolume div 16;
  NewShowSelect(2, menu, word, w);
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
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_kp6) then
        begin
          menu := menu + 1;
          if menu > length(word) - 1 then
            menu := 0;
          NewshowSelect(2, menu, word, w);
        end;
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) then
        begin
          menu := menu - 1;
          if menu < 0 then
            menu := length(word) - 1;
          NewshowSelect(2, menu, word, w);
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
          if menu >= 0 then
          begin
            MusicVolume := menu * 16;
            //Mix_VolumeMusic(MusicVolume);
            BASS_ChannelSetAttribute(Music[nowmusic], BASS_ATTRIB_VOL, MusicVOLUME / 128.0);
            Kys_ini.WriteInteger('constant', 'MUSIC_VOLUME', MusicVolume);
          end;
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
          MusicVolume := menu * 16;
          //Mix_VolumeMusic(MusicVolume);
          BASS_ChannelSetAttribute(Music[nowmusic], BASS_ATTRIB_VOL, MusicVOLUME / 128.0);
          Kys_ini.WriteInteger('constant', 'MUSIC_VOLUME', MusicVolume);
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        menup := menu;
        if (round(event.button.x / (RealScreen.w / screen.w)) >= 112) and
          (round(event.button.x / (RealScreen.w / screen.w)) < 640) and
          (round(event.button.y / (RealScreen.h / screen.h)) > 251) and
          (round(event.button.y / (RealScreen.h / screen.h)) < 331) then
        begin
          menu := (round(event.button.x / (RealScreen.w / screen.w)) - 117) div w;
          if menu > length(word) - 1 then
            menu := length(word) - 1;
          if menu < 0 then
            menu := 0;
        end
        else
        begin
          menu := musicvolume div 16;
        end;
        if menup <> menu then
          NewshowSelect(2, menu, word, w);
      end;
    end;
  end;
  SDL_EnableKeyRepeat(30, (30 * GameSpeed) div 10);
end;

procedure NewMenuQuit;
var
  menu: integer;
  menup: integer;
  w: integer;
  word: array[0..1] of WideString;
begin
  w := 56;
  word[0] := UTF8Decode(' 取消');
  word[1] := UTF8Decode(' 退出');
  menu := -1;
  SDL_EnableKeyRepeat(10, 100);
  NewShowSelect(3, menu, word, w);
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
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_kp6) then
        begin
          menu := menu + 1;
          if menu > length(word) - 1 then
            menu := 0;
          NewshowSelect(3, menu, word, w);
        end;
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) then
        begin
          menu := menu - 1;
          if menu < 0 then
            menu := length(word) - 1;
          NewshowSelect(3, menu, word, w);
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
          if menu = 1 then
          begin
            Quit;
          end;
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
          if menu = 1 then
          begin
            Quit;
          end;
        end;
        break;
      end;
      SDL_MOUSEMOTION:
      begin
        menup := menu;
        if (round(event.button.x / (RealScreen.w / screen.w)) >= 112) and
          (round(event.button.x / (RealScreen.w / screen.w)) < 640) and
          (round(event.button.y / (RealScreen.h / screen.h)) > 352) and
          (round(event.button.y / (RealScreen.h / screen.h)) < 432) then
        begin
          menu := (round(event.button.x / (RealScreen.w / screen.w)) - 117) div w;
          if menu > length(word) - 1 then
            menu := length(word) - 1;
          if menu < 0 then
            menu := 0;
        end
        else
        begin
          menu := -1;
        end;
        if menup <> menu then
          NewshowSelect(3, menu, word, w);
      end;
    end;
  end;
  SDL_EnableKeyRepeat(30, (30 * GameSpeed) div 10);
end;

procedure DrawItemPic(num, x, y: integer);
begin
  if ITEM_PIC[num].pic = nil then
    ITEM_PIC[num] := GetPngPic(Items_file, num);
  drawPngPic(ITEM_PIC[num], x, y, 0);
end;

procedure ShowMap;
var
  i, i1, i2, u, maxspd, n, mousex, mousey, x, y, l, p: integer;
  str1, str, strboat: WideString;
  str2, str3: array of WideString;
  Scenex: array of integer;
  Sceney: array of integer;
  Scenenum: array of integer;
begin
  event.key.keysym.sym := 0;
  event.button.button := 0;
  n := 0;
  p := 0;
  u := 0;
  maxspd := 0;
  for i := 0 to length(rrole) - 1 do
    if rrole[i].TeamState in [1, 2] then
      maxspd := max(maxspd, GetRoleSpeed(i, True));
  l := length(RScene);
  for i := 0 to l - 1 do
  begin
    if ((RScene[i].MainEntranceY1 = 0) and (RScene[i].MainEntranceX1 = 0) and
      (RScene[i].MainEntranceX2 = 0) and (RScene[i].MainEntranceY2 = 0)) or
      ((RScene[i].EnCondition = 2) and (maxspd < 70)) or (RScene[i].EnCondition = 1) or
      (RScene[i].EnCondition = 3) or (RScene[i].EnCondition = 4) then continue;
    Inc(u);
    setlength(Scenex, u);
    setlength(Sceney, u);
    setlength(Scenenum, u);
    setlength(str2, u);
    setlength(str3, u);
    Scenex[u - 1] := RScene[i].MainEntranceX1;
    Sceney[u - 1] := RScene[i].MainEntranceY1;
    Scenenum[u - 1] := i;
    str2[u - 1] := gbktounicode(@RScene[i].Name[0]);
    str3[u - 1] := format('%3d, %3d', [RScene[i].MainEntranceY1, RScene[i].MainEntranceX1]);

  end;
  str := UTF8Decode(' 你的位置');
  strboat := UTF8Decode(' 船的位置');
  while SDL_PollEvent(@event) >= 0 do
  begin
    if (n mod 10 = 0) then
    begin
      drawPngPic(MAP_PIC, 0, 30, 640, 380, 0, 30, 0);

      //  if i = p then continue;
      for i := 0 to u - 1 do
      begin
        x := 313 + ((Sceney[i] - Scenex[i]) * 5) div 8;
        y := 63 + ((Sceney[i] + Scenex[i]) * 5) div 16;
        drawPngPic(MAP_PIC, 15, 0, 15, 15, x, y, 0);
        if (x < round(event.button.x / (RealScreen.w / screen.w))) and
          (x + 15 > round(event.button.x / (RealScreen.w / screen.w))) and
          (y < round(event.button.y / (RealScreen.h / screen.h))) and
          (y + 15 > round(event.button.y / (RealScreen.h / screen.h))) then
        begin
          p := i;
        end;
      end;
      x := 313 + ((Sceney[p] - Scenex[p]) * 5) div 8;
      y := 63 + ((Sceney[p] + Scenex[p]) * 5) div 16;

      drawPngPic(MAP_PIC, 30, 0, 15, 15, x, y, 0);
      drawPngPic(MAP_PIC, 30, 0, 15, 15, x, y, 0);

      x := 313 + ((Shipx - Shipy) * 5) div 8;
      y := 63 + ((Shipx + Shipy) * 5) div 16;

      drawPngPic(MAP_PIC, 45, 0, 15, 15, x, y, 0);
      drawPngPic(MAP_PIC, 45, 0, 15, 15, x, y, 0);

      drawshadowtext(@str2[p][1], 17, 80, colcolor(0, 21), colcolor(0, 25));
      drawengshadowtext(@str3[p][1], 37, 100, colcolor(0, 255), colcolor(0, 254));

      drawshadowtext(@str[1], 17, 275, colcolor(0, 21), colcolor(0, 25));
      str1 := format('%3d, %3d', [My, Mx]);
      drawengshadowtext(@str1[1], 37, 295, colcolor(0, 255), colcolor(0, 254));

      drawshadowtext(@strboat[1], 17, 325, colcolor(0, 21), colcolor(0, 25));
      str1 := format('%3d, %3d', [shipx, shipy]);
      drawengshadowtext(@str1[1], 37, 345, colcolor(0, 255), colcolor(0, 254));

    end;
    if n mod 20 = 1 then
    begin
      x := 313 + ((my - mx) * 5) div 8;
      y := 63 + (((my + mx) * 5)) div 16;
      drawPngPic(MAP_PIC, 0, 0, 15, 15, x, y, 0);
      drawPngPic(MAP_PIC, 0, 0, 15, 15, x, y, 0);

    end;
    SDL_UpdateRect2(screen, 0, 0, 640, 440);
    sdl_delay(20);
    n := n + 1;
    if n = 1000 then
      n := 0;

    case event.type_ of
      SDL_QUITEV:
        if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then
          Quit;
      //方向键使用压下按键事件
      SDL_VIDEORESIZE:
      begin
        ResizeWindow(event.resize.w, event.resize.h);
      end;
      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = sdlk_escape) or (event.key.keysym.sym = sdlk_return) or
          (event.key.keysym.sym = sdlk_space) then break;
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) or
          (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          if u <> 0 then
          begin
            p := p - 1;
            if p <= -1 then p := u - 1;
          end;
        end;
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_kp6) or
          (event.key.keysym.sym = sdlk_down) or (event.key.keysym.sym = sdlk_kp2) then
        begin
          if u <> 0 then
          begin
            p := p + 1;
            if p >= u then p := 0;
          end;
        end;
        event.key.keysym.sym := 0;
        event.button.button := 0;

      end;

      SDL_MOUSEBUTTONUP:
      begin
        if event.button.button = sdl_button_right then
          break;
        if (debug = 1) and (event.button.button = sdl_button_left) then
        begin
          for i1 := 0 to 1 do
            for i2 := 0 to 1 do
            begin
              mx := Scenex[p] + i2;
              my := Sceney[p] + i1;
              if canwalk(mx, my) then break;
            end;
        end;
      end;
      SDL_MOUSEMotion:
      begin
        for i := 0 to length(Sceney) - 1 do
        begin
          x := 313 + ((Sceney[i] - Scenex[i]) * 5) div 8;
          y := 63 + ((Sceney[i] + Scenex[i]) * 5) div 16;
          if (x < round(event.button.x / (RealScreen.w / screen.w))) and
            (x + 15 > round(event.button.x / (RealScreen.w / screen.w))) and (y <
            round(event.button.y / (RealScreen.h / screen.h))) and
            (y + 15 > round(event.button.y / (RealScreen.h / screen.h))) then
          begin
            p := i;
          end;
        end;

      end;
    end;
  end;
end;

procedure NewMenuEsc;
var
  x, y, menu, N, i, i1, i2: integer;
  positionX: array[0..5] of integer;
  positionY: array[0..5] of integer;
  menu1: integer;
begin
  x := 270;
  y := 50 + 117;
  N := 102;
  positionY[0] := y - 117;
  positionY[1] := y - 58;
  positionY[2] := y + 58;
  positionY[3] := 117 + y;
  positionY[4] := y + 58;
  positionY[5] := y - 58;

  positionX[0] := X;
  positionX[1] := X + N;
  positionX[2] := X + N;
  positionX[3] := X;
  positionX[4] := X - N;
  positionX[5] := X - N;

  redraw;

  SDL_EnableKeyRepeat(10, 100);
  menu := 0;
 { for i1 := 0 to 10 do
  begin
    drawPngPic(MenuescBack_PIC, 300, 0, 300, 300, 170, 70, 0);
    if (where = 1) and (water < 0) then
      sdl_delay((25 * GameSpeed) div 10);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  end;

  for i2 := 0 to 10 do
  begin
    if (where = 0) and (i2 mod 2 = 1) then continue;
    redraw;
    drawPngPic(MenuescBack_PIC, 0, 0, 300, 300, 170, 70, 0);
    for I := 0 to 5 do
    begin
      drawPngPic(Menuesc_PIC, (i mod 3) * 100, (i div 3) * 100 + 200, 100, 100, x + i2 * (positionX[i] - x) div 10, y + i2 * (positionY[i] - y) div 10, 0);
    end;
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  end;     }
  showNewMenuEsc(menu, positionX, positionY);

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
          if (menu = 0) or (menu = 1) or (menu = 2) then menu := menu + 1
          else if (menu = 5) or (menu = 4) then menu := menu - 1;
          showNewMenuEsc(menu, positionX, positionY);
        end;
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          if (menu = 1) or (menu = 2) or (menu = 3) then menu := menu - 1
          else if (menu = 4) then menu := menu + 1
          else if (menu = 5) then menu := 0;
          showNewMenuEsc(menu, positionX, positionY);
        end;
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_kp6) then
        begin
          if (menu = 0) then menu := menu + 1
          else if (menu = 3) or (menu = 4) then menu := menu - 1
          else if (menu = 5) then menu := 0;
          showNewMenuEsc(menu, positionX, positionY);
        end;
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) then
        begin
          if (menu = 0) then menu := 5
          else if (menu = 3) or (menu = 2) then menu := menu + 1
          else if (menu = 5) or (menu = 1) then menu := menu - 1;
          showNewMenuEsc(menu, positionX, positionY);
        end;
      end;

      SDL_KEYUP:
      begin
        if (event.key.keysym.sym = sdlk_f5) then
        begin
          SwitchFullscreen;
          Kys_ini.WriteInteger('set', 'fullscreen', fullscreen);
        end;
        if (event.key.keysym.sym = sdlk_escape) then
        begin
          resetpallet;
          break;

        end;
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          resetpallet(0);
          case menu of
            0:
            begin
              SelectShowMagic;
            end;
            1:
            begin
              SelectShowStatus;
            end;
            2:
            begin
              NewMenuSystem;
              resetpallet;
              event.key.keysym.sym := 0;
              event.button.button := 0;
              exit;
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
              newMenuItem;
            end;
          end;
          resetpallet;
          showNewMenuEsc(menu, positionX, positionY);
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_right) then
        begin
          resetpallet;
          break;
        end;
        if (event.button.button = sdl_button_left) then
        begin
          menu1 := -1;
          for i := 0 to 5 do
            if ((positionX[i] + 10 < round(event.button.x / (RealScreen.w / screen.w))) and
              (positionX[i] + 90 > round(event.button.x / (RealScreen.w / screen.w)))) and
              ((positionY[i] + 10 < round(event.button.y / (RealScreen.h / screen.h))) and
              (positionY[i] + 90 > round(event.button.y / (RealScreen.h / screen.h)))) then
            begin
              menu1 := i;
              resetpallet;
              break;
            end;
          if menu1 >= 0 then
          begin
            resetpallet(0);
            case menu1 of
              0:
              begin
                SelectShowMagic;
              end;
              1:
              begin
                SelectShowStatus;
              end;
              2:
              begin
                NewMenuSystem;
                resetpallet;
                event.key.keysym.sym := 0;
                event.button.button := 0;
                exit;
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
                newMenuItem;
              end;
            end;
            resetpallet;
            showNewMenuEsc(menu, positionX, positionY);
          end;
        end;

      end;
      SDL_MOUSEMOTION:
      begin
        menu1 := menu;
        for i := 0 to 5 do
          if ((positionX[i] + 10 < round(event.button.x / (RealScreen.w / screen.w))) and
            (positionX[i] + 90 > round(event.button.x / (RealScreen.w / screen.w)))) and
            ((positionY[i] + 10 < round(event.button.y / (RealScreen.h / screen.h))) and
            (positionY[i] + 90 > round(event.button.y / (RealScreen.h / screen.h)))) then
          begin
            menu := i;
            break;
          end;

        if menu <> menu1 then showNewMenuEsc(menu, positionX, positionY);

      end;
    end;
  end;

  redraw;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);

  event.key.keysym.sym := 0;
  event.button.button := 0;
{
  for i2 := 0 to 10 do
  begin
    if (where = 0) and (i2 mod 2 = 1) then continue;
    redraw;
    drawPngPic(MenuescBack_PIC, 0, 0, 300, 300, 170, 70, 0);
    for I := 0 to 5 do
    begin
      drawPngPic(Menuesc_PIC, (i mod 3) * 100, (i div 3) * 100 + 200, 100, 100, x + (10 - i2) * (positionX[i] - x) div 10, y + (10 - i2) * (positionY[i] - y) div 10, 0);
    end;
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  end;

  for i1 := 0 to 10 do
  begin
    if (where = 0) and (i1 mod 2 = 1) then continue;
    redraw;
    for i := 0 to 10 - i1 do
      drawPngPic(Menuescback_PIC, 300, 0, 300, 300, 170, 70, 0);

    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  end;
         }
  SDL_EnableKeyRepeat(30, (30 * GameSpeed) div 10);
end;

procedure showNewMenuEsc(menu: integer; positionX, positionY: array of integer);
var
  i: integer;
begin
  redraw;

  drawPngPic(Menuescback_PIC, 0, 0, 300, 300, 170, 70, 0);

  for I := 0 to 5 do
  begin
    if i = menu then
      drawPngPic(Menuesc_PIC, (i mod 3) * 100, (i div 3) * 100, 100, 100, positionX[i], positionY[i], 0)
    else
      drawPngPic(Menuesc_PIC, (i mod 3) * 100, (i div 3) * 100 + 200, 100, 100, positionX[i], positionY[i], 0);
  end;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
end;

procedure resetpallet; overload;
var
  i, c: integer;
  p: pbyte;
begin
  c := 0;
  if where = 1 then
  begin
    if rScene[curScene].Pallet in [0..3] then
      c := rScene[curScene].Pallet
    else c := 0;
    p := @Col[c][0];
  end
  else p := @Col[0][0];

  for i := 0 to 768 - 1 do
  begin
    Acol[i] := p^;
    Inc(p);

  end;

end;

procedure resetpallet(num: integer); overload;
var
  i: integer;
begin
  for i := 0 to 768 - 1 do
    Acol[i] := Col[num][i];
end;

function RoRforUint16(a, n: Uint16): Uint16;
var
  b: Uint16;
begin
  b := a shl (16 - n);
  a := a shr n;
  Result := a or b;
end;

function RoLforUInt16(a, n: Uint16): Uint16;
var
  b: Uint16;
begin
  b := a shr (16 - n);
  a := a shl n;
  Result := a or b;
end;

function RoRforByte(a: byte; n: Uint16): byte;
var
  b: byte;
begin
  b := a shl (8 - n);
  a := a shr n;
  Result := a or b;
end;

function RoLforByte(a: byte; n: Uint16): byte;
var
  b: byte;
begin
  b := a shr (8 - n);
  a := a shl n;
  Result := a or b;
end;

procedure DrawEftPic(Pic: Tpic; px, py, level: integer);
var
  w, h, xs, ys, black: integer;
  xx, yy: integer;
  pix, pix0: Uint32;
  pix1, pix2, pix3, pix4, pix01, pix02, pix03, pix04: byte;
  i: double;
  pic1: Tpic;
begin
  if (level = 0) then level := 10;

  i := (level) / 20 + 0.5;
  xs := trunc(pic.x * i);
  ys := trunc(pic.y * i);
  pic1.x := xs;
  pic1.y := ys;
  xs := px - xs;
  ys := py - ys;
  w := trunc(pic.pic.w * i);
  h := trunc(pic.pic.h * i);
  black := pic.black;
  pic1.pic := zoomSurface(pic.pic, i, i, 0);
  if black <> 0 then
  begin
    for yy := 0 to h - 1 do
    begin
      if yy + ys < screen.h then
        for xx := 0 to w - 1 do
        begin
          if xx + xs < screen.w then
          begin
            pix0 := getpixel(pic1.pic, xx, yy);
            if (pix0 and $FFFFFF) <> 0 then
            begin
              pix := getpixel(screen, xx + xs, yy + ys);

{$IFDEF darwin}
              {pix03 := pix0 and $FF;
              pix02 := pix0 shr 8 and $FF;
              pix01 := pix0 shr 16 and $FF;
              pix04 := pix0 shr 24 and $FF;

              if fullscreen = 1 then
              begin}
              pix04 := pix0 and $FF;
              pix03 := pix0 shr 24 and $FF;
              pix02 := pix0 shr 16 and $FF;
              pix01 := pix0 shr 8 and $FF;
              //end;

              pix4 := pix and $FF;
              pix1 := pix shr 8 and $FF;
              pix2 := pix shr 16 and $FF;
              pix3 := pix shr 24 and $FF;

              pix1 := pix1 + pix01 - (pix01 * pix1) div 255;
              pix2 := pix2 + pix02 - (pix02 * pix2) div 255;
              pix3 := pix3 + pix03 - (pix03 * pix3) div 255;
              //pix4 := pix4 + pix04 - (pix04 * pix4) div 255;

              pix := pix1 shl 8 + pix2 shl 16 + pix3 shl 24 + pix4 shl 0;
{$ELSE}
              pix03 := pix0 and $FF;
              pix02 := pix0 shr 8 and $FF;
              pix01 := pix0 shr 16 and $FF;
              pix04 := pix0 shr 24 and $FF;

              pix1 := pix and $FF;
              pix2 := pix shr 8 and $FF;
              pix3 := pix shr 16 and $FF;
              pix4 := pix shr 24 and $FF;

              pix1 := pix1 + pix01 - (pix01 * pix1) div 255;
              pix2 := pix2 + pix02 - (pix02 * pix2) div 255;
              pix3 := pix3 + pix03 - (pix03 * pix3) div 255;

              pix := pix1 + pix2 shl 8 + pix3 shl 16 + pix4 shl 24;
{$ENDIF}
              putpixel(screen, xx + xs, yy + ys, pix);

            end;
          end;

        end;
    end;
  end
  else
  begin

    for yy := 0 to h - 1 do
    begin
      if yy + ys < screen.h then
        for xx := 0 to w - 1 do
        begin
          if xx + xs < screen.w then
          begin
            pix0 := getpixel(pic1.pic, xx, yy);
            if (pix0 and $FF000000) <> 0 then
            begin
              pix := getpixel(screen, xx + xs, yy + ys);
{$IFDEF darwin}
              {pix03 := pix0 and $FF;
              pix02 := pix0 shr 8 and $FF;
              pix01 := pix0 shr 16 and $FF;
              pix04 := pix0 shr 24 and $FF;

              if fullscreen = 1 then
              begin}
              pix04 := pix0 and $FF;
              pix03 := pix0 shr 24 and $FF;
              pix02 := pix0 shr 16 and $FF;
              pix01 := pix0 shr 8 and $FF;
              //end;

              pix4 := pix and $FF;
              pix1 := pix shr 8 and $FF;
              pix2 := pix shr 16 and $FF;
              pix3 := pix shr 24 and $FF;

              pix1 := pix1 + pix01 - (pix01 * pix1) div 255;
              pix2 := pix2 + pix02 - (pix02 * pix2) div 255;
              pix3 := pix3 + pix03 - (pix03 * pix3) div 255;
              pix4 := pix4 + pix04 - (pix04 * pix4) div 255;

              pix := pix1 shl 8 + pix2 shl 16 + pix3 shl 24 + pix4 shl 0;
{$ELSE}
              pix03 := pix0 and $FF;
              pix02 := pix0 shr 8 and $FF;
              pix01 := pix0 shr 16 and $FF;
              pix04 := pix0 shr 24 and $FF;
              pix1 := pix and $FF;
              pix2 := pix shr 8 and $FF;
              pix3 := pix shr 16 and $FF;
              pix4 := pix shr 24 and $FF;

              pix1 := (pix04 * pix01 + (255 - pix04) * pix1) div 255;
              pix2 := (pix04 * pix02 + (255 - pix04) * pix2) div 255;
              pix3 := (pix04 * pix03 + (255 - pix04) * pix3) div 255;

              pix := pix1 + pix2 shl 8 + pix3 shl 16;
{$ENDIF}
              putpixel(screen, xx + xs, yy + ys, pix);

            end;
          end;
        end;
    end;
  end;
  sdl_freesurface(pic1.pic);
end;

procedure ZoomPic(scr: Psdl_surface; angle: double; x, y, w, h: integer);
var
  a, b: double;
  dest, sest: tsdl_Rect;
  temp: psdl_surface;
begin
  a := w / scr.w;
  b := h / scr.h;
  dest.x := x;
  dest.y := y;
  dest.w := w;
  dest.h := h;
  temp := sdl_gfx.rotozoomSurfaceXY(scr, angle, a, b, 0);
  SDL_BlitSurface(temp, nil, screen, @dest);
  sdl_freesurface(temp);
end;

function GetZoomPic(scr: Psdl_surface; angle: double; x, y, w, h: integer): Psdl_surface;
var
  a, b: double;
  dest, sest: tsdl_Rect;
begin
  a := w / scr.w;
  b := h / scr.h;
  dest.x := x;
  dest.y := y;
  dest.w := w;
  dest.h := h;
  Result := sdl_gfx.rotozoomSurfaceXY(scr, angle, a, b, 0);
end;

procedure PlayBeginningMovie(beginnum, endnum: integer);
var
  i, grp, idx, Count, len: integer;
  MOV: Tpic;
begin
  //PlayMp3(1, 1);

  if (FileExistsUTF8(AppPath + MOVIE_file) { *Converted from FileExists*  }) then
  begin
    SDL_ShowCursor(SDL_DISABLE);
    grp := fileopen(AppPath + MOVIE_file, fmopenread);
    fileseek(grp, 0, 0);
    fileread(grp, Count, 4);

    if (beginnum < 0) then beginnum := Count - 1;
    if (endnum < 0) then endnum := Count - 1;
    if (beginnum > Count - 1) then beginnum := Count - 1;
    if (endnum > Count - 1) then endnum := Count - 1;

    if endnum > beginnum then
    begin
      //MOV := GetPngPic(@MOVPic[0], @MOVidx[0], 1);
      for i := beginnum to endnum do
      begin
        while SDL_PollEVENT(@event) > 0 do
        begin
          case event.type_ of
            SDL_QUITEV:
              if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then
                Quit;
            //方向键使用压下按键事件
            SDL_VIDEORESIZE:
            begin
              ResizeWindow(event.resize.w, event.resize.h);
            end;
            SDL_KEYUP:
            begin
              if (event.key.keysym.sym = sdlk_escape) or (event.key.keysym.sym = sdlk_return) or
                (event.key.keysym.sym = sdlk_space) then
              begin
                fileclose(grp);

                event.key.keysym.sym := 0;
                event.button.button := 0;
                SDL_ShowCursor(SDL_ENABLE);
                Exit;
              end;
            end;
          end;
        end;

        MOV := GetPngPic(grp, i);
        ZoomPic(MOV.pic, 0, 0, 0, screen.w, screen.h);

        sdl_delay(20);
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        SDL_freeSurface(MOV.pic);
      end;
    end
    else
    begin
      for i := beginnum downto endnum do
      begin
        while SDL_PollEVENT(@event) > 0 do
        begin
          case event.type_ of
            SDL_QUITEV:
              if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then
                Quit;
            //方向键使用压下按键事件
            SDL_VIDEORESIZE:
            begin
              ResizeWindow(event.resize.w, event.resize.h);
            end;
            SDL_KEYUP:
            begin
              if (event.key.keysym.sym = sdlk_escape) or (event.key.keysym.sym = sdlk_return) or
                (event.key.keysym.sym = sdlk_space) then
              begin
                fileclose(grp);

                SDL_ShowCursor(SDL_ENABLE);
                event.key.keysym.sym := 0;
                event.button.button := 0;
                Exit;
              end;
            end;
          end;
        end;

        MOV := GetPngPic(grp, i);
        ZoomPic(MOV.pic, 0, 0, 0, screen.w, screen.h);

        sdl_delay(1);
        SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        SDL_freeSurface(MOV.pic);
      end;
    end;
    fileclose(grp);
    // Setlength(MOVIDX, 0);
    //Setlength( 0);
  end;

  SDL_ShowCursor(SDL_ENABLE);
end;

procedure NewMenuTeammate;
var
  i, i1, rcount, tcount, menu1, menu2, tmenu, rmenu, temp, t, tt, rr, p, position: integer;
  TeamMate: array[0..25] of smallint;
  newList: array[0..5] of smallint;
begin
  tmenu := 1;
  rmenu := 0;
  rcount := 0;
  position := 0;
  t := -1;
  tt := -1;
  rr := -1;
  for i := 0 to 25 do
  begin
    teammate[i] := -1;
  end;
  for i := 1 to length(Rrole) - 1 do
  begin
    if rrole[i].TeamState = 2 then
    begin
      teammate[rcount] := i;
      Inc(rcount);
    end;
  end;
  tcount := 1;
  for i := 1 to 5 do
  begin
    if teamlist[i] > 0 then
    begin
      Inc(tcount);
    end;
  end;
  ShowTeammateMenu(tmenu, rmenu, @Teammate[0], rcount, 0);

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
          if position = 0 then
          begin
            Tmenu := Tmenu + 1;
            if Tmenu > 5 then Tmenu := 1;
          end
          else
          begin
            Rmenu := Rmenu + 2;
            if Rmenu > 25 then Rmenu := 0;
          end;
        end;
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          if position = 0 then
          begin
            Tmenu := Tmenu - 1;
            if Tmenu < 1 then Tmenu := 5;
          end
          else
          begin
            Rmenu := Rmenu - 2;
            if Rmenu < 0 then Rmenu := 25;
          end;
        end;
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_kp6) then
        begin
          if position = 0 then
          begin
            if t < 0 then
              position := 1;
          end
          else
          begin
            Rmenu := Rmenu + 1;
            if Rmenu > 25 then Rmenu := 0;
          end;

        end;
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) then
        begin
          if position = 1 then
          begin
            if Rmenu mod 2 = 0 then
              if t < 0 then

                position := 0;
          end
          else
          begin
            Rmenu := Rmenu - 1;
            if Rmenu < 0 then Rmenu := 25;
          end;
        end;
        if (event.key.keysym.sym = sdlk_f5) then
        begin
          SwitchFullscreen;
          Kys_ini.WriteInteger('set', 'fullscreen', fullscreen);
        end;
        if (event.key.keysym.sym = sdlk_escape) then
        begin
          //resetpallet;
          if t < 0 then
            break
          else
          begin
            t := -1;
            tt := -1;
            rr := -1;
          end;
        end;
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          if t < 0 then
          begin
            if position = 0 then
            begin
              t := Tmenu;
              tt := tmenu;
            end
            else
            begin
              t := rmenu;
              rr := rmenu;
            end;
          end
          else
          begin
            if rr = -1 then rr := rmenu;
            if tt = -1 then tt := tmenu;
            if TeamList[tt] > 0 then Rrole[TeamList[tt]].TeamState := 2;
            if TeamMate[rr] > 0 then Rrole[TeamMate[rr]].TeamState := 1;
            temp := TeamList[tt];
            TeamList[tt] := TeamMate[rr];
            TeamMate[rr] := temp;
            t := -1;
            tt := -1;
            rr := -1;
          end;
          position := 1 - position;
        end;
        if t > -1 then ShowTeammateMenu(tmenu, rmenu, @Teammate[0], rcount, 2)
        else ShowTeammateMenu(tmenu, rmenu, @Teammate[0], rcount, position);
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_right) then
        begin
          if t < 0 then
            break
          else
          begin
            t := -1;
            tt := -1;
            rr := -1;
          end;
        end;
        if (event.button.button = sdl_button_left) then
        begin
          if t < 0 then
          begin
            if position = 0 then
            begin
              t := Tmenu;
              tt := tmenu;
            end
            else
            begin
              t := rmenu;
              rr := rmenu;
            end;
          end
          else
          begin
            if rr = -1 then rr := rmenu;
            if tt = -1 then tt := tmenu;

            if TeamList[tt] > 0 then Rrole[TeamList[tt]].TeamState := 2;
            if TeamMate[rr] > 0 then Rrole[TeamMate[rr]].TeamState := 1;
            temp := TeamList[tt];
            TeamList[tt] := TeamMate[rr];
            TeamMate[rr] := temp;
            t := -1;
            tt := -1;
            rr := -1;
          end;
          position := 1 - position;
        end;
        if t > -1 then ShowTeammateMenu(tmenu, rmenu, @Teammate[0], rcount, 2)
        else ShowTeammateMenu(tmenu, rmenu, @Teammate[0], rcount, position);
      end;
      SDL_MOUSEMOTION:
      begin
        menu1 := Tmenu;
        menu2 := Rmenu;
        p := position;
        position := -1;
        if (round(event.button.x / (RealScreen.w / screen.w)) > 120) and
          (round(event.button.y / (RealScreen.h / screen.h)) > 60) and
          (round(event.button.x / (RealScreen.w / screen.w)) < 120 + 220) and
          (round(event.button.y / (RealScreen.h / screen.h)) < 60 + 25 * 5) then
        begin
          position := 0;
          TMenu := (round(event.button.y / (RealScreen.h / screen.h)) - 60) div 25 + 1;
        end;
        if (round(event.button.x / (RealScreen.w / screen.w)) > 350) and
          (round(event.button.y / (RealScreen.h / screen.h)) > 60) and
          (round(event.button.x / (RealScreen.w / screen.w)) < 350 + 200) and
          (round(event.button.y / (RealScreen.h / screen.h)) < 60 + 25 * 13) then
        begin
          position := 1;
          RMenu := ((round(event.button.y / (RealScreen.h / screen.h)) - 60) div 25) * 2 +
            (round(event.button.x / (RealScreen.w / screen.w)) - 350) div 100;
        end;
        if Rmenu > 25 then Rmenu := 25;
        if Rmenu < 0 then Rmenu := 0;
        if tmenu < 1 then Rmenu := 1;
        if tmenu > 5 then Rmenu := 5;

        if (menu1 <> Tmenu) or (p <> position) or (menu2 <> Rmenu) then
        begin
          if t > -1 then ShowTeammateMenu(tmenu, rmenu, @Teammate[0], rcount, 2)
          else ShowTeammateMenu(tmenu, rmenu, @Teammate[0], rcount, position);
        end;
      end;
    end;
  end;
  i1 := 0;
  for i := 0 to 5 do
  begin
    NewList[i] := -1;
  end;
  for i := 0 to 5 do
  begin
    if TeamList[i] >= 0 then
    begin
      NewList[i1] := TeamList[i];
      Inc(i1);
    end;
  end;
  for i := 0 to 5 do
  begin
    TeamList[i] := NewList[i];
  end;

end;

procedure ShowTeammateMenu(TeamListNum, RoleListNum: integer; rlist: psmallint; MaxCount, position: integer);
var
  x2, y2, x1, y1, i: integer;
  str, str2: WideString;
begin
  x1 := 120;
  x2 := 350;
  y1 := 35;
  y2 := 35;
  display_imgFromSurface(TEAMMATE_PIC, 0, 0);
  str := UTF8Decode(' 隊中人員');
  drawrectangle(x1 + 15, y1 - 5, 220, 160, 0, $FFFFFFFF, 40);
  drawShadowtext(@str[1], x1, y1, colcolor(255), colcolor(111));
  str := UTF8Decode(' 預備人員');
  drawrectangle(x2 + 15, y2 - 5, 240, 376, 0, $FFFFFFFF, 40);
  drawShadowtext(@str[1], x2, y2, colcolor(255), colcolor(111));
  drawrectangle(x1 + 15, y1 - 5 + 165, 220, 104, 0, $FFFFFFFF, 40);
  drawrectangle(x1 + 15, y1 - 5 + 165 + 108, 220, 104, 0, $FFFFFFFF, 40);

  for i := 1 to 5 do
  begin
    if teamlist[i] >= 0 then
    begin
      drawgbkShadowtext(@Rrole[teamlist[i]].Name[0], x1 + 5, i * 25 + y1, colcolor(0, $5), colcolor(0, $7));

      str2 := format('%2d', [Rrole[teamlist[i]].Level]);
      drawShadowtext(@str2[1], x1 + 175, i * 25 + y1, colcolor(0, $5), colcolor(0, $7));
      str2 := UTF8Decode(' 等級  ');
      drawShadowtext(@str2[1], x1 + 105, i * 25 + y1, colcolor(0, $5), colcolor(0, $7));
    end;
    if (position in [0, 2]) and (teamlist[TeamListNum] >= 0) and (i = teamlistnum) then
    begin
      drawgbkShadowtext(@Rrole[teamlist[i]].Name[0], x1 + 5, y1 + 170 - 5, colcolor(0, $5), colcolor(0, $7));
      UpdateHpMp(teamlist[i], x1 + 5, y1 + 170);
      str2 := format('%2d', [Rrole[teamlist[i]].Level]);
      drawShadowtext(@str2[1], x1 + 175, y1 + 170 - 5, colcolor(0, $5), colcolor(0, $7));
      str2 := UTF8Decode(' 等級  ');
      drawShadowtext(@str2[1], x1 + 105, y1 + 170 - 5, colcolor(0, $5), colcolor(0, $7));
    end;
  end;
  for i := 0 to 25 do
  begin
    if rlist^ >= 0 then
      drawgbkShadowtext(@Rrole[rlist^].Name[0], x2 + (i mod 2) * 100 + 5, ((i div 2) + 1) *
        25 + y2, colcolor(0, $5), colcolor(0, $7));
    //  UpdateHpMp(rlist^, x1 + 5, y1 +170+104);
    if (position in [1, 2]) and (rlist^ >= 0) and (i = Rolelistnum) then
    begin
      drawgbkShadowtext(@Rrole[rlist^].Name[0], x1 + 5, y1 + 170 - 5 + 110, colcolor(0, $5), colcolor(0, $7));
      UpdateHpMp(rlist^, x1 + 5, y1 + 170 + 110);
      str2 := format('%2d', [Rrole[rlist^].Level]);
      drawShadowtext(@str2[1], x1 + 105 + 70, y1 + 170 - 5 + 110, colcolor(0, $5), colcolor(0, $7));
      str2 := UTF8Decode(' 等級  ');
      drawShadowtext(@str2[1], x1 + 105, y1 + 170 - 5 + 110, colcolor(0, $5), colcolor(0, $7));
    end;
    Inc(rlist);
  end;
  if (position = 0) or (position = 2) then
    drawrectangle(x1 + 20, y1 + TeamListNum * 25, 210, 25, 0, $FFFFFFFF, 0);
  if (position = 1) or (position = 2) then
    drawrectangle(x2 + 20 + 100 * (RoleListNum mod 2), y2 + (1 + (RoleListNum div 2)) * 25, 100, 25, 0, $FFFFFF, 0);

  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
end;

procedure NewMenuItem;
var
  menu, max, menup: integer;
  //point似乎未使用, atlu为处于左上角的物品在列表中的序号, x, y为光标位置
  //col, row为总列数和行数
begin
  menu := 0;
  max := 5;
  setlength(menustring, 0);

  setlength(menustring, 6);
  setlength(menuengstring, 0);
  menustring[0] := UTF8Decode(' 全部物品');
  menustring[1] := UTF8Decode(' 劇情物品');
  menustring[2] := UTF8Decode(' 神兵寶甲');
  menustring[3] := UTF8Decode(' 武功秘笈');
  menustring[4] := UTF8Decode(' 靈丹妙藥');
  menustring[5] := UTF8Decode(' 傷人暗器');
  showNewItemMenu(menu);
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
  while SDL_WaitEvent(@event) >= 0 do
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
          showNewItemMenu(menu);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          menu := menu - 1;
          if menu < 0 then
            menu := max;
          showNewItemMenu(menu);
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
        end;
      end;

      SDL_KEYUP:
      begin
        if ((event.key.keysym.sym = sdlk_escape)) then
        begin
          ReDraw;
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          break;
        end;
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          if not MenuItem(menu) then break;
          //Redraw;
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          break;
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_right) then
        begin
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          break;
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        if (round(event.button.x / (RealScreen.w / screen.w)) >= 122) then
        begin
          if not MenuItem(menu) then break;
        end
        else if (round(event.button.x / (RealScreen.w / screen.w)) >= 15) and
          (round(event.button.x / (RealScreen.w / screen.w)) < 15 + 87) and
          (round(event.button.y / (RealScreen.h / screen.h)) >= 15) and
          (round(event.button.y / (RealScreen.h / screen.h)) < 132 + 6) then
        begin
          menup := menu;
          menu := (round(event.button.y / (RealScreen.h / screen.h)) - 17) div 22;
          if menu > max then menu := max;
          if menu < 0 then menu := 0;
          if menup <> menu then
          begin
            showNewItemMenu(menu);
            SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          end;
        end;

      end;
    end;
  end;
  //清空键盘键和鼠标键值, 避免影响其余部分
  event.key.keysym.sym := 0;
  event.button.button := 0;
  SDL_EnableKeyRepeat(30, (30 * GameSpeed) div 10);
end;

procedure showNewItemMenu(menu: integer);
var
  i, p, x, y, w, iamount, max: integer;
begin
  x := 15;
  y := 15;
  w := 87;
  SDL_EnableKeyRepeat(10, 100);
  //DrawMMap;
  max := 5;

  display_imgFromSurface(MENUITEM_PIC, 0, 0);
  DrawRectangle(x, y, w, max * 22 + 28, 0, colcolor(255), 30);
  for i := 0 to 5 do
    if i = menu then
    begin
      drawshadowtext(@menustring[i][1], x - 17, y + 2 + 22 * i, colcolor(0, $64), colcolor(0, $66));
    end
    else
    begin
      drawshadowtext(@menustring[i][1], x - 17, y + 2 + 22 * i, colcolor(0, $5), colcolor(0, $7));
    end;
  if menu = 0 then
    menu := 101;
  menu := menu - 1;
  iamount := ReadItemList(menu);
  showMenuItem(3, 6, 0, 0, 0);
end;

function SelectItemUser(inum: integer): smallint;
var
  menu, menup, x, y, w, h, i, len: integer;
  teammatelist: array of smallint;
begin
  menu := 0;
  len := 1;
  x := 223;
  y := 46;
  setlength(teammatelist, len);
  teammatelist[0] := 0;
  for i := 1 to Length(rrole) - 1 do
  begin
    if rrole[i].TeamState in [1, 2] then
    begin
      Inc(len);
      setlength(teammatelist, len);
      teammatelist[len - 1] := i;
    end;
  end;
  showSelectItemUser(x, y, inum, menu, len, @teammatelist[0]);
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
          menu := menu + 3;
          if menu > len - 1 then
            menu := 0;
          showSelectItemUser(x, y, inum, menu, len, @teammatelist[0]);
        end;
        if (event.key.keysym.sym = sdlk_up) or (event.key.keysym.sym = sdlk_kp8) then
        begin
          menu := menu - 3;
          if menu < 0 then
            menu := len - 1;
          showSelectItemUser(x, y, inum, menu, len, @teammatelist[0]);
        end;
        if (event.key.keysym.sym = sdlk_right) or (event.key.keysym.sym = sdlk_kp6) then
        begin
          menu := menu + 1;
          if menu > len - 1 then
            menu := 0;
          showSelectItemUser(x, y, inum, menu, len, @teammatelist[0]);
        end;
        if (event.key.keysym.sym = sdlk_left) or (event.key.keysym.sym = sdlk_kp4) then
        begin
          menu := menu - 1;
          if menu < 0 then
            menu := len - 1;
          showSelectItemUser(x, y, inum, menu, len, @teammatelist[0]);
        end;
      end;

      SDL_KEYUP:
      begin
        if ((event.key.keysym.sym = sdlk_escape)) then
        begin
          Result := -1;
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          break;
        end;
        if (event.key.keysym.sym = sdlk_return) or (event.key.keysym.sym = sdlk_space) then
        begin
          //Redraw;
          Result := teammatelist[menu];
          SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
          if ritem[inum].ItemType = 3 then
          begin
            if where <> 2 then
            begin
              Result := teammatelist[menu];
            end;
            if Result >= 0 then
            begin
              //redraw;
              EatOneItem(Result, inum);
              waitanykey();
              showSelectItemUser(x, y, inum, menu, len, @teammatelist[0]);
              instruct_32(inum, -1);
              if getitemcount(inum) <= 0 then
                break;
            end;
          end
          else
            break;
        end;
      end;
      SDL_MOUSEBUTTONUP:
      begin
        if (event.button.button = sdl_button_right) then
        begin
          Result := -1;
          break;
        end;
        if (event.button.button = sdl_button_left) then
        begin
          if menu in [0..len - 1] then
          begin
            Result := teammatelist[menu];

            if ritem[inum].ItemType = 3 then
            begin
              if where <> 2 then
              begin
                Result := teammatelist[menu];
              end;
              if Result >= 0 then
              begin
                //redraw;
                EatOneItem(Result, inum);
                waitanykey();
                showSelectItemUser(x, y, inum, menu, len, @teammatelist[0]);
                instruct_32(inum, -1);
                if getitemcount(inum) <= 0 then
                  break;
              end;
            end
            else
              break;
          end;
        end;
      end;
      SDL_MOUSEMOTION:
      begin
        if (round(event.button.x / (RealScreen.w / screen.w)) >= x) and
          (round(event.button.x / (RealScreen.w / screen.w)) < x + 300) and
          (round(event.button.y / (RealScreen.h / screen.h)) >= y) and
          (round(event.button.y / (RealScreen.h / screen.h)) < 8 * 23 + y) then
        begin
          menup := menu;
          menu := 3 * ((round(event.button.y / (RealScreen.h / screen.h)) - y) div 23) +
            ((round(event.button.x / (RealScreen.w / screen.w)) - x) div 100);
          if menu > len - 1 then menu := -1;
          if menu < 0 then menu := -1;

          if menup <> menu then
          begin
            showSelectItemUser(x, y, inum, menu, len, @teammatelist[0]);
          end;
        end;

      end;
    end;
  end;
  //清空键盘键和鼠标键值, 避免影响其余部分
  event.key.keysym.sym := 0;
  event.button.button := 0;
end;

procedure showSelectItemUser(x, y, inum, menu, max: integer; p: psmallint);
var
  setnum, i, c1, c2, j, len, newa, newd, news, a, d, s, addfist, addsword, addknife, addunusual, addhid: integer;
  attack, defend, speed, fist, sword, knife, unusual, hidden, med, medpoi, usepoi: WideString;
  attack1, defend1, speed1, fist1, sword1, knife1, unusual1, hidden1, med1, medpoi1, usepoi1: WideString;
  title, str: WideString;
  equip: array[0..3] of integer;
begin
  display_imgFromSurface(MENUITEM_PIC, 110, 0, 110, 0, 530, 440);
  drawrectangle(110 + 12, 16, 499, 405, 0, colcolor(255), 40);
  title := UTF8Decode('　　——————請選擇使用者——————');
  drawshadowtext(@title[1], 142, 21, colcolor(0, 5), colcolor(0, 7));
  for i := 0 to 3 do
    equip[i] := -1;
  for i := 0 to max - 1 do
  begin
    if i = menu then
    begin
      drawgbkshadowtext(@rrole[p^].Name[0], x + (i mod 3) * 100, y + (i div 3) * 23,
        colcolor(0, $64), colcolor(0, $66));
      drawheadpic(p^, x - 75, y + 290);
      UpdateHpMp(p^, x - 30, y + 212);
      med := UTF8Decode(' 醫療 ');
      medpoi := UTF8Decode(' 解毒 ');
      usepoi := UTF8Decode(' 用毒 ');
      fist := UTF8Decode(' 拳掌 ');
      sword := UTF8Decode(' 劍術 ');
      knife := UTF8Decode(' 刀法 ');
      Unusual := UTF8Decode(' 奇門 ');
      Hidden := UTF8Decode(' 暗器 ');
      attack := UTF8Decode(' 攻擊 ');
      defend := UTF8Decode(' 防禦 ');
      speed := UTF8Decode(' 輕功 ');

      med1 := format('%3d', [GetRoleMedcine(p^, True)]);
      medpoi1 := format('%3d', [GetRoleMedpoi(p^, True)]);
      usepoi1 := format('%3d', [GetRoleUsePoi(p^, True)]);
      fist1 := format('%3d', [GetRolefist(p^, True)]);
      sword1 := format('%3d', [GetRolesword(p^, True)]);
      knife1 := format('%3d', [GetRoleknife(p^, True)]);
      Unusual1 := format('%3d', [GetRoleUnusual(p^, True)]);
      Hidden1 := format('%3d', [GetRoleHidWeapon(p^, True)]);
      attack1 := UTF8Decode(' ');
      defend1 := UTF8Decode(' ');
      speed1 := UTF8Decode(' ');
      if ritem[inum].ItemType = 1 then
      begin
        med1 := format('%3d', [GetRoleMedcine(p^, True)]);
        medpoi1 := format('%3d', [GetRoleMedpoi(p^, True)]);
        usepoi1 := format('%3d', [GetRoleUsePoi(p^, True)]);
        fist1 := format('%3d', [GetRolefist(p^, True)]);
        sword1 := format('%3d', [GetRolesword(p^, True)]);
        knife1 := format('%3d', [GetRoleknife(p^, True)]);
        Unusual1 := format('%3d', [GetRoleUnusual(p^, True)]);
        Hidden1 := format('%3d', [GetRoleHidWeapon(p^, True)]);
        a := 0;
        d := 0;
        s := 0;
        newa := 0;
        newd := 0;
        news := 0;
        addsword := 0;
        addfist := 0;
        addknife := 0;
        addunusual := 0;
        addhid := 0;
        for j := 0 to length(rrole[p^].Equip) - 1 do
        begin
          if (ritem[inum].EquipType = j) then
          begin
            if rrole[p^].Equip[j] <> -1 then
            begin
              Inc(a, ritem[rrole[p^].Equip[j]].AddAttack);
              Inc(d, ritem[rrole[p^].Equip[j]].AddDefence);
              Inc(s, ritem[rrole[p^].Equip[j]].AddSpeed);
            end;
            Inc(newa, ritem[inum].AddAttack);
            Inc(newd, ritem[inum].AddDefence);
            Inc(news, ritem[inum].AddSpeed);
            Inc(addfist, ritem[inum].AddAttack);
            Inc(addknife, ritem[inum].AddDefence);
            Inc(addunusual, ritem[inum].AddDefence);
            Inc(addhid, ritem[inum].AddDefence);
            Inc(addsword, ritem[inum].AddSpeed);
            equip[j] := inum;
          end
          else if rrole[p^].Equip[j] <> -1 then
          begin
            Inc(a, ritem[rrole[p^].Equip[j]].AddAttack);
            Inc(d, ritem[rrole[p^].Equip[j]].AddDefence);
            Inc(s, ritem[rrole[p^].Equip[j]].AddSpeed);
            Inc(newa, ritem[rrole[p^].Equip[j]].AddAttack);
            Inc(newd, ritem[rrole[p^].Equip[j]].AddDefence);
            Inc(news, ritem[rrole[p^].Equip[j]].AddSpeed);
            Inc(addfist, ritem[rrole[p^].Equip[j]].AddAttack);
            Inc(addknife, ritem[rrole[p^].Equip[j]].AddDefence);
            Inc(addunusual, ritem[rrole[p^].Equip[j]].AddDefence);
            Inc(addhid, ritem[rrole[p^].Equip[j]].AddDefence);
            Inc(addsword, ritem[rrole[p^].Equip[j]].AddSpeed);
            equip[j] := rrole[p^].Equip[j];
          end;
        end;
        if CheckEquipSet(Equip[0], Equip[1], Equip[2], Equip[3]) = 5 then
        begin
          Inc(newa, 50);
          Inc(newd, -25);
          Inc(news, 30);
        end;
        if newa - a > 0 then
        begin
          attack1 := format('%3d +%d', [GetRoleAttack(p^, True), newa - a]);
          c1 := $14;
          c2 := $18;
        end
        else if newa - a = 0 then
        begin
          attack1 := format('%3d', [GetRoleAttack(p^, True)]);
          c1 := 5;
          c2 := 7;
        end
        else
        begin
          attack1 := format('%3d %d', [GetRoleAttack(p^, True), newa - a]);
          c1 := $30;
          c2 := $33;
        end;
        drawshadowtext(@attack1[1], x + 50 + 200 - 10, y + 234, colcolor(0, c1), colcolor(0, c2));

        if newd - d > 0 then
        begin
          defend1 := format('%3d +%d', [GetRoleDefence(p^, False), newd - d]);
          c1 := $14;
          c2 := $18;
        end
        else if newd - d = 0 then
        begin
          defend1 := format('%3d ', [GetRoleDefence(p^, True)]);
          c1 := 5;
          c2 := 7;
        end
        else
        begin
          defend1 := format('%3d %d', [GetRoleDefence(p^, True), newd - d]);
          c1 := $30;
          c2 := $33;
        end;
        drawshadowtext(@defend1[1], x + 50 + 200 - 10, y + 256, colcolor(0, c1), colcolor(0, c2));

        if news - s > 0 then
        begin
          speed1 := format('%3d +%d', [GetRoleSpeed(p^, True), news - s]);
          c1 := $14;
          c2 := $18;
        end
        else if news - s = 0 then
        begin
          speed1 := format('%3d ', [GetRoleSpeed(p^, True)]);
          c1 := 5;
          c2 := 7;
        end
        else
        begin
          speed1 := format('%3d %d', [GetRoleSpeed(p^, True), news - s]);
          c1 := $30;
          c2 := $33;
        end;
        drawshadowtext(@speed1[1], x + 50 + 200 - 10, y + 278, colcolor(0, c1), colcolor(0, c2));
      end
      else
      begin
        if ritem[inum].ItemType = 2 then
        begin
          attack1 := format('%3d', [GetRoleAttack(p^, False)]);
          defend1 := format('%3d', [GetRoleDefence(p^, False)]);
          speed1 := format('%3d', [GetRoleSpeed(p^, False)]);
          med1 := format('%3d', [GetRoleMedcine(p^, False)]);
          medpoi1 := format('%3d', [GetRoleMedpoi(p^, False)]);
          usepoi1 := format('%3d', [GetRoleUsePoi(p^, False)]);
          fist1 := format('%3d', [GetRolefist(p^, False)]);
          sword1 := format('%3d', [GetRolesword(p^, False)]);
          knife1 := format('%3d', [GetRoleknife(p^, False)]);
          Unusual1 := format('%3d', [GetRoleUnusual(p^, False)]);
          Hidden1 := format('%3d', [GetRoleHidWeapon(p^, False)]);
        end
        else
        begin
          attack1 := format('%3d', [GetRoleAttack(p^, True)]);
          defend1 := format('%3d', [GetRoleDefence(p^, True)]);
          speed1 := format('%3d', [GetRoleSpeed(p^, True)]);
          med1 := format('%3d', [GetRoleMedcine(p^, True)]);
          medpoi1 := format('%3d', [GetRoleMedpoi(p^, True)]);
          usepoi1 := format('%3d', [GetRoleUsePoi(p^, True)]);
          fist1 := format('%3d', [GetRolefist(p^, True)]);
          sword1 := format('%3d', [GetRolesword(p^, True)]);
          knife1 := format('%3d', [GetRoleknife(p^, True)]);
          Unusual1 := format('%3d', [GetRoleUnusual(p^, True)]);
          Hidden1 := format('%3d', [GetRoleHidWeapon(p^, True)]);
        end;
        drawshadowtext(@attack1[1], x + 50 + 200 - 10, y + 234, colcolor(0, 5), colcolor(0, 7));
        drawshadowtext(@defend1[1], x + 50 + 200 - 10, y + 256, colcolor(0, 5), colcolor(0, 7));
        drawshadowtext(@speed1[1], x + 50 + 200 - 10, y + 278, colcolor(0, 5), colcolor(0, 7));
      end;
      drawshadowtext(@attack[1], x + 200 - 10, y + 234, colcolor(0, 5), colcolor(0, 7));
      drawshadowtext(@defend[1], x + 200 - 10, y + 256, colcolor(0, 5), colcolor(0, 7));
      drawshadowtext(@speed[1], x + 200 - 10, y + 278, colcolor(0, 5), colcolor(0, 7));
      drawshadowtext(@med[1], x - 85 - 10, y + 300, colcolor(0, 5), colcolor(0, 7));
      drawshadowtext(@medpoi[1], x + 10 - 10, y + 300, colcolor(0, 5), colcolor(0, 7));
      drawshadowtext(@usepoi[1], x + 105 - 10, y + 300, colcolor(0, 5), colcolor(0, 7));
      drawshadowtext(@hidden[1], x + 200 - 10, y + 300, colcolor(0, 5), colcolor(0, 7));
      drawshadowtext(@fist[1], x - 85 - 10, y + 322, colcolor(0, 5), colcolor(0, 7));
      drawshadowtext(@sword[1], x + 10 - 10, y + 322, colcolor(0, 5), colcolor(0, 7));
      drawshadowtext(@knife[1], x + 105 - 10, y + 322, colcolor(0, 5), colcolor(0, 7));
      drawshadowtext(@unusual[1], x + 200 - 10, y + 322, colcolor(0, 5), colcolor(0, 7));

      drawshadowtext(@med1[1], x + 50 - 85 - 10, y + 300, colcolor(0, 5), colcolor(0, 7));
      drawshadowtext(@medpoi1[1], x + 50 + 10 - 10, y + 300, colcolor(0, 5), colcolor(0, 7));
      drawshadowtext(@usepoi1[1], x + 50 + 105 - 10, y + 300, colcolor(0, 5), colcolor(0, 7));
      drawshadowtext(@hidden1[1], x + 50 + 200 - 10, y + 300, colcolor(0, 5), colcolor(0, 7));
      drawshadowtext(@fist1[1], x + 50 - 85 - 10, y + 322, colcolor(0, 5), colcolor(0, 7));
      drawshadowtext(@sword1[1], x + 50 + 10 - 10, y + 322, colcolor(0, 5), colcolor(0, 7));
      drawshadowtext(@knife1[1], x + 50 + 105 - 10, y + 322, colcolor(0, 5), colcolor(0, 7));
      drawshadowtext(@unusual1[1], x + 50 + 200 - 10, y + 322, colcolor(0, 5), colcolor(0, 7));
      setnum := CheckEquipSet(Equip[0], Equip[1], Equip[2], Equip[3]);
      if setnum > 0 then
      begin
        case setnum of
          1:
          begin
            //str := GBKtoUnicode('套裝獎勵：攻擊距離加1');
            str := UTF8Decode('套裝獎勵：攻擊距離加1');
            drawshadowtext(@str[1], x - 85 - 10, y + 344, colcolor(0, 5), colcolor(0, 7));
          end;
          2:
          begin
            //str := GBKtoUnicode('套裝獎勵：資質上升至100 ');
            str := UTF8Decode('套裝獎勵：資質上升至100 ');
            drawshadowtext(@str[1], x - 85 - 10, y + 344, colcolor(0, 5), colcolor(0, 7));
          end;
          3:
          begin
            //str := GBKtoUnicode('套裝獎勵：攻擊100%內傷');
            str := UTF8Decode('套裝獎勵：攻擊100%內傷');
            drawshadowtext(@str[1], x - 85 - 10, y + 344, colcolor(0, 5), colcolor(0, 7));
          end;
          4:
          begin
            //str := GBKtoUnicode('套裝獎勵：負面狀態免疫');
            str := UTF8Decode('套裝獎勵：負面狀態免疫');
            drawshadowtext(@str[1], x - 85 - 10, y + 344, colcolor(0, 5), colcolor(0, 7));
          end;
          5:
          begin
            //str := GBKtoUnicode('套裝獎勵：攻擊加50，防禦減25，輕功加30');
            str := UTF8Decode('套裝獎勵：攻擊加50，防禦減25，輕功加30');
            drawshadowtext(@str[1], x - 85 - 10, y + 344, colcolor(0, 5), colcolor(0, 7));
          end;
        end;
      end;
    end
    else if CanEquip(p^, inum) or (ritem[inum].ItemType = 3) then
      drawgbkshadowtext(@rrole[p^].Name[0], x + (i mod 3) * 100, y + (i div 3) * 23, colcolor(0, $5), colcolor(0, $7))
    else
      drawgbkshadowtext(@rrole[p^].Name[0], x + (i mod 3) * 100, y + (i div 3) * 23,
        colcolor(0, $66), colcolor(0, $68));
    Inc(p);
  end;
  SDL_UpdateRect2(screen, 110, 0, 530, 440);
end;



procedure UpdateBattleScene(xs, ys, oldPic, newpic: integer);
var
  i1, i2, x, y: integer;
  num, offset: integer;
  xp, yp, xp1, yp1, xp2, yp2, w2, w1, h1, h2, w, h: smallint;
begin

  x := -xs * 18 + ys * 18 + 1151;
  y := xs * 9 + ys * 9 + 9;

  oldpic := oldpic div 2;
  newpic := newpic div 2;
  if oldpic > 0 then
  begin
    offset := SIdx[oldpic - 1];
    xp1 := x - (SPic[offset + 4] + 256 * SPic[offset + 5]);
    yp1 := y - (SPic[offset + 6] + 256 * SPic[offset + 7]);
    w1 := (SPic[offset] + 256 * SPic[offset + 1]);
    h1 := (SPic[offset + 2] + 256 * SPic[offset + 3]);
    //  InitialSPic(oldpic , x, y,  xp, yp, w, h, 1);
  end
  else
  begin
    xp1 := x;
    yp1 := y;
    w1 := 0;
    h1 := 0;
  end;

  if newpic > 0 then
  begin
    offset := SIdx[newpic - 1];
    xp2 := x - (SPic[offset + 4] + 256 * SPic[offset + 5]);
    yp2 := y - (SPic[offset + 6] + 256 * SPic[offset + 7]);
    w2 := (SPic[offset] + 256 * SPic[offset + 1]);
    h2 := (SPic[offset + 2] + 256 * SPic[offset + 3]);
    //  InitialSPic(oldpic , x, y,  xp, yp, w, h, 1);
  end
  else
  begin
    xp2 := x;
    yp2 := y;
    w2 := 0;
    h2 := 0;
  end;
  xp := min(xp2, xp1) - 1;
  yp := min(yp2, yp1) - 1;
  w := max(xp2 + w2, xp1 + w1) + 3 - xp;
  h := max(yp2 + h2, yp1 + h1) + 3 - yp;


  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      x := -i1 * 18 + i2 * 18 + 1151;
      y := i1 * 9 + i2 * 9 + 9;
      if BField[0, i1, i2] > 0 then
        InitialBPic(BField[0, i1, i2] div 2, x, y, xp, yp, w, h, 0);
      if (BField[1, i1, i2] > 0) then
        InitialBPic(BField[1, i1, i2] div 2, x, y, xp, yp, w, h, 0);
    end;
end;

procedure Moveman(x1, y1, x2, y2: integer);
var
  s, i, i1, i2, a, tempx, tx1, tx2, ty1, ty2, tempy: integer;
  Xinc, Yinc, dir: array[1..4] of integer;
begin
  if Fway[x2, y2] > 0 then
  begin
    Xinc[1] := 0; Xinc[2] := 1; Xinc[3] := -1; Xinc[4] := 0;
    Yinc[1] := -1; Yinc[2] := 0; Yinc[3] := 0; Yinc[4] := 1;
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
  totalgrid := 0;
  Xlist[totalgrid] := x1;
  Ylist[totalgrid] := y1;
  steplist[totalgrid] := 0;
  totalgrid := totalgrid + 1;
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
            Bgrid[i] := 3
          else if Fway[nextX, nextY] >= 0 then
            Bgrid[i] := 2
          else if not canwalkinscene(cury, curx, nexty, nextx) then
            Bgrid[i] := 1
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
      if ((inship = 1) and (Bgrid[i] = 5)) or (((Bgrid[i] = 0) or (Bgrid[i] = 4)) and (inship = 0)) then
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
    if (where = 0) and (curX - MX > 22) and (curY - My > 22) then break;
  end;
end;

//主地图上画云

procedure DrawCPic(num, px, py, shadow, alpha: integer; mixColor: Uint32; mixAlpha: integer);
var
  Area: TRect;
begin
  Area.x := 0;
  Area.y := 0;
  Area.w := screen.w;
  Area.h := screen.h;
  DrawRLE8Pic3(@Col[0][0], num, px, py, @CIdx[0], @CPic[0], @Area, nil, 0, 0, 0, shadow, alpha,
    nil, nil, 0, 0, 0, 128, mixColor, mixAlpha);

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

//调色板变化, 贴图闪烁效果

procedure ChangeCol;
var
  i, a, b: integer;
  temp: array[0..2] of byte;
begin

  a := $E7 * 3;
  temp[0] := ACol[a];
  temp[1] := ACol[a + 1];
  temp[2] := ACol[a + 2];

  for i := $E7 downto $E1 do
  begin
    b := i * 3;
    a := (i - 1) * 3;
    ACol[b] := ACol[a];
    ACol[b + 1] := ACol[a + 1];
    ACol[b + 2] := ACol[a + 2];
  end;

  b := $E0 * 3;
  ACol[b] := temp[0];
  ACol[b + 1] := temp[1];
  ACol[b + 2] := temp[2];

  a := $FC * 3;
  temp[0] := ACol[a];
  temp[1] := ACol[a + 1];
  temp[2] := ACol[a + 2];

  for i := $FC downto $F5 do
  begin
    b := i * 3;
    a := (i - 1) * 3;
    ACol[b] := ACol[a];
    ACol[b + 1] := ACol[a + 1];
    ACol[b + 2] := ACol[a + 2];
  end;

  b := $F4 * 3;
  ACol[b] := temp[0];
  ACol[b + 1] := temp[1];
  ACol[b + 2] := temp[2];

end;

//这是改写的绘制RLE8图片程序, 增加了选调色板, 遮挡控制, 亮度, 半透明, 混合色等
//colorPanel: Pchar; 调色板的指针. 某些情况下需要使用静态调色板, 避免静态图跟随水的效果
//num, px, py: integer; 图片的编号和位置
//Pidx: Pinteger; Ppic: PByte; 图片的索引和内容的资源所在地
//RectArea: Pchar; 画图的范围, 所指向地址应为连续4个integer, 表示一个矩形, 仅图片的部分或全部会出现在这个矩形内才画
//Image: PChar; widthI, heightI, sizeI: integer; 映像的位置, 尺寸, 每单位长度. 如果Img不为空, 则会将图画到这个镜像上, 否则画到屏幕
//shadow, alpha: integer; 图片的暗度和透明度, 仅在画到屏幕上时有效
//BlockImageW: PChar; 大小与场景和战场映像相同. 如果此地址不为空, 则会记录该像素的场景深度depth, 用于遮挡计算.
//BlockScreenR: PChar; widthR, heightR, sizeR: integer; 该映像应该与屏幕像素数相同, 保存屏幕上每一点的深度值
//depth: integer; 所画物件的深度, 即场景坐标 x + y, 深度高的物件会遮挡深度低的.
//当BlockImageW不为空时, 将该值写入BlockImageW, 如果该值超出范围(0~128), 会根据图片的y坐标计算一个,
//但是需注意计算值在场景内包含高度的情况下是不准确的.
//当Image为空, 即画到屏幕上时, 同时BlockScreenR不为空, 如果所绘像素的已有深度大于该值, 则按照alpha绘制该像素
//即该值起作用的机会有两种: Image不为空(到映像), 且BlockImageW不为空; 或者Image为空(到屏幕), 且BlockScreenR不为空.
//如果在画到屏幕时避免该值起作用, 可以设为128, 这是深度理论上的最大值(实际达不到)
//MixColor: Uint32; MixAlpha: integer 图片的混合颜色和混合度, 仅在画到屏幕上时有效

procedure DrawRLE8Pic3(colorPanel: PChar; num, px, py: integer; Pidx: Pinteger; Ppic: PByte;
  RectArea: PChar; Image: PChar; widthI, heightI, sizeI: integer; shadow, alpha: integer;
  BlockImageW: PChar; BlockScreenR: PChar; widthR, heightR, sizeR: integer; depth: integer;
  MixColor: Uint32; MixAlpha: integer);
var
  w, h, xs, ys: smallint;
  offset, length, p, isAlpha, lenInt: integer;
  l, l1, ix, iy, pixdepth: integer;
  pix, colorin: Uint32;
  pix1, pix2, pix3, pix4, color1, color2, color3, color4: byte;
begin
  if num = 0 then
    offset := 0
  else
  begin
    Inc(Pidx, num - 1);
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
  pixdepth := 0;

  lenInt := sizeof(integer);

  if (w > 1) and (h > 1) and (px - xs + w >= pint(RectArea)^) and (px - xs < pint(RectArea)^
    + pint(RectArea + lenInt * 2)^) and (py - ys + h >= pint(RectArea + lenInt)^) and
    (py - ys < pint(RectArea + lenInt)^ + pint(RectArea + lenInt * 3)^) then
  begin
    for iy := 1 to h do
    begin
      l := Ppic^;
      Inc(Ppic, 1);
      w := 1;
      p := 0;
      for ix := 1 to l do
      begin
        l1 := Ppic^;
        Inc(Ppic);
        if p = 0 then
        begin
          w := w + l1;
          p := 1;
        end
        else if p = 1 then
        begin
          p := 2 + l1;
        end
        else if p > 2 then
        begin
          p := p - 1;
          if (w - xs + px >= pint(RectArea)^) and (iy - ys + py >= pint(RectArea + lenInt)^) and
            (w - xs + px < pint(RectArea)^ + pint(RectArea + lenInt * 2)^) and
            (iy - ys + py < pint(RectArea + lenInt)^ + pint(RectArea + lenInt * 3)^) then
          begin
            if image = nil then
            begin
              pix := sdl_maprgb(screen.format, puint8(colorPanel + l1 * 3)^ * (4 + shadow),
                puint8(colorPanel + l1 * 3 + 1)^ * (4 + shadow), puint8(colorPanel + l1 * 3 + 2)^ * (4 + shadow));
              if (alpha <> 0) then
              begin
                if (BlockScreenR = nil) then
                begin
                  isAlpha := 1;
                end
                else
                begin
                  if ((w - xs + px) < widthR) and ((iy - ys + py) < heightR) then
                  begin
                    pixdepth := pint(BlockScreenR + ((w - xs + px) * heightR + (iy - ys + py)) * sizeR)^;
                    if pixdepth > depth then
                    begin
                      isAlpha := 1;
                    end
                    else
                      isAlpha := 0;
                  end;
                end;
                if (isAlpha = 1) and (Alpha < 100) then
                begin
                  colorin := getpixel(screen, w - xs + px, iy - ys + py);
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
              end;
              if mixAlpha <> 0 then
              begin
                colorin := MixColor;
                pix1 := pix and $FF;
                color1 := colorin and $FF;
                pix2 := pix shr 8 and $FF;
                color2 := colorin shr 8 and $FF;
                pix3 := pix shr 16 and $FF;
                color3 := colorin shr 16 and $FF;
                pix4 := pix shr 24 and $FF;
                color4 := colorin shr 24 and $FF;
                pix1 := (mixAlpha * color1 + (100 - mixAlpha) * pix1) div 100;
                pix2 := (mixAlpha * color2 + (100 - mixAlpha) * pix2) div 100;
                pix3 := (mixAlpha * color3 + (100 - mixAlpha) * pix3) div 100;
                pix4 := (mixAlpha * color4 + (100 - mixAlpha) * pix4) div 100;
                pix := pix1 + pix2 shl 8 + pix3 shl 16 + pix4 shl 24;
              end;
              if (Alpha < 100) or (pixdepth <= depth) then
                putpixel(screen, w - xs + px, iy - ys + py, pix);
            end
            else
            begin
              if ((w - xs + px) < widthI) and ((iy - ys + py) < heightI) then
              begin
                if (BlockImageW <> nil) then
                begin
                  if (depth < 0) or (depth > 128) then
                    depth := py div 9 - 1;
                  Pint(BlockImageW + ((w - xs + px) * heightI + (iy - ys + py)) * sizeI)^ := depth;
                end;
                Pint(image + ((w - xs + px) * heightI + (iy - ys + py)) * sizeI)^ :=
                  sdl_maprgb(screen.format, puint8(colorPanel + l1 * 3)^ * (4 + shadow),
                  puint8(colorPanel + l1 * 3 + 1)^ * (4 + shadow), puint8(colorPanel + l1 * 3 + 2)^ * (4 + shadow));
              end;
            end;
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


procedure SDL_UpdateRect2(scr1: PSDL_Surface; x, y, w, h: integer);
var
  realx, realy, realw, realh, ZoomType: integer;
  tempscr: Psdl_surface;
  now, Next: Uint32;
  dest: TSDL_Rect;
  TextureID: GLUint;
begin
  dest.x := x;
  dest.y := y;
  dest.w := w;
  dest.h := h;
  SDL_BlitSurface(screen, @dest, prescreen, @dest);
  if GLHR = 1 then
  begin
    glGenTextures(1, @TextureID);
    glBindTexture(GL_TEXTURE_2D, TextureID);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, screen.w, screen.h, 0, GL_BGRA, GL_UNSIGNED_BYTE, prescreen.pixels);

    if SMOOTH = 1 then
    begin
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    end
    else
    begin
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
      glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    end;

    glENABLE(GL_TEXTURE_2D);
    glBEGIN(GL_QUADS);
    glTexCoord2f(0.0, 0.0);
    glVertex3f(-1.0, 1.0, 0.0);
    glTexCoord2f(1.0, 0.0);
    glVertex3f(1.0, 1.0, 0.0);
    glTexCoord2f(1.0, 1.0);
    glVertex3f(1.0, -1.0, 0.0);
    glTexCoord2f(0.0, 1.0);
    glVertex3f(-1.0, -1.0, 0.0);
    glEND;
    glDISABLE(GL_TEXTURE_2D);
    SDL_GL_SwapBuffers;
    glDeleteTextures(1, @TextureID);
  end
  else
  begin
    {realx := x * RealScreen.w div scr1.w;
    realw := (x + w + 2) * RealScreen.w div scr1.w - realx;
    realy := y * RealScreen.h div scr1.h;
    realh := (y + h + 2) * RealScreen.h div scr1.h - realy;
    if realw + realx > RealScreen.w then realw := RealScreen.w - realx;
    if realh + realy > RealScreen.h then realh := RealScreen.h - realy;}

    tempscr := sdl_gfx.zoomSurface(prescreen, RealScreen.w / screen.w, RealScreen.h / screen.h, SMOOTH);
    SDL_BlitSurface(tempscr, nil, RealScreen, nil);
    SDL_UpdateRect(RealScreen, 0, 0, RealScreen.w, RealScreen.h);
    sdl_freesurface(tempscr);
  end;
end;


procedure SDL_GetMouseState2(var x, y: integer);
var
  tempx, tempy: integer;
begin
  SDL_GetMouseState(tempx, tempy);
  x := tempx * screen.w div RealScreen.w;
  y := tempy * screen.h div RealScreen.h;
end;

procedure ResizeWindow(w, h: integer);
begin
  RealScreen := SDL_SetVideoMode(w, h, 32, ScreenFlag);
  event.type_ := 0;
  SDL_UpdateRect2(Screen, 0, 0, screen.w, screen.h);
end;

procedure SwitchFullscreen;
begin
  fullscreen := 1 - fullscreen;
  if fullscreen = 0 then
  begin
    RealScreen := SDL_SetVideoMode(RESOLUTIONX, RESOLUTIONY, 32, ScreenFlag);
  end
  else
  begin
    realscreen := SDL_SetVideoMode(Center_X * 2, Center_Y * 2, 32, ScreenFlag or SDL_FULLSCREEN);
  end;

end;

end.
