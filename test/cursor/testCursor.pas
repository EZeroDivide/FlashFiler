unit testCursor;

interface

uses
  BaseTestCase,
  Forms,
  FFDB,
  FFLLBase,
  FFLLDict,
  FFLLEng,
  FFLLLgcy,
  FFLLLog,
  FFSrBase,
  FFSrEng,
  FFSrFold,
  TestFramework;

type
  TffTestSQLResultSet = class(TTestCase)
  protected
    FBufMgr : TffBufferManager;
    FClient : TffSrClient;
    FEngine : TffServerEngine;
    FDB : TffSrDatabase;
    FSession : TffSrSession;
    FFolder : TffSrFolder;

    procedure Setup; override;
    procedure Teardown; override;

    procedure CopyRecCallback(Sender : TffSrBaseCursor;
                              aSrcRecord : PffByteArray;
                              aCookie1, aCookie2 : Longint;
                          var include : boolean);

    procedure CopyRecPartsCallback(Sender : TffSrBaseCursor;
                                   aSrcRecord : PffByteArray;
                                   aCookie1, aCookie2 : Longint;
                               var include : boolean);
  public
  published
    procedure testCreateTempSQLResultSet;
      { Verify that we can create a temporary simple cursor. }

    procedure testTempInsertRecords;
      { Verify that we can insert records into the contact table, obtain
        a valid record count, step forward through the records, & step
        backward through the records. }

    procedure testTempEmpty;
      { Verify that the files can be emptied and re-used. }

    procedure testTempCloneCursor;
      { Verify that we can clone the cursor of a temporary table. }

    procedure testTempBookmark;
      { Verify that we can set and position to bookmarks within the temporary
        table. }

    procedure testTempCompareBookmarks;
      { Verify that bookmark comparison works. }

    procedure testTempModifyRecord;
      { Verify that record modification works. }

    procedure testTempSetToCursor;
      { Verify that we can position a cursor to another cursor's current
        record. }

    procedure testTempDeleteRecord;
      { Verify that records are deleted properly. }

    procedure testTempCopyRecords;
      { Verify that we can copy records from one cursor to another. }

    procedure testTempCopyRecordParts;
      { Verify that we can copy specific fields of records from one cursor to
        another. }

    procedure testTempCopyNoBLOBs;
      { Verify that copied records can have the destination BLOB fields set
        to null. }

    procedure testTempCopyBLOBs;
      { Verify that BLOBs can be copied from a source cursor to a destination
        cursor. }

    procedure testTempCreateBLOBLinks;
      { Verify that BLOB links can be created in a destination cursor. }

  end;

  TffTestCursors = class(TffBaseTest)
  protected
    FClient : TffClient;
    FDB : TffDatabase;
    FSession : TffSession;
    FTable : TffTable;
    FTable2 : TffTable;

    procedure PrepareContactTable;
    procedure Setup; override;
    procedure Teardown; override;
  public
  published

    {==========  Cursor tests  ==========================}
    procedure test2CursorEditAfterDelete;
      { See what happens when a cursor tries to edit a record that another
        cursor has just deleted. }

    procedure testBookmarkOnCrack;
      { Verify that we can obtain a bookmark on a crack and reposition to
        that crack. }

    procedure testInsertIntoRange;
      { Issue 3712 - Verify that if a range is active & a record not matching
        the range is inserted then the record does not show up in the range
        & the cursor position is unaffected. }

    procedure testOnCrackAfterDeleteUInx;
      { Given a unique index, verifies that a cursor is positioned on the
        crack between the two records surrounding a record just deleted by
        the cursor. }

    procedure testOnCrackAfterDeleteNUInx;
      { Given a non-unique index, verifies that a cursor is positioned on the
        crack between the two records surrounding a record just deleted by
        the cursor. }

    procedure testLocateDelWithIndex;
      { Verify that we can delete records in a loop using TffTable.Locate.
        This case causes TffTable to use a lookup cursor and the lookup cursor
        switches to an existing index. }

    procedure testLocateDelNoIndex;
      { Verify that we can delete records in a loop using TffTable.Locate.
        This case causes TffTable to use a lookup cursor but there is no
        compatible index for the lookup, so the lookup cursor must use a
        filter. }

    procedure testDeleteAllRecsInRange;
      { Verify that we can delete all records in an active range within
        an explicit transaction. See bug 720 for more info. }

    procedure testModifyRecordsInRange;
      { Verify that when modifying records in a range, the range is
        updated correctly. See bug 826 for more info. }

    procedure testMultiTableInstancesOnOneTable;
      { Verify that multiple instances of TffTable component associated with
        a single TffClient can modify/scan the same physical table using
        implicit transactions. }

    procedure testMultiTableInstancesInOneTransaction;
      { Verify that two different tables can modify the same record within
        the context of one transaction. }
  end;


function CreateContactDict : TffDataDictionary;
function CreateContactDictWithNotes : TffDataDictionary;
function CreatePartialContactDict : TffDataDictionary;
procedure InsertRandomContactsWithNotes(aCursor : TffSrBaseCursor;
                                        aCount : longInt;
                                        Notes1Char, Notes2Char : char);

implementation

uses
  Classes,
  Dialogs,
  DB,
  DBCommon,
  SysUtils,
  Windows,
  ContactU,
  FFCLReng,
  FFConst,
  FFDBBase,
  FFFile,
  FFLLComm,
  FFLLExcp,
  FFSrBDE,
  FFSrCur,
  FFSrLock,
  FFTbBase,
  StUtils;

const
  csAliasDir = '..\cursor';  //directory used for cursor tests
  csSourceDir = '..\data';        //FF2's test data
  csByAge = 'byAge';
  csContacts = 'Contacts';
  csContactsRen = 'ContactsRen';
  csEmail = 'Email';
  csPrimary = 'Primary';

  { Timeout constants }
  clClientTimeout = 500000;
  clSessionTimeout = 500000;
  clDBTimeout = 500000;
  clTableTimeout = 500000;

  { Field constants }
  cnIDFld = 0;
  cnFirstNameFld = 1;
  cnLastNameFld = 2;
  cnAgeFld = 3;
  cnStateFld = 4;
  cnDMakerFld = 5;


{===Utility routines=================================================}
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
    AddField('BirthDate', '', fftDateTime, 0, 0, false, nil);

    { Add indexes }
    FldArray[0] := 0;
    IHFldList[0] := '';
    AddIndex('primary', '', 0, 1, FldArray, IHFldList, False, True, True);

    FldArray[0] := 3;
    IHFldList[0] := '';
    AddIndex(csByAge, '', 0, 1, FldArray, IHFldList, True, True, True);

  end;

end;
{--------}
function CreateContactDictWithNotes : TffDataDictionary;
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
    AddField('SalesNotes', '', fftBLOBMemo, 0, 0, false, nil);
    AddField('Age', '', fftInt16, 5, 0, false, nil);
    AddField('State', '', fftShortString, 2, 0, false, nil);
    AddField('DecisionMaker', '', fftBoolean, 0, 0, false, nil);
    AddField('CustSrvNotes', '', fftBLOBMemo, 0, 0, false, nil);

    { Add indexes }
    FldArray[0] := 0;
    IHFldList[0] := '';
    AddIndex('primary', '', 0, 1, FldArray, IHFldList, False, True, True);

    FldArray[0] := 4;
    IHFldList[0] := '';
    AddIndex(csByAge, '', 0, 1, FldArray, IHFldList, True, True, True);

  end;

end;
{--------}
function CreatePartialContactDict : TffDataDictionary;
var
  FldArray : TffFieldList;
  IHFldList : TffFieldIHList;
begin

  Result := TffDataDictionary.Create(65536);
  with Result do begin

    { Add fields }
    AddField('ID', '', fftAutoInc, 0, 0, false, nil);
    AddField('Age', '', fftInt16, 5, 0, false, nil);
    AddField('State', '', fftShortString, 2, 0, false, nil);

    { Add indexes }
    FldArray[0] := 0;
    IHFldList[0] := '';
    AddIndex('primary', '', 0, 1, FldArray, IHFldList, False, True, True);

    FldArray[0] := 1;
    IHFldList[0] := '';
    AddIndex(csByAge, '', 0, 1, FldArray, IHFldList, True, True, True);
  end;
end;
{--------}
procedure InsertRandomContactsWithNotes(aCursor : TffSrBaseCursor;
                                        aCount : longInt;
                                        Notes1Char, Notes2Char : char);
var
  aBLOBNr : TffInt64;
  aRecord : PffByteArray;
  Dict : TffDataDictionary;
  Index : longInt;
  fldFirstName : string[25];
  fldLastName : string[25];
  fldAge : integer;
  fldState : string[2];
  fldDecisionMaker : boolean;
  noteBuffer : PffByteArray;
  noteSize : integer;
begin

  { Assumptions: Using contact table as defined in testCursor.pas and
                 testDBThread.pas }

  { Obtain a buffer to hold the record. }
  Dict := aCursor.Dictionary;
  FFGetMem(aRecord, Dict.RecordLength);

  { Start inserting records. }
  for Index := 1 to aCount do begin
    FillChar(aRecord^, Dict.RecordLength, 0);
      { Make sure buffer is zeroed out so that autoincrement field doesn't
        appear to be filled. }
    fldFirstName := genFirstName;
    fldFirstName := fldFirstName + StringOfChar(' ', 25 - length(fldFirstName));
    fldLastName := genLastName;
    fldLastName := fldLastName + StringOfChar(' ', 25 - length(fldLastName));
    fldAge := genAge;
    fldState := genState;
    fldDecisionMaker := genDecisionMaker;
    Dict.SetRecordField(1, aRecord, @fldFirstName[0]);
    Dict.SetRecordField(2, aRecord, @fldLastName[0]);
    Dict.SetRecordField(4, aRecord, @fldAge);
    Dict.SetRecordField(5, aRecord, @fldState[0]);
    Dict.SetRecordField(6, aRecord, @fldDecisionMaker);
    { Skip birthDate field since I don't want to code the transformation of
      a TDateTime into the right format. }

    { Set up the first set of notes. }
    noteSize := random(ffcl_1MB * 5) + 1;
    FFGetMem(noteBuffer, noteSize);
    FillChar(noteBuffer^, noteSize, ord(Notes1Char));

    aCursor.BLOBAdd(aBLOBNr);
    aCursor.BLOBWrite(aBLOBNr, 0, noteSize, noteBuffer^);
    aCursor.BLOBFree(aBLOBNr);
    Dict.SetRecordField(3, aRecord, @aBLOBNr);
    FFFreeMem(noteBuffer, noteSize);

    { Set up the second set of notes. }
    noteSize := random(ffcl_1MB * 5) + 1;
    FFGetMem(noteBuffer, noteSize);
    FillChar(noteBuffer^, noteSize, ord(Notes2Char));

    aCursor.BLOBAdd(aBLOBNr);
    aCursor.BLOBWrite(aBLOBNr, 0, noteSize, noteBuffer^);
    Dict.SetRecordField(7, aRecord, @aBLOBNr);
    aCursor.BLOBFree(aBLOBNr);
    FFFreeMem(noteBuffer, noteSize);

    aCursor.InsertRecord(aRecord, ffsltExclusive);
  end;

end;
{====================================================================}

{===TffTestSQLResultSet==============================================}
procedure TffTestSQLResultSet.CopyRecCallback(Sender : TffSrBaseCursor;
                                              aSrcRecord : PffByteArray;
                                              aCookie1, aCookie2 : Longint;
                                          var include : boolean);
var
  anAge : smallint;
  isNull : boolean;
begin
  { Include only those records for contacts whose age is 65 or higher. }
  Sender.GetRecordField(cnAgeFld, aSrcRecord, isNull, @anAge);
  include := (not isNull) and (anAge >= 65);
end;
{--------}
procedure TffTestSQLResultSet.CopyRecPartsCallback(Sender : TffSrBaseCursor;
                                                   aSrcRecord : PffByteArray;
                                                   aCookie1, aCookie2 : Longint;
                                               var include : boolean);
var
  anAge : smallint;
  isNull : boolean;
begin
  { Include only those records for contacts whose age is 65 or higher. }
  Sender.GetRecordField(1, aSrcRecord, isNull, @anAge);
  include := (not isNull) and (anAge >= 65);
end;
{--------}
procedure TffTestSQLResultSet.Setup;
var
  aClientID : TffClientID;
  aDBID : TffDatabaseID;
  aHash : TffWord32;
begin
  inherited;
  randomize;
  FileProcsInitialize;
  FEngine := TffServerEngine.Create(nil);
  FBufMgr := TffBufferManager.Create(FEngine.ConfigDir, 20);
  FEngine.Configuration.GeneralInfo^.giAllowEncrypt := False;
  FEngine.BufferManager.MaxRAM := 50;
  FEngine.Startup;
  FEngine.ClientAdd(aClientID, '', '', 1000000, aHash);
  FClient := TffSrClient(aClientID);
  FEngine.DatabaseOpenNoAlias(FClient.ClientID, ExtractFilePath(Application.ExeName),
                              omReadWrite, smShared, 1000000, aDBID);
  FDB := TffSrDatabase(aDBID);
end;
{--------}
procedure TffTestSQLResultSet.Teardown;
begin
  inherited;
  FEngine.DatabaseClose(FDB.DatabaseID);
  FEngine.ClientRemove(FClient.ClientID);
  FBufMgr.Free;
  FEngine.Free;
end;
{--------}
procedure TffTestSQLResultSet.testCreateTempSQLResultSet;
const
  cPersistentName = 'testCreateTempSQLResultSet';
  cTempName = 'testTemp';
var
  aCursor : TffSrSQLResultSet;
  aDict : TffDataDictionary;
  aFileName : TffFullFileName;
