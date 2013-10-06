program kys_promise;

//{$MODE Delphi}
{$IFDEF UNIX}
{$LINKLIB SDL_ttf}
{$LINKLIB SDL_image}
//{$LINKLIB SDL_mixer}
{$LINKLIB SDL_gfx}
{$LINKLIB smpeg}
{$LINKLIB lua}
{$LINKLIB bass}
{$LINKLIB bassmidi}
{$ELSE}

{$ENDIF}

{$APPTYPE GUI}

uses
  SysUtils,
  LCLIntf, LCLType, LMessages,
  Forms, Interfaces,
  kys_main in 'kys_main.pas',
  kys_event in 'kys_event.pas',
  kys_battle in 'kys_battle.pas',
  kys_engine in 'kys_engine.pas',
  kys_script in 'kys_script.pas',
  kys_littlegame in 'kys_littlegame.pas',
  Dialogs;

{$R kys_promise.res}


begin
  // Application.Title := 'KYS';
  // alpplication..Create(kysw).Enabled;
  // form1.Show;
  Application.Initialize;
  Run;
end.
