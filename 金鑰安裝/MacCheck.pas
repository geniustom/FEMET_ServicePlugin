unit MacCheck;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls,Forms,
  IdMessage, IdTCPConnection, IdTCPClient,inifiles,
  IdMessageClient, IdSMTP, IdBaseComponent, IdComponent, IdIOHandler,
  IdIOHandlerSocket, IdSSLOpenSSL,Dialogs,winsock, StdCtrls;


  function GetMacFromIP(IP: String): String;
  function GetAllLocalIP : string;
  function Get_HostName : string;
  procedure Mail(SUB,MAIL:String;TBODY:Tstringlist);
  procedure InitMacChecker();
  function SendARP(Destip,scrip:DWORD;pmacaddr:PDWORD;VAR phyAddrlen:DWORD):DWORD; stdcall ;external 'iphlpapi.dll' ;
  function CheckUniComputer():boolean;
  
var
    IdSMTP1: TIdSMTP;
    IdMessage1: TIdMessage;
    IdSSLIOHandlerSocket1: TIdSSLIOHandlerSocket;  

implementation


function CheckUniComputer():boolean;
var
  ConfigINI:tinifile;
  DataPath:string;
  MAC1,MAC2,MAC3,MAC4:string;
  HOSTNAME:string;
  MailList:string;
  MailTittle:string;
  Deadline:TDate;
  B:TstringList;
  NowDate:TDate;
begin
  result:=true;

  ConfigINI:=tinifile.create('C:\windows\Femet.ini');
  MAC1:= ConfigINI.ReadString('SET','MAC1','');
  MAC2:= ConfigINI.ReadString('SET','MAC2','');
  MAC3:= ConfigINI.ReadString('SET','MAC3','');
  MAC4:= ConfigINI.ReadString('SET','MAC4','');
  MailList:= ConfigINI.ReadString('SET','MailList','geniustom@gmail.com;chunwei0928@gmail.com;tengchunnan@gmail.com;victor.chen62@gmail.com;chrishsu2u@gmail.com');
  MailTittle:= ConfigINI.ReadString('SET','MailTittle','雲林縣政府機構端程式單機版');
  HOSTNAME:= ConfigINI.ReadString('SET','HOSTNAME','');
  Deadline:= ConfigINI.ReadDate('SET','Deadline',strtodatetime('2099/09/01'));

  ConfigINI.WriteString('SET','MAC1',MAC1);
  ConfigINI.WriteString('SET','MAC2',MAC2);
  ConfigINI.WriteString('SET','MAC3',MAC3);
  ConfigINI.WriteString('SET','MAC4',MAC4);
  ConfigINI.WriteString('SET','MailList',MailList);
  ConfigINI.WriteString('SET','MailTittle',MailTittle);
  ConfigINI.WriteString('SET','HOSTNAME',HOSTNAME);
  ConfigINI.WriteDate('SET','Deadline',Deadline);

  //================================
  B:=TstringList.Create;
  B.Delimiter:=',';
  B.Add('偵測到有人不合法使用,狀況如下：');
  B.Add('');
  //================================
  if (pos(MAC1,GetMacFromIP(GetAllLocalIP))<=0) and
     (pos(MAC2,GetMacFromIP(GetAllLocalIP))<=0) and
     (pos(MAC3,GetMacFromIP(GetAllLocalIP))<=0) then
  begin
     result:=false;
     B.Add('MAC Address不符');
  end;
  //================================
  NowDate:=now;
  if NowDate>Deadline then
  begin
     result:=false;
     B.Add('試用時間已到期');
  end;
  //================================
  NowDate:=now;
  if pos(Get_HostName,HOSTNAME)<=0 then
  begin
     result:=false;
     B.Add('主機名稱不符');
  end;
  //================================
  B.Add('');
  B.Add('================================');
  B.Add('不合法IP:'+GetAllLocalIP);
  B.Add('不合法MAC:'+GetMacFromIP(GetAllLocalIP));
  B.Add('不合法HOST:'+Get_HostName);
  B.Add('================================');
  if result=false then
  begin
    InitMacChecker();
    mail('[不合法使用通知]'+MailTittle,MailList,B);
  end;
end;

procedure InitMacChecker();
begin
    IdSMTP1:=TIdSMTP.Create(nil);
    IdMessage1:=TIdMessage.Create(nil);
    IdSSLIOHandlerSocket1:=TIdSSLIOHandlerSocket.Create(nil);
end;

procedure Mail(SUB,MAIL:String;TBODY:Tstringlist);
begin

