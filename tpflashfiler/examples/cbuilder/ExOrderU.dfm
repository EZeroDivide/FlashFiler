�
 TFORM1 0C  TPF0TForm1Form1Left� TopkWidthMHeighteCaptionForm1Font.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style Menu	MainMenu1PixelsPerInch`
TextHeight 	TGroupBox	GroupBox1Left Top WidthEHeight� AlignalTopCaption	CustomersTabOrder  TDBGridDBGrid1LeftTopWidthAHeight� AlignalClient
DataSourceCustomerDataTabOrder TitleFont.CharsetDEFAULT_CHARSETTitleFont.ColorclWindowTextTitleFont.Height�TitleFont.NameMS Sans SerifTitleFont.Style    	TGroupBox	GroupBox2Left Top� WidthEHeightxAlignalBottomCaptionOrdersTabOrder TDBGridDBGrid4LeftTopWidth� HeightgAlignalLeft
DataSource
OrdersDataTabOrder TitleFont.CharsetDEFAULT_CHARSETTitleFont.ColorclWindowTextTitleFont.Height�TitleFont.NameMS Sans SerifTitleFont.Style Columns	FieldNameOrderID 	FieldNameDate 	FieldName
CustomerID    TDBGridDBGrid3Left{TopWidth�HeightgAlignalRight
DataSource	LinesDataTabOrderTitleFont.CharsetDEFAULT_CHARSETTitleFont.ColorclWindowTextTitleFont.Height�TitleFont.NameMS Sans SerifTitleFont.Style Columns	FieldName	ProductID 	FieldNameCount 	FieldNameDescription 	FieldNameTotal 	FieldNameOrderID     
TffSession
ffSession1
ClientNameMain1SessionNameExOrdersLeft(Toph  TDataSourceCustomerDataDataSetCustomerTableLeftpTopH  TDataSource	LinesDataDataSet
LinesTableLeftpTop(  TDataSource
OrdersDataDataSetOrdersTableLeftxToph  TffTableCustomerTableDatabaseNameTutorial	FieldDefs 	IndexNameSequential Access IndexSessionNameExOrders	TableNameEXCustLeftPTopH  TffTableOrdersTableDatabaseNameTutorial	FieldDefs 	IndexName
ByCustomerMasterFields
CustomerIDMasterSourceCustomerDataSessionNameExOrders	TableNameEXOrdersLeftPToph  TffTable
LinesTableDatabaseNameTutorial	FieldDefs 	IndexNameByOrderMasterFieldsOrderIDMasterSource
OrdersDataSessionNameExOrders	TableNameEXLinesOnCalcFieldsLinesTableCalcFieldsLeft(TopH TIntegerFieldLinesTableLineID	FieldNameLineID  TIntegerFieldLinesTableOrderID	FieldNameOrderID  TIntegerFieldLinesTableProductID	FieldName	ProductID  TIntegerFieldLinesTableCount	FieldNameCountRequired	  TStringFieldLinesTableDescription	FieldNameDescriptionLookupDataSetProductTableLookupKeyFields	ProductIDLookupResultFieldDescription	KeyFields	ProductIDSizeLookup	  TCurrencyFieldLinesTableTotal	FieldNameTotal
Calculated	  TCurrencyFieldLinesTablePrice	FieldNamePriceLookupDataSetProductTableLookupKeyFields	ProductIDLookupResultFieldPrice	KeyFields	ProductIDLookup	   TffTableProductTableDatabaseNameTutorial	FieldDefs IndexFieldNames	ProductIDSessionNameExOrders	TableNameEXProdsLeftPTop(  	TMainMenu	MainMenu1Left� Top( 	TMenuItemFile1Caption&File 	TMenuItemOpen1Caption&OpenOnClick
Open1Click  	TMenuItemClose1Caption&CloseOnClickClose1Click  	TMenuItemN1Caption-  	TMenuItemExit1Caption&ExitOnClick
Exit1Click    	TffClientFFClient
ClientNameMain1ServerEngineFFRemoteServerEngine1Left(Top(  TffLegacyTransportffLegacyTransport1Enabled	
ServerNameSeanFF2@192.168.9  .108LeftTop   TFFRemoteServerEngineFFRemoteServerEngine1	TransportffLegacyTransport1Left� Top    