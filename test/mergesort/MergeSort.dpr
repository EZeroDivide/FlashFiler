program MergeSort;

uses
  Forms,
  main in 'main.pas' {frmMain},
  contactu in '..\util\contactu.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
