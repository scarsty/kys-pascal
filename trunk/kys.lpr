{$IFDEF android}
library kys;

{$ELSE}
program kys;
{$ENDIF}

//{$MODE Delphi}
{$IFDEF UNIX}

{$ELSE}

{$ENDIF}

uses
  Interfaces,
  Forms,
  kys_type in 'kys_type.pas',
  kys_main in 'kys_main.pas',
  kys_event in 'kys_event.pas',
  kys_battle in 'kys_battle.pas',
  kys_engine in 'kys_engine.pas',
  kys_script in 'kys_script.pas',
  kys_draw in 'kys_draw.pas';

{$R *.res}

{$IFDEF android}
exports
  Run;
{$endif}

begin
{$IFNDEF android}
  Application.Initialize;
  Run;
{$ENDIF}
end.

















