unit TEST_FFSRLOCK;

interface
uses
  Classes,
  TestFrameWork,
  FFSrBase;

const
  cnMaxFiles = 100;

type
  TffHashTest = class(TTestCase)
  published
    procedure testCreateDestoy;
    procedure testAddRemove;
    procedure testAddRemoveMultiple;
    procedure testAddExisting;
    procedure testGrow;
    procedure testShrink;
    procedure testClear;
    procedure testCount;
    procedure testGet;

    procedure testOnDisposeData;
  end;

  TffHash64Test = class(TTestCase)
  published
    procedure testCreateDestoy;
    procedure testAddRemove;
    procedure testAddRemoveMultiple;
    procedure testAddExisting;
    procedure testGrow;
    procedure testShrink;
    procedure testClear;
    procedure testCount;
    procedure testOnDisposeData;
    procedure testGet;
  end;

  TffThreadHashTest = class(TTestCase)
  published
    procedure testCreateDestoy;
    procedure testAddRemove;
    procedure testAddRemoveMultiple;
    procedure testAddExisting;
    procedure testGrow;
    procedure testShrink;
    procedure testClear;
    procedure testCount;
    procedure testOnDisposeData;
    procedure testGet;
  end;

  TffThreadHash64Test = class(TTestCase)
  published
    procedure testCreateDestoy;
    procedure testAddRemove;
    procedure testAddRemoveMultiple;
    procedure testAddExisting;
    procedure testGrow;
    procedure testShrink;
    procedure testClear;
    procedure testCount;
    procedure testOnDisposeData;
    procedure testGet;
  end;

  TffListTest = class(TTestCase)
  published
    procedure testCreateDestoy;
  end;

  TffThreadListTest = class(TTestCase)
  published
    procedure testCreateDestoy;
    procedure testSimple;
  end;

  TFFBaseLockTest = class(TTestCase)
  protected
    FFI : array[0..pred(cnMaxFiles)] of PffFileInfo;
    TRAN : TffsrTransaction;

    procedure Setup; override;
    procedure Teardown; override;
  end;

  TFFSrLockManagerTest = class(TTestCase)
  protected
  published
    procedure testCreateAndFreeLockManager;
    procedure testFFMapLockName;
  end;


  TFFSrLockContentTests = class(TTestCase)
  protected
  published
    procedure testConditionalConvertExcl;
    procedure testConditionalConvertShare;
  end;

  TFFSrLockTableTests = class(TTestCase)
  protected
  published
    { Simple single thread tests }
    procedure testAcquireOneLock;
    procedure testAcquireAndReleaseLock;
    procedure testAcquireAndReleaseMultipleLocks;
    procedure testAcquireAndReleaseInstantLock;
    procedure testAcquireFailInstantLock;
    procedure testAcquireConditionalLockSuccess;
    procedure testAcquireConditionalLockFail;
    procedure testAcquireCompatibleLock;
    procedure testIncrementLockRefCount;
    procedure testAcquireLockWaitTimeout;
    procedure testLockConversion;

    procedure testLockGranted;
    procedure testIsLockedBy;
    procedure testReleaseTableLockAll;
    { Multiple thread tests }

    { Deadlock tests }
  end;

  TFFSrLockRecordTests = class(TffBaseLockTest)
  published
    { Simple single thread tests }
    procedure testAcquireAndReleaseRecordlock;
    procedure testAcquireAndReleaseMultipleLocks;
    procedure testAcquireAndReleaseInstantLock;
    procedure testAcquireFailInstantLock;
    procedure testAcquireConditionalLockSuccess;
    procedure testAcquireConditionalLockFail;
    procedure testAcquireCompatibleLock;
    procedure testRecordLockRefCount;
    procedure testAcquireLockWaitTimeout;
    procedure testReleaseTransaction;
    procedure testLockConversion;

    procedure testLockGranted;
    procedure testIsLockedBy;
    procedure testReleaseTransactionLocks;
    { Multiple thread tests }

    { Deadlock tests }
  end;

  function Suite: ITest;

implementation
uses
  FFlLBase, FFSrLock, FFHash;

function Suite: ITest;
begin
  Result := MakeTestSuites('Lock Manager Suites',
                        [
//                          TffHashTest,
//                          TffHash64Test,
//                          TffThreadHashTest,
//                          TffThreadHash64Test,
//                          TffListTest,
//                          TffThreadListTest,
//                          TffBaseLockTest,
//                          TffSrLockManagerTest,
                          TffSrLockContentTests
//                          TffSrLockTableTests,
//                          TffSrLockRecordTests
                          ]);
end;

procedure TffBaseLockTest.Setup;
var
  index : integer;
begin
  for index := 0 to pred(cnMaxFiles) do begin
    GetMem(FFI[index], sizeOf(TfffileInfo));
    Fillchar(FFI[index]^, sizeOf(TffFileInfo), 0);
  end;
  TRAN := TffSrTransaction.Create(1, False, False);
end;

procedure TffBaseLockTest.Teardown;
var
  index : integer;
begin
  TRAN.Free;
  for index := 0 to pred(cnMaxFiles) do begin
    if assigneD(FFI[index]^.fiRecordLocks) then
      FFI[index]^.fiRecordLocks.Free;
    FreeMem(FFI[index], sizeOf(TffFileInfo));
  end;
end;


{ TFFSrLockContentTests }
procedure TffSrLockContentTests.testConditionalConvertExcl;
const
  DBID = 1;
var
  aTran : TffSrTransaction;
  aTable : TffObject;
  Container : TffLockContainer;
  LMan : TffLockManager;
  LStatus : TffLockRequestStatus;
begin
  aTable := TffObject.Create;
  aTran := TffSrTransaction.Create(DBID, False, False);
  aTable := TffObject.Create;
  LMan := TffLockManager.Create;
  Container := TffLockContainer.Create;
  try
    LStatus := LMan.AcquireContentLock(Container, aTable, aTran,
                                       True, 5000, ffsltExclusive);
    Assert(LStatus = fflrsGranted, 'Lock not granted.');
    LStatus := LMan.AcquireContentLock(Container, aTable, aTran,
                                       True, 5000, ffsltExclusive);
    Assert(LStatus = fflrsGranted, 'Lock not granted.');
  finally
    aTable.Free;
    Container.Free;
    aTran.Free;
    LMan.Free;
  end;
