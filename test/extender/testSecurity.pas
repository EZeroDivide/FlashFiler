unit TestSecurity;

interface

uses
  FFSrSec,
  FFLLComp,
  FFLLEng,
  FFSrEng,
  FFSrFold,
  FFSrBase,
  FFSrCfg,
  FFLLBase,
  TestFramework;

type
  TFFSecManTest = class(TTestCase)
  private
    FClientID : TfFClientID;
    fPWHash   : TffWord32;
    fUserItem : TffUserItem;
    FCursor : TFFSrCursor;
    FDatabaseID     : TFFDatabaseID;
    fDB       : TffSrDatabase;
    FSessionID : TfFSessionID;
    FEngine : TffServerEngine;
    fSrvCfg : TffServerConfiguration;
    FSecExt : TFfSecurityExtender;
    FSecMon : TffSecurityMonitor;
  protected
    procedure Prepare(aSecure : boolean; aUserRights : TffUserRights);
    procedure Terminate;
  published
    procedure testNonSecServer;
    procedure testInsufficientCursorRights;
    procedure testInsufficeintDBRights;
    procedure testGoodCursorRights;
    procedure testGoodDBRights;
    procedure testGoodInterest;
    procedure testBadInterest;
  end;

implementation

uses
  Forms,
  FFSrBDE,
  SysUtils;

procedure TFFSecManTest.Prepare(aSecure : boolean; aUserRights : TffUserRights);
const
  csTableName = 'SecMgrTest';
var
  User     : TffUserItem;
  DataDir  : string;
begin

  DataDir := '..\data';

  {setup a server engine}
  if assigned(FEngine) then
    FEngine.Free;
  try
    FEngine := TffServerEngine.Create(nil);
    FEngine.State := ffesStarted;
    FEngine.Configuration.GeneralInfo.giIsSecure := aSecure;
  except
    on E : Exception do
      ShowException(E, @E);
  end;

  {setup a security monitor}
  if assigned(FSecMon) then
    FSecMon.free;
  try
    FSecMon := TffSecurityMonitor.Create(nil);
    FSecMon.ServerEngine := FEngine;
  except
    on E : Exception do
      ShowException(E, @E);
  end;

  {setup a security extender}
  if assigned(FSecExt) then
    FSecExt.free;
  try
    FSecExt := TffSecurityExtender.Create(FSecMon);
  except
    on E : Exception do
      ShowException(E, @E);
  end;

  {setup a client}
  fPWHash := 5;
  FClientID := 1;
  User := TffUserItem.Create('Me', 'Carter', 'Scott', fPWHash, aUserRights);
  FEngine.Configuration.AddUser(User.UserID, User.LastName, User.FirstName, fPWHash, aUserRights);
  FEngine.ClientAdd(FClientID, 'MyClient', 'Me', 10, fPWHash);

  {setup a session}
  FEngine.SessionAdd(FClientID, 10, FSessionID);

  { Open a database. }
  FEngine.DatabaseOpenNoAlias(FClientID, DataDir, omReadWrite, smShared, 0,
                              FDatabaseID);
  FDB := TffSrDatabase(FDatabaseID);

  { Open a cursor. }
  if assigned(FCursor) then
   FCursor.free;
  try
    FFSetRetry(0);
    FCursor := TffSrCursor.Create(FEngine, FDB, 0);
    FCursor.Open(csTableName, '', 0, omReadWrite, smShared, false, false, []);
  except
    on E : Exception do
      ShowException(E, @E);
  end;
end;

procedure TFFSecManTest.Terminate;
begin
  FEngine.CursorClose(FCursor.CursorID);
  FEngine.DatabaseClose(FDatabaseID);
  FEngine.SessionRemove(FClientID, FSessionID);
  FEngine.ClientRemove(FClientID);
  FreeAndNil(FEngine);
  FreeAndNil(fSrvCfg);
  FreeAndNil(fUserItem);
  FreeAndNil(FSecExt);
  FreeAndNil(FSecMon);
  FCursor := nil;
end;

procedure TFFSecManTest.testGoodInterest;
var
  anExt : TffBaseEngineExtender;
begin
  Prepare(true, [arRead]);
  try
    anExt := FSecMon.Interested(FCursor);
    try
      assert(assigned(anExt), 'Got a Null response');
    finally
      anExt.Free;
    end;
  finally
    Terminate;
  end;
end;

procedure TFFSecManTest.testBadInterest;
var
  MyEvent : TffEvent;
begin
  Prepare(true, [arRead]);
  try
    MyEvent := TffEvent.Create;
    Assert(not assigned(FSecMon.Interested(MyEvent)), 'Should have got a null since we not interested');
    MyEvent.Free;
  finally
    Terminate;
  end;  
end;

procedure TFFSecManTest.testNonSecServer;
begin
  Prepare(false, [arRead]);
  try
    {ensure the extender gives us nil back since we're not interested
     in non-secure servers}
    CheckEquals(0,
                 FSecExt.Notify(FCursor, ffeaBeforeTabPack),
                 'The security extender is concerned about a non-secure server');
  finally
    Terminate;
  end;
end;

procedure TFFSecManTest.testInsufficientCursorRights;
begin
  Prepare(true, [arRead]);
  try
    {ensure that we catch a cursor that we catch a cursor with
     insufficient rights for an action on a secure server}
    CheckEquals(DBIERR_NOTSUFFTABLERIGHTS,
                 FSecExt.Notify(FCursor, ffeaBeforeTabPack),
                 'Unexpected return from cursor w/insuff rights');
  finally
    Terminate;
  end;
end;

procedure TFFSecManTest.testInsufficeintDBRights;
begin
  Prepare(true, [arRead]);
  try
    {ensure that we catch a cursor that we catch a database with
     insufficient rights for an action on a secure server}
    CheckEquals(DBIERR_NOTSUFFTABLERIGHTS,
                 FSecExt.Notify(fDB, ffeaBeforeDBDelete),
                 'Unexpected return from cursor w/insuff rights');
  finally
    Terminate;
  end;
end;

procedure TFFSecManTest.testGoodCursorRights;
begin
  Prepare(true, [arRead, arUpdate]);
  try
    {ensure that we allow a cursor with adequate rights to complete its
     action on a secure server}
    CheckEquals(DBIERR_NONE,
                 FSecExt.Notify(FCursor, ffeaBeforeTabUpdate),
                 'Unexpected return from cursor w/good rights');


  finally
    Terminate;
  end;
end;

procedure TFFSecManTest.testGoodDBRights;
begin
  Prepare(true, [arRead, arUpdate]);
  try
    {ensure that we allow a database with adequate rights to complete
     its action on a secure server}
    CheckEquals(DBIERR_NONE,
                 FSecExt.Notify(fDB, ffeaBeforeDBUpdate),
                 'Unexpected return from database w/good rights');
  finally
    Terminate;
  end;
end;

initialization
  RegisterTest('Security Manager Tests', TFFSecManTest.Suite);
end.

