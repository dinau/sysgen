unit cModelItem;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

{ JM v1.2
// - change to use mpasm's 8bit_device.info file instead of the MPLAB .dev files
// - the DeviceInfo class is now used to get config settings instead of relying
//    on comments in the MPASM .inc files (which was problematic)
// - change method of computing available ram
// - add new '#const _wdt_type' to output .bas file (conditional)
// - add PROD as a 16bit (conditional)
// - misc fixes
}

// JM - conditional to define PROD as a 16bit reg. comment out for 8bit
{$DEFINE PROD_AS_16BIT}
// JM - conditional to add '#const _wdt_type'
{$DEFINE _WDT_TYPE}

interface

uses
{$IFnDEF FPC}
  Windows,
{$ELSE}
  LCLIntf, LCLType, LMessages,
{$ENDIF}
  Forms, FileUtil, IniFiles, Classes, SysUtils,
   cSFR, cBadRAM, gDeviceInfo, cUtils;

type
   TModelItem = class(TObject)
   private
      FWriteDefaultINI:boolean;
      FMPASMFilename:string;
      FDevice:string;

      FMaxRAM:integer;
      FMaxRamUsed:integer;
      FMaxRamUsedContig:integer;
      FMaxRamBanksUsed:integer;
      FMaxRamAccess:integer;        // was from .dev file

      FMaxROM:integer;              // was from .dev file

      FBadRAM:TList;
      FEEPROM:integer;              // was from .dev file
      FEEPROMStart:integer;

      FNumberOfADC:integer;
      FADCRes:integer;
      FNumberOfComp:integer;
      FNumberOfCCP:integer;
      FNumberOfECCP:integer;
      FNumberOfECCPDel:integer;
      FPSP:integer;
      FEthernet:integer;
      FCan:integer;
      FFlashWrite:integer;
      FGenerateModel:boolean;
      FWdtType:integer;

      FSFR:TList;
      FPorts:TList;
      FFuses:TStringList;           // was from .asm file
      FDefaultFuses:TStringList;
      FBitnames:TStringList;

      procedure CalculateBanksAndRAMUsed;
      procedure DeleteSFR(pName:string);
      function GetLatch(pPort:string):string;
      function GetTRIS(pPort:string):string;
      function IsPort(pName:string):boolean;
      procedure UpdateAnalog(pName:string);
      function IsComp(pName:string):boolean;
      function IsPSP(pName:string):boolean;
      procedure UpdateCCP(pName:string);
      procedure UpdateEthernet(pName:string);
      procedure UpdateCan(pName:string);
      function GetNextPort(pPort:string):string;
      procedure GetMissingPorts(pPorts:TStrings);
      function HasMissingPorts:boolean;
      function NumberOfPorts:integer;
      function NumberOfUSART:integer;
      function NumberOfMSSP:integer;

      function HasUSB:integer;
      function HaveLH(pName:string):boolean;
      procedure MakeLH(pItem:TSFR);
      procedure LoadSFR;
      procedure LoadBadRAM;
      procedure LoadFuses;
      procedure Clear;
      function GetMPASMID(pLine:string):string;
      function GetMPASMValue(pLine:string):string;
      function ProcessValues(pValues:TStringList):string;
      function FindFuseValue(pValue:string;pValues:TStringList):boolean;
      procedure SetDefaultFuse(pID:string;pValues:TStringList);
      procedure SetWdtType(pID:string;pValues:TStringList);
      procedure MakeHeader(pName:string;pLines:TStrings);
      function Pad(pLine:string;pAmount:integer):string;
   public
      constructor Create(pMPASMPath, pDevice:string);
      destructor Destroy;override;
      function IsValid:boolean;
      function SaveToStrings(pLines:TStrings):boolean;
      property MPASMFilename:string read FMPASMFilename;
      property Device:string read FDevice;
      property WriteDefaultINI:boolean read FWriteDefaultINI write FWriteDefaultINI;
      property Ethernet:integer read FEthernet write FEthernet;
   end;

implementation

