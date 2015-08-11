object MainForm: TMainForm
  Left = 244
  Height = 281
  Top = 262
  Width = 470
  BorderStyle = bsDialog
  Caption = 'Firewing System Generator v1.2 - 16 Bit'
  ClientHeight = 281
  ClientWidth = 470
  Color = clBtnFace
  Font.CharSet = ANSI_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  Position = poScreenCenter
  LCLVersion = '1.2.6.0'
  object Label2: TLabel
    Left = 8
    Height = 13
    Top = 12
    Width = 256
    Caption = 'XC16 Folder - Required for *.inc and *.gld files'
    Font.CharSet = ANSI_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentColor = False
    ParentFont = False
  end
  object LabelXC16Path: TLabel
    Left = 8
    Height = 13
    Top = 28
    Width = 69
    Caption = '[not specified]'
    ParentColor = False
  end
  object Bevel3: TBevel
    Left = 0
    Height = 8
    Top = 250
    Width = 470
    Align = alBottom
    Shape = bsBottomLine
  end
  object ButtonConvert: TButton
    Left = 120
    Height = 25
    Top = 220
    Width = 105
    Caption = 'Convert Files'
    OnClick = ButtonConvertClick
    TabOrder = 1
  end
  object MemoDevices: TMemo
    Left = 8
    Height = 113
    Top = 98
    Width = 453
    ScrollBars = ssVertical
    TabOrder = 5
    TabStop = False
  end
  object ButtonGetCandidates: TButton
    Left = 8
    Height = 25
    Top = 220
    Width = 105
    Caption = 'Get Candidates'
    OnClick = ButtonGetCandidatesClick
    TabOrder = 0
  end
  object ButtonCopy: TButton
    Left = 352
    Height = 25
    Top = 220
    Width = 107
    Caption = 'Copy As Includes'
    OnClick = ButtonCopyClick
    TabOrder = 4
    TabStop = False
    Visible = False
  end
  object ButtonChangeXC16Folder: TButton
    Left = 8
    Height = 25
    Top = 52
    Width = 129
    Caption = 'Change Folder...'
    OnClick = ButtonChangeXC16FolderClick
    TabOrder = 3
  end
  object Panel1: TPanel
    Left = 0
    Height = 23
    Top = 258
    Width = 470
    Align = alBottom
    BevelOuter = bvNone
    ClientHeight = 23
    ClientWidth = 470
    TabOrder = 6
    object StatusBar: TLabel
      Left = 8
      Height = 13
      Top = 4
      Width = 31
      Caption = 'Ready'
      ParentColor = False
    end
  end
  object CheckBoxDSPIC: TCheckBox
    Left = 232
    Height = 21
    Top = 224
    Width = 78
    Caption = 'dsPIC30/33'
    OnClick = CheckBoxDsPICClick
    TabOrder = 2
  end
  object FFolderDialog: TSelectDirectoryDialog
    left = 336
    top = 32
  end
end
