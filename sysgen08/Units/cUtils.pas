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

function GetEQUName(pLine:string):string;
function GetEQUAddress(pLine:string):integer;
function GetKeyName(pLine:string):string;
function GetKeyAddress(pLine:string):integer;

implementation
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
function GetEQUName(pLine:string):string;
var
   Position:integer;
begin
   pLine := Uppercase(pLine);
   Position := Pos('EQU',pLine) - 1;
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
function GetEQUAddress(pLine:string):integer;
var
   Index,Range:integer;
   ValueStr:string;
begin
   pLine := Uppercase(pLine);
   Result := 0;
   ValueStr := '';
   Range := Length(pLine);
   Index := Pos('H''',pLine) + 2;
   while (Index > 0) and (Index <= Range) and (pLine[Index] in ['0'..'9','A'..'F']) do
   begin
      ValueStr := ValueStr + pLine[index];
      inc(Index);
   end;
   try
      Result := StrToInt('$' + ValueStr);
   except
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
