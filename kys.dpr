program kys;

//{$MODE Delphi}
{$IFDEF UNIX}
{$LINKLIB SDL_ttf}
{$LINKLIB SDL_image}
{$LINKLIB SDL_mixer}
{$LINKLIB lua}
{$ELSE}

{$ENDIF}

//{$APPTYPE CONSOLE}

uses
  SysUtils,
  Windows,
  Dialogs,
  Forms,
  kys_main in 'kys_main.pas',
  kys_event in 'kys_event.pas',
  kys_battle in 'kys_battle.pas',
  kys_engine in 'kys_engine.pas',
  kys_script in 'kys_script.pas',
  lua52 in 'lua52.pas';

{$R *.res}

begin
  Application.Initialize;
  //Application.Run;
  Run;

end.
