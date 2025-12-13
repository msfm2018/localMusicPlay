object frm_url: Tfrm_url
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'frm_url'
  ClientHeight = 509
  ClientWidth = 222
  Color = clGray
  DoubleBuffered = True
  Font.Charset = GB2312_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = #24494#36719#38597#40657
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnPaint = FormPaint
  PixelsPerInch = 96
  TextHeight = 19
  object songlst: TListBox
    Left = 18
    Top = 1
    Width = 222
    Height = 507
    BorderStyle = bsNone
    Color = clGray
    DoubleBuffered = True
    ItemHeight = 19
    ParentDoubleBuffered = False
    TabOrder = 0
    OnDblClick = songlstDblClick
  end
  object Timer1: TTimer
    Interval = 100
    OnTimer = Timer1Timer
    Left = 96
    Top = 272
  end
  object NetHTTPClient1: TNetHTTPClient
    Asynchronous = False
    ConnectionTimeout = 60000
    ResponseTimeout = 60000
    AllowCookies = True
    HandleRedirects = True
    UserAgent = 'Embarcadero URI Client/1.0'
    Left = 152
    Top = 144
  end
end
