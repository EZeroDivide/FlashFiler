unit TEST_TranMgr;

interface
uses
  FFFile,
  FFLLBase,
  FFSRBase,
  FFSrLock,
  FFSRTran,
  baseTestCase,
  TestFramework;

type
  TFFTranMgrTestCase = class(TffBaseTest)
    fBufMgr : TffBufferManager;
    fLockMgr : TffLockManager;
    fTranMgr : TffSrTransactionMgr;
  protected
    { We don't use Setup/Teardown because we want to control when initialization
      is performed. }
    procedure Prepare; virtual;
    procedure Terminate; virtual;
  end;

  TFFTranMgrTest = class(TFFTranMgrTestCase)

    FConfigFile : PffFileInfo;

    procedure SetNextLSN(const aFile : TffFullFileName;
                         const NextLSN : TffWord32);
  published
    procedure testInitialCommitLSN; virtual;
      { Verify initial CommitLSN has correct value. }
    procedure testNestTrans; virtual;
      { Verify that only one database may be started per logical database. }
    procedure testTranStartCommit; virtual;
      { Verify that a transaction is started and committed correctly. }
    procedure testMultipleTran; virtual;
      { Verify that multiple transactions can be started, rolled back,
        and committed. }
    procedure testRollover; virtual;
      { Verify that LSN rollover is properly handled. }
    procedure testUseCfgFile; virtual;
      { Ensure that FFSTran.cfg is used if valid [exist and not too old].}
    procedure testCalcLSN; virtual;
      { Is the LSN properly calculated when FFSTran.cfg not available?}
    procedure testOldCfgFile; virtual;
      { Do we ignore an out-of-date config file and calculate from
        tables?}

  end;


implementation
uses
  SysUtils,
  StUtils,
  Forms,
  Windows,
  FFLLExcp,
  FFSRBDE;

