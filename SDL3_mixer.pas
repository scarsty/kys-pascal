unit SDL3_mixer;

{$mode objfpc}{$H+}

interface

uses
  ctypes,
  SDL3;

const
{$IFDEF WINDOWS}
  SDL_MIXER_LIB = 'SDL3_mixer.dll';
{$ELSE}
  SDL_MIXER_LIB = 'SDL3_mixer';
{$ENDIF}

  SDL_MIXER_MAJOR_VERSION = 3;
  SDL_MIXER_MINOR_VERSION = 2;
  SDL_MIXER_MICRO_VERSION = 0;

  MIX_DURATION_UNKNOWN = -1;
  MIX_DURATION_INFINITE = -2;

  MIX_PROP_MIXER_DEVICE_NUMBER = 'SDL_mixer.mixer.device';
  MIX_PROP_AUDIO_LOAD_IOSTREAM_POINTER = 'SDL_mixer.audio.load.iostream';
  MIX_PROP_AUDIO_LOAD_CLOSEIO_BOOLEAN = 'SDL_mixer.audio.load.closeio';
  MIX_PROP_AUDIO_LOAD_PREDECODE_BOOLEAN = 'SDL_mixer.audio.load.predecode';
  MIX_PROP_AUDIO_LOAD_PREFERRED_MIXER_POINTER = 'SDL_mixer.audio.load.preferred_mixer';
  MIX_PROP_AUDIO_LOAD_SKIP_METADATA_TAGS_BOOLEAN = 'SDL_mixer.audio.load.skip_metadata_tags';
  MIX_PROP_AUDIO_DECODER_STRING = 'SDL_mixer.audio.decoder';

  MIX_PROP_METADATA_TITLE_STRING = 'SDL_mixer.metadata.title';
  MIX_PROP_METADATA_ARTIST_STRING = 'SDL_mixer.metadata.artist';
  MIX_PROP_METADATA_ALBUM_STRING = 'SDL_mixer.metadata.album';
  MIX_PROP_METADATA_COPYRIGHT_STRING = 'SDL_mixer.metadata.copyright';
  MIX_PROP_METADATA_TRACK_NUMBER = 'SDL_mixer.metadata.track';
  MIX_PROP_METADATA_TOTAL_TRACKS_NUMBER = 'SDL_mixer.metadata.total_tracks';
  MIX_PROP_METADATA_YEAR_NUMBER = 'SDL_mixer.metadata.year';
  MIX_PROP_METADATA_DURATION_FRAMES_NUMBER = 'SDL_mixer.metadata.duration_frames';
  MIX_PROP_METADATA_DURATION_INFINITE_BOOLEAN = 'SDL_mixer.metadata.duration_infinite';

  MIX_PROP_PLAY_LOOPS_NUMBER = 'SDL_mixer.play.loops';
  MIX_PROP_PLAY_MAX_FRAME_NUMBER = 'SDL_mixer.play.max_frame';
  MIX_PROP_PLAY_MAX_MILLISECONDS_NUMBER = 'SDL_mixer.play.max_milliseconds';
  MIX_PROP_PLAY_START_FRAME_NUMBER = 'SDL_mixer.play.start_frame';
  MIX_PROP_PLAY_START_MILLISECOND_NUMBER = 'SDL_mixer.play.start_millisecond';
  MIX_PROP_PLAY_LOOP_START_FRAME_NUMBER = 'SDL_mixer.play.loop_start_frame';
  MIX_PROP_PLAY_LOOP_START_MILLISECOND_NUMBER = 'SDL_mixer.play.loop_start_millisecond';
  MIX_PROP_PLAY_FADE_IN_FRAMES_NUMBER = 'SDL_mixer.play.fade_in_frames';
  MIX_PROP_PLAY_FADE_IN_MILLISECONDS_NUMBER = 'SDL_mixer.play.fade_in_milliseconds';
  MIX_PROP_PLAY_FADE_IN_START_GAIN_FLOAT = 'SDL_mixer.play.fade_in_start_gain';
  MIX_PROP_PLAY_APPEND_SILENCE_FRAMES_NUMBER = 'SDL_mixer.play.append_silence_frames';
  MIX_PROP_PLAY_APPEND_SILENCE_MILLISECONDS_NUMBER = 'SDL_mixer.play.append_silence_milliseconds';
  MIX_PROP_PLAY_HALT_WHEN_EXHAUSTED_BOOLEAN = 'SDL_mixer.play.halt_when_exhausted';

  { Old-style compat constants used by existing project code }
  SDL_MIXER_INIT_FLAC = $00000001;
  SDL_MIXER_INIT_MOD = $00000002;
  SDL_MIXER_INIT_MP3 = $00000008;
  SDL_MIXER_INIT_OGG = $00000010;
  SDL_MIXER_INIT_MID = $00000020;
  MIX_MAX_VOLUME = 128;