end;

procedure TffSrLockContentTests.testConditionalConvertShare;
const
  DBID = 1;
var
  aTran : TffSrTransaction;
  aTable : TffObject;
  Container : TffLockContainer;
  LMan : TffLockManager;
  LStatus : TffLockRequestStatus;
begin
  aTable := TffObject.Create;
  aTran := TffSrTransaction.Create(DBID, False, False);
  aTable := TffObject.Create;
  LMan := TffLockManager.Create;
  Container := TffLockContainer.Create;
  try
    LStatus := LMan.AcquireContentLock(Container, aTable, aTran,
                                       True, 5000, ffsltShare);
    Assert(LStatus = fflrsGranted, 'Lock not granted.');
    LStatus := LMan.AcquireContentLock(Container, aTable, aTran,
                                       True, 5000, ffsltExclusive);
    Assert(LStatus = fflrsGranted, 'Lock not granted.');
  finally
    aTable.Free;
    Container.Free;
    aTran.Free;
    LMan.Free;
  end;
end;

{ TFFSrLockTableTests }

procedure TFFSrLockTableTests.testAcquireAndReleaseInstantLock;
const
 RID = 1;
 SID = 2;
 TiO = 2000;
var
  LMan : TffLockManager;
  LStatus : TffLockRequestStatus;
begin
  LMan := TffLockManager.Create;
  try
    LStatus := LMan.AcquireTableLock(RID,
                          ffsltIntentS,
                          False,
                          Tio,
                          SID);
    Assert(LStatus = fflrsGranted, 'Invalid Lock Status Returned');
    LMan.ReleaseTableLock(RID, SID);
  finally
    LMan.Free;
  end;
end;

procedure TFFSrLockTableTests.testAcquireAndReleaseMultipleLocks;
const
 RID = 1;
 TID = 2;
 SID = 3;
 TiO = 2000;
var
  LMan : TffLockManager;
  Count : Integer;
  ls : TffLockRequestStatus;
begin
  LMan := TffLockManager.Create;
  try
    for Count := 0 to 100 do begin
      ls := LMan.AcquireTableLock(RID + Count,
                            ffsltIntentS,
                            False,
                            TiO,
                            SID + Count);
      Assert(ls=fflrsGranted, 'Lock not granted');
    end;
    for Count := 0 to 100 do
      LMan.ReleaseTableLock(RID + Count,
                            SID + Count);
  finally
    LMan.Free;
  end;
end;

procedure TFFSrLockTableTests.testAcquireAndReleaseLock;
const
 RID = 1;
 SID = 3;
 TiO = 2000;
var
  LMan : TffLockManager;
begin
  LMan := TffLockManager.Create;
  try
    LMan.AcquireTableLock(RID,
                          ffsltIntentS,
                          False,
                          TiO,
                          SID);
    LMan.ReleaseTableLock(RID, SID);
  finally
    LMan.Free;
  end;
end;

procedure TFFSrLockTableTests.testAcquireCompatibleLock;
const
 RID = 1;
 SID = 2;
 TiO = 2000;
var
  LMan    : TffLockManager;
  LStatus : TffLockRequestStatus;
begin
  LMan := TffLockManager.Create;
  try
    LStatus := LMan.AcquireTableLock(RID,
                          ffsltIntentS,
                          False,
                          TiO,
                          SID+1);
    Assert(LStatus = fflrsGranted, 'Invalid Lock Status Returned');
    LStatus := LMan.AcquireTableLock(RID,
                          ffsltIntentS,
                          False,
                          TiO,
                          SID);
    Assert(LStatus = fflrsGranted, 'Invalid Lock Status Returned');
    LMan.ReleaseTableLock(RID, SID);
  finally
    LMan.Free;
  end;
end;

procedure TFFSrLockTableTests.testAcquireConditionalLockFail;
const
 RID = 1;
 SID = 2;
 TiO = 2000;
var
  LMan : TffLockManager;
  LStatus : TffLockRequestStatus;
begin
  LMan := TffLockManager.Create;
  try
    LStatus := LMan.AcquireTableLock(RID,
                          ffsltExclusive,
                          False,
                          TiO,
                          SID+1);
    Assert(LStatus = fflrsGranted, 'Invalid Lock Status Returned');
    LStatus := LMan.AcquireTableLock(RID,
                          ffsltIntentS,
                          True,
                          TiO,
                          SID);
    Assert(LStatus = fflrsRejected, 'Invalid Lock Status Returned');
    LMan.ReleaseTableLock(RID, SID);
  finally
    LMan.Free;
  end;

end;

procedure TFFSrLockTableTests.testAcquireConditionalLockSuccess;
const
 RID = 1;
 SID = 2;
 TiO = 2000;
var
  LMan : TffLockManager;
  LStatus : TffLockRequestStatus;
begin
  LMan := TffLockManager.Create;
  try
    LStatus := LMan.AcquireTableLock(RID,
                          ffsltIntentS,
                          True,
                          TiO,
                          SID);
    Assert(LStatus = fflrsGranted, 'Invalid Lock Status Returned');
    LMan.ReleaseTableLock(RID, SID);
  finally
    LMan.Free;
  end;
end;

procedure TFFSrLockTableTests.testAcquireOneLock;
var
  LMan : TffLockManager;
begin
  LMan := TffLockManager.Create;
  try
    LMan.AcquireTableLock(1,
                          ffsltIntentS,
                          False,
                          2000,
                          2);
  finally
    LMan.Free;
  end;
end;

procedure TFFSrLockTableTests.testAcquireFailInstantLock;
const
 RID = 1;
 SID = 2;
 TiO = 2000;
var
  LMan : TffLockManager;
  LStatus : TffLockRequestStatus;
