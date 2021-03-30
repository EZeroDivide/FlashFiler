unit testDBThread;

interface

uses
  TestFramework,
  baseTestCase,
  fflllgcy,
  ffLLLog,
  dialogs;

type
  TffDBTest = class(TffBaseTest)
  protected
    procedure PrepareContactTable;
    procedure PrepareEmailTable;
    procedure testSingleThreadInsertPrim(const recCount, recsPerTran : longInt);
  public
    {$WARNINGS OFF}
    constructor Create(Name: string);
    {$WARNINGS ON}
  published

    {==========  Database tests =========================}
    procedure testDBOpenBothExcl; virtual;
      { Verify that only one client may open a given database exclusively. }
    procedure testDBOpenExclNonExcl; virtual;
      { Verify that Client A may open database exclusively and that Client B
        is not able to access the database when it asks for non-exclusive
        access. }
    procedure testDBOpenBothNonExcl; virtual;
      { Verify that Client A and Client B may both open a database in
        non-exclusive mode. }
    procedure testDBOpenNonExclExcl; virtual;
      { Verify that if Client A opens the database non-exclusively then
        Client B cannot open the database exclusively. }
    procedure testDBROTableRW; virtual;
      { Verify that Client A cannot open a table in read-write mode after
        it has opened the parent database in read-only mode. }
    procedure testDBROTableRO; virtual;
      { Verify that Client A can open a table in read-only mode after
        it has opened the parent database in read-only mode. }
    procedure testTableRWTableDel; virtual;
      { Verify that while Client A has table 1 open, Client B may not delete
        that table. }
    procedure testTableDelTableRw; virtual;
      { Verify that after Client A deletes Table 1, Client B cannot open
        Table 1. }
    procedure testTableRwTableRen; virtual;
      { Verify that while Client A has table 1 open, Client B may not rename
        that table. }
    procedure testTableRenTableRw; virtual;
      { Verify that after Client A renames Table 1, Client B cannot open
        Table 1 under its old name. }
    procedure testTableRenTableNewRw; virtual;
      { Verify that after Client A renames Table 1, Client B can open the table
        using its new name. }
    procedure testMultiOpenSameDB; virtual;
      { Verify that several clients can open/close a database repeatedly
        without problems. }
    procedure testMultiOpenMultiDB; virtual;
      { Verify that several clients can open/close various databases repeatedly
        without problems. }

    {==========  Table tests ============================}

    procedure testTblDropIndexTimeout; virtual;
      { Verify that if Client A opens a table and keeps it open, Client B will
        timeout if it attempts to drop an index on that table. }

    procedure testTblDropIndex; virtual;
      { Verify that Client B can drop an index on a table after waiting for
        exclusive access. }

    procedure testTblROMultRW; virtual;
      { Verify that if one client opens a table in read-only mode, other clients
        are still able to open the table in read-write mode. }

    procedure testTblRepeatOpenSame; virtual;
      { Verify that multiple clients may simultaneously open and close the same
        table. }

    procedure testTblRepeatOpenMulti; virtual;
      { Verify that multiple clients may simultaneously open and close 3
        different tables. }

    procedure testTblDeadlock; virtual;
      { Verify that a table deadlock is detected. }

    {==========  Object cleanup =========================}

    procedure testServerObjectCleanup; virtual;
      { Verify that server objects are cleaned up properly in the case
        where a client app closes the objects before the objects can
        legitimately be freed. }
        
    {==========  Cursor tests ===========================}

    procedure testSingleThreadInsert10k; virtual;
      { Verify that one thread can insert 10k records into the
        Contacts table. }

    procedure testMassInsert; virtual;
      { Verify that a large number of records can be inserted into the
        Contacts table. }

  end;

implementation

uses
  SysUtils,
  Windows,
  BaseThread,
  DBThread,
  ffdb,
  ffclreng,
  ffllBase,
  ffllDict,
  ffsrBde,
  ffllcomm,
  ffTbBase,
  ffsreng;

{$I FFCONST.INC}

const
  clTimeout = 60000;
  clTimeoutDelta = 1000;
  csAliasDir = 'e:\ff2db\test';
  csByAge = 'byAge';
  csContacts = 'Contacts';
  csContactsRen = 'ContactsRen';
  csEmail = 'Email';
  csPrimary = 'Primary';

{===TffDBTest========================================================}
constructor TffDBTest.Create(name : string);
begin
  inherited Create(name);
  FRemoteEngine := True;
end;
{--------}
procedure TffDBTest.PrepareContactTable;
var
  Dict : TffDataDictionary;
  FldArray : TffFieldList;
  IHArray : TffFieldIHList;
  FClient : TffClient;
  FSession : TffSession;
  FDB : TffDatabase;
begin

  { Make sure Contacts table exists. }

  FClient := TffClient.Create(nil);
  FClient.ServerEngine := FEngine;
  FClient.ClientName := 'FClient' + intToStr(GetCurrentThreadID);
  FClient.Active := True;

  FSession := TffSession.Create(nil);
  FSession.ClientName := FClient.ClientName;
  FSession.SessionName := 'FSession' + intToStr(GetCurrentThreadID);
  FSession.Active := True;

  FDB := TffDatabase.Create(nil);
  FDB.SessionName := FSession.SessionName;
  FDB.DatabaseName := 'FDB';
  FDB.AliasName := csAliasDir;
  FDB.Exclusive := False;
  FDB.Connected := True;

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

      { Add indexes }
      FldArray[0] := 0;
      IHArray[0] := '';
      AddIndex('primary', '', 0, 1, FldArray, IHArray, False, True, True);

      FldArray[0] := 2;
      IHArray[0] := '';
      AddIndex('byLastName', '', 0, 1, FldArray, IHArray, True, True, True);

      FldArray[0] := 1;
      IHArray[0] := '';
      AddIndex('byFirstName', '', 0, 1, FldArray, IHArray, True, True, True);

      FldArray[0] := 3;
      IHArray[0] := '';
      AddIndex(csByAge, '', 0, 1, FldArray, IHArray, True, True, True);

      FldArray[0] := 4;
      IHArray[0] := '';
      AddIndex('byState', '', 0, 1, FldArray, IHArray, True, True, True);

      FldArray[0] := 1;
      FldArray[1] := 2;
      IHArray[0] := '';
      IHArray[1] := '';
      AddIndex('byFullName', '', 0, 2, FldArray, IHArray, True, True, True);

      FldArray[0] := 3;
      FldArray[1] := 4;
      IHArray[0] := '';
      IHArray[1] := '';
      AddIndex('byAgeState', '', 0, 2, FldArray, IHArray, True, True, True);

      FldArray[0] := 4;
      FldArray[1] := 3;
      IHArray[0] := '';
      IHArray[1] := '';
      AddIndex('byStateAge', '', 0, 2, FldArray, IHArray, True, True, True);

      FldArray[0] := 5;
      IHArray[0] := '';
      AddIndex('byDecisionMaker', '', 0, 1, FldArray, IHArray, True, True, True);

      FldArray[0] := 3;
      FldArray[1] := 4;
      IHArray[0] := '';
      IHArray[1] := '';
      AddIndex('byAgeDecisionMaker', '', 0, 2, FldArray, IHArray, True, True, True);

    end;

    FDB.CreateTable(True, csContacts, Dict);

    { Make sure renamed Contacts table is deleted. }
    try
      FFTblHlpDelete(csAliasDir, csContactsRen, Dict)
    except
    end;

  finally
    Dict.Free;
    FDB.Connected := False;
    FDB.Free;
    FSession.Free;
    FClient.Free;
  end;

end;
{--------}
procedure TffDBTest.PrepareEmailTable;
var
  Dict : TffDataDictionary;
  FldArray : TffFieldList;
  IHArray : TffFieldIHList;
  FClient : TffClient;
  FSession : TffSession;
  FDB : TffDatabase;
begin

  { Make sure Contacts table exists. }

  FClient := TffClient.Create(nil);
  FClient.ServerEngine := FEngine;
  FClient.ClientName := 'FClient' + intToStr(GetCurrentThreadID);
  FClient.Active := True;

  FSession := TffSession.Create(nil);
  FSession.ClientName := FClient.ClientName;
  FSession.SessionName := 'FSession' + intToStr(GetCurrentThreadID);
  FSession.Active := True;

  FDB := TffDatabase.Create(nil);
  FDB.SessionName := FSession.SessionName;
  FDB.DatabaseName := 'FDB';
  FDB.AliasName := csAliasDir;
  FDB.Exclusive := False;
  FDB.Connected := True;

  Dict := TffDataDictionary.Create(65536);
  try
    with Dict do begin

      { Add fields }
      AddField('ContactID', '', fftAutoInc, 0, 0, true, nil);
      AddField('EmailAddress', '', fftShortString, 100, 0, true, nil);
      AddField('AsOf', '', fftDateTime, 0, 0, true, nil);

      { Add indexes }
      FldArray[0] := 0;
      IHArray[0] := '';
      AddIndex('primary', '', 0, 1, FldArray, IHArray, False, True, True);

    end;

    FDB.CreateTable(True, csEmail, Dict);
  finally
    Dict.Free;
    FDB.Connected := False;
    FDB.Free;
    FSession.Free;
    FClient.Free;
  end;

end;
{--------}
procedure TffDBTest.testDBOpenBothExcl;
var
  ClientA, ClientB : TffDBThread;
  HandleArray : array[0..1] of THandle;  { array of thread handles }
  PHandleArray : pointer;
