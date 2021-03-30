unit BLOBThread;

interface

uses
  classes,
  baseThread,
  FFLLCore,
  FFLLExcp,
  FFDB;


type
  TffBLOBThread = class(TffBaseTestThread)
  protected
    fAlias     : string;                  { The alias to which the thread is to connect. }
    fClient    : TffClient;
    fDB        : TffDatabase;
    fSession   : TffSession;
    fTable     : TffTable;
    fOldStream : TMemoryStream;
    fNewStream : TMemoryStream;
    fCount     : integer;

    procedure AfterTest; override;
    procedure BeforeTest; override;
    procedure ExecuteStep(const StepNumber : integer); override;
    procedure ExecuteSynch; override;
    function  GetStepCount : integer; override;
  public
    constructor Create(const aThreadName : string;
                       const anAlias : string;
                       const aMode : TffTestThreadMode;
                             anEngine : TffBaseServerEngine);
  end;

const
  { Test steps.  Remember that steps are base 1. }
  BstInsertRecord   = 1;
  BstGetBLOBField   = 2;
  BstDeleteRecord   = 3;
  BstRetrieveRecord = 4;
  BstCompMStreams   = 5;
  BstCompUmStreams  = 6;
  BstUpdateBLOB     = 7;
  BstPost           = 8;
  BstCancel         = 9;
  BstTruncateBLOB   = 10;
  BstRead1HalfBLOB  = 11;
  BstRead2HalfBLOB  = 12;
  BstSleep          = 13;

  { Key values for saving/reading results. }
  brKeyErrCode    = 'ErrCode';
  brKeyInsertRec  = 'InsertRec';
  brKeyGetBLOB    = 'GetField';
  brKeyDeleteRec  = 'DeleteRec';
  brKeyGetRecord  = 'GetRecord';
  brPost          = 'RecordPosted';
  brCancel        = 'CancelRecEdit';
  brCompMStreams  = 'CompareMStreams';
  brCompUmStreams = 'CompareUmStreams';
  brUpdateBLOB    = 'UpdateBLOB';
  brTruncBLOB     = 'TruncateBLOB';
  brRead1HalfBLOB = 'Read1HalfBLOB';
  brRead2HalfBLOB = 'Read2HalfBLOB';
  brSleep         = 'Sleep';
  brOK            = 'OK';

implementation

uses
  SysUtils,
  Windows,
  db,
  ffllbase,
  ffdbBase;

{===TffDbThread======================================================}
constructor TffBLOBThread.Create(const aThreadName : string;
                                 const anAlias     : string;
                                 const aMode       : TffTestThreadMode;
                                       anEngine    : TffBaseServerEngine);
begin
  inherited Create(aThreadName, aMode, anEngine);
  FAlias := anAlias;
end;
{--------}
procedure TffBLOBThread.AfterTest;
begin
  if assigned(ftable) then begin
    fTable.Close;
    fTable.Free;
    fTable := nil;
  end;
  if assigned(fdb) then begin
    FDB.Free;
    fDB := nil;
  end;
  if assigned(fSession) then begin
    FSession.Free;
    FSession := nil;
  end;
  if assigned(fClient) then begin
    FClient.Free;
    fClient := nil;
  end;
  if assigned(fOldStream) then begin
    fOldStream.Free;
    fOldStream := nil;
  end;
  if assigned(fNewStream) then begin
    fNewStream.Free;
    fNewStream := nil;
  end;
end;
{--------}
procedure TffBLOBThread.BeforeTest;
const
  TimeOut = 1000;
var
  code : TffResult;
  msg  : string;
