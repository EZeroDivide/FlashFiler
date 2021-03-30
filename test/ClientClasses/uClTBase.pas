unit uClTBase;

interface
uses
  BaseTestCase,
  FFLLBase,
  FFDB;

const
  clClientName : string = 'TestClientClasses_Client';
  clCommsEngineName : string = 'TestClientClasses_CommsEngine';
  clSessionName : string = 'TestClientClasses_Session';
  clDatabaseName = 'TutorialDB';
  clDatabasePath = '..\data';
  clAliasName = 'Tutorial';
  clClientTimeout = 5000;

type
  TffBaseClientTest = class(TffBaseTest)
    protected
      FCommsEngine : TffCommsEngine;
      FClient   : TffClient;
      FSession  : TffSession;
      FDatabase : TffDatabase;


      FtblExBlob   : TffTable;
      FtblExCust   : TffTable;
      FtblExLines  : TffTable;
      FtblExOrders : TffTable;
      FtblExProds  : TffTable;

      procedure Setup; override;
      procedure Teardown; override;

      procedure CloneTable(SrcName, DestName : string);
      procedure CreateExBlobTable;
      procedure CreateExCustTable;
      procedure CreateExLinesTable;
      procedure CreateExOrdersTable;
      procedure CreateExProdsTable;
    public
      property Client : TffClient
         read FClient;
      property CommsEngine : TffCommsEngine
         read FCommsEngine;
      property Session : TffSession
         read FSession;
      property Database : TffDatabase
         read FDatabase;

      property tblExBlob : TffTable
         read FtblExBlob;
      property tblExCust : TffTable
         read FtblExCust;
      property tblExLines : TffTable
         read FtblExLines;
      property tblExOrders : TffTable
         read FtblExOrders;
      property tblExProds : TffTable
         read FtblExProds;
  end;

implementation
uses
  Forms, SysUtils, Windows, uTestCfg;

{===TffBaseClientTest================================================}
procedure TffBaseClientTest.Setup;
var
  InfoStr : string;
begin
  RemoteEngine := frmClientTestConfig.RemoteEngine;
  Protocol := frmClientTestConfig.Protocol;
  ServerName := frmClientTestConfig.ServerName;
  SystemDir := frmClientTestConfig.SystemDir;

  inherited Setup;

  FClient := TffClient.Create(nil);
  try
    FClient.AutoClientName := True;
    clClientName := FClient.ClientName;
    FClient.ServerEngine := FEngine;
    FClient.Timeout := clClientTimeout;
    FClient.Active := True;
  except
    on E:Exception do begin
      InfoStr := 'Client create failure; ' + E.message;
      raise Exception.Create(InfoStr);
    end;
  end;

  FCommsEngine := TffCommsEngine.Create(nil);
  try
    FCommsEngine.AutoClientName := True;
    clCommsEngineName := FCommsEngine.ClientName;
    FCommsEngine.ServerEngine := FEngine;
    FCommsEngine.Timeout := clClientTimeout;
    FCommsEngine.Active := True;
  except
    on E:Exception do begin
      InfoStr := 'CommsEngine create failure; ' + E.message;
      raise Exception.Create(InfoStr);
    end;
  end;

  FSession := TffSession.Create(nil);
  try
    FSession.AutoSessionName := True;
    clSessionName := FSession.SessionName;
    FSession.ClientName := FClient.ClientName;
    FSession.Active := True;
    { If using a remote engine then see if it has the required alias. }
    if FRemoteEngine then begin
      if not FSession.IsAlias(clAliasName) then
        raise Exception.Create('Required alias ' + clAliasName +
                               ' does not exist on remote server engine.');
    end
    else begin
      { Otherwise this is an embedded server so create the alias. }
      FSession.DeleteAliasEx(clAliasName);
      FSession.AddAliasEx(clAliasName, ExtractFilePath(Application.ExeName)
                                       + clDatabasePath);
    end;
  except
    on E:Exception do begin
      InfoStr := 'Session create failure; ' + E.message;
      raise Exception.Create(InfoStr);
    end;
  end;

  FDatabase := TffDatabase.Create(nil);
  try
    FDatabase.SessionName := FSession.SessionName;
    FDatabase.DatabaseName := clDatabaseName;
    FDatabase.AliasName := clAliasName;
    FDatabase.Connected := True;
  except
    on E:Exception do begin
      InfoStr := 'Database create failure; ' + E.message;
      raise Exception.Create(InfoStr);
    end;
  end;

  CreateExBlobTable;
  CreateExCustTable;
  CreateExLinesTable;
  CreateExOrdersTable;
  CreateExProdsTable;

  FtblExBlob := TffTable.Create(nil);
  FtblExBlob.SessionName := FSession.SessionName;
  FtblExBlob.DatabaseName := clDatabaseName;
  FtblExBlob.TableName := 'ExBlob';

  FtblExCust := TffTable.Create(nil);
  FtblExCust.SessionName := FSession.SessionName;
  FtblExCust.DatabaseName := clDatabaseName;
  FtblExCust.TableName := 'ExCust';

  FtblExLines := TffTable.Create(nil);
  FtblExLines.SessionName := FSession.SessionName;
  FtblExLines.DatabaseName := clDatabaseName;
  FtblExLines.TableName := 'ExLines';

  FtblExOrders := TffTable.Create(nil);
  FtblExOrders.SessionName := FSession.SessionName;
  FtblExOrders.DatabaseName := clDatabaseName;
  FtblExOrders.TableName := 'ExOrders';

  FtblExProds := TffTable.Create(nil);
  FtblExProds.SessionName := FSession.SessionName;
  FtblExProds.DatabaseName := clDatabaseName;
  FtblExProds.TableName := 'ExProds';
end;
{--------}
procedure TffBaseClientTest.Teardown;
begin

  FDataBase.Free;
  FSession.Free;
  FCommsEngine.Free;
  FClient.Free;

  inherited TearDown;
end;
{--------}
procedure TffBaseClientTest.CloneTable(SrcName, DestName : string);
var
  aTable, aDestTable : TffTable;
begin
  { Assumption: FSession & FDatabase instantiated & valid. }
  aTable := TffTable.Create(nil);
  with aTable do
    try
      SessionName := FSession.SessionName;
      DatabaseName := FDatabase.DatabaseName;
      TableName := SrcName;
      Open;

      FDatabase.CreateTable(True, DestName, aTable.Dictionary);

      aDestTable := TffTable.Create(nil);
      with aDestTable do
        try
          SessionName := FSession.SessionName;
          DatabaseName := FDatabase.DatabaseName;
          TableName := DestName;
          Open;
          CopyRecords(aTable, True);
        finally
          Free;
        end;
    finally
      Free;
    end;
end;
{--------}
procedure TffBaseClientTest.CreateExBlobTable;
const
  cFile = 'ExBlob';
begin
  CloneTable('sav' + cFile, cFile);
end;
{--------}
procedure TffBaseClientTest.CreateExCustTable;
const
  cFile = 'ExCust';
begin
  CloneTable('sav' + cFile, cFile);
end;
{--------}
procedure TffBaseClientTest.CreateExLinesTable;
const
  cFile = 'ExLines';
begin
  CloneTable('sav' + cFile, cFile);
end;
{--------}
procedure TffBaseClientTest.CreateExOrdersTable;
const
  cFile = 'ExOrders';
begin
  CloneTable('sav' + cFile, cFile);
end;
{--------}
procedure TffBaseClientTest.CreateExProdsTable;
const
  cFile = 'ExProds';
begin
  CloneTable('sav' + cFile, cFile);
end;
{====================================================================}

end.
