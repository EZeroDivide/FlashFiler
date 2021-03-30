unit fSQLTestEditor;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, IniFiles, StdCtrls, ExtCtrls, Grids, DBGrids, Db, DBCtrls;

type
  TfrmSQLTestEditor = class(TForm)
    dtsTest: TDataSource;
    grdTests: TDBGrid;
    pnlActions: TPanel;
    btnEdit: TButton;
    btnAdd: TButton;
    btnDelete: TButton;
    lblTestCount: TLabel;
    memSQL: TDBMemo;
    splSQL: TSplitter;
    pnlCategory: TPanel;
    lblCategory: TLabel;
    cboCategory: TComboBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure dtsTestDataChange(Sender: TObject; Field: TField);
    procedure cboCategoryChange(Sender: TObject);
  private
    FArchiveLocation : string;
    procedure DisplayCount;
  public
  end;

var
  frmSQLTestEditor: TfrmSQLTestEditor;

implementation

uses fConfiguration, dSQLTestEditor, ftestconfig;

{$R *.DFM}

procedure TfrmSQLTestEditor.FormCreate(Sender: TObject);
var
  RO : Boolean;
  Abrt : Boolean;
  Att : Integer;
  dbpath : string;
  tbname : string;
begin
  cboCategory.ItemIndex := 0;
  FArchiveLocation := ExtractFilePath(Application.EXEName) + 'SQLTests.FF2';

  {verify table exists}
  if not FileExists(FArchiveLocation) then begin
    ShowMessage('Archive must exist before this application can be run');
    Halt(1);
  end;

  {verify table is not read only}
  Abrt := False;
  repeat
    Att := FileGetAttr(FArchiveLocation);
    RO := Att and SysUtils.faReadOnly <> 0;
    if RO then
      Abrt := MessageDlg(Format('The archive "%s" is read-only. Please check-out from VSS and click '+#13+#10+'retry to continue.', [FArchiveLocation]), mtWarning, [mbAbort, mbRetry], 0) = mrAbort;
  until (RO = False) or (Abrt = True);

  if RO then begin
    ShowMessage('Archive cannot be read-only. Halting');
    Halt(1);
  end;

  {open table}
  dbpath := ExtractFilePath(FArchiveLocation);
  tbname := ExtractFileName(FArchiveLocation);
  dtmSQLTestEditor.Session.Open;
  dtmSQLTestEditor.Session.DeleteAliasEx('SQLTester');
  dtmSQLTestEditor.Session.AddAliasEx('SQLTester', dbpath);
  dtmSQLTestEditor.tblTest.DatabaseName := 'SQLTester';
  dtmSQLTestEditor.tblTest.TableName := tbName;
  dtmSQLTestEditor.tblTest.Open;
  dtmSQLTestEditor.tblOrderID.DatabaseName := 'SQLTester';
  dtmSQLTestEditor.tblOrderID.TableName := tbName;
  dtmSQLTestEditor.tblOrderID.Open;
end;
{--------}
procedure TfrmSQLTestEditor.FormDestroy(Sender: TObject);
begin
end;
{--------}
procedure TfrmSQLTestEditor.btnEditClick(Sender: TObject);
var
  frm:  TfrmConfigureTest;
begin
  frm := TfrmConfigureTest.Create(nil);
  try
    frm.SaveMode := smEdit;
    frm.TestTable := dtsTest.Dataset;
    frm.ShowModal
  finally
    frm.Free;
  end;
end;
{--------}
procedure TfrmSQLTestEditor.btnAddClick(Sender: TObject);
var
  frm:  TfrmConfigureTest;
begin
  frm := TfrmConfigureTest.Create(nil);
  try
    frm.SaveMode := smNew;
    frm.TestTable := dtsTest.Dataset;
    frm.ShowModal
  finally
    frm.Free;
  end;
end;
{--------}
procedure TfrmSQLTestEditor.btnDeleteClick(Sender: TObject);
begin
  if dtstest.dataset.recordcount = 0 then
    exit;
  if MessageDlg('Are you sure?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    dtsTest.Dataset.Delete;
end;
{--------}
procedure TfrmSQLTestEditor.DisplayCount;
begin
  lblTestCount.Caption := Format('%d tests',
                                 [dtmSQLTestEditor.tblTest.RecordCount]);
end;
{--------}
procedure TfrmSQLTestEditor.FormShow(Sender: TObject);
begin
  DisplayCount;
end;

procedure TfrmSQLTestEditor.dtsTestDataChange(Sender: TObject;
  Field: TField);
begin
  DisplayCount;
end;

procedure TfrmSQLTestEditor.cboCategoryChange(Sender: TObject);
begin
  dtmSQLTestEditor.LimitByCategory(cboCategory.Text);
end;

end.