begin
  ClientA := nil;
  ClientB := nil;
  try
    try
      ClientA := TffDBThread.Create('ClientA', csAliasDir, ffttmAsynch, FEngine);
      ClientA.FreeOnTerminate := False;
      ClientA.AddToFilter([ciDBOpenExcl, ciDBClose]);
        { Note: Step ciSleep lets us verify the close worked okay.  Without
                ciSleep, the thread would terminate immediately after the
                ciDBClose. }
      ClientA.WaitForReady(clTimeout);

      ClientB := TffDBThread.Create('ClientB', csAliasDir, ffttmAsynch, FEngine);
      ClientB.FreeOnTerminate := False;
      ClientB.AddToFilter([ciDBOpenExcl, ciDBClose]);
      ClientB.WaitForReady(clTimeout);

      { Have Client A open the database exclusively. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyOpenDB], 'ClientA DB open failure');

      { Have Client B open the database exclusively.  We expect it to fail. }
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(DBIERR_NEEDEXCLACCESS, ClientB.ResultsInt[csKeyErrCode],
                   'ClientB DB open failure');

      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;

      { Disconnect Client A. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyCloseDB], 'ClientA DB close failure');

      { Tell Clients to die. }
      ClientA.DieEvent.SignalEvent;
      ClientB.DieEvent.SignalEvent;

    except
      if Assigned(ClientA) then
        HandleArray[0] := ClientA.Handle;
      if Assigned(ClientB) then
        HandleArray[1] := ClientB.Handle;

      ClientA.DieEvent.SignalEvent;
      ClientB.DieEvent.SignalEvent;

      raise;
    end;
  finally
    { Wait for the threads to finish. }
    pHandleArray := @HandleArray;
    WaitForMultipleObjects(1, pHandleArray, true, ffcl_INFINITE);     {!!.06}
    WaitForMultipleObjects(2, pHandleArray, true, ffcl_INFINITE);     {!!.06}
    ClientA.Free;
    ClientB.Free;
  end;
end;
{--------}
procedure TffDBTest.testDBOpenExclNonExcl;
var
  ClientA, ClientB : TffDBThread;
  HandleArray : array[0..1] of THandle;  { array of thread handles }
  PHandleArray : pointer;
begin
  ClientA := nil;
  ClientB := nil;
  try
    try
      ClientA := TffDBThread.Create('ClientA', csAliasDir, ffttmAsynch, FEngine);
      ClientA.AddToFilter([ciDBOpenExcl, ciDBClose, ciSleep]);
          { Note: Step ciSleep lets us verify the close worked okay.  Without
                  ciSleep, the thread would terminate immediately after the
                  ciDBClose. }
      ClientA.WaitForReady(clTimeout);

      ClientB := TffDBThread.Create('ClientB', csAliasDir, ffttmAsynch, FEngine);
      ClientB.AddToFilter([ciDBOpenNonExcl, ciDBClose]);
      ClientB.WaitForReady(clTimeout);

      { Have Client A open the database exclusively. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyOpenDB], 'ClientA DB open failure');

      { Have Client B open the database non-exclusively.  We expect it to fail. }
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(DBIERR_NEEDEXCLACCESS, ClientB.ResultsInt[csKeyErrCode],
                   'ClientB DB open failure');

      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;

      { Disconnect Client A. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyCloseDB], 'ClientA DB close failure');

      ClientA.NextStep;

      { Tell Clients to die. }
      ClientA.DieEvent.SignalEvent;
      ClientB.DieEvent.SignalEvent;
    except
      if Assigned(ClientA) then
        HandleArray[0] := ClientA.Handle;
      if Assigned(ClientB) then
        HandleArray[1] := ClientB.Handle;

      ClientA.DieEvent.SignalEvent;
      ClientB.DieEvent.SignalEvent;

      raise;
    end;
  finally
    { Wait for the threads to finish. }
    pHandleArray := @HandleArray;
    WaitForMultipleObjects(1, pHandleArray, true, ffcl_INFINITE);     {!!.06}
//    WaitForMultipleObjects(2, pHandleArray, true, INFINITE);
  end;
end;
{--------}
procedure TffDBTest.testDBOpenBothNonExcl;
var
  ClientA, ClientB : TffDBThread;
  HandleArray : array[0..1] of THandle;  { array of thread handles }
  PHandleArray : pointer;
begin
  ClientA := nil;
  ClientB := nil;
  try
    try
      ClientA := TffDBThread.Create('ClientA', csAliasDir, ffttmAsynch, FEngine);
      ClientA.AddToFilter([ciDBOpenNonExcl, ciDBClose, ciSleep]);
          { Note: Step ciSleep lets us verify the close worked okay.  Without
                  ciSleep, the thread would terminate immediately after the
                  ciDBClose. }
      ClientA.WaitForReady(clTimeout);

      ClientB := TffDBThread.Create('ClientB', csAliasDir, ffttmAsynch, FEngine);
      ClientB.AddToFilter([ciDBOpenNonExcl, ciDBClose, ciSleep]);
          { Note: Step ciSleep lets us verify the close worked okay.  Without
                  ciSleep, the thread would terminate immediately after the
                  ciDBClose. }
      ClientB.WaitForReady(clTimeout);

      { Have Client A open the database non-exclusively. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyOpenDB], 'ClientA DB open failure');

      { Have Client B open the database non-exclusively. }
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientB.Results[csKeyOpenDB], 'ClientB DB open failure');

      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;

      { Disconnect Client A. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyCloseDB], 'ClientA DB close failure');

      { Disconnect Client B. }
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientB.Results[csKeyCloseDB], 'ClientB DB close failure');

      ClientA.NextStep;
      ClientB.NextStep;

    except
      if Assigned(ClientA) then
        HandleArray[0] := ClientA.Handle;
      if Assigned(ClientB) then
        HandleArray[1] := ClientB.Handle;

      ClientA.DieEvent.SignalEvent;
      ClientB.DieEvent.SignalEvent;

      raise;
    end;
  finally
    { Wait for the threads to finish. }
    pHandleArray := @HandleArray;
    WaitForMultipleObjects(2, pHandleArray, true, ffcl_INFINITE);     {!!.06}
  end;
end;
{--------}
procedure TffDBTest.testDBOpenNonExclExcl;
var
  ClientA, ClientB : TffDBThread;
  HandleArray : array[0..1] of THandle;  { array of thread handles }
  PHandleArray : pointer;
begin
  ClientA := nil;
  ClientB := nil;
  try
    try
      ClientA := TffDBThread.Create('ClientA', csAliasDir, ffttmAsynch, FEngine);
      ClientA.AddToFilter([ciDBOpenNonExcl, ciDBClose, ciSleep]);
          { Note: Step ciSleep lets us verify the close worked okay.  Without
                  ciSleep, the thread would terminate immediately after the
                  ciDBClose. }
      ClientA.WaitForReady(clTimeout);

      ClientB := TffDBThread.Create('ClientB', csAliasDir, ffttmAsynch, FEngine);
      ClientB.AddToFilter([ciDBOpenExcl, ciDBClose]);
      ClientB.WaitForReady(clTimeout);

      { Have Client A open the database non-exclusively. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyOpenDB], 'ClientA DB open failure');

      { Have Client B open the database exclusively.  We expect it to fail. }
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(DBIERR_NEEDEXCLACCESS, ClientB.ResultsInt[csKeyErrCode],
                   'ClientB DB open failure');

      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;

      { Disconnect Client A. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyCloseDB], 'ClientA DB close failure');

      ClientA.NextStep;

      { Tell Client B to die. }
      ClientB.DieEvent.SignalEvent;

    except
      if Assigned(ClientA) then
        HandleArray[0] := ClientA.Handle;
      if Assigned(ClientB) then
        HandleArray[1] := ClientB.Handle;

      ClientA.DieEvent.SignalEvent;
      ClientB.DieEvent.SignalEvent;

      raise;
    end;
  finally
    { Wait for the threads to finish. }
    pHandleArray := @HandleArray;
    WaitForMultipleObjects(2, pHandleArray, true, ffcl_INFINITE);     {!!.06}
  end;
end;
{--------}
procedure TffDBTest.testDBROTableRW;
var
  ClientA : TffDBThread;
  HandleArray : array[0..0] of THandle;  { array of thread handles }
  PHandleArray : pointer;
begin
  PrepareContactTable;
  try
    ClientA := TffDBThread.Create('ClientA', csAliasDir, ffttmAsynch, FEngine);
    try
      ClientA.AddToFilter([ciDBOpenNonExclRO, ciTblOpenNonExclRW, ciDBClose,
                           ciSleep]);
          { Note: Step ciSleep lets us verify the close worked okay.  Without
                  ciSleep, the thread would terminate immediately after the
                  ciDBClose. }
      ClientA.WaitForReady(clTimeout);

      { Have Client A open the database non-exclusively, read-only. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyOpenDB], 'ClientA DB open failure');

      { Have Client A open a table within the database in read-write mode. }
      ClientA.SetInput(csKeyTableName, csContacts);
      ClientA.SetInput(csKeyIndexName, csByAge);
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      { We expect the client layer to change the table's open mode to read-only
        & the table should be opened successfully. }
      CheckEquals(csOK, ClientA.Results[csKeyOpenTbl],
                   'ClientA table open failure');
      assert(ClientA.ResultsBool[csKeyTableIsReadOnly],
             'ClientA table not opened as read-only');

      HandleArray[0] := ClientA.Handle;

      { Disconnect Client A. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyCloseDB], 'ClientA DB close failure');

      ClientA.NextStep;

    except
      on E:Exception do begin
        showMessage(E.message);
        HandleArray[0] := ClientA.Handle;
        ClientA.DieEvent.SignalEvent;
        raise;
      end;
    end;
  finally
    { Wait for the threads to finish. }
    pHandleArray := @HandleArray;
    WaitForMultipleObjects(1, pHandleArray, true, ffcl_INFINITE); {!!.06}
  end;