type
  PPAnsiChar = ^PAnsiChar;

  { Some SDL3 Pascal headers in this project do not expose these C names. }
  SDL_AudioDeviceID = UInt32;
  SDL_PropertiesID = UInt32;
  Sint64 = Int64;

  MIX_Mixer = Pointer;
  MIX_Audio = Pointer;
  MIX_Track = Pointer;
  MIX_Group = Pointer;
  MIX_AudioDecoder = Pointer;

  PPMIX_Track = ^MIX_Track;

  MIX_StereoGains = record
    left: Single;
    right: Single;
  end;
  PMIX_StereoGains = ^MIX_StereoGains;

  MIX_Point3D = record
    x: Single;
    y: Single;
    z: Single;
  end;
  PMIX_Point3D = ^MIX_Point3D;

  MIX_TrackStoppedCallback = procedure(userdata: Pointer; track: MIX_Track); cdecl;
  MIX_TrackMixCallback = procedure(userdata: Pointer; track: MIX_Track; spec: PSDL_AudioSpec; pcm: PSingle; samples: cint); cdecl;
  MIX_GroupMixCallback = procedure(userdata: Pointer; group: MIX_Group; spec: PSDL_AudioSpec; pcm: PSingle; samples: cint); cdecl;
  MIX_PostMixCallback = procedure(userdata: Pointer; mixer: MIX_Mixer; spec: PSDL_AudioSpec; pcm: PSingle; samples: cint); cdecl;

  { Old-style compat opaque handles for legacy call sites }
  PMIX_Music = Pointer;
  PMIX_Chunk = Pointer;

