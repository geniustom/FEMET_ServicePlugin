unit BarCode_Lib;

interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

Type
  TCallBack = procedure;
  
  TBarCode=Class
    constructor Create(TimeLimit:integer);overload;
  Public
    KeyBuffer:array[0..10] of char;
    KeyIndex:integer;
    StartTime:int64;
    EndTime:int64;
    TimeOut:integer;
    IDNo:string;
    function ReceiveKey(var Msg: TMessage;CB:TCallBack):string;
  end;
  function CheckIdNo(sIdNo: string): Boolean;


var
  BarCode:TBarCode;
  function StartHook(MemoHandle, AppHandle: HWND): Byte; export; far; external 'HookLib.dll';
  function StopHook: Boolean; export;far; external 'HookLib.dll';



implementation

constructor TBarCode.Create(TimeLimit:integer);
begin
   inherited Create;
   TimeOut:=TimeLimit;
end;

function TBarCode.ReceiveKey(var Msg: TMessage;CB:TCallBack):string;
var
UserID:string;
KeyStr:string;
begin
  result:='';
  if (Msg.wParam in [65..90]) OR (Msg.wParam in [97..122]) then
  begin
     KeyIndex:=0;
     StartTime:=windows.GetTickCount;
  end;
  KeyStr:=chr(Msg.wParam);
  KeyBuffer[KeyIndex]:=UpperCase(KeyStr)[1];
  KeyIndex:=(KeyIndex+1) mod 11;
  if (Msg.wParam = 13) and (KeyIndex=0) then
  begin
    EndTime:=windows.GetTickCount;
    UserID:=copy(string(@KeyBuffer),0,10);
    if CheckIdNo(UserID) and (EndTime-StartTime<TimeOut) then
    begin
      result:=UserID;
      IDNo:=UserID;
      beep;
      if Assigned(CB) then CB;
    end;
  end;
end;

function CheckIdNo(sIdNo: string): Boolean;
const
    IDNIDX : array['A'..'Z'] of byte =
        (1,2,3,4,5,6,7,8,25,9,10,11,12,13,26,14,15,16,17,18,19,20,23,21,22,24);

    IDNTable : array[1..26] of byte = (10,11,12,13,14,15,16,17,18,19,20,21,22,
        23,24,25,26,27,28,29,30,31,32,33,34,35);
var V:integer;
begin
    if sIdNo[1] in ['A'..'Z'] then
    begin
        V :=
        IDNTable[IDNIDX[sIdNo[1]]] div 10 + (IDNTable[IDNIDX[sIdNo[1]]] mod 10) * 9 +
        (byte(sIdNo[2])-48) * 8 + (byte(sIdNo[3])-48) * 7 + (byte(sIdNo[4])-48) * 6 +
        (byte(sIdNo[5])-48) * 5 + (byte(sIdNo[6])-48) * 4 + (byte(sIdNo[7])-48) * 3 +
        (byte(sIdNo[8])-48) * 2 + byte(sIdNo[9])-48 + byte(sIdNo[10])-48;
        result := (length(sIdNo) = 10) and ((sIdNo[2] = '1') or (sIdNo[2] = '2')) and (V
        div 10 = V / 10);
        //SHOWMESSAGE(BOOLTOSTR(result));
    end
    else
        result := False;
end;

end.