try
{
  IdSMTP1.Host := 'smtp.gmail.com';
  IdSMTP1.Username := 'ctilog.femet';        // 不含 @gmail.com
  IdSMTP1.Password := 'femet!!!';
  IdSMTP1.Port := 465;
  IdSMTP1.IOHandler := IdSSLIOHandlerSocket1;
  IdSSLIOHandlerSocket1.SSLOptions.Method := sslvSSLv2;
  IdSSLIOHandlerSocket1.SSLOptions.Mode := sslmClient;
}
{
  IdSMTP1.Host := 'smtp.163.com';
  IdSMTP1.Username := 'ctilog';        // 不含 @gmail.com
  IdSMTP1.Password := 'femetfemet';
  IdSMTP1.Port := 25;
}
  IdSMTP1.Host := 'authsmtp.seed.net.tw';
  IdSMTP1.Username := 'geniustom';        // 不含 @gmail.com
  IdSMTP1.Password := 'apiapiapi';
  IdSMTP1.Port := 25;


  with TIdText.Create(IdMessage1.MessageParts) do
  begin
    ContentType := 'text/plain';
    Body.Add('***Big Heading***');
  end;

  with TIdText.Create(IdMessage1.MessageParts) do
  begin
    ContentType := 'text/html';
    Body.Add('<html><body>');
    Body.Add('<head><meta http-equiv="Content-Type" content="text/html; charset=big5"></head><pre>');

    Body.Add(TBODY.Text);
    Body.Add('</pre></body></html>');
  end;


 with IdMessage1 do
 begin
  IdMessage1.Recipients.EMailAddresses := Mail;
  IdMessage1.From.Address := 'geniustom@seed.net.tw';
  IdMessage1.CCList.EMailAddresses := '';
  IdMessage1.BccList.EMailAddresses := '';
  IdMessage1.Subject := SUB;
  IdMessage1.ContentType := 'multipart/alternative';
  IdMessage1.CharSet := 'big5';
 end;

  IdSMTP1.Connect(6000);
    application.ProcessMessages;

  if (IdSMTP1.AuthSchemesSupported.IndexOf('LOGIN')<>-1) then
  begin
     IdSMTP1.AuthenticationType :=atLogin;
     IdSMTP1.Authenticate;
  end;

  if IdSMTP1.Connected then
  begin
    try
      application.ProcessMessages;
      IdSMTP1.Send(IdMessage1);
    finally
      application.ProcessMessages;
    end;
  end;

  IdSMTP1.Disconnect;
except
end;
end;


function Get_HostName : string;
//
// Return computer IP if you are connected in a network
// Declare Winsock in the uses clause
//
type
    TaPInAddr = array [0..10] of PInAddr;
    PaPInAddr = ^TaPInAddr;
var
    phe : PHostEnt;
    Buffer : array [0..63] of char;
    GInitData : TWSADATA;
begin
    WSAStartup($101, GInitData);
    Result := '';
    GetHostName(@Buffer, SizeOf(Buffer));
    phe :=GetHostByName(@buffer);
    result := String(phe^.h_Name);
    WSACleanup;
end;
function GetAllLocalIP : string;
//
// Return computer IP if you are connected in a network
// Declare Winsock in the uses clause
//
type
    TaPInAddr = array [0..10] of PInAddr;
    PaPInAddr = ^TaPInAddr;
var
    phe : PHostEnt;
    pptr : PaPInAddr;
    Buffer : array [0..63] of char;
    I : Integer;
    GInitData : TWSADATA;
begin
    WSAStartup($101, GInitData);
    Result := '';
    GetHostName(@Buffer, SizeOf(Buffer));
    phe :=GetHostByName(@buffer);
    if phe = nil then
    begin
        Exit;
    end;
    pptr := PaPInAddr(Phe^.h_addr_list);
    I := 0;
    while pptr^[I] <> nil do
    begin
      if i=0 then
        result:= String(StrPas(inet_ntoa(pptr^[I]^)))
      else
        result:= result + ' , ' + String(StrPas(inet_ntoa(pptr^[I]^)));
      Inc(I);
    end;
    WSACleanup;
end;


function GetMacFromIP(IP: String): String;
type
Tinfo = array[0..7] of byte;
var
    dwTargetIP: dword;
    dwMacAddress: array[0..1] of DWORD;
    dwMacLen: DWORD;
    dwResult: DWORD;
    X: Tinfo;
    stemp:string;
    iloop:integer;
begin
    dwTargetIP := Inet_Addr(pchar(ip));
    dwMacLen:= 6;
    dwResult:= sendarp(dwtargetip,0,@dwmacaddress[0], dwMaclen);
    if dwResult= NO_ERROR then
    begin
    x:= tinfo(dwMacAddress);
   
    for iloop:= 0 to 5 do
    begin
    stemp:= stemp+inttohex(x[iloop],2);
    end;
    Result:= stemp;
    end;
end;


end.
