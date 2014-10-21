unit GM_LIB;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, SPComm, StdCtrls, ExtCtrls,DateUtils,Registry,inifiles;

type
  TGMScanPort = class(TThread)
    procedure Comm1ReceiveData(Sender: TObject; Buffer: Pointer;BufferLength: Word);
  private

  public
    cfg_Used:boolean;
    cfg_AutoDect:boolean;
    cfg_ComPort:integer;

    GMCom:integer;
    GMComIsOK:boolean;
    GMValue:integer;
    GMTime:TDateTime;

    EarseGMNow:boolean;

    ComPortCount:integer;
    ScanComIsComplete:boolean;
    CommArray:array[0..32] of TComm;
    ComList:array of integer;
    ComIsAlive:array of boolean;

    procedure ScanGM_Port();
    function  PortIsAlive(ComNum:integer):boolean;
    procedure WriteCMDAndWait(var COM:TComm;CMD:string);
    procedure ReFreshTime(var COM:TComm);
    procedure Execute; override;
  end;

var GMPort:TGMScanPort;

implementation


procedure TGMScanPort.Execute;
var
  ConfigINI:tinifile;
begin
  ConfigINI:=tinifile.create(ExtractFileDir(application.ExeName)+'\Config.ini');
  cfg_Used := ConfigINI.ReadBool('Bionime','Used',true);
  cfg_AutoDect:= ConfigINI.ReadBool('Bionime','AutoDetect',true);
  cfg_ComPort:= ConfigINI.ReadInteger('Bionime','COM',1);
  ConfigINI.WriteBool('Bionime','Used',cfg_Used);
  ConfigINI.WriteBool('Bionime','AutoDetect',cfg_AutoDect);
  ConfigINI.WriteInteger('Bionime','COM',cfg_ComPort);

  self.Priority:= tpLower;
  while true do
  begin
    ScanGM_Port();
    sleep(1000);
  end;
end;


procedure TGMScanPort.Comm1ReceiveData(Sender: TObject; Buffer: Pointer;
  BufferLength: Word);
var
  BUF:pchar;
  BINData:array of byte;
  Data,j,i:integer;
  DataIndex:integer;
  ETime,Y,M,D,H,N:integer;
  CheckSum:integer;
begin
   BINData:=Buffer;
   BUF:=pchar(BINData);
   if pos('Q&',BUF)>0 then
   begin
      CheckSum:=0;
      for i:=0 to 6 do
        CheckSum:=CheckSum+BINData[i];
      if (BINData[6]<>$A5) then exit;
      if ((CheckSum mod 256)<>BINData[7]) then exit;

      GMCom:=TComm(Sender).Tag;
      GMComIsOK:=true;
      ScanComIsComplete:=true;
      GMValue:= BINData[3]*256+BINData[2];
   end
   else if pos('Q%',BUF)>0 then
   begin
      CheckSum:=0;
      for i:=0 to 6 do
        CheckSum:=CheckSum+BINData[i];
      //if (BINData[6]<>$A5) then exit;
      //if ((CheckSum mod 256)<>BINData[7]) then exit;
      
      ETime:=BINData[3]*256+BINData[2];
      Y:=(ETime div 512) mod 100;
      M:=(ETime div 32) mod 16;
      D:=ETime mod 32;
      H:=BINData[5] mod 32;
      N:=BINData[4] mod 64;
      GMTime:= StrtoDatetime(format('%d/%d/%d %d:%d',[Y,M,D,H,N]));
   end;
end;


procedure TGMScanPort.ReFreshTime(var COM:TComm);
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

procedure TGMScanPort.WriteCMDAndWait(var COM:TComm;CMD:string);
const
  GetHealthData:array [0..7] of byte=($51,$26,$00,$00,$00,$00,$A3,$1A);
  GetHealthTime:array [0..7] of byte=($51,$25,$00,$00,$00,$00,$A3,$19);
  ClearAllData :array [0..7] of byte=($51,$52,$00,$00,$00,$00,$A3,$46);
var
  i:integer;
  Delay:integer;
begin
  if CMD='Data' then
    if PortIsAlive(COM.Tag) then COM.WriteCommData(@GetHealthData,8);
  if CMD='Time' then
    if PortIsAlive(COM.Tag) then COM.WriteCommData(@GetHealthTime,8);
  if CMD='SetTime' then
    if PortIsAlive(COM.Tag) then ReFreshTime(COM);
  if CMD='Clean' then
    if PortIsAlive(COM.Tag) then COM.WriteCommData(@ClearAllData,8);

  application.ProcessMessages;


   Delay:=windows.GetTickCount;
   while(windows.GetTickCount-Delay<150) do
   begin
      application.ProcessMessages;
      sleep(1);
   end;
end;

function  TGMScanPort.PortIsAlive(ComNum:integer):boolean;
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

procedure TGMScanPort.ScanGM_Port();
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
      sleep(50);
      application.ProcessMessages;
      try
        if PortIsAlive(CommArray[i].Tag) then CommArray[i].StartComm;
        sleep(100);
        WriteCMDAndWait(CommArray[i],'Data');
        //sleep(100);
        WriteCMDAndWait(CommArray[i],'Time');
        //sleep(100);
        WriteCMDAndWait(CommArray[i],'SetTime');
        //sleep(100);
        if EarseGMNow=true then
        begin
          WriteCMDAndWait(CommArray[i],'Clean');
          EarseGMNow:=false;
        end;
      except
        ComIsAlive[i]:=false;
      end;
      application.ProcessMessages;
   end;

   if ScanComIsComplete=false then
   begin
    GMCom:=0;
    GMComIsOK:=false;
    GMValue:=0;
   end;
end;

end.


