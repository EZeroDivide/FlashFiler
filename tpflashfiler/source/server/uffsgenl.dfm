�
 TFFGENCONFIGFORM 0A  TPF0TFFGenConfigFormFFGenConfigFormLeft� Top� BorderStylebsDialogCaption'FlashFiler Server General ConfigurationClientHeightClientWidthColor	clBtnFaceFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style OldCreateOrder	PositionpoScreenCenterShowHint	OnCreate
FormCreateOnShowFormShowPixelsPerInchj
TextHeight 	TGroupBox
grpGeneralLeftTopWidthHeight� Caption	 General Font.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFontTabOrder  TLabellblServerNameLeftTopWidth?HeightCaptionSer&ver name:FocusControledtServerNameFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFont  TLabel	lblMaxRAMLeftTop+WidthnHeightCaptionMaximum &RAM (in MB):FocusControl	edtMaxRAMFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFont  TLabellblPriorityLeftTop[WidthCHeightHintServer PriorityCaptionServer &priority:FocusControlcbxPriorityFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFont  TLabellblTempStoreSizeLeftTopDWidthHeightCaption&Temporary storage (in MB):FocusControledtTempStoreSize  TEditedtServerNameLeft� TopWidthyHeightHintThe server nameFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 	MaxLength
ParentFontTabOrder   TEdit	edtMaxRAMLeft� Top'WidthyHeightHint.Maximum number of RAM pages the server can useFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 	MaxLength
ParentFontTabOrder  	TComboBoxcbxPriorityLeft� TopWWidthzHeightFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFontTabOrderTextcbxPriorityItems.StringsLowestBelow NormalNormalAbove NormalHighest   	TCheckBox
boxEncryptLeftToptWidth� HeightCaption%Creation of &encrypted tables enabledFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFontTabOrder  	TCheckBoxboxReadOnlyLeftTop� Width� HeightCaption&Disable all server outputFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFontTabOrderOnClickboxReadOnlyClick  	TCheckBoxboxSecurityLeftTop� Width� HeightHintSelect if user logins requiredCaption &Security enabled (force logins)Font.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFontTabOrder  	TCheckBoxboxDebugLogLeftTop� Width� HeightCaptionDebug &logging enabledFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFontTabOrder  	TCheckBoxboxNoSaveCfgLeftTop� Width� HeightCaption%Disable saving &configuration changesFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFontTabOrderOnClickboxNoSaveCfgClick  TEditedtTempStoreSizeLeft� Top@WidthyHeightTabOrder   	TGroupBox
gbxStartupLeftTopWidth� Height7Caption Startup Options Font.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFontTabOrder 	TCheckBoxboxServerUpLeftTopWidth� HeightHint3Select if the server is to be brought up on startupCaptionBring Server &up automaticallyFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFontTabOrder   	TCheckBoxboxMinimizeLeftTop WidthaHeightHint2Select if the server is to be minimized on startupCaptionStart minimi&zed Font.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFontTabOrder   	TGroupBoxgbxKeepAliveLeftTop� Width� HeightYCaption Keep Alive Options Font.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFontTabOrder TLabellblLMIntervalLeftTopWidth� HeightAutoSizeCaption!&Interval from last message (ms):FocusControl
edtLastMsgFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFont  TLabellblBetKeepsLeftTop(Width� HeightAutoSizeCaption#Interval bet&ween Keep Alives (ms):FocusControledtKAIntervalFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFont  TLabellblKARetriesLeftTop?Width� HeightAutoSizeCaptionKeep &Alive retries:FocusControledtKARetriesFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFont  TEdit
edtLastMsgLeft� TopWidth:HeightFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFontTabOrder   TEditedtKAIntervalLeft� Top$Width:HeightFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFontTabOrder  TEditedtKARetriesLeft� Top;Width:HeightFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style 
ParentFontTabOrder   TBitBtn
btnDiscardLeft�Top� WidthKHeightHintClick to discard all changesCancel	CaptionCancelModalResult	NumGlyphsTabOrder  TBitBtnbtnSaveLeftkTop� WidthKHeightHint1Click to save all changed information permanentlyCaption&OKDefault		NumGlyphsTabOrderOnClickbtnSaveClick  	TGroupBox	gbCollectLeftTop@Width� HeightACaptionGarbage CollectionTabOrder TLabellblCollectFreqLeftTop(Width� HeightCaption!Collection &frequency (millisec):FocusControledtCollectFreq  	TCheckBoxboxCollectEnabledLeftTopWidth� HeightCaptionEna&bledChecked	State	cbCheckedTabOrder OnClickboxCollectEnabledClick  TEditedtCollectFreqLeft� Top$Width:HeightTabOrder    