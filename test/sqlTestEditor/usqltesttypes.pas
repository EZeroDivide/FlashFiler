unit usqltesttypes;

interface

uses
  db, ffdb;
type
  PsqtFilterProperties = ^TsqtFilterProperties;
  TsqtFilterProperties = packed record
    Filter : string[255];
    Filtered : Boolean;
    FilterEvalServer : Boolean;
    FilterOptionCaseInsensitive: Boolean;
    FilterOptionNoPartialCompare: Boolean;
    FilterResync : Boolean;
    FilterTimeout: Integer;
  end;

procedure InitFilterProperties(var FP : TsqtFilterProperties);
procedure SetDatasetFilter(Tbl: TDataset; FilterProp: TsqtFilterProperties);

implementation

procedure InitFilterProperties(var FP : TsqtFilterProperties);
begin
  FillChar(FP, SizeOf(FP), #0);
  FP.Filter := '';
  FP.Filtered := False;
  FP.FilterEvalServer := True;
  FP.FilterOptionCaseInsensitive := False;
  FP.FilterOptionNoPartialCompare := False;
  FP.FilterResync := True;
  FP.FilterTimeout := 500;
end;

procedure SetDatasetFilter(Tbl: TDataset; FilterProp: TsqtFilterProperties);
var
  fo : TFilterOptions;
begin
  tbl.Filter := FilterProp.Filter;
  tbl.Filtered := FilterProp.Filtered;

  if FilterProp.FilterOptionCaseInsensitive then
    Include(fo, foCaseInsensitive);
  if FilterProp.FilterOptionNoPartialCompare then
    Include(fo, foNoPartialCompare);
  tbl.FilterOptions := fo;

  if Tbl is TffDataSet then
    with Tbl as TffDataSet do begin
      if FilterProp.FilterEvalServer then
        FilterEval := ffeServer
      else
        FilterEval := ffeLocal;
      FilterResync := FilterProp.FilterResync;
      FilterTimeout := FilterProp.FilterTimeout;
    end;  { with }
end;

end.
