unit baseTestCase;

interface

uses
  Forms,
  SysUtils,
  FFDB,
  FFLLEng,
  FFLLProt,
  FFLLLgcy,
  FFLLLog,
  FFLLComp,
  FFSrSec,
  FFSrEng,
  TestFramework;

type
  TffBaseTest = class(TTestCase)
  protected
    FEngine : TffBaseServerEngine;
    FEventLog : TffEventLog;
    FProtocol : TffProtocolType;
    FRemoteEngine : boolean;
    FSecMon : TffSecurityMonitor;
    FSecured : Boolean;
    FServerName : string;
    FSystemDir : string;
    FTransport : TffLegacyTransport;

    procedure SetSecured(const Value : Boolean);

    procedure Setup; override;
    procedure Teardown; override;

  public
    property Protocol : TffProtocolType read FProtocol write FProtocol;
      { If using a remote server engine, this specifies the protocol to be
        used. }

    property RemoteEngine : boolean read FRemoteEngine write FRemoteEngine;
      { If True then use a remote server engine for testing. }

    property Secured : boolean read FSecured write SetSecured;
      { Activate secure logins on embedded server engine.
        Raises an exception if Remote server engine is in use. }

    property ServerName : string read FServerName write FServerName;
      { If using a remote server engine, this specifies the server's name. }

    property SystemDir : string read FSystemDir write FSystemDir;
      { The system directory to be used by the server engine. }

  end;

const
  { User constants for setting up users in a secured server. }
  csROUserID = 'tester';
  csROPassword = 'testering';
  csROLastName = 'RO';
  csROFirstName = 'tester';

implementation

uses
  FFCLReng,
  ffHash,
  ffsrBase,
  FFLLComm;

{===TffBaseTest======================================================}
procedure TffBaseTest.SetSecured(const Value : Boolean);
begin
  if FRemoteEngine then
    raise Exception.Create('You can set Secured to True only when using ' +
                           'an embedded server engine');
  if FSecured <> Value then begin
    FSecured := Value;
    if FSecured then begin
      { Create read-only user. }
      TffServerEngine(FEngine).Configuration.AddUser
        (csROUserID, csROLastName, csROFirstName,
         FFCalcShStrELFHash(csROPassword),
         [arRead]);
    end;
    { Update the server engine's configuration. }
    TffServerEngine(FEngine).Configuration.GeneralInfo^.giIsSecure := FSecured;
  end;
end;
{--------}
procedure TffBaseTest.Setup;
begin
  Application.ProcessMessages;
  FEngine := nil;
  FSecured := False;

//  FProtocol := ptSingleUser;
//  FRemoteEngine := False;
//  FServerName := '';

  FSystemDir := ExtractFilePath(Application.ExeName);
  FTransport := nil;
  if FRemoteEngine then begin
    FEventLog := TffEventLog.Create(nil);
    FEventLog.Enabled := True;
    FEventLog.FileName := FSystemDir + 'event.log';
    FEngine := TffRemoteServerEngine.Create(nil);
    with FEngine do begin
      EventLog := FEventLog;
      EventLogEnabled := True;
      SystemDir := FSystemDir;
    end;

    FTransport := TffLegacyTransport.Create(nil);
    with FTransport do
      begin
        Mode := fftmSend;
        Protocol := FProtocol;
        ServerName := FServerName;
        Enabled := True;
        EventLogEnabled := False;
        EventLogOptions := [fftpLogErrors, fftpLogRequests, fftpLogReplies];
        EventLog := FEventLog;
      end;
    TffRemoteServerEngine(FEngine).Transport := FTransport;
    FEngine.State := ffesStarted;
    FTransport.State := ffesStarted;
  end
  else begin
    FEngine := TffServerEngine.Create(nil);
    FEngine.State := ffesStarted;
    FSecMon := TffSecurityMonitor.Create(nil);
    FSecMon.ServerEngine := FEngine;
  end;
end;
{--------}
procedure TffBaseTest.Teardown;
begin
  if FRemoteEngine then begin
    FTransport.State := ffesInactive;
    FEngine.State := ffesInactive;
    FTransport.Free;
    FEngine.Free;
    FEventLog.Free;
    FEventLog := nil;
    FEngine := nil;
    FTransport := nil;
  end
  else begin
    FEngine.State := ffesInactive;
    FSecMon.Free;
    FEngine.Free;
    FEngine := nil;
  end;
  Application.ProcessMessages;
end;
{====================================================================}

end.