{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
constructor TModelItem.Create(pMPASMPath,pDevice:string);
var
   PartInfoList:TStringList;
begin
   inherited Create;
   FGenerateModel := true;
   FWriteDefaultINI := true;
   FMaxRam := 0;
   FMaxRamUsed := 0;
   FMaxRAMUsedContig := 0;
   FMaxRamBanksUsed := 0;
   FMaxRamAccess := 0;

   FNumberOfADC := 0;
   FADCRes := 10;
   FNumberOfComp := 0;
   FNumberOfCCP := 0;
   FNumberOfECCP := 0;
   FNumberOfECCPDel := 0;
   FPSP := 0;
   FEthernet := 0;
   FCan := 0;
   FFlashWrite := 1;
   FWdtType := 0;

   FMaxROM := 0;
   FSFR := TList.Create;
   FPorts := TList.Create;
   FBadRam := TList.Create;
   FEEPROM := $0000;
   FEEPROMStart := $F00000;
   FDevice := pDevice;
   FMPASMFilename := pMPASMPath + '\P' + FDevice + '.inc';
   FFuses := TStringList.Create;
   FDefaultFuses := TStringList.Create;
   FBitnames := TStringList.Create;

   PartInfoList := TStringList.Create;
   PartInfoList.Clear;

   // set maxrom, eeprom, and accessram from deviceinfo file
   if (DeviceInfo.FindPartInfo(FDevice, PartInfoList) = true) then
   begin
      FMaxROM := StrToInt('$' + PartInfoList[6]) + 1;     // maxrom field
      FEEPROM := StrToInt('$' + PartInfoList[9]);     // eeprom field
      if (FEEPROM <> 0) then FEEPROM := FEEPROM + 1;
      FMaxRamAccess := StrToInt('$' + PartInfoList[10]) + 1;     // access ram
   end;

   LoadSFR;
   LoadBadRAM;
   CalculateBanksAndRamUsed;
   LoadFuses;

   PartInfoList.Free;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
destructor TModelItem.Destroy;
begin
   Clear;
   FSFR.Free;
   FPorts.Free;
   FBadRam.Free;
   FFuses.Free;
   FDefaultFuses.Free;
   FBitnames.Free;
   inherited Destroy;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TModelItem.Clear;
var
   Index:integer;
begin
   for Index := 0 to FSFR.Count - 1 do
      TSFR(FSFR.Items[index]).Free;
   for Index := 0 to FPorts.Count - 1 do
      TSFR(FPorts.Items[index]).Free;
   for Index := 0 to FBadRam.Count - 1 do
      TBadRam(FBadRam.Items[index]).Free;
   FSFR.Clear;
   FPorts.Clear;
   FBadRam.Clear;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModelItem.IsValid:boolean;
begin
   result := true;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
// JM v12 - modified to use asm .INC file info only
// JM v11 - modified to attempt to better account for BANK15 ram usage
// in some cases, the original was leaving some ram on the table (no big deal),
// but for others it wasn't accounting for SFR's in the upper bank and was
// treating them as available ram (some of the .inc files BADRAM was incomplete)
// fixes devices like J11, J72, J94, K22, and K80 families (+ others)
//
procedure TModelItem.CalculateBanksAndRamUsed;
var
   Index, Lowest:integer;
begin

   // default to max ram = 4096
   Lowest := 4096;

   // find lowest of PORT registers
   for Index := 0 to FPorts.Count - 1 do
      if TSFR(FPorts.Items[index]).Address < Lowest then
         Lowest := TSFR(FPorts.Items[index]).Address;

   // find lowest of SFR registers
   for Index := 0 to FSFR.Count - 1 do
      if TSFR(FSFR.Items[index]).Address < Lowest then
         Lowest := TSFR(FSFR.Items[index]).Address;

   // find lowest of BADRAM regions
   for Index := 0 to FBadRam.Count - 1 do
      if TBadRam(FBadRam.Items[index]).RamStart < Lowest then
         Lowest := TBadRam(FBadRam.Items[index]).RamStart;

   Lowest := Lowest - 1;       // last usable addr

   // the number of RAM and RAM banks used
   FMaxRamUsed := Lowest + 1;
   FMaxRAMUsedContig := FMaxRAMUsed;
   FMaxRamBanksUsed := (Lowest div 256) + 1;    // number of banks
end;

{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TModelItem.DeleteSFR(pName:string);
var
   Item:TSFR;
   index:integer;
begin
   for Index := 0 to FSFR.Count - 1 do
   begin
      Item := TSFR(FSFR.Items[index]);
      if uppercase(pName) = uppercase(Item.Name) then
      begin
         Item.Free;
         FSFR.Items[index] := nil;
         FSFR.Pack;
         exit;
      end;
   end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModelItem.GetLatch(pPort:string):string;
begin
   result := 'LAT' + Copy(pPort,5,Length(pPort));
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModelItem.GetTRIS(pPort:string):string;
begin
   result := 'TRIS' + Copy(pPort,5,Length(pPort));
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModelItem.IsPort(pName:string):boolean;
begin
   pName := trim(lowercase(pName));
   result := (pName = 'porta') or
             (pName = 'portb') or
             (pName = 'portc') or
             (pName = 'portd') or
             (pName = 'porte') or
             (pName = 'portf') or
             (pName = 'portg') or
             (pName = 'porth') or
             (pName = 'porti') or
             (pName = 'portj') or
             (pName = 'portk') or
             (pName = 'portl') or
             (pName = 'portm') or
             (pName = 'portn');
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
// JM - this one's pretty hopeless as .inc files use ANx, ANSx, or ANSELx
// and combinations of them as well!
procedure TModelItem.UpdateAnalog(pName:string);
begin
   pName := trim(lowercase(pName));
   if Pos('an',pName) = 1 then
   begin
      if (pName = 'an0') or
            (pName = 'an1') or
            (pName = 'an2') or
            (pName = 'an3') or
            (pName = 'an4') or
            (pName = 'an5') or
            (pName = 'an6') or
            (pName = 'an7') or
            (pName = 'an8') or
            (pName = 'an9') or
            (pName = 'an10') or
            (pName = 'an11') or
            (pName = 'an12') or
            (pName = 'an13') or
            (pName = 'an14') or
            (pName = 'an15') then
               inc(FNumberOfADC);
  end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModelItem.IsComp(pName:string):boolean;
var
   index,Position:integer;
   MatchName:string;
begin
   result := false;
   pName := trim(lowercase(pName));
   Index := 0;
   while (Index < 8) and not result do
   begin
      MatchName := 'c' + IntToStr(Index) + 'out';
      if MatchName = pName then
         result := true
      else if Pos(MatchName + '_', pName) = 1 then
      begin
         Position := Pos('_',pName) + 1;
         MatchName := Copy(pName,Position,Length(pName) - 1);
         result := IsPort(MatchName);
      end;
      inc(Index);
   end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModelItem.IsPSP(pName:string):boolean;
begin
   pName := trim(lowercase(pName));
   result := (pName = 'pspmode');
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TModelItem.UpdateCCP(pName:string);
var
   NumStr:string;
   Number:integer;
begin
   pName := trim(lowercase(pName));

   if (Pos('ccp',pName) = 1) and (Pos('con',pName) = 5) then
   begin
      NumStr := Copy(pName,4,1);
      try
         Number := StrToInt(NumStr);
         if Number > FNumberOfCCP then
            FNumberOfCCP := Number;
      except
      end;
   end
   else if pName = 'ccpcon' then
      if FNumberOfCCP = 0 then
         FNumberOfCCP := 1;

   if (Pos('eccp',pName) = 1) and (Pos('as',pName) = 6) then
   begin
      NumStr := Copy(pName,5,1);
      try
         Number := StrToInt(NumStr);
         if Number > FNumberOfECCPDel then
            FNumberOfECCPDel := Number;
      except
      end;
   end
   else if pName = 'eccpas' then
      if FNumberOfECCPDel = 0 then
         FNumberOfECCPDel := 1;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TModelItem.UpdateEthernet(pName:string);
begin
   pName := trim(lowercase(pName));
   if (pName = 'erdptl') then
      FEthernet := 1;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TModelItem.UpdateCAN(pName:string);
begin
   pName := trim(lowercase(pName));
   if (pName = 'canstat') then
      FCan := 1;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModelItem.GetNextPort(pPort:string):string;
begin
   result := '';
   pPort := trim(uppercase(pPort));
   if pPort = 'PORTA' then
      result := 'PORTB'
   else if pPort = 'PORTB' then
      result := 'PORTC'
   else if pPort = 'PORTC' then
      result := 'PORTD'
   else if pPort = 'PORTD' then
      result := 'PORTE'
   else if pPort = 'PORTE' then
      result := 'PORTF'
   else if pPort = 'PORTF' then
      result := 'PORTG'
   else if pPort = 'PORTG' then
      result := 'PORTH'
   else if pPort = 'PORTH' then
      result := 'PORTI'
   else if pPort = 'PORTI' then
      result := 'PORTJ'
   else if pPort = 'PORTJ' then
      result := 'PORTK'
   else if pPort = 'PORTK' then
      result := 'PORTL'
   else if pPort = 'PORTL' then
      result := 'PORTM'
   else if pPort = 'PORTM' then
      result := 'PORTN';
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TModelItem.GetMissingPorts(pPorts:TStrings);
var
   ThisPort,NextPort:string;
   Index:integer;
begin
   if FPorts.Count > 0 then
   begin
      ThisPort := uppercase(TSFR(FPorts.Items[FPorts.Count - 1]).Name);
      for Index := (FPorts.Count - 1) downto 1 do
      begin
         NextPort := uppercase(TSFR(FPorts.Items[Index - 1]).Name);
         if NextPort = GetNextPort(ThisPort) then
            ThisPort := NextPort
         else
         begin
            ThisPort := GetNextPort(ThisPort);
            pPorts.Add(ThisPort);
         end;
      end;
   end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModelItem.HasMissingPorts:boolean;
var
   ThisPort,NextPort:string;
   Index:integer;
begin
   result := false;
   if FPorts.Count > 0 then
      for Index := 0 to FPorts.Count - 2 do
      begin
         NextPort := uppercase(TSFR(FPorts.Items[Index]).Name);
         ThisPort := uppercase(TSFR(FPorts.Items[Index + 1]).Name);
         if NextPort <> GetNextPort(ThisPort) then
         begin
            result := true;
            exit;
         end;
      end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModelItem.NumberOfPorts:integer;
begin
   result := FPorts.Count;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModelItem.NumberOfUSART:integer;
var
   Index:integer;
   SFR:TSFR;
begin
   result := 0;
   for Index := 0 to FSFR.Count - 1 do
   begin
      SFR := TSFR(FSFR.Items[index]);
      if uppercase(SFR.Name) = 'RCREG' then
      begin
         result := 1;
         exit;
      end
      else if uppercase(SFR.Name) = 'RCREG2' then
      begin
         result := 2;
         exit;
      end;
   end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModelItem.NumberOfMSSP:integer;
var
   Index:integer;
   SFR:TSFR;
begin
   result := 0;
   for Index := 0 to FSFR.Count - 1 do
   begin
      SFR := TSFR(FSFR.Items[index]);
      if uppercase(SFR.Name) = 'SSPSTAT' then
      begin
         result := 1;
         exit;
      end
      else if uppercase(SFR.Name) = 'SSP2STAT' then
      begin
         result := 2;
         exit;
      end;
  end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModelItem.HasUSB:integer;
var
   Index:integer;
   SFR:TSFR;
begin
   result := 0;
   for Index := 0 to FSFR.Count - 1 do
   begin
      SFR := TSFR(FSFR.Items[index]);
      if uppercase(SFR.Name) = 'UCON' then
      begin
         result := 1;
         exit;
      end;
   end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModelItem.HaveLH(pName:string):boolean;
var
   Index:integer;
begin
   result := false;
   for Index := 0 to FSFR.Count - 1 do
      if uppercase(TSFR(FSFR.Items[Index]).Name) = uppercase(pName) then
      begin
         result := true;
         exit;
      end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TModelItem.MakeLH(pItem:TSFR);
var
   Name,LoHi:string;
   Item,NewItem:TSFR;
begin
   if FSFR.Count > 1 then
   begin
      Name := uppercase(pItem.Name);
      if Length(Name) > 0 then
      begin
         LoHi := Name[Length(Name)];
         if LoHi = 'L' then
         begin
            Name := Copy(Name,1,Length(Name) - 1);
            Item := FSFR.Items[FSFR.Count - 2];
            if (uppercase(Item.Name) = Name + 'H') and not HaveLH(Name + 'LH') then
            begin
               NewItem := TSFR.Create(Name + 'LH',Item.Address);
               NewItem.IsLowHigh := true;
               FSFR.Insert(FSFR.Count - 1,NewItem);
            end;
         end
         else if LoHi = 'H' then
         begin
            Name := Copy(Name,1,Length(Name) - 1);
            Item := FSFR.Items[FSFR.Count - 2];
            if (uppercase(Item.Name) = Name + 'L') and not HaveLH(Name + 'LH') then
            begin
               NewItem := TSFR.Create(Name + 'LH',pItem.Address);
               NewItem.IsLowHigh := true;
               FSFR.Insert(FSFR.Count - 1,NewItem);
            end;
         end;
      end;
   end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TModelItem.LoadSFR;
var
   Item:TSFR;
   Lines:TStringList;
   Index,Position,BitnameValue:integer;
   Line,Bitname:string;
   RegStart,WaitingForBitnames:boolean;

begin
   FNumberOfADC := 0;
   FNumberOfComp := 0;
   FNumberOfCCP := 0;
   FNumberOfECCP := 0;
   FNumberOfECCPDel := 0;
   FPSP := 0;
   FEthernet := 0;
   FCan := 0;

   if FileExistsUTF8(FMPASMFilename) { *Converted from FileExists* } then
   begin
      FBitnames.Clear;
      RegStart := false;
      WaitingForBitnames := false;
      Lines := TStringList.Create;
      Lines.LoadFromFile(FMPASMFilename);
      for Index := 0 to Lines.Count - 1 do
      begin
         Line := Trim(Lines.Strings[Index]);
         if Line <> '' then
         begin
            if Pos('REGISTER FILES',Uppercase(Line)) > 0 then
               RegStart := true
            else if RegStart and (Pos(';',Line) = 1) and (Pos('RESERVED',Uppercase(Line)) > 0) then
            begin
            end   
            else if RegStart and (Pos('EQU',Uppercase(Line)) = 0) then
            begin
               WaitingForBitnames := true;
               RegStart := false;
            end
            else if RegStart then
            begin
               if Pos(';',Line) <> 1 then
               begin
                  Item := TSFR.Create(Line);
                  if IsPort(Item.Name) then
                     FPorts.Add(Item)
                  else
                  begin
                     if Uppercase(Item.Name) = 'DEBUG' then
                        Item.Free
                     // JM - added to remove PROD from the list...
                     // it'll be added as a word later w/other 16-bit regs
                     {$IFDEF PROD_AS_16BIT}
                     else if Uppercase(Item.Name) = 'PROD' then
                        Item.Free
                     {$ENDIF}
                     else
                     begin
                        FSFR.Add(Item);
                        UpdateCCP(Item.Name);
                        UpdateEthernet(Item.Name);
                        UpdateCAN(Item.Name);
                        MakeLH(Item);
                     end;
                  end;
               end;
            end;

            if WaitingForBitnames then
               if Pos('RAM DEFINITION',Uppercase(Line)) > 0 then
                  WaitingForBitnames := false
               else
               begin
                  Position := Pos(';-----',Line);
                  if Position > 0 then
                  begin
                     inc(Position,6);
                     Bitname := Trim(Copy(Line,Position,Length(LIne)));
                     Position := Pos(' ',Bitname);
                     if Position > 0 then
                        Bitname := Trim(Copy(Bitname,1,Position - 1));
                     FBitnames.Add('');
                     FBitnames.Add('; ' + Bitname);
                  end
                  else if Pos('EQU',Uppercase(Line)) > 0 then
                  begin
                     Bitname := GetEQUName(Line);
                     UpdateAnalog(Bitname);
                     if IsComp(Bitname) then
                        inc(FNumberOfComp)
                     else if IsPSP(Bitname) then
                        FPSP := 1;
                     BitnameValue := GetEQUAddress(Line);
                     FBitnames.Add(Bitname + ' = ' + IntToStr(BitnameValue));
                  end;
               end;
         end;
      end;
      Lines.Free;
   end;

end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TModelItem.LoadBadRAM;
var
   BadRam:TBadRam;
   Lines,Fields:TStringList;
   Line,NewLine:string;
   Index,Position:integer;
begin
   if FileExistsUTF8(FMPASMFilename) { *Converted from FileExists* } then
   begin
      Lines := TStringList.Create;
      Lines.LoadFromFile(FMPASMFilename);
      for Index := 0 to Lines.Count - 1 do
      begin
         Line := Trim(Lines.Strings[index]);

         //  __BADRAM H'07'-H'09', H'0D', H'13'-H'14', H'1B'-H'1E'
         Position := Pos('__BADRAM',Uppercase(Line));
         if Position > 0 then
         begin
            inc(Position,Length('__BADRAM'));
            Line := Trim(Copy(Line,Position,Length(Line)));
            NewLine := '';
            for Position := 1 to Length(Line) do
               if Line[Position] in ['0'..'9','A'..'F','a'..'f','-',','] then
                  NewLine := NewLine + Line[Position];
            Fields := TStringList.Create;
            Fields.CommaText := NewLine;
            for Position := 0 to Fields.Count - 1 do
            begin
               BadRam := TBadRam.Create(Fields.Strings[Position]);
               if BadRam.IsValid then
                  FBadRam.Add(BadRam)
               else
                  BadRam.Free;
            end;
            Fields.Free;
         end
         else if FMaxRam = 0 then
         begin
            Position := Pos('__MAXRAM',Uppercase(Line));
            if Position > 0 then
            begin
               inc(Position,Length('__MAXRAM'));
               Line := Trim(Copy(Line,Position,Length(Line)));
               NewLine := '';
               for Position := 1 to Length(Line) do
                  if Line[Position] in ['0'..'9','A'..'F','a'..'f'] then
                     NewLine := NewLine + Line[Position];

               try
                  FMaxRam := StrToInt('$' + NewLine);
               except
                  FMaxRam := 0;
               end;
            end;
         end;
      end;
      Lines.Free;
   end;

end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModelItem.GetMPASMID(pLine:string):string;
var
   Index:integer;
begin
   result := '';
   pLine := Uppercase(Trim(Copy(pLine,2,Length(pLine) - 1)));
   for index := 1 to Length(pLine) do
      if not (pLine[index] in ['A'..'Z','0'..'9','_']) then
         break
      else
         result := result + pLine[index];
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModelItem.GetMPASMValue(pLine:string):string;
var
   Position,Index:integer;
begin
   result := '';
   Position := Pos('=',pLine);
   if Position > 0 then
   begin
      pLine := Trim(Copy(pLine,Position + 1,Length(pLine) - Position));
      for index := 1 to Length(pLine) do
         if not (pLine[index] in ['A'..'Z','0'..'9','_']) then
            break
         else
            result := result + pLine[index];
   end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
// JM - change to use TStringList (since we already have it available)
// pValues[0] = config ID name
// pValues[1...n] = config settings
function TModelItem.ProcessValues(pValues:TStringList):string;
var
   Index:integer;
begin
   result := '';
   if (pValues.Count > 1) then
   begin
      result := 'public config ' + pValues[0] + '(' + pValues[0] + ') = {';    // fuse ID
      for index := 1 to pValues.Count-2  do                         // settings
         result := result + pValues[index] + ', ';
      result := result + pValues[pValues.Count-1] + '}';

      // patch in WDTEN alias
      if (pValues[0] = 'WDTEN') then
      begin
         result := result + #13#10 + 'public config WDT' + '(' + pValues[0] + ') = {';    // fuse ID
         for index := 1 to pValues.Count-2  do                         // settings
            result := result + pValues[index] + ', ';
         result := result + pValues[pValues.Count-1] + '}';
      end;
   end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModelItem.FindFuseValue(pValue:string;pValues:TStringList):boolean;
var
   Index:integer;
begin
   pValue := uppercase(pValue);
   result := false;
   Index := 0;
   while (Index < pValues.Count) and not result do
   begin
      Result := uppercase(pValues.Strings[Index]) = pValue;
      inc(Index);
   end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TModelItem.SetDefaultFuse(pID:string;pValues:TStringList);
begin
   pID := uppercase(pID);

   // OSC...
   if (pID = 'OSC') and FindFuseValue('HS',pValues) then
      FDefaultFuses.Add(pID + ' = HS')
   else if (pID = 'FOSC') and FindFuseValue('HS',pValues) then
      FDefaultFuses.Add(pID + ' = HS')

   // USB OSC
   else if (pID = 'CPUDIV') and FindFuseValue('OSC1_PLL2',pValues) then
      FDefaultFuses.Add(pID + ' = OSC1_PLL2')

   // OSC switch enable...
   else if (pID = 'OSCS') and FindFuseValue('OFF',pValues) then
      FDefaultFuses.Add(pID + ' = OFF')

   // Brown out reset...
   else if (pID = 'BOR') and FindFuseValue('ON',pValues) then
      FDefaultFuses.Add(pID + ' = ON')
   else if (pID = 'BOREN') and FindFuseValue('ON',pValues) then
      FDefaultFuses.Add(pID + ' = ON')
   else if (pID = 'BOREN') and FindFuseValue('BOACTIVE',pValues) then
      FDefaultFuses.Add(pID + ' = BOACTIVE')

   // brown out reset voltage...
   else if (pID = 'BORV') and FindFuseValue('20',pValues) then
      FDefaultFuses.Add(pID + ' = 20')
   else if (pID = 'BORV') and FindFuseValue('25',pValues) then
      FDefaultFuses.Add(pID + ' = 25')
   else if (pID = 'BORV') and FindFuseValue('27',pValues) then
      FDefaultFuses.Add(pID + ' = 27')

   // power on reset
   else if (pID = 'PWRT') and FindFuseValue('ON',pValues) then
      FDefaultFuses.Add(pID + ' = ON')

   // watch dog timer...
   else if (pID = 'WDT') and FindFuseValue('OFF',pValues) then
      FDefaultFuses.Add(pID + ' = OFF')
   else if (pID = 'WDTEN') and FindFuseValue('OFF',pValues) then
      FDefaultFuses.Add(pID + ' = OFF')

   // watch dog prescale...
   else if (pID = 'WDTPS') and FindFuseValue('128',pValues) then
      FDefaultFuses.Add(pID + ' = 128')

   // stack overflow reset...
   else if (pID = 'STVR') and FindFuseValue('ON',pValues) then
      FDefaultFuses.Add(pID + ' = ON')
   else if (pID = 'STVREN') and FindFuseValue('ON',pValues) then
      FDefaultFuses.Add(pID + ' = ON')

   // low voltage programming
   else if (pID = 'LVP') and FindFuseValue('OFF',pValues) then
      FDefaultFuses.Add(pID + ' = OFF')

   // Fail-Safe Clock Monitor disabled
   else if (pID = 'FCMEN') and FindFuseValue('OFF',pValues) then
      FDefaultFuses.Add(pID + ' = OFF')

   // Two-Speed Start-up disabled
   else if (pID = 'IESO') and FindFuseValue('OFF',pValues) then
      FDefaultFuses.Add(pID + ' = OFF')

   // INTRC enabled as system clock when OSCCON<1:0> = 00
   else if (pID = 'FOSC2') and FindFuseValue('ON',pValues) then
      FDefaultFuses.Add(pID + ' = ON')

   // portb as digital...
   else if (pID = 'PBADEN') and FindFuseValue('OFF',pValues) then
      FDefaultFuses.Add(pID + ' = OFF')

   // extended instruction set
   else if (pID = 'XINST') and FindFuseValue('OFF',pValues) then
      FDefaultFuses.Add(pID + ' = OFF')

   // dedicated debug/ICP programming port enable bit
   else if (pID = 'ICPRT') and FindFuseValue('OFF',pValues) then
      FDefaultFuses.Add(pID + ' = OFF')

   // debug
   else if (pID = 'DEBUG') and FindFuseValue('OFF',pValues) then
      FDefaultFuses.Add(pID + ' = OFF')
end;

{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
// JM - added to identify the watchdog config type
//  0   WDT(WDT) = [OFF, ON]
//  1   WDTEN(WDTEN) = [OFF, ON]
//  2   WDTEN(WDTEN) = [OFF, NOSLP, SWON, ON]
//  3   WDTEN(WDTEN) = [OFF, NOSLP, ON, SWDTDIS]
//
procedure TModelItem.SetWdtType(pID:string;pValues:TStringList);
begin
   pID := uppercase(pID);

   // watch dog timer...
   if (pID = 'WDT') then
      FWdtType := 0
   else if (pID = 'WDTEN') then
   begin
      FWdtType := 1;
      if FindFuseValue('SWON',pValues) then
         FWdtType := 2;
      if FindFuseValue('SWDTDIS',pValues) then
         FWdtType := 3;
   end;
end;

{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TModelItem.LoadFuses;
var
   ID, Line:string;
   Lines, Values, NewLines:TStringList;
   Index:integer;
   StartBlock:boolean;
begin
   FFuses.Clear;
   FDefaultFuses.Clear;

   Values := TStringList.Create;
   NewLines := TStringList.Create;
   Lines := TStringList.Create;

   // we should be sitting at PART_INFO_TYPE
   if (DeviceInfo.FindPartInfo(FDevice, Values)) then
   begin
      Values.Clear;
      if (DeviceInfo.NextLine()) then
      begin
         StartBlock := DeviceInfo.GetConfigList(Values);
         while (StartBlock = true) do begin
            ID := Values[0];
            SetDefaultFuse(ID,Values);
          {$IFDEF _WDT_TYPE}
            if (Pos('WDT', ID) > 0) then
               SetWdtType(ID,Values);
          {$ENDIF}
            Line := ProcessValues(Values);
            if Line <> '' then
               NewLines.Add(Line);
            Values.Clear;
            StartBlock := DeviceInfo.GetConfigList(Values);
         end;

         if NewLines.Count > 0 then
         begin
            NewLines.Insert(0,''' configuration fuses...');
            NewLines.Insert(0,'');
            FFuses.AddStrings(NewLines);
         end;
      end;
   end;

   NewLines.Free;
   Lines.Free;
   Values.Free;
end;

{
**********************************************************************
* Name    :                                                          *
* Purpose :                                                          *
**********************************************************************
}
procedure TModelItem.MakeHeader(pName:string;pLines:TStrings);
function Pad(pText:string;pCount:integer;pChar:string):string;
var
   index:integer;
begin
   result := pText;
   for index := 1 to pCount - Length(pText) do
      result := result + pChar;
end;
var
   DateStr,Author,Copyright,YearStr:string;
begin
   Author := 'David John Barker';
   Copyright := 'Mecanique';
   DateStr := FormatDateTime(ShortDateFormat,Date);
   YearStr := FormatDateTime('yyyy',Date);

//   pLines.Insert(0,'');
   pLines.Insert(0,'''****************************************************************');
   pLines.Insert(0,'''*  Info    : ' + Pad('resource file ' + DeviceInfo.ResFileVersion,50,' ') + '*');
   pLines.Insert(0,'''*  Date    : ' + Pad(DateStr,50,' ') + '*');
   pLines.Insert(0,'''*          : All Rights Reserved                               *');
   pLines.Insert(0,'''*  Notice  : ' + Pad('Copyright (c) ' + YearStr + ' ' + Copyright,50,' ') + '*');
   pLines.Insert(0,'''*  Author  : ' + Pad(Author,50,' ') + '*');
   pLines.Insert(0,'''*  Name    : ' + Pad(UpperCase(pName),50,' ') + '*');
   pLines.Insert(0,'''****************************************************************');
end;

{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModelItem.SaveToStrings(pLines:TStrings):boolean;
var
   Index:integer;
   SFR, SFR_EDATA:TSFR;
begin
   result := false;
   if IsValid then
   begin
      if (FNumberOfECCP = 0) and (FNumberOfECCPDel > 0) then
      begin
         dec(FNumberOfCCP,FNumberOfECCPDel);
         FNumberOfECCP := FNumberOfECCPDel;
      end;

      if FGenerateModel then
      with pLines do
      begin

         MakeHeader(FDevice,pLines);

         // name...
         Add('module PIC');
         Add('');

         // system header
         Add(''' system header...');
         Add(Pad('#const _core = &H0012',38) + ''' processor core');                                  // always $12
         Add(Pad('#const _ram_banks = &H' + IntToHex(FMaxRamBanksUsed, 2),38) + ''' ' + IntToStr(FMaxRamBanksUsed) + ' RAM bank(s) used'); // OK
         Add(Pad('#variable _maxaccess = &H' + IntToHex(FMaxRamAccess,2),38) + ''' access ram is ' + IntToStr(FMaxRamAccess) + ' bytes');     // OK
         Add(Pad('#variable _maxram = &H' + IntToHex(FMaxRAMUsed,4),38) + ''' ' + IntToStr(FMaxRAMUsed) + ' bytes of user RAM');          // OK
         if FMaxRamUsed <> FMaxRAMUsedContig then
            Add(Pad('#variable _maxram_contig = &H' + IntToHex(FMaxRAMUsedContig,4),38) + ''' ' + IntToStr(FMaxRamUsedContig) + ' bytes of contiguous RAM');  // OK
         Add(Pad('#variable _maxrom = &H' + IntToHex(FMaxRom,6),38) + ''' ' + IntToStr(FMaxRom div 1024) + ' KB of program ROM');              // OK
         Add(Pad('#const _eeprom = &H' + IntToHex(FEEPROM,4),38) + ''' ' + IntToStr(FEEPROM) + ' bytes of EEPROM');         // OK
         Add(Pad('#const _eeprom_start = &H' + IntToHex(FEEPROMStart,6),38) + ''' EEPROM start address');    // always $F00000
         Add(Pad('#const _ports = &H' + IntToHex(NumberOfPorts,2),38) + ''' ' + IntToStr(NumberOfPorts) + ' available ports');           // always OK

         // JM - removed this code... it causes issues with non-contiguous PORT addr ie PORTK/PORTL
         {
         // missing ports
         if HasMissingPorts then
         begin
            MissingPorts := TStringList.Create;
            GetMissingPorts(MissingPorts);
            for Index := 0 to MissingPorts.Count - 1 do
               Add(Pad('#const _no_' + lowercase(MissingPorts.Strings[index]) + ' = &H01',38) + ''' no ' + MissingPorts.Strings[index]);
            MissingPorts.Free;
         end;
         }
         // JM - added instead of above. No PIC18 device has a PORTI... it's always skipped
         if (NumberOfPorts > 8) then
         begin
            Add(Pad('#const _no_porti = &H01',38) + ''' no PORTI');
         end;

         if FNumberOfCCP = 0 then
            Add(Pad('#const _ccp = &H' + IntToHex(FNumberOfCCP,2),38) + ''' CCP module NOT supported')
         else
            Add(Pad('#const _ccp = &H' + IntToHex(FNumberOfCCP,2),38) + ''' ' + IntToStr(FNumberOfCCP) + ' CCP module(s) available');            // OK

         if FNumberOfECCP = 0 then
            Add(Pad('#const _eccp = &H' + IntToHex(FNumberOfECCP,2),38) + ''' ECCP module NOT supported')
         else
            Add(Pad('#const _eccp = &H' + IntToHex(FNumberOfECCP,2),38) + ''' ' + IntToStr(FNumberOfECCP) + ' ECCP module(s) available');          // OK

         if NumberOfMSSP = 0 then
            Add(Pad('#const _mssp = &H' + IntToHex(NumberOfMSSP, 2),38) + ''' MSSP module NOT supported')
         else
            Add(Pad('#const _mssp = &H' + IntToHex(NumberOfMSSP, 2),38) + ''' ' + IntToStr(NumberOfMSSP) + ' MSSP module(s) available');          // OK

         if NumberOfUSART = 0 then
            Add(Pad('#const _usart = &H' + IntToHex(NumberOfUSART, 2),38) + ''' USART module NOT supported')
         else
            Add(Pad('#const _usart = &H' + IntToHex(NumberOfUSART, 2),38) + ''' ' + IntToStr(NumberOfUSART) + ' USART(s) available');

         Add(Pad('#const _adc = &H' + IntToHex(FNumberOfADC,2),38) + ''' ' + IntToStr(FNumberOfADC) + ' ADC channels available');             // OK

         if FNumberOfComp = 0 then
            Add(Pad('#const _comparator = &H' + IntToHex(FNumberOfComp,2),38) + ''' comparator module NOT supported')
         else
            Add(Pad('#const _comparator = &H' + IntToHex(FNumberOfComp,2),38) + ''' ' + IntToStr(FNumberOfComp) + ' comparator(s) available');     // OK

         if FPSP > 0 then
            Add(Pad('#const _psp = &H' + IntToHex(FPSP,2),38) + ''' onboard Parallel Slave Port (PSP) available')
         else
            Add(Pad('#const _psp = &H' + IntToHex(FPSP,2),38) + ''' Parallel Slave Port (PSP) is NOT supported');

         if FCan > 0 then
            Add(Pad('#const _can = &H' + IntToHex(FCan,2),38) + ''' onboard CAN available')
         else
            Add(Pad('#const _can = &H' + IntToHex(FCan,2),38) + ''' onboard CAN is NOT supported');

         if HasUSB > 0 then
            Add(Pad('#const _usb = &H' + IntToHex(HasUSB,2),38) + ''' onboard USB available')
         else
            Add(Pad('#const _usb = &H' + IntToHex(HasUSB,2),38) + ''' USB is NOT supported');

         if FEthernet > 0 then
            Add(Pad('#const _ethernet = &H' + IntToHex(FEthernet,2),38) + ''' onboard Ethernet available')
         else
            Add(Pad('#const _ethernet = &H' + IntToHex(FEthernet,2),38) + ''' onboard Ethernet is NOT supported');

         if FFlashWrite > 0 then
            Add(Pad('#const _flash_write = &H' + IntToHex(FFLASHWrite,2),38) + ''' FLASH has write capability')
         else
            Add(Pad('#const _flash_write = &H' + IntToHex(FFLASHWrite,2),38) + ''' FLASH does NOT have write capability');

         // JM - added
         {$IFDEF _WDT_TYPE}
         if FWdtType = 0 then
            Add(Pad('#const _wdt_type = &H' + IntToHex(FWdtType,2),38) + ''' WDT watchdog')
         else if FWdtType = 1 then
            Add(Pad('#const _wdt_type = &H' + IntToHex(FWdtType,2),38) + ''' WDTEN watchdog')
         else if FWdtType = 2 then
            Add(Pad('#const _wdt_type = &H' + IntToHex(FWdtType,2),38) + ''' WDTEN watchdog (w/SWON)')
         else if FWdtType = 3 then
            Add(Pad('#const _wdt_type = &H' + IntToHex(FWdtType,2),38) + ''' WDTEN watchdog (w/SWDTDIS)');
         {$ENDIF}

         // special function registers
         SFR_EDATA := nil;
         if FSFR.Count > 0 then
         begin
            Add('');
            Add(''' special function registers...');
            for Index := 0 to FSFR.Count - 1 do
            begin
               SFR := TSFR(FSFR.Items[Index]);

               // proton EDATA is reserved word!!!
               if uppercase(SFR.Name) = 'EDATA' then
               begin
                  pLines.Add('''' + SFR.Name + ' as byte absolute $' + IntToHex(SFR.Address,4) + ',');
                  SFR_EDATA := SFR;
               end

               else if not SFR.IsLowHigh then
                  pLines.Add('public system ' + SFR.Name + ' as byte absolute &H' + IntToHex(SFR.Address,4));
            end;
         end;

         // system ports...
         if FPorts.Count > 0 then
         begin
            Add('');
            Add(''' system ports...');
            for Index := 0 to FPorts.Count - 1 do
            begin
               SFR := TSFR(FPorts.Items[Index]);
               pLines.Add('public system port ' + SFR.Name + ' as byte absolute &H' + IntToHex(SFR.Address,4));
            end;
         end;

         // aliases...
         pLines.Add('');
         pLines.Add(''' alias...');

         // JM - correct address (was SFR.Address)
         if Assigned(SFR_EDATA) and Assigned(SFR) then
            pLines.Add('public dim ' + SFR_EDATA.Name + ' as byte absolute &H' + IntToHex(SFR_EDATA.Address,4) + ',');

         // JM - added PROD as 16-bit reg
         {$IFDEF PROD_AS_16BIT}
         pLines.Add('public dim PROD as PRODL.AsUShort');
         {$ENDIF}
         pLines.Add('public dim FSR0 as FSR0L.AsUShort');
         pLines.Add('public dim FSR1 as FSR1L.AsUShort');
         pLines.Add('public dim FSR2 as FSR2L.AsUShort');
         pLines.Add('public dim TABLEPTR as TBLPTRL.AsUShort');

         // fuses
         pLines.AddStrings(FFuses);

         // default fuses..
         if FDefaultFuses.Count > 0 then
         begin
            pLines.Add('');
            pLines.Add(''' default fuses...');
            for Index := 0 to FDefaultFuses.Count - 1 do
               pLines.Add('config ' + FDefaultFuses.Strings[index]);
         end;

         pLines.Add('');
         pLines.Add(''' entry point with startup event handler...');
         pLines.Add('Public Event OnStartup()');
         pLines.Add('Inline Sub Main()');
         pLines.Add('   RaiseEvent OnStartup()');
         pLines.Add('End Sub');
         pLines.Add('');
         pLines.Add('end module');
         result := true;
      end;
   end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModelItem.Pad(pLine:string;pAmount:integer):string;
var
   Index:integer;
begin
   result := pLine;
   for Index := Length(pLine) to pAmount do
      Result := Result + ' ';
end;

end.
