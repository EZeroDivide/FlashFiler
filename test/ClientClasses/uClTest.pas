unit uClTest;

{$I FFDefine.inc}

interface
uses
  TestFramework,
  SysUtils,
  Classes,
  Windows,
  Forms,
  stCrc,
  FFClCfg,
  db,
  DM301,
  ffllcomp,
  fflldict,
  FFLLEng,
  ffllprot,
  ffllcomm,
  ffllexcp,
  ffllbase,
  FFlllgcy,
  ffclreng,
  FFSQLEng,
  uClTBase;

const
  csBLOB = 'ExBLOB';
  csCust = 'ExCust';

type
  TffDataDictTests = class(TTestCase)
  protected
  public
  published
    procedure testHasBLOBs;
    procedure testRemoveField;
    procedure testRemoveFile;
  end;

  TffBugTests = class(TffBaseClientTest)
    protected
      procedure CreateTestRangeTable;
      procedure CreateTestTable338;
      procedure BZ938PostError(DataSet: TDataSet; E: EDatabaseError;
                               var Action: TDataAction);
      procedure Setup; override;
      procedure Teardown; override;

    published
      { Bugs entered into Bugzilla. }
      procedure BZ301;
        { AutoXXXXXName procedures don't work on TDataModule that is
          dynamically created. }
      procedure BZ412;
        { Server engine should allow multiple active filters. }
      procedure BZ938;
        { Server engine: Index entry not rolled back on key violation.}

      { Bugs originally entered into DevTrack. }
      procedure FFD205;
        { TffSession.GetAliasNames - Should clear the list. }
      procedure FFD206;
        { TffSession.GetAliasNames - does not free PffAliasDescriptors }
      procedure FFD209;
        { TffSession.GetTableNames does not free table descriptors }
      procedure FFD217;
        { Add TffDatabase.TryStartTransaction method }
      procedure FFD219;
        { TffDatabase.GetTableNames - Leaks memory }
      procedure FFD226;
        { TffDataSet.dsGetRecordCountPrim issues. }
      procedure FFD227;
        { TffSession, TffBaseDatabase, TffBaseDataset should have their own copy of the serverengine pointer. }
      procedure FFD228;
        { TffDataset - Default filter timeout should be 500 }
      procedure FFD229;
        { Setting database to exclusive tries to connect to the server }
      procedure FFD257;
        { Verify that we can build a table while a transaction is active. }
      procedure FFD284;
        { Cannot compile use of TffDatabase.InTransaction }
      procedure FFD290;
        { Cursor gets first record twice when first opened }
      procedure FFD291;
        { DatabaseTableExists does not work properly }
      procedure FFD292;
        { Serverengine.GetServerNames should have a timeout parameter}
      procedure FFD294;
        { Opening a table that has the readonly flag set will cause a list index out of bounds error. }
      procedure FFD299;
        { Cannot connect to server in IDE }
      procedure FFD306;
        { Open TffTable at run-time causes error }
      procedure FFD338;
        { AddIndex bug }
      procedure FFD361;
        { Using network...GotoCurrent produces a No Current Record error unnecessarily }
      procedure FFD362;
        { Call to locate results in a dataset with 1 record }
      procedure FFD366;
        { FindKey does not work as expected }
      procedure FFD372;
        { Table broken during open trans in IDE. }
      procedure FFD375;
        { Server crash if try to start multiple transactions using same
          database component. }
      procedure FFD609;
        { Setting database.SessionName results in errors when datasets are attached }
      procedure FFD608;
        { problem with IndexName property }
      procedure FFD556;
        { Setting database.connected=false results in error}
      procedure FFD968;
        { Setting a Transport to Inactive may cause Invalid handle to function error }
  end;

  TffClientTests = class(TffBaseClientTest)
    protected
      procedure Setup; override;
      procedure TearDown; override;
      procedure ServerCreationOrderIterator(Combination : array of integer;
                                      const IterationCount : Longint);

    published
      procedure ClientList; virtual;
      procedure DefaultClientExists; virtual;

      procedure DefaultSessionExists; virtual;
      procedure Helper_FindAutoFFClient; virtual;
      procedure Helper_FindDefaultFFClient; virtual;
      procedure Helper_FindDefaultFFSession; virtual;
      procedure Helper_FindFFClientName; virtual;
      procedure Helper_FindFfSessionName; virtual;
      procedure Helper_FindFFDatabasename; virtual;
      procedure Helper_GetDefaultFFClient; virtual;
      procedure Helper_GetDefaultFFSession; virtual;
      procedure Helper_GetFFClientNames; virtual;
      procedure Helper_GetFFSessionNames; virtual;
      procedure Helper_GetFFDatabaseNames; virtual;
      procedure Helper_Session; virtual;
      procedure Helper_FFSession; virtual;

      procedure Client_GetServerNames;
      procedure Client_IsConnected;
      procedure Client_ActiveProperty;
      procedure Client_ClientIDProperty;
      procedure Client_ClientNameProperty;
      procedure Client_CommsEngineNameProperty;
      procedure Client_IsDefaultProperty;
      procedure Client_ServerEngineProperty;
      procedure Client_SessionCountProperty;
      procedure Client_SessionsProperty;
      procedure Client_TimeOutProperty;
      procedure Client_UserNameProperty;
      procedure Client_VersionProperty;

      procedure CommsEngine_Create;
      procedure CommsEngine_Destroy;
      procedure CommsEngine_GetServerNames;
      procedure CommsEngine_IsConnected;
      procedure CommsEngine_ActiveProperty;
      procedure CommsEngine_ClientIDProperty;
      procedure CommsEngine_ClientNameProperty;
      procedure CommsEngine_CommsEngineNameProperty;
      procedure CommsEngine_IsDefaultProperty;
      procedure CommsEngine_ServerEngineProperty;
      procedure CommsEngine_SessionCountProperty;
      procedure CommsEngine_SessionsProperty;
      procedure CommsEngine_TimeOutProperty;
      procedure CommsEngine_UserNameProperty;
      procedure CommsEngine_VersionProperty;

      procedure CommsEngine_OpenNoTransport; //bug 1012
      procedure Client_OpenNoTreansport; //bug 1012;

      procedure ServerCreationOrderTest;
      procedure StdCreationOrderTest;
      procedure ExtCreationOrderTest;
  end;

  TffSessionTests = class(TffBaseClientTest)
  protected
    procedure Setup; override;
    procedure TearDown; override;
  published
    procedure testIsAlias;
  end;

  TffDatabaseTests = class(TffBaseClientTest)
  published
    procedure testCommit;
    procedure testExclusive;
    procedure testRollback;
    procedure testStartTransactionWith;
  end;


  TffRemoteServerEngineTests = class(TffBaseClientTest)
  protected
  public
  published
    procedure RSE_Create;
    procedure RSE_Destroy;
  end;

  TffQueryTests = class(TffBaseClientTest)
  protected
    FSQLEngine : TffSQLEngine;

    procedure PrepareContactTable;
    procedure Setup; override;
    procedure Teardown; override;
    procedure LoginEventRO(aSource   : TObject;
                       var aUserName : TffName;
                       var aPassword : TffName;
                       var aResult   : Boolean);
  public
    procedure DeleteTable(const TableName : string);
  published
    {==========  TffQuery tests  ========================}
    procedure testSQLParsed;
      { Verify that TffQuery.Text parameter returns SQL statement with
        parameters replaced by question marks. }

    procedure testParamsOnLeft_1136;
      { Issue 1136
        Verify that a parameter on the left hand side of an operator is
        handled correctly. }

    procedure testParamsSaved;
      { Verify that TffQuery.Params is saved to a resource file and is
        restored when the component is loaded. }

    procedure testEmptySQL;
      { Verify that an exception is raised when we attempt to open a TffQuery
        that has no SQL statement. }

    procedure testEmptySQLPrepare;
      { Verify that an exception is raised when we attempt to prepare a TffQuery
        that has no SQL statement. }

    procedure testParamsByName;
      { Verify that we can retrieve parameter instances by name. }

    procedure testParamCount;
      { Verify that TffQuery returns the proper parameter count for when no
        parameters are specified and for when > 0 parameters are specified. }

    procedure testPrepare;
      { Verify that we can prepare a SQL query and the Prepared property returns
        True. }

    procedure testRequestLiveFalse;
      { Verify that when RequestLive is False, we cannot update the resultset. }

    procedure testRequestLiveTrue;
      { Verify that when RequestLive is True, we can update the resultset. }

    procedure testReadOnlyRights;
      { Verify that a read-only user can select data but they cannot insert,
        update, or delete data. }

    procedure testRowCount;
      { Verify that when we perform a query, we obtain the correct number of
        records. }

    procedure testFirsttoEOF;
      { Verify that we can move from First to EOF in a resultset. }

    procedure testNoDBOpen;
      { Verify that we receive the correct exception when TffQuery.DatabaseName
        is not specified and we activate the TffQuery. }

    procedure testParamsUpdated;
      { Verify that when ParamCheck is True, changing the SQL regenerates the
        Params. }

    procedure testParamsNotUpdated;
      { Verify that when ParamCheck is False, changing the SQL does not
        regenerate the Params. }

    procedure testCircularDatasource;
      { Verify that we cannot create a circular datasource reference. }

    procedure testDatasource;
      { Verify that when we connect a datasource to the TffQuery, its parameters
        are used to populate the query. }

    procedure testMultInserts;
      { Verify that multiple records may be inserted within the same
        transaction. }

    procedure testMultDeletes;
      { Verify that multiple records may be deleted within the same
        transaction. }

    procedure testMultUpdates;
      { Verify that multiple records may be updated within the same
        transaction. }

    procedure testObeysRecLock_3752;
      { Verify that SQL DELETE & UPDATE obey a record lock. }

    procedure testObeysTableReadLock;
      { Verify that SQL INSERT, UPDATE, & DELETE obey a table read lock. }

    procedure testObeysTableWriteLock;
      { Verify that SQL INSERT, UPDATE, & DELETE obey a table write lock. }

    procedure testBLOBParam;
      { Verify that a parameter may obtain its value from a BLOB. }

  end;

  TffDatasetTests = class(TffBaseClientTest)
    procedure CreateContactTable(const aTableName : string);
    procedure CreateTestCaseTable;
  published
    { Introduced in TffDataset }
    procedure testAddFileBlob;
    procedure testBookmarkValid;
    procedure testCompareBookmarks;
    procedure testCopyRecords;
    procedure testCreateBlobStream;
    procedure testDeleteTable;
    procedure testEmptyTable;
    procedure testGetCurrentRecord;
    procedure testGetFieldData;
    procedure testGetRecordBatch;
    procedure testGetRecordBatchEx;
    procedure testGotoCurrent;
    procedure testInsertRecordBatch;
    procedure testLockTable;
    procedure testPackTable;
    procedure testReadBLOBs;
    procedure testRenameTable;
    procedure testRestructureTable;
    procedure testSetTableAutoIncValue;
    procedure testTruncateBlob;
    procedure testUnlockTable;
    procedure testUnlockTableAll;
    procedure testIsSequenced;
    procedure testSessionProp;
    procedure testCursorIDProp;
    procedure testDatabaseProp;
    procedure testDictionaryProp;
    procedure testServerEngineProp;
    procedure testDatabaseNameProp;
    procedure testFilterEvalProp;
    procedure testFilterResyncProp;
    procedure testFilterTimeoutProp;
    procedure testOnServerFilterTimeoutEvent;
    procedure testSessionNameProp;
    procedure testTimeoutProp;
    procedure testVersionProp;

    { Introduced in TffBaseTable }
    procedure testAddIndex;
    procedure testAddIndexEx;
    procedure testApplyRange;
    procedure testCancel;
    procedure testCancelRange;
    procedure testCreateTable;
    procedure testDeleteIndex;
    procedure testDeleteRecords;
    procedure testEditKey;
    procedure testEditRangeEnd;
    procedure testEditRangeStart;
    procedure testFFVersion;
    procedure testFindKey;
    procedure testFindNearest;
    procedure testGetIndexNames;
    procedure testGotoKey;
    procedure testGotoNearest;
    procedure testLocate;
    procedure testLookup;
    procedure testPost;
    procedure testReIndexTable;
    procedure testSetKey;
    procedure testSetRange;
    procedure testSetRangeEnd;
    procedure testSetRangeStart;

    { Introduced in TffTable }
    { No functionality intoduced! }


    { Inherited from TDataset }
    procedure testActiveBuffer;
    procedure testAppend;
    procedure testAppendRecord;
    procedure testCheckBrowseMode;
    procedure testClearFields;
    procedure testClose;
    procedure testControlsDisabled;
    procedure testCursorPosChanged;
    procedure testDelete;
    procedure testDisableControls;
    procedure testEdit;
    procedure testEnableControls;
    procedure testFieldByName;
    procedure testFindField;
    procedure testFindFirst;
    procedure testFindLast;
    procedure testFindNext;
    procedure testFindPrior;
    procedure testFirst;
    procedure testFreeBookmark;
    procedure testGetBookmark;
    procedure testGetDetailDataSets;
    procedure testGetDetailLinkFields;
    procedure testGetBlobFieldData;
    procedure testGetFieldData2;
    procedure testGetFieldData3;
    procedure testGetFieldList;
    procedure testGetFieldNames;
    procedure testGotoBookmark;
    procedure testInsert;
    procedure testInsertRecord;
    procedure testIsEmpty;
    procedure testIsLinkedTo;
    procedure testLast;
    procedure testMoveBy;
    procedure testNext;
    procedure testOpen;
    procedure testPrior;
    procedure testRecordCountAsync;
    procedure testRefresh;
    procedure testResync;
    procedure testSetFields;
    procedure testTranslate;
    procedure testUpdateCursorPos;
    procedure testUpdateRecord;
    procedure testUpdateStatus;
    procedure testAggFieldsProp;
    procedure testBofProp;
    procedure testBookmarkProp;
    procedure testCanModifyProp;
    procedure testDataSetFieldProp;
    procedure testDataSourceProp;
    procedure testDefaultFieldsProp;
    procedure testDesignerProp;
    procedure testEofProp;
    procedure testBlockReadSizeProp;
    procedure testFieldCountProp;
    procedure testFieldDefsProp;
    procedure testFieldDefListProp;
    procedure testFieldsProp;
    procedure testFieldListProp;
    procedure testFieldValuesProp;
    procedure testFoundProp;
    procedure testModifiedProp;
    procedure testObjectViewProp;
    procedure testRecordCountProp;
    procedure testRecNoProp;
    procedure testRecordSizeProp;
    procedure testSparseArraysProp;
    procedure testStateProp;
    procedure testFilterProp;
    procedure testFilteredProp;
    procedure testFilterOptionsProp;
    procedure testActiveProp;
    procedure testAutoCalcFieldsProp;
    procedure testBeforeOpenEvent;
    procedure testAfterOpenEvent;
    procedure testBeforeCloseEvent;
    procedure testAfterCloseEvent;
    procedure testBeforeInsertEvent;
    procedure testAfterInsertEvent;
    procedure testBeforeEditEvent;
    procedure testAfterEditEvent;
    procedure testBeforePostEvent;
    procedure testAfterPostEvent;
    procedure testBeforeCancelEvent;
    procedure testAfterCancelEvent;
    procedure testBeforeDeleteEvent;
    procedure testAfterDeleteEvent;
    procedure testBeforeScrollEvent;
    procedure testAfterScrollEvent;
    procedure testBeforeRefreshEvent;
    procedure testAfterRefreshEvent;
    procedure testOnCalcFieldsEvent;
    procedure testOnDeleteErrorEvent;
    procedure testOnEditErrorEvent;
    procedure testOnFilterRecordEvent;
    procedure testOnNewRecordEvent;
    procedure testOnPostErrorEvent;

    { Transaction-related }
    procedure testNestedTranPartialRollback;
    procedure testCursorCloseDuringTran;

    { Connection-related }
    procedure testConnection;
    procedure testConnection2;
  end;

function CreateContactDict : TffDataDictionary;

implementation
uses
  BaseTestCase,
  ffllthrd,
  ffsrsec,
  ffsrcmd,
  contactU,
  dialogs,
  FFConst,
  FFDB,
  FFDBBase,
  FFSrBDE,
  FFTbBase,
  ffsreng,
  fflllog,
  ShellAPI,
  ConnectTest,
  ConnectTest2,
  TestServer,
  {$IFDEF DCC6OrLater}
  Variants,
  {$ENDIF}
  uclExt;

const
  csByAge = 'byAge';
  csByState = 'byState';
  csContacts = 'Contacts';
  csContactsRen = 'ContactsRen';
  csEmail = 'Email';
  csPrimary = 'Primary';

{===Utility routines=================================================}
procedure CompareMatchedStreams(aOldSt, aNewSt : TStream; aCount : integer);
var
  OldChar, NewChar : Char;
  i : integer;
begin
  aOldSt.Position := 0;
  aNewSt.Position := 0;
  for i := 0 to pred(aCount) do begin
    aOldSt.Read(OldChar, 1);
    aNewSt.Read(NewChar, 1);
    assert(OldChar = NewChar, 'String mismatch at pos ' + intToStr(i));
  end;
end;
{--------}
function CreateContactDict : TffDataDictionary;
var
  FldArray : TffFieldList;
  IHFldList : TffFieldIHList;
begin

  Result := TffDataDictionary.Create(65536);
  with Result do begin

    { Add fields }
    AddField('ID', '', fftAutoInc, 0, 0, false, nil);
    AddField('FirstName', '', fftShortString, 25, 0, true, nil);
    AddField('LastName', '', fftShortString, 25, 0, true, nil);
    AddField('Age', '', fftInt16, 5, 0, false, nil);
    AddField('State', '', fftShortString, 2, 0, false, nil);
    AddField('DecisionMaker', '', fftBoolean, 0, 0, false, nil);

    { Add indexes }
    FldArray[0] := 0;
    IHFldList[0] := '';
    AddIndex('primary', '', 0, 1, FldArray, IHFldList, False, True, True);

    FldArray[0] := 2;
    IHFldList[0] := '';
    AddIndex('byLastName', '', 0, 1, FldArray, IHFldList, True, True, True);

    FldArray[0] := 1;
    IHFldList[0] := '';
    AddIndex('byFirstName', '', 0, 1, FldArray, IHFldList, True, True, True);

    FldArray[0] := 3;
    IHFldList[0] := '';
    AddIndex(csByAge, '', 0, 1, FldArray, IHFldList, True, True, True);

    FldArray[0] := 4;
    IHFldList[0] := '';
    AddIndex('byState', '', 0, 1, FldArray, IHFldList, True, True, True);

    FldArray[0] := 1;
    FldArray[1] := 2;
    IHFldList[0] := '';
    IHFldList[1] := '';
    AddIndex('byFullName', '', 0, 2, FldArray, IHFldList, True, True, True);

    FldArray[0] := 3;
    FldArray[1] := 4;
    IHFldList[0] := '';
    IHFldList[1] := '';
    AddIndex('byAgeState', '', 0, 2, FldArray, IHFldList, True, True, True);

    FldArray[0] := 4;
    FldArray[1] := 3;
    IHFldList[0] := '';
    IHFldList[1] := '';
    AddIndex('byStateAge', '', 0, 2, FldArray, IHFldList, True, True, True);

    FldArray[0] := 5;
    IHFldList[0] := '';
    AddIndex('byDecisionMaker', '', 0, 1, FldArray, IHFldList, True, True, True);

    FldArray[0] := 3;
    FldArray[1] := 4;
    IHFldList[0] := '';
    IHFldList[1] := '';
    AddIndex('byAgeDecisionMaker', '', 0, 2, FldArray, IHFldList, True, True, True);

  end;

end;
{====================================================================}

{===TffDataDictTests=================================================}
procedure TffDataDictTests.TestHasBLOBs;
var
  aDict : TffDataDictionary;
begin
  { Verify that table with no BLOBs returns False. }
  aDict := CreateContactDict;
  try
    Assert(not aDict.HasBLOBFields, 'test 1');

    { Verify that reloading the table resets internal FHasBLOBs flag. }
    aDict.Clear;
    with aDict do begin
      { Add fields }
      AddField('ID', '', fftAutoInc, 0, 0, false, nil);
      AddField('FirstName', '', fftShortString, 25, 0, true, nil);
      AddField('LastName', '', fftShortString, 25, 0, true, nil);
      AddField('Notes', '', fftBLOB, 0, 0, False, nil);
    end;

    { Verify that table with BLOBs returns True. }
    Assert(aDict.HasBLOBFields, 'test 2');
    aDict.Clear;

    Assert(not aDict.HasBLOBFields, 'test 3');
    with aDict do begin
      { Add fields }
      AddField('ID', '', fftAutoInc, 0, 0, false, nil);
      AddField('FirstName', '', fftShortString, 25, 0, true, nil);
      AddField('LastName', '', fftShortString, 25, 0, true, nil);
      AddField('Notes', '', fftBLOBFile, 0, 0, False, nil);
    end;
    Assert(aDict.HasBLOBFields, 'test 3');
  finally
    aDict.Free;
  end;

end;
{--------}
procedure TffDataDictTests.testRemoveField;
var
  FldArray : TffFieldList;
  IHFldList : TffFieldIHList;
  Dict : TffDataDictionary;
  ExceptRaised : Boolean;
begin

  Dict := TffDataDictionary.Create(65536);
  with Dict do
    try
      { Add fields }
      AddField('ID', '', fftAutoInc, 0, 0, false, nil);
      AddField('FirstName', '', fftShortString, 25, 0, true, nil);
      AddField('LastName', '', fftShortString, 25, 0, true, nil);
      AddField('Age', '', fftInt16, 5, 0, false, nil);
      AddField('State', '', fftShortString, 2, 0, false, nil);
      AddField('DecisionMaker', '', fftBoolean, 0, 0, false, nil);

      { Add files }
      AddFile('Inx1File', 'ix1', 4096, ftIndexFile);
      AddFile('Inx2File', 'ix2', 4096, ftIndexFile);

      { Verify field count }
      CheckEquals(6, Dict.FieldCount, 'Unexpected field count');

      { Add indexes each in its own file }
      FldArray[0] := 0;
      IHFldList[0] := '';
      AddIndex('Inx1', 'primary', 1, 1, FldArray, IHFldList, False, True, True);

      FldArray[0] := 2;
      IHFldList[0] := '';
      AddIndex('Inx2', 'by last name', 2, 1, FldArray, IHFldList, True, True, True);

      { Verify index count }
      CheckEquals(3, Dict.IndexCount, 'Unexpected index count');

      { Remove the LastName field. Should raise an exception because the field
        is still referenced by an index. }
      ExceptRaised := False;
      try
        RemoveField(2);
      except
        ExceptRaised := True;
      end;

      Check(ExceptRaised, 'Exception not raised when removing a field still referenced by an index');

      { Remove the index & then remove the field. }
      RemoveIndex(2);
      RemoveField(2);

      { Verify file & index counts. }
      CheckEquals(5, Dict.FieldCount, 'Unexpected post-remove field count');
      CheckEquals(2, Dict.IndexCount, 'Unexpected post-remove index count');

    finally
      Free;
    end;
end;
{--------}
procedure TffDataDictTests.testRemoveFile;
var
  FldArray : TffFieldList;
  IHFldList : TffFieldIHList;
  Dict : TffDataDictionary;
  ExceptRaised : Boolean;
begin

  Dict := TffDataDictionary.Create(65536);
  with Dict do
    try
      { Add fields }
      AddField('ID', '', fftAutoInc, 0, 0, false, nil);
      AddField('FirstName', '', fftShortString, 25, 0, true, nil);
      AddField('LastName', '', fftShortString, 25, 0, true, nil);
      AddField('Age', '', fftInt16, 5, 0, false, nil);
      AddField('State', '', fftShortString, 2, 0, false, nil);
      AddField('DecisionMaker', '', fftBoolean, 0, 0, false, nil);

      { Add files }
      AddFile('Inx1File', 'ix1', 4096, ftIndexFile);
      AddFile('Inx2File', 'ix2', 4096, ftIndexFile);

      { Verify file count }
      CheckEquals(3, Dict.FileCount, 'Unexpected file count');

      { Add indexes each in its own file }
      FldArray[0] := 0;
      IHFldList[0] := '';
      AddIndex('Inx1', 'primary', 1, 1, FldArray, IHFldList, False, True, True);

      FldArray[0] := 2;
      IHFldList[0] := '';
      AddIndex('Inx2', 'by last name', 2, 1, FldArray, IHFldList, True, True, True);

      { Verify index count }
      CheckEquals(3, Dict.IndexCount, 'Unexpected index count');

      { Remove the file for index 1. Should raise an exception because the file
        is still referenced by an index. }
      ExceptRaised := False;
      try
        RemoveFile(1);
      except
        ExceptRaised := True;
      end;

      Check(ExceptRaised, 'Exception not raised when removing a file still referenced by an index');

      { Remove the index & then remove the file. }
      RemoveIndex(1);
      RemoveFile(1);

      { Verify file & index counts. }
      CheckEquals(2, Dict.FileCount, 'Unexpected post-remove file count');
      CheckEquals(2, Dict.IndexCount, 'Unexpected post-remove index count');

      { Verify file number of remaining indices. }
      CheckEquals(0, Dict.IndexFileNumber[0], 'Unexpected file # for index 0');
      CheckEquals(1, Dict.IndexFileNumber[1], 'Unexpected file # for index 1');
    finally
      Free;
    end;
