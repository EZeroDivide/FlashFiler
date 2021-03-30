program FFBLOBTest;

uses
  Forms,
  baseTestCase in '..\Util\baseTestCase.pas',
  testBLOBs in 'testBLOBs.pas',
  TestFramework in '..\..\..\dunit\src\TestFramework.pas',
  GUITestRunner in '..\..\..\dunit\src\GUITestRunner.pas' {GUITestRunner};

{$R *.RES}

begin
  GUITestRunner.runRegisteredTests;
end.
