unit fFilterProperties;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls,  usqltesttypes;

type
  TfrmFilterProperties = class(TForm)
    lblFilterString: TLabel;
    edtFilterString: TEdit;
    edtFiltered: TCheckBox;
    lblEval: TLabel;
    edtEval: TComboBox;
    edtCaseInsensitive: TCheckBox;
    edtNoPartialCompare: TCheckBox;
    edtResync: TCheckBox;
    lblTimeout: TLabel;
    edtTimeout: TEdit;
    btnOK: TButton;
    btnCancel: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
  public
    FilterProps : TsqtFilterProperties;
    procedure UpdateProps;
    procedure SaveProps;
  end;

var
  frmFilterProperties: TfrmFilterProperties;

function EditFilterProperties(var aProps: TsqtFilterProperties) : Boolean;

implementation

{$R *.DFM}

function EditFilterProperties(var aProps: TsqtFilterProperties) : Boolean;
var
  Frm : TfrmFilterProperties;
begin
  Result := False;
  Frm := TfrmFilterProperties.Create(nil);
  try
    Frm.FilterProps := aProps;
    if Frm.ShowModal = mrOK then begin
      Result := True;
      aProps := Frm.FilterProps;
    end;
  finally
    Frm.Free;
  end;
end;

{ TfrmFilterProperties }

procedure TfrmFilterProperties.btnOKClick(Sender: TObject);
begin
  SaveProps;
  ModalResult := mrOK;
end;

procedure TfrmFilterProperties.FormCreate(Sender: TObject);
begin
  InitFilterProperties(FilterProps);
end;

procedure TfrmFilterProperties.SaveProps;
begin
  FilterProps.Filter := edtFilterString.Text;
  FilterProps.Filtered := edtFiltered.Checked;
  FilterProps.FilterEvalServer := edtEval.ItemIndex = 0;
  FilterProps.FilterOptionCaseInsensitive := edtCaseInSensitive.Checked;
  FilterProps.FilterOptionNoPartialCompare := edtNoPartialCompare.Checked;
  FilterProps.FilterResync := edtResync.Checked;
  try
    FilterProps.FilterTimeout := StrToInt('0' + edtTimeout.Text);
  except
    FilterPRops.FilterTimeout := 10000;
  end;
end;

procedure TfrmFilterProperties.UpdateProps;
begin
  edtFilterString.Text := FilterProps.Filter;
  edtFiltered.Checked := FilterProps.Filtered;
  if FilterProps.FilterEvalServer then
    edtEval.ItemIndex := 0
  else
    edtEval.ItemIndex := 1;
  edtCaseInSensitive.Checked := FilterProps.FilterOptionCaseInsensitive;
  edtNoPartialCompare.Checked := FilterProps.FilterOptionNoPartialCompare;
  edtResync.Checked := FilterProps.FilterResync;
  try
    edtTimeout.Text := IntToStr(FilterProps.FilterTimeout);
  except
    FilterPRops.FilterTimeout := 10000;
  end;

end;

end.