end;
{====================================================================}

{===TffBugTests======================================================}
procedure TffBugTests.BZ301;
var
  DM1, DM2, DM3 : TdmIssue301;
begin
  { We should be able to dynamically create multiple instances of an existing
    data module at run-time. }
  DM1 := TdmIssue301.Create(nil);
  try
    DM2 := TdmIssue301.Create(nil);
    try
      DM3 := TdmIssue301.Create(nil);
      try
      finally
        DM3.Free;
      end;
    finally
      DM2.Free;
    end;
  finally
    DM1.Free;
  end;

end;
{--------}
procedure TffBugTests.BZ412;
var
  db : TffDatabase;
  t  : TffTable;

  procedure erzeuge(monat:string;nummer:word);
  begin
    t.append;
    t.fieldbyname('monat').asstring   :=monat;
    t.fieldbyname('nummer').asinteger :=nummer;
    t.post;
  end;

begin
  db := TffDatabase.create(nil);
  try
    db.aliasname := clAliasName;
    db.databasename := 'testdb';
    db.SessionName := FSession.SessionName;
    db.open;

    t := tfftable.create(nil);
    try
      t.SessionName := FSession.SessionName;
      t.databasename:='testdb';
      t.tablename:='issue412';

      t.fielddefs.add('monat',ftstring,4,false);
      t.fielddefs.add('nummer',ftword,0,false);
      t.indexdefs.add('haupt','monat;nummer',[]);
      t.createtable;
      t.open;

      erzeuge('0100',1);
      erzeuge('0100',2);
      erzeuge('0100',3);
      erzeuge('0200',1);
      erzeuge('0200',2);
      erzeuge('0200',3);

      t.filter := 'monat = '+#39+'0100'+#39;
      t.timeout := 0;
      t.filterTimeout := 1000000;
      t.filtered := True;
      t.first;

      CheckEquals(1, t.fieldbyname('nummer').AsInteger, 'Test 1');
      t.locate('nummer',3,[]);
      CheckEquals(3, t.fieldbyname('nummer').AsInteger, 'Test 2');
      t.filtered := False;

      t.filter := 'monat = '+#39+'0200'+#39;
      t.filtered := True;
      t.first;
      CheckEquals(1, t.fieldbyname('nummer').AsInteger, 'Test 3');
      t.locate('nummer',3,[]);
      CheckEquals(3, t.fieldbyname('nummer').AsInteger, 'Test 4');
      t.filtered := False;
      t.close;
    finally
      t.free;
    end;
    db.close;
  finally
    db.free;
  end;
end;
{--------}
procedure TffBugTests.BZ938PostError(DataSet: TDataSet; E: EDatabaseError;
                                 var Action: TDataAction);
begin
  Action := daAbort;
end;
{--------}
procedure TffBugTests.BZ938;
var
  db : TffDatabase;
  i : integer;
  t  : TffTable;
begin
  db := TffDatabase.create(nil);
  try
    db.aliasname := clAliasName;
    db.databasename := 'testdb';
    db.SessionName := FSession.SessionName;
    db.open;

    t := tfftable.create(nil);
    try
      t.SessionName := FSession.SessionName;
      t.databasename:='testdb';
      t.tablename:='issue412';

      t.fielddefs.add('test', ftInteger, 0, false);
      t.indexdefs.add('nonUnique','test', []);
      t.indexdefs.add('unique', 'test', [ixUnique]);
      t.createtable;
      t.OnPostError := BZ938PostError;
      t.open;

      db.StartTransaction;
      try
        for i := 1 to 100 do
          try
            t.Append;
            t.Fields[0].AsInteger := 1;
            t.Post;
          except
          end;
        if t.State = dsInsert then
          t.Cancel;
      finally
        db.Commit;
      end;
      { Verify that each index contains 1 record. }
      i := 0;
      t.IndexName := 'nonUnique';
      t.First;
      while not t.EOF do begin
        inc(i);
        t.Next;
      end;
      CheckEquals(1, i, Format('nonUnique index has %d records', [i]));

      i := 0;
      t.IndexName := 'unique';
      t.First;
      while not t.EOF do begin
        inc(i);
        t.Next;
      end;
      CheckEquals(1, i, Format('unique index has %d records', [i]));

    finally
      t.free;
    end;
    db.close;
  finally
    db.free;
  end;
end;
{--------}
procedure TffBugTests.FFD205;
  { TffSession.GetAliasNames - Should clear the list. }
var
  aList : TStringList;
  aRealCount : Integer;
begin
  aList := TStringList.Create;
  try
    Session.GetAliasNames(aList);
    aRealCount := aList.Count;

    aList.Clear;
    aList.Add('~!@#$%^&*()');
    Session.GetAliasNames(aList);
    Assert(aRealCount = aList.Count);
  finally
    aList.Free;
  end;
end;
{--------}
procedure TffBugTests.FFD206;
  { TffSession.GetAliasNames - does not free PffAliasDescriptors }
var
  aList : TStringList;
begin
  aList := TStringList.Create;
  try
    Session.GetDatabaseNames(aList);
  finally
    aList.Free;
  end;
end;
{--------}
procedure TffBugTests.FFD209;
  { TffSession.GetTableNames does not free table descriptors }
var
  aList : TStringList;
begin
  aList := TStringList.Create;
  try
    Session.GetTableNames(clAliasName,
                          '*.ff2',
                          False,
                          False,
                          aList);
  finally
    aList.Free;
  end;
end;
{--------}
procedure TffBugTests.FFD217;
  { Add TffDatabase.TryStartTransaction method }
var
  TransactionStarted: Boolean;
begin
  TransactionStarted := Database.TryStartTransaction;
  Assert(TransactionStarted);
  try
    // do something with ffTable1
    if TransactionStarted then
      Database.Commit;
  except
    if TransactionStarted then
      Database.Rollback
    else
      Database.TransactionCorrupted;
    raise;
  end;

(*Database.StartTransaction;
  try
    try
      TransactionStarted := Database.TryStartTransaction;
      Assert(not TransactionStarted);
      try
        raise Exception.Create('Close me');
        // do something with ffTable1
        if TransactionStarted then
          Database.Commit;
      except
        if TransactionStarted then
          Database.Rollback
        else
          Database.TransactionCorrupted;
        raise;
      end;
    finally
      Database.Commit;
    end;
  except
    on E:Exception do begin
      Assert(E is EffDatabaseError, 'Invalid exception type');
      Assert(15443 = EffDatabaseError(E).ErrorCode,
                   'Invalid error code');
    end else
      raise;
  end;*)
end;
{--------}
procedure TffBugTests.FFD219;
  { TffDatabase.GetTableNames - Leaks memory }
var
  aList : TStringList;
begin
  aList := TStringList.Create;
  try
    Database.GetTableNames(aList);
  finally
    aList.Free;
  end;
end;
{--------}
procedure TffBugTests.FFD226;
  { TffDataSet.dsGetRecordCountPrim issues. }
var
  aTable : TffTable;
begin
  aTable := TffTable.Create(nil);
  try
    aTable.SessionName := FSession.SessionName;
    aTable.DatabaseName := FDatabase.DatabaseName;
    aTable.TableName := csCust;
    aTable.Open;
    aTable.Filter := '[state] = ''NC''';
    aTable.Filtered := True;
    aTable.RecordCount;
  finally
    aTable.Free;
  end;
end;
{--------}
procedure TffBugTests.FFD227;
  { TffSession, TffBaseDatabase, TffBaseDataset should have their own copy of the serverengine pointer. }
begin
  Assert((Client.ServerEngine = Session.ServerEngine) and
         (Client.ServerEngine = Database.ServerEngine)
         );
end;
{--------}
procedure TffBugTests.FFD228;
  { TffDataset - Default filter timeout should be 500 }
var
  aTable : TffTable;
begin
  aTable := TffTable.Create(nil);
  try
    Assert(aTable.FilterTimeout = 500);
  finally
    aTable.Free;
  end;
end;
{--------}
procedure TffBugTests.FFD229;
  { Setting database to exclusive tries to connect to the server }
var
  aDatabase : TffDatabase;
begin
  aDatabase := TffDatabase.Create(nil);
  try
    aDatabase.Exclusive := True;
    aDatabase.Exclusive := False;
  finally
    aDatabase.Free;
  end;
end;
{--------}
procedure TffBugTests.FFD257;
var
  Dict : TffDataDictionary;
  ExceptRaised : boolean;
  ExceptMsg : string;
  Table : TffTable;
begin
  ExceptRaised := False;
  FDatabase.StartTransaction;
  Table := nil;
  try
    { Create a table. }
    Dict := CreateContactDict;
    try
      FDatabase.CreateTable(true, csContacts, Dict);
    finally
      Dict.Free;
    end;

    { Open the table and insert a record. }
    Table := TffTable.Create(nil);
    try
      Table.SessionName := Session.SessionName;
      Table.DatabaseName := Database.DatabaseName;
      Table.TableName := csContacts;
      Table.Open;

      with Table do begin
        Insert;
        fieldByName('FirstName').asString := 'Ick';
        fieldByName('LastName').asString := 'Oook';
        fieldByName('Age').asInteger := 100;
        fieldByName('State').asString := 'CO';
        fieldByName('DecisionMaker').asBoolean := false;
        Post;
      end;

      FDatabase.Commit;
      Table.Close;
    except
      on E:Exception do begin
        ExceptRaised := True;
        ExceptMsg := E.message;
        FDatabase.Rollback;
      end;
    end;
  finally
    Table.Free;
  end;

  Assert(not ExceptRaised, 'Exception raised: ' + ExceptMsg);
end;
{--------}
procedure TffBugTests.FFD284;
begin
  if Database.InTransaction then;
end;
{--------}
procedure TffBugTests.FFD290;
  { Cursor gets first record twice when first opened }
var
  aTable  : TffTable;
  aString : string;
begin
  aTable := TffTable.Create(nil);
  try
    aTable.SessionName := FSession.SessionName;
    aTable.DatabaseName := FDatabase.DatabaseName;
    aTable.TableName := csCust;
    with aTable do begin
      Open;
      aString := '';
      while not EOF do begin
        Assert(aString <> aTable.FieldByName('CustomerID').AsString);
        aString := aTable.FieldByName('CustomerID').AsString;
        Next;
      end;
      Close;
    end;
  finally
    aTable.Free;
  end;
end;
{--------}
procedure TffBugTests.FFD291;
  { DatabaseTableExists does not work properly }
begin
  Assert(Database.TableExists(csCust));
  Assert(Database.TableExists('ExCust.FF2'));
  Assert(Database.TableExists('ExCust.ff2'));
end;
{--------}
procedure TffBugTests.FFD292;
 { Serverengine.GetServerNames should have a timeout parameter}
var
  aList : TStringList;
begin
  aList := TStringList.Create;
  try
    Client.GetServerNames(aList);
  finally
    aList.Free;
  end;
end;
{--------}
procedure TffBugTests.FFD294;
  { Opening a table that has the readonly flag set will cause a list index out
    of bounds error. }
const
  cFile = 'ExCust';
  cSourceFile = clDatabasePath + '\sav' + cFile + '.bak';
  cDestFile = clDatabasePath + '\' + cFile + '_.ff2';
var
  aTable : TffTable;
begin
  if FileExists(cDestFile) then DeleteFile(cDestFile);
  CopyFile(cSourceFile, cDestFile, False);
  FileSetAttr(cDestFile, SysUtils.faReadOnly);
  try
    aTable := TffTable.Create(nil);
    try
      aTable.SessionName := FSession.SessionName;
      aTable.DatabaseName := FDatabase.DatabaseName;
      aTable.TableName := csCust;
      aTable.Open;
    finally
      aTable.Free;
    end;
  finally
    FileSetAttr(cDestFile, 0);
    DeleteFile(cDestFile);
  end;
end;
{--------}
procedure TffBugTests.FFD299;
  { Cannot connect to server in IDE }
var
  LClient : TffClient;
  LSession : TffSession;
  LList : TStringList;
begin
  { This test can only be run with remote server engine. }
  if not RemoteEngine then
    Exit;
  LClient := TffClient.Create(nil);
  try
    LClient.ClientName := 'FFD299';
    LSession := TffSession.Create(nil);
    try
      LSession.ClientName := 'FFD299';
      LSession.Sessionname := 'FFD299';
      LSession.Open;
      LList := TStringList.Create;
      try
        LSession.GetDatabaseNames(LList);
      finally
        LList.Free;
      end;
    finally
      LSession.Free;
    end;
  finally
    LClient.Free;
  end;
end;
{--------}
procedure TffBugTests.FFD306;
  { Open TffTable at run-time causes error }
var
  TBL : TffTable;
begin
  TBL := TffTable.Create(nil);
  try
    { Make sure all components are inactive. }
    FClient.Active := False;
    TBL.SessionName := FSession.SessionName;
    TBL.DatabaseName := FDatabase.DatabaseName;
    TBL.TableName := csCust;
    TBL.Open;
  finally
    TBL.Free;
  end;
end;
{--------}
procedure TffBugTests.FFD338;
  { AddIndex bug }
var
  tbl : TffTable;
begin
  Database.Open;

  tbl := TffTable.Create(nil);
  try
    tbl.DatabaseName := Database.DatabaseName;
    tbl.TableName := 'Table338';
    tbl.SessionName := FSession.SessionName;
    tbl.AddIndex('rbWord','rbWord',[ixUnique]);
    tbl.AddIndex('rbLike','rbLike',[]);
  finally
    tbl.Free;
  end;
end;
{--------}
type
  TFFD361 = class(TObject)
  public
    FFTable1 : TffTable;
    FFTable3 : TffTable;
    DataSource1 : TDataSource;
    procedure DataSource1DataChange(Sender: TObject; Field: TField);
    constructor Create;
    destructor Destroy; override;
    procedure Open;
    procedure Transverse;
  end;
{--------}
constructor TFFD361.Create;
begin
  FFTable1 := TffTable.Create(nil);
  FFTable3 := TffTable.Create(nil);
  DataSource1 := TDataSource.Create(nil);

  FFTable1.DatabaseName := clDatabaseName;
  FFTable1.SessionName := clSessionName;
  FFTable1.TableName := csCust;

  FFTable3.DatabaseName := clDatabaseName;
  FFTable3.SessionName := clSessionName;
  FFTable3.TableName := csCust;
end;
{--------}
destructor TFFD361.Destroy;
begin
  Datasource1.Free;
  FFTable3.Free;
  FFTable1.Free;
  inherited Destroy;
end;
{--------}
procedure TFFD361.Open;
begin
  FFTable1.Open;
  FFTable3.Open;
  DataSource1.DataSet := FFTable1;
end;
{--------}
procedure TFFD361.DataSource1DataChange(Sender: TObject; Field: TField);
begin
  if (FFTable3 = nil) or (FFTable1 = nil) then exit;
  if ffTable3.IndexName <> ffTable1.IndexName then
     ffTable3.IndexName := ffTable1.IndexName;
  FFTable3.GotoCurrent(FFTable1);
end;
{--------}
procedure TFFD361.Transverse;
begin
  FFTable1.First;
  while not FFTable1.EOF do
    FFTable1.Next;
end;
{--------}
procedure TffBugTests.FFD361;
  { Using network...GotoCurrent produces a No Current Record error unnecessarily }
var
  TestObject : TFFD361;
begin
  TestObject := TFFD361.Create;
  try
    TestObject.Open;
    TestObject.Transverse;
  finally
    TestObject.Free;
  end;
end;
{--------}
procedure TffBugTests.FFD362;
  { Call to locate results in a dataset with 1 record }
var
  tbl : TffTable;
begin
  Database.Open;

  tbl := TffTable.Create(nil);
  try
    tbl.DatabaseName := Database.DatabaseName;
    tbl.TableName := 'TestRange';
    tbl.SessionName := clSessionName;
    tbl.Open;
    tbl.IndexName := 'ikeyDate';
    Assert(tbl.RecordCount = 7);
    tbl.SetRange(['2'],['2']);
    Assert(tbl.RecordCount = 4);
    tbl.Locate('date','b',[]);
    Assert(tbl.RecordCount = 4);
    tbl.CancelRange;
    Assert(tbl.RecordCount = 7);
    tbl.close;
  finally
    tbl.Free;
  end;
end;
{--------}
procedure TffBugTests.FFD366;
  {FindKey does not work as expected}
var
  aTable  : TffTable;
  aString : string;
begin
  aTable := TffTable.Create(nil);
  try
    aTable.SessionName := FSession.SessionName;
    aTable.DatabaseName := FDatabase.DatabaseName;
    aTable.TableName := csCust;
    with aTable do begin
      Open;
      IndexName := 'ByName';
      First;

      aString := aTable.FieldByName('LastName').AsString;

      Assert(Locate('LastName', aString, []));
      Assert(FindKey([aString]));
      close;
    end;
  finally
    aTable.Free;
  end;
end;
{--------}
procedure TffBugTests.FFD372;
const
  cNumRecs = 200;
var
  Index : Longint;
  IndexStr : string;
  originalRecCount : Longint;
  Table : TffTable;
begin
  { Assumption: Database already connected. }
  Table := TffTable.Create(nil);
  try
    Table.SessionName := Session.SessionName;
    Table.DatabaseName := Database.DatabaseName;
    Table.TableName := csCust;
    Table.Timeout := 5000;

    CreateExCustTable;

    { Strategy:
      1. Start a transaction.
      2. Insert a bunch of records.
      3. Terminate the connection such that the database does not have
         a chance to commit.
      4. Re-open the table and scan the records.  Should have only those
         that were originally in the table. }
    Table.Open;
    originalRecCount := Table.RecordCount;

    Table.Database.StartTransaction;

    with Table do
      for Index := 1 to cNumRecs do begin
        IndexStr := intToStr(Index);
        Insert;
        fieldByName('CustomerID').asInteger := Index + 1000000;
        fieldByName('FirstName').asString := IndexStr;
        fieldByName('LastName').asString := IndexStr;
        fieldByName('Address').asString := IndexStr;
        fieldByName('City').asString := IndexStr;
        fieldByName('State').asString := IndexStr;
        fieldByName('Zip').asString := IndexStr;
        Post;
      end;

    { Terminate the connection. }
    FClient.Active := False;

    { Re-open the table. }
    FClient.Active := True;
    FSession.Active := True;
    FDatabase.Connected := True;
    Table.Open;

    { Does the record count match? }
    CheckEquals(originalRecCount, Table.RecordCount);

    { Can we scan through the records. }
    while not Table.EOF do begin
      Table.Next;
    end;

  finally
    Table.Free;
  end;

  { Sleep long enough so that the server-side garbage collection cleans up
    our aborted transaction. }
//  Sleep(65 * 1000);
end;
{--------}
procedure TffBugTests.FFD375;
var
  ExceptRaised : boolean;
  Table : TffTable;
begin
  {!!!see Expect note below}
  Exit;

  { Assumption: Database already connected. }
  Table := TffTable.Create(nil);
  try
    Table.SessionName := Session.SessionName;
    Table.DatabaseName := Database.DatabaseName;
    Table.TableName := csCust;
    Table.Timeout := 50000;

    CreateExCustTable;

    Table.Open;
    FDatabase.StartTransaction;
    Table.Last;
    Table.First;
    ExceptRaised := False;
    try
      { Expect: Exception raised since transaction already started
        on this database. TODO: Revise test when expose nested
        transactions on client side. }
      FDatabase.StartTransaction;
    except
      on E:EffException do
        ExceptRaised := True;
    end;
    Assert(not ExceptRaised, 'Exception not raised');
  finally
    Table.Free;
  end;

end;
{--------}
procedure TffBugTests.FFD609;
var
  aTbl1 : TffTable;
  aTbl2 : TffTable;
begin
  aTbl1 := TffTable.Create(nil);
  try
    aTbl1.DatabaseName := FDatabase.DatabaseName;
    aTbl1.SessionName  := FDatabase.SessionName;
    aTbl1.TableName := 'ExCust';
    aTbl1.Open;
    aTbl2 := TffTable.Create(nil);
    try
      aTbl2.DatabaseName := FDatabase.DatabaseName;
      aTbl2.SessionName  := FDatabase.SessionName;
      aTbl2.TableName := 'ExCust';
      aTbl2.Open;
      FSession.AutoSessionName := True;
      FDatabase.SessionName := FSession.SessionName;
    finally
      aTbl2.Free;
    end;
  finally
    aTbl1.Free;
  end;
end;
{--------}
procedure TffBugTests.FFD608;
  { problem with IndexName property }
var
  tbl : TffTable;
  ixlist : TStringList;
  ixList2 : TStringList;
begin
  ixlist := TStringList.Create;
  ixList2 := TStringList.Create;
  try
    tbl := TffTable.Create(nil);
    try
      tbl.SessionName := Session.SessionName;
      tbl.DatabaseName := Database.DatabaseName;
      tbl.TableName := 'ExCust';
      tbl.GetIndexNames(ixlist);
      tbl.TableName := 'ExBlob';
      tbl.GetIndexNames(ixList2);
      Assert(ixlist.Count <> ixList2.Count);
    finally
      tbl.Free;
    end;
  finally
    ixlist.Free;
    ixList2.Free;
  end;
end;
{--------}
procedure TffBugTests.FFD556;
var
  TP : TffBaseTransport;
  RSE : TffRemoteServerEngine;
  CL : TffClient;
  SS : TffSession;
  DB : TffDatabase;
begin
  { This test can only be run with remote server engine. }
  if not RemoteEngine then
    Exit;

  TP := TffLegacyTransport.Create(nil);
  try
    RSE := TffremoteServerEngine.Create(nil);
    try
      RSE.Transport := TP;
      CL := TffClient.Create(nil);
      try
        CL.AutoClientName := True;
        CL.ServerEngine := RSE;
        SS := TffSession.Create(nil);
        try
          SS.AutoSessionName := True;
          SS.ClientName := CL.ClientName;
          SS.Open;
          Assert(TP.Enabled);
          Assert(CL.Active);
          Assert(SS.Active);

          TP.Enabled := False;
          Assert(not TP.Enabled);
          Assert(not CL.Active);
          Assert(not SS.Active);

          SS.Open;
          Assert(TP.Enabled);
          Assert(CL.Active);
          Assert(SS.Active);

          DB := TffDatabase.Create(nil);
          try
            DB.AliasName := 'examples';
            DB.AutoDatabaseName := True;
            DB.SessionName := SS.SessionName;
            DB.Open;
            Assert(TP.Enabled);
            Assert(CL.Active);
            Assert(SS.Active);
            Assert(DB.Connected);

            TP.Enabled := False;
            Assert(not TP.Enabled);
            Assert(not CL.Active);
            Assert(not SS.Active);
            Assert(not DB.Connected);

            DB.Open;
            Assert(TP.Enabled);
            Assert(CL.Active);
            Assert(SS.Active);
            Assert(DB.Connected);

            CL.Close;
            Assert(TP.Enabled);
            Assert(not CL.Active);
            Assert(not SS.Active);
            Assert(not DB.Connected);

          finally
            DB.Free;
          end;
        finally
          SS.Free;
        end;
      finally
        CL.Free;
      end;
    finally
      RSE.Free;
    end;
  finally
    TP.Free;
  end;
end;
{====================================================================}

{===TffClientTests===================================================}
procedure TffBugTests.CreateTestRangeTable;
const
  cFile = 'TestRange';
begin
  CloneTable('sav' + cFile, cFile);
end;
{--------}
procedure TffBugTests.CreateTestTable338;
const
  cFile = 'Table338';
begin
  CloneTable('sav' + cFile, cFile);
end;
{--------}
procedure TffBugTests.Setup;
begin
  inherited Setup;

  CreateTestTable338;
  CreateTestRangeTable;
end;
{--------}
procedure TffBugTests.Teardown;
begin
  DeleteFile(clDatabasePath + '\Table338');
  DeleteFile(clDatabasePath + '\TestRange');

  inherited Teardown;
end;
{--------}
procedure TffClientTests.Setup;
begin
  inherited Setup;
end;
{--------}
procedure TffClientTests.Teardown;
begin
  DeleteFile(clDatabasePath + '\TestRange');

  inherited Teardown;
end;
{--------}
procedure TffClientTests.Client_ActiveProperty;
var
  Client : TFfClient;
begin
  Client := TffClient(GetDefaultFfClient);
  Client.Close;
  Assert(not Client.Active, 'Invalid Result 1');
  Client.Open;
  Assert(Client.Active, 'Invalid Result 2');
  Client.Active := False;
  Assert(not Client.Active, 'Invalid Result 3');
  Client.Active := True;
  Assert(Client.Active, 'Invalid Result 4');
  Client.Active := False;                                              {!!.10}
end;
{--------}
procedure TffClientTests.Client_ClientIDProperty;
var
  Client : TFfClient;
begin
  Client := TffClient(GetDefaultFfClient);
  Client.Close;
  Assert(Client.ClientID = 0, 'Invalid Result 1');
  Client.Open;
  Assert(Client.ClientID = 0, 'Invalid Result 2');
  Client.Close;
  Assert(Client.ClientID = 0, 'Invalid Result 3');
