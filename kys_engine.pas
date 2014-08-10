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
  SDL2_TTF,
  SDL2_image,
  SDL2,
  bassmidi,
  bass,
  ziputils,
  unzip,
  kys_main,
  kys_type,
  mythoutput;

function EventFilter(p: pointer; e: PSDL_Event): longint; cdecl;
//音频子程
procedure InitialMusic;
procedure PlayMP3(MusicNum, times: integer; frombeginning: integer = 1); overload;
procedure PlayMP3(filename: pchar; times: integer); overload;
procedure StopMP3(frombeginning: integer = 1);
procedure PlaySoundE(SoundNum, times: integer); overload;
procedure PlaySoundE(SoundNum: integer); overload;
procedure PlaySoundE(SoundNum, times, x, y, z: integer); overload;
//procedure PlaySoundE(filename: pchar; times: integer); overload;
procedure PlaySoundA(SoundNum, times: integer);

//用于读取的子程
procedure ReadTiles;
function ReadFileToBuffer(p: pchar; filename: string; size, malloc: integer): pchar;
procedure FreeFileBuffer(var p: pchar);
function LoadIdxGrp(stridx, strgrp: string; var idxarray: TIntArray; var grparray: TByteArray): integer;
function LoadPNGTiles(path: string; var PNGIndexArray: TPNGIndexArray; var SurfaceArray: TSurfaceArray;
  LoadPic: integer = 1): integer;
procedure LoadOnePNGTile(path: string; p: pchar; filenum: integer; var PNGIndex: TPNGIndex;
  SurfacePointer: PPSDL_Surface; forceLoad: integer = 0);
function LoadSurfaceFromFile(filename: string): PSDL_Surface;
function LoadSurfaceFromMem(p: pchar; len: integer): PSDL_Surface;
function LoadSurfaceFromZIPFile(zipFile: unzFile; filename: string): PSDL_Surface;
procedure FreeAllSurface;

//基本绘图子程
function GetPixel(surface: PSDL_Surface; x: integer; y: integer): uint32;
procedure PutPixel(surface: PSDL_Surface; x: integer; y: integer; pixel: uint32);
procedure display_bmp(file_name: pchar; x, y: integer);
procedure display_img(file_name: pchar; x, y: integer);
function ColColor(num: byte): uint32;
procedure DrawRectangle(sur: PSDL_Surface; x, y, w, h: integer; colorin, colorframe: uint32; alpha: integer);
procedure DrawRectangleWithoutFrame(sur: PSDL_Surface; x, y, w, h: integer; colorin: uint32; alpha: integer);

//画RLE8图片的子程
function JudgeInScreen(px, py, w, h, xs, ys: integer): boolean; overload;
function JudgeInScreen(px, py, w, h, xs, ys, xx, yy, xw, yh: integer): boolean; overload;
procedure DrawRLE8Pic(colorPanel: pchar; num, px, py: integer; Pidx: Pinteger; Ppic: PByte;
  RectArea: pchar; Image: PSDL_Surface; widthI, heightI, sizeI: integer; shadow: integer); overload; inline;
procedure DrawRLE8Pic(colorPanel: pchar; num, px, py: integer; Pidx: Pinteger; Ppic: PByte;
  RectArea: pchar; Image: PSDL_Surface; widthI, heightI, sizeI: integer; shadow, alpha: integer); overload; inline;
procedure DrawRLE8Pic(colorPanel: pchar; num, px, py: integer; Pidx: Pinteger; Ppic: PByte;
  RectArea: pchar; Image: PSDL_Surface; widthI, heightI, sizeI: integer; shadow, alpha: integer;
  BlockImageW: pchar; BlockPosition: pchar; widthW, heightW, sizeW: integer; depth: integer;
  mixColor: uint32; mixAlpha: integer); overload;
function GetPositionOnScreen(x, y, CenterX, CenterY: integer): TPosition;


//显示文字的子程
function Big5ToUnicode(str: pchar; len: integer = -1): WideString;
function UnicodeToBig5(str: pWideChar): string;
procedure DrawText(sur: PSDL_Surface; word: puint16; x_pos, y_pos: integer; color: uint32);
procedure DrawEngText(sur: PSDL_Surface; word: puint16; x_pos, y_pos: integer; color: uint32);
procedure DrawShadowText(sur: PSDL_Surface; word: puint16; x_pos, y_pos: integer; color1, color2: uint32); overload;
procedure DrawShadowText(word: puint16; x_pos, y_pos: integer; color1, color2: uint32); overload;
procedure DrawEngShadowText(sur: PSDL_Surface; word: puint16; x_pos, y_pos: integer; color1, color2: uint32);
procedure DrawBig5Text(sur: PSDL_Surface; str: pchar; x_pos, y_pos: integer; color: uint32);
procedure DrawBig5ShadowText(sur: PSDL_Surface; word: pchar; x_pos, y_pos: integer; color1, color2: uint32);
procedure DrawTextWithRect(word: puint16; x, y, w: integer; color1, color2: uint32); overload;
procedure DrawTextWithRect(sur: PSDL_Surface; word: puint16; x, y, w: integer; color1, color2: uint32); overload;


//PNG贴图相关的子程
procedure DrawPNGTile(PNGIndex: TPNGIndex; FrameNum: integer; RectArea: pchar; scr: PSDL_Surface;
  px, py: integer); overload;
procedure DrawPNGTile(PNGIndex: TPNGIndex; FrameNum: integer; RectArea: pchar; scr: PSDL_Surface;
  px, py: integer; shadow, alpha: integer; mixColor: uint32; mixAlpha: integer); overload;
procedure DrawPNGTile(PNGIndex: TPNGIndex; FrameNum: integer; RectArea: pchar; scr: PSDL_Surface;
  px, py: integer; shadow, alpha: integer; mixColor: uint32; mixAlpha: integer; depth: integer;
  BlockImgR: pchar; Width, Height, size, leftupx, leftupy: integer); overload;
procedure SetPNGTileBlock(PNGIndex: TPNGIndex; px, py, depth: integer; BlockImageW: pchar;
  Width, Height, size: integer);

