unit kys_engine;

//{$MODE Delphi}

interface

uses
  SysUtils,
  {$IFDEF fpc}
  LConvEncoding,
  LCLType,
  LCLIntf,
  {$ENDIF}
  {$IFDEF mswindows}
  Windows,
  {$ENDIF}
  Math,
  Dialogs,
  SDL3_TTF,
  SDL3_image,
  SDL3,
  bassmidi,
  bass,
  //ziputils,
  //unzip,
  kys_main,
  kys_type,
  StrUtils;

function EventFilter(p: pointer; e: PSDL_Event): boolean; cdecl;
//音频子程
procedure InitialMusic;
procedure PlayMP3(MusicNum, times: integer; frombeginning: integer = 1); overload;
procedure PlayMP3(filename: putf8char; times: integer); overload;
procedure StopMP3(frombeginning: integer = 1);
procedure PlaySoundE(SoundNum, times: integer); overload;
procedure PlaySoundE(SoundNum: integer); overload;
procedure PlaySoundE(SoundNum, times, x, y, z: integer); overload;
//procedure PlaySoundE(filename: putf8char; times: integer); overload;
procedure PlaySoundA(SoundNum, times: integer);

//用于读取的子程
procedure ReadTiles;
function ReadFileToBuffer(p: putf8char; filename: utf8string; size, malloc: integer): putf8char;
procedure FreeFileBuffer(var p: putf8char);
function LoadIdxGrp(stridx, strgrp: utf8string; var idxarray: TIntArray; var grparray: TByteArray): integer;
function LoadPNGTiles(path: utf8string; var PNGIndexArray: TPNGIndexArray; var SurfaceArray: TSurfaceArray; LoadPic: integer = 1): integer;
procedure LoadOnePNGTile(path: utf8string; p: putf8char; filenum: integer; var PNGIndex: TPNGIndex; SurfacePointer: PPSDL_Surface; forceLoad: integer = 0);
function LoadSurfaceFromFile(filename: utf8string): PSDL_Surface;
function LoadSurfaceFromMem(p: putf8char; len: integer): PSDL_Surface;
procedure FreeAllSurface;

//基本绘图子程
function GetPixel(surface: PSDL_Surface; x: integer; y: integer): uint32; inline;
procedure PutPixel(surface: PSDL_Surface; x: integer; y: integer; pixel: uint32); inline;
procedure display_img(file_name: putf8char; x, y: integer);
function ColColor(num: byte): uint32; inline;
procedure DrawRectangle(sur: PSDL_Surface; x, y, w, h: integer; colorin, colorframe: uint32; alpha: integer);
procedure DrawRectangleWithoutFrame(sur: PSDL_Surface; x, y, w, h: integer; colorin: uint32; alpha: integer);

//画RLE8图片的子程
function JudgeInScreen(px, py, w, h, xs, ys: integer): boolean; overload; inline;
function JudgeInScreen(px, py, w, h, xs, ys, xx, yy, xw, yh: integer): boolean; overload; inline;
procedure DrawRLE8Pic(colorPanel: putf8char; num, px, py: integer; Pidx: Pinteger; Ppic: pbyte; RectArea: putf8char; Image: PSDL_Surface; widthI, heightI, sizeI: integer; shadow: integer); overload; inline;
procedure DrawRLE8Pic(colorPanel: putf8char; num, px, py: integer; Pidx: Pinteger; Ppic: pbyte; RectArea: putf8char; Image: PSDL_Surface; widthI, heightI, sizeI: integer; shadow, alpha: integer); overload; inline;
procedure DrawRLE8Pic(colorPanel: putf8char; num, px, py: integer; Pidx: Pinteger; Ppic: pbyte; RectArea: putf8char; Image: PSDL_Surface; widthI, heightI, sizeI: integer; shadow, alpha: integer; BlockImageW: putf8char; BlockPosition: putf8char; widthW, heightW, sizeW: integer; depth: integer; mixColor: uint32; mixAlpha: integer); overload;
function GetPositionOnScreen(x, y, CenterX, CenterY: integer): TPosition;

//显示文字的子程
function cp950toutf8(str: pansichar; len: integer = -1): utf8string; overload;
function utf8tocp950(constref str: utf8string): ansistring; overload;
function transcode(constref str: utf8string; input, output: integer): utf8string;
procedure DrawText(sur: PSDL_Surface; word: utf8string; x_pos, y_pos: integer; color: uint32);
procedure DrawEngText(sur: PSDL_Surface; constref word: utf8string; x_pos, y_pos: integer; color: uint32);
procedure DrawShadowText(sur: PSDL_Surface; constref word: utf8string; x_pos, y_pos: integer; color1, color2: uint32); overload;
procedure DrawShadowText(constref word: utf8string; x_pos, y_pos: integer; color1, color2: uint32); overload;
procedure DrawEngShadowText(sur: PSDL_Surface; constref word: utf8string; x_pos, y_pos: integer; color1, color2: uint32);
procedure DrawBig5Text(sur: PSDL_Surface; str: pansichar; x_pos, y_pos: integer; color: uint32);
procedure DrawBig5ShadowText(sur: PSDL_Surface; word: pansichar; x_pos, y_pos: integer; color1, color2: uint32);
procedure DrawTextWithRect(constref word: utf8string; x, y, w: integer; color1, color2: uint32); overload;
procedure DrawTextWithRect(sur: PSDL_Surface; constref word: utf8string; x, y, w: integer; color1, color2: uint32); overload;

//PNG贴图相关的子程
procedure DrawPNGTile(PNGIndex: TPNGIndex; FrameNum: integer; RectArea: putf8char; scr: PSDL_Surface; px, py: integer); overload;
procedure DrawPNGTile(PNGIndex: TPNGIndex; FrameNum: integer; RectArea: putf8char; scr: PSDL_Surface; px, py: integer; shadow, alpha: integer; mixColor: uint32; mixAlpha: integer); overload;
procedure DrawPNGTile(PNGIndex: TPNGIndex; FrameNum: integer; RectArea: putf8char; scr: PSDL_Surface; px, py: integer; shadow, alpha: integer; mixColor: uint32; mixAlpha: integer; depth: integer; BlockImgR: putf8char; Width, Height, size, leftupx, leftupy: integer); overload;
procedure SetPNGTileBlock(PNGIndex: TPNGIndex; px, py, depth: integer; BlockImageW: putf8char; Width, Height, size: integer);

//用于系统响应的子程
procedure ChangeCol;
procedure SDL_UpdateRect2(scr1: PSDL_Surface; x, y, w, h: integer);
procedure SDL_GetMouseState2(var x, y: integer);
procedure ResizeWindow(w, h: integer);
procedure SwitchFullscreen;
procedure QuitConfirm;
function CheckBasicEvent: uint32;
function AngleToDirection(y, x: real): integer;

function DrawLength(str: utf8string): integer; overload;
function DrawLength(p: putf8char): integer; overload;

function round(x: real): integer;
procedure swap(var x, y: uint32); overload;
procedure UpdateAllScreen;
procedure TransBlackScreen;
procedure CleanKeyValue;
procedure GetMousePosition(var x, y: integer; x0, y0: integer; yp: integer = 0);

function MouseInRegion(x, y, w, h: integer): boolean; overload;
function MouseInRegion(x, y, w, h: integer; var x1, y1: integer): boolean; overload;

function RegionParameter(x, x1, x2: integer): integer;

procedure QuickSortB(var a: array of TBuildInfo; l, r: integer);

//简繁体转换
function Simplified2Traditional(str: utf8string): utf8string;
function Traditional2Simplified(str: utf8string): utf8string;

//计时, 测速用
procedure tic;
procedure toc;

procedure kyslog(formatstring: utf8string; content: array of const; cr: boolean = True); overload;
procedure kyslog(formatstring: string = ''; cr: boolean = True); overload;

function utf8follow(c1: utf8char): integer;

function checkFileName(f: utf8string): utf8string;
function InRegion(x1, y1, x, y, w, h: integer): boolean;

implementation

uses
  kys_draw;

function EventFilter(p: pointer; e: PSDL_Event): boolean; cdecl;
begin
  Result := True;
  {or (e.type_ = SDL_EVENT_FINGER_MOTION)}
  case e.type_ of
    SDL_EVENT_FINGER_UP, SDL_EVENT_FINGER_DOWN, SDL_EVENT_GAMEPAD_AXIS_MOTION, SDL_EVENT_GAMEPAD_BUTTON_DOWN, SDL_EVENT_GAMEPAD_BUTTON_UP: Result := False;
    SDL_EVENT_FINGER_MOTION:
      if CellPhone = 0 then
        Result := False;
    SDL_EVENT_DID_ENTER_FOREGROUND: PlayMP3(nowmusic, -1, 0);
    SDL_EVENT_DID_ENTER_BACKGROUND: StopMP3();
  end;
