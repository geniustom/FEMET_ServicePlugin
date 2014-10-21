unit SPO2_Lib;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, SPComm, StdCtrls, ExtCtrls,DateUtils,Registry,inifiles;

type
  TSPO2ScanPort = class(TThread)
    procedure Comm1ReceiveData(Sender: TObject; Buffer: Pointer;BufferLength: Word);
  private

  public
    cfg_Used:boolean;
    cfg_AutoDect:boolean;
    cfg_ComPort:integer;
    
    SPO2Com:integer;
    SPO2ComIsOK:boolean;
    SPO2Value:double;
    SPO2Time:TDateTime;

    EarseSPO2Now:boolean;

    ComPortCount:integer;
    ScanComIsComplete:boolean;
    CommArray:array[0..32] of TComm;
    ComList:array of integer;
    ComIsAlive:array of boolean;

    procedure ScanSPO2_Port();
    function  PortIsAlive(ComNum:integer):boolean;
    procedure WriteCMDAndWait(var COM:TComm;CMD:string);
    procedure ReFreshTime(var COM:TComm);
    procedure Execute; override;
  end;

var SPO2Port:TSPO2ScanPort;

implementation


procedure TSPO2ScanPort.Execute;
var
  ConfigINI:tinifile;
begin
  ConfigINI:=tinifile.create(ExtractFileDir(application.ExeName)+'\Config.ini');
  cfg_Used := ConfigINI.ReadBool('Comdec','Used',true);
  cfg_AutoDect:= ConfigINI.ReadBool('Comdec','AutoDetect',true);
  cfg_ComPort:= ConfigINI.ReadInteger('Comdec','COM',1);
  ConfigINI.WriteBool('Comdec','Used',cfg_Used);
  ConfigINI.WriteBool('Comdec','AutoDetect',cfg_AutoDect);
  ConfigINI.WriteInteger('Comdec','COM',cfg_ComPort);

  self.Priority:= tpLower;
  while true do
  begin
    ScanSPO2_Port();
    sleep(2000);
  end;
end;


procedure TSPO2ScanPort.Comm1ReceiveData(Sender: TObject; Buffer: Pointer;
  BufferLength: Word);
var
  BUF:pchar;
  BINData:array of byte;
  Data,j,i:integer;
  DataIndex,CheckIndex:integer;
  ETime,Y,M,D,H,N:integer;
  TempData:integer;
begin
   BINData:=Buffer;
   BUF:=pchar(BINData);
   CheckIndex:=99;

   if BufferLength<2 then exit;

   for i:=0 to BufferLength-2 do
   begin
      if BINData[i]=$FE then TempData:= BINData[i+1];
      if BINData[i]=$FB then CheckIndex:= BINData[i+1];
   end;

   if (CheckIndex=0)and (TempData>0) and (TempData<=100)then
   begin
      SPO2ComIsOK:=true;
      ScanComIsComplete:=true;
      SPO2Com:=TComm(Sender).Tag;

      SPO2Value:= TempData;
      SPO2Time:=now;
   end
end;


procedure TSPO2ScanPort.ReFreshTime(var COM:TComm);
var
  EDate,i:integer;
  CheckSum:integer;
  SetTime:array [0..7] of byte;
begin

end;

procedure TSPO2ScanPort.WriteCMDAndWait(var COM:TComm;CMD:string);
var
  i:integer;
  Delay:integer;
begin

end;

function  TSPO2ScanPort.PortIsAlive(ComNum:integer):boolean;
var
  i,j:integer;
  reg : TRegistry;
  ts: TStrings;
  ComNo:integer;
begin
  reg := TRegistry.Create;
  reg.RootKey := HKEY_LOCAL_MACHINE;
  reg.OpenKey('hardware\devicemap\serialcomm',false);
  ts := TStringList.Create;
  reg.GetValueNames(ts);
  result:=false;
  for i:=0 to ts.Count -1 do
  begin
     ComNo:=strtoint(StringReplace(reg.ReadString(ts.Strings[i]),'COM','',[rfReplaceAll]));
     if ComNo=ComNum then
     begin
        result:=true;
        exit;
     end;
  end;

end;

procedure TSPO2ScanPort.ScanSPO2_Port();
var
  i,j:integer;
  reg : TRegistry;
  ts: TStrings;
  Com4Digi:string;
begin
  ScanComIsComplete:=false;

  if cfg_AutoDect then
  begin
    reg := TRegistry.Create;
    reg.RootKey := HKEY_LOCAL_MACHINE;
    reg.OpenKey('hardware\devicemap\serialcomm',false);
    ts := TStringList.Create;
    reg.GetValueNames(ts);
    ComPortCount:=ts.Count;
    setlength(ComList,ComPortCount);
    setlength(ComIsAlive,ComPortCount);
  end
  else
  begin
    ComPortCount:=1;
    setlength(ComList,ComPortCount);
    setlength(ComIsAlive,ComPortCount);
    ComList[0]:=cfg_ComPort;
  end;

   for i:=0 to ComPortCount -1 do
   begin
      if cfg_AutoDect then ComList[i]:=strtoint(StringReplace(reg.ReadString(ts.Strings[i]),'COM','',[rfReplaceAll]));
      if CommArray[i]<>nil then
      begin
        if PortIsAlive(CommArray[i].Tag) then
          CommArray[i].StopComm;
        CommArray[i].Free;
      end;
      CommArray[i]:=TComm.Create(nil);
      CommArray[i].CommName:='\\.\COM'+inttostr(ComList[i]);
      CommArray[i].BaudRate:=115200;
      CommArray[i].Tag:=ComList[i];
      CommArray[i].OnReceiveData:=Comm1ReceiveData;
      ComIsAlive[i]:=true;
      application.ProcessMessages;
      try
        if PortIsAlive(CommArray[i].Tag) then CommArray[i].StartComm;
        sleep(1000);
        //WriteCMDAndWait(CommArray[i],'Data');
      except
        ComIsAlive[i]:=false;
      end;
      application.ProcessMessages;
   end;

   if ScanComIsComplete=false then
   begin
    SPO2Com:=0;
    SPO2ComIsOK:=false;
    SPO2Value:=0;
   end;
end;

end.


