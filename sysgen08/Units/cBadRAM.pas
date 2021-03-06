unit cBadRAM;

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
  Classes, SysUtils;

type
   TBadRAM = class(TObject)
   private
      FRamStart:integer;
      FRamEnd:integer;
      procedure GetRange(pBadRAM:string);
   public
      constructor Create(pBadRAM:string);
      function IsValid:boolean;
      property RamStart:integer read FRamStart;
      property RamEnd:integer read FRamEnd;
      function Collision(pStart, pEnd:integer):boolean;
   end;

implementation

{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
constructor TBadRAM.Create(pBadRAM:string);
begin
   inherited Create;
   GetRange(pBadRAM);
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
procedure TBadRAM.GetRange(pBadRAM:string);
var
   Position:integer;
   StrValueA,StrValueB:string;
begin
   FRamStart := -1;
   FRamEnd := -1;
   pBadRAM := Uppercase(pBadRam);

   //     07-09 OR 0D etc
   Position := Pos('-',pBadRam);
   if Position > 0 then
   begin
      StrValueA := Copy(pBadRam,1,Position - 1);
      StrValueB := Copy(pBadRam,Position + 1,Length(pBadRam));
   end   
   else
   begin
      StrValueA := pBadRam;
      StrValueB := StrValueA;
   end;
   try
      FRamStart := StrToInt('$' + StrValueA);
      FRamEnd := StrToInt('$' + StrValueB);
   except
   end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TBadRAM.IsValid:boolean;
begin
   Result := (FRamStart >= 0) and (FRamEnd >= 0);
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function TBadRam.Collision(pStart, pEnd:integer):boolean;
var
   Index:integer;
begin
   result := false;
   for Index := pStart to pEnd do
      if  (Index >= FRamStart) and (Index <= FRamEnd) then
      begin
         result := true;
         exit;
      end;
end;

end.


