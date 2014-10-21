unit Scales_LIB;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, SPComm, StdCtrls, ExtCtrls,DateUtils,Registry,inifiles;

type
  TSCScanPort = class(TThread)
    procedure Comm1ReceiveData(Sender: TObject; Buffer: Pointer;BufferLength: Word);
  private

  public
    cfg_Used:boolean;
    cfg_AutoDect:boolean;
    cfg_ComPort:integer;
    
    SCCom:integer;
    SCComIsOK:boolean;
    SCValue:double;
    SCTime:TDateTime;

    EarseSCNow:boolean;

    ComPortCount:integer;
    ScanComIsComplete:boolean;
    CommArray:array[0..32] of TComm;
    ComList:array of integer;
    ComIsAlive:array of boolean;

    procedure ScanSC_Port();
    function  PortIsAlive(ComNum:integer):boolean;
    procedure WriteCMDAndWait(var COM:TComm;CMD:string);
    procedure ReFreshTime(var COM:TComm);
    procedure Execute; override;
  end;

var SCPort:TSCScanPort;

implementation


procedure TSCScanPort.Execute;
var
  ConfigINI:tinifile;
begin
  ConfigINI:=tinifile.create(ExtractFileDir(application.ExeName)+'\Config.ini');
  cfg_Used := ConfigINI.ReadBool('Satrue','Used',true);
  cfg_AutoDect:= ConfigINI.ReadBool('Satrue','AutoDetect',true);
  cfg_ComPort:= ConfigINI.ReadInteger('Satrue','COM',1);
  ConfigINI.WriteBool('Satrue','Used',cfg_Used);
  ConfigINI.WriteBool('Satrue','AutoDetect',cfg_AutoDect);
  ConfigINI.WriteInteger('Satrue','COM',cfg_ComPort);

  self.Priority:= tpLower;
  while true do
  begin
    ScanSC_Port();
    sleep(500);
  end;
end;


procedure TSCScanPort.Comm1ReceiveData(Sender: TObject; Buffer: Pointer;
  BufferLength: Word);
var
  BUF:pchar;
  BINData:array of byte;
  Data,j,i:integer;
  DataSIndex,DataEIndex:integer;
  ETime,Y,M,D,H,N:integer;
  TempData:string;
begin
   BINData:=Buffer;
   BUF:=pchar(BINData);

   if pos('-S',BUF)>0 then
   begin
      SCComIsOK:=true;
      ScanComIsComplete:=true;
      SCCom:=TComm(Sender).Tag;

      DataSIndex:=pos('RC',BUF)+2;
      DataEIndex:=pos('kg',BUF)-3;
      if (DataSIndex<3)or(DataEIndex<3) then exit;

      TempData:= copy(BUF,DataSIndex,DataEIndex);
      SCValue:= strtofloat(TempData);
      SCTime:=now;
   end
end;


procedure TSCScanPort.ReFreshTime(var COM:TComm);
  //SetTime:array [0..7] of byte=($51,$33,$00,$00,$00,$00,$A3,$00);
var
  EDate,i:integer;
  CheckSum:integer;
  SetTime:array [0..7] of byte;
begin
  for i:=0 to 7 do SetTime[i]:=0;
  SetTime[0]:=$51;
  SetTime[1]:=$33;
  SetTime[6]:=$A3;
  EDate:=(DateUtils.DayOf(Now))+
         (DateUtils.MonthOf(Now)*32)+
         ((DateUtils.YearOf(Now)-2000)*512);

  SetTime[2]:=EDate mod 256;
  SetTime[3]:=EDate shr 8;
  SetTime[4]:=DateUtils.MinuteOf(Now);
  SetTime[5]:=DateUtils.HourOf(Now);

  CheckSum:=0;
  for i:=0 to 6 do
    CheckSum:=CheckSum+SetTime[i];

  SetTime[7]:=(CheckSum mod 256);

  if PortIsAlive(COM.Tag) then
    COM.WriteCommData(@SetTime,8);

end;

procedure TSCScanPort.WriteCMDAndWait(var COM:TComm;CMD:string);
var
  i:integer;
  Delay:integer;
begin
  if CMD='Data' then
    if PortIsAlive(COM.Tag) then COM.WriteCommData('A',1);

  application.ProcessMessages;


   Delay:=windows.GetTickCount;
   while(windows.GetTickCount-Delay<200) do
   begin
      application.ProcessMessages;
      sleep(10);
   end;
end;

function  TSCScanPort.PortIsAlive(ComNum:integer):boolean;
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

procedure TSCScanPort.ScanSC_Port();
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
      CommArray[i].BaudRate:=9600;
      CommArray[i].Tag:=ComList[i];
      CommArray[i].OnReceiveData:=Comm1ReceiveData;
      ComIsAlive[i]:=true;
      application.ProcessMessages;
      try
        if PortIsAlive(CommArray[i].Tag) then CommArray[i].StartComm;
        sleep(200);
        WriteCMDAndWait(CommArray[i],'Data');
      except
        ComIsAlive[i]:=false;
      end;
      application.ProcessMessages;
   end;

   if ScanComIsComplete=false then
   begin
    SCCom:=0;
    SCComIsOK:=false;
    SCValue:=0;
   end;
end;

end.


