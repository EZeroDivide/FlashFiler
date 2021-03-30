unit fConfiguration;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TfrmConfiguration = class(TForm)
    lblArchiveLocation: TLabel;
    edtArchiveName: TEdit;
    Button1: TButton;
    dlgBrowse: TOpenDialog;
    lblServerName: TLabel;
    edtServerName: TEdit;
    lblProtocol: TLabel;
    edtProtocol: TComboBox;
    btnOK: TButton;
    btnCancel: TButton;
    procedure Button1Click(Sender: TObject);
  private
    function GetArchiveName: string;
    function GetProtocol: Integer;
    function GetServerName: string;
    procedure SetArchiveName(const Value: string);
    procedure SetProtocol(const Value: Integer);
    procedure SetServerName(const Value: string);
    { Private declarations }
  public
    property ArchiveName : string
      read GetArchiveName
      write SetArchiveName;
    property ServerName : string
      read GetServerName
      write SetServerName;
    property Protocol : Integer
      read GetProtocol
      write SetProtocol;
  end;

var
  frmConfiguration: TfrmConfiguration;

implementation

{$R *.DFM}

function TfrmConfiguration.GetArchiveName: string;
begin
  Result := edtArchiveName.Text;
end;

function TfrmConfiguration.GetProtocol: Integer;
begin
  Result := edtProtocol.ItemIndex;
end;

function TfrmConfiguration.GetServerName: string;
begin
  Result := edtServerName.Text
end;

procedure TfrmConfiguration.SetArchiveName(const Value: string);
begin
  edtArchiveName.Text := Value;
end;

procedure TfrmConfiguration.SetProtocol(const Value: Integer);
begin
  edtProtocol.ItemIndex := Value;
end;

procedure TfrmConfiguration.SetServerName(const Value: string);
begin
  edtServerName.Text := Value;
end;

procedure TfrmConfiguration.Button1Click(Sender: TObject);
begin
  dlgBrowse.FileName := edtArchiveName.Text;
  if dlgBrowse.Execute then
    edtArchiveName.Text := dlgBrowse.FileName;

end;

end.
