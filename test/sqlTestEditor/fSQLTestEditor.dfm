�
 TFRMSQLTESTEDITOR 0�  TPF0TfrmSQLTestEditorfrmSQLTestEditorLeft� Top� Width�HeightCaptionSQL Test EditorColor	clBtnFaceFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style OldCreateOrderPositionpoScreenCenterOnCreate
FormCreate	OnDestroyFormDestroyOnShowFormShowPixelsPerInch`
TextHeight 	TSplittersplSQLLeft TopcWidth}HeightCursorcrVSplitAlignalBottom  TDBGridgrdTestsLeft Top)Width}Height:AlignalClient
DataSourcedtsTestTabOrderTitleFont.CharsetDEFAULT_CHARSETTitleFont.ColorclWindowTextTitleFont.Height�TitleFont.NameMS Sans SerifTitleFont.Style 
OnDblClickbtnEditClickColumnsExpanded	FieldNameCategoryWidth7Visible	 Expanded	FieldNameOrderIDTitle.CaptionOrder IDWidth0Visible	 Expanded	FieldNameNameWidth� Visible	 Expanded	FieldNameIssueIDTitle.CaptionIssue IDVisible	    TPanel
pnlActionsLeft Top�Width}Height)AlignalBottom
BevelOuterbvNoneTabOrder TLabellblTestCountLeft� TopWidth'HeightCaption%d tests  TButtonbtnEditLeftTopWidth9HeightCaption&EditTabOrder OnClickbtnEditClick  TButtonbtnAddLeftHTopWidth9HeightCaption&AddTabOrderOnClickbtnAddClick  TButton	btnDeleteLeft� TopWidth9HeightCaption&DeleteTabOrderOnClickbtnDeleteClick   TDBMemomemSQLLeft TopfWidth}HeightYAlignalBottom	DataFieldQuerySQL
DataSourcedtsTest
ScrollBarsssBothTabOrder  TPanelpnlCategoryLeft Top Width}Height)AlignalTop
BevelOuterbvNoneTabOrder  TLabellblCategoryLeftTopWidth*HeightCaptionCategory  	TComboBoxcboCategoryLeft@TopWidth� HeightStylecsDropDownList
ItemHeightTabOrder OnChangecboCategoryChangeItems.Strings<ALL>SELECTINSERTUPDATEDELETE    TDataSourcedtsTestDataSetdtmSQLTestEditor.tblTestOnDataChangedtsTestDataChangeLeft]Top0   