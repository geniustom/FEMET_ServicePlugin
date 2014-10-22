unit OmronBP_Lib;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, SPComm, StdCtrls, ExtCtrls,DateUtils,JvHidControllerClass,ShellAPI,DelayLib;

type
  sBpData=record
    sys:Integer;
    dia:Integer;
    pulse:Integer;
    ms_number:Integer;
    ms_cnt:Integer;
    ms_setcnt:Integer;
    memo:Integer;
    move_flg:Integer;
    fpulse_flg:Integer;
    bpkbn:Integer;     //0:No division / 1:After it gets up / 2:Normal / 3:Before retiring
    serial:Integer;    //Serial data number
    userkbn:Integer;   //User division(0:User A / 1:User B / 2:For one user)
    bp_date:array[0..10] of byte;
    bp_time:array[0..8] of byte;
  end;

  TOmronBP = class(TThread)
  private
    CMDTimer:TTimer;
    procedure GetLastMeasure();
    procedure DelAll();
    procedure GetAllDevice();
  public
    BPIsLink:boolean;
    BP_Value_1:integer;
    BP_Value_2:integer;
    BP_Value_3:integer;
    BPTime:TDateTime;
    DataLock:boolean;
    procedure Execute; override;
    procedure OnCMDTimer(Sender: TObject);
    procedure CanFetchData();
  end;

  Function Occ_GetDeviceList(mode:Integer;modellist:pointer;conlist:pointer):Integer;cdecl;far;external 'occLib.dll';
  
  Function Occ_Init(mode:Integer):Integer;cdecl;far;external 'occLib.dll';
  Function Occ_SetConnectDeviceName(modellist:pchar):Integer;cdecl;far;external 'occLib.dll';
  Function Occ_OpenDevice():Integer;cdecl;far;external 'occLib.dll';
  Function Occ_SetUserKbn(userkbn:Integer):Integer;cdecl;far;external 'occLib.dll';
  Function Occ_StartDownload():Integer;cdecl;far;external 'occLib.dll';
  Function Occ_GetDownloadStatus():Integer;cdecl;far;external 'occLib.dll';
  Function Occ_GetErrStatus():Integer;cdecl;far;external 'occLib.dll';
  Function Occ_GetStatus():Integer;cdecl;far;external 'occLib.dll';

  Function Occ_GetDataCnt():Integer;cdecl;far;external 'occLib.dll';
  Function Occ_SetDataCurrent(no:Integer):Integer;cdecl;far;external 'occLib.dll';
  Function Occ_GetBpData(out bpdata:sBpData):Integer;cdecl;far;external 'occLib.dll';

  Function Occ_End():Integer;cdecl;far;external 'occLib.dll';
  Function Occ_DataClear():Integer;cdecl;far;external 'occLib.dll';

var
  OmronBPDevice:TOmronBP;


implementation

var
  Omodellist:array[0..1000] of char;
  Oconlist:array[0..1000] of char;
  bpdata:sBpData;

procedure TOmronBP.CanFetchData();
begin
   CMDTimer.Enabled:=true;
end;


procedure TOmronBP.GetLastMeasure();
var
  ret:integer;
  data_cnt:integer;
  ErrNo:integer;
  i:integer;
begin
  DataLock:=true;
  BPIsLink:=false;
  BP_Value_1:=0;
  BP_Value_2:=0;
  BP_Value_3:=0;

  ret:=Occ_Init(0);
  ret:=Occ_SetConnectDeviceName(pchar('HEM-7301-IT'));

  ret:=-1;

  while ret<>0 do
  begin
    ret:=Occ_OpenDevice();
    sleep(50);
  end;
  if ret<>0 then exit;
  BPIsLink:=true;
  
  ret:=Occ_SetUserKbn(0);
  Occ_StartDownload();

  while Occ_GetStatus()=1 do
  begin
    sleep(100);
    ret:=Occ_GetDownloadStatus();
  end;

  data_cnt:= Occ_GetDataCnt();
  if data_cnt=0 then
  begin
    DataLock:=false;
    exit;
  end;

{
  for i:= 0 to data_cnt-1 do
  begin
    Occ_SetDataCurrent(i);
    Occ_GetBpData(bpdata);
    memo1.Lines.Add(inttostr(bpdata.sys)+','+inttostr(bpdata.dia)+','+inttostr(bpdata.pulse));
  end;
}

  Occ_SetDataCurrent(data_cnt-1);
  Occ_GetBpData(bpdata);

  BP_Value_1:=bpdata.sys;
  BP_Value_2:=bpdata.dia;
  BP_Value_3:=bpdata.pulse;
  BPTime:=now;
  //form1.memo1.Lines.Add(inttostr(bpdata.sys)+','+inttostr(bpdata.dia)+','+inttostr(bpdata.pulse));
  Occ_End();
  DataLock:=false;
end;


procedure TOmronBP.GetAllDevice();
var
  ret:integer;
begin
  //Occ_Init(0);
  //Occ_OpenDevice();
  ret:=Occ_GetDeviceList(0,@Omodellist,@Oconlist);
  //showmessage(inttostr(ret));
  showmessage(Omodellist);
  showmessage(Oconlist);
end;

procedure TOmronBP.DelAll();
var
  ret:integer;
begin
{
  ret:=Occ_Init(0);
  ret:=Occ_SetConnectDeviceName(pchar('HEM-7301-IT'));

  ret:=-1;
  while ret<>0 do
  begin
    ret:=Occ_OpenDevice();
    sleep(50);
  end;
}
  //ret:=Occ_Init(0);
  ret:=Occ_SetConnectDeviceName(pchar('HEM-7301-IT'));
  ret:=Occ_OpenDevice();
  ret:=Occ_DataClear();
  ret:=Occ_End();
end;


procedure TOmronBP.OnCMDTimer(Sender: TObject);
var i:integer;
begin
  CMDTimer.Enabled:=false;
  GetLastMeasure();
  DelAll();
end;

procedure TOmronBP.Execute;
begin
  self.Priority:= tpLower;


  CMDTimer:=TTimer.Create(nil);
  CMDTimer.Interval:=1;
  CMDTimer.Enabled:=false;
  CMDTimer.OnTimer:=OnCMDTimer;
  CMDTimer.Enabled:=true;

   while true do
   begin
      Delay(100);
      application.ProcessMessages;
   end;
end;

end.
