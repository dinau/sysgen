unit cDeviceInfo;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils, Classes;

function SplitStringIntoTokens(const Source:string; var TokensList:TStringList):integer;

type
   TDeviceInfo = class
   private
   public
      Lines: TStringList;
      LineIndex: integer;
      FileVer:string;
      DevList: TStringList;
      DevIndex: integer;
      PartInfoList: TStringList;
      PartInfoFound: boolean;

      constructor Create;
      destructor Destroy;override;
      procedure Clear();
      procedure GetDeviceList(pMPASMPath:string);
      function FindPartInfo(Device:string; var PartInfoList:TStringList):boolean;
      function GetConfigList(var ConfigList:TStringList):boolean;
      function NextLine():boolean;
      property ResFileVersion:string read FileVer;
   end;

implementation
{
****************************************************************************
* Name    : SplitStringIntoTokens
* Purpose : get '<xx>' delimited tokens from a string and put them in a list
*           PARMS : Source          - String to Split
*                   TokenList       - TStringList of Tokens
*           RETURN : Count of Tokens
****************************************************************************
}
function SplitStringIntoTokens(const Source:string; var TokensList:TStringList):integer;
var
   SourceString    : string;
   Token           : string;
   ch              : char;
   ix              : integer;
   FoundDelimiter  : boolean;
begin
   TokensList.Clear;
  
   // trim string
   SourceString := Trim(Source);

   Token := '';
   FoundDelimiter := False;
   ix := 0;
   while (ix < length(SourceString)) do begin
      ch := SourceString[ix];
      // next char index
      ix := ix + 1;

      // check for left delimiter (start of token)
      if (ch = '<') and (FoundDelimiter = False) then begin
         FoundDelimiter := True;
      end
      else begin
         if (FoundDelimiter) then begin
            if (ch = '>') then begin      // found right delimiter...
               // save token (if not null)
               if (Token <> '') then begin
                  TokensList.Add(Token);
               end;
               // copy rest of string to split
               SourceString := Trim(Copy(SourceString, ix, Length(SourceString)));
               Token := '';
               FoundDelimiter := False;
               ix := 0;
            end
            else begin
               // char is not a delimiter... add char to the token
               Token := Token + ch;
            end
         end
      end;
   end;
   // end of input string

   // add the last token to the list (if not null)
   if (Token <> '') then begin
      TokensList.Add(Token);
   end;

   // return the count of tokens found
   result := TokensList.Count;
end;