end;

procedure InitialMusic;
var
  i: integer;
  str: utf8string;
  sf: BASS_MIDI_FONT;
  Flag: longword;
begin
  BASS_Set3DFactors(1, 0, 0);
  str := AppPath + 'music/mid.sf2';
  if (not FileExists(str)) then
    str := AppPathCommon + 'music/mid.sf2';
  sf.font := BASS_MIDI_FontInit(putf8char(str), 0);
  BASS_MIDI_StreamSetFonts(0, sf, 1);
  sf.preset := -1; //use all presets
  sf.bank := 0;
  Flag := 0;
  if SOUND3D = 1 then
    Flag := BASS_SAMPLE_3D or Flag;

  for i := low(Music) to high(Music) do
  begin
    str := AppPath + 'music/' + IntToStr(i) + '.mp3';
    if FileExists(putf8char(str)) then
    begin
      try
        Music[i] := BASS_StreamCreateFile(False, putf8char(str), 0, 0, 0);
      finally

      end;
    end
    else
    begin
      str := AppPath + 'music/' + IntToStr(i) + '.mid';
      if FileExists(putf8char(str)) then
      begin
        try
          Music[i] := BASS_MIDI_StreamCreateFile(False, putf8char(str), 0, 0, 0, 0);
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
    if FileExists(putf8char(str)) then
      ESound[i] := BASS_SampleLoad(False, putf8char(str), 0, 0, 1, Flag)
    else
      ESound[i] := 0;
    //showmessage(inttostr(esound[i]));
  end;
  for i := low(ASound) to high(ASound) do
  begin
    str := AppPath + formatfloat('sound/atk00', i) + '.wav';
    if FileExists(putf8char(str)) then
      ASound[i] := BASS_SampleLoad(False, putf8char(str), 0, 0, 1, Flag)
    else
      ASound[i] := 0;
  end;

end;

//播放mp3音乐
procedure PlayMP3(MusicNum, times: integer; frombeginning: integer = 1); overload;
var
  repeatable: boolean;
begin
  if times = -1 then
    repeatable := True
  else
    repeatable := False;
  try
    if (MusicNum >= low(Music)) and (MusicNum <= high(Music)) and (VOLUME > 0) then
      if Music[MusicNum] > 0 then
      begin
        //BASS_ChannelSlideAttribute(Music[nowmusic], BASS_ATTRIB_VOL, 0, 1000);
        if nowmusic > 0 then
        begin
          BASS_ChannelStop(Music[nowmusic]);
          if frombeginning = 1 then
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
        BASS_ChannelPlay(Music[MusicNum], False);
        nowmusic := MusicNum;
      end;
  finally

  end;

end;

procedure PlayMP3(filename: putf8char; times: integer); overload;
begin
  //if fileexists(filename) then
  //begin
  //Music := Mix_LoadMUS(filename);
  //Mix_volumemusic(MIX_MAX_VOLUME div 3);
  //Mix_PlayMusic(music, times);
  //end;

end;

//停止当前播放的音乐
procedure StopMP3(frombeginning: integer = 1);
begin
  BASS_ChannelStop(Music[nowmusic]);
  if frombeginning = 1 then
    BASS_ChannelSetPosition(Music[nowmusic], 0, BASS_POS_BYTE);

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
  if (SoundNum >= low(ESound)) and (SoundNum <= high(ESound)) and (VOLUME > 0) then
    if ESound[SoundNum] <> 0 then
    begin
      //Mix_VolumeChunk(Esound[SoundNum], Volume);
      //Mix_PlayChannel(-1, Esound[SoundNum], 0);
      BASS_SampleStop(ESound[SoundNum]);
      ch := BASS_SampleGetChannel(ESound[SoundNum], False);
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
  PlaySoundE(SoundNum, 0);

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

  if (SoundNum >= low(ESound)) and (SoundNum <= high(ESound)) and (VOLUMEWAV > 0) then
    if ESound[SoundNum] <> 0 then
    begin
      //Mix_VolumeChunk(Esound[SoundNum], Volume);
      //Mix_PlayChannel(-1, Esound[SoundNum], 0);
      BASS_SampleStop(ESound[SoundNum]);
      ch := BASS_SampleGetChannel(ESound[SoundNum], False);
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
  if (SoundNum >= low(ASound)) and (SoundNum <= high(ASound)) and (VOLUMEWAV > 0) then
    if ASound[SoundNum] <> 0 then
    begin
      //Mix_VolumeChunk(Esound[SoundNum], Volume);
      //Mix_PlayChannel(-1, Esound[SoundNum], 0);
      BASS_SampleStop(ESound[SoundNum]);
      ch := BASS_SampleGetChannel(ASound[SoundNum], False);
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
  str: utf8string;
  begin
  for i := 0 to 23 do
  begin
  str := AppPath + 'music/' + inttostr(i) + '.mid';
  if FileExists(putf8char(str)) then
  begin
  Music[i] := Mix_LoadMUS(putf8char(str));
  end
  else
  Music[i] := nil;
  end;
  for i := 0 to 52 do
  begin
  str := AppPath + formatfloat('sound/e00', i) + '.wav';
  if FileExists(putf8char(str)) then
  ESound[i] := Mix_LoadWav(putf8char(str))
  else
  ESound[i] := nil;
  end;
  for i := 0 to 24 do
  begin
  str := AppPath + formatfloat('sound/atk00', i) + '.wav';
  if FileExists(putf8char(str)) then
  ASound[i] := Mix_LoadWav(putf8char(str))
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

  procedure PlayMP3(filename: putf8char; times: integer); overload;
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

  procedure PlaySoundE(filename: putf8char; times: integer); overload;
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

procedure ReadTiles;
var
  i: integer;
begin
  if PNG_TILE = 0 then
  begin
    if IsConsole then
      writeln('Reading idx and grp files...');
    MPicAmount := LoadIdxGrp('resource/mmap.idx', 'resource/mmap.grp', MIdx, MPic);
    SPicAmount := LoadIdxGrp('resource/sdx', 'resource/smp', SIdx, SPic);
    BPicAmount := LoadIdxGrp('resource/wdx', 'resource/wmp', WIdx, WPic);
    EPicAmount := LoadIdxGrp('resource/eft.idx', 'resource/eft.grp', EIdx, EPic);
    //LoadIdxGrp('resource/hdgrp.idx', 'resource/hdgrp.grp', HIdx, HPic);
    CPicAmount := LoadIdxGrp('resource/cloud.idx', 'resource/cloud.grp', CIdx, CPic);
    HPicAmount := LoadIdxGrp('resource/hdgrp.idx', 'resource/hdgrp.grp', HIdx, HPic);
  end;

  if PNG_TILE > 0 then
  begin
    MPicAmount := LoadPNGTiles('resource/mmap', MPNGIndex, MPNGTile, 1);
    SPicAmount := LoadPNGTiles('resource/smap', SPNGIndex, SPNGTile, 1);
    {for i := BeginSceneRolePic to BeginSceneRolePic + 27 do
      LoadOnePNGTile('resource/smap', nil,i, SPNGIndex[i], @SPNGTile[0]);
      for i := 3410 to 4102 do
      LoadOnePNGTile('resource/smap', nil,i, SPNGIndex[i], @SPNGTile[0]);}
    BPicAmount := LoadPNGTiles('resource/wmap', BPNGIndex, BPNGTile, 1);
    EPicAmount := LoadPNGTiles('resource/eft', EPNGIndex, EPNGTile, 1);
    CPicAmount := LoadPNGTiles('resource/cloud', CPNGIndex, CPNGTile, 1);
  end;

  if BIG_PNG_TILE > 0 then
  begin
    {MMapSurface :=  LoadSurfaceFromFile(AppPath + 'resource/bigpng/mmap.png');
      if MMapSurface <> nil then
      writeln('Main map loaded.');}
  end;
end;

//读入文件到缓冲区
//当读入的位置并非变长数据时, 务必设置 malloc = 0!
//size小于0时, 则读整个文件.
function ReadFileToBuffer(p: putf8char; filename: utf8string; size, malloc: integer): putf8char;
var
  i: integer;
begin
  i := FileOpen(filename, fmopenread);
  if i > 0 then
  begin
    if size < 0 then
      size := FileSeek(i, 0, 2);
    if malloc = 1 then
    begin
      //GetMem(result, size + 4);
      {$IFDEF fpc}
      Result := StrAlloc(size + 4);
      {$ELSE}
      Result := AnsiStrAlloc(size + 4);
      {$ENDIF}
      p := Result;
      //writeln(StrBufSize(p));
    end;
    FileSeek(i, 0, 0);
    FileRead(i, p^, size);
    FileClose(i);
  end
  else if malloc = 1 then
    Result := nil;
