unit msg;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Buttons;

type
  TAlert = class(TForm)
    Panel1: TPanel;
    Label2: TLabel;
    Panel2: TPanel;
    Label1: TLabel;
    Label3: TLabel;
    SpeedButton1: TSpeedButton;
    TopTimer: TTimer;
    procedure SpeedButton1Click(Sender: TObject);
    procedure TopTimerTimer(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Alert: TAlert;

implementation

{$R *.dfm}

procedure TAlert.SpeedButton1Click(Sender: TObject);
begin
  TopTimer.Enabled:=false;
  self.Close;
end;

procedure TAlert.TopTimerTimer(Sender: TObject);
begin
  self.DoubleBuffered:=true;
  SetForegroundWindow(self.Handle);
  SetActiveWindow(self.Handle);
  //SendMessage(self.Handle,   WM_ACTIVATE   ,   0,   0);
  //PostMessage(self.Handle,WM_KEYDOWN,VK_TAB,0);
end;

procedure TAlert.FormShow(Sender: TObject);
begin
  TopTimer.Enabled:=true;
end;

end.
