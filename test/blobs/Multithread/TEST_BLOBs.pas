unit TEST_BLOBs;

interface

uses
  Classes,
  Forms,
  DUnit,
  FFLLBase,
  FFLLCore,
  FFLLExcp,
  FFSrFold,
  FFSrBase,
  FFSrCfg,
  FFLLDict,
  FFClIntf,
  FFSrEng;

type
  TFFBLOBTest = class(TTestCase)
  private
    fClientID : TffClientID;
    fEngine : TffServerEngine;
    fPWHash : TffWord32;
    fDBID   : TFFDatabaseID;
    fDB     : TffSRDatabase;
    fSessionID : TffSessionID;
    fBLOBNr    : TffInt64;
    fOldStream  : TMemoryStream;
    fNewStream  : TMemoryStream;
    fBytesRead : integer;
    fCurID : TffCursorID;
  protected
    procedure Prepare;
    procedure Terminate;
    procedure CompareMatchedStreams(aOldSt, aNewSt : TMemoryStream; aCount : integer);
    procedure CompareUnMatchedStreams(aOldSt, aNewSt : TMemoryStream; aCount : integer);
  published
    procedure testWriteReadBLOB;
    procedure testExtendBLOB;
    procedure testWritePastBLOB;
    procedure testTruncateBLOB;
    procedure testDeleteBLOB;
  end;

  MyStringList = class(TStrings)

  end;

  function Suite : ITestSuite;

implementation

uses
  SysUtils,
  FFSrBDE;
{--------}
function Suite : ITestSuite;
begin
  Result := TTestSuite.Create('BLOB Tests');
  Result.AddTest(TFFBLOBTest.MakeTestSuite);
end;
{--------}
procedure TFFBLOBTest.testWriteReadBLOB;
var
  DBIResult : integer;