end;

procedure FreeFileBuffer(var p: putf8char);
begin
  if p <> nil then
    StrDispose(p);
  p := nil;
end;

function LoadIdxGrp(stridx, strgrp: utf8string; var idxarray: TIntArray; var grparray: TByteArray): integer;
var
  idx, grp, len, tnum: integer;
begin
  if length(idxarray) > 0 then
  begin
    Result := length(idxarray);
    exit;
  end;
  grp := FileOpen(AppPath + strgrp, fmopenread);
  len := FileSeek(grp, 0, 2);
  setlength(grparray, len + 4);
  FileSeek(grp, 0, 0);
  FileRead(grp, grparray[0], len);
  FileClose(grp);

  idx := FileOpen(AppPath + stridx, fmopenread);
  tnum := FileSeek(idx, 0, 2) div 4;
  setlength(idxarray, tnum + 1);
  FileSeek(idx, 0, 0);
  FileRead(idx, idxarray[0], tnum * 4);
  FileClose(idx);

  Result := tnum;

end;

//为了提高启动的速度, M之外的贴图均仅读入基本信息, 需要时才实际载入图, 并且游戏过程中通常不再释放资源
function LoadPNGTiles(path: utf8string; var PNGIndexArray: TPNGIndexArray; var SurfaceArray: TSurfaceArray; LoadPic: integer = 1): integer;
var
  i, j, k, state, size, Count, pngoff: integer;
  //zipFile: unzFile;
  //info: unz_file_info;
  offset: array of smallint;
  p: putf8char;
begin
  //载入偏移值文件, 计算贴图的最大数量
  size := 0;
  Result := 0;
  p := nil;

  if PNG_TILE = 2 then
  begin
    if IsConsole then
      writeln('Searching imz file... ', path);
    p := ReadFileToBuffer(nil, AppPath + path + '.imz', -1, 1);
    if p <> nil then
    begin
      Result := Pinteger(p)^;
      //最大的有帧数的数量作为贴图的最大编号
      for i := Result - 1 downto 0 do
      begin
        if Pinteger(p + Pinteger(p + 4 + i * 4)^ + 4)^ > 0 then
        begin
          Result := i + 1;
          break;
        end;
      end;

      //初始化贴图索引, 并计算全部帧数和
      setlength(PNGIndexArray, Result);
      Count := 0;
      for i := 0 to Result - 1 do
      begin
        pngoff := Pinteger(p + 4 + i * 4)^;
        with PNGIndexArray[i] do
        begin
          num := Count;
          x := psmallint(p + pngoff)^;
          y := psmallint(p + pngoff + 2)^;
          Frame := Pinteger(p + pngoff + 4)^;
          Count := Count + Frame;
          CurPointer := nil;
          Loaded := 0;
        end;
      end;
    end
    else if IsConsole then
      writeln('Can''t find imz file.');
  end;

  if (PNG_TILE = 1) or (p = nil) then
  begin
    if IsConsole then
      writeln('Searching index of png files... ', path + '/index.ka');
    path := path + '/';
    p := ReadFileToBuffer(nil, AppPath + path + '/index.ka', -1, 1);
    size := StrBufSize(p);
    setlength(offset, size div 2 + 2);
    move(p^, offset[0], size);
    FreeFileBuffer(p);

    for i := size div 4 downto 0 do
    begin
      if FileExists(AppPath + path + IntToStr(i) + '.png') or FileExists(AppPath + path + IntToStr(i) + '_0.png') then
      begin
        Result := i + 1;
        break;
      end;
    end;
    //贴图的数量是有文件存在的最大数量
    setlength(PNGIndexArray, Result);
    //计算合法贴图文件的总数, 同时指定每个图的索引数据
    Count := 0;
    for i := 0 to Result - 1 do
    begin
      with PNGIndexArray[i] do
      begin
        num := -1;
        Frame := 0;
        CurPointer := nil;
        if FileExists(AppPath + path + IntToStr(i) + '.png') then
        begin
          num := Count;
          Frame := 1;
          Count := Count + 1;
        end
        else
        begin
          k := 0;
          while FileExists(AppPath + path + IntToStr(i) + '_' + IntToStr(k) + '.png') do
          begin
            k := k + 1;
            if k = 1 then
              num := Count;
            Count := Count + 1;
          end;
          Frame := k;
        end;
        x := offset[i * 2];
        y := offset[i * 2 + 1];
        Loaded := 0;
        UseGRP := 0;
      end;
    end;
  end;

  if IsConsole then
    writeln(Result, ' index, ', Count, ' real titles. Now loading...');

  setlength(SurfaceArray, Count);
  for i := 0 to Count - 1 do
    SurfaceArray[i] := nil;

  if LoadPic = 1 then
  begin
    for i := 0 to Result - 1 do
    begin
      LoadOnePNGTile(path, p, i, PNGIndexArray[i], @SurfaceArray[0], 1);
    end;
  end;
  FreeFileBuffer(p);

end;

procedure LoadOnePNGTile(path: utf8string; p: putf8char; filenum: integer; var PNGIndex: TPNGIndex; SurfacePointer: PPSDL_Surface; forceLoad: integer = 0);
var
  j, k, index, len, off: integer;
  tempscr: PSDL_Surface;
  frommem: boolean;
begin
  SDL_PollEvent(@event);
  CheckBasicEvent;

  frommem := ((PNG_TILE = 2) and (p <> nil));
  if not frommem then
    path := path + '/';
  with PNGIndex do
  begin
    if ((Loaded = 0) or (forceLoad = 1)) and (num >= 0) and (Frame > 0) then
    begin
      Loaded := 1;
      Inc(SurfacePointer, num);
      CurPointer := SurfacePointer;
      if Frame = 1 then
      begin
        if frommem then
        begin
          off := Pinteger(p + 4 + filenum * 4)^ + 8;
          index := Pinteger(p + off)^;
          len := Pinteger(p + off + 4)^;
          SurfacePointer^ := LoadSurfaceFromMem(p + index, len);
        end
        else
          SurfacePointer^ := LoadSurfaceFromFile(AppPath + path + IntToStr(filenum) + '.png');
        if SurfacePointer^ = nil then
          SurfacePointer^ := LoadSurfaceFromFile(AppPath + path + IntToStr(filenum) + '_0.png');
      end;
      if Frame > 1 then
      begin
        for j := 0 to Frame - 1 do
        begin
          if frommem then
          begin
            off := Pinteger(p + 4 + filenum * 4)^ + 8;
            index := Pinteger(p + off + j * 8)^;
            len := Pinteger(p + off + j * 8 + 4)^;
            SurfacePointer^ := LoadSurfaceFromMem(p + index, len);
          end
          else
            SurfacePointer^ := LoadSurfaceFromFile(AppPath + path + IntToStr(filenum) + '_' + IntToStr(j) + '.png');
          Inc(SurfacePointer, 1);
        end;
      end;
    end;
  end;
end;

function LoadSurfaceFromFile(filename: utf8string): PSDL_Surface;
var
  tempscr: PSDL_Surface;
begin
  Result := nil;
  if FileExists(filename) then
  begin
    tempscr := IMG_Load(putf8char(filename));
    Result := SDL_ConvertSurface(tempscr, screen.format);
    SDL_DestroySurface(tempscr);
  end;
end;

function LoadSurfaceFromMem(p: putf8char; len: integer): PSDL_Surface;
var
  tempscr: PSDL_Surface;
  //tempRWops: PSDL_RWops;
begin
  Result := nil;
  //tempRWops := SDL_IOFromMem(p, len);
  //tempscr := IMG_LoadPNG_RW(tempRWops);
  //Result := SDL_ConvertSurface(tempscr, screen.format, 0);
  //SDL_DestroySurface(tempscr);
  //SDL_FreeRW(tempRWops);

end;

procedure FreeAllSurface;
var
  i, j: integer;
begin
  for i := 0 to high(MPNGTile) do
    SDL_DestroySurface(MPNGTile[i]);
  for i := 0 to high(SPNGTile) do
    SDL_DestroySurface(SPNGTile[i]);
  for i := 0 to high(BPNGTile) do
    SDL_DestroySurface(BPNGTile[i]);
  for i := 0 to high(EPNGTile) do
    SDL_DestroySurface(EPNGTile[i]);
  for i := 0 to high(CPNGTile) do
    SDL_DestroySurface(CPNGTile[i]);
  for i := 0 to high(TitlePNGTile) do
    SDL_DestroySurface(TitlePNGTile[i]);
  for i := 0 to high(FPNGTile) do
    for j := 0 to high(FPNGTile[i]) do
      SDL_DestroySurface(FPNGTile[i, j]);
  SDL_DestroySurface(screen);
  SDL_DestroySurface(prescreen);
  SDL_DestroySurface(ImgScene);
  SDL_DestroySurface(ImgSceneBack);
  SDL_DestroySurface(ImgBField);
  SDL_DestroySurface(ImgBBuild);
