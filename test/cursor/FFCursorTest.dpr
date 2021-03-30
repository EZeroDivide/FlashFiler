program FFCursorTest;

uses
  SysUtils,
  testCursor in 'testCursor.pas',
  contactu in '..\util\contactu.pas',
  baseTestCase in '..\util\basetestcase.pas',
  TestFramework in '..\..\..\dunit\src\TestFramework.pas',
  GUITestRunner in '..\..\..\dunit\src\GUITestRunner.pas' {GUITestRunner};

{$R *.RES}

begin
  GUITestRunner.runRegisteredTests;
end.
