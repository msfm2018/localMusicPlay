object frm_local: Tfrm_local
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'frm_local'
  ClientHeight = 509
  ClientWidth = 246
  Color = clGray
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCreate = FormCreate
  OnPaint = FormPaint
  TextHeight = 13
  object songlst: TListBox
    Left = 18
    Top = 0
    Width = 222
    Height = 503
    BorderStyle = bsNone
    Color = clGray
    DoubleBuffered = True
    ItemHeight = 13
    ParentDoubleBuffered = False
    PopupMenu = PopupMenu1
    TabOrder = 0
    OnDblClick = songlstDblClick
  end
  object Timer1: TTimer
    OnTimer = Timer1Timer
    Left = 112
    Top = 240
  end
  object PopupMenu1: TPopupMenu
    Left = 136
    Top = 112
    object N1: TMenuItem
      Caption = #28155#21152
      OnClick = N1Click
    end
    object N2: TMenuItem
      Caption = #21024#38500
      OnClick = N2Click
    end
    object N3: TMenuItem
      Caption = #28165#31354
      OnClick = N3Click
    end
  end
end
