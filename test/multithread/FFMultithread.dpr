program FFMultithread;

uses
  SysUtils,
  contactu in '..\util\contactu.pas',
  testDBThread in 'testDBThread.pas',
  dbThread in 'dbThread.pas',
  baseTestCase in '..\util\basetestcase.pas',
  baseThread in '..\util\basethread.pas',
  GUITestRunner in '..\..\..\dunit\src\GUITestRunner.pas' {GUITestRunner},
  TestFramework in '..\..\..\dunit\src\TestFramework.pas';

{$R *.RES}

begin
  GUITestRunner.RunRegisteredTests;
end.

