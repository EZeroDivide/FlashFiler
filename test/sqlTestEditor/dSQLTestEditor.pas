unit dSQLTestEditor;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Db, ffdb, ffdbbase, ffllcomp, fflleng, ffsrintm, ffsreng, ffllbase,
  ffsqlbas, ffsqleng;

type
  TdtmSQLTestEditor = class(TDataModule)
    SQL: TffSqlEngine;
    Server: TffServerEngine;
    Client: TffClient;
    Session: TffSession;
    tblTest: TffTable;
    Database: TffDatabase;
    tblOrderID: TffTable;
    TestSession: TffSession;
    TestClient: TffClient;
    procedure DataModuleDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    procedure LimitByCategory(const Category : string);
    function GetNextOrderID : Integer;
  end;

var
  dtmSQLTestEditor: TdtmSQLTestEditor;

implementation

{$R *.DFM}

function TdtmSQLTestEditor.GetNextOrderID: Integer;
begin
  tblOrderID.Last;
  Result := Succ(tblOrderID.FieldByName('OrderID').AsInteger);
end;
procedure TdtmSQLTestEditor.LimitByCategory(const Category: string);
begin
  if CompareText(Category, '<ALL>') = 0 then
    tblTest.CancelRange
  else
    tblTest.SetRange([Category],[Category]);
end;
procedure TdtmSQLTestEditor.DataModuleDestroy(Sender: TObject);
begin
  TestClient.Close;
end;

end.
