unit BP_Lib;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, SPComm, StdCtrls, ExtCtrls,DateUtils,JvHidControllerClass,ShellAPI,DelayLib;

type
  TMicroLife = class(TThread)
  private
    MicroLifeHID: TJvHidDevice;
    ReceiveStr:string;
    CMDTimer:TTimer;
    HID: TJvHidDeviceController;
    DataBuf:array[0..32] of byte;
    Packet:array[0..32] of byte;
    DataIndex:integer; 
    procedure OnCMDTimer(Sender: TObject);
    procedure ShowRead(HidDev: TJvHidDevice; ReportID: Byte; const Data: Pointer; Size: Word);
    function HIDEnumerate(HidDev: TJvHidDevice;const Idx: Integer): Boolean;
    procedure HIDRemoval(HidDev: TJvHidDevice);
    procedure HIDArrival(HidDev: TJvHidDevice);
    procedure GetBPValue();
    procedure WriteData(Data:pchar;Len:integer);
    procedure WriteTimeToDevice();
  public
    BPIsLink:boolean;
    BP_Value_1:integer;
    BP_Value_2:integer;
    BP_Value_3:integer;
    BPTime:TDateTime;
    DataLock:boolean;
    procedure Execute; override;
    procedure StartMeasure();
    procedure StopMeasure();
  end;

var
  BPDevice:TMicroLife;
  IsRemove:boolean;  //確保蹦出視窗時將網後的USB插拔都無效化
  BP_Measure_errmsg:string;
  Measure_StartTimestamp:int64;
  WriteBuf:array[0..16]of byte;
implementation

uses unit1,msg;

procedure TMicroLife.WriteData(Data:pchar;Len:integer);
var
  BUF:array [0..8]of byte;
  Written: Cardinal;
  BUFIndex:integer;
  i,j:integer;
begin
  for i:=0 to (Len div 7) do
  begin
     BUF[0]:=0;
     BUFIndex:=0;
     for j:=0 to 6 do
     begin
        if(i*7+j)<Len then
        begin
          BUFIndex:=BUFIndex+1;
          BUF[j+2]:=ord(Data[i*7+j]);
        end;
     end;
     BUF[1]:=BUFIndex;
     try
        MicroLifeHID.WriteFile(BUF, 9, Written);
     except
     end;
  end;

end;

