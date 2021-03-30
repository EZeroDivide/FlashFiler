program transportTest;

uses
  Forms,
  main in 'main.pas' {frmMain},
  tstCmd in 'tstCmd.pas',
  tstThread in 'tstThread.pas',
  memLog in 'memLog.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
