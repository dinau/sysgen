unit UnitMain;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
{$IFnDEF FPC}
  Windows,
{$ELSE}
  LCLIntf, LCLType, LMessages,
{$ENDIF}
  Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Registry, StdCtrls,
  cModel, ClipBrd, ExtCtrls, FileUtil;

type

  { TMainForm }

  TMainForm = class(TForm)
    ButtonConvert: TButton;
    MemoDevices: TMemo;
    ButtonGetCandidates: TButton;
    ButtonCopy: TButton;
    Label2: TLabel;
    LabelXC16Path: TLabel;
    ButtonChangeXC16Folder: TButton;
    Bevel3: TBevel;
    Panel1: TPanel;
    FFolderDialog: TSelectDirectoryDialog;
    StatusBar: TLabel;
    CheckBoxDSPIC: TCheckBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure ButtonConvertClick(Sender: TObject);
    procedure ButtonGetCandidatesClick(Sender: TObject);
    procedure ButtonCopyClick(Sender: TObject);
    procedure ButtonChangeXC16FolderClick(Sender: TObject);
    procedure CheckBoxDsPICClick(Sender: TObject);
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
     procedure OnModelSaved(pSender:TObject;pName:ansistring);
     procedure OnModelFound(pSender:TObject;pName:ansistring);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

const
   RegSwordfishIDE            = '\Software\MecaniqueUK\SystemConvert16';
   RegPath                    = RegSwordfishIDE;
   RegRootKey                 = HKEY_CURRENT_USER;
   RegConverter               = 'Converter';
   RegXC16Path                = 'XC16Path';
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
   FModels.dsPIC33 := CheckBoxDSPIC.Checked;
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
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TMainForm.FormShow(Sender: TObject);
begin
{
}
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

      // xc16 path
      if OpenKey(Regpath + '\' + RegConverter,false) then
      begin
         try
            FModels.XC16Path := lowercase(ReadString(RegXC16Path));
            if DirectoryExistsUTF8(FModels.XC16Path) then
               LabelXC16Path.Caption := FModels.XC16Path;
         except
            LabelXC16Path.Caption := 'program files\microchip\xc16\v1.11';
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
            WriteString(RegXC16Path,FModels.XC16Path);
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
   DevicesPerLine = 5;
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
// original routine - skips devices
procedure TMainForm.MakeDeviceCommaList;
var
   NewList:TStringList;
   Index:integer;
   Line:string;
begin
   NewList := TStringList.Create;
   NewList.Assign(MemoDevices.Lines);
   MemoDevices.Clear;
   Line := '';
   for Index := 0 to NewList.Count - 1 do
      if (Index mod 9 = 0) then
      begin
         if Line <> '' then
            MemoDevices.Lines.Add(Line + ', ');
         Line := '';
      end
      else if Line <> '' then
         Line := Line + ', ' + NewList.Strings[Index]
      else
         Line := NewList.Strings[Index];
   MemoDevices.Lines.Add(Line);
   NewList.Free;
end;
}
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
   StatusBar.Caption := ' ' + IntToStr(MemoDevices.Lines.Count) + ' device(s) found';
   MakeDeviceCommaList;
   ButtonGetCandidates.Enabled := true;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TMainForm.OnModelSaved(pSender:TObject;pName:ansistring);
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
procedure TMainForm.OnModelFound(pSender:TObject;pName:ansistring);
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
procedure TMainForm.ButtonChangeXC16FolderClick(Sender: TObject);
begin
   with FFolderDialog do
   begin
      Title := 'Please select the folder that contains the XC16 Compiler';
      InitialDir := FModels.XC16Path;
      Caption := 'Select Folder';
      if Execute then
      begin
         FModels.XC16Path := lowercase(FFolderDialog.FileName);
         LabelXC16Path.Caption := FModels.XC16Path;
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

{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TMainForm.CheckBoxDsPICClick(Sender: TObject);
begin
   FModels.dsPIC33 := CheckBoxDSPIC.Checked;
end;


end.