begin
  { Define the structure of the table. }
  aDict := CreateContactDict;
  try
    { Create the temporary version first. }
    aCursor := TffSrSQLResultSet.Create(FEngine, FDB, 1000000);
    aCursor.Build(cTempName, aDict, omReadWrite, smExclusive, False,
                  False, [fffaTemporary], 0);
    try
      { Make sure the file doesn't exist. }
      aFileName := FFMakeFullFileName(ExtractFilePath(Application.ExeName),
                                      FFMakeFileNameExt(cTempName, ffc_ExtForData));
      Assert((not FFFileExists(aFileName)), 'Temp table exists on disk.');

    finally
      { Get rid of the cursor. }
      aCursor.Free;
    end;

    { Create the persistent version next. }
    aFileName := FFMakeFullFileName(ExtractFilePath(Application.ExeName),
                                    FFMakeFileNameExt(cPersistentName, ffc_ExtForData));
    aCursor := TffSrSQLResultSet.Create(FEngine, FDB, 100000);
    aCursor.Build(cPersistentName, aDict, omReadWrite, smExclusive, False,
                  True, [],  0);
    try
      { Verify the file exists. }
      Assert(FFFileExists(aFileName), 'Persistent table not created.');
    finally
      { Get rid of the cursor. }
      aCursor.Free;
      FEngine.TableList.RemoveUnusedTables;

      { Get rid of the file. }
      FFTblHlpDelete(ExtractFilePath(aFileName), ExtractFileName(aFileName),
                     aDict);

    end;

  finally
    aDict.Free;
  end;
end;
{--------}
procedure TffTestSQLResultSet.testTempInsertRecords;
const
  cTempName = 'testTemp';
  cNumRecs : array[0..9] of integer = (1, 10, 100, 250, 1000, 5000, 10000,
                                       20000, 50000, 100000);
var
  aContactID : Longint;
  aCursor : TffSrSQLResultSet;
  aDict : TffDataDictionary;
  aFileName : TffFullFileName;
  anIndex : integer;
  anIndex2 : integer;
  aRecCount : Longint;
  aRecord : PffByteArray;
  aStepCount : Longint;
  aResult : TffResult;
  isNull : boolean;
begin
  { Define the structure of the table. }
  aDict := CreateContactDict;

  try
    { Do this several times for differing record counts. }
    for anIndex := low(cNumRecs) to high(cNumRecs) do begin
      { Create the temporary table. }
      aCursor := TffSrSQLResultSet.Create(FEngine, FDB, 1000000);
      aCursor.Build(cTempName, aDict, omReadWrite, smExclusive, False,
                    False, [fffaTemporary],  0);
      try
        aFileName := FFMakeFullFileName(ExtractFilePath(Application.ExeName),
                                        FFMakeFileNameExt(cTempName, ffc_ExtForData));
        { Make sure the file doesn't exist. }
        Assert((not FFFileExists(aFileName)), 'Temp table exists on disk.');

        { Start a transaction. }
        FEngine.TransactionStart(FDB.DatabaseID, false);
        try
          { Obtain a record buffer. }
          FFGetMem(aRecord, aCursor.Dictionary.RecordLength);

          { Insert some contact records. }
          InsertRandomContactsViaCursor(aCursor, cNumRecs[anIndex]);

          { Verify record count. }
          aResult := aCursor.GetRecordCount(aRecCount);
          CheckEquals(DBIERR_NONE, aResult,
                      format('Unexpected error, rec count 1, err code %d',
                             [aResult]));
          CheckEquals(cNumRecs[anIndex], aRecCount,
                      format('Invalid record count 1: %d', [aRecCount]));

          { Make sure we can step forward through the records. }
          aResult := DBIERR_NONE;
          aStepCount := 0;
          aCursor.SetToBegin;
          while (aResult = DBIERR_NONE) do begin
            aResult := aCursor.GetNextRecord(aRecord, ffsltNone);
            if aResult = DBIERR_NONE then begin
              inc(aStepCount);
              { Verify that the contact ID matches what we expect. }
              aCursor.Dictionary.GetRecordField(0, aRecord, isNull, @aContactID);
              CheckEquals(aStepCount, aContactID, 'Unexpected contact ID');
            end;
          end;

          CheckEquals(DBIERR_EOF, aResult,
                      format('Unexpected error, step forward 1, err code %d',
                             [aResult]));
          CheckEquals(cNumRecs[anIndex], aStepCount,
                      format('Invalid step count 1: %d', [aStepCount]));

          { Make sure we can step backward through the records. }
          aResult := DBIERR_NONE;
          aStepCount := 0;
          while (aResult = DBIERR_NONE) do begin
            aResult := aCursor.GetPriorRecord(aRecord, ffsltNone);
            if aResult = DBIERR_NONE then
              inc(aStepCount);
          end;

          CheckEquals(DBIERR_BOF, aResult,
                      format('Unexpected error, step backward 1, err code %d',
                             [aResult]));
          CheckEquals(cNumRecs[anIndex], aStepCount,
                      format('Invalid step count 2: %d', [aStepCount]));

          { Commit the transaction. }
          FEngine.TransactionCommit(FDB.DatabaseID);

          { Verify record count. }
          aResult := aCursor.GetRecordCount(aRecCount);
          CheckEquals(DBIERR_NONE, aResult,
                      format('Unexpected error, rec count 2, err code %d',
                             [aResult]));
          CheckEquals(cNumRecs[anIndex], aRecCount,
                      format('Invalid record count 2: %d', [aRecCount]));

          { Step part-way through the records. }
          aStepCount := 0;
          for anIndex2 := 0 to (cNumRecs[anIndex] div 3) do begin
            aResult := aCursor.GetNextRecord(aRecord, ffsltNone);
            CheckEquals(DBIERR_NONE, aResult,
                        format('Unexpected error, step forward 3.a, err code %d',
                               [aResult]));
            inc(aStepCount);
          end;

          { Verify record count. Our point in doing this is to prove that the
            record count logic repositions us to the correct record. }
          aResult := aCursor.GetRecordCount(aRecCount);
          CheckEquals(DBIERR_NONE, aResult,
                      format('Unexpected error, rec count 3, err code %d',
                             [aResult]));
          CheckEquals(cNumRecs[anIndex], aRecCount,
                      format('Invalid record count 3: %d', [aRecCount]));

          { Step to the end of the records. }
          aResult := DBIERR_NONE;
          while (aResult = DBIERR_NONE) do begin
            aResult := aCursor.GetNextRecord(aRecord, ffsltNone);
            if aResult = DBIERR_NONE then
              inc(aStepCount);
          end;

          CheckEquals(DBIERR_EOF, aResult,
                      format('Unexpected error, step forward 3.b, err code %d',
                             [aResult]));
          CheckEquals(cNumRecs[anIndex], aStepCount,
                      format('Invalid step count 3.b: %d', [aStepCount]));

        except
          { Rollback the transaction. }
          FEngine.TransactionRollback(FDB.DatabaseID);
          raise;
        end;

      finally
        { Get rid of the cursor. }
        FFFreeMem(aRecord, aCursor.Dictionary.RecordLength);
        aCursor.Free;
        FEngine.TableList.RemoveUnusedTables;
      end; { try..finally }

    end; { for }
    { Make sure the file doesn't exist. }
    Assert((not FFFileExists(aFileName)), 'Post insert: Temp table exists on disk.');
  finally
    aDict.Free;
  end;
end;
{--------}
procedure TffTestSQLResultSet.testTempEmpty;
const
  cTempName = 'testTemp';
  cNumRecs = 100;
var
  aContactID : Longint;
  aCursor : TffSrSQLResultSet;
  aDict : TffDataDictionary;
  aFileName : TffFullFileName;
  aRecCount : Longint;
  aRecord : PffByteArray;
  aStepCount : Longint;
  aResult : TffResult;
  isNull : boolean;
begin
  { Define the structure of the table. }
  aDict := CreateContactDict;
  try
    { Create the temporary table. }
    aCursor := TffSrSQLResultSet.Create(FEngine, FDB, 1000000);
    aCursor.Build(cTempName, aDict, omReadWrite, smExclusive, False,
                  False, [fffaTemporary],  0);
    try
      aFileName := FFMakeFullFileName(ExtractFilePath(Application.ExeName),
                                      FFMakeFileNameExt(cTempName, ffc_ExtForData));
      { Make sure the file doesn't exist. }
      Assert((not FFFileExists(aFileName)), 'Temp table exists on disk.');

      { Start a transaction. }
      FEngine.TransactionStart(FDB.DatabaseID, false);
      try
        { Obtain a record buffer. }
        FFGetMem(aRecord, aCursor.Dictionary.RecordLength);

        { Insert some contact records. }
        InsertRandomContactsViaCursor(aCursor, cNumRecs);

        { Verify record count. }
        aResult := aCursor.GetRecordCount(aRecCount);
        CheckEquals(DBIERR_NONE, aResult,
                    format('Unexpected error, rec count 1, err code %d',
                           [aResult]));
        CheckEquals(cNumRecs, aRecCount,
                    format('Invalid record count 1: %d', [aRecCount]));

        { Make sure we can step forward through the records. }
        aResult := DBIERR_NONE;
        aStepCount := 0;
        aCursor.SetToBegin;
        while (aResult = DBIERR_NONE) do begin
          aResult := aCursor.GetNextRecord(aRecord, ffsltNone);
          if aResult = DBIERR_NONE then begin
            inc(aStepCount);
            { Verify that the contact ID matches what we expect. }
            aCursor.Dictionary.GetRecordField(0, aRecord, isNull, @aContactID);
            CheckEquals(aStepCount, aContactID, 'Unexpected contact ID');
          end;
        end;

        CheckEquals(DBIERR_EOF, aResult,
                    format('Unexpected error, step forward 1, err code %d',
                           [aResult]));
        CheckEquals(cNumRecs, aStepCount,
                    format('Invalid step count 1: %d', [aStepCount]));

        { Commit the transaction. }
        FEngine.TransactionCommit(FDB.DatabaseID);

        { Start a new transaction. }
        FEngine.TransactionStart(FDB.DatabaseID, false);

        { Empty the files. }
        aResult := aCursor.Empty;
        CheckEquals(DBIERR_NONE, aResult,
                    format('Unexpected error, aCursor.Empty, err code %d',
                           [aResult]));

        { Insert a bunch of records. }
        InsertRandomContactsViaCursor(aCursor, cNumRecs);

        { Verify record count. }
        aResult := aCursor.GetRecordCount(aRecCount);
        CheckEquals(DBIERR_NONE, aResult,
                    format('Unexpected error, rec count 2, err code %d',
                           [aResult]));
        CheckEquals(cNumRecs, aRecCount,
                    format('Invalid record count 2: %d', [aRecCount]));

        { Make sure we can step forward through the records. }
        aResult := DBIERR_NONE;
        aStepCount := 0;
        aCursor.SetToBegin;
        while (aResult = DBIERR_NONE) do begin
          aResult := aCursor.GetNextRecord(aRecord, ffsltNone);
          if aResult = DBIERR_NONE then begin
            inc(aStepCount);
            { Verify that the contact ID matches what we expect. }
            aCursor.Dictionary.GetRecordField(0, aRecord, isNull, @aContactID);
            CheckEquals(aStepCount, aContactID,
                        'Unexpected contact ID in 2nd set of contacts');
          end;
        end;

        CheckEquals(DBIERR_EOF, aResult,
                    format('Unexpected error, step forward 2, err code %d',
                           [aResult]));
        CheckEquals(cNumRecs, aStepCount,
                    format('Invalid step count 2: %d', [aStepCount]));

        FEngine.TransactionCommit(FDB.DatabaseID);

      except
        { Rollback the transaction. }
        FEngine.TransactionRollback(FDB.DatabaseID);
        raise;
      end;

    finally
      { Get rid of the cursor. }
      FFFreeMem(aRecord, aCursor.Dictionary.RecordLength);
      aCursor.Free;
    end;

    { Make sure the file doesn't exist. }
    Assert((not FFFileExists(aFileName)), 'Post insert: Temp table exists on disk.');
  finally
    aDict.Free;
  end;
end;
{--------}
procedure TffTestSQLResultSet.testTempCloneCursor;
const
  cTempName = 'testTemp';
  cNumRecs = 100;
var
  aContactID : Longint;
  aCursor : TffSrSQLResultSet;
  aClone : TffSrSQLResultSet;
  aDict : TffDataDictionary;
  aFileName : TffFullFileName;
  aRecCount : Longint;
  aRecord : PffByteArray;
  aStepCount : Longint;
  aResult : TffResult;
  isNull : boolean;
begin
  { Define the structure of the table. }
  aDict := CreateContactDict;
  aClone := nil;
  try
    { Create the temporary table. }
    aCursor := TffSrSQLResultSet.Create(FEngine, FDB, 1000000);
    aCursor.Build(cTempName, aDict, omReadWrite, smShared, False,
                  False, [fffaTemporary], 0);
    { Obtain a record buffer. }
    FFGetMem(aRecord, aCursor.Dictionary.RecordLength);
    try
      aFileName := FFMakeFullFileName(ExtractFilePath(Application.ExeName),
                                      FFMakeFileNameExt(cTempName, ffc_ExtForData));
      { Make sure the file doesn't exist. }
      Assert((not FFFileExists(aFileName)), 'Temp table exists on disk.');

      { Start a transaction. }
      FEngine.TransactionStart(FDB.DatabaseID, false);
      try

        { Insert some contact records. }
        InsertRandomContactsViaCursor(aCursor, cNumRecs);

        { Commit the transaction. }
        FEngine.TransactionCommit(FDB.DatabaseID);

        { Verify record count. }
        aResult := aCursor.GetRecordCount(aRecCount);
        CheckEquals(DBIERR_NONE, aResult,
                    format('Unexpected error, rec count 1, err code %d',
                           [aResult]));
        CheckEquals(cNumRecs, aRecCount,
                    format('Invalid record count 1: %d', [aRecCount]));

        { Make sure we can step forward through the records. }
        aResult := DBIERR_NONE;
        aStepCount := 0;
        aCursor.SetToBegin;
        while (aResult = DBIERR_NONE) do begin
          aResult := aCursor.GetNextRecord(aRecord, ffsltNone);
          if aResult = DBIERR_NONE then begin
            inc(aStepCount);
            { Verify that the contact ID matches what we expect. }
            aCursor.Dictionary.GetRecordField(0, aRecord, isNull, @aContactID);
            CheckEquals(aStepCount, aContactID, 'Unexpected contact ID');
          end;
        end;

        CheckEquals(DBIERR_EOF, aResult,
                    format('Unexpected error, step forward 1, err code %d',
                           [aResult]));
        CheckEquals(cNumRecs, aStepCount,
                    format('Invalid step count 1: %d', [aStepCount]));


        { Clone the cursor. }
        aClone := TffSrSQLResultSet(aCursor.CloneCursor(omReadWrite));

        { The cloned cursor should be at the same position as the original
          cursor. In this case we should be at EOF. Make sure we can step
          backward through the records. }
        aResult := DBIERR_NONE;
        aStepCount := 0;
        while (aResult = DBIERR_NONE) do begin
          aResult := aClone.GetPriorRecord(aRecord, ffsltNone);
          if aResult = DBIERR_NONE then
            inc(aStepCount);
        end;

        CheckEquals(DBIERR_BOF, aResult,
                    format('Unexpected error, step backward 1, err code %d',
                           [aResult]));
        CheckEquals(cNumRecs, aStepCount,
                    format('Invalid step count 2: %d', [aStepCount]));

        { Verify record count. }
        aResult := aClone.GetRecordCount(aRecCount);
        CheckEquals(DBIERR_NONE, aResult,
                    format('Unexpected error, rec count 2, err code %d',
                           [aResult]));
        CheckEquals(cNumRecs, aRecCount,
                    format('Invalid record count 2: %d', [aRecCount]));

        { Verify that we can still use the cloned cursor. }
        aCursor.SetToBegin;

      except
        { Rollback the transaction. }
        FEngine.TransactionRollback(FDB.DatabaseID);
        raise;
      end;

    finally
      { Get rid of the cursors. }
      FFFreeMem(aRecord, aCursor.Dictionary.RecordLength);
      aClone.Free;
      aCursor.Free;
    end;

    { Make sure the file doesn't exist. }
    Assert((not FFFileExists(aFileName)), 'Post insert: Temp table exists on disk.');
  finally
    aDict.Free;
  end;
end;
{--------}
procedure TffTestSQLResultSet.testTempBookmark;
const
  cTempName = 'testTemp';
  cNumRecs = 1000;
var
  aBM : PffSrBookmark;
  aContactID : Longint;
  aContactID2 : Longint;
  aCursor : TffSrSQLResultSet;
  aDict : TffDataDictionary;
  aFileName : TffFullFileName;
  anIndex, anIndex2 : integer;
  aRecCount : Longint;
  aRecord : PffByteArray;
  aStepCount : Longint;
  aResult : TffResult;
  isNull : boolean;
begin
  { Define the structure of the table. }
  aDict := CreateContactDict;
  try
    { Create the temporary table. }
    aCursor := TffSrSQLResultSet.Create(FEngine, FDB, 1000000);
    aCursor.Build(cTempName, aDict,omReadWrite, smShared, False,
                  False, [fffaTemporary],  0);
    try
      aFileName := FFMakeFullFileName(ExtractFilePath(Application.ExeName),
                                      FFMakeFileNameExt(cTempName, ffc_ExtForData));

      { Make sure the file doesn't exist. }
      Assert((not FFFileExists(aFileName)), 'Temp table exists on disk.');

      { Start a transaction. }
      FEngine.TransactionStart(FDB.DatabaseID, false);
      try
        { Insert some contact records. }
        InsertRandomContactsViaCursor(aCursor, cNumRecs);

        { Commit the transaction. }
        FEngine.TransactionCommit(FDB.DatabaseID);

      except
        FEngine.TransactionRollback(FDB.DatabaseID);
        raise;
      end;

      { Verify record count. }
      aResult := aCursor.GetRecordCount(aRecCount);
      CheckEquals(DBIERR_NONE, aResult,
                  format('Unexpected error, rec count 1, err code %d',
                         [aResult]));
      CheckEquals(cNumRecs, aRecCount,
                  format('Invalid record count 1: %d', [aRecCount]));

      { Obtain a record buffer. }
      FFGetMem(aRecord, aCursor.Dictionary.RecordLength);
      try
        for anIndex := 1 to 1000 do begin
          { Position to some random record. }
          aStepCount := Random(cNumRecs);
          aCursor.SetToBegin;
          for anIndex2 := 0 to aStepCount do begin
            aResult := aCursor.GetNextRecord(aRecord, ffsltNone);
            CheckEquals(DBIERR_NONE, aResult,
                        format('Unexpected error while positioning to record %d',
                               [aStepCount]));
          end;

          { Obtain a bookmark. }
          FFGetMem(aBM, ffcl_FixedBookmarkSize);
          try
            { Determine the contactID of the current record, for verification
              purposes. }
            aCursor.GetRecord(aRecord, ffsltNone);
            aCursor.Dictionary.GetRecordField(0, aRecord, isNull, @aContactID);

            aResult := aCursor.GetBookmark(PffByteArray(aBM));
            CheckEquals(DBIERR_NONE, aResult,
                        'Unexpected error while obtaining a bookmark');

            { Position to EOF. }
            aCursor.SetToEnd;

            { Reposition to the bookmark. }
            aCursor.SetToBookmark(PffByteArray(aBM));
            aCursor.GetRecord(aRecord, ffsltNone);
            aCursor.Dictionary.GetRecordField(0, aRecord, isNull, @aContactID2);

            CheckEquals(aContactID, aContactID2,
                        'Did not reposition to same contact record');

          finally
            FFFreeMem(aBM, ffcl_FixedBookmarkSize);
          end;
        end;  { for }
      finally
        FFFreeMem(aRecord, aCursor.Dictionary.RecordLength);
      end;

    finally
      { Get rid of the cursor. }
      aCursor.Free;
    end;

    { Make sure the file doesn't exist. }
    Assert((not FFFileExists(aFileName)), 'Post insert: Temp table exists on disk.');
  finally
    aDict.Free;
  end;
end;
{--------}
procedure TffTestSQLResultSet.testTempCompareBookmarks;
const
  cTempName = 'testTemp';
  cNumRecs = 1000;
var
  BM1, BM2 : PffByteArray;
  aCursor : TffSrSQLResultSet;
  aDict : TffDataDictionary;
  aFileName : TffFullFileName;
  aRecord : PffByteArray;
  aResult : TffResult;
  CmpResult : Longint;
begin
  { Define the structure of the table. }
  aDict := CreateContactDict;
  try
    { Create the temporary table. }
    aCursor := TffSrSQLResultSet.Create(FEngine, FDB, 1000000);
    aCursor.Build(cTempName, aDict, omReadWrite, smShared, False,
                  False, [fffaTemporary],  0);
    try
      aFileName := FFMakeFullFileName(ExtractFilePath(Application.ExeName),
                                      FFMakeFileNameExt(cTempName, ffc_ExtForData));

      { Make sure the file doesn't exist. }
      Assert((not FFFileExists(aFileName)), 'Temp table exists on disk.');

      { Start a transaction. }
      FEngine.TransactionStart(FDB.DatabaseID, false);
      try
        { Insert some contact records. }
        InsertRandomContactsViaCursor(aCursor, cNumRecs);

        { Commit the transaction. }
        FEngine.TransactionCommit(FDB.DatabaseID);

      except
        FEngine.TransactionRollback(FDB.DatabaseID);
        raise;
      end;

      { Initialize bookmarks for comparison of real data. }
      FFGetMem(BM1, ffcl_FixedBookmarkSize);
      FFGetMem(BM2, ffcl_FixedBookmarkSize);

      { Obtain a record buffer. }
      FFGetMem(aRecord, aCursor.Dictionary.RecordLength);

      try
        { Obtain bookmarks for the 1st through 3rd records. }
        aCursor.SetToBegin;
        aCursor.GetNextRecord(aRecord, ffsltNone);
        aResult := aCursor.GetBookmark(PffByteArray(BM1));
        CheckEquals(DBIERR_NONE, aResult,
                    'Unexpected error while obtaining 1st bookmark');

        aCursor.GetNextRecord(aRecord, ffsltNone);
        aResult := aCursor.GetBookmark(PffByteArray(BM2));
        CheckEquals(DBIERR_NONE, aResult,
                    'Unexpected error while obtaining 2nd bookmark');

        { Do some comparisons. }
        { Both bookmarks are equivalent. }
        aResult := aCursor.CompareBookmarks(BM1, BM1, CmpResult);
        CheckEquals(DBIERR_NONE, aResult, 'Unexpected error, both equal');
        CheckEquals(0, CmpResult, 'Invalid compare result, both equal');

        { BM2 is 2nd }
        aResult := aCursor.CompareBookmarks(BM1, BM2, CmpResult);
        CheckEquals(DBIERR_NONE, aResult, 'Unexpected error, BM2 is 2nd');
        CheckEquals(-1, CmpResult, 'Invalid compare result, BM2 is 2nd');

        { BM1 is 1st }
        aResult := aCursor.CompareBookmarks(BM2, BM1, CmpResult);
        CheckEquals(DBIERR_NONE, aResult, 'Unexpected error, BM2 is 1st');
        CheckEquals(1, CmpResult, 'Invalid compare result, BM2 is 1st');

      finally
        FFFreeMem(aRecord, aCursor.Dictionary.RecordLength);
        FFFreeMem(BM1, ffcl_FixedBookmarkSize);
        FFFreeMem(BM2, ffcl_FixedBookmarkSize);
      end;

    finally
      { Get rid of the cursor. }
      aCursor.Free;
    end;

    { Make sure the file doesn't exist. }
    Assert((not FFFileExists(aFileName)), 'Post insert: Temp table exists on disk.');
  finally
    aDict.Free;
  end;
end;
{--------}
procedure TffTestSQLResultSet.testTempModifyRecord;
const
  cTempName = 'testTemp';
  cNumRecs = 1000;
var
  aCursor : TffSrSQLResultSet;
  aDict : TffDataDictionary;
  aFileName : TffFullFileName;
  aFirstName, aModName : string[25];
  anIndex : integer;
  aRecord : PffByteArray;
  aRecCount : longint;
  aResult : TffResult;
  isNull : boolean;
begin
  { Define the structure of the table. }
  aDict := CreateContactDict;
  try
    { Create the temporary table. }
    aCursor := TffSrSQLResultSet.Create(FEngine, FDB, 1000000);
    aCursor.Build(cTempName, aDict, omReadWrite, smShared, False,
                  False, [fffaTemporary],  0);
    try
      aFileName := FFMakeFullFileName(ExtractFilePath(Application.ExeName),
                                      FFMakeFileNameExt(cTempName, ffc_ExtForData));

      { Make sure the file doesn't exist. }
      Assert((not FFFileExists(aFileName)), 'Temp table exists on disk.');

      { Start a transaction. }
      FEngine.TransactionStart(FDB.DatabaseID, false);
      try
        { Insert some contact records. }
        InsertRandomContactsViaCursor(aCursor, cNumRecs);

        { Commit the transaction. }
        FEngine.TransactionCommit(FDB.DatabaseID);

      except
        FEngine.TransactionRollback(FDB.DatabaseID);
        raise;
      end;

      { Start a new transaction. Modify the first name of every record.
        Verify the modifications were made. }
      FEngine.TransactionStart(FDB.DatabaseID, false);
      try

        FFGetMem(aRecord, aCursor.Dictionary.RecordLength);
        aFirstName := 'Humulous' + StringOfChar(' ', 17);

        try
          aCursor.SetToBegin;
          for anIndex := 1 to cNumRecs do begin
            aResult := aCursor.GetNextRecord(aRecord, ffsltExclusive);
            CheckEquals(DBIERR_NONE, aResult,
                        format('Error occurred retrieving record %d',
                               [anIndex]));
            aCursor.Dictionary.SetRecordField(1, aRecord, @aFirstName);
            aResult := aCursor.ModifyRecord(aRecord, false);
            CheckEquals(DBIERR_NONE, aResult,
                        format('Error occurred modifying record %d',
                               [anIndex]));
          end;

          { Commit the transaction. }
          FEngine.TransactionCommit(FDB.DatabaseID);

          { Verify record count. }
          aResult := aCursor.GetRecordCount(aRecCount);
          CheckEquals(DBIERR_NONE, aResult,
                      format('Unexpected error, rec count 1, err code %d',
                             [aResult]));
          CheckEquals(cNumRecs, aRecCount,
                      format('Invalid record count 1: %d', [aRecCount]));
                      
          { Verify the records were changed. }
          aCursor.SetToBegin;
          for anIndex := 1 to cNumRecs do begin
            aResult := aCursor.GetNextRecord(aRecord, ffsltExclusive);
            CheckEquals(DBIERR_NONE, aResult,
                        format('Error occurred retrieving record %d',
                               [anIndex]));
            aCursor.Dictionary.GetRecordField(1, aRecord, isNull, @aModName);
            CheckEquals(aFirstName, aModName,
                        format('Invalid name for record %d', [anIndex]));
          end;

        finally
          FFFreeMem(aRecord, aCursor.Dictionary.RecordLength);
        end;

      except
        FEngine.TransactionRollback(FDB.DatabaseID);
        raise;
      end;

    finally
      { Get rid of the cursor. }
      aCursor.Free;
    end;

    { Make sure the file doesn't exist. }
    Assert((not FFFileExists(aFileName)), 'Post insert: Temp table exists on disk.');
  finally
    aDict.Free;
  end;
end;
{--------}
procedure TffTestSQLResultSet.testTempSetToCursor;
const
  cTempName = 'testTemp';
  cNumRecs = 1000;
var
  aContactID, aContactID2 : Longint;
  aCursor : TffSrSQLResultSet;
  aClone : TffSrSQLResultSet;
  aDict : TffDataDictionary;
  aFileName : TffFullFileName;
  anIndex, anIndex2, aRecPos : integer;
  aRecord : PffByteArray;
  aResult : TffResult;
  isNull : boolean;
begin
  { Define the structure of the table. }
  aDict := CreateContactDict;
  aClone := nil;
  try
    { Create the temporary table. }
    aCursor := TffSrSQLResultSet.Create(FEngine, FDB, 1000000);
    aCursor.Build(cTempName, aDict, omReadWrite, smShared, False,
                  False, [fffaTemporary],  0);
    { Obtain a record buffer. }
    FFGetMem(aRecord, aCursor.Dictionary.RecordLength);
    try
      aFileName := FFMakeFullFileName(ExtractFilePath(Application.ExeName),
                                      FFMakeFileNameExt(cTempName, ffc_ExtForData));
      { Make sure the file doesn't exist. }
      Assert((not FFFileExists(aFileName)), 'Temp table exists on disk.');

      { Start a transaction. }
      FEngine.TransactionStart(FDB.DatabaseID, false);
      try

        { Insert some contact records. }
        InsertRandomContactsViaCursor(aCursor, cNumRecs);

        { Commit the transaction. }
        FEngine.TransactionCommit(FDB.DatabaseID);

      except
        { Rollback the transaction. }
        FEngine.TransactionRollback(FDB.DatabaseID);
        raise;
      end;

      { Clone the cursor. }
      aClone := TffSrSQLResultSet(aCursor.CloneCursor(omReadWrite));

      for anIndex := 1 to 100 do begin
        { Move the first cursor to a random record. }
        aCursor.SetToBegin;

        aRecPos := Random(cNumRecs);

        for anIndex2 := 0 to aRecPos do begin
          aResult := aCursor.GetNextRecord(aRecord, ffsltNone);
          CheckEquals(DBIERR_NONE, aResult,
                      format('Unexpected error, position to rec %d, error at rec %d',
                             [aRecPos, anIndex2]));
          aCursor.Dictionary.GetRecordField(0, aRecord, isNull, @aContactID);
        end;

        { Set the cloned cursor to the same position. }
        aResult := aClone.SetToCursor(aCursor);
        CheckEquals(DBIERR_NONE, aResult,
                    'Unexpected error, set to cloned cursor');
        aResult := aCursor.GetRecord(aRecord, ffsltNone);
        CheckEquals(DBIERR_NONE, aResult,
                    'Unexpected error, retrieve ID of cloned cursor record');
        aClone.Dictionary.GetRecordField(0, aRecord, isNull, @aContactID2);

        { Verify they are on the same record. }
        CheckEquals(aContactID, aContactID2,
                    format('Not positioned to same record, cycle %d',
                           [anIndex]));
      end;  { for }
    finally
      { Get rid of the cursors. }
      FFFreeMem(aRecord, aCursor.Dictionary.RecordLength);
      aClone.Free;
      aCursor.Free;
    end;

    { Make sure the file doesn't exist. }
    Assert((not FFFileExists(aFileName)), 'Post insert: Temp table exists on disk.');
  finally
    aDict.Free;
  end;
end;
{--------}
procedure TffTestSQLResultSet.testTempDeleteRecord;
const
  cTempName = 'testTemp';
  cNumRecs = 1000;
var
  aContactID : Longint;
  aCursor : TffSrSQLResultSet;
  aDict : TffDataDictionary;
  aFileName : TffFullFileName;
  anIndex, anIndex2 : integer;
  aRecord : PffByteArray;
  aResult : TffResult;
  aStepCount : integer;
  DelChance : integer;
  DelCount : integer; { # of records deleted }
  ActiveList : TList; { list of records not deleted }
  isNull : boolean;
begin
  { Define the structure of the table. }
  aDict := CreateContactDict;
  ActiveList := TList.Create;
  try
    for anIndex := 1 to 100 do begin

      { Create the temporary table. }
      aCursor := TffSrSQLResultSet.Create(FEngine, FDB, 1000000);
      aCursor.Build(cTempName, aDict, omReadWrite, smShared, False,
                    False, [fffaTemporary],  0);
      try
        aFileName := FFMakeFullFileName(ExtractFilePath(Application.ExeName),
                                        FFMakeFileNameExt(cTempName, ffc_ExtForData));

        { Make sure the file doesn't exist. }
        Assert((not FFFileExists(aFileName)), 'Temp table exists on disk.');

        { Start a transaction. }
        FEngine.TransactionStart(FDB.DatabaseID, false);
        try
          { Insert some contact records. }
          InsertRandomContactsViaCursor(aCursor, cNumRecs);

          { Commit the transaction. }
          FEngine.TransactionCommit(FDB.DatabaseID);

        except
          FEngine.TransactionRollback(FDB.DatabaseID);
          raise;
        end;

        FFGetMem(aRecord, aCursor.Dictionary.RecordLength);

        try

          { Determine the chance to delete each record. }
          DelChance := random(100);
          DelCount := 0;

          { Start a new transaction. }
          FEngine.TransactionStart(FDB.DatabaseID, false);
          try
            aCursor.SetToBegin;
            for anIndex2 := 1 to cNumRecs do begin
              aResult := aCursor.GetNextRecord(aRecord, ffsltExclusive);
              CheckEquals(DBIERR_NONE, aResult,
                          format('Error occurred retrieving record %d',
                                 [anIndex2]));
              { Should this record be deleted? }
              if Random(100) <= DelChance then begin
                { Yes. Delete it. }
                aResult := aCursor.DeleteRecord(aRecord);
                CheckEquals(DBIERR_NONE, aResult,
                            format('Error deleting record %d',[anIndex2]));
                inc(DelCount);
              end
              else begin
                { Get the contact ID. }
                aCursor.Dictionary.GetRecordField(0, aRecord, isNull, @aContactID);
                ActiveList.Add(pointer(aContactID));
              end;
            end;

            { Commit the transaction. }
            FEngine.TransactionCommit(FDB.DatabaseID);

          except
            FEngine.TransactionRollback(FDB.DatabaseID);
            raise;
          end;

          { Position to BOF and scan through the active records. Verify that we
            see only those records we expect to see. }
          aResult := DBIERR_NONE;
          aStepCount := 0;
          aCursor.SetToBegin;
          while (aResult = DBIERR_NONE) do begin
            aResult := aCursor.GetNextRecord(aRecord, ffsltNone);
            if aResult = DBIERR_NONE then begin
              { Verify that the contact ID matches what we expect. }
              aCursor.Dictionary.GetRecordField(0, aRecord, isNull, @aContactID);
              CheckEquals(Longint(ActiveList.Items[aStepCount]), aContactID,
                          'Unexpected contact ID');
              inc(aStepCount);
            end;
          end;

          ActiveList.Clear;

          CheckEquals(DBIERR_EOF, aResult,
                      format('Unexpected error, scanning, err code %d',
                             [aResult]));
          CheckEquals(cNumRecs - delCount, aStepCount,
                      format('Invalid step count: %d', [aStepCount]));

        finally
          FFFreeMem(aRecord, aCursor.Dictionary.RecordLength);
        end;

      finally
        { Get rid of the cursor. }
        aCursor.Free;
      end;

      FEngine.TableList.RemoveUnusedTables;

      { Make sure the file doesn't exist. }
      Assert((not FFFileExists(aFileName)), 'Post insert: Temp table exists on disk.');

    end;  { for }

  finally
    ActiveList.Free;
    aDict.Free;
  end;
end;
{--------}
procedure TffTestSQLResultSet.testTempCopyRecords;
const
  cPersistName = 'Contacts1';
  cPersist2Name = 'Contacts2';
  cNumRecs = 1000;
var
  aCursor, aCursor2 : TffSrCursor;
  aCursor3 : TffSrSQLResultSet;
  anIndex : integer;
  aResult : TffResult;
  aSrcRec, aDestRec : PffByteArray;
  aSrcID, aDestID : Longint;
  aSrcFirstName, aDestFirstName : string[25];
  aSrcLastName, aDestLastName : string[25];
  aSrcAge, aDestAge : smallint;
  aSrcState, aDestState : string[2];
  aSrcDMaker, aDestDMaker : boolean;
  isSrcNull, isDestNull : boolean;
  aSrcRecCnt, aDestRecCnt : Longint;

  Dict, Dict2 : TffDataDictionary;
  ExceptRaised : boolean;
begin

  { Build a common dictionary used to create the tables in this test. }
  Dict := CreateContactDict;

  aCursor := TffSrCursor.Create(FEngine, FDB, 1000);
  aCursor.Build(cPersistName, Dict, omReadWrite,
                smShared, false, true, [],  0);
  { Verify that we cannot copy to the same table. }
  try
    aCursor2 := TffSrCursor.Create(FEngine, FDB, 1000);
    aCursor2.Open(cPersistName, '', 0, omReadWrite, smShared, false, false, []);
    try
      ExceptRaised := False;
      try
        aCursor2.CopyRecords(aCursor, ffbcmNoCopy, nil, 0, 0);
      except
        on E:EffException do begin
          ExceptRaised := (E.ErrorCode = fferrSameTable);
        end;
      end;
      Assert(ExceptRaised, 'Copy to same table did not raise exception.');
    finally
      aCursor2.Free;
      FEngine.TableList.RemoveUnusedTables;
    end;

    { Verify that the dictionaries must have the same structure. }
    Dict2 := CreateContactDict;
    try
      Dict2.AddField('Student', '', fftBoolean, 0, 0, false, nil);
      aCursor2 := TffSrCursor.Create(FEngine, FDB, 1000);
      aCursor2.Build('', Dict2, omReadWrite, smExclusive, false, false,
                     [fffaTemporary],  0);
      ExceptRaised := False;
      try
        aCursor2.CopyRecords(aCursor, ffbcmNoCopy, nil, 0, 0);
      except
        on E:EffException do begin
          ExceptRaised := (E.ErrorCode = fferrIncompatDict);
        end;
      end;
      Assert(ExceptRaised, 'Differing dictionaries did not raise exception.');
    finally
      aCursor2.Free;
      Dict2.Free;
      FEngine.TableList.RemoveUnusedTables;
    end;

    aCursor3 := TffSrSQLResultSet.Create(FEngine, FDB, 1000);
    aCursor3.Build('', Dict, omReadWrite, smExclusive, false, false,
                   [fffaTemporary],  0);
    try
      { Verify that we can copy all records from a persistent table to a
        temporary table. }
      { Start a transaction. }
      FEngine.TransactionStart(FDB.DatabaseID, false);
      try
        { Insert some contact records. }
        InsertRandomContactsViaCursor(aCursor, cNumRecs);

        { Commit the transaction. }
        FEngine.TransactionCommit(FDB.DatabaseID);

      except
        FEngine.TransactionRollback(FDB.DatabaseID);
        raise;
      end;

      { Copy the records. }
      aResult := aCursor3.CopyRecords(aCursor, ffbcmNoCopy, nil, 0, 0);
      CheckEquals(DBIERR_NONE, aResult, 'CopyRecords 1 failed.');

      { Validate the records. }
      aCursor.SetToBegin;
      aCursor3.SetToBegin;
      FFGetMem(aSrcRec, Dict.RecordLength);
      FFGetMem(aDestRec, Dict.RecordLength);
      try
        for anIndex := 1 to cNumRecs do begin
          aResult := aCursor.GetNextRecord(aSrcRec, ffsltNone);
          CheckEquals(DBIERR_NONE, aResult, 'Invalid result, src, rec scan 1');
          aResult := aCursor3.GetNextRecord(aDestRec, ffsltNone);
          CheckEquals(DBIERR_NONE, aResult, 'Invalid result, dest, rec scan 1');

          { Get the value of the source fields. }
          aCursor.GetRecordField(0, aSrcRec, isSrcNull, @aSrcID);
          aCursor.GetRecordField(1, aSrcRec, isSrcNull, @aSrcFirstName);
          aCursor.GetRecordField(2, aSrcRec, isSrcNull, @aSrcLastName);
          aCursor.GetRecordField(3, aSrcRec, isSrcNull, @aSrcAge);
          aCursor.GetRecordField(4, aSrcRec, isSrcNull, @aSrcState);
          aCursor.GetRecordField(5, aSrcRec, isSrcNull, @aSrcDMaker);

          { Get the value of the dest fields. }
          aCursor3.GetRecordField(0, aDestRec, isDestNull, @aDestID);
          aCursor3.GetRecordField(1, aDestRec, isDestNull, @aDestFirstName);
          aCursor3.GetRecordField(2, aDestRec, isDestNull, @aDestLastName);
          aCursor3.GetRecordField(3, aDestRec, isDestNull, @aDestAge);
          aCursor3.GetRecordField(4, aDestRec, isDestNull, @aDestState);
          aCursor3.GetRecordField(5, aDestRec, isDestNull, @aDestDMaker);

          { Compare the fields. }
          CheckEquals(aSrcID, aDestID, 'Invalid IDs, rec scan 1');
          CheckEquals(aSrcFirstName, aDestFirstName, 'Invalid first name, rec scan 1');
          CheckEquals(aSrcLastName, aDestLastName, 'Invalid last name, rec scan 1');
          CheckEquals(aSrcAge, aDestAge, 'Invalid age, rec scan 1');
          CheckEquals(aSrcState, aDestState, 'Invalid state, rec scan 1');
          Assert(aSrcDMaker = aDestDMaker, 'Invalid decision maker, rec scan 1');

        end;
      finally
        FFFreeMem(aSrcRec, Dict.RecordLength);
        FFFreeMem(aDestRec, Dict.RecordLength);
      end;

      FEngine.TransactionStart(FDB.DatabaseID, false);
      try
        aResult := aCursor3.Empty;
        CheckEquals(DBIERR_NONE, aResult, 'aCursor3.Empty 1 failed');
        FEngine.TransactionCommit(FDB.DatabaseID);
      except
        FEngine.TransactionRollback(FDB.DatabaseID);
        raise;
      end;

      { Verify that we can control copying via a callback. }
      aResult := aCursor3.CopyRecords(aCursor, ffbcmNoCopy, CopyRecCallback, 0, 0);
      CheckEquals(DBIERR_NONE, aResult, 'CopyRecords 2 failed.');

      { Verify that fewer records were copied than in original table. Given
        our filter this is a reasonable expectation. }
      aCursor.GetRecordCount(aSrcRecCnt);
      aCursor3.GetRecordCount(aDestRecCnt);
      Assert(aSrcRecCnt > aDestRecCnt,
             'More records copied by callback than expected.');

      { Validate the records. }
      aCursor3.SetToBegin;
      FFGetMem(aDestRec, Dict.RecordLength);
      try
        aResult := DBIERR_NONE;
        while aResult = DBIERR_NONE do begin
          aResult := aCursor3.GetNextRecord(aDestRec, ffsltNone);

          { Get the value of the age field. }
          aCursor3.GetRecordField(3, aDestRec, isDestNull, @aDestAge);
          Assert((not isDestNull) and (aDestAge >= 65),
                 'Age not within expected parameters.');

        end;
        CheckEquals(DBIERR_EOF, aResult, 'Unexpected return code, rec scan 2');
      finally
        FFFreeMem(aDestRec, Dict.RecordLength);
      end;

      FEngine.TransactionStart(FDB.DatabaseID, false);
      try
        aResult := aCursor3.Empty;
        CheckEquals(DBIERR_NONE, aResult, 'aCursor3.Empty 2 failed');
        FEngine.TransactionCommit(FDB.DatabaseID);
      except
        FEngine.TransactionRollback(FDB.DatabaseID);
        raise;
      end;


    finally
      aCursor3.Free;
      FEngine.TableList.RemoveUnusedTables;
    end;

    { Verify that we can copy from a persistent table to another persistent
      table. }
    aCursor2 := TffSrCursor.Create(FEngine, FDB, 1000);
    aCursor2.Build(cPersist2Name, Dict,omReadWrite, smShared, false, true,
                   [], 0);
    try
      { Copy the records. }
      aResult := aCursor2.CopyRecords(aCursor, ffbcmNoCopy, nil, 0, 0);
      CheckEquals(DBIERR_NONE, aResult, 'CopyRecords 3 failed.');

      { Validate the records. }
      aCursor.SetToBegin;
      aCursor2.SetToBegin;
      FFGetMem(aSrcRec, Dict.RecordLength);
      FFGetMem(aDestRec, Dict.RecordLength);
      try
        for anIndex := 1 to cNumRecs do begin
          aResult := aCursor.GetNextRecord(aSrcRec, ffsltNone);
          CheckEquals(DBIERR_NONE, aResult, 'Invalid result, src, rec scan 3');
          aResult := aCursor2.GetNextRecord(aDestRec, ffsltNone);
          CheckEquals(DBIERR_NONE, aResult, 'Invalid result, dest, rec scan 3');

          { Get the value of the source fields. }
          aCursor.GetRecordField(0, aSrcRec, isSrcNull, @aSrcID);
          aCursor.GetRecordField(1, aSrcRec, isSrcNull, @aSrcFirstName);
          aCursor.GetRecordField(2, aSrcRec, isSrcNull, @aSrcLastName);
          aCursor.GetRecordField(3, aSrcRec, isSrcNull, @aSrcAge);
          aCursor.GetRecordField(4, aSrcRec, isSrcNull, @aSrcState);
          aCursor.GetRecordField(5, aSrcRec, isSrcNull, @aSrcDMaker);

          { Get the value of the dest fields. }
          aCursor2.GetRecordField(0, aDestRec, isDestNull, @aDestID);
          aCursor2.GetRecordField(1, aDestRec, isDestNull, @aDestFirstName);
          aCursor2.GetRecordField(2, aDestRec, isDestNull, @aDestLastName);
          aCursor2.GetRecordField(3, aDestRec, isDestNull, @aDestAge);
          aCursor2.GetRecordField(4, aDestRec, isDestNull, @aDestState);
          aCursor2.GetRecordField(5, aDestRec, isDestNull, @aDestDMaker);

          { Compare the fields. }
          CheckEquals(aSrcID, aDestID, 'Invalid IDs, rec scan 3');
          CheckEquals(aSrcFirstName, aDestFirstName, 'Invalid first name, rec scan 3');
          CheckEquals(aSrcLastName, aDestLastName, 'Invalid last name, rec scan 3');
          CheckEquals(aSrcAge, aDestAge, 'Invalid age, rec scan 3');
          CheckEquals(aSrcState, aDestState, 'Invalid state, rec scan 3');
          Assert(aSrcDMaker = aDestDMaker, 'Invalid decision maker, rec scan 3');

        end;
      finally
        FFFreeMem(aSrcRec, Dict.RecordLength);
        FFFreeMem(aDestRec, Dict.RecordLength);
      end;
    finally
      aCursor2.Free;
      FEngine.TableList.RemoveUnusedTables;
    end;

  finally
    aCursor.Free;
    Dict.Free;

    { Get rid of any tables that might be lying around. }
    FEngine.TableDelete(FDB.DatabaseID, cPersistName);
    FEngine.TableDelete(FDB.DatabaseID, cPersist2Name);
  end;

end;
{--------}
procedure TffTestSQLResultSet.testTempCopyRecordParts;
const
  cPersistName = 'Contacts1';
  cPersist2Name = 'Contacts2';
  cNumRecs = 1000;
var
  aCursor, aCursor2 : TffSrCursor;
  aCursor3 : TffSrSQLResultSet;
  aFields : PffLongintArray;
  anIndex : integer;
  aResult : TffResult;
  aSrcRec, aDestRec : PffByteArray;
  aSrcID, aDestID : Longint;
  aSrcAge, aDestAge : smallint;
  aSrcState, aDestState : string[2];
  isSrcNull, isDestNull : boolean;
  aSrcRecCnt, aDestRecCnt : Longint;

  Dict, DictDest : TffDataDictionary;
  ExceptRaised : boolean;
begin

  { Build the dictionary for the source table. }
  Dict := CreateContactDict;

  { Build the dictionary for the target table. }
  DictDest := CreatePartialContactDict;
  { Set up an array to specify which fields are to be copied to the destination
    table. }
  FFGetMem(aFields, SizeOf(Longint) * 3);

  aCursor := TffSrCursor.Create(FEngine, FDB, 1000);
  aCursor.Build(cPersistName, Dict, omReadWrite, smShared, false, true, [], 0);
  try
    { Verify that we must supply compatible fields. }
    aCursor2 := TffSrCursor.Create(FEngine, FDB, 1000);
    aCursor2.Build('', DictDest, omReadWrite, smExclusive, false, false,
                   [fffaTemporary], 0);
    try
      ExceptRaised := False;
      try
        { Try it with inadequate number of fields. }
        aFields^[0] := 0;
        aCursor2.CopyRecordParts(aCursor, aFields, 1, ffbcmNoCopy, nil, 0, 0);
      except
        on E:EffException do begin
          ExceptRaised := (E.ErrorCode = fferrIncompatDict);
        end;
      end;
      Assert(ExceptRaised, 'Too few fields did not raise exception.');

      ExceptRaised := False;
      try
        { Try it with differing dictionaries. }
        aFields^[0] := 0;
        aFields^[1] := 1; { This field doesn't match what is in DictDest. }
        aFields^[2] := 2; { This field doesn't match what is in DictDest. }
        aCursor2.CopyRecordParts(aCursor, aFields, 3, ffbcmNoCopy, nil, 0, 0);
      except
        on E:EffException do begin
          ExceptRaised := (E.ErrorCode = fferrIncompatDict);
        end;
      end;
      Assert(ExceptRaised, 'Differing dictionaries did not raise exception.');

    finally
      aCursor2.Free;
      FEngine.TableList.RemoveUnusedTables;
    end;

    aCursor3 := TffSrSQLResultSet.Create(FEngine, FDB, 1000);
    aCursor3.Build('', DictDest, omReadWrite, smExclusive, false, false,
                   [fffaTemporary], 0);
    try
      { Verify that we can copy all records from a persistent table to a
        temporary table. }
      aFields^[1] := 3; { This field doesn't match what is in DictDest. }
      aFields^[2] := 4; { This field doesn't match what is in DictDest. }
      { Start a transaction. }
      FEngine.TransactionStart(FDB.DatabaseID, false);
      try
        { Insert some contact records. }
        InsertRandomContactsViaCursor(aCursor, cNumRecs);

        { Commit the transaction. }
        FEngine.TransactionCommit(FDB.DatabaseID);

      except
        FEngine.TransactionRollback(FDB.DatabaseID);
        raise;
      end;

      { Copy the records. }
      aResult := aCursor3.CopyRecordParts(aCursor, aFields, 3, ffbcmNoCopy,
                                          nil, 0, 0);
      CheckEquals(DBIERR_NONE, aResult, 'CopyRecords 1 failed.');

      { Validate the records. }
      aCursor.SetToBegin;
      aCursor3.SetToBegin;
      FFGetMem(aSrcRec, Dict.RecordLength);
      FFGetMem(aDestRec, DictDest.RecordLength);
      try
        for anIndex := 1 to cNumRecs do begin
          aResult := aCursor.GetNextRecord(aSrcRec, ffsltNone);
          CheckEquals(DBIERR_NONE, aResult, 'Invalid result, src, rec scan 1');
          aResult := aCursor3.GetNextRecord(aDestRec, ffsltNone);
          CheckEquals(DBIERR_NONE, aResult, 'Invalid result, dest, rec scan 1');

          { Get the value of the source fields. }
          aCursor.GetRecordField(0, aSrcRec, isSrcNull, @aSrcID);
          aCursor.GetRecordField(3, aSrcRec, isSrcNull, @aSrcAge);
          aCursor.GetRecordField(4, aSrcRec, isSrcNull, @aSrcState);

          { Get the value of the dest fields. }
          aCursor3.GetRecordField(0, aDestRec, isDestNull, @aDestID);
          aCursor3.GetRecordField(1, aDestRec, isDestNull, @aDestAge);
          aCursor3.GetRecordField(2, aDestRec, isDestNull, @aDestState);

          { Compare the fields. }
          CheckEquals(aSrcID, aDestID, 'Invalid IDs, rec scan 1');
          CheckEquals(aSrcAge, aDestAge, 'Invalid age, rec scan 1');
          CheckEquals(aSrcState, aDestState, 'Invalid state, rec scan 1');

        end;
      finally
        FFFreeMem(aSrcRec, Dict.RecordLength);
        FFFreeMem(aDestRec, DictDest.RecordLength);
      end;

      FEngine.TransactionStart(FDB.DatabaseID, false);
      try
        aResult := aCursor3.Empty;
        CheckEquals(DBIERR_NONE, aResult, 'aCursor3.Empty 1 failed');
        FEngine.TransactionCommit(FDB.DatabaseID);
      except
        FEngine.TransactionRollback(FDB.DatabaseID);
        raise;
      end;

      { Verify that we can control copying via a callback. }
      aResult := aCursor3.CopyRecordParts(aCursor, aFields, 3, ffbcmNoCopy,
                                          CopyRecCallback, 0, 0);
      CheckEquals(DBIERR_NONE, aResult, 'CopyRecords 2 failed.');

      { Verify that fewer records were copied than in original table. Given
        our filter this is a reasonable expectation. }
      aCursor.GetRecordCount(aSrcRecCnt);
      aCursor3.GetRecordCount(aDestRecCnt);
      Assert(aSrcRecCnt > aDestRecCnt,
             'More records copied by callback than expected.');

      { Validate the records. }
      aCursor3.SetToBegin;
      FFGetMem(aDestRec, Dict.RecordLength);
      try
        aResult := DBIERR_NONE;
        while aResult = DBIERR_NONE do begin
          aResult := aCursor3.GetNextRecord(aDestRec, ffsltNone);

          { Get the value of the age field. }
          aCursor3.GetRecordField(1, aDestRec, isDestNull, @aDestAge);
          Assert((not isDestNull) and (aDestAge >= 65),
                 'Age not within expected parameters.');

        end;
        CheckEquals(DBIERR_EOF, aResult, 'Unexpected return code, rec scan 2');
      finally
        FFFreeMem(aDestRec, Dict.RecordLength);
      end;

      FEngine.TransactionStart(FDB.DatabaseID, false);
      try
        aResult := aCursor3.Empty;
        CheckEquals(DBIERR_NONE, aResult, 'aCursor3.Empty 2 failed');
        FEngine.TransactionCommit(FDB.DatabaseID);
      except
        FEngine.TransactionRollback(FDB.DatabaseID);
        raise;
      end;


    finally
      aCursor3.Free;
      FEngine.TableList.RemoveUnusedTables;
    end;

    { Verify that we can copy from a persistent table to another persistent
      table. }
    aCursor2 := TffSrCursor.Create(FEngine, FDB, 1000);
    aCursor2.Build(cPersist2Name, DictDest, omReadWrite, smShared, false, true,
                   [], 0);
    try
      { Copy the records. }
      aResult := aCursor2.CopyRecordParts(aCursor, aFields, 3, ffbcmNoCopy,
                                          nil, 0, 0);
      CheckEquals(DBIERR_NONE, aResult, 'CopyRecords 3 failed.');

      { Validate the records. }
      aCursor.SetToBegin;
      aCursor2.SetToBegin;
      FFGetMem(aSrcRec, Dict.RecordLength);
      FFGetMem(aDestRec, Dict.RecordLength);
      try
        for anIndex := 1 to cNumRecs do begin
          aResult := aCursor.GetNextRecord(aSrcRec, ffsltNone);
          CheckEquals(DBIERR_NONE, aResult, 'Invalid result, src, rec scan 3');
          aResult := aCursor2.GetNextRecord(aDestRec, ffsltNone);
          CheckEquals(DBIERR_NONE, aResult, 'Invalid result, dest, rec scan 3');

          { Get the value of the source fields. }
          aCursor.GetRecordField(0, aSrcRec, isSrcNull, @aSrcID);
          aCursor.GetRecordField(3, aSrcRec, isSrcNull, @aSrcAge);
          aCursor.GetRecordField(4, aSrcRec, isSrcNull, @aSrcState);

          { Get the value of the dest fields. }
          aCursor2.GetRecordField(0, aDestRec, isDestNull, @aDestID);
          aCursor2.GetRecordField(1, aDestRec, isDestNull, @aDestAge);
          aCursor2.GetRecordField(2, aDestRec, isDestNull, @aDestState);

          { Compare the fields. }
          CheckEquals(aSrcID, aDestID, 'Invalid IDs, rec scan 3');
          CheckEquals(aSrcAge, aDestAge, 'Invalid age, rec scan 3');
          CheckEquals(aSrcState, aDestState, 'Invalid state, rec scan 3');

        end;
      finally
        FFFreeMem(aSrcRec, Dict.RecordLength);
        FFFreeMem(aDestRec, DictDest.RecordLength);
      end;
    finally
      aCursor2.Free;
    end;

  finally
    FFFreeMem(aFields, SizeOf(Longint) * 3);
    aCursor.Free;
    Dict.Free;
    DictDest.Free;

    { Get rid of any tables that might be lying around. }
    FEngine.TableDelete(FDB.DatabaseID, cPersistName);
    FEngine.TableDelete(FDB.DatabaseID, cPersist2Name);
  end;

end;
{--------}
procedure TffTestSQLResultSet.testTempCopyNoBLOBs;
const
  cPersistName = 'Contacts1';
  cPersist2Name = 'Contacts2';
  cNumRecs = 10;
var
  aBLOBNr : TffInt64;
  aCursor, aCursor2 : TffSrCursor;
  anIndex : integer;
  aResult : TffResult;
  aSrcRec, aDestRec : PffByteArray;
  isDestNull : boolean;
  Dict : TffDataDictionary;
  notes1Char, notes2Char : char;
begin

  { NOTE: This routine deals with up to 65 MB worth of BLOBs. We purposefully
    leave the buffer manager's RAM set low just to cause some thrashing &
    see what happens. }

  { Build a common dictionary used to create the tables in this test. }
  Dict := CreateContactDictWithNotes;

  aCursor := TffSrCursor.Create(FEngine, FDB, 1000);
  aCursor.Build(cPersistName, Dict, omReadWrite, smShared, false, true, [],  0);
  try
    { Verify that when we copy the records from the persistent table to
      another persistent table, the BLOB fields in the temporary table are
      set to null. }
    aCursor2 := TffSrCursor.Create(FEngine, FDB, 1000);
    aCursor2.Build(cPersist2Name, Dict, omReadWrite, smExclusive, false, true,
                   [],  0);
    try
      { Start a transaction. }
      FEngine.TransactionStart(FDB.DatabaseID, false);
      try
        { Insert some contact records. }
        notes1Char := 'B';
        notes2Char := '2';
        InsertRandomContactsWithNotes(aCursor, cNumRecs, notes1Char, notes2Char);

        { Commit the transaction. }
        FEngine.TransactionCommit(FDB.DatabaseID);

      except
        FEngine.TransactionRollback(FDB.DatabaseID);
        raise;
      end;

      { Copy the records. }
      aResult := aCursor2.CopyRecords(aCursor, ffbcmNoCopy, nil, 0, 0);
      CheckEquals(DBIERR_NONE, aResult, 'CopyRecords 1 failed.');

      { Validate the records. }
      aCursor.SetToBegin;
      aCursor2.SetToBegin;
      FFGetMem(aSrcRec, Dict.RecordLength);
      FFGetMem(aDestRec, Dict.RecordLength);
      try
        for anIndex := 1 to cNumRecs do begin
          aResult := aCursor.GetNextRecord(aSrcRec, ffsltNone);
          CheckEquals(DBIERR_NONE, aResult, 'Invalid result, src, rec scan 1');
          aResult := aCursor2.GetNextRecord(aDestRec, ffsltNone);
          CheckEquals(DBIERR_NONE, aResult, 'Invalid result, dest, rec scan 1');

          aBLOBNr.iLow := 0;
          aBLOBNr.iHigh := 0;

          { Is the first BLOB field null? }
          aCursor2.GetRecordField(3, aDestRec, isDestNull, @aBLOBNr);
          Assert(isDestNull,
                 format('First BLOB field NOT null, record %d', [anIndex]));
          Assert((aBLOBNr.iLow = 0) and (aBLOBNr.iHigh = 0),
                 format('Unexpected BLOB nr for first BLOB field, record %d',
                 [anIndex]));

          aBLOBNr.iLow := 0;
          aBLOBNr.iHigh := 0;

          { Is the second BLOB field null? }
          aCursor2.GetRecordField(7, aDestRec, isDestNull, @aBLOBNr);
          Assert(isDestNull,
                 format('First BLOB field NOT null, record %d', [anIndex]));
          Assert((aBLOBNr.iLow = 0) and (aBLOBNr.iHigh = 0),
                 format('Unexpected BLOB nr for first BLOB field, record %d',
                 [anIndex]));
        end;
      finally
        FFFreeMem(aSrcRec, Dict.RecordLength);
        FFFreeMem(aDestRec, Dict.RecordLength);
      end;

    finally
      aCursor2.Free;
    end;

  finally
    aCursor.Free;
    Dict.Free;
    FEngine.TableList.RemoveUnusedTables;

    { Get rid of any tables that might be lying around. }
    FEngine.TableDelete(FDB.DatabaseID, cPersistName);
    FEngine.TableDelete(FDB.DatabaseID, cPersist2Name);
  end;

end;
{--------}
procedure TffTestSQLResultSet.testTempCopyBLOBs;
const
  cPersistName = 'Contacts1';
  cPersist2Name = 'Contacts2';
  cNumRecs = 10;
var
  aBytesRead  : TffWord32;
  aDestBLOBNr,
  aSrcBLOBNr  : TffInt64;
  aCursor,
  aCursor2    : TffSrCursor;
  aResult     : TffResult;
  anIndex     : Integer;
  aSrcBuf,
  aDestBuf    : PffByteArray;
  aSrcLen,
  aDestLen    : TffWord32;
  aSrcRec,
  aDestRec    : PffByteArray;
  IsNull      : Boolean;
  anInx       : Longint;
  Dict        : TffDataDictionary;
  notes1Char,
  notes2Char  : char;
begin

  { NOTE: This routine deals with up to 65 MB worth of BLOBs. We purposefully
    leave the buffer manager's RAM set low just to cause some thrashing &
    see what happens. }

  { Build a common dictionary used to create the tables in this test. }
  Dict := CreateContactDictWithNotes;

  aCursor := TffSrCursor.Create(FEngine, FDB, 1000);
  aCursor.Build(cPersistName, Dict, omReadWrite, smShared, false, true, [],  0);
  try
    { Verify that when we copy the records from the persistent table to
      another persistent table, the BLOB fields in the temporary table are
      set to null. }
    aCursor2 := TffSrCursor.Create(FEngine, FDB, 1000);
    aCursor2.Build(cPersist2Name, Dict, omReadWrite, smExclusive, false, true,
                   [],  0);
    try
      { Start a transaction. }
      FEngine.TransactionStart(FDB.DatabaseID, false);
      try
        { Insert some contact records. }
        notes1Char := 'B';
        notes2Char := '2';
        InsertRandomContactsWithNotes(aCursor, cNumRecs, notes1Char, notes2Char);

        { Commit the transaction. }
        FEngine.TransactionCommit(FDB.DatabaseID);

      except
        FEngine.TransactionRollback(FDB.DatabaseID);
        raise;
      end;

      { Copy the records. }
      aResult := aCursor2.CopyRecords(aCursor, ffbcmCopyFull, nil, 0, 0);
      CheckEquals(DBIERR_NONE, aResult, 'CopyRecords 1 failed.');

      { Validate the records. }
      aCursor.SetToBegin;
      aCursor2.SetToBegin;
      FFGetMem(aSrcRec, Dict.RecordLength);
      FFGetMem(aDestRec, Dict.RecordLength);
      try
        for anIndex := 1 to cNumRecs do begin
          aResult := aCursor.GetNextRecord(aSrcRec, ffsltNone);
          CheckEquals(DBIERR_NONE, aResult, 'Invalid result, src, rec scan 1');
          aResult := aCursor2.GetNextRecord(aDestRec, ffsltNone);
          CheckEquals(DBIERR_NONE, aResult, 'Invalid result, dest, rec scan 1');

          { Verify the first BLOB is present and equal to the original
            BLOB. }
          aCursor2.GetRecordField(3, aDestRec, isNull, @aDestBLOBNr);
          Assert((not isNull),
                 format('First BLOB field is null, record %d', [anIndex]));

          aCursor.GetRecordField(3, aSrcRec, isNull, @aSrcBLOBNr);
          { Compare lengths of the two BLOB fields. }
          aSrcLen := aCursor.BLOBGetLength(aSrcBLOBNr, aResult);
          Assert(aResult = DBIERR_NONE, 'Failed to get source BLOB len');
          aDestLen := aCursor2.BLOBGetLength(aDestBLOBNr, aResult);
          Assert(aResult = DBIERR_NONE, 'Failed to get dest BLOB len');
          Assert( aDestLen = aSrcLen,
                 format('BLOB 1 lengths do not match; src: %d, dest: %d',
                        [aSrcLen, aDestLen]));

          { Create record buffers to hold the 2 BLOBs. }
          FFGetZeroMem(aSrcBuf, aSrcLen);
          FFGetZeroMem(aDestBuf, aDestLen);
          try
            aResult := aCursor.BLOBRead(aSrcBLOBNr, 0, aSrcLen, aSrcBuf^,
                                        aBytesRead);
            Assert(aResult = DBIERR_NONE, 'Failed to read source BLOB 1');
            Assert(aBytesRead = aSrcLen, 'Bytes read mismatch, source BLOB 1');

            aResult := aCursor2.BLOBRead(aDestBLOBNr, 0, aDestLen, aDestBuf^,
                                         aBytesRead);
            Assert(aResult = DBIERR_NONE, 'Failed to read dest BLOB 1');
            Assert(aBytesRead = aDestLen, 'Bytes read mismatch, dest BLOB 1');

            for anInx := 0 to pred(aSrcLen) do
              CheckEquals(aSrcBuf^[anInx], aDestBuf^[anInx],
                          format('BLOB 1 mismatch, position %d', [anInx]));

          finally
            FFFreeMem(aSrcBuf, aSrcLen);
            FFFreeMem(aDestBuf, aDestLen);
          end;

          ffInitI64(aDestBLOBNr);
          ffInitI64(aSrcBLOBNr);

          { Verify the second BLOB is present and equal to the original
            BLOB. }
          aCursor2.GetRecordField(7, aDestRec, isNull, @aDestBLOBNr);
          Assert((not isNull),
                 format('Second BLOB field is null, record %d', [anIndex]));

          aCursor.GetRecordField(7, aSrcRec, isNull, @aSrcBLOBNr);
          { Compare lengths of the two BLOB fields. }
          aSrcLen := aCursor.BLOBGetLength(aSrcBLOBNr, aResult);
          Assert(aResult = DBIERR_NONE, 'Failed to get source BLOB len');
          aDestLen := aCursor2.BLOBGetLength(aDestBLOBNr, aResult);
          Assert(aResult = DBIERR_NONE, 'Failed to get dest BLOB len');
          Assert( aDestLen = aSrcLen,
                 format('BLOB 2 lengths do not match; src: %d, dest: %d',
                        [aSrcLen, aDestLen]));

          { Create record buffers to hold the 2 BLOBs. }
          FFGetZeroMem(aSrcBuf, aSrcLen);
          FFGetZeroMem(aDestBuf, aDestLen);
          try
            aResult := aCursor.BLOBRead(aSrcBLOBNr, 0, aSrcLen, aSrcBuf^,
                                        aBytesRead);
            Assert(aResult = DBIERR_NONE, 'Failed to read source BLOB 2');
            Assert(aBytesRead = aSrcLen, 'Bytes read mismatch, source BLOB 2');

            aResult := aCursor2.BLOBRead(aDestBLOBNr, 0, aDestLen, aDestBuf^,
                                         aBytesRead);
            Assert(aResult = DBIERR_NONE, 'Failed to read dest BLOB 2');
            Assert(aBytesRead = aDestLen, 'Bytes read mismatch, dest BLOB 2');

            for anInx := 0 to pred(aSrcLen) do
              CheckEquals(aSrcBuf^[anInx], aDestBuf^[anInx],
                          format('BLOB 1 mismatch, position %d', [anInx]));

          finally
            FFFreeMem(aSrcBuf, aSrcLen);
            FFFreeMem(aDestBuf, aDestLen);
          end;
        end;
      finally
        FFFreeMem(aSrcRec, Dict.RecordLength);
        FFFreeMem(aDestRec, Dict.RecordLength);
      end;

    finally
      aCursor2.Free;
    end;

  finally
    aCursor.Free;
    Dict.Free;
    FEngine.TableList.RemoveUnusedTables;

    { Get rid of any tables that might be lying around. }
    FEngine.TableDelete(FDB.DatabaseID, cPersistName);
    FEngine.TableDelete(FDB.DatabaseID, cPersist2Name);
  end;

end;
{--------}
procedure TffTestSQLResultSet.testTempCreateBLOBLinks;
const
  cPersistName = 'Contacts1';
  cNumRecs = 10;
var
  aBytesRead  : TffWord32;
  aDestBLOBNr,
  aSrcBLOBNr  : TffInt64;
  aCursor     : TffSrCursor;
  aCursor2    : TffSrSQLResultSet;
  aResult     : TffResult;
  anIndex     : Integer;
  aSrcBuf,
  aDestBuf    : PffByteArray;
  aSrcLen,
  aDestLen    : TffWord32;
  aSrcRec,
  aDestRec    : PffByteArray;
  IsNull      : Boolean;
  anInx       : Longint;
  Dict        : TffDataDictionary;
  notes1Char,
  notes2Char  : char;
begin

  { NOTE: This routine deals with up to 65 MB worth of BLOBs. We purposefully
    leave the buffer manager's RAM set low just to cause some thrashing &
    see what happens. }

  { Build a common dictionary used to create the tables in this test. }
  Dict := CreateContactDictWithNotes;

  aCursor := TffSrCursor.Create(FEngine, FDB, 1000);
  aCursor.Build(cPersistName, Dict, omReadWrite, smShared, false, true, [],  0);
  try
    { Verify that when we copy the records from the persistent table to
      another persistent table, the BLOB fields in the temporary table are
      set to null. }
    aCursor2 := TffSrSQLResultSet.Create(FEngine, FDB, 1000);
    aCursor2.Build('', Dict, omReadWrite, smExclusive, false, true,
                   [fffaTemporary],  0);
    try
      { Start a transaction. }
      FEngine.TransactionStart(FDB.DatabaseID, false);
      try
        { Insert some contact records. }
        notes1Char := 'B';
        notes2Char := '2';
        InsertRandomContactsWithNotes(aCursor, cNumRecs, notes1Char, notes2Char);

        { Commit the transaction. }
        FEngine.TransactionCommit(FDB.DatabaseID);

      except
        FEngine.TransactionRollback(FDB.DatabaseID);
        raise;
      end;

      { Copy the records. }
      aResult := aCursor2.CopyRecords(aCursor, ffbcmCreateLink, nil, 0, 0);
      CheckEquals(DBIERR_NONE, aResult, 'CopyRecords 1 failed.');

      { Validate the records. }
      aCursor.SetToBegin;
      aCursor2.SetToBegin;
      FFGetMem(aSrcRec, Dict.RecordLength);
      FFGetMem(aDestRec, Dict.RecordLength);
      try
        for anIndex := 1 to cNumRecs do begin
          aResult := aCursor.GetNextRecord(aSrcRec, ffsltNone);
          CheckEquals(DBIERR_NONE, aResult, 'Invalid result, src, rec scan 1');
          aResult := aCursor2.GetNextRecord(aDestRec, ffsltNone);
          CheckEquals(DBIERR_NONE, aResult, 'Invalid result, dest, rec scan 1');

          { Verify the first BLOB is present and equal to the original
            BLOB. }
          aCursor2.GetRecordField(3, aDestRec, isNull, @aDestBLOBNr);
          Assert((not isNull),
                 format('First BLOB field is null, record %d', [anIndex]));

          aCursor.GetRecordField(3, aSrcRec, isNull, @aSrcBLOBNr);
          { Compare lengths of the two BLOB fields. }
          aSrcLen := aCursor.BLOBGetLength(aSrcBLOBNr, aResult);
          Assert(aResult = DBIERR_NONE, 'Failed to get source BLOB len');
          aDestLen := aCursor2.BLOBGetLength(aDestBLOBNr, aResult);
          Assert(aResult = DBIERR_NONE, 'Failed to get dest BLOB len');
          Assert( aDestLen = aSrcLen,
                 format('BLOB 1 lengths do not match; src: %d, dest: %d',
                        [aSrcLen, aDestLen]));

          { Create record buffers to hold the 2 BLOBs. }
          FFGetZeroMem(aSrcBuf, aSrcLen);
          FFGetZeroMem(aDestBuf, aDestLen);
          try
            aResult := aCursor.BLOBRead(aSrcBLOBNr, 0, aSrcLen, aSrcBuf^,
                                        aBytesRead);
            Assert(aResult = DBIERR_NONE, 'Failed to read source BLOB 1');
            Assert(aBytesRead = aSrcLen, 'Bytes read mismatch, source BLOB 1');

            aResult := aCursor2.BLOBRead(aDestBLOBNr, 0, aDestLen, aDestBuf^,
                                         aBytesRead);
            Assert(aResult = DBIERR_NONE, 'Failed to read dest BLOB 1');
            Assert(aBytesRead = aDestLen, 'Bytes read mismatch, dest BLOB 1');

            for anInx := 0 to pred(aSrcLen) do
              CheckEquals(aSrcBuf^[anInx], aDestBuf^[anInx],
                          format('BLOB 1 mismatch, position %d', [anInx]));

          finally
            FFFreeMem(aSrcBuf, aSrcLen);
            FFFreeMem(aDestBuf, aDestLen);
          end;

          ffInitI64(aDestBLOBNr);
          ffInitI64(aSrcBLOBNr);

          { Verify the second BLOB is present and equal to the original
            BLOB. }
          aCursor2.GetRecordField(7, aDestRec, isNull, @aDestBLOBNr);
          Assert((not isNull),
                 format('Second BLOB field is null, record %d', [anIndex]));

          aCursor.GetRecordField(7, aSrcRec, isNull, @aSrcBLOBNr);
          { Compare lengths of the two BLOB fields. }
          aSrcLen := aCursor.BLOBGetLength(aSrcBLOBNr, aResult);
          Assert(aResult = DBIERR_NONE, 'Failed to get source BLOB len');
          aDestLen := aCursor2.BLOBGetLength(aDestBLOBNr, aResult);
          Assert(aResult = DBIERR_NONE, 'Failed to get dest BLOB len');
          Assert( aDestLen = aSrcLen,
                 format('BLOB 2 lengths do not match; src: %d, dest: %d',
                        [aSrcLen, aDestLen]));

          { Create record buffers to hold the 2 BLOBs. }
          FFGetZeroMem(aSrcBuf, aSrcLen);
          FFGetZeroMem(aDestBuf, aDestLen);
          try
            aResult := aCursor.BLOBRead(aSrcBLOBNr, 0, aSrcLen, aSrcBuf^,
                                        aBytesRead);
            Assert(aResult = DBIERR_NONE, 'Failed to read source BLOB 2');
            Assert(aBytesRead = aSrcLen, 'Bytes read mismatch, source BLOB 2');

            aResult := aCursor2.BLOBRead(aDestBLOBNr, 0, aDestLen, aDestBuf^,
                                         aBytesRead);
            Assert(aResult = DBIERR_NONE, 'Failed to read dest BLOB 2');
            Assert(aBytesRead = aDestLen, 'Bytes read mismatch, dest BLOB 2');

            for anInx := 0 to pred(aSrcLen) do
              CheckEquals(aSrcBuf^[anInx], aDestBuf^[anInx],
                          format('BLOB 1 mismatch, position %d', [anInx]));

          finally
            FFFreeMem(aSrcBuf, aSrcLen);
            FFFreeMem(aDestBuf, aDestLen);
          end;
        end;
      finally
        FFFreeMem(aSrcRec, Dict.RecordLength);
        FFFreeMem(aDestRec, Dict.RecordLength);
      end;

    finally
      aCursor2.Free;
    end;

  finally
    aCursor.Free;
    Dict.Free;
    FEngine.TableList.RemoveUnusedTables;

    { Get rid of any tables that might be lying around. }
    FEngine.TableDelete(FDB.DatabaseID, cPersistName);
  end;

end;
{====================================================================}

{===TffTestCursors===================================================}
procedure TffTestCursors.Setup;
begin
  inherited Setup;
  FClient := TffClient.Create(nil);
  FClient.ServerEngine := FEngine;
  FClient.AutoClientName := True;
//  FClient.ClientName := 'FClient' + intToStr(GetCurrentThreadID);
  FClient.Timeout := clClientTimeout;
  FClient.Active := True;

  FSession := TffSession.Create(nil);
  FSession.ClientName := FClient.ClientName;
  FSession.AutoSessionName := True;
//  FSession.SessionName := 'FSession' + intToStr(GetCurrentThreadID);
  FSession.Timeout := clSessionTimeout;
  FSession.Active := True;

  { Assumption: csAliasDir is always a path. }
  FDB := TffDatabase.Create(nil);
  FDB.SessionName := FSession.SessionName;
  FDB.DatabaseName := 'FDB';
  FDB.Timeout := clDBTimeout;
  FDB.AliasName := csAliasDir;

  FTable := TffTable.Create(nil);
  FTable.DatabaseName := FDB.DatabaseName;
  FTable.SessionName := FDB.SessionName;
  FTable.TableName := csContacts;
  FTable.Timeout := clTableTimeout;

  FTable2 := TffTable.Create(nil);
  FTable2.DatabaseName := FDB.DatabaseName;
  FTable2.SessionName := FDB.SessionName;
  FTable2.TableName := csContacts;
  FTable2.Timeout := clTableTimeout;

end;
{--------}
procedure TffTestCursors.PrepareContactTable;
var
  Dict : TffDataDictionary;
begin
  { Make sure Contacts table exists. }
  Dict := CreateContactDict;
  try
    FDB.CreateTable(True, csContacts, Dict);
  finally
    { Make sure renamed Contacts table is deleted. }
    if FileExists(csAliasDir + '\' + csContactsRen + '.' + ffc_ExtForData) then
      FFTblHlpDelete(csAliasDir, csContactsRen, Dict);
    Dict.Free;
  end;

end;
{--------}
procedure TffTestCursors.Teardown;
begin
  FTable2.Free;
  FTable.Free;
  FDB.Free;
  FSession.Free;
  FClient.Free;
  inherited Teardown;
end;
{--------}
procedure TffTestCursors.test2CursorEditAfterDelete;
var
  anID : longInt;
  ExceptRaised : boolean;
begin
  PrepareContactTable;

  { Add a contact. }
  FTable.Open;
  InsertRandomContactsSameAge(FTable, 30, 1);

  { Position the first cursor to the contact. }
  FTable.First;
  anID := FTable.fieldByName('ID').asInteger;

  { Open a second cursor, position to the record, and delete
    the record. }
  with FTable2 do begin
    Open;
    First;
    CheckEquals(anID, FTable2.FieldByName('ID').asInteger,
                 'Cursors not on same record.');
    Delete;
  end;

  { What happens when the first cursor tries to edit the record? }
  ExceptRaised := False;
  try
    FTable.Edit;
  except
    on E:EffDatabaseError do
      { We should get a record/key deleted exception. }
      ExceptRaised := (E.ErrorCode = DBIERR_KEYORRECDELETED);
  end;

  Assert(ExceptRaised, 'Expected exception was not raised.');
end;
{--------}
procedure TffTestCursors.testBookmarkOnCrack;
var
  prevID : longInt;
  testPrevID : longInt;
  nextID : longInt;
  testNextID : longInt;
  bkmBuffer : PffByteArray;
  recBuffer : PffByteArray;
  Dict : TffDataDictionary;
  IsNull : boolean;

begin
  PrepareContactTable;
  Dict := nil;

  FTable.Open;

  { Add 10 contacts.  Specify unique index. }
  InsertRandomContactsSameAge(FTable, 30, 10);

  with FTable do begin
    IndexName := csPrimary;
    { Position to contact #5.  Get IDs of previous & next contacts. }
    First;
    Next;
    Next;
    Next;
    prevID := fieldByName('ID').asInteger;
    Next;
    Next;
    nextID := fieldByName('ID').asInteger;
    Prior;

    { Note: From this point onwards, we need to use the TffBaseServerEngine
            API because the VCL will do stuff behind the scenes that prevents
            us from really testing the functionality. }
    { Delete contact #5. }
    FEngine.RecordDelete(FTable.CursorID, nil);

    { Obtain a bookmark.  Should return a bookmark on the crack. }
    FFGetMem(bkmBuffer, ffcl_FixedBookmarkSize);
    try
      FEngine.CursorGetBookmark(FTable.CursorID, bkmBuffer);

      { Position to BOF and then position back to the bookmark. }
      First;
      FEngine.CursorSetToBookmark(FTable.CursorID, bkmBuffer);

      { Verify that previous and next contacts are what we expect. }
      Dict := FTable.Dictionary;
      FFGetMem(recBuffer, Dict.RecordLength);
      FEngine.RecordGetPrior(FTable.CursorID, ffltNoLock, recBuffer);

      { Grab the ID field out of the record buffer.  Is it what we expect? }
      Dict.GetRecordField(0, recBuffer, IsNull, @testPrevID);
      CheckEquals(prevID, testPrevID, 'Invalid Prior contact');

      FEngine.RecordGetNext(FTable.CursorID, ffltNoLock, recBuffer);
      Dict.GetRecordField(0, recBuffer, IsNull, @testNextID);
      CheckEquals(nextID, testNextID, 'Invalid Next contact');
    finally
      FFFreeMem(bkmBuffer, ffcl_FixedBookmarkSize);
      FFFreeMem(recBuffer, Dict.RecordLength);
    end;
  end;

  FTable.Close;

end;
{--------}
procedure TffTestCursors.testInsertIntoRange;
  { Issue 3712 }
const
  cFile = 'TestRange';
  ExpectedKeys : array[1..7] of string = ('1', '2', '2', '2', '2', '3', '4');
var
  i : Integer;
  tbl : TffTable;
begin
  { Test resolution for issue 3712. If range is active & inserted record
    does not match the range then record should not be in the result set. }
  { First, create the table to be used for the test. }
  { Copy the source table from the source directory and ensure it's
    read-only flag is not set. }
  Windows.CopyFile(csSourceDir + '\sav' + cFile + '.FF2',
           csAliasDir + '\' + cFile + '.FF2', False);
  FileSetAttr(csAliasDir + '\' + cFile + '.FF2', 0);

  tbl := TffTable.Create(nil);
  try
    { Set up the table. }
    tbl.DatabaseName := FDB.DatabaseName;
    tbl.SessionName := FSession.SessionName;
    tbl.TableName := cFile;
    tbl.IndexName := 'iKey';

    { Open the table & set a range. }
    tbl.Open;
    tbl.SetRange(['8'], ['8']);
    CheckEquals(0, tbl.RecordCount, 'Unexpected record count when range is set');
    Check(tbl.EOF, 'Not at EOF prior to first insert');

    { Insert a record that does not fit into the range. }
    tbl.Insert;
    tbl.FieldByName('key').AsString := '9';
    tbl.Post;
    CheckEquals(0, tbl.RecordCount, 'Unexpected record count after inserting record');
    Check(tbl.EOF, 'Not at EOF after first insert');

    { Delete the record just inserted. }
    tbl.CancelRange;
    tbl.Last;
    CheckEquals('9', tbl.FieldByName('key').AsString,
                'Did not find record just inserted.');
    tbl.Delete;

    { Now set a range that allows records with keys 1 through 4. Walk through
      them & at each record, insert a record that does not fit into the range.
      Verify that we can continue to walk through the records without skipping
      any of the records in the range. }
    tbl.SetRange(['1'], ['4']);
    CheckEquals(High(ExpectedKeys), tbl.RecordCount,
                'Unexpected record count for traversal range');
    i := 1;
    while not tbl.EOF do begin
      CheckEquals(ExpectedKeys[i], tbl.FieldByName('Key').AsString,
                  Format('Unexpected key value for record %d while ' +
                         'traversing range', [i]));
      tbl.Insert;
      tbl.FieldByName('key').AsString := IntToStr(900 + i);
      tbl.Post;
      CheckEquals(High(ExpectedKeys), tbl.RecordCount,
                  'Unexpected record count after inserting record for traversal range');
      tbl.Next;
      inc(i);
    end;  { while }
  finally
    tbl.Free;
  end;

end;
{--------}
procedure TffTestCursors.testOnCrackAfterDeleteUInx;
var
  prevID : longInt;
  nextID : longInt;
begin
  PrepareContactTable;

  FTable.Open;

  { Add 10 contacts.  Specify unique index. }
  InsertRandomContactsSameAge(FTable, 30, 10);

  with FTable do begin
    IndexName := csPrimary;
    { Position to contact #5.  Get IDs of previous & next contacts. }
    First;
    Next;
    Next;
    Next;
    prevID := fieldByName('ID').asInteger;
    Next;
    Next;
    nextID := fieldByName('ID').asInteger;
    Prior;

    { Delete contact #5. }
    Delete;

    { Verify that previous and next contacts are what we expect. }
    Prior;
    CheckEquals(prevID, fieldByName('ID').asInteger,
                 'Invalid Prior contact');
    Next;
    CheckEquals(nextID, fieldByName('ID').asInteger,
                 'Invalid Next contact');
  end;

  FTable.Close;

end;
{--------}
procedure TffTestCursors.testOnCrackAfterDeleteNUInx;
var
  prevID : longInt;
  nextID : longInt;
begin
  PrepareContactTable;

  FTable.Open;

  { Add 10 contacts.  Specify unique index. }
  InsertRandomContactsSameAge(FTable, 30, 10);

  with FTable do begin
    IndexName := csByAge;
    { Position to contact #5.  Get IDs of previous & next contacts. }
    First;
    Next;
    Next;
    Next;
    prevID := fieldByName('ID').asInteger;
    Next;
    Next;
    nextID := fieldByName('ID').asInteger;
    Prior;

    { Delete contact #5. }
    Delete;

    { Verify that previous and next contacts are what we expect. }
    Prior;
    CheckEquals(prevID, fieldByName('ID').asInteger,
                 'Invalid Prior contact');
    Next;
    CheckEquals(nextID, fieldByName('ID').asInteger,
                 'Invalid Next contact');
  end;

end;
{--------}
procedure TffTestCursors.testLocateDelWithIndex;
const
  csAgeToDel = 30;
  csNumRecs = 2500;
var
  DelCount, ExpectedCount : integer;
begin
  PrepareContactTable;
  FTable.Open;
  try
    InsertRandomContacts(FTable, csNumRecs);
    with FTable do begin
      { Note that we do not switch from the Sequential Access Index.
        We want the locate to use a lookup cursor. }

      DelCount := 0;
      ExpectedCount := 0;

      { We will delete every record having Age = 30.
        Figure out how many records we will delete. }
      First;
      while not EOF do begin
        if FieldByName('Age').AsInteger = csAgeToDel then
          inc(ExpectedCount);
        Next;
      end;
      First;

      { Now delete the records. }
      while Locate('Age', csAgeToDel, []) do begin
        Delete;
        inc(DelCount);
        if DelCount > ExpectedCount then
          break;
      end;

      { Verify the # deleted is what we expected. }
      CheckEquals(ExpectedCount, DelCount,
                  'Did not delete expected # records.');

      { Verify that the table's record count is what we expect. }
      CheckEquals(csNumRecs - ExpectedCount, FTable.RecordCount,
                  'Invalid record count');
    end;
  finally
    FTable.Close;
  end;

end;
{--------}
procedure TffTestCursors.testLocateDelNoIndex;
const
  csDecMakerToDel = false;
  csNumRecs = 500;
var
  DelCount, ExpectedCount : integer;
begin
  PrepareContactTable;
  FTable.Open;
  try
    InsertRandomContacts(FTable, 500);
    with FTable do begin
      { Note that we do not switch from the Sequential Access Index.
        We want the locate to use a lookup cursor. }

      DelCount := 0;
      ExpectedCount := 0;

      { We will delete every record having Age = 30.
        Figure out how many records we will delete. }
      First;
      while not EOF do begin
        if FieldByName('DecisionMaker').AsBoolean = csDecMakerToDel then
          inc(ExpectedCount);
        Next;
      end;
      First;

      { Now delete the records. }
      while Locate('DecisionMaker', csDecMakerToDel, []) do begin
        Delete;
        inc(DelCount);
        if DelCount > ExpectedCount then
          break;
      end;

      { Verify the # deleted is what we expected. }
      CheckEquals(ExpectedCount, DelCount,
                  'Did not delete expected # records.');

      { Verify that the table's record count is what we expect. }
      CheckEquals(csNumRecs - ExpectedCount, FTable.RecordCount,
                  'Invalid record count');

    end;
  finally
    FTable.Close;
  end;
end;
{--------}
procedure TffTestCursors.testDeleteAllRecsInRange;
const
  TestTblName = 'coleta';
var
  TheTable : TffTable;
  S        : array[1..5] of string;
  DtStart  : TDateTime;
  DtFinish : TDateTime;
  j        : Integer;
  RecCount : Integer;
begin
  { Note: See Bug 720 for more info about this test. }

  { Copy the source table from the source directory and ensure it's
    read-only flag is not set. Note that the table uses external
    indexes.}
  Windows.CopyFile(csSourceDir + '\' + TestTblName + '.FF2',
           csAliasDir + '\' + TestTblName + '.FF2', False);
  FileSetAttr(csAliasDir + '\' + TestTblName + '.FF2', 0);
  Windows.CopyFile(csSourceDir + '\' + TestTblName + '.IX1',
           csAliasDir + '\' + TestTblName + '.IX1', False);
  FileSetAttr(csAliasDir + '\' + TestTblName + '.IX1', 0);
  Windows.CopyFile(csSourceDir + '\' + TestTblName + '.IX2',
           csAliasDir + '\' + TestTblName + '.IX2', False);
  FileSetAttr(csAliasDir + '\' + TestTblName + '.IX2', 0);
  Windows.CopyFile(csSourceDir + '\' + TestTblName + '.IX3',
           csAliasDir + '\' + TestTblName + '.IX3', False);
  FileSetAttr(csAliasDir + '\' + TestTblName + '.IX3', 0);

  if FEngine is TffServerEngine then
    TffServerEngine(FEngine).BufferManager.MaxRAM := 50;

  TheTable := TffTable.Create(nil);
  try
    TheTable.DatabaseName := FDB.DatabaseName;
    TheTable.SessionName := FDB.SessionName;
    TheTable.TableName := TestTblName;
    TheTable.Timeout := clTableTimeout;
    TheTable.Open;

    { Set a variety of ranges and delete all records in each range. }
    TheTable.IndexName := 'is_ped';
    DtStart := EncodeDate(2000, 7, 1);
    DtFinish := EncodeDate(2000, 7, 10);
    S[1] := '02';
    S[2] := '04';
    S[3] := '05';
    S[4] := '07';
    S[5] := '12';
    for j := 1 to 5 do begin
      TheTable.SetRange(['BHZ', S[J], DtStart], ['BHZ', S[J], DtFinish]);
      TheTable.Database.StartTransaction;
      try
        while (not TheTable.Eof) do
          TheTable.Delete;
        TheTable.Refresh;
        { Ensure all records in range were deleted. }
        Assert(TheTable.Eof, 'The table should be at EOF, but isn''t');
        Assert(TheTable.IsEmpty, 'RecordCount should be 0, but isn''t');
        Assert(TheTable.RecordCount = 0, 'RecordCount should be 0, but isn''t');
        TheTable.Database.Commit;
      except
        TheTable.Database.Rollback;
        Assert(False, 'Exception: Something went wrong');
      end;
      TheTable.CancelRange;
    end;

    { Do the same thing again in the reverse order.
      -- we need a fresh table for this. }
    TheTable.Close;
    FDB.Close;

    Check(Windows.CopyFile(csSourceDir + '\' + TestTblName + '.FF2',
                   csAliasDir + '\' + TestTblName + '.FF2', False),
          'Could not copy ' + TestTblName);
    FileSetAttr(csAliasDir + '\' + TestTblName + '.FF2', 0);
    Windows.CopyFile(csSourceDir + '\' + TestTblName + '.IX1',
             csAliasDir + '\' + TestTblName + '.IX1', False);
    FileSetAttr(csAliasDir + '\' + TestTblName + '.IX1', 0);
    Windows.CopyFile(csSourceDir + '\' + TestTblName + '.IX2',
             csAliasDir + '\' + TestTblName + '.IX2', False);
    FileSetAttr(csAliasDir + '\' + TestTblName + '.IX2', 0);
    Windows.CopyFile(csSourceDir + '\' + TestTblName + '.IX3',
             csAliasDir + '\' + TestTblName + '.IX3', False);
    FileSetAttr(csAliasDir + '\' + TestTblName + '.IX3', 0);

    FDB.Open;
    TheTable.Open;

    for j := 1 to 5 do begin
      TheTable.SetRange(['BHZ', S[J], DtStart], ['BHZ', S[J], DtFinish]);
      TheTable.Database.StartTransaction;
      try
        TheTable.Last;
        while (not TheTable.Bof) do
          TheTable.Delete;
        { Ensure all records in range were deleted. }
        Assert(TheTable.Bof, 'The table should be at BOF, but isn''t');
        Assert(TheTable.RecordCount = 0, 'RecordCount should be 0, but isn''t');
        TheTable.Database.Commit;
      except
        TheTable.Database.Rollback;
        Assert(False, 'Exception: Something went wrong');
      end;
      TheTable.CancelRange;
    end;

    TheTable.Close;
    FDB.Close;

    { Now test forwards delete split into multiple transactions. }
    Check(Windows.CopyFile(csSourceDir + '\' + TestTblName + '.FF2',
                   csAliasDir + '\' + TestTblName + '.FF2', False),
          'Could not copy ' + TestTblName);
    FileSetAttr(csAliasDir + '\' + TestTblName + '.FF2', 0);
    Windows.CopyFile(csSourceDir + '\' + TestTblName + '.IX1',
             csAliasDir + '\' + TestTblName + '.IX1', False);
    FileSetAttr(csAliasDir + '\' + TestTblName + '.IX1', 0);
    Windows.CopyFile(csSourceDir + '\' + TestTblName + '.IX2',
             csAliasDir + '\' + TestTblName + '.IX2', False);
    FileSetAttr(csAliasDir + '\' + TestTblName + '.IX2', 0);
    Windows.CopyFile(csSourceDir + '\' + TestTblName + '.IX3',
             csAliasDir + '\' + TestTblName + '.IX3', False);
    FileSetAttr(csAliasDir + '\' + TestTblName + '.IX3', 0);

    FDB.Open;
    TheTable.Open;
    for j := 1 to 5 do begin
      RecCount := 0;
      TheTable.SetRange(['BHZ', S[J], DtStart], ['BHZ', S[J], DtFinish]);
      TheTable.Database.StartTransaction;
      try
        while (not TheTable.Eof) do begin
          TheTable.Delete;
          inc(RecCount);
          if RecCount mod 1000 = 0 then begin
            TheTable.Database.Commit;
            TheTable.Database.StartTransaction;
          end;
        end;  { while }
        { Ensure all records in range were deleted. }
        Assert(TheTable.Eof, 'The table should be at EOF, but isn''t');
        Assert(TheTable.IsEmpty, 'RecordCount should be 0, but isn''t');
        Assert(TheTable.RecordCount = 0, 'RecordCount should be 0, but isn''t');
        if TheTable.Database.InTransaction then
          TheTable.Database.Commit;
      except
        TheTable.Database.Rollback;
        Assert(False, 'Exception: Something went wrong');
      end;
      TheTable.CancelRange;
    end;

  finally
    TheTable.Free;
  end;
end;
{--------}
procedure TffTestCursors.testModifyRecordsInRange;
const
  TestTblName = 'RangeTest';
var
  TheTable : TffTable;
begin
  { There are 4 situations to test:
    -- #1: Modify a record in the middle of a range to a value
           outside of the range.
    -- #2: Modify the 1st record in a dataset to a value outside of
           the range.
    -- #3: Modify the last record in a dataset to a value outside of
           the range.
    -- #4: Modify the only record in a range to a value outside the
           range.
    -- #5: Modify a record in the middle of a range so that it is still
           in the range.

    NOTE: See bug 826 for more information and examples. }

  { Copy the source table from the source directory and ensure it's
    read-only flag is not set. }
  Windows.CopyFile(csSourceDir + '\' + TestTblName + '.FF2',
           csAliasDir + '\' + TestTblName + '.FF2', False);
  FileSetAttr(csAliasDir + '\' + TestTblName + '.FF2', 0);

  { Prep the table. }
  TheTable := TffTable.Create(nil);
  try
    TheTable.DatabaseName := FDB.DatabaseName;
    TheTable.SessionName := FDB.SessionName;
    TheTable.TableName := TestTblName;
    TheTable.Timeout := clTableTimeout;
    TheTable.IndexName := 'idxStringVal';
    TheTable.Open;

    { Table's initial state:
        RecordCount 5 - 'F', 'I', 'K', 'S', 'U' }

    { Prepare table for Test #1 }
    TheTable.SetRange(['I'], ['S']);
    { RecordCount = 3: 'F', ['I', 'K', 'S'], 'U' }
    Assert(TheTable.RecordCount = 3,
           'Test #1 Prep: Test range didn''t set properly');

    { Test #1: Change 'K' to 'Y'.
      -- RecordCount should go to 2 and we should be setting on 'S' }
    Assert(TheTable.FindKey(['K']),
           'Test #1: Couldn''t find "K" in test table.');
    TheTable.Edit;
    TheTable.FieldByName('StringValue').AsString := 'Y';
    TheTable.Post;
    Assert(TheTable.RecordCount = 2,
           'Test #1: Table didn''t update range correctly');
    Assert(TheTable.FieldByName('StringValue').AsString = 'S',
           'Test #1: Table is positioned on wrong record');

    { Prepare table for test #2. }
    TheTable.CancelRange;
    TheTable.SetRange(['I'], ['U']);
    { RecordCount = 3: 'F', ['I', 'S', 'U'], 'Y' }
    Assert(TheTable.RecordCount = 3,
           'Test #2 Prep: Test range didn''t set properly');

    { Test #2: Change 'I' to 'B'.
      -- RecordCount should go to 2 and we should be setting on 'S' }
    Assert(TheTable.FindKey(['I']),
           'Test #2: Couldn''t find "I" in test table.');
    TheTable.Edit;
    TheTable.FieldByName('StringValue').AsString := 'B';
    TheTable.Post;
    Assert(TheTable.RecordCount = 2,
           'Test #2: Table didn''t update range correctly');
    Assert(TheTable.FieldByName('StringValue').AsString = 'S',
           'Test #2: Table is positioned on wrong record');

    { Prepare table for test #3. }
    TheTable.CancelRange;
    TheTable.SetRange(['F'], ['Y']);
    { RecordCount = 4: 'B', ['F', 'S', 'U', 'Y'] }
    Assert(TheTable.RecordCount = 4,
           'Test #3 Prep: Test range didn''t set properly');

    { Test #3: Change 'Y' to 'Z'.
      -- RecordCount should go to 3 and we should be setting on EOF,
         but not BOF }
    Assert(TheTable.FindKey(['Y']),
           'Test #3: Couldn''t find "S" in test table.');
    TheTable.Edit;
    TheTable.FieldByName('StringValue').AsString := 'Z';
    TheTable.Post;
    Assert(TheTable.RecordCount = 3,
           'Test #3: Table didn''t update range correctly');
    Assert(TheTable.FieldByName('StringValue').AsString = 'U',
           'Test #3: Table should be positioned on EOF');

    { Prepare table for test #4.
      -- Do a little more testing on the way. }
    { RecordCount = 3: 'B', ['F', 'S', 'U'], 'Z' }
    Assert(TheTable.FindKey(['S']),
           'Test #4 Prep(1): Couldn''t find "S" in test table.');
    TheTable.Edit;
    TheTable.FieldByName('StringValue').AsString := 'C';
    TheTable.Post;
    Assert(TheTable.RecordCount = 2,
           'Test #4 Prep(1): Table didn''t update range correctly');
    Assert(TheTable.FieldByName('StringValue').AsString = 'U',
           'Test #4 Prep(1):  Table is positioned on wrong record');
    { RecordCount = 2: 'B', 'C', ['F', 'U'], 'Z' }
    Assert(TheTable.FindKey(['U']),
           'Test #4 Prep(2): Couldn''t find "U" in test table.');
    TheTable.Edit;
    TheTable.FieldByName('StringValue').AsString := 'D';
    TheTable.Post;
    Assert(TheTable.RecordCount = 1,
           'Test #4 Prep(2): Table didn''t update range correctly');
    Assert(TheTable.FieldByName('StringValue').AsString = 'F',
           'Test #4 Prep(2): Table is positioned on wrong record');
    { RecordCount = 2: 'B', 'C', 'D', ['F'], 'Z' }

    { Test #4: Change 'F' to 'E'.
      -- RecordCount should go to 0 and we should be setting on EOF
         and BOF. }
    Assert(TheTable.FindKey(['F']),
           'Test #4:Couldn''t find "F" in test table.');
    TheTable.Edit;
    TheTable.FieldByName('StringValue').AsString := 'E';
    TheTable.Post;
    Assert(TheTable.RecordCount = 0,
           'Test #4: Table didn''t update range correctly');
    Assert(TheTable.EOF,
           'Test #4: Table not at EOF');
    Assert(TheTable.BOF,
           'Test #4: Table not at BOF');

    { Prepare table for test #5 }
    TheTable.CancelRange;
    TheTable.SetRange(['A'],['E']);
    { RecordCount = 4: ['B', 'C', 'D', 'E'], 'Z'] }
    Assert(TheTable.RecordCount = 4,
           'Test #5 Prep: Test range didn''t set properly');

    { Test #5: Change 'D' to 'A'
      -- RecordCount should be the same and we should be positioned
         on 'A' }
    Assert(TheTable.FindKey(['D']),
           'Test #5: Could not find "D" in test table.');
    TheTable.Edit;
    TheTable.FieldByName('StringValue').AsString := 'A';
    TheTable.Post;
    CheckEquals(4, TheTable.RecordCount,
                'Test #5: Table did not update range correctly');
    CheckEquals('A', TheTable.FieldByName('StringValue').AsString,
                'Test #5: Cursor not positioned properly after changed posted.');

  finally
    TheTable.Free;
  end;
end;
{--------}
procedure TffTestCursors.testMultiTableInstancesOnOneTable;
var
  Log : TffEventLog;
  RecNum : Integer;
begin
  Log := TffEventLog.Create(nil);
  Log.FileName := ExtractFilePath(Application.ExeName) + 'multi.log';
  Log.Enabled := False;  { Set to True for debugging }
  RecNum := 0;

  PrepareContactTable;
  FTable.Timeout := 5000;
  FTable.Open;
    { Will be used to add new records. }
  InsertRandomContacts(FTable, 10000);
  try
    FTable.IndexName := 'primary';
    FTable2.Timeout := 5000;
    FTable2.Open;
      { Will be used to edit or delete existing records. }
    FTable2.IndexName := csByAge;

    Log.WriteString('*** Starting ***');
    FTable.First;
    while not FTable.EOF do begin

      inc(RecNum);

      { Add situation? }
      FTable2.First;
      if (FTable.FieldByName('age').AsInteger <= 100) and
         (FTable.FieldByName('age').AsInteger mod 2 = 0) and
         (not FTable2.FindKey([FTable.FieldByName('age').asInteger + 50])) then begin
        Log.WriteStringFmt('%d : Append new record for age %d',
                           [RecNum, FTable.FieldByName('age').asInteger + 50]);
        FTable2.Append;
        FTable2.FieldByName('FirstName').AsString := 'new';
        FTable2.FieldByName('LastName').AsString := 'entry';
        FTable2.FieldByName('Age').AsInteger := FTable.FieldByName('age').AsInteger + 50;
        FTable2.FieldByName('State').AsString := 'xx';
        FTable2.FieldByName('DecisionMaker').AsBoolean := False;
        FTable2.FieldByName('BirthDate').AsDateTime := Date;
        FTable2.Post;
      end;

      { Edit or delete situation? Deletes those with ages divisible by 2 or 3. }
      if (FTable.FieldByName('age').AsInteger mod 2 = 0) or
         (FTable.FieldByName('age').AsInteger mod 3 = 0) then begin
        Log.WriteStringFmt('%d : Edit record, age = %d',
                           [RecNum, FTable.FieldByName('age').asInteger]);
        FTable.Edit;
        FTable.FieldByName('State').AsString := 'ev';
        FTable.Post;
        FTable.Next;
      end
      else begin
        Log.WriteStringFmt('%d : Delete record, age = %d',
                           [RecNum, FTable.FieldByName('age').asInteger]);
        FTable.Delete;
      end;
    end;
  finally
    Log.WriteString('*** Finished ***');
    FTable.Close;
    FTable2.Close;
    Log.Free;
  end;
end;
{--------}
procedure TffTestCursors.testMultiTableInstancesInOneTransaction;
begin
  PrepareContactTable;
  FTable.Timeout := 500000;
  FTable.Open;
  { Will be used to add new records. }
  InsertRandomContacts(FTable, 100);
  try
    { Reposition FTable to first record. }
    FTable.First;
    FTable2.Timeout := 500000;
    FTable2.Open;

    FTable.Database.StartTransaction;
    try
      FTable.Edit;
      FTable.FieldByName('LastName').AsString := 'test1';
      FTable.Post;

      FTable2.Edit;
      FTable2.FieldByName('LastName').AsString := 'test2';
      FTable2.Post;
    finally
      FTable.Database.Commit;
    end;

    FTable.Refresh;
    CheckEquals('test2', FTable.FieldByName('LastName').AsString,
                'Unexpected value for table 1');
    CheckEquals('test2', FTable2.FieldByName('LastName').AsString,
                'Unexpected value for table 2');
  finally
    FTable.Close;
    FTable2.Close;
  end;
end;
{====================================================================}

initialization
  RegisterTest('SQL result sets', TffTestSQLResultSet.Suite);
  RegisterTest('Cursors', TffTestCursors.Suite);
end.

