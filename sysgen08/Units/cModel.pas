unit cModel;

interface

uses
   Windows, Classes, SysUtils, FileCtrl, INIFiles,
   cModelItem, gDeviceInfo;

type
   TOnModelSaved = procedure(pSender:TObject;pName:string) of object;
   TOnModelFound = procedure(pSender:TObject;pName:string) of object;
   TModels = class(TObject)
   private
      FModels:TList;
      FMicrochipPath:string;
      FMPASMPath:string;
      FOnModelSaved:TOnModelSaved;
      FOnModelFound:TOnModelFound;
      procedure SetPath(pPath:string);
      function GetFilenameNoExt(pFilename:string):string;
   public
      constructor Create;
      destructor Destroy;override;
      procedure Clear;
      procedure BuildCandidates;
      procedure GetCandidates(pLines:TStrings);
      procedure SaveModels(pPathBASIC:string);
      property MicrochipPath:string read FMicrochipPath write SetPath;
      property MPASMPath:string read FMPASMPath;
      property OnModelSaved:TOnModelSaved read FOnModelSaved write FOnModelSaved;
      property OnModelFound:TOnModelFound read FOnModelFound write FOnModelFound;
   end;

implementation

{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
constructor TModels.Create;
begin
   inherited Create;
   FMicrochipPath := '';
   FMPASMPath := '';
   FModels := TList.Create;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
destructor TModels.Destroy;
begin
   Clear;
   FModels.Free;
   inherited Destroy;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TModels.Clear;
var
   Index:integer;
begin
   for index := 0 to FModels.Count - 1 do
      TModelItem(FModels.Items[index]).Free;
   FModels.Clear;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TModels.SetPath(pPath:string);
begin
   FMicrochipPath := pPath;
   FMPASMPath := FMicrochipPath;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModels.GetFilenameNoExt(pFilename:string):string;
var
   index :integer;
begin
   index := Length(pFilename);
   while (index > 0) and (pFilename[index] <> '.') do
      dec(index);
   result := Copy(pFilename,1,Length(pFilename) - (Length(pFilename) - index + 1));
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TModels.BuildCandidates;
var
   Index:integer;
   Device:string;
   Model:TModelItem;
begin
   Clear;

   // search the mpasm dev.info file for names of 18F devices
   // and add them to the FModels list
   DeviceInfo.GetDeviceList(FMPASMPath);
   for Index := 0 to DeviceInfo.DevList.Count - 1 do
   begin
      Device := DeviceInfo.DevList.Strings[Index];
      if FileExists(FMPASMPath + '\p' + Device + '.inc') then
      begin
         Model := TModelItem.Create(FMPASMPath,DeviceInfo.DevList.Strings[Index]);
         if Model.IsValid then
         begin
            FModels.Add(Model);
            if Assigned(FOnModelFound) then
               FOnModelFound(self,Model.Device);
         end
         else
            Model.Free;
      end;
   end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TModels.GetCandidates(pLines:TStrings);
var
   Index:integer;
begin
   for Index := 0 to FModels.Count - 1 do
      pLines.Add(TModelItem(FModels.Items[Index]).Device);
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TModels.SaveModels(pPathBASIC:string);
var
   Index:integer;
   Model:TModelItem;
   Lines:TStringList;
begin
   pPathBASIC := pPathBASIC + '\';
   if DirectoryExists(pPathBASIC) then
   begin
      Lines := TStringList.Create;
      for Index := 0 to FModels.Count - 1 do
      begin
         Model := TModelItem(FModels.Items[Index]);
         Lines.Clear;
         if Model.SaveToStrings(Lines) then
         begin
            Lines.SaveToFile(pPathBASIC + Model.Device + '.bas');
            if Assigned(FOnModelSaved) then
               FOnModelSaved(self,Model.Device);
         end;
      end;
      Lines.Free;
   end;
end;

end.
