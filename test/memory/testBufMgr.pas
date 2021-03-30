unit testBufMgr;

interface

uses
  TestFramework,
  FFSrBase;

type
  TffBufferMgrTest = class(TTestCase)
  protected

    bmtBufMgr : TffBufferManager;
    bmtTI : PffTransInfo;
    bmtTrans : TffSrTransaction;

    function bmtCreateFile(const aName : string;
                           const aBlockSize, aRecordLen : Longint;
                           const attributes : TffFileAttributes) : PffFileInfo;
    procedure Setup; override;
    procedure Teardown; override;
  published
    procedure testRecycled;
      { Verify that all pages associated with a file are added to the
        recycled list when the file is closed. }
    procedure testReuseRecycled;
      { Verify that pages in the recycled list are recycled. }
    procedure testCreateTempTable;
      { Verify that we can create a temporary table. }
    procedure testTempTableStored;
      { Verify that a temporary table can be shoved off into temporary
        storage & then retrieved. }
    procedure testTempStoreFull;
      { See what happens when temporary storage is filled. }
    procedure testReuseModeUpdated;
      { Verify that a page's Reuse mode is updated when it is re-used for
        another file. }
  end;

implementation

uses
  SysUtils,
  FFConst,
  FFFile,
  FFLLBase,
  FFLLExcp;

const
  ffc_64k = 64 * 1024;
  
{===TffBufferMgrTest=================================================}
function TffBufferMgrTest.bmtCreateFile(const aName : string;
                                        const aBlockSize, aRecordLen : Longint;
                                        const attributes : TffFileAttributes) : PffFileInfo;
var
  FileHeader   : PffBlockHeaderFile;
  aRelMethod : TffReleaseMethod;
