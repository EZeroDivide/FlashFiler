{ Change log
{ 6/27/2000 -
    1.Fixed access violation when closing the application if server is
      selected, but not started.
}
unit main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, FFLLLgcy, tstCmd, FFLLThrd, tstThread, ffllbase,
  ffllEng, ffllComm, FFLLProt, FFLLComp, ffllLog, memLog;

type
  TfrmMain = class(TForm)
    timServer: TTimer;
    GroupBox1: TGroupBox;
    gbClientStatus: TGroupBox;
    lblClientStatus1: TLabel;
    lblClientStatus2: TLabel;
    lblClientStatus3: TLabel;
    gbSendParm: TGroupBox;
    lblThreads: TLabel;
    lblThreadMsg: TLabel;
    lblServerName: TLabel;
    lblMaxPause: TLabel;
    efNumThreads: TEdit;
    efMsgsPerThread: TEdit;
    efRemoteSrvName: TEdit;
    efMaxPause: TEdit;
    rgProtocol: TRadioGroup;
    GroupBox2: TGroupBox;
    gbServerParam: TGroupBox;
    lblSrvName: TLabel;
    lblSrvDelay: TLabel;
    efSrvName: TEdit;
    efSrvDelay: TEdit;
    gbServerStatus: TGroupBox;
    lblServerStatus1: TLabel;
    lblServerStatus2: TLabel;
    lblProtocols: TLabel;
    lblTCP: TLabel;
    lblIPX: TLabel;
    lblSUP: TLabel;
    lblConns: TLabel;
    lblTCPconn: TLabel;
    lblIPXconn: TLabel;
    lblSUPconn: TLabel;
    pbReset: TButton;
    pbStartServer: TButton;
    pbStopServer: TButton;
    pbStartClient: TButton;
    pbStopClient: TButton;
    gbProtocols: TGroupBox;
    chkServerSUP: TCheckBox;
    chkServerTCPIP: TCheckBox;
    chkServerIPXSPX: TCheckBox;
    cbClientLog: TCheckBox;
    cbServerLog: TCheckBox;
    timClient: TTimer;
    rgTestType: TRadioGroup;
    pbFlush: TButton;
    cbClientLogType: TCheckBox;
    cbServerLogType: TCheckBox;
    pbServerSaveLog: TButton;
    pbClientSaveLog: TButton;
    pbClientClear: TButton;
    pbServerClear: TButton;
    procedure pbStartServerClick(Sender: TObject);
    procedure pbStopServerClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure rgModeClick(Sender: TObject);
    procedure timServerTimer(Sender: TObject);
    procedure pbResetClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure pbStartClientClick(Sender: TObject);
    procedure pbStopClientClick(Sender: TObject);
    procedure timClientTimer(Sender: TObject);
    procedure pbFlushClick(Sender: TObject);
    procedure pbClientSaveLogClick(Sender: TObject);
    procedure pbServerSaveLogClick(Sender: TObject);
    procedure pbClientClearClick(Sender: TObject);
    procedure pbServerClearClick(Sender: TObject);
  private
    { Private declarations }

    FCmdHandler : TffTestCmdHandler;
    FClientBadReplyCount : longInt;
    FClientGoodReplyCount : longInt;
    FClientLog : TffMemoryLog;
    FClientProtocol : TffProtocolType;
    FServerProtocol : TffProtocolType;
    FClientStarted : boolean;
    FServerLog : TffMemoryLog;
    FServerStarted : Boolean;
    FThreadList : TffThreadList;
    FThreadPool : TffThreadPool;
    FTransport : TffLegacyTransport;

    { Server transports }
    FTransportTCP : TffLegacyTransport;
    FTransportIPX : TffLegacyTransport;
    FTransportSUP : TffLegacyTransport;

    function getProtocol : TffProtocolType;

    procedure HandleAppException(Sender : TObject; E: Exception);
    procedure handleServer;
    procedure handleClient;

    procedure SetGBox(aBox : TGroupBox; active : boolean);
    procedure SetRBox(aBox : TRadioGroup; active : boolean);

    procedure SetCtrlStates;

    procedure stopServer;
    procedure stopClient;

    procedure ThreadTerminated(Sender : TObject);
      { Called when a thread has finished processing.  This handler removes
        the thread from the thread list. }

    procedure UpdateClientThreadDisplay;
    procedure UpdateCountDisplay(updateGood, updateBad : boolean);

  public
    { Public declarations }
    procedure BadReply(Sender : TObject);
      { Called from a thread when a good reply is received. }
    procedure GoodReply(Sender : TObject);
      { Called from a thread when a bad reply is received. }
  end;

var
  frmMain: TfrmMain;

implementation

uses
  ffSrEng;

{$R *.DFM}

const
  csStatus = 'Status: ';

procedure TfrmMain.pbStartServerClick(Sender: TObject);
begin
  FServerProtocol := getProtocol;
  FServerStarted := True;

  handleServer;
end;

function TfrmMain.getProtocol : TffProtocolType;
begin
  case rgProtocol.itemIndex of
    0 : Result := ptIPXSPX;
    1 : Result := ptSingleUser;
    2 : Result := ptTCPIP;
  else
    Result := ptSingleUser;
  end;  { case }
end;

procedure TfrmMain.handleServer;
begin
  if not (chkServerSUP.Checked or
          chkServerIPXSPX.Checked or
          chkServerTCPIP.Checked) then begin
    MessageDlg('You must select at least one protocol!.', mtError, [mbOK], 0);
    Exit;
  end;

  { Create the command handler. }
  FCmdHandler := TffTestCmdHandler.Create(nil);
  FCmdHandler.DelayRange := strToInt(efSrvDelay.text);

  { Create the thread pool. }
  FThreadPool := TffThreadPool.Create(nil);
  FThreadPool.InitialCount := 20;
  FThreadPool.MaxCount := 50;

  { Create the transports and register them with the command handler. }
  if chkServerTCPIP.Checked then begin
    FTransportTCP := TffLegacyTransport.Create(nil);
  //  FTransportTCP.BeginUpdate;
  //  try
      FTransportTCP.CommandHandler := FCmdHandler;
      FTransportTCP.Protocol := ptTCPIP;
      FTransportTCP.RespondToBroadcasts := True;
      FTransportTCP.Mode := fftmListen;
      FTransportTCP.EventLogEnabled := cbServerLog.Checked;
      if cbServerLogType.Checked then
        FTransportTCP.EventLogOptions := [fftpLogErrors, fftpLogRequests,
                                          fftpLogReplies]
      else
        FTransportTCP.EventLogOptions := [fftpLogErrors];
      FTransportTCP.EventLog := FServerLog;
      FTransportTCP.ServerName := efSrvName.Text;
      FTransportTCP.ThreadPool := FThreadPool;
      FTransportTCP.Enabled := True;
  //  finally
  //    FTransportTCP.EndUpdate;
  //  end;
  end;

  if chkServerIPXSPX.Checked then begin
    FTransportIPX := TffLegacyTransport.Create(nil);
    FTransportIPX.BeginUpdate;
    try
      FTransportIPX.CommandHandler := FCmdHandler;
      FTransportIPX.Protocol := ptIPXSPX;
      FTransportIPX.RespondToBroadcasts := True;
      FTransportIPX.Mode := fftmListen;
      FTransportIPX.EventLogEnabled := cbServerLog.Checked;
      if cbServerLogType.Checked then
        FTransportIPX.EventLogOptions := [fftpLogErrors, fftpLogRequests,
                                          fftpLogReplies]
      else
        FTransportIPX.EventLogOptions := [fftpLogErrors];
      FTransportIPX.EventLog := FServerLog;
      FTransportIPX.ServerName := efSrvName.Text;
      FTransportIPX.ThreadPool := FThreadPool;
      FTransportIPX.Enabled := True;
    finally
      FTransportIPX.EndUpdate;
    end;
  end;

  if chkServerSUP.Checked then begin
    FTransportSUP := TffLegacyTransport.Create(nil);
  //  FTransport.BeginUpdate;
  //  try
      FTransportSUP.CommandHandler := FCmdHandler;
      FTransportSUP.Protocol := ptSingleUser;
      FTransportSUP.RespondToBroadcasts := True;
      FTransportSUP.Mode := fftmListen;
      FTransportSUP.EventLogEnabled := cbServerLog.Checked;
      if cbServerLogType.Checked then
        FTransportSUP.EventLogOptions := [fftpLogErrors, fftpLogRequests,
                                          fftpLogReplies]
      else
        FTransportSUP.EventLogOptions := [fftpLogErrors];
      FTransportSUP.EventLog := FServerLog;
      FTransportSUP.ServerName := efSrvName.Text;
      FTransportSUP.ThreadPool := FThreadPool;
      FTransportSUP.Enabled := True;
  //  finally
  //    FTransportSUP.EndUpdate;
  //  end;
  end;

  { Activate the command handler. }
  FCmdHandler.State := ffesStarted;

  timServer.Enabled := True;
  timServerTimer(Self);

  SetCtrlStates;

end;

procedure TfrmMain.handleClient;
var
  anItem : TffIntListItem;
  aThread : TffTestThread;
  anInx : longInt;
  MaxPause : longInt;
  numThreads : longInt;
  numMsgs : longInt;
begin

  { Get the Sender parameters. }
  numThreads := strToInt(efNumThreads.text);
  numMsgs := strToInt(efMsgsPerThread.text);
  MaxPause := strToInt(efMaxPause.text);

  { Create the thread container. }
  FThreadList := TffThreadList.Create;

  { Create the transport. }
  FTransport := TffLegacyTransport.Create(nil);
//  FTransport.BeginUpdate;
//  try
    FTransport.Protocol := FClientProtocol;
    FTransport.Mode := fftmSend;
    if FClientProtocol <> ptSingleUser then
      FTransport.ServerName := efRemoteSrvName.text;
    FTransport.EventLogEnabled := cbClientLog.Checked;
    FTransport.EventLog := FClientLog;
    if cbClientLogType.Checked then
      FTransport.EventLogOptions := [fftpLogErrors, fftpLogRequests,
                                     fftpLogReplies]
    else
      FTransport.EventLogOptions := [fftpLogErrors];
    FTransport.Enabled := True;
    FTransport.State := ffesStarted;
//  finally
//    FTransport.EndUpdate;
//  end;

  { Create the threads. }
  with FThreadList.BeginWrite do
    try
      for anInx := 1 to numThreads do begin
        aThread := TffTestThread.Create(numMsgs, FTransport, MaxPause,
                                        GoodReply, BadReply);
        aThread.FreeOnTerminate := True;
        aThread.OnTerminate := ThreadTerminated;
        if rgTestType.ItemIndex = 0 then
          aThread.TestType := ttConcurrentConnect
        else
          aThread.TestType := ttConcurrentSend;
        anItem := TffIntListItem.Create(longInt(aThread));
        Insert(anItem);
      end;
    finally
      EndWrite;
    end;

  { Start the threads. }
  with FThreadList.BeginRead do
    try
      for anInx := 0 to pred(Count) do
        TffTestThread(TffIntListItem(Items[anInx]).KeyAsInt).Resume;
    finally
      EndRead;
    end;

  timClient.Enabled := True;

  SetCtrlStates;

end;

procedure TfrmMain.ThreadTerminated(Sender : TObject);
var
  aThread : TffTestThread;
  freeEverything : boolean;
begin
  aThread := TffTestThread(Sender);
  { Find & remove the thread from the thread list. }
  with FThreadList.BeginWrite do
    try
      Delete(longInt(aThread));
      freeEverything := (Count = 0);
    finally
      EndWrite;
    end;

  { Clean up if that was the last thread. }
  if freeEverything then begin
    { Tell the client transport to stop. }
    FTransport.State := ffesInactive;
    FTransport.Free;
    FTransport := nil;

    FClientStarted := False;
    SetCtrlStates;
    timClient.Enabled := False;

    FThreadList.Free;
    FThreadList := nil;

  end;
end;

procedure TfrmMain.UpdateCountDisplay;
begin
  lblClientStatus1.Caption := format('# good replies: %d',[FClientGoodReplyCount]);
  lblClientStatus2.Caption := format('# bad replies: %d',[FClientBadReplyCount]);
end;

procedure TfrmMain.pbStopServerClick(Sender: TObject);
begin

  stopServer;

  FServerStarted := False;

  SetCtrlStates;

end;

procedure TfrmMain.SetGBox(aBox : TGroupBox; active : boolean);
begin
  aBox.Enabled := active;
  if active then
    aBox.Font.Color := clWindowText
  else
    aBox.Font.Color := clInactiveCaption;
end;

procedure TfrmMain.SetRBox(aBox : TRadioGroup; active : boolean);
begin
  aBox.Enabled := active;
  if active then
    aBox.Font.Color := clWindowText
  else
    aBox.Font.Color := clInactiveCaption;

end;

procedure TfrmMain.SetCtrlStates;
begin
  pbStartClient.Enabled := (not FClientStarted);
  pbStopClient.Enabled := FClientStarted;
  pbStartServer.Enabled := not FServerStarted;
  pbStopServer.Enabled := FServerStarted;

  pbReset.Enabled := (not FServerStarted);

  if not FServerStarted then begin
    gbServerStatus.Caption := 'Server: ' + csStatus + '<Inactive>';
    lblServerStatus1.Caption := 'Active threads: --';
    lblServerStatus2.Caption := 'Inactive threads: --';
  end;

  if not FClientStarted then begin
    gbClientStatus.Caption := 'Client: ' + csStatus + '<Inactive>';
    lblClientStatus1.Caption := '# good replies: --';
    lblClientStatus2.Caption := '# bad replies: --';
  end;

  UpdateClientThreadDisplay;

  if FClientStarted or FServerStarted then begin
    if FServerStarted then begin
      gbServerStatus.Caption := 'Server: ' + csStatus + '<Listening>';
      frmMain.Caption := 'Server';
      application.Title := 'Server';

      { Update the protocol labels. }
      if assigned(FTransportTCP) then
        lblTCP.Caption := format('%s: %s',
                                 [FTransportTCP.GetName, FTransportTCP.ServerName])
      else
        lblTCP.Caption := 'TCP: --';

      if assigned(FTransportIPX) then
        lblIPX.Caption := format('%s: %s',
                                 [FTransportIPX.GetName, FTransportIPX.ServerName])
      else
        lblIPX.Caption := 'IPX: --';

      if assigned(FTransportSUP) then
        lblSUP.Caption := format('%s: %s',
                                 [FTransportSUP.GetName, FTransportSUP.ServerName])
      else
        lblSUP.Caption := 'SUP: --';
    end;
end;
  if FClientStarted then begin
      gbClientStatus.Caption := 'Client: ' + csStatus + '<Sending>';
    timClientTimer(Self);
  end;

  SetRBox(rgProtocol, not FClientStarted);
  SetGBox(gbSendParm, not FClientStarted);
  SetGBox(gbServerParam, not FServerStarted);
end;

procedure TfrmMain.stopServer;
begin
  if not FServerStarted then Exit;
  try
    { Tell the command handler to shutdown. }
    FCmdHandler.State := ffesInactive;
    timServer.Enabled := False;
    timServerTimer(Self);
  finally

    if assigned(FTransportTCP) then begin
      FTransportTCP.State := ffesInactive;
      FTransportTCP.Free;
      FTransportTCP := nil;
    end;

    if assigned(FTransportIPX) then begin
      FTransportIPX.State := ffesInactive;
      FTransportIPX.Free;
      FTransportIPX := nil;
    end;

    if assigned(FTransportSUP) then begin
      FTransportSUP.State := ffesInactive;
      FTransportSUP.Free;
      FTransportSUP := nil;
    end;

    if assigned(FCmdHandler) then begin
      FCmdHandler.Free;
      FCmdHandler := nil;
    end;

    if assigned(FThreadPool) then begin
      FThreadPool.Free;
      FThreadPool := nil;
    end;

  end;

end;

procedure TfrmMain.stopClient;
var
  anInx : longInt;
begin
  if FClientStarted and assigned(FThreadList) then
    with FThreadList.BeginRead do
      try
        for anInx := 0 to pred(Count) do
          TffTestThread(TffIntListItem(Items[anInx]).KeyAsInt).Terminate;
      finally
        EndRead;
      end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FClientBadReplyCount := 0;
  FClientGoodReplyCount := 0;
  FClientStarted := false;
  FServerStarted := False;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  FClientLog := TffMemoryLog.Create(nil);
  FClientLog.Enabled := True;
  FClientLog.MaxLines := 10000;
  FClientLog.FileName := 'client.log';

  FServerLog := TffMemoryLog.Create(nil);
  FServerLog.Enabled := True;
  FServerLog.MaxLines := 10000;
  FServerLog.FileName := 'server.log';

  SetCtrlStates;
  UpdateCountDisplay(true, true);
  Application.OnException := HandleAppException;
end;

procedure TfrmMain.HandleAppException(Sender : TObject; E: Exception);
begin
  showMessage('Object ' + Sender.Classname + ', E: ' + E.message);
end;

procedure TfrmMain.rgModeClick(Sender: TObject);
begin
  SetCtrlStates;
end;

procedure TfrmMain.GoodReply(Sender : TObject);
begin
  inc(FClientGoodReplyCount);
  UpdateCountDisplay(true, false);
end;

procedure TfrmMain.BadReply(Sender : TObject);
begin
  inc(FClientBadReplyCount);
  UpdatecountDisplay(false, true);
end;

procedure TfrmMain.UpdateClientThreadDisplay;
begin
  if FClientStarted then begin
    if assigned(FThreadList) then
      lblClientStatus3.Caption := format('Active threads: %d', [FThreadList.Count])
    else
      lblClientStatus3.Caption := 'Active threads: No ThreadList';
  end else
    lblClientStatus3.Caption := 'Active threads: ---';
end;

procedure TfrmMain.timServerTimer(Sender: TObject);
begin
  if FServerStarted then begin
    { Update thread pool info. }
    if assigned(FThreadPool) then begin
      lblServerStatus1.Caption := format('Active threads: %d', [FThreadPool.ActiveCount]);
      lblServerStatus2.Caption := format('Inactive threads: %d', [FThreadPool.InactiveCount]);
    end else begin
      lblServerStatus1.Caption := 'Active threads: No Pool';
      lblServerStatus2.Caption := 'Inactive threads: No Pool';
    end;

    { Update connection counts. }
    if assigned(FTransportTCP) then
      lblTCPconn.caption := intToStr(FTransportTCP.ConnectionCount)
    else
      lblTCPconn.caption := '0';

    if assigned(FTransportIPX) then
      lblIPXconn.caption := intToStr(FTransportIPX.ConnectionCount)
    else
      lblIPXconn.caption := '0';

    if assigned(FTransportSUP) then
      lblSUPconn.caption := intToStr(FTransportSUP.ConnectionCount)
    else
      lblSUPconn.caption := '0';

  end;
end;

procedure TfrmMain.pbResetClick(Sender: TObject);
begin
  FClientGoodReplyCount := 0;
  FClientBadReplyCount := 0;
  UpdateCountDisplay(true, true);
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  stopClient;
  stopServer;
  FClientLog.Free;
  FServerLog.Free;
end;

procedure TfrmMain.pbStartClientClick(Sender: TObject);
begin
  FClientProtocol := getProtocol;
  FClientStarted := True;
  handleClient;
end;

procedure TfrmMain.pbStopClientClick(Sender: TObject);
begin
  stopClient;
  FClientStarted := False;
  SetCtrlStates;
end;

procedure TfrmMain.timClientTimer(Sender: TObject);
begin
  UpdateClientThreadDisplay;
end;

procedure TfrmMain.pbFlushClick(Sender: TObject);
begin
  if assigned(FThreadPool) then
    FThreadPool.Flush(0);
end;

procedure TfrmMain.pbClientSaveLogClick(Sender: TObject);
var
  anInx : Integer;
begin
  { Write info about active threads. }
  if Assigned(FThreadList) then
    with FThreadList.BeginRead do
      try
        for anInx := 0 to pred(Count) do
          FClientLog.WriteString(TffTestThread(TffIntListItem(Items[anInx]).KeyAsInt).Status);
      finally
        EndRead;
      end;
    if assigned(FClientLog) then
      FClientLog.SaveToFile;
end;

procedure TfrmMain.pbServerSaveLogClick(Sender: TObject);
begin
  if assigned(FServerLog) then
    FServerLog.SaveToFile;
  TffMemoryLog(FFLLProt.KALog).SaveToFile;
end;

procedure TfrmMain.pbClientClearClick(Sender: TObject);
begin
  FClientLog.Clear;
end;

procedure TfrmMain.pbServerClearClick(Sender: TObject);
begin
  FServerLog.Clear;
  TffMemoryLog(FFLLPROT.KaLog).Clear;
end;

end.
