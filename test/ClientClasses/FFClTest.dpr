program FFClTest;

uses
  Forms,
  baseTestCase in '..\Util\baseTestCase.pas',
  uTestCfg in 'uTestCfg.pas' {frmClientTestConfig},
  uClTBase in 'uClTBase.pas',
  uClTest in 'uClTest.pas',
  contactu in '..\util\contactu.pas',
  uclExt in 'uclExt.pas',
  ConnectTest in 'ConnectTest.pas' {frmConnectTest},
  TestServer in 'TestServer.pas' {frmTestServer},
  GUITestRunner in '..\..\..\dunit\src\GUITestRunner.pas' {GUITestRunner},
  TestFramework in '..\..\..\dunit\src\TestFramework.pas',
  DM301 in 'DM301.pas' {dmIssue301: TDataModule};

{$R *.RES}

begin
  GUITestRunner.runRegisteredTests;
end.
