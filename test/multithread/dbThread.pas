{*********************************************************}
{* FlashFiler: DBTHREAD.PAS                              *}
{* Copyright (c) TurboPower Software Co 1996-2000        *}
{* All rights reserved.                                  *}
{*********************************************************}
{* FlashFiler: Database threads (testing)                *}
{*********************************************************}
unit dbThread;

interface

uses
  baseThread,
  FFLLEng,
  FFLLExcp,
  FFDB;

const
  clClientTimeout = 5000;
  clSessionTimeout = 5000;
  clDBTimeout = 5000;
  clTableTimeout = 5000;

type
  TffDBThread = class(TffBaseTestThread)
  protected
    FAlias : string;
      { The alias to which the thread is to connect. }
    FClient : TffClient;                                 
    FDB : TffDatabase;
    FSession : TffSession;
    FTable : TffTable;
    FTable2 : TffTable;
    FTableOpenCount : longInt;
      { If TrackTableOpens is True then this is the number of times
        the table was opened successfully. }
    FTrackTableOpens : boolean;
      { If True then tracks # of times a table is successfully opened. }

    procedure AfterTest; override;
    procedure BeforeTest; override;
    procedure ExecuteStep(const StepNumber : integer); override;
    procedure ExecuteSynch; override;
    function GetStepCount : integer; override;
    procedure InsertRandomContacts;
  public
    constructor Create(const aThreadName : string;
                       const anAlias : string;
                       const aMode : TffTestThreadMode;
                             anEngine : TffBaseServerEngine);

    property TableOpenCount : longInt read FTableOpenCount;

    property TrackTableOpens : boolean read FTrackTableOpens
                                       write FTrackTableOpens;

  end;

const
  { Test steps.  Remember that steps are base 1. }
  ciDBOpenExcl = 1;
  ciDBClose = 2;
  ciDBOpenNonExcl = 3;
  ciDBOpenNonExclRO = 4;
  ciTblOpenNonExclRW = 5;
  ciTblOpenNonExclRO = 6;
  ciTblClose = 7;
  ciTblDelete = 8;
  ciTblOpenExclRW = 9;
  ciTblRename = 10;
  ciRandomSleep = 11;
  ciSleep = 12;
  ciTblDropIndex = 13;
  ciTblOpenExclRW2 = 14;
  ciInsertRandomContacts = 15;

  { Key values for saving/reading results. }
  csKeyClientTimeout = 'ClientTimeout';
  csKeyCloseDB = 'CloseDB';
  csKeyCloseTbl = 'CloseTbl';
  csKeyDBTimeout = 'DBTimeout';
  csKeyDelTbl = 'DeleteTbl';
  csKeyDropIndex = 'TableDropIndex';
  csKeyErrCode = 'ErrCode';
  csKeyOpenDB = 'OpenDB';
  csKeyOpenTbl = 'OpenTbl';
  csKeyIndexName = 'IndexName';
  csKeyInsertRandomContacts = 'InsertRandomContacts';
  csKeyNumRecords = 'NumberOfRecords';
  csKeyNumRecordsPerTran = 'NumberOfRecordsPerTransaction';

  {---Performance keys---}
  csKeyPerf1stIteration = 'Perf1stIt';
  csKeyPerfLastIteration = 'PerfLastIt';
  csKeyPerfAvgTime = 'PerfAvgTime';
  csKeyPerfTotalTime = 'PerfTotalTime';

  csKeyRecordsInserted = 'NumberRecordsInserted';
  csKeyRenTbl = 'RenameTbl';
  csKeySessionTimeout = 'SessionTimeout';
  csKeySleep = 'SleepStatus';
  csKeySleepMs = 'SleepMs';
  csKeyTableIsReadOnly = 'TableIsReadOnly';
  csKeyTableName = 'TableName';
  csKeyTableNameNew = 'TableNameNew';
  csKeyTableTimeout = 'TableTimeout';
  csKeyTable2Timeout = 'Table2Timeout';
  csKeyTime = 'Time';
  csOK = 'OK';

implementation

uses
  SysUtils,
  db,
  Windows,
  contactu,
  ffclreng,
  ffllbase,
  ffdbBase;

{===TffDbThread======================================================}
constructor TffDBThread.Create(const aThreadName : string;
                               const anAlias : string;
                               const aMode : TffTestThreadMode;
                                     anEngine : TffBaseServerEngine);
begin
  inherited Create(aThreadName, aMode, anEngine);
  FAlias := anAlias;
  FTableOpenCount := 0;
end;
{--------}
procedure TffDBThread.AfterTest;
begin
  FTable2.Free;
  FTable.Free;
  FDB.Free;
  FSession.Free;
  FClient.Free;
end;
{--------}
procedure TffDBThread.BeforeTest;
var
  tmpTimeout : longInt;
begin

  FClient := TffClient.Create(nil);
  FClient.ServerEngine := FEngine;
  FClient.ClientName := 'FClient' + intToStr(GetCurrentThreadID);
  tmpTimeout := GetInputInt(csKeyClientTimeout);
  if tmpTimeout > -1 then
    FClient.Timeout := tmpTimeout
  else
    FClient.Timeout := clClientTimeout;
  FClient.Active := True;
  SaveResultInt(csKeyClientTimeout, FClient.Timeout);

  FSession := TffSession.Create(nil);
  FSession.ClientName := FClient.ClientName;
  FSession.SessionName := 'FSession' + intToStr(GetCurrentThreadID);
  tmpTimeout := GetInputInt(csKeySessionTimeout);
  if tmpTimeout > -1 then
    FSession.Timeout := tmpTimeout
  else
    FSession.Timeout := clSessionTimeout;
  FSession.Active := True;
  SaveResultInt(csKeySessionTimeout, FSession.Timeout);

  { Assumption: FAlias is always a path. }
  FDB := TffDatabase.Create(nil);
  FDB.SessionName := FSession.SessionName;
  FDB.DatabaseName := 'FDB';
  tmpTimeout := GetInputInt(csKeyDBTimeout);
  if tmpTimeout > -1 then
    FDB.Timeout := tmpTimeout
  else
    FDB.Timeout := clDBTimeout;
  FDB.AliasName := FAlias;
  SaveResultInt(csKeyDBTimeout, FDB.Timeout);

  FTable := TffTable.Create(nil);
  FTable.DatabaseName := FDB.DatabaseName;
  FTable.SessionName := FDB.SessionName;
  tmpTimeout := GetInputInt(csKeyTableTimeout);
  if tmpTimeout > -1 then
    FTable.Timeout := tmpTimeout
  else
    FTable.Timeout := clTableTimeout;
  SaveResultInt(csKeyTableTimeout, FTable.Timeout);

  FTable2 := TffTable.Create(nil);
  FTable2.DatabaseName := FDB.DatabaseName;
  FTable2.SessionName := FDB.SessionName;
  tmpTimeout := GetInputInt(csKeyTable2Timeout);
  if tmpTimeout > -1 then
    FTable2.Timeout := tmpTimeout
  else
    FTable2.Timeout := clTableTimeout;
  SaveResultInt(csKeyTable2Timeout, FTable2.Timeout);

end;
{--------}
procedure TffDBThread.ExecuteStep(const StepNumber : integer);
var
  StartTime : DWORD;
begin
  case StepNumber of
    ciDBOpenExcl :
      try
        FDB.Exclusive := True;
        FDB.Connected := True;
        SaveResult(csKeyOpenDB, csOK);
      except
        on E:Exception do
          SaveException(E, csKeyOpenDB, csKeyErrCode);
      end;
    ciDBClose :
      try
        FDB.Connected := False;
        SaveResult(csKeyCloseDB, csOK);
      except
        on E:Exception do
          SaveException(E, csKeyCloseDB, csKeyErrCode);
      end;
    ciDBOpenNonExcl :
      try
        FDB.Exclusive := False;
        FDB.Connected := True;
        SaveResult(csKeyOpenDB, csOK);
      except
        on E:Exception do
          SaveException(E, csKeyOpenDB, csKeyErrCode);
      end;
    ciDBOpenNonExclRO :
      try
        FDB.Exclusive := False;
        FDB.ReadOnly := True;
        FDB.Connected := True;
        SaveResult(csKeyOpenDB, csOK);
      except
        on E:Exception do
          SaveException(E, csKeyOpenDB, csKeyErrCode);
      end;
    ciTblOpenNonExclRW:
      try
        FTable.TableName := FInputParms.Values[csKeyTableName];
        FTable.IndexName := FInputParms.Values[csKeyIndexName];
        FTable.Exclusive := False;
        FTable.ReadOnly := False;
        FTable.Open;
        SaveResult(csKeyOpenTbl, csOK);
        SaveResultBool(csKeyTableIsReadOnly, FTable.ReadOnly);
        if FTrackTableOpens then
          inc(FTableOpenCount);
      except
        on E:Exception do
          SaveException(E, csKeyOpenTbl, csKeyErrCode);
      end;
    ciTblOpenNonExclRO:
      try
        FTable.TableName := FInputParms.Values[csKeyTableName];
        FTable.IndexName := FInputParms.Values[csKeyIndexName];
        FTable.Exclusive := False;
        FTable.ReadOnly := True;
        FTable.Open;
        SaveResult(csKeyOpenTbl, csOK);
        SaveResultBool(csKeyTableIsReadOnly, FTable.ReadOnly);
        if FTrackTableOpens then
          inc(FTableOpenCount);
      except
        on E:Exception do
          SaveException(E, csKeyOpenTbl, csKeyErrCode);
      end;
    ciTblClose :
      try
        FTable.Close;
        SaveResult(csKeyCloseTbl, csOK);
      except
        on E:Exception do
          SaveException(E, csKeyCloseTbl, csKeyErrCode);
      end;
    ciTblDelete:
      try
        FTable.TableName := FInputParms.Values[csKeyTableName];
        FTable.DeleteTable;
        SaveResult(csKeyDelTbl, csOK);
      except
        on E:Exception do
          SaveException(E, csKeyDelTbl, csKeyErrCode);
      end;
    ciTblOpenExclRW:
      try
        FTable.TableName := FInputParms.Values[csKeyTableName];
        FTable.IndexName := FInputParms.Values[csKeyIndexName];
        FTable.Exclusive := True;
        FTable.ReadOnly := False;
        FTable.Open;
        SaveResult(csKeyOpenTbl, csOK);
        SaveResultBool(csKeyTableIsReadOnly, FTable.ReadOnly);
        if FTrackTableOpens then
          inc(FTableOpenCount);
      except
        on E:Exception do
          SaveException(E, csKeyOpenTbl, csKeyErrCode);
      end;
    ciTblRename :
      try
        FTable.TableName := FInputParms.Values[csKeyTableName];
        FTable.RenameTable(FInputParms.Values[csKeyTableNameNew]);
        SaveResult(csKeyRenTbl, csOK);
      except
        on E:Exception do
          SaveException(E, csKeyRenTbl, csKeyErrCode);
      end;
    ciRandomSleep :
      try
        Sleep(Random(GetInputInt(csKeySleepMs)));
      except
        on E:Exception do
          SaveException(E, csKeySleep, csKeyErrCode);
      end;
    ciSleep :
      try
        Sleep(10);
      except
        on E:Exception do
          SaveException(E, csKeySleep, csKeyErrCode);
      end;
    ciTblDropIndex :
      begin
        StartTime := GetTickCount;
        try
          FTable.TableName := FInputParms.Values[csKeyTableName];
          FTable.DeleteIndex(FInputParms.Values[csKeyIndexName]);
          SaveResult(csKeyDropIndex, csOK);
        except
          on E:Exception do begin
            { Store the amount of time it took. }
            SaveResultInt(csKeyTime, GetTickCount - StartTime);
            SaveException(E, csKeyRenTbl, csKeyErrCode);
          end;
        end;
      end;
      ciTblOpenExclRW2:
      try
        FTable2.TableName := FInputParms.Values[csKeyTableName];
        FTable2.IndexName := FInputParms.Values[csKeyIndexName];
        FTable2.Exclusive := True;
        FTable2.ReadOnly := False;
        FTable2.Open;
        SaveResult(csKeyOpenTbl, csOK);
        SaveResultBool(csKeyTableIsReadOnly, FTable2.ReadOnly);
        if FTrackTableOpens then
          inc(FTableOpenCount);
      except
        on E:Exception do
          SaveException(E, csKeyOpenTbl, csKeyErrCode);
      end;
    ciInsertRandomContacts :
      try
        InsertRandomContacts;
      except
        on E:Exception do
          SaveException(E, csKeyInsertRandomContacts, csKeyErrCode);
      end;
  end;  { case }
end;
{--------}
procedure TffDBThread.ExecuteSynch;
begin
  { Do nothing }
end;
{--------}
function TffDBThread.GetStepCount : integer;
begin
  Result := 0;
end;
{--------}
procedure TffDBThread.InsertRandomContacts;
var
  Index : longInt;
  RecCount : longInt;
  RecsPerTran : longInt;
  RecsInserted : dword;
  fldFirstName : TField;
  fldLastName : TField;
  fldAge : TField;
  fldState : TField;
  fldDecisionMaker : TField;

  Perf1stIt : DWord;  { calculated time for 1st iteration }
  PerfLastIt : DWord;  { calculated time for last iteration }

  ItTime : DWord;  { # ms for an iteration }
  TimeSum : DWord;  { total # ms for all iterations, used to calc average }
  StartIt : DWord;  { start time for an iteration }
  StartTime : DWord;  { start time for the entire operation }
begin
  Perf1stIt := 0;
  PerfLastIt := 0;
  { Assumption: Using FFTable. }

  { Get inputs. }
  RecCount := GetInputInt(csKeyNumRecords);
  RecsPerTran := GetInputInt(csKeyNumRecordsPerTran);

  { Init vars. }
  RecsInserted := 0;
  TimeSum := 0;

  with FTable do begin
    fldFirstName := FieldByName('FirstName');
    fldLastName := FieldByName('LastName');
    fldAge := FieldByName('age');
    fldState := FieldByName('State');
    fldDecisionMaker := FieldByName('DecisionMaker');
  end;

  StartTime := GetTickCount;

  { Start a transaction. }
  FDB.StartTransaction;

  try

    { Start inserting records. }
    for Index := 1 to RecCount do begin
      StartIt := GetTickCount;
      with FTable do begin
        Insert;
        fldFirstName.asString := genFirstName;
        fldLastName.asString := genLastName;
        fldAge.asInteger := genAge;
        fldState.asString := genState;
        fldDecisionMaker.asBoolean := genDecisionMaker;
        Post;
        itTime := GetTickCount - StartIt;
        if Index = 1 then
          Perf1stIt := itTime
        else if Index = RecCount then
          PerfLastIt := itTime;
        inc(TimeSum, itTime);
        inc(RecsInserted);
      end;
      if Index mod RecsPerTran = 0 then begin
        FDB.Commit;
        FDB.StartTransaction;
      end;
    end;

    if FDB.InTransaction then
      FDB.Commit;
  except
    on E:Exception do begin
      { Commit what we have inserted so far. }
      FDB.Commit;
      SaveResultInt(csKeyRecordsInserted, RecsInserted);
      raise;
    end;
  end;

  SaveResultInt(csKeyPerf1stIteration, Perf1stIt);
  SaveResultInt(csKeyPerfLastIteration, PerfLastIt);
  SaveResultInt(csKeyPerfAvgTime, TimeSum div RecsInserted);
  SaveResultInt(csKeyPerfTotalTime, GetTickCount - StartTime);
  SaveResultInt(csKeyRecordsInserted, RecsInserted);

end;
{====================================================================}

end.
