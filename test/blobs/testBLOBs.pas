unit testBLOBs;

interface

uses
  Classes,
  Forms,
  TestFramework,
  FFLLBase,
  FFLLComp,
  FFLLExcp,
  FFSrFold,
  FFSrBase,
  FFSrCfg,
  FFLLDict,
  FFClIntf,
  FFSrEng,
  FFDB;

type
  TFFBLOBTest = class(TTestCase)
  private
    FClientID   : TfFClientID;
    FEngine     : TffServerEngine;
    FPWHash     : TffWord32;
    FDBID       : TFFDatabaseID;
    FDB         : TffSRDatabase;
    FSessionID  : TffSessionID;
    FBLOBNr     : TffInt64;
    FOldStream  : TMemoryStream;
    FTmpStream  : TMemoryStream;
    FNewStream  : TMemoryStream;
    FBytesRead  : TffWord32;
    FCurID      : TffCursorID;
  protected
    procedure CompareMatchedStreams(aOldSt, aNewSt : TMemoryStream; aCount : integer);
      { Compares the specified number of bytes in both streams, starting at
        position zero in both streams. }
    procedure CompareMatchedStreams2(aOldSt, aNewSt : TMemoryStream; aCount : integer);
      { Compare the specified number of bytes in both streams, starting at the
        current position of each stream. }
    procedure CompareUnMatchedStreams(aOldSt, aNewSt : TMemoryStream; aCount : integer);
    function GetTableSize(const aFile : string) : Longword;
    procedure SetupVersion(const Version : Longint);
      { We have to manually call our own version of Setup so that we can control
        the version # of the table & therefore the BLOB engine used to manage
        the BLOBs. }
    procedure Teardown; override;

    { The following methods are called from the version-specific test methods. } 
    procedure testBloat;
    procedure testDeleteBLOB;
    procedure testExtendBLOB;
    procedure testOverwriteBLOB;
    procedure testRewriteBLOB;
    procedure testTruncateBLOB;
    procedure testWritePastBLOB;
    procedure testWriteReadBLOB;
  published
    procedure testBloatCurVersion;
    procedure testBloat210;

    procedure testDeleteBLOBCurVersion;
    procedure testDeleteBLOB210;

    procedure testExtendBLOBCurVersion;
    procedure testExtendBLOB210;

    procedure testOverwriteBLOBCurVersion;
    procedure testOverwriteBLOB210;

    procedure testRewriteBLOBCurVersion;
    procedure testRewriteBLOB210;

    procedure testTruncateBLOBCurVersion;
    procedure testTruncateBLOB210;

    procedure testWritePastBLOBCurVersion;
    procedure testWritePastBLOB210;

    procedure testWriteReadBLOBCurVersion;
    procedure testWriteReadBLOB210;

  end;

  MyStringList = class(TStrings)

  end;

function CreateBLOBDict : TffDataDictionary;

implementation

uses
  Dialogs,
  Windows,
  Math,
  SysUtils,
  FFSrBDE;

const
  csAlias = 'BLOBTest';

{===Utility routines=================================================}
function CreateBLOBDict : TffDataDictionary;
var
  FldArray : TffFieldList;
  IHFldList : TffFieldIHList;
begin

  Result := TffDataDictionary.Create(65536);
  with Result do begin

    { Add fields }
    AddField('Value', '', fftAutoInc, 10, 0, false, nil);
    AddField('BLOB1', '', fftBLOB, 0, 0, true, nil);
    AddField('BLOB2', '', fftBLOB, 0, 0, true, nil);
    AddField('UVal', '', fftInt32, 0, 0, true, nil);

    { Add indexes }
    FldArray[0] := 3;
    IHFldList[0] := '';
    AddIndex('Unique', '', 0, 1, FldArray, IHFldList, False, True, True);

  end;

end;
{====================================================================}

{====================================================================}
procedure TFFBLOBTest.testWriteReadBLOBCurVersion;
begin
  SetupVersion(FFVersionNumber);
  testWriteReadBLOB;
end;
{--------}
procedure TFFBLOBTest.testWriteReadBLOB210;
begin
  SetupVersion(FFVersion2_10);
  testWriteReadBLOB;
end;
{--------}
procedure TFFBLOBTest.testRewriteBLOBCurVersion;
begin
  SetupVersion(FFVersionNumber);
  testRewriteBLOB;
end;
{--------}
procedure TFFBLOBTest.testRewriteBLOB210;
begin
  SetupVersion(FFVersion2_10);
  testRewriteBLOB;