end;
{--------}
procedure TffClientTests.Client_ClientNameProperty;
var
  Client : TFfClient;
  ClName : String;
  OldClName : string;
begin
  Client := TFfClient(GetDefaultFfClient);
  OldClName := Client.ClientName;
  try
    Client.Open;
    try
      Client.ClientName := 'ERROR';
      Assert(False, 'You should not be able to set the clientname with the component is active');
    except
    end;

    Client.Close;
    ClName := '_' + IntToStr(GetTickCount);
    Client.ClientName := ClName;
    Assert(Client.ClientName = ClName, 'Client name could not be set');

    Client.Close;
    ClName := '_' + IntToStr(GetTickCount);
    Client.CommsEngineName := ClName;
    Assert(Client.ClientName = ClName, 'Client and Commsenginename do not match');

    Assert(Client.ClientName = Client.CommsEngineName, 'Client and Commsenginename do not match');
  finally
    Client.ClientName := OldClName;
  end;
end;
{--------}
procedure TffClientTests.Client_CommsEngineNameProperty;
var
  Client : TFfClient;
  ClName : String;
  OldClName : string;
begin
  Client := TFfClient(GetDefaultFfClient);
  OldClName := Client.ClientName;
  try
    Client.Open;
    try
      Client.CommsEngineName := 'ERROR';
      Assert(False, 'You should not be able to set the clientname with the component is active');
    except
    end;

    Client.Close;
    ClName := '_' + IntToStr(GetTickCount) + '1';
    Client.CommsEngineName := ClName;
    Assert(Client.CommsEngineName = ClName, 'Client name could not be set');

    Client.Close;
    ClName := '_' + IntToStr(GetTickCount) + '2';
    Client.ClientName := ClName;
    Assert(Client.CommsEngineName = ClName, 'Client and Commsenginename do not match');

    Assert(Client.ClientName = Client.CommsEngineName, 'Client and Commsenginename do not match');

    Client.Close;
    Client.ClientName := Client.ClientName;
  finally
    Client.ClientName := OldClName;
  end;
end;
{--------}
procedure TffClientTests.Client_GetServerNames;
var
  List : TStringList;
  Client : TFfClient;
begin
  List := TStringList.Create;
  Client := TFfClient(GetDefaultFfClient);
  try
    Client.ServerEngine := Self.Client.ServerEngine;
    Client.Open;
    Client.GetServerNames(List);
    Assert(List.Count = 1, 'Invalid Result 2');
  finally
    List.Free;
  end;
end;
{--------}
procedure TffClientTests.Client_IsConnected;
var
  Client : TFfClient;
begin
  Client := TFfClient(GetDefaultFfClient);

  Assert(not Client.IsConnected, 'Invalid Result 1');
end;
{--------}
procedure TffClientTests.Client_IsDefaultProperty;
var
  Client : TFfClient;
begin
  Client := TFfClient(GetDefaultFfClient);

  Assert(Client.IsDefault, 'Invalid Result');
end;
{--------}
procedure TffClientTests.Client_ServerEngineProperty;
var
  Client : TFfClient;
  SEng : TffServerEngine;
begin
  Client := TFfClient(GetDefaultFfClient);
  SEng := TffServerEngine.Create(nil);
  try

    Client.ServerEngine := SEng;
    Assert(Client.ServerEngine = SEng, 'Property not set correctly');

    Client.ServerEngine := nil;
    Assert(Client.ServerEngine = nil, 'Property not set correctly');
  finally
    SEng.Free;
    { Note: DO NOT free the default client. }
  end;
end;
{--------}
procedure TffClientTests.Client_SessionCountProperty;
var
  Client : TFfClient;
begin
  Client := TFfClient(GetDefaultFfClient);

  Assert(Client.SessionCount = 1, 'Invalid Result');
end;
{--------}
procedure TffClientTests.Client_SessionsProperty;
var
  Client : TFfClient;
begin
  Client := TFfClient(GetDefaultFfClient);

  Assert(Client.Sessions[0].IsDefault, 'Invalid Result 1');
end;
{--------}
procedure TffClientTests.Client_TimeOutProperty;
var
  Client : TFfClient;
begin
  Client := TFfClient(GetDefaultFfClient);
  Client.TimeOut := 999;
  Assert(Client.TimeOut = 999, 'Property not set correctly');
end;
{--------}
procedure TffClientTests.Client_UserNameProperty;
var
  Client : TFfClient;
begin
  Client := TFfClient(GetDefaultFfClient);
  Client.UserName := 'UserName';
  Assert(Client.UserName = 'UserName', 'Property not set correctly');

  Client := TFfClient(GetDefaultFfClient);
  Client.UserName := '';
  Client.Open;
  try
    Client.UserName := 'UserName';
  except
  end;
  Assert(Client.UserName = '', 'Property set, but component was active');
end;
{--------}
procedure TffClientTests.Client_VersionProperty;
var
  Client : TFfClient;
begin
  Client := TFfClient(GetDefaultFfClient);
  CheckEquals(Format('%5.4f', [ffVersionNumber / 10000.0]),
              Client.Version, Format('Invalid Version %s', [Client.Version]));
end;
{--------}
procedure TffClientTests.ClientList;
begin
  Assert(Assigned(Clients), 'Clients list not valid');
end;
{--------}
procedure TffClientTests.CommsEngine_ActiveProperty;
var
  CommsEngine : TffCommsEngine;
begin
  CommsEngine := TffCommsEngine.Create(nil);
  try
    Commsengine.AutoClientName := True;
    Assert(not CommsEngine.Active, 'Invalid Result 1');
    CommsEngine.Open;
    Assert(CommsEngine.Active, 'Invalid Result 2');

    {---}

    CommsEngine.Active := False;
    Assert(not CommsEngine.Active, 'Invalid Result 3');
    CommsEngine.Active := True;
    Assert(CommsEngine.Active, 'Invalid Result 4');
  finally
    CommsEngine.Free;
  end;
end;
{--------}
procedure TffClientTests.CommsEngine_ClientIDProperty;
var
  CommsEngine : TffCommsEngine;
begin
  CommsEngine := TffCommsEngine.Create(nil);
  try
    CommsEngine.AutoClientName := True;
    Assert(CommsEngine.ClientID = 0, 'Invalid Result 1');
    CommsEngine.Open;
    Assert(CommsEngine.ClientID = 0, 'Invalid Result 2');
    CommsEngine.Close;
    Assert(CommsEngine.ClientID = 0, 'Invalid Result 3');
  finally
    CommsEngine.Free;
  end;
end;
{--------}
procedure TffClientTests.CommsEngine_ClientNameProperty;
var
  ClName : String;
  CommsEngine : TffCommsEngine;
begin
  CommsEngine := TffCommsEngine.Create(nil);
  try
    Commsengine.AutoClientName := True;
    CommsEngine.Open;
    try
      CommsEngine.ClientName := 'ERROR';
      Assert(False, 'You should not be able to set the clientname with the component is active');
    except
    end;

    CommsEngine.Close;
    ClName := '_' + IntToStr(GetTickCount);
    CommsEngine.ClientName := ClName;
    Assert(CommsEngine.ClientName = ClName, 'Client name could not be set');

    CommsEngine.Close;
    ClName := '_' + IntToStr(GetTickCount);
    CommsEngine.CommsEngineName := ClName;
    Assert(CommsEngine.ClientName = ClName, 'Client and Commsenginename do not match');

    Assert(CommsEngine.ClientName = CommsEngine.CommsEngineName, 'Client and Commsenginename do not match');
  finally
    CommsEngine.Free;
  end;
end;
{--------}
procedure TffClientTests.CommsEngine_CommsEngineNameProperty;
var
  ClName : String;
  CommsEngine : TffCommsEngine;
begin
  CommsEngine := TffCommsEngine.Create(nil);
  try
    Commsengine.AutoClientName := True;
    CommsEngine.Open;
    try
      CommsEngine.CommsEngineName := 'ERROR';
      Assert(False, 'You should not be able to set the clientname with the component is active');
    except
    end;

    CommsEngine.Close;
    ClName := '_' + IntToStr(GetTickCount) + '1';
    CommsEngine.CommsEngineName := ClName;
    Assert(CommsEngine.CommsEngineName = ClName, 'Client name could not be set');

    CommsEngine.Close;
    ClName := '_' + IntToStr(GetTickCount) + '2';
    CommsEngine.ClientName := ClName;
    Assert(CommsEngine.CommsEngineName = ClName, 'Client and Commsenginename do not match');

    Assert(CommsEngine.ClientName = CommsEngine.CommsEngineName, 'Client and Commsenginename do not match');

    CommsEngine.Close;
    CommsEngine.ClientName := CommsEngine.ClientName;
  finally
    CommsEngine.Free;
  end;
end;
{--------}
procedure TffClientTests.CommsEngine_Create;
var
  ACE : TFfCommsEngine;
begin
  ACE := TFfCommsEngine.Create(nil);
  ACE.Free;

  ACE := TFfCommsEngine.Create(Application);
  ACE.Free;
end;
{--------}
procedure TffClientTests.CommsEngine_Destroy;
var
  ACE : TFfCommsEngine;
  Comp : TComponent;
begin
  ACE := TFfCommsEngine.Create(nil);
  ACE.Free;

  Comp := TComponent.Create(nil);
  ACE := TFfCommsEngine.Create(Comp);
  Comp.Free;
  try
    ACE.ProtocolClass;
    Assert(False, 'Comms engine not destroyed correctly');
  except
  end;
end;
{--------}
procedure TffClientTests.CommsEngine_GetServerNames;
var
  List : TStringList;
  CommsEngine : TffCommsEngine;
begin
  CommsEngine := TffCommsEngine.Create(nil);
  try
    CommsEngine.AutoClientName := True;
    List := TStringList.Create;
    try
      CommsEngine.ServerEngine := Self.Client.ServerEngine;
      CommsEngine.Open;
      CommsEngine.GetServerNames(List);
      Assert(List.Count = 1, 'Invalid Result 2');
    finally
      List.Free;
    end;
  finally
    CommsEngine.Free;
  end;
end;
{--------}
procedure TffClientTests.CommsEngine_IsConnected;
var
  CommsEngine : TffCommsEngine;
begin
  CommsEngine := TffCommsEngine.Create(nil);
  try
    CommsEngine.AutoClientName := True;
    Assert(not CommsEngine.IsConnected, 'Invalid Result 1');
  finally
    CommsEngine.Free;
  end;
end;
{--------}
procedure TffClientTests.CommsEngine_IsDefaultProperty;
var
  Client      : TffBaseClient;
  CommsEngine : TffCommsEngine;
begin
  Client := nil;
  CommsEngine := TffCommsEngine.Create(nil);
  try
    CommsEngine.AutoClientName := True;

    Assert(not CommsEngine.IsDefault, 'Invalid Result');

    Client := GetDefaultFFClient;

    CommsEngine.IsDefault := True;

    Assert(CommsEngine.IsDefault, 'Invalid Result');
  finally
    if Client <> nil then
      Client.IsDefault := True;
    CommsEngine.Free;
  end;
end;
{--------}
procedure TffClientTests.CommsEngine_ServerEngineProperty;
var
  SEng : TffServerEngine;
  CommsEngine : TffCommsEngine;
begin
  CommsEngine := TffCommsEngine.Create(nil);
  try
    SEng := TffServerEngine.Create(nil);
    try
      CommsEngine.ServerEngine := SEng;
      Assert(CommsEngine.ServerEngine = SEng, 'Property not set correctly');

      CommsEngine.ServerEngine := nil;
      Assert(CommsEngine.ServerEngine = nil, 'Property not set correctly');
    finally
      SEng.Free;
    end;
  finally
    CommsEngine.Free;
  end;
end;
{--------}
procedure TffClientTests.CommsEngine_SessionCountProperty;
var
  CommsEngine : TffCommsEngine;
begin
  CommsEngine := TffCommsEngine.Create(nil);
  try
    CommsEngine.AutoClientName := True;
    Assert(CommsEngine.SessionCount = 0, 'Invalid Result');
  finally
    CommsEngine.Free;
  end;
end;
{--------}
procedure TffClientTests.CommsEngine_SessionsProperty;
var
  CommsEngine : TffCommsEngine;
begin
  CommsEngine := TffCommsEngine.Create(nil);
  try
    CommsEngine.AutoClientName := True;
    Assert(CommsEngine.SessionCount = 0, 'Invalid Result');
  finally
    CommsEngine.Free;
  end;
end;
{--------}
procedure TffClientTests.CommsEngine_TimeOutProperty;
var
  CommsEngine : TffCommsEngine;
begin
  CommsEngine := TffCommsEngine.Create(nil);
  try
    CommsEngine.AutoClientName := True;
    CommsEngine.TimeOut := 999;
    Assert(CommsEngine.TimeOut = 999, 'Property not set correctly');
  finally
    CommsEngine.Free;
  end;
end;
{--------}
procedure TffClientTests.CommsEngine_UserNameProperty;
var
  CommsEngine : TffCommsEngine;
begin
  CommsEngine := TffCommsEngine.Create(nil);
  try
    CommsEngine.AutoClientName := True;
    CommsEngine.UserName := 'UserName';
    Assert(CommsEngine.UserName = 'UserName', 'Property not set correctly');

    CommsEngine.UserName := '';
    CommsEngine.Open;
    try
      CommsEngine.UserName := 'UserName';
    except
    end;
    Assert(CommsEngine.UserName = '', 'Property set, but component was active');
  finally
    CommsEngine.Free;
  end;
end;
{--------}
procedure TffClientTests.CommsEngine_VersionProperty;
var
  CommsEngine : TffCommsEngine;
begin
  CommsEngine := TffCommsEngine.Create(nil);
  try
    CommsEngine.AutoClientName := True;
    CheckEquals(Format('%5.4f', [ffVersionNumber / 10000.0]),
                Client.Version, Format('Invalid Version %s', [CommsEngine.Version]));
  finally
    CommsEngine.Free;
  end;
end;
{--------}
procedure TffClientTests.DefaultClientExists;
var
  Idx : Integer;
begin
  Assert(Clients.Count <> 0);
  for Idx := 0 to Pred(Clients.Count) do
    if TFfBaseClient(Clients[Idx]).IsDefault then
      Exit;
  Assert(False, 'No default client found');
end;
{--------}
procedure TffClientTests.DefaultSessionExists;
var
  Client : TFfBaseClient;
  Idx : Integer;
begin
  Client := nil;
  for Idx := 0 to Pred(Clients.Count) do
    if TFfBaseClient(Clients[Idx]).IsDefault then
      Client := TFfBaseClient(Clients[Idx]);

  if not Assigned(Client) then
    Exit;

  for Idx := 0 to Pred(Client.SessionCount) do
    if Client.Sessions[Idx].IsDefault then
      Exit;
  Assert(False, 'No default session found');
end;
{--------}
procedure TffClientTests.Helper_FFSession;
begin
  Assert(FFDB.FFSession = FFDB.Session, 'Invalid Result 1');
end;
{--------}
procedure TffClientTests.Helper_FindAutoFFClient;
var
  Client : TffBaseClient;
begin
  Client := FindAutoFFClient;
  Assert(Assigned(Client), 'No client returned by FindAutoFFClient');
  Assert(Client.ClientName = AutoObjName, 'Invalid Result 1');
end;
{--------}
procedure TffClientTests.Helper_FindDefaultFFClient;
var
  Client : TFfBaseClient;
begin
  Client := FindDefaultFfClient;
  Assert(Client.IsDefault, 'Invalid Result 1');
end;
{--------}
procedure TffClientTests.Helper_FindDefaultFFSession;
var
  Session : TFfSession;
begin
  Session := FindDefaulTFfSession;
  Assert(Session.IsDefault, 'Invalid Result 1');
end;
{--------}
procedure TffClientTests.Helper_FindFFClientName;
var
  Client : TFfBaseClient;
begin
  Client := FindFfClientName(AutoObjName);
  Assert(Assigned(Client), 'No client returned by FindFFClientName');
  Assert(Client.ClientName = AutoObjName, 'Invalid Result 1');

  Client := FindFfClientName('xx');
  Assert(Client = nil, 'Invalid Result 3');
end;
{--------}
procedure TffClientTests.Helper_FindFFDatabasename;
var
  Database : TFfBaseDatabase;
begin
  { test that a database is not returned for an invalid name }
  Database := FindFfDatabaseName(Session, 'INVALID_NAME', False);
  Assert(not Assigned(Database), 'Invalid Result 1');
  if Assigned(Database) then Database.Free;

  { test that a database is not returned for an invalid name }
  { even thought the create parameter is set }
  Database := FindFfDatabaseName(Session, 'INVALID_NAME', True);
  Assert(not Assigned(Database), 'Invalid Result 5');
  if Assigned(Database) then Database.Free;

  Session.Open;
  Session.AddAliasEx('Test', 'c:\test\ff2');

  Database := FindFfDatabaseName(Session, 'Test', True);
  Assert(Assigned(Database), 'Invalid Result 9');

  Database := FindFfDatabaseName(Session, 'Test', False);
  Assert(Assigned(Database), 'Invalid Result 10');
  if Assigned(Database) then Database.Free;
end;
{--------}
procedure TffClientTests.Helper_FindFfSessionName;
var
  Session : TFfSession;
begin
  Session := FindFfSessionName(AutoObjName);
  Assert(Session.SessionName = AutoObjName, 'Invalid Result 1');
end;
{--------}
procedure TffClientTests.Helper_GetDefaultFFClient;
var
  Client : TFfBaseClient;
begin
  Client := GetDefaultFfClient;
  Assert(Client.IsDefault, 'Invalid Result');

  TffClient(Client).Active := False;
  Client.ClientName := 'XX';
  Client.IsDefault := False;

  try
    GetDefaultFfClient;
  except
    on EFFDatabaseError do
    else
      Assert(False, 'Appropriate exception was not raised');
  end;

  Client.ClientName := AutoObjName;
  Client.IsDefault := True;
end;
{--------}
procedure TffClientTests.Helper_GetDefaultFFSession;
var
  Session : TFfSession;
begin
  Session := GetDefaultFfSession;
  Assert(Session.IsDefault, 'Invalid Result');

  Session.SessionName := 'XX';
  Session.IsDefault := False;

  try
    GetDefaultFfSession;
  except
    on EFFDatabaseError do
    else
      Assert(False, 'Appropriate exception was not raised');
  end;

  Session.SessionName := AutoObjName;
  Session.IsDefault := True;
end;
{--------}
procedure TffClientTests.Helper_GetFFClientNames;
var
  Names : TStringList;
begin
  Names := TStringList.Create;
  try
    GetFfClientNames(Names);
    Assert(Names.Count = 3, 'Invalid Result 1');
  finally
    Names.Free;
  end;
end;
{--------}
procedure TffClientTests.Helper_GetFFDatabaseNames;
var
  Names : TStringList;
begin
  Names := TStringList.Create;
  try
    Session.Open;
    Session.AddAliasEx('xxx', 'c:\1');
    GetFfDatabaseNames(Session, Names);
    Assert(Names.IndexOf('xxx') > -1, 'Invalid Result 1');
  finally
    Names.Free;
  end;
end;
{--------}
procedure TffClientTests.Helper_GetFFSessionNames;
var
  Names : TStringList;
begin
  Names := TStringList.Create;
  try
    GetFfSessionNames(Names);
    Assert(Names.Count = 2, 'Invalid Result 1');
  finally
    Names.Free;
  end;
end;
{--------}
procedure TffClientTests.Helper_Session;
begin
  Assert(FfSession = FFDB.Session, 'Invalid Result 1');
end;
{====================================================================}

{===TffSessionTests==================================================}
procedure TffSessionTests.Setup;
begin
  inherited;
end;
{--------}
procedure TffSessionTests.Teardown;
begin
  inherited;
end;
{--------}
procedure TffSessionTests.testIsAlias;
begin
  { Create an alias. }
  Check(Session.IsAlias(clAliasName), 'IsAliasName failed on valid alias');
  Check(not Session.IsAlias('carrothead'),
                            'IsAliasName failed on invalid alias');
end;
{====================================================================}

{===TffDatabaseTests=================================================}
procedure TffDatabaseTests.testCommit;
var
  Inx, Inx2 : Integer;
begin
  { Verify that key violations do not cause a corrupt table even if
    the transaction has been committed. }

  { First step, load up the table with a bunch of valid records & a bunch
    of records that result in key violations. }
  FDatabase.StartTransaction;
  try
    tblExOrders.Open;
    for Inx := 1 to 100 do begin
      for Inx2 := 1 to 2 do begin
        tblExOrders.Insert;
        try
          tblExOrders.FieldbyName('OrderID').AsInteger := Inx + 500;
          tblExOrders.FieldByName('CustomerID').AsInteger := Inx;
          tblExOrders.FieldByName('Date').AsDateTime := Date;
          tblExOrders.Post;
        except
          tblExOrders.Cancel;
        end;
      end;  { for }
    end;
  finally
    FDatabase.Commit;
  end;

  { Next, verify that we can read through the table using the unique index. }
  tblExOrders.First;
  while not tblExOrders.EOF do
    tblExOrders.Next

end;
{--------}
procedure TffDatabaseTests.testExclusive;
var
  tblCust2 : TffTable;
begin
  FDatabase.Close;
  FDatabase.Exclusive := True;
  FDatabase.Open;

  tblCust2 := TffTable.Create(nil);
  try
    tblCust2.SessionName := FSession.SessionName;
    tblCust2.DatabaseName := FDatabase.DatabaseName;
    tblCust2.TableName := 'ExCust';
    tblCust2.Open;

    (* Enable the following code when issue 984 is resolved
    { Verify that more than one table may be opened - Issue 984. }
    tblExBlob.Open;
    tblExCust.Open;
    *)
  finally
    tblCust2.Free;
  end;

end;
{--------}
procedure TffDatabaseTests.testRollback;
var
  i : Integer;
begin
  { Verify that a rollback does not result in a memory leak due to unfreed
    RAM pages.

    NOTE: The memory leak would only show up if the following DEFINE is enabled
    in unit FFLLBASE and the test is run under Sleuth CodeWatch:

    $DEFINE MemCheck

  }

  FDatabase.StartTransaction;
  try
    tblExCust.EmptyTable;
    tblExCust.Timeout := 100000; {SPW}
    tblExCust.Open;
    for i := 1 to 1000 do
      with tblExCust do begin
        Insert;
        FieldByName('FirstName').AsString := 'A';
        FieldByName('LastName').AsString := 'B';
        FieldByName('Address').AsString := 'C';
        FieldByName('City').AsString := 'D';
        FieldByName('State').AsString := 'E';
        FieldByName('Zip').AsString := 'F';
        Post;
      end;  { with }
  finally
    FDatabase.Rollback;
  end;

  { Now verify that we can add a new record after the rollback has occurred. }
  with tblExCust do begin
    Insert;
    FieldByName('FirstName').AsString := 'A';
    FieldByName('LastName').AsString := 'B';
    FieldByName('Address').AsString := 'C';
    FieldByName('City').AsString := 'D';
    FieldByName('State').AsString := 'E';
    FieldByName('Zip').AsString := 'F';
    Post;
  end;  { with }

end;
{--------}
procedure TffDatabaseTests.testStartTransactionWith;
var
  ExceptRaised : Boolean;
  Database2 : TffDatabase;
  Table2 : TffTable;
  Data : string;
begin

  { Verify that all tables must be open before the transaction may be started. }
  ExceptRaised := False;
  tblExCust.Close;
  try
    FDatabase.StartTransactionWith([tblExBLOB, tblExCust]);
  except
    on E:EffDatabaseError do begin
      ExceptRaised := (E.ErrorCode = ffdse_StartTranTblActive);
    end;
    on E:Exception do begin
      Check(False, 'Unexpected exception: ' + E.message);
    end;
  end;
  Check(ExceptRaised, 'Exception not raised');

  { Verify the transaction will not start if one of the tables is already
    share locked by another transaction. }
  tblExCust.Open;
  tblExBLOB.Open;
  Database2 := TffDatabase.Create(nil);
  Table2 := TffTable.Create(nil);
  try
    Database2.SessionName := FSession.SessionName;
    Database2.DatabaseName := 'DB2';
    Database2.AliasName := FDatabase.AliasName;
    Database2.Open;

    Table2.SessionName := Database2.SessionName;
    Table2.DatabaseName := Database2.DatabaseName;
    Table2.TableName := tblExCust.TableName;
    Table2.Open;
    Database2.StartTransaction;
    try
      Table2.First;
      Data := Table2.FieldByName('LastName').AsString;
//      FDatabase.Timeout := 1000000;
      CheckEquals(DBIERR_LOCKED, FDatabase.StartTransactionWith([tblExBLOB, tblExCust]),
                  'Test 1');
    finally
      Database2.Rollback;
    end;
    { Verify the transaction can be started. }
    CheckEquals(0, FDatabase.StartTransactionWith([tblExBLOB, tblExCust]),
                'Test 2');
    FDatabase.Rollback;

    { Now verify the same behavior but with an exclusive lock. }
    Database2.StartTransaction;
    try
      Table2.Edit;
