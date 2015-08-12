object MainForm: TMainForm
  Left = 334
  Top = 294
  BorderStyle = bsDialog
  Caption = 'Firewing System Generator v1.2 - 8 Bit'
  ClientHeight = 263
  ClientWidth = 471
  Color = clBtnFace
  Font.Charset = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 16
    Top = 16
    Width = 192
    Height = 13
    Caption = 'Microchip MPASM/MPASMX Folder'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object LabelIncludePath: TLabel
    Left = 16
    Top = 32
    Width = 69
    Height = 13
    Caption = '[not specified]'
  end
  object Bevel1: TBevel
    Left = 0
    Top = 232
    Width = 471
    Height = 8
    Align = alBottom
    Shape = bsBottomLine
  end
  object ButtonConvert: TButton
    Left = 128
    Top = 208
    Width = 105
    Height = 25
    Caption = 'Convert Files'
    TabOrder = 1
    OnClick = ButtonConvertClick
  end
  object ButtonChangeFolder: TButton
    Left = 16
    Top = 56
    Width = 129
    Height = 25
    Caption = 'Change Folder...'
    TabOrder = 3
    OnClick = ButtonChangeFolderClick
  end
  object MemoDevices: TMemo
    Left = 16
    Top = 88
    Width = 441
    Height = 113
    TabStop = False
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object ButtonGetCandidates: TButton
    Left = 16
    Top = 208
    Width = 105
    Height = 25
    Caption = 'Get Candidates'
    TabOrder = 0
    OnClick = ButtonGetCandidatesClick
  end
  object Panel1: TPanel
    Left = 0
    Top = 240
    Width = 471
    Height = 23
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 4
    object StatusBar: TLabel
      Left = 8
      Top = 4
      Width = 31
      Height = 13
      Caption = 'Ready'
    end
  end
end
