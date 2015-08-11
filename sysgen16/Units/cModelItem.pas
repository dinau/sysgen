unit cModelItem;

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
  Forms, FileUtil, IniFiles, Classes, SysUtils,
   cSFR, cUtils;

type
   TModelItem = class(TObject)
   private
      FWriteDefaultINI:boolean;
      FIncFilename:string;
      FGLDFilename:string;
      FDevice:string;
      FMaxROM:integer;
      FIvtBase:integer;
      FIvtLength:integer;
      FAIvtBase:integer;
      FAIvtLength:integer;
      FCodeBase:integer;
      FCodeLength:integer;
      FAuxFlashBase:integer;
      FAuxFlashLength:integer;
      FMaxAuxFlash:integer;
      FMaxRAM:integer;
      FXRAMStart:integer;
      FXRAM:integer;
      FYRAMStart:integer;
      FYRAM:integer;
      FDMARAMStart:integer;
      FDMARAM:integer;
      FGenerateModel:boolean;

      FGLDVersion:string;     // added v1.2
      FSFR:TList;
      FPorts:TList;
      FFuses:TStringList;
      FDefaultFuses:TStringList;

      procedure GetCandidateFuse(pLines:TStrings);
      procedure GetFuseOptionsAndComments(pFuse:string; var pOptions:string; var pComments:string);
      procedure GenerateAllFuse(pLines:TStrings);

      function IsPort(pName:string):boolean;
      function NumberOfPorts:integer;
      function NumberOfUSART:integer;
      function NumberOfSPI:integer;
      function NumberOfI2C:integer;
      function NumberOfPWM:integer;

      function HasSFR(pName:string):boolean;
      function HasUSB:integer;
      function HasRTC:integer;
      function HasPMP:integer;
      function NumberOfDMA:integer;
      function NumberOfECAN:integer;

      function GetHexValue(pIndex:integer; pLine:string):integer;
      procedure LoadSFR;
      procedure LoadROM;
      procedure LoadRAM;
      procedure LoadFuses;
      procedure Clear;
      function GetMPASMID(pLine:string):string;
      function GetMPASMValue(pLine:string):string;
      function ProcessValues(pID:string;pValues:TStrings):string;
      function FindFuseValue(pValue:string;pValues:TStringList):boolean;
      procedure SetDefaultFuse(pID:string;pValues:TStringList);
      procedure MakeHeader(pName:string;pLines:TStrings);
      function Pack(pName:string;pAmount:integer):string;
      function Pad(pLine:string;pAmount:integer):string;
      procedure AddInterrupts(pLines:TStrings);
      procedure GetGLDVersion();       // added v1.2
public
      constructor Create(pIncAndGLDPath, pDevice:string);
      destructor Destroy;override;
      function IsValid:boolean;
      function SaveToStrings_BASIC(pLines:TStrings):boolean;
      procedure SaveToStrings_INCLUDE(pLines:TStrings);
      property IncFilename:string read FIncFilename;
      property GLDFilename:string read FGLDFilename;
      property Device:string read FDevice;
      property WriteDefaultINI:boolean read FWriteDefaultINI write FWriteDefaultINI;
   end;

implementation

