program kys;

//{$MODE Delphi}
{$IFDEF UNIX}
{$LINKLIB SDL_ttf}
{$LINKLIB SDL_image}
//{$LINKLIB SDL_mixer}
{$linklib SDL_gfx}
{$LINKLIB lua}
{$linklib bass}
{$linklib bassmidi}
{$ELSE}

{$ENDIF}

//{$APPTYPE CONSOLE}

uses
  Forms,
  Interfaces,
  kys_type in 'kys_type.pas',
  kys_main in 'kys_main.pas',
  kys_event in 'kys_event.pas',
  kys_battle in 'kys_battle.pas',
  kys_engine in 'kys_engine.pas',
  kys_script in 'kys_script.pas',
  kys_draw in 'kys_draw.pas',
  lua52 in 'lua52.pas';

{$R *.res}

begin
  Application.Initialize;
  //Application.Run;
  Run;

end.