//用于系统响应的子程
procedure ChangeCol;
procedure SDL_UpdateRect2(scr1: PSDL_Surface; x, y, w, h: integer);
procedure SDL_GetMouseState2(var x, y: integer);
procedure ResizeWindow(w, h: integer);
procedure SwitchFullscreen;
procedure QuitConfirm;
function CheckBasicEvent: uint32;
function AngleToDirection(y, x: real): integer;

function DrawLength(str: WideString): integer; overload;
function DrawLength(p: pWideChar): integer; overload;
function DrawLength(p: pchar): integer; overload;

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

//计时, 测速用
procedure tic;
procedure toc;

procedure Message(formatstring: string; content: array of const; cr: boolean = True); overload; inline;
procedure Message(formatstring: string = ''; cr: boolean = True); overload; inline;

implementation

uses
  kys_draw;

function EventFilter(p: pointer; e: PSDL_Event): longint; cdecl;
begin
  Result := 1;
  {or (e.type_ = SDL_FINGERMOTION)}
  case e.type_ of
    SDL_FINGERUP, SDL_FINGERDOWN, SDL_CONTROLLERAXISMOTION, SDL_CONTROLLERBUTTONDOWN, SDL_CONTROLLERBUTTONUP:
      Result := 0;
    SDL_FINGERMOTION:
      if CellPhone = 0 then
        Result := 0;
  end;
end;

procedure InitialMusic;
var
  i: integer;
  str: string;
  sf: BASS_MIDI_FONT;
  Flag: longword;