{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
constructor TDeviceInfo.Create;
begin
   inherited Create;
   Lines := TStringList.Create;
   DevList := TStringList.Create;
   FileVer := '<none>';
end;

{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
destructor TDeviceInfo.Destroy;
begin
   Clear;
   inherited Destroy;
end;

{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TDeviceInfo.Clear;
begin
   DevList.Free;
   DevIndex := 0;
   Lines.Free;
end;

{
****************************************************************************
* Name    : GetDeviceList                                                  *
* Purpose : load mpasm 8bit_device.info and get a list of PIC18 devices    *
****************************************************************************
<PARTS_INDEX_TYPE><10F200><823b>#################
1 <10F200>        device name
2 <823b>          file offset of device PART_INFO_TYPE
3 #################  padding (each PARTS_INDEX_TYPE is +50 chars/line)
}
procedure TDeviceInfo.GetDeviceList(pMPASMPath:string);
var
   Line: string;
   TokensList: TStringList;
   Index: integer;
begin
   DevIndex := 0;
   Index := 0;
   LineIndex := 0;
   FileVer := '<none>';
   DevList.Clear;

   Lines.Clear;
   try
      Lines.LoadFromFile(pMPASMPath + '\8bit_device.info');
   except
      exit;
   end;

   TokensList := TStringList.Create;

   // read file and get a list of the 18F devices (PARTS_INDEX_TYPE)
   for Index := 0 to Lines.Count - 1 do
   begin
      Line := Lines.Strings[Index];
      TokensList.Clear;
      // split string into tokens
      SplitStringIntoTokens(Line, TokensList);
      if (TokensList[0] = 'PARTS_INDEX_TYPE') then
      begin
        if (Pos('18F', TokensList[1]) = 1) then begin    // found 18F device
           DevList.Add(TokensList[1]);
        end
      end
      else if (TokensList[0] = 'PART_INFO_TYPE') then
      begin
         // we can quit now... past all the initial PARTS_INDEX_TYPE entries
         break;
      end
      else if (TokensList[0] = 'RES_FILE_VERSION_INFO_TYPE') then
      begin
         FileVer := 'V' + TokensList[1];
      end
   end;

   // record the line index where we stopped (first PART_INFO_TYPE)
   LineIndex := Index;

   TokensList.Free;
end;

{
****************************************************************************
* Name    : FindPartInfo                                                   *
* Purpose : read lines until Device part info section found                *
****************************************************************************
//
// PART_INFO_TYPE field decoding
//
<PART_INFO_TYPE><a680><PIC18F26K80><18xxxx><6><1><ffff><10><ff><3ff><5f><0><c>
1 <a680>       short identifier
2 <PIC18F26K80>   device name
3 <18xxxx>     device family
4 <6>          2=no XINST, 6=supports XINST (some 18FxxJ parts have '7', but this is changed/corrected in mpasmx)
5 <1>          all PIC18 devices
6 <ffff>       maxrom (flash size)
7 <10>         number of ram banks (same for all PIC18 devices... 16 banks) see note
8 <ff>         size of ram bank-1  ie bank is 0->ff = 256 bytes/bank (same for all PIC18 devices)
9 <3ff>        eeprom size
10 <5f>        accessbank split
11 <0>         all PIC18 devices
12 <c>         number of config registers (CONFIGREG_INFO_TYPEs)
}
function TDeviceInfo.FindPartInfo(Device:string; var PartInfoList:TStringList):boolean;
var
   Line: string;
   Index: integer;
begin
   Index := LineIndex;

   PartInfoFound := false;
   while ((PartInfoFound = false) and (Index < Lines.Count)) do
   begin
      Line := Lines.Strings[Index];
      // split string into tokens
      SplitStringIntoTokens(Line, PartInfoList);
      if (PartInfoList[0] = 'PART_INFO_TYPE') then begin
        // PART_INFO_TYPE device tokens have 'PIC' prefix in the device name
        if (PartInfoList[2] = 'PIC'+Device) then begin
            PartInfoFound := true;
            LineIndex := Index;
        end
      end;
      Index := Index + 1;
   end;
   result := PartInfoFound;
end;

{
****************************************************************************
* Name    : GetConfigList                                                  *
* Purpose : get a single config fuse ID and its settings                   *
****************************************************************************
//
// SWITCH_INFO_TYPE field decoding
//
<SWITCH_INFO_TYPE><FOSC><Oscillator Selection bits><f><e>
1 <FOSC>                      name
2 <Oscillator Selection bits> desc
3 <f>                         bit mask
4 <e>                         number of settings (SETTING_VALUE_TYPEs)
//
// SETTING_VALUE_TYPE field decoding
//
<SETTING_VALUE_TYPE><ECLPIO6><EC oscillator (low power, <500 kHz)><d>
1 <ECLPIO6>                  setting     
2 <EC oscillator (...)>      desc
3 <d>                        value
}
function TDeviceInfo.GetConfigList(var ConfigList:TStringList):boolean;
var
   Line: string;
   Index: integer;
   Found: boolean;
   TokensList: TStringList;
begin
   Index := LineIndex;
   Found := false;

   TokensList := TStringList.Create;

   ConfigList.Clear;

   // find the fuse ID
   while ((Found = false) and (Index < Lines.Count)) do begin
      Line := Lines.Strings[Index];
      SplitStringIntoTokens(Line, TokensList);
      if (TokensList[0] = 'SWITCH_INFO_TYPE') then begin    // new fuse ID
         ConfigList.Add(TokensList[1]);      // add fuse ID as first item in list
         Found := true;
      end;
      if (TokensList[0] = 'PART_INFO_TYPE') then break;
      Index := Index + 1;
   end;

   // now, find all the config settings
   while ((Found = true) and (Index < Lines.Count)) do begin
      Line := Lines.Strings[Index];
      SplitStringIntoTokens(Line, TokensList);
      if (TokensList[0] = 'SETTING_VALUE_TYPE') then begin    // new setting value
         if (TokensList[1] <> 'RESERVED') then
            ConfigList.Add(TokensList[1]);      // add fuse setting to list
         Index := Index + 1;
      end
      else begin
         Found := false;
      end;
   end;

   TokensList.Free;

   LineIndex := Index;
   if (ConfigList.Count > 0) then
      result := true
   else
      result := false;
end;

{
****************************************************************************
* Name    : NextLine                                                       *
* Purpose : advance to next line. return true=advanced, false=end of list  *
****************************************************************************
}
function TDeviceInfo.NextLine():boolean;
begin
   result := false;
   if (LineIndex < Lines.Count-1) then
   begin
      LineIndex := LineIndex + 1;
      result := true;
   end
end;

end.
