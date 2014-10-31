unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls,
  
  BarCode_Lib,SimCard_Lib,Abbot_LIB,BP_Lib,GM_LIB,Scales_LIB,SPO2_Lib,ECG_Lib,OmronBP_Lib,

  ExtCtrls, PCSCConnector,SPComm, ScktComp,XML_Lib, OleServer,  ComCtrls,ShellApi,
  CoolTrayIcon, ImgList, Menus, Buttons,inifiles,printers, TeEngine,
  Series, TeeProcs, Chart, TeeFunci;

type
  TForm1 = class(TForm)
    Timer1: TTimer;
    GroupBox1: TGroupBox;
    Memo1: TMemo;
    ReaderOK: TCheckBox;
    ReadIsBusy: TCheckBox;
    CardOK: TCheckBox;
    GroupBox2: TGroupBox;
    BarCodeMEMO: TMemo;
    Label1: TLabel;
    Label2: TLabel;
    SimCardMemo: TMemo;
    G_2: TGroupBox;
    Label3: TLabel;
    Label4: TLabel;
    BP_SYS: TEdit;
    Label5: TLabel;
    BP_DIA: TEdit;
    BP_HR: TEdit;
    G_5: TGroupBox;
    Label9: TLabel;
    BP_TIME: TEdit;
    Label7: TLabel;
    Label8: TLabel;
    StatusBar1: TStatusBar;
    BP_LINK: TCheckBox;
    ServerSocket1: TServerSocket;
    GroupBox5: TGroupBox;
    BARXMLPATH: TEdit;
    Label6: TLabel;
    Label10: TLabel;
    SIMXMLPATH: TEdit;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    N2: TMenuItem;
    CoolTrayIcon1: TCoolTrayIcon;
    GroupBox6: TGroupBox;
    GroupBox7: TGroupBox;
    BarStatus: TMemo;
    SimStatus: TMemo;
    GroupBox8: TGroupBox;
    Memo2: TMemo;
    GM_Value: TEdit;
    GM_Time: TEdit;
    GM_LINK: TCheckBox;
    Button2: TButton;
    Button1: TButton;
    Timer2: TTimer;
    GroupBox9: TGroupBox;
    PrintSel: TComboBox;
    LOGO: TImage;
    G_1: TGroupBox;
    Label11: TLabel;
    SC_Value: TEdit;
    SC_LINK: TCheckBox;
    G_3: TGroupBox;
    Label12: TLabel;
    SPO2_Value: TEdit;
    SPO2_LINK: TCheckBox;
    G_4: TGroupBox;
    Label13: TLabel;
    Label14: TLabel;
    WAGM_Value: TEdit;
    WAGM_Time: TEdit;
    WAGM_LINK: TCheckBox;
    GM_COMName: TEdit;
    SPO2_COMName: TEdit;
    WAGM_COMName: TEdit;
    SC_COMName: TEdit;
    G_ECG: TGroupBox;
    ECG_Link: TCheckBox;
    ECG_COMName: TEdit;
    Label15: TLabel;
    ECG_SPO2: TEdit;
    ECG_Chart: TChart;
    Series1: TFastLineSeries;
    Timer3: TTimer;
    G_6: TGroupBox;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    OmronBP_SYS: TEdit;
    OmronBP_DIA: TEdit;
    OmronBP_HR: TEdit;
    OmronBP_TIME: TEdit;
    OmronBP_LINK: TCheckBox;
    Button3: TSpeedButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Timer1Timer(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure N2Click(Sender: TObject);
    procedure ServerSocket1ClientRead(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure CoolTrayIcon1DblClick(Sender: TObject);
    procedure EraseSCClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure PrintSelChange(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Timer3Timer(Sender: TObject);
    procedure ServerSocket1ClientError(Sender: TObject;
      Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
      var ErrorCode: Integer);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    procedure ReceiveKey(var Msg: TMessage); message WM_USER + 1678;
  end;

var
  Form1: TForm1;
  CardReader:THCardReader;
  cfg_UserMode:boolean;
  cfg_FootText,cfg_FootText2:string;
  cfg_PrintID:integer;
  SocketBusyFlag:boolean;
  SYS,DIA,HR,GM,MEATIME:string;
implementation

{$R *.dfm}


procedure BarCodeTrigger();
var
  BarRec:XMLRecord;
begin
  BarRec.IDNO:=BarCode.IDNo;
  BarRec.GwDateTime:=formatdatetime('yyyy/mm/dd hh:nn:ss',now);
  if MEATIME<>'' then
    BarRec.BP_MeaDateTime:=formatdatetime('yyyy/mm/dd hh:nn:ss',strtodatetime(MEATIME));
  if form1.GM_TIME.Text<>'' then
    BarRec.Gm_MeaDateTime:=formatdatetime('yyyy/mm/dd hh:nn:ss',strtodatetime(form1.GM_TIME.Text));

  BarRec.BP_SYS:=SYS;
  BarRec.BP_DIA:=DIA;
  BarRec.BP_HR:=HR;
  BarRec.GLU_Normal:=GM;
  if cfg_UserMode=true then
    form1.BARXMLPATH.Text:=CreateTXT('BarcodeReader',BarRec)
  else
    form1.BARXMLPATH.Text:=CreateXML('BarcodeReader',BarRec);
end;

procedure SimCardTrigger();  //0拔 1插
var
  SimRec:XMLRecord;
begin
  if CardReader.InsertState=0 then
  begin
    SimRec.IDNO:=form1.SimCardMemo.Text;
    SimRec.GwDateTime:=formatdatetime('yyyy/mm/dd hh:nn:ss',now);
    if MEATIME<>'' then
      SimRec.BP_MeaDateTime:=formatdatetime('yyyy/mm/dd hh:nn:ss',strtodatetime(MEATIME));
    if form1.GM_TIME.Text<>'' then
      SimRec.GM_MeaDateTime:=formatdatetime('yyyy/mm/dd hh:nn:ss',strtodatetime(form1.GM_TIME.Text));

    SimRec.BP_SYS:=SYS;
    SimRec.BP_DIA:=DIA;
    SimRec.BP_HR:=HR;
    SimRec.GLU_Normal:=GM;
    if cfg_UserMode=true then
      form1.SIMXMLPATH.Text:=CreateTXT('SIMReader',SimRec)
    else
      form1.SIMXMLPATH.Text:=CreateXML('SIMReader',SimRec);
  end;
  if CardReader.InsertState=1 then
  begin
     form1.SIMXMLPATH.Text:='';
  end;
end;

procedure TForm1.ReceiveKey(var Msg: TMessage);
begin
  BarCodeMEMO.Text:=BarCode.ReceiveKey(Msg,@BarCodeTrigger);
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  StopHook;
  WinExec('command.com /c taskkill /F /T /IM FEMET_ClientWeb.exe',sw_Hide);
  WinExec('taskkill /F /T /IM FEMET_ClientWeb.exe',sw_Hide);
end;

{
  BP_Link
  SC_Link
  SIM_Link
  BAR_Link
  Trigger_Flag
  ID_No
  XML-Path
}
function PacketData(TriggerType:integer):string;
var Pack:TstringList;
begin
   Pack:=TstringList.Create;
   Pack.Delimiter:=',';
   Pack.Add(booltostr(form1.BP_LINK.Checked,true));      //BP_Link
   Pack.Add(booltostr(form1.GM_LINK.Checked,true));      //GM_Link
   Pack.Add(booltostr(form1.ReaderOK.Checked,true));     //SIM_Link
   Pack.Add(booltostr(true,true));                       //BAR_Link
   if TriggerType=0 then
     Pack.Add(booltostr(form1.BARXMLPATH.text<>'',true)) //Trigger_Flag
   else
     Pack.Add(booltostr(form1.SIMXMLPATH.text<>'',true));

   if TriggerType=0 then
     Pack.Add(form1.BarCodeMEMO.Text)               //ID_No
   else
     Pack.Add(form1.SimCardMemo.Text);

   if TriggerType=0 then
     Pack.Add(form1.BARXMLPATH.Text)               //XML-Path
   else
     Pack.Add(form1.SIMXMLPATH.Text);

   result:=Pack.DelimitedText;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var i:integer;
begin
  with CardReader.CardRecord do
  begin
    Memo1.Lines.Clear;
    Memo1.Text:='姓　　名：' + HolderName+#13#10+
                '身分證號：' + IDN+#13#10+
                '生　　日：' + BirthDate+#13#10+
                '性　　別：' + Sex;
    SimCardMemo.Text:= CardReader.ID_NO;
  end;
  ReaderOK.Checked:=CardReader.ReaderIsOK;
  CardOK.Checked:=CardReader.CardIsOK;
  ReadIsBusy.Checked:=CardReader.CardIsRemove;

//========================================================上準體重
if G_1.Visible then
begin
  SC_LINK.Checked:=SCPort.SCComIsOK;
  if (SC_LINK.Checked) then
  begin
    SC_COMName.Text:= 'COM'+inttostr(SCPort.SCCom);
    if (SCPort.SCValue<>0) and (SCPort.SCTime<>0) then
    begin
      SC_Value.Text:=format('%2.1f',[SCPort.SCValue]);
    end;
  end
  else
  begin
    SC_COMName.Text:='';
    SC_Value.Text:='';
  end;
end;
//========================================================康定血氧
if G_3.Visible then
begin
  SPO2_LINK.Checked:=SPO2Port.SPO2ComIsOK;
  if (SPO2_LINK.Checked) then
  begin
    SPO2_COMName.Text:= 'COM'+inttostr(SPO2Port.SPO2Com);
    if (SPO2Port.SPO2Value<>0) and (SPO2Port.SPO2Time<>0) then
    begin
      SPO2_Value.Text:=format('%2.1f',[SPO2Port.SPO2Value]);
    end;
  end
  else
  begin
    SPO2_COMName.Text:='';
    SPO2_Value.Text:='';
  end;
end;
//========================================================百略血壓
if G_2.Visible then
begin
  BP_LINK.Checked:= BPDevice.BPIsLink;
  if (BP_LINK.Checked)and(BPDevice.BP_Value_1<>0)and(BPDevice.DataLock=false)  then
  begin
    BP_SYS.Text:=inttostr(BPDevice.BP_Value_1);
    BP_DIA.Text:=inttostr(BPDevice.BP_Value_2);
    BP_HR.Text:=inttostr(BPDevice.BP_Value_3);
    BP_TIME.Text:=FormatDatetime('yy/mm/dd hh:nn',BPDevice.BPTime);
  end
  else
  begin
    BP_SYS.Text:='';
    BP_DIA.Text:='';
    BP_HR.Text:='';
    BP_TIME.Text:='';
  end;
end;
//======================================================華廣血糖
if G_4.Visible then
begin
  WAGM_LINK.Checked:=GMPort.GMComIsOK;
  if (WAGM_LINK.Checked) then
  begin
    WAGM_COMName.Text:= 'COM'+inttostr(GMPort.GMCom);
    if (GMPort.GMValue<>0) and (GMPort.GMTime<>0) then
    begin
      WAGM_Value.Text:=format('%2d',[GMPort.GMValue]);
      WAGM_Time.Text:=formatDatetime('yy/mm/dd hh:nn',GMPort.GMTime);
    end;
  end
  else
  begin
    WAGM_COMName.Text:='';
    WAGM_Value.Text:='';
    WAGM_Time.Text:='';
  end;
end;
//======================================================亞培血糖
if G_5.Visible then
begin
  GM_LINK.Checked:=AbbotPort.GMComIsOK;
  //GM_Discount.Text:=AbbotPort.MeasureDisCount;
  if (GM_LINK.Checked) then
  begin
    GM_COMName.Text:= 'COM'+inttostr(AbbotPort.GMCom);
    if (AbbotPort.GMValue<>0) and (AbbotPort.GMTime<>0) then
    begin
      GM_Value.Text:=format('%2d',[AbbotPort.GMValue]);
      GM_Time.Text:=formatDatetime('yy/mm/dd hh:nn',AbbotPort.GMTime);
    end;
  end
  else
  begin
    GM_COMName.Text:='';
    GM_Value.Text:='';
    GM_Time.Text:='';
  end;
end;
  //========================================================康定ECG
  if G_ECG.Visible then
  begin
    ECG_Link.Checked:=ECGPort.ECGComIsOK;
    if ECGPort.ECGComIsOK then
    begin
      ECG_COMName.Text:= 'COM'+inttostr(ECGPort.ECGCom);
      ECGPort.ProcessData(ECG_Chart,ECG_SPO2);
      ECG_Chart.Refresh;
    end;
  end;
//========================================================OMRON血壓
if G_6.Visible then
begin
  OmronBP_LINK.Checked:= OmronBPDevice.BPIsLink;
  if (OmronBP_LINK.Checked)and(OmronBPDevice.BP_Value_1<>0)and(OmronBPDevice.DataLock=false)  then
  begin
    OmronBP_SYS.Text:=inttostr(OmronBPDevice.BP_Value_1);
    OmronBP_DIA.Text:=inttostr(OmronBPDevice.BP_Value_2);
    OmronBP_HR.Text:=inttostr(OmronBPDevice.BP_Value_3);
    OmronBP_TIME.Text:=FormatDatetime('yy/mm/dd hh:nn',OmronBPDevice.BPTime);
  end
  else
  begin
    OmronBP_SYS.Text:='';
    OmronBP_DIA.Text:='';
    OmronBP_HR.Text:='';
    OmronBP_TIME.Text:='';
  end;
end;
//========================================================
  BarStatus.Lines.Delimiter:=',';
  SimStatus.Lines.Delimiter:=',';

  BarStatus.Lines.DelimitedText:=PacketData(0);
  SimStatus.Lines.DelimitedText:=PacketData(1);


  if G_6.Visible then
  begin
     SYS:=OmronBP_SYS.Text;
     DIA:=OmronBP_DIA.Text;
     HR:=OmronBP_HR.Text;
     MEATIME:= OmronBP_TIME.Text;
  end;
  if G_2.Visible then
  begin
     SYS:=BP_SYS.Text;
     DIA:=BP_DIA.Text;
     HR:=BP_HR.Text;
     MEATIME:=BP_TIME.Text;
  end;
  if G_4.Visible then
  begin
     GM:= WAGM_Value.Text;
  end;
  if G_5.Visible then
  begin
     GM:= GM_Value.Text;
  end;
end;

procedure TForm1.N1Click(Sender: TObject);
begin
  CoolTrayIcon1.ShowMainForm;
end;

procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if CoolTrayIcon1.Enabled=true then
  begin
    CanClose:=False;
    CoolTrayIcon1.HideMainForm;
  end;
end;

procedure TForm1.N2Click(Sender: TObject);
begin
  CoolTrayIcon1.Enabled:=false;
  Form1.close;
end;




procedure TForm1.ServerSocket1ClientRead(Sender: TObject;Socket: TCustomWinSocket);
var
Packet:string;
VitalData:TStringList;
begin
//   if SocketBusyFlag=true then exit;
//   SocketBusyFlag:=true;

   Packet:=Socket.ReceiveText;
   if pos('GETBAR',Packet)>0 then
   begin
      Socket.SendText(PacketData(0));
   end;
   if pos('GETSIM',Packet)>0 then
   begin
      Socket.SendText(PacketData(1));
   end;
   if pos('RESETBAR',Packet)>0 then
   begin
      BPDevice.BP_Value_1:=0;
      BPDevice.BP_Value_2:=0;
      BPDevice.BP_Value_3:=0;
      BPDevice.BPTime:=now;
      AbbotPort.GMValue:=0;
      AbbotPort.GMTime:=0;
      GM_Value.Text:='';
      GM_Time.Text:='';
      WAGM_Value.Text:='';
      WAGM_Time.Text:='';
      SC_Value.TEXT:='';
      SPO2_Value.TEXT:='';
      ECG_SPO2.Text:='';
      BarCodeMEMO.Text:='';
      BARXMLPATH.Text:='';
      Socket.SendText('OK');
   end;
   if pos('RESETSIM',Packet)>0 then
   begin
      BPDevice.BP_Value_1:=0;
      BPDevice.BP_Value_2:=0;
      BPDevice.BP_Value_3:=0;
      BPDevice.BPTime:=now;
      AbbotPort.GMValue:=0;
      AbbotPort.GMTime:=0;
      GM_Value.Text:='';
      GM_Time.Text:='';
      WAGM_Value.Text:='';
      WAGM_Time.Text:='';
      SC_Value.TEXT:='';
      SPO2_Value.TEXT:='';
      CardReader.ID_NO:='';
      SIMXMLPATH.Text:='';
      Socket.SendText('OK');
   end;

   if pos('GetVital',Packet)>0 then
   begin
      VitalData:=TStringList.Create;
      VitalData.Delimiter:=',';
      VitalData.Add(inttostr(BPDevice.BP_Value_1));
      VitalData.Add(inttostr(BPDevice.BP_Value_2));
      VitalData.Add(inttostr(BPDevice.BP_Value_3));
      VitalData.Add(GM_Value.TEXT);
      VitalData.Add(WAGM_Value.TEXT);
      VitalData.Add(SC_Value.TEXT);
      VitalData.Add(SPO2_Value.TEXT);
      VitalData.Add(ECG_SPO2.TEXT);
      //VitalData.Add(ECGQueue.ShowData);
      Socket.SendText(VitalData.DelimitedText);
   end;

//   SocketBusyFlag:=false;
end;

procedure TForm1.CoolTrayIcon1DblClick(Sender: TObject);
begin
   CoolTrayIcon1.ShowMainForm;
end;

procedure TForm1.EraseSCClick(Sender: TObject);
var
  ConfigINI:tinifile;
begin
//===========================================================
  ConfigINI:=tinifile.create(ExtractFileDir(application.ExeName)+'\Config.ini');
//===========================================================
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  PageWidth:integer;
  i:integer;
  R: TRect;

begin
  Button1.Enabled:=false;
  PageWidth:=800;

  //for i:=0 to Printer.Printers.Count-1 do
  //begin
    //if (pos('Prowill',Printer.Printers.Strings[i])>=0) or
    //   (pos('3250II',Printer.Printers.Strings[i])>=0) then
    //begin
      Printer.PrinterIndex := PrintSel.ItemIndex;
      Printer.Orientation := poPortrait;//直  poLandscape;    //橫
      Printer.BeginDoc; // ?定打印?容
      with Printer do
      begin
        //R := Rect(0, 800, LOGO.Picture.Width,LOGO.Picture.Height+800);
        //Canvas.StretchDraw(R, LOGO.Picture.Graphic);

        // Set up a medium sized font
        Canvas.Font.Color := clBlack;
        Canvas.Font.Style:=[fsBold];

        // Write out
        Canvas.Font.Size   := 24;
        Canvas.TextOut(150,  0, '檢測數據');

        // Write out
        Canvas.Font.Name:='微軟正黑體';
        Canvas.Font.Size   := 10;
        Canvas.TextOut(50,  100, formatdatetime('檢測日期：yyyy/mm/dd  hh:nn',now));

        // Underline this page number
        Canvas.MoveTo(40,150);
        Canvas.LineTo(Printer.PageWidth-20,150);
     
        Canvas.TextOut(50,  200, format('您的血壓　收縮壓： %s mm/Hg',[SYS]));
        Canvas.TextOut(50,  250, format('您的血壓　舒張壓： %s mm/Hg',[DIA]));
        Canvas.TextOut(50,  300, format('您的心跳　　　　： %s beats/min',[HR]));
        Canvas.TextOut(50,  350, format('您的血糖　　　　： %s mg/dL',[GM_Value.Text]));

        // Underline this page number
        Canvas.MoveTo(40,400);
        Canvas.LineTo(Printer.PageWidth-20,400);

        Canvas.TextOut(50,  450, '標準血壓　收縮壓： 120 mm/Hg');
        Canvas.TextOut(50,  500, '標準血壓　舒張壓： 80 mm/Hg');
        Canvas.TextOut(50,  550, '標準心跳　　　　： 60~100 beats/min');
        Canvas.TextOut(50,  600, '標準血糖　　　　： 80~120 mg/dL');

        // Underline this page number
        Canvas.MoveTo(40,650);
        Canvas.LineTo(Printer.PageWidth-20,650);

        Canvas.TextOut(50,  700, cfg_FootText);
        Canvas.TextOut(50,  750, cfg_FootText2);
      end;
    //end;
  //end;
  Printer.EndDoc;
  Button1.Enabled:=true;
end;

procedure TForm1.Timer2Timer(Sender: TObject);
begin
  if cfg_UserMode=true then
  begin
     GroupBox6.Visible:=false;
     GroupBox7.Visible:=false;
     GroupBox8.Visible:=false;
     CoolTrayIcon1.ShowMainForm;
     CoolTrayIcon1.Enabled:=false;
     CoolTrayIcon1.IconVisible:=false;
     button1.Visible:=true;
     button2.Visible:=true;
     button3.Visible:=true;
  end
  else
  begin
     button1.Visible:=false;
     button2.Visible:=false;
     button3.Visible:=false;
     GroupBox9.Visible:=false;
  end;
end;

procedure TForm1.PrintSelChange(Sender: TObject);
var
ConfigINI:tinifile;
begin
//===========================================================
  cfg_PrintID:=PrintSel.ItemIndex;
  ConfigINI:=tinifile.create(ExtractFileDir(application.ExeName)+'\Config.ini');

  ConfigINI.WriteInteger('SETTING','PRINTID',cfg_PrintID);

end;

procedure TForm1.Button2Click(Sender: TObject);
var
  ExecInfo:TShellExecuteInfo;
begin
  Button2.Enabled:=false;
  //清除記憶空間
  ZeroMemory(@ExecInfo,SizeOf(ExecInfo));
  with ExecInfo do begin
    cbSize := SizeOf(ExecInfo);
    fMask := SEE_MASK_NOCLOSEPROCESS;
    lpVerb := 'open';
    lpFile := pchar(ExtractFileDir(application.ExeName)+'\BatchUpload.exe'); //路徑檔案(不一定是執行檔)
    //lpParameters := 'c:autoexec.bat'; //參數 (不一定需要)
    Wnd := self.Handle;
    nShow := SW_SHOWNORMAL; //開啟的狀態
  end;
  //hide;
  ShellExecuteEx(@ExecInfo);
  WaitForSingleObject(ExecInfo.hProcess, INFINITE);
  {在這邊寫等待完要做的程式}
  //show;
  Button2.Enabled:=true;
end;

procedure TForm1.Button3Click(Sender: TObject);
var
  SHresult: Byte;
begin
  if Button3.Caption='連接裝置'#10'後請按此' then
  begin
     Button3.Caption:='重新讀取'#10'下一位';
     OmronBPDevice.Resume;
  end
  else
  begin
     Button3.Caption:='連接裝置'#10'後請按此';
     OmronBPDevice.Suspend;
  end;

  if BPDevice<>nil then
  begin
      BPDevice.BP_Value_1:=0;
      BPDevice.BP_Value_2:=0;
      BPDevice.BP_Value_3:=0;
      BPDevice.BPTime:=now;
  end;

  if OmronBPDevice<>nil then
  begin
      OmronBPDevice.BP_Value_1:=0;
      OmronBPDevice.BP_Value_2:=0;
      OmronBPDevice.BP_Value_3:=0;
      OmronBPDevice.BPTime:=now;
      OmronBPDevice.CanFetchData;
  end;

  if AbbotPort<>nil then
  begin
      //AbbotPort.GMValue:=0;
      AbbotPort.GMComIsOK:=false;
      //form1.GM_Value.Text:='';
      //form1.GM_Time.Text:='';
  end;

  form1.BarCodeMEMO.Text:='';
  CardReader.ID_NO:='';

  form1.BARXMLPATH.Text:='';
  form1.SIMXMLPATH.Text:='';

{
  if BarCode<>nil then BarCode.Free;
  BarCode:=TBarCode.Create(500);
  SHresult := StartHook(BarCodeMEMO.Handle , Handle);

  if AbbotPort<>nil then  AbbotPort.Terminate;
  AbbotPort:=TSCanPort.Create(true);
  AbbotPort.Resume;

  if CardReader<>nil then  CardReader.Terminate;
  CardReader:=THCardReader.Create(true,@SimCardTrigger);
  CardReader.Resume;

  if BPDevice<>nil then  BPDevice.Terminate;
  BPDevice:=TMicroLife.Create(true);
  BPDevice.Resume;
}
end;

procedure TForm1.Timer3Timer(Sender: TObject);
var
  Str:string;
  ECGF:TextFile;
begin
  if G_ECG.Visible then
  begin
    if ECGPort.ECGComIsOK then
    begin
      STR:=ECGQueue.ShowData;
      application.ProcessMessages;
      try
        assignfile(ECGF,ExtractFileDir(application.ExeName)+'\ECG.txt');
        rewrite(ECGF);
        write(ECGF,STR);
        closefile(ECGF);
      except
      end;
    end;
  end;

end;

procedure TForm1.ServerSocket1ClientError(Sender: TObject;
  Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
  var ErrorCode: Integer);
begin
   ErrorCode:=0;
end;

procedure TForm1.FormActivate(Sender: TObject);
var
  SHresult: Byte;
  ConfigINI:tinifile;
  ExecInfo:TShellExecuteInfo;
  i:integer;
begin
  form1.DoubleBuffered:=true;
//===========================================================
  ConfigINI:=tinifile.create(ExtractFileDir(application.ExeName)+'\Config.ini');
  cfg_UserMode          := ConfigINI.ReadBool('SETTING','USERMODE',true);
  cfg_FootText          := ConfigINI.ReadString('SETTING','FOOTTEXT','遠　東　醫　電　科　技　關　心　您');
  cfg_FootText2         := ConfigINI.ReadString('SETTING','FOOTTEXT2','電 話：(02)8913-5683');
  cfg_PrintID           := ConfigINI.ReadInteger('SETTING','PRINTID',0);

  ConfigINI.WriteInteger('SETTING','PRINTID',cfg_PrintID);
  ConfigINI.WriteBool('SETTING','USERMODE',cfg_UserMode);
  ConfigINI.WriteString('SETTING','FOOTTEXT',cfg_FootText);
//===========================================================SQL DB

  if ConfigINI.ReadBool('Satrue','Used',true) then
  begin
    G_1.Visible:=true;
    SCPort:=TSCSCanPort.Create(true);
    SCPort.Resume;
  end;

  if ConfigINI.ReadBool('MicroLife','Used',true) then
  begin
    G_2.Visible:=true;
    BPDevice:=TMicroLife.Create(true);
    BPDevice.Resume;
  end;

  if ConfigINI.ReadBool('Comdec','Used',true) then
  begin
    G_3.Visible:=true;
    SPO2Port:=TSPO2ScanPort.Create(true);
    SPO2Port.Resume;
  end;

  if ConfigINI.ReadBool('ComdecECG','Used',true) then
  begin
    G_ECG.Visible:=true;
    ECG_Chart.Series[0].Clear;
    for i:=0 to 2999 do
    begin
       ECG_Chart.Series[0].AddY(128);
    end;
    ECGPort:=TECGScanPort.Create(true);
    ECGPort.Resume;
  end;


  if ConfigINI.ReadBool('Bionime','Used',true) then
  begin
    G_4.Visible:=true;
    GMPort:=TGMScanPort.Create(true);
    GMPort.Resume;
  end;

  if ConfigINI.ReadBool('Abbott','Used',true) then
  begin
    G_5.Visible:=true;
    AbbotPort:=TSCanPort.Create(true);
    AbbotPort.Resume;
  end;

  if ConfigINI.ReadBool('OmronBP','Used',true) then
  begin
    G_6.Visible:=true;
    OmronBPDevice:=TOmronBP.Create(true);
    OmronBPDevice.Resume;
  end;


  PrintSel.Items.DelimitedText:=Printer.Printers.DelimitedText;
  PrintSel.ItemIndex:=cfg_PrintID;

  BarCode:=TBarCode.Create(500);
  SHresult := StartHook(BarCodeMEMO.Handle , Handle);

  CardReader:=THCardReader.Create(true,@SimCardTrigger);
  CardReader.Resume;

  timer1.Enabled:=true;
  timer2.Enabled:=true;
  timer3.Enabled:=true;

  if (ConfigINI.ReadBool('SETTING','USERMODE',true)=false) and
       (ConfigINI.ReadBool('SETTING','ClientWebAutoStart',true)=true)  then
  begin
    WinExec('command.com /c taskkill /F /T /IM FEMET_ClientWeb.exe',sw_Hide);
    WinExec('taskkill /F /T /IM FEMET_ClientWeb.exe',sw_Hide);
    sleep(1000);
    winexec(pchar(ExtractFileDir(application.ExeName)+'\FEMET_ClientWeb.EXE'),0);
{
    ZeroMemory(@ExecInfo,SizeOf(ExecInfo));
    with ExecInfo do begin
      cbSize := SizeOf(ExecInfo);
      fMask := SEE_MASK_NOCLOSEPROCESS;
      lpVerb := 'open';
      lpFile := pchar(ExtractFileDir(application.ExeName)+'\FEMET_ClientWeb.EXE'); //路徑檔案(不一定是執行檔)
      //lpParameters := 'c:autoexec.bat'; //參數 (不一定需要)
      Wnd := Form1.Handle;
      nShow := SW_SHOWNORMAL; //開啟的狀態
    end;
    ShellExecuteEx(@ExecInfo);
}
  end;

//  if SHresult = 0 then ShowMessage('the Key Hook was Started, good');
//  if SHresult = 1 then ShowMessage('the Key Hook was already Started');
//  if SHresult = 2 then ShowMessage('the Key Hook can NOT be Started, bad');
//  if SHresult = 4 then ShowMessage('MemoHandle is incorrect');
end;


procedure TForm1.FormCreate(Sender: TObject);
var
  SHresult: Byte;
  ConfigINI:tinifile;
  ExecInfo:TShellExecuteInfo;
  i:integer;
begin
  Button3.Caption:='連接裝置'#10'後請按此';
  //Button3.Caption:='重新讀取'#10'下一位';
  form1.DoubleBuffered:=true;
//===========================================================
  ConfigINI:=tinifile.create(ExtractFileDir(application.ExeName)+'\Config.ini');
  cfg_UserMode          := ConfigINI.ReadBool('SETTING','USERMODE',true);
  cfg_FootText          := ConfigINI.ReadString('SETTING','FOOTTEXT','遠　東　醫　電　科　技　關　心　您');
  cfg_FootText2         := ConfigINI.ReadString('SETTING','FOOTTEXT2','電 話：(02)8913-5683');
  cfg_PrintID           := ConfigINI.ReadInteger('SETTING','PRINTID',0);

  ConfigINI.WriteInteger('SETTING','PRINTID',cfg_PrintID);
  ConfigINI.WriteBool('SETTING','USERMODE',cfg_UserMode);
  ConfigINI.WriteString('SETTING','FOOTTEXT',cfg_FootText);
//===========================================================SQL DB

  if ConfigINI.ReadBool('Satrue','Used',true) then
  begin
    G_1.Visible:=true;
    SCPort:=TSCSCanPort.Create(true);
    SCPort.Resume;
  end;

  if ConfigINI.ReadBool('MicroLife','Used',true) then
  begin
    G_2.Visible:=true;
    BPDevice:=TMicroLife.Create(true);
    BPDevice.Resume;
  end;

  if ConfigINI.ReadBool('Comdec','Used',true) then
  begin
    G_3.Visible:=true;
    SPO2Port:=TSPO2ScanPort.Create(true);
    SPO2Port.Resume;
  end;

  if ConfigINI.ReadBool('ComdecECG','Used',true) then
  begin
    G_ECG.Visible:=true;
    ECG_Chart.Series[0].Clear;
    for i:=0 to 2999 do
    begin
       ECG_Chart.Series[0].AddY(128);
    end;
    ECGPort:=TECGScanPort.Create(true);
    ECGPort.Resume;
  end;


  if ConfigINI.ReadBool('Bionime','Used',true) then
  begin
    G_4.Visible:=true;
    GMPort:=TGMScanPort.Create(true);
    GMPort.Resume;
  end;

  if ConfigINI.ReadBool('Abbott','Used',true) then
  begin
    G_5.Visible:=true;
    AbbotPort:=TSCanPort.Create(true);
    AbbotPort.Resume;
  end;

  if ConfigINI.ReadBool('OmronBP','Used',true) then
  begin
    G_6.Visible:=true;
    OmronBPDevice:=TOmronBP.Create(true);
    OmronBPDevice.Resume;
  end;


  PrintSel.Items.DelimitedText:=Printer.Printers.DelimitedText;
  PrintSel.ItemIndex:=cfg_PrintID;

  BarCode:=TBarCode.Create(500);
  SHresult := StartHook(BarCodeMEMO.Handle , Handle);

  CardReader:=THCardReader.Create(true,@SimCardTrigger);
  CardReader.Resume;

  timer1.Enabled:=true;
  timer2.Enabled:=true;
  timer3.Enabled:=true;

  if (ConfigINI.ReadBool('SETTING','USERMODE',true)=false) and
       (ConfigINI.ReadBool('SETTING','ClientWebAutoStart',true)=true)  then
  begin
    WinExec('command.com /c taskkill /F /T /IM FEMET_ClientWeb.exe',sw_Hide);
    WinExec('taskkill /F /T /IM FEMET_ClientWeb.exe',sw_Hide);
    sleep(1000);
    winexec(pchar(ExtractFileDir(application.ExeName)+'\FEMET_ClientWeb.EXE'),0);
{
    ZeroMemory(@ExecInfo,SizeOf(ExecInfo));
    with ExecInfo do begin
      cbSize := SizeOf(ExecInfo);
      fMask := SEE_MASK_NOCLOSEPROCESS;
      lpVerb := 'open';
      lpFile := pchar(ExtractFileDir(application.ExeName)+'\FEMET_ClientWeb.EXE'); //路徑檔案(不一定是執行檔)
      //lpParameters := 'c:autoexec.bat'; //參數 (不一定需要)
      Wnd := Form1.Handle;
      nShow := SW_SHOWNORMAL; //開啟的狀態
    end;
    ShellExecuteEx(@ExecInfo);
}
  end;

//  if SHresult = 0 then ShowMessage('the Key Hook was Started, good');
//  if SHresult = 1 then ShowMessage('the Key Hook was already Started');
//  if SHresult = 2 then ShowMessage('the Key Hook can NOT be Started, bad');
//  if SHresult = 4 then ShowMessage('MemoHandle is incorrect');
end;


end.