begin
  BASS_Set3DFactors(1, 0, 0);
  sf.font := BASS_MIDI_FontInit(pchar(AppPath + 'music/mid.sf2'), 0);
  BASS_MIDI_StreamSetFonts(0, sf, 1);
  sf.preset := -1; // use all presets
  sf.bank := 0;
  Flag := 0;
  if SOUND3D = 1 then
    Flag := BASS_SAMPLE_3D or Flag;

  for i := low(Music) to high(Music) do
  begin
    str := AppPath + 'music/' + IntToStr(i) + '.mp3';
    if FileExists(pchar(str)) then
    begin
      try
        Music[i] := BASS_StreamCreateFile(False, pchar(str), 0, 0, 0);
      finally

      end;
    end
    else
    begin
      str := AppPath + 'music/' + IntToStr(i) + '.mid';
      if FileExists(pchar(str)) then
      begin
        try
          Music[i] := BASS_MIDI_StreamCreateFile(False, pchar(str), 0, 0, 0, 0);
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
    if FileExists(pchar(str)) then
      ESound[i] := BASS_SampleLoad(False, pchar(str), 0, 0, 1, Flag)
    else
      ESound[i] := 0;
    //showmessage(inttostr(esound[i]));
  end;
  for i := low(ASound) to high(ASound) do
  begin
    str := AppPath + formatfloat('sound/atk00', i) + '.wav';
    if FileExists(pchar(str)) then
      ASound[i] := BASS_SampleLoad(False, pchar(str), 0, 0, 1, Flag)
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
    if (MusicNum in [Low(Music)..High(Music)]) and (VOLUME > 0) then
      if Music[MusicNum] <> 0 then
      begin
        //BASS_ChannelSlideAttribute(Music[nowmusic], BASS_ATTRIB_VOL, 0, 1000);
        BASS_ChannelStop(Music[nowmusic]);
        if frombeginning = 1 then
          BASS_ChannelSetPosition(Music[nowmusic], 0, BASS_POS_BYTE);
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
        nowmusic := musicnum;
      end;
  finally

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
    if FileExists(pchar(str)) then
    begin
      Music[i] := Mix_LoadMUS(pchar(str));
    end
    else
      Music[i] := nil;
  end;
  for i := 0 to 52 do
  begin
    str := AppPath + formatfloat('sound/e00', i) + '.wav';
    if FileExists(pchar(str)) then
      ESound[i] := Mix_LoadWav(pchar(str))
    else
      ESound[i] := nil;
  end;
  for i := 0 to 24 do
  begin
    str := AppPath + formatfloat('sound/atk00', i) + '.wav';
    if FileExists(pchar(str)) then
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
    {for i := BeginScenceRolePic to BeginScenceRolePic + 27 do
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

function ReadFileToBuffer(p: pchar; filename: string; size, malloc: integer): pchar;
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
      Result := StrAlloc(size + 4);
      p := Result;
      //writeln(StrBufSize(p));
    end;
    FileSeek(i, 0, 0);
    FileRead(i, p^, size);
    FileClose(i);
  end
  else
  if malloc = 1 then
    Result := nil;
end;

procedure FreeFileBuffer(var p: pchar);
begin
  if p <> nil then
    StrDispose(p);
  p := nil;
end;

function LoadIdxGrp(stridx, strgrp: string; var idxarray: TIntArray; var grparray: TByteArray): integer;
var
  idx, grp, len, tnum: integer;
begin
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

function LoadPNGTiles(path: string; var PNGIndexArray: TPNGIndexArray; var SurfaceArray: TSurfaceArray;
  LoadPic: integer = 1): integer;
var
  i, j, k, state, size, Count, pngoff: integer;
  zipFile: unzFile;
  info: unz_file_info;
  offset: array of smallint;
  p: pchar;
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
      Result := pinteger(p)^;
      //最大的有帧数的数量作为贴图的最大编号
      for i := Result - 1 downto 0 do
      begin
        if pinteger(p + pinteger(p + 4 + i * 4)^ + 4)^ > 0 then
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
        pngoff := pinteger(p + 4 + i * 4)^;
        with PNGIndexArray[i] do
        begin
          Num := Count;
          x := psmallint(p + pngoff)^;
          y := psmallint(p + pngoff + 2)^;
          Frame := pinteger(p + pngoff + 4)^;
          Count := Count + frame;
          CurPointer := nil;
          Loaded := 0;
        end;
      end;
    end
    else
    if IsConsole then
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
      if FileExists(AppPath + path + IntToStr(i) + '.png') or FileExists(AppPath + path +
        IntToStr(i) + '_0.png') then
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
        Num := -1;
        Frame := 0;
        CurPointer := nil;
        if FileExists(AppPath + path + IntToStr(i) + '.png') then
        begin
          Num := Count;
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
              Num := Count;
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

procedure LoadOnePNGTile(path: string; p: pchar; filenum: integer; var PNGIndex: TPNGIndex;
  SurfacePointer: PPSDL_Surface; forceLoad: integer = 0);
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
    if ((Loaded = 0) or (forceLoad = 1)) and (Num >= 0) and (Frame > 0) then
    begin
      Loaded := 1;
      Inc(SurfacePointer, Num);
      CurPointer := SurfacePointer;
      if Frame = 1 then
      begin
        if frommem then
        begin
          off := pinteger(p + 4 + filenum * 4)^ + 8;
          index := pinteger(p + off)^;
          len := pinteger(p + off + 4)^;
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
            off := pinteger(p + 4 + filenum * 4)^ + 8;
            index := pinteger(p + off + j * 8)^;
            len := pinteger(p + off + j * 8 + 4)^;
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

function LoadSurfaceFromFile(filename: string): PSDL_Surface;
var
  tempscr: PSDL_Surface;
begin
  Result := nil;
  if FileExists(filename) then
  begin
    tempscr := IMG_Load(pchar(filename));
    Result := SDL_ConvertSurface(tempscr, screen.format, 0);
    SDL_FreeSurface(tempscr);
  end;
end;

function LoadSurfaceFromMem(p: pchar; len: integer): PSDL_Surface;
var
  tempscr: PSDL_Surface;
  tempRWops: PSDL_RWops;
begin
  Result := nil;
  tempRWops := SDL_RWFromMem(p, len);
  tempscr := IMG_LoadPNG_RW(tempRWops);
  Result := SDL_ConvertSurface(tempscr, screen.format, 0);
  SDL_FreeSurface(tempscr);
  SDL_FreeRW(tempRWops);

end;

function LoadSurfaceFromZIPFile(zipFile: unzFile; filename: string): PSDL_Surface;
var
  archiver: unzFile;
  info: unz_file_info;
  buffer: pchar;
begin

end;

procedure FreeAllSurface;
var
  i, j: integer;
begin
  for i := 0 to high(MPNGTile) do
    SDL_FreeSurface(MPNGTile[i]);
  for i := 0 to high(SPNGTile) do
    SDL_FreeSurface(SPNGTile[i]);
  for i := 0 to high(BPNGTile) do
    SDL_FreeSurface(BPNGTile[i]);
  for i := 0 to high(EPNGTile) do
    SDL_FreeSurface(EPNGTile[i]);
  for i := 0 to high(CPNGTile) do
    SDL_FreeSurface(CPNGTile[i]);
  for i := 0 to high(TitlePNGTile) do
    SDL_FreeSurface(TitlePNGTile[i]);
  for i := 0 to high(FPNGTile) do
    for j := 0 to high(FPNGTile[i]) do
      SDL_FreeSurface(FPNGTile[i, j]);
  SDL_FreeSurface(screen);
  SDL_FreeSurface(prescreen);
  SDL_FreeSurface(ImgScence);
  SDL_FreeSurface(ImgScenceBack);
  SDL_FreeSurface(ImgBField);
  SDL_FreeSurface(ImgBBuild);
end;

//获取某像素信息

function GetPixel(surface: PSDL_Surface; x: integer; y: integer): uint32;
type
  TByteArray = array[0..2] of byte;
  PByteArray = ^TByteArray;
var
  bpp: integer;
  p: PInteger;
begin
  if (x >= 0) and (x < surface.w) and (y >= 0) and (y < surface.h) then
  begin
    bpp := surface.format.BytesPerPixel;
    // Here p is the address to the pixel we want to retrieve
    p := Pointer(uint32(surface.pixels) + y * surface.pitch + x * bpp);
    case bpp of
      1:
        Result := longword(p^);
      2:
        Result := puint16(p)^;
      3:
        if (SDL_BYTEORDER = SDL_BIG_ENDIAN) then
          Result := PByteArray(p)[0] shl 16 or PByteArray(p)[1] shl 8 or PByteArray(p)[2]
        else
          Result := PByteArray(p)[0] or PByteArray(p)[1] shl 8 or PByteArray(p)[2] shl 16;
      4:
        Result := puint32(p)^;
      else
        Result := 0; // shouldn't happen, but avoids warnings
    end;
  end;

end;

//画像素

procedure PutPixel(surface: PSDL_Surface; x: integer; y: integer; pixel: uint32);
type
  TByteArray = array[0..2] of byte;
  PByteArray = ^TByteArray;
var
  bpp: integer;
  p: PInteger;
begin
  if (x >= 0) and (x < surface.w) and (y >= 0) and (y < surface.h) then
  begin
    bpp := surface.format.BytesPerPixel;
    // Here p is the address to the pixel we want to set
    p := Pointer(uint32(surface.pixels) + y * surface.pitch + x * bpp);

    case bpp of
      1:
        longword(p^) := pixel;
      2:
        puint16(p)^ := pixel;
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
        puint32(p)^ := pixel;
    end;
  end;
end;


//显示bmp文件

procedure display_bmp(file_name: pchar; x, y: integer);
var
  image: PSDL_Surface;
  dest: TSDL_Rect;
begin
  if FileExists(file_name) { *Converted from FileExists*  } then
  begin
    image := SDL_LoadBMP(file_name);
    if (image = nil) then
    begin
      MessageBox(0, pchar(Format('Couldn''t load %s : %s', [file_name, SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
    dest.x := x;
    dest.y := y;
    if (SDL_BlitSurface(image, nil, screen, @dest) < 0) then
      MessageBox(0, pchar(Format('BlitSurface error : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
    //SDL_UpdateRect2(screen, 0, 0, image.w, image.h);
    SDL_FreeSurface(image);
  end;
end;

//显示tif, png, jpg等格式图片

procedure display_img(file_name: pchar; x, y: integer);
var
  image: PSDL_Surface;
  dest: TSDL_Rect;
begin
  if FileExists(file_name) { *Converted from FileExists*  } then
  begin
    image := IMG_Load(file_name);
    if (image = nil) then
    begin
      MessageBox(0, pchar(Format('Couldn''t load %s : %s', [file_name, SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
      exit;
    end;
    dest.x := x;
    dest.y := y;
    if (SDL_BlitSurface(image, nil, screen, @dest) < 0) then
      MessageBox(0, pchar(Format('BlitSurface error : %s', [SDL_GetError])), 'Error', MB_OK or MB_ICONHAND);
    //SDL_UpdateRect2(screen, 0, 0, image.w, image.h);
    SDL_FreeSurface(image);
  end;
end;

//取调色板的颜色, 视频系统为32位色, 但很多时候仍需要原调色板的颜色

function ColColor(num: byte): uint32;
begin
  //{$IFDEF darwin}
  //colcolor := SDL_mapRGB(screen.format, Acol[num * 3 + 0] * 4, Acol[num * 3 + 1] * 4, Acol[num * 3 + 2] * 4);
  //{$ELSE}
  if (num >= 0) and (num <= 255) then
    Result := SDL_MapRGB(screen.format, Acol[num * 3] * 4, Acol[num * 3 + 1] * 4, Acol[num * 3 + 2] * 4)
  else
    Result := 0;
  //{$ENDIF}

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

//RLE8图片绘制子程, 所有相关子程均对此封装. 最后一个参数为亮度, 仅在绘制战场选择对方时使用

procedure DrawRLE8Pic(colorPanel: pchar; num, px, py: integer; Pidx: Pinteger; Ppic: PByte;
  RectArea: pchar; Image: PSDL_Surface; widthI, heightI, sizeI: integer; shadow: integer); overload;
begin
  DrawRLE8Pic(colorPanel, num, px, py, Pidx, Ppic, RectArea, Image, widthI, heightI, sizeI, Shadow, 0);

end;

//增加透明度选项

procedure DrawRLE8Pic(colorPanel: pchar; num, px, py: integer; Pidx: Pinteger; Ppic: PByte;
  RectArea: pchar; Image: PSDL_Surface; widthI, heightI, sizeI: integer; shadow, alpha: integer); overload;
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

procedure DrawRLE8Pic(colorPanel: pchar; num, px, py: integer; Pidx: Pinteger; Ppic: PByte;
  RectArea: pchar; Image: PSDL_Surface; widthI, heightI, sizeI: integer; shadow, alpha: integer;
  BlockImageW: pchar; BlockPosition: pchar; widthW, heightW, sizeW: integer; depth: integer;
  mixColor: uint32; mixAlpha: integer); overload;
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
    blockx := pinteger(BlockPosition)^;
    blocky := pinteger(BlockPosition + 4)^;
  end;
  alpha1 := (alpha shr 8) and $FF;
  if ((w > 1) or (h > 1)) and (px - xs + w >= area.x) and (px - xs < area.x + area.w) and
    (py - ys + h >= area.y) and (py - ys < area.y + area.h) then
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
            pix1 := puint8(colorPanel + l1 * 3)^ * (4 + shadow);
            pix2 := puint8(colorPanel + l1 * 3 + 1)^ * (4 + shadow);
            pix3 := puint8(colorPanel + l1 * 3 + 2)^ * (4 + shadow);
            pix4 := 0;
            //pix := sdl_maprgba(screen.format, pix1, pix2, pix3, pix4);
            if image = screen then
            begin
              if mixAlpha <> 0 then
              begin
                SDL_GetRGBA(mixColor, screen.format, @color1, @color2, @color3, @color4);
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
                if (isAlpha = 1) and (Alpha < 100) then
                begin
                  colorin := GetPixel(screen, x, y);
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
                if (isAlpha = 0) and (alpha1 > 0) and (Alpha1 <= 100) then
                begin
                  colorin := GetPixel(screen, x, y);
                  SDL_GetRGBA(colorin, screen.format, @color1, @color2, @color3, @color4);
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
              pix := SDL_MapRGBA(screen.format, pix1, pix2, pix3, pix4);
              if (Alpha < 100) or (pixdepth <= curdepth) then
                PutPixel(screen, x, y, pix);
            end
            else
            begin
              if (x < widthI) and (y < heightI) then
              begin
                if (BlockImageW <> nil) then
                begin
                  //if (depth < 0) then
                  //depth := (py div 9 - 1);
                  Psmallint(BlockImageW + (x * heightI + y) * sizeI)^ := depth;
                end;
                pix := SDL_MapRGBA(screen.format, pix1, pix2, pix3, pix4);
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


//big5转为unicode

function Big5ToUnicode(str: pchar; len: integer = -1): WideString;
var
  str1: ansistring;
begin
{$IFDEF fpc}
  str1 := str;
  if (len >= 0) and (length(str) > len * 2) then
    setlength(str1, len * 2);
  Result := UTF8Decode(CP950ToUTF8(str));
{$ELSE}
  len := MultiByteToWideChar(950, 0, pchar(str), -1, nil, 0);
  setlength(Result, len - 1);
  MultiByteToWideChar(950, 0, pchar(str), length(str), pWideChar(Result), len + 1);
{$ENDIF}
  //Result := ' ' + Result;
  {if len >= 0 then
  begin
    if length(Result) > len then
      setlength(Result, len);
  end;}

end;

//unicode转为big5, 仅用于输入姓名

function UnicodeToBig5(str: pWideChar): string;
var
  len: integer;
begin
{$IFDEF fpc}
  Result := UTF8ToCP950((str));
{$ELSE}
  len := WideCharToMultiByte(950, 0, pWideChar(str), -1, nil, 0, nil, nil);
  setlength(Result, len + 1);
  WideCharToMultiByte(950, 0, pWideChar(str), -1, pchar(Result), len + 1, nil, nil);
{$ENDIF}

end;

//显示unicode文字

procedure DrawText(sur: PSDL_Surface; word: puint16; x_pos, y_pos: integer; color: uint32);
var
  dest, src: TSDL_Rect;
  tempcolor: TSDL_Color;
  len, i, k: integer;
  word0: array[0..2] of uint16 = (32, 0, 0);
  word1: ansistring;
  word2: WideString;
  p1: pbyte;
  p2: pbyte;
  Text: PSDL_Surface;
  r, g, b: byte;
begin
{$IFDEF fpc}
  //widestring在fpc中的默认赋值动作是将utf8码每字节间插入一个00.
  //此处删除这些0, 同时统计这些0的数目, 若与字串长度相同
  //即认为是一个纯英文字串, 或者是一个直接赋值的widestring,
  //需要再编码为Unicode, 否则即认为已经是Unicode
  len := length(pWideChar(word));
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

  SDL_GetRGB(color, sur.format, @r, @g, @b);
  tempcolor.r := r;
  tempcolor.g := g;
  tempcolor.b := b;
  dest.x := x_pos;
  //注意每种字体的空格宽度不同
  src.x := CHNFONT_SPACEWIDTH;
  src.y := 0;
  while word^ > 0 do
  begin
    word0[1] := word^;
    Inc(word);
    if word0[1] > $1000 then
    begin
      Text := TTF_RenderUnicode_blended(font, @word0[0], tempcolor);
      dest.x := x_pos;
      //dest.x := x_pos - CHNFONT_SPACEWIDTH;
      dest.y := y_pos;
      src.x := Text.w - 20;
      src.w := Text.w - src.x;
      src.h := Text.h;
      SDL_BlitSurface(Text, @src, sur, @dest);
      x_pos := x_pos + 20;
    end
    else
    begin
      //if word0[1] <> 20 then
      begin
        Text := TTF_RenderUNICODE_blended(engfont, @word0[1], tempcolor);
        //showmessage(inttostr(pword[1]));
        //dest.x := x_pos + 10;
        dest.x := x_pos;
        dest.y := y_pos + 2;
        SDL_BlitSurface(Text, nil, sur, @dest);
      end;
      x_pos := x_pos + 10;
    end;
    SDL_FreeSurface(Text);
  end;

end;

//显示英文

procedure DrawEngText(sur: PSDL_Surface; word: puint16; x_pos, y_pos: integer; color: uint32);
var
  dest: TSDL_Rect;
  a: Uint8;
  tempcolor: TSDL_Color;
  Text: PSDL_Surface;
  r, g, b: byte;
begin
  SDL_GetRGB(color, sur.format, @r, @g, @b);
  tempcolor.r := r;
  tempcolor.g := g;
  tempcolor.b := b;

  Text := TTF_RenderUNICODE_blended(engfont, word, tempcolor);
  dest.x := x_pos;
  dest.y := y_pos + 2;
  SDL_BlitSurface(Text, nil, sur, @dest);
  SDL_FreeSurface(Text);

end;

//显示unicode中文阴影文字, 即将同样内容显示2次, 间隔1像素

procedure DrawShadowText(sur: PSDL_Surface; word: puint16; x_pos, y_pos: integer; color1, color2: uint32); overload;
begin
  DrawText(sur, word, x_pos + 1, y_pos, color2);
  DrawText(sur, word, x_pos, y_pos, color1);
end;

procedure DrawShadowText(word: puint16; x_pos, y_pos: integer; color1, color2: uint32); overload;
begin
  DrawText(screen, word, x_pos + 1, y_pos, color2);
  DrawText(screen, word, x_pos, y_pos, color1);

end;

//显示英文阴影文字

procedure DrawEngShadowText(sur: PSDL_Surface; word: puint16; x_pos, y_pos: integer; color1, color2: uint32);
begin
  DrawEngText(sur, word, x_pos + 1, y_pos, color2);
  DrawEngText(sur, word, x_pos, y_pos, color1);

end;

//显示big5文字

procedure DrawBig5Text(sur: PSDL_Surface; str: pchar; x_pos, y_pos: integer; color: uint32);
var
  len: integer;
  words: WideString;
begin
{$IFDEF fpc}
  words := UTF8Decode(CP950ToUTF8(str));
{$ELSE}
  len := MultiByteToWideChar(950, 0, pchar(str), -1, nil, 0);
  setlength(words, len - 1);
  MultiByteToWideChar(950, 0, pchar(str), length(str), pWideChar(words), len + 1);
{$ENDIF}
  DrawText(sur, @words[1], x_pos, y_pos, color);

end;

//显示big5阴影文字

procedure DrawBig5ShadowText(sur: PSDL_Surface; word: pchar; x_pos, y_pos: integer; color1, color2: uint32);
var
  len: integer;
  words: WideString;
begin
{$IFDEF fpc}
  words := UTF8Decode(CP950ToUTF8(word));
{$ELSE}
  len := MultiByteToWideChar(950, 0, pchar(word), -1, nil, 0);
  setlength(words, len - 1);
  MultiByteToWideChar(950, 0, pchar(word), length(word), pWideChar(words), len + 1);
{$ENDIF}
  DrawText(sur, @words[1], x_pos + 1, y_pos, color2);
  DrawText(sur, @words[1], x_pos, y_pos, color1);

end;

//显示带边框的文字, 仅用于unicode, 需自定义宽度

procedure DrawTextWithRect(word: puint16; x, y, w: integer; color1, color2: uint32); overload;
begin
  DrawTextWithRect(screen, word, x, y, w, color1, color2);
end;

procedure DrawTextWithRect(sur: PSDL_Surface; word: puint16; x, y, w: integer; color1, color2: uint32); overload;
var
  len: integer;
  p: pchar;
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
  {if (SDL_MustLock(screen)) then
  begin
    SDL_LockSurface(screen);
  end;}
  tempscr := SDL_CreateRGBSurface(sur.flags, w + 1, h + 1, 32, RMask, GMask, BMask, AMask);
  SDL_GetRGB(colorin, tempscr.format, @r, @g, @b);
  SDL_GetRGB(colorframe, tempscr.format, @r1, @g1, @b1);
  SDL_FillRect(tempscr, nil, SDL_MapRGBA(tempscr.format, r, g, b, alpha * 255 div 100));
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
      if (((l1 >= 4) and (l2 >= 4) and (l3 >= 4) and (l4 >= 4) and ((i1 = 0) or (i1 = w) or
        (i2 = 0) or (i2 = h))) or ((l1 = 4) or (l2 = 4) or (l3 = 4) or (l4 = 4))) then
      begin
        //a := round(200 - min(abs(i1/w-0.5),abs(i2/h-0.5))*2 * 100);
        a := round(250 - abs(i1 / w + i2 / h - 1) * 150);
        //writeln(a);
        PutPixel(tempscr, i1, i2, SDL_MapRGBA(tempscr.format, r1, g1, b1, a));
      end;
    end;
  SDL_BlitSurface(tempscr, nil, sur, @dest);
  SDL_FreeSurface(tempscr);
  {if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;}

end;

//画不含边框的矩形, 用于对话和黑屏

procedure DrawRectangleWithoutFrame(sur: PSDL_Surface; x, y, w, h: integer; colorin: uint32; alpha: integer);
var
  tempscr: PSDL_Surface;
  dest: TSDL_Rect;
begin
  {if (SDL_MustLock(screen)) then
  begin
    SDL_LockSurface(screen);
  end;}
  tempscr := SDL_CreateRGBSurface(sur.flags, w, h, 32, RMASK, GMASK, BMASK, AMASK);
  SDL_FillRect(tempscr, nil, colorin or $ff000000);
  SDL_SetSurfaceAlphaMod(tempscr, alpha * 255 div 100);
  dest.x := x;
  dest.y := y;
  SDL_BlitSurface(tempscr, nil, sur, @dest);
  SDL_FreeSurface(tempscr);
  //boxRGBA(sur, x, y, x+w-1, y+h-1, 0,0,0,alpha * 255 div 100);
  {if (SDL_MustLock(screen)) then
  begin
    SDL_UnlockSurface(screen);
  end;}

end;


//调色板变化, 贴图闪烁效果

procedure ChangeCol;
var
  i, i1, i2, a, b, add0, len: integer;
  temp: array[0..2] of byte;
  now, next_time: uint32;
  p, p0, p1, p2: real;
begin
  now := SDL_GetTicks;
  if (NIGHT_EFFECT = 1) and (where = 0) then
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

//绘制PNG贴图相关的代码
//这里的可能较旧, 可以参照水浒的

procedure DrawPNGTile(PNGIndex: TPNGIndex; FrameNum: integer; RectArea: pchar; scr: PSDL_Surface;
  px, py: integer); overload;
begin
  DrawPNGTile(PNGIndex, FrameNum, RectArea, scr, px, py, 0, 0, 0, 0);
end;

procedure DrawPNGTile(PNGIndex: TPNGIndex; FrameNum: integer; RectArea: pchar; scr: PSDL_Surface;
  px, py: integer; shadow, alpha: integer; mixColor: uint32; mixAlpha: integer); overload;
begin
  DrawPNGTile(PNGIndex, FrameNum, RectArea, scr, px, py, shadow, alpha, mixColor, mixAlpha, 0, nil, 0, 0, 0, 0, 0);

end;

procedure DrawPNGTile(PNGIndex: TPNGIndex; FrameNum: integer; RectArea: pchar; scr: PSDL_Surface;
  px, py: integer; shadow, alpha: integer; mixColor: uint32; mixAlpha: integer; depth: integer;
  BlockImgR: pchar; Width, Height, size, leftupx, leftupy: integer); overload;
var
  dest, area: TSDL_Rect;
  tempscr, tempscrfront, tempscrback, CurSurface: PSDL_Surface;
  pixdepth, i1, i2: integer;
  tran: byte;
  bigtran, pixel, Mask, AlphaValue: uint32;
  x1, x2, y1, y2: integer;
  lenint: integer;
begin
  {with PNGIndex do
  begin
    if (CurPointer <> nil) and (Loaded = 1) and (Frame > 0) then
    begin
      if frame > 1 then
        Inc(CurPointer, FrameNum mod Frame);
      CurSurface := CurPointer^;
      if CurSurface <> nil then
      begin
        if RectArea <> nil then
        begin
          area := PSDL_Rect(RectArea)^;
          x1 := area.x;
          y1 := area.y;
          x2 := x1 + area.w;
          y2 := y1 + area.h;
        end
        else
        begin
          x1 := 0;
          y1 := 0;
          x2 := scr.w;
          y2 := scr.h;
        end;
        dest.x := px - x + 1;
        dest.y := py - y + 1;
        dest.w := CurSurface.w;
        dest.h := CurSurface.h;
        if (dest.x + CurSurface.w >= x1) and (dest.y + CurSurface.h >= y1) and (dest.x < x2) and
          (dest.y < y2) then
        begin
          if shadow > 0 then
          begin
            mixColor := $FFFFFFFF;
            mixAlpha := shadow * 25;
          end
          else if shadow < 0 then
          begin
            mixColor := 0;
            mixAlpha := -shadow * 25;
          end;
          if (mixAlpha = 0) and (BlockImgR = nil) then
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
            if (mixAlpha > 0) then
            begin
              //mixalpha := 100;
              tran := mixAlpha * 255 div 100;
              bigtran := tran * $01010101;
              Mask := tempscr.format.AMask;
              tempscrfront := SDL_DisplayFormatAlpha(CurSurface);
              SDL_FillRect(tempscrfront, nil, (mixColor and (not Mask)) or (bigtran and Mask));
              SDL_BlitSurface(tempscrfront, nil, tempscr, nil);
              if (BlockImgR = nil) then
              begin
                if alpha > 0 then
                begin
                  tempscrback := SDL_DisplayFormat(CurSurface);
                  SDL_BlitSurface(scr, @dest, tempscrback, nil);
                  SDL_BlitSurface(tempscr, nil, tempscrback, nil);
                  SDL_SetAlpha(tempscrback, SDL_SRCALPHA, 255 - alpha * 255 div 100);
                  SDL_BlitSurface(tempscrback, nil, scr, @dest);
                  SDL_FreeSurface(tempscrback);
                end
                else
                begin
                  SDL_BlitSurface(tempscr, nil, scr, @dest);
                end;
              end
              else
              begin
                //SDL_BlitSurface(tempscrback, nil, scr, @dest);
                //SDL_BlitSurface(tempscrback, nil, tempscr, nil);
              end;
              SDL_FreeSurface(tempscrfront);
            end;
            if (BlockImgR <> nil) then
            begin
              tran := 255 - alpha * 255 div 100;
              //将透明通道的值写入所有位, 具体的位置由蒙板决定
              bigtran := tran * $01010101;
              Mask := tempscr.format.AMask;
              for i1 := 0 to tempscr.w - 1 do
              begin
                for i2 := 0 to tempscr.h - 1 do
                begin
                  pixdepth := psmallint(BlockImgR + ((dest.x + leftupx + i1) * Height + dest.y +
                    leftupy + i2) * size)^;
                  pixel := GetPixel(tempscr, i1, i2);
                  AlphaValue := pixel and Mask;
                  if AlphaValue > 0 then
                  begin
                    if (pixdepth > depth) then
                    begin
                      //替换透明通道的值
                      //注意: 这里如果效率较低, 则改用完全指针, 或者汇编编写. 设置偏移也相同
                      PutPixel(tempscr, i1, i2, (pixel and (not Mask)) or (bigtran and Mask));
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
  end;}
end;

procedure SetPNGTileBlock(PNGIndex: TPNGIndex; px, py, depth: integer; BlockImageW: pchar;
  Width, Height, size: integer);
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
            if ((GetPixel(CurSurface, i1, i2) and CurSurface.format.AMask) <> 0) and
              (x1 + i1 >= 0) and (x1 + i1 < Width) and (y1 + i2 >= 0) and (y1 + i2 < Height) then
            begin
              psmallint(BlockImageW + ((x1 + i1) * Height + y1 + i2) * size)^ := depth;
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
  tempscr: PSDL_Surface;
  now, Next: uint32;
  dest: TSDL_Rect;
  p: Pointer;
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
    // Here p is the address to the pixel we want to set
    p := Pointer(uint32(screen.pixels) + y * screen.pitch + x * screen.format.BytesPerPixel);
    SDL_UpdateTexture(screenTex, @dest, p, screen.pitch);
    SDL_RenderCopy(render, screenTex, nil, nil);
    SDL_RenderPresent(render);
  end;
  //SDL_BlitSurface(screen, @dest, prescreen, @dest);

  {if GLHR = 1 then
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

    glEnable(GL_TEXTURE_2D);
    glBegin(GL_QUADS);
    glTexCoord2f(0.0, 0.0);
    glVertex3f(-1.0, 1.0, 0.0);
    glTexCoord2f(1.0, 0.0);
    glVertex3f(1.0, 1.0, 0.0);
    glTexCoord2f(1.0, 1.0);
    glVertex3f(1.0, -1.0, 0.0);
    glTexCoord2f(0.0, 1.0);
    glVertex3f(-1.0, -1.0, 0.0);
    glEnd;
    glDisable(GL_TEXTURE_2D);
    SDL_GL_SwapBuffers;
    glDeleteTextures(1, @TextureID);
  end
  else
  begin
    //realx := x * resolutionx div scr1.w;
    //realw := (x + w + 2) * resolutionx div scr1.w - realx;
    //realy := y * resolutiony div scr1.h;
    //realh := (y + h + 2) * resolutiony div scr1.h - realy;
    //if realw + realx > resolutionx then realw := resolutionx - realx;
    //if realh + realy > resolutiony then realh := resolutiony - realy;
    if (resolutionx = screen.w) and (resolutiony = screen.h) then
    begin
      SDL_BlitSurface(prescreen, nil, RealScreen, nil);
    end
    else
    begin
      tempscr := sdl_gfx.zoomSurface(prescreen, resolutionx / screen.w, resolutiony / screen.h, SMOOTH);
      SDL_BlitSurface(tempscr, nil, RealScreen, nil);
      SDL_FreeSurface(tempscr);
    end;
    SDL_UpdateRect(RealScreen, 0, 0, resolutionx, resolutiony);
  end;}
end;


procedure SDL_GetMouseState2(var x, y: integer);
var
  tempx, tempy: integer;
begin
  SDL_GetMouseState(@tempx, @tempy);
  x := tempx * screen.w div RESOLUTIONX;
  y := tempy * screen.h div RESOLUTIONY;

end;

procedure ResizeWindow(w, h: integer);
begin
  RESOLUTIONX := w;
  RESOLUTIONY := h;
  {RealScreen := SDL_SetVideoMode(w, h, 32, ScreenFlag);
  event.type_ := 0;
  SDL_UpdateRect2(screen, 0, 0, screen.w, screen.h);}

end;

procedure SwitchFullscreen;
begin
  {FULLSCREEN := 1 - FULLSCREEN;
  if FULLSCREEN = 0 then
  begin
    RealScreen := SDL_SetVideoMode(RESOLUTIONX, RESOLUTIONY, 32, ScreenFlag);
  end
  else
  begin
    RealScreen := SDL_SetVideoMode(CENTER_X * 2, CENTER_Y * 2, 32, ScreenFlag or SDL_FULLSCREEN);
  end;}
end;

procedure QuitConfirm;
var
  tempscr: PSDL_Surface;
  menuString: array[0..1] of WideString;
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
    tempscr := SDL_ConvertSurface(screen, screen.format, screen.flags);
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
    SDL_FreeSurface(tempscr);
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
    Result := (x > CENTER_X * 2 - 100) and (y > CENTER_Y * 2 - 100);
  end;

  function inEscape(x, y: integer): boolean; inline;
  begin
    Result := (x < 100) and (y > CENTER_Y * 2 - 100);
  end;

begin
  //if not ((LoadingTiles) or (LoadingScence)) then
  SDL_FlushEvent(SDL_MOUSEWHEEL);
  SDL_FlushEvent(SDL_JOYAXISMOTION);
  SDL_FlushEvent(SDL_FINGERMOTION);
  //SDL_FlushEvent(SDL_FINGERDOWN);
  //SDL_FlushEvent(SDL_FINGERUP);
  if CellPhone = 1 then
    SDL_FlushEvent(SDL_MOUSEMOTION);
  //writeln(inttohex(event.type_, 4));
  //JoyAxisMouse;
  Result := event.type_;
  case event.type_ of
    SDL_JOYBUTTONUP:
    begin
      event.type_ := SDL_KEYUP;
      if event.jbutton.button = JOY_ESCAPE then
        event.key.keysym.sym := SDLK_ESCAPE
      else if event.jbutton.button = JOY_RETURN then
        event.key.keysym.sym := SDLK_RETURN
      else if event.jbutton.button = JOY_MOUSE_LEFT then
      begin
        event.button.button := SDL_BUTTON_LEFT;
        event.type_ := SDL_MOUSEBUTTONUP;
      end
      else if event.jbutton.button = JOY_UP then
        event.key.keysym.sym := SDLK_UP
      else if event.jbutton.button = JOY_DOWN then
        event.key.keysym.sym := SDLK_DOWN
      else if event.jbutton.button = JOY_LEFT then
        event.key.keysym.sym := SDLK_LEFT
      else if event.jbutton.button = JOY_RIGHT then
        event.key.keysym.sym := SDLK_RIGHT;
    end;
    SDL_JOYBUTTONDOWN:
    begin
      event.type_ := SDL_KEYDOWN;
      if event.jbutton.button = JOY_UP then
        event.key.keysym.sym := SDLK_UP
      else if event.jbutton.button = JOY_DOWN then
        event.key.keysym.sym := SDLK_DOWN
      else if event.jbutton.button = JOY_LEFT then
        event.key.keysym.sym := SDLK_LEFT
      else if event.jbutton.button = JOY_RIGHT then
        event.key.keysym.sym := SDLK_RIGHT;
    end;
    SDL_JOYHATMOTION:
    begin
      event.type_ := SDL_KEYDOWN;
      case event.jhat.value of
        SDL_HAT_UP: event.key.keysym.sym := SDLK_UP;
        SDL_HAT_DOWN: event.key.keysym.sym := SDLK_DOWN;
        SDL_HAT_LEFT: event.key.keysym.sym := SDLK_LEFT;
        SDL_HAT_RIGHT: event.key.keysym.sym := SDLK_RIGHT;
      end;
    end;
    SDL_FINGERMOTION:
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
            event.type_ := SDL_KEYDOWN;
            event.key.keysym.sym := AngleToDirection(event.tfinger.dy, event.tfinger.dx);
          end;
        end;
      end;
    SDL_FINGERUP:
      ;
    SDL_MULTIGESTURE:
      ;
    SDL_QUITEV:
      QuitConfirm;
    SDL_WindowEvent:
    begin
      if event.window.event = SDL_WINDOWEVENT_RESIZED then
      begin
        ResizeWindow(event.window.data1, event.window.data2);
      end;
    end;
    SDL_APP_DIDENTERFOREGROUND:
      PlayMP3(nowmusic, -1, 0);
    SDL_APP_DIDENTERBACKGROUND:
      StopMP3(0);
    {SDL_MOUSEBUTTONDOWN:
    if (CellPhone = 1) and (event.button.button = SDL_BUTTON_LEFT) then
    begin
      SDL_GetMouseState(@x, @y);
    end;}
    SDL_MOUSEMOTION:
    begin
      if CellPhone = 1 then
      begin
        FingerCount := 0;
        SDL_GetMouseState2(x, y);
        if inEscape(x, y) or inReturn(x, y) then
          event.type_ := 0;
      end;
    end;
    SDL_KEYUP, SDL_MOUSEBUTTONUP:
    begin
      if (CellPhone = 1) and (event.type_ = SDL_MOUSEBUTTONUP) and (event.button.button = SDL_BUTTON_LEFT) then
      begin
        SDL_GetMouseState2(x, y);
        if inEscape(x, y) then
        begin
          //event.button.x := RESOLUTIONX div 2;
          //event.button.y := RESOLUTIONY div 2;
          event.button.button := SDL_BUTTON_RIGHT;
          event.key.keysym.sym := SDLK_ESCAPE;
          message('Change to escape');
        end
        else if inReturn(x, y) then
        begin
          //event.button.x := RESOLUTIONX div 2;
          //event.button.y := RESOLUTIONY div 2;
          event.type_ := SDL_KEYUP;
          event.key.keysym.sym := SDLK_RETURN;
          message('Change to return');
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
      if (where = 2) and ((event.key.keysym.sym = SDLK_ESCAPE) or (event.button.button = SDL_BUTTON_RIGHT)) then
      begin
        for i := 0 to BRoleAmount - 1 do
        begin
          if Brole[i].Team = 0 then
            Brole[i].Auto := 0;
        end;
      end;
      if event.key.keysym.sym = SDLK_KP_ENTER then
        event.key.keysym.sym := SDLK_RETURN;
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

function DrawLength(str: WideString): integer; overload;
var
  l, i: integer;
begin
  l := length(str);
  Result := l;
  for i := 1 to l do
  begin
    if uint16(str[i]) >= $1000 then
      Result := Result + 1;
  end;
end;

function DrawLength(p: pWideChar): integer; overload;
var
  l, i: integer;
begin
  l := length(p);
  Result := l;
  for i := 0 to l - 1 do
  begin
    if puint16(p)^ >= $1000 then
      Result := Result + 1;
    Inc(p);
  end;
end;

function DrawLength(p: pchar): integer; overload;
begin
  DrawLength(pWideChar(p));
end;

{$IFDEF fpc}

{$ELSE}

{function UTF8Decode(str: widestring): widestring;
begin
  result := str;
end;}
{$ENDIF}

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
  event.key.keysym.sym := 0;
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

{$ifdef mswindows}

procedure tic;
begin
  QueryPerformanceFrequency(tttt);
  QueryPerformanceCounter(cccc1);
  //tttt := SDL_GetTicks;
end;

procedure toc;
begin
  QueryPerformanceCounter(cccc2);
  Message(' %3.2f us', [(cccc2 - cccc1) / tttt * 1e6]);
end;

{$else}

procedure tic;
begin
  tttt := SDL_GetTicks;
end;

procedure toc;
begin
  Message(' %d ms', [SDL_GetTicks - tttt]);
end;

{$endif}


procedure Message(formatstring: string; content: array of const; cr: boolean = True); overload;
var
  i: integer;
  str: string;
begin
{$ifdef console}
  Write(format(formatstring, content));
  if cr then
    writeln();
{$endif}
{$ifdef android}
  str := format(formatstring, content);
  mythoutput.mythoutput(pchar(str));
  {i := fileopen(SDL_AndroidGetExternalStoragePath()+'/pig3_place_game_here',fmopenwrite);
  fileseek(i, 0, 2);
  filewrite(i, str[1], length(str));
  fileclose(i);}
{$endif}
end;

procedure Message(formatstring: string = ''; cr: boolean = True); overload;
var
  i: integer;
  str: string;
begin
{$ifdef console}
  Write(format(formatstring, []));
  if cr then
    writeln();
{$endif}
{$ifdef android}
  str := format(formatstring, []);
  mythoutput.mythoutput(pchar(str));
  {i := fileopen(SDL_AndroidGetExternalStoragePath()+'/pig3_place_game_here',fmopenwrite);
  fileseek(i, 0, 2);
  filewrite(i, str[1], length(str));
  fileclose(i);}
{$endif}
end;

end.