end;

//获取某像素信息
function GetPixel(surface: PSDL_Surface; x: integer; y: integer): uint32;
begin
  if (x >= 0) and (x < surface.w) and (y >= 0) and (y < surface.h) then
  begin
    Result := PUint32(nativeuint(surface.pixels) + y * surface.pitch + x * 4)^;
  end;
end;

//画像素
procedure PutPixel(surface: PSDL_Surface; x: integer; y: integer; pixel: uint32);
begin
  if (x >= 0) and (x < surface.w) and (y >= 0) and (y < surface.h) then
  begin
    PUint32(nativeuint(surface.pixels) + y * surface.pitch + x * 4)^ := pixel;
  end;
end;

//显示tif, png, jpg等格式图片
procedure display_img(file_name: putf8char; x, y: integer);
var
  dest: TSDL_Rect;
begin
  if FileExists(file_name) {*Converted from FileExists*} then
  begin
    if ImageName <> file_name then
    begin
      SDL_DestroySurface(Image);
      Image := IMG_Load(file_name);
      ImageName := file_name;
    end;
    if (Image = nil) then
    begin
      //MessageBox(0, putf8char(Format('Couldn''t load %s : %s', [file_name, SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
    dest.x := x;
    dest.y := y;
    SDL_BlitSurface(Image, nil, screen, @dest);
    //MessageBox(0, putf8char(Format('BlitSurface error : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
    //SDL_UpdateRect2(screen, 0, 0, image.w, image.h);
  end;
end;

//取调色板的颜色, 视频系统为32位色, 但很多时候仍需要原调色板的颜色
function ColColor(num: byte): uint32;
begin
  Result := SDL_MapSurfaceRGB(screen, Acol[num * 3] * 4, Acol[num * 3 + 1] * 4, Acol[num * 3 + 2] * 4);
end;

//判断像素是否在屏幕内
function JudgeInScreen(px, py, w, h, xs, ys: integer): boolean;
begin
  Result := (px - xs + w >= 0) and (px - xs < screen.w) and (py - ys + h >= 0) and (py - ys < screen.h);
end;

//判断像素是否在指定范围内(重载)
function JudgeInScreen(px, py, w, h, xs, ys, xx, yy, xw, yh: integer): boolean;
begin
  Result := (px - xs + w >= xx) and (px - xs < xx + xw) and (py - ys + h >= yy) and (py - ys < yy + yh);
end;

//RLE8图片绘制子程, 所有相关子程均对此封装. 最后一个参数为亮度, 仅在绘制战场选择对方时使用
procedure DrawRLE8Pic(colorPanel: putf8char; num, px, py: integer; Pidx: Pinteger; Ppic: pbyte; RectArea: putf8char; Image: PSDL_Surface; widthI, heightI, sizeI: integer; shadow: integer); overload;
begin
  DrawRLE8Pic(colorPanel, num, px, py, Pidx, Ppic, RectArea, Image, widthI, heightI, sizeI, shadow, 0);

end;

//增加透明度选项
procedure DrawRLE8Pic(colorPanel: putf8char; num, px, py: integer; Pidx: Pinteger; Ppic: pbyte; RectArea: putf8char; Image: PSDL_Surface; widthI, heightI, sizeI: integer; shadow, alpha: integer); overload;
begin
  DrawRLE8Pic(colorPanel, num, px, py, Pidx, Ppic, RectArea, Image, widthI, heightI, sizeI, shadow, alpha, nil, nil, 0, 0, 0, 0, 0, 0);

end;

//这是改写的绘制RLE8图片程序, 增加了选调色板, 遮挡控制, 亮度, 半透明, 混合色等
//colorPanel: putf8char; 调色板的指针. 某些情况下需要使用静态调色板, 避免静态图跟随水的效果
//num, px, py: integer; 图片的编号和位置
//Pidx: Pinteger; Ppic: PByte; 图片的索引和内容的资源所在地
//RectArea: putf8char; 画图的范围; 所指向地址应为连续4个integer, 表示一个矩形, 仅图片的部分或全部会出现在这个矩形内才画
//Image: putf8char; widthI, heightI, sizeI: integer; 映像及其尺寸, 每单位长度（无用） 如果Img不为空则会将图画到这个镜像, 否则画到屏幕
//shadow, alpha: integer; 图片的暗度和透明度, 仅在画到屏幕上时有效
//BlockImageW: putf8char; 大小与场景和战场映像相同. 如果此地址不为空则会记录该像素的场景深度depth, 用于遮挡计算.
//BlockScreenR: putf8char; widthR, heightR, sizeR: integer; 该映像应该与屏幕像素数相同, 保存屏幕上每一点的深度
//depth: integer; 所画物件的绘图优先级
//当BlockImageW不为空时, 将该值写入BlockImageW
//但是需注意计算值在场景内包含高度的情况下是不准确的.
//当Image为空, 即画到屏幕上, 同时BlockPosition不为空时, 如果所绘像素的已有深度大于该深度, 则按照alpha绘制该像素
//即该值起作用的机会有两种: Image不为空到映像, 且BlockImageW不为空. 或者Image为空(到屏幕), 且BlockPosition不为空
//如果在画到屏幕时避免该值起作用, 可以设为一个很大的值
//MixColor: Uint32; MixAlpha: integer 图片的混合颜色和混合度, 仅在画到屏幕上时有效
procedure DrawRLE8Pic(colorPanel: putf8char; num, px, py: integer; Pidx: Pinteger; Ppic: pbyte; RectArea: putf8char; Image: PSDL_Surface; widthI, heightI, sizeI: integer; shadow, alpha: integer; BlockImageW: putf8char; BlockPosition: putf8char; widthW, heightW, sizeW: integer; depth: integer; mixColor: uint32; mixAlpha: integer); overload;
var
  w, h, xs, ys, x, y, blockx, blocky: smallint;
  offset, length, p, isAlpha, lenInt: integer;
  l, l1, ix, iy, pixdepth, curdepth, alpha1: integer;
  pix, colorin: uint32;
  pix1, pix2, pix3, pix4, color1, color2, color3, color4: byte;
  area: TSDL_Rect;
