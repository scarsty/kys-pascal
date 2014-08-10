{
  BASSmix 2.4 Delphi unit
  Copyright (c) 2005-2012 Un4seen Developments Ltd.

  See the BASSMIX.CHM file for more detailed documentation
}

Unit BASSmix;

interface

{$IFDEF MSWINDOWS}
uses BASS, Windows;
{$ELSE}
uses BASS;
{$ENDIF}

const
  // additional BASS_SetConfig option
  BASS_CONFIG_MIXER_BUFFER  = $10601;
  BASS_CONFIG_MIXER_POSEX   = $10602;
  BASS_CONFIG_SPLIT_BUFFER  = $10610;

  // BASS_Mixer_StreamCreate flags
  BASS_MIXER_END     = $10000;  // end the stream when there are no sources
  BASS_MIXER_NONSTOP = $20000;  // don't stall when there are no sources
  BASS_MIXER_RESUME  = $1000;   // resume stalled immediately upon new/unpaused source
  BASS_MIXER_POSEX   = $2000;   // enable BASS_Mixer_ChannelGetPositionEx support

  // source flags
  BASS_MIXER_BUFFER  = $2000;   // buffer data for BASS_Mixer_ChannelGetData/Level
  BASS_MIXER_LIMIT   = $4000;   // limit mixer processing to the amount available from this source
  BASS_MIXER_MATRIX  = $10000;  // matrix mixing
  BASS_MIXER_PAUSE   = $20000;  // don't process the source
  BASS_MIXER_DOWNMIX = $400000; // downmix to stereo/mono
  BASS_MIXER_NORAMPIN = $800000; // don't ramp-in the start

  // splitter flags
  BASS_SPLIT_SLAVE   = $1000;   // only read buffered data

  // envelope types
  BASS_MIXER_ENV_FREQ = 1;
  BASS_MIXER_ENV_VOL  = 2;
  BASS_MIXER_ENV_PAN  = 3;
  BASS_MIXER_ENV_LOOP = $10000; // FLAG: loop

  // additional sync type
  BASS_SYNC_MIXER_ENVELOPE = $10200;
  BASS_SYNC_MIXER_ENVELOPE_NODE = $10201;

  // BASS_CHANNELINFO type
  BASS_CTYPE_STREAM_MIXER = $10800;
  BASS_CTYPE_STREAM_SPLIT = $10801;

type
  // envelope node
  BASS_MIXER_NODE = record
	pos: QWORD;
	value: Single;
  end;

const
{$IFDEF MSWINDOWS}
  bassmixdll = 'bassmix.dll';
{$ENDIF}
{$IFDEF LINUX}
  bassmixdll = 'libbassmix.so';
{$ENDIF}
{$IFDEF MACOS}
  bassmixdll = 'libbassmix.dylib';
{$ENDIF}

function BASS_Mixer_GetVersion: DWORD; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;

function BASS_Mixer_StreamCreate(freq, chans, flags: DWORD): HSTREAM; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;
function BASS_Mixer_StreamAddChannel(handle: HSTREAM; channel, flags: DWORD): BOOL; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;
function BASS_Mixer_StreamAddChannelEx(handle: HSTREAM; channel, flags: DWORD; start, length: QWORD): BOOL; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;

function BASS_Mixer_ChannelGetMixer(handle: DWORD): HSTREAM; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;
function BASS_Mixer_ChannelFlags(handle, flags, mask: DWORD): DWORD; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;
function BASS_Mixer_ChannelRemove(handle: DWORD): BOOL; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;
function BASS_Mixer_ChannelSetPosition(handle: DWORD; pos: QWORD; mode: DWORD): BOOL; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;
function BASS_Mixer_ChannelGetPosition(handle, mode: DWORD): QWORD; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;
function BASS_Mixer_ChannelGetPositionEx(handle, mode, delay: DWORD): QWORD; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;
function BASS_Mixer_ChannelGetLevel(handle: DWORD): DWORD; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;
function BASS_Mixer_ChannelGetData(handle: DWORD; buffer: Pointer; length: DWORD): DWORD; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;
function BASS_Mixer_ChannelSetSync(handle: DWORD; type_: DWORD; param: QWORD; proc: SYNCPROC; user: Pointer): HSYNC; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;
function BASS_Mixer_ChannelRemoveSync(handle: DWORD; sync: HSYNC): BOOL; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;
function BASS_Mixer_ChannelSetMatrix(handle: DWORD; matrix: Pointer): BOOL; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;
function BASS_Mixer_ChannelGetMatrix(handle: DWORD; matrix: Pointer): BOOL; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;
function BASS_Mixer_ChannelSetEnvelope(handle, type_: DWORD; var nodes: BASS_MIXER_NODE; count: DWORD): BOOL; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;
function BASS_Mixer_ChannelSetEnvelopePos(handle, type_: DWORD; pos: QWORD): BOOL; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;
function BASS_Mixer_ChannelGetEnvelopePos(handle, type_: DWORD; value: PSingle): QWORD; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;

function BASS_Split_StreamCreate(channel, flags: DWORD; chanmap: PLongInt): HSTREAM; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;
function BASS_Split_StreamGetSource(handle: HSTREAM): DWORD; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;
function BASS_Split_StreamGetSplits(handle: DWORD; var splits: HSTREAM; count: DWORD): DWORD; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;
function BASS_Split_StreamReset(handle: DWORD): BOOL; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;
function BASS_Split_StreamResetEx(handle, offset: DWORD): BOOL; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;
function BASS_Split_StreamGetAvailable(handle: DWORD): DWORD; {$IFDEF MSWINDOWS}stdcall{$ELSE}cdecl{$ENDIF}; external bassmixdll;

implementation

end.