{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
constructor TModelItem.Create(pIncAndGLDPath, pDevice:string);
begin
   inherited Create;
   FGenerateModel := true;
   FWriteDefaultINI := true;
   FMaxRam := 0;
   FMaxROM := 0;
   FSFR := TList.Create;
   FPorts := TList.Create;
   FDevice := pDevice;
   FGLDFilename := pIncAndGLDPath + '\gld\P' + FDevice + '.gld';
   FIncFilename := pIncAndGLDPath + '\inc\P' + FDevice + '.inc';

   FGldVersion := '';

   GetGLDVersion;
   FFuses := TStringList.Create;
   FDefaultFuses := TStringList.Create;
   LoadSFR;
   LoadROM;
   LoadRAM;
   LoadFuses;
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
   FFuses.Free;
   FDefaultFuses.Free;
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
   FSFR.Clear;
   FPorts.Clear;
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
procedure TModelItem.GetGLDVersion();
var
   Lines:TStringList;
   index:integer;
   Line:string;
   Position:integer;
   Found:boolean;
begin
   if FileExistsUTF8(FGLDFilename) { *Converted from FileExists* } then
   begin
      FGLDVersion := '';
      Found := false;
      Lines := TStringList.Create;
      Lines.LoadFromFile(FGLDFilename);
      Index := 0;
      while (Index < Lines.Count) and not Found do
      begin
         Line := Lines.Strings[Index];
         Position := Pos('part support version',lowercase(Line));
         if (Position <> 0) then
         begin
            FGLDVersion := Copy(Line, Position, MaxInt);
            Found := true;
         end;
         inc(index);
      end;
      if (Found = false) then
         FGLDVersion := 'part support version not found';
      Lines.free;
   end;
end;

{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
(*
MEMORY
{
  data  (a!xr)   : ORIGIN = 0x800,         LENGTH = 0x2000
  reset          : ORIGIN = 0x0,           LENGTH = 0x4
  ivt            : ORIGIN = 0x4,           LENGTH = 0xFC
  _reserved      : ORIGIN = 0x100,         LENGTH = 0x4
  aivt           : ORIGIN = 0x104,         LENGTH = 0xFC
  program (xr)   : ORIGIN = 0x200,         LENGTH = 0x155FA
  CONFIG2        : ORIGIN = 0x157FC,       LENGTH = 0x2
  CONFIG1        : ORIGIN = 0x157FE,       LENGTH = 0x2
}
*)
procedure TModelItem.GetCandidateFuse(pLines:TStrings);
var
   Lines:TStringList;
   index, Position:integer;
   Line:string;
   BlockStart, CandidateStart, Finished:boolean;
begin
   if FileExistsUTF8(FGLDFilename) { *Converted from FileExists* } then
   begin
      Finished := false;
      CandidateStart := false;
      BlockStart := false;
      Lines := TStringList.Create;
      Lines.LoadFromFile(FGLDFilename);
      Index := 0;
      while (Index < Lines.Count) and not Finished do
      begin
         Line := Trim(Lines.Strings[Index]);
         if Pos('memory',lowercase(Line)) = 1 then
            BlockStart := true
         else if BlockStart and (Pos('program', lowercase(Line)) = 1) then
            CandidateStart := true
         else if BlockStart and (Pos('FBOOT', Line) = 1) then     // added for dual-panel devices ie 24FJ128GA406
         begin
            Position := Pos(':', Line);
            if Position > 0 then
            begin
               Line := Trim(Copy(Line, 1, Position - 1));
               pLines.Add(Line);
            end;
         end
         else if (CandidateStart and ( (Pos('}', Line) > 0) or (Pos('#ifdef __DUAL_PARTITION', Line) > 0) )) then
            Finished := true
         else if CandidateStart and (Pos('eedata', lowercase(Line)) <> 1) then
         begin
            Position := Pos(':', Line);
            if Position > 0 then
            begin
               Line := Trim(Copy(Line, 1, Position - 1));
               pLines.Add(Line);
            end;
         end;
         inc(index);
      end;
      Lines.free;
   end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
(*
        .equiv WDTPS_PS1,       0x7FF0 ; 1:1
        .equiv WDTPS_PS2,       0x7FF1 ; 1:2
*)
procedure TModelItem.GetFuseOptionsAndComments(pFuse:string; var pOptions:string; var pComments:string);
var
   Lines:TStringList;
   index, Position:integer;
   Line:string;
   BlockStart, Finished:boolean;
   Options:TStringList;
begin
   pOptions := '';
   pComments := '';
   if FileExistsUTF8(FIncFilename) { *Converted from FileExists* } then
   begin
      Options := TStringList.Create;
      Finished := false;
      BlockStart := false;
      Lines := TStringList.Create;
      Lines.LoadFromFile(FIncFilename);
      Index := 0;
      while (Index < Lines.Count) and not Finished do
      begin
         Line := Trim(Lines.Strings[Index]);
         if Pos(lowercase(';----- ' + pFuse + ' '), lowercase(Line + ' ')) = 1 then
            BlockStart := true
         else if BlockStart and (Pos(';-----', Line) > 0) then
            Finished := true
         else if BlockStart and (Pos(';', Line) = 1) then
         begin
            Line := TrimRight(Copy(Line, 2, Length(Line)));
            if Line <> '' then pComments := pComments + '''' + Line + #13#10;
         end
         else if BlockStart then
         begin
            Position := Pos('.equiv', lowercase(Line));
            if Position > 0 then
            begin
               Line := Trim(Copy(Line, Position + length('.equiv'), Length(Line)));
               Position := Pos(',', Line);
               if Position > 0 then
               begin
                  Line := Trim(Copy(Line,1,Position - 1));
                  Options.Add(Line);
               end;
            end;
         end;
         inc(index);
      end;

      if Options.Count > 0 then
      begin
         pOptions := '   ';
         for Index := 0 to Options.Count - 2 do
            if (Index <> 0) and (Index mod 8 = 0) then
               pOptions := pOptions + Options.Strings[index] + ',_' + #13#10 + '   '
            else
               pOptions := pOptions + Options.Strings[index] + ', ';
         pOptions := pOptions + Options.Strings[Options.Count - 1];
      end;
      Options.Free;
      Lines.Free;
   end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
(*
' CONFIG1
public config config1(Config1) = {_
   JTAGEN_OFF, JTAGEN_ON, GCP_ON, GCP_OFF, GWRP_ON, GWRP_OFF, BKBUG_ON, BKBUG_OFF,_
   COE_ON, COE_OFF, ICS_PGx1, ICS_PGx2, FWDTEN_OFF, FWDTEN_ON, WINDIS_ON, WINDIS_OFF,_
   FWPSA_PR32, FWPSA_PR128, WDTPS_PS1, WDTPS_PS2, WDTPS_PS4, WDTPS_PS8, WDTPS_PS16, WDTPS_PS32,_
   WDTPS_PS64, WDTPS_PS128, WDTPS_PS256, WDTPS_PS512, WDTPS_PS1024, WDTPS_PS2048, WDTPS_PS4096, WDTPS_PS8192,_
   WDTPS_PS16384, WDTPS_PS32768}
*)
procedure TModelItem.GenerateAllFuse(pLines:TStrings);
var
   Fuses:TStringList;
   index:integer;
   Fuse, Options, Comments:string;
begin
   Fuses := TStringList.Create;
   GetCandidateFuse(Fuses);
   for Index := 0 to Fuses.Count - 1 do
   begin
      Fuse := Fuses.Strings[index];
      GetFuseOptionsAndComments(Fuse, Options, Comments);
      if Trim(Options) <> '' then
      begin
         pLines.Add('');
         pLines.Add(Comments);
         pLines.Add(''' ' + Fuse);
         pLines.Add('public config ' + Fuse + '(' + Fuse + ') = {_');
         pLines.Add(Options + '}');
      end;
   end;
   Fuses.Free;
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
   SFRName:string;
begin
   result := 0;
   for Index := 0 to FSFR.Count - 1 do
   begin
      SFR := TSFR(FSFR.Items[index]);
      SFRName := uppercase(SFR.Name);
      if (Pos('MODE', SFRName) > 0) then
      begin
         if (SFRName = 'UMODE') and (result < 1) then result := 1;
         if (SFRName = 'U1MODE') and (result < 1) then result := 1;
         if (SFRName = 'U2MODE') and (result < 2) then result := 2;
         if (SFRName = 'U3MODE') and (result < 3) then result := 3;
         if (SFRName = 'U4MODE') and (result < 4) then result := 4;
         if (SFRName = 'U5MODE') and (result < 5) then result := 5;
         if (SFRName = 'U6MODE') and (result < 6) then result := 6;
      end;
  end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModelItem.NumberOfSPI:integer;
var
   Index:integer;
   SFR:TSFR;
   SFRName:string;
begin
   result := 0;
   for Index := 0 to FSFR.Count - 1 do
   begin
      SFR := TSFR(FSFR.Items[index]);
      SFRName := uppercase(SFR.Name);
      if (Pos('SPI', SFRName) > 0) then
      begin
         if ((SFRName = 'SPISTAT') or (SFRName = 'SPISTATL')) and (result < 1) then result := 1;
         if ((SFRName = 'SPI1STAT') or (SFRName = 'SPI1STATL') or (SFRName = 'SPI1BUF')) and (result < 1) then result := 1;
         if ((SFRName = 'SPI2STAT') or (SFRName = 'SPI2STATL') or (SFRName = 'SPI2BUF')) and (result < 2) then result := 2;
         if ((SFRName = 'SPI3STAT') or (SFRName = 'SPI3STATL') or (SFRName = 'SPI3BUF')) and (result < 3) then result := 3;
         if ((SFRName = 'SPI4STAT') or (SFRName = 'SPI3STATL') or (SFRName = 'SPI4BUF')) and (result < 4) then result := 4;
      end;
  end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModelItem.NumberOfI2C:integer;
var
   Index:integer;
   SFR:TSFR;
   SFRName:string;
begin
   result := 0;
   for Index := 0 to FSFR.Count - 1 do
   begin
      SFR := TSFR(FSFR.Items[index]);
      SFRName := uppercase(SFR.Name);
      if (Pos('I2C', SFRName) > 0) then
      begin
         if ((SFRName = 'I2CCON') or (SFRName = 'I2CCONL')) and (result < 1) then result := 1;
         if ((SFRName = 'I2C1CON') or (SFRName = 'I2C1CONL') or (SFRName = 'I2C1ADD')) and (result < 1) then result := 1;
         if ((SFRName = 'I2C2CON') or (SFRName = 'I2C2CONL') or (SFRName = 'I2C2ADD')) and (result < 2) then result := 2;
         if ((SFRName = 'I2C3CON') or (SFRName = 'I2C3CONL') or (SFRName = 'I2C3ADD')) and (result < 3) then result := 3;
         if ((SFRName = 'I2C4CON') or (SFRName = 'I2C4CONL') or (SFRName = 'I2C4ADD')) and (result < 4) then result := 4;
      end;
  end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModelItem.NumberOfPWM:integer;
var
   Index:integer;
   SFR:TSFR;
   SFRName:string;
begin
   result := 0;
   for Index := 0 to FSFR.Count - 1 do
   begin
      SFR := TSFR(FSFR.Items[index]);
      SFRName := uppercase(SFR.Name);
      if (Pos('OC', SFRName) > 0) then
      begin
         if (SFRName = 'OCCON') and (result < 1) then result := 1;
         if ((SFRName = 'OC1CON') or (SFRName = 'OC1CON1')) and (result < 1) then result := 1;
         if ((SFRName = 'OC2CON') or (SFRName = 'OC2CON1')) and (result < 2) then result := 2;
         if ((SFRName = 'OC3CON') or (SFRName = 'OC3CON1')) and (result < 3) then result := 3;
         if ((SFRName = 'OC4CON') or (SFRName = 'OC4CON1')) and (result < 4) then result := 4;
         if ((SFRName = 'OC5CON') or (SFRName = 'OC5CON1')) and (result < 5) then result := 5;
         if ((SFRName = 'OC6CON') or (SFRName = 'OC6CON1')) and (result < 6) then result := 6;
         if ((SFRName = 'OC7CON') or (SFRName = 'OC7CON1')) and (result < 7) then result := 7;
         if ((SFRName = 'OC8CON') or (SFRName = 'OC8CON1')) and (result < 8) then result := 8;
         if ((SFRName = 'OC9CON')  or (SFRName = 'OC9CON1')) and (result < 9) then result := 9;
         if ((SFRName = 'OC10CON') or (SFRName = 'OC10CON1')) and (result < 10) then result := 10;
      end;
      if (Pos('PWM', SFRName) > 0) then
      begin
         if ((SFRName = 'PWMCON1') or (SFRName = 'PWM1CON1')) and (result < 1) then result := 1;
         if ((SFRName = 'PWMCON2') or (SFRName = 'PWM2CON1')) and (result < 2) then result := 2;
         if ((SFRName = 'PWMCON3') or (SFRName = 'PWM3CON1')) and (result < 3) then result := 3;
         if ((SFRName = 'PWMCON4') or (SFRName = 'PWM4CON1')) and (result < 4) then result := 4;
         if ((SFRName = 'PWMCON5') or (SFRName = 'PWM5CON1')) and (result < 5) then result := 5;
         if ((SFRName = 'PWMCON6') or (SFRName = 'PWM6CON1')) and (result < 6) then result := 6;
         if ((SFRName = 'PWMCON7') or (SFRName = 'PWM7CON1')) and (result < 7) then result := 7;
         if ((SFRName = 'PWMCON8') or (SFRName = 'PWM8CON1')) and (result < 8) then result := 8;
      end;
      if (Pos('CCP', SFRName) > 0) then
      begin
         if ((SFRName = 'CCP1CON') or (SFRName = 'CCP1STAT')) and (result < 1) then result := 1;
         if ((SFRName = 'CCP2CON') or (SFRName = 'CCP2STAT')) and (result < 2) then result := 2;
         if ((SFRName = 'CCP3CON') or (SFRName = 'CCP3STAT')) and (result < 3) then result := 3;
         if ((SFRName = 'CCP4CON') or (SFRName = 'CCP4STAT')) and (result < 4) then result := 4;
         if ((SFRName = 'CCP5CON') or (SFRName = 'CCP5STAT')) and (result < 5) then result := 5;
         if ((SFRName = 'CCP6CON') or (SFRName = 'CCP6STAT')) and (result < 6) then result := 6;
         if ((SFRName = 'CCP7CON') or (SFRName = 'CCP7STAT')) and (result < 7) then result := 7;
         if ((SFRName = 'CCP8CON') or (SFRName = 'CCP8STAT')) and (result < 8) then result := 8;
      end;
   end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModelItem.HasSFR(pName:string):boolean;
var
   Index:integer;
   SFR:TSFR;
begin
   result := false;
   for Index := 0 to FSFR.Count - 1 do
   begin
      SFR := TSFR(FSFR.Items[index]);
      if (uppercase(SFR.Name) = uppercase(pName)) then
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
function TModelItem.HasUSB:integer;
var
   Index:integer;
   SFR:TSFR;
   SFRName: string;
begin
   result := 0;
   for Index := 0 to FSFR.Count - 1 do
   begin
      SFR := TSFR(FSFR.Items[index]);
      SFRName := uppercase(SFR.Name);
      if (Pos('OTG', SFRName) > 0) then
      begin
         if (SFRName = 'UOTGCON') and (result < 1) then result := 1;
         if (SFRName = 'U1OTGCON') and (result < 1) then result := 1;
         if (SFRName = 'U2OTGCON') and (result < 2) then result := 2;
      end;         
  end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModelItem.HasRTC:integer;
var
   Index:integer;
   SFR:TSFR;
   SFRName: string;
begin
   result := 0;
   for Index := 0 to FSFR.Count - 1 do
   begin
      SFR := TSFR(FSFR.Items[index]);
      SFRName := uppercase(SFR.Name);
      if (SFRName = 'RCFGCAL') then
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
function TModelItem.HasPMP:integer;
var
   Index:integer;
   SFR:TSFR;
   SFRName: string;
begin
   result := 0;
   for Index := 0 to FSFR.Count - 1 do
   begin
      SFR := TSFR(FSFR.Items[index]);
      SFRName := uppercase(SFR.Name);
      if (SFRName = 'PMCON') or (SFRName = 'PMCON1') then
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
function TModelItem.NumberOfDMA:integer;
var
   Index:integer;
   SFR:TSFR;
   SFRName: string;
begin
   result := 0;
   for Index := 0 to FSFR.Count - 1 do
   begin
      SFR := TSFR(FSFR.Items[index]);
      SFRName := uppercase(SFR.Name);
      if (Pos('DMA', SFRName) > 0) then
      begin
         if (SFRName = 'DMACON') and (result < 1) then result := 1;
         if ((SFRName = 'DMA0CON') or (SFRName = 'DMACH0')) and (result < 1) then result := 1;
         if ((SFRName = 'DMA1CON') or (SFRName = 'DMACH1')) and (result < 2) then result := 2;
         if ((SFRName = 'DMA2CON') or (SFRName = 'DMACH2')) and (result < 3) then result := 3;
         if ((SFRName = 'DMA3CON') or (SFRName = 'DMACH3')) and (result < 4) then result := 4;
         if ((SFRName = 'DMA4CON') or (SFRName = 'DMACH4')) and (result < 5) then result := 5;
         if ((SFRName = 'DMA5CON') or (SFRName = 'DMACH5')) and (result < 6) then result := 6;
         if ((SFRName = 'DMA6CON') or (SFRName = 'DMACH6')) and (result < 7) then result := 7;
         if ((SFRName = 'DMA7CON') or (SFRName = 'DMACH7')) and (result < 8) then result := 8;
         if ((SFRName = 'DMA8CON') or (SFRName = 'DMACH8')) and (result < 9) then result := 9;
         if ((SFRName = 'DMA9CON') or (SFRName = 'DMACH9')) and (result < 10) then result := 10;
         if ((SFRName = 'DMA10CON') or (SFRName = 'DMACH10')) and (result < 11) then result := 11;
         if ((SFRName = 'DMA11CON') or (SFRName = 'DMACH11')) and (result < 12) then result := 12;
         if ((SFRName = 'DMA12CON') or (SFRName = 'DMACH12')) and (result < 13) then result := 13;
         if ((SFRName = 'DMA13CON') or (SFRName = 'DMACH13')) and (result < 14) then result := 14;
         if ((SFRName = 'DMA14CON') or (SFRName = 'DMACH14')) and (result < 15) then result := 15;
         if ((SFRName = 'DMA15CON') or (SFRName = 'DMACH15')) and (result < 16) then result := 16;
      end;
  end;
end;

{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TModelItem.NumberOfECAN:integer;
var
   Index:integer;
   SFR:TSFR;
   SFRName:string;
begin
   result := 0;
   for Index := 0 to FSFR.Count - 1 do
   begin
      SFR := TSFR(FSFR.Items[index]);
      SFRName := uppercase(SFR.Name);
      if (Pos('FIFO', SFRName) > 0) then
      begin
         if (SFRName = 'CFIFO') and (result < 1) then result := 1;
         if (SFRName = 'C1FIFO') and (result < 1) then result := 1;
         if (SFRName = 'C2FIFO') and (result < 2) then result := 2;
         if (SFRName = 'C3FIFO') and (result < 3) then result := 3;
         if (SFRName = 'C4FIFO') and (result < 4) then result := 4;
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
   Index:integer;
   Line:string;
   RegStart:boolean;
begin
   if FileExistsUTF8(FGLDFilename) { *Converted from FileExists* } then
   begin
      RegStart := false;
      Lines := TStringList.Create;
      Lines.LoadFromFile(FGLDFilename);
      for Index := 0 to Lines.Count - 1 do
      begin
         Line := Trim(Lines.Strings[Index]);
         if Line <> '' then
         begin
            if Pos('EQUATES FOR SFR ADDRESSES',Uppercase(Line)) > 0 then
               RegStart := true
            else if RegStart and (Pos('BASE ADDRESSES FOR VARIOUS PERIPHERALS',Uppercase(Line)) > 0) then
            begin
               RegStart := false;
            end

            (*
            TRISC        = 0x2D0;
            _TRISC        = 0x2D0;
            _TRISCbits    = 0x2D0;
            PORTC        = 0x2D2;
            _PORTC        = 0x2D2;
            *)
            else if RegStart and (Pos('_', Line) <> 1) and (Pos('=', Line) > 0) then
            begin
               Item := TSFR.Create(Line);
               if IsPort(Item.Name) then
                  FPorts.Add(Item)
               else
               begin
                  FSFR.Add(Item);
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
// xymem (region=0x800-0x27ff ymem=0x0-0x0)
function TModelItem.GetHexValue(pIndex:integer;pLine:string):integer;
var
   Position, Index, Len : integer;
   StrVal:string;
begin
   result := 0;
   dec(pIndex);
   pLine := lowercase(pLine);
   Position := Pos('0x', pLine);
   while (Position > 0) and (pIndex > 0) do
   begin
      pLine := Copy(pLine, Position + 2, Length(pLine));
      Position := Pos('0x', pLine);
      dec(pIndex);
   end;
   if Position > 0 then
   begin
      Len := Length(pLine);
      StrVal := '0x0';
      Index := 1;
      pLine := Copy(pLine, Position + 2, Length(pLine));
      while (pLine[index] in ['0'..'9','a'..'f']) and (Index <= Len) do
      begin
         StrVal := StrVal + pLine[index];
         inc(index);
      end;
      try
         result := StrToInt(StrVal);
      except
      end;
   end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TModelItem.LoadROM;
var
   Lines:TStringList;
   Line:string;
   Index:integer;
   Found:boolean;
begin
   FMaxROM := 0;
   FCodeBase := 0;
   FCodeLength := 0;
   FAuxFlashBase := 0;
   FAuxFlashLength := 0;
   FMaxAuxFlash := 0;
   FIvtBase := 0;
   FIvtLength := 0;
   FAIvtBase := 0;
   FAIvtLength := 0;
   if FileExistsUTF8(FGLDFilename) { *Converted from FileExists* } then
   begin
      Found := false;
      Lines := TStringList.Create;
      Lines.LoadFromFile(FGLDFilename);
      Index := 0;
      while (Index < Lines.Count) and not Found do
      begin
         Line := Trim(Lines.Strings[Index]);
         // program (xr)   : ORIGIN = 0x200,         LENGTH = 0x2AA00
         // auxflash (xr)  : ORIGIN = 0x7FC000,      LENGTH = 0x3FFA
         // ivt            : ORIGIN = 0x4,           LENGTH = 0x1FC
         // aivt           : ORIGIN = 0x104,           LENGTH = 0x1FC
         if Pos('program (xr)', Line) > 0 then
         begin
            FCodeBase := GetHexValue(1,Line);
            FCodeLength := GetHexValue(2,Line);
            FMaxROM := FCodeBase + FCodeLength;
         // assuming the rom value is $157FC, then each word value has two bytes
         // so $157FC * 2 = $2AFF8. However, only three quarters are usable, because
         // an instruction is 24 bits (3 bytes) so $2AFF8 * 0.75 = $203FA = 132,090 bytes
         // pgmmem (region=0x0-0x157fb)
            FMaxROM := FMaxROM * 2 div 4 * 3;
         end;
         if Pos('auxflash (xr)', Line) > 0 then
         begin
            FAuxFlashBase := GetHexValue(1,Line);
            FAuxFlashLength := GetHexValue(2,Line);
            FMaxAuxFlash := FAuxFlashBase + FAuxFlashLength;
            FMaxAuxFlash := FMaxAuxFlash * 2 div 4 * 3;
         end;
         if Pos('aivt', Line) > 0 then
         begin
            FAIvtBase := GetHexValue(1,Line);
            FAIvtLength := GetHexValue(2,Line);
         end
         else if Pos('ivt', Line) > 0 then
         begin
            FIvtBase := GetHexValue(1,Line);
            FIvtLength := GetHexValue(2,Line);
         end;
         if Pos('SECTIONS', uppercase(Line)) = 1 then    // we've looked far enough...
            Found := true;
         inc(index);
      end;
      Lines.free;
   end;
end;

{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TModelItem.LoadRAM;
var
   Lines:TStringList;
   Line:string;
   Index:integer;
   Found:boolean;
begin
   FXRAM := 0;
   FYRAM := 0;
   FXRAMStart := 0;
   FYRAMStart := 0;
   FDMARamStart := 0;
   FDMARam := 0;
   if FileExistsUTF8(FGLDFilename) { *Converted from FileExists* } then
   begin
      Found := false;
      Lines := TStringList.Create;
      Lines.LoadFromFile(FGLDFilename);
      Index := 0;
      while (Index < Lines.Count) and not Found do
      begin
         Line := Trim(Lines.Strings[Index]);
         // __DATA_BASE = 0x1000;
         if Pos('__DATA_BASE', Line) = 1 then
            FXRAMStart := GetHexValue(1,Line);
         //__DATA_LENGTH = 0x8000;
         if Pos('__DATA_LENGTH', Line) = 1 then
         begin
            FXRAM := GetHexValue(1,Line);
            //FXRAM := FXRAM + FXRAMStart;
         end;
         // __YDATA_BASE = 0x5000;
         if Pos('__YDATA_BASE', Line) = 1 then
         begin
            FYRAMStart := GetHexValue(1,Line);
         end;
         // __DMA_BASE = 0x2000;
         if Pos('__DMA_BASE', Line) = 1 then
         begin
            FDMARamStart := GetHexValue(1,Line);
         end;
         // __DMA_END = 0x27FF;
         if Pos('__DMA_END', Line) = 1 then
         begin
            FDMARam := GetHexValue(1,Line);
            FDMARam := FDMARam - FDMARamStart + 1;
         end;
         if Pos('SECTIONS', uppercase(Line)) = 1 then    // we've looked far enough...
            Found := true;
         inc(index);
      end;
      FMaxRam := FXRAM;          // amount of ram
      if (FYRamStart <> 0) then
         FYRAM := (FXRAMStart + FXRAM) - FYRamStart;
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
function TModelItem.ProcessValues(pID:string;pValues:TStrings):string;
var
   Index:integer;
   NewLine:string;
   Position:integer;
begin
   result := '';
   if (Trim(pID) <> '') and (pValues.Count > 0) then
   begin
      result := 'public config ' + pID + '(' + pID + ') = {';
      for index := 0 to pValues.Count - 2 do
         result := result + pValues.Strings[index] + ', ';
      result := result + pValues.Strings[pValues.Count - 1] + '}';

      // patch in WDTEN alias
      if pID = 'WDTEN' then
      begin
         NewLine := Result;
         Position := Pos('WDTEN',NewLine);
         if Position > 0 then
         begin
            Delete(Newline,Position,Length('WDTEN'));
            Insert('WDT',Newline,Position);
            result := result + #13#10 + Newline;
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
procedure TModelItem.LoadFuses;
var
   Line,ID,NewID,NewLine,Value:string;
   Lines,Values,NewLines:TStringList;
   Index:integer;
   StartBlock:boolean;
begin
   FFuses.Clear;
   FDefaultFuses.Clear;
   if FileExistsUTF8(FIncFilename) { *Converted from FileExists* } then
   begin
      Values := TStringList.Create;
      NewLines := TStringList.Create;
      Lines := TStringList.Create;
      Lines.LoadFromFile(FIncFilename);
      ID := '';
      StartBlock := false;
      for Index := 0 to Lines.Count - 1 do
      begin
         Line := Uppercase(Lines.Strings[index]);
         if Pos('IMPORTANT: FOR THE PIC18 DEVICES, THE __CONFIG DIRECTIVE',Line) > 0 then
            StartBlock := true
         else if StartBlock and (Pos('==============',Line) > 0) then
            break;
         if StartBlock then
            if Pos('=',Line) > 0 then
            begin
               NewID := GetMPASMID(Line);
               if ID = '' then
               begin
                  ID := NewID;
                  Value := GetMPASMValue(Line);
                  Values.Add(Value);
               end
               else if NewID = ID then
               begin
                  Value := GetMPASMValue(Line);
                  Values.Add(Value)
               end
               else if NewID <> ID then
               begin
                  SetDefaultFuse(ID,Values);
                  NewLine := ProcessValues(ID,Values);
                  if NewLine <> '' then
                     NewLines.Add(NewLine);
                  Values.Clear;
                  ID := NewID;
                  Value := GetMPASMValue(Line);
                  Values.Add(Value);
               end;
            end;
      end;
      if Values.Count > 0 then
      begin
         NewLine := ProcessValues(ID,Values);
         if NewLine <> '' then
            NewLines.Add(NewLine);
      end;

      if NewLines.Count > 0 then
      begin
         NewLines.Insert(0,''' configuration fuses...');
         NewLines.Insert(0,'');
         FFuses.AddStrings(NewLines);
      end;
      NewLines.Free;
      Lines.Free;
      Values.Free;
   end;
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
   Author := 'Firewing System Generator';
   Copyright := 'Mecanique';
   DateStr := FormatDateTime(ShortDateFormat,Date);
   YearStr := FormatDateTime('yyyy',Date);

//   pLines.Insert(0,'');
   pLines.Insert(0,'''****************************************************************');
   pLines.Insert(0,'''*  ' + Pad(FGLDVersion,60,' ') + '*');
   pLines.Insert(0,'''*  Notice  : ' + Pad('Generated on the ' + DateStr,50,' ') + '*');
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
(*
.ivt __IVT_BASE :
    LONG( DEFINED(__ReservedTrap0)    ? ABSOLUTE(__ReservedTrap0)    :
         ABSOLUTE(__DefaultInterrupt));
    LONG( DEFINED(__OscillatorFail)    ? ABSOLUTE(__OscillatorFail)    :
         ABSOLUTE(__DefaultInterrupt));
    LONG( DEFINED(__AddressError)    ? ABSOLUTE(__AddressError)    :
         ABSOLUTE(__DefaultInterrupt));
    LONG( DEFINED(__StackError)    ? ABSOLUTE(__StackError)    :
         ABSOLUTE(__DefaultInterrupt));
    LONG( DEFINED(__MathError)    ? ABSOLUTE(__MathError)    :
         ABSOLUTE(__DefaultInterrupt));
    LONG( DEFINED(__ReservedTrap5)    ? ABSOLUTE(__ReservedTrap5)    :
         ABSOLUTE(__DefaultInterrupt));
    LONG( DEFINED(__ReservedTrap6)    ? ABSOLUTE(__ReservedTrap6)    :
         ABSOLUTE(__DefaultInterrupt));
    LONG( DEFINED(__ReservedTrap7)    ? ABSOLUTE(__ReservedTrap7)    :
         ABSOLUTE(__DefaultInterrupt));

*)
(*
public const ReservedTrap0 as string = "ReservedTrap0"
public const OscillatorFail as string = "OscillatorFail"
public const AddressError as string = "AddressError"
public const StackError as string = "StackError"
public const MathError as string = "MathError"
public const ReservedTrap5 as string = "ReservedTrap5"
public const ReservedTrap6 as string = "ReservedTrap6"
public const ReservedTrap7 as string = "ReservedTrap7"
public const INT0Interrupt as string = "INT0Interrupt,  IEC0.0"
public const IC1Interrupt as string = "IC1Interrupt,  IEC0.1"
*)
procedure TModelItem.AddInterrupts(pLines:TStrings);
var
   Lines:TStringList;
   Index,Position, ISRIndex:integer;
   Line, Key, Name, SFR:string;
   StartOfISR:boolean;
   SFRAddr:integer;
begin
   if FileExistsUTF8(FGLDFilename) { *Converted from FileExists* } then
   begin
      SFRAddr := 0;
      ISRIndex := 0;
      StartOfISR := false;
      Lines := TStringList.Create;
      Lines.LoadFromFile(FGLDFilename);
      Key := 'long( defined(__';
      for Index := 0 to Lines.Count - 1 do
      begin
         Line := Trim(Lines.Strings[Index]);
         if Pos('.ivt', Line) = 1 then
            StartOfISR := true
         else if Pos('.aivt', Line) = 1 then
            StartOfISR := false
         else if StartOfISR then
         begin
            Position := Pos(Key, lowercase(Line));
            if Position > 0 then
            begin
               Line := Copy(Line, Position + Length(Key), Length(Line));
               Position := Pos(')', Line);
               if Position > 0 then
               begin
                  SFR := '';
                  if ISRIndex >= 8 then
                  begin
                     SFR := ', IEC' + IntToStr(SFRAddr div 16) + '.' + IntToStr(SFRAddr mod 16);
                     inc(SFRAddr);
                  end;
                  Name := Copy(Line, 1, Position - 1);
                  if Pos('interrupt', lowercase(name)) <> 1 then
                     if Pos('reserved', lowercase(name)) <> 1 then
                        pLines.Add('public const ' + Name + ' as string = "' + Name + SFR + '"');
                  inc(ISRIndex);
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
function TModelItem.SaveToStrings_BASIC(pLines:TStrings):boolean;
var
   Index:integer;
   SFR:TSFR;
   ch:char;
begin
   result := false;
   if IsValid then
   begin

      if FGenerateModel then
      with pLines do
      begin
        // WriteINI;

         MakeHeader(FDevice,pLines);

         // name...
         Add('module PIC');
         Add('');

         // system header
         Add(''' system header...');
         Add(Pad('#const _core = &H0018',38) + ''' processor core');
         Add(Pad('#variable _maxrom = &H' + IntToHex(FMaxRom,6),38) + ''' ' + IntToStr((FMaxRom - 1) div 1024) + ' KB of program ROM');
         Add(Pad('#variable _maxram = &H' + IntToHex(FMaxRAM,4),38) + ''' ' + IntToStr(FMaxRAM) + ' bytes of user RAM');

         Add(Pad('#variable _ivtbase = &H' + IntToHex(FIvtBase,6),38) + ''' ivt addr');
         Add(Pad('#variable _ivtlen = &H' + IntToHex(FIvtLength,6),38) + ''' ivt size');
         if (FAIvtBase > 0) then
         begin
            Add(Pad('#variable _aivtbase = &H' + IntToHex(FAIvtBase,6),38) + ''' aivt addr');
            Add(Pad('#variable _aivtlen = &H' + IntToHex(FAIvtLength,6),38) + ''' aivt size');
         end;
         Add(Pad('#variable _codebase = &H' + IntToHex(FCodeBase,6),38) + ''' program start addr');
         Add(Pad('#variable _codelen = &H' + IntToHex(FCodeLength,6),38) + ''' program size');
         if (FAuxFlashBase > 0) then
         begin
            Add(Pad('#variable _auxflashbase = &H' + IntToHex(FAuxFlashBase,6),38) + ''' aux flash addr');
            Add(Pad('#variable _auxflash = &H' + IntToHex(FAuxFlashLength,6),38) + ''' aux flash size');
         end;

         Add(Pad('#variable _xramstart = &H' + IntToHex(FXRAMStart,4),38) + ''' x RAM start addr');
         Add(Pad('#variable _xram = &H' + IntToHex(FXRAM,4),38) + ''' x RAM size');
         Add(Pad('#variable _yramstart = &H' + IntToHex(FYRAMStart,4),38) + ''' y RAM start addr');
         Add(Pad('#variable _yram = &H' + IntToHex(FYRAM,4),38) + ''' y RAM size');
         Add(Pad('#variable _dmaramstart = &H' + IntToHex(FDMARamStart,4),38) + ''' DMA ram start addr');
         Add(Pad('#variable _dmaram = &H' + IntToHex(FDMARam,4),38) + ''' DMA RAM size');

         Add(Pad('#const _eeprom = &H' + IntToHex(0,4),38) + ''' ' + IntToStr(0) + ' bytes of EEPROM');
         Add(Pad('#const _ports = &H' + IntToHex(NumberOfPorts,2),38) + ''' ' + IntToStr(NumberOfPorts) + ' available ports');

         if HasUSB > 0 then
            Add(Pad('#const _usb = &H' + IntToHex(HasUSB,2),38) + ''' onboard USB available')
         else
            Add(Pad('#const _usb = &H' + IntToHex(HasUSB,2),38) + ''' USB is NOT supported');

         if HasRTC > 0 then
            Add(Pad('#const _rtcc = &H' + IntToHex(HasRTC,2),38) + ''' onboard Real-Time Clock/Calendar (RTCC) available')
         else
            Add(Pad('#const _rtcc = &H' + IntToHex(HasRTC,2),38) + ''' Real-Time Clock/Calendar (RTCC) is NOT supported');

         if HasPMP > 0 then
            Add(Pad('#const _pmp = &H' + IntToHex(HasPMP,2),38) + ''' onboard Parallel Master Slave Port (PMP) available')
         else
            Add(Pad('#const _pmp = &H' + IntToHex(HasPMP,2),38) + ''' Parallel Master Slave Port (PMP) is NOT supported');

         if NumberOfDMA > 0 then
            Add(Pad('#const _dma = &H' + IntToHex(NumberOfDMA,2),38) +  ''' ' + IntToStr(NumberOfDMA) + ' DMA channel(s) available')
         else
            Add(Pad('#const _dma = &H' + IntToHex(NumberOfDMA,2),38) + ''' Direct Memory Access (DMA) is NOT supported');

         if NumberOfECAN > 0 then
            Add(Pad('#const _ecan = &H' + IntToHex(NumberOfECAN,2),38) + ''' ' + IntToStr(NumberOfECAN) + ' ECAN(s) available')
         else
            Add(Pad('#const _ecan = &H' + IntToHex(NumberOfECAN,2),38) + ''' Enhanced CAN is NOT supported');

         if NumberOfUSART = 0 then
            Add(Pad('#const _usart = &H' + IntToHex(NumberOfUSART, 2),38) + ''' USART module NOT supported')
         else
            Add(Pad('#const _usart = &H' + IntToHex(NumberOfUSART, 2),38) + ''' ' + IntToStr(NumberOfUSART) + ' USART(s) available');

         if NumberOfSPI= 0 then
            Add(Pad('#const _spi = &H' + IntToHex(NumberOfSPI, 2),38) + ''' SPI module NOT supported')
         else
            Add(Pad('#const _spi = &H' + IntToHex(NumberOfSPI, 2),38) + ''' ' + IntToStr(NumberOfSPI) + ' SPI module(s) available');          // OK

         if NumberOfI2C= 0 then
            Add(Pad('#const _i2c = &H' + IntToHex(NumberOfI2C, 2),38) + ''' I2C module NOT supported')
         else
            Add(Pad('#const _i2c = &H' + IntToHex(NumberOfI2C, 2),38) + ''' ' + IntToStr(NumberOfI2C) + ' I2C module(s) available');          // OK

         if NumberOfPWM= 0 then
            Add(Pad('#const _pwm = &H' + IntToHex(NumberOfPWM, 2),38) + ''' PWM module NOT supported')
         else
            Add(Pad('#const _pwm = &H' + IntToHex(NumberOfPWM, 2),38) + ''' ' + IntToStr(NumberOfPWM) + ' PWM module(s) available');          // OK


         // dump the interrupts

         // special function registers
         if FSFR.Count > 0 then
         begin
            Add('');
            Add(''' special function registers...');
            for Index := 0 to FSFR.Count - 1 do
            begin
               SFR := TSFR(FSFR.Items[Index]);
               pLines.Add('public system ' + SFR.Name + ' as ushort absolute &H' + IntToHex(SFR.Address,4));
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
               pLines.Add('public system port ' + SFR.Name + ' as ushort absolute &H' + IntToHex(SFR.Address,4));
            end;
         end;

         // fuses
         GenerateAllFuse(pLines);
         //pLines.AddStrings(FFuses);

         // default fuses..
         if FDefaultFuses.Count > 0 then
         begin
            pLines.Add('');
            pLines.Add(''' default fuses...');
            for Index := 0 to FDefaultFuses.Count - 1 do
               pLines.Add('config ' + FDefaultFuses.Strings[index]);
         end;

         pLines.Add('');
         pLines.Add(''' interrupts...');
         AddInterrupts(pLines);

         pLines.Add('');
         pLines.Add(''' entry point with startup event handler...');
         pLines.Add('Public Event OnStartup()');
         pLines.Add('Inline Sub Main()');

         // adc
         if HasSFR('AD1PCFG') then
            pLines.Add('   AD1PCFG = &HFFFF')
         else if HasSFR('AD1PCFGL') then
         begin
            pLines.Add('   AD1PCFGL = &HFFFF');
            if HasSFR('AD1PCFGH') then pLines.Add('   AD1PCFGH = &HFFFF');
         end;

         if HasSFR('ANSEL') then
            pLines.Add('   ANSEL = 0')
         else
         begin
            for ch := 'A' to 'F' do
               if HasSFR('ANSEL' + Ch) then
                 pLines.Add('   ANSEL' + Ch + ' = 0');
         end;

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
function TModelItem.Pack(pName:string;pAmount:integer):string;
var
   Index:integer;
begin
   result := '';
   for Index := Length(pName) to pAmount do
      Result := Result + ' ';
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
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TModelItem.SaveToStrings_INCLUDE(pLines:TStrings);
var
   Index:integer;
   SFR:TSFR;
begin
   if IsValid then
      with pLines do
      begin
         pLines.Add('NOLIST');
         pLines.Add('; *******************************************');
         pLines.Add('; * ASM Definition file for Swordfish BASIC *');
         pLines.Add('; *******************************************');
         pLines.Add('LIST');

         // write SFR
         pLines.Add('');
         pLines.Add('; special function registers...');
         for Index := 0 to FSFR.Count - 1 do
         begin
            SFR := TSFR(FSFR.Items[Index]);
            pLines.Add(SFR.Name + Pack(SFR.Name,16) + 'EQU 0x' + IntToHex(SFR.Address,4));
         end;

         // write ports
         pLines.Add('');
         pLines.Add('; system ports...');
         for Index := 0 to FPorts.Count - 1 do
         begin
            SFR := TSFR(FPorts.Items[Index]);
            pLines.Add(SFR.Name + Pack(SFR.Name,16) + 'EQU 0x' + IntToHex(SFR.Address,4));
         end;

         pLines.Add('');
         pLines.Add('; LIST');
      end;
end;

end.
