unit ECG_Lib;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, SPComm, StdCtrls, ExtCtrls,DateUtils,Registry,inifiles,Series, TeeProcs, Chart, TeeFunci;

type
  TECGScanPort = class(TThread)
    procedure Comm1ReceiveData(Sender: TObject; Buffer: Pointer;BufferLength: Word);
  private

  public
    cfg_Used:boolean;
    cfg_AutoDect:boolean;
    cfg_ComPort:integer;
    
    ECGDataNow:boolean;
    ECGDataIndex:integer;
    SPO2DataNow:boolean;
    CheckSPO2Now:boolean;
    SPO2DataOK:boolean;
    SPO2Value:integer;

    ECGCom:integer;
    ComPortCount:integer;
    ScanComIsComplete:boolean;
    CommArray:array[0..32] of TComm;

    ComList:array of integer;
    ComIsAlive:array of boolean;
    ECGComIsOK:boolean;

    procedure ScanECG_Port();
    function  PortIsAlive(ComNum:integer):boolean;
    procedure ProcessData(out Chart:TChart;out SPO2:TEdit);
    procedure Execute; override;
  end;

  TQueue=class
     Front:integer;
     Rear:integer;
     Length:integer;
     Data:array[0..18000] of byte;

     procedure InitQ;
     procedure AddQ(D:byte);
     function DeQ():byte;
     function ISEmpty:boolean;
     function ShowData:string;
  end;

var
  ECGPort:TECGScanPort;
  ECGQueue:TQueue;
  DataQueue:TQueue;

implementation

procedure TQueue.InitQ;
begin
  Front:=0;
  Rear:=0;
  Length:=0;
end;

procedure TQueue.AddQ(D:byte);
begin
   if Length<=17999 then Length:=Length+1;
   Data[Front]:=D;
   Front:=(Front+1)mod 18000;
end;

function TQueue.DeQ():byte;
begin
   if Length<1 then exit;
   Length:=Length-1;
   result:=Data[Rear];
   Rear:=(Rear+1)mod 18000;
end;

function TQueue.ShowData():string;
var
  i,Index:integer;
begin
   for i:=0 to 18000-1 do
   begin
      Index:= (Front+i+18000) mod 18000;
      result:= result+inttohex(Data[Index],2);
      if i<17999 then result:= result+',';
   end;
end;

function TQueue.ISEmpty:boolean;
begin
   result:=(Length=0);
end;




procedure TECGScanPort.Execute;
var
  ConfigINI:tinifile;
begin
  ConfigINI:=tinifile.create(ExtractFileDir(application.ExeName)+'\Config.ini');
  cfg_Used := ConfigINI.ReadBool('ComdecECG','Used',true);
  cfg_AutoDect:= ConfigINI.ReadBool('ComdecECG','AutoDetect',true);
  cfg_ComPort:= ConfigINI.ReadInteger('ComdecECG','COM',11);
  ConfigINI.WriteBool('ComdecECG','Used',cfg_Used);
  ConfigINI.WriteBool('ComdecECG','AutoDetect',cfg_AutoDect);
  ConfigINI.WriteInteger('ComdecECG','COM',cfg_ComPort);

  DataQueue:=TQueue.Create;
  DataQueue.InitQ;

  ECGQueue:=TQueue.Create;
  ECGQueue.InitQ;

  self.Priority:= tpLower;
  ScanECG_Port();

  while true do
  begin
    sleep(3);
    application.ProcessMessages;
  end;
end;


procedure TECGScanPort.Comm1ReceiveData(Sender: TObject; Buffer: Pointer;
  BufferLength: Word);
var
  BUF:pchar;
  BINData:array of byte;
  Data,j,i:integer;
  DataIndex,CheckIndex:integer;
  ETime,Y,M,D,H,N:integer;
  TempData:integer;
begin
   ECGComIsOK:=true;
   BINData:=Buffer;
   BUF:=pchar(BINData);

   for i:=0 to BufferLength-1 do
     DataQueue.AddQ(BINData[i]);
end;


procedure TECGScanPort.ProcessData(out Chart:TChart;out SPO2:TEdit);
var
  i:integer;
  Len:integer;
  QData:byte;
begin
   while DataQueue.Length>0 do
   begin
      QData:=DataQueue.DeQ;
      //=========================================================ECG
      if (QData>=$fa) and (QData<$ff) then ECGDataNow:=false;
      if (QData=$ff) then ECGDataNow:=true;
      if (ECGDataNow=true) and (QData<$fa) then
      begin
         ECGQueue.AddQ(QData);
         ECGDataIndex:=(ECGDataIndex+1) mod 3000;
         Chart.Series[0].YValue[ECGDataIndex]:=QData;
         application.ProcessMessages;
      end;
      //=========================================================SPO2
      if (QData=$fe) then SPO2DataNow:=true;
      if (QData>=$fa) and (QData<=$ff) and (QData<>$fe) then SPO2DataNow:=false;
      if (SPO2DataNow=true) and (QData<$fa) then
        SPO2Value:=QData;
      //=========================================================SPO2 Check
      if (QData=$fb) then CheckSPO2Now:=true;
      if (QData>=$fa) and (QData<=$ff) and (QData<>$fb) then CheckSPO2Now:=false;
      if (CheckSPO2Now=true) and (QData<$fb) then
      begin
        if QData=0 then SPO2DataOK:=true else SPO2DataOK:=false;
      end;
      if (SPO2DataOK)and (SPO2Value<>0) then SPO2.Text:=inttostr(SPO2Value);
      //=========================================================
      if (QData>=$fa) and (QData<$ff) then ECGDataNow:=false;
      if (QData=$ff) then ECGDataNow:=true;
   end;
   application.ProcessMessages;
end;


function  TECGScanPort.PortIsAlive(ComNum:integer):boolean;
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

procedure TECGScanPort.ScanECG_Port();
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
      CommArray[i].ReadIntervalTimeout:=50;
      CommArray[i].BaudRate:=9600;
      CommArray[i].Tag:=ComList[i];
      CommArray[i].OnReceiveData:=Comm1ReceiveData;
      ComIsAlive[i]:=true;
      application.ProcessMessages;
      try
        ECGCom:=ComList[i];
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
    //ECGCom:=0;
    ECGComIsOK:=false;
    SPO2Value:=0;
   end;
end;

end.