begin
  if num = 0 then
    offset := 0
  else
  begin
    Inc(Pidx, num - 1);
    offset := Pidx^;
  end;

  Inc(Ppic, offset);
  w := psmallint((Ppic))^;
  Inc(Ppic, 2);
  h := psmallint((Ppic))^;
  Inc(Ppic, 2);
  xs := psmallint((Ppic))^;
  Inc(Ppic, 2);
  ys := psmallint((Ppic))^;
  Inc(Ppic, 2);
  pixdepth := 0;

  //if (num >= 1916) and (num <= 1941) then h := h - 50;
  if Image = nil then
    Image := screen;

  if RectArea <> nil then
  begin
    area := PSDL_Rect(RectArea)^;
  end
  else
  begin
    area.x := 0;
    area.y := 0;
    area.w := Image.w;
    area.h := Image.h;
  end;
  if (BlockPosition <> nil) then
  begin
    blockx := Pinteger(BlockPosition)^;
    blocky := Pinteger(BlockPosition + 4)^;
  end;
  alpha1 := (alpha shr 8) and $FF;
  if ((w > 1) or (h > 1)) and (px - xs + w >= area.x) and (px - xs < area.x + area.w) and (py - ys + h >= area.y) and (py - ys < area.y + area.h) then
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
          if (x >= area.x) and (y >= area.y) and (x < area.x + area.w) and (y < area.y + area.h) then
          begin
            pix1 := pbyte(colorPanel + l1 * 3)^ * (4 + shadow);
            pix2 := pbyte(colorPanel + l1 * 3 + 1)^ * (4 + shadow);
            pix3 := pbyte(colorPanel + l1 * 3 + 2)^ * (4 + shadow);
            pix4 := 0;
            //pix := sdl_maprgba(screen.format, pix1, pix2, pix3, pix4);
            if Image = screen then
            begin
              if mixAlpha <> 0 then
              begin
                SDL_GetRGBA(mixColor, SDL_GetPixelFormatDetails(screen.format), SDL_GetSurfacePalette(screen), @color1, @color2, @color3, @color4);
                pix1 := (mixAlpha * color1 + (100 - mixAlpha) * pix1) div 100;
                pix2 := (mixAlpha * color2 + (100 - mixAlpha) * pix2) div 100;
                pix3 := (mixAlpha * color3 + (100 - mixAlpha) * pix3) div 100;
                pix4 := (mixAlpha * color4 + (100 - mixAlpha) * pix4) div 100;
                //pix := pix1 + pix2 shl 8 + pix3 shl 16 + pix4 shl 24;
              end;
              if (alpha <> 0) then
              begin
                if (BlockImageW = nil) then
                begin
                  isAlpha := 1;
                end
                else
                begin
                  //以下表示需要遮挡
                  //被遮挡的像素按照低位计算, 未被遮挡的按照高位计算
                  if (x < blockx + screen.w) and (y < blocky + screen.h) then
                  begin
                    pixdepth := psmallint(BlockImageW + ((x + blockx) * heightW + y + blocky) * sizeW)^;
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
                if (isAlpha = 1) and (alpha < 100) then
                begin
                  colorin := GetPixel(screen, x, y);
                  SDL_GetRGBA(colorin, SDL_GetPixelFormatDetails(screen.format), SDL_GetSurfacePalette(screen), @color1, @color2, @color3, @color4);
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
                if (isAlpha = 0) and (alpha1 > 0) and (alpha1 <= 100) then
                begin
                  colorin := GetPixel(screen, x, y);
                  SDL_GetRGBA(colorin, SDL_GetPixelFormatDetails(screen.format), SDL_GetSurfacePalette(screen), @color1, @color2, @color3, @color4);
                  //pix1 := pix and $FF;
                  //color1 := colorin and $FF;
                  //pix2 := pix shr 8 and $FF;
                  //color2 := colorin shr 8 and $FF;
                  //pix3 := pix shr 16 and $FF;
                  //color3 := colorin shr 16 and $FF;
                  //pix4 := pix shr 24 and $FF;
                  //color4 := colorin shr 24 and $FF;
                  pix1 := (alpha1 * color1 + (100 - alpha1) * pix1) div 100;
                  pix2 := (alpha1 * color2 + (100 - alpha1) * pix2) div 100;
                  pix3 := (alpha1 * color3 + (100 - alpha1) * pix3) div 100;
                  pix4 := (alpha1 * color4 + (100 - alpha1) * pix4) div 100;
                  //pix := pix1 + pix2 shl 8 + pix3 shl 16 + pix4 shl 24;
                end;
              end;
              pix := SDL_MapSurfaceRGBA(screen, pix1, pix2, pix3, 255);
              if (alpha < 100) or (pixdepth <= curdepth) then
              begin
                PutPixel(screen, x, y, pix);
              end;
            end
            else
            begin
              if (x < widthI) and (y < heightI) then
              begin
                if (BlockImageW <> nil) then
                begin
                  //if (depth < 0) then
                  //depth := (py div 9 - 1);
                  psmallint(BlockImageW + (x * heightI + y) * sizeI)^ := depth;
                end;
                pix := SDL_MapSurfaceRGBA(screen, pix1, pix2, pix3, 255);
                PutPixel(Image, x, y, pix);
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

//big5转utf8
function cp950toutf8(str: pansichar; len: integer = -1): utf8string;
begin
  Result := transcode(utf8string(str), 950, 65001);
end;

//utf8转big5
function utf8tocp950(constref str: utf8string): ansistring;
begin
  Result := transcode(str, 65001, 950);
end;

function transcode(constref str: utf8string; input, output: integer): utf8string;
var
  len: integer;
  strw: widestring;
  instr, outstr: ansistring;
begin
  {$IFDEF fpc}
  instr := 'cp' + IntToStr(input);
  outstr := 'cp' + IntToStr(output);
  if input = 65001 then
    instr := 'utf8';
  if output = 65001 then
    outstr := 'utf8';
  Result := ConvertEncoding(str, instr, outstr);
  {$ELSE}
  len := MultiByteToWideChar(input, 0, @str[1], -1, nil, 0);
  setlength(strw, len - 1);
  MultiByteToWideChar(input, 0, @str[1], length(str), @strw[1], len + 1);
  len := WideCharToMultiByte(output, 0, @strw[1], -1, nil, 0, nil, nil);
  setlength(Result, len - 1);
  WideCharToMultiByte(output, 0, @strw[1], length(strw), @Result[1], len - 1, nil, nil);
  {$ENDIF}
end;

//显示utf-8文字
procedure DrawText(sur: PSDL_Surface; word: utf8string; x_pos, y_pos: integer; color: uint32);
var
  dest, src: TSDL_Rect;
  tempcolor: TSDL_Color;
  len, i, k: integer;
  word0: array [0 .. 4] of utf8char;
  Text: PSDL_Surface;
  r, g, b: byte;
  got: bool;
begin
  if SIMPLE = 1 then
  begin
    word := Traditional2Simplified(putf8char(word));
  end;
  SDL_GetRGB(color, SDL_GetPixelFormatDetails(sur.format), SDL_GetSurfacePalette(sur), @r, @g, @b);
  tempcolor.r := 255;
  tempcolor.g := 255;
  tempcolor.b := 255;
  tempcolor.a := 255;
  dest.x := x_pos;
  len := length(word);
  if len = 0 then
    exit;
  i := 1;
  while True do
  begin
    if (byte(word[i]) > 32) and (byte(word[i]) < 128) then
    begin
      word0[1] := word[i];
      word0[2] := utf8char(0);
      k := byte(word0[1]);
      if not fonts.ContainsKey(k) then
      begin
        kyslog('%s(%d)', [midstr(word, i, 1), fonts.Count], False);
        fonts.add(k, TTF_RenderText_blended(engfont, @word0[1], 1, tempcolor));
      end;
      Text := fonts.Items[k];
      dest.x := x_pos;
      dest.y := y_pos + 2;
      SDL_SetSurfaceColorMod(Text, r, g, b);
      SDL_SetSurfaceBlendMode(Text, SDL_BLENDMODE_BLEND);
      SDL_SetSurfaceAlphaMod(Text, 255);
      SDL_BlitSurface(Text, nil, sur, @dest);
      //SDL_DestroySurface(Text);
      //i := i + 1;
    end;
    if (byte(word[i]) >= $c0) and (byte(word[i]) < $e0) then
    begin
      word0[1] := word[i];
      word0[2] := word[i + 1];
      word0[3] := utf8char(0);
      word0[4] := utf8char(0);
      k := byte(word0[1]) + 256 * byte(word0[2]) + 65536 * byte(word0[3]);
      if not fonts.ContainsKey(k) then
      begin
        kyslog('%s(%d)', [midstr(word, i, 2), fonts.Count], False);
        fonts.add(k, TTF_RenderText_blended(font, @word0[1], 2, tempcolor));
      end;
      got := fonts.TryGetValue(k, Text);
      dest.x := x_pos;
      dest.y := y_pos;
      SDL_SetSurfaceColorMod(Text, r, g, b);
      SDL_SetSurfaceBlendMode(Text, SDL_BLENDMODE_BLEND);
      SDL_SetSurfaceAlphaMod(Text, 255);
      SDL_BlitSurface(Text, nil, sur, @dest);
      //SDL_DestroySurface(Text);
      i := i + 1;
    end;
    if (byte(word[i]) >= $e0) then
    begin
      word0[1] := word[i];
      word0[2] := word[i + 1];
      word0[3] := word[i + 2];
      word0[4] := utf8char(0);
      k := byte(word0[1]) + 256 * byte(word0[2]) + 65536 * byte(word0[3]);
      if not fonts.ContainsKey(k) then
      begin
        kyslog('%s(%d)', [midstr(word, i, 3), fonts.Count], False);
        fonts.add(k, TTF_RenderText_blended(font, @word0[1], 3, tempcolor));
      end;
      got := fonts.TryGetValue(k, Text);
      dest.x := x_pos;
      dest.y := y_pos;
      SDL_SetSurfaceColorMod(Text, r, g, b);
      SDL_SetSurfaceBlendMode(Text, SDL_BLENDMODE_BLEND);
      SDL_SetSurfaceAlphaMod(Text, 255);
      SDL_BlitSurface(Text, nil, sur, @dest);
      //SDL_DestroySurface(Text);
      x_pos := x_pos + 10;
      i := i + 2;
    end;
    x_pos := x_pos + 10;
    i := i + 1;
    if i > len then
      break;
  end;
end;

//显示英文
procedure DrawEngText(sur: PSDL_Surface; constref word: utf8string; x_pos, y_pos: integer; color: uint32);
var
  dest: TSDL_Rect;
  a: uint8;
  tempcolor: TSDL_Color;
  Text: PSDL_Surface;
  r, g, b: byte;