end;
{--------}
procedure TffDBTest.testDBROTableRO;
var
  ClientA : TffDBThread;
  HandleArray : array[0..0] of THandle;  { array of thread handles }
  PHandleArray : pointer;
begin
  PrepareContactTable;
  try
    ClientA := TffDBThread.Create('ClientA', csAliasDir, ffttmAsynch, FEngine);
    try
      ClientA.AddToFilter([ciDBOpenNonExclRO, ciTblOpenNonExclRO, ciTblClose,
                           ciDBClose, ciSleep]);
          { Note: Step ciSleep lets us verify the close worked okay.  Without
                  ciSleep, the thread would terminate immediately after the
                  ciDBClose. }
      ClientA.WaitForReady(clTimeout);

      { Have Client A open the database non-exclusively, read-only. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyOpenDB], 'ClientA DB open failure');

      { Have Client A open a table within the database in read-only mode. }
      ClientA.SetInput(csKeyTableName, csContacts);
      ClientA.SetInput(csKeyIndexName, csByAge);
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyOpenTbl], 'ClientA table open failure');
      assert(ClientA.ResultsBool[csKeyTableIsReadOnly],
             'ClientA table not opened as read-only');

      { Have Client A close the table. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyCloseTbl], 'ClientA table close failure');

      { Disconnect Client A. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyCloseDB], 'ClientA DB close failure');

      HandleArray[0] := ClientA.Handle;

      ClientA.NextStep;

    except
      HandleArray[0] := ClientA.Handle;
      ClientA.DieEvent.SignalEvent;
      raise;
    end;
  finally
    { Wait for the threads to finish. }
    pHandleArray := @HandleArray;
    WaitForMultipleObjects(1, pHandleArray, true, ffcl_INFINITE); {!!.06}
  end;
end;
{--------}
procedure TffDBTest.testTableRWTableDel;
var
  ClientA, ClientB : TffDBThread;
  HandleArray : array[0..1] of THandle;  { array of thread handles }
  PHandleArray : pointer;
begin
  PrepareContactTable;
  try
    ClientA := TffDBThread.Create('ClientA', csAliasDir, ffttmAsynch, FEngine);
    ClientA.AddToFilter([ciDBOpenNonExcl, ciTblOpenNonExclRW, ciTblClose,
                           ciDBClose, ciSleep]);
          { Note: Step ciSleep lets us verify the close worked okay.  Without
                  ciSleep, the thread would terminate immediately after the
                  ciDBClose. }
    ClientA.WaitForReady(clTimeout);
    ClientB := TffDBThread.Create('ClientB', csAliasDir, ffttmAsynch, FEngine);
    try
      ClientB.AddToFilter([ciDBOpenNonExcl, ciTblDelete, ciDBClose, ciSleep]);
          { Note: Step ciSleep lets us verify the close worked okay.  Without
                  ciSleep, the thread would terminate immediately after the
                  ciDBClose. }
      ClientB.WaitForReady(clTimeout);

      { Have Client A open the database non-exclusively. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyOpenDB], 'ClientA DB open failure');

      { Have Client A open the table. }
      ClientA.SetInput(csKeyTableName, csContacts);
      ClientA.SetInput(csKeyIndexName, csByAge);
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyOpenTbl], 'ClientA table open failure');

      { Have Client B open the database non-exclusively. }
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientB.Results[csKeyOpenDB], 'ClientB DB open failure');

      { Have Client B delete the table.  It should fail. }
      ClientB.SetInput(csKeyTableName, csContacts);
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(DBIERR_TABLEOPEN, ClientB.ResultsInt[csKeyErrCode],
                   'ClientB Delete Table failure');

      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;

      { Have Client B disconnect from the DB. }
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientB.Results[csKeyCloseDB], 'ClientB DB close failure');

      { Have Client A close the table. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyCloseTbl], 'ClientA Table close failure');

      { Disconnect Client A. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyCloseDB], 'ClientA DB close failure');

      ClientA.NextStep;
      ClientB.NextStep;

    except
      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;

      ClientA.DieEvent.SignalEvent;
      ClientB.DieEvent.SignalEvent;

      raise;
    end;
  finally
    { Wait for the threads to finish. }
    pHandleArray := @HandleArray;
    WaitForMultipleObjects(2, pHandleArray, true, ffcl_INFINITE); {!!.06}
  end;
end;
{--------}
procedure TffDBTest.testTableDelTableRw;
var
  ClientA, ClientB : TffDBThread;
  HandleArray : array[0..1] of THandle;  { array of thread handles }
  PHandleArray : pointer;
begin
  PrepareContactTable;
  try
    ClientA := TffDBThread.Create('ClientA', csAliasDir, ffttmAsynch, FEngine);
    ClientA.AddToFilter([ciDBOpenExcl, ciTblDelete, ciDBClose, ciSleep]);
        { Note: Step ciSleep lets us verify the close worked okay.  Without
                ciSleep, the thread would terminate immediately after the
                ciDBClose. }
    ClientA.WaitForReady(clTimeout);
    ClientB := TffDBThread.Create('ClientB', csAliasDir, ffttmAsynch, FEngine);
    try
      ClientB.AddToFilter([ciDBOpenNonExcl, ciTblOpenNonExclRW, ciDBClose, ciSleep]);
          { Note: Step ciSleep lets us verify the close worked okay.  Without
                  ciSleep, the thread would terminate immediately after the
                  ciDBClose. }
      ClientB.WaitForReady(clTimeout);

      { Have Client A open the database non-exclusively. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyOpenDB], 'ClientA DB open failure');

      { Have Client A delete the table. }
      ClientA.SetInput(csKeyTableName, csContacts);
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyDelTbl], 'ClientA Delete Table failure');

      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;

      { Disconnect Client A. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyCloseDB], 'ClientA DB close failure');

      { Have Client B open the database non-exclusively. }
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientB.Results[csKeyOpenDB], 'ClientB DB open failure');

      { Have Client B open the table.  We expect it to fail. }
      ClientB.SetInput(csKeyTableName, csContacts);
      ClientB.SetInput(csKeyIndexName, csByAge);
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(DBIERR_NOSUCHTABLE, ClientB.ResultsInt[csKeyErrCode],
                   'ClientB table open failure');

      { Have Client B disconnect from the DB. }
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientB.Results[csKeyCloseDB], 'ClientB DB close failure');

      ClientA.NextStep;
      ClientB.NextStep;

    except
      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;

      ClientA.DieEvent.SignalEvent;
      ClientB.DieEvent.SignalEvent;

      raise;
    end;
  finally
    { Wait for the threads to finish. }
    pHandleArray := @HandleArray;
    WaitForMultipleObjects(2, pHandleArray, true, ffcl_INFINITE); {!!.06}
  end;
end;
{--------}
procedure TffDBTest.testTableRWTableRen;
var
  ClientA, ClientB : TffDBThread;
  HandleArray : array[0..1] of THandle;  { array of thread handles }
  PHandleArray : pointer;
begin
  PrepareContactTable;
  try
    ClientA := TffDBThread.Create('ClientA', csAliasDir, ffttmAsynch, FEngine);
    ClientA.AddToFilter([ciDBOpenNonExcl, ciTblOpenNonExclRW, ciTblClose,
                         ciDBClose, ciSleep]);
        { Note: Step ciSleep lets us verify the close worked okay.  Without
                ciSleep, the thread would terminate immediately after the
                ciDBClose. }
    ClientA.WaitForReady(clTimeout);

    ClientB := TffDBThread.Create('ClientB', csAliasDir, ffttmAsynch, FEngine);
    try
      ClientB.AddToFilter([ciDBOpenNonExcl, ciTblRename, ciDBClose, ciSleep]);
          { Note: Step ciSleep lets us verify the close worked okay.  Without
                  ciSleep, the thread would terminate immediately after the
                  ciDBClose. }
      ClientB.WaitForReady(clTimeout);

      { Have Client A open the database non-exclusively. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyOpenDB], 'ClientA DB open failure');

      { Have Client A open the table. }
      ClientA.SetInput(csKeyTableName, csContacts);
      ClientA.SetInput(csKeyIndexName, csByAge);
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyOpenTbl], 'ClientA table open failure');

      { Have Client B open the database non-exclusively. }
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientB.Results[csKeyOpenDB], 'ClientB DB open failure');

      { Have Client B rename the table.  It should fail. }
      ClientB.SetInput(csKeyTableName, csContacts);
      ClientB.SetInput(csKeyTableNameNew, csContactsRen);
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(DBIERR_FF_RenameFile, ClientB.ResultsInt[csKeyErrCode],
                   'ClientB Rename Table failure');

      { Have Client B disconnect from the DB. }
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientB.Results[csKeyCloseDB], 'ClientB DB close failure');

      { Have Client A close the table. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyCloseTbl], 'ClientA Table close failure');

      { Disconnect Client A. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyCloseDB], 'ClientA DB close failure');

      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;

      ClientA.NextStep;
      ClientB.NextStep;

    except
      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;

      ClientA.DieEvent.SignalEvent;
      ClientB.DieEvent.SignalEvent;

      raise;
    end;
  finally
    { Wait for the threads to finish. }
    pHandleArray := @HandleArray;
    WaitForMultipleObjects(2, pHandleArray, true, ffcl_INFINITE); {!!.06}
  end;
