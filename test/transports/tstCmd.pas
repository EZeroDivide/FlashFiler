unit tstCmd;

// NOTE: This code does not compile with the latest version of FF2.

interface

uses
     classes,
     ffllbase,
     ffllComm;

const
  clTestMsg = $0800;

type
  TffTestCmdHandler = class(TffBaseCommandHandler)
  private
    FClients : TffThreadList;
    FDelayRange : longInt;
  protected

    { The following methods were nabbed from ffSrCmd }
    procedure bchAddTransport(aTransport : TffBaseTransport); override;
      { This overridden method sets the OnAddclient and OnRemoveClient events
        of the registering transport. }

    procedure schOnAddClient(Sender : TffBaseTransport;
                       const userID : TffName;
                       const timeout : longInt;
                       const clientVersion : longInt;
                         var passwordHash : TffWord32;
                         var aClientID : TffClientID;
                         var errorCode : TffResult;
                         var isSecure : boolean;
                         var aVersion : longInt);
      { This method is called when the transport needs to establish a new
        client. }

    procedure schOnRemoveClient(Sender : TffBaseTransport;
                          const aClientID : TffClientID;
                            var errorCode : TffResult);
      { This method is called when the transport needs to remove an existing
        client. }

    procedure scInitialize; override;
    procedure scPrepareForShutdown; override;
    procedure scShutdown; override;
    procedure scStartup; override;

  public

    constructor Create(aOwner : TComponent); override;

    destructor Destroy; override;

    procedure Process(Msg : PffDataMessage); override;

    property DelayRange : longInt read FDelayRange write FDelayRange;
  end;


implementation

uses
  Dialogs,
  Windows,
  FFLLProt,
  FFNetMsg;

{--------}
constructor TffTestCmdHandler.Create(aOwner : TComponent);
begin
  inherited Create(aOwner);
  FClients := TffThreadList.Create;
  FDelayRange := 0;
end;
{--------}
destructor TffTestCmdHandler.Destroy;
begin
  if assigned(FClients) then
    FClients.Free;
  inherited Destroy;
end;
{--------}
procedure TffTestCmdHandler.bchAddTransport(aTransport : TffBaseTransport);
begin
  inherited bchAddTransport(aTransport);
  aTransport.OnAddClient := schOnAddClient;
  aTransport.OnRemoveClient := schOnRemoveClient;
end;
{--------}
procedure TffTestCmdHandler.Process(Msg : PffDataMessage);
begin
  case Msg^.dmMsg of
    clTestMsg :
      begin
        if FDelayRange > 0 then
          Sleep(Random(FDelayRange));
        TffBaseTransport.Reply(Msg^.dmMsg, 0, Msg^.dmData, Msg^.dmDataLen);
      end;
    ffnmCheckSecureComms :
      TffBaseTransport.Reply(Msg^.dmMsg, 0, nil, 0);
  else
    showMessage('unknown msg');
  end;  { case }
end;
{--------}
procedure TffTestCmdHandler.schOnAddClient
                               (Sender : TffBaseTransport;
                          const userID : TffName;
                          const timeout : longInt;
                          const clientVersion : longInt;
                            var passwordHash : TffWord32;
                            var aClientID : TffClientID;
                            var errorCode : TffResult;
                            var isSecure : boolean;
                            var aVersion : longInt);
var
  anItem : TffSelfListItem;
begin
  passwordHash := 0;
  with FClients.BeginWrite do
    try
      anItem := TffSelfListItem.Create;
      aClientID := anItem.KeyAsInt;
      Insert(anItem);
    finally
      EndWrite;
    end;
  isSecure := False;
  errorCode := 0;
  aVersion := ffVersionNumber;
end;
{--------}
procedure TffTestCmdHandler.schOnRemoveClient
                                    (Sender : TffBaseTransport;
                               const aClientID : TffClientID;
                                 var errorCode : TffResult);
begin
  with FClients.BeginWrite do
    try
      FClients.Delete(aClientID);
    finally
      EndWrite;
    end;
  errorCode := 0;
end;
{--------}
procedure TffTestCmdHandler.scInitialize;
begin
  { Do nothing }
end;
{--------}
procedure TffTestCmdHandler.scPrepareForShutdown;
begin
  { Do nothing }
end;
{--------}
procedure TffTestCmdHandler.scShutdown;
begin
  { Do nothing }
end;
{--------}
procedure TffTestCmdHandler.scStartup;
begin
  { Do nothing }
end;

end.
