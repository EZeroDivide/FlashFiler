program FFMemTest;

uses
  SysUtils,
  testTmpStore in 'testTmpStore.pas',
  testMemPool in 'testMemPool.pas',
  testBufMgr in 'testBufMgr.pas',
  TestFramework in '..\..\..\dunit\src\TestFramework.pas',
  GUITestRunner in '..\..\..\dunit\src\GUITestRunner.pas' {GUITestRunner};

{$R *.RES}

begin
  GUITestRunner.RunRegisteredTests;
end.