end;
{--------}
procedure TffDBTest.testTableRenTableRw;
var
  ClientA, ClientB : TffDBThread;
  HandleArray : array[0..1] of THandle;  { array of thread handles }
  PHandleArray : pointer;
begin
  PrepareContactTable;
  try
    ClientA := TffDBThread.Create('ClientA', csAliasDir, ffttmAsynch, FEngine);
    ClientA.AddToFilter([ciDBOpenExcl, ciTblRename, ciDBClose, ciSleep]);
        { Note: Step ciSleep lets us verify the close worked okay.  Without
                ciSleep, the thread would terminate immediately after the
                ciDBClose. }
    ClientA.WaitForReady(clTimeout);

    ClientB := TffDBThread.Create('ClientB', csAliasDir, ffttmAsynch, FEngine);
    try
      ClientB.AddToFilter([ciDBOpenNonExcl, ciTblOpenNonExclRW, ciDBClose, ciSleep]);
          { Note: Step ciSleep lets us verify the close worked okay.  Without
                  ciSleep, the thread would terminate immediately after the
                  ciDBClose. }
      ClientB.WaitForReady(clTimeout);

      { Have Client A open the database non-exclusively. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyOpenDB], 'ClientA DB open failure');

      { Have Client A rename the table. }
      ClientA.SetInput(csKeyTableName, csContacts);
      ClientA.SetInput(csKeyTableNameNew, csContactsRen);
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyRenTbl], 'ClientA Rename Table failure');

      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;

      { Disconnect Client A. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyCloseDB], 'ClientA DB close failure');

      { Have Client B open the database non-exclusively. }
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientB.Results[csKeyOpenDB], 'ClientB DB open failure');

      { Have Client B open the table under its old name.  We expect it to fail. }
      ClientB.SetInput(csKeyTableName, csContacts);
      ClientB.SetInput(csKeyIndexName, csByAge);
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(DBIERR_NOSUCHTABLE, ClientB.ResultsInt[csKeyErrCode],
                   'ClientB table open failure');

      { Have Client B disconnect from the DB. }
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientB.Results[csKeyCloseDB], 'ClientB DB close failure');

      ClientA.NextStep;
      ClientB.NextStep;

    except
      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;

      ClientA.DieEvent.SignalEvent;
      ClientB.DieEvent.SignalEvent;

      raise;
    end;
  finally
    { Wait for the threads to finish. }
    pHandleArray := @HandleArray;
    WaitForMultipleObjects(2, pHandleArray, true, ffcl_INFINITE); {!!.06}
  end;
end;
{--------}
procedure TffDBTest.testTableRenTableNewRw;
var
  ClientA, ClientB : TffDBThread;
  HandleArray : array[0..1] of THandle;  { array of thread handles }
  PHandleArray : pointer;
begin
  ClientA := nil; ClientB := nil;
  PrepareContactTable;
  try
    try
      ClientA := TffDBThread.Create('ClientA', csAliasDir, ffttmAsynch, FEngine);
      ClientA.AddToFilter([ciDBOpenExcl, ciTblRename, ciDBClose, ciSleep]);
          { Note: Step ciSleep lets us verify the close worked okay.  Without
                  ciSleep, the thread would terminate immediately after the
                  ciDBClose. }
      ClientA.WaitForReady(clTimeout);

      ClientB := TffDBThread.Create('ClientB', csAliasDir, ffttmAsynch, FEngine);
      ClientB.AddToFilter([ciDBOpenNonExcl, ciTblOpenNonExclRW, ciTblClose,
                           ciDBClose, ciSleep]);
          { Note: Step ciSleep lets us verify the close worked okay.  Without
                  ciSleep, the thread would terminate immediately after the
                  ciDBClose. }
      ClientB.WaitForReady(clTimeout);

      { Have Client A open the database non-exclusively. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyOpenDB], 'ClientA DB open failure');

      { Have Client A rename the table. }
      ClientA.SetInput(csKeyTableName, csContacts);
      ClientA.SetInput(csKeyTableNameNew, csContactsRen);
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyRenTbl], 'ClientA Rename Table failure');

      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;

      { Disconnect Client A. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyCloseDB], 'ClientA DB close failure');

      { Have Client B open the database non-exclusively. }
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientB.Results[csKeyOpenDB], 'ClientB DB open failure');

      { Have Client B open the table under its new name. }
      ClientB.SetInput(csKeyTableName, csContactsRen);
      ClientB.SetInput(csKeyIndexName, csByAge);
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientB.Results[csKeyOpenTbl], 'ClientB table open failure');

      { Have Client B close the table. }
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientB.Results[csKeyCloseTbl], 'ClientB table close failure');

      { Have Client B disconnect from the DB. }
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientB.Results[csKeyCloseDB], 'ClientB DB close failure');

      ClientA.NextStep;
      ClientB.NextStep;

    except
      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;

      ClientA.DieEvent.SignalEvent;
      ClientB.DieEvent.SignalEvent;

      raise;
    end;
  finally
    { Wait for the threads to finish. }
    pHandleArray := @HandleArray;
    WaitForMultipleObjects(2, pHandleArray, true, ffcl_INFINITE); {!!.06}
  end;
end;
{--------}
procedure TffDBTest.testMultiOpenSameDB;
var
  ClientA, ClientB, ClientC, ClientD, ClientE : TffDBThread;
  HandleArray : array[0..4] of THandle;  { array of thread handles }
  PHandleArray : pointer;
const
  RptCount = 10;
  SleepMs = 100;
begin
  ClientA := nil; ClientB := nil; ClientC := nil; ClientD := nil; ClientE := nil;
  try
    try
      ClientA := TffDBThread.Create('ClientA', csAliasDir, ffttmSynch, FEngine);
      ClientA.AddToFilter([ciDBOpenNonExcl, ciRandomSleep, ciDBClose, ciRandomSleep]);
      ClientA.SetInputInt(csKeySleepMs, SleepMs);
      ClientA.RepeatCount := RptCount;

      ClientB := TffDBThread.Create('ClientB', csAliasDir, ffttmSynch, FEngine);
      ClientB.AddToFilter([ciDBOpenNonExcl, ciRandomSleep, ciDBClose, ciRandomSleep]);
      ClientB.SetInputInt(csKeySleepMs, SleepMs);
      ClientB.RepeatCount := RptCount;

      ClientC := TffDBThread.Create('ClientC', csAliasDir, ffttmSynch, FEngine);
      ClientC.AddToFilter([ciDBOpenNonExcl, ciRandomSleep, ciDBClose, ciRandomSleep]);
      ClientC.SetInputInt(csKeySleepMs, SleepMs);
      ClientC.RepeatCount := RptCount;

      ClientD := TffDBThread.Create('ClientD', csAliasDir, ffttmSynch, FEngine);
      ClientD.AddToFilter([ciDBOpenNonExcl, ciRandomSleep, ciDBClose, ciRandomSleep]);
      ClientD.SetInputInt(csKeySleepMs, SleepMs);
      ClientD.RepeatCount := RptCount;

      ClientE := TffDBThread.Create('ClientE', csAliasDir, ffttmSynch, FEngine);
      ClientE.AddToFilter([ciDBOpenNonExcl, ciRandomSleep, ciDBClose, ciRandomSleep]);
      ClientE.SetInputInt(csKeySleepMs, SleepMs);
      ClientE.RepeatCount := RptCount;

      { Wait for threads to initialize. }
      ClientA.WaitForReady(clTimeout);
      ClientB.WaitForReady(clTimeout);
      ClientC.WaitForReady(clTimeout);
      ClientD.WaitForReady(clTimeout);
      ClientE.WaitForReady(clTimeout);

      { Build an array of thread handles.  We will use these to know when the
        threads have terminated. }
      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;
      HandleArray[2] := ClientC.Handle;
      HandleArray[3] := ClientD.Handle;
      HandleArray[4] := ClientE.Handle;

      { Tell the client threads to start. }
      ClientA.NextStep;
      ClientB.NextStep;
      ClientC.NextStep;
      ClientD.NextStep;
      ClientE.NextStep;

    except
      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;
      HandleArray[2] := ClientC.Handle;
      HandleArray[3] := ClientD.Handle;
      HandleArray[4] := ClientE.Handle;

      ClientA.DieEvent.SignalEvent;
      ClientB.DieEvent.SignalEvent;
      ClientC.DieEvent.SignalEvent;
      ClientD.DieEvent.SignalEvent;
      ClientE.DieEvent.SignalEvent;

      raise;
    end;
  finally
    { Wait for the threads to finish. }
    pHandleArray := @HandleArray;
    WaitForMultipleObjects(5, pHandleArray, true, ffcl_INFINITE); {!!.06}
  end;
end;
{--------}
procedure TffDBTest.testMultiOpenMultiDB;
var
  ClientA, ClientB, ClientC, ClientD, ClientE : TffDBThread;
  HandleArray : array[0..4] of THandle;  { array of thread handles }
  PHandleArray : pointer;
  Status : DWord;
const
  RptCount = 50;
  SleepMs = 5;
