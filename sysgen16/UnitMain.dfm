object MainForm: TMainForm
  Left = 579
  Top = 185
  BorderStyle = bsDialog
  Caption = 'Firewing System Generator v1.2 - 16 Bit'
  ClientHeight = 281
  ClientWidth = 470
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
  object Label2: TLabel
    Left = 8
    Top = 12
    Width = 256
    Height = 13
    Caption = 'XC16 Folder - Required for *.inc and *.gld files'
    Font.Charset = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object LabelXC16Path: TLabel
    Left = 8
    Top = 28
    Width = 69
    Height = 13
    Caption = '[not specified]'
  end
  object Bevel3: TBevel
    Left = 0
    Top = 250
    Width = 470
    Height = 8
    Align = alBottom
    Shape = bsBottomLine
  end
  object ButtonConvert: TButton
    Left = 120
    Top = 220
    Width = 105
    Height = 25
    Caption = 'Convert Files'
    TabOrder = 1
    OnClick = ButtonConvertClick
  end
  object MemoDevices: TMemo
    Left = 8
    Top = 98
    Width = 453
    Height = 113
    TabStop = False
    ScrollBars = ssVertical
    TabOrder = 4
  end
  object ButtonGetCandidates: TButton
    Left = 8
    Top = 220
    Width = 105
    Height = 25
    Caption = 'Get Candidates'
    TabOrder = 0
    OnClick = ButtonGetCandidatesClick
  end
  object ButtonCopy: TButton
    Left = 352
    Top = 220
    Width = 107
    Height = 25
    Caption = 'Copy As Includes'
    TabOrder = 5
    TabStop = False
    Visible = False
    OnClick = ButtonCopyClick
  end
  object ButtonChangeXC16Folder: TButton
    Left = 8
    Top = 52
    Width = 129
    Height = 25
    Caption = 'Change Folder...'
    TabOrder = 3
    OnClick = ButtonChangeXC16FolderClick
  end
  object Panel1: TPanel
    Left = 0
    Top = 258
    Width = 470
    Height = 23
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 6
    object StatusBar: TLabel
      Left = 8
      Top = 4
      Width = 31
      Height = 13
      Caption = 'Ready'
    end
  end
  object CheckBoxDSPIC: TCheckBox
    Left = 232
    Top = 224
    Width = 81
    Height = 17
    Caption = 'dsPIC30/33'
    TabOrder = 2
    OnClick = CheckBoxDsPICClick
  end
end
