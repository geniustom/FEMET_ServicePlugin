object Form1: TForm1
  Left = 213
  Top = 142
  BorderStyle = bsDialog
  Caption = #36960#26481#37291#38651#21934#27231#29256#23433#35037#37329#38000
  ClientHeight = 207
  ClientWidth = 243
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -24
  Font.Name = #24494#36575#27491#40657#39636
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 31
  object Button1: TButton
    Left = 45
    Top = 27
    Width = 160
    Height = 55
    Caption = #23433#35037#37329#38000
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 45
    Top = 117
    Width = 160
    Height = 55
    Caption = #31227#38500#37329#38000
    TabOrder = 1
    OnClick = Button2Click
  end
  object Web: TWebBrowser
    Left = 33
    Top = 222
    Width = 577
    Height = 265
    TabOrder = 2
    ControlData = {
      4C000000A23B0000631B00000000000000000000000000000000000000000000
      000000004C000000000000000000000001000000E0D057007335CF11AE690800
      2B2E126208000000000000004C0000000114020000000000C000000000000046
      8000000000000000000000000000000000000000000000000000000000000000
      00000000000000000100000000000000000000000000000000000000}
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 500
    OnTimer = Timer1Timer
    Left = 6
    Top = 3
  end
end
