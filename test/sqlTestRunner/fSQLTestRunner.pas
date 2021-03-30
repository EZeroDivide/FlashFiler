unit fSQLTestRunner;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, ffdb, ffsreng, ffsqleng, abzipper, abziptyp, utester, IniFiles,
  StdCtrls, ComCtrls, usqltesttypes, db,AbZBrows, AbUnZper,
  AbArcTyp, AbMeter, AbBrowse, AbBase, filectrl, DBTables, stfileop,
  StStrs, StUtils, StSystem;

const
  LogFileName = 'c:\SQLTestRunner.Results';

type

  TffRunMode = (rmVCL, rmODBC);

  TfrmSQLTestRunner = class(TForm)
    Timer1: TTimer;
    barProgress: TProgressBar;
    lblStatus: TLabel;
    lblCount: TLabel;
    procedure FormShow(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FODBCDatabase : TDatabase;
    FMode : TffRunMode;
    FRunType : string;
    FTempPath : string;

    procedure Cleanup(tblTests : TffTable;
                      Query : TDataSet;
                const QAliasName : string);
    procedure DeleteDirectory(const DirPath : string);
    procedure ExtractArchiveToDir(const ArchiveName, DirName : string);
    procedure PopulateQueryFilter(tblTests : TffTable; Filter : TsqtFilterProperties);
    procedure PopulateResultFilter(tblTests : TffTable; Filter : TsqtFilterProperties);
    procedure PrepareTestData(var QPath, RPath : string; tblTests: TffTable);
    function PrepQuery(tblTests : TffTable;
                 const QAliasName, QPath : string) : TDataSet;
    procedure RunTest(tblTests : TffTable; Log : TStrings);
    function RunTests : Boolean;
  public
    { Public declarations }
    property RunMode : TffRunMode read FMode write FMode;
    property RunType : string read FRunType write FRunType;
  end;

var
  frmSQLTestRunner: TfrmSQLTestRunner;
  TestsPath : string;
  DeleteDirsOnClose : TStringList;

implementation

uses
  ExCreateDSN,
  FFLLComm,
  FFLLLgcy,
  FFLLProt,
  FFLLThrd,
  FFSrCmd;

{$R *.DFM}

procedure ForceDeleteDirectory(const DirName: string);
begin
  DeleteFile(DirName + '\*.*');
  RemoveDir(DirName);
end;

procedure TfrmSQLTestRunner.FormCreate(Sender: TObject);
begin
  FMode := rmVCL;
  FRunType := 'SELECT';
end;

procedure TfrmSQLTestRunner.FormShow(Sender: TObject);
begin
  Timer1.Enabled := True;
end;

procedure TfrmSQLTestRunner.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := False;
  if not RunTests then begin
    showmessage(Format('Error running SQL tests. See log "%s" for details', [LogFileName]));
    ModalResult := mrNo;
  end else
    ModalResult := mrYes;
end;

function TfrmSQLTestRunner.RunTests: Boolean;
var
  TempLog,
  Log          : TStringList;
  sqlengine    : TffSqlEngine;
  serverengine : TffServerEngine;
  client       : TffClient;
  session      : TffSession;
  transport    : TffLegacyTransport;
  cmdHandler   : TffServerCommandHandler;
  thrdPool     : TffThreadPool;
  tblTests     : TffTable;
begin
  Log := TStringList.Create;

  { Open the table containing the tests. }
  sqlengine := TffSqlEngine.Create(nil);
  serverengine := TffServerEngine.Create(nil);
  serverengine.SQLEngine := sqlengine;

  if FMode = rmODBC then begin
    cmdHandler := TffServerCommandHandler.Create(nil);
    cmdHandler.ServerEngine := serverengine;

    thrdPool := TffThreadPool.Create(nil);

    transport := TffLegacyTransport.Create(nil);
    transport.RespondToBroadcasts := True;
    transport.Protocol := ptSingleUser;
    transport.Mode := fftmListen;
    transport.CommandHandler := cmdHandler;
    transport.ThreadPool := thrdPool;
    transport.Enabled := True;
  end
  else begin
    cmdHandler := nil;
    thrdPool := nil;
    transport := nil;
  end;

  client := TffClient.Create(nil);
  client.autoclientname := true;
  client.serverengine := serverengine;

  session := TffSession.Create(nil);
  session.AutoSessionName := true;
  session.ClientName := client.clientname;
  session.open;
  session.DeleteAliasEx('SQLTests');
  session.AddAliasEx('SQLTests', TestsPath);

  tblTests := TffTable.Create(nil);
  tblTests.SessionName := session.sessionname;
  tblTests.DatabaseName := 'SQLTests';
  tblTests.ReadOnly := True;
  tblTests.TableName :='SQLTests.ff2';
  tbltests.open;
  tblTests.IndexName := 'ByOrderID';
  tblTests.SetRange([FRunType],[FRunType]);
  try
//    if (FileExists(LogFileName)) then
//      DeleteFile(LogFileName);

    barProgress.Max := tblTests.RecordCount;
    barProgress.Position := 0;
    while not tblTests.eof do begin
      lblStatus.Caption := Format('Current test: %s',
                                  [tblTests.FieldByName('Name').Value]);
      barProgress.StepIt;
      lblCount.Caption := Format('Test %d of %d',
                                 [barProgress.Position, barProgress.Max]);
      Application.ProcessMessages;
      RunTest(tblTests, Log);
      Application.ProcessMessages;
      tblTests.Next;
    end;
  finally
    if Log.Count > 0 then begin
      if (FileExists(LogFileName)) then begin
        TempLog := TStringList.Create;
        try
          TempLog.LoadFromFile(LogFileName);
          TempLog.AddStrings(Log);
          Log.Clear;
          Log.AddStrings(TempLog);
        finally
          TempLog.Free;
        end;
      end;
      Log.SaveToFile(LogFileName);
    end;
    Result := Log.Count = 0;
    Log.Free;
    tblTests.Free;
    session.Free;
    client.Free;
    cmdHandler.Free;
    thrdPool.free;
    transport.free;
    serverengine.Free;
    sqlengine.Free;
    DeleteDirectory(FTempPath + '\sqltest_*');
  end;
end;

function TfrmSQLTestRunner.PrepQuery(tblTests : TffTable;
                               const QAliasName, QPath : string) : TDataSet;
begin
  Result := nil;

  { Create an alias on the FF Server. }
  tblTests.Session.AddAliasEx(QAliasName, QPath);

  case FMode of
    rmVCL :
      begin
        Result := TffQuery.Create(nil);
        with Result as TffQuery do begin
          SessionName := tblTests.Session.SessionName;
          DatabaseName := QAliasName;
          RequestLive := tblTests.FieldByName('QueryRequestLive').Value;
          Timeout := tblTests.FieldByName('QueryTimeout').Value;
          SQL.Text := tblTests.FieldByName('QuerySQL').AsString;
        end;  { with }
      end;
    rmODBC :
      begin
        { Create an ODBC DSN }
        CreateDSN(QAliasName, ptSingleUser, 'LocalServer', '', '', QAliasName);
        FODBCDatabase := TDatabase.Create(nil);
        FODBCDatabase.AliasName := QAliasName;
        FODBCDatabase.DatabaseName := 'ODBC_DB';
        FODBCDatabase.LoginPrompt := False;
        Result := TQuery.Create(nil);
        with Result as TQuery do begin
          DatabaseName := FODBCDatabase.DatabaseName;
          RequestLive := tblTests.FieldByName('QueryRequestLive').Value;
          SQL.Text := tblTests.FieldByName('QuerySQL').AsString;
        end;
      end;
  end;  { case }
end;

procedure TfrmSQLTestRunner.Cleanup(tblTests : TffTable;
                                    Query : TDataSet;
                              const QAliasName : string);
begin
  case FMode of
    rmVCL :
      begin
      end;
    rmODBC :
      begin
        DeleteDSN(QAliasName);
        FODBCDatabase.Free;
        FODBCDatabase := nil;
      end;
  end;  { case }

  { Remove the alias from FF Server. }
  tblTests.Session.DeleteAlias(QAliasName);

end;


procedure TfrmSQLTestRunner.RunTest(tblTests : TffTable; Log : TStrings);
var
  QAliasName, RAliasName,
  QPath, RPath : string;
  Test : TQueryTester;
  ResultTbl : TffTable;
  Query : TDataSet;
  FQueryFilter, FResultFilter : TsqtFilterProperties;
  RunCount : Integer;
  Idx : Integer;
  TempList : TStringList;
begin
  ResultTbl := nil;
  Test := nil;

  { extract data to temporary directories }
  PrepareTestData(QPath, RPath, tblTests);
  try

    { Prepare the query }
    QAliasName := IntToStr(GetTickCount);
    Query := PrepQuery(tblTests, QAliasName, QPath);
    Assert(Assigned(Query), 'Query not prepared');

    { add temp alias to hold result table }
    RAliasName := IntToStr(GetTickCount+1);
    tblTests.Session.AddAliasEx(RAliasName, RPath);

    try
      PopulateQueryFilter(tblTests, FQueryFilter);
      SetDatasetFilter(Query, FQueryFilter);

      Test := TQueryTester.Create(nil);
//      Test.ProgressBar := barProgress;
      Test.Query := Query;
      Test.RunMode := uTester.TffRunMode(FMode);
      Test.ExecDirect := RunType <> 'SELECT';
      Test.ExecDirectSQL := tblTests.FieldByName('QueryResultSQL').AsString;
      Test.MaxSourceTableReads := tblTests.FieldByName('ResultMaxSourceReads').Value;
      case tblTests.FieldByName('ResultType').Value of
        0 : {dataset}
            begin
              Test.ExpectedResult := rtDataset;

              {create result dataset}
              ResultTbl := TffTable.Create(nil);
              ResultTbl.SessionName := tblTests.Session.SessionName;
              ResultTbl.DatabaseName := RAliasName;
              ResultTbl.TableName := ExtractFileName(tblTests.FieldByName('ResultPath').Value);
              PopulateResultFilter(tblTests, FResultFilter);
              SetDatasetFilter(ResultTbl, FResultFilter);
              Test.ResultDataset := ResultTbl;
            end;
        1 : {error code}
            begin
              Test.ExpectedResult := rtExceptionCode;
              Test.ExceptionCode := StrToInt(tblTests.FieldByName('ResultCode').Value);
            end;
        2 : {error string}
            begin
              Test.ExpectedResult := rtExceptionString;
              Test.ExceptionString := tblTests.FieldByName('ResultString').Value
            end;
      end;
      for RunCount := 1 to tblTests.FieldByName('RunCount').Value do begin
        TempList := TStringList.Create;
        try
          if not Test.Execute then begin
            if not tblTests.FieldByName('IgnoreTest').Value then begin
              Test.GetErrors(TempList);
              Log.Add(Format('Error in Test orderID: %d, Name: %s',
                             [tblTests.FieldByName('OrderID').AsInteger,
                              tblTests.FieldByName('Name').Value]));
              for Idx := 0 to Pred(TempList.Count) do
                Log.Add(TempList[Idx]);
              Log.Add(' ');
              Log.Add(' ');
            end;
          end;
        finally
          TempList.Free;
        end;
      end;
    finally
      Test.Free;
      ResultTbl.Free;
      Cleanup(tblTests, Query, QAliasName);
      Query.Free;
      tblTests.Session.DeleteAlias(RAliasName);
    end;
  finally
    Screen.Cursor := crDefault;
    DeleteDirectory(QPath);
    DeleteDirectory(RPath);
  end;
end;

procedure TfrmSQLTestRunner.PopulateQueryFilter(tblTests : TffTable; Filter : TsqtFilterProperties);
begin
  Filter.Filter := tblTests.FieldByName('QueryFilterString').Value;
  Filter.Filtered := tblTests.FieldByName('QueryFiltered').Value;
  Filter.FilterEvalServer := tblTests.FieldByName('QueryFilterEval').AsBoolean;
  Filter.FilterOptionCaseInsensitive := tblTests.FieldByName('QueryFilterCaseInsensitive').Value;
  Filter.FilterOptionNoPartialCompare := tblTests.FieldByName('QueryFilterNoPartialCompare').Value;
  Filter.FilterResync := tblTests.FieldByName('QueryFilterResync').Value;
  Filter.FilterTimeout := tblTests.FieldByName('QueryFilterTimeout').Value;
end;

procedure TfrmSQLTestRunner.PopulateResultFilter(tblTests : TffTable; Filter : TsqtFilterProperties);
begin
  Filter.Filter := tblTests.FieldByName('ResultFilterString').Value;
  Filter.Filtered := tblTests.FieldByName('ResultFiltered').Value;
  Filter.FilterEvalServer := tblTests.FieldByName('ResultFilterEval').AsBoolean;
  Filter.FilterOptionCaseInsensitive := tblTests.FieldByName('ResultFilterCaseInsensitive').Value;
  Filter.FilterOptionNoPartialCompare := tblTests.FieldByName('ResultFilterNoPartialCompare').Value;
  Filter.FilterResync := tblTests.FieldByName('ResultFilterResync').Value;
  Filter.FilterTimeout := tblTests.FieldByName('ResultFilterTimeout').Value;
end;

procedure TfrmSQLTestRunner.PrepareTestData(var QPath, RPath : string; tblTests: TffTable);
var
  PathName : array[0..MAX_PATH] of char;
begin
  GetTempPath(MAX_PATH, @PathName);
  FTempPath := PathName;
  Delete(FTempPath, Length(FTempPath), 1);
  QPath := PathName + Format('sqltest_%d', [GetTickCount]);
  RPath := PathName + Format('sqltest_%d', [GetTickCount+1]);
  if not (CreateDir(QPath) and CreateDir(RPath)) then
    raise exception.create('could not create temporary directories');

  TBlobField(tblTests.FieldByName('QueryDatabase')).SaveToFile(QPath + '\archive.zip');
  ExtractArchiveToDir(QPath + '\archive.zip', QPath);

  if tblTests.FieldByName('ResultType').Value = 0 then begin
    TBlobField(tblTests.FieldByName('ResultTable')).SaveToFile(RPath + '\archive.zip');
    ExtractArchiveToDir(RPath + '\archive.zip', RPath);
  end;
end;

procedure TfrmSQLTestRunner.DeleteDirectory(const DirPath : string);
var
  SearchRec : TSearchRec;
  Path,
  SearchStr,
  CurrFile  : string;
begin
  if (DirPath[Length(DirPath)] = '*') then begin
    Path := Copy(DirPath, 1, Length(DirPath) - 10);
    SearchStr := 'sqltest_*.*';
  end else begin
    Path := DirPath;
    SearchStr := '*.*';
  end;

  if (DirectoryExists(Path)) then begin
    if (FindFirst(Path + '\' + SearchStr, faAnyFile, SearchRec) = 0) then begin
      CurrFile := Path + '\' + SearchRec.Name;
      if (IsDirectory(CurrFile)) then begin
        if ((SearchRec.Name <> '.') and
            (SearchRec.Name <> '..')) then begin
          if (IsDirectoryEmpty(CurrFile)= 1) then
            RemoveDir(CurrFile)
          else
            DeleteDirectory(CurrFile);
        end;
      end else
        DeleteFile(Currfile);

      while (FindNext(SearchRec) = 0) do begin
        CurrFile := Path + '\' + SearchRec.Name;
        if (IsDirectory(CurrFile)) then begin
          if ((SearchRec.Name <> '.') and
              (SearchRec.Name <> '..')) then begin
            if (IsDirectoryEmpty(CurrFile) = 1) then
              RemoveDir(CurrFile)
            else
              DeleteDirectory(CurrFile);
          end;
        end else
          DeleteFile(Currfile);
      end;

      FindClose(SearchRec);
    end;

    RemoveDir(Path);
  end;
end;

procedure TfrmSQLTestRunner.ExtractArchiveToDir(const ArchiveName, DirName : string);
var
  unzipper : TAbUnZipper;
begin
  unzipper := TAbUnZipper.Create(nil);
  try
    DeleteDirsOnClose.Add(DirName);
    unzipper.FileName := ArchiveName;
    unzipper.basedirectory := DirName;
    unzipper.ExtractFiles('*.*');
    unzipper.filename := '';
  finally
    unzipper.free;
  end;
end;

procedure __Init;
begin
  TestsPath := ExtractFilePath(Application.EXEName) + '..\SqlTestEditor\';
  DeleteDirsOnClose := TStringList.Create;
end;

procedure __Final;
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
      CopyCmd.SourceFiles.Add(AddBackSlashS(DeleteDir));
      CopyCmd.Operation := fopDelete;
      CopyCmd.Options := [foSilent, foNoErrorUI, foNoConfirmation, foNoConfirmMkDir];
      CopyCmd.Execute;
      RemoveDir(DeleteDir);
   finally
      CopyCmd.Free;
    end;
  end;
  DeleteDirsOnClose.Free;
end;

initialization
  __Init;

finalization
  __Final;


end.
