unit cUtils;

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
  SysUtils,
   Classes;

function GetName(pLine:string):string;
function GetAddress(pLine:string):integer;
function GetKeyName(pLine:string):string;
function GetKeyAddress(pLine:string):integer;

implementation
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
// PORTC        = 0x2D2;
function GetName(pLine:string):string;
var
   Position:integer;
begin
   pLine := Uppercase(pLine);
   Position := Pos('=',pLine) - 1;
   if Position > 0 then
      Result:= Trim(Copy(pLine,1,Position))
   else
      Result := '';
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
// PORTC        = 0x2D2;
function GetAddress(pLine:string):integer;
var
   Position:integer;
begin
   pLine := Uppercase(pLine);

   Position := Pos(';',pLine);
   if Position > 0 then
      pLine := Trim(Copy(pLine,1, Position - 1));

   Position := Pos('=',pLine);
   if Position > 0 then
      pLine := Trim(Copy(pLine,Position + 1, Length(pLine)));

   Position := Pos('0X',pLine);
   if Position = 1 then
      Delete(pLine,1,2);

   try
      Result := StrToInt('$' + pLine);
   except
      Result := 0;
   end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
// sfr (key=TOS addr=0xFFD size=3 flags=j)
function GetKeyName(pLine:string):string;
var
   PosStart,PosEnd:integer;
begin
   result := '';
   pLine := Uppercase(pLine);
   PosStart := Pos('KEY=',pLine);
   if PosStart > 0 then
   begin
      inc(PosStart,4);
      pLine := Trim(Copy(pLine,PosStart,Length(pLine)));
      PosEnd := Pos(' ',pLine);
      if PosEnd > 0 then
      begin
         pLine := Trim(Copy(pLine,1,PosEnd));
         Result := pLine;
      end
   end;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
// sfr (key=TOS addr=0xFFD size=3 flags=j)
function GetKeyAddress(pLine:string):integer;
var
   PosStart,PosEnd:integer;
begin
   result := 0;
   pLine := Uppercase(pLine);
   PosStart := Pos('ADDR=',pLine);
   if PosStart > 0 then
   begin
      inc(PosStart,5);
      pLine := Trim(Copy(pLine,PosStart,Length(pLine)));
      PosEnd := Pos(' ',pLine);
      if PosEnd > 0 then
      begin
         pLine := Trim(Copy(pLine,1,PosEnd));
         Delete(pLine,1,2);
         Insert('$',pLine,1);
         try
            Result := StrToInt(pLine);
         except
            Result := 0;
         end;
      end
   end;
end;



end.
