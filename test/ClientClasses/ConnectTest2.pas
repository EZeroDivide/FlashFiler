unit ConnectTest2;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ffllcomm, fflllgcy, ffsrintm, ffsrcmd, ffllcomp, fflleng, ffsreng, Db,
  ffdb, ffllbase, ffdbbase, Grids, DBGrids, ffclreng, fflllog;

type
  TfrmConnectTest2 = class(TForm)
    grdTest: TDBGrid;
    dsTest: TDataSource;
    FFClient: TffClient;
    FFSess: TffSession;
    FFDB: TffDatabase;
    TestTable: TffTable;
    RemoteServer: TFFRemoteServerEngine;
    ClientSUP: TffLegacyTransport;
    ClientLog: TffEventLog;
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Connect;
    procedure Disconnect;
  end;

var
  frmConnectTest2: TfrmConnectTest2;

implementation

{$R *.DFM}

procedure TfrmConnectTest2.Connect;
begin
  TestTable.Open;
end;

procedure TfrmConnectTest2.Disconnect;
begin
  TestTable.Session.Client.Close;
end;

end.