begin
  LMan := TffLockManager.Create;
  try
    LStatus := LMan.AcquireTableLock(RID,
                          ffsltExclusive,
                          False,
                          TiO,
                          SID+1);
    Assert(LStatus = fflrsGranted, 'Invalid Lock Status Returned');
    LStatus := LMan.AcquireTableLock(RID,
                          ffsltIntentS,
                          False,
                          TiO,
                          SID);
    Assert(LStatus = fflrsRejected, 'Invalid Lock Status Returned');
    LMan.ReleaseTableLock(RID, SID+1);
  finally
    LMan.Free;
  end;
end;

procedure TFFSrLockTableTests.testAcquireLockWaitTimeout;
const
  RID = 1;
  SID = 2;
  TiO = 2000;
var
  LMan : TffLockManager;
  LStatus : TffLockRequestStatus;
begin
  LMan := TffLockManager.Create;
  try
    LStatus := LMan.AcquireTableLock(RID,
                          ffsltExclusive,
                          False,
                          TiO,
                          SID+1);
    Assert(LStatus = fflrsGranted, 'Invalid Lock Status Returned');
    LStatus := LMan.AcquireTableLock(RID,
                          ffsltIntentS,
                          False,
                          TiO,
                          SID);
    Assert(LStatus = fflrsTimeout, 'Invalid Lock Status Returned');
    LMan.ReleaseTableLock(RID, SID+1);
  finally
    LMan.Free;
  end;
end;

procedure TFFSrLockTableTests.testIsLockedBy;
const
 RID = 1;
 TID = 2;
 SID = 3;
 TiO = 2000;
var
  LMan : TffLockManager;
  ls : TffLockRequestStatus;
begin
  LMan := TffLockManager.Create;
  try
    ls := LMan.AcquireTableLock(RID,
                                ffsltIntentS,
                                False,
                                TiO,
                                SID);
    Assert(ls=fflrsGranted, 'Lock not granted');

    Assert(LMan.IsTableLockedBy(RID, SID, ffsltIntentS), 'Invalid Result');
  finally
    LMan.Free;
  end;
end;

procedure TFFSrLockTableTests.testLockConversion;
const
 RID = 1;
 SID = 2;
 TiO = 2000;
var
  LMan : TffLockManager;
  LStatus : TffLockRequestStatus;
begin
  { Convert to less }
  LMan := TffLockManager.Create;
  try
    LStatus := LMan.AcquireTableLock(RID,
                                     ffsltSIX,
                                     True,
                                     TiO,
                                     SID);
    Assert(LStatus = fflrsGranted, 'Invalid Lock Status Returned');
    LStatus := LMan.AcquireTableLock(RID,
                                     ffsltShare,
                                     True,
                                     TiO,
                                     SID);
    Assert(LStatus = fflrsGranted, 'Invalid Lock Status Returned');
    LMan.ReleaseTableLock(RID, SID);
  finally
    LMan.Free;
  end;

  { Convert to more }
  LMan := TffLockManager.Create;
  try
    LStatus := LMan.AcquireTableLock(RID,
                                     ffsltShare,
                                     True,
                                     TiO,
                                     SID);
    Assert(LStatus = fflrsGranted, 'Invalid Lock Status Returned');
    LStatus := LMan.AcquireTableLock(RID,
                                     ffsltSIX,
                                     True,
                                     TiO,
                                     SID);
    Assert(LStatus = fflrsGranted, 'Invalid Lock Status Returned');
    LMan.ReleaseTableLock(RID, SID);
  finally
    LMan.Free;
  end;
end;

procedure TFFSrLockTableTests.testLockGranted;
const
 RID = 1;
 TID = 2;
 SID = 3;
 TiO = 2000;
var
  LMan : TffLockManager;
  ls : TffLockRequestStatus;
begin
  LMan := TffLockManager.Create;
  try
    ls := LMan.AcquireTableLock(RID,
                                ffsltIntentS,
                                False,
                                TiO,
                                SID);
    Assert(ls=fflrsGranted, 'Lock not granted');

    Assert(LMan.TableLockGranted(RID) = ffsltIntentS, 'Invalid Result');
  finally
    LMan.Free;
  end;
end;

procedure TFFSrLockTableTests.testReleaseTableLockAll;
const
 RID = 1;
 TID = 2;
 SID = 3;
 TiO = 2000;
var
  LMan : TffLockManager;
  Count : Integer;
  ls : TffLockRequestStatus;
begin
  LMan := TffLockManager.Create;
  try
    for Count := 0 to 50 do begin
      ls := LMan.AcquireTableLock(RID,
                            ffsltIntentS,
                            False,
                            TiO,
                            SID);
      Assert(ls=fflrsGranted, 'Lock not granted');
    end;

    LMan.ReleaseTableLockAll(RID, SID);
  finally
    LMan.Free;
  end;
end;

procedure TFFSrLockTableTests.testIncrementLockRefCount;
const
 RID = 1;
 SID = 2;
 TiO = 2000;
var
  LMan    : TffLockManager;
  LStatus : TffLockRequestStatus;
begin
  LMan := TffLockManager.Create;
  try
    LStatus := LMan.AcquireTableLock(RID,
                          ffsltExclusive,
                          False,
                          TiO,
                          SID);
    Assert(LStatus = fflrsGranted, 'Invalid Lock Status Returned');
    LStatus := LMan.AcquireTableLock(RID,
                          ffsltIntentS,
                          False,
                          TiO,
                          SID);
    Assert(LStatus = fflrsGranted, 'Invalid Lock Status Returned');
    LMan.ReleaseTableLock(RID, SID);
    LMan.ReleaseTableLock(RID, SID);
  finally
    LMan.Free;
  end;
end;


{ TFFSrLockRecordTests }

procedure TFFSrLockRecordTests.testAcquireAndReleaseInstantLock;
const
 TID = 2;
 CID = 3;
 FID = 4;
 TiO = 2000;
var
  LMan : TffLockManager;
  LStatus : TffLockRequestStatus;
  RID  : TffInt64;
