object Form1: TForm1
  Left = 200
  Top = 108
  BorderStyle = bsSingle
  Caption = 'FlashFiler Example - Blob Data'
  ClientHeight = 334
  ClientWidth = 423
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = True
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 312
    Width = 423
    Height = 22
    Align = alBottom
    BevelOuter = bvLowered
    TabOrder = 0
    object DbText1: TDBText
      Left = 1
      Top = 1
      Width = 150
      Height = 20
      Align = alLeft
      Alignment = taCenter
      DataField = 'Title'
      DataSource = BlobSource
      Transparent = True
    end
    object DbText2: TDBText
      Left = 272
      Top = 1
      Width = 150
      Height = 20
      Align = alRight
      Alignment = taCenter
      DataField = 'Size'
      DataSource = BlobSource
      Transparent = True
    end
    object DbText3: TDBText
      Left = 168
      Top = 1
      Width = 100
      Height = 20
      Alignment = taCenter
      DataField = 'Type'
      DataSource = BlobSource
    end
  end
  object DbImage1: TDBImage
    Left = 0
    Top = 30
    Width = 423
    Height = 282
    Align = alClient
    DataField = 'Image'
    DataSource = BlobSource
    Enabled = False
    ReadOnly = True
    TabOrder = 1
    ExplicitLeft = -1
    ExplicitTop = 36
  end
  object DBNavigator1: TDBNavigator
    Left = 0
    Top = 0
    Width = 423
    Height = 30
    DataSource = BlobSource
    VisibleButtons = [nbFirst, nbPrior, nbNext, nbLast]
    Align = alTop
    Flat = True
    TabOrder = 2
  end
  object ltMain: TffLegacyTransport
    Enabled = True
    Left = 40
    Top = 80
  end
  object ffRSE: TFFRemoteServerEngine
    Transport = ltMain
    Left = 8
    Top = 80
  end
  object ffClient: TffClient
    ClientName = 'ffClient'
    ServerEngine = ffRSE
    Left = 8
    Top = 48
  end
  object ffSess: TffSession
    ClientName = 'ffClient'
    SessionName = 'ExBlob'
    Left = 40
    Top = 48
  end
  object BlobTable: TffTable
    DatabaseName = 'Tutorial'
    FieldDefs = <>
    ReadOnly = True
    SessionName = 'ExBlob'
    TableName = 'ExBlob'
    Timeout = 10000
    Left = 72
    Top = 48
  end
  object BlobSource: TDataSource
    DataSet = BlobTable
    Left = 104
    Top = 48
  end
  object MainMenu1: TMainMenu
    Left = 136
    Top = 48
    object File1: TMenuItem
      Caption = '&File'
      object Open1: TMenuItem
        Caption = '&Open'
        OnClick = Open1Click
      end
      object Close1: TMenuItem
        Caption = '&Close'
        OnClick = Close1Click
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object Exit1: TMenuItem
        Caption = '&Exit'
        OnClick = Exit1Click
      end
    end
    object Navigate1: TMenuItem
      Caption = '&Navigate'
      Enabled = False
      object First1: TMenuItem
        Caption = '&First'
        OnClick = First1Click
      end
      object Last1: TMenuItem
        Caption = '&Last'
        OnClick = Last1Click
      end
      object Next1: TMenuItem
        Caption = '&Next'
        OnClick = Next1Click
      end
      object Prior1: TMenuItem
        Caption = '&Prior'
        OnClick = Prior1Click
      end
    end
    object Images1: TMenuItem
      Caption = '&Images'
      object Bmp1: TMenuItem
        Caption = '&Bmp'
        RadioItem = True
        OnClick = Bmp1Click
      end
      object Jpeg1: TMenuItem
        Caption = '&Jpeg'
        RadioItem = True
        OnClick = Jpeg1Click
      end
      object All1: TMenuItem
        Caption = '&All'
        Checked = True
        RadioItem = True
        OnClick = All1Click
      end
    end
  end
end
