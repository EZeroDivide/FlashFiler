object frmCltMain: TfrmCltMain
  Left = 200
  Top = 108
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'FF Chat Client'
  ClientHeight = 218
  ClientWidth = 746
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  OnClose = FormClose
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object bvMain: TBevel
    Left = 8
    Top = 5
    Width = 733
    Height = 202
  end
  object lblUserName: TLabel
    Left = 12
    Top = 177
    Width = 53
    Height = 13
    Caption = 'User Name'
  end
  object lblConnect: TLabel
    Left = 218
    Top = 146
    Width = 64
    Height = 13
    Caption = 'Connected to'
  end
  object pbSend: TButton
    Left = 12
    Top = 110
    Width = 75
    Height = 25
    Caption = '&Send'
    Enabled = False
    TabOrder = 0
    OnClick = pbSendClick
  end
  object efMessage: TEdit
    Left = 90
    Top = 112
    Width = 641
    Height = 21
    Enabled = False
    TabOrder = 1
    Text = '<Enter message here>'
    OnKeyDown = efMessageKeyDown
  end
  object pbConnect: TButton
    Left = 218
    Top = 171
    Width = 75
    Height = 25
    Caption = '&Connect'
    Default = True
    TabOrder = 2
    OnClick = pbConnectClick
  end
  object pbDisconnect: TButton
    Left = 572
    Top = 171
    Width = 75
    Height = 25
    Caption = '&Disconnect'
    Enabled = False
    TabOrder = 3
    OnClick = pbDisconnectClick
  end
  object efUserName: TEdit
    Left = 69
    Top = 173
    Width = 121
    Height = 21
    MaxLength = 31
    TabOrder = 4
    Text = 'me'
  end
  object lbUsers: TListBox
    Left = 627
    Top = 15
    Width = 104
    Height = 87
    ItemHeight = 13
    TabOrder = 5
  end
  object chkPrivate: TCheckBox
    Left = 12
    Top = 144
    Width = 97
    Height = 17
    Caption = 'Private message'
    TabOrder = 6
    OnClick = chkPrivateClick
  end
  object lbOutput: TListBox
    Left = 12
    Top = 14
    Width = 609
    Height = 87
    Style = lbOwnerDrawFixed
    ExtendedSelect = False
    TabOrder = 7
    OnDrawItem = lbOutputDrawItem
  end
  object pbExit: TButton
    Left = 656
    Top = 171
    Width = 75
    Height = 25
    Caption = 'E&xit'
    TabOrder = 8
    OnClick = pbExitClick
  end
  object cmbServers: TComboBox
    Left = 296
    Top = 173
    Width = 233
    Height = 21
    TabOrder = 9
    Text = 'cmbServers'
  end
  object pbRefreshServers: TButton
    Left = 531
    Top = 175
    Width = 33
    Height = 16
    Caption = '...'
    TabOrder = 10
    OnClick = pbRefreshServersClick
  end
  object tpClient: TffLegacyTransport
    Enabled = True
    EventLogOptions = [fftpLogErrors, fftpLogRequests, fftpLogReplies]
    Protocol = ptTCPIP
    Left = 16
    Top = 16
  end
end