begin
  DrawText(sur, word, x_pos, y_pos + 2, color);
end;

//显示unicode中文阴影文字, 即将同样内容显示2次, 间隔1像素
procedure DrawShadowText(sur: PSDL_Surface; constref word: utf8string; x_pos, y_pos: integer; color1, color2: uint32); overload;
begin
  DrawText(sur, word, x_pos + 1, y_pos, color2);
  DrawText(sur, word, x_pos, y_pos, color1);
end;

procedure DrawShadowText(constref word: utf8string; x_pos, y_pos: integer; color1, color2: uint32); overload;
begin
  DrawText(screen, word, x_pos + 1, y_pos, color2);
  DrawText(screen, word, x_pos, y_pos, color1);
end;

//显示英文阴影文字
procedure DrawEngShadowText(sur: PSDL_Surface; constref word: utf8string; x_pos, y_pos: integer; color1, color2: uint32);
begin
  DrawEngText(sur, word, x_pos + 1, y_pos, color2);
  DrawEngText(sur, word, x_pos, y_pos, color1);
end;

//显示big5文字
procedure DrawBig5Text(sur: PSDL_Surface; str: pansichar; x_pos, y_pos: integer; color: uint32);
var
  len: integer;
  words: utf8string;
begin
  words := cp950toutf8(str);
  DrawText(sur, words, x_pos, y_pos, color);
end;

//显示big5阴影文字
procedure DrawBig5ShadowText(sur: PSDL_Surface; word: pansichar; x_pos, y_pos: integer; color1, color2: uint32);
var
  len: integer;
  words: utf8string;
begin
  words := cp950toutf8(word);
  DrawText(sur, words, x_pos + 1, y_pos, color2);
  DrawText(sur, words, x_pos, y_pos, color1);
end;

//显示带边框的文字, 仅用于unicode, 需自定义宽度
procedure DrawTextWithRect(constref word: utf8string; x, y, w: integer; color1, color2: uint32); overload;
begin
  DrawTextWithRect(screen, word, x, y, w, color1, color2);
end;

procedure DrawTextWithRect(sur: PSDL_Surface; constref word: utf8string; x, y, w: integer; color1, color2: uint32); overload;
var
  len: integer;
  p: putf8char;
begin
  DrawRectangle(sur, x, y, w, 28, 0, ColColor(255), 50);
  DrawShadowText(sur, word, x + 3, y + 2, color1, color2);
  SDL_UpdateRect2(screen, x, y, w + 1, 29);
end;

//画带边框矩形, (x坐标, y坐标, 宽度, 高度, 内部颜色, 边框颜色, 透明度）
procedure DrawRectangle(sur: PSDL_Surface; x, y, w, h: integer; colorin, colorframe: uint32; alpha: integer);
var
  i1, i2, l1, l2, l3, l4: integer;
  tempscr: PSDL_Surface;
  dest: TSDL_Rect;
  r, g, b, r1, g1, b1, a: byte;
begin
  tempscr := SDL_CreateSurface(w + 1, h + 1, SDL_GetPixelFormatForMasks(32, Rmask, Gmask, Bmask, Amask));
  SDL_GetRGB(colorin, SDL_GetPixelFormatDetails(tempscr.format), SDL_GetSurfacePalette(tempscr), @r, @g, @b);
  SDL_GetRGB(colorframe, SDL_GetPixelFormatDetails(tempscr.format), SDL_GetSurfacePalette(tempscr), @r1, @g1, @b1);
  SDL_FillSurfaceRect(tempscr, nil, SDL_MapSurfaceRGBA(tempscr, r, g, b, alpha * 255 div 100));
  dest.x := x;
  dest.y := y;
  dest.w := 0;
  dest.h := 0;
  for i1 := 0 to w do
    for i2 := 0 to h do
    begin
      l1 := i1 + i2;
      l2 := -(i1 - w) + (i2);
      l3 := (i1) - (i2 - h);
      l4 := -(i1 - w) - (i2 - h);
      //4边角
      if not ((l1 >= 4) and (l2 >= 4) and (l3 >= 4) and (l4 >= 4)) then
      begin
        PutPixel(tempscr, i1, i2, 0);
      end;
      //框线
      if (((l1 >= 4) and (l2 >= 4) and (l3 >= 4) and (l4 >= 4) and ((i1 = 0) or (i1 = w) or (i2 = 0) or (i2 = h))) or ((l1 = 4) or (l2 = 4) or (l3 = 4) or (l4 = 4))) then
      begin
        //a := round(200 - min(abs(i1/w-0.5),abs(i2/h-0.5))*2 * 100);
        a := round(250 - abs(i1 / w + i2 / h - 1) * 150);
        //writeln(a);
        PutPixel(tempscr, i1, i2, SDL_MapSurfaceRGBA(tempscr, r1, g1, b1, a));
      end;
    end;
  SDL_BlitSurface(tempscr, nil, sur, @dest);
  SDL_DestroySurface(tempscr);
end;

//画不含边框的矩形, 用于对话和黑屏
procedure DrawRectangleWithoutFrame(sur: PSDL_Surface; x, y, w, h: integer; colorin: uint32; alpha: integer);
var
  tempscr: PSDL_Surface;
  dest: TSDL_Rect;
begin
  tempscr := SDL_CreateSurface(w, h, SDL_GetPixelFormatForMasks(32, Rmask, Gmask, Bmask, Amask));
  SDL_FillSurfaceRect(tempscr, nil, colorin or $FF000000);
  SDL_SetSurfaceAlphaMod(tempscr, alpha * 255 div 100);
  dest.x := x;
  dest.y := y;
  SDL_BlitSurface(tempscr, nil, sur, @dest);
  SDL_DestroySurface(tempscr);
end;

//调色板变化, 贴图闪烁效果
procedure ChangeCol;
var
  i, i1, i2, a, b, add0, len: integer;
  temp: array [0 .. 2] of byte;
  now, next_time: uint32;
  p, p0, p1, p2: real;
begin
  now := SDL_GetTicks;
  if (NIGHT_EFFECT = 1) then
  begin
    now_time := now_time + 0.3;
    if now_time > 1440 then
      now_time := 0;
    p := now_time / 1440;
    //writeln(p);
    if p > 0.5 then
      p := 1 - p;
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
    move(Acol1[0], Acol[0], 768);
  end;

  add0 := $E0;
  len := 8;
  a := now div 200 mod len;
  move(Acol1[add0 * 3], Acol[add0 * 3 + a * 3], (len - a) * 3);
  move(Acol1[add0 * 3 + (len - a) * 3], Acol[add0 * 3], a * 3);

  add0 := $F4;
  len := 9;
  a := now div 200 mod len;
  move(Acol1[add0 * 3], Acol[add0 * 3 + a * 3], (len - a) * 3);
  move(Acol1[add0 * 3 + (len - a) * 3], Acol[add0 * 3], a * 3);

end;

//绘制PNG贴图相关的代码
//这里的可能较旧, 可以参照水浒的
procedure DrawPNGTile(PNGIndex: TPNGIndex; FrameNum: integer; RectArea: putf8char; scr: PSDL_Surface; px, py: integer); overload;
begin
end;

procedure DrawPNGTile(PNGIndex: TPNGIndex; FrameNum: integer; RectArea: putf8char; scr: PSDL_Surface; px, py: integer; shadow, alpha: integer; mixColor: uint32; mixAlpha: integer); overload;
begin
end;

procedure DrawPNGTile(PNGIndex: TPNGIndex; FrameNum: integer; RectArea: putf8char; scr: PSDL_Surface; px, py: integer; shadow, alpha: integer; mixColor: uint32; mixAlpha: integer; depth: integer; BlockImgR: putf8char; Width, Height, size, leftupx, leftupy: integer); overload;
var
  dest, area: TSDL_Rect;
  tempscr, tempscrfront, tempscrback, CurSurface: PSDL_Surface;
  pixdepth, i1, i2: integer;
  tran: byte;
  bigtran, pixel, Mask, AlphaValue: uint32;
  x1, x2, y1, y2: integer;
  lenInt: integer;
begin

end;

procedure SetPNGTileBlock(PNGIndex: TPNGIndex; px, py, depth: integer; BlockImageW: putf8char; Width, Height, size: integer);
var
  i, i1, i2, x1, y1: integer;
  CurSurface: PSDL_Surface;
begin

end;

{function TestPNGTile(PNGTile: TPNGTile; num: integer): boolean;
  begin

  end;}

procedure SDL_UpdateRect2(scr1: PSDL_Surface; x, y, w, h: integer);
var
  realx, realy, realw, realh, ZoomType: integer;
  tempscr: PSDL_Surface;
  now, Next: uint32;
  dest: TSDL_Rect;
  p: pointer;
  //TextureID: GLUint;
