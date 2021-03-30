program testAll;

uses
  Forms,
  testSecurity in '..\Extender\testSecurity.pas',
  testCursorExt in '..\Extender\testCursorExt.pas',
  contactu in '..\util\contactu.pas',
  baseTestCase in '..\util\basetestcase.pas',
  testBLOBs in '..\BLOBs\testBLOBs.pas',
  testCursor in '..\cursor\testCursor.pas',
  testBufMgr in '..\Memory\testBufMgr.pas',
  testMemPool in '..\Memory\testMemPool.pas',
  testTmpStore in '..\Memory\testTmpStore.pas',
  testDBThread in '..\multiThread\testDBThread.pas',
  dbThread in '..\multiThread\dbThread.pas',
  baseThread in '..\util\basethread.pas',
  testTransactionActions in '..\Extender\testTransactionActions.pas',
  TestFramework in '..\..\..\dunit\src\TestFramework.pas',
  GUITestRunner in '..\..\..\dunit\src\GUITestRunner.pas' {GUITestRunner},
  uClTBase in '..\ClientClasses\uClTBase.pas',
  uTestCfg in '..\ClientClasses\uTestCfg.pas' {frmClientTestConfig},
  uClTest in '..\ClientClasses\uClTest.pas',
  uclExt in '..\ClientClasses\uclExt.pas',
  ConnectTest2 in '..\ClientClasses\ConnectTest2.pas' {frmConnectTest2},
  ConnectTest in '..\ClientClasses\ConnectTest.pas' {frmConnectTest},
  TestServer in '..\ClientClasses\TestServer.pas' {frmTestServer},
  DM301 in '..\ClientClasses\DM301.pas' {dmIssue301: TDataModule},
  TEST_TranMgr in '..\transactions\TEST_TranMgr.pas';

{$R *.RES}

begin
  GUITestRunner.runRegisteredTests;
end.