begin
  Result := FFAllocFileInfo(aName, ffc_ExtForData, bmtBufMgr);
  Result.fiAttributes := attributes;

  if not (fffaTemporary in attributes) then
    FFOpenFile(Result, omReadWrite, smExclusive, true, true);
  try
    Result.fiBlockSize := aBlockSize;
    {patch up the file's block size for the buffer manager}
    Result^.fiBlockSize := aBlockSize;

    {add a new block for the new header}
    FileHeader := PffBlockHeaderFile(bmtBufMgr.AddBlock(Result, bmtTI, 0,
                                                        aRelMethod));
    try
      {set up the file header information}
      with FileHeader^ do begin
        bhfSignature := ffc_SigHeaderBlock;
        bhfNextBlock := $FFFFFFFF;
        bhfThisBlock := 0;
        bhfLSN := 0;
        bhfBlockSize := aBlockSize;
        bhfEncrypted := 0;
        bhfLog2BlockSize := FFCalcLog2BlockSize(aBlockSize);
        bhfUsedBlocks := 1; {ie this header block}
        bhfAvailBlocks := 0;
        bhf1stFreeBlock := $FFFFFFFF;
        bhfRecordCount := 0;
        bhfDelRecCount := 0;
        bhf1stDelRec.iLow := $FFFFFFFF;
        bhfRecordLength := aRecordLen;
        bhfRecLenPlusTrailer := aRecordLen + sizeof(byte);
        bhfRecsPerBlock := (aBlockSize - ffc_BlockHeaderSizeData) div bhfRecLenPlusTrailer;
        bhf1stDataBlock := $FFFFFFFF;
        bhfLastDataBlock := $FFFFFFFF;
        bhfBLOBCount := 0;
        bhfDelBLOBHead.iLow := $FFFFFFFF;
        bhfDelBLOBTail.iLow := $FFFFFFFF;
        bhfAutoIncValue := 0;
        bhfIndexCount := 0;
        bhfHasSeqIndex := 1;
        bhfIndexHeader := ffc_W32NoValue;
        bhfDataDict := 0;
        bhfFieldCount := 1;
        bhfFFVersion := ffVersionNumber;
      end;
    except
      bmtBufMgr.RemoveFile(Result);
      FFCloseFile(Result);
      raise;
    end;{try..except}
  finally
    aRelMethod(PffBlock(FileHeader));
  end;
end;
{--------}
procedure TffBufferMgrTest.Setup;
begin
  inherited Setup;
  FileProcsInitialize;
  bmtBufMgr := TffBufferManager.Create('.\', 20);
  bmtTrans := TffSrTransaction.Create(1, false, false);
  FFGetMem(bmtTI, SizeOf(TffTransInfo));
  bmtTI^.tirLockMgr := nil;
  bmtTI^.tirTrans := bmtTrans;
end;
{--------}
procedure TffBufferMgrTest.Teardown;
begin
  bmtBufMgr.Free;
  bmtTrans.Free;
  FFFreeMem(bmtTI, SizeOf(TffTransInfo));
  inherited Teardown;
end;
{--------}
procedure TffBufferMgrTest.testRecycled;
var
  aBlock : PffBlock;
  aCount : Longint;
  aFI : PffFileInfo;
  Index : Longint;
  aRelList : TffPointerList;
  aRelMethod : TffReleaseMethod;
begin
  { Create a new file. }
  aFI := bmtCreateFile('test', ffc_64k, 100, []);
  aRelList := TffPointerList.Create;
  try
    { Add several blocks. }
    for Index := 1 to 10 do begin
      aBlock := bmtBufMgr.AddBlock(aFI, bmtTI, Index, aRelMethod);
      aRelList.Append(FFAllocReleaseInfo(aBlock, TffInt64(aRelMethod)));
    end;

    { Verify the RAM page count. }
    aCount := bmtBufMgr.RAMPageCount;
    CheckEquals(aCount, 11,
                format('Invalid RAM Page Count: %d',[aCount]));

    for Index := 0 to pred(aRelList.Count) do
      FFDeallocReleaseInfo(aRelList[Index]);

    { Close the file. Note that we do not save any of the blocks to disk. }
    bmtBufMgr.RemoveFile(aFI);

    { Verify the recycled page count. }
    aCount := bmtBufMgr.RecycledCount;
    CheckEquals(aCount, 11,
                format('Invalid recycled page count: %d', [aCount]));
    aCount := bmtBufMgr.RAMPageCount;
    CheckEquals(aCount, 0,
                format('Invalid final RAM Page Count: %d',[aCount]));
  finally
    aRelList.Free;
    FFCloseFile(aFI);
    FFFreeMem(aFI, SizeOf(TffTransInfo));
  end;

end;
{--------}
procedure TffBufferMgrTest.testReuseRecycled;
var
  aCount : Longint;
  aBlock : PffBlock;
  aFI : PffFileInfo;
  Index : Longint;
  aRelList : TffPointerList;
  aRelMethod : TffReleaseMethod;
begin
  { Create a new file. }
  aFI := bmtCreateFile('test', ffc_64k, 100, []);
  aRelList := TffPointerList.Create;
  try
    { Add several blocks. }
    for Index := 1 to 10 do begin
      aBlock := bmtBufMgr.AddBlock(aFI, bmtTI, Index, aRelMethod);
      aRelList.Append(FFAllocReleaseInfo(aBlock, TffInt64(aRelMethod)));
    end;

    { Verify the RAM page count. }
    aCount := bmtBufMgr.RAMPageCount;
    CheckEquals(aCount, 11,
                format('Invalid RAM Page Count: %d',[aCount]));

    for Index := 0 to pred(aRelList.Count) do
      FFDeallocReleaseInfo(aRelList[Index]);

    { Close the file. Note that we do not save any of the blocks to disk. }
    bmtBufMgr.RemoveFile(aFI);

    { Verify the recycled page count. }
    aCount := bmtBufMgr.RecycledCount;
    CheckEquals(aCount, 11,
                format('Invalid recycled page count: %d', [aCount]));
    aCount := bmtBufMgr.RAMPageCount;
    CheckEquals(aCount, 0,
                format('Invalid final RAM Page Count: %d',[aCount]));

  finally
    aRelList.Free;
    FFCloseFile(aFI);
    FFFreeMem(aFI, SizeOf(TffTransInfo));
  end;

  { Now open a new file & verify the pages in the recycled list are
    recycled. }
  aFI := bmtCreateFile('test2', ffc_64k, 100, []);
  aRelList := TffPointerList.Create;
  try
    aCount := bmtBufMgr.RecycledCount;
    CheckEquals(aCount, 10,
                format('Invalid initial recycled page count: %d', [aCount]));
    aCount := bmtBufMgr.RAMPageCount;
    CheckEquals(aCount, 1,
                format('Invalid initial RAM Page Count: %d',[aCount]));

    { Add several blocks. }
    for Index := 1 to 5 do begin
      aBlock := bmtBufMgr.AddBlock(aFI, bmtTI, Index, aRelMethod);
      aRelList.Append(FFAllocReleaseInfo(aBlock, TffInt64(aRelMethod)));
    end;
    try
      aCount := bmtBufMgr.RecycledCount;
      CheckEquals(aCount, 5,
                  format('Invalid stage2 recycled page count: %d', [aCount]));
      aCount := bmtBufMgr.RAMPageCount;
      CheckEquals(aCount, 6,
                  format('Invalid stage2 RAM Page Count: %d',[aCount]));
    finally
      for Index := 0 to pred(aRelList.Count) do
        FFDeallocReleaseInfo(aRelList[Index]);
      aRelList.Free;
    end;

    bmtBufMgr.RemoveFile(aFI);

    { Verify the recycled page count. }
    aCount := bmtBufMgr.RecycledCount;
    CheckEquals(aCount, 11,
                format('Invalid recycled page count: %d', [aCount]));
    aCount := bmtBufMgr.RAMPageCount;
    CheckEquals(aCount, 0,
                format('Invalid final RAM Page Count: %d',[aCount]));
  finally
    FFCloseFile(aFI);
    FFFreeMem(aFI, SizeOf(TffTransInfo));
  end;

end;
{--------}
procedure TffBufferMgrTest.testCreateTempTable;
var
  aBlock : PffBlock;
  aCount : Longint;
  aFI : PffFileInfo;
  Index : Longint;
  aRelList : TffPointerList;
  aRelMethod : TffReleaseMethod;
begin
  { Create a new file. }
  aFI := bmtCreateFile('TMP:test', ffc_64k, 100, [fffaTemporary]);
  aRelList := TffPointerList.Create;
  try
    { Add several blocks. }
    for Index := 1 to 10 do begin
      aBlock := bmtBufMgr.AddBlock(aFI, bmtTI, Index, aRelMethod);
      aRelList.Append(FFAllocReleaseInfo(aBlock, TffInt64(aRelMethod)));
    end;
    try
      { Verify the RAM page count. }
      aCount := bmtBufMgr.RAMPageCount;
      CheckEquals(aCount, 11,
                  format('Invalid RAM Page Count: %d',[aCount]));

      { Verify the reuse mode of each page. }
      for Index := 0 to pred(aCount) do
        Check(bmtBufMgr.RAMPages[Index].ReuseMode = ffrmTempStore,
                    format('Invalid reuse mode, block: %d',[Index]));
    finally
      for Index := 0 to pred(aRelList.Count) do
        FFDeallocReleaseInfo(aRelList[Index]);
      aRelList.Free;
    end;

    { Close the file.  }
    bmtBufMgr.RemoveFile(aFI);

    { Verify the recycled page count. }
    aCount := bmtBufMgr.RecycledCount;
    CheckEquals(aCount, 11,
                format('Invalid recycled page count: %d', [aCount]));
    aCount := bmtBufMgr.RAMPageCount;
    CheckEquals(aCount, 0,
                format('Invalid final RAM Page Count: %d',[aCount]));
  finally
    FFFreeMem(aFI, SizeOf(TffTransInfo));
  end;

end;
{--------}
procedure TffBufferMgrTest.testTempTableStored;
const
  stdFileBlocks = ffcl_1MB div (4 * 1024);
  tmpFileBlocks = ffcl_1MB div ffc_64k;
var
  aBlock: PffBlock;
  aBlockValue : byte;
  aCount : Longint;
  aFI, aTmpFI : PffFileInfo;
  aPage : TffbmRAMPage;
  Index, Index2 : Longint;
  aRelList : TffPointerList;
  aRelMethod : TffReleaseMethod;
begin
  { Limit the buffer manager to 1 MB of RAM. }
  bmtBufMgr.MaxRAM := 1;

  { Create a temporary file. }
  aTmpFI := bmtCreateFile('TMP:test', ffc_64k, 100, [fffaTemporary]);
  aRelList := TffPointerList.Create;
  try
    { Add enough blocks to fill up the 1 MB of RAM. }
    aBlockValue := 1;
    for Index := 1 to pred(tmpFileBlocks) do begin
      aBlock := bmtBufMgr.AddBlock(aTmpFI, bmtTI, Index, aRelMethod);
      { Mark the block with a unique bit pattern. }
      FillChar(aBlock^, ffc_64k, aBlockValue);
      inc(aBlockValue);
      aRelMethod(aBlock);
    end;

    { Commit the changes. }
    bmtBufMgr.CommitTransaction(bmtTI^.tirTrans);

    { Verify the RAM page count. }
    aCount := bmtBufMgr.RAMPageCount;
    CheckEquals(aCount, tmpFileBlocks,
                format('Invalid RAM Page count for temp file: %d',[aCount]));

    { Verify the reuse mode of each page. }
    for Index := 0 to pred(aCount) do
      Check(bmtBufMgr.RAMPages[Index].ReuseMode = ffrmTempStore,
                  format('Invalid reuse mode, block: %d',[Index]));

    { Create a persistent file. }
    aFI := bmtCreateFile('persistent', 4 * 1024, 100, []);
    try
      { Add enough blocks to fill 1 MB of RAM. }
      for Index := 1 to pred(stdFileBlocks) do begin
        aBlock := bmtBufMgr.AddBlock(aFI, bmtTI, Index, aRelMethod);
        aRelList.Append(FFAllocReleaseInfo(aBlock, TffInt64(aRelMethod)));
      end;

      { Verify the block count. }
      aCount := bmtBufMgr.RAMPageCount;
      CheckEquals(aCount, tmpFileBlocks + stdFileBlocks,
                  format('Invalid RAM Page count for temp file: %d',[aCount]));

      { Verify that the temporary file's blocks have been handed off to
        temporary storage. Try to retrieve each block & check its bit pattern. }
      for Index := 0 to pred(bmtBufMgr.RAMPageCount) do begin
        aPage := bmtBufMgr.RAMPages[Index];
        { Is this page associated with the persistent file? }
        if aPage.FileInfo = aFI then begin
          { Yes. Verify it is not in temporary storage. }
          Check(not aPage.InTempStore,
                format('Invalid InTempStore value for persistent page %d',
                       [aPage.BlockNumber]));
        end
        else begin
          { No. Verify the page is in temporary storage. Check not needed for
            block zero. }
          if aPage.BlockNumber > 0 then
            Check(aPage.InTempStore,
                  format('Invalid InTempStore value for temporary page %d',
                         [aPage.BlockNumber]));
          { Retrieve the page's block. }
          aBlock := aPage.Block(bmtTI^.tirTrans, aRelMethod);
          if aPage.BlockNumber > 0 then
            { Verify the first 12 bytes are set to zero. The next 4 bytes are
              the page's LSN so we will ignore everything at that point and
              beyond. }
            for Index2 := 0 to 11 do
            CheckEquals(aPage.BlockNumber, aBlock^[Index2],
                        format('Invalid byte value for block %d at position %d',
                               [aPage.BlockNumber, Index2]));
          aRelMethod(aBlock);
        end;
      end;
    finally
      for Index := 0 to pred(aRelList.Count) do
        FFDeallocReleaseInfo(aRelList[Index]);
      aRelList.Free;
      { Close the files.  }
      bmtBufMgr.RemoveFile(aTmpFI);
      bmtBufMgr.RemoveFile(aFI);
    end;

    { Verify the recycled page count. }
    aCount := bmtBufMgr.RecycledCount;
    CheckEquals(aCount, tmpFileBlocks + stdFileBlocks,
                format('Invalid recycled page count: %d', [aCount]));
    aCount := bmtBufMgr.RAMPageCount;
    CheckEquals(aCount, 0,
                format('Invalid final RAM Page Count: %d',[aCount]));
  finally
    FFCloseFile(aFI);
    FFFreeMem(aFI, SizeOf(TffTransInfo));
    FFFreeMem(aTmpFI, SizeOf(TffTransInfo));
  end;

end;
{--------}
procedure TffBufferMgrTest.testTempStoreFull;
const
  stdFileBlocks = (30 * ffcl_1MB) div ffc_64k;
  tmpFileBlocks = (21 * ffcl_1MB) div ffc_64k;
  tmpFileBlocksInTemp = (20 * ffcl_1MB) div ffc_64k;
var
  aBlock: PffBlock;
  aBlockValue : byte;
  aCount : Longint;
  addedStdBlocks : Longint;
  aFI, aTmpFI : PffFileInfo;
  aPage : TffbmRAMPage;
  errMsg : string;
  ExceptRaised : boolean;
  SomeOtherExceptRaised : boolean;
  Index, Index2 : Longint;
  aRelMethod : TffReleaseMethod;
begin
  { Limit the buffer manager to 20 MB of RAM. }
  bmtBufMgr.MaxRAM := 20;

  { Create a temporary file. }
  aTmpFI := bmtCreateFile('TMP:test', ffc_64k, 100, [fffaTemporary]);
  try
    { Add enough blocks to fill up the 20 MB of RAM. }
    aBlockValue := 1;
    for Index := 1 to pred(tmpFileBlocks) do begin
      aBlock := bmtBufMgr.AddBlock(aTmpFI, bmtTI, Index, aRelMethod);
      { Mark the block with a unique bit pattern. }
      FillChar(aBlock^, ffc_64k, aBlockValue);
      inc(aBlockValue);
      aRelMethod(aBlock);
    end;

    { Commit the changes. }
    bmtBufMgr.CommitTransaction(bmtTI^.tirTrans);

    { Verify the RAM page count. }
    aCount := bmtBufMgr.RAMPageCount;
    CheckEquals(aCount, tmpFileBlocks,
                format('Invalid RAM Page count for temp file: %d',[aCount]));

    { Verify the reuse mode of each page. }
    for Index := 0 to pred(aCount) do
      Check(bmtBufMgr.RAMPages[Index].ReuseMode = ffrmTempStore,
                  format('Invalid reuse mode, block: %d',[Index]));

    { Create a persistent file. }
    aFI := bmtCreateFile('persistent', ffc_64k, 100, []);

    { Add enough blocks to fill 20 MB of RAM. We do not expect an exception to
      be raised when temporary storage is full because the temporary file blocks
      should stop saying they can be reused once temp storage is full. }
    ExceptRaised := False;
    SomeOtherExceptRaised := False;
    errMsg := '';
    addedStdBlocks := 1;
    try
      for Index := 1 to pred(stdFileBlocks) do begin
        aBlock := bmtBufMgr.AddBlock(aFI, bmtTI, Index, aRelMethod);
        inc(addedStdBlocks);
        aRelMethod(aBlock);
      end;
    except
      on E:EffException do begin
        ExceptRaised := (E.ErrorCode = ffErrTmpStoreFull);
        SomeOtherExceptRaised := true;
        errMsg := E.Message;
      end
      else
        SomeOtherExceptRaised := True;
    end;

    { Verify an exception was raised. }
    Assert(not ExceptRaised, '''Temporary Storage Full'' exception raised.');
    Assert(not SomeOtherExceptRaised,
           format('Unexpected exception: %s.',[errMsg]));

    { Verify the block count. }
    aCount := bmtBufMgr.RAMPageCount;
    CheckEquals(aCount, tmpFileBlocks + addedStdBlocks,
                format('Invalid RAM Page count for persistent file: %d',[aCount]));

    { Verify that the temporary file's blocks have been handed off to temporary
      storage. Try to retrieve each block & check its bit pattern. }
    for Index := 0 to pred(bmtBufMgr.RAMPageCount) do begin
      aPage := bmtBufMgr.RAMPages[Index];
      { Is this page associated with the persistent file? }
      if aPage.FileInfo = aFI then begin
        { Yes. Verify it is not in temporary storage. }
        Check(not aPage.InTempStore,
              format('Invalid InTempStore value for persistent page %d',
                     [aPage.BlockNumber]));
      end
      else begin
        { No. Verify the page is in temporary storage. }
        if (aPage.BlockNumber > 0) and
           (aPage.BlockNumber < tmpFileBlocksInTemp) then
          Check(aPage.InTempStore,
                format('Invalid InTempStore value for temporary page %d',
                       [aPage.BlockNumber]));
        { Retrieve the page's block. }
        aBlock := aPage.Block(bmtTI^.tirTrans, aRelMethod);
        if aPage.BlockNumber > 0 then
          { Verify the first 12 bytes are set to zero. The next 4 bytes are
            the page's LSN so we will ignore everything at that point and
            beyond. }
          for Index2 := 0 to 11 do
          CheckEquals(aPage.BlockNumber - (aPage.BlockNumber div 256) * 256, aBlock^[Index2],
                      format('Invalid byte value for block %d at position %d',
                             [aPage.BlockNumber, Index2]));
        aRelMethod(aBlock);
      end;
    end;

    { Close the files.  }
    bmtBufMgr.RemoveFile(aTmpFI);
    bmtBufMgr.RemoveFile(aFI);

    { Verify the recycled page count. }
    aCount := bmtBufMgr.RecycledCount;
    CheckEquals(aCount, tmpFileBlocks + addedStdBlocks,
                format('Invalid recycled page count: %d', [aCount]));
    aCount := bmtBufMgr.RAMPageCount;
    CheckEquals(aCount, 0,
                format('Invalid final RAM Page Count: %d',[aCount]));
  finally
    FFCloseFile(aFI);
    FFFreeMem(aFI, SizeOf(TffTransInfo));
    FFFreeMem(aTmpFI, SizeOf(TffTransInfo));
  end;

end;
{--------}
procedure TffBufferMgrTest.testReuseModeUpdated;
const
  numBlocks = 10;
var
  aBlock : PffBlock;
  aCount : Longint;
  aFI, aTmpFI : PffFileInfo;
  Index : Longint;
  aRelMethod : TffReleaseMethod;
begin
  { Limit the buffer manager to 20 MB of RAM. }
  bmtBufMgr.MaxRAM := 20;

  { Create a temporary file. }
  aTmpFI := bmtCreateFile('TMP:test', ffc_64k, 100, [fffaTemporary]);
  try
    { Add some blocks. }
    for Index := 1 to pred(numBlocks) do begin
      aBlock := bmtBufMgr.AddBlock(aTmpFI, bmtTI, Index, aRelMethod);
      aRelMethod(aBlock);
    end;

    { Commit the changes. }
    bmtBufMgr.CommitTransaction(bmtTI^.tirTrans);

    { Verify the RAM page count. }
    aCount := bmtBufMgr.RAMPageCount;
    CheckEquals(aCount, numBlocks,
                format('Invalid RAM Page count for temp file: %d',[aCount]));

    { Verify the reuse mode of each page. }
    for Index := 0 to pred(aCount) do
      Check(bmtBufMgr.RAMPages[Index].ReuseMode = ffrmTempStore,
                  format('Invalid reuse mode, block: %d',[Index]));

    { Close the temporary file. }
    bmtBufMgr.RemoveFile(aTmpFI);

    { Verify that RAM page count is now zero. }
    aCount := bmtBufMgr.RAMPageCount;
    CheckEquals(aCount, 0,
                format('Invalid RAM page count after closing temp file: %d',
                       [aCount]));

    { Create a persistent file. }
    aFI := bmtCreateFile('persistent', ffc_64k, 100, []);

    { Add some blocks. }
    for Index := 1 to pred(numBlocks) do begin
      aBlock := bmtBufMgr.AddBlock(aFI, bmtTI, Index, aRelMethod);
      aRelMethod(aBlock);
    end;

    { Verify the block count. }
    aCount := bmtBufMgr.RAMPageCount;
    CheckEquals(aCount, numBlocks,
                format('Invalid RAM Page count for persistent file: %d',
                       [aCount]));

    { Verify that recycle count is zero. }
    aCount := bmtBufMgr.RecycledCount;
    CheckEquals(aCount, 0,
                format('Invalid Recycled count for persistent file: %d',
                       [aCount]));

    { Verify the reuse mode of each page. }
    for Index := 0 to pred(aCount) do
      Check(bmtBufMgr.RAMPages[Index].ReuseMode = ffrmUseAsIs,
                  format('Invalid reuse mode, block: %d',[Index]));

    { Close the file.  }
    bmtBufMgr.RemoveFile(aFI);

  finally
    FFCloseFile(aFI);
    FFFreeMem(aFI, SizeOf(TffTransInfo));
    FFFreeMem(aTmpFI, SizeOf(TffTransInfo));
  end;

end;
{====================================================================}

initialization

  RegisterTest('Buffer manager tests', TffBufferMgrTest.Suite);

end.