end;
{--------}
procedure TFFBLOBTest.testOverwriteBLOBCurVersion;
begin
  SetupVersion(FFVersionNumber);
  testOverwriteBLOB;
end;
{--------}
procedure TFFBLOBTest.testOverwriteBLOB210;
begin
  SetupVersion(FFVersion2_10);
  testOverwriteBLOB;
end;
{--------}
procedure TFFBLOBTest.testExtendBLOBCurVersion;
begin
  SetupVersion(FFVersionNumber);
  testExtendBLOB;
end;
{--------}
procedure TFFBLOBTest.testExtendBLOB210;
begin
  SetupVersion(FFVersion2_10);
  testExtendBLOB;
end;
{--------}
procedure TFFBLOBTest.testWritePastBLOBCurVersion;
begin
  SetupVersion(FFVersionNumber);
  testWritePastBLOB;
end;
{--------}
procedure TFFBLOBTest.testWritePastBLOB210;
begin
  SetupVersion(FFVersion2_10);
  testWritePastBLOB;
end;
{--------}
procedure TFFBLOBTest.testTruncateBLOBCurVersion;
begin
  SetupVersion(FFVersionNumber);
  testTruncateBLOB;
end;
{--------}
procedure TFFBLOBTest.testTruncateBLOB210;
begin
  SetupVersion(FFVersion2_10);
  testTruncateBLOB;
end;
{--------}
procedure TFFBLOBTest.testDeleteBLOBCurVersion;
begin
  SetupVersion(FFVersionNumber);
  testDeleteBLOB;
end;
{--------}
procedure TFFBLOBTest.testDeleteBLOB210;
begin
  SetupVersion(FFVersion2_10);
  testDeleteBLOB;
end;
{--------}
procedure TFFBLOBTest.testBloatCurVersion;
begin
  SetupVersion(FFVersionNumber);
  testBloat;
end;
{--------}
procedure TFFBLOBTest.testBloat210;
begin
  SetupVersion(FFVersion2_10);
  testBloat;
end;
{--------}
procedure TFFBLOBTest.testWriteReadBLOB;
const
  cCount = 20;
  cFiles : array[0..1] of string = ('..\DATA\winzip.log', '..\DATA\TestBLOB.exe');
var
  aInx, fileInx, ChunkInx : integer;
  aLength : Longint;
  aSize : integer;
  DBIResult : integer;
  Chunks, LeftOver : Integer;
