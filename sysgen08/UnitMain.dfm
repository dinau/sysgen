object MainForm: TMainForm
  Left = 350
  Height = 263
  Top = 514
  Width = 471
  BorderStyle = bsDialog
  Caption = 'Firewing System Generator v1.2 - 8 Bit'
  ClientHeight = 263
  ClientWidth = 471
  Color = clBtnFace
  Font.CharSet = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  Position = poScreenCenter
  LCLVersion = '1.4.2.0'
  object Label1: TLabel
    Left = 16
    Height = 13
    Top = 16
    Width = 192
    Caption = 'Microchip MPASM/MPASMX Folder'
    Font.CharSet = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentColor = False
    ParentFont = False
  end
  object LabelIncludePath: TLabel
    Left = 16
    Height = 13
    Top = 32
    Width = 69
    Caption = '[not specified]'
    ParentColor = False
  end
  object Bevel1: TBevel
    Left = 0
    Height = 8
    Top = 232
    Width = 471
    Align = alBottom
    Shape = bsBottomLine
  end
  object ButtonConvert: TButton
    Left = 128
    Height = 25
    Top = 208
    Width = 105
    Caption = 'Convert Files'
    OnClick = ButtonConvertClick
    TabOrder = 1
  end
  object ButtonChangeFolder: TButton
    Left = 16
    Height = 25
    Top = 56
    Width = 129
    Caption = 'Change Folder...'
    OnClick = ButtonChangeFolderClick
    TabOrder = 3
  end
  object MemoDevices: TMemo
    Left = 16
    Height = 113
    Top = 88
    Width = 441
    ScrollBars = ssVertical
    TabOrder = 2
    TabStop = False
  end
  object ButtonGetCandidates: TButton
    Left = 16
    Height = 25
    Top = 208
    Width = 105
    Caption = 'Get Candidates'
    OnClick = ButtonGetCandidatesClick
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Height = 23
    Top = 240
    Width = 471
    Align = alBottom
    BevelOuter = bvNone
    ClientHeight = 23
    ClientWidth = 471
    TabOrder = 4
    object StatusBar: TLabel
      Left = 8
      Height = 13
      Top = 4
      Width = 31
      Caption = 'Ready'
      ParentColor = False
    end
  end
  object FFolderDialog: TSelectDirectoryDialog
    left = 328
    top = 32
  end
end
