object Animation_: TAnimation_
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'Animation_'
  ClientHeight = 99
  ClientWidth = 612
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  StyleElements = []
  PixelsPerInch = 96
  TextHeight = 13
  object ProgressBar1: TProgressBar
    Left = 232
    Top = 40
    Width = 150
    Height = 16
    TabOrder = 0
  end
  object Timer1: TTimer
    OnTimer = Timer1Timer
    Left = 296
    Top = 32
  end
end
