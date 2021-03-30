unit DM301;

{ The purpose of this unit is to verify that issue 301 has been resolved. }

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ffdb, ffllbase, ffdbbase;

type
  TdmIssue301 = class(TDataModule)
    ffClient1: TffClient;
    ffSession1: TffSession;
    ffDatabase1: TffDatabase;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  dmIssue301: TdmIssue301;

implementation

{$R *.DFM}

end.
