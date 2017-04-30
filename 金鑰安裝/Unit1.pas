unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, OleCtrls, SHDocVw,MacCheck, ExtCtrls ,mshtml, HTTPApp, HTTPProd;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Web: TWebBrowser;
    Timer1: TTimer;
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  RetryCount:integer;

implementation

{$R *.dfm}

procedure GenKey();
var
  IP,MAC,HOST:string;
  ADDR:string;
begin
  IP:=GetAllLocalIP;
  MAC:=GetMacFromIP(GetAllLocalIP);
  HOST:=Get_HostName;
  ADDR:='http://124.155.168.240:8080/yunlingov/create_ini.php?IP='+IP+'&MAC1='+MAC+'&HOSTNAME='+Host;
  //form1.edit1.text:= addr;
  form1.web.Navigate(ADDR);
  form1.Timer1.Enabled:=true;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  if  FileExists('C:\Windows\Femet.ini') then
  begin
    DeleteFile('C:\Windows\Femet.ini');
    showmessage('���_�w����');
    form1.Close;
  end
  else
    showmessage('�t�Τ��s�b���_,�L�k����');
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  RetryCount:=0;
  Button1.Enabled:=false;
  GenKey();
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  Addr:string;
  Data:string;
  myFile : TextFile;
begin
  retryCount:= retryCount+1;

  if Web.ReadyState <> READYSTATE_COMPLETE then exit;

  if pos('IP=',(WEB.Document AS IHTMLDocument2).body.innerHTML)>0 then
  begin
     //showmessage((WEB.Document AS IHTMLDocument2).body.innerHTML);
     Timer1.Enabled:=false;
     Button1.Enabled:=true;
     Data:= stringreplace((WEB.Document AS IHTMLDocument2).body.innerHTML,'<BR>',#13#10, [rfReplaceAll, rfIgnoreCase]);
     if  FileExists('C:\Windows\Femet.ini') then
     begin
       DeleteFile('C:\Windows\Femet.ini');
     end;

     AssignFile(myFile, 'C:\Windows\Femet.ini');
     ReWrite(myFile);
     Writeln(myFile,'[SET]');
     Write(myFile,Data);
     Closefile(myFile);

     showmessage('���_�]�w����');
     form1.Close;
  end;

  if retryCount=10 then
  begin
     showmessage('�P���F��q���o���_����,���ˬd�����s�u�O�_���`');
     Timer1.Enabled:=false;
     Button1.Enabled:=true;
  end;
end;

end.
