program sysgen16;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

uses
{$IFnDEF FPC}
{$ELSE}
  Interfaces,
{$ENDIF}
  Forms,
  UnitMain in 'UnitMain.pas' {MainForm},
  cModel in 'Units\cModel.pas',
  cModelItem in 'Units\cModelItem.pas',
  cSFR in 'Units\cSFR.pas',
  cUtils in 'Units\cUtils.pas';

begin
  Application.Initialize;
  Application.Title := 'Firewing System Generator';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