procedure TMicroLife.WriteTimeToDevice();
const
  MCMD_PCLink:array [0..3] of byte=($12,$16,$18,$21);
  MCMD_PCUnLink:array [0..3] of byte=($12,$16,$18,$20);
  MCMD_SetTime:array [0..3] of byte=($12,$16,$18,$27);
  MCMD_WEAKUP:array [0..4] of byte=($00,$00,$00,$00,$00);
  HexWord:array[0..15]of char=('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
var
  MEncodeDate:integer;
  MEncodeTime:integer;
  CheckSum:integer;
  MCMD_SetNowTime: array [0..15] of Byte;
  i:integer;
begin
  //喚醒機制要先進行
  WriteData(@MCMD_WEAKUP,5);
  Delay(500);
  WriteData(@MCMD_PCLink,4);
  Delay(500);
  WriteData(@MCMD_SetTime,4);
  Delay(500);
  MEncodeDate:=(DateUtils.YearOf(Now)-2000)+
             (DateUtils.DayOf(now)*100)+
             (DateUtils.MonthOf(now)*10000);
  MEncodeTime:=DateUtils.SecondOf(now)+
             (DateUtils.MinuteOf(now)*100)+
             (DateUtils.HourOf(now)*10000);
  
  
  for i:=0 to 5 do
  begin
    MCMD_SetNowTime[6-i-1]:=ord(HexWord[(MEncodeDate mod 10)]);
    MEncodeDate:=MEncodeDate div 10;
  end;

  MCMD_SetNowTime[6]:=$32;
  MCMD_SetNowTime[7]:=$30;
  
  for i:=13 downto 8 do
  begin
    MCMD_SetNowTime[i]:=ord(HexWord[(MEncodeTime mod 10)]);
    MEncodeTime:=MEncodeTime div 10;
  end;

  CheckSum:=0;
  for i:=0 to 13 do
    CheckSum:=CheckSum+MCMD_SetNowTime[i];

  CheckSum:=CheckSum mod 256;

  MCMD_SetNowTime[14]:=ord(HexWord[(CheckSum mod 16)]);
  MCMD_SetNowTime[15]:=ord(HexWord[(CheckSum shr 4)]);

  WriteData(@MCMD_SetNowTime,16);
  Delay(500);
  WriteData(@MCMD_PCUnLink,4);
  Delay(500);
end;

procedure TMicroLife.GetBPValue();
var
  i,j:integer;
  Part,PIndex:integer;
  HealthData,Y,M,D,H,N:integer;
  MicroLifeBuf:array[0..6]of byte;
begin
  PIndex:=0;
  for i:=0 to 3 do
  begin
    Part:=DataBuf[i*8]-240;
    if Part>7 then exit;
    for j:=1 to Part do
    begin
      Packet[PIndex]:=DataBuf[i*8+j];
      PIndex:=PIndex+1;
    end;
  end;
  for i:=0 to 6 do
  begin
     MicroLifeBuf[i]:=Packet[i+2];
  end;


  //======================過濾不合法資料==============
  if (((MicroLifeBuf[0]=69) and (MicroLifeBuf[1]=114)) or (MicroLifeBuf[0]=6)) then
  begin
    if((MicroLifeBuf[0]=69) and (MicroLifeBuf[1]=114))then
    begin
      BP_Measure_errmsg:='BP Er:'+char(MicroLifeBuf[2]+48);
      for i:=0 to length(DataBuf)-1 do DataBuf[i]:=0;
      for i:=0 to length(Packet)-1 do Packet[i]:=0;
      //StopMeasure;
    end;
    exit;
  end;

  DataLock:=true;
  //======================取出資料====================
  HealthData:=0;
  HealthData:=(MicroLifeBuf[0]*1000000)
                +(MicroLifeBuf[1]*1000)
                +(MicroLifeBuf[2]);
  BP_Value_1:= HealthData div 1000000;
  BP_Value_2:= (HealthData div 1000) mod 1000;
  BP_Value_3:= HealthData mod 1000;
  {
  //======================校時==========
  if (BP_Value_1<>0)and(BP_Value_2<>0)and(BP_Value_3<>0) then
  begin
    WriteTimeToDevice();
    //========================取出時間====================
    Y:=(MicroLifeBuf[3]shr 4)+(16*(MicroLifeBuf[6]shr 7));
    M:=MicroLifeBuf[3] mod 16;
    D:=MicroLifeBuf[4] shr 3;
    H:=((MicroLifeBuf[4] mod 8)*4)+(MicroLifeBuf[5] shr 6);
    N:=MicroLifeBuf[5] mod 64;
    BPTime:=StrtoDatetime(format('%d/%d/%d %d:%d:00',[Y,M,D,H,N]));
  end;
  }
  DataLock:=false;
end;


procedure TMicroLife.Execute;
begin
  self.Priority:= tpLower;
  IsRemove:=false;

  CMDTimer:=TTimer.Create(nil);
  CMDTimer.Interval:=500;
  CMDTimer.Enabled:=false;
  CMDTimer.OnTimer:=OnCMDTimer;



  HID:=TJvHidDeviceController.Create(nil);
  HID.OnArrival:=HIDArrival;
  HID.OnEnumerate:=HIDEnumerate;
  HID.OnRemoval:=HIDRemoval;
  HID.Enumerate;

   while true do
   begin
      Delay(100);
      application.ProcessMessages;
   end;
end;

procedure TMicroLife.OnCMDTimer(Sender: TObject);
var i:integer;
begin
  CMDTimer.Enabled:=false;
  GetBPValue();
  DataIndex:=0;
  for i:=0 to length(DataBuf)-1 do
    DataBuf[i]:=0;
end;

function TMicroLife.HIDEnumerate(HidDev: TJvHidDevice;const Idx: Integer): Boolean;
begin
  if IsRemove=true then exit;
  if(HidDev.Attributes.ProductID=$5500)and(HidDev.Attributes.VendorID=$04B4) then
  begin
    BPIsLink:=true;
    BP_Value_1:=0;
    BP_Value_2:=0;
    BP_Value_3:=0;
    HID.CheckOutByIndex(MicroLifeHID, Idx);
    try
      MicroLifeHID.OnData:=ShowRead;
      WriteTimeToDevice(); //一插上即校時
    except
      //HID.Enumerate;
    end;
  end;
  Result := True;
end;

procedure TMicroLife.ShowRead(HidDev: TJvHidDevice; ReportID: Byte; const Data: Pointer; Size: Word);
var
  I: Integer;
begin
  if CMDTimer.Enabled=false then
  begin
    CMDTimer.Enabled:=true;
    DataIndex:=0;
    for i:=0 to length(DataBuf)-1 do
      DataBuf[i]:=0;
  end;
  for I := 0 to Size - 1 do
  begin
    DataBuf[DataIndex]:=Cardinal(PChar(Data)[I]);
    DataIndex:=DataIndex+1;
  end;

end;



procedure TMicroLife.HIDRemoval(HidDev: TJvHidDevice);
begin
  if IsRemove=true then exit;
  if(HidDev.Attributes.ProductID=$5500)and(HidDev.Attributes.VendorID=$04B4) then
  begin
    IsRemove:=true;
    Application.Title := '遠東醫電裝置監控服務器';
    BPIsLink:=false;
    MicroLifeHID:= nil;
    Hid.Enumerate;
    ReleaseMutex(Mutex);
    application.ProcessMessages;
    //showmessage('偵測到血壓計被拔除'+#13#10+'由於穩定性考量，本程式將自動關閉，請按確定繼續'+#13#10+'請重新執行本程式');
    //showmessage('偵測到血壓計被拔除'+#13#10+'由於穩定性考量，本程式將自動重啟，請按確定繼續'+#13#10+'若沒自動重啟，請手動執行本程式');
    Alert.ShowModal;

    //application.ProcessMessages;
    WinExec('command.com /c taskkill /F /T /IM FEMET_ClientWeb.exe',sw_Hide);
    application.ProcessMessages;
    WinExec('taskkill /F /T /IM FEMET_ClientWeb.exe',sw_Hide);
    application.ProcessMessages;
    Form1.KillallThread;
    sleep(1000);
    ShellExecute(0,'open',pchar('"'+ExtractFileDir(application.ExeName)+'\FEMET_ServicePlugin.exe"'),'',0,0);
    application.ProcessMessages;
    Form1.CoolTrayIcon1.Enabled:=false;
    Form1.close;
  end;
end;

procedure TMicroLife.HIDArrival(HidDev: TJvHidDevice);
begin
  if IsRemove=true then exit;
  HID.Enumerate;
end;

procedure TMicroLife.StartMeasure();
const
  MCMD_WEAKUP:array [0..4] of byte=($00,$00,$00,$00,$00);
  MCMD_StartMeasure:array [0..3] of byte=($12,$16,$18,$25);
  MCMD_PCLink:array [0..3] of byte=($12,$16,$18,$21);
  MCMD_PCUnLink:array [0..3] of byte=($12,$16,$18,$20);
var
  i:integer;
begin
  //self.Suspend;
  //喚醒機制要先進行
  WriteData(@MCMD_WEAKUP,5);
  Delay(500);
  WriteData(@MCMD_PCLink,4);
  Delay(500);
  WriteData(@MCMD_StartMeasure,4);
  Delay(500);
  //WriteData(@MCMD_PCUnLink,4);
  //Delay(500);

  BP_Value_1:=0;
  BP_Value_2:=0;
  BP_Value_3:=0;
  for i:=0 to length(DataBuf)-1 do
    DataBuf[i]:=0;
end;

procedure TMicroLife.StopMeasure();
const
  MCMD_WEAKUP:array [0..4] of byte=($00,$00,$00,$00,$00);
  MCMD_StopMeasure:array [0..3] of byte=($12,$16,$18,$19);
  MCMD_PCLink:array [0..3] of byte=($12,$16,$18,$21);
  MCMD_PCUnLink:array [0..3] of byte=($12,$16,$18,$20);
begin
  WriteData(@MCMD_WEAKUP,5);
  Delay(500);
  WriteData(@MCMD_PCLink,4);
  Delay(500);
  WriteData(@MCMD_StopMeasure,4);
  Delay(500);
  //WriteData(@MCMD_PCUnLink,4);
  //Delay(500);
end;

end.


{
procedure TMicroLife.GetBPValue();
var
  i,j:integer;
  Part,PIndex:integer;
  HealthData,Y,M,D,H,N:integer;
  MicroLifeBuf:array[0..6]of byte;
begin
  PIndex:=0;
  for i:=0 to 3 do
  begin
    Part:=DataBuf[i*8]-240;
    if Part>7 then exit;
    for j:=1 to Part do
    begin
      Packet[PIndex]:=DataBuf[i*8+j];
      PIndex:=PIndex+1;
    end;
  end;
  for i:=0 to 6 do
  begin
     MicroLifeBuf[i]:=Packet[i+2];
  end;


  //======================過濾不合法資料==============
  if (((MicroLifeBuf[0]=69) and (MicroLifeBuf[1]=114)) or (MicroLifeBuf[0]=6)) then
  begin
    exit;
  end;

  DataLock:=true;
  //======================取出資料====================
  HealthData:=0;
  HealthData:=(MicroLifeBuf[0]*1000000)
                +(MicroLifeBuf[1]*1000)
                +(MicroLifeBuf[2]);
  BP_Value_1:= HealthData div 1000000;
  BP_Value_2:= (HealthData div 1000) mod 1000;
  BP_Value_3:= HealthData mod 1000;
  //======================更新時間的特殊動作==========
  if (BP_Value_1=69)and(BP_Value_2=114)and(BP_Value_3<20)then
  begin
     BP_Value_1:=0;
     BP_Value_2:=0;
     BP_Value_3:=0;
  end
  else if (BP_Value_1<>0)and(BP_Value_2<>0)and(BP_Value_3<>0) then
  begin
    WriteTimeToDevice();
    //========================取出時間====================
    Y:=(MicroLifeBuf[3]shr 4)+(16*(MicroLifeBuf[6]shr 7));
    M:=MicroLifeBuf[3] mod 16;
    D:=MicroLifeBuf[4] shr 3;
    H:=((MicroLifeBuf[4] mod 8)*4)+(MicroLifeBuf[5] shr 6);
    N:=MicroLifeBuf[5] mod 64;
    BPTime:=StrtoDatetime(format('%d/%d/%d %d:%d:00',[Y,M,D,H,N]));
  end;
  DataLock:=false;
end;
}