begin
  dest.x := x;
  dest.y := y;
  dest.w := w;
  dest.h := h;
  if w <= 0 then
    dest.w := CENTER_X * 2;
  if h <= 0 then
    dest.h := CENTER_Y * 2;
  if scr1 = screen then
  begin
    //Here p is the address to the pixel we want to set
    p := pointer(nativeuint(screen.pixels) + y * screen.pitch + x * 4);
    SDL_UpdateTexture(screenTex, @dest, p, screen.pitch);
    SDL_RenderTexture(render, screenTex, nil, nil);
    SDL_RenderPresent(render);
  end;
end;

procedure SDL_GetMouseState2(var x, y: integer);
var
  tempx, tempy: single;
begin
  SDL_GetMouseState(@tempx, @tempy);
  x := round(tempx * screen.w / RESOLUTIONX);
  y := round(tempy * screen.h / RESOLUTIONY);

end;

procedure ResizeWindow(w, h: integer);
begin
  RESOLUTIONX := w;
  RESOLUTIONY := h;
end;

procedure SwitchFullscreen;
begin

end;

procedure QuitConfirm;
var
  tempscr: PSDL_Surface;
  menuString: array [0 .. 1] of utf8string;
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
    tempscr := SDL_ConvertSurface(screen, screen.format);
    SDL_BlitSurface(tempscr, nil, screen, nil);
    DrawRectangleWithoutFrame(screen, 0, 0, screen.w, screen.h, 0, 50);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    menuString[0] := '取消';
    menuString[1] := '確認';
    if CommonMenu(CENTER_X * 2 - 50, 2, 45, 1, menuString) = 1 then
      Quit;
    Redraw(1);
    SDL_BlitSurface(tempscr, nil, screen, nil);
    SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);
    SDL_DestroySurface(tempscr);
    AskingQuit := False;
  end;

end;

function CheckBasicEvent: uint32;
var
  i, x, y: integer;
  msCount: uint32;
  msWait: uint32;

  function inReturn(x, y: integer): boolean; inline;
  begin
    Result := InRegion(x, y, CENTER_X * 2 - 200, CENTER_Y * 2 - 100, 100, 100);
  end;

  function inEscape(x, y: integer): boolean; inline;
  begin
    Result := InRegion(x, y, CENTER_X * 2 - 100, CENTER_Y * 2 - 200, 100, 100);
  end;

  function inSwitchShowVirtualKey(x, y: integer): boolean; inline;
  begin
    //Result := (x > CENTER_X * 2 - 100) and (y < 100);
    Result := False;
  end;

  function inVirtualKey(x, y: integer; var key: uint32): uint32;
  begin
    Result := 0;
    //if InRegion(x, y, CENTER_X * 2 - 200, CENTER_Y * 2 - 200, 100, 100) then
      //Result := SDLK_TAB;
    if InRegion(x, y, CENTER_X * 2 - 100, CENTER_Y * 2 - 100, 100, 100) then
      Result := SDLK_TAB;
    if InRegion(x, y, VirtualKeyX - VirtualKeySize, VirtualKeyY, VirtualKeySize * 3, VirtualKeySize * 3) then
      Result := SDLK_TAB;
    if InRegion(x, y, VirtualKeyX, VirtualKeyY, VirtualKeySize, VirtualKeySize) then
      Result := SDLK_UP;
    if InRegion(x, y, VirtualKeyX - VirtualKeySize, VirtualKeyY + VirtualKeySize, VirtualKeySize, VirtualKeySize) then
      Result := SDLK_LEFT;
    if InRegion(x, y, VirtualKeyX, VirtualKeyY + VirtualKeySize * 2, VirtualKeySize, VirtualKeySize) then
      Result := SDLK_DOWN;
    if InRegion(x, y, VirtualKeyX + VirtualKeySize, VirtualKeyY + VirtualKeySize, VirtualKeySize, VirtualKeySize) then
      Result := SDLK_RIGHT;
    key := Result;
  end;

begin
  //if not ((LoadingTiles) or (LoadingScene)) then
  SDL_FlushEvent(SDL_EVENT_MOUSE_WHEEL);
  SDL_FlushEvent(SDL_EVENT_JOYSTICK_AXIS_MOTION);
  SDL_FlushEvent(SDL_EVENT_FINGER_MOTION);
  //SDL_FlushEvent(SDL_EVENT_FINGER_DOWN);
  //SDL_FlushEvent(SDL_EVENT_FINGER_UP);
  if CellPhone = 1 then
    SDL_FlushEvent(SDL_EVENT_MOUSE_MOTION);
  //writeln(inttohex(event.type_, 4));
  //JoyAxisMouse;
  Result := event.type_;
  case event.type_ of
    SDL_EVENT_JOYSTICK_BUTTON_UP:
    begin
      event.type_ := SDL_EVENT_KEY_UP;
      if event.jbutton.button = JOY_ESCAPE then
        event.key.key := SDLK_ESCAPE
      else if event.jbutton.button = JOY_RETURN then
        event.key.key := SDLK_RETURN
      else if event.jbutton.button = JOY_MOUSE_LEFT then
      begin
        event.button.button := SDL_BUTTON_LEFT;
        event.type_ := SDL_EVENT_MOUSE_BUTTON_UP;
      end
      else if event.jbutton.button = JOY_UP then
        event.key.key := SDLK_UP
      else if event.jbutton.button = JOY_DOWN then
        event.key.key := SDLK_DOWN
      else if event.jbutton.button = JOY_LEFT then
        event.key.key := SDLK_LEFT
      else if event.jbutton.button = JOY_RIGHT then
        event.key.key := SDLK_RIGHT;
    end;
    SDL_EVENT_JOYSTICK_BUTTON_DOWN:
    begin
      event.type_ := SDL_EVENT_KEY_DOWN;
      if event.jbutton.button = JOY_UP then
        event.key.key := SDLK_UP
      else if event.jbutton.button = JOY_DOWN then
        event.key.key := SDLK_DOWN
      else if event.jbutton.button = JOY_LEFT then
        event.key.key := SDLK_LEFT
      else if event.jbutton.button = JOY_RIGHT then
        event.key.key := SDLK_RIGHT;
    end;
    SDL_EVENT_JOYSTICK_HAT_MOTION:
    begin
      event.type_ := SDL_EVENT_KEY_DOWN;
      case event.jhat.Value of
        SDL_HAT_UP: event.key.key := SDLK_UP;
        SDL_HAT_DOWN: event.key.key := SDLK_DOWN;
        SDL_HAT_LEFT: event.key.key := SDLK_LEFT;
        SDL_HAT_RIGHT: event.key.key := SDLK_RIGHT;
      end;
    end;
    SDL_EVENT_FINGER_MOTION:
      if CellPhone = 1 then
      begin
        if event.tfinger.fingerId = 1 then
        begin
          msCount := SDL_GetTicks() - FingerTick;
          msWait := 50;
          if BattleSelecting then
            msWait := 100;
          if msCount > 500 then
            FingerCount := 1;
          if ((FingerCount <= 2) and (msCount > 200)) or ((FingerCount > 2) and (msCount > msWait)) then
          begin
            FingerCount := FingerCount + 1;
            FingerTick := SDL_GetTicks();
            event.type_ := SDL_EVENT_KEY_DOWN;
            event.key.key := AngleToDirection(event.tfinger.dy, event.tfinger.dx);
          end;
        end;
      end;
    SDL_EVENT_FINGER_UP: ;
    SDL_EVENT_QUIT: QuitConfirm;
    SDL_EVENT_WINDOW_RESIZED:
    begin
      ResizeWindow(event.window.data1, event.window.data2);
    end;
    SDL_EVENT_DID_ENTER_FOREGROUND: PlayMP3(nowmusic, -1, 0);
    SDL_EVENT_DID_ENTER_BACKGROUND: StopMP3(0);
    {SDL_EVENT_MOUSE_BUTTON_DOWN:
      if (CellPhone = 1) and (event.button.button = SDL_BUTTON_LEFT) then
      begin
      SDL_GetMouseState(@x, @y);
      end;}
    SDL_EVENT_MOUSE_MOTION:
    begin
      if CellPhone = 1 then
      begin
        FingerCount := 0;
        SDL_GetMouseState2(x, y);
        if inEscape(x, y) or inReturn(x, y) then
          event.type_ := 0;
        inVirtualKey(x, y, VirtualKeyValue);
      end;
    end;
    SDL_EVENT_MOUSE_BUTTON_DOWN:
    begin
      if (CellPhone = 1) and (showVirtualKey <> 0) then
      begin
        SDL_GetMouseState2(x, y);
        inVirtualKey(x, y, VirtualKeyValue);
        if VirtualKeyValue <> 0 then
        begin
          event.type_ := SDL_EVENT_KEY_DOWN;
          event.key.key := VirtualKeyValue;
        end;
      end;
    end;
    SDL_EVENT_KEY_UP, SDL_EVENT_MOUSE_BUTTON_UP:
    begin
      if (CellPhone = 1) and (event.type_ = SDL_EVENT_MOUSE_BUTTON_UP) and (event.button.button = SDL_BUTTON_LEFT) then
      begin
        SDL_GetMouseState2(x, y);
        if inEscape(x, y) then
        begin
          //event.button.x := RESOLUTIONX div 2;
          //event.button.y := RESOLUTIONY div 2;
          event.button.button := SDL_BUTTON_RIGHT;
          event.key.key := SDLK_ESCAPE;
          kyslog('Change to escape');
        end
        else if inReturn(x, y) then
        begin
          //event.button.x := RESOLUTIONX div 2;
          //event.button.y := RESOLUTIONY div 2;
          event.type_ := SDL_EVENT_KEY_UP;
          event.key.key := SDLK_RETURN;
          kyslog('Change to return');
        end
        else if (showVirtualKey <> 0) and (inVirtualKey(x, y, VirtualKeyValue) <> 0) then
        begin
          if VirtualKeyValue <> 0 then
          begin
            event.type_ := SDL_EVENT_KEY_UP;
            event.key.key := VirtualKeyValue;
          end;
        end
        else if inSwitchShowVirtualKey(x, y) then
        begin
          showVirtualKey := not showVirtualKey;
        end
        //手机在战场仅有确认键有用
        else if (where = 2) and (BattleSelecting) then
        begin
          event.button.button := 0;
        end;
        //第二指不触发事件
        if FingerCount >= 1 then
          event.button.button := 0;
      end;
      if (where = 2) and ((event.key.key = SDLK_ESCAPE) or (event.button.button = SDL_BUTTON_RIGHT)) then
      begin
        for i := 0 to BRoleAmount - 1 do
        begin
          if Brole[i].Team = 0 then
            Brole[i].Auto := 0;
        end;
      end;
      if event.key.key = SDLK_KP_ENTER then
        event.key.key := SDLK_RETURN;
    end;
  end;
  //CheckRenderTextures;
