unit testCursorExt;

interface

uses
  basetestcase,
  ffllbase,
  fflleng,
  ffsrbase,
  uClTBase,
  TestFramework;

type
  TffCursorExtender = class(TffBaseEngineExtender)
  protected
    FOldBuffer : PffByteArray;
    FOldBufferLen : Integer;
    FOldBufferMatched : Boolean;
  public
    constructor Create(aOwner : TffBaseEngineMonitor); override;
    destructor Destroy; override;
    function  Notify(aServerObject : TffObject;
                      aAction      : TffEngineAction) : TffResult; override;
    procedure SetOldBuffer(aBuffer : PffByteArray; aBufLen : Integer);

    property OldBuffer : PffByteArray read FOldBuffer;
    property OldBufferLen : Integer read FOldBufferLen;
    property OldBufferMatched : boolean read FOldBufferMatched;
  end;

  TffCursorMonitor = class(TffBaseEngineMonitor)
  protected
    procedure bemSetServerEngine(anEngine : TffBaseServerEngine); override;

  public
    function  Interested(aServerObject : TffObject) : TffBaseEngineExtender; override;
  end;

  TffCursorExtTest = class(TffBaseClientTest)
  protected
    FCursorMon : TffCursorMonitor;
    FCursorExt : TffCursorExtender;

    procedure Setup; override;
    procedure Teardown; override;
  public
    property CursorExt : TffCursorExtender read FCursorExt;
  published
    procedure testDeleteRecord;
      { Currently tests old record buffer only. }
    procedure testModifyRecord;
      { Currently tests old record buffer only. }
  end;

implementation

uses
  ffsrbde,
  ffsreng;

{===TffCursorMonitor=================================================}
function TffCursorMonitor.Interested(aServerObject : TffObject) : TffBaseEngineExtender;
begin
  { This should always be a TffSrBaseCursor, TffSrClient or TffDatabase,
    but we need to check to be sure. }
  if (aServerObject is TffSrBaseCursor) then
    Result := TffCursorExtender.Create(self)
  else
    Result := nil;
end;
{--------}
procedure TffCursorMonitor.bemSetServerEngine(anEngine : TffBaseServerEngine);
begin
  inherited bemSetServerEngine(anEngine);
  AddInterest(TffSrBaseCursor);
end;
{====================================================================}

{===TffCursorExtender================================================}
constructor TffCursorExtender.Create(aOwner: TffBaseEngineMonitor);
begin
  inherited Create(aOwner);
  FActions := [ffeaAfterRecDelete, ffeaAfterRecUpdate];
  FOldBuffer := nil;
  FOldBufferMatched := False;
end;
{--------}
destructor TffCursorExtender.Destroy;
begin
  if Assigned(FOldBuffer) then
    FFFreeMem(FOldBuffer, FOldBufferLen);
  inherited Destroy;
end;
{--------}
function TffCursorExtender.Notify(aServerObject : TffObject;
                                  aAction       : TffEngineAction) : TffResult;
var
  aCursor : TffSrBaseCursor absolute aServerObject;
  anInx : Integer;
begin
  Result := DBIERR_NONE;

  { Ignore if this is not the right kind of server object. }
  if (not (aServerObject is TffSrBaseCursor)) then
    Exit;

  case aAction of
    ffeaAfterRecDelete :
      { Assumption: Test routine has told the extender what record is to
        be deleted. }
      { Assumption: Buffers are of identical length. }
      { Does OldRecordBuffer match what we expect? }
      begin
        FOldBufferMatched := True;
        for anInx := 0 to pred(FOldBufferLen) do
          if aCursor.OldRecordBuffer^[anInx] <> FOldBuffer^[anInx] then begin
            FOldBufferMatched := False;
            break;
          end;
      end;
    ffeaAfterRecUpdate :
      { Assumption: Test routine has told the extender what the record looked
        like before it was modified. }
      { Assumption: Buffers are of identical length. }
      { Does OldRecordBuffer match what we expect? }
      begin
        FOldBufferMatched := True;
        for anInx := 0 to pred(FOldBufferLen) do
          if aCursor.OldRecordBuffer^[anInx] <> FOldBuffer^[anInx] then begin
            FOldBufferMatched := False;
            break;
          end;
      end;
  end;  { case }