begin
  { Add a BLOB to the table, read it back out, and ensure the BLOB
    matches what was read in by comparing what was read from the BLOB
    and compare it to what as written as strings. }

  Randomize;

  for fileInx := low(cFiles) to high(cFiles) do begin

    FOldStream.Clear;
    FOldStream.LoadFromFile(ExtractFilePath(Application.ExeName) + cFiles[fileInx]);

    for aInx := 1 to cCount do begin
      Application.ProcessMessages;
      { Calculate initial number of bytes. }
      aSize := 0;
      while aSize < 10 do
        aSize := Random(FOldStream.Size);
      DBIResult := FEngine.BLOBCreate(FCurID, fBLOBNr);
      try
        assert(DBIResult = DBIERR_None, 'WriteRead: couldn''t create BLOB for file ' + cFiles[fileInx]);
        Chunks := aSize div 8000;
        LeftOver := aSize mod 8000;
        for ChunkInx := 0 to Pred(Chunks) do begin
          DBIResult := FEngine.BLOBWrite(FCurID, fBLOBNr, ChunkInx * 8000,
                                         8000, PChar(FOldStream.Memory)[ChunkInx * 8000]);
          assert(DBIResult = DBIERR_None,
                 Format('WriteRead: BLOB Write failure in file %s, offset: %d',
                        [cFiles[fileInx], ChunkInx * 8000]));
        end;
        if LeftOver > 0 then begin
          DBIResult := FEngine.BLOBWrite(FCurID, fBLOBNr, Chunks * 8000,
                                         LeftOver, PChar(FOldStream.Memory)[Chunks * 8000]);
          assert(DBIResult = DBIERR_None,
                 Format('WriteRead: BLOB Write failure in file %s, offset: %d',
                        [cFiles[fileInx], Chunks * 8000]));
        end;

        { Verify the BLOB's length. }
        DBIResult := FEngine.BLOBGetLength(FCurID, FBLOBNr, aLength);
        assert(DBIResult = DBIERR_None, 'WriteRead: couldn''t read BLOB length for file ' + cFiles[fileInx]);
        CheckEquals(aSize, aLength,
                    'WriteRead: Unexpected length after initial write for file ' + cFiles[fileInx]);

        FNewStream.SetSize(aSize);
        DBIResult := FEngine.BLOBRead(FCurID, fBLOBNr, 0, aSize,
                                      FNewStream.Memory^, FBytesRead);
        assert(DBIResult = DBIERR_None, 'WriteRead: couldn''t read BLOB for file ' + cFiles[fileInx]);

        { Verify the bytes read. }
        CheckEquals(aSize, FBytesRead, 'WriteRead: Invalid # of bytes read for file ' + cFiles[fileInx]);

        { Each of these should match. }
        CompareMatchedStreams(FOldStream, FNewStream, FNewStream.Size);

      finally
        DBIResult := FEngine.BLOBFree(FCurID, fBLOBNr, false);
        CheckEquals(DBIERR_NONE, DBIResult, 'WriteRead: Couldn''t free BLOB for file ' + cFiles[fileInx]);
      end;
    end;  { for }
  end;  { for }

end;
{--------}
procedure TFFBLOBTest.testRewriteBLOB;
const
  cCount = 3000;
  cSize = 50000;
var
  aInx : integer;
  aLength : Longint;
  aSize : Longint;
  DBIResult : integer;
  StrBuffer : string;
begin
  { Add a BLOB to the table, write over a portion of the BLOB, and verify
    that we wind up with the correct BLOB length and content. }

  Randomize;
  SetLength(StrBuffer, cSize);
  for aInx := 1 to cSize do
    StrBuffer[aInx] := char(Random(127) + 1);
  FOldStream.Clear;
  FOldStream.Write(StrBuffer[1], cSize);
  FOldStream.Position := 0;

  DBIResult := FEngine.BLOBCreate(FCurID, fBLOBNr);
  assert(DBIResult = DBIERR_None, 'Rewrite: Couldn''t create BLOB');

  { Test sequence: truncate, write }
  for aInx := 1 to cCount do begin
    Application.ProcessMessages;
    try

      { Calculate a random length for the BLOB. }
      aSize := 0;
      while aSize < 10 do
        aSize := Random(cSize);

      DBIResult := FEngine.BLOBTruncate(FCurID, fBLOBNr, 0);
      assert(DBIResult = DBIERR_None, 'Rewrite: Could not truncate BLOB to size 0');
      DBIResult := FEngine.BLOBWrite(FCurID, fBLOBNr, 0, aSize,
                                     FOldStream.Memory^);
      assert(DBIResult = DBIERR_None, 'Rewrite: Couldn''t write BLOB');

      { Verify the BLOB's length. }
      DBIResult := FEngine.BLOBGetLength(FCurID, FBLOBNr, aLength);
      assert(DBIResult = DBIERR_None, 'Rewrite: couldn''t read BLOB length phase 2');
      CheckEquals(aSize, aLength,
                 'Rewrite: Unexpected length after initial write.');

      { Read the BLOB. }
      FNewStream.SetSize(aSize);
      DBIResult := FEngine.BLOBRead(FCurID, fBLOBNr, 0, aSize,
                                    FNewStream.Memory^, FBytesRead);
      CheckEquals(DBIERR_None, DBIResult, 'Rewrite: couldn''t read BLOB');

      { Verify the bytes read. }
      CheckEquals(aSize, FBytesRead, 'Rewrite: Invalid # of bytes read');

      { Each of these should match. }
      CompareMatchedStreams(FOldStream, FNewStream, aSize);
    finally
      DBIResult := FEngine.BLOBFree(FCurID, fBLOBNr, false);
      assert(DBIResult = DBIERR_None, 'Rewrite: couldn''t free BLOB');
    end;
  end;  { for }

  { Test sequence: write, truncate }
  for aInx := 1 to cCount do begin
    Application.ProcessMessages;
    try

      { Calculate a random length for the BLOB. }
      aSize := 0;
      while aSize < 10 do
        aSize := Random(cSize);

      DBIResult := FEngine.BLOBWrite(FCurID, fBLOBNr, 0, aSize,
                                     FOldStream.Memory^);
      assert(DBIResult = DBIERR_None, 'Rewrite part 2: Couldn''t write BLOB');
      DBIResult := FEngine.BLOBTruncate(FCurID, fBLOBNr, aSize);
      assert(DBIResult = DBIERR_None,
             'Rewrite part 2: Could not truncate BLOB to size ' +
             IntToStr(aSize));

      { Verify the BLOB's length. }
      DBIResult := FEngine.BLOBGetLength(FCurID, FBLOBNr, aLength);
      assert(DBIResult = DBIERR_None,
             'Rewrite part 2: couldn''t read BLOB length phase 2');
      CheckEquals(aSize, aLength,
                 'Rewrite part 2: Unexpected length after initial write.');

      { Read the BLOB. }
      FNewStream.SetSize(aSize);
      DBIResult := FEngine.BLOBRead(FCurID, fBLOBNr, 0, aSize,
                                    FNewStream.Memory^, FBytesRead);
      CheckEquals(DBIERR_None, DBIResult,
                  'Rewrite part 2: couldn''t read BLOB');

      { Verify the bytes read. }
      CheckEquals(aSize, FBytesRead,
                  'Rewrite part 2: Invalid # of bytes read');

      { Each of these should match. }
      CompareMatchedStreams(FOldStream, FNewStream, aSize);
    finally
      DBIResult := FEngine.BLOBFree(FCurID, fBLOBNr, false);
      assert(DBIResult = DBIERR_None,
             'Rewrite part 2: couldn''t free BLOB');
    end;
  end;  { for }
end;
{--------}
procedure TFFBLOBTest.testOverwriteBLOB;
const
  cCount = 1000;
var
  aBuffer : PffByteArray;
  aInx : integer;
  aLength : Longint;
  aOverwriteLen : Longint;
  aPos : Longint;
  aSize, aSizeSav : Longint;
  DBIResult : integer;
begin
  { Add a BLOB to the table, write over a portion of the BLOB, and verify
    that we wind up with the correct BLOB length and content. }

  FOldStream.Clear;
  FOldStream.LoadFromFile(ExtractFilePath(Application.ExeName) + '..\DATA\winzip.log');
  FOldStream.Position := 0;
  Randomize;

  for aInx := 1 to cCount do begin
    Application.ProcessMessages;
    try
      FTmpStream.LoadFromStream(FOldStream);
      DBIResult := FEngine.BLOBCreate(FCurID, fBLOBNr);
      assert(DBIResult = DBIERR_None, 'Overwrite: Couldn''t create BLOB');

      { Calculate a random length for the BLOB. }
      aSize := 0;
      while aSize < 10 do
        aSize := Random(FTmpStream.Size);
      aSizeSav := aSize;

      DBIResult := FEngine.BLOBWrite(FCurID, fBLOBNr, 0, aSize,
                                     FTmpStream.Memory^);
      assert(DBIResult = DBIERR_None, 'Overwrite: Couldn''t write BLOB');

      { Verify the BLOB's length. }
      DBIResult := FEngine.BLOBGetLength(FCurID, FBLOBNr, aLength);
      assert(DBIResult = DBIERR_None, 'Overwrite: couldn''t read BLOB length phase 2');
      CheckEquals(aSize, aLength,
                 'Overwrite: Unexpected length after initial write.');

      { Overwrite a portion of the BLOB. }
      aPos := Random(aSize div 2);
      aOverWriteLen := 0;
      while aOverWriteLen = 0  do
        aOverwriteLen := Random(aSize);
      GetMem(aBuffer, aOverwriteLen);
      Fillchar(aBuffer^, aOverwriteLen, 1);
      try
        FTmpStream.Position := aPos;
        FTmpStream.Write(aBuffer^, aOverwriteLen);
        DBIResult := FEngine.BLOBWrite(FCurID, FBLOBNr, aPos, aOverwriteLen,
                                       aBuffer^);
        CheckEquals(DBIERR_NONE, DBIResult, 'Overwrite: Overwrite failure');
      finally
        FreeMem(aBuffer, aOverWriteLen);
      end;

      { Update the size. }
      aSize := Max(aLength, aPos + aOverwriteLen);

      { Verify the BLOB's length. }
      DBIResult := FEngine.BLOBGetLength(FCurID, FBLOBNr, aLength);
      assert(DBIResult = DBIERR_None, 'Overwrite: couldn''t read BLOB length');
      CheckEquals(aSize, aLength,
                 'Overwrite: Unexpected length after overwrite.');

      { Read the BLOB. }
      FNewStream.SetSize(aSize);
      DBIResult := FEngine.BLOBRead(FCurID, fBLOBNr, 0, aSize,
                                    FNewStream.Memory^, FBytesRead);
      CheckEquals(DBIERR_None, DBIResult, 'Overwrite: couldn''t read BLOB');

      { Verify the bytes read. }
      CheckEquals(aSize, FBytesRead, 'Overwrite: Invalid # of bytes read');

      { Each of these should match. }
      try
        CompareMatchedStreams(FTmpStream, FNewStream, aSize);
      except
        showMessage(format('aSize %d, aPos %d, aOverwriteLen %d',
                           [aSizeSav, aPos, aOverwriteLen]));
        raise;
      end;
    finally
      DBIResult := FEngine.BLOBFree(FCurID, fBLOBNr, false);
      assert(DBIResult = DBIERR_None, 'Overwrite: couldn''t free BLOB');
    end;
  end;  { for }

end;
{--------}
procedure TFFBLOBTest.testExtendBLOB;
var
  AddedChunk : array[0..4999] of char;
  aLength : Longint;
  DBIResult  : integer;
begin
  { We need to ensure that we can successfully extend a BLOB.  We're
    testing this by adding a 5,000 byte BLOB and then adding an
    additional 5,000 bytes to the BLOB. The BLOB should then match the
    first 10,000 bytes of our test file. }

  { Add starting 5,000 byte BLOB. }
  FOldStream.Clear;
  FOldStream.SetSize(10000);
  FOldStream.LoadFromFile(ExtractFilePath(Application.ExeName) + '..\DATA\winzip.log');
  DBIResult := FEngine.BLOBCreate(FCurID, fBLOBNr);
  assert(DBIResult = DBIERR_None, 'Extend: couldn''t create BLOB.');
  DBIResult := FEngine.BLOBWrite(FCurID, fBLOBNr, 0, 5000, FOldStream.Memory^);
  assert(DBIResult = DBIERR_None, 'Extend: couldn''t write BLOB.');
  DBIResult := FEngine.BLOBGetLength(FCurID, FBLOBNr, aLength);
  CheckEquals(DBIERR_NONE, DBIResult, 'Extend: Failed to get BLOB length, phase 1');
  CheckEquals(5000, aLength, 'Extend: Invalid length, phase 1');

  { Add 5,000 bytes to the BLOB. }
  FOldStream.Position := 5000;
  FOldStream.Read(AddedChunk, 5000);
  DBIResult := FEngine.BLOBWrite(FCurID, fBLOBNr, 5000, 5000, AddedChunk);
  assert(DBIResult = DBIERR_None, 'Extend: couldn''t write BLOB.');

  { Verify the length of the BLOB. }
  DBIResult := FEngine.BLOBGetLength(FCurID, FBLOBNr, aLength);
  CheckEquals(DBIERR_NONE, DBIResult, 'Extend: Failed to get BLOB length, phase 1');
  CheckEquals(10000, aLength, 'Extend: Invalid length, phase 2');

  { Read the BLOB into FNewStream and then compare OldStream and
   NewStream to ensure they match. }
  FNewStream.SetSize(10000);
  DBIResult := FEngine.BLOBRead(FCurID, fBLOBNr, 0, 10000, FNewStream.Memory^, FBytesRead);
  assert(DBIResult = DBIERR_None, 'Extend: couldn''t read BLOB.');

  CompareMatchedStreams(FOldStream, FNewStream, FNewStream.Size);

end;
{--------}
procedure TFFBLOBTest.testWritePastBLOB;
var
  DBIResult : integer;
begin
  { Verify that we cannot write past the end of the BLOB. }

  { Add 5,000 byte BLOB}
  FOldStream.Clear;
  FOldStream.SetSize(10000);
  FOldStream.LoadFromFile(ExtractFilePath(Application.ExeName) + '..\DATA\winzip.log');
  DBIResult := FEngine.BLOBCreate(FCurID, fBLOBNr);
  assert(DBIResult = DBIERR_None, 'Couldn''t create BLOB');
  DBIResult := FEngine.BLOBWrite(FCurID, fBLOBNr, 0, 5000, FOldStream.Memory^);
  assert(DBIResult = DBIERR_None, 'Couldn''t write BLOB');

  { Now attempt to write somewhere past the end. }
  DBIResult := FEngine.BLOBWrite(FCurID, fBLOBNr, 333333, 333, FOldStream.Memory^);
  CheckEquals(DBIERR_INVALIDBLOBOFFSET, DBIResult,
              'WritePast: Unexpected result when writing past.');
end;
{--------}
procedure TFFBLOBTest.testTruncateBLOB;
const
  cNumLoops = 250;
var
  DBIResult,
  Inx,
  MaxSize,
  NewSize : Integer;
begin
  { Truncate a BLOB and file to the same length. If the two match, our
    test passed. }
  try
    for Inx := 1 to cNumLoops do begin
      Application.ProcessMessages;
      { Use a file as the source for the BLOB data. }
      FOldStream.Clear;
      FOldStream.LoadFromFile(ExtractFilePath(Application.ExeName) + '..\DATA\winzip.log');
      MaxSize := FOldStream.Size;

      { Add a BLOB. }
      DBIResult := FEngine.BLOBCreate(FCurID, fBLOBNr);
      assert(DBIResult = DBIERR_NONE, 'Truncate: couldn''t create BLOB');

      { Write the entire stream to the BLOB. }
      DBIResult := FEngine.BLOBWrite(FCurID, fBLOBNr, 0, MaxSize,
                                     FOldStream.Memory^);
      assert(DBIResult = DBIERR_NONE, 'Truncate: couldn''t write BLOB');

      { Calculate a new size & truncate the new BLOB. }
      NewSize := Random(MaxSize div 2);
      DBIResult := FEngine.BLOBTruncate(FCurID, fBLOBNr, NewSize);
      assert(DBIResult = DBIERR_NONE, 'Truncate: couldn''t truncate BLOB');

      { Read the truncated blob into newStream and compare the two streams. }
      FNewStream.SetSize(NewSize);
      DBIResult := FEngine.BLOBRead(FCurID, fBLOBNr, 0, NewSize, FNewStream.Memory^,
                                    FBytesRead);
      assert(DBIResult = DBIERR_NONE, 'Truncate: couldn''t read BLOB');

      { Verify the bytes read. }
      CheckEquals(NewSize, FBytesRead, 'Truncate: Invalid # of bytes read');
      CompareMatchedStreams(FOldStream, FNewStream, FBytesRead);
    end;  { for }
  finally
  end;
end;
{--------}
procedure TFFBLOBTest.testDeleteBLOB;
var
  DBIResult : integer;
begin
  { Add a BLOB. }
  FOldStream.Clear;
  FOldStream.LoadFromFile(ExtractFilePath(Application.ExeName) + '..\DATA\winzip.log');
  DBIResult := FEngine.BLOBCreate(FCurID, fBLOBNr);
  assert(DBIResult = DBIERR_None, 'Delete: couldn''t create BLOB');
  DBIResult := FEngine.BLOBWrite(FCurID, fBLOBNr, 0, 5000, FOldStream.Memory^);
  assert(DBIResult = DBIERR_None, 'Delete: couldn''t write BLOB');

  { Delete the BLOB. }
  DBIResult := FEngine.BLOBDelete(FCurID, fBLOBNr);
  assert(DBIResult = DBIERR_None, 'Delete: couldn''t delete BLOB');

  { Try to read the BLOB we just deleted. }
  FNewStream.SetSize(222);
  DBIResult := FEngine.BLOBRead(FCurID, fBLOBNr, 0, 222, FNewStream.Memory^, FBytesRead);
  assert(DBIResult = DBIERR_BLOBERR,
         'Delete: Attempt to read deleted BLOB did not fail as expected');
end;
{--------}
procedure TFFBLOBTest.testBloat;
const
  cAddCount = 1000;
var
  MyClient   : TffClient;
  MySession  : TffSession;
  MyDatabase : TffDatabase;
  MyTable    : TffTable;
  TaskID     : Longint;
  StartList,
  EndList    : TMemoryStream;
  i          : Integer;
  Done       : Boolean;
  TaskStatus : TffRebuildStatus;
begin
  FEngine.DatabaseClose(FDBID);
  {setup our client}
  MyClient := TffClient.Create(nil);
  try
    MyClient.ClientName := 'ConvClient' + IntToStr(GetCurrentThreadID);
    MyClient.ServerEngine := FEngine;
    {setup our session}
    MySession := TffSession.Create(nil);
    try
      MySession.ClientName := MyClient.ClientName;
      MySession.SessionName := 'ConvSess' + IntToStr(GetCurrentThreadID);
      MySession.Open;
      {setup a database}
      MyDatabase := TffDatabase.Create(nil);
      try
        MyDatabase.SessionName := MySession.SessionName;
        MyDatabase.AliasName := csAlias;
        MyDatabase.DatabaseName := csAlias;

        MyTable := TffTable.Create(nil);
        try
          MyTable.SessionName := MySession.SessionName;
          MyTable.DatabaseName := MyDatabase.DatabaseName;
          MyTable.Exclusive := True;
          MyTable.TableName := 'TestBloat';

          { Add a bunch of records with BLOBs to the table. }
          with MyTable do begin
            EmptyTable;
            CheckEquals(DBIERR_NONE, PackTable(TaskID), 'Pack request failed');
            { Wait for pack to complete. }
            Done := False;
            while not Done do begin
              Session.GetTaskStatus(TaskID, Done, TaskStatus);
              Application.ProcessMessages;
            end;

            Open;
            MyDatabase.StartTransaction;
            for i := 1 to cAddCount do begin
              Insert;
              FieldByName('Activity').asString := 'z';
              Post;
            end;
            MyDatabase.Commit;
          end;

          { Is the table a reasonable size? }
          MyTable.Close;
          MyDatabase.Close;
          MySession.CloseInactiveTables;
          Assert(GetTableSize(ExtractFilePath(Application.ExeName) +
                              '..\DATA\TestBloat.ff2') < 260000,
                 'The table is bigger than it should be.');

          { Now we need to be sure that our bloat preventing code
            rollsback correctly. }
          MyDatabase.Open;
          MyTable.Open;

          StartList := TMemoryStream.Create;
          try
            FEngine.CursorListBLOBFreeSpace(MyTable.CursorID,
                                            False,
                                            StartList);
            { Add a bunch of records with BLOBs to the table, but
              roll it back this time. }
            with MyTable do begin
              MyDatabase.StartTransaction;
              for i := 1 to cAddCount do begin
                Insert;
                FieldByName('Activity').asString := 'z';
                Post;
              end;
              MyDatabase.Rollback;
            end;

            { Now lets get another list of free space and see if it
              matches the first list we got. }
            EndList := TMemoryStream.Create;
            try
              FEngine.CursorListBLOBFreeSpace(MyTable.CursorID,
                                              False,
                                              EndList);
              StartList.Position := 0;
              EndList.Position := 0;

              { The lists should be the same size. }
              Assert(StartList.Size = EndList.Size,
                     'The blob free segment lists are not the same size');

              CompareMatchedStreams2(StartList,
                                     EndList,
                                     StartList.Size);

              { To be sure we didn't get luck, we're going to do the
                last test again, but commit it this time. It VERY
                unlikly that the free lists could be the same after
                committing all those adds. }
              StartList.Position := 0;
              with MyTable do begin
                MyDatabase.StartTransaction;
                for i := 1 to cAddCount do begin
                  Insert;
                  FieldByName('Activity').asString := 'z';
                  Post;
                end;
                MyDatabase.Commit;
              end;

              FEngine.CursorListBLOBFreeSpace(MyTable.CursorID,
                                              False,
                                              EndList);
              StartList.Position := 0;
              EndList.Position := 0;

              { The lists should not be the same size. }
              Assert(StartList.Size <> EndList.Size,
                     'The blob free segment lists are the same size');

              if (StartList.Size = EndList.Size) then
                try
                  CompareMatchedStreams2(StartList,
                                         EndList,
                                         StartList.Size);
                  Assert(False, 'The list compare should have failed.');
                except
                end;
            finally
              EndList.Free;
            end;
          finally
            StartList.Free;
          end;
        finally
          MyTable.Free;
        end;
      finally
        MyDatabase.Free;
      end;
    finally
      MySession.Free;
    end;
  finally
    MyClient.Free;
  end;
  FEngine.DatabaseOpen(FClientID,
                       csAlias,
                       omReadWrite,
                       smShared,
                       100000,
                       FDBID);
end;
{--------}
procedure TFFBLOBTest.CompareMatchedStreams(aOldSt, aNewSt : TMemoryStream; aCount : integer);
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
procedure TFFBLOBTest.CompareMatchedStreams2(aOldSt, aNewSt : TMemoryStream; aCount : integer);
var
  OldChar, NewChar : Char;
  i : integer;
begin
  for i := 0 to pred(aCount) do begin
    aOldSt.Read(OldChar, 1);
    aNewSt.Read(NewChar, 1);
    assert(OldChar = NewChar, 'String mismatch at pos ' + intToStr(i));
  end;
end;
{--------}
procedure TFFBLOBTest.CompareUnMatchedStreams(aOldSt, aNewSt : TMemoryStream; aCount : integer);
var
  OldChar, NewChar : Char;
  i : integer;
  Equal : boolean;
begin
  Equal := True;

  aOldSt.Position := 0;
  aNewSt.Position := 0;

  for i := 0 to pred(aCount) do begin
    aOldSt.Read(OldChar, 1);
    aNewSt.Read(NewChar, 1);
    if OldChar <> NewChar then begin
      Equal := False;
      break;
    end;
  end;

  assert(not Equal, 'Streams Matched');

end;
{--------}
{ The following database cracker class allows us to control the version for
  newly-created tables. }
type
  DBCracker = class(TffSrDatabase);
  
procedure TFFBLOBTest.SetupVersion(const Version : Longint);
var
  User : TffUserItem;
  Dict : TffDataDictionary;
begin
  FOldStream := TMemoryStream.Create;
  FNewStream := TMemoryStream.Create;
  FTmpStream := TMemoryStream.Create;

  { Set up a server engine. }
  if assigned(FEngine) then
    FEngine.Free;
  try
    FEngine := TffServerEngine.Create(nil);
    FEngine.State := ffesStarted;
  except
    on e : Exception do
      ShowException(e, @e);
  end;

  { Set up a client. }
  fPWHash := 5;
  FClientID := 1;
  User := TffUserItem.Create('Me', 'Carter', 'Scott', fPWHash, [arAdmin]);
  FEngine.Configuration.AddUser(User.UserID, User.LastName, User.FirstName, fPWHash, [arAdmin, arRead, arUpdate]);
  FEngine.ClientAdd(FClientID, 'MyClient', 'Me', 10, fPWHash);

  { Set up a session. }
  FSessionID := 0;
  CheckEquals(DBIERR_NONE, FEngine.SessionAdd(FClientID, 10, FSessionID),
              'Could not add a session.');

  { Set up the alias and database. }
  FEngine.DatabaseDeleteAlias(csAlias, FClientID);
  CheckEquals(DBIERR_NONE,
              FEngine.DatabaseAddAlias(csAlias,
                                       ExtractFilePath(Application.ExeName) +
                                       '..\DATA',
                                       False,
                                       FClientID),
              'Could not add an alias');
  FDBID := 0;
  CheckEquals(DBIERR_NONE, FEngine.DatabaseOpen(FClientID, csAlias, omReadWrite,
                                                smExclusive, 1000, FDBID),
              'Could not open the database.');
  FEngine.CheckDatabaseIDAndGet(fDBID, fDB);

  { Set the version for new tables. }
  DBCracker(fDB).dbSetNewTableVersion(Version);
  fDB.Deactivate;

  { Create & open the table. }
  Dict := CreateBLOBDict;
  try
    CheckEquals(DBIERR_NONE,
                FEngine.TableBuild(FDBID, True, 'TestBLOBs', False, Dict),
                'Failed to build TestBLOBs table');
  finally
    Dict.Free;
  end;
  FCurID := 0;
  CheckEquals(DBIERR_NONE,FEngine.TableOpen(fDB.DatabaseID, 'TestBLOBs', true,
                                            '', 0, omReadWrite, smExclusive,
                                            10000, FCurID, FOldStream),
              'Could not open a table');
end;
{--------}
procedure TFFBLOBTest.Teardown;
begin
  if assigned(FEngine) then begin
    if FCurID <> 0 then
      FEngine.CursorClose(FCurID);
    if FDBID <> 0 then
      FEngine.DatabaseClose(FDBID);
    if FSessionID <> 0 then
      FEngine.SessionRemove(FClientID, FSessionID);
    FEngine.ClientRemove(FClientID);
    FEngine.Free;
    FEngine := nil;
  end;
  FOldStream.Free;
  FNewStream.Free;
  FTmpStream.Free;
end;

{====================================================================}

function TFFBLOBTest.GetTableSize(const aFile : string) : Longword;
var
  FileHandle : DWord;
begin
  FileHandle := CreateFile(PChar(aFile),
                             GENERIC_READ,
                             0,
                             nil,
                             OPEN_EXISTING,
                             FILE_ATTRIBUTE_NORMAL,
                             0);
  if FileHandle = INVALID_HANDLE_VALUE then
    raise Exception.Create(SysErrorMessage(GetLastError))
  else
    try
      try
        Result := GetFileSize(FileHandle, nil);
      except
        Result := 0;
      end;
    finally
      CloseHandle(FileHandle);
    end;
end;

initialization
  RegisterTest('BLOB Tests', TffBLOBTest.Suite);

end.
