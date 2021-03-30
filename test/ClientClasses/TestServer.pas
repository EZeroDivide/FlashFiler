unit TestServer;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ffllcomm, fflllgcy, ffsrintm, ffsrcmd, ffllbase, ffllcomp, fflleng,
  ffsreng;

type
  TfrmTestServer = class(TForm)
    Server: TffServerEngine;
    ServerCH: TffServerCommandHandler;
    ServerSUP: TffLegacyTransport;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmTestServer: TfrmTestServer;

implementation

{$R *.DFM}

procedure TfrmTestServer.FormCreate(Sender: TObject);
var
  ClientID : TffClientID;
  PwdHash : TffWord32;
begin
  Server.Startup;

  { Make sure the alias exists. }
  Server.ClientAdd(ClientID, '', '', 1000, PwdHash);
  Server.DatabaseDeleteAlias('issue449', ClientID);
  Server.DatabaseAddAlias('issue449', '..\data', True, ClientID);
  Server.ClientRemove(ClientID);
end;

procedure TfrmTestServer.FormDestroy(Sender: TObject);
begin
  Server.Shutdown;
end;

end.
