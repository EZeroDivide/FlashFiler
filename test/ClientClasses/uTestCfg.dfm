object frmClientTestConfig: TfrmClientTestConfig
  Left = 192
  Top = 107
  Width = 484
  Height = 465
  AutoSize = True
  Caption = 'Client Test - Configuration'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object pnlBottom: TPanel
    Left = 0
    Top = 397
    Width = 476
    Height = 41
    Align = alBottom
    TabOrder = 0
    object btnOK: TButton
      Left = 16
      Top = 8
      Width = 75
      Height = 25
      Cancel = True
      Caption = 'OK'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
  end
  object grpServerEngine: TRadioGroup
    Left = 0
    Top = 0
    Width = 476
    Height = 89
    Align = alTop
    Caption = 'Server Engine'
    Items.Strings = (
      'Internal'
      'Remote')
    TabOrder = 1
    OnClick = grpServerEngineClick
  end
  object grpConfiguration: TGroupBox
    Left = 0
    Top = 89
    Width = 476
    Height = 128
    Align = alTop
    Caption = 'Configuration'
    TabOrder = 2
    object lblSystemDir: TLabel
      Left = 20
      Top = 32
      Width = 50
      Height = 13
      Caption = 'System Dir'
    end
    object lblProtocol: TLabel
      Left = 31
      Top = 64
      Width = 39
      Height = 13
      Caption = 'Protocol'
    end
    object lblServerName: TLabel
      Left = 8
      Top = 96
      Width = 62
      Height = 13
      Caption = 'Server Name'
    end
    object edtSystemDir: TEdit
      Left = 88
      Top = 24
      Width = 121
      Height = 21
      TabOrder = 0
      Text = 'c:\'
    end
    object edtProtocol: TComboBox
      Left = 88
      Top = 56
      Width = 145
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 1
      Items.Strings = (
        'Single User'
        'TCP/IP'
        'IPX/SPX')
    end
    object edtServerName: TEdit
      Left = 88
      Top = 88
      Width = 201
      Height = 21
      TabOrder = 2
    end
  end
end