begin
  ClientA := nil; ClientB := nil; ClientC := nil; ClientD := nil; ClientE := nil;
  try
    try
      ClientA := TffDBThread.Create('ClientA', csAliasDir, ffttmSynch, FEngine);
      ClientA.AddToFilter([ciDBOpenNonExcl, ciRandomSleep, ciDBClose, ciRandomSleep]);
      ClientA.SetInputInt(csKeySleepMs, SleepMs);
      ClientA.RepeatCount := RptCount;

      ClientB := TffDBThread.Create('ClientB', csAliasDir, ffttmSynch, FEngine);
      ClientB.AddToFilter([ciDBOpenNonExcl, ciRandomSleep, ciDBClose, ciRandomSleep]);
      ClientB.SetInputInt(csKeySleepMs, SleepMs);
      ClientB.RepeatCount := RptCount;

      ClientC := TffDBThread.Create('ClientC', csAliasDir, ffttmSynch, FEngine);
      ClientC.AddToFilter([ciDBOpenNonExcl, ciRandomSleep, ciDBClose, ciRandomSleep]);
      ClientC.SetInputInt(csKeySleepMs, SleepMs);
      ClientC.RepeatCount := RptCount;

      ClientD := TffDBThread.Create('ClientD', csAliasDir, ffttmSynch, FEngine);
      ClientD.AddToFilter([ciDBOpenNonExcl, ciRandomSleep, ciDBClose, ciRandomSleep]);
      ClientD.SetInputInt(csKeySleepMs, SleepMs);
      ClientD.RepeatCount := RptCount;

      ClientE := TffDBThread.Create('ClientE', csAliasDir, ffttmSynch, FEngine);
      ClientE.AddToFilter([ciDBOpenNonExcl, ciRandomSleep, ciDBClose, ciRandomSleep]);
      ClientE.SetInputInt(csKeySleepMs, SleepMs);
      ClientE.RepeatCount := RptCount;

      { Wait for threads to initialize. }
      ClientA.WaitForReady(clTimeout);
      ClientB.WaitForReady(clTimeout);
      ClientC.WaitForReady(clTimeout);
      ClientD.WaitForReady(clTimeout);
      ClientE.WaitForReady(clTimeout);

      { Build an array of thread handles.  We will use these to know when the
        threads have terminated. }
      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;
      HandleArray[2] := ClientC.Handle;
      HandleArray[3] := ClientD.Handle;
      HandleArray[4] := ClientE.Handle;

      { Tell the client threads to start. }
      ClientA.NextStep;
      ClientB.NextStep;
      ClientC.NextStep;
      ClientD.NextStep;
      ClientE.NextStep;

    except
      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;
      HandleArray[2] := ClientC.Handle;
      HandleArray[3] := ClientD.Handle;
      HandleArray[4] := ClientE.Handle;

      ClientA.DieEvent.SignalEvent;
      ClientB.DieEvent.SignalEvent;
      ClientC.DieEvent.SignalEvent;
      ClientD.DieEvent.SignalEvent;
      ClientE.DieEvent.SignalEvent;

      raise;
    end;
  finally
    { Wait for them to finish. }
    PHandleArray := @HandleArray;
    Status := WaitForMultipleObjects(5, pHandleArray, true, ffcl_INFINITE); {!!.06}
    Assert(WAIT_FAILED <> Status, 'Thread wait failure');
//  CheckNotEquals(WAIT_FAILED, Status,'Thread wait failure');
  end;
end;
{--------}
procedure TffDBTest.testTblDropIndexTimeout;
var
  ClientA, ClientB : TffDBThread;
  HandleArray : array[0..2] of THandle;  { array of thread handles }
  PHandleArray : pointer;
begin
  ClientA := nil; ClientB := nil;
  PrepareContactTable;
  try
    try
      ClientA := TffDBThread.Create('ClientA', csAliasDir, ffttmAsynch, FEngine);
      ClientA.AddToFilter([ciDBOpenNonExcl, ciTblOpenNonExclRW, ciTblClose,
                           ciDBClose, ciSleep]);
          { Note: Step ciSleep lets us verify the close worked okay.  Without
                  ciSleep, the thread would terminate immediately after the
                  ciDBClose. }
      ClientA.WaitForReady(clTimeout);

      ClientB := TffDBThread.Create('ClientB', csAliasDir, ffttmAsynch, FEngine);
      ClientB.AddToFilter([ciDBOpenNonExcl, ciTblDropIndex, ciDBClose, ciSleep]);
          { Note: Step ciSleep lets us verify the close worked okay.  Without
                  ciSleep, the thread would terminate immediately after the
                  ciDBClose. }
      ClientB.WaitForReady(clTimeout);

      { Have Client A open the database non-exclusively. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyOpenDB], 'ClientA DB open failure');

      { Have Client A open the table. }
      ClientA.SetInput(csKeyTableName, csContacts);
      ClientA.SetInput(csKeyTableNameNew, csContactsRen);
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyOpenTbl], 'ClientA Open Table failure');

      { Have Client B open the database non-exclusively. }
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientB.Results[csKeyOpenDB], 'ClientB DB open failure');

      { Have Client B drop an index on the table.  Since Client A keeps the
        table open.  We expect Client B to timeout. }
      ClientB.SetInput(csKeyTableName, csContacts);
      ClientB.SetInput(csKeyIndexName, csByAge);
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(DBIERR_FILELOCKED, ClientB.ResultsInt[csKeyErrCode],
                   'ClientB drop index failure');
      { Verify that it took as long as we expected. }
      CheckEquals(ClientB.ResultsInt[csKeyDBTimeout],
                   ClientB.ResultsInt[csKeyTime], clTimeoutDelta,
                   'ClientB drop index Timeout outside of range');

      { Have Client B disconnect from the DB. }
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientB.Results[csKeyCloseDB], 'ClientB DB close failure');

      { Have Client A close the table. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyCloseTbl], 'ClientA table close failure');

      { Have Client A disconnect from the DB. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyCloseDB], 'ClientA DB close failure');

      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;

      ClientA.NextStep;
      ClientB.NextStep;

    except
      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;

      ClientA.DieEvent.SignalEvent;
      ClientB.DieEvent.SignalEvent;

      raise;
    end;
  finally
    { Wait for the threads to finish. }
    pHandleArray := @HandleArray;
    WaitForMultipleObjects(2, pHandleArray, true, ffcl_INFINITE); {!!.06}
  end;
end;
{--------}
procedure TffDBTest.testTblDropIndex;
var
  ClientA, ClientB : TffDBThread;
  HandleArray : array[0..4] of THandle;  { array of thread handles }
  PHandleArray : pointer;
begin
  ClientA := nil; ClientB := nil;
  PrepareContactTable;
  try
    try
      ClientA := TffDBThread.Create('ClientA', csAliasDir, ffttmAsynch, FEngine);
      ClientA.AddToFilter([ciDBOpenNonExcl, ciTblOpenNonExclRW, ciTblClose,
                           ciDBClose, ciSleep]);
          { Note: Step ciSleep lets us verify the close worked okay.  Without
                  ciSleep, the thread would terminate immediately after the
                  ciDBClose. }
      ClientA.WaitForReady(clTimeout);

      ClientB := TffDBThread.Create('ClientB', csAliasDir, ffttmAsynch, FEngine);
      ClientB.AddToFilter([ciDBOpenNonExcl, ciTblDropIndex, ciDBClose, ciSleep]);
          { Note: Step ciSleep lets us verify the close worked okay.  Without
                  ciSleep, the thread would terminate immediately after the
                  ciDBClose. }
      ClientB.WaitForReady(clTimeout);

      { Have Client A open the database non-exclusively. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyOpenDB], 'ClientA DB open failure');

      { Have Client A open the table. }
      ClientA.SetInput(csKeyTableName, csContacts);
      ClientA.SetInput(csKeyTableNameNew, csContactsRen);
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyOpenTbl], 'ClientA Open Table failure');

      { Have Client B open the database non-exclusively. }
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientB.Results[csKeyOpenDB], 'ClientB DB open failure');

      { Have Client B drop an index on the table. }
      ClientB.SetInput(csKeyTableName, csContacts);
      ClientB.SetInput(csKeyIndexName, csByAge);
      ClientB.NextStep;

      { Have Client A close the table. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyCloseTbl], 'ClientA table close failure');

      { At this point, Client B should have been granted access to the table
        and should now be able to drop the index. }
      ClientB.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientB.Results[csKeyDropIndex],
                   'ClientB drop index failure');

      { Have Client B disconnect from the DB. }
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientB.Results[csKeyCloseDB], 'ClientB DB close failure');

      { Have Client A disconnect from the DB. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyCloseDB], 'ClientA DB close failure');

      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;

      ClientA.NextStep;
      ClientB.NextStep;

    except
      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;

      ClientA.DieEvent.SignalEvent;
      ClientB.DieEvent.SignalEvent;

      raise;
    end;
  finally
    { Wait for the threads to finish. }
    pHandleArray := @HandleArray;
    WaitForMultipleObjects(2, pHandleArray, true, ffcl_INFINITE); {!!.06}
  end;
end;
{--------}
procedure TffDBTest.testTblROMultRW;
var
  ClientA, ClientB, ClientC : TffDBThread;
  HandleArray : array[0..2] of THandle;  { array of thread handles }
  PHandleArray : pointer;
