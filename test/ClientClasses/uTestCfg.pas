unit uTestCfg;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls,
  FFLLProt;

type
  TfrmClientTestConfig = class(TForm)
    pnlBottom: TPanel;
    btnOK: TButton;
    grpServerEngine: TRadioGroup;
    grpConfiguration: TGroupBox;
    edtSystemDir: TEdit;
    lblSystemDir: TLabel;
    lblProtocol: TLabel;
    edtProtocol: TComboBox;
    lblServerName: TLabel;
    edtServerName: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure grpServerEngineClick(Sender: TObject);
  protected
    function GetProtocol : TffProtocolType;
    function GetRemoteEngine : Boolean;
    function GetServerName : string;
    function GetSystemDir : string;
  public
    property Protocol : TffProtocolType
       read GetProtocol;
    property RemoteEngine : Boolean
       read GetRemoteEngine;
    property ServerName : string
       read GetServerName;
    property SystemDir : string
       read GetSystemDir;
  end;

var
  frmClientTestConfig: TfrmClientTestConfig;

implementation

{$R *.DFM}

function TfrmClientTestConfig.GetProtocol : TffProtocolType;
begin
  Result := TffProtocolType(edtProtocol.ItemIndex);
end;
{--------}
function TfrmClientTestConfig.GetRemoteEngine : Boolean;
begin
  Result := grpServerEngine.ItemIndex = 1;
end;
{--------}
function TfrmClientTestConfig.GetServerName : string;
begin
  Result := edtServerName.Text;
end;
{--------}
function TfrmClientTestConfig.GetSystemDir : string;
begin
  Result := edtSystemDir.Text;
end;
{--------}
procedure TfrmClientTestConfig.FormCreate(Sender: TObject);
begin
  grpServerEngine.ItemIndex := 0;
end;
{--------}
procedure TfrmClientTestConfig.grpServerEngineClick(Sender: TObject);
begin
  edtSystemDir.Enabled := grpServerEngine.ItemIndex = 0;
  edtServerName.Enabled := grpServerEngine.ItemIndex = 1;
  edtProtocol.Enabled := grpServerEngine.ItemIndex = 1;

  edtSystemDir.TabStop := edtSystemDir.Enabled;
  edtServerName.TabStop := edtServerName.TabStop;
  edtProtocol.TabStop := edtProtocol.TabStop;
end;

initialization
begin
  frmClientTestConfig := TfrmClientTestConfig.Create(Application);
  frmClienttestConfig.ShowModal;
end;

end.
