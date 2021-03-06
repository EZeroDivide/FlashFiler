object frmServerMain: TfrmServerMain
  Left = 200
  Top = 108
  Caption = 'Chat Server'
  ClientHeight = 197
  ClientWidth = 733
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  Position = poScreenCenter
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object lblServerName: TLabel
    Left = 8
    Top = 14
    Width = 62
    Height = 13
    Caption = 'Server Name'
  end
  object pnlMain: TPanel
    Left = 0
    Top = 28
    Width = 733
    Height = 169
    Align = alBottom
    TabOrder = 0
    object lblServerLog: TLabel
      Left = 320
      Top = 4
      Width = 52
      Height = 13
      Caption = 'Server Log'
    end
    object memChat: TMemo
      Left = 8
      Top = 25
      Width = 723
      Height = 136
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clMaroon
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
    end
  end
  object efSrvName: TEdit
    Left = 80
    Top = 10
    Width = 121
    Height = 21
    TabOrder = 1
    Text = 'FFChatServer'
  end
  object pbSrvCtrl: TButton
    Left = 208
    Top = 8
    Width = 75
    Height = 25
    Caption = '&Start'
    TabOrder = 2
    OnClick = pbSrvCtrlClick
  end
  object tpMain: TffLegacyTransport
    Enabled = True
    EventLogOptions = [fftpLogErrors, fftpLogRequests, fftpLogReplies]
    Mode = fftmListen
    RespondToBroadcasts = True
    Protocol = ptTCPIP
    Left = 24
    Top = 24
  end
end