end;
{--------}
procedure TffCursorExtender.SetOldBuffer(aBuffer : PffByteArray; aBufLen : Integer);
begin
  FOldBufferLen := aBufLen;
  FFGetMem(FOldBuffer, aBufLen);
  Move(aBuffer^, FOldBuffer^, aBufLen);
end;
{====================================================================}

{===TffCursorExtTest=================================================}
procedure TffCursorExtTest.Setup;
begin
  inherited Setup;
  FCursorMon := TffCursorMonitor.Create(nil);
  FCursorMon.ServerEngine := FEngine;
end;
{--------}
procedure TffCursorExtTest.Teardown;
begin
  inherited Teardown;
  FCursorMon.Free;
end;
{--------}
procedure TffCursorExtTest.testDeleteRecord;
{ Bugs: 473 }
var
  aSrvCursor : TffSrCursor;
begin
  { This test can only be run with embedded server engine. }
  if RemoteEngine then
    Exit;
  FTblExCust.Open;
  Check(FTblExCust.RecordCount > 0, 'No records in table');

  { Verify that the cursor extender attached itself to the cursor. }
  aSrvCursor := TffSrCursor(FTblExCust.CursorID);
  CheckEquals(2, aSrvCursor.Extenders.Count, 'Invalid extender count');
    { Note: Since we are using an embedded server engine, a security monitor
      will have already attached itself to the server engine therefore we check
      for 2 extenders. }

  { Get the extender. }
  FCursorExt := TffCursorExtender(TffIntListItem
                                  (aSrvCursor.Extenders[0]).KeyAsInt);

  { Tell the cursor extender which record it should see. }
  FCursorExt.SetOldBuffer(PffByteArray(FTblExCust.ActiveBuffer),
                          FTblExCust.Dictionary.RecordLength);

  { Delete the first record. }
  FTblExCust.Delete;

  { Did the cursor extender see the record? }
  Check(FCursorExt.OldBufferMatched, 'Buffer not matched');

  { Now test using a filter. }
  FTblExCust.Filter := 'State = ''MA''';
  FTblExCust.Filtered := True;
  FTblExCust.First;
  Check(FTblExCust.RecordCount > 0, 'No records in table for filter');

  { Tell the cursor extender which record it should see. }
  FCursorExt.SetOldBuffer(PffByteArray(FTblExCust.ActiveBuffer),
                          FTblExCust.Dictionary.RecordLength);

  { Delete the first record. }
  FTblExCust.Delete;

  { Did the cursor extender see the record? }
  Check(FCursorExt.OldBufferMatched, 'Buffer not matched on filter');
end;
{--------}
procedure TffCursorExtTest.testModifyRecord;
{ Bugs: 472 }
var
  aSrvCursor : TffSrCursor;
begin
  { This test can only be run with embedded server engine. }
  if RemoteEngine then
    Exit;
  FTblExCust.Open;
  Check(FTblExCust.RecordCount > 0, 'No records in table');

  { Verify that the cursor extender attached itself to the cursor. }
  aSrvCursor := TffSrCursor(FTblExCust.CursorID);
  CheckEquals(2, aSrvCursor.Extenders.Count, 'Invalid extender count');
    { Note: Since we are using an embedded server engine, a security monitor
      will have already attached itself to the server engine therefore we check
      for 2 extenders. }

  { Get the extender. }
  FCursorExt := TffCursorExtender(TffIntListItem
                                  (aSrvCursor.Extenders[0]).KeyAsInt);

  { Tell the cursor extender which record it should see. }
  FCursorExt.SetOldBuffer(PffByteArray(FTblExCust.ActiveBuffer),
                          FTblExCust.Dictionary.RecordLength);

  { Modify the first record. }
  FTblExCust.Edit;
  FTblExCust.FieldByName('FirstName').asString := 'Blarnsworth';
  FTblExCust.FieldByName('Zip').asString := 'q909q9';
  FTblExCust.Post;

  { Did the cursor extender see the record? }
  Check(FCursorExt.OldBufferMatched, 'Buffer not matched');
end;
{====================================================================}

initialization
  RegisterTest('Cursor Extender Tests', TffCursorExtTest.Suite);
end.
