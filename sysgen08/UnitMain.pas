unit UnitMain;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{
// JM v1.2
// - revamp to use mpasm 8bit_device.info file
// - add module cDeviceInfo
}

interface

uses
{$IFnDEF FPC}
  Windows,
{$ELSE}
  LCLIntf, LCLType, LMessages,
{$ENDIF}
  Messages, SysUtils, Classes, Graphics, Controls,
  Forms, Dialogs, Registry, StdCtrls, ClipBrd, ExtCtrls, FileUtil,
  cModel, cDeviceInfo, gDeviceInfo;

type

  { TMainForm }

  TMainForm = class(TForm)
    Label1: TLabel;
    LabelIncludePath: TLabel;
    ButtonConvert: TButton;
    ButtonChangeFolder: TButton;
    MemoDevices: TMemo;
    ButtonGetCandidates: TButton;
    Panel1: TPanel;
    FFolderDialog: TSelectDirectoryDialog;
    StatusBar: TLabel;
    Bevel1: TBevel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ButtonConvertClick(Sender: TObject);
    procedure ButtonChangeFolderClick(Sender: TObject);
    procedure ButtonGetCandidatesClick(Sender: TObject);
    procedure ButtonCopyClick(Sender: TObject);
  private
     //FFolderDialog:TFolderDlg;
     FApplicationPath:string;
     FNewIncludePathBasic:string;
     FIncludes:TStringList;
     FModels:TModels;
     FConvertCount:integer;
     procedure LoadFromRegistry;
     procedure SaveToRegistry;
     procedure MakeDeviceCommaList;
     procedure CreateNewFolders;
     procedure OnModelSaved(pSender:TObject;pName:string);
     procedure OnModelFound(pSender:TObject;pName:string);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

const
   RegSwordfishIDE            = '\Software\MecaniqueUK\SystemConvert';
   RegPath                    = RegSwordfishIDE;
   RegRootKey                 = HKEY_CURRENT_USER;
   RegConverter               = 'Converter';
   RegMicrochipPath           = 'MicrochipPath';
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TMainForm.FormCreate(Sender: TObject);

begin
   FIncludes := TStringList.Create;
   FModels := TModels.Create;
   FModels.OnModelSaved := OnModelSaved;
   FModels.OnModelFound := OnModelFound;

   // JM - init new module
   DeviceInfo := TDeviceInfo.Create;

   //FFolderDialog := TFolderDlg.Create(self);
   FApplicationPath := ExtractFilePath(Application.ExeName);
   FNewIncludePathBASIC := FApplicationPath + 'NewIncludeBASIC';
   LoadFromRegistry;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TMainForm.FormDestroy(Sender: TObject);
begin
   SaveToRegistry;
   FIncludes.Free;
   FModels.Free;
   FFolderDialog.Free;
   DeviceInfo.Free;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TMainForm.FormShow(Sender: TObject);
begin
   ButtonGetCandidates.SetFocus;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TMainForm.LoadFromRegistry;
var
   Registry:TRegistry;
