unit kys_engine;

//{$MODE Delphi}

interface

uses
  SysUtils,
{$IFDEF fpc}
  LMessages, LConvEncoding, LCLType, LCLIntf, FileUtil,
{$ELSE}
  Windows,
{$ENDIF}
  Math, Dialogs,
  SDL_TTF, SDL_mixer, SDL_image, SDL_gfx, SDL,
  glext, gl,
  bassmidi, bass,
  ziputils, unzip,
  kys_main;

//音频子程
procedure InitialMusic;
procedure PlayMP3(MusicNum, times: integer); overload;
procedure PlayMP3(filename: PChar; times: integer); overload;
procedure StopMP3;
procedure PlaySoundE(SoundNum, times: integer); overload;
procedure PlaySoundE(SoundNum: integer); overload;
procedure PlaySoundE(SoundNum, times, x, y, z: integer); overload;
//procedure PlaySoundE(filename: pchar; times: integer); overload;
procedure PlaySoundA(SoundNum, times: integer);

//基本绘图子程
function getpixel(surface: PSDL_Surface; x: integer; y: integer): Uint32;
procedure putpixel(surface_: PSDL_Surface; x: integer; y: integer; pixel: Uint32);
procedure drawscreenpixel(x, y: integer; color: Uint32);
procedure display_bmp(file_name: PChar; x, y: integer);
procedure display_img(file_name: PChar; x, y: integer);
function ColColor(num: byte): Uint32;

function LoadSurfaceFromFile(filename: string): PSDL_Surface;
function LoadSurfaceFromZIPFile(zipFile: unzFile; filename: string): PSDL_Surface;

//画RLE8图片的子程
function JudgeInScreen(px, py, w, h, xs, ys: integer): boolean; overload;
function JudgeInScreen(px, py, w, h, xs, ys, xx, yy, xw, yh: integer): boolean; overload;
procedure DrawRLE8Pic(colorPanel: PChar; num, px, py: integer; Pidx: Pinteger; Ppic: PByte;
  RectArea: PChar; Image: PSDL_Surface; widthI, heightI, sizeI: integer; shadow: integer); overload;
procedure DrawRLE8Pic(colorPanel: PChar; num, px, py: integer; Pidx: Pinteger; Ppic: PByte;
  RectArea: PChar; Image: PSDL_Surface; widthI, heightI, sizeI: integer; shadow, alpha: integer); overload;
procedure DrawRLE8Pic(colorPanel: PChar; num, px, py: integer; Pidx: Pinteger; Ppic: PByte;
  RectArea: PChar; Image: PSDL_Surface; widthI, heightI, sizeI: integer; shadow, alpha: integer;
  BlockImageW: PChar; BlockPosition: PChar; widthW, heightW, sizeW: integer; depth: integer;
  mixColor: Uint32; mixAlpha: integer); overload;
function GetPositionOnScreen(x, y, CenterX, CenterY: integer): TPosition;
procedure DrawTitlePic(imgnum, px, py: integer);
procedure DrawMPic(num, px, py: integer);
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

//显示文字的子程
function Big5ToUnicode(str: PChar): WideString;
function UnicodeToBig5(str: PWideChar): string;
procedure DrawText(sur: PSDL_Surface; word: PUint16; x_pos, y_pos: integer; color: Uint32);
procedure DrawEngText(sur: PSDL_Surface; word: PUint16; x_pos, y_pos: integer; color: Uint32);
procedure DrawShadowText(sur: PSDL_Surface; word: PUint16; x_pos, y_pos: integer; color1, color2: Uint32);
procedure DrawEngShadowText(sur: PSDL_Surface; word: PUint16; x_pos, y_pos: integer; color1, color2: Uint32);
procedure DrawBig5Text(sur: PSDL_Surface; str: PChar; x_pos, y_pos: integer; color: Uint32);
procedure DrawBig5ShadowText(sur: PSDL_Surface; word: PChar; x_pos, y_pos: integer; color1, color2: Uint32);
procedure DrawTextWithRect(sur: PSDL_Surface; word: puint16; x, y, w: integer; color1, color2: uint32);
procedure DrawRectangle(sur: PSDL_Surface; x, y, w, h: integer; colorin, colorframe: Uint32; alpha: integer);
procedure DrawRectangleWithoutFrame(sur: PSDL_Surface; x, y, w, h: integer; colorin: Uint32; alpha: integer);

//绘制整个屏幕的子程
procedure Redraw(WriteFresh: integer = 0);
procedure WriteFreshScreen(x, y, w, h: integer);
procedure ReadFreshScreen(x, y, w, h: integer);
procedure DrawMMap;
procedure DrawScence;
procedure DrawScenceWithoutRole(x, y: integer);
procedure DrawRoleOnScence(x, y: integer);
procedure InitialScence(); overload;
procedure InitialScence(Visible: integer); overload;
procedure InitialScenceOnePosition(i1, i2, x1, y1, w, h, depth, temp: integer);
procedure UpdateScence(xs, ys: integer);
procedure LoadScencePart(x, y: integer);
procedure DrawWholeBField;
procedure DrawBfieldWithoutRole(x, y: integer);
procedure DrawRoleOnBfield(x, y: integer; MixColor: Uint32 = 0; MixAlpha: integer = 0);
procedure InitialWholeBField;
procedure InitialBFieldPosition(i1, i2, depth: integer);
procedure LoadBfieldPart(x, y: integer);
procedure LoadBFieldPart2(x, y, alpha: integer);
procedure DrawBFieldWithCursor(step: integer);
procedure DrawBFieldWithEft(Epicnum: integer); overload;
procedure DrawBFieldWithEft(Epicnum, beginpic, endpic, bnum: integer; MixColor: Uint32); overload;
procedure DrawBFieldWithEft(Epicnum, beginpic, endpic, curlevel, bnum: integer; MixColor: Uint32); overload;
procedure DrawBFieldWithAction(bnum, Apicnum: integer);

procedure DrawClouds;

procedure ChangeCol;

//PNG贴图相关的子程
procedure DrawPngTile(PNGIndex: TPNGIndex; FrameNum: integer; scr: PSDL_Surface; px, py: integer); overload;
procedure DrawPngTile(PNGIndex: TPNGIndex; FrameNum: integer; scr: PSDL_Surface; px, py: integer; shadow, alpha: integer; MixColor: Uint32; MixAlpha: integer); overload;
procedure DrawPngTile(PNGIndex: TPNGIndex; FrameNum: integer; scr: PSDL_Surface; px, py: integer; shadow, alpha: integer; MixColor: Uint32; MixAlpha: integer;
  depth: integer; BlockImgR: pchar; width, height, size, leftupx, leftupy: integer); overload;
procedure SetPngTileBlock(PNGIndex: TPNGIndex; px, py, depth: integer; BlockImageW: pchar; width, height, size: integer);

procedure SDL_UpdateRect2(scr1: PSDL_Surface; x, y, w, h: integer);
procedure SDL_GetMouseState2(var x, y: integer);
procedure ResizeWindow(w, h: integer);
procedure SwitchFullScreen;
procedure QuitConfirm;
procedure CheckBasicEvent;

{$IFDEF fpc}

{$ELSE}
function FileExistsUTF8(filename: PChar): boolean; overload;
function FileExistsUTF8(filename: string): boolean; overload;
//function UTF8Decode(str: widestring): widestring;
{$ENDIF}

implementation

uses kys_battle;

procedure InitialMusic;
var
  i: integer;
  str: string;
  sf: BASS_MIDI_FONT;
  Flag: longword;
begin
  BASS_Set3DFactors(1, 0, 0);
  sf.font := BASS_MIDI_FontInit(PChar(AppPath + 'music/mid.sf2'), 0);
  BASS_MIDI_StreamSetFonts(0, sf, 1);
  sf.preset := -1; // use all presets
  sf.bank := 0;
  Flag := 0;
  if SOUND3D = 1 then
    Flag := BASS_SAMPLE_3D or Flag;

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
    if (MusicNum in [Low(Music)..High(Music)]) and (VOLUME > 0) then
      if Music[MusicNum] <> 0 then
      begin
        //BASS_ChannelSlideAttribute(Music[nowmusic], BASS_ATTRIB_VOL, 0, 1000);
        if nowmusic in [Low(Music)..High(Music)] then
        begin
          BASS_ChannelStop(Music[nowmusic]);
          BASS_ChannelSetPosition(Music[nowmusic], 0, BASS_POS_BYTE);
        end;
        BASS_ChannelSetAttribute(Music[MusicNum], BASS_ATTRIB_VOL, VOLUME / 100.0);
        if SOUND3D = 1 then
        begin
          //BASS_SetEAXParameters(EAX_ENVIRONMENT_UNDERWATER, -1, 0, 0);
          BASS_Apply3D();
        end;

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

procedure PlayMP3(filename: PChar; times: integer); overload;
begin
  //if fileexists(filename) then
  //begin
  //Music := Mix_LoadMUS(filename);
  //Mix_volumemusic(MIX_MAX_VOLUME div 3);
  //Mix_PlayMusic(music, times);
  //end;

end;

//停止当前播放的音乐

procedure StopMP3;
begin
  {  Mix_HaltMusic;}

end;

//播放wav音效

procedure PlaySoundE(SoundNum, times: integer); overload;
var
  ch: HCHANNEL;
  repeatable: boolean;
