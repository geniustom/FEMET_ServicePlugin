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
  msg in '..\..\Dropbox\���z�]����\����v����վ�{��\msg.pas' {Alert};

{$R *.res}

begin
  Mutex := CreateMutex(nil, false,pchar('���F��q�˸m�ʱ��A�Ⱦ�V3.0'));
  WinExec('command.com /c taskkill /F /T /IM FEMET_ServicePlugin.EXE',sw_Hide);
  if (Mutex = 0) OR (GetLastError = ERROR_ALREADY_EXISTS) then
  begin
    WinExec('command.com /c taskkill /F /T /IM FEMET_ServicePlugin.EXE',sw_Hide);
    //exit;
  end;


  if MacCheck.CheckUniComputer=false then
  begin
     showmessage('�L�k�}�ҥ��{��,��]�i��p�U�G'+#13+'1.�z�b�D���F��q�Ҧw�˪��q��������'+#13+
                 '2.�Ұʪ��_�򥢩Υ��w��'+#13+
                 '�Y��������D,�Ь����F��q(02)8913-5683');
  end
  else
  begin
    Application.Initialize;
    Application.Title := '���F��q�˸m�ʱ��A�Ⱦ�V3.0';
  Application.CreateForm(TForm1, Form1);
  Application.CreateForm(TAlert, Alert);
  WinExec('command.com /c taskkill /F /T /IM FEMET_ClientWeb.EXE',sw_Hide);
    Application.Run;
  end;

end.