begin
  FFIntToI64(1, RID);
  LMan := TffLockManager.Create;
  try
    LStatus := LMan.AcquireRecordLock(RID,
                                      FFI[0],
                                      ffsltIntentS,
                                      False,
                                      Tio,
                                      TRAN,
                                      CID);
    Assert(LStatus = fflrsGranted, 'Invalid Lock Status Returned');
    LMan.ReleaseRecordLock(RID, FFI[0], TRAN, CID);
  finally
    LMan.Free;
  end;
end;

procedure TFFSrLockRecordTests.testAcquireAndReleaseMultipleLocks;
const
 TID = 2;
 CID = 3;
 FID = 4;
 TiO = 2000;
var
  LMan : TffLockManager;
  Count : Integer;
  ls : TffLockRequestStatus;
  RID  : TffInt64;
begin
  FFIntToI64(1, RID);
  LMan := TffLockManager.Create;
  try
    for Count := 0 to pred(cnMaxFiles) do begin
      ffI64AddInt(RID, 1, RID);
      ls := LMan.AcquireRecordLock(RID,
                                   FFI[Count],
                                   ffsltIntentS,
                                   False,
                                   TiO,
                                   TRAN,
                                   CID + Count);
      Assert(ls=fflrsGranted, 'Lock not granted');
    end;
    ffIntToI64(1, RID);
    for Count := 0 to pred(cnMaxFiles) do begin
      ffI64AddInt(RID, 1, RID);
      LMan.ReleaseRecordLock(RID,
                             FFI[Count],
                             TRAN,
                             CID + Count);
    end;
  finally
    LMan.Free;
  end;
end;

procedure TFFSrLockRecordTests.testAcquireAndReleaseRecordlock;
const
 TID = 2;
 CID = 3;
 FID = 4;
 TiO = 2000;
var
  LMan : TffLockManager;
  RID  : TffInt64;
begin
  FFIntToI64(1, RID);
  LMan := TffLockManager.Create;
  try
    LMan.AcquireRecordLock(RID,
                           FFI[0],
                           ffsltIntentS,
                           False,
                           TiO,
                           TRAN,
                           CID);
    LMan.ReleaseRecordLock(RID, FFI[0], TRAN, CID);
  finally
    LMan.Free;
  end;
end;

procedure TFFSrLockRecordTests.testAcquireCompatibleLock;
const
 TID = 2;
 CID = 3;
 FID = 4;
 TiO = 2000;
var
  LMan    : TffLockManager;
  LStatus : TffLockRequestStatus;
  RID  : TffInt64;
begin
  FFIntToI64(1, RID);
  LMan := TffLockManager.Create;
  try
    LStatus := LMan.AcquireRecordLock(RID,
                                      FFI[0],
                                      ffsltIntentS,
                                      False,
                                      TiO,
                                      TRAN,
                                      CID+1);
    Assert(LStatus = fflrsGranted, 'Invalid Lock Status Returned');
    LStatus := LMan.AcquireRecordLock(RID,
                                      FFI[0],
                                      ffsltIntentS,
                                      False,
                                      TiO,
                                      TRAN,
                                      CID);
    Assert(LStatus = fflrsGranted, 'Invalid Lock Status Returned');
    LMan.ReleaseRecordLock(RID, FFI[0], TRAN, CID+1);
    LMan.ReleaseRecordLock(RID, FFI[0], TRAN, CID);
  finally
    LMan.Free;
  end;
end;

procedure TFFSrLockRecordTests.testAcquireConditionalLockFail;
const
 TID = 2;
 CID = 3;
 FID = 4;
 TiO = 2000;
var
  LMan : TffLockManager;
  LStatus : TffLockRequestStatus;
  RID  : TffInt64;
begin
  FFIntToI64(1, RID);
  LMan := TffLockManager.Create;
  try
    LStatus := LMan.AcquireRecordLock(RID,
                                      FFI[0],
                                      ffsltExclusive,
                                      False,
                                      TiO,
                                      TRAN,
                                      CID+1);
    Assert(LStatus = fflrsGranted, 'Invalid Lock Status Returned');
    LStatus := LMan.AcquireRecordLock(RID,
                                      FFI[0],
                                      ffsltIntentS,
                                      True,
                                      TiO,
                                      TRAN,
                                      CID);
    Assert(LStatus = fflrsRejected, 'Invalid Lock Status Returned');
    LMan.ReleaseRecordLock(RID, FFI[0], TRAN, CID+1);
  finally
    LMan.Free;
  end;
end;

procedure TFFSrLockRecordTests.testAcquireConditionalLockSuccess;
const
 TID = 2;
 CID = 3;
 FID = 4;
 TiO = 2000;
var
  LMan : TffLockManager;
  LStatus : TffLockRequestStatus;
  RID  : TffInt64;
begin
  FFIntToI64(1, RID);
  LMan := TffLockManager.Create;
  try
    LStatus := LMan.AcquireRecordLock(RID,
                                      FFI[0],
                                      ffsltIntentS,
                                      True,
                                      TiO,
                                      TRAN,
                                      CID);
    Assert(LStatus = fflrsGranted, 'Invalid Lock Status Returned');
    LMan.ReleaseRecordLock(RID, FFI[0], TRAN, CID);
  finally
    LMan.Free;
  end;
end;

procedure TFFSrLockRecordTests.testAcquireFailInstantLock;
const
 TID = 2;
 CID = 3;
 FID = 4;
 TiO = 2000;
var
  LMan : TffLockManager;
  LStatus : TffLockRequestStatus;
  RID  : TffInt64;
begin
  FFIntToI64(1, RID);
  LMan := TffLockManager.Create;
  try
    LStatus := LMan.AcquireRecordLock(RID,
                                      FFI[0],
                                      ffsltExclusive,
                                      False,
                                      TiO,
                                      TRAN,
                                      CID+1);
    Assert(LStatus = fflrsGranted, 'Invalid Lock Status Returned');
    LStatus := LMan.AcquireRecordLock(RID,
                                      FFI[0],
                                      ffsltIntentS,
                                      False,
                                      TiO,
                                      TRAN,
                                      CID);
    Assert(LStatus = fflrsRejected, 'Invalid Lock Status Returned');
    LMan.ReleaseRecordLock(RID, FFI[0], TRAN, CID+1);
  finally
    LMan.Free;
  end;
