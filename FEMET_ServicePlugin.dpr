program FEMET_ServicePlugin;

uses
  Forms,
  windows,
  Dialogs,
  inifiles,
  ShellApi,
  SysUtils,
  Unit1 in 'Unit1.pas' {Form1},
  BarCode_Lib in 'BarCode_Lib.pas',
  SimCard_Lib in 'SimCard_Lib.pas',
  XML_Lib in 'XML_Lib.pas',
  PCSCConnector in 'CardReader\PCSCConnector.pas',
  DBT in 'HIDLib\DBT.pas',
  Hid in 'HIDLib\HID.pas',
  HidToken in 'HIDLib\HidToken.pas',
  HidUsage in 'HIDLib\HidUsage.pas',
  JvHidControllerClass in 'HIDLib\JvHidControllerClass.pas',
  ModuleLoader in 'HIDLib\ModuleLoader.pas',
  SetupApi in 'HIDLib\SetupApi.pas',
  BP_Lib in 'BP_Lib.pas',
  Abbot_LIB in 'Abbot_LIB.pas',
  MacCheck in 'MacCheck.pas',
  DelayLib in 'DelayLib.pas',
  GM_LIB in 'GM_Lib.pas',
  SPO2_Lib in 'SPO2_Lib.pas',
  Scales_LIB in 'Scales_Lib.pas',
  ECG_Lib in 'ECG_Lib.pas',
  OmronBP_Lib in 'OmronBP_Lib.pas',
  msg in '..\..\Dropbox\投資理財相關\選擇權部位調整程式\msg.pas' {Alert};

{$R *.res}

begin
  Mutex := CreateMutex(nil, false,pchar('遠東醫電裝置監控服務器V3.0'));
  WinExec('command.com /c taskkill /F /T /IM FEMET_ServicePlugin.EXE',sw_Hide);
  if (Mutex = 0) OR (GetLastError = ERROR_ALREADY_EXISTS) then
  begin
    WinExec('command.com /c taskkill /F /T /IM FEMET_ServicePlugin.EXE',sw_Hide);
    //exit;
  end;


  if MacCheck.CheckUniComputer=false then
  begin
     showmessage('無法開啟本程式,原因可能如下：'+#13+'1.您在非遠東醫電所安裝的電腦中執行'+#13+
                 '2.啟動金鑰遺失或未安裝'+#13+
                 '若有任何問題,請洽遠東醫電(02)8913-5683');
  end
  else
  begin
    Application.Initialize;
    Application.Title := '遠東醫電裝置監控服務器V3.0';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TAlert, Alert);
  WinExec('command.com /c taskkill /F /T /IM FEMET_ClientWeb.EXE',sw_Hide);
    Application.Run;
  end;

end.

