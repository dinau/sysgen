program sysgen08;

uses
  Forms,
  UnitMain in 'UnitMain.pas' {MainForm},
  cDialogs in 'Units\cDialogs.pas',
  cModel in 'Units\cModel.pas',
  cModelItem in 'Units\cModelItem.pas',
  cDeviceInfo in 'Units\cDeviceInfo.pas',
  gDeviceInfo in 'Units\gDeviceInfo.pas',
  cSFR in 'Units\cSFR.pas',
  cBadRAM in 'Units\cBadRAM.pas',
  cUtils in 'Units\cUtils.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.Title := 'System Generator';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