end;

procedure TFFSrLockRecordTests.testAcquireLockWaitTimeout;
const
  TID = 2;
  CID = 3;
  FID = 4;
  TiO = 2000;
var
  LMan : TffLockManager;
  LStatus : TffLockRequestStatus;
  RID  : TffInt64;
begin
  FFIntToI64(1, RID);
  LMan := TffLockManager.Create;
  try
    LStatus := LMan.AcquireRecordLock(RID,
                                      FFI[0],
                                      ffsltExclusive,
                                      False,
                                      TiO,
                                      TRAN,
                                      CID+1);
    Assert(LStatus = fflrsGranted, 'Invalid Lock Status Returned');
    LStatus := LMan.AcquireRecordLock(RID,
                                      FFI[0],
                                      ffsltIntentS,
                                      False,
                                      TiO,
                                      TRAN,
                                      CID);
    Assert(LStatus = fflrsTimeout, 'Invalid Lock Status Returned');
    LMan.ReleaseRecordLock(RID, FFI[0], TRAN, CID+1);
  finally
    LMan.Free;
  end;

end;

procedure TFFSrLockManagerTest.testFFMapLockName;
const
  ffcLockNone      = 'None';
  ffcLockIntentS   = 'Intent Shared';
  ffcLockIntentX   = 'Intent Exclusive';
  ffcLockShare     = 'Share';
  ffcLockSIX       = 'Shared Intent Exclusive';
  ffcLockUpdate    = 'Update';
  ffcLockExclusive = 'Exclusive';

var
  LT : TffSrLockType;
begin
  LT := ffsltNone;
  Assert(FFMapLockToName(LT) = ffcLockNone, 'Incorrect Lock Name');

  LT := ffsltIntentS;
  Assert(FFMapLockToName(LT) = ffcLockIntentS, 'Incorrect Lock Name');

  LT := ffsltIntentX;
  Assert(FFMapLockToName(LT) = ffcLockIntentX, 'Incorrect Lock Name');

  LT := ffsltShare;
  Assert(FFMapLockToName(LT) = ffcLockShare, 'Incorrect Lock Name');

  LT := ffsltSIX;
  Assert(FFMapLockToName(LT) = ffcLockSIX, 'Incorrect Lock Name');

  LT := ffsltUpdate;
  Assert(FFMapLockToName(LT) = ffcLockUpdate, 'Incorrect Lock Name');

  LT := ffsltExclusive;
  Assert(FFMapLockToName(LT) = ffcLockExclusive, 'Incorrect Lock Name');
end;


procedure TFFSrLockRecordTests.testIsLockedBy;
const
 CID = 1;
 TID = 2;
 SID = 3;
 FID = 4;
 TiO = 2000;
var
  RID : TffInt64;
  LMan : TffLockManager;
  ls : TffLockRequestStatus;
begin
  LMan := TffLockManager.Create;
  try
    ffIntToI64(1, RID);
    ls := LMan.AcquireRecordLock(RID,
                                 FFI[0],
                                 ffsltIntentS,
                                 False,
                                 TiO,
                                 TRAN,
                                 CID);
    Assert(ls=fflrsGranted, 'Lock not granted');

    Assert(LMan.IsRecordLocked(RID, FFI[0]), 'Invalid Result');

    LMan.ReleaseRecordLock(RID, FFI[0], TRAN, CID);
  finally
    LMan.Free;
  end;
end;

procedure TFFSrLockRecordTests.testLockConversion;
begin
{ TODO -oBen Oram -cLock Manager : TffSrLocRecordTests.testLockConversion - Write Test}
end;

procedure TFFSrLockRecordTests.testLockGranted;
const
 CID = 1;
 TID = 2;
 FID = 4;
 TiO = 2000;
var
  RID : TffInt64;
  LMan : TffLockManager;
  ls : TffLockRequestStatus;
begin
  LMan := TffLockManager.Create;
  try
    ffIntToI64(1, RID);
    ls := LMan.AcquireRecordLock(RID,
                                 FFI[0],
                                 ffsltIntentS,
                                 False,
                                 TiO,
                                 TRAN,
                                 CID);
    Assert(ls=fflrsGranted, 'Lock not granted');

    Assert(LMan.RecordLockGranted(RID, FFI[0]) = ffsltIntentS, 'Invalid Result');

    LMan.ReleaseRecordLock(RID, FFI[0], TRAN, CID);
  finally
    LMan.Free;
  end;
end;

procedure TFFSrLockRecordTests.testRecordLockRefCount;
const
 TID = 2;
 CID = 3;
 FID = 4;
 TiO = 2000;
var
  LMan    : TffLockManager;
  LStatus : TffLockRequestStatus;
  RID  : TffInt64;
begin
  FFIntToI64(1, RID);
  LMan := TffLockManager.Create;
  try
    LStatus := LMan.AcquireRecordLock(RID,
                                      FFI[0],
                                      ffsltExclusive,
                                      False,
                                      TiO,
                                      TRAN,
                                      CID);
    Assert(LStatus = fflrsGranted, 'Invalid Lock Status Returned');
    LStatus := LMan.AcquireRecordLock(RID,
                                      FFI[0],
                                      ffsltIntentS,
                                      False,
                                      TiO,
                                      TRAN,
                                      CID);
    Assert(LStatus = fflrsGranted, 'Invalid Lock Status Returned');
    LMan.ReleaseRecordLock(RID, FFI[0], TRAN, CID);
    LMan.ReleaseRecordLock(RID, FFI[0], TRAN, CID);
  finally
    LMan.Free;
  end;
end;

procedure TFFSrLockRecordTests.testReleaseTransaction;
begin
{ TODO -oBen Oram -cLock Manager : TffSrLocRecordTests.testReleaseTransaction - Write Test}
end;

procedure TFFSrLockRecordTests.testReleaseTransactionLocks;
const
 TID = 2;
 SID = 3;
 FID = 4;
 CID = 5;
 TiO = 2000;