function MIX_Version(): cint; cdecl; external SDL_MIXER_LIB;
function MIX_Init(): Boolean; cdecl; external SDL_MIXER_LIB;
procedure MIX_Quit(); cdecl; external SDL_MIXER_LIB;
function MIX_GetNumAudioDecoders(): cint; cdecl; external SDL_MIXER_LIB;
function MIX_GetAudioDecoder(index: cint): PAnsiChar; cdecl; external SDL_MIXER_LIB;
function MIX_CreateMixerDevice(devid: SDL_AudioDeviceID; spec: PSDL_AudioSpec): MIX_Mixer; cdecl; external SDL_MIXER_LIB;
function MIX_CreateMixer(spec: PSDL_AudioSpec): MIX_Mixer; cdecl; external SDL_MIXER_LIB;
procedure MIX_DestroyMixer(mixer: MIX_Mixer); cdecl; external SDL_MIXER_LIB;
function MIX_GetMixerProperties(mixer: MIX_Mixer): SDL_PropertiesID; cdecl; external SDL_MIXER_LIB;
function MIX_GetMixerFormat(mixer: MIX_Mixer; spec: PSDL_AudioSpec): Boolean; cdecl; external SDL_MIXER_LIB;
procedure MIX_LockMixer(mixer: MIX_Mixer); cdecl; external SDL_MIXER_LIB;
procedure MIX_UnlockMixer(mixer: MIX_Mixer); cdecl; external SDL_MIXER_LIB;
function MIX_LoadAudio_IO(mixer: MIX_Mixer; io: PSDL_IOStream; predecode: Boolean; closeio: Boolean): MIX_Audio; cdecl; external SDL_MIXER_LIB;
function MIX_LoadAudio(mixer: MIX_Mixer; path: PAnsiChar; predecode: Boolean): MIX_Audio; cdecl; external SDL_MIXER_LIB;
function MIX_LoadAudioNoCopy(mixer: MIX_Mixer; data: Pointer; datalen: NativeUInt; free_when_done: Boolean): MIX_Audio; cdecl; external SDL_MIXER_LIB;
function MIX_LoadAudioWithProperties(props: SDL_PropertiesID): MIX_Audio; cdecl; external SDL_MIXER_LIB;
function MIX_LoadRawAudio_IO(mixer: MIX_Mixer; io: PSDL_IOStream; spec: PSDL_AudioSpec; closeio: Boolean): MIX_Audio; cdecl; external SDL_MIXER_LIB;
function MIX_LoadRawAudio(mixer: MIX_Mixer; data: Pointer; datalen: NativeUInt; spec: PSDL_AudioSpec): MIX_Audio; cdecl; external SDL_MIXER_LIB;
function MIX_LoadRawAudioNoCopy(mixer: MIX_Mixer; data: Pointer; datalen: NativeUInt; spec: PSDL_AudioSpec; free_when_done: Boolean): MIX_Audio; cdecl; external SDL_MIXER_LIB;
function MIX_CreateSineWaveAudio(mixer: MIX_Mixer; hz: cint; amplitude: Single; ms: Sint64): MIX_Audio; cdecl; external SDL_MIXER_LIB;
function MIX_GetAudioProperties(audio: MIX_Audio): SDL_PropertiesID; cdecl; external SDL_MIXER_LIB;
function MIX_GetAudioDuration(audio: MIX_Audio): Sint64; cdecl; external SDL_MIXER_LIB;
function MIX_GetAudioFormat(audio: MIX_Audio; spec: PSDL_AudioSpec): Boolean; cdecl; external SDL_MIXER_LIB;
procedure MIX_DestroyAudio(audio: MIX_Audio); cdecl; external SDL_MIXER_LIB;
function MIX_CreateTrack(mixer: MIX_Mixer): MIX_Track; cdecl; external SDL_MIXER_LIB;
procedure MIX_DestroyTrack(track: MIX_Track); cdecl; external SDL_MIXER_LIB;
function MIX_GetTrackProperties(track: MIX_Track): SDL_PropertiesID; cdecl; external SDL_MIXER_LIB;
function MIX_GetTrackMixer(track: MIX_Track): MIX_Mixer; cdecl; external SDL_MIXER_LIB;
function MIX_SetTrackAudio(track: MIX_Track; audio: MIX_Audio): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_SetTrackAudioStream(track: MIX_Track; stream: PSDL_AudioStream): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_SetTrackIOStream(track: MIX_Track; io: PSDL_IOStream; closeio: Boolean): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_SetTrackRawIOStream(track: MIX_Track; io: PSDL_IOStream; spec: PSDL_AudioSpec; closeio: Boolean): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_TagTrack(track: MIX_Track; tag: PAnsiChar): Boolean; cdecl; external SDL_MIXER_LIB;
procedure MIX_UntagTrack(track: MIX_Track; tag: PAnsiChar); cdecl; external SDL_MIXER_LIB;
function MIX_GetTrackTags(track: MIX_Track; count: Pcint): PPAnsiChar; cdecl; external SDL_MIXER_LIB;
function MIX_GetTaggedTracks(mixer: MIX_Mixer; tag: PAnsiChar; count: Pcint): PPMIX_Track; cdecl; external SDL_MIXER_LIB;
function MIX_SetTrackPlaybackPosition(track: MIX_Track; frames: Sint64): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_GetTrackPlaybackPosition(track: MIX_Track): Sint64; cdecl; external SDL_MIXER_LIB;
function MIX_GetTrackFadeFrames(track: MIX_Track): Sint64; cdecl; external SDL_MIXER_LIB;
function MIX_GetTrackLoops(track: MIX_Track): cint; cdecl; external SDL_MIXER_LIB;
function MIX_SetTrackLoops(track: MIX_Track; num_loops: cint): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_GetTrackAudio(track: MIX_Track): MIX_Audio; cdecl; external SDL_MIXER_LIB;
function MIX_GetTrackAudioStream(track: MIX_Track): PSDL_AudioStream; cdecl; external SDL_MIXER_LIB;
function MIX_GetTrackRemaining(track: MIX_Track): Sint64; cdecl; external SDL_MIXER_LIB;
function MIX_TrackMSToFrames(track: MIX_Track; ms: Sint64): Sint64; cdecl; external SDL_MIXER_LIB;
function MIX_TrackFramesToMS(track: MIX_Track; frames: Sint64): Sint64; cdecl; external SDL_MIXER_LIB;
function MIX_AudioMSToFrames(audio: MIX_Audio; ms: Sint64): Sint64; cdecl; external SDL_MIXER_LIB;
function MIX_AudioFramesToMS(audio: MIX_Audio; frames: Sint64): Sint64; cdecl; external SDL_MIXER_LIB;
function MIX_MSToFrames(sample_rate: cint; ms: Sint64): Sint64; cdecl; external SDL_MIXER_LIB;
function MIX_FramesToMS(sample_rate: cint; frames: Sint64): Sint64; cdecl; external SDL_MIXER_LIB;
function MIX_PlayTrack(track: MIX_Track; options: SDL_PropertiesID): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_PlayTag(mixer: MIX_Mixer; tag: PAnsiChar; options: SDL_PropertiesID): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_PlayAudio(mixer: MIX_Mixer; audio: MIX_Audio): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_StopTrack(track: MIX_Track; fade_out_frames: Sint64): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_StopAllTracks(mixer: MIX_Mixer; fade_out_ms: Sint64): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_StopTag(mixer: MIX_Mixer; tag: PAnsiChar; fade_out_ms: Sint64): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_PauseTrack(track: MIX_Track): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_PauseAllTracks(mixer: MIX_Mixer): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_PauseTag(mixer: MIX_Mixer; tag: PAnsiChar): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_ResumeTrack(track: MIX_Track): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_ResumeAllTracks(mixer: MIX_Mixer): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_ResumeTag(mixer: MIX_Mixer; tag: PAnsiChar): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_TrackPlaying(track: MIX_Track): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_TrackPaused(track: MIX_Track): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_SetMixerGain(mixer: MIX_Mixer; gain: Single): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_GetMixerGain(mixer: MIX_Mixer): Single; cdecl; external SDL_MIXER_LIB;
function MIX_SetTrackGain(track: MIX_Track; gain: Single): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_GetTrackGain(track: MIX_Track): Single; cdecl; external SDL_MIXER_LIB;
function MIX_SetTagGain(mixer: MIX_Mixer; tag: PAnsiChar; gain: Single): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_SetMixerFrequencyRatio(mixer: MIX_Mixer; ratio: Single): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_GetMixerFrequencyRatio(mixer: MIX_Mixer): Single; cdecl; external SDL_MIXER_LIB;
function MIX_SetTrackFrequencyRatio(track: MIX_Track; ratio: Single): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_GetTrackFrequencyRatio(track: MIX_Track): Single; cdecl; external SDL_MIXER_LIB;
function MIX_SetTrackOutputChannelMap(track: MIX_Track; chmap: Pcint; count: cint): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_SetTrackStereo(track: MIX_Track; gains: PMIX_StereoGains): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_SetTrack3DPosition(track: MIX_Track; position: PMIX_Point3D): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_GetTrack3DPosition(track: MIX_Track; position: PMIX_Point3D): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_CreateGroup(mixer: MIX_Mixer): MIX_Group; cdecl; external SDL_MIXER_LIB;
procedure MIX_DestroyGroup(group: MIX_Group); cdecl; external SDL_MIXER_LIB;
function MIX_GetGroupProperties(group: MIX_Group): SDL_PropertiesID; cdecl; external SDL_MIXER_LIB;
function MIX_GetGroupMixer(group: MIX_Group): MIX_Mixer; cdecl; external SDL_MIXER_LIB;
function MIX_SetTrackGroup(track: MIX_Track; group: MIX_Group): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_SetTrackStoppedCallback(track: MIX_Track; cb: MIX_TrackStoppedCallback; userdata: Pointer): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_SetTrackRawCallback(track: MIX_Track; cb: MIX_TrackMixCallback; userdata: Pointer): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_SetTrackCookedCallback(track: MIX_Track; cb: MIX_TrackMixCallback; userdata: Pointer): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_SetGroupPostMixCallback(group: MIX_Group; cb: MIX_GroupMixCallback; userdata: Pointer): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_SetPostMixCallback(mixer: MIX_Mixer; cb: MIX_PostMixCallback; userdata: Pointer): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_Generate(mixer: MIX_Mixer; buffer: Pointer; buflen: cint): cint; cdecl; external SDL_MIXER_LIB;
function MIX_CreateAudioDecoder(path: PAnsiChar; props: SDL_PropertiesID): MIX_AudioDecoder; cdecl; external SDL_MIXER_LIB;
function MIX_CreateAudioDecoder_IO(io: PSDL_IOStream; closeio: Boolean; props: SDL_PropertiesID): MIX_AudioDecoder; cdecl; external SDL_MIXER_LIB;
procedure MIX_DestroyAudioDecoder(audiodecoder: MIX_AudioDecoder); cdecl; external SDL_MIXER_LIB;
function MIX_GetAudioDecoderProperties(audiodecoder: MIX_AudioDecoder): SDL_PropertiesID; cdecl; external SDL_MIXER_LIB;
function MIX_GetAudioDecoderFormat(audiodecoder: MIX_AudioDecoder; spec: PSDL_AudioSpec): Boolean; cdecl; external SDL_MIXER_LIB;
function MIX_DecodeAudio(audiodecoder: MIX_AudioDecoder; buffer: Pointer; buflen: cint; spec: PSDL_AudioSpec): cint; cdecl; external SDL_MIXER_LIB;

{ Compatibility API (legacy Mix_* names used by current codebase) }
implementation

end.
