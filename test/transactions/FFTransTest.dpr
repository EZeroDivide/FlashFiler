program FFTransTest;

uses
  Forms,
  TEST_TranMgr in 'test_tranmgr.pas',
  TestFramework in '..\..\..\dunit\src\TestFramework.pas',
  GUITestRunner in '..\..\..\dunit\src\GUITestRunner.pas' {GUITestRunner},
  baseTestCase in '..\util\baseTestCase.pas';

{$R *.RES}

begin
  GUITestRunner.runRegisteredTests;
end.
