unit simplecc;

{$mode Delphi}

interface

uses
  Classes, SysUtils;

const
  {$ifdef windows}
  LIB_NAME = 'simplecc.dll';
  {$else}
  LIB_NAME = 'libsimplecc.so';
{$endif}
function simplecc_create(): pointer; cdecl; external LIB_NAME;
function simplecc_load(cc: Pointer; filename: pansichar): integer; cdecl; external LIB_NAME;
function simplecc_convert(cc: Pointer; src: pansichar): pansichar; cdecl; external LIB_NAME;
function simplecc_load1(cc: Pointer; filename: utf8string): integer;
function simplecc_convert1(cc: Pointer; src: utf8string): utf8string;

implementation

function simplecc_load1(cc: Pointer; filename: utf8string): integer;
begin
  Result := simplecc_load(cc, Putf8Char(filename));
end;

function simplecc_convert1(cc: Pointer; src: utf8string): utf8string;
var
  res: pansichar;
begin
  res := simplecc_convert(cc, Putf8Char(src));
  if res = nil then
    Result := ''
  else
    Result := utf8string(res);
  // Note: No need to free 'res' as it is managed by the library  
end;

end.
