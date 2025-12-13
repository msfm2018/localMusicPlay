object frmLrcShow: TfrmLrcShow
  Left = 142
  Top = 635
  Cursor = crSizeAll
  BorderIcons = [biSystemMenu]
  BorderStyle = bsNone
  ClientHeight = 80
  ClientWidth = 751
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -48
  Font.Name = #23435#20307
  Font.Style = [fsBold]
  OldCreateOrder = False
  PopupMenu = pmLyric
  Position = poDesigned
  Visible = True
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnMouseDown = FormMouseDown
  OnMouseEnter = FormMouseEnter
  OnMouseLeave = FormMouseLeave
  OnMouseMove = FormMouseMove
  OnMouseUp = FormMouseUp
  PixelsPerInch = 96
  TextHeight = 48
  object tmr1: TTimer
    Interval = 60000
    OnTimer = tmr1Timer
    Left = 8
    Top = 8
  end
  object pmLyric: TPopupMenu
    Left = 40
    Top = 8
    object N2: TMenuItem
      Caption = #27468#35789#39068#33394
      object N3: TMenuItem
        Caption = #34013#33394
        OnClick = N3Click
      end
      object N4: TMenuItem
        Caption = #32418#33394
        OnClick = N4Click
      end
      object N5: TMenuItem
        Caption = #32511#33394
        OnClick = N5Click
      end
    end
    object LRC1: TMenuItem
      Caption = #36716#25442#21040'LRC'#26684#24335
      Enabled = False
    end
  end
end
