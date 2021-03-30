unit ConnectTest;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ffllcomm, fflllgcy, ffsrintm, ffsrcmd, ffllcomp, fflleng, ffsreng, Db,
  ffdb, ffllbase, ffdbbase, Grids, DBGrids, ffclreng, fflllog;

type
  TfrmConnectTest = class(TForm)
    grdTest: TDBGrid;
    dsTest: TDataSource;
    TestTable: TffTable;
    ClientLog: TffEventLog;
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Connect;
    procedure Disconnect;
  end;

var
  frmConnectTest: TfrmConnectTest;

implementation

{$R *.DFM}

uses
  FFClCfg,
  FFLLProt;


procedure TfrmConnectTest.Connect;
begin
  FFClientConfigWriteProtocolClass(TffSingleUserProtocol);
  TestTable.Open;
end;

procedure TfrmConnectTest.Disconnect;
begin
  TestTable.Session.Client.Close;
end;

end.