begin
  try
    FClient := TffClient.Create(nil);
    FClient.ServerEngine := FEngine;
    FClient.ClientName := 'FClient' + intToStr(GetCurrentThreadID);
    FClient.Active := True;
    FClient.TimeOut := TimeOut;
    SaveResult('ClientTO', inttoStr(TimeOut));

    FSession := TffSession.Create(nil);
    FSession.ClientName := FClient.ClientName;
    FSession.SessionName := 'FSession' + intToStr(GetCurrentThreadID);
    FSession.Active := True;
    if not FSession.IsAlias('ThePath') then
      FSession.AddAlias('ThePath', 'd:\ff2tests');
    FSession.TimeOut := Timeout;
    SaveResult('SessionTO', inttostr(TimeOut));

    FDB := TffDatabase.Create(nil);
    FDB.SessionName := FSession.SessionName;
    FDB.DatabaseName := 'FDB';
    FDB.AliasName := 'ThePath';
    fDB.TimeOut := Timeout;
    SaveResult('fDBTO', inttostr(TimeOut));
    fDB.Open;

    fTable := TffTable.Create(nil);
    fTable.SessionName := fSession.SessionName;
    fTable.DatabaseName := fDB.DatabaseName;
    fTable.TableName := 'testtable';
    fTable.Exclusive := false;
    fTable.ReadOnly := false;
    fTable.TimeOut := 20000;
    SaveResult('TableTO', inttostr(TimeOut));
    fTable.Open;

    fOldStream := TMemoryStream.Create;
    fNewStream := TMemoryStream.Create;
  except
    on E:EffDatabaseError do begin
      msg := E.ErrorString;
      msg := E.Message;
      code := E.errorCode;
    end;
  end;
end;
{--------}
procedure TffBLOBThread.ExecuteStep(const StepNumber : integer);
var
  Success    : boolean;
  i          : integer;
  OldChar,
  NewChar    : Char;
  BLOBField  : TBLOBField;
  BLOBStream : TffBLOBStream;
  Buffer     : pointer;
