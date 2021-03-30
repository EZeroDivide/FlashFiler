program TextTest;

{$APPTYPE CONSOLE}
uses
  Forms,
  baseTestCase in '..\util\baseTestCase.pas',
  uTestCfg in 'uTestCfg.pas' {frmClientTestConfig},
  uClTBase in 'uClTBase.pas',
  uClTest in 'uClTest.pas',
  contactu in '..\util\contactu.pas',
  TextTestRunner in '..\DUnit\src\TextTestRunner.pas',
  TestFramework in '..\DUnit\src\TestFramework.pas';

{$R *.RES}

begin
  TextTestRunner.RunRegisteredTests(rxbHaltOnFailures);

end.