begin
   Registry := TRegistry.Create;
   with Registry do
   begin
      // set the root key
      RootKey := RegRootKey;

      // compiler and its path
      if OpenKey(Regpath + '\' + RegConverter,false) then
      begin
         try
            FModels.MicrochipPath := Uppercase(ReadString(RegMicrochipPath));
            if DirectoryExistsUTF8(FModels.MicrochipPath) then
               LabelIncludePath.Caption := FModels.MicrochipPath;
         except
            LabelIncludePath.Caption := '[not specified]';
         end;
         CloseKey;
      end;

   end;
   Registry.Free;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TMainForm.SaveToRegistry;
var
   Registry:TRegistry;
begin
   Registry := TRegistry.Create;
   with Registry do
   begin
      // set the root key
      RootKey := RegRootKey;

      // compiler and its path
      if OpenKey(Regpath + '\' + RegConverter,true) then
      begin
         try
            WriteString(RegMicrochipPath,FModels.MicrochipPath);
         except
         end;
         CloseKey;
      end;

   end;
   Registry.Free;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TMainForm.CreateNewFolders;
begin
   if not DirectoryExistsUTF8(FNewIncludePathBASIC) then
      CreateDirUTF8(FNewIncludePathBASIC); { *Converted from CreateDir* }
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TMainForm.MakeDeviceCommaList;
var
   NewList:TStringList;
   Index:integer;
   Line:string;
const
   DevicesPerLine = 6;
begin
   NewList := TStringList.Create;
   NewList.Assign(MemoDevices.Lines);
   MemoDevices.Clear;

   // JM - original code skips listing the device when (index mod 6) = 0
   if (NewList.Count > 0) then
   begin
      Line := '';
      for Index := 0 to NewList.Count - 1 do
      begin
         Line := Line + NewList.Strings[Index];       // add device
         if (Index <> NewList.Count - 1) then         // if not last device add comma separator
            Line := Line + ', ';
         if (Index mod DevicesPerLine = 0) and (Index <> 0) then   // line filled...
         begin
            MemoDevices.Lines.Add(Line);
            Line := '';
         end
      end;
      if (Line <> '') then                            // add any remaining partial line
         MemoDevices.Lines.Add(Line);
   end;
   NewList.Free;
end;

{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TMainForm.ButtonGetCandidatesClick(Sender: TObject);
begin
   FIncludes.Clear;
   ButtonGetCandidates.Enabled := false;
   StatusBar.Caption := ' Working, please wait...';
   Application.ProcessMessages;

   MemoDevices.Clear;
   FModels.BuildCandidates;
   FModels.GetCandidates(MemoDevices.Lines);
   StatusBar.Caption := 'resource file: ' + DeviceInfo.ResFileVersion +
                        '    ' + IntToStr(MemoDevices.Lines.Count) + ' device(s) found';
   MakeDeviceCommaList;
   ButtonGetCandidates.Enabled := true;
   ButtonConvert.SetFocus;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TMainForm.OnModelSaved(pSender:TObject;pName:string);
begin
   if FIncludes.Count = 0 then
      FIncludes.Add('device = ' + pName)
   else
      FIncludes.Add('''device = ' + pName);
   MemoDevices.Lines.Add(pName);
   StatusBar.Caption := ' Converting : ' + pName;
   StatusBar.Update;
   Update;
   inc(FConvertCount);
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TMainForm.OnModelFound(pSender:TObject;pName:string);
begin
   if FIncludes.Count = 0 then
      FIncludes.Add('device = ' + pName)
   else
      FIncludes.Add('''device = ' + pName);
   StatusBar.Caption := ' Processing : ' + pName;
   StatusBar.Update;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TMainForm.ButtonConvertClick(Sender: TObject);
begin
   FIncludes.Clear;
   MemoDevices.Clear;
   ButtonGetCandidates.Enabled := false;
   ButtonConvert.Enabled := false;
   Application.ProcessMessages;

   FConvertCount := 0;
   CreateNewFolders;
   FModels.SaveModels(FNewIncludePathBASIC);
   StatusBar.Caption := ' ' + IntToStr(FConvertCount) + ' device(s) converted';
   ButtonGetCandidates.Enabled := true;
   ButtonConvert.Enabled := true;
   MakeDeviceCommaList;   
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TMainForm.ButtonChangeFolderClick(Sender: TObject);
begin
   with FFolderDialog do
   begin
      Title := 'Please select the folder that contains the Microchip MPASM/MPASMX files';
      InitialDir := FModels.MicrochipPath;
      Caption := 'Select Folder';
      if Execute then
      begin
         FModels.MicrochipPath := uppercase(FFolderDialog.FileName);
         LabelIncludePath.Caption := FModels.MicrochipPath;
      end;
   end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TMainForm.ButtonCopyClick(Sender: TObject);
begin
   ClipBoard.AsText := FIncludes.Text;
end;

end.
