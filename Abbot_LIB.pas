unit Abbot_LIB;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, SPComm, StdCtrls, ExtCtrls,DateUtils,Registry,DelayLib,inifiles;

type
  TScanPort = class(TThread)
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
    DataLock:integer;
    EarseGMNow:boolean;
    TotalBUF:string;
    MeasureDisCount:String;

    ComPortCount:integer;
    ScanComIsComplete:boolean;
    CommArray:array[0..64] of TComm;
    ComList:array of integer;
    ComIsAlive:array of boolean;

    procedure ScanGM_Port();
    function  PortIsAlive(ComNum:integer):boolean;
    procedure Execute; override;
  end;

var AbbotPort:TScanPort;

implementation


procedure TScanPort.Execute;
var
  ConfigINI:tinifile;
begin
  ConfigINI:=tinifile.create(ExtractFileDir(application.ExeName)+'\Config.ini');
  cfg_Used := ConfigINI.ReadBool('Abbott','Used',true);
  cfg_AutoDect:= ConfigINI.ReadBool('Abbott','AutoDetect',true);
  cfg_ComPort:= ConfigINI.ReadInteger('Abbott','COM',1);
  ConfigINI.WriteBool('Abbott','Used',cfg_Used);
  ConfigINI.WriteBool('Abbott','AutoDetect',cfg_AutoDect);
  ConfigINI.WriteInteger('Abbott','COM',cfg_ComPort);

  self.Priority:= tpLower;
  while true do
  begin
    MeasureDisCount:='資料讀取中...';
    ScanGM_Port();
    //MeasureDisCount:='2';
    //while strtoint(MeasureDisCount)>0 do
    //begin
      Delay(1000);
    //  MeasureDisCount:=inttostr(strtoint(MeasureDisCount)-1);
    //end;
  end;
end;


procedure TScanPort.Comm1ReceiveData(Sender: TObject; Buffer: Pointer;BufferLength: Word);
var
  BUF:pchar;
  BINData:array of byte;
  i:integer;
begin
   BINData:=Buffer;
   BUF:=pchar(BINData);

   
   TotalBUF:=TotalBUF+BUF;

   if length(TotalBUF)>54 then
   begin
      if((TotalBUF[1]=#13)and(TotalBUF[2]=#10)and(TotalBUF[3]='X')and(TotalBUF[16]=#13)and(TotalBUF[17]=#10)
          and(TotalBUF[16]=#13)and(TotalBUF[17]=#10)
          and(TotalBUF[22]=#13)and(TotalBUF[23]=#10)
          and(TotalBUF[45]=#13)and(TotalBUF[46]=#10)) then
      begin
        if (TotalBUF[47]='L')and(TotalBUF[48]='O') then exit;
        if (TotalBUF[47]='H')and(TotalBUF[48]='I') then exit;
        GMValue:=(ord(TotalBUF[47])-$30)*100+(ord(TotalBUF[48])-$30)*10+(ord(TotalBUF[49])-$30);
        GMTime:= StrtoDatetime(formatdatetime('yy/mm/dd hh:nn:ss',now));
        GMCom:=TComm(Sender).Tag;
        GMComIsOK:=true;
        ScanComIsComplete:=true;
        //beep;
        DataLock:=1;
      end;
   end;

end;



function  TScanPort.PortIsAlive(ComNum:integer):boolean;
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

procedure TScanPort.ScanGM_Port();
var
  Data:pansichar;
  i,j,k:integer;
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
      CommArray[i].BaudRate:=19200;
      CommArray[i].Tag:=ComList[i];
      CommArray[i].ReadIntervalTimeout:=100;
      CommArray[i].OnReceiveData:=Comm1ReceiveData;
      ComIsAlive[i]:=true;
      application.ProcessMessages;
      try
        if PortIsAlive(CommArray[i].Tag) then CommArray[i].StartComm;
        Delay(500);
        TotalBUF:='';
        CommArray[i].WriteCommData('$xlog,1'#13#10,9);
        //DataLock:=0;
      except
        ComIsAlive[i]:=false;
      end;

      Delay(2500);
      //showmessage(TotalBUF);
   end;

   if ScanComIsComplete=false then
   begin
    GMCom:=0;
    GMComIsOK:=false;
    GMValue:=0;
   end;

end;

end.



{                                原有的
      if((TotalBUF[1]=#13)and(TotalBUF[2]=#10)and(TotalBUF[3]='X')and(TotalBUF[4]='C')and(TotalBUF[5]='G')and (length(TotalBUF)>46))then
      //if((TotalBUF[44]=#13)and(TotalBUF[45]=#10)and(TotalBUF[49]=#13)and(TotalBUF[50]=#10)) then
      begin
        if (TotalBUF[52]='L')and(TotalBUF[53]='O') then exit;
        if (TotalBUF[52]='H')and(TotalBUF[53]='I') then exit;
        GMValue:=(ord(TotalBUF[52])-$30)*100+(ord(TotalBUF[53])-$30)*10+(ord(TotalBUF[54])-$30);
        GMTime:= StrtoDatetime(formatdatetime('yy/mm/dd hh:nn:ss',now));
        GMCom:=TComm(Sender).Tag;
        GMComIsOK:=true;
        ScanComIsComplete:=true;
        //beep;
        DataLock:=1;
      end;

      if((TotalBUF[1]<>'x')and(TotalBUF[2]<>'0')and(TotalBUF[3]<>'0')and(TotalBUF[4]=#13)and(TotalBUF[5]=#10)) then
      begin
        if (TotalBUF[6]='L')and(TotalBUF[7]='O') then exit;
        if (TotalBUF[6]='H')and(TotalBUF[7]='I') then exit;

        GMValue:=(ord(TotalBUF[6])-$30)*100+(ord(TotalBUF[7])-$30)*10+(ord(TotalBUF[8])-$30);
        GMTime:= StrtoDatetime(formatdatetime('yy/mm/dd hh:nn:ss',now));
        GMCom:=TComm(Sender).Tag;
        GMComIsOK:=true;
        ScanComIsComplete:=true;
        //beep;
        DataLock:=1;
      end;
}
