unit ftestconfig;

interface

uses
  Windows, utester, Messages, SysUtils, Classes, Graphics, Controls,
  Forms, Dialogs, StdCtrls, ComCtrls, ExtCtrls, Db, ffdb, IniFiles,
  ffdbbase, ffllcomp, fflleng, ffsrintm, ffsreng, ffllbase, ffsqlbas,
  ffsqleng, Filectrl, usqltesttypes, abzipper, abziptyp, Buttons, Grids,
  DBGrids, ComObj, ActiveX, ststrs, abUnzper, stFileOp;

type
  TSaveMode = (smEdit, smNew);

  TsqtIgnoreOption = (ioResultPath);
  TsqtIgnoreOptions = set of TsqtIgnoreOption;

  TfrmConfigureTest = class(TForm)
    pcWizard: TPageControl;
    pnlBottom: TPanel;
    tsIntroduction: TTabSheet;
    edtSkip: TCheckBox;
    memIntroduction: TMemo;
    tsQueryInformation: TTabSheet;
    tsTestInformation: TTabSheet;
    lblTestName: TLabel;
    edtTestName: TEdit;
    lblDescription: TLabel;
    edtDescription: TMemo;
    lblIssueID: TLabel;
    edtIssueID: TEdit;
    lblDate: TLabel;
    edtDate: TEdit;
    dlgBrowse: TOpenDialog;
    btnSave: TButton;
    btnCancel: TButton;
    lblCheckout: TLabel;
    lblConfigure: TLabel;
    lblDatabasePath: TLabel;
    edtQRequestLive: TCheckBox;
    lblSQL: TLabel;
    lblTimeout: TLabel;
    edtQPath: TEdit;
    edtQTimeout: TEdit;
    edtQSQL: TMemo;
    btnConfigureFilterQuery: TButton;
    btnTestTheTest: TButton;
    barProgress: TProgressBar;
    lblRunCount: TLabel;
    edtRunCount: TEdit;
    edtIgnoreTest: TCheckBox;
    lblOrderID: TLabel;
    edtOrderID: TEdit;
    tsTestResults: TTabSheet;
    grdResultSet: TDBGrid;
    dsResultSet: TDataSource;
    pnlResultSet: TPanel;
    pbSaveResultSet: TButton;
    lblSaveAs: TLabel;
    edtSaveAs: TEdit;
    dlgSave: TSaveDialog;
    lblRecCount: TLabel;
    tsResultInformation: TTabSheet;
    lblTablePath: TLabel;
    lblResultType: TLabel;
    lblErrorCode: TLabel;
    lblErrorString: TLabel;
    btnBrose: TSpeedButton;
    edtTablePath: TEdit;
    btnConfigureFilterResult: TButton;
    edtRResultType: TComboBox;
    edtRErrorCode: TEdit;
    edtRErrorString: TEdit;
    lblCategory: TLabel;
    edtCategory: TComboBox;
    edtMaxSourceReads: TEdit;
    lblMaxSourceReads: TLabel;
    tsCompareAgainst: TTabSheet;
    memSQLExecResultSQL: TMemo;
    Label2: TLabel;
    Label3: TLabel;
    pbExtract: TButton;
    pbExtractResult: TButton;
    procedure tsIntroductionShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure tsTestInformationShow(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure btnTestTheTestClick(Sender: TObject);
    procedure btnConfigureFilterResultClick(Sender: TObject);
    procedure btnConfigureFilterQueryClick(Sender: TObject);
    procedure btnBrowseResultClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnBroseClick(Sender: TObject);
    procedure pbSaveResultSetBrowseClick(Sender: TObject);
    procedure edtSaveAsChange(Sender: TObject);
    procedure pbSaveResultSetClick(Sender: TObject);
    procedure edtCategoryChange(Sender: TObject);
    procedure pbExtractClick(Sender: TObject);
    procedure pbExtractResultClick(Sender: TObject);
  private
    FQueryFilter  : TsqtFilterProperties;
    FResultFilter : TsqtFilterProperties;
    FArchiveLocation : string;
    FSaveMode : TSaveMode;
    FTester : TQueryTester;
    FTestTable : TDataset;
    FTestQuery : TffQuery;
    procedure ExtractToDisk(const FieldName, ArchiveName : string);
    procedure MapCategoryToCombo(const Category : string);
    procedure ValidateRecord(const IgnoreOptions : TsqtIgnoreOptions);
    procedure SaveRecord;
  public
    property SaveMode : TSaveMode
       read FSaveMode
       write FSaveMode
       default smNew;
    property TestTable : TDataset
       read FTestTable
       write FTestTable;
  end;

var
  frmConfigureTest: TfrmConfigureTest;
  DeleteDirsOnClose : TStringList;

implementation

uses fFilterProperties, dSQLTestEditor;

{$R *.DFM}

procedure TfrmConfigureTest.tsIntroductionShow(Sender: TObject);
var
  Att: Integer;
begin
  lblConfigure.Visible := not FileExists(FArchiveLocation);
  if not lblConfigure.Visible then begin
    {make sure archive exists and is ready}
    Att := FileGetAttr(FArchiveLocation);
    lblCheckOut.Visible := Att and SysUtils.faReadOnly <> 0;
  end;
end;

procedure TfrmConfigureTest.FormCreate(Sender: TObject);
var
  Ini : TIniFile;
begin
  barProgress.Visible := True;
  lblRecCount.Visible := False;
  FTester := TQueryTester.Create(nil);
  FTester.ProgressBar := barProgress;
  SaveMode := smNew;
  TestTable := nil;
  InitFilterProperties(FQueryFilter);
  InitFilterProperties(FResultFilter);

  {load preferences}
  Ini := TIniFile.Create('SQLTester.ini');
  try
    FArchiveLocation := Ini.ReadString('Archive', 'Location', '');
    edtSkip.Checked := Ini.ReadBool('General', 'Skip Introduction', False);
  finally
    Ini.Free;
  end;
  if edtSkip.Checked then
    pcWizard.ActivePageIndex := 1
  else
    pcWizard.ActivePageIndex := 0;
end;

procedure TfrmConfigureTest.FormDestroy(Sender: TObject);
var
  Ini : TIniFile;
begin
  {save preferences}
  Ini := TIniFile.Create('SQLTester.ini');
  try
    Ini.WriteBool('General', 'Skip Introduction', edtSkip.Checked);
  finally
    Ini.Free;
  end;
  FreeAndNil(FTestQuery);
  FreeAndNil(FTester);
end;

procedure TfrmConfigureTest.tsTestInformationShow(Sender: TObject);
begin
  if edtDate.Text = '' then
    edtDate.Text := FormatDateTime('mm/dd/yyyy', Now);
  if edtRunCount.Text = '' then
    edtRunCount.Text := '1';
  if edtOrderID.Text = '' then
    edtOrderID.Text := IntToStr(dtmSQLTestEditor.GetNextOrderID);
  if edtMaxSourceReads.Text = '' then
    edtMaxSourceReads.Text := '-1';
  if edtCategory.ItemIndex = -1 then
    edtCategory.ItemIndex := 0;
  edtOrderID.SetFocus;
end;

procedure TfrmConfigureTest.btnSaveClick(Sender: TObject);
var
  NewGuid: TGuid;
  SysTime: TSystemTime;
begin
  Screen.Cursor := crHourglass;
  try
    ValidateRecord([]);
    GetSystemTime(SysTime);

    if FTester.Query <> nil then
      FTester.Query.Close;
    dtmSQLTestEditor.TestSession.CloseInactiveTables;

    Assert(Assigned(TestTable));
    if SaveMode = smNew then begin
      TestTable.Insert;
      CoCreateGuid(NewGuid);
      TestTable.FieldByName('UniqueID').AsString := GUIDToString(NewGuid);
      TestTable.FieldByName('TimeStamp').Value := SystemTimeToDateTime(SysTime);
    end else begin
      TestTable.Edit;
      TestTable.FieldByName('TimeStamp').Value := SystemTimeToDateTime(SysTime);
    end;

    SaveRecord;
    TestTable.Post;
  finally
    Screen.Cursor := crDefault;
  end;

  ModalResult := mrOK;
end;

procedure TfrmConfigureTest.SaveRecord;
var
  ZipFileName : string;
  Zipper : TAbZipper;
  PathName : array[0..MAX_PATH] of char;
  FileName : array[0..MAX_PATH] of char;
begin
  TestTable.FieldByName('OrderID').Value := edtOrderID.Text;
  TestTable.FieldByName('Category').Value := edtCategory.Text;
  TestTable.FieldByName('Name').Value := edtTestName.Text;
  TestTable.FieldByName('IssueID').Value := edtIssueID.Text;
  TestTable.FieldByName('Date').Value := edtDate.Text;
  TestTable.FieldByName('RunCount').Value := StrToInt(edtRunCount.Text);
  TestTable.FieldByName('Description').AsString := edtDescription.Lines.Text;
  TestTable.FieldByName('ResultType').Value := edtRResultType.ItemIndex;
  TestTable.FieldByName('IgnoreTest').Value := edtIgnoreTest.Checked;
  case edtRResultType.ItemIndex of
    1 : TestTable.FieldByName('ResultCode').Value := StrToInt(edtRErrorCode.Text);
    2 : TestTable.FieldByName('ResultString').Value := edtRErrorString.Text;
  end;

  TestTable.FieldByName('IgnoreTest').Value := False;

  TestTable.FieldByName('QueryPath').Value := edtQPath.Text;
  TestTable.FieldByName('ResultPath').Value := edtTablePath.Text;
  
  {save query properties}
  TestTable.FieldByName('QueryRequestLive').Value := edtQRequestLive.Checked;
  TestTable.FieldByName('QueryTimeout').Value := StrToInt(edtQTimeout.Text);

  TestTable.FieldByName('QuerySQL').AsString := edtQSQL.Lines.Text;
  TestTable.FieldByName('QueryResultSQL').AsString := memSQLExecResultSQL.Lines.Text;
  TestTable.FieldByName('QueryFilterString').Value := FQueryFilter.Filter;
  TestTable.FieldByName('QueryFiltered').Value := FQueryFilter.Filtered;
  TestTable.FieldByName('QueryFilterCaseInsensitive').Value := FQueryFilter.FilterOptionCaseInsensitive;
  TestTable.FieldByName('QueryFilterNoPartialCompare').Value := FQueryFilter.FilterOptionNoPartialCompare;
  TestTable.FieldByName('QueryFilterResync').Value := FQueryFilter.FilterResync;
  TestTable.FieldByName('QueryFilterTimeout').Value := FQueryFilter.FilterTimeout;
  TestTable.FieldByName('ResultMaxSourceReads').Value := edtMaxSourceReads.Text;

  {save result properties}
  TestTable.FieldByName('ResultFilterString').Value := FResultFilter.Filter;
  TestTable.FieldByName('ResultFiltered').Value := FResultFilter.Filtered;
  TestTable.FieldByName('ResultFilterCaseInsensitive').Value := FResultFilter.FilterOptionCaseInsensitive;
  TestTable.FieldByName('ResultFilterNoPartialCompare').Value := FResultFilter.FilterOptionNoPartialCompare;
  TestTable.FieldByName('ResultFilterResync').Value := FResultFilter.FilterResync;
  TestTable.FieldByName('ResultFilterTimeout').Value := FResultFilter.FilterTimeout;
  TestTable.FieldByName('SaveAs').Value := edtSaveAs.Text;

    {save query database}
  Zipper := TAbZipper.Create(nil);
  try
    Zipper.CompressionMethodToUse := smBestMethod;
    Zipper.DeflationOption := doMaximum;
    GetTempPath(MAX_PATH, @PathName);
    GetTempFileName(PathName, 'SQL', 0, @FileName);
    if FileExists(FileName) then
      DeleteFile(FileName);
    ZipFileName := ChangeFileExt(FileName, '.zip');
    Zipper.FileName := ZipFileName;
    Zipper.BaseDirectory := edtQPath.Text;
    Zipper.AddFiles('*.*', 0);
    Zipper.Save;
    Zipper.CloseArchive;
    Zipper.FileName := '';

    {save into table}
    TestTable.FieldByName('QueryDatabase').Clear;
    TBlobField(TestTable.FieldByName('QueryDatabase')).LoadFromFile(ZipFileName);
    DeleteFile(ZipFileName);

  finally
    Zipper.Free;
  end;

  {save result table}
  if edtRResultType.ItemIndex = 0 then begin
    Zipper := TAbZipper.Create(nil);
    try
      Zipper.CompressionMethodToUse := smBestMethod;
      Zipper.DeflationOption := doMaximum;
      GetTempPath(MAX_PATH, @PathName);
      GetTempFileName(PathName, 'SQL', 0, @FileName);
      if FileExists(FileName) then
        DeleteFile(FileName);
      Zipper.FileName := ZipFileName;
      Zipper.BaseDirectory := ExtractFilePath(edtTablePath.Text);
      Zipper.AddFiles(ExtractFileName(edtTablePath.Text), 0);
      Zipper.Save;
      Zipper.CloseArchive;
      Zipper.FileName := '';

      {save into table}

      TestTable.FieldByName('ResultTable').Clear;
      TBlobField(TestTable.FieldByName('ResultTable')).LoadFromFile(ZipFileName);
      DeleteFile(ZipFileName);
    finally
      Zipper.Free;
    end;
  end;

end;

procedure TfrmConfigureTest.ValidateRecord(const IgnoreOptions : TsqtIgnoreOptions);
  procedure Check(const Condition : Boolean; const Msg : string);
  begin
    if not Condition then
      raise Exception.Create(Msg);
  end;
var
  OrderID : Integer;
begin
  Check(edtOrderID.Text <> '', 'Must have an Order ID');
  OrderID := 0;
  try
    OrderID := StrToInt(edtOrderID.Text);
  except
    Check(False, 'OrderID must be a numeric value.');
  end;
  if OrderID <= 0 then
    Check(False, 'OrderID must be greater than zero.');
  Check(edtTestName.Text <> '', 'Must have a test name');
  Check(edtDate.Text <> '', 'Must have a test date');
  Check(edtQPath.Text <> '', 'Must have a query database path');
  SetCurrentDir(ExtractFilePath(Application.ExeName));
  Check(DirectoryExists(edtQPath.Text), 'Query database path must exist');
  Check(edtQTimeout.Text <> '', 'Must specify a query timeout');
  try
    StrToInt(edtQTimeout.Text);
  except
    Check(False, 'Timeout must be an integer');
  end;
  Check(edtRunCount.Text <> '', 'Must specify a run count');
  try
    StrToInt(edtRunCount.Text);
  except
    Check(False, 'Rn count must be an integer');
  end;

  Check(edtQSQL.Lines.Text <> 'SELECT', 'Must specify an SQL statement');
  Check(edtRResultType.ItemIndex <> -1, 'Must specify a result type');
  case edtRResultType.ItemIndex of
    0 : {dataset}
        begin
          if not (ioResultPath in IgnoreOptions) then begin
            Check(edtTablePath.Text <> '', 'Must specify a result table path');
            Check(FileExists(edtTablePath.Text), 'Result table must exist');
            if edtCategory.ItemIndex <> 0 then
              Check(memSQLExecResultSQL.Text <> '', 'Must have a ExecDirect test SQL');
          end;
        end;
    1 : {error code}
        begin
          Check(edtRErrorCode.Text <> '', 'Must specify a result error code');
          try
            StrToInt(edtRErrorCode.Text);
          except
            Check(False, 'Error code must be an integer');
          end;
        end;
    2 : {error string}
        Check(edtRErrorString.Text <> '', 'Must specify a result error string');
  end;
end;

procedure TfrmConfigureTest.btnTestTheTestClick(Sender: TObject);
var
  QAlias, RAlias : string;
  Errors : TStringList;
  ResultTbl : TffTable;
  RunTest : Boolean;
    { If True then run the test otherwise just open the query (i.e., the user
      is testing the query prior to specifying an output path). }
  PathName : array[0..MAX_PATH] of char;
  ResultPath,
  TempPath : string;
  CopyCmd : TStFileOperation;
  UserResponse : Word;
  QueryDBField, ResultTableField : TBLOBField;
begin
  { If we are editing an existing test & the database path & input tables
    do not exist then see if we should extract them from the existing record. }
  QueryDBField := TBLOBField(FTestTable.FieldByName('QueryDatabase'));
  if (SaveMode = smEdit) and
     (edtQPath.Text <> '') and
     (not QueryDBField.IsNull) and
     (not DirectoryExists(edtQPath.Text)) then begin
    UserResponse := MessageDlg(Format('Query database %s not found. ' + #13#10 +
                                      'Recreate from existing test record?',
                                      [edtQPath.Text]),
                               mtConfirmation, [mbYes, mbNo], 0);
    if UserResponse = mrYes then
      ExtractToDisk('QueryDatabase', edtQPath.Text + '\archive.zip');
  end;  { if }

  { If we are editing an existing test & the result table does not exist
    then see if we should extract it from the existing record. }
  ResultTableField := TBLOBField(FTestTable.FieldByName('ResultTable'));
  ResultPath := ExtractFileDir(edtTablePath.Text);
  if (SaveMode = smEdit) and
     (ResultPath <> '') and
     (not ResultTableField.IsNull) and
     (not DirectoryExists(ResultPath)) then begin
    UserResponse := MessageDlg(Format('Result table %s not found. ' + #13#10 +
                                      'Recreate from existing test record?',
                                      [edtTablePath.Text]),
                               mtConfirmation, [mbYes, mbNo], 0);
    if UserResponse = mrYes then
      ExtractToDisk('ResultTable', ResultPath + '\archive.zip');
  end;  { if }

  ValidateRecord([ioResultPath]);

  barProgress.Position := 0;
  lblRecCount.Visible := False;
  barProgress.Visible := True;
  Screen.Cursor := crHourglass;
  try
    FreeAndNil(ResultTbl);
    FreeAndNil(FTestQuery);
    FTester.Query := nil;
    FTester.ExecDirect := edtCategory.ItemIndex <> 0;
    FTester.ExecDirectSQL := memSQLExecResultSQL.Text;

    { create temp directory to run query from }
    GetTempPath(MAX_PATH, @PathName);
    TempPath := AddBackSlashS(string(PathName)) + IntToStr(GetTickCount);
    { add temp alias }
    QAlias := IntToStr(GetTickCount);
    dtmSQLTestEditor.TestSession.Open;
    dtmSQLTestEditor.TestSession.AddAliasEx(QAlias, TempPath);
    { copy tables to temp path }
    CopyCmd := TStFileOperation.Create(nil);
    try
      CopyCmd.Destination := TempPath;
      CopyCmd.SourceFiles.Add(ExpandFileName(AddBackSlashS(edtQPath.Text) + '*.*'));
      CopyCmd.Operation := fopCopy;
      CopyCmd.Options := [foFilesOnly, foNoConfirmation, foNoConfirmMkDir];
      CopyCmd.Execute;
    finally
      CopyCmd.Free;
    end;
    try
      { create query }
      FTestQuery := TffQuery.Create(nil);
      FTestQuery.SessionName := dtmSQLTestEditor.TestSession.SessionName;
      FTestQuery.DatabaseName := QAlias;
      FTestQuery.RequestLive := edtQRequestLive.Checked;
      FTestQuery.Timeout := StrToInt('0' + edtQTimeout.Text);
      SetDatasetFilter(FTestQuery, FQueryFilter);
      FTestQuery.SQL.Text := edtQSQL.Lines.Text;
      FTester.MaxSourceTableReads := StrToInt(edtMaxSourceReads.Text);

      FTester.Query := FTestQuery;
      dsResultSet.DataSet := nil;
      RunTest := True;
      case edtRResultType.ItemIndex of
        0 : {dataset}
            begin
              if edtTablePath.Text <> '' then begin
                FTester.ExpectedResult := rtDataset;

                { add temp alias }
                RAlias := IntToStr(GetTickCount+1);
                dtmSQLTestEditor.TestSession.AddAliasEx(RAlias,
                                                    ExtractFilePath(edtTablePath.Text));

                {create result dataset}
                ResultTbl := TffTable.Create(nil);
                ResultTbl.SessionName := dtmSQLTestEditor.TestSession.SessionName;
                ResultTbl.DatabaseName := RAlias;
                ResultTbl.TableName := ExtractFileName(edtTablePath.Text);
                SetDatasetFilter(ResultTbl, FResultFilter);
                FTester.ResultDataset := ResultTbl;
              end else
                RunTest := False;
              pcWizard.ActivePage := tsTestResults;
            end;
        1 : {error code}
            begin
              FTester.ExpectedResult := rtExceptionCode;
              FTester.ExceptionCode := StrToInt(edtRErrorCode.Text);
            end;
        2 : {error string}
            begin
              FTester.ExpectedResult := rtExceptionString;
              FTester.ExceptionString := edtRErrorString.Text;
            end;
      end;

      if RunTest then begin
        if FTester.Execute then
          ShowMessage('Test Passed')
        else begin
          Errors := TStringList.Create;
          try
            FTester.GetErrors(Errors);
            ShowMessage('Test Failed: ' + Errors.Text);
          finally
            Errors.Free;
          end;
        end;
      end else begin
        if FTester.ExecDirect then begin
          TffQuery(FTester.Query).ExecSQL;
          TffQuery(FTester.Query).SQL.Text := FTester.ExecDirectSQL;
          FTester.Query.Open;
        end else begin
          FTester.Query.Open;
        end;
      end;

      if FTester.Query.Active and
        (edtRResultType.ItemIndex = 0) then begin
        barProgress.Visible := False;
        dsResultSet.DataSet := FTester.Query;
        lblRecCount.Caption := Format('%d records in result set: %d source table reads',
                                      [FTester.Query.RecordCount, TffQuery(FTester.Query).RecordsRead]);
        lblRecCount.Visible := True;
      end;
    finally
      ResultTbl.Free;
      dtmSQLTestEditor.TestSession.CloseInactiveTables;

      {delete temporary files & dir}
      DeleteDirsOnClose.Add(TempPath);
    end;
  finally
    barProgress.Visible := False;
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmConfigureTest.btnConfigureFilterResultClick(Sender: TObject);
begin
  EditFilterProperties(FResultFilter);
end;

procedure TfrmConfigureTest.btnConfigureFilterQueryClick(Sender: TObject);
begin
  EditFilterProperties(FQueryFilter);
end;

procedure TfrmConfigureTest.btnBrowseResultClick(Sender: TObject);
begin
  dlgBrowse.FileName := edtTablePath.Text;
  if dlgBrowse.Execute then
    edtTablePath.Text := dlgBrowse.FileName;
end;

procedure TfrmConfigureTest.MapCategoryToCombo(const Category : string);
var
  Inx : Integer;
begin
  for Inx := 0 to Pred(edtCategory.Items.Count) do begin
    if edtCategory.Items[Inx] = Category then begin
      edtCategory.ItemIndex := Inx;
      Break;
    end;  { if }
  end;  { for }
end;

procedure TfrmConfigureTest.FormShow(Sender: TObject);
begin
  pbExtract.Enabled := (SaveMode = smEdit);
  if SaveMode = smEdit then begin
    if not TestTable.FieldByName('OrderID').IsNull then begin
      edtOrderID.Text := TestTable.FieldByName('OrderID').Value;
      Caption := Caption + ' - OrderID ' + edtOrderID.Text
    end;
    if not TestTable.FieldByName('Name').IsNull then
      edtTestName.Text := TestTable.FieldByName('Name').Value;
    if not TestTable.FieldByName('IssueID').IsNull then
      edtIssueID.Text := TestTable.FieldByName('IssueID').Value;
    if not TestTable.FieldByName('ResultMaxSourceReads').IsNull then
      edtMaxSourceReads.Text := TestTable.FieldByName('ResultMaxSourceReads').Value;
    if not TestTable.FieldByName('Category').IsNull then
      MapCategoryToCombo(TestTable.FieldByName('Category').Value);
    if not TestTable.FieldByName('Date').IsNull then
      edtDate.Text := TestTable.FieldByName('Date').Value;
    if not TestTable.FieldByName('RunCount').IsNull then
      edtRunCount.Text := TestTable.FieldByName('RunCount').AsString;
    if not TestTable.FieldByName('IgnoreTest').IsNull then
      edtIgnoreTest.Checked := TestTable.FieldByName('IgnoreTest').Value;
    if not TestTable.FieldByName('Description').IsNull then
      edtDescription.Lines.Text := TestTable.FieldByName('Description').AsString;
    if not TestTable.FieldByName('ResultType').IsNull then
      edtRResultType.ItemIndex := TestTable.FieldByName('ResultType').Value
    else
      edtRResultType.ItemIndex := 0;
    if not TestTable.FieldByName('ResultCode').IsNull then
      edtRErrorCode.Text := TestTable.FieldByName('ResultCode').AsString;
    if not TestTable.FieldByName('ResultString').IsNull then
      edtRErrorString.Text := TestTable.FieldByName('ResultString').AsString;

    if not TestTable.FieldByName('QueryPath').IsNull then
      edtQPath.Text := TestTable.FieldByName('QueryPath').Value;
    if not TestTable.FieldByName('ResultPath').IsNull then
      edtTablePath.Text := TestTable.FieldByName('ResultPath').Value;

    {save query properties}
    if not TestTable.FieldByName('QueryRequestLive').IsNull then
      edtQRequestLive.Checked := TestTable.FieldByName('QueryRequestLive').Value;
    if not TestTable.FieldByName('QueryTimeout').IsNull then
      edtQTimeout.Text := TestTable.FieldByName('QueryTimeout').AsString;

    if not TestTable.FieldByName('QuerySQL').IsNull then
      edtQSQL.Lines.Text := TestTable.FieldByName('QuerySQL').AsString;
    if not TestTable.FieldByName('QueryResultSQL').IsNull then
      memSQLExecResultSQL.Lines.Text := TestTable.FieldByName('QueryResultSQL').AsString;
    if not TestTable.FieldByName('QueryFilterString').IsNull then
      FQueryFilter.Filter := TestTable.FieldByName('QueryFilterString').Value;
    if not TestTable.FieldByName('QueryFiltered').IsNull then
      FQueryFilter.Filtered := TestTable.FieldByName('QueryFiltered').Value;
    if not TestTable.FieldByName('QueryFilterCaseInsensitive').IsNull then
      FQueryFilter.FilterOptionCaseInsensitive := TestTable.FieldByName('QueryFilterCaseInsensitive').Value;
    if not TestTable.FieldByName('QueryFilterNoPartialCompare').IsNull then
      FQueryFilter.FilterOptionNoPartialCompare := TestTable.FieldByName('QueryFilterNoPartialCompare').Value;
    if not TestTable.FieldByName('QueryFilterResync').IsNull then
      FQueryFilter.FilterResync := TestTable.FieldByName('QueryFilterResync').Value;
    if not TestTable.FieldByName('QueryFilterTimeout').IsNull then
      FQueryFilter.FilterTimeout := TestTable.FieldByName('QueryFilterTimeout').Value;

    {save result properties}
    if not TestTable.FieldByName('ResultFilterString').IsNull then
      FResultFilter.Filter := TestTable.FieldByName('ResultFilterString').Value;
    if not TestTable.FieldByName('ResultFiltered').IsNull then
      FResultFilter.Filtered := TestTable.FieldByName('ResultFiltered').Value;
    if not TestTable.FieldByName('ResultFilterCaseInsensitive').IsNull then
      FResultFilter.FilterOptionCaseInsensitive := TestTable.FieldByName('ResultFilterCaseInsensitive').Value;
    if not TestTable.FieldByName('ResultFilterNoPartialCompare').IsNull then
      FResultFilter.FilterOptionNoPartialCompare :=TestTable.FieldByName('ResultFilterNoPartialCompare').Value;
    if not TestTable.FieldByName('ResultFilterResync').IsNull then
      FResultFilter.FilterResync := TestTable.FieldByName('ResultFilterResync').Value;
    if not TestTable.FieldByName('ResultFilterTimeout').IsNull then
      FResultFilter.FilterTimeout := TestTable.FieldByName('ResultFilterTimeout').Value;
    if not TestTable.FieldByName('SaveAs').IsNull then
      edtSaveAs.Text := TestTable.FieldByName('SaveAs').Value;
  end
  else
    edtRResultType.ItemIndex := 0;
  edtCategoryChange(nil);
end;

procedure TfrmConfigureTest.btnBroseClick(Sender: TObject);
begin
  dlgBrowse.FileName := edtTablePath.Text;
  if dlgBrowse.Execute then
    edtTablePath.Text := dlgBrowse.FileName;
end;

procedure TfrmConfigureTest.pbSaveResultSetBrowseClick(Sender: TObject);
begin
  if edtSaveAs.Text = '' then
    dlgSave.InitialDir := ExtractFilePath(edtTablePath.Text);
  if edtSaveAs.Text = '' then
    dlgSave.FileName := ExtractFileName(edtTablePath.Text);
  if dlgSave.Execute then begin
    edtSaveAs.Text := dlgSave.FileName;
  end;
end;

procedure TfrmConfigureTest.edtSaveAsChange(Sender: TObject);
begin
  pbSaveResultSet.Enabled := (edtSaveAs.Text <> '');
end;

procedure TfrmConfigureTest.pbSaveResultSetClick(Sender: TObject);
var
  aDatabase : TffDatabase;
  aTable : TffTable;
  savCursor : TCursor;
begin
  if edtSaveAs.Text = '' then
    dlgSave.InitialDir := ExtractFilePath(edtTablePath.Text);
  if edtSaveAs.Text = '' then
    dlgSave.FileName := ExtractFileName(edtTablePath.Text);
  if dlgSave.Execute then begin
    edtSaveAs.Text := dlgSave.FileName;
    edtTablePath.Text := dlgSave.FileName;
  end else begin
    Exit;
  end;
  { Create a database for the output directory. }
  savCursor := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  aTable := nil;
  aDatabase := TffDatabase.Create(nil);
  try
    aDatabase.SessionName := dtmSQLTestEditor.Session.SessionName;
    aDatabase.AliasName := ExtractFilePath(edtSaveAs.Text);
    aDatabase.DatabaseName := 'SaveResultSet';
    try
      aDatabase.Open;
    except
      on E:Exception do begin
        ShowMessage('Could not create database for output file: ' +
                    E.Message);
        Exit;
      end;
    end;

    { Create the table based upon the result set query. }
    try
      aDatabase.CreateTable(True,
                            ChangeFileExt(ExtractFileName(edtSaveAs.Text), ''),
                            TffQuery(FTester.Query).Dictionary);
    except
      on E:Exception do begin
        ShowMessage('Could not create output table: ' +
                    E.Message);
        Exit;
      end;
    end;

    { Copy the records from the result set query to the new table. }
    try
      aTable := TffTable.Create(nil);
      try
        aTable.SessionName := dtmSQLTestEditor.Session.SessionName;
        aTable.DatabaseName := aDatabase.DatabaseName;
        aTable.TableName := ChangeFileExt(ExtractFileName(edtSaveAs.Text), '');
        aTable.Open;
        aTable.CopyRecords(TffQuery(FTester.Query), True);
      except
        on E:Exception do begin
          ShowMessage('Could not copy result set to output table: ' +
                      E.Message);
          Exit;
        end;
      end;
    finally
      aTable.Free;
    end;
  finally
    aDatabase.Free;
    Screen.Cursor := savCursor;
  end;
end;

procedure __FINAL;
var
  Idx : Integer;
  CopyCmd : TStFileOperation;
  DeleteDir : string;
begin
  for Idx := 0 to Pred(DeleteDirsOnClose.Count) do begin
    DeleteDir := DeleteDirsOnClose[Idx];
    CopyCmd := TStFileOperation.Create(nil);
    try
      CopyCmd.Destination := DeleteDir;
      CopyCmd.SourceFiles.Add(AddBackSlashS(DeleteDir) + '*.*');
      CopyCmd.Operation := fopDelete;
      CopyCmd.Options := [foSilent, foNoErrorUI, foNoConfirmation, foNoConfirmMkDir];
      CopyCmd.Execute;
      RmDir(DeleteDir);
    finally
      CopyCmd.Free;
    end;
  end;
  DeleteDirsOnClose.Free;
end;

procedure TfrmConfigureTest.edtCategoryChange(Sender: TObject);
begin
  if edtCategory.ItemIndex = 0 then begin
    tsCompareAgainst.TabVisible := False;
  end else begin
    tsCompareAgainst.TabVisible := True;  
  end;
end;

procedure TfrmConfigureTest.ExtractToDisk(const FieldName, ArchiveName : string);
var
  QueryDBField : TBLOBField;
  unzipper : TAbUnzipper;
  FullArchiveName,
  FullDirName : string;
begin
  FullArchiveName := ExpandFileName(ArchiveName);
  FullDirName := ExtractFileDir(FullArchiveName);
  QueryDBField := TBLOBField(FTestTable.FieldByName(FieldName));
  ForceDirectories(FullDirName);
  QueryDBField.SaveToFile(FullArchiveName);
  unzipper := TAbUnZipper.Create(nil);
  try
    unzipper.FileName := FullArchiveName;
    unzipper.BaseDirectory := FullDirName;
    unzipper.ExtractFiles('*.*');
    unzipper.Filename := '';
  finally
    unzipper.Free;
    DeleteFile(FullArchiveName);
  end;
end;

procedure TfrmConfigureTest.pbExtractClick(Sender: TObject);
var
  SavCursor : TCursor;
begin
  SavCursor := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  try
    SetCurrentDir(ExtractFilePath(Application.ExeName));
    ExtractToDisk('QueryDatabase', edtQPath.Text + '\archive.zip');
  finally
    Screen.Cursor := SavCursor;
  end;
end;

procedure TfrmConfigureTest.pbExtractResultClick(Sender: TObject);
var
  SavCursor : TCursor;
begin
  SavCursor := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  try
    SetCurrentDir(ExtractFilePath(Application.ExeName));
    ExtractToDisk('ResultTable', ExtractFileDir(edtTablePath.Text) + '\archive.zip');
  finally
    Screen.Cursor := SavCursor;
  end;
end;

initialization
  DeleteDirsOnClose := TStringList.Create;

finalization
  __FINAL;
  
end.