end;

function AngleToDirection(y, x: real): integer;
var
  angle: real;
  angleregion: real;
begin
  Result := 0;
  angle := arctan2(-y, x);
  angleregion := PI / 4;
  //注意这里的判断方法可能并不准确

  if (abs(angle + PI / 8) < angleregion) then
    Result := SDLK_RIGHT;
  if (abs(angle - PI * 3 / 8) < angleregion) then
    Result := SDLK_UP;
  if (abs(angle - PI * 7 / 8) < angleregion) or (angle < -PI * 7 / 8) then
    Result := SDLK_LEFT;
  if (abs(angle + PI * 5 / 8) < angleregion) then
    Result := SDLK_DOWN;
  if ScreenRotate = 1 then
    case Result of
      SDLK_UP: Result := SDLK_LEFT;
      SDLK_DOWN: Result := SDLK_RIGHT;
      SDLK_LEFT: Result := SDLK_DOWN;
      SDLK_RIGHT: Result := SDLK_UP;
    end;
end;

function DrawLength(str: utf8string): integer; overload;
var
  l, i: integer;
begin
  i := 1;
  Result := 0;
  while i <= length(str) do
  begin
    if (byte(str[i]) >= 128) and (byte(str[i]) < $c0) then
    begin
      Result := Result + 1;
      i := i + 2;
    end
    else if (byte(str[i]) >= $e0) then
    begin
      Result := Result + 2;
      i := i + 3;
    end
    else
    begin
      Result := Result + 1;
      i := i + 1;
    end;
  end;
end;

function DrawLength(p: putf8char): integer; overload;
begin
  Result := DrawLength(utf8string(p));
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

//屏幕整体变半透明黑
procedure TransBlackScreen;
begin
  DrawRectangleWithoutFrame(screen, 0, 0, CENTER_X * 2, CENTER_Y * 2, 0, 50);
end;

//清键值
procedure CleanKeyValue;
begin
  event.key.key := 0;
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

//判断鼠标是否在区域内, 以画布的坐标为准
//第二个函数会返回鼠标的画布位置
function MouseInRegion(x, y, w, h: integer): boolean; overload;
var
  x1, y1: integer;
begin
  SDL_GetMouseState2(x1, y1);
  Result := (x1 >= x) and (y1 >= y) and (x1 < x + w) and (y1 < y + h);
end;

function MouseInRegion(x, y, w, h: integer; var x1, y1: integer): boolean; overload;
begin
  SDL_GetMouseState2(x1, y1);
  Result := (x1 >= x) and (y1 >= y) and (x1 < x + w) and (y1 < y + h);
end;

//限制变量的范围
function RegionParameter(x, x1, x2: integer): integer;
var
  px: integer;
begin
  if x < x1 then
    x := x1;
  if x > x2 then
    x := x2;
  Result := x;
end;

procedure QuickSortB(var a: array of TBuildInfo; l, r: integer);
var
  i, j: integer;
  x, t: TBuildInfo;
begin
  i := l;
  j := r;
  x := a[(l + r) div 2];
  repeat
    while a[i].c < x.c do
      Inc(i);
    while a[j].c > x.c do
      Dec(j);
    if i <= j then
    begin
      t := a[i];
      a[i] := a[j];
      a[j] := t;
      Inc(i);
      Dec(j);
    end;
  until i > j;
  if i < r then
    QuickSortB(a, i, r);
  if l < j then
    QuickSortB(a, l, j);
end;

function Simplified2Traditional(str: utf8string): utf8string;
var
  l: integer;
begin
  {$ifdef windows}
  str := transcode(str, 65001, 936);
  l := length(str);
  setlength(Result, l + 3);
  Result[l + 1] := char(0);
  if l > 0 then
    LCMapStringA($0800, $4000000, @str[1], l, @Result[1], l);
  Result := transcode(Result, 936, 65001);
  {$else}
  Result := str;
  {$endif}
  //writeln(L,str,',',result,GetUserDefaultLCID);
end;

//繁体汉字转化成简体汉字
function Traditional2Simplified(str: utf8string): utf8string; //返回繁体字符串
var
  L: integer;
begin
  {$IFDEF windows}
  str := UTF8ToCP936(str);
  L := Length(str);
  SetLength(Result, L + 1);
  Result[L + 1] := char(0);
  if L > 0 then
    LCMapString($0800, $02000000, putf8char(str), L, @Result[1], L);
  Result := CP936TOUTF8(Result);
  {$ELSE}
  Result := str;
  {$ENDIF}
end;

{$IFDEF mswindows}

procedure tic;
begin
  QueryPerformanceFrequency(tttt);
  QueryPerformanceCounter(cccc1);
  //tttt := SDL_GetTicks;
end;

procedure toc;
begin
  QueryPerformanceCounter(cccc2);
  kyslog(' %3.2f us', [(cccc2 - cccc1) / tttt * 1E6]);
end;

{$ELSE}

procedure tic;
begin
  tttt := SDL_GetTicks;
end;

procedure toc;
begin
  kyslog(' %d ms', [SDL_GetTicks - tttt]);
end;

{$ENDIF}

procedure kyslog(formatstring: utf8string; content: array of const; cr: boolean = True); overload;
var
  i: integer;
  str: utf8string;
begin
  str := format(formatstring, content);
  SDL_log('%s', [@str[1]]);
end;

procedure kyslog(formatstring: string = ''; cr: boolean = True); overload;
var
  i: integer;
  str: utf8string;
begin
  SDL_log('%s', [@formatstring[1]]);
end;

function utf8follow(c1: utf8char): integer;
var
  c: byte;
begin
  c := byte(c1);
  if (c and $80) = 0 then
    Result := 1
  else if (c and $E0) = $C0 then
    Result := 2
  else if (c and $F0) = $E0 then
    Result := 3
  else if (c and $F8) = $F0 then
    Result := 4
  else if (c and $FC) = $F8 then
    Result := 5
  else if (c and $FE) = $FC then
    Result := 6
  else
    Result := 1;    //skip one char
end;

function checkFileName(f: utf8string): utf8string;
begin
  Result := AppPath + f;
  if (not fileexists(Result)) then
    Result := AppPathCommon + f;
end;

function InRegion(x1, y1, x, y, w, h: integer): boolean;
begin
  Result := (x1 >= x) and (y1 >= y) and (x1 < x + w) and (y1 < y + h);
end;

end.