var
  RID : TffInt64;
  LMan : TffLockManager;
  Count : Integer;
  ls : TffLockRequestStatus;
begin
  LMan := TffLockManager.Create;
  try
    ffIntToI64(1, RID);
    for Count := 0 to 50 do begin
      ffIntToI64(Count, RID);
      ls := LMan.AcquireRecordLock(RID,
                                   FFI[0],
                                   ffsltIntentS,
                                   False,
                                   TiO,
                                   TRAN,
                                   CID);
      Assert(ls=fflrsGranted, 'Lock not granted');
    end;

    LMan.ReleaseTransactionLocks(TRAN, True);
  finally
    LMan.Free;
  end;
end;

{ TFFSrLockManagerTest }

procedure TFFSrLockManagerTest.testCreateAndFreeLockManager;
var
  LMan : TffLockManager;
begin
  LMan := TffLockManager.Create;
  try
  finally
    LMan.Free;
  end;
end;

{ TffThreadListTest }

procedure TffThreadListTest.testSimple;
var
  TL : TffThreadList;
  TI : TffSelfListItem;
  PTI : Pointer;
begin
  TI := TffSelfListItem.Create;
  TL := TffThreadList.Create;
  try
    TL.BeginWrite;
    try
      TL.Insert(TI);
      PTI := TI.Key;
    finally
      TL.BeginWrite;
    end;

    TL.BeginWrite;
    try
      TL.Delete(PTI);
    finally
      TL.EndWrite;
    end;
  finally
    TL.Free;
  end;
end;

{ TffHashTest }

procedure TffHashTest.testAddExisting;
var
  Hash : TffHash;
  Worked : Boolean;
begin
  Hash := TffHash.Create(0);
  try
    Hash.Add(100, nil);
    Worked := Hash.Add(100, nil);
    Assert(not Worked, 'You should not be able to add an existing key to the hash table!');
  finally
    Hash.Free;
  end;
end;

procedure TffHashTest.testAddRemove;
var
  Hash : TffHash;
begin
  Hash := TffHash.Create(0);
  try
    Hash.Add(100, nil);
    Hash.Remove(100);
  finally
    Hash.Free;
  end;
end;

procedure TffHashTest.testAddRemoveMultiple;
var
  Hash : TffHash;
  Count : Integer;
begin
  Hash := TffHash.Create(0);
  try
    for Count := 1 to 20 do
      Hash.Add(100*Count, nil);
    for Count := 1 to 20 do
      Hash.Remove(100*Count);
  finally
    Hash.Free;
  end;
end;

procedure TffHashTest.testClear;
var
  Hash : TffHash;
  Count : Integer;
begin
  Hash := TffHash.Create(0);
  try
    for Count := 1 to 20 do
      Hash.Add(100*Count, nil);
    Hash.Clear;
  finally
    Hash.Free;
  end;
end;

procedure TffHashTest.testCount;
var
  Hash : TffHash;
  Count : Integer;
begin
  Hash := TffHash.Create(0);
  try
    for Count := 1 to 20 do
      Hash.Add(100*Count, nil);
    Assert(Hash.Count = 20, 'Invalid Count');
    Hash.Clear;
  finally
    Hash.Free;
  end;
end;

procedure TffHashTest.testCreateDestoy;
var
  Hash : TffHash;
begin
  hash := TffHash.Create(0);
  try
    Assert('TffHash' = Hash.ClassName, 'Error');
  finally
    Hash.Free;
  end;
end;

procedure TffHashTest.testGet;
var
  Hash : TffHash;
begin
  Hash := TffHash.Create(0);
  try
    Hash.Add(100, Self);
    Assert(Hash.Get(100) = Self, 'Get Error');
    Hash.Clear;
  finally
    Hash.Free;
  end;
end;

procedure TffHashTest.testGrow;
var
  Hash : TffHash;
  Count : Integer;
begin
  Hash := TffHash.Create(0);
  try
    for Count := 1 to 100 do
      Hash.Add(100*Count, nil);
    Hash.Clear;
  finally
    Hash.Free;
  end;
end;

procedure TffHashTest.testOnDisposeData;
begin

end;

procedure TffHashTest.testShrink;
var
  Hash : TffHash;
  Count : Integer;
begin
  Hash := TffHash.Create(0);
  try
    for Count := 1 to 100 do
      Hash.Add(100*Count, nil);
    for Count := 1 to 100 do
      Hash.Remove(100*Count);
  finally
    Hash.Free;
  end;
end;

{ TffHash64Test }

procedure TffHash64Test.testAddExisting;
var
  Hash : TffHash64;
  Worked : Boolean;
  I64 : TffInt64;
begin
  Hash := TffHash64.Create(0);
  try
    ffIntToI64(100, I64);
    Hash.Add(I64, nil);
    Worked := Hash.Add(I64, nil);
    Assert(not Worked, 'You should not be able to add an existing key to the hash table!');
  finally
    Hash.Free;
  end;
end;

procedure TffHash64Test.testAddRemove;
var
  Hash : TffHash64;
  I64 : TffInt64;
begin
  Hash := TffHash64.Create(0);
  try
    ffIntToI64(100, I64);
    Hash.Add(I64, nil);
    Hash.Remove(I64);
  finally
    Hash.Free;
  end;
end;

procedure TffHash64Test.testAddRemoveMultiple;
var
  Hash : TffHash64;
  Count : Integer;
  I64 : TffInt64;
begin
  Hash := TffHash64.Create(0);
  try
    for Count := 1 to 20 do begin
      ffIntToI64(100*Count, I64);
      Hash.Add(I64, nil);
    end;
    for Count := 1 to 20 do begin
      ffIntToI64(100*Count, I64);
      Hash.Remove(I64);
    end;
  finally
    Hash.Free;
  end;
end;

procedure TffHash64Test.testClear;
var
  Hash : TffHash64;
  Count : Integer;
  I64 : TffInt64;
begin
  Hash := TffHash64.Create(0);
  try
    for Count := 1 to 20 do begin
      ffIntToI64(100*Count, I64);
      Hash.Add(I64, nil);
    end;
    Hash.Clear;
  finally
    Hash.Free;
  end;