begin
  if times = -1 then
    repeatable := True
  else
    repeatable := False;
  if (SoundNum in [Low(Esound)..High(Esound)]) and (VOLUME > 0) then
    if Esound[SoundNum] <> 0 then
    begin
      //Mix_VolumeChunk(Esound[SoundNum], Volume);
      //Mix_PlayChannel(-1, Esound[SoundNum], 0);
      BASS_SampleStop(Esound[soundnum]);
      ch := BASS_SampleGetChannel(Esound[soundnum], False);
      BASS_ChannelSetAttribute(ch, BASS_ATTRIB_VOL, VOLUMEWAV / 100.0);
      if repeatable then
        BASS_ChannelFlags(ch, BASS_SAMPLE_LOOP, BASS_SAMPLE_LOOP)
      else
        BASS_ChannelFlags(ch, 0, BASS_SAMPLE_LOOP);
      BASS_ChannelPlay(ch, repeatable);
    end;

end;

procedure PlaySoundE(SoundNum: integer); overload;
begin
  PlaySoundE(Soundnum, 0);

end;

procedure PlaySoundE(SoundNum, times, x, y, z: integer); overload;
var
  ch: HCHANNEL;
  repeatable: boolean;
  pos, posvec, posvel: BASS_3DVECTOR;
  //音源的位置, 向量, 速度
  //p: PSource;
begin
  if times = -1 then
    repeatable := True
  else
    repeatable := False;

  if (SoundNum in [Low(Esound)..High(Esound)]) and (VOLUMEWAV > 0) then
    if Esound[SoundNum] <> 0 then
    begin
      //Mix_VolumeChunk(Esound[SoundNum], Volume);
      //Mix_PlayChannel(-1, Esound[SoundNum], 0);
      BASS_SampleStop(Esound[soundnum]);
      ch := BASS_SampleGetChannel(Esound[soundnum], False);
      //BASS_ChannelSet3DAttributes(ch, BASS_3DMODE_RELATIVE, -1, -1, -1, -1, -1);
      if ch = 0 then
        ShowMessage(IntToStr(BASS_ErrorGetCode));
      if SOUND3D = 1 then
      begin
        pos.x := x * 100;
        pos.y := y * 100;
        pos.z := z * 100;
        posvec.x := x;
        posvec.y := y;
        posvec.z := z;
        posvel.x := -x * 100;
        posvel.y := -y * 100;
        posvel.z := -z * 100;
        BASS_ChannelSet3DPosition(ch, pos, posvec, posvel);
        BASS_Apply3D();
      end;
      BASS_ChannelSetAttribute(ch, BASS_ATTRIB_VOL, VOLUMEWAV / 100.0);
      if repeatable then
        BASS_ChannelFlags(ch, BASS_SAMPLE_LOOP, BASS_SAMPLE_LOOP)
      else
        BASS_ChannelFlags(ch, 0, BASS_SAMPLE_LOOP);
      BASS_ChannelPlay(ch, repeatable);
      //BASS_Apply3D();
    end;

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
  if (SoundNum in [Low(Asound)..High(Asound)]) and (VOLUMEWAV > 0) then
    if Asound[SoundNum] <> 0 then
    begin
      //Mix_VolumeChunk(Esound[SoundNum], Volume);
      //Mix_PlayChannel(-1, Esound[SoundNum], 0);
      BASS_SampleStop(Esound[soundnum]);
      ch := BASS_SampleGetChannel(Asound[soundnum], False);
      BASS_ChannelSetAttribute(ch, BASS_ATTRIB_VOL, VOLUMEWAV / 100.0);
      if repeatable then
        BASS_ChannelFlags(ch, BASS_SAMPLE_LOOP, BASS_SAMPLE_LOOP)
      else
        BASS_ChannelFlags(ch, 0, BASS_SAMPLE_LOOP);
      BASS_ChannelPlay(ch, repeatable);
    end;

end;


{procedure InitialMusic;
var
  i: integer;
  str: string;
begin
  for i := 0 to 23 do
  begin
    str := AppPath + 'music/' + inttostr(i) + '.mid';
    if FileExistsUTF8(pchar(str)) then
    begin
      Music[i] := Mix_LoadMUS(pchar(str));
    end
    else
      Music[i] := nil;
  end;
  for i := 0 to 52 do
  begin
    str := AppPath + formatfloat('sound/e00', i) + '.wav';
    if FileExistsUTF8(pchar(str)) then
      ESound[i] := Mix_LoadWav(pchar(str))
    else
      ESound[i] := nil;
  end;
  for i := 0 to 24 do
  begin
    str := AppPath + formatfloat('sound/atk00', i) + '.wav';
    if FileExistsUTF8(pchar(str)) then
      ASound[i] := Mix_LoadWav(pchar(str))
    else
      ASound[i] := nil;
  end;

end;



//播放mp3音乐

procedure PlayMP3(MusicNum, times: integer); overload;
begin
  if MusicNum in [Low(Music)..High(Music)] then
  begin

    if Music[MusicNum] <> nil then
    begin
      Mix_PlayMusic(Music[MusicNum], times);
    end;
  end;

end;

procedure PlayMP3(filename: pchar; times: integer); overload;
begin
  //if fileexists(filename) then
  //begin
    //Music := Mix_LoadMUS(filename);
    //Mix_volumemusic(MIX_MAX_VOLUME div 3);
    //Mix_PlayMusic(music, times);
  //end;

end;

//停止当前播放的音乐

procedure StopMP3;
begin
  Mix_HaltMusic;

end;

//播放eft音效

procedure PlaySoundE(SoundNum, times: integer); overload;
begin
  if SoundNum in [Low(Esound)..High(Esound)] then
    if Esound[SoundNum] <> nil then
      Mix_PlayChannel(-1, Esound[SoundNum], times);

end;

procedure PlaySoundE(SoundNum: integer); overload;
begin
  if SoundNum in [Low(Esound)..High(Esound)] then
    if Esound[SoundNum] <> nil then
      Mix_PlayChannel(-1, Esound[SoundNum], 0);

end;

procedure PlaySoundE(filename: pchar; times: integer); overload;
begin
  if fileexists(filename) then
  begin
    Sound := Mix_LoadWav(filename);
    Mix_PlayChannel(-1, sound, times);
  end;
end;

//播放atk音效

procedure PlaySoundA(SoundNum, times: integer);
begin
  if SoundNum in [Low(ASound)..High(ASound)] then
    if ASound[SoundNum] <> nil then
      Mix_PlayChannel(-1, ASound[SoundNum], times);

end;}

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
begin

  {regionx1 := 0;
  regionx2 := surface_.w;
  regiony1 := 0;
  regiony2 := surface_.h;}

  //{$IFDEF DARWIN}
  {if (RegionRect.w > 0) then
  begin
    regionx1 := RegionRect.x;
    regionx2 := RegionRect.x + RegionRect.w;
    regiony1 := RegionRect.y;
    regiony2 := RegionRect.y + RegionRect.h;
  end;}
  //{$ENDIF}
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
  if FileExistsUTF8(file_name) { *Converted from FileExists*  } then
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

procedure display_img(file_name: PChar; x, y: integer);
var
  image: PSDL_Surface;
  dest: TSDL_Rect;
begin
  if FileExistsUTF8(file_name) { *Converted from FileExists*  } then
  begin
    image := IMG_Load(file_name);
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

//取调色板的颜色, 视频系统为32位色, 但很多时候仍需要原调色板的颜色

function ColColor(num: byte): Uint32;
begin
  //{$IFDEF darwin}
  //colcolor := SDL_mapRGB(screen.format, Acol[num * 3 + 0] * 4, Acol[num * 3 + 1] * 4, Acol[num * 3 + 2] * 4);
  //{$ELSE}
  if (num >= 0) and (num <= 255) then
    Result := SDL_mapRGB(screen.format, Acol[num * 3 + 2] * 4, Acol[num * 3 + 1] * 4, Acol[num * 3 + 0] * 4)
  else
    Result := 0;
  //{$ENDIF}

end;

function LoadSurfaceFromFile(filename: string): PSDL_Surface;
var
  tempscr: PSDL_Surface;
begin
  Result := nil;
  if fileexistsUTF8(filename) then
  begin
    tempscr := IMG_Load(PChar(filename));
    Result := SDL_DisplayFormatAlpha(tempscr);
    SDL_FreeSurface(tempscr);
  end;
end;

function LoadSurfaceFromZIPFile(zipFile: unzFile; filename: string): PSDL_Surface;
var
  archiver: unzFile;
  info: unz_file_info;
  buffer: pchar;
begin

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

//RLE8图片绘制子程，所有相关子程均对此封装. 最后一个参数为亮度, 仅在绘制战场选择对方时使用

procedure DrawRLE8Pic(colorPanel: PChar; num, px, py: integer; Pidx: Pinteger; Ppic: PByte;
  RectArea: PChar; Image: PSDL_Surface; widthI, heightI, sizeI: integer; shadow: integer); overload;
begin
  DrawRLE8Pic(colorPanel, num, px, py, Pidx, Ppic, RectArea, Image, widthI, heightI, sizeI, Shadow, 0);

end;

//增加透明度选项