begin
  {Add a BLOB to the table, read it back out, and ensure the BLOB
   matches what was read in by comparing what was read from the BLOB
   and compare it to what as written as strings.}

  Prepare;
  fOldStream.Clear;
  fOldStream.LoadFromFile(ExtractFilePath(Application.ExeName) + '..\BLOBs\winzip.log');
  DBIResult := fEngine.BLOBCreate(fCurID, fBLOBNr);
  assert(DBIResult = DBIERR_None, 'Write/Read: couldn''t create BLOB');
  DBIResult := fEngine.BLOBWrite(fCurID, fBLOBNr, 0, fOldStream.Size, fOldStream.Memory^);
  assert(DBIResult = DBIERR_None, 'Write/Read: couldn''t write BLOB');
  fNewStream.SetSize(fOldStream.Size);
  DBIResult := fEngine.BLOBRead(fCurID, fBLOBNr, 0, fOldStream.Size, fNewStream.Memory^, fBytesRead);
  assert(DBIResult = DBIERR_None, 'Write/Read: couldn''t read BLOB');
  DBIResult := fEngine.BLOBFree(fCurID, fBLOBNr, false);
  assert(DBIResult = DBIERR_None, 'Write/Read: couldn''t free BLOB');

  {each of these should match}
  CompareMatchedStreams(fOldStream, fNewStream, fNewStream.Size);

  {mess the new blob up and see if it catches that the blobs (streams)
   don't match}
  fOldStream.Position := (fOldStream.Size div 2);
  fOldStream.Write('Add this junk', 13);

  CompareUnMatchedStreams(fOldStream, fNewStream, fNewStream.size);

  Terminate;
end;
{--------}
procedure TFFBLOBTest.testExtendBLOB;
var
  AddedChunk : array[0..4999] of char;
  DBIResult  : integer;
begin
  {we need to ensure that we can successfully extend a BLOB.  We're
   testing this by adding a 5,000 byte BLOB and then adding an
   additional 5,000 bytes to the BLOB.  The BLOB should then match the
   first 10,000 bytes of our test file.}

  Prepare;

  {add starting 5,000 byte BLOB}
  fOldStream.Clear;
  fOldStream.SetSize(10000);
  fOldStream.LoadFromFile(ExtractFilePath(Application.ExeName) + '..\BLOBs\winzip.log');
  DBIResult := fEngine.BLOBCreate(fCurID, fBLOBNr);
  assert(DBIResult = DBIERR_None, 'Extend: couldn''t create BLOB.');
  DBIResult := fEngine.BLOBWrite(fCurID, fBLOBNr, 0, 5000, fOldStream.Memory^);
  assert(DBIResult = DBIERR_None, 'Extend: couldn''t write BLOB.');

  {add 5,000 bytes to the BLOB}
  fOldStream.Position := 5000;
  fOldStream.Read(AddedChunk, 5000);
  DBIResult := fEngine.BLOBWrite(fCurID, fBLOBNr, 5000, 5000, AddedChunk);
  assert(DBIResult = DBIERR_None, 'Extend: couldn''t write BLOB.');

  {read the BLOB into fNewStream and then compare OldStream and
   NewStream to ensure they match}
  fNewStream.SetSize(10000);
  DBIResult := fEngine.BLOBRead(fCurID, fBLOBNr, 0, 10000, fNewStream.Memory^, fBytesRead);
  assert(DBIResult = DBIERR_None, 'Extend: couldn''t read BLOB.');

  CompareMatchedStreams(fOldStream, fNewStream, fNewStream.Size);

  Terminate;
end;
{--------}
procedure TFFBLOBTest.testWritePastBLOB;
var
  DBIResult : integer;
begin
  {we are going to attempt to write past the end of a BLOB to ensure
   it isn't allowed}

  Prepare;

  {add 5,000 byte BLOB}
  fOldStream.Clear;
  fOldStream.SetSize(10000);
  fOldStream.LoadFromFile(ExtractFilePath(Application.ExeName) + '..\BLOBs\winzip.log');
  DBIResult := fEngine.BLOBCreate(fCurID, fBLOBNr);
  assert(DBIResult = DBIERR_None, 'Couldn''t create BLOB');
  DBIResult := fEngine.BLOBWrite(fCurID, fBLOBNr, 0, 5000, fOldStream.Memory^);
  assert(DBIResult = DBIERR_None, 'Couldn''t write BLOB');

  DBIResult := fEngine.BLOBWrite(fCurID, fBLOBNr, 333333, 333, fOldStream.Memory^);
  assert(DBIResult = 9998, 'Write: wrote past a BLOB');

  Terminate;
end;
{--------}
procedure TFFBLOBTest.testTruncateBLOB;
var
  DBIResult : integer;
begin
  {Truncate a BLOB and file to the same length. If the two match, our
   test passed.}
  Prepare;

  //add a blob
  fOldStream.Clear;
  fOldStream.LoadFromFile(ExtractFilePath(Application.ExeName) + '..\BLOBs\winzip.log');
  DBIResult := fEngine.BLOBCreate(fCurID, fBLOBNr);
  assert(DBIResult = DBIERR_NONE, 'Truncate: couldn''t create BLOB');
  DBIResult := fEngine.BLOBWrite(fCurID, fBLOBNr, 0, 5000, fOldStream.Memory^);
  assert(DBIResult = DBIERR_NONE, 'Truncate: couldn''t write BLOB');
  //truncate the newly added blob
  DBIResult := fEngine.BLOBTruncate(fCurID, fBLOBNr, 4000);
  assert(DBIResult = DBIERR_NONE, 'Truncate: couldn''t truncate BLOB');

  {read the truncated blob into newStream and compare the two streams}
  fNewStream.SetSize(4000);
  DBIResult := fEngine.BLOBRead(fCurId, fBLOBNr, 0, 4000, fNewStream.Memory^, fBytesRead);
  assert(DBIResult = DBIERR_NONE, 'Truncate: couldn''t read BLOB');

  CompareMatchedStreams(fOldStream, fNewStream, fBytesRead);

  Terminate;
end;
{--------}
procedure TFFBLOBTest.testDeleteBLOB;
var
  DBIResult : integer;
begin
  Prepare;

  //add a blob
  fOldStream.Clear;
  fOldStream.LoadFromFile(ExtractFilePath(Application.ExeName) + '..\BLOBs\winzip.log');
  DBIResult := fEngine.BLOBCreate(fCurID, fBLOBNr);
  assert(DBIResult = DBIERR_None, 'Delete: couldn''t create BLOB');
  DBIResult := fEngine.BLOBWrite(fCurID, fBLOBNr, 0, 5000, fOldStream.Memory^);
  assert(DBIResult = DBIERR_None, 'Delete: couldn''t write BLOB');

  {Delete the BLOB}
  DBIResult := fEngine.BLOBDelete(fCurID, fBLOBNr);
  assert(DBIResult = DBIERR_None, 'Delete: couldn''t delete BLOB');

  {Try to read the BLOB we just deleted}
  fNewStream.SetSize(222);
  DBIResult := fEngine.BLOBRead(fCurID, fBLOBNr, 0, 222, fNewStream.Memory^, fBytesRead);
  assert(DBIResult = 10030, 'Delete: couldn''t read BLOB');

  Terminate;
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
    fOldStream.Read(OldChar, 1);
    fNewStream.Read(NewChar, 1);
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
    fOldStream.Read(OldChar, 1);
    fNewStream.Read(NewChar, 1);
    if OldChar <> NewChar then begin
      Equal := False;
      break;
    end;
  end;

  assert(not Equal, 'Streams Matched');

end;
{--------}
procedure TFFBLOBTest.Prepare;
var
  User     : TffUserItem;
begin

  fOldStream := TMemoryStream.Create;
  fNewStream := TMemoryStream.Create;

  {setup a server engine}
  if assigned(fEngine) then
    fEngine.Free;
  try
    fEngine := TffServerEngine.Create(nil);
    fEngine.State := ffesStarted;
  except
    on e : Exception do
      ShowException(e, @e);
  end;


  {setup a client}
  fPWHash := 5;
  fClientID := 1;
  User := TffUserItem.Create('Me', 'Carter', 'Scott', fPWHash, [arAdmin]);
  fEngine.Configuration.AddUser(User.UserID, User.LastName, User.FirstName, fPWHash, [arAdmin, arRead, arUpdate]);
  fEngine.ClientAdd(fClientID, 'MyClient', 'Me', 10, fPWHash);

  {setup a session}
  fEngine.SessionAdd(fClientID, 10, fSessionID);


  {setup a database}
  fEngine.DatabaseAddAlias('BLOBTest',
                           ExtractFilePath(Application.ExeName) + '..\BLOBs',
                           fClientID);
  fEngine.DatabaseOpen(fClientID, 'BLOBTest', omReadWrite, smExclusive,
                       1000, fDBID);
  fEngine.CheckDatabaseIDAndGet(fDBID, fDB);

  fEngine.TableOpen(fDB.DatabaseID, 'TestTable', true, '', 0, omReadWrite,
                    smExclusive, 1000, fCurID, fOldStream);

end;
{--------}
procedure TFFBLOBTest.Terminate;
begin
  if assigned(fEngine) then begin
    fEngine.Free;
    FEngine := nil;
  end;
  if assigned (fOldStream) then
    fOldStream.free;
  if assigned (fNewStream) then
    fNewStream.free;
end;
end.