begin
  ClientA := nil; ClientB := nil; ClientC := nil;
  PrepareContactTable;
  try
    try
      ClientA := TffDBThread.Create('ClientA', csAliasDir, ffttmAsynch, FEngine);
      ClientA.AddToFilter([ciDBOpenNonExcl, ciTblOpenNonExclRO, ciTblClose,
                           ciDBClose, ciSleep]);
          { Note: Step ciSleep lets us verify the close worked okay.  Without
                  ciSleep, the thread would terminate immediately after the
                  ciDBClose. }
      ClientA.WaitForReady(clTimeout);

      ClientB := TffDBThread.Create('ClientB', csAliasDir, ffttmAsynch, FEngine);
      ClientB.AddToFilter([ciDBOpenNonExcl, ciTblOpenNonExclRW, ciTblClose,
                           ciDBClose, ciSleep]);
          { Note: Step ciSleep lets us verify the close worked okay.  Without
                  ciSleep, the thread would terminate immediately after the
                  ciDBClose. }
      ClientB.WaitForReady(clTimeout);

      ClientC := TffDBThread.Create('ClientC', csAliasDir, ffttmAsynch, FEngine);
      ClientC.AddToFilter([ciDBOpenNonExcl, ciTblOpenNonExclRW, ciTblClose,
                           ciDBClose, ciSleep]);
          { Note: Step ciSleep lets us verify the close worked okay.  Without
                  ciSleep, the thread would terminate immediately after the
                  ciDBClose. }
      ClientC.WaitForReady(clTimeout);

      { Have Client A open the database non-exclusively. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyOpenDB], 'ClientA DB open failure');

      { Have Client B open the database non-exclusively. }
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientB.Results[csKeyOpenDB], 'ClientB DB open failure');

      { Have Client C open the database non-exclusively. }
      ClientC.NextStep;
      Clientc.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientC.Results[csKeyOpenDB], 'ClientC DB open failure');

      { Have Client A open the table in read-only mode. }
      ClientA.SetInput(csKeyTableName, csContacts);
      ClientA.SetInput(csKeyIndexName, csByAge);
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyOpenTbl], 'ClientA Open Table failure');
      assert(ClientA.ResultsBool[csKeyTableIsReadOnly],
             'ClientA table not opened as read-only');

      { Have Client A open the table in read-write mode. }
      ClientB.SetInput(csKeyTableName, csContacts);
      ClientB.SetInput(csKeyIndexName, csByAge);
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientB.Results[csKeyOpenTbl], 'ClientB Open Table failure');
      assert((not ClientB.ResultsBool[csKeyTableIsReadOnly]),
             'ClientB table opened as read-only');

      { Have Client C open the table in read-write mode. }
      ClientC.SetInput(csKeyTableName, csContacts);
      ClientC.SetInput(csKeyIndexName, csByAge);
      ClientC.NextStep;
      ClientC.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientC.Results[csKeyOpenTbl], 'ClientC Open Table failure');
      assert((not ClientC.ResultsBool[csKeyTableIsReadOnly]),
             'ClientC table opened as read-only');

      { Have Client A close the table. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyCloseTbl], 'ClientA table close failure');

      { Have Client B close the table. }
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientB.Results[csKeyCloseTbl], 'ClientB table close failure');

      { Have Client C close the table. }
      ClientC.NextStep;
      ClientC.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientC.Results[csKeyCloseTbl], 'ClientC table close failure');

      { Have Client A disconnect from the DB. }
      ClientA.NextStep;
      ClientA.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientA.Results[csKeyCloseDB], 'ClientA DB close failure');

      { Have Client B disconnect from the DB. }
      ClientB.NextStep;
      ClientB.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientB.Results[csKeyCloseDB], 'ClientB DB close failure');

      { Have Client C disconnect from the DB. }
      ClientC.NextStep;
      ClientC.WaitForStep(clTimeout);
      CheckEquals(csOK, ClientC.Results[csKeyCloseDB], 'ClientC DB close failure');

      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;
      HandleArray[2] := ClientC.Handle;

      ClientA.NextStep;
      ClientB.NextStep;
      ClientC.NextStep;

    except
      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;
      HandleArray[2] := ClientC.Handle;

      ClientA.DieEvent.SignalEvent;
      ClientB.DieEvent.SignalEvent;
      ClientC.DieEvent.SignalEvent;

      raise;
    end;
  finally
    { Wait for the threads to finish. }
    pHandleArray := @HandleArray;
    WaitForMultipleObjects(3, pHandleArray, true, ffcl_INFINITE); {!!.06}
  end;
end;
{--------}
procedure TffDBTest.testTblRepeatOpenSame;
var
  ClientA, ClientB, ClientC : TffDBThread;
  HandleArray : array[0..4] of THandle;  { array of thread handles }
  PHandleArray : pointer;
  Status : DWord;
const
  RptCount = 100;
  SleepMs = 5;
begin
  ClientA := nil; ClientB := nil; ClientC := nil;
  PrepareContactTable;
  try
    try

      { Four threads will open the table non-exclusively, one thread will
        open the thread exclusively. }
      ClientA := TffDBThread.Create('ClientA', csAliasDir, ffttmSynch, FEngine);
      ClientA.AddToFilter([ciDBOpenNonExcl, ciRandomSleep, ciTblOpenNonExclRW,
                           ciRandomSleep, ciTblClose, ciDBClose, ciRandomSleep]);
      ClientA.SetInputInt(csKeySleepMs, SleepMs);
      ClientA.RepeatCount := RptCount;
      ClientA.SetInput(csKeyTableName, csContacts);
      ClientA.SetInput(csKeyIndexName, csByAge);

      ClientB := TffDBThread.Create('ClientB', csAliasDir, ffttmSynch, FEngine);
      ClientB.AddToFilter([ciDBOpenNonExcl, ciRandomSleep, ciTblOpenNonExclRW,
                           ciRandomSleep, ciTblClose, ciDBClose, ciRandomSleep]);
      ClientB.SetInputInt(csKeySleepMs, SleepMs);
      ClientB.RepeatCount := RptCount;
      ClientB.SetInput(csKeyTableName, csContacts);
      ClientB.SetInput(csKeyIndexName, csByAge);

      ClientC := TffDBThread.Create('ClientC', csAliasDir, ffttmSynch, FEngine);
      ClientC.AddToFilter([ciDBOpenNonExcl, ciRandomSleep, ciTblOpenNonExclRW,
                           ciRandomSleep, ciTblClose, ciDBClose, ciRandomSleep]);
      ClientC.SetInputInt(csKeySleepMs, SleepMs);
      ClientC.RepeatCount := RptCount;
      ClientC.SetInput(csKeyTableName, csContacts);
      ClientC.SetInput(csKeyIndexName, csByAge);

      { This thread opens in read-only mode. }
{      ClientD := TffDBThread.Create('ClientD', csAliasDir, ffttmSynch, FEngine);
      ClientD.AddToFilter([ciDBOpenNonExcl, ciRandomSleep, ciTblOpenNonExclRO,
                           ciRandomSleep, ciTblClose, ciDBClose, ciRandomSleep]);
      ClientD.SetInputInt(csKeySleepMs, SleepMs);
      ClientD.RepeatCount := RptCount;
      ClientD.SetInput(csKeyTableName, csContacts);
      ClientD.SetInput(csKeyIndexName, csByAge);}

      { This thread opens the table exclusively. }
{      ClientE := TffDBThread.Create('ClientE', csAliasDir, ffttmSynch, FEngine);
      ClientE.AddToFilter([ciDBOpenNonExcl, ciRandomSleep, ciTblOpenExclRW,
                           ciRandomSleep, ciTblClose, ciDBClose, ciRandomSleep]);
      ClientE.SetInputInt(csKeySleepMs, SleepMs);
      ClientE.RepeatCount := RptCount;
      ClientE.SetInput(csKeyTableName, csContacts);
      ClientE.SetInput(csKeyIndexName, csByAge);}

      { Wait for threads to initialize. }
      ClientA.WaitForReady(clTimeout);
      ClientB.WaitForReady(clTimeout);
      ClientC.WaitForReady(clTimeout);
{      ClientD.WaitForReady(clTimeout);
      ClientE.WaitForReady(clTimeout);}

      { Build an array of thread handles.  We will use these to know when the
        threads have terminated. }
      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;
      HandleArray[2] := ClientC.Handle;
{      HandleArray[3] := ClientD.Handle;
      HandleArray[4] := ClientE.Handle;}

      { Tell the client threads to start. }
      ClientA.NextStep;
      ClientB.NextStep;
      ClientC.NextStep;
{      ClientD.NextStep;
      ClientE.NextStep;}

    except
      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;
      HandleArray[2] := ClientC.Handle;
{      HandleArray[3] := ClientD.Handle;
      HandleArray[4] := ClientE.Handle;}

      ClientA.DieEvent.SignalEvent;
      ClientB.DieEvent.SignalEvent;
      ClientC.DieEvent.SignalEvent;
{      ClientD.DieEvent.SignalEvent;
      ClientE.DieEvent.SignalEvent;}

      raise;
    end;
  finally
    { Wait for them to finish. }
    PHandleArray := @HandleArray;
    Status := WaitForMultipleObjects(3, pHandleArray, true, ffcl_INFINITE); {!!.06}
//    Status := WaitForMultipleObjects(5, pHandleArray, true, INFINITE);
    Assert(WAIT_FAILED <> STATUS, 'Thread wait failure');
//    CheckNotEquals(WAIT_FAILED, Status, 'Thread wait failure');
  end;
end;
{--------}
procedure TffDBTest.testTblRepeatOpenMulti;
var
  ClientA, ClientB, ClientC, ClientD, ClientE : TffDBThread;
  HandleArray : array[0..4] of THandle;  { array of thread handles }
  PHandleArray : pointer;
  Status : DWord;
const
  RptCount = 100;
  SleepMs = 5;