procedure DrawRLE8Pic(colorPanel: PChar; num, px, py: integer; Pidx: Pinteger; Ppic: PByte;
  RectArea: PChar; Image: PSDL_Surface; widthI, heightI, sizeI: integer; shadow, alpha: integer); overload;
begin
  DrawRLE8Pic(colorPanel, num, px, py, Pidx, Ppic, RectArea, Image, widthI, heightI, sizeI,
    Shadow, alpha, nil, nil, 0, 0, 0, 0, 0, 0);

end;

//这是改写的绘制RLE8图片程序, 增加了选调色板, 遮挡控制, 亮度, 半透明, 混合色等
//colorPanel: Pchar; 调色板的指针. 某些情况下需要使用静态调色板, 避免静态图跟随水的效果
//num, px, py: integer; 图片的编号和位置
//Pidx: Pinteger; Ppic: PByte; 图片的索引和内容的资源所在地
//RectArea: Pchar; 画图的范围; 所指向地址应为连续4个integer, 表示一个矩形, 仅图片的部分或全部会出现在这个矩形内才画
//Image: PChar; widthI, heightI, sizeI: integer; 映像及其尺寸, 每单位长度（无用） 如果Img不为空则会将图画到这个镜像, 否则画到屏幕
//shadow, alpha: integer; 图片的暗度和透明度, 仅在画到屏幕上时有效
//BlockImageW: PChar; 大小与场景和战场映像相同. 如果此地址不为空则会记录该像素的场景深度depth, 用于遮挡计算.
//BlockScreenR: PChar; widthR, heightR, sizeR: integer; 该映像应该与屏幕像素数相同, 保存屏幕上每一点的深度
//depth: integer; 所画物件的绘图优先级
//当BlockImageW不为空时, 将该值写入BlockImageW
//但是需注意计算值在场景内包含高度的情况下是不准确的.
//当Image为空, 即画到屏幕上, 同时BlockPosition不为空时, 如果所绘像素的已有深度大于该深度, 则按照alpha绘制该像素
//即该值起作用的机会有两种: Image不为空到映像, 且BlockImageW不为空. 或者Image为空(到屏幕), 且BlockPosition不为空
//如果在画到屏幕时避免该值起作用, 可以设为一个很大的值
//MixColor: Uint32; MixAlpha: integer 图片的混合颜色和混合度, 仅在画到屏幕上时有效

procedure DrawRLE8Pic(colorPanel: PChar; num, px, py: integer; Pidx: Pinteger; Ppic: PByte;
  RectArea: PChar; Image: PSDL_Surface; widthI, heightI, sizeI: integer; shadow, alpha: integer;
  BlockImageW: PChar; BlockPosition: PChar; widthW, heightW, sizeW: integer; depth: integer;
  MixColor: Uint32; MixAlpha: integer); overload;