{===TffTranMgrTestCase===============================================}
procedure TFFTranMgrTestCase.Prepare;
begin
  if assigned(fBufMgr) then
    fBufMgr.Free;

  fBufMgr := TffBufferManager.Create('.\', 20);
  fileProcsInitialize;

  fLockMgr.Free;
  fLockMgr := TffLockManager.Create;

  if assigned(fTranMgr) then
    fTranMgr.Free;

  fTranMgr := TffSrTransactionMgr.Create(fBufMgr,
                                         fLockMgr,
                                         ExtractFilePath(Application.ExeName),
                                         False);

end;
{--------}
procedure TffTranMgrTestCase.Terminate;
begin
  if assigned(fBufMgr) then begin
    fBufMgr.Free;
    fBufMgr := nil;
  end;
  fTranMgr.Free;
  FTranMgr := nil;
  if assigned(fTranMgr) then begin
    fTranMgr.Free;
    fTranMgr := nil;
  end;
end;
{====================================================================}

{===TffTranMgrTest===================================================}
procedure TffTranMgrTest.SetNextLSN(const aFile : TffFullFileName;
                                    const NextLSN : TffWord32);
var
  aFileExists : boolean;
  TempPos : TffInt64;
begin

  fileProcsInitialize;

  { Allocate an in-memory structure for the config file & see if the config
    file exists. }
  FConfigFile := FFAllocFileInfo(aFile, 'cfg', nil);
  aFileExists := FFFileExists(FConfigFile^.fiName^);

  { Open the config file in Exclusive mode, creating it if necessary. }
  FConfigFile^.fiHandle := FFOpenFilePrim(@FConfigFile^.fiName^[1],
                                          omReadWrite, smShared, true,
                                          (not aFileExists));

  { Write the next LSN. }
  FFInitI64(TempPos);
  FFPositionFilePrim(FConfigFile, TempPos);
  FFWriteFilePrim(FConfigFile, sizeOf(TffWord32), NextLSN);

  { Close the file. }
  FFCloseFilePrim(FConfigFile);

end;
{--------}
procedure TFFTranMgrTest.testInitialCommitLSN;
begin
  Prepare;
  assert((fTranMgr.CommitLSN = high(TffWord32)),
         format('Invalid initial CommitLSN value: %d',[fTranMgr.CommitLSN]));
  Terminate;
end;
{--------}
procedure TffTranMgrTest.testNestTrans;
var
  Tran1, Tran2 : TffSrTransaction;
  Error : TffResult;
  NextLSN : TffWord32;
begin
  Prepare;

  { Capture the next LSN so that we can predict the LSN's for the transaction. }
  NextLSN := fTranMgr.NextLSN;

  { Start the first transaction. }
  Error := fTranMgr.StartTransaction(1, false, false, false, '', Tran1);
  assert(DBIERR_NONE = Error, 'StartTransaction(1) failure');

  { Do we have a good transaction ID? }
  assert(assigned(Tran1),'Transaction not returned.');
  assert((Tran1.TransactionID > 0),
         format('Invalid transaction ID: %d',[Tran1.TransactionID]));

  { Does the transaction have the correct LSN? }
  assert(NextLSN = Tran1.LSN, 'Tran LSN (1)');

  { Do we have a correct transaction count? }
  assert((fTranMgr.Count = 1),
         format('Invalid transaction count: %d',[fTranMgr.Count]));

  { Start a second transaction on the same database.  Do we get any
    errors? }
  Error := fTranMgr.StartTransaction(1, false, false, false, '', Tran2);
  assert(DBIERR_NONE = Error, 'StartTransaction(2) failure');
  {did it properly nest?}
  assert(Tran1 = Tran2, 'Trans(2) returned a new transaction');

  { Verify Commit LSN. }
  assert(NextLSN = fTranMgr.CommitLSN, 'Commit LSN(1)');

  { Do we have a correct transaction count? }
  assert((fTranMgr.Count = 1),
         format('Invalid transaction count(2): %d',[fTranMgr.Count]));

  Terminate;
end;
{--------}
procedure TFFTranMgrTest.testTranStartCommit;
var
  Tran : TffSrTransaction;
  Error : TffResult;
  NextLSN : TffWord32;
  Trash   : Boolean;
begin
  Prepare;

  { Capture the next LSN so that we can predict the LSN's for the transaction. }
  NextLSN := fTranMgr.NextLSN;

  Error := fTranMgr.StartTransaction(1, false, false, false, '', Tran);
  assert(DBIERR_NONE = Error, 'StartTransaction failure');

  { Do we have a good transaction ID? }
  assert(assigned(Tran),'Transaction not returned.');
  assert((Tran.TransactionID > 0),
         format('Invalid transaction ID: %d',[Tran.TransactionID]));

  { Does the transaction have the correct LSN? }
  assert(NextLSN = Tran.LSN, 'Tran LSN (1)');

  { Do we have a correct transaction count? }
  assert((fTranMgr.Count = 1),
         format('Invalid transaction count: %d',[fTranMgr.Count]));

  { Rollback the transaction. }
  fTranMgr.Rollback(Tran.TransactionID, Trash);

  { Do we have a correct transaction count? }
  assert((fTranMgr.Count = 0),
         format('Invalid transaction count: %d',[fTranMgr.Count]));

  { Has the commitLSN been reset properly? }
  assert((fTranMgr.CommitLSN = high(TffWord32)),
         format('Invalid initial CommitLSN value: %d',[fTranMgr.CommitLSN]));

  Terminate;

end;
{--------}
procedure TFFTranMgrTest.testMultipleTran;
var
  Tran1, Tran2, Tran3, Tran4 : TffSrTransaction;
  Error : TffResult;
  NextLSN : TffWord32;
  Trash   : Boolean;
begin

  Prepare;

  { Capture the next LSN so that we can predict the LSN's for the transaction. }
  NextLSN := fTranMgr.NextLSN;

  Error := fTranMgr.StartTransaction(1, false, false, false, '', Tran1);
  assert(DBIERR_NONE = Error, 'StartTransaction failure');

  { Do we have a good transaction ID? }
  assert(assigned(Tran1),'Transaction not returned.');
  assert((Tran1.TransactionID > 0), format('Invalid transaction ID: %d',
                                           [Tran1.TransactionID]));

  { Does the transaction have the correct LSN? }
  assert(NextLSN = Tran1.LSN, 'Tran LSN (1)');

  { Do we have a correct transaction count? }
  assert(1 = fTranMgr.Count, 'Invalid transaction count');


  { Start the 2nd transaction. }
  Error := fTranMgr.StartTransaction(2, false, false, false, '', Tran2);
  assert(DBIERR_NONE = Error, 'StartTransaction failure');

  { Do we have a good transaction ID? }
  assert(assigned(Tran2),'Transaction not returned.');
  assert((Tran2.TransactionID > 0), format('Invalid transaction ID: %d',
                                           [Tran2.TransactionID]));

  { Does the transaction have the correct LSN? }
  assert(NextLSN + 1 = Tran2.LSN, 'Tran LSN (2)');

  { Do we have a correct transaction count? }
  assert(2 = fTranMgr.Count, 'Invalid transaction(2) count');


  { Start the 3rd transaction. }
  Error := fTranMgr.StartTransaction(3, false, false, false, '', Tran3);
  assert(DBIERR_NONE = Error, 'StartTransaction failure');

  { Do we have a good transaction ID? }
  assert(assigned(Tran3),'Transaction not returned.');
  assert((Tran3.TransactionID > 0), format('Invalid transaction ID: %d',
                                           [Tran3.TransactionID]));

  { Does the transaction have the correct LSN? }
  assert(NextLSN + 2 = Tran3.LSN, 'Tran LSN (3)');

  { Do we have a correct transaction count? }
  assert(3 = fTranMgr.Count, 'Invalid transaction(3) count');


  { Start the 4th transaction. }
  Error := fTranMgr.StartTransaction(4, false, false, false, '', Tran4);
  assert(DBIERR_NONE = Error, 'StartTransaction failure');

  { Do we have a good transaction ID? }
  assert(assigned(Tran4),'Transaction not returned.');
  assert((Tran4.TransactionID > 0), format('Invalid transaction ID: %d',
                                           [Tran4.TransactionID]));

  { Does the transaction have the correct LSN? }
  assert(NextLSN + 3 = Tran4.LSN, 'Tran LSN (4)');

  { Do we have a correct transaction count? }
  assert(4 = fTranMgr.Count, 'Invalid transaction(4) count');

  { Rollback transaction 2.  Verify CommitLSN is correct. }
  fTranMgr.Rollback(Tran2.TransactionID, Trash);
  assert(NextLSN = fTranMgr.CommitLSN, 'Commit LSN(1)');

  { Commit transaction 1.  Verify CommitLSN. }
  fTranMgr.Commit(Tran1.TransactionID, Trash);
  assert(NextLSN + 2 = fTranMgr.CommitLSN, 'Commit LSN(2)');

  { Commit transaction 3.  Verify CommitLSN. }
  fTranMgr.Commit(Tran3.TransactionID, Trash);
  assert(NextLSN + 3 = fTranMgr.CommitLSN, 'Commit LSN(3)');

  { Rollback transaction 4.  Verify CommitLSN is correct. }
  fTranMgr.Rollback(Tran4.TransactionID, Trash);
  assert(high(Tffword32) = fTranMgr.CommitLSN, 'Commit LSN(4)');

  { Do we have a correct transaction count? }
  assert((fTranMgr.Count = 0),
         format('Invalid transaction count: %d',[fTranMgr.Count]));

  { Has the commitLSN been reset properly? }
  assert(high(TffWord32) = fTranMgr.CommitLSN,
               'Invalid initial CommitLSN');

  Terminate;

end;
{--------}
procedure TFFTranMgrTest.testRollover;
var
  Error               : TffResult;
  OldNextLSN          : TffWord32;
  PredictedCommitLSN  : TffWord32;
  Tran1, Tran2, Tran3 : TffSrTransaction;
  Trash               : Boolean;
begin

  { Set the nextLSN such that the LSN rolls over on the 3rd transaction. }
  OldNextLSN := high(TffWord32) - 2;
  PredictedCommitLSN := 2;

  SetNextLSN(FFMakeFullFileName(ExtractFilePath(Application.EXEName), 'FFSTRAN'),
             OldNextLSN);
  Prepare;

  { Start 1st transaction. }
  Error := fTranMgr.StartTransaction(1, false, false, false, '', Tran1);
  assert(DBIERR_NONE = Error, 'StartTransaction failure (1)');

  { Do we have a good transaction ID? }
  assert(assigned(Tran1),'Transaction not returned (1).');
  assert((Tran1.TransactionID > 0), format('Invalid transaction ID: %d',
                                           [Tran1.TransactionID]));

  { Does the transaction have the correct LSN? }
  assert(OldNextLSN = Tran1.LSN, 'Tran LSN (1)');

  { Do we have a correct transaction count? }
  assert(1 = fTranMgr.Count, 'Invalid transaction count(1)');


  { Start 2nd transaction. }
  Error := fTranMgr.StartTransaction(2, false, false, false, '', Tran2);
  assert(DBIERR_NONE = Error, 'StartTransaction failure (2)');

  { Do we have a good transaction ID? }
  assert(assigned(Tran2),'Transaction not returned (2).');
  assert((Tran2.TransactionID > 0), format('Invalid transaction ID: %d',
                                           [Tran2.TransactionID]));

  { Does the transaction have the correct LSN? }
  assert(OldNextLSN + 1 = Tran2.LSN, 'Tran LSN (2)');

  { Do we have a correct transaction count? }
  assert(2 = fTranMgr.Count, 'Invalid transaction count(2)');


  { Start 3rd transaction.  At this point, the LSN should rollover. }
  Error := fTranMgr.StartTransaction(3, false, false, false, '', Tran3);
  assert(DBIERR_NONE = Error, 'StartTransaction failure (3)');

  { Do we have a good transaction ID? }
  assert(assigned(Tran3),'Transaction not returned (3).');
  assert((Tran3.TransactionID > 0), format('Invalid transaction ID: %d',
                                           [Tran3.TransactionID]));

  { Does the transaction have the correct LSN? }
  assert(PredictedCommitLSN + 2 = Tran3.LSN, 'Tran LSN (3)');

  { Do we have a correct transaction count? }
  assert(3 = fTranMgr.Count, 'Invalid transaction count(3)');

  { Do the previously-started transactions have a correctly adjusted LSN? }
  assert(PredictedCommitLSN = Tran1.LSN, 'Incorrectly adjusted LSN (1)');
  assert(PredictedCommitLSN + 1 = Tran2.LSN,
               'Incorrectly adjusted LSN (2)');

  { Has the commit LSN been correctly adjusted? }
  assert(PredictedCommitLSN = FTranMgr.CommitLSN,
               'Incorrectly adjusted commitLSN.');

  { Commit the transactions. }
  fTranMgr.Commit(1, Trash);
  fTranMgr.Commit(2, Trash);
  fTranMgr.Commit(3, Trash);

  Terminate;
end;
{====================================================================}
procedure TFFTranMgrTest.testCalcLSN;
begin
  {ensure the lsn is calculated. delete the system tables so that
   we don't retrieve the lsn from there.}
  SysUtils.DeleteFile(ExtractFilePath(Application.ExeName) + 'FFSTran.CFG');
  SysUtils.DeleteFile(ExtractFilePath(Application.ExeName) + 'FFSinfo.ff2');
  SysUtils.DeleteFile(ExtractFilePath(Application.ExeName) + 'FFSalias.ff2');
  SysUtils.DeleteFile(ExtractFilePath(Application.ExeName) + 'FFSindex.ff2');
  SysUtils.DeleteFile(ExtractFilePath(Application.ExeName) + 'FFSuser.ff2');

  {make copies of our backup tables so we have static numbers to test.}
  CopyFile(PChar(ExtractFilePath(Application.Exename) + 'data\FFSALIAS.bak'),
           PChar(ExtractFilePath(Application.Exename) + 'FFSALIAS.ff2'), false);
  CopyFile(PChar(ExtractFilePath(Application.Exename) + 'data\FFSindex.bak'),
           PChar(ExtractFilePath(Application.Exename) + 'FFSindex.ff2'), false);
  CopyFile(PChar(ExtractFilePath(Application.Exename) + 'data\FFSuser.bak'),
           PChar(ExtractFilePath(Application.Exename) + 'FFSuser.ff2'), false);
  CopyFile(PChar(ExtractFilePath(Application.Exename) + 'data\FFSinfo.bak'),
           PChar(ExtractFilePath(Application.Exename) + 'FFSinfo.ff2'), false);
  CopyFile(PChar(ExtractFilePath(Application.Exename) + 'data\exblob.bak'),
           PChar(ExtractFilePath(Application.Exename) + 'exblob.ff2'), false);
  CopyFile(PChar(ExtractFilePath(Application.Exename) + 'data\excust.bak'),
           PChar(ExtractFilePath(Application.Exename) + 'excust.ff2'), false);
  CopyFile(PChar(ExtractFilePath(Application.Exename) + 'data\exlines.bak'),
           PChar(ExtractFilePath(Application.Exename) + 'exlines.ff2'), false);
  CopyFile(PChar(ExtractFilePath(Application.Exename) + 'data\exorders.bak'),
           PChar(ExtractFilePath(Application.Exename) + 'exorder.ff2'), false);
  CopyFile(PChar(ExtractFilePath(Application.Exename) + 'data\exprods.bak'),
           PChar(ExtractFilePath(Application.Exename) + 'exprods.ff2'), false);

  Prepare;
  {the highest lsn in the above tables is 3027}
  Assert(fTranMgr.NextLSN = 3027, 'LSN not calculated from tables correctly');

  Terminate;
end;

procedure TFFTranMgrTest.testUseCfgFile;
var
  CfgFile : PffFileInfo;
  FileLSN : TffWord32;
begin
  SysUtils.DeleteFile(ExtractFilePath(Application.ExeName) + 'FFSTran.CFG');
//  SysUtils.DeleteFile(ExtractFilePath(Application.ExeName) + 'FFSinfo.ff2');
//  SysUtils.DeleteFile(ExtractFilePath(Application.ExeName) + 'FFSalias.ff2');
//  SysUtils.DeleteFile(ExtractFilePath(Application.ExeName) + 'FFSindex.ff2');
//  SysUtils.DeleteFile(ExtractFilePath(Application.ExeName) + 'FFSuser.ff2');

  {make a copy of the cfg so we can access it after the server starts.}
  CopyFile(PChar(ExtractFilePath(Application.ExeName) + 'data\FFSTran.bak'),
           PChar(ExtractFilePath(Application.ExeName) + 'FFSTran.cfg'), false);

  {make copies of our backup tables so we have static numbers to test.}
  CfgFile := FFAllocFileInfo(ExtractFilePath(Application.ExeName) + 'FFSTRAN.cfg',
                                                'cfg', nil);
  CfgFile^.fiHandle := FFOpenFilePrim(@CfgFile^.fiName^[1],
                                      omReadWrite, smExclusive, True,
                                      False);
  FFReadFilePrim(CfgFile, sizeOf(TffWord32), FileLSN);
  FileSetDate(CfgFile^.fiHandle, DateTimeToFileDate(Now));
  FFCloseFile(CfgFile);

  Prepare;
  Assert(fTranMgr.NextLSN = FileLSN, 'LSN not retrieved from cfg file correctly');

  SysUtils.DeleteFile(CfgFile^.fiName^);

  Terminate;
end;

procedure TFFTranMgrTest.testOldCfgFile;
var
  TestLSN : TffWord32;
  TransInfo : TffTransInfo;
  Tran    : TffSrTransaction;
  NewBlock : TffBlock;
  pNewBlock : Pffblock;
  CfgFile   : TffFileInfo;
  CfgHandle : Integer;
  Trash     : Boolean;
  relMethod1, relMethod2 : TffReleaseMethod;
begin
  {ensure we have a table and config file with a lsn we can test}
  SysUtils.DeleteFile(ExtractFilePath(Application.Exename) + 'excust.ff2');
  SysUtils.DeleteFile(ExtractFilePath(Application.Exename) + 'ffstran.cfg');

  CopyFile(PChar(ExtractFilePath(Application.Exename) + 'data\excust.bak'),
           PChar(ExtractFilePath(Application.Exename) + 'excust.ff2'), false);

  CopyFile(PChar(ExtractFilePath(Application.Exename) + 'ffstran.bak'),
           PChar(ExtractFilePath(Application.Exename) + 'ffstran.cfg'), false);

  Prepare;

  {increment the LSN by starting transactions}
  fTranMgr.StartTransaction(1, false, false, false, '', Tran);
  fTranMgr.Commit(Tran.TransactionID, Trash);
  fTranMgr.StartTransaction(1, false, false, false, '', Tran);
  fTranMgr.Commit(Tran.TransactionID, Trash);
  fTranMgr.StartTransaction(1, false, false, false, '', Tran);

  {open the test table and dirty it so it's lsn will be adjusted.}
  CfgFile := PffFileInfo(FFAllocFileInfo(FFMakeFullFileName(ExtractFilePath(Application.ExeName),
                                                'ExCust.ff2'),
                                                'ff2', nil))^;
  CfgFile.fiBlockSize := 4096;
  CfgFile.fiHandle := FFOpenFilePrim(@CfgFile.fiName^[1],
                                     omReadWrite, smExclusive, True,
                                     False);

  TransInfo.tirLockMgr := fLockMgr;
  TransInfo.tirTrans := Tran;
  FBufMgr.GetBlock(@CfgFile, 4, @TransInfo, True, relMethod1);
  FBufMgr.GetBlock(@CfgFile, 0, @TransInfo, True, relMethod2);
  pNewBlock := @Newblock;
  FBufMgr.DirtyBlock(@CfgFile, 4, @TransInfo, PNewblock);
  FBufMgr.DirtyBlock(@CfgFile, 0, @TransInfo, PNewblock);

  {the test table's lsn should be updated when the last transaction
   is committed.}
  fTranMgr.Commit(Tran.TransactionID, Trash);
  Fbufmgr.RemoveFile(@CfgFile);

  {Save the lsn so we can see if it is retrieved correctly}
  TestLSN := fTranMgr.NextLSN;

  FFCloseFile(@CfgFile);
  {Stop the server and restart it so we can see if it retrieves the
   lsn correctly}
  Terminate;

  {set the date of the config file to an earlier time (while the
   server doesn't have it exclusively opened) so that the lsn will
   be calculated using the test table}
  CfgHandle := FileOpen(ExtractFilePath(Application.ExeName) + 'ffstran.cfg', fmOpenRead);
  FileSetDate(CfgHandle, DateTimeToFileDate(Now)  - 1011111);
  FileClose(CfgHandle);

  {restart the server and let's see if it has the correct lsn.}
  Prepare;
  Assert(fTranMgr.NextLSN = TestLSN, 'LSN not properly calculated from tables');

  Terminate;
end;

initialization
  RegisterTest('Transactions', TFFTranMgrTest.Suite);
end.


