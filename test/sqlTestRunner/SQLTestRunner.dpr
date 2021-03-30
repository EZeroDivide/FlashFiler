program SQLTestRunner;

uses
  Forms,
  GUITestRunner in '..\..\..\dunit\src\GUITestRunner.pas',
  fSQLTestRunner in 'fSQLTestRunner.pas' {frmSQLTestRunner},
  uSQLTestRunner in 'uSQLTestRunner.pas',
  ExCreateDSN in 'ExCreateDSN.pas',
  TestFramework in '..\..\..\dunit\src\TestFramework.pas',
  utester in '..\sqlTestEditor\utester.pas',
  usqltesttypes in '..\sqlTestEditor\usqltesttypes.pas';

{$R *.RES}

begin
  GUITestRunner.runRegisteredTests;
end.