var
  w, h, xs, ys, x, y, blockx, blocky: smallint;
  offset, length, p, isAlpha, lenInt: integer;
  l, l1, ix, iy, pixdepth, curdepth: integer;
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
  //if (num >= 1916) and (num <= 1941) then h := h - 50;
  lenInt := sizeof(integer);

  if ((w > 1) or (h > 1)) and (px - xs + w >= pint(RectArea)^) and (px - xs < pint(RectArea)^
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
          x := w - xs + px;
          y := iy - ys + py;
          if (x >= pint(RectArea)^) and (y >= pint(RectArea + lenInt)^) and
            (x < pint(RectArea)^ + pint(RectArea + lenInt * 2)^) and (y < pint(RectArea + lenInt)^
            + pint(RectArea + lenInt * 3)^) then
          begin
            pix1 := puint8(colorPanel + l1 * 3)^ * (4 + shadow);
            pix2 := puint8(colorPanel + l1 * 3 + 1)^ * (4 + shadow);
            pix3 := puint8(colorPanel + l1 * 3 + 2)^ * (4 + shadow);
            pix4 := 0;
            //pix := sdl_maprgba(screen.format, pix1, pix2, pix3, pix4);
            if image = nil then
            begin
              //pix := sdl_maprgb(screen.format, puint8(colorPanel + l1 * 3)^ * (4 + shadow),
              //puint8(colorPanel + l1 * 3 + 1)^ * (4 + shadow), puint8(colorPanel + l1 * 3 + 2)^ * (4 + shadow));
              if (alpha <> 0) then
              begin
                if (BlockImageW = nil) then
                begin
                  isAlpha := 1;
                end
                else
                begin
                  blockx := pint(BlockPosition)^;
                  blocky := pint(BlockPosition + 4)^;
                  if (x < blockx + screen.w) and (y < blocky + screen.h) then
                  begin
                    pixdepth := pint(BlockImageW + ((x + blockx) * heightW + y + blocky) * sizeW)^;
                    curdepth := depth;
                    //if where = 1 then
                      //curdepth := depth - (w - xs - 1) div 18;
                    //处理过宽的图片, 仅画图时使用, 事实上该遮挡值只用来画主角, 起作用的唯一机会是拔金蛇剑时
                    if pixdepth >= curdepth then
                    begin
                      isAlpha := 1;
                    end
                    else
                      isAlpha := 0;
                  end;
                end;
                if (isAlpha = 1) and (Alpha < 100) then
                begin
                  colorin := getpixel(screen, x, y);
                  SDL_GetRGBA(colorin, screen.format, @color1, @color2, @color3, @color4);
                  //pix1 := pix and $FF;
                  //color1 := colorin and $FF;
                  //pix2 := pix shr 8 and $FF;
                  //color2 := colorin shr 8 and $FF;
                  //pix3 := pix shr 16 and $FF;
                  //color3 := colorin shr 16 and $FF;
                  //pix4 := pix shr 24 and $FF;
                  //color4 := colorin shr 24 and $FF;
                  pix1 := (alpha * color1 + (100 - alpha) * pix1) div 100;
                  pix2 := (alpha * color2 + (100 - alpha) * pix2) div 100;
                  pix3 := (alpha * color3 + (100 - alpha) * pix3) div 100;
                  pix4 := (alpha * color4 + (100 - alpha) * pix4) div 100;
                  //pix := pix1 + pix2 shl 8 + pix3 shl 16 + pix4 shl 24;
                end;
              end;
              if mixAlpha <> 0 then
              begin
                colorin := MixColor;
                //pix1 := pix and $FF;
                color1 := colorin and $FF;
                //pix2 := pix shr 8 and $FF;
                color2 := colorin shr 8 and $FF;
                //pix3 := pix shr 16 and $FF;
                color3 := colorin shr 16 and $FF;
                //pix4 := pix shr 24 and $FF;
                color4 := colorin shr 24 and $FF;
                pix1 := (mixAlpha * color1 + (100 - mixAlpha) * pix1) div 100;
                pix2 := (mixAlpha * color2 + (100 - mixAlpha) * pix2) div 100;
                pix3 := (mixAlpha * color3 + (100 - mixAlpha) * pix3) div 100;
                pix4 := (mixAlpha * color4 + (100 - mixAlpha) * pix4) div 100;
                //pix := pix1 + pix2 shl 8 + pix3 shl 16 + pix4 shl 24;
              end;
              pix := sdl_maprgba(screen.format, pix1, pix2, pix3, pix4);
              if (Alpha < 100) or (pixdepth <= curdepth) then
                putpixel(screen, x, y, pix);
            end
            else
            begin
              if (x < widthI) and (y < heightI) then
              begin
                if (BlockImageW <> nil) then
                begin
                  //if (depth < 0) then
                    //depth := (py div 9 - 1);
                  Pint(BlockImageW + (x * heightI + y) * sizeI)^ := depth;
                end;
                pix := sdl_maprgba(screen.format, pix1, pix2, pix3, pix4);
                putpixel(Image, x, y, pix);
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
  if PNG_TILE = 1 then
  begin
    DrawPngTile(TitlePNGIndex[imgnum], 0, screen, px, py);
  end;
  if PNG_TILE = 0 then
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
    DrawRLE8Pic(@ACol[0], imgnum, px, py, @BufferIdx[0], @BufferPic[0], @Area, nil, 0, 0, 0, 0);
  end;
end;

//显示主地图贴图

procedure DrawMPic(num, px, py: integer);
var
  Area: Trect;
  NeedGRP, Framenum: integer;
begin
  if (num >= 0) and (num < MPicAmount) then
  begin
    NeedGRP := 0;
    if (PNG_Tile <> 0) then
    begin
      if MPNGIndex[num].UseGRP = 0 then
      begin
        Framenum := sdl_getticks div 200 + random(3);
        if (num = 1377) or (num = 1388)
          or (num = 1404) or (num = 1417) then
          Framenum := sdl_getticks div 200;
        //瀑布场景的闪烁需要
        DrawPNGTile(MPNGIndex[num], Framenum, screen, px, py)
      end
      else
        NeedGRP := 1;
    end;
    if (PNG_Tile = 0) or (NeedGRP = 1) then
    begin
      Area.x := 0;
      Area.y := 0;
      Area.w := screen.w;
      Area.h := screen.h;
      DrawRLE8Pic(@ACol[0], num, px, py, @Midx[0], @Mpic[0], @Area, nil, 0, 0, 0, 0);
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
  Area: TRect;
begin
  if (num >= 0) and (num < SPicAmount) then
  begin
    if num = 1941 then
    begin
      num := 0;
      py := py - 50;
    end;
    if PNG_Tile = 1 then
      DrawPngTile(SPNGIndex[num], 0, screen, px, py)
    else
    begin
      Area.x := x;
      Area.y := y;
      Area.w := w;
      Area.h := h;
      DrawRLE8Pic(@ACol[0], num, px, py, @SIdx[0], @SPic[0], @Area, nil, 0, 0, 0, 0);
    end;
  end;
end;

//画考虑遮挡的内场景

procedure DrawSPic(num, px, py, shadow, alpha, depth: integer; mixColor: Uint32; mixAlpha: integer); overload;
var
  Area: TRect;
begin
  if (num >= 0) and (num < SPicAmount) then
  begin
    if num = 1941 then
    begin
      num := 0;
      py := py - 50;
    end;
    if PNG_Tile = 1 then
      DrawPngTile(SPNGIndex[num], 0, screen, px, py, shadow, alpha, mixColor, mixAlpha,
        depth, @BlockImg[0], 2304, 1402, sizeof(BlockImg[0, 0]), BlockScreen.x, BlockScreen.y)
    else
    begin
      Area.x := 0;
      Area.y := 0;
      Area.w := screen.w;
      Area.h := screen.h;
      DrawRLE8Pic(@ACol[0], num, px, py, @SIdx[0], @SPic[0], @Area, nil, 0, 0, 0, shadow, alpha,
        @BlockImg[0], @BlockScreen, 2304, 1402, sizeof(BlockImg[0, 0]), depth, mixColor, mixAlpha);
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

procedure InitialSPic(num, px, py, x, y, w, h, needBlock, depth, temp: integer);
  overload;
var
  Area: TRect;
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
    if (PNG_TILE = 1) then
    begin
      if temp <> 1 then
        LoadOnePNGTile('resource/smap/', num, SPNGIndex[num], @SPNGTile[0]);
      DrawPNGTile(SPNGIndex[num], sdl_getticks div 300, pImg, px, py);
      if needBlock <> 0 then
      begin
        SetPNGTileBlock(SPNGIndex[num], px, py, depth, pBlock, 2304, 1402, sizeof(BlockImg[0, 0]));
      end;
    end
    else
    begin
      if x + w > 2303 then
        w := 2303 - x;
      if y + h > 1401 then
        h := 1401 - y;
      Area.x := x;
      Area.y := y;
      Area.w := w;
      Area.h := h;
      if num = 1941 then
      begin
        num := 0;
        py := py - 50;
      end;
      if needBlock <> 0 then
      begin
        DrawRLE8Pic(@ACol[0], num, px, py, @SIdx[0], @SPic[0], @Area, pImg, 2304, 1402,
          sizeof(BlockImg[0, 0]), 0, 0, pBlock, nil, 0, 0, 0, depth, 0, 0);
      end
      else
        DrawRLE8Pic(@ACol[0], num, px, py, @SIdx[0], @SPic[0], @Area, pImg, 2304, 1402, sizeof(BlockImg[0, 0]), 0);
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
  Area: TRect;
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
    DrawRLE8Pic(@ACol1[0], num, px, py + y, @HIdx[0], @HPic[0], @Area, scr, scr.w, scr.h, 0,
      0, 0, nil, nil, 0, 0, 0, 0, 0, 0);
  end;
end;

procedure DrawHeadPic(num, px, py, shadow, alpha, depth: integer; mixColor: Uint32; mixAlpha: integer); overload;
var
  len, grp, idx: integer;
  Area: TRect;
  str: string;
begin
  str := AppPath + 'head/' + IntToStr(num) + '.png';
  if FileExistsUTF8(str) { *Converted from FileExists*  } then
    display_img(@str[1], px, py - 60)
  else
  begin
    Area.x := 0;
    Area.y := 0;
    Area.w := screen.w;
    Area.h := screen.h;
    DrawRLE8Pic(@ACol1[0], num, px, py, @HIdx[0], @HPic[0], @Area, nil, 0, 0, 0, shadow, alpha,
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
var
  Area: TRect;
begin
  if (num > 0) and (num < BPicAmount) then
  begin
    if PNG_TILE = 1 then
    begin
      //LoadOnePNGTile('resource/wmap/', num, BPNGIndex[num], @BPNGTile[0]);
      DrawPNGTile(BPNGIndex[num], 0, screen, px, py, shadow, alpha, mixColor, mixAlpha,
        depth, @BlockImg[0], 2304, 1402, sizeof(BlockImg[0, 0]), BlockScreen.x, BlockScreen.y);
    end
    else
    begin
      Area.x := 0;
      Area.y := 0;
      Area.w := screen.w;
      Area.h := screen.h;
      DrawRLE8Pic(@ACol[0], num, px, py, @WIdx[0], @WPic[0], @Area, nil, 0, 0, 0, shadow, alpha,
        @BlockImg[0], @BlockScreen, 2304, 1402, sizeof(BlockImg[0, 0]), depth, mixColor, mixAlpha);
    end;
  end;

end;

//仅在某区域显示战场图

procedure DrawBPicInRect(num, px, py, shadow, x, y, w, h: integer);
var
  Area: TRect;
begin
  if (num > 0) and (num < BPicAmount) then
  begin
    if PNG_TILE = 1 then
    begin
      //LoadOnePNGTile('resource/wmap/', num, BPNGIndex[num], @BPNGTile[0]);
      DrawPNGTile(BPNGIndex[num], 0, screen, px, py);
    end
    else
    begin
      Area.x := x;
      Area.y := y;
      Area.w := w;
      Area.h := h;
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
  Area: TRect;
  pImg: PSDL_Surface;
begin
  if (num > 0) and (num < BPicAmount) then
  begin
    if PNG_TILE = 1 then
    begin
      LoadOnePNGTile('resource/wmap/', num, BPNGIndex[num], @BPNGTile[0]);
      if needBlock <> 0 then
      begin
        SetPNGTileBlock(BPNGIndex[num], px, py, depth, @BlockImg[0], 2304, 1402, sizeof(BlockImg[0, 0]));
        pImg := ImgBBuild;
      end
      else
        pImg := ImgBfield;
      DrawPNGTile(BPNGIndex[num], 0, pImg, px, py);
    end
    else
    begin
      Area.x := 0;
      Area.y := 0;
      Area.w := 2304;
      Area.h := 1402;
      if needBlock <> 0 then
        DrawRLE8Pic(@ACol[0], num, px, py, @WIdx[0], @WPic[0], @Area, ImgBBuild, 2304, 1402,
          sizeof(BlockImg[0, 0]), 0, 0, @BlockImg[0], nil, 0, 0, 0, depth, 0, 0)
      else
        DrawRLE8Pic(@ACol[0], num, px, py, @WIdx[0], @WPic[0], @Area, ImgBfield, 2304, 1402, sizeof(BlockImg[0, 0]), 0);
    end;
  end;
end;

//显示效果图片

procedure DrawEPic(num, px, py: integer); overload;
begin
  DrawEPic(num, px, py, 0, 0, 0, 0, 0);

end;

procedure DrawEPic(num, px, py, shadow, alpha, depth: integer; mixColor: Uint32; mixAlpha: integer); overload;
var
  Area: TRect;
begin
  if PNG_TILE = 1 then
  begin
    DrawPNGTile(EPNGIndex[num], 0, screen, px, py, shadow, alpha, mixColor, mixAlpha,
      0, nil, 0, 0, 0, 0, 0);
  end;
  if PNG_TILE = 0 then
  begin
    Area.x := 0;
    Area.y := 0;
    Area.w := screen.w;
    Area.h := screen.h;
    DrawRLE8Pic(@ACol[0], num, px, py, @EIdx[0], @EPic[0], @Area, nil, 0, 0, 0, shadow, alpha,
      nil, nil, 0, 0, 0, depth, mixColor, mixAlpha);
  end;
end;

//显示人物动作图片

procedure DrawFPic(num, px, py, index: integer); overload;
begin
  DrawFPic(num, px, py, 0, 0, 0, 0, 0, index);

end;

//用于画带透明度和遮挡的人物动作图片

procedure DrawFPic(num, px, py, index, shadow, alpha, depth: integer; mixColor: Uint32; mixAlpha: integer); overload;
var
  Area: TRect;
begin
  case PNG_TILE of
    1:
      begin
        if (index >= 0) and (index < BRoleAmount) then
          if (num >= Low(FPNGIndex[index])) and (num <= High(FPNGIndex[index])) then
            DrawPngTile(FPNGIndex[index][num], 0, screen, px, py, shadow, alpha, mixColor, mixAlpha,
              depth, @BlockImg[0], 2304, 1402, sizeof(BlockImg[0, 0]), BlockScreen.x, BlockScreen.y);
      end;
    0:
      begin
        Area.x := 0;
        Area.y := 0;
        Area.w := screen.w;
        Area.h := screen.h;
        DrawRLE8Pic(@ACol[0], num, px, py, @FIdx[0], @FPic[0], @Area, nil, 0, 0, 0, shadow, alpha,
          @BlockImg[0], @BlockScreen, screen.w, screen.h, sizeof(BlockImg[0, 0]), depth, mixColor, mixAlpha);
      end;
  end;
end;

//主地图上画云

procedure DrawCPic(num, px, py, shadow, alpha: integer; mixColor: Uint32; mixAlpha: integer);
var
  Area: TRect;
begin
  if PNG_TILE = 1 then
  begin
    DrawPngTile(CPNGIndex[num], 0, screen, px, py, shadow, alpha, mixColor, MixAlpha);
  end;
  if PNG_TILE = 0 then
  begin
    Area.x := 0;
    Area.y := 0;
    Area.w := screen.w;
    Area.h := screen.h;
    DrawRLE8Pic(@ACol1[0], num, px, py, @CIdx[0], @CPic[0], @Area, nil, 0, 0, 0, shadow, alpha,
      nil, nil, 0, 0, 0, 0, mixColor, mixAlpha);
  end;
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

//显示unicode文字

procedure DrawText(sur: PSDL_Surface; word: PUint16; x_pos, y_pos: integer; color: Uint32);
var
  dest: TSDL_Rect;
  tempcolor: TSDL_Color;
  len, i, k: integer;
  pword: array[0..2] of Uint16;
  word1: ansistring;
  word2: WideString;
  p1: pbyte;
  p2: pbyte;
begin
{$IFDEF fpc}
  //widestring在fpc中的默认赋值动作是将utf8码每字节间插入一个00.
  //此处删除这些0, 同时统计这些0的数目, 若与字串长度相同
  //即认为是一个纯英文字串, 或者是一个直接赋值的widestring,
  //需要再编码为Unicode, 否则即认为已经是Unicode
  len := length(pwidechar(word));
  setlength(word1, len * 2 + 1);
  p1 := @word1[1];
  p2 := pbyte(word);
  k := 0;
  for i := 0 to len - 1 do
  begin
    p1^ := p2^;
    Inc(p1);
    Inc(p2);
    if p2^ = 0 then
    begin
      k := k + 1;
      Inc(p2);
    end
    else
    begin
      p1^ := p2^;
      Inc(p1);
      Inc(p2);
    end;
  end;
  p1^ := 0;
  if k >= len then
  begin
    word2 := UTF8Decode(word1);
    word := @word2[1];
  end;
{$ELSE}
  //word2 := UTF8Decode(string(word));
  //word := @word2[1];
{$ENDIF}

  pword[0] := 32;
  pword[2] := 0;

  dest.x := x_pos;

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
  tempcolor := TSDL_Color(color);
  //{$ENDIF}


  while word^ > 0 do
  begin
    pword[1] := word^;
    Inc(word);
    if pword[1] > 128 then
    begin
      Text := TTF_RenderUnicode_blended(font, @pword[0], tempcolor);
      //dest.x := x_pos;
      dest.x := x_pos - 0;
      dest.y := y_pos;
      SDL_BlitSurface(Text, nil, sur, @dest);
      x_pos := x_pos + 20;
    end
    else
    begin
      //if pword[1] <> 20 then
      begin
        Text := TTF_RenderUNICODE_blended(engfont, @pword[1], tempcolor);
        //showmessage(inttostr(pword[1]));
        dest.x := x_pos + 10;
        dest.y := y_pos + 2;
        SDL_BlitSurface(Text, nil, sur, @dest);
      end;
      x_pos := x_pos + 10;
    end;
    SDL_FreeSurface(Text);
  end;

end;

//显示英文

procedure DrawEngText(sur: PSDL_Surface; word: PUint16; x_pos, y_pos: integer; color: Uint32);
var
  dest: TSDL_Rect;
  a: Uint8;
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
  tempcolor := TSDL_Color(color);
  //{$ENDIF}

  Text := TTF_RenderUNICODE_blended(engfont, word, tempcolor);
  dest.x := x_pos;
  dest.y := y_pos + 2;
  SDL_BlitSurface(Text, nil, sur, @dest);
  SDL_FreeSurface(Text);

end;

//显示unicode中文阴影文字, 即将同样内容显示2次, 间隔1像素

procedure DrawShadowText(sur: PSDL_Surface; word: PUint16; x_pos, y_pos: integer; color1, color2: Uint32);
begin
  DrawText(sur, word, x_pos + 1, y_pos, color2);
  DrawText(sur, word, x_pos, y_pos, color1);

end;

//显示英文阴影文字

procedure DrawEngShadowText(sur: PSDL_Surface; word: PUint16; x_pos, y_pos: integer; color1, color2: Uint32);
begin
  DrawEngText(sur, word, x_pos + 1, y_pos, color2);
  DrawEngText(sur, word, x_pos, y_pos, color1);

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
  drawtext(sur, @words[1], x_pos, y_pos, color);

end;

//显示big5阴影文字

procedure DrawBig5ShadowText(sur: PSDL_Surface; word: PChar; x_pos, y_pos: integer; color1, color2: Uint32);
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
  DrawText(sur, @words[1], x_pos + 1, y_pos, color2);
  DrawText(sur, @words[1], x_pos, y_pos, color1);

end;

//显示带边框的文字, 仅用于unicode, 需自定义宽度

procedure DrawTextWithRect(sur: PSDL_Surface; word: puint16; x, y, w: integer; color1, color2: uint32);
var
  len: integer;
  p: PChar;
begin
  DrawRectangle(sur, x, y, w, 28, 0, colcolor(255), 30);
  DrawShadowText(sur, word, x - 17, y + 2, color1, color2);
  SDL_UpdateRect2(screen, x, y, w + 1, 29);

end;

//画带边框矩形, (x坐标, y坐标, 宽度, 高度, 内部颜色, 边框颜色, 透明度）

procedure DrawRectangle(sur: PSDL_Surface; x, y, w, h: integer; colorin, colorframe: Uint32; alpha: integer);
var
  i1, i2, l1, l2, l3, l4: integer;
  tempscr, tempscr1: PSDL_Surface;
  dest: TSDL_Rect;
begin
  {if (SDL_MustLock(screen)) then
  begin
    SDL_LockSurface(screen);
  end;}
  tempscr := SDL_CreateRGBSurface(sur.flags, w + 1, h + 1, 32, 0, 0, 0, 0);
  tempscr1 := SDL_CreateRGBSurface(sur.flags, w + 1, h + 1, 32, 0, 0, 0, 0);
  SDL_FillRect(tempscr, nil, colorin);
  SDL_FillRect(tempscr1, nil, 1);
  SDL_SetAlpha(tempscr, SDL_SRCALPHA, alpha * 255 div 100);
  SDL_SetColorKey(tempscr, SDL_SRCCOLORKEY, 1);
  SDL_SetColorKey(tempscr1, SDL_SRCCOLORKEY, 1);
  dest.x := x;
  dest.y := y;
  for i1 := 0 to w do
    for i2 := 0 to h do
    begin
      l1 := i1 + i2;
      l2 := -(i1 - w) + (i2);
      l3 := (i1) - (i2 - h);
      l4 := -(i1 - w) - (i2 - h);
      if not ((l1 >= 4) and (l2 >= 4) and (l3 >= 4) and (l4 >= 4)) then
      begin
        putpixel(tempscr, i1, i2, 1);
      end;
      if (((l1 >= 4) and (l2 >= 4) and (l3 >= 4) and (l4 >= 4) and ((i1 = 0) or (i1 = w) or
        (i2 = 0) or (i2 = h))) or ((l1 = 4) or (l2 = 4) or (l3 = 4) or (l4 = 4))) then
      begin
        putpixel(tempscr1, i1, i2, colorframe);
      end;
    end;
  SDL_BlitSurface(tempscr, nil, sur, @dest);
  SDL_BlitSurface(tempscr1, nil, sur, @dest);
  SDL_FreeSurface(tempscr);
  SDL_FreeSurface(tempscr1);
  {if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;}

end;

//画不含边框的矩形, 用于对话和黑屏

procedure DrawRectangleWithoutFrame(sur: PSDL_Surface; x, y, w, h: integer; colorin: Uint32; alpha: integer);
var
  tempscr: PSDL_Surface;
  dest: TSDL_Rect;
begin
  {if (SDL_MustLock(screen)) then
  begin
    SDL_LockSurface(screen);
  end;}
  tempscr := SDL_CreateRGBSurface(sur.flags, w, h, 32, 0, 0, 0, 0);
  SDL_FillRect(tempscr, nil, colorin);
  SDL_SetAlpha(tempscr, SDL_SRCALPHA, alpha * 255 div 100);
  dest.x := x;
  dest.y := y;
  SDL_BlitSurface(tempscr, nil, sur, @dest);
  SDL_FreeSurface(tempscr);
  {if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;}

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

procedure RecordFreshScreen;
begin
  SDL_BlitSurface(screen, nil, freshscreen, nil);
end;

procedure ReFreshScreen;
begin
  SDL_BlitSurface(freshscreen, nil, screen, nil);
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
  i1, i2, i, sum, x, y, k, c, widthregion, sumregion: integer;
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
  for sum := -sumregion to sumregion + 10 do
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
        if (temp[i1, i2] > 0) then
        begin
          BuildingList[k].x := i1;
          BuildingList[k].y := i2;
          Width := smallint(Mpic[MIdx[temp[i1, i2] div 2 - 1]]);
          Height := smallint(Mpic[MIdx[temp[i1, i2] div 2 - 1] + 2]);
          yoffset := smallint(Mpic[MIdx[temp[i1, i2] div 2 - 1] + 6]);
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
    CurScenceRolePic := BeginScenceRolePic + SFace * 7 + SStep;
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
  i1, i2, sumi, i: integer;
  pos: TPosition;
begin
  loadScencePart(-x * 18 + y * 18 + 1151 - CENTER_X, x * 9 + y * 9 + 9 - CENTER_Y + 250);

  {for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      pos := GetPositionOnScreen(i1, i2, Sx, Sy);
      if SData[CurScence, 4, i1, i2] <= 0 then
        DrawSPic(SData[CurScence, 0, i1, i2] div 2, pos.x, pos.y);
    end;}
  {for sumi := 0 to 63 * 2 do
    for i1 := 0 to 63 do
    begin
      i2 := sumi - i1;
      if (i2 >= 0) and (i2 < 64) then
      begin
        pos := GetPositionOnScreen(i1, i2, Sx, Sy);
        {if SData[CurScence, 4, i1, i2] > 0 then
          DrawSPic(SData[CurScence, 0, i1, i2] div 2, pos.x, pos.y);
        if (SData[CurScence, 1, i1, i2] > 0) then
          DrawSPic(SData[CurScence, 1, i1, i2] div 2, pos.x, pos.y);
        if (SData[CurScence, 2, i1, i2] > 0) then
          DrawSPic(SData[CurScence, 2, i1, i2] div 2, pos.x, pos.y);}
        {if (SData[CurScence, 3, i1, i2] >= 0) and (DData[CurScence, SData[CurScence, 3, i1, i2], 5] > 0) then
          DrawSPic(DData[CurScence, SData[CurScence, 3, i1, i2], 5] div 2, pos.x, pos.y - SData[CurScence, 4, Sx, Sy], 0, 100, i1 + i2, 0, 0);
      end;
    end;}

end;

//画主角于场景

procedure DrawRoleOnScence(x, y: integer);
var
  depth: integer;
  pos: TPosition;
begin
  pos := getpositiononscreen(Sx, Sy, x, y);
  depth := 128 * min(Sx, Sy) + abs(Sx - Sy);
  DrawSPic(CurScenceRolePic, pos.x, pos.y - SData[CurScence, 4, Sx, Sy], 0, 100, depth, 0, 0);

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
  mini, maxi, num, depth, temp: integer;
  dest: TSDL_Rect;
begin
  SDL_LockMutex(mutex);
  if CurEvent >= 0 then
  begin
    x1 := -Cx * 18 + Cy * 18 + 1151 - CENTER_X;
    y1 := Cx * 9 + Cy * 9 + 9 - CENTER_Y + 250;
  end
  else
  begin
    x1 := -Sx * 18 + Sy * 18 + 1151 - CENTER_X;
    y1 := Sx * 9 + Sy * 9 + 9 - CENTER_Y + 250;
  end;
  w := screen.w;
  h := screen.h;
  {if (x1 >= 0) and (x1 < 2304 - w) and (y1 >= 0) and (y1 < 1152 - h) then
    for i1 := x1 to x1 + w - 1 do
      for i2 := y1 to y1 + h - 1 do
      begin
        BlockImg[i1, i2] := 0;
      end;}

  if Visible = 0 then
  begin
    x1 := 0;
    y1 := 0;
    w := 2304;
    h := 1402;
    //temp := sdl_getticks;
    {for i1 := x1 to x1 + w - 1 do
      for i2 := y1 to y1 + h - 1 do
      begin
        putpixel(Img, i1, i2, 0);
      end;}
    //InitialSPic(SData[CurScence, 0, 31, 31], 0, 0, x1, y1, w, h, 0, 0, 0);
    SDL_FillRect(ImgScence, nil, 0);
    SDL_FillRect(ImgScenceBack, nil, 1);
  end;


  temp := 0;
  if (Visible = 2) and (where = 1) then
    temp := 1;

  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      x := -i1 * 18 + i2 * 18 + 1151;
      y := i1 * 9 + i2 * 9 + 9 + 250;
      if SData[CurScence, 4, i1, i2] <= 0 then
      begin
        num := SData[CurScence, 0, i1, i2] div 2;
        InitialSPic(num, x, y, x1, y1, w, h, 1, 0, temp);
      end;
    end;
  for mini := 0 to 63 do
  begin
    depth := 128 * mini;
    InitialScenceOnePosition(mini, mini, x1, y1, w, h, depth, temp);
    for maxi := mini + 1 to 63 do
    begin
      depth := 128 * mini + maxi - mini;
      InitialScenceOnePosition(maxi, mini, x1, y1, w, h, depth, temp);
      InitialScenceOnePosition(mini, maxi, x1, y1, w, h, depth, temp);
    end;
  end;
  {if Visible = 0 then
  begin
    i := filecreate(inttostr(CurScence)+'.bin');
    filewrite(i, BLockImg[0, 0], 2304 * 1402 * 4);
    fileclose(i);
    writeln('Write block infomation.');
  end;}
  if (Visible = 2) and (where = 1) and (x1 >= 0) and (x1 < 2304 - w) and (y1 >= 0) and (y1 < 1402 - h) then
  begin
    Move(BlockImg2[x1, 0], BlockImg[x1, 0], w * sizeof(BlockImg[x1]));
    dest.x := x1;
    dest.y := y1;
    dest.w := w;
    dest.h := h;
    SDL_BlitSurface(ImgScenceBack, @dest, ImgScence, @dest);
  end;
  SDL_UnLockMutex(mutex);
end;

//上面函数的子程

procedure InitialScenceOnePosition(i1, i2, x1, y1, w, h, depth, temp: integer);
var
  i, x, y, num: integer;
begin
  x := -i1 * 18 + i2 * 18 + 1151;
  y := i1 * 9 + i2 * 9 + 9 + 250;
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
        if (temp = 0) and (PNG_TILE = 1) then
          LoadOnePNGTile('resource/smap/', i, SPNGIndex[i], @SPNGTile[0]);
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
  {for i1 := 0 to screen.w - 1 do
    for i2 := 0 to screen.h - 1 do
      if (x + i1 >= 0) and (y + i2 >= 0) and (x + i1 < 2304) and (y + i2 < 1402) then
      begin
        //putpixel(screen, i1, i2, scenceimg[x + i1, y + i2]);
        BlockScreen[i1 * screen.h + i2] := BlockImg[x + i1, y + i2];
      end
      else
      begin
        //putpixel(screen, i1, i2, 0);
        BlockScreen[i1 * screen.h + i2] := 0;
      end;}
  if (x < 0) or (x >= 2304 - CENTER_X * 2) then
    SDL_FillRect(screen, nil, 0);
  SDL_BlitSurface(ImgScence, @dest, screen, nil);

end;

//画战场

procedure DrawWholeBField;
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
  DrawBFieldWithoutRole(Bx, By);

  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      if (Bfield[2, i1, i2] >= 0) and (Brole[Bfield[2, i1, i2]].Dead = 0) then
        DrawRoleOnBfield(i1, i2);
    end;

  //DrawProgress;
  //BfieldDrawn := 1;
  {if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;}
end;

//画不含主角的战场

procedure DrawBFieldWithoutRole(x, y: integer);
var
  i1, i2, xpoint, ypoint: integer;
begin
  {if (SDL_MustLock(screen)) then
  begin
    if (SDL_LockSurface(screen) < 0) then
    begin
      MessageBox(0, PChar(Format('Can''t lock screen : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
  end;}
  //BFieldDrawn := 0;
  loadBfieldPart(-x * 18 + y * 18 + 1151 - CENTER_X, x * 9 + y * 9 + 9 - CENTER_Y + 250);

  {if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;}
  //SDL_UpdateRect2(screen, 0,0,screen.w,screen.h);

end;

//画战场上人物, 需更新人物身前的遮挡

procedure DrawRoleOnBfield(x, y: integer; MixColor: Uint32 = 0; MixAlpha: integer = 0);
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
  depth := 128 * min(x, y) + abs(x - y);
  if MODVersion = 62 then
  begin
    DrawBPic(Rrole[Brole[Bfield[2, x, y]].rnum].ListNum * 4 + Brole[Bfield[2, x, y]].Face + BEGIN_BATTLE_ROLE_PIC,
      pos.x, pos.y, 0, 75, depth, MixColor, MixAlpha);
    exit;
  end;
  DrawBPic(Rrole[Brole[Bfield[2, x, y]].rnum].HeadNum * 4 + Brole[Bfield[2, x, y]].Face + BEGIN_BATTLE_ROLE_PIC,
    pos.x, pos.y, 0, 75, depth, MixColor, MixAlpha);

  //if (Bfield[1, i1, i2] > 0) then
  {begin
    pos1 := GetPositionOnScreen(i1, i2, Bx, By);
    DrawBPicInRect(Bfield[1, i1, i2] div 2, pos1.x, pos1.y, 0, pos.x - 20, pos.y - 60, 40, 60);
    if (Bfield[2, i1, i2] >= 0) and (Brole[Bfield[2, i1, i2]].Dead = 0) then
      DrawBPicInRect(Rrole[Brole[Bfield[2, x, y]].rnum].HeadNum * 4 + Brole[Bfield[2, i1, i2]].Face + BEGIN_BATTLE_ROLE_PIC, pos1.x, pos1.y, 0, pos.x - 20, pos.y - 60, 40, 60);
  end;}

end;

//初始化战场映像

procedure InitialWholeBField;
var
  mini, maxi, depth: integer;
begin
  FillChar(BlockImg[0, 0], sizeof(BlockImg), -1);
  SDL_FillRect(ImgBField, nil, 0);
  SDL_FillRect(ImgBBuild, nil, 1);

  for mini := 0 to 63 do
  begin
    depth := 128 * mini;
    InitialBFieldPosition(mini, mini, depth);
    for maxi := mini + 1 to 63 do
    begin
      depth := 128 * mini + maxi - mini;
      InitialBFieldPosition(maxi, mini, depth);
      InitialBFieldPosition(mini, maxi, depth);
    end;
  end;

end;

procedure InitialBFieldPosition(i1, i2, depth: integer);
var
  x, y: integer;
begin
  x := -i1 * 18 + i2 * 18 + 1151;
  y := i1 * 9 + i2 * 9 + 9 + 250;
  if (i1 < 0) or (i2 < 0) or (i1 > 63) or (i2 > 63) then
  begin
    InitialBPic(0, x, y, 0, 0);
  end
  else
  begin
    InitialBPic(bfield[0, i1, i2] div 2, x, y, 0, 0);
    if (bfield[1, i1, i2] > 0) then
    begin
      InitialBPic(bfield[1, i1, i2] div 2, x, y, 1, depth);
    end;
  end;
end;

//将战场映像画到屏幕并载入遮挡数据

procedure LoadBFieldPart(x, y: integer);
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
  {for i1 := 0 to screen.w - 1 do
    for i2 := 0 to screen.h - 1 do
      if (x + i1 >= 0) and (y + i2 >= 0) and (x + i1 < 2304) and (y + i2 < 1402) then
      begin
        //putpixel(screen, i1, i2, Bfieldimg[x + i1, y + i2]);
        BlockScreen[i1 * screen.h + i2] := BlockImg[x + i1, y + i2];
        //showmessage(inttostr(BlockScreen[i1, i2]));
      end
      else
      begin
        //putpixel(screen, i1, i2, 0);
        BlockScreen[i1 * screen.h + i2] := 0;
      end;}
  if (x < 0) or (x >= 2304 - CENTER_X * 2) then
    SDL_FillRect(screen, nil, 0);
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
  i, i1, i2, bnum, depth: integer;
  pos: TPosition;
begin
  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
      if Bfield[0, i1, i2] > 0 then
      begin
        pos := GetpositionOnScreen(i1, i2, Bx, By);
        if {(i1 = Ax) and (i2 = Ay)} Bfield[4, i1, i2] > 0 then
          //DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 0, 0, 0, $FFFFFFFF, 20)
          DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 1)
        else if (BField[3, i1, i2] >= 0) and (abs(i1 - Bx) + abs(i2 - By) <= step) then
          DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 0)
        else
          DrawBPic(Bfield[0, i1, i2] div 2, pos.x, pos.y, 0, 0, 0, 0, 33);
        {if (i1 = Ax) and (i2 = Ay) then
          DrawMPic(1, pos.x, pos.y);}
      end;

  loadBfieldPart2(-Bx * 18 + By * 18 + 1151 - CENTER_X, Bx * 9 + By * 9 + 9 - CENTER_Y + 250, 35);

  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      pos := getpositiononScreen(i1, i2, Bx, By);
      depth := 128 * min(i1, i2) + abs(i1 - i2);
      {if Bfield[1, i1, i2] > 0 then
        DrawBPic(Bfield[1, i1, i2] div 2, pos.x, pos.y, 0);}
      bnum := Bfield[2, i1, i2];
      if (bnum >= 0) and (Brole[bnum].Dead = 0) then
      begin
        if (Brole[bnum].Team <> Brole[Bfield[2, Bx, By]].Team) and (Bfield[4, i1, i2] > 0) then
          DrawBPic(Rrole[Brole[bnum].rnum].HeadNum * 4 + Brole[bnum].Face + BEGIN_BATTLE_ROLE_PIC,
            pos.x, pos.y, 0, 75, depth, $FFFFFFFF, 20)
        else
          DrawBPic(Rrole[Brole[bnum].rnum].HeadNum * 4 + Brole[bnum].Face + BEGIN_BATTLE_ROLE_PIC,
            pos.x, pos.y, 0, 75, depth, 0, 0);

      end;
    end;

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
      pos := getpositiononScreen(i1, i2, Bx, By);
      if (Bfield[2, i1, i2] >= 0) and (Brole[Bfield[2, i1, i2]].Dead = 0) then
        DrawRoleOnBField(i1, i2);
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
      pos := getpositiononScreen(i1, i2, Bx, By);
      if (Bfield[2, i1, i2] >= 0) and (Brole[Bfield[2, i1, i2]].Dead = 0) then
        DrawRoleOnBField(i1, i2, 0, 50);
      if (Bfield[4, i1, i2] > 0) and (Epicnum - Bfield[4, i1, i2] + 1 >= beginpic) and
        (Epicnum - Bfield[4, i1, i2] + 1 <= endpic) then
        DrawEPic(Epicnum - Bfield[4, i1, i2] + 1, pos.x, pos.y, 0, 25, 0, 0, 0);
    end;
  DrawProgress;

end;

procedure DrawBFieldWithEft(Epicnum, beginpic, endpic, curlevel, bnum: integer; MixColor: Uint32); overload;
var
  k, i1, i2: integer;
  pos: TPosition;
begin
  DrawBfieldWithoutRole(Bx, By);

  for i1 := 0 to 63 do
    for i2 := 0 to 63 do
    begin
      pos := getpositiononScreen(i1, i2, Bx, By);
      k := Bfield[2, i1, i2];
      if (k >= 0) and (Brole[k].Dead = 0) then
      begin
        if (Bfield[4, Brole[k].X, Brole[k].Y] > 0) and (Brole[bnum].Team <> Brole[k].Team) then
          DrawRoleOnBField(i1, i2, MixColor, random(50))
        else
          DrawRoleOnBField(i1, i2);
      end;
      if Bfield[4, i1, i2] > 0 then
      begin
        k := Epicnum + curlevel - Bfield[4, i1, i2];
        if (k >= beginpic) and (k <= endpic) then
        begin
          DrawEPic(k, pos.x, pos.y, 0, 25, 0, 0, 0);
          //writeln(k, ' ',curlevel, ' ', beginpic, ' ' ,endpic);
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
        DrawFPic(apicnum, pos.x, pos.y, Brole[bnum].Bhead, 0, 75, Bx + By, 0, 0);
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

//调色板变化, 贴图闪烁效果

procedure ChangeCol;
var
  i, i1, i2, a, b, add0, len: integer;
  temp: array[0..2] of byte;
  now, next_time: uint32;
  p, p0, p1, p2: real;
begin
  now := sdl_getticks;
  if (NIGHT_EFFECT = 1) and (where = 0) then
  begin
    now_time := now_time + 0.3;
    if now_time > 1440 then now_time := 0;
    p := now_time / 1440;
    //writeln(p);
    if p > 0.5 then p := 1 - p;
    p0 := 0.6 + p;
    p1 := 0.6 + p;
    p2 := 1.0 - 0.4 / 1.3 + p / 1.3;
    for i := 0 to 255 do
    begin
      b := i * 3;
      Acol1[b] := min(trunc(Acol2[b] * p0), 63);
      Acol1[b + 1] := min(trunc(Acol2[b + 1] * p1), 63);
      Acol1[b + 2] := min(trunc(Acol2[b + 2] * p2), 63);
    end;
    move(ACol1[0], ACol[0], 768);
  end;

  add0 := $E0;
  len := 8;
  a := now div 200 mod len;
  move(ACol1[add0 * 3], ACol[add0 * 3 + a * 3], (len - a) * 3);
  move(ACol1[add0 * 3 + (len - a) * 3], ACol[add0 * 3], a * 3);

  add0 := $F4;
  len := 9;
  a := now div 200 mod len;
  move(ACol1[add0 * 3], ACol[add0 * 3 + a * 3], (len - a) * 3);
  move(ACol1[add0 * 3 + (len - a) * 3], ACol[add0 * 3], a * 3);

end;

procedure DrawPngTile(PNGIndex: TPNGIndex; FrameNum: integer; scr: PSDL_Surface; px, py: integer); overload;
begin
  DrawPngTile(PNGIndex, FrameNum, scr, px, py, 0, 0, 0, 0);
end;

procedure DrawPngTile(PNGIndex: TPNGIndex; FrameNum: integer; scr: PSDL_Surface; px, py: integer; shadow, alpha: integer; MixColor: Uint32; MixAlpha: integer); overload;
begin
  DrawPngTile(PNGIndex, FrameNum, scr, px, py, shadow, alpha, MixColor, MixAlpha, 0, nil, 0, 0, 0, 0, 0);

end;

procedure DrawPngTile(PNGIndex: TPNGIndex; FrameNum: integer; scr: PSDL_Surface; px, py: integer; shadow, alpha: integer; MixColor: Uint32; MixAlpha: integer;
  depth: integer; BlockImgR: pchar; width, height, size, leftupx, leftupy: integer); overload;
var
  dest: TSDL_Rect;
  tempscr, tempscrfront, tempscrback, CurSurface: PSDL_Surface;
  pixdepth, i1, i2: integer;
  tran: byte;
  bigtran, pixel, Mask, AlphaValue: uint32;
begin
  with PNGIndex do
  begin
    if (CurPointer <> nil) and (Loaded = 1) then
    begin
      if frame > 1 then
        inc(CurPointer, FrameNum mod Frame);
      CurSurface := CurPointer^;
      if CurSurface <> nil then
      begin
        dest.x := px - x + 1;
        dest.y := py - y + 1;
        dest.w := CurSurface.w;
        dest.h := CurSurface.h;
        if (dest.x + CurSurface.w > 0) and (dest.y + CurSurface.h > 0)
          and (dest.x < scr.w) and (dest.y < scr.h) then
        begin
          if shadow > 0 then
          begin
            MixColor := $FFFFFFFF;
            MixAlpha := shadow * 25;
          end
          else if shadow < 0 then
          begin
            MixColor := 0;
            MixAlpha := shadow * 25;
          end;
          if (MixAlpha = 0) and (BlockImgR = nil) then
          begin
            if (alpha > 0) then
            begin
              //注意, 使用以下特殊算法, 是由图片格式决定
              //资源标准为带有透明通道的Surface, 因此总的Alpha和ColorKey值无效
              //将所画图片直接画入背景, 再将结果与背景混合
              tempscr := SDL_DisplayFormat(CurSurface);
              SDL_BlitSurface(scr, @dest, tempscr, nil);
              SDL_BlitSurface(CurSurface, nil, tempscr, nil);
              SDL_SetAlpha(tempscr, SDL_SRCALPHA, 255 - alpha * 255 div 100);
              SDL_BlitSurface(tempscr, nil, scr, @dest);
              SDL_FreeSurface(tempscr);
            end
            else
              SDL_BlitSurface(CurSurface, nil, scr, @dest);
          end
          else
          begin
            tempscr := SDL_DisplayFormatAlpha(CurSurface);
            //SDL_BlitSurface(tempscr, nil, scr, @dest);
            if (MixAlpha > 0) then
            begin
              //mixalpha := 100;
              tran := MixAlpha * 255 div 100;
              bigtran := tran * $01010101;
              Mask := tempscr.format.AMask;
              tempscrfront := SDL_DisplayFormatAlpha(CurSurface);
              //tempscrback := SDL_DisplayFormatAlpha(CurSurface);
              SDL_FillRect(tempscrfront, nil, (MixColor and (not Mask)) or (bigtran and Mask));
              //SDL_SetAlpha(tempscrfront, SDL_SRCALPHA, MixAlpha * 255 div 100);
              //SDL_FillRect(tempscrback, nil, MixColor);
              //SDL_SetAlpha(tempscrback, SDL_SRCALPHA, 255);
              //SDL_BlitSurface(CurSurface, nil, tempscrback, nil);
              SDL_BlitSurface(tempscrfront, nil, tempscr, nil);
              //SDL_SetColorKey(tempscrback, SDL_SRCCOLORKEY, MixColor);
              if (BlockImgR = nil) then
              begin
                //SDL_SetAlpha(tempscrback, SDL_SRCALPHA, 255 - alpha * 255 div 100);
                SDL_BlitSurface(tempscr, nil, scr, @dest);
              end
              else
              begin
                //SDL_BlitSurface(tempscrback, nil, scr, @dest);
                //SDL_BlitSurface(tempscrback, nil, tempscr, nil);
              end;
              SDL_FreeSurface(tempscrfront);
              //SDL_FreeSurface(tempscrback);
            end;
            if (BlockImgR <> nil) then
            begin
              //depth := depth * 18 - y + CurSurface.h;
              tran := 255 - alpha * 255 div 100;
              //将透明通道的值写入所有位, 具体的位置由蒙板决定
              bigtran := tran * $01010101;
              Mask := tempscr.format.AMask;
              for i1 := 0 to tempscr.w - 1 do
              begin
                for i2 := 0 to tempscr.h - 1  do
                begin
                  pixdepth := pint(BlockImgR + ((dest.x + leftupx + i1) * height + dest.y + leftupy + i2) * size)^;
                  //writeln(depth, pixdepth);
                  pixel := getpixel(tempscr, i1, i2);
                  AlphaValue := pixel and Mask;
                  if AlphaValue > 0 then
                  begin
                    if (pixdepth > depth) then
                    begin
                      //替换透明通道的值
                      //注意: 这里如果效率较低，则改用完全指针, 或者汇编编写. 设置偏移也相同
                      putpixel(tempscr, i1, i2, (pixel and (not Mask)) or (bigtran and Mask));
                    end;
                  end;
                end;
              end;
              SDL_BlitSurface(tempscr, nil, scr, @dest);
            end;
            SDL_FreeSurface(tempscr);
          end;
        end;
      end;
    end;
  end;
end;

procedure SetPngTileBlock(PNGIndex: TPNGIndex; px, py, depth: integer; BlockImageW: pchar; width, height, size: integer);
var
  i, i1, i2, x1, y1: integer;
  CurSurface: PSDL_Surface;
begin
  with PNGIndex do
  begin
    if CurPointer <> nil then
    begin
      CurSurface := CurPointer^;
      if CurSurface <> nil then
      begin
        x1 := px - x + 1;
        y1 := py - y + 1;
        for i1 := 0 to CurSurface.w - 1 do
        begin
          for i2 := 0 to CurSurface.h - 1 do
          begin
            //当该值并非透明色值时, 表示需要遮挡数据
            //游戏中的遮挡实际上可由绘图顺序决定, 即绘图顺序靠后的应有最大遮挡值
            //绘图顺序比较的优先级为: x, y的最小值; 坐标差绝对值; y较小(或x较大)
            //保存遮挡需要一个数组, 但是如果利用Surface可能会更快
            if ((getpixel(CurSurface, i1, i2) and CurSurface.format.AMask) <> 0)
              and (x1 + i1 >= 0) and (x1 + i1 < width) and (y1 + i2 >= 0) and (y1 + i2 < height) then
            begin
              pint(BlockImageW + ((x1 + i1) * height + y1 + i2) * size)^ := depth;
            end;
          end;
        end;
      end;
    end;
  end;

end;

{function TestPNGTile(PNGTile: TPNGTile; num: integer): boolean;
begin

end;}

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
  if scr1 = screen then
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
    //realx := x * RealScreen.w div scr1.w;
    //realw := (x + w + 2) * RealScreen.w div scr1.w - realx;
    //realy := y * RealScreen.h div scr1.h;
    //realh := (y + h + 2) * RealScreen.h div scr1.h - realy;
    //if realw + realx > RealScreen.w then realw := RealScreen.w - realx;
    //if realh + realy > RealScreen.h then realh := RealScreen.h - realy;
    if (RealScreen.w = screen.w) and (RealScreen.h = screen.h) then
    begin
      SDL_BlitSurface(prescreen, nil, RealScreen, nil);
    end
    else
    begin
      tempscr := sdl_gfx.zoomSurface(prescreen, RealScreen.w / screen.w, RealScreen.h / screen.h, SMOOTH);
      SDL_BlitSurface(tempscr, nil, RealScreen, nil);
      sdl_freesurface(tempscr);
    end;
    SDL_UpdateRect(RealScreen, 0, 0, RealScreen.w, RealScreen.h);
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
    realscreen := SDL_SetVideoMode(RESOLUTIONX, RESOLUTIONY, 32, ScreenFlag);
  end
  else
  begin
    realscreen := SDL_SetVideoMode(Center_X * 2, Center_Y * 2, 32, ScreenFlag or SDL_FULLSCREEN);
  end;

end;

procedure QuitConfirm;
var
  tempscr: Psdl_surface;
  menustring: array[0..1] of WideString;
begin
  if (EXIT_GAME = 0) or (AskingQuit = True) then
  begin
    if messagedlg('Are you sure to quit?', mtConfirmation, [mbOK, mbCancel], 0) = idOk then
      Quit;
  end
  else
  begin
    if AskingQuit then
      exit;
    AskingQuit := True;
    tempscr := SDL_ConvertSurface(prescreen, screen.format, screen.flags);
    SDL_BlitSurface(tempscr, nil, Screen, nil);
    DrawRectangleWithoutFrame(screen, 0, 0, screen.w, screen.h, 0, 50);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    menustring[0] := ' 取消';
    menustring[1] := ' 確認';
    if commonmenu(CENTER_X * 2 - 50, 2, 45, 1, menustring) = 1 then
      Quit;
    redraw(1);
    SDL_BlitSurface(tempscr, nil, Screen, nil);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    sdl_freesurface(tempscr);
    AskingQuit := False;
  end;

end;

procedure CheckBasicEvent;
var
  i: integer;
begin
  case event.type_ of
    SDL_QUITEV:
      QuitConfirm;
    SDL_VIDEORESIZE:
      ResizeWindow(event.resize.w, event.resize.h);
    SDL_KEYUP:
      if (where = 2) and (event.key.keysym.sym = sdlk_Escape) then
      begin
        for i := 0 to BroleAmount - 1 do
        begin
          if Brole[i].Team = 0 then
            Brole[i].Auto := 0;
        end;
      end;
  end;

end;

{$IFDEF fpc}

{$ELSE}

function FileExistsUTF8(filename: PChar): boolean; overload;
begin
  Result := FileExists(filename);
end;

function FileExistsUTF8(filename: string): boolean; overload;
begin
  Result := FileExists(filename);
end;

{function UTF8Decode(str: widestring): widestring;
begin
  result := str;
end;}
{$ENDIF}

end.