begin
  ClientA := nil; ClientB := nil; ClientC := nil; ClientD := nil; ClientE := nil;
  PrepareContactTable;
  PrepareEmailTable;
  try
    try

      { All threads open their table exclusively. }
      ClientA := TffDBThread.Create('ClientA', csAliasDir, ffttmSynch, FEngine);
      ClientA.AddToFilter([ciDBOpenNonExcl, ciRandomSleep, ciTblOpenExclRW,
                           ciRandomSleep, ciTblClose, ciDBClose, ciRandomSleep]);
      ClientA.SetInputInt(csKeySleepMs, SleepMs);
      ClientA.RepeatCount := RptCount;
      ClientA.SetInput(csKeyTableName, csContacts);
      ClientA.SetInput(csKeyIndexName, csByAge);

      ClientB := TffDBThread.Create('ClientB', csAliasDir, ffttmSynch, FEngine);
      ClientB.AddToFilter([ciDBOpenNonExcl, ciRandomSleep, ciTblOpenExclRW,
                           ciRandomSleep, ciTblClose, ciDBClose, ciRandomSleep]);
      ClientB.SetInputInt(csKeySleepMs, SleepMs);
      ClientB.RepeatCount := RptCount;
      ClientB.SetInput(csKeyTableName, csEmail);
      ClientB.SetInput(csKeyIndexName, csPrimary);

      ClientC := TffDBThread.Create('ClientC', csAliasDir, ffttmSynch, FEngine);
      ClientC.AddToFilter([ciDBOpenNonExcl, ciRandomSleep, ciTblOpenExclRW,
                           ciRandomSleep, ciTblClose, ciDBClose, ciRandomSleep]);
      ClientC.SetInputInt(csKeySleepMs, SleepMs);
      ClientC.RepeatCount := RptCount;
      ClientC.SetInput(csKeyTableName, csContacts);
      ClientC.SetInput(csKeyIndexName, csByAge);

      ClientD := TffDBThread.Create('ClientD', csAliasDir, ffttmSynch, FEngine);
      ClientD.AddToFilter([ciDBOpenNonExcl, ciRandomSleep, ciTblOpenExclRW,
                           ciRandomSleep, ciTblClose, ciDBClose, ciRandomSleep]);
      ClientD.SetInputInt(csKeySleepMs, SleepMs);
      ClientD.RepeatCount := RptCount;
      ClientD.SetInput(csKeyTableName, csEmail);
      ClientD.SetInput(csKeyIndexName, csPrimary);

      ClientE := TffDBThread.Create('ClientE', csAliasDir, ffttmSynch, FEngine);
      ClientE.AddToFilter([ciDBOpenNonExcl, ciRandomSleep, ciTblOpenExclRW,
                           ciRandomSleep, ciTblClose, ciDBClose, ciRandomSleep]);
      ClientE.SetInputInt(csKeySleepMs, SleepMs);
      ClientE.RepeatCount := RptCount;
      ClientE.SetInput(csKeyTableName, csContacts);
      ClientE.SetInput(csKeyIndexName, csByAge);

      { Wait for threads to initialize. }
      ClientA.WaitForReady(clTimeout);
      ClientB.WaitForReady(clTimeout);
      ClientC.WaitForReady(clTimeout);
      ClientD.WaitForReady(clTimeout);
      ClientE.WaitForReady(clTimeout);

      { Build an array of thread handles.  We will use these to know when the
        threads have terminated. }
      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;
      HandleArray[2] := ClientC.Handle;
      HandleArray[3] := ClientD.Handle;
      HandleArray[4] := ClientE.Handle;

      { Tell the client threads to start. }
      ClientA.NextStep;
      ClientB.NextStep;
      ClientC.NextStep;
      ClientD.NextStep;
      ClientE.NextStep;

    except
      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;
      HandleArray[2] := ClientC.Handle;
      HandleArray[3] := ClientD.Handle;
      HandleArray[4] := ClientE.Handle;

      ClientA.DieEvent.SignalEvent;
      ClientB.DieEvent.SignalEvent;
      ClientC.DieEvent.SignalEvent;
      ClientD.DieEvent.SignalEvent;
      ClientE.DieEvent.SignalEvent;

      raise;
    end;
  finally
    { Wait for them to finish. }
    PHandleArray := @HandleArray;
    Status := WaitForMultipleObjects(5, pHandleArray, true, ffcl_INFINITE); {!!.06}
    Assert(WAIT_FAILED <> Status, 'Thread wait failure');
//    CheckNotEquals(WAIT_FAILED, Status, 'Thread wait failure');
  end;
end;
{--------}
procedure TffDBTest.testTblDeadlock;
var
  ClientA, ClientB : TffDBThread;
  ClientAErr, ClientBErr : TffResult;
  HandleArray : array[0..1] of THandle;  { array of thread handles }
  PHandleArray : pointer;
  Status : DWord;
const
  SleepMs = 5;
begin
  ClientA := nil; ClientB := nil;
  PrepareContactTable;
  PrepareEmailTable;
  try
    try

      { All threads open their table exclusively. }
      ClientA := TffDBThread.Create('ClientA', csAliasDir, ffttmAsynch, FEngine);
      ClientA.AddToFilter([ciDBOpenNonExcl, ciTblOpenExclRW, ciTblOpenExclRw2,
                           ciRandomSleep]);
      ClientA.SetInputInt(csKeySleepMs, SleepMs);

      ClientB := TffDBThread.Create('ClientB', csAliasDir, ffttmAsynch, FEngine);
      ClientB.AddToFilter([ciDBOpenNonExcl, ciTblOpenExclRW, ciTblOpenExclRw2,
                           ciRandomSleep]);
      ClientB.SetInputInt(csKeySleepMs, SleepMs);

      { Wait for threads to initialize. }
      ClientA.WaitForReady(clTimeout);
      ClientB.WaitForReady(clTimeout);

      { Build an array of thread handles.  We will use these to know when the
        threads have terminated. }
      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;

      { Have Client A open the Contacts table in Exclusive mode. }
      ClientA.NextStep;  { database }
      ClientA.WaitForStep(clTimeout);
      ClientA.SetInput(csKeyTableName, csContacts);
      ClientA.SetInput(csKeyIndexName, csByAge);
      ClientA.NextStep;  { open table }
      ClientA.WaitForStep(clTimeout);

      { Have Client B open the Email table in Exclusive mode. }
      ClientB.NextStep;  { database }
      ClientB.WaitForStep(clTimeout);
      ClientB.SetInput(csKeyTableName, csEmail);
      ClientB.SetInput(csKeyIndexName, csPrimary);
      ClientB.NextStep;  { open table }
      ClientB.WaitForStep(clTimeout);

      { Have Client A open the Email table in Exclusive mode. }
      ClientA.SetInput(csKeyTableName, csEmail);
      ClientA.SetInput(csKeyIndexName, csPrimary);
      ClientA.NextStep;  { open table 2 }

      { Have Client B open the Contacts table in Exclusive mode. }
      ClientB.SetInput(csKeyTableName, csContacts);
      ClientB.SetInput(csKeyIndexName, csByAge);
      ClientB.NextStep;  { open table 2 }

      { Wait for Client A. }
      ClientA.WaitForStep(clTimeout);

      { Wait for Client B. }
      ClientB.WaitForStep(clTimeout);

      { Was one of them chosen as the deadlock victim? }
      ClientAErr := ClientA.ResultsInt[csKeyErrCode];
      ClientBErr := ClientB.ResultsInt[csKeyErrCode];

      assert((ClientAErr = DBIERR_FF_Deadlock) or (ClientBErr = DBIERR_FF_Deadlock),
             format('Neither thread was deadlocked.  ClientA: %d, ClientB: %d',
                    [ClientAErr, ClientBErr]));

      { Tell both clients to finish. }
      ClientA.DieEvent.SignalEvent;
      ClientB.DieEvent.SignalEvent;

    except
      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;

      ClientA.DieEvent.SignalEvent;
      ClientB.DieEvent.SignalEvent;

      raise;
    end;
  finally
    { Wait for them to finish. }
    PHandleArray := @HandleArray;
    Status := WaitForMultipleObjects(2, pHandleArray, true, ffcl_INFINITE); {!!.06}
//    CheckNotEquals(WAIT_FAILED, Status, 'Thread wait failure');
    Assert(WAIT_FAILED <> Status, 'Thread wait failure');
  end;
end;
{--------}
procedure TffDBTest.testServerObjectCleanup;
var
  ClientA, ClientB : TffDBThread;
  HandleArray : array[0..1] of THandle;  { array of thread handles }
  PHandleArray : pointer;
  Status : DWord;
const
  SleepMs = 5;
begin
  ClientA := nil; ClientB := nil;
  { Approach: Set timeout adjustment in transport to a negative number.
      This ensures we timeout on the client-side before a timeout occurs
      on the server-side.  Get two tables into a deadlock.  When we timeout
      on the client side, close the client threads.  The server objects
      should be left as is.  The cursors should free themselves when they
      deactivate.  The higher-level objects should be cleaned up by the
      garbage collector. }

{ Temporarily comment out this stuff.  Avoids some excess junk being written
  to FFServer.log }
