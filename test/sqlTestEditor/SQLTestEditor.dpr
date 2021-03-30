program SQLTestEditor;

uses
  Forms,
  sysutils,
  fSQLTestEditor in 'fSQLTestEditor.pas' {frmSQLTestEditor},
  dSQLTestEditor in 'dSQLTestEditor.pas' {dtmSQLTestEditor: TDataModule},
  fConfiguration in 'fConfiguration.pas' {frmConfiguration},
  usqltesttypes in 'usqltesttypes.pas',
  utester in 'utester.pas',
  fFilterProperties in 'fFilterProperties.pas' {frmFilterProperties},
  ftestconfig in 'ftestconfig.pas' {frmConfigureTest};

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TdtmSQLTestEditor, dtmSQLTestEditor);
  Application.CreateForm(TfrmSQLTestEditor, frmSQLTestEditor);
  Application.CreateForm(TfrmFilterProperties, frmFilterProperties);
  Application.CreateForm(TfrmConfigureTest, frmConfigureTest);
  Application.Run;
  DeleteFile(ExtractFilePath(Application.ExeName) + 'ffsalias.ff2');
  DeleteFile(ExtractFilePath(Application.ExeName) + 'ffsinfo.ff2');
end.
