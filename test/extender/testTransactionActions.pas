unit testTransactionActions;

interface
uses
  basetestcase,
  ffllbase,
  fflleng,
  ffsrbase,
  uCLTBase,
  ffdb,
  sysutils,
  TestFramework;

type
  TffDBExtender = class(TffBaseEngineExtender)
  protected
  public
    constructor Create(aOwner: TffBaseEngineMonitor); override;
    function Notify(aServerObject : TffObject;
                    aAction       : TffEngineAction) : TffResult; override;
  end;

  TffDBMonitor = class(TffBaseEngineMonitor)
  protected
    procedure bemSetServerEngine(anEngine: TffBaseServerEngine); override;
  public
    function Interested(aServerObject: TffObject): TffBaseEngineExtender; override;
  end;

  TffDBExtTest = class(TffBaseClientTest)
  protected
    FDBMon : TffDBMonitor;
    FDBExt : TffDBExtender;
    procedure Setup; override;
    procedure TearDown; override;
  public
    property DBExt : TffDBExtender read FDBExt;
  published
    procedure testNormalTransaction;
    procedure testAbortTransaction;
  end;

var
  MakeCommitFail : Boolean;

implementation
uses
  ffsrbde,
  ffsreng;

{ TffDBExtender }

constructor TffDBExtender.Create(aOwner: TffBaseEngineMonitor);
begin
  inherited Create(aOwner);

  FActions := [ffeaBeforeCommit, ffeaCommitFail];
end;

function TffDBExtender.Notify(aServerObject: TffObject;
  aAction: TffEngineAction): TffResult;
var
  aDB : TffSrDatabase absolute aServerObject;
begin
  Result := DBIERR_NONE;

  if (not(aServerObject is TffSrDatabase)) then
    Exit;

  case aAction of
    ffeaBeforeCommit : if MakeCommitFail then
                         Result := DBIERR_NOTSUFFTABLERIGHTS
                       else
                         Result := DBIERR_NONE;
    ffeaCommitFail : Assert(MakeCommitFail, 'Commit should not have failed');
  end;
end;

{ TffDBMonitor }

procedure TffDBMonitor.bemSetServerEngine(anEngine: TffBaseServerEngine);
begin
  inherited bemSetServerEngine(anEngine);
  AddInterest(TffSrDatabase);
end;

function TffDBMonitor.Interested(
  aServerObject: TffObject): TffBaseEngineExtender;
begin
  if (aServerObject is TffSrDatabase) then
    Result := TffDBExtender.Create(self)
  else
    Result := nil;
end;

{ TffDBExtTest }

procedure TffDBExtTest.Setup;
begin
  inherited Setup;

  FDBMon := TffDBMonitor.Create(nil);
  FDBMon.ServerEngine := FEngine;
end;

procedure TffDBExtTest.TearDown;
begin
  FDBMon.Free;

  inherited Teardown;
end;


type
  TffSrDatabaseEx = class(TffSrDatabase);

procedure TffDBExtTest.testAbortTransaction;
var
  aSrvDB : TffSrDatabaseEx;
  Cl : TffClient;
  SS : TffSession;
  DB : TffDatabase;
begin
  { This test can only be run with embedded server engine. }
  if RemoteEngine then
    Exit;

  MakeCommitFail := True;

  CL := TffClient.Create(nil);
  CL.AutoClientName := True;
  CL.ServerEngine := FEngine;

  SS := TffSession.Create(nil);
  SS.AutoSessionName := True;
  SS.ClientName := CL.ClientName;
  SS.Open;

  DB := TffDatabase.Create(nil);
  DB.SessionName := SS.SessionName;
  DB.AutoDatabaseName := True;
  DB.AliasName := clAliasName;
  DB.Open;
  try
    aSrvDB := TffSrDatabaseEx(DB.DatabaseID);

    aSrvDB.dbExtenders.BeginRead;
    try
      CheckEquals(2, aSrvDB.dbExtenders.Count, 'Invalid extender count');
        { Note: Since we are using an embedded server engine, a security monitor
          will have already attached itself to the server engine therefore we check
          for 2 extenders. }
    finally
      aSrvDB.dbExtenders.EndRead;
    end;

    DB.StartTransaction;
    try
      DB.Commit;
      raise Exception.Create('Invalid commit result');
    except
    end;

  finally
    DB.Free;
    SS.Free;
    CL.Free;
  end;
end;

procedure TffDBExtTest.testNormalTransaction;
var
  aSrvDB : TffSrDatabaseEx;
  Cl : TffClient;
  SS : TffSession;
  DB : TffDatabase;
begin
  { This test can only be run with embedded server engine. }
  if RemoteEngine then
    Exit;

  MakeCommitFail := False;

  CL := TffClient.Create(nil);
  CL.AutoClientName := True;
  CL.ServerEngine := FEngine;

  SS := TffSession.Create(nil);
  SS.AutoSessionName := True;
  SS.ClientName := CL.ClientName;
  SS.Open;

  DB := TffDatabase.Create(nil);
  DB.SessionName := SS.SessionName;
  DB.AutoDatabaseName := True;
  DB.AliasName := clAliasName;
  DB.Open;
  try
    aSrvDB := TffSrDatabaseEx(DB.DatabaseID);

    aSrvDB.dbExtenders.BeginRead;
    try
      CheckEquals(2, aSrvDB.dbExtenders.Count, 'Invalid extender count');
        { Note: Since we are using an embedded server engine, a security monitor
          will have already attached itself to the server engine therefore we check
          for 2 extenders. }
    finally
      aSrvDB.dbExtenders.EndRead;
    end;

    DB.StartTransaction;
    DB.Commit;
  finally
    DB.Free;
    SS.Free;
    CL.Free;
  end;
end;

initialization
  RegisterTest('Transaction Actions Tests', TffDBExtTest.Suite);

end.
