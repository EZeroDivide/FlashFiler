unit uSQLTestRunner;

interface
uses
  TestFramework, Controls, SysUtils;

type
  TffSQLQueryTests = class(TTestCase)
  published
    procedure TestVCLSelect;
    procedure TestVCLInsert;
    procedure TestVCLUpdate;
    procedure TestVCLDelete;
    procedure TestODBCSelect;
    procedure TestODBCInsert;
    procedure TestODBCUpdate;
    procedure TestODBCDelete;
  end;

implementation
uses
  fSQLTestRunner;


{ TffSQLQueryTests }

procedure TffSQLQueryTests.TestODBCDelete;
var
  frm : TfrmSQLTestRunner;
begin
  frm := TfrmSQLTestRunner.Create(nil);
  try
    frm.RunMode := rmODBC;
    frm.RunType := 'DELETE';
    if frm.ShowModal = mrNo then
      raise exception.Create('error in test. See ' + LogFileName + ' for details');
  finally
    frm.Free;
  end;
end;

procedure TffSQLQueryTests.TestODBCInsert;
var
  frm : TfrmSQLTestRunner;
begin
  frm := TfrmSQLTestRunner.Create(nil);
  try
    frm.RunMode := rmODBC;
    frm.RunType := 'INSERT';
    if frm.ShowModal = mrNo then
      raise exception.Create('error in test. See ' + LogFileName + ' for details');
  finally
    frm.Free;
  end;
end;

procedure TffSQLQueryTests.TestODBCSelect;
var
  frm : TfrmSQLTestRunner;
begin
  frm := TfrmSQLTestRunner.Create(nil);
  try
    frm.RunMode := rmODBC;
    frm.RunType := 'SELECT';
    if frm.ShowModal = mrNo then
      raise exception.Create('error in test. See ' + LogFileName + ' for details');
  finally
    frm.Free;
  end;
end;

procedure TffSQLQueryTests.TestODBCUpdate;
var
  frm : TfrmSQLTestRunner;
begin
  frm := TfrmSQLTestRunner.Create(nil);
  try
    frm.RunMode := rmODBC;
    frm.RunType := 'UPDATE';
    if frm.ShowModal = mrNo then
      raise exception.Create('error in test. See ' + LogFileName + ' for details');
  finally
    frm.Free;
  end;
end;

procedure TffSQLQueryTests.TestVCLDelete;
var
  frm : TfrmSQLTestRunner;
begin
  frm := TfrmSQLTestRunner.Create(nil);
  try
    frm.RunType := 'DELETE';
    if frm.ShowModal = mrNo then
      raise exception.Create('error in test. See ' + LogFileName + ' for details');
  finally
    frm.Free;
  end;
end;

procedure TffSQLQueryTests.TestVCLInsert;
var
  frm : TfrmSQLTestRunner;
begin
  frm := TfrmSQLTestRunner.Create(nil);
  try
    frm.RunType := 'INSERT';
    if frm.ShowModal = mrNo then
      raise exception.Create('error in test. See ' + LogFileName + ' for details');
  finally
    frm.Free;
  end;
end;

procedure TffSQLQueryTests.TestVCLSelect;
var
  frm : TfrmSQLTestRunner;
begin
  frm := TfrmSQLTestRunner.Create(nil);
  try
    frm.RunType := 'SELECT';
    if frm.ShowModal = mrNo then
      raise exception.Create('error in test. See ' + LogFileName + ' for details');
  finally
    frm.Free;
  end;
end;

procedure TffSQLQueryTests.TestVCLUpdate;
var
  frm : TfrmSQLTestRunner;
begin
  frm := TfrmSQLTestRunner.Create(nil);
  try
    frm.RunType := 'UPDATE';
    if frm.ShowModal = mrNo then
      raise exception.Create('error in test. See ' + LogFileName + ' for details');
  finally
    frm.Free;
  end;
end;

initialization
  RegisterTest('SQL Unit Tester', TffSQLQueryTests.Suite);

end.

