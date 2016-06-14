unit mythoutput;

{$mode delphi}

interface

{$ifdef android}
const
  LIB_NAME = 'libmythoutput.so';

function mythoutput(const str: PChar): integer; cdecl; external LIB_NAME;
function Android_ReadFiletoBuffer(p: PChar; filename: PChar; size: integer; ismalloc: integer): PChar;
  cdecl; external LIB_NAME;
function Android_FileFreeBuffer(p: pchar):integer; cdecl; external LIB_NAME;
function Android_FileGetlength(filename: pchar):integer; cdecl; external LIB_NAME;
//char* Android_ReadFiletoBuffer(char* p,char* filename,int size,int ismalloc);
//int Android_FileFreeBuffer(char* p);
//int Android_FileGetlength(char* filename);
{$endif}
implementation

end.