begin
  { Assumption: table is positioned to correct record}
  case StepNumber of
    BstInsertRecord :
    {insert a record w/a BLOB}
      try
        fTable.Insert;
        BLOBField := TBLOBField(fTable.FieldByName('BLOB1'));
        BLOBField.LoadFromFile(GetInput('filename'));
        SetInputInt('Size', TBLOBField(fTable.FieldByName('BLOB1')).BLOBSize);
        SaveResult(brKeyInsertRec, brOK);
      except
        on E:Exception do begin
          SaveException(E, brKeyInsertRec, brKeyErrCode);
        end;
      end;
    BstGetBLOBField :
    {get the BLOB field out of a record}
      try
        BLOBField := TBLOBField(fTable.FieldByName('blob1'));
        fOldStream := TMemoryStream.Create;
        fOldStream.LoadFromFile(GetInput('filename'));
        SetInputInt('Size', fOldStream.Size);
        fOldStream.Free;
        fOldStream := nil;
        SaveResult(brKeyGetBLOB, brOK);
      except
        on E:Exception do begin
          SaveException(E, brKeyGetBLOB, brKeyErrCode);
          fOldStream.Free;
          fOldStream := nil;
        end;
      end;
    BstDeleteRecord :
    {delete a record}
      try
        fTable.Delete;
        SaveResult(brKeyDeleteRec, brOK);
      except
        on E:Exception do
          SaveException(E, brKeyDeleteRec, brKeyErrCode);
      end;
    BstRetrieveRecord :
    {I guess this was a waste of keystrokes}
      try
        {????}
        SaveResult(brKeyGetRecord, brOK);
      except
        on E:Exception do
          SaveException(E, brKeyGetRecord, brKeyErrCode);
      end;
    BstCompMStreams :
    {compare streams that should match}
      try
        Success := True;
        if not assigned(foldStream) then
          fOldStream := TMemoryStream.Create;
        fOldStream.Position := 0;
        if not assigned(fnewStream) then
          fNewStream := TMemoryStream.Create;
        fNewStream.Position := 0;
        for i := 0 to pred(GetInputInt('Size')) do begin
          fOldStream.Read(OldChar, 1);
          fNewStream.Read(NewChar, 1);
          if oldChar <> Newchar then begin
            SaveResult(brCompMStreams, brKeyErrCode);
            Success := False;
            break;
          end;
        end;
        if Success then
          SaveResult(brCompMStreams, brOK);
      except
        on E:Exception do
          SaveException(E, brKeyGetRecord, brKeyErrCode);
      end;
    BstCompUmStreams :
    {compare streams that shouldn't match}
      try
        Success := False;
        fOldStream.Position := 0;
        fNewStream.Position := 0;
        for i := 0 to pred(GetInputInt('Size')) do begin
          fOldStream.Read(OldChar, 1);
          fNewStream.Read(NewChar, 1);
          if OldChar <> NewChar then begin
            SaveResult(brCompUmStreams, brKeyErrCode);
            Success := False;
            break;
          end;
        end;
        if Success then
          SaveResult(brCompUmStreams, brOK);
      except
        on E:Exception do
          SaveException(E, brCompUmStreams, brKeyErrCode);
      end;
    BstUpdateBLOB :
    {update a BLOB field}
      try
        fOldStream.LoadFromFile(GetInput('filename'));
        SetInputInt('NewSize', fOldStream.Size);
        fNewStream.SetSize(fOldStream.size);
        fTable.first;
        BLOBField := TBLOBField(fTable.FieldByName('blob1'));
        fTable.Edit;
        BLOBField.LoadFromFile(GetInput('filename'));
        BLOBField.SaveToStream(fNewStream);
        SaveResult(brUpdateBLOB, brOK);
      except
        on E:Exception do
          SaveException(E, brUpdateBLOB, brKeyErrCode);
      end;
    BstPost :
    {post a table update}
      try
        fTable.Post;
        SaveResult(brPost, brOK);
      except
        on E:Exception do
          SaveException(E, brPost, brKeyErrCode);
      end;
    BstCancel :
    {rollback a table update}
      try
        fTable.Cancel;
        SaveResult(brCancel, brOK);
      except
        on E:Exception do
          SaveException(E, brCancel, brKeyErrCode);
      end;
    BstTruncateBLOB :
    {truncate a BLOB}
      try
        BLOBStream := nil;
        fTable.first;
        fTable.Edit;
        BLOBField := TBLOBField(fTable.FieldByName('blob1'));
        BLOBStream := TffBLOBStream(fTable.CreateBLOBStream(BLOBField, bmReadWrite));
        BLOBStream.Seek(GetInputInt('newsize') - 2, soFromBeginning);
        BLOBStream.Truncate;
        fOldStream.LoadFromFile(GetInput('filename'));
        BLOBStream.CopyFrom(fOldStream, GetInputInt('NewSize'));
        BLOBStream.free;
        BLOBStream := nil;
        SaveResult(brTruncBLOB, brOK);
      except
        on E:Exception do begin
          SaveException(E, brTruncBLOB, brKeyErrCode);
          if Assigned(BLOBStream) then begin
            BLOBStream.free;
            BLOBStream := nil;
          end;
        end;
      end;
    BstRead1HalfBLOB :
    {open an explicit transaction and read 1st half of BLOB}
      try
        fDB.StartTransaction;
        fTable.first;
        fTable.Edit;
        BLOBField := TBLOBField(fTable.FieldByName('BLOB1'));
        BLOBStream := TffBLOBStream.Create(BLOBField, bmRead);
        fNewStream.SetSize(BLOBField.BlobSize);
        fCount := BLOBStream.Read(fNewStream.Memory^, ((BLOBField.BlobSize + 1) div 2));
        BLOBStream.Free;
        BLOBStream := nil;
        SaveResult(brRead1HalfBLOB, brOK);
      except
        on E:Exception do begin
          SaveException(E, brRead1HalfBLOB, brKeyErrCode);
          BLOBStream.free;
          BLOBStream := nil;
        end;
      end;
    BstRead2HalfBLOB :
    {read 2nd half of BLOB and then end the transaction}
      try
        fOldStream.LoadFromFile(GetInput('filename'));
        BLOBField := tBLOBField(fTable.FieldByName('blob1'));
        BLOBStream := TffBLOBStream.Create(BLOBField, bmRead);
        fCount := fCount + BLOBStream.Read(fNewStream.Memory^, (BLOBField.Size - fCount));
        fDB.Commit;
        BLOBStream.Free;
        BLOBStream := nil;
        SaveResult(brRead2HalfBLOB, brOK);
      except
        on E:Exception do begin
          SaveException(E, brRead2HalfBLOB, brKeyErrCode);
          BLOBStream.free;
          BLOBStream := nil;
        end;
      end;
    BstSleep :
      try
        Sleep(10);
        SaveResult(brSleep, brOK);
      except
        on E:Exception do
          SaveException(E, brSleep, brKeyErrCode);
      end;
  end;  { case }
end;
{--------}
procedure TffBLOBThread.ExecuteSynch;
begin
  { Do nothing }
end;
{--------}
function TffBLOBThread.GetStepCount : integer;
begin
  { Do nothing }
end;
{====================================================================}

end.
