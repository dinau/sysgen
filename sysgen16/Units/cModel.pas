unit cModel;

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
  Classes, SysUtils, FileCtrl, FileUtil, INIFiles,
   cModelItem;

type
   TOnModelSaved = procedure(pSender:TObject;pName:ansistring) of object;
   TOnModelFound = procedure(pSender:TObject;pName:ansistring) of object;
   TModels = class(TObject)
   private
      FModels:TList;
      FMicrochipPath:string;
      FXC16Path:string;
      FdsPIC33:boolean;
      FOnModelSaved:TOnModelSaved;
      FOnModelFound:TOnModelFound;
      procedure SetPath(pPath:string);
      procedure SetXC16Path(pPath:string);
      function GetFilenameNoExt(pFilename:string):string;
      procedure FindCandidates(pIncAndGldPath:string);
   public
      constructor Create;
      destructor Destroy;override;
      procedure Clear;
      procedure BuildCandidates;
      procedure GetCandidates(pLines:TStrings);
      procedure SaveModels(pPathBASIC:string);
      property MicrochipPath:string read FMicrochipPath write SetPath;
      property XC16Path:string read FXC16Path write SetXC16Path;
      property dsPIC33:boolean read FdsPIC33 write FdsPIC33;
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
   FXC16Path := '';
   FDSPIC33 := false;
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
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TModels.SetXC16Path(pPath:string);
begin
   FXC16Path := pPath;
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
procedure TModels.FindCandidates(pIncAndGLDPath:string);
var
   Found, Index:integer;
   SearchRec:TSearchRec;
   Device:string;
   Model:TModelItem;
   DeviceList:TStringList;
begin
 //  Clear;
   if DirectoryExistsUTF8(pIncAndGldPath) { *Converted from DirectoryExists* } then
   begin
      DeviceList := TStringList.Create;
      Found := FindFirstUTF8(pIncAndGLDPath + '\inc\*.inc',faAnyFile,SearchRec); { *Converted from FindFirst* }
      if Found = 0 then
      begin
         while Found = 0 do
            with SearchRec do
            begin
               Device := Uppercase(GetFilenameNoExt(SearchRec.Name));
               if Pos('P', Device) = 1 then
               begin
                  if FileExistsUTF8(pIncAndGLDPath + '\gld\' + Device + '.gld') { *Converted from FileExists* } then
                  begin
                     Device := Copy(Device,2,Length(Device));

                     if Pos('24',Device) = 1 then
                        DeviceList.Add(Device);

                     // v1.1 *JM*
                     if (FdsPIC33) then
                     begin
                        if Pos('33',Device) = 1 then
                           DeviceList.Add(Device);
                        if Pos('30',Device) = 1 then
                           DeviceList.Add(Device);
                     end;
                  end;
               end;
               Found := FindNextUTF8(SearchRec); { *Converted from FindNext* }
            end;
      end;
      FindCloseUTF8(SearchRec); { *Converted from FindClose* }

      for Index := 0 to DeviceList.Count - 1 do
      begin
         Model := TModelItem.Create(pIncAndGLDPath,DeviceList.Strings[Index]);
         if Model.IsValid then
         begin
            FModels.Add(Model);
            if Assigned(FOnModelFound) then
               FOnModelFound(self,Model.Device);
         end
         else
            Model.Free;
      end;
      DeviceList.Free;
   end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TModels.BuildCandidates;
begin
   Clear;
   if DirectoryExistsUTF8(FXC16Path) { *Converted from DirectoryExists* } then
   begin
      Clear;
      FindCandidates(FXC16Path + '\Support\PIC24E');
      FindCandidates(FXC16Path + '\Support\PIC24F');
      FindCandidates(FXC16Path + '\Support\PIC24H');
// *JM*
      FindCandidates(FXC16Path + '\Support\dsPIC30F');
      FindCandidates(FXC16Path + '\Support\dsPIC33E');
      FindCandidates(FXC16Path + '\Support\dsPIC33F');
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
   if DirectoryExistsUTF8(pPathBASIC) { *Converted from DirectoryExists* } then
   begin
      Lines := TStringList.Create;
      for Index := 0 to FModels.Count - 1 do
      begin
         Model := TModelItem(FModels.Items[Index]);

         Lines.Clear;
         if Model.SaveToStrings_BASIC(Lines) then
         begin
            Lines.SaveToFile(pPathBASIC + Model.Device + '.bas');
            Lines.Clear;

            if Assigned(FOnModelSaved) then
               FOnModelSaved(self,Model.Device);
         end;

      end;
      Lines.Free;
   end;
end;

end.
