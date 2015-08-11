unit cSFR;

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
  Classes, SysUtils,
   cUtils;

type   
   TSFR = class(TObject)
   private
      FName:string;
      FAddress:integer;
   public
      constructor Create(pSFR:string); overload;
      constructor Create(pName:string;pAddress:integer);overload;
      constructor CreateFromDevice(pSFR:string);
      property Name:string read FName;
      property Address:integer read FAddress;
   end;

implementation

{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
constructor TSFR.Create(pSFR:string);
begin
   inherited Create;
   FName := GetName(pSFR);
   FAddress := GetAddress(pSFR);
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
constructor TSFR.Create(pName:string;pAddress:integer);
begin
   inherited Create;
   FName := pName;
   FAddress := pAddress;
end;
{
****************************************************************************
* Name    :                                                                *
* Purpose :                                                                *
****************************************************************************
}
constructor TSFR.CreateFromDevice(pSFR:string);
begin
   inherited Create;
   FName := GetKeyName(pSFR);
   FAddress := GetKeyAddress(pSFR);
end;

end.