end;

procedure TffHash64Test.testCount;
var
  Hash : TffHash64;
  Count : Integer;
  I64 : TffInt64;
begin
  Hash := TffHash64.Create(0);
  try
    for Count := 1 to 20 do begin
      ffIntToI64(100*Count, I64);
      Hash.Add(I64, nil);
    end;
    Assert(Hash.Count = 20, 'Invalid Count');
    Hash.Clear;
  finally
    Hash.Free;
  end;
end;

procedure TffHash64Test.testCreateDestoy;
var
  Hash : TffHash64;
begin
  hash := TffHash64.Create(0);
  try
    Assert('TffHash64' = Hash.ClassName, 'Error');
  finally
    Hash.Free;
  end;
end;

procedure TffHash64Test.testGet;
var
  Hash : TffHash64;
  I64 : TffInt64;
begin
  Hash := TffHash64.Create(0);
  try
    ffIntToI64(100, I64);
    Hash.Add(I64, Self);
    Assert(Hash.Get(I64) = Self, 'Get Error');
    Hash.Clear;
  finally
    Hash.Free;
  end;
end;

procedure TffHash64Test.testGrow;
var
  Hash : TffHash64;
  Count : Integer;
  I64 : TffInt64;
begin
  Hash := TffHash64.Create(0);
  try
    for Count := 1 to 100 do begin
      ffIntToI64(100*Count, I64);
      Hash.Add(I64, nil);
    end;  
    Hash.Clear;
  finally
    Hash.Free;
  end;
end;

procedure TffHash64Test.testOnDisposeData;
begin

end;

procedure TffHash64Test.testShrink;
var
  Hash : TffHash64;
  Count : Integer;
  I64 : TffInt64;
begin
  Hash := TffHash64.Create(0);
  try
    for Count := 1 to 100 do begin
      ffIntToI64(100*Count, I64);
      Hash.Add(I64, nil);
    end;
    for Count := 1 to 100 do begin
      ffIntToI64(100*Count, I64);
      Hash.Remove(I64);
    end;  
  finally
    Hash.Free;
  end;
end;

{ TffThreadHashTest }

procedure TffThreadHashTest.testAddExisting;
var
  Hash : TffThreadHash;
  Worked : Boolean;
begin
  Hash := TffThreadHash.Create(0);
  try
    Hash.BeginWrite;
    try
      Hash.Add(100, nil);
      Worked := Hash.Add(100, nil);
      Assert(not Worked, 'You should not be able to add an existing key to the hash table!');
    finally
      Hash.EndWrite;
    end;
  finally
    Hash.Free;
  end;
end;

procedure TffThreadHashTest.testAddRemove;
var
  Hash : TffThreadHash;
begin
  Hash := TffThreadHash.Create(0);
  try
    Hash.BeginWrite;
    try
      Hash.Add(100, nil);
      Hash.Remove(100);
    finally
      Hash.EndWrite;
    end;
  finally
    Hash.Free;
  end;
end;

procedure TffThreadHashTest.testAddRemoveMultiple;
var
  Hash : TffThreadHash;
  Count : Integer;
begin
  Hash := TffThreadHash.Create(0);
  try
    Hash.BeginWrite;
    try
      for Count := 1 to 20 do
        Hash.Add(100*Count, nil);
      for Count := 1 to 20 do
        Hash.Remove(100*Count);
    finally
      Hash.EndWrite;
    end;
  finally
    Hash.Free;
  end;
end;

procedure TffThreadHashTest.testClear;
var
  Hash : TffThreadHash;
  Count : Integer;
begin
  Hash := TffThreadHash.Create(0);
  try
    hash.BeginWrite;
    try
      for Count := 1 to 20 do
        Hash.Add(100*Count, nil);
      Hash.Clear;
    finally
      Hash.EndWrite;
    end;
  finally
    Hash.Free;
  end;
end;

procedure TffThreadHashTest.testCount;
var
  Hash : TffThreadHash;
  Count : Integer;
begin
  Hash := TffThreadHash.Create(0);
  try
    Hash.BeginWrite;
    try
      for Count := 1 to 20 do
        Hash.Add(100*Count, nil);
      Assert(Hash.Count = 20, 'Invalid Count');
      Hash.Clear;
    finally
      Hash.EndWrite;
    end;
  finally
    Hash.Free;
  end;
end;

procedure TffThreadHashTest.testCreateDestoy;
var
  Hash : TffThreadHash;
begin
  hash := TffThreadHash.Create(0);
  try
    Assert('TffThreadHash' = Hash.ClassName, 'Error');
  finally
    Hash.Free;
  end;
end;
procedure TffThreadHashTest.testGet;
var
  Hash : TffThreadHash;
begin
  Hash := TffThreadHash.Create(0);
  try
    Hash.BeginWrite;
    try
      Hash.Add(100, Self);
    finally
      Hash.EndWrite;
    end;

    hash.BeginRead;
    try
      Assert(Hash.Get(100) = Self, 'Get Error');
    finally
      Hash.EndRead;
    end;

    hash.BeginWrite;
    try
      Hash.Clear;
    finally
      Hash.EndWrite;
    end;
  finally
    Hash.Free;
  end;
end;

procedure TffThreadHashTest.testGrow;
var
  Hash : TffThreadHash;
  Count : Integer;
begin
  Hash := TffThreadHash.Create(0);
  try
    Hash.BeginWrite;
    try
      for Count := 1 to 100 do
        Hash.Add(100*Count, nil);
      Hash.Clear;
    finally
      Hash.EndWrite;
    end;
  finally
    Hash.Free;
  end;
end;

procedure TffThreadHashTest.testOnDisposeData;
begin

end;

procedure TffThreadHashTest.testShrink;
var
  Hash : TffThreadHash;
  Count : Integer;
