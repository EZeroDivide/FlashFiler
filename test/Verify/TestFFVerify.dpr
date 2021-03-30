program TestFFVerify;

uses
  Forms,
  GUITestRunner in '..\..\..\dunit\src\GUITestRunner.pas' {GUITestRunner},
  TestFramework in '..\..\..\dunit\src\TestFramework.pas',
  TestVerify in 'TestVerify.pas',
  uProgressW in '..\..\..\test\uProgressW.pas' {dlgProgress},
  ffrepair in '..\..\Verify\ffrepair.pas',
  ffFileInt in '..\..\Verify\ffFileInt.pas',
  ffrepcnst in '..\..\Verify\ffrepcnst.pas',
  ffv2file in '..\..\Verify\ffv2file.pas';

{$R *.RES}

begin
  GUITestRunner.runRegisteredTests;
end.
