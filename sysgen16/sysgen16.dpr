program sysgen16;

uses
  Forms,
  UnitMain in 'UnitMain.pas' {MainForm},
  cDialogs in 'Units\cDialogs.pas',
  cModel in 'Units\cModel.pas',
  cModelItem in 'Units\cModelItem.pas',
  cSFR in 'Units\cSFR.pas',
  cUtils in 'Units\cUtils.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'Firewing System Generator';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