begin
  Hash := TffThreadHash.Create(0);
  try
    Hash.BeginWrite;
    try
      for Count := 1 to 100 do
        Hash.Add(100*Count, nil);
      for Count := 1 to 100 do
        Hash.Remove(100*Count);
    finally
      Hash.EndWrite;
    end;  
  finally
    Hash.Free;
  end;
end;

{ TffThreadHash64Test }

procedure TffThreadHash64Test.testAddExisting;
var
  Hash : TffThreadHash64;
  Worked : Boolean;
  I64 : TffInt64;
begin
  Hash := TffThreadHash64.Create(0);
  try
    Hash.BeginWrite;
    try
      ffIntToI64(100, I64);
      Hash.Add(I64, nil);
      Worked := Hash.Add(I64, nil);
      Assert(not Worked, 'You should not be able to add an existing key to the hash table!');
    finally
      Hash.EndWrite;
    end;
  finally
    Hash.Free;
  end;
end;

procedure TffThreadHash64Test.testAddRemove;
var
  Hash : TffThreadHash64;
  I64 : TffInt64;
begin
  Hash := TffThreadHash64.Create(0);
  try
    Hash.BeginWrite;
    try
      ffIntToI64(100, I64);
      Hash.Add(I64, nil);
      Hash.Remove(I64);
    finally
      Hash.EndWrite;
    end;
  finally
    Hash.Free;
  end;
end;

procedure TffThreadHash64Test.testAddRemoveMultiple;
var
  Hash : TffThreadHash64;
  Count : Integer;
  I64 : TffInt64;
begin
  Hash := TffThreadHash64.Create(0);
  try
    Hash.BeginWrite;
    try
      for Count := 1 to 20 do begin
        ffIntToI64(100*Count, I64);
        Hash.Add(I64, nil);
      end;
      for Count := 1 to 20 do begin
        ffIntToI64(100*Count, I64);
        Hash.Remove(I64);
      end;
    finally
      hash.EndWrite;
    end;
  finally
    Hash.Free;
  end;
end;

procedure TffThreadHash64Test.testClear;
var
  Hash : TffThreadHash64;
  Count : Integer;
  I64 : TffInt64;
begin
  Hash := TffThreadHash64.Create(0);
  try
    Hash.BeginWrite;
    try
      for Count := 1 to 20 do begin
        ffIntToI64(100*Count, I64);
        Hash.Add(I64, nil);
      end;
      Hash.Clear;
    finally
      hash.EndWrite;
    end;
  finally
    Hash.Free;
  end;
end;

procedure TffThreadHash64Test.testCount;
var
  Hash : TffThreadHash64;
  Count : Integer;
  I64 : TffInt64;
begin
  Hash := TffThreadHash64.Create(0);
  try
    Hash.BeginWrite;
    try
      for Count := 1 to 20 do begin
        ffIntToI64(100*Count, I64);
        Hash.Add(I64, nil);
      end;
      Assert(Hash.Count = 20, 'Invalid Count');
      Hash.Clear;
    finally
      Hash.EndWrite;
    end;
  finally
    Hash.Free;
  end;
end;

procedure TffThreadHash64Test.testCreateDestoy;
var
  Hash : TffThreadHash64;
begin
  hash := TffThreadHash64.Create(0);
  try
    Assert('TffThreadHash64' = Hash.ClassName, 'Error');
  finally
    Hash.Free;
  end;
end;

procedure TffThreadHash64Test.testGet;
var
  Hash : TffThreadHash64;
  I64 : TffInt64;
begin
  Hash := TffThreadHash64.Create(0);
  try
    Hash.BeginWrite;
    try
      ffIntToI64(100, I64);
      Hash.Add(I64, Self);
    finally
      Hash.EndWrite;
    end;

    Hash.BeginRead;
    try
      Assert(Hash.Get(I64) = Self, 'Get Error');
    finally
      Hash.EndRead;
    end;

    Hash.BeginWrite;
    try
      Hash.Clear;
    finally
      Hash.EndWrite;
    end;
  finally
    Hash.Free;
  end;
end;

procedure TffThreadHash64Test.testGrow;
var
  Hash : TffThreadHash64;
  Count : Integer;
  I64 : TffInt64;
begin
  Hash := TffThreadHash64.Create(0);
  try
    Hash.BeginWrite;
    try
      for Count := 1 to 100 do begin
        ffIntToI64(100*Count, I64);
        Hash.Add(I64, nil);
      end;
      Hash.Clear;
    finally
      Hash.EndWrite;
    end;
  finally
    Hash.Free;
  end;
end;

procedure TffThreadHash64Test.testOnDisposeData;
begin

end;

procedure TffThreadHash64Test.testShrink;
var
  Hash : TffThreadHash64;
  Count : Integer;
  I64 : TffInt64;
begin
  Hash := TffThreadHash64.Create(0);
  try
    Hash.BeginWrite;
    try
      for Count := 1 to 100 do begin
        ffIntToI64(100*Count, I64);
        Hash.Add(I64, nil);
      end;
      for Count := 1 to 100 do begin
        ffIntToI64(100*Count, I64);
        Hash.Remove(I64);
      end;  
    finally
      hash.EndWrite;
    end;
  finally
    Hash.Free;
  end;
end;

{ TffListTest }

procedure TffListTest.testCreateDestoy;
var
  List : TffList;
begin
  List := TffList.Create;
  try
    Assert('TffList' = List.ClassName, 'Error');
  finally
    List.Free;
  end;
end;

procedure TffThreadListTest.testCreateDestoy;
var
  List : TffThreadList;
begin
  List := TffThreadList.Create;
  try
    Assert('TffThreadList' = List.ClassName, 'Error');
  finally
    List.Free;
  end;
end;

initialization
  RegisterTest('', TffHashTest);
  RegisterTest('', TffHash64Test);
  RegisterTest('', TffThreadHashTest);
  RegisterTest('', TffThreadHash64Test);
  RegisterTest('', TffListTest);
  RegisterTest('', TffThreadListTest);
  RegisterTest('', TffBaseLockTest);
  RegisterTest('', TffSrLockManagerTest);
  RegisterTest('', TFFSrLockTableTests);
  RegisterTest('', TFFSrLockRecordTests);

end.