//  PrepareContactTable;
//  PrepareEmailTable;
  try
    try

      { All threads open their table exclusively. }
      ClientA := TffDBThread.Create('ClientA', csAliasDir, ffttmAsynch, FEngine);
      ClientA.AddToFilter([ciDBOpenNonExcl, ciTblOpenExclRW, ciRandomSleep]);
      ClientA.SetInputInt(csKeySleepMs, SleepMs);

      ClientB := TffDBThread.Create('ClientB', csAliasDir, ffttmAsynch, FEngine);
      ClientB.AddToFilter([ciDBOpenNonExcl, ciTblOpenExclRW, ciRandomSleep]);
      ClientB.SetInputInt(csKeySleepMs, SleepMs);

      { Wait for threads to initialize. }
      ClientA.WaitForReady(clTimeout);
      ClientB.WaitForReady(clTimeout);

      { Build an array of thread handles.  We will use these to know when the
        threads have terminated. }
      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;

      { Have Client A open the Contacts table in Exclusive mode. }
      ClientA.NextStep;  { database }
      ClientA.WaitForStep(clTimeout);
      ClientA.SetInput(csKeyTableName, csContacts);
      ClientA.SetInput(csKeyIndexName, csByAge);
      ClientA.NextStep;  { open table }
      ClientA.WaitForStep(clTimeout);

      { At this point, Client A will just sit. }

      { Have Client B open the Contacts table in Exclusive mode.
        Client B will wait for Client A to close the table but that will
        never happen...Bwaahahaha!}
      ClientB.NextStep;  { database }
      ClientB.WaitForStep(clTimeout);
      ClientB.SetInput(csKeyTableName, csContacts);
      ClientB.SetInput(csKeyIndexName, csByAge);
      ffcl_RequestLatencyAdjustment := -3000;
      ClientB.NextStep;  { open table }

      { We should sit here for about 3 seconds at which time the client
        will time out waiting for a reply. }
      ClientB.WaitForStep(clTimeout);

      { Tell Client B to finish.  This should happen while a thread is trying
        to fulfill Client B's request to exclusively open the Contacts table. }
      ClientB.DieEvent.SignalEvent;

      { Wait for a little bit. }
      Sleep(5000);

      { Now tell Client A to die. }
      ClientA.DieEvent.SignalEvent;

    except
      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;

      ClientA.DieEvent.SignalEvent;
      ClientB.DieEvent.SignalEvent;

      raise;
    end;
  finally
    { Wait for them to finish. }
    PHandleArray := @HandleArray;
    Status := WaitForMultipleObjects(2, pHandleArray, true, ffcl_INFINITE); {!!.06}
//    CheckNotEquals(WAIT_FAILED, Status, 'Thread wait failure');
    Assert(WAIT_FAILED <> Status, 'Thread wait failure');
  end;
end;
{--------}
procedure TffDBTest.testSingleThreadInsert10k;
begin
  testSingleThreadInsertPrim(10000, 1000);
end;
{--------}
procedure TffDBTest.testSingleThreadInsertPrim(const recCount, recsPerTran : longInt);
var
  ClientA : TffDBThread;
  HandleArray : array[0..0] of THandle;  { array of thread handles }
  PHandleArray : pointer;
  Status : DWord;

//  TotalTime : DWord;
//  AvgTime : DWord;
//  FirstIt : DWord;
//  LastIt : DWord;
  
const
  aFilter : array[0..4] of integer = (ciDBOpenNonExcl, ciTblOpenNonExclRW,
                                      ciInsertRandomContacts, ciTblClose, ciDBClose);
begin
  ClientA := nil;
  { Goal: Have 1 thread quickly insert 10,000 contact records. }
  PrepareContactTable;
  try
    try

      { Create a thread. }
      ClientA := TffDBThread.Create('ClientA', csAliasDir, ffttmSynch, FEngine);
      ClientA.WaitAtEnd := True;
      ClientA.SetInput(csKeyTableName, csContacts);
      ClientA.SetInputInt(csKeyTableTimeout, 2000000);
      ClientA.SetInputInt(csKeyNumRecordsPerTran, recsPerTran);
      ClientA.SetInputInt(csKeyNumRecords, recCount);
      ClientA.AddToFilter(aFilter);

      { Wait for thread to initialize. }
      ClientA.WaitForReady(clTimeout);

      HandleArray[0] := ClientA.Handle;

      { Tell the thread to start & wait for it to finish. }
      ClientA.NextStep;
      ClientA.WaitForStep(0);

      { Test results. }
      { Were all records inserted? }
      CheckEquals(recCount, ClientA.ResultsInt[csKeyRecordsInserted],
                   'Client A did not insert all records.');

      { Are there any value gaps in the ID field? }
      { TODO }

//      TotalTime := ClientA.ResultsInt[csKeyPerfTotalTime];
//      FirstIt := ClientA.ResultsInt[csKeyPerf1stIteration];
//      LastIt := ClientA.ResultsInt[csKeyPerfLastIteration];
//      AvgTime := ClientA.ResultsInt[csKeyPerfAvgTime];

      { Tell the thread to die. }
      ClientA.DieEvent.SignalEvent;

    except
      HandleArray[0] := ClientA.Handle;

      ClientA.DieEvent.SignalEvent;

      raise;
    end;
  finally
    { Wait for them to finish. }
    PHandleArray := @HandleArray;
    Status := WaitForMultipleObjects(1, pHandleArray, true, ffcl_INFINITE); {!!.06}
//    CheckNotEquals(WAIT_FAILED, Status, 'Thread wait failure');
    Assert(WAIT_FAILED <> Status, 'Thread wait failure');
  end;
end;
{--------}
procedure TffDBTest.testMassInsert;
var
  ClientA, ClientB, ClientC, ClientD, ClientE : TffDBThread;
  HandleArray : array[0..4] of THandle;  { array of thread handles }
  PHandleArray : pointer;
  Status : DWord;
const
  aFilter : array[0..4] of integer = (ciDBOpenNonExcl, ciTblOpenNonExclRW,
                                      ciInsertRandomContacts, ciTblClose, ciDBClose);
begin
  ClientA := nil; ClientB := nil; ClientC := nil; ClientD := nil; ClientE := nil;
  { Goal: Have 5 threads quickly insert 20,000 contact records each. }
  PrepareContactTable;
  try
    try

      { Create the threads. }
      ClientA := TffDBThread.Create('ClientA', csAliasDir, ffttmSynch, FEngine);
      ClientA.WaitAtEnd := True;
      ClientA.SetInput(csKeyTableName, csContacts);
      ClientA.SetInputInt(csKeyNumRecordsPerTran, 1000);
      ClientA.SetInputInt(csKeyNumRecords, 20000);
      ClientA.AddToFilter(aFilter);

      ClientB := TffDBThread.Create('ClientA', csAliasDir, ffttmSynch, FEngine);
      ClientB.WaitAtEnd := True;
      ClientB.SetInput(csKeyTableName, csContacts);
      ClientB.SetInputInt(csKeyNumRecordsPerTran, 1000);
      ClientB.SetInputInt(csKeyNumRecords, 20000);
      ClientB.AddToFilter(aFilter);

      ClientC := TffDBThread.Create('ClientA', csAliasDir, ffttmSynch, FEngine);
      ClientC.WaitAtEnd := True;
      ClientC.SetInput(csKeyTableName, csContacts);
      ClientC.SetInputInt(csKeyNumRecordsPerTran, 1000);
      ClientC.SetInputInt(csKeyNumRecords, 20000);
      ClientC.AddToFilter(aFilter);

      ClientD := TffDBThread.Create('ClientA', csAliasDir, ffttmSynch, FEngine);
      ClientD.WaitAtEnd := True;
      ClientD.SetInput(csKeyTableName, csContacts);
      ClientD.SetInputInt(csKeyNumRecordsPerTran, 1000);
      ClientD.SetInputInt(csKeyNumRecords, 20000);
      ClientD.AddToFilter(aFilter);

      ClientE := TffDBThread.Create('ClientA', csAliasDir, ffttmSynch, FEngine);
      ClientE.WaitAtEnd := True;
      ClientE.SetInput(csKeyTableName, csContacts);
      ClientE.SetInputInt(csKeyNumRecordsPerTran, 1000);
      ClientE.SetInputInt(csKeyNumRecords, 20000);
      ClientE.AddToFilter(aFilter);

      { Wait for threads to initialize. }
      ClientA.WaitForReady(clTimeout);
      ClientB.WaitForReady(clTimeout);
      ClientC.WaitForReady(clTimeout);
      ClientD.WaitForReady(clTimeout);
      ClientE.WaitForReady(clTimeout);

      { Build an array of thread handles.  We will use these to know when the
        threads have terminated. }
      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;
      HandleArray[2] := ClientC.Handle;
      HandleArray[3] := ClientD.Handle;
      HandleArray[4] := ClientE.Handle;

      { Tell the threads to start. }
      ClientA.NextStep;
      ClientB.NextStep;
      ClientC.NextStep;
      ClientD.NextStep;
      ClientE.NextStep;

    except
      HandleArray[0] := ClientA.Handle;
      HandleArray[1] := ClientB.Handle;
      HandleArray[2] := ClientC.Handle;
      HandleArray[3] := ClientD.Handle;
      HandleArray[4] := ClientE.Handle;

      ClientA.DieEvent.SignalEvent;
      ClientB.DieEvent.SignalEvent;
      ClientC.DieEvent.SignalEvent;
      ClientD.DieEvent.SignalEvent;
      ClientE.DieEvent.SignalEvent;

      raise;
    end;
  finally
    { Wait for them to finish. }
    PHandleArray := @HandleArray;
    Status := WaitForMultipleObjects(5, pHandleArray, true, ffcl_INFINITE); {!!.06}
//    CheckNotEquals(WAIT_FAILED, Status, 'Thread wait failure');
    Assert(WAIT_FAILED <> Status, 'Thread wait failure');
  end;
end;

{====================================================================}

initialization

  RegisterTest('DB Thread tests', TffDBTest.Suite);
end.