//      FDatabase.Timeout := 1000000;
      CheckEquals(DBIERR_LOCKED, FDatabase.StartTransactionWith([tblExBLOB, tblExCust]),
                  'Test 3');
    finally
      Database2.Rollback;
    end;
    { Verify the transaction can be started. }
    CheckEquals(0, FDatabase.StartTransactionWith([tblExBLOB, tblExCust]),
                'Test 4');
    FDatabase.Rollback;

  finally
    if FDatabase.InTransaction then
      FDatabase.Rollback;
    Table2.Free;
    Database2.Free;
  end;
end;
{====================================================================}

{===TffRemoteServerEngineTests=======================================}
procedure TffRemoteServerEngineTests.RSE_Create;
var
  ARSE : TFfRemoteServerEngine;
  Comp : TComponent;
begin
  ARSE := TffRemoteServerEngine.Create(nil);
  Assert(ARSE is TffRemoteServerEngine, 'Creation Error');

  ARSE.Free;

  Comp := TComponent.Create(nil);
  ARSE := TFfRemoteServerEngine.Create(Comp);
  Assert(ARSE is TffRemoteServerEngine, 'Creation Error');
  Comp.Free;

  try
    ARSE.GetDefaultClient;
    Assert(False, 'ARSE Not freed correctly');
  except
  end;
end;
{--------}
procedure TffRemoteServerEngineTests.RSE_Destroy;
var
  ARSE : TFfRemoteServerEngine;
  Comp : TComponent;
begin
  ARSE := TFfRemoteServerEngine.Create(nil);
  ARSE.Free;
  try
    ARSE.GetDefaultClient;
    Assert(False, 'ARSE Not freed correctly');
  except
  end;

  Comp := TComponent.Create(nil);
  ARSE := TFfRemoteServerEngine.Create(Comp);
  Comp.Free;

  try
    ARSE.GetDefaultClient;
    Assert(False, 'ARSE Not freed correctly');
  except
  end;
end;
{====================================================================}

{===TffQueryTests===================================================}
procedure TffQueryTests.DeleteTable(const TableName : string);
var
  aTable : TffTable;
begin
  aTable := TffTable.Create(nil);
  try
    aTable.SessionName := clSessionName;
    aTable.DatabaseName := clDatabaseName;
    aTable.TableName := TableName;
    aTable.DeleteTable;
  finally
    aTable.Free;
  end;
end;
{--------}
procedure TffQueryTests.Setup;
begin
  inherited Setup;

  { Create a SQL engine if necessary. }
  if FEngine is TffServerEngine then begin
    FSQLEngine := TffSQLEngine.Create(nil);
    TffServerEngine(FEngine).SQLEngine := FSQLEngine;
  end else
    FSQLEngine := nil;
end;
{--------}
procedure TffQueryTests.PrepareContactTable;
var
  Dict : TffDataDictionary;
  FldArray : TffFieldList;
  IHFldList : TffFieldIHList;
