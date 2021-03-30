unit tstThread;

interface

uses
     classes,
     windows,
     FFLLBase,
     FFLLLgcy,
     ffsrBDE;

type
  PffTestMsg = ^TffTestMsg;
  TffTestMsg = packed record
    SomeNumber : DWORD;
    SomeTag : DWORD;
  end;

  TffTestThread = class;  { forward declaration }

  TffThreadNotifyEvent = procedure(Sender : TffTestThread; goodReply : boolean) of object;

  TTestType = (ttConcurrentConnect, ttConcurrentSend);

  TffTestThread = class(TThread)
  private
    FBadReplyCount : longInt;
    FBadReply : TNotifyEvent;
    FClientID : TffClientID;
    FData : PffTestMsg;   { The data sent in the request. }
    FDataLen : longInt;   { The length of the data in the request. }
    FGoodReply : TNotifyEvent;
    FGoodReplyCount : longInt;
    FGoodReplyFlag : boolean;
    FMaxPause : longInt;
    FMsgCount : longInt;
    FStop : boolean;
    FTestType : TTestType;
    FTransport : TffLegacyTransport;
  protected
    procedure UpdateUI;
  public
    constructor Create(const msgCount : longInt;
                       transport : TffLegacyTransport;
                       maxPause : longInt;
                       GoodReply, BadReply : TNotifyEvent);

    procedure Execute; override;

    procedure HandleReply(msgID        : longInt;
                          errorCode    : TffWord16;
                          replyData    : pointer;
                          replyDataLen : LongInt;
                          replyCookie  : LongInt);

    function Status : string;

    property BadReplyCount : longInt read FBadReplyCount;

    property GoodReplyCount : longInt read FGoodReplyCount;

    property Stop : boolean read FStop write FStop;

    property TestType : TTestType read FTestType write FTestType;

  end;

implementation

uses
  dialogs,
  sysUtils,
  tstCmd;

procedure ReplyCallback(msgID        : longInt;
                        errorCode    : TffResult;
                        replyData    : pointer;
                        replyDataLen : LongInt;
                        replyCookie  : LongInt);
begin
  TffTestThread(replyCookie).HandleReply(msgID, errorCode, replyData, replyDataLen, replyCookie);
end;

constructor TffTestThread.Create(const msgCount : longInt;
                                 transport : TffLegacyTransport;
                                 maxPause : longInt;
                                 GoodReply, BadReply : TNotifyEvent);
begin
  inherited Create(True);
  FBadReply := BadReply;
  FBadReplyCount := 0;
  FGoodReply := GoodReply;
  FGoodReplyCount := 0;
  FGoodReplyFlag := false;
  FMaxPause := maxPause;
  FMsgCount := msgCount;
  FStop := false;
  FTestType := ttConcurrentSend;
  FTransport := transport;
end;

procedure TffTestThread.Execute;
var
  Inx : longInt;
begin
  if FTestType = ttConcurrentSend then
    { Establish a connection. }
    try
      if FTransport.EstablishConnection('testThread', 0, 25000, FClientID) = DBIERR_NONE then begin
        New(FData);
        FData^.SomeTag := GetCurrentThreadID;
        FDataLen := sizeOf(TffTestMsg);
        for Inx := 1 to FMsgCount do begin
          if FStop then break;
          FData^.SomeNumber := GetTickCount;
          FTransport.Request(0, FClientID, clTestMsg, 240000, FData, FDataLen,
                             replycallback, longInt(Self));
          if Terminated then break;
          Sleep(Random(FMaxPause));
        end;
      end;
    finally
      if assigned(FData) then
        Dispose(FData);
      if FClientID > 0 then
        FTransport.TerminateConnection(FClientID, 2000);
    end
  else
    for Inx := 1 to FMsgCount do begin
      if FStop or Terminated then break;
      try
        FData := nil;
        if FTransport.EstablishConnection('testThread', 0, 25000, FClientID) = DBIERR_NONE then begin
          New(FData);
          FData^.SomeTag := GetCurrentThreadID;
          FDataLen := sizeOf(TffTestMsg);
          FData^.SomeNumber := GetTickCount;
          FTransport.Request(0, FClientID, clTestMsg, 240000, FData, FDataLen,
                             replycallback, longInt(Self));
          Sleep(Random(FMaxPause));
        end
        else
          FTransport.EventLog.WriteString('Could not establish connection');
      finally
        if assigned(FData) then
          Dispose(FData);
        if FClientID > 0 then
          FTransport.TerminateConnection(FClientID, 2000);
      end;
    end;  { for }
end;

procedure TffTestThread.HandleReply(msgID        : longInt;
                                    errorCode    : TffWord16;
                                    replyData    : pointer;
                                    replyDataLen : LongInt;
                                    replyCookie  : LongInt);
var
  replyMsg : PffTestMsg absolute replyData;
begin

  { Is this a good reply? }
  FGoodReplyFlag := (msgID = clTestMsg) and
                    (errorCode = 0) and
                    (FDataLen = replyDataLen) and
                    (replyMsg^.SomeNumber = FData^.SomeNumber) and
                    (replyMsg^.SomeTag = FData^.SomeTag);

  Synchronize(UpdateUI);

end;

function TffTestThread.Status : string;
begin
  Result := 'Thread ' + IntToStr(GetCurrentThreadID) + ' still active.';
end;

procedure TffTestThread.UpdateUI;
begin
  { If there is anything wrong about the message then mark it as a bad
    reply else mark it as a good reply. }
  if FGoodReplyFlag then begin
    inc(FGoodReplyCount);
    if assigned(FGoodReply) then
      FGoodReply(Self);
  end else begin
    inc(FBadReplyCount);
    if assigned(FBadReply) then
      FBadReply(Self);
  end;
end;

end.
