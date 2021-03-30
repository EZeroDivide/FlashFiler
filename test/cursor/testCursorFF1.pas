unit testCursorFF1;

interface

uses
  FFDB,
  Dunit;

type
  TffTestCursors = class(TTestCase)
  protected
    FClient : TffCommsEngine;
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

    procedure testOnCrackAfterDeleteUInx;
      { Given a unique index, verifies that a cursor is positioned on the
        crack between the two records surrounding a record just deleted by
        the cursor. }

    procedure testOnCrackAfterDeleteNUInx;
      { Given a non-unique index, verifies that a cursor is positioned on the
        crack between the two records surrounding a record just deleted by
        the cursor. }

  end;

function Suite :ITestSuite;

implementation

uses
  Dialogs,
  DB,
  SysUtils,
  Windows,
  ContactU,
  FFClIntf,
  FFDBBase,
  FFLLBase,
  FFLLDict,
  FFSrEng,
  FFTbBase;

const
  csAliasDir = 'c:\temp';
  csByAge = 'byAge';
  csContacts = 'Contacts';
  csContactsRen = 'ContactsRen';
  csEmail = 'Email';
  csPrimary = 'Primary';

  { Timeout constants }
  clClientTimeout = 50000;
  clSessionTimeout = 50000;
  clDBTimeout = 50000;
  clTableTimeout = 500000;


function suite :ITestSuite;
begin
  Result := TTestSuite.create('Cursor Tests');
  Result.AddTest(testSuiteOf(TffTestCursors));
end;

{===TffTestCursors===================================================}
procedure TffTestCursors.Setup;
begin
  inherited Setup;
  FClient := TffCommsEngine.Create(nil);
  FClient.CommsEngineName := 'FClient' + intToStr(GetCurrentThreadID);
  FClient.Active := True;

  FSession := TffSession.Create(nil);
  FSession.CommsEngineName := FClient.CommsEngineName;
  FSession.SessionName := 'FSession' + intToStr(GetCurrentThreadID);
  FSession.Active := True;

  { Assumption: csAliasDir is always a path. }
  FDB := TffDatabase.Create(nil);
  FDB.SessionName := FSession.SessionName;
  FDB.DatabaseName := 'FDB';
  FDB.AliasName := csAliasDir;

  FTable := TffTable.Create(nil);
  FTable.DatabaseName := FDB.DatabaseName;
  FTable.SessionName := FDB.SessionName;
  FTable.TableName := csContacts;

  FTable2 := TffTable.Create(nil);
  FTable2.DatabaseName := FDB.DatabaseName;
  FTable2.SessionName := FDB.SessionName;
  FTable2.TableName := csContacts;

end;
{--------}
procedure TffTestCursors.PrepareContactTable;
var
  Dict : TffDataDictionary;
  FldArray : TffFieldList;
begin

  { Make sure Contacts table exists. }

  Dict := TffDataDictionary.Create(32768);
  try
    with Dict do begin

      { Add fields }
      AddField('ID', '', fftAutoInc, 0, 0, false);
      AddField('FirstName', '', fftShortString, 25, 0, true);
      AddField('LastName', '', fftShortString, 25, 0, true);
      AddField('Age', '', fftInt16, 5, 0, false);
      AddField('State', '', fftShortString, 2, 0, false);
      AddField('DecisionMaker', '', fftBoolean, 0, 0, false);

      { Add indexes }
      FldArray[0] := 0;
      AddIndex('primary', '', 0, 1, FldArray, False, True, True);

      FldArray[0] := 2;
      AddIndex('byLastName', '', 0, 1, FldArray, True, True, True);

      FldArray[0] := 1;
      AddIndex('byFirstName', '', 0, 1, FldArray, True, True, True);

      FldArray[0] := 3;
      AddIndex(csByAge, '', 0, 1, FldArray, True, True, True);

      FldArray[0] := 4;
      AddIndex('byState', '', 0, 1, FldArray, True, True, True);

      FldArray[0] := 1;
      FldArray[1] := 2;
      AddIndex('byFullName', '', 0, 2, FldArray, True, True, True);

      FldArray[0] := 3;
      FldArray[1] := 4;
      AddIndex('byAgeState', '', 0, 2, FldArray, True, True, True);

      FldArray[0] := 4;
      FldArray[1] := 3;
      AddIndex('byStateAge', '', 0, 2, FldArray, True, True, True);

      FldArray[0] := 5;
      AddIndex('byDecisionMaker', '', 0, 1, FldArray, True, True, True);

      FldArray[0] := 3;
      FldArray[1] := 4;
      AddIndex('byAgeDecisionMaker', '', 0, 2, FldArray, True, True, True);

    end;

    FFDBICreateTable(FDB.Handle, True, csContacts, Dict);
  finally
    Dict.Free;
  end;

  { Make sure renamed Contacts table is deleted. }
  FFTblHlpDelete(csAliasDir, csContactsRen)

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
    assertEquals(anID, FTable2.FieldByName('ID').asInteger,
                 'Cursors not on same record.');
    Delete;
  end;

  { What happens when the first cursor tries to edit the record? }
  try
    FTable.Edit;
  except
    on E:EffDatabaseError do
      ShowMessage(format('Exception (%d) %s',[E.ErrorCode, E.Message]));
    on E:Exception do
      showMessage(format('Exception %s', [E.message]));
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
    assertEquals(prevID, fieldByName('ID').asInteger,
                 'Invalid Prior contact');
    Next;
    assertEquals(nextID, fieldByName('ID').asInteger,
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
    assertEquals(prevID, fieldByName('ID').asInteger,
                 'Invalid Prior contact');
    Next;
    assertEquals(nextID, fieldByName('ID').asInteger,
                 'Invalid Next contact');
  end;

end;
{====================================================================}

end.