begin

  { Make sure Contacts table exists. }

  Dict := TffDataDictionary.Create(65536);
  try
    with Dict do begin

      { Add fields }
      AddField('ID', '', fftAutoInc, 0, 0, false, nil);
      AddField('FirstName', '', fftShortString, 25, 0, true, nil);
      AddField('LastName', '', fftShortString, 25, 0, true, nil);
      AddField('Age', '', fftInt16, 5, 0, false, nil);
      AddField('State', '', fftShortString, 2, 0, false, nil);
      AddField('DecisionMaker', '', fftBoolean, 0, 0, false, nil);
      AddField('BirthDate', '', fftDateTime, 0, 0, false, nil);

      { Add indexes }
      FldArray[0] := 0;
      IHFldList[0] := '';
      AddIndex('primary', '', 0, 1, FldArray, IHFldList, False, True, True);

      FldArray[0] := 2;
      IHFldList[0] := '';
      AddIndex('byLastName', '', 0, 1, FldArray, IHFldList, True, True, True);

      FldArray[0] := 1;
      IHFldList[0] := '';
      AddIndex('byFirstName', '', 0, 1, FldArray, IHFldList, True, True, True);

      FldArray[0] := 3;
      IHFldList[0] := '';
      AddIndex(csByAge, '', 0, 1, FldArray, IHFldList, True, True, True);

      FldArray[0] := 4;
      IHFldList[0] := '';
      AddIndex('byState', '', 0, 1, FldArray, IHFldList, True, True, True);

      FldArray[0] := 1;
      FldArray[1] := 2;
      IHFldList[0] := '';
      IHFldList[1] := '';
      AddIndex('byFullName', '', 0, 2, FldArray, IHFldList, True, True, True);

      FldArray[0] := 3;
      FldArray[1] := 4;
      IHFldList[0] := '';
      IHFldList[1] := '';
      AddIndex('byAgeState', '', 0, 2, FldArray, IHFldList, True, True, True);

      FldArray[0] := 4;
      FldArray[1] := 3;
      IHFldList[0] := '';
      IHFldList[1] := '';
      AddIndex('byStateAge', '', 0, 2, FldArray, IHFldList, True, True, True);

      FldArray[0] := 5;
      IHFldList[0] := '';
      AddIndex('byDecisionMaker', '', 0, 1, FldArray, IHFldList, True, True, True);

      FldArray[0] := 3;
      FldArray[1] := 4;
      IHFldList[0] := '';
      IHFldList[1] := '';
      AddIndex('byAgeDecisionMaker', '', 0, 2, FldArray, IHFldList, True, True, True);

    end;

    Database.CreateTable(True, csContacts, Dict);

    { Make sure renamed Contacts table is deleted. }
    try
      if FileExists(clDatabasePath + '\' + csContactsRen) then
        FFTblHlpDelete(clDatabasePath, csContactsRen, Dict);
    except
    end;

  finally
    Dict.Free;
  end;

end;
{--------}
procedure TffQueryTests.Teardown;
begin
  if Assigned(FSQLEngine) then
    FSQLEngine.Free;

  inherited Teardown;
end;
{--------}
procedure TffQueryTests.testSQLParsed;
const
  inputs  : array[0..6] of string =
            ('select * from contacts where Age = :anAge',

             'update Customers set CompanyName = ''Antonio Moreno Taquería ":thisisabug"''' +
             ' WHERE (CustomerID = ''ANTOX'')',

             'select * from table t where t."field name" = :"field name"',

             'select * from table t where :a=:b',

             'select * from table t where :income<300',

             'select * from table t where :income>300',

             'select * from table t where (a=:x) or :y>b'

            );

  outputs : array[0..6] of string =
            ('select * from contacts where Age = ?',

             { output[1] = input[1] (i.e., no parameters should be found in this
               statement }
             'update Customers set CompanyName = ''Antonio Moreno Taquería ":thisisabug"''' +
             ' WHERE (CustomerID = ''ANTOX'')',

             'select * from table t where t."field name" = ?',

             'select * from table t where ?=?',

             'select * from table t where ?<300',

             'select * from table t where ?>300',

             'select * from table t where (a=?) or ?>b'

            );

  names   : array[0..6] of string =
            ('anAge',
             '',
             'field name',
             'a',
             'income',
             'income',
             'x'
            );

var
  aQuery : TffQuery;
  Index : integer;
begin
  aQuery := TffQuery.Create(nil);
  with aQuery do
    try
      SessionName := clSessionName;
      DatabaseName := clDatabaseName;
      for Index := low(inputs) to high(inputs) do begin
        SQL.Clear;
        SQL.Add(inputs[Index]);
        { Verify the text matches. }
        Assert(outputs[Index] + #13#10 = Text, 'Invalid Text value');

        { If we expect a parameter, verify the parameter name. }
        if names[Index] <> '' then
          Assert(names[Index] = Params.Items[0].Name, 'Invalid parameter name');
      end;
    finally
      Free;
    end;
end;
{--------}
procedure TffQueryTests.testParamsOnLeft_1136;
var
  Query : TffQuery;
begin
  Query := TffQuery.Create(nil);
  with Query do
    try
      SessionName := clSessionName;
      DatabaseName := clDatabaseName;
      SQL.Add('SELECT *');
      SQL.Add('FROM');
      SQL.Add('StaffDefaultTimetables');
      SQL.Add('WHERE StartTime <= :StartTime');

      CheckEquals(1, ParamCount, 'Unexpected ParamCount');
      Params[0].DataType := ftDateTime;
      Params[0].Value := EncodeTime(9, 30, 0, 0);
      Open;
      CheckEquals(1, Query.RecordCount, 'Unexpected RecordCount');
      Close;

      SQL.Clear;
      SQL.Add('SELECT *');
      SQL.Add('FROM');
      SQL.Add('StaffDefaultTimetables');
      SQL.Add('WHERE :StartTime >= StartTime');

      CheckEquals(1, ParamCount, 'Unexpected ParamCount 2');
      Params[0].DataType := ftDateTime;
      Params[0].Value := EncodeTime(9, 30, 0, 0);
      Open;
      CheckEquals(1, Query.RecordCount, 'Unexpected RecordCount 2');
      Close;

    finally
      Free;
    end;
end;
{--------}
procedure TffQueryTests.testParamsSaved;
const
  fileName = 'testParamsSaved.res';
var
  aCount : integer;
  aParamName : string;
  aParamType : TFieldType;
  aQuery : TffQuery;
begin
  { Does the res file already exist? }
  if FileExists(fileName) then
    { Yes.  Delete it. }
    Deletefile(fileName);

  { Create the query & write it to the file. }
  aQuery := TffQuery.Create(nil);
  with aQuery do
    try
      SessionName := clSessionName;
      DatabaseName := clDatabaseName;
      SQL.Add('Select * from Contacts');
      SQL.Add(' where Age = :anAge');
      aCount := ParamCount;
      aParamType := Params[0].DataType;
      aParamName := Params[0].Name;
      WriteComponentResFile(fileName, aQuery);
    finally
      Free;
    end;

  { Create the component and read it from the res file. }
  aQuery := TffQuery.Create(nil);
  with aQuery do
    try
      ReadComponentResfile(fileName, aQuery);

      { Verify the # of parameters. }
      Assert(aCount = ParamCount, 'Invalid parameter count');

      { Verify the first parameter. }
      Assert(ord(aParamType) = ord(Params[0].DataType),
                   'Bad field type');
      Assert(aParamName = Params[0].Name, 'Bad param name');
    finally
      Free;
    end;
end;
{--------}
procedure TffQueryTests.testEmptySQL;
var
  aQuery : TffQuery;
  ExceptionRaised : boolean;
begin
  ExceptionRaised := False;
  aQuery := TffQuery.Create(nil);
  with aQuery do
    try
      try
        SessionName := clSessionName;
        DatabaseName := clDatabaseName;
        Open;
      except
        on E:Exception do begin
          ExceptionRaised := True;
          Assert(E is EffDatabaseError, 'Invalid exception type');
          Assert(ffdse_EmptySQLStatement = EffDatabaseError(E).ErrorCode,
                       'Invalid error code');
        end;
      end;
    finally
      Free;
    end;
  assert(ExceptionRaised, 'Exception not raised');
end;
{--------}
procedure TffQueryTests.testEmptySQLPrepare;
var
  aQuery : TffQuery;
  ExceptionRaised : boolean;
begin
  ExceptionRaised := False;
  aQuery := TffQuery.Create(nil);
  with aQuery do
    try
      try
        SessionName := clSessionName;
        DatabaseName := clDatabaseName;
        Prepare;
      except
        on E:Exception do begin
          ExceptionRaised := True;
          Assert(E is EffDatabaseError, 'Invalid exception type');
          Assert(ffdse_EmptySQLStatement = EffDatabaseError(E).ErrorCode,
                       'Invalid error code');
        end;
      end;
    finally
      Free;
    end;
  assert(ExceptionRaised, 'Exception not raised');
end;
{--------}
procedure TffQueryTests.testParamsByName;
const
  parm1 = 'anAge';
  parm2 = 'aLastName';
var
  aParam : TParam;
  aQuery : TffQuery;
begin
  aQuery := TffQuery.Create(nil);
  with aQuery do
    try
      SessionName := clSessionName;
      DatabaseName := clDatabaseName;
      SQL.Add('Select * from Contacts');
      SQL.Add(' where Age = :anAge and lastName = :aLastName');
      { Verify we can access the parameters by name. }
      aParam := ParamByName(parm1);
      Assert(Assigned(aParam), parm1 + ' not found');
      Assert(parm1 = aParam.Name, 'Invalid param name');
      aParam := ParamByName(parm2);
      Assert(Assigned(aParam), parm2 + ' not found');
      Assert(parm2 = aParam.Name, 'Invalid param name');
    finally
      Free;
    end;
end;
{--------}
procedure TffQueryTests.testParamCount;
var
  aQuery : TffQuery;
begin
  aQuery := TffQuery.Create(nil);
  with aQuery do
    try
      SessionName := clSessionName;
      DatabaseName := clDatabaseName;
      SQL.Add('Select * from Contacts');
      SQL.Add(' where Age = :anAge and');
      SQL.Add(' lastName = :aLastName and');
      SQL.Add(' decisionMaker = :aFlag');
      SQL.Add(' order by Age');
      { Verify param count. }
      Assert(3 = ParamCount, 'Invalid param count');

      SQL.Clear;
      SQL.Add('Select * from Contacts');
      Assert(0 = ParamCount, 'Invalid param count');
    finally
      Free;
    end;
end;
{--------}
procedure TffQueryTests.testPrepare;
var
  aQuery : TffQuery;
begin
  aQuery := TffQuery.Create(nil);
  with aQuery do
    try
      SessionName := clSessionName;
      DatabaseName := clDatabaseName;
      SQL.Add('Select * from ExCust where CustomerID = :CustomerID');
      Prepare;
      Check(Prepared, 'SQL not prepared 1');
      Unprepare;
      Check((not Prepared), 'SQL marked as prepared');
      Prepare;
      Check(Prepared, 'SQL not prepared 2');
      ParamByName('CustomerID').AsInteger := 1;
      Open;
      CheckEquals(1, RecordCount, 'Unexpected record count');
      Close;
{ TODO:: Fix when preparation logic is corrected }
//      Check(Prepared, 'SQL not prepared 3');
//      ParamByName('CustomerID').AsInteger := 2;
//      Open;
//      CheckEquals(1, RecordCount, 'Unexpected record count');
//      Check(Prepared, 'SQL not prepared 4');
    finally
      Free;
    end;
end;
{--------}
procedure TffQueryTests.testRequestLiveFalse;
var
  aQuery : TffQuery;
begin
  { TODO: When can execute the query, need to test for raised exception. }
  Exit;
  aQuery := TffQuery.Create(nil);
  with aQuery do
    try
      SessionName := clSessionName;
      DatabaseName := clDatabaseName;
      RequestLive := False;
      SQL.Add('Select * from Contacts');
      Prepare;
      Open;
      Insert;
      FieldByName('FirstName').asString := 'Henry';
      fieldByName('LastName').asString := 'Ford';
      fieldByName('Age').asInteger := 99;
      Post;
    finally
      Free;
    end;
end;
{--------}
procedure TffQueryTests.testRequestLiveTrue;
var
  aQuery : TffQuery;
begin
  { TODO: When can execute the query, need to test for raised exception. }
  Exit;
  aQuery := TffQuery.Create(nil);
  with aQuery do
    try
      SessionName := clSessionName;
      DatabaseName := clDatabaseName;
      RequestLive := True;
      SQL.Add('Select * from Contacts');
      Prepare;
      Open;
      Insert;
      FieldByName('FirstName').asString := 'Henry';
      fieldByName('LastName').asString := 'Ford';
      fieldByName('Age').asInteger := 99;
      Post;
    finally
      Free;
    end;
end;
{--------}
procedure TffQueryTests.LoginEventRO(aSource   : TObject;
                                 var aUserName : TffName;
                                 var aPassword : TffName;
                                 var aResult   : Boolean);
begin
  aUserName := csROUserID;
  aPassword := csROPassword;
  aResult := True;
end;
{--------}
procedure TffQueryTests.testReadOnlyRights;
  { Verify that a read-only user can select data but they cannot insert,
    update, or delete data. }
const
  cContacts = 100;
var
  aTable : TffTable;
  aQuery : TffQuery;
  GotExcept : Boolean;
  OldCount : Longint;
begin

  { This test can only be run with embedded server engine. }
  if RemoteEngine then
    Exit;
  PrepareContactTable;
  aTable := TffTable.Create(nil);
  try
    aTable.SessionName := FSession.SessionName;
    aTable.DatabaseName := clDatabaseName;
    aTable.TableName := csContacts;
    aTable.Open;
    InsertRandomContacts(aTable, cContacts);
    Check(aTable.RecordCount > 0, 'No records in Contacts table');

    { Activate secure logins. }
    FClient.Close;
    FSession.OnLogin := LoginEventRO;
    Secured := True;
    FSession.Open;
    aTable.Open;
    aQuery := TffQuery.Create(nil);
    try

      { Select }
      aQuery.SessionName := FSession.SessionName;
      aQuery.DatabaseName := clDatabaseName;
      aQuery.SQL.Add('Select * from Contacts');
      aQuery.Prepare;
      aQuery.Open;
      CheckEquals(aTable.RecordCount, aQuery.RecordCount,
                  'Invalid record count for Select');
      aQuery.Close;

      { Insert }
      OldCount := aTable.RecordCount;
      aQuery.Timeout := 1000000;
      aQuery.SQL.Clear;
      aQuery.SQL.Add('Insert into Contacts (FirstName, LastName) Values');
      aQuery.SQL.Add('(''First'', ''Last'')');
      GotExcept := False;
      try
        aQuery.ExecSQL;
      except
        on E:EffDatabaseError do begin
          CheckEquals(DBIERR_NOTSUFFTABLERIGHTS, E.ErrorCode,
                      'Unexpected error code for Insert');
          GotExcept := True;
        end;
      end;
      Check(GotExcept, 'No exception raised on Insert');
      CheckEquals(-1, aQuery.RowsAffected, 'Rows affected by Insert');
      CheckEquals(OldCount, aTable.RecordCount, 'Row inserted on Insert');
      aQuery.Close;

      { Update }
      aQuery.SQL.Clear;
      aQuery.SQL.Add('Update Contacts set LastName = ''TurkeyBreath''');
      GotExcept := False;
      try
        aQuery.ExecSQL;
      except
        on E:EffDatabaseError do begin
          CheckEquals(DBIERR_NOTSUFFTABLERIGHTS, E.ErrorCode,
                      'Unexpected error code for Update');
          GotExcept := True;
        end;
      end;
      Check(GotExcept, 'No exception raised on Update');
      CheckEquals(-1, aQuery.RowsAffected, 'Rows affected by Update');
      aQuery.Close;

      { Delete }
      aQuery.SQL.Clear;
      aQuery.SQL.Add('delete from Contacts');
      GotExcept := False;
      try
        aQuery.ExecSQL;
      except
        on E:EffDatabaseError do begin
          CheckEquals(DBIERR_NOTSUFFTABLERIGHTS, E.ErrorCode,
                      'Unexpected error code for Delete');
          GotExcept := True;
        end;
      end;
      Check(GotExcept, 'No exception raised on Delete');
      Check(aTable.RecordCount > 0, 'Records deleted from Contacts table');
      CheckEquals(-1, aQuery.RowsAffected, 'Rows affected by Delete');
      aQuery.Close;
    finally
      aQuery.Free;
    end;
  finally
    aTable.Free;

    { Deactivate secure logins. }
    FClient.Close;
    Secured := False;
  end;
end;
{--------}
procedure TffQueryTests.testRowCount;
  { Verify that when we perform a query, we obtain the correct number of
    records. }
var
  aQuery : TffQuery;
begin
  PrepareContactTable;
  aQuery := TffQuery.Create(nil);
  with aQuery do
    try
      SessionName := FSession.SessionName;
      DatabaseName := clDatabaseName;
      SQL.Add('Select * from Contacts');
      Prepare;
      Open;
      Assert(RecordCount = 0);
//      InsertRecord([null, 'First1', 'Last']);
//      Assert(RecordCount = 1);
//      InsertRecord([null, 'First2', 'Last']);
//      Assert(RecordCount = 2);
//      InsertRecord([null, 'First3', 'Last']);
//      Assert(RecordCount = 3);
//      InsertRecord([null, 'First4', 'Last']);
//      Assert(RecordCount = 4);
    finally
      Free;
    end;
end;
{--------}
procedure TffQueryTests.testFirsttoEOF;
  { Verify that we can move from First to EOF in a resultset. }
var
  aQuery : TffQuery;
begin
  PrepareContactTable;
  aQuery := TffQuery.Create(nil);
  with aQuery do
    try
      SessionName := FSession.SessionName;
      DatabaseName := clDatabaseName;
      SQL.Add('Select * from Contacts');
      Prepare;
      Open;
//      InsertRecord([null, 'First1', 'Last']);
//      InsertRecord([null, 'First2', 'Last']);
//      InsertRecord([null, 'First3', 'Last']);
//      InsertRecord([null, 'First4', 'Last']);
      First;
      while not EOF do Next;
    finally
      Free;
    end;
end;
{--------}
procedure TffQueryTests.testNoDBOpen;
  { Verify that we receive the correct exception when TffQuery.DatabaseName
    is not specified and we activate the TffQuery. }
var
  aQuery : TffQuery;
  ExceptionRaised : boolean;
begin
  ExceptionRaised := False;
  aQuery := TffQuery.Create(nil);
  with aQuery do
    try
      try
        SessionName := FSession.SessionName;
        DatabaseName := '';
        SQL.Add('Select * from Contacts');
        Prepare;
        Open;
      except
        on E:Exception do begin
          ExceptionRaised := True;
          Assert(E is EffDatabaseError, 'Invalid exception type');
          Assert(ffdse_TblBadDBName = EffDatabaseError(E).ErrorCode,
                       'Invalid error code');
        end;
      end;
    finally
      Free;
    end;
  assert(ExceptionRaised, 'Exception not raised');
end;
{--------}
procedure TffQueryTests.testParamsUpdated;
const
  parm1 = 'anAge';
  parm2 = 'lastName';
var
  aQuery : TffQuery;
  aParam : TParam;
begin
  aQuery := TffQuery.Create(nil);
  with aQuery do
    try
      SessionName := clSessionName;
      DatabaseName := clDatabaseName;
      ParamCheck := True;
      SQL.Add('Select * from Contacts');
      SQL.Add(' where Age = :anAge');
      aParam := ParamByName(parm1);
      assert(assigned(aParam), 'Did not find first param');

      { Change the SQL. }
      SQL.Strings[1] := ' where LastName = :' + parm2;
      aParam := nil;
      try
        aParam := ParamByName(parm1);
      except
      end;
      { Verify we can no longer find the original parameter. }
      assert(not assigned(aParam), 'Original parameter still exists');

      aParam := ParamByName(parm2);
      { Verify we found the new parameter. }
      assert(assigned(aParam), 'Did not find second parm');
    finally
      Free;
    end;
end;
{--------}
procedure TffQueryTests.testParamsNotUpdated;
  { Verify that when ParamCheck is False, changing the SQL does not
    regenerate the Params. }
const
  parm1 = 'anAge';
  parm2 = 'lastName';
var
  aQuery : TffQuery;
  aParam : TParam;
begin
  aQuery := TffQuery.Create(nil);
  with aQuery do
    try
      SessionName := clSessionName;
      DatabaseName := clDatabaseName;
      SQL.Add('Select * from Contacts');
      SQL.Add(' where Age = :anAge');
      aParam := ParamByName(parm1);
      assert(assigned(aParam), 'Did not find first param');
      ParamCheck := False;

      { Change the SQL. }
      SQL.Strings[1] := ' where LastName = :' + parm2;
      aParam := nil;
      try
        aParam := ParamByName(parm1);
      except
      end;
      { Verify we can still find the original parameter. }
      assert(assigned(aParam), 'Original parameter no longer exists');

      aParam := nil;
      try
        aParam := ParamByName(parm2);
      except
      end;
      { Verify we do not find the new parameter. }
      assert(not assigned(aParam), 'Found new parameter');
    finally
      Free;
    end;
end;
{--------}
procedure TffQueryTests.testCircularDatasource;
var
  aQuery : TffQuery;
  aDataSrc : TDataSource;
  ExceptionRaised : boolean;
begin
  aDataSrc := nil;
  aQuery := TffQuery.Create(nil);
  with aQuery do
    try
      SessionName := clSessionName;
      DatabaseName := clDatabaseName;
      SQL.Add('Select * from Contacts');
      SQL.Add(' where Age = :anAge');

      aDataSrc := TDataSource.Create(nil);
      aDataSrc.DataSet := aQuery;

      { Verify an exception is raised if we assign the datasource to the
        query's DataSource property. }
      ExceptionRaised := False;
      try
        aQuery.DataSource := aDataSrc;
      except
        ExceptionRaised := True;
      end;

      assert(ExceptionRaised, 'Exception not raised');

    finally
      Free;
      if assigned(aDataSrc) then
        aDataSrc.Free;
    end;
end;
{--------}
procedure TffQueryTests.testDatasource;
  { Verify that when we connect a datasource to the TffQuery, its parameters
    are used to populate the query. }
begin
//  fail('Test not complete');
  { TODO:: When can execute a query, finish off this routine. }
end;
{--------}
procedure TffQueryTests.testMultInserts;
var
  aQuery : TffQuery;
  Inx : Integer;
begin
  CloneTable('Contacts', 'Contacts2');
  aQuery := TffQuery.Create(nil);
  try
    with aQuery do begin
      SessionName := FSession.SessionName;
      DatabaseName := FDatabase.DatabaseName;
    end;  { with }

    aQuery.Database.StartTransaction;
    try
      for Inx := 1 to 9 do begin
        aQuery.SQL.Clear;
        aQuery.SQL.Add('insert into Contacts2 ' +
                       '(firstname, lastname, age, state, decisionmaker) ' +
                       'values (' + QuotedStr('first' + InttoStr(Inx)) +
                       ', ' + QuotedStr('last' + IntToStr(Inx)) +
                       ', ' + IntToStr(30 + Inx) +
                       ', ' + QuotedStr(IntToStr(Inx) + IntToStr(Inx)) +
                       ', false)');
        aQuery.ExecSQL;
        CheckEquals(1, aQuery.RowsAffected, 'Insert ' + IntToStr(Inx) + ' failed');
      end;
      aQuery.Database.Commit;
    except
      aQuery.Database.Rollback;
      raise;
    end;
  finally
    aQuery.Free;
    { Make sure that database is closed so that table may be deleted. }
    FDatabase.Close;
    DeleteTable('Contacts2');
  end;
end;
{--------}
procedure TffQueryTests.testMultDeletes;
var
  aQuery : TffQuery;
  TotalCount,
  BillCount,
  DavidCount,
  JohnCount : Integer;
begin
  aQuery := TffQuery.Create(nil);
  try
    with aQuery do begin
      SessionName := clSessionName;
      DatabaseName := clDatabaseName;
    end;  { with }

    aQuery.Database.StartTransaction;
    try
      { Grab the total # of records. Will be used to verify total # of
        records remaining at end. }
      aQuery.SQL.Add('select * from ExCust');
      aQuery.Open;
      TotalCount := aQuery.RecordCount;
      aQuery.Close;

      { Grab the # of contacts with a specific first name. This will be used
        to verify the # of records deleted. }
      aQuery.SQL.Clear;
      aQuery.SQL.Add('select * from ExCust where firstName = ');
      aQuery.SQL.Add(QuotedStr('Bill'));

      aQuery.Open;
      BillCount := aQuery.RecordCount;
      Assert(BillCount > 0, 'No Bills found');

      aQuery.Close;
      aQuery.SQL[1] := QuotedStr('David');
      aQuery.Open;
      DavidCount := aQuery.RecordCount;
      Assert(DavidCount > 0, 'No Davids found');

      aQuery.Close;
      aQuery.SQL[1] := QuotedStr('John');
      aQuery.Open;
      JohnCount := aQuery.RecordCount;
      Assert(JohnCount > 0, 'No Johns found');

      aQuery.Close;
      aQuery.SQL.Clear;
      aQuery.SQL.Add('Delete from ExCust where FirstName = ');
      aQuery.SQL.Add(QuotedStr('Bill'));
      aQuery.ExecSQL;
      CheckEquals(BillCount, aQuery.RowsAffected, 'Bill delete failed');

      aQuery.SQL[1] := QuotedStr('David');
      aQuery.ExecSQL;
      CheckEquals(DavidCount, aQuery.RowsAffected, 'David delete failed');

      aQuery.SQL[1] := QuotedStr('John');
      aQuery.ExecSQL;
      CheckEquals(JohnCount, aQuery.RowsAffected, 'John delete failed');

      aQuery.Database.Commit;

      { Verify correct # of records remaining. }
      aQuery.SQL.Clear;
      aQuery.SQL.Add('select * from ExCust');
      aQuery.Open;
      CheckEquals(TotalCount - (BillCount + DavidCount + JohnCount),
                  aQuery.RecordCount, 'Invalid remainder');
      aQuery.Close;

    except
      aQuery.Database.Rollback;
      raise;
    end;
  finally
    aQuery.Free;
  end;
end;
{--------}
procedure TffQueryTests.testMultUpdates;
var
  aQuery : TffQuery;
begin
  aQuery := TffQuery.Create(nil);
  try
    with aQuery do begin
      SessionName := clSessionName;
      DatabaseName := clDatabaseName;
    end;  { with }

    aQuery.Database.StartTransaction;
    try
      { Insert a contact. }
      aQuery.SQL.Add('insert into ExCust ' +
                     '(firstname, lastname, address, city, state, zip) ' +
                     'values (' + QuotedStr('first1') +
                     ', ' + QuotedStr('last1') +
                     ', ' + QuotedStr('1 Our Street') +
                     ', ' + QuotedStr('Our Fair City') +
                     ', ' + QuotedStr('CO') +
                     ', ' + QuotedStr('80808') + ')');
      aQuery.ExecSQL;
      CheckEquals(1, aQuery.RowsAffected, 'Insert failed');

      { Doublecheck that record exists. }
      aQuery.SQL.Clear;
      aQuery.SQL.Add('select * from ExCust where LastName = ''last1''');
      aQuery.Open;
      CheckEquals(1, aQuery.RecordCount, 'Record not deleted');
      aQuery.Close;

      { Update the contact. }
      aQuery.SQL.Clear;
      aQuery.SQL.Add('update ExCust set FirstName = ''Ted'' where ');
      aQuery.SQL.Add('FirstName = ''first1''');
      aQuery.ExecSQL;
      CheckEquals(1, aQuery.RowsAffected, 'Update failed');

      { Delete the contact. }
      aQuery.SQL.Clear;
      aQuery.SQL.Add('delete from ExCust where LastName = ''last1''');
      aQuery.ExecSQL;
      CheckEquals(1, aQuery.RowsAffected, 'Update failed');

      aQuery.Database.Commit;

      { Does the record still exist? }
      aQuery.SQL.Clear;
      aQuery.SQL.Add('select * from ExCust where LastName = ''last1''');
      aQuery.Open;
      CheckEquals(0, aQuery.RecordCount, 'Record not deleted');
      aQuery.Close;
    except
      aQuery.Database.Rollback;
      raise;
    end;
  finally
    aQuery.Free;
  end;
end;
{--------}
procedure TffQueryTests.testObeysRecLock_3752;
var
  aQuery : TffQuery;
  ExceptRaised : Boolean;
  OriginalName : string;
begin
  aQuery := TffQuery.Create(nil);
  try
    tblExCust.Open;
    tblExCust.Edit;

    with aQuery do begin
      SessionName := clSessionName;
      DatabaseName := clDatabaseName;
      SQL.Add('delete from ExCust');
    end;  { with }

    { Edit a record via the table. }
    tblExCust.Edit;

    { Try to delete the same record via the query. }
    ExceptRaised := False;
    try
      aQuery.ExecSQL;
    except
      on E:EffDatabaseError do begin
        ExceptRaised := True;
        CheckEquals(ffdse_QueryExecFail, E.ErrorCode, 'Unexpected error code');
      end;
    end;

    Check(ExceptRaised, 'Exception not raised for DELETE');

    { Verify record count. }
    tblExCust.Cancel;
    CheckEquals(200, tblExCust.RecordCount, 'Invalid record count');

    tblExCust.First;
    tblExCust.Edit;
    OriginalName := tblExCust.FieldByName('FirstName').AsString;

    { Now attempt an update. }
    aQuery.SQL.Clear;
    aQuery.SQL.Add('Update ExCust set FirstName = ''1010101''');
    ExceptRaised := False;
    try
      aQuery.ExecSQL;
    except
      on E:EffDatabaseError do begin
        ExceptRaised := True;
        CheckEquals(ffdse_QueryExecFail, E.ErrorCode, 'Unexpected error code');
      end;
    end;

    Check(ExceptRaised, 'Exception not raised for UPDATE');

    { Verify record was not really changed. }
    CheckEquals(OriginalName, tblExCust.FieldByName('FirstName').AsString,
                'Unexpected name change');

  finally
    aQuery.Free;
    tblExCust.Cancel;
  end;
end;
{--------}
procedure TffQueryTests.testObeysTableReadLock;
var
  aQuery : TffQuery;
  ExceptRaised : Boolean;
  OriginalName : string;
begin
  aQuery := TffQuery.Create(nil);
  try
    tblExCust.Open;
    tblExCust.LockTable(ffltReadLock);

    with aQuery do begin
      SessionName := clSessionName;
      DatabaseName := clDatabaseName;
      SQL.Add('delete from ExCust');
    end;  { with }

    { Try to delete the same record via the query. }
    ExceptRaised := False;
    try
      aQuery.ExecSQL;
    except
      on E:EffDatabaseError do begin
        ExceptRaised := True;
        CheckEquals(DBIERR_FileLocked, E.ErrorCode, 'Unexpected error code');
      end;
    end;

    Check(ExceptRaised, 'Exception not raised for DELETE');

    { Verify record count. }
    CheckEquals(200, tblExCust.RecordCount, 'Invalid record count');

    tblExCust.First;
    OriginalName := tblExCust.FieldByName('FirstName').AsString;

    { Now attempt an update. }
    aQuery.SQL.Clear;
    aQuery.SQL.Add('Update ExCust set FirstName = ''1010101''');
    ExceptRaised := False;
    try
      aQuery.ExecSQL;
    except
      on E:EffDatabaseError do begin
        ExceptRaised := True;
        CheckEquals(DBIERR_FileLocked, E.ErrorCode, 'Unexpected error code');
      end;
    end;

    Check(ExceptRaised, 'Exception not raised for UPDATE');

    { Verify record was not really changed. }
    CheckEquals(OriginalName, tblExCust.FieldByName('FirstName').AsString,
                'Unexpected name change');

    { Now attempt an INSERT. }
    aQuery.SQL.Clear;
    aQuery.SQL.Add('INSERT into ExCust (FirstName, LastName, Address, ');
    aQuery.SQL.Add('City, State, Zip) values');
    aQuery.SQL.Add('(''a'', ''b'', ''c'', ''d'', ''e'', ''f'')');
    ExceptRaised := False;
    try
      aQuery.ExecSQL;
    except
      on E:EffDatabaseError do begin
        ExceptRaised := True;
        CheckEquals(DBIERR_FileLocked, E.ErrorCode, 'Unexpected error code');
      end;
    end;

    Check(ExceptRaised, 'Exception not raised for INSERT');

    { Verify record counts. }
    CheckEquals(200, tblExCust.RecordCount, 'Invalid record count');

  finally
    aQuery.Free;
    tblExCust.UnlockTable(ffltReadLock);
    tblExCust.Close;
  end;
end;
{--------}
procedure TffQueryTests.testObeysTableWriteLock;
var
  aQuery : TffQuery;
  ExceptRaised : Boolean;
  OriginalName : string;
begin
  aQuery := TffQuery.Create(nil);
  try
    tblExCust.Open;
    tblExCust.LockTable(ffltWriteLock);

    with aQuery do begin
      SessionName := clSessionName;
      DatabaseName := clDatabaseName;
      SQL.Add('delete from ExCust');
    end;  { with }

    { Try to delete the same record via the query. }
    ExceptRaised := False;
    try
      aQuery.ExecSQL;
    except
      on E:EffDatabaseError do begin
        ExceptRaised := True;
        CheckEquals(DBIERR_FileLocked, E.ErrorCode, 'Unexpected error code');
      end;
    end;

    Check(ExceptRaised, 'Exception not raised for DELETE');

    { Verify record count. }
    CheckEquals(200, tblExCust.RecordCount, 'Invalid record count');

    tblExCust.First;
    OriginalName := tblExCust.FieldByName('FirstName').AsString;

    { Now attempt an update. }
    aQuery.SQL.Clear;
    aQuery.SQL.Add('Update ExCust set FirstName = ''1010101''');
    ExceptRaised := False;
    try
      aQuery.ExecSQL;
    except
      on E:EffDatabaseError do begin
        ExceptRaised := True;
        CheckEquals(DBIERR_FileLocked, E.ErrorCode, 'Unexpected error code');
      end;
    end;

    Check(ExceptRaised, 'Exception not raised for UPDATE');

    { Verify record was not really changed. }
    CheckEquals(OriginalName, tblExCust.FieldByName('FirstName').AsString,
                'Unexpected name change');

    { Now attempt an INSERT. }
    aQuery.SQL.Clear;
    aQuery.SQL.Add('INSERT into ExCust (FirstName, LastName, Address, ');
    aQuery.SQL.Add('City, State, Zip) values');
    aQuery.SQL.Add('(''a'', ''b'', ''c'', ''d'', ''e'', ''f'')');
    ExceptRaised := False;
    try
      aQuery.ExecSQL;
    except
      on E:EffDatabaseError do begin
        ExceptRaised := True;
        CheckEquals(DBIERR_FileLocked, E.ErrorCode, 'Unexpected error code');
      end;
    end;

    Check(ExceptRaised, 'Exception not raised for INSERT');

    { Verify record counts. }
    CheckEquals(200, tblExCust.RecordCount, 'Invalid record count');

  finally
    aQuery.Free;
    tblExCust.UnlockTable(ffltWriteLock);
    tblExCust.Close;
  end;
end;
{--------}
procedure TffQueryTests.testBLOBParam;
var
  OldRecName : string;
  OrigBLOB : TffBLOBStream;
  NewBLOB : TffBLOBStream;
  Query : TffQuery;
  OldByte, NewByte: Byte;

  procedure CopyBLOB(const RecName : string; SrcBLOB : TffBLOBStream);
  var
    Inx : Integer;
    NewBLOB : TffBLOBStream;
  begin
    { Set the parameter values. }
    Query.ParamByName('title').Value := RecName;
    Query.ParamByName('image').AssignField(tblExBlob.FieldByName('image'));
    Query.ParamByName('size').Value := tblExBLOB.FieldByName('size').Value;
    Query.ParamByName('type').Value := tblExBLOB.FieldByName('type').Value;
    Query.ExecSQL;
    CheckEquals(1, Query.RowsAffected, 'Unexpected RowsAffected value');

    { Find the newly-inserted record. }
    Check(tblExBLOB.Locate('title', RecName, []),
          'Could not find new record for verification');
    NewBLOB := TffBLOBStream.Create(TBlobField(tblExBLOB.FieldByName('Image')),
                                    bmRead);
    try
      Assert(NewBLOB <> nil, 'BLOB stream not created');
      CheckEquals(SrcBLOB.Size, NewBLOB.Size, 'BLOB sizes do not match');
      { Compare the BLOB content. }
      for Inx := 1 to SrcBLOB.Size do begin
        SrcBLOB.Read(OldByte, SizeOf(OldByte));
        NewBLOB.Read(NewByte, SizeOf(NewByte));
        CheckEquals(OldByte, NewByte, 'Mismatch at position ' + IntToStr(Inx));
      end;  { for }
    finally
      NewBLOB.Free;
    end;
  end;
begin
  { Clone a record from the ExBLOB table and verify the BLOBs match. }
  tblExBLOB.Open;
  { Get the original BLOB. }
  OrigBLOB := TffBLOBStream.Create(TBlobField(tblExBLOB.FieldByName('Image')),
                                   bmRead);
  try
    Assert(OrigBLOB <> nil, 'BLOB stream not created');
    Assert(OrigBLOB.Size > 0, 'BLOB has no content');

    { Create an insert statement. }
    Query := TffQuery.Create(nil);
    try
      Query.SessionName := tblExBLOB.SessionName;
      Query.DatabaseName := tblExBLOB.DatabaseName;
      Query.Timeout := 0;
      FDatabase.Timeout := 0;
      Query.SQL.Add('insert into ExBLOB (title, image, size, type) values');
      Query.SQL.Add('(:title, :image, :size, :type)');

      OldRecName := tblExBLOB.FieldByName('title').Value;
      CopyBLOB(OldRecName + 'Copy1', OrigBLOB);

      { Now lets NULL out the BLOB in the new record. We'll attempt to insert
        a null BLOB via an INSERT statement. }
      tblExBLOB.Edit;
      tblExBLOB.FieldByName('image').Clear;
      tblExBLOB.Post;
      { Verify it really was truncated. }
      NewBLOB := TffBLOBStream.Create(TBlobField(tblExBLOB.FieldByName('Image')),
                                      bmRead);
      try
        Assert(NewBLOB <> nil, 'BLOB stream not created');
        CheckEquals(0, NewBLOB.Size, 'BLOB sizes do not match');

        { Do that copy thing you do so well. }
        CopyBLOB(OldRecName + 'Copy2', NewBLOB);
      finally
        NewBLOB.Free;
      end;

    finally
      Query.Free;
    end;
  finally
    OrigBLOB.Free;
    tblExBLOB.Close;
  end;
end;
{====================================================================}
procedure TffClientTests.ServerCreationOrderIterator(Combination : array of integer;
                                               const IterationCount : Longint);
type
  TCompArr = array[1..9] of TCompClass;
const
  CompArr : TCompArr =
    (TffClient, TffSession, TffSecurityMonitor, TffServerEngine,
     TffThreadPool, TffServerCommandHandler, TffSQLEngine, TffLegacyTransport,
     TffEventLog);
var
  SE : TffServerEngine;
  SQL: TffSQLEngine;
  CH : TffServerCommandHandler;
  LT : TffLegacyTransport;
  EV : TffEventLog;
  SM : TffSecurityMonitor;
  TP : TffThreadPool;
  CL : TffClient;
  SS : TffSession;

  C : Integer;
  Comp : TComponent;
begin
  SE := nil;
  SQL := nil;
  CH := nil;
  LT := nil;
  EV := nil;
  SM := nil;
  TP := nil;
  CL := nil;
  SS := nil;

  try
    for C := Low(Combination) to High(Combination) do begin
      Comp := CompArr[Combination[C]].Create(nil);
      if Comp is TffServerEngine then
        SE := TffServerEngine(Comp)
      else if Comp is TffSQLEngine then
        SQL := TffSQLEngine(Comp)
      else if Comp is TffServerCommandHandler then
        CH := TffServerCommandHandler(Comp)
      else if Comp is TffLegacyTransport then
        LT := TffLegacyTransport(Comp)
      else if Comp is TffEventLog then
        EV := TffEventLog(Comp)
      else if Comp is TffSecurityMonitor then
        SM := TffSecurityMonitor(Comp)
      else if Comp is TffThreadPool then
        TP := TffThreadPool(Comp)
      else if Comp is TffClient then
        CL := TffClient(Comp)
      else if Comp is TffSession then
        SS := TffSession(Comp);
    end;

    { Connect the components. }
    EV.FileName := 'SvrCreationOrderTest.log';
    EV.Enabled := False;

    SE.SQLEngine := SQL;
    SE.EventLog := EV;
    SE.EventLogEnabled := True;
    SE.IsReadOnly := True;

    SQL.EventLog := EV;
    SQL.EventLogEnabled := True;

    CH.ServerEngine := SE;
    CH.EventLog := EV;
    CH.EventLogEnabled := True;

    LT.EventLog := EV;
    LT.EventLogEnabled := True;
    LT.CommandHandler := CH;
    LT.ThreadPool := TP;
    LT.Protocol := ptSingleUser;
    LT.Enabled := True;

    SM.EventLog := EV;
    SM.EventLogEnabled := True;
    SM.ServerEngine := SE;

    CL.ServerEngine := SE;
    CL.AutoClientName := True;
    CL.Open;

    SS.AutoSessionName := True;
    SS.ClientName := CL.ClientName;
    SS.Open;

    Check(SE.State = ffesStarted, 'Server not started');
    Check(LT.State = ffesStarted, 'Transport not started');
    Check(SS.Active, 'Session not active');

    for C := High(Combination) downto Low(Combination) do begin
      Comp := CompArr[Combination[C]].Create(nil);
      try
        if Comp is TffServerEngine then begin
          SE.Free;
          SE := nil;
        end
        else if Comp is TffSQLEngine then begin
          SQL.Free;
          SQL := nil;
        end
        else if Comp is TffServerCommandHandler then begin
          CH.Free;
          CH := nil;
        end
        else if Comp is TffLegacyTransport then begin
          LT.Free;
          LT := nil;
        end
        else if Comp is TffEventLog then begin
          EV.Free;
          EV := nil;
        end
        else if Comp is TffSecurityMonitor then begin
          SM.Free;
          SM := nil;
        end
        else if Comp is TffThreadPool then begin
          TP.Free;
          TP := nil;
        end
        else if Comp is TffClient then begin
          CL.Free;
          CL := nil;
        end
        else if Comp is TffSession then begin
          SS.Free;
          SS := nil;
        end;
      finally
        Comp.Free;
      end;
    end;

    { Sleep a bit so as to avoid overrun of commands between tests. }
    Sleep(100);
  except
    { For debugging purposes. Set a breakpoint on raise so that we can tell
      where the problem occurs. }
    raise;
  end;
end;
{--------}
procedure TffClientTests.ServerCreationOrderTest;
const
  AtomArray : array[1..9] of integer =
    (1, 2, 3, 4, 5, 6, 7, 8, 9);
begin
  { This test can only be run with an embedded server engine. }
  if RemoteEngine then
    Exit;
  { Comment out the following line if you really want to run this test.
    This test may take 10+ hours to execute. }
  Check(False, 'Test disabled due to length of time it takes to run');
  GenerateCombinations(AtomArray, ServerCreationOrderIterator);
end;
{--------}
procedure TffClientTests.StdCreationOrderTest;
type
  TCompArr = array[1..24,1..4]of TCompClass;
const
  CompArr : TCompArr = (
    (TffClient, TffSession, TffDatabase, TffTable),
    (TffClient, TffSession, TffTable, TffDatabase),
    (TffClient, TffDatabase, TffSession, TffTable),
    (TffClient, TffDatabase, TffTable, TffSession),
    (TffClient, TffTable, TffSession, TffDatabase),
    (TffClient, TffTable, TffDatabase, TffSession),
    (TffSession, TffClient, TffDatabase, TffTable),
    (TffSession, TffClient, TffTable, TffDatabase),
    (TffSession, TffDatabase, TffClient, TffTable),
    (TffSession, TffDatabase, TffTable, TffClient),
    (TffSession, TffTable, TffClient, TffDatabase),
    (TffSession, TffTable, TffDatabase, TffClient),
    (TffDatabase, TffClient, TffSession, TffTable),
    (TffDatabase, TffClient, TffTable, TffSession),
    (TffDatabase, TffSession, TffClient, TffTable),
{>} (TffDatabase, TffSession, TffTable, TffClient),
    (TffDatabase, TffTable, TffClient, TffSession),
    (TffDatabase, TffTable, TffSession, TffClient),
    (TffTable, TffClient, TffSession, TffDatabase),
    (TffTable, TffClient, TffDatabase, TffSession),
    (TffTable, TffSession, TffClient, TffDatabase),
    (TffTable, TffSession, TffDatabase, TffClient),
    (TffTable, TffDatabase, TffClient, TffSession),
    (TffTable, TffDatabase, TffSession, TffClient));
var
  CL : TffClient;
  SS : TffSession;
  DB : TffDatabase;
  TB : TffTable;
  C, I : Integer;
  Comp : TComponent;
begin
  CL := nil;
  SS := nil;
  DB := nil;
  TB := nil;
  try
    for I := 1 to 24 do begin
       for C := 1 to 4 do begin
         Comp := CompArr[I, C].Create(nil);
         if Comp is TffClient then
           CL := TffClient(Comp)
         else if Comp is TffSession then
           SS := TffSession(Comp)
         else if Comp is TffDatabase then
           DB := TffDatabase(Comp)
         else if Comp is TffTable then
           TB := TffTable(Comp);
       end;

       CL.AutoClientName := True;
       CL.ServerEngine := Client.ServerEngine;
       CL.Open;

       SS.AutoSessionName := True;
       SS.ClientName := CL.ClientName;
       SS.Open;

       DB.DatabaseName := 'DBxxx';
       DB.SessionName := SS.SessionName;
       DB.AliasName := 'Tutorial';
       DB.Open;

       TB.SessionName := DB.SessionName;
       TB.DatabaseName := DB.DatabaseName;
       TB.TableName := 'Contacts';
       TB.Open;

       for C := 4 downto 1 do begin
         Comp := CompArr[I, C].Create(nil);
         try
           if Comp is TffClient then
             CL.Free
           else if Comp is TffSession then
             SS.Free
           else if Comp is TffDatabase then
             DB.Free
           else if Comp is TffTable then
             TB.Free;
         finally
           Comp.Free;
         end;
       end;

       CL := nil;
       SS := nil;
       DB := nil;
       TB := nil;

       { Sleep a bit so as to avoid overrun of commands between tests. }
       Sleep(100);
    end;
  except
    { For debugging purposes. Set a breakpoint on raise so that we can tell
      where the problem occurs. }
    raise;
  end;
end;
{--------}
procedure TffClientTests.ExtCreationOrderTest;
var
  LT : TffLegacyTransport;
  RSE : TffRemoteServerEngine;
  CL : TffClient;
  SS : TffSession;
  DB : TffDatabase;
  TB : TffTable;
  EL : TffEventLog;
  C, I : Integer;
  LastI, LastC : Integer;
  Comp : TComponent;
  Freeing : Boolean;
  FreeStr : string;
begin
  { This test can only be run with remote server engine. }
  if not RemoteEngine then
    Exit;

  LT := nil;
  RSE := nil;
  CL := nil;
  SS := nil;
  DB := nil;
  TB := nil;
  EL := nil;
  Freeing := False;
  LastC := -1;
  LastI := -1;

  { Test implicit database. }
  try
    LastC := -1;
    for I := low(ExtCompArrNoDB) to high(ExtCompArrNoDB) do begin
     LastI := I;
     Freeing := False;
     for C := 1 to 6 do begin
       LastC := C;
       Comp := ExtCompArrNoDB[I, C].Create(nil);
       if Comp is TffLegacyTransport then
         LT := TffLegacyTransport(Comp)
       else if Comp is TffRemoteServerEngine then
         RSE := TffRemoteServerEngine(Comp)
       else if Comp is TffClient then
         CL := TffClient(Comp)
       else if Comp is TffSession then
         SS := TffSession(Comp)
       else if Comp is TffDatabase then
         DB := TffDatabase(Comp)
       else if Comp is TffTable then
         TB := TffTable(Comp)
       else if Comp is TffEventLog then
         EL := TffEventLog(Comp);
     end;

     EL.Enabled := True;
     EL.FileName := 'Test.Log';

     LT.Protocol := ptSingleUser;
     LT.EventLog := EL;
     LT.EventLogEnabled := True;
     LT.EventLogOptions := [fftpLogErrors, fftpLogRequests, fftpLogReplies];
     LT.Enabled := True;

     RSE.EventLog := EL;
     RSE.EventLogEnabled := True;
     RSE.Transport := LT;

     CL.AutoClientName := True;
     CL.ServerEngine := RSE;
     CL.Open;

     SS.AutoSessionName := True;
     SS.ClientName := CL.ClientName;
     SS.Open;

     TB.SessionName := SS.SessionName;
     TB.DatabaseName := 'Tutorial';
     TB.TableName := 'ExCust';
     TB.Open;

     Freeing := True;
     for C := 6 downto 1 do begin
       LastC := C;
       Comp := ExtCompArr[I, C].Create(nil);
       try
         if Comp is TffLegacyTransport then
           LT.Free
         else if Comp is TffRemoteServerEngine then
           RSE.Free
         else if Comp is TffClient then
           CL.Free
         else if Comp is TffSession then
           SS.Free
         else if Comp is TffDatabase then
           DB.Free
         else if Comp is TffTable then
           TB.Free
         else if Comp is TffEventLog then
           EL.Free;
       finally
         Comp.Free;
       end;
     end;

     LT := nil;
     RSE := nil;
     CL := nil;
     SS := nil;
     DB := nil;
     TB := nil;
     EL := nil;
    end;
  except
    if Freeing then
      FreeStr := 'Freeing'
    else
      FreeStr := 'Creating';
    Check(False, format('TempDB I/C %s: %d/%d', [FreeStr, LastI, LastC]));
  end;

  { Test explicit database. }
  try
    for I := low(ExtCompArr) to high(ExtCompArr) do begin
     LastI := I;
     Freeing := False;
     for C := 1 to 7 do begin
       LastC := C;
       Comp := ExtCompArr[I, C].Create(nil);
       if Comp is TffLegacyTransport then
         LT := TffLegacyTransport(Comp)
       else if Comp is TffRemoteServerEngine then
         RSE := TffRemoteServerEngine(Comp)
       else if Comp is TffClient then
         CL := TffClient(Comp)
       else if Comp is TffSession then
         SS := TffSession(Comp)
       else if Comp is TffDatabase then
         DB := TffDatabase(Comp)
       else if Comp is TffTable then
         TB := TffTable(Comp)
       else if Comp is TffEventLog then
         EL := TffEventLog(Comp);
     end;

     EL.Enabled := True;
     EL.FileName := 'Test.Log';

     LT.Protocol := ptSingleUser;
     LT.EventLog := EL;
     LT.EventLogEnabled := True;
     LT.EventLogOptions := [fftpLogErrors, fftpLogRequests, fftpLogReplies];
     LT.Enabled := True;

     RSE.EventLog := EL;
     RSE.EventLogEnabled := True;
     RSE.Transport := LT;

     CL.AutoClientName := True;
     CL.ServerEngine := RSE;
     CL.Open;

     SS.AutoSessionName := True;
     SS.ClientName := CL.ClientName;
     SS.Open;

     DB.DatabaseName := 'DBxxx';
     DB.SessionName := SS.SessionName;
     DB.AliasName := 'Tutorial';
     DB.Open;

     TB.SessionName := DB.SessionName;
     TB.DatabaseName := DB.DatabaseName;
     TB.TableName := 'ExCust';
     TB.Open;

     Freeing := True;
     for C := 7 downto 1 do begin
       LastC := C;
       Comp := ExtCompArr[I, C].Create(nil);
       try
         if Comp is TffLegacyTransport then
           LT.Free
         else if Comp is TffRemoteServerEngine then
           RSE.Free
         else if Comp is TffClient then
           CL.Free
         else if Comp is TffSession then
           SS.Free
         else if Comp is TffDatabase then
           DB.Free
         else if Comp is TffTable then
           TB.Free
         else if Comp is TffEventLog then
           EL.Free;
       finally
         Comp.Free;
       end;
     end;

     LT := nil;
     RSE := nil;
     CL := nil;
     SS := nil;
     DB := nil;
     TB := nil;
     EL := nil;
    end;
  except
    if Freeing then
      FreeStr := 'Freeing'
    else
      FreeStr := 'Creating';
    Check(False, format('ExplicitDB I/C %s: %d/%d', [FreeStr, LastI, LastC]));
  end;

end;
{--------}
procedure TffDataSetTests.CreateContactTable(const aTableName : string);
var
  Dict : TffDataDictionary;
  FldArray : TffFieldList;
  IHFldList : TffFieldIHList;
begin

  { Create the table. }
  Dict := TffDataDictionary.Create(65536);
  try
    with Dict do begin

      { Add fields }
      AddField('ID', '', fftAutoInc, 0, 0, false, nil);
      AddField('FirstName', '', fftShortString, 25, 0, true, nil);
      AddField('LastName', '', fftShortString, 25, 0, true, nil);
      AddField('Age', '', fftInt16, 5, 0, false, nil);
      AddField('State', '', fftShortString, 2, 0, false, nil);
      AddField('DecisionMaker', '', fftBoolean, 0, 0, false, nil);
      AddField('BirthDate', '', fftDateTime, 0, 0, false, nil);

      { Add indexes }
      FldArray[0] := 0;
      IHFldList[0] := '';
      AddIndex('primary', '', 0, 1, FldArray, IHFldList, False, True, True);

      FldArray[0] := 2;
      IHFldList[0] := '';
      AddIndex('byLastName', '', 0, 1, FldArray, IHFldList, True, True, True);

      FldArray[0] := 1;
      IHFldList[0] := '';
      AddIndex('byFirstName', '', 0, 1, FldArray, IHFldList, True, True, True);

      FldArray[0] := 3;
      IHFldList[0] := '';
      AddIndex(csByAge, '', 0, 1, FldArray, IHFldList, True, True, True);

      FldArray[0] := 4;
      IHFldList[0] := '';
      AddIndex('byState', '', 0, 1, FldArray, IHFldList, True, True, True);

      FldArray[0] := 1;
      FldArray[1] := 2;
      IHFldList[0] := '';
      IHFldList[1] := '';
      AddIndex('byFullName', '', 0, 2, FldArray, IHFldList, True, True, True);

      FldArray[0] := 3;
      FldArray[1] := 4;
      IHFldList[0] := '';
      IHFldList[1] := '';
      AddIndex('byAgeState', '', 0, 2, FldArray, IHFldList, True, True, True);

      FldArray[0] := 4;
      FldArray[1] := 3;
      IHFldList[0] := '';
      IHFldList[1] := '';
      AddIndex('byStateAge', '', 0, 2, FldArray, IHFldList, True, True, True);

      FldArray[0] := 5;
      IHFldList[0] := '';
      AddIndex('byDecisionMaker', '', 0, 1, FldArray, IHFldList, True, True, True);

      FldArray[0] := 3;
      FldArray[1] := 4;
      IHFldList[0] := '';
      IHFldList[1] := '';
      AddIndex('byAgeDecisionMaker', '', 0, 2, FldArray, IHFldList, True, True, True);

    end;

    Database.CreateTable(True, aTableName, Dict);

  finally
    Dict.Free;
  end;
end;
{--------}
procedure TffDatasetTests.CreateTestCaseTable;
const
  cFile = 'TestCaseResults';
begin
  CloneTable('sav' + cFile, cFile);
end;
{--------}
procedure TffDatasetTests.testAddFileBlob;
var
  Table      : TffTable;
  BlobStream : TStream;
  FileStream : TMemoryStream;
  DataFile   : string;
begin
  { NOTE: This test will fail if using a remote server on a remote
          machine. }
  Table := TffTable.Create(nil);
  try
    Table.SessionName := Session.SessionName;
    Table.DatabaseName := Database.DatabaseName;
    Table.TableName := csBLOB;
    Table.Open;
    Table.Insert;
    Table.FieldByName('Title').AsString := 'FileBlob';

    DataFile := ExtractFileDir(Application.ExeName);
    DataFile := Copy(DataFile, 1, LastDelimiter('\', DataFile));
    DataFile := DataFile + 'DATA\Winzip.log';

    Check(FileExists(DataFile), 'Required file ' + DataFile +
                                ' does not exist on local machine.');
    Table.AddFileBlob(2, DataFile);
    Table.FieldByName('Size').AsInteger := -1;
    Table.FieldByName('Type').AsString := 'TEXT';
    Table.Post;
    BlobStream := Table.CreateBlobStream(Table.Fields[1], bmRead);
    FileStream := TMemoryStream.Create;
    FileStream.LoadFromFile(DataFile);
    try
      BlobStream.Position := 0;
      FileStream.Position := 0;
      CheckEquals(BlobStream.Size, FileStream.Size, 'Differing file sizes');
      CompareMatchedStreams(BlobStream, FileStream, FileStream.Size);
    finally
      BlobStream.Free;
      FileStream.Free;
      Table.Close;
    end;
  finally
    Table.Free;
  end;
end;
{--------}
procedure TffDatasetTests.testBookmarkValid;
var
  Table : TffTable;
  BM : TBookmark;
begin
  Table := TffTable.Create(nil);
  try
    Table.SessionName := Session.SessionName;
    Table.DatabaseName := Database.DatabaseName;
    Table.TableName := csBLOB;

    { Table is not open bookmark should not be valid}
    Assert(not Table.BookmarkValid(nil));

    Table.Open;

    { Nil bookmark should not be valid }
    Assert(not Table.BookmarkValid(nil));

    { This should not be valid either }
    BM := Self;
    Assert(not Table.BookmarkValid(BM));

    { This should be valid }
    BM := Table.GetBookmark;
    Assert(Table.BookmarkValid(BM));

    { Table is not open bookmark should not be valid}
    Table.Close;
    Assert(not Table.BookmarkValid(BM));
    Table.FreeBookmark(BM);
  finally
    Table.Free;
  end;
end;
{--------}
procedure TffDatasetTests.testCompareBookmarks;
var
  BM1, BM2 : TBookmark;
  Table : TffTable;
begin
  Table := TffTable.Create(nil);
  try
    Table.SessionName := Session.SessionName;
    Table.DatabaseName := Database.DatabaseName;
    Table.TableName := csBLOB;

    { Bookmarks are both nil, therefore equal }
    BM1 := nil;
    BM2 := nil;
    Assert(0 = Table.CompareBookmarks(BM1, BM2));

    { BM2 is greater }
    BM2 := Self;
    Assert(1 = Table.CompareBookmarks(BM1, BM2));

    { BM1 is greater }
    BM1 := Self; BM2 := nil;
    Assert(-1 = Table.CompareBookmarks(BM1, BM2));

    { BM2 is greater }
    Table.Open;
    BM1 := Table.GetBookmark;
    Table.Next;
    BM2 := Table.GetBookmark;
    Assert(-1 = Table.CompareBookmarks(BM1, BM2));
    Assert(1 = Table.CompareBookmarks(BM2, BM1));
    Table.FreeBookmark(BM1);
    Table.FreeBookmark(BM2);

    Table.Close;
  finally
    Table.Free;
  end;
end;
{--------}
procedure TffDatasetTests.testCopyRecords;
const
  csTblName = 'Contacts1';
  csTbl2Name = 'Contacts2';
  cNumRecs = 1000;
var
  aCursor, aCursor2 : TffTable;
  Dict, Dict2 : TffDataDictionary;
  ExceptRaised : boolean;
begin

  { Build a common dictionary used to create the tables in this test. }
  Dict := CreateContactDict;

  aCursor := TffTable.Create(nil);
  try
    aCursor.SessionName := Session.SessionName;
    aCursor.DatabaseName := Database.DatabaseName;
    aCursor.TableName := csTblName;
    Check(Database.CreateTable(True, csTblName, Dict) = DBIERR_NONE,
          'Could not create table ' + csTblName);
    aCursor.Open;

    { Verify that we cannot copy to the same table. }
    aCursor2 := TffTable.Create(nil);
    aCursor2.SessionName := Session.SessionName;
    aCursor2.DatabaseName := Database.DatabaseName;
    aCursor2.TableName := csTblName;
    aCursor2.Open;

    try
      ExceptRaised := False;
      try
        aCursor2.CopyRecords(aCursor, False);
      except
        on E:EffDatabaseError do begin
          ExceptRaised := (E.ErrorCode = DBIERR_FF_SameTable);
        end;
      end;
      Assert(ExceptRaised, 'Copy to same table did not raise exception.');
    finally
      aCursor2.Free;
      Session.CloseInactiveTables;
    end;

    { Verify that the dictionaries must have the same structure. }
    Dict2 := CreateContactDict;
    try
      Dict2.AddField('Student', '', fftBoolean, 0, 0, false, nil);
      aCursor2 := TffTable.Create(nil);
      aCursor2.SessionName := Session.SessionName;
      aCursor2.DatabaseName := Database.DatabaseName;
      aCursor2.TableName := csTbl2Name;
      Check(Database.CreateTable(True, csTbl2Name, Dict2) = DBIERR_NONE,
            'Could not create table ' + csTbl2Name);
      aCursor2.Open;
      ExceptRaised := False;
      try
        aCursor2.CopyRecords(aCursor, False);
      except
        on E:EffDatabaseError do begin
          ExceptRaised := (E.ErrorCode = DBIERR_FF_IncompatDict);
        end;
      end;
      Assert(ExceptRaised, 'Differing dictionaries did not raise exception.');
    finally
      aCursor2.Free;
      Dict2.Free;
      Session.CloseInactiveTables;
      if FileExists(csTbl2Name + '.ff2') then
        DeleteFile(csTbl2Name + '.ff2');
    end;

    { This method does not test the actual copying since that is tested at the
      server engine level in <FF 2>\Test\Cursor\TestCursor.pas. }

  finally
    aCursor.Free;
    Dict.Free;
    Session.CloseInactiveTables;
    if FileExists(csTblName + '.ff2') then
      DeleteFile(csTblName + '.ff2');
  end;

end;
{--------}
procedure TffDatasetTests.testCreateBlobStream;
begin
  { Tested in AddFileBlob }
  Assert(True);
end;
{--------}
procedure TffDatasetTests.testDeleteTable;
var
  Table : TffTable;
begin
  Table := TffTable.Create(nil);
  try
    Table.SessionName := Session.SessionName;
    Table.DatabaseName := Database.DatabaseName;
    Table.TableName := csBLOB;
    Table.DeleteTable;
    try
      Table.Open;
      Assert(False);
    except
    end;
  finally
    Table.Free;
  end;
end;

procedure TffDatasetTests.testEmptyTable;
var
  Table : TffTable;
begin
  Table := TffTable.Create(nil);
  try
    Table.SessionName := Session.SessionName;
    Table.DatabaseName := Database.DatabaseName;
    Table.TableName := csCust;
    Table.Open;
    Assert(Table.RecordCount > 0);
    Table.EmptyTable;

    Assert(Table.RecordCount = 0);
  finally
    Table.Free;
  end;
end;
{--------}
procedure TffDatasetTests.testGetCurrentRecord;
var
  Table : TffTable;
  Buffer : PChar;
  Result : Boolean;
begin
  Buffer := nil;
  Table := TffTable.Create(nil);
  try
    Table.SessionName := Session.SessionName;
    Table.DatabaseName := Database.DatabaseName;
    Table.TableName := csCust;

    {should fail on a closed dataset}
    try
      Result := Table.GetCurrentRecord(Buffer);
      Assert(not Result);
    except
    end;

    table.Open;

    Table.Next;
    GetMem(Buffer, 150);
    try
      {now it should work}
      try
        Result := Table.GetCurrentRecord(Buffer);
        Assert(Result);
      except
        Assert(False);
      end;
    finally
      FreeMem(Buffer);
    end;
  finally
    Table.Free;
  end;
end;
{--------}
procedure TffDatasetTests.testGetFieldData;
var
  Table : TffTable;
  Buffer : PChar;
begin
  Table := TffTable.Create(nil);
  try
    Table.SessionName := Session.SessionName;
    Table.DatabaseName := Database.DatabaseName;
    Table.TableName := csCust;

    table.Open;
    {should fail w/a null buffer}
    Table.First;
//    Buffer := nil;
//    try
//      Result := Table.GetFieldData(Table.FieldByName('LastName'), Buffer);
//      Assert(not Result);
//    except
//    end;

    GetMem(Buffer, 55);
    try
      try
        Table.GetFieldData(Table.FieldByName('LastName'), Buffer);
        Assert(Buffer = 'Boyd');
      except
        Assert(False);
      end;
    finally
      FreeMem(Buffer);
    end;
  finally
    Table.Free;
  end;
end;
{--------}
procedure TffDatasetTests.testGetRecordBatch;
var
  Table : TffTable;
  Buffer : array[0..900] of char;
  RetCount : Integer;
begin
  Table := TffTable.Create(nil);
  try
    Table.SessionName := Session.SessionName;
    Table.DatabaseName := Database.DatabaseName;
    Table.TableName := csCust;

    Table.Open;

      {should fail on a closed dataset}
  //    try
  //      Table.GetRecordBatch(4, RetCount, Buffer);
  //      Assert(False);
  //    except
  //    end;

      {should fail w/a null buffer}
  //    Buffer := nil;
  //    try
  //      Table.GetRecordBatch(4, RetCount,Buffer);
  //      Assert(False);
  //    except
  //    end;

    try
      Table.GetRecordBatch(4, RetCount, @Buffer);
      {should return 4 records}
      Assert(RetCount = 4);
      {the first byte of the first field of the first record should be '1'}
      Assert(PInteger(@Buffer)^ = 2);
    except
      Assert(False);
    end;
  finally
    Table.Free;
  end;
end;
{--------}
procedure TffDatasetTests.testGetRecordBatchEx;
var
  Table : TffTable;
  Buffer : array[0..5000] of char;
  RetCount : Integer;
  ErrorMsg : Integer;
begin
  Table := TffTable.Create(nil);
  try
    try
      Table.SessionName := Session.SessionName;
      Table.DatabaseName := Database.DatabaseName;
      Table.TableName := csCust;

      Table.open;

      {should fail w/a null buffer}
  //    Table.First;
  //    Buffer := nil;
  //    try
  //      Table.GetRecordBatchEx(4, RetCount,Buffer, ErrorMsg);
  //      Assert(False);
  //    except
  //    end;

      Table.Next;
      Table.Next;
      Table.Next;

      Table.GetRecordBatchEx(10, RetCount, @Buffer, ErrorMsg);
      {should return 10 records}
      Assert(RetCount = 10);
      {the first byte of the first field of the fourth record should be '4'}
      Assert(PInteger(@Buffer)^ = 5);
      {we should not get an error}
      Assert(ErrorMsg = 0);
    except
      Assert(False);
    end;
  finally
    Table.Free;
  end;
end;
{--------}
procedure TffDatasetTests.testGotoCurrent;
var
  BM1, BM2 : TBookmark;
  Table1, Table2 : TffTable;
begin

  Table1 := TffTable.Create(nil);
  Table1.SessionName := Session.SessionName;
  Table1.DatabaseName := Database.DatabaseName;
  Table1.TableName := csBLOB;

  Table2 := TffTable.Create(nil);
  Table2.SessionName := Table1.SessionName;
  Table2.DatabaseName := Table1.DatabaseName;
  Table2.TableName := Table1.TableName;

  try
    Table1.Open;
    Table1.MoveBy(Table1.RecordCount div 2);

    Table2.Open;
    Table2.GotoCurrent(Table1);

    BM1 := Table1.GetBookmark;
    BM2 := Table2.GetBookmark;
    Assert(0 = Table1.CompareBookmarks(BM1, BM2));
  finally
    Table2.Close;
    Table2.Free;
    Table1.Close;
    Table1.Free;
  end;

end;
{--------}
procedure TffDatasetTests.testInsertRecordBatch;
const
  cNumRecs1 = 100;
  cNumRecs2 = 600;
var
  aValue : string;
  Index : integer;
  pCurRec, pRecBuff : PffByteArray;
  pErrors : PffLongIntArray;
  RecLen : LongInt;
begin

  pErrors := nil;
  pRecBuff := nil;

  { Verify that we can insert records. }

  { Allocate memory for the records & prepare the records.
    We will insert contacts whose every field value is a sequential number
    (e.g., FirstName = '1', LastName = '1', State = '1').
    This makes it easier for us to verify our results. }
  tblExCust.Timeout := 1000000; {SPW}
  tblExCust.Open;
  RecLen := tblExCust.Dictionary.RecordLength;
  FFGetZeroMem(pRecBuff, RecLen * cNumRecs1);
  try
    pCurRec := pRecBuff;
    for Index := 1 to cNumRecs1 do begin
      with tblExCust.Dictionary do begin
        aValue := intToStr(Index);
        SetRecordField(1, pCurRec, PChar(aValue));
        SetRecordField(2, pCurRec, PChar(aValue));
        SetRecordField(3, pCurRec, PChar(aValue));
        SetRecordField(4, pCurRec, PChar(aValue));
        SetRecordField(5, pCurRec, PChar(aValue));
        SetRecordField(6, pCurRec, PChar(aValue));
        inc(PChar(pCurRec), RecLen);
      end;
    end;

    { Prepare the errors array. }
    FFGetZeroMem(pErrors, SizeOf(Longint) * cNumRecs1);
    try
      { Insert the records. }
      Assert(tblExCust.InsertRecordBatch(cNumRecs1, pRecBuff, pErrors) = DBIERR_NONE,
             'Inserting batch of records failed');
    finally
      FFFreeMem(pErrors, SizeOf(Longint) * cNumRecs1);
    end;

    { Verify the records are really there.
      Strategy: Switch to an index that will allow us to quickly locate the
        first inserted record. Locate that record. Switch back to the
        sequential access index & scan through the records. }
    tblExCust.IndexName := 'byName';
    tblExCust.FindNearest(['1']);
    Assert(tblExCust.FieldByName('FirstName').asString = '1',
           'Did not find first contact record.');
    tblExCust.IndexName := '';
    for Index := 2 to cNumRecs1 do begin
      tblExCust.Next;
      Assert(tblExCust.FieldByName('FirstName').asString = IntToStr(Index),
             format('Did not find contact %d',[IntToStr(Index)]));
    end;
  finally
    FFFreeMem(pRecBuff, RecLen * cNumRecs1);
  end;

  { Verify that we can cause & detect a failure. We will do this by trying
    to insert duplicate records. }
  FFGetZeroMem(pRecBuff, RecLen * cNumRecs1);
  try

    { Set up the record buffers. }
    pCurRec := pRecBuff;
    for Index := 1 to cNumRecs1 do begin
      with tblExCust.Dictionary do begin
        aValue := intToStr(Index);
        SetRecordField(0, pCurRec, @Index);
        SetRecordField(1, pCurRec, PChar(aValue));
        SetRecordField(2, pCurRec, PChar(aValue));
        SetRecordField(3, pCurRec, PChar(aValue));
        SetRecordField(4, pCurRec, PChar(aValue));
        SetRecordField(5, pCurRec, PChar(aValue));
        SetRecordField(6, pCurRec, PChar(aValue));
        inc(PChar(pCurRec), RecLen);
      end;
    end;

    { Prepare the errors array. }
    FFGetZeroMem(pErrors, SizeOf(Longint) * cNumRecs1);
    try
      { Insert the records. }
      Assert(tblExCust.InsertRecordBatch(cNumRecs1, pRecBuff, pErrors) = DBIERR_KEYVIOL,
             'Failure not detected as expected.');
    finally
      FFFreeMem(pErrors, SizeOf(Longint) * cNumRecs1);
    end;
  finally
    FFFreeMem(pRecBuff, RecLen * cNumRecs1);
  end;

end;
{--------}
procedure TffDatasetTests.testLockTable;
var
  ExceptRaised : boolean;
  Table1, Table2 : TffTable;
begin


  exit;

  Table1 := TffTable.Create(nil);
  Table1.SessionName := Session.SessionName;
  Table1.DatabaseName := Database.DatabaseName;
  Table1.TableName := csCust;
  Table1.Open;

  Table2 := TffTable.Create(nil);
  Table2.SessionName := Session.SessionName;
  Table2.DatabaseName := Database.DatabaseName;
  Table2.TableName := csCust;
  Table2.Timeout := 2000;
  Table2.Open;

  try
    { Verify that if table A has a record lock then table B cannot obtain a
      read or write lock. }
    ExceptRaised := False;
    Table1.Edit;
    try
      try
        Table2.LockTable(ffltReadLock);
      except
        ExceptRaised := True;
      end;
      Assert(ExceptRaised, 'Rec1-Read2, Exception not raised');
      try
        Table2.LockTable(ffltWriteLock);
      except
        ExceptRaised := True;
      end;
      Assert(ExceptRaised, 'Rec1-Write2, Exception not raised');
    finally
      Table1.Cancel;
    end;

    { Verify that if table A obtains a read lock then table B can also obtain
      a read lock. }
    ExceptRaised := False;
    Table1.LockTable(ffltReadLock);
    try
      Table2.LockTable(ffltReadLock);
      Table2.UnlockTable(ffltReadLock);
    except
      ExceptRaised := True;
    end;
    Assert(not ExceptRaised, 'Read-Read, Unexpected exception');

    { Verify that if there is a read-lock on the table then a record lock
      may not be obtained by either the locking table or another table. }
    ExceptRaised := False;
    try
      Table1.Edit;
    except
      ExceptRaised := True;
    end;
    Assert(ExceptRaised, 'R1-Edit1, Exception not raised');

    ExceptRaised := False;
    try
      Table2.Edit;
    except
      ExceptRaised := True;
    end;
    Assert(ExceptRaised, 'R1-Edit2, Exception not raised');

    { Verify that if table A obtains a read lock then table B cannot obtain a
      write lock. }
    ExceptRaised := False;
    try
      Table2.LockTable(ffltWriteLock);
    except
      on E:EffDatabaseError do begin
        ExceptRaised := (E.ErrorCode = DBIERR_FILELOCKED);
      end;
    end;
    Assert(ExceptRaised, 'Read-Write, Exception not raised');

    { Verify that if table A obtains a write lock then table B cannot obtain a
      read lock. }
    ExceptRaised := False;
    Table1.LockTable(ffltWriteLock);
    try
      Table2.LockTable(ffltReadLock);
    except
      on E:EffDatabaseError do begin
        ExceptRaised := (E.ErrorCode = DBIERR_FILELOCKED);
      end;
    end;
    Assert(ExceptRaised, 'Write-Read, Exception not raised');

    { Verify that if table A obtains a write lock then table B cannot obtain
      a record lock. }
    ExceptRaised := False;
    try
      Table2.Edit;
    except
      ExceptRaised := True;
    end;
    Assert(ExceptRaised, 'W1-Edit2, Exception not raised');

    { Verify that if table A obtains a write lock then table A can obtain a
      record lock. }
    ExceptRaised := False;
    try
      Table1.Edit;
      Table1.Cancel;
    except
      ExceptRaised := True;
    end;
    Assert(not ExceptRaised, 'W1-Edit1, Exception raised');

    { Verify that if table A obtains a write lock then table B cannot obtain a
      write lock. }
    ExceptRaised := False;
    try
      Table2.LockTable(ffltWriteLock);
    except
      on E:EffDatabaseError do begin
        ExceptRaised := (E.ErrorCode = DBIERR_FILELOCKED);
      end;
    end;
    Assert(ExceptRaised, 'Write-Write, Exception not raised');
  finally
    Table1.Close;
    Table1.Free;
    Table2.Close;
    Table2.Free;
  end

end;
{--------}
procedure TffDatasetTests.testPackTable;
const
  cNumPacks = 25;
var
  aTaskID : integer;
  DelChance : integer;
  Done : boolean;
  OrigRecCount : integer;
  PackIndex : integer;
  RecIndex : integer;
  RecList : TList;
  Table : TffTable;
  TaskStatus : TffRebuildStatus;
  ThisID : longInt;
begin


  Table := TffTable.Create(nil);
  Table.SessionName := Session.SessionName;
  Table.DatabaseName := Database.DatabaseName;
  Table.TableName := csCust;
  Table.Timeout := 50000;

  try
    Randomize;
    RecList := TList.Create;

    { Loop through a series of packs. Prior to each pack, randomly delete records
      from the table. Track those records that are kept in the table. After the
      table is packed, verify that only those records we expect to be in the table
      are in the table. }
    for PackIndex := 1 to cNumPacks do begin
      Application.ProcessMessages;
      { Close & re-open the database so that the ExCust table is closed and
        we can replace it. Note that this client class stuff should really
        be using the FF API to create tables instead of copying around
        the saved file stuff. }
      FDatabase.Connected := False;
      FDatabase.Connected := True;
      { Calculate the chance of a record being deleted. }
      DelChance := 10 + random(60);
      { Get a fresh copy of the table to be packed. }
      CreateExCustTable;

      { Figure out which records are to be deleted from the table. }
      Table.Open;
      OrigRecCount := Table.RecordCount;
      ThisID := Table.FieldByName('CustomerID').asInteger;
      while not Table.EOF do begin
        if Random(100) < DelChance then begin
          Table.Delete;
          { If we delete the last record, the VCL will position us to the prior
           record. Look for this case and move to EOF so that we fall out of this
           loop gracefully. }
          if ThisID = OrigRecCount then
            Table.Next;
        end
        else begin
          RecList.Add(pointer(Table.FieldByName('CustomerID').asInteger));
          Table.Next;
        end;
        if not Table.EOF then begin
          Assert(ThisID + 1 = Table.FieldByName('CustomerID').asInteger,
                 format('ID mismatch, lastID: %d, currentID: %d',
                        [ThisID, Table.FieldByName('CustomerID').asInteger]));
          ThisID := Table.FieldByName('CustomerID').asInteger;
        end;
      end;

      { Verify we have some records. }
      if Table.RecordCount > 0 then
        Assert(RecList.Count = Table.RecordCount,
             format('Stage 1: Record count mismatch, list: %d, table: %d',
                    [RecList.Count, Table.RecordCount]));


      { Pack the table. }
      Table.Close;
      Table.PackTable(aTaskID);

      { Wait until the pack is done. }
      Done := False;
      while not Done do begin
        Session.GetTaskStatus(aTaskID, Done, TaskStatus);
        Application.ProcessMessages;
      end;

      { Loop through the table, verifying the correct records are present. }
      Table.Open;
      Assert(RecList.Count = Table.RecordCount,
             format('Stage 2: Record count mismatch, list: %d, table: %d',
                    [RecList.Count, Table.RecordCount]));
      RecIndex := 0;
      while not Table.EOF do begin
        Assert(Table.FieldByName('CustomerID').asInteger = Integer(RecList.Items[RecIndex]));
        Table.Next;
        inc(RecIndex);
        if RecIndex mod 100 = 0 then
          Application.ProcessMessages;
      end;

      Table.Close;

      { Clear the record list. }
      RecList.Clear;

    end;
  finally
    Table.Free;
  end;
end;
{--------}
procedure TffDatasetTests.testReadBLOBs;
const
  ciRepeatCount = 10;
  ciBLOBCount = 10;
  ciBLOBRepeat = 100;
  csTableName = 'MongoBLOBs';
var
  aBuffer : string;
  ArrayInx,
  CheckInx,
  Cutoff,
  RepeatInx,
  RepeatInx2 : Integer;
  BLOBTbl : TffTable;
  Strm : TMemoryStream;
  BLOBFld : TBLOBField;
  BLOBStrm : TffBLOBStream;
  CharArray : array[1..10] of Char;
  SizeArray : array[1..10] of Integer;
begin
  Cutoff := ciBLOBRepeat div 2;
  { Create a table to hold some BLOBs. }
  BLOBTbl := TffTable.Create(nil);
  try
    BLOBTbl.SessionName := Session.SessionName;
    BLOBTbl.DatabaseName := Database.DatabaseName;
    BLOBTbl.TableName := csTableName;

    BLOBTbl.FieldDefs.Add('ID', ftAutoInc, 0, False);
    BLOBTbl.FieldDefs.Add('BLOB', ftMemo, 0, False);
    BLOBTbl.CreateTable;

    for RepeatInx := 1 to ciRepeatCount do begin

      BLOBTbl.EmptyTable;
      BLOBTbl.Open;

      BLOBFld := TBLOBField(BLOBTbl.FieldByName('BLOB'));

      for RepeatInx2 := 1 to ciBLOBCount do begin
        CharArray[RepeatInx2] := Char(Random(26) + 65);
        SizeArray[RepeatInx2] := 100000 + Random(100000);
        aBuffer := StringOfChar(CharArray[RepeatInx2], SizeArray[RepeatInx2]);
        BLOBTbl.Insert;
        BLOBStrm := TffBLOBStream(BLOBTbl.CreateBlobStream(BLOBFld, bmWrite));
        BLOBStrm.Write(aBuffer[1], Length(aBuffer));
        BLOBStrm.Free;
        BLOBTbl.Post;
      end;

      { Read the BLOBs repeatedly. }
      for RepeatInx2 := 1 to ciBLOBRepeat do begin
        BLOBTbl.First;
        ArrayInx := 1;
        while not BLOBTbl.EOF do begin
          Strm := TMemoryStream.Create;
          try
            TBLOBField(BLOBTbl.FieldByName('BLOB')).SaveToStream(Strm);
            { Verify the size of the stream. }
            CheckEquals(SizeArray[ArrayInx], Strm.Size,
                        Format('Size invalid for BLOB %d', [ArrayInx]));
            { First half of ciBLOBRepeat, we go for speed. In second half,
              verify content of stream. }
            if RepeatInx2 > Cutoff then
              for CheckInx := 0 to Pred(SizeArray[ArrayInx]) do begin
                Assert(PChar(Strm.Memory)[CheckInx] = CharArray[ArrayInx],
                       Format('Invalid char at position %d of BLOB %d',
                              [CheckInx, ArrayInx]));
            end;
          finally
            Strm.Free;
          end;
          BLOBTbl.Next;
          inc(ArrayInx);
          Application.ProcessMessages;
        end;  { while }
      end;  { for }
    end;  { for }
  finally
    BLOBTbl.Free;
    Session.CloseInactiveTables;
    if FileExists(csTableName) then
      DeleteFile(csTableName);
  end;
end;
{--------}
procedure TffDatasetTests.testRenameTable;
begin

end;
{--------}
procedure TffDatasetTests.testRestructureTable;
const
  csNumContactsPerTable = 1000;
  csNumTables = 50;
var
  aDict : TffDataDictionary;
  aFieldMap : TStringList;
  aList : TList;
  anInx, anInx2 : Integer;
  aTable : TffTable;
  aTmpTable : TffTable;
  aTaskID : Integer;
  Done : Boolean;
  TaskStatus : TffRebuildStatus;
begin

  { Initial test: Verify that we can restructure a large number of tables
    & then open those tables. }

  { First, create and populate the tables. }
  aTable := TffTable.Create(nil);
  aFieldMap := TStringList.Create;
  aList := TList.Create;
  try
    for anInx := 1 to csNumTables do begin
      CreateContactTable(csContacts + intToStr(anInx));
      aTable.SessionName := Session.SessionName;
      aTable.DatabaseName := Database.DatabaseName;
      aTable.TableName := csContacts + intToStr(anInx);
      aTable.Open;
      InsertRandomContacts(aTable, csNumContactsPerTable);
      aTable.Close;
    end;  { for }

    { Second, open the database exclusively and restructure the tables. }
    Database.Close;
    Database.Exclusive := True;
    Database.Open;

    aDict := TffDataDictionary.Create(65536);
    try
      for anInx := 1 to csNumTables do begin
        aDict.Clear;
        aDict.Assign(aTable.Dictionary);
        aTable.TableName := csContacts + intToStr(anInx);
        aFieldMap.Clear;
        for anInx2 := 0 To pred(aDict.FieldCount) do
          aFieldmap.add(Format('%s=%s',[aDict.Fieldname[anInx2],
                                        aDict.Fieldname[anInx2]]));
        aTable.RestructureTable(aDict, aFieldMap, aTaskID);

        { Wait until the restructure is done. }
        Done := False;
        while not Done do begin
          Session.GetTaskStatus(aTaskID, Done, TaskStatus);
          Application.ProcessMessages;
        end;
      end;
    finally
      aDict.Free;
    end;

    Database.Close;
    Database.Exclusive := False;
    Database.Open;

    { Third, open the tables. }
    for anInx := 1 to csNumTables do begin
      aTmpTable := TffTable.Create(nil);
      aTmpTable.SessionName := Session.SessionName;
      aTmpTable.DatabaseName := Database.DatabaseName;
      aTmpTable.TableName := csContacts + intToStr(anInx);
      aTmpTable.Open;
      aList.Add(pointer(aTmpTable));
    end;

  finally
    { Finally, get rid of the tables. }
    Database.Close;
    Database.Open;
    for anInx := pred(aList.Count) downto 0 do begin
      aTmpTable := TffTable(aList.Items[anInx]);
      aTmpTable.DeleteTable;
      aTmpTable.Free;
      aList.Delete(anInx);
    end;

    aTable.Free;
    aFieldMap.Free;
    aList.Free;
  end;

  { TODO:: Verify restructuring of all field types and indexes. Verify
    use of field map. }
end;
{--------}
procedure TffDatasetTests.testSetTableAutoIncValue;
{fix create table with autoinc for testing}
begin
(*
var
  TickCount : Integer;
begin
  Make sure it cannot be called unless the table is open
  TickCount := GetTickCount;
  tblExCust.SetTableAutoIncValue(TickCount);
  tblExCust.InsertRecord([]);
  Assert(tblExCust.Fields[0].Value = Succ(TickCount));

*)
end;
{--------}
procedure TffDatasetTests.testTruncateBlob;
begin
{  Make sure it cannot be called unless the table is open
  { Cycle through ExBlob

end;
{--------}
procedure TffDatasetTests.testUnlockTable;
begin

end;
{--------}
procedure TffDatasetTests.testUnlockTableAll;
begin

end;
{--------}
procedure TffDatasetTests.testIsSequenced;
begin
  {we don't support record numbers so this will always return false}
  Assert(not tblExcust.IsSequenced);
end;
{--------}
procedure TffDatasetTests.testSessionProp;
var
  Session : TffSession;
begin

  Session := tblExCust.Session;
  Assert(Assigned(Session));
end;
{--------}
procedure TffDatasetTests.testCursorIDProp;
var
  Cursor : Longint;
begin

  Cursor := tblExCust.CursorID;
  Assert(Cursor <> -9999);
  Assert(Cursor <> -1);
end;
{--------}
procedure TffDatasetTests.testDatabaseProp;
var
  DB : TffBaseDatabase;
begin

  DB := tblExCust.Database;
  Assert(Assigned(DB));
end;
{--------}
procedure TffDatasetTests.testDictionaryProp;
var
  Dict : TffDataDictionary;
begin

  tblExLines.Open;
  Dict := tblExLines.Dictionary;
  Assert(Assigned(Dict));
  try
    Dict.CheckValid;
  except
    Assert(False);
  end;
end;
{--------}
procedure TffDatasetTests.testServerEngineProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testDatabaseNameProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testFilterEvalProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testFilterResyncProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testFilterTimeoutProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testOnServerFilterTimeoutEvent;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testSessionNameProp;
begin
  {make sure the sessionname cannot be changed if active.}
  { TODO }
end;
{--------}
procedure TffDatasetTests.testTimeoutProp;
begin
  tblExCust.Timeout := 9999;
  Assert(tblExCust.Timeout = 9999);
  {make sure that the timeout is set, and get returns the
   new timeout.
end;
{--------}
procedure TffDatasetTests.testVersionProp;
begin
  Assert(tblExCust.Version = Session.Version);
end;
{--------}
procedure TffDatasetTests.testAddIndex;
var
  Table : TffTable;
begin
  CreateTestCaseTable;
  Table := TffTable.Create(nil);
  try
    Table.SessionName := Session.SessionName;
    Table.DatabaseName := Database.DatabaseName;
    Table.TableName := 'TestCaseResults';

    Table.Exclusive := True;

    try
      Table.AddIndex('byTestRun', 'TestCaseID;RunID', []);
      if Table.Dictionary.GetIndexFromName('byTestRun') = -1 then
        Assert(False);
    except
      Assert(False);
    end;
  finally
    Table.Free;
  end;
end;
{--------}
procedure TffDatasetTests.testAddIndexEx;
var
  Done : boolean;
  MyIndex : TffIndexDescriptor;
  FldLst  : TffFieldList;
  Status  : TffResult;
  TaskID  : Integer;
  TaskStatus : TffRebuildStatus;
begin
//  tblExProds.Open;
  MyIndex.idNumber := 3;
  MyIndex.idName := 'byPrice';
  MyIndex.idFile := 0;
  MyIndex.idKeyLen := 8;
  MyIndex.idCount := 1;
  FldLst[0] := 2;
  MyIndex.idFields := FldLst;
  FillChar(MyIndex.idFieldIHlprs, sizeof(TffFieldIHList), 0);
  MyIndex.idDups := True;
  MyIndex.idAscend := True;
  MyIndex.idNoCase := True;
  try
    if tblExProds.AddIndexEx(MyIndex, TaskID) <> 0 then
      Assert(False);
    { Wait until the reindex is done. }
    Done := False;
    Status := DBIERR_NONE;
    while (not Done) and (Status = DBIERR_NONE) do
      Status := Session.GetTaskStatus(TaskID, Done, TaskStatus);

    Assert(Status = DBIERR_NONE, 'Unexpected status returned');

    { See if the index is really there. Must open the table in order to see
      the updated index. }
    tblExProds.Open;
    if tblExProds.Dictionary.GetIndexFromName('byPrice') = -1 then
      Assert(False);
  except
    On E: Exception do
      Assert(False, E.message);
  end;
end;
{--------}
procedure TffDatasetTests.testApplyRange;
begin

  tblExLines.Open;
  tblExLines.IndexName := 'byID';
  tblExLines.SetRangeStart;
  tblExLInes.FieldByName('LineID').Value := 5;
  tblExLines.SetRangeEnd;
  tblExLines.FieldByName('LineID').Value := 10;
  tblExLines.ApplyRange;
  Assert(tblExLines.RecordCount = 6);
  tblExLines.CancelRange;
end;
{--------}
procedure TffDatasetTests.testCancel;
var
  DB1, DB2 : TffDatabase;
  Table1, Table2 : TffTable;
begin

  tblExLines.Open;
  tblExLines.Edit;
  tblExLines.Cancel;
  Assert(tblExLines.State = dsBrowse);
  tblExLines.Close;

  Exit;
  { TODO:: When change handling of Table.Cancel in this situation, re-activate
    the following test code. }
  { SPW: Now for some meat <g>... }

  { Edit a record with table A then attempt to edit the same record, whilst
    inside a transaction, with table B. Note that each table must be associated
    with its own database.

    Once the edit fails to obtain a record lock, cancel the edit & rollback
    the transaction.

    The reason for this test is that the call to Cancel would fail because it
    couldn't obtain a shared content lock on the table. It does work okay if
    you first do rollback & then cancel. Our goal is to
    overcome this problem because so many people do cancel and then rollback
    instead of the other way around. }
  DB1 := TffDatabase.Create(nil);
  DB2 := TffDatabase.Create(nil);
  Table1 := TffTable.Create(nil);
  Table2 := TffTable.Create(nil);
  try
    DB1.SessionName := FSession.SessionName;
    DB1.AutoDatabaseName := True;
    DB1.AliasName := FDatabase.AliasName;
    DB2.SessionName := FSession.SessionName;
    DB2.AutoDatabaseName := True;
    DB2.AliasName := FDatabase.AliasName;

    Table1.SessionName := DB1.SessionName;
    Table1.DatabaseName := DB1.DatabaseName;
    Table1.TableName := tblExCust.TableName;
    Table1.Open;

    Table2.SessionName := DB2.SessionName;
    Table2.DatabaseName := DB2.DatabaseName;
    Table2.TableName := tblExCust.TableName;
    Table2.Open;

    DB1.StartTransaction;
    try
      Table1.Edit;
      Table1.FieldByName('FirstName').AsString := 'EditedByTable1';
      Table1.Post;

      try
        DB2.StartTransaction;
        Table2.Append;
        Table2.FieldByName('FirstName').AsString := 'AddedByTable2';
        Table2.FieldByName('Zip').AsString := '80919';
        Table2.Post;
        DB2.Commit;
        { If we make it to this point, we've obtained a record lock even
          though the record was already locked. Raise an error. }
        Check(False, 'Table 2 was able to lock the record being edited!!');
      except
        on E:Exception do begin
          Table2.Cancel;
          DB2.Rollback;
        end;
      end;
    finally
      DB1.Rollback;
    end;

  finally
    Table2.Free;
    Table1.Free;
    DB2.Free;
    DB1.Free;
  end;

end;
{--------}
procedure TffDatasetTests.testCancelRange;
begin

  tblExLines.Open;
  tblExLines.IndexName := 'byID';
  tblExLines.SetRangeStart;
  tblExLines.FieldByName('LineID').Value := 5;
  tblExLines.SetRangeEnd;
  tblExLines.FieldByName('LineID').Value := 10;
  tblExLines.ApplyRange;
  Assert(tblExLines.RecordCount = 6);
  tblExLines.CancelRange;
  Assert(tblExLines.RecordCount = 1000);
end;
{--------}
procedure TffDatasetTests.testCreateTable;
begin

  tblExLines.Open;
  tblExLines.CreateTable;
  tblExLines.Open;
  Assert(tblExLines.RecordCount = 0);
end;
{--------}
procedure TffDatasetTests.testDeleteIndex;
begin

end;
{--------}
procedure TffDatasetTests.testDeleteRecords;
const
  cNumComboDeletes = 50;
  cNumFilterDeletes = 10;
  cNumRangeDeletes = 100;
var
  i,
  CustID,
  ProductID,
  RecCount,
  StartOrder, EndOrder,
  TotalRecCount : Integer;
  State : string;
begin
  Randomize;

  { Delete all records in ExCust table. }
  tblExCust.IndexName := 'ByID';
  tblExCust.Open;
  Assert(tblExCust.RecordCount > 0, 'tblExCust is empty');
  tblExCust.DeleteRecords;
  CheckEquals(0, tblExCust.RecordCount,
              'Invalid record count for delete of all ExCust records');

  { Test ranged delete. Randomly set ranges on State field of ExCust table and
    delete the records within the range. }
  CreateExCustTable;
  tblExCust.IndexName := csByState;
  tblExCust.Open;
  TotalRecCount := tblExCust.RecordCount;
  State := '';
  for i := 1 to cNumRangeDeletes do begin
    State := Char(Random(26) + 65) + Char(Random(26) + 65);
    tblExCust.SetRange([State], [State]);
    RecCount := tblExCust.RecordCount;
    tblExCust.DeleteRecords;
    CheckEquals(0, tblExCust.RecordCount,
                Format('Invalid record count for %s', [State]));
    tblExCust.CancelRange;
    dec(TotalRecCount, RecCount);
  end;  { for }

  CheckEquals(tblExCust.RecordCount, TotalRecCount, 'Invalid end total for ExCust');

  { Delete all remaining records. }
  tblExCust.CancelRange;
  tblExCust.DeleteRecords;
  CheckEquals(0, tblExCust.RecordCount, 'Invalid record count when deleting all records.');

  { Delete empty table. }
  tblExCust.DeleteRecords;
  CheckEquals(0, tblExCust.RecordCount, 'Invalid record count when deleting empty table.');

  { Test filtered delete. Randomly set a filter for productID in ExLines table
    and delete the records. }
  tblExLines.Open;
  TotalRecCount := tblExLines.RecordCount;
  for i := 1 to cNumFilterDeletes do begin
    ProductID := Random(25) + 1;
    tblExLines.Filtered := False;
    tblExLines.Filter := Format('ProductID = %d', [ProductID]);
    tblExLines.Filtered := True;
    RecCount := tblExLines.RecordCount;
    tblExLines.DeleteRecords;
    CheckEquals(0, tblExLines.RecordCount,
                Format('Invalid ExLines record count for product %d',
                       [ProductID]));
    dec(TotalRecCount, RecCount);
  end;  { for }
  tblExLines.Filtered := False;
  CheckEquals(tblExLines.RecordCount, TotalRecCount,
              'Invalid end total for ExLines');

  { Test filter & range combo. }
  tblExOrders.Open;
  tblExOrders.IndexName := 'ByOrder';
  TotalRecCount := tblExOrders.RecordCount;
  for i := 1 to cNumComboDeletes do begin
    tblExOrders.Filtered := False;
    tblExOrders.CancelRange;
    StartOrder := Random(400) + 1;
    EndOrder := StartOrder + Random(200);
    CustID := Random(200) + 1;
    tblExOrders.SetRange([StartOrder],[EndOrder]);
    tblExOrders.Filter := Format('CustomerID = %d', [CustID]);
    tblExOrders.Filtered := True;
    RecCount := tblExOrders.RecordCount;
    tblExOrders.DeleteRecords;
    CheckEquals(0, tblExOrders.RecordCount,
                Format('Invalid ExOrders record count for customer %d, ' +
                       'startOrd %d, endOrd %d',
                       [CustID, StartOrder, EndOrder]));
    dec(TotalRecCount, RecCount);
  end;  { for }
  tblExOrders.Filtered := False;
  tblExOrders.CancelRange;
  CheckEquals(tblExOrders.RecordCount, TotalRecCount,
              'Invalid end total for ExOrders');

end;
{--------}
procedure TffDatasetTests.testEditKey;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testEditRangeEnd;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testFFVersion;
var
  Dict : TffDataDictionary;
  Table : TffTable;
  ExpectedVersion : string;
begin

  ExpectedVersion := Format('%5.4f', [FFVersionNumber / 10000.0]);
  Table := nil;
  try
    { Create a table. }
    Dict := CreateContactDict;
    try
      FDatabase.CreateTable(True, csContacts, Dict);
    finally
      Dict.Free;
    end;

    { Verify we can retrieve the version # from the closed table. }
    FSession.CloseInactiveTables;
      { Just in case. }
    Table := TffTable.Create(nil);
    Table.SessionName := Session.SessionName;
    Table.DatabaseName := Database.DatabaseName;
    Table.TableName := csContacts;

    CheckEquals(ExpectedVersion, Table.FFVersion, 'Closed table: Wrong version');

    { Open the table & verify we can retrieve the version #. }
    Table.Open;
    CheckEquals(ExpectedVersion, Table.FFVersion, 'Open table: Wrong version');
  finally
    Table.DeleteTable;
    Table.Free;
  end;
end;
{--------}
procedure TffDatasetTests.testEditRangeStart;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testFindKey;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testFindNearest;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testGetIndexNames;
begin
  {Make sure this matches up with all example tables}
  { TODO }
end;
{--------}
procedure TffDatasetTests.testGotoKey;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testGotoNearest;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testLocate;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testLookup;
var
  aCurrencyValue : currency;
  Results : Variant;
begin

  tblExProds.Open;
  try
    Results := tblExProds.Lookup('ProductID', 6, 'Description;Price');
  except
    Assert(False);
  end;
  if VarType(Results) <> varBoolean then begin
    Assert(Results[0] = 'Television');
    aCurrencyValue := Currency(Results[1]);
    Assert(aCurrencyValue = 649.99);
  end else
    Assert(False);
end;
{--------}
procedure TffDatasetTests.testPost;
var
  RecCount : Integer;
begin

  tblExProds.Open;
  RecCount := tblExProds.RecordCount;
  tblExProds.Insert;
  tblExProds.FieldByName('Description').AsString := 'TestDesc';
  tblExProds.FieldByName('Price').Value := 999.99;
  tblExProds.Post;
  Assert(tblExProds.RecordCount = Succ(RecCount));
end;
{--------}
procedure TffDatasetTests.testReIndexTable;
var
  Done : boolean;
  TaskID : Integer;
  TaskStatus : TffRebuildStatus;
begin
  if tblExCust.ReIndexTable(1, TaskID) <> 0 then
    Assert(False);
  { Give the reindex some time to finish. }
  Done := False;
  while not Done do begin
    Session.GetTaskStatus(TaskID, Done, TaskStatus);
    Application.ProcessMessages;
  end;
end;
{--------}
procedure TffDatasetTests.testSetKey;
begin

  tblExLines.Open;
  tblExLines.SetKey;
  Assert(tblExLines.State = dsSetKey);
end;
{--------}
procedure TffDatasetTests.testSetRange;
begin

  tblExCust.Open;
  tblExCust.IndexName := 'byID';
  tblExCust.SetRange([3], [5]);
  Assert(tblExCust.RecordCount = 3);
end;
{--------}
procedure TffDatasetTests.testSetRangeEnd;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testSetRangeStart;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testActiveBuffer;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testAppend;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testAppendRecord;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testCheckBrowseMode;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testClearFields;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testClose;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testControlsDisabled;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testCursorPosChanged;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testDelete;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testDisableControls;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testEdit;
var
  CustID : Longint;
begin

  { Verify that editing a record in a range such that the record falls out of
    the range will
  { Verify that when a record is edited such that it changes position in the
    index then the cursor is still positioned on that record. }
  with tblExCust do begin
    Open;
    IndexName := 'ByState';
    { Move to the third record. }
    MoveBy(1);
    MoveBy(1);
    MoveBy(1);
  end;

  try
    { Save landmark info for the current record. }
    { Change the state field of the current record. }
    CustID := tblExCust.FieldByName('CustomerID').asInteger;
    tblExCust.Edit;
    tblExCust.FieldByName('State').AsString := 'ZZZ' +
       tblExCust.FieldByName('State').AsString;
    tblExCust.Post;
    CheckEquals(CustID, tblExCust.FieldByNAme('CustomerID').asInteger);
  finally
    tblExCust.Close;
  end;

  tblExCust.Open;
  tblExCust.Database.StartTransaction;
  try
    tblExCust.Edit;
    tblExCust.FieldByName('LastName').AsString := 'test1';
    tblExCust.Post;

    tblExCust.Edit;
    tblExCust.FieldByName('LastName').AsString := 'test2';
    tblExCust.Post;
  finally
    tblExCust.Database.Commit;
  end;
  tblExCust.Refresh;
  try
    CheckEquals('test2', tblExCust.FieldByName('LastName').AsString,
                'Unexpected value');
  finally
    tblExCust.Close;
  end;
end;
{--------}
procedure TffDatasetTests.testEnableControls;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testFieldByName;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testFindField;
begin
  { make sure results match fieldbyname, and fields }
  { validate result returned when field does not exist }
  { TODO }
end;
{--------}
procedure TffDatasetTests.testFindFirst;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testFindLast;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testFindNext;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testFindPrior;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testFirst;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testFreeBookmark;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testGetBookmark;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testGetDetailDataSets;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testGetDetailLinkFields;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testGetBlobFieldData;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testGetFieldData2;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testGetFieldData3;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testGetFieldList;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testGetFieldNames;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testGotoBookmark;
var
  BM1, BM2 : TBookmark;
begin
  tblExCust.Open;
  BM1 := tblExCust.GetBookmark;
  tblExCust.Next;
  tblExCust.Next;
  tblExCust.Next;
  tblExCust.GotoBookmark(BM1);
  BM2 := tblExCust.GetBookmark;
  Assert(tblExCust.CompareBookmarks(BM1, BM2) = 0);
  tblExCust.FreeBookmark(BM1);
  tblExCust.FreeBookmark(BM2);

end;
{--------}
procedure TffDatasetTests.testInsert;
begin
  tblExCust.Open;
  tblExCust.Insert;
  Assert(tblExCust.State = dsInsert);

end;
{--------}
procedure TffDatasetTests.testInsertRecord;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testIsEmpty;
begin
  tblExCust.Open;
  Assert(tblExCust.IsEmpty = False);
  while not tblExCust.EOF do
    tblExCust.Delete;
  Assert(tblExCust.IsEmpty);
end;
{--------}
procedure TffDatasetTests.testIsLinkedTo;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testLast;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testMoveBy;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testNext;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testOpen;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testPrior;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testRecordCountAsync;
const
  cNumReps = 100;
var
  Done : Boolean;
  i,
  CustID,
  ProductID,
  RecCount,
  StartOrder,
  EndOrder,
  TaskID : Longint;
  TaskStatus : TffRebuildStatus;
  State : string;
begin

  { Test record count, client disconnects before finished }
  ProductID := Random(25) + 1;
  tblExLines.Filtered := False;
  tblExLines.Filter := Format('ProductID = %d', [ProductID]);
  tblExLines.Filtered := True;
  tblExLines.Open;
  tblExLines.RecordCountAsync(TaskID);
  Session.Close;
  { TODO:: What should we verify? }

  { Re-establish connection. }
  tblExCust.Open;
  tblExCust.Close;

  { Test record count, no filter or range, zero records }
  tblExCust.EmptyTable;
  tblExCust.Open;
  tblExCust.RecordCountAsync(TaskID);
  { Wait until the count is done. }
  Done := False;
  while not Done do begin
    Session.GetTaskStatus(TaskID, Done, TaskStatus);
    Application.ProcessMessages;
  end;

  CheckEquals(0, TaskStatus.rsRecsWritten, 'Test 1');

  { Test record count, no filter or range }
  tblExCust.Close;
  CreateExCustTable;
  tblExCust.Open;
  tblExCust.RecordCountAsync(TaskID);
  { Wait until the count is done. }
  Done := False;
  while not Done do begin
    Session.GetTaskStatus(TaskID, Done, TaskStatus);
    Application.ProcessMessages;
  end;

  CheckEquals(tblExCust.RecordCount, TaskStatus.rsRecsWritten, 'Test 2');
  tblExCust.Close;

  { Test record count, filter applied }
  tblExLines.Open;
  for i := 1 to cNumReps do begin
    Application.ProcessMessages;
    ProductID := Random(25) + 1;
    tblExLines.Filtered := False;
    tblExLines.Filter := Format('ProductID = %d', [ProductID]);
    tblExLines.Filtered := True;
    RecCount := tblExLines.RecordCount;
    tblExLines.RecordCountAsync(TaskID);
    { Wait until the count is done. }
    Done := False;
    while not Done do begin
      Session.GetTaskStatus(TaskID, Done, TaskStatus);
      Application.ProcessMessages;
    end;
    CheckEquals(RecCount, TaskStatus.rsRecsWritten,
                Format('Test 3, Invalid ExLines record count for product %d',
                       [ProductID]));
  end;  { for }

  { Test record count, filter applied, no matching records }
  for i := 1 to cNumReps do begin
    ProductID := Random(25) + 10000;
    tblExLines.Filtered := False;
    tblExLines.Filter := Format('ProductID = %d', [ProductID]);
    tblExLines.Filtered := True;
    RecCount := tblExLines.RecordCount;
    tblExLines.RecordCountAsync(TaskID);
    { Wait until the count is done. }
    Done := False;
    while not Done do begin
      Session.GetTaskStatus(TaskID, Done, TaskStatus);
      Application.ProcessMessages;
    end;
    CheckEquals(RecCount, TaskStatus.rsRecsWritten,
                Format('Test 4, Invalid ExLines record count for product %d',
                       [ProductID]));
  end;  { for }
  tblExLines.Close;

  { Test record count, range applied }
  tblExCust.IndexName := csByState;
  tblExCust.Open;
  State := '';
  for i := 1 to cNumReps do begin
    State := Char(Random(26) + 65) + Char(Random(26) + 65);
    tblExCust.SetRange([State], [State]);
    RecCount := tblExCust.RecordCount;
    tblExCust.RecordCountAsync(TaskID);
    { Wait until the count is done. }
    Done := False;
    while not Done do begin
      Session.GetTaskStatus(TaskID, Done, TaskStatus);
      Application.ProcessMessages;
    end;  { while }
    CheckEquals(RecCount, TaskStatus.rsRecsWritten,
                Format('Test 5, Invalid ExCust record count for state %s',
                       [State]));
    tblExCust.CancelRange;
  end;  { for }
  tblExCust.Close;

  { Test record count, range applied, no matching records }
  tblExCust.IndexName := csByState;
  tblExCust.Open;
  State := '';
  for i := 1 to cNumReps do begin
    State := Char(Random(26) + 100) + Char(Random(26) + 100);
    tblExCust.SetRange([State], [State]);
    RecCount := tblExCust.RecordCount;
    tblExCust.RecordCountAsync(TaskID);
    { Wait until the count is done. }
    Done := False;
    while not Done do begin
      Session.GetTaskStatus(TaskID, Done, TaskStatus);
      Application.ProcessMessages;
    end;  { while }
    CheckEquals(RecCount, TaskStatus.rsRecsWritten,
                Format('Test 6, Invalid ExCust record count for state %s',
                       [State]));
    tblExCust.CancelRange;
  end;  { for }
  tblExCust.Close;

  { Test record count, filter & range applied }
  tblExOrders.Open;
  tblExOrders.IndexName := 'ByOrder';
  for i := 1 to cNumReps do begin
    tblExOrders.Filtered := False;
    tblExOrders.CancelRange;
    StartOrder := Random(400) + 1;
    EndOrder := StartOrder + Random(200);
    CustID := Random(200) + 1;
    tblExOrders.SetRange([StartOrder],[EndOrder]);
    tblExOrders.Filter := Format('CustomerID = %d', [CustID]);
    tblExOrders.Filtered := True;
    RecCount := tblExOrders.RecordCount;
    tblExOrders.RecordCountAsync(TaskID);
    { Wait until the count is done. }
    Done := False;
    while not Done do begin
      Session.GetTaskStatus(TaskID, Done, TaskStatus);
      Application.ProcessMessages;
    end;  { while }
    CheckEquals(RecCount, tblExOrders.RecordCount,
                Format('Test 7, Invalid ExOrders record count for customer %d, ' +
                       'startOrd %d, endOrd %d',
                       [CustID, StartOrder, EndOrder]));
  end;  { for }
  tblExOrders.Filtered := False;
  tblExOrders.CancelRange;
  tblExOrders.Close;

  { Test record count, filter & range applied, no matching records }
  tblExOrders.Open;
  tblExOrders.IndexName := 'ByOrder';
  for i := 1 to cNumReps do begin
    tblExOrders.Filtered := False;
    tblExOrders.CancelRange;
    StartOrder := Random(400) + 1000;
    EndOrder := StartOrder + Random(200);
    CustID := Random(200) + 1;
    tblExOrders.SetRange([StartOrder],[EndOrder]);
    tblExOrders.Filter := Format('CustomerID = %d', [CustID]);
    tblExOrders.Filtered := True;
    RecCount := tblExOrders.RecordCount;
    tblExOrders.RecordCountAsync(TaskID);
    { Wait until the count is done. }
    Done := False;
    while not Done do begin
      Session.GetTaskStatus(TaskID, Done, TaskStatus);
      Application.ProcessMessages;
    end;  { while }
    CheckEquals(RecCount, tblExOrders.RecordCount,
                Format('Test 8, Invalid ExOrders record count for customer %d, ' +
                       'startOrd %d, endOrd %d',
                       [CustID, StartOrder, EndOrder]));
  end;  { for }
  tblExOrders.Filtered := False;
  tblExOrders.CancelRange;
  tblExOrders.Close;
end;
{--------}
procedure TffDatasetTests.testRefresh;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testResync;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testSetFields;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testTranslate;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testUpdateCursorPos;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testUpdateRecord;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testUpdateStatus;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testAggFieldsProp;
begin
  tblExCust.Open;
  Assert(tblExCust.AggFields.Count = 0);
end;
{--------}
procedure TffDatasetTests.testBofProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testBookmarkProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testCanModifyProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testDataSetFieldProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testDataSourceProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testDefaultFieldsProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testDesignerProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testEofProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testBlockReadSizeProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testFieldCountProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testFieldDefsProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testFieldDefListProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testFieldsProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testFieldListProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testFieldValuesProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testFoundProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testModifiedProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testObjectViewProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testRecordCountProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testRecNoProp;
begin
  Assert(tblExCust.RecNo = -1);
end;
{--------}
procedure TffDatasetTests.testRecordSizeProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testSparseArraysProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testStateProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testFilterProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testFilteredProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testFilterOptionsProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testActiveProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testAutoCalcFieldsProp;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testBeforeOpenEvent;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testAfterOpenEvent;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testBeforeCloseEvent;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testAfterCloseEvent;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testBeforeInsertEvent;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testAfterInsertEvent;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testBeforeEditEvent;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testAfterEditEvent;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testBeforePostEvent;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testAfterPostEvent;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testBeforeCancelEvent;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testAfterCancelEvent;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testBeforeDeleteEvent;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testAfterDeleteEvent;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testBeforeScrollEvent;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testAfterScrollEvent;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testBeforeRefreshEvent;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testAfterRefreshEvent;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testOnCalcFieldsEvent;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testOnDeleteErrorEvent;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testOnEditErrorEvent;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testOnFilterRecordEvent;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testOnNewRecordEvent;
begin
  { TODO }
end;
{--------}
procedure TffDatasetTests.testOnPostErrorEvent;
begin
  { TODO }
end;
{--------}
procedure TffDataSetTests.testNestedTranPartialRollback;
var
  NameMod1 : string;
  Table : TffTable;
begin
  Table := TffTable.Create(nil);
  try
    Table.SessionName := Session.SessionName;
    Table.DatabaseName := Database.DatabaseName;
    Table.TableName := csCust;
    Table.Timeout := 50000;

    CreateExCustTable;

    Table.Open;
    FDatabase.StartTransaction;
    { First, verify that we can make a change, change our change, and
      then rollback to the first change. }
    try
      { Modify the first record. }
      with Table do begin
        NameMod1 := FieldByName('FirstName').asString + 'Mod1';
        Edit;
        FieldByName('FirstName').asString := NameMod1;
        Post;
        CheckEquals(NameMod1, FieldByName('FirstName').asString,
                    'NameMod1');

        try
          FDatabase.StartTransaction;
          {nested transactions are not allowed}
          Assert(False);
        except
        end;
//        try
//          NameMod2 := FieldByName('FirstName').asString + 'Mod2';
//          Edit;
//          FieldByName('FirstName').asString := NameMod2;
//          Post;
//          CheckEquals(NameMod2, FieldByName('FirstName').asString,
//                      'NameMod2');
//        finally
//          { Now rollback the nested transaction. }
//          FDatabase.Rollback;
//          Table.Refresh;
//        end;

//        { Verify that our first change is still in place. }
//        CheckEquals(NameMod1, FieldByName('FirstName').asString,
//                    'Rollback1');

//        { Commit the transaction. }
//        FDatabase.Commit;

//        { Verify that our first change is still in place. }
//        CheckEquals(NameMod1, FieldByName('FirstName').asString,
//                    'Rollback1');
      end;
    except
      FDatabase.Rollback;
      raise;
    end;
  finally
    if FDatabase.InTransaction then
      FDatabase.Rollback;
    Table.Free;
  end;

end;
{--------}
procedure TffDataSetTests.testCursorCloseDuringTran;
var
  NameMod1 : string;
  Table : TffTable;
begin
  Table := TffTable.Create(nil);
  try
    Table.SessionName := Session.SessionName;
    Table.DatabaseName := Database.DatabaseName;
    Table.TableName := csCust;
    Table.Timeout := 50000;

    CreateExCustTable;

    FDatabase.StartTransaction;
    try
      with Table do begin
        { Open the cursor after the transaction has started, just to see what
          happens. }
        Open;

        { Modify the first record. }
        NameMod1 := FieldByName('FirstName').asString + 'Mod1';
        Edit;
        FieldByName('FirstName').asString := NameMod1;
        Post;
        CheckEquals(NameMod1, FieldByName('FirstName').asString,
                    'NameMod1');

        { Close the table. }
        Close;

        { Commit the transaction. }
        FDatabase.Commit;

        { Verify that our change is still in place. }
        Open;
        CheckEquals(NameMod1, FieldByName('FirstName').asString,
                    'Post Commit 1');
        Close;
      end;
    except
      FDatabase.Rollback;
      raise;
    end;

    FDatabase.StartTransaction;
    try
      with Table do begin
        { Open the cursor after the transaction has started, just to see what
          happens. }
        Open;

        { Modify the first record. }
        NameMod1 := FieldByName('FirstName').asString + 'Mod1';
        Edit;
        FieldByName('FirstName').asString := NameMod1;
        Post;
        CheckEquals(NameMod1, FieldByName('FirstName').asString,
                    'NameMod1');

        { Close the table. }
        Close;

        { Rollback the transaction. }
        FDatabase.Rollback;

        { Verify that our change is rolled back. }
        Open;
        CheckNotEquals(NameMod1, FieldByName('FirstName').asString,
                      'Post Commit 2');
        Close;
      end;
    except
      FDatabase.Rollback;
      raise;
    end;
  finally
    Table.Free;
  end;

end;
{--------}
procedure TffDataSetTests.testConnection;
                          { Issue 449, test 1 }
var
  aForm : TfrmConnectTest;
  aServer : TfrmTestServer;
begin
  { This test can only be run with a server engine spawned from this process.
    That is because we need to access its message count. If tests are being
    run with a remote server engine then we may get responses from that server
    engine instead of the spawned server engine, so exit. }
  if RemoteEngine then
    Exit;

  FEngine.Shutdown;
  aServer := TfrmTestServer.Create(nil);
  try
    aServer.Show;
    Application.ProcessMessages;
    aForm := TfrmConnectTest.Create(nil);
    with aForm do
      try
        Show;
        CheckEquals(0, aServer.ServerSUP.MsgCount);
        Connect;
        Application.ProcessMessages;
        Sleep(1000);
        Assert(aForm.TestTable.Active, 'Table not connected');
      finally
        Disconnect;
        Free;
      end;
   finally
     aServer.Free;
   end;
end;
{--------}
procedure TffDataSetTests.testConnection2;
                          { Issue 449, test 2 }
var
  aForm : TfrmConnectTest2;
  aServer : TfrmTestServer;
begin
  { This test can only be run with a server engine spawned from this process.
    That is because we need to access its message count. If tests are being
    run with a remote server engine then we may get responses from that server
    engine instead of the spawned server engine, so exit. }
  if RemoteEngine then
    Exit;

  FEngine.Shutdown;
  aServer := TfrmTestServer.Create(nil);
  try
    aServer.Show;
    Application.ProcessMessages;
    aForm := TfrmConnectTest2.Create(nil);
    with aForm do
      try
        Show;
        CheckEquals(0, aServer.ServerSUP.MsgCount);
        Connect;
        Application.ProcessMessages;
        Sleep(1000);
        Assert(aForm.TestTable.Active, 'Table not connected');
      finally
        Disconnect;
        Free;
      end;
   finally
     aServer.Free;
   end;
end;
{====================================================================}

procedure TffBugTests.FFD968;
var
  CE : TffCommsEngine;
  SS : TffSession;
  L  : TStringList;
begin
  { This test can only be run with remote server engine. }
  if not RemoteEngine then
    Exit;
  L := TStringList.Create;
  try
    CE := TffCommsEngine.Create(nil);
    CE.Protocol := FProtocol;
    CE.ServerName := FServerName;
    try
      CE.CommsEngineName := 'CE';
      SS := TffSession.Create(nil);
      try
        SS.CommsEngineName := 'CE';
        SS.SessionName := 'CE';
        {If 968 was to return, then the following line would cause the
         error message "Invalid handle to function"}
        SS.GetDatabaseNames(l);
      finally
        SS.Free;
      end;
    finally
      CE.Free;
    end;
  finally
    L.Free;
  end;
end;

procedure TffClientTests.Client_OpenNoTreansport;
var
  RSE  : TffRemoteServerEngine;
  CL   : TffClient;
  SESS : TffSession;
begin
  RSE := TffRemoteServerEngine.Create(nil);
  CL := TffClient.Create(nil);
  CL.AutoClientName := True;
  CL.ServerEngine := RSE;
  SESS := TffSession.Create(nil);
  SESS.AutoSessionName := True;
  SESS.ClientName := CL.ClientName;
  try
    try
      SESS.OPEN;
    except
      on E:Exception do begin
        Assert(E is EffDatabaseError, 'Invalid exception type');
        Assert($D53B = EffDatabaseError(E).ErrorCode,
                     'Invalid error code');
      end;
    end;
  finally
    SESS.Free;
    CL.Free;
    RSE.Free;
  end;
end;

procedure TffClientTests.CommsEngine_OpenNoTransport;
var
  RSE  : TffRemoteServerEngine;
  CL   : TffCommsEngine;
  SESS : TffSession;
begin
  RSE := TffRemoteServerEngine.Create(nil);
  CL := TffCommsEngine.Create(nil);
  CL.AutoClientName := True;
  CL.ServerEngine := RSE;
  SESS := TffSession.Create(nil);
  SESS.AutoSessionName := True;
  SESS.ClientName := CL.ClientName;
  try
    try
      SESS.OPEN;
    except
      on E:Exception do begin
        Assert(E is EffDatabaseError, 'Invalid exception type');
        Assert($D53B = EffDatabaseError(E).ErrorCode,
                     'Invalid error code');
      end;
    end;
  finally
    SESS.Free;
    CL.Free;
    RSE.Free;
  end;
end;

initialization
  RegisterTest('Data Dictionary tests', TffDataDictTests.Suite);
  RegisterTest('Bug tests', TffBugTests.Suite);
  RegisterTest('Client class tests', TffClientTests.Suite);
  RegisterTest('Session tests', TffSessionTests.Suite);
  RegisterTest('Database tests', TffDatabaseTests.Suite);
  RegisterTest('Query tests', TffQueryTests.Suite);
  RegisterTest('Remote Server Engine tests', TffRemoteServerEngineTests.Suite);
  RegisterTest('TffDataset & Company', TffDatasetTests.Suite);
end.
