unit utester;

{$I FFDEFINE.INC}

interface
uses
  Classes, DB, SysUtils, ffdbbase, ComCtrls, ffdb;

type
  TResultType = (rtExceptionCode, rtExceptionString, rtDataset);

  TDatasetCompare = class
  private
    FProgressBar: TProgressBar;
  protected
    FRecordNumber : Integer;
    function CompareRecord(var aResultText : string) : Boolean;
    function CompareFieldNames(Dataset1, Dataset2 : TDataset) : Boolean;
  public
    Dataset1, Dataset2 : TDataset;
    constructor Create;
    function Compare(aResultData : TStrings): Boolean;
    property ProgressBar: TProgressBar
      read FProgressBar
      write FProgressBar;

  end;

  TffRunMode = (rmVCL, rmODBC);

  TQueryTester = class(TComponent)
  protected
    FRunMode : TffRunMode;
    FCloseQuery : Boolean;
    FErrors : TStrings;
    FExceptionCode: Integer;
    FExceptionString: String;
    FExpectedResult: TResultType;
    FResultDataset: TDataset;
    FQuery: TDataset;
    FProgressBar : TProgressBar;
    FMaxSourceTableReads : Integer;
    FExecDirect : Boolean;
    FExecDirectSQL : string;
  public
    constructor Create(aOwner : TComponent); override;
    destructor Destroy; override;
  published
    property CloseQuery : Boolean
      read FCloseQuery
      write FCloseQuery default False;
      { If True then close the query after the Execute method has finished
        otherwise leave the query open. }
    property Query : TDataset
      read FQuery
      write FQuery;
    property ProgressBar: TProgressBar
      read FProgressBar
      write FProgressBar;
    property ResultDataset : TDataset
      read FResultDataset
      write FResultDataset;
    property ExceptionCode : Integer
      read FExceptionCode
      write FExceptionCode;
    property ExceptionString : string
      read FExceptionString
      write FExceptionString;
    property ExpectedResult : TResultType
      read FExpectedResult
      write FExpectedResult;
    property MaxSourceTableReads : integer
      read FMaxSourceTableReads
      write FMaxSourceTableReads
      default -1;
    property ExecDirect : Boolean
      read FExecDirect
      write FExecDirect
      default False;
    property ExecDirectSQL : string
      read FExecDirectSQL
      write FExecDirectSQL;

    property RunMode : TffRunMode
      read FRunMode
      write FRunMode;

    function Execute: Boolean;
    procedure GetErrors(aList : TStrings);
  end;


implementation

uses
{$IFDEF DCC6OrLater}
  Variants,
{$ENDIF}
  dbTables;

{=== TQueryTester ===================================================}
constructor TQueryTester.Create(aOwner: TComponent);
begin
  inherited Create(aOwner);

  FCloseQuery := False;
  FErrors := TStringList.Create;
  FProgressBar := nil;
  FMaxSourceTableReads := -1;
  FExecDirect := False;
end;
{--------}
destructor TQueryTester.Destroy;
begin
  FErrors.Free;

  inherited Destroy;
end;
{--------}
function TQueryTester.Execute: Boolean;
var
  Comp        : TDatasetCompare;
  FFExecDirect : TffQuery;
  ODBCExecDirect : TQuery;
begin
  FErrors.Clear;
  try
    try
      if FExecDirect then begin
        if FRunMode <> rmODBC then begin
          FFExecDirect := TffQuery.Create(nil);
          try
            FFExecDirect.SessionName := TffQuery(Query).SessionName;
            FFExecDirect.DatabaseName := TffQuery(Query).DatabaseName;
            FFExecDirect.SQL.Text := TffQuery(Query).SQL.Text;
            TffQuery(Query).SQL.Text := FExecDirectSQL;
            FFExecDirect.ExecSQL;
          finally
            FFExecDirect.Free
          end;
        end
        else begin
          ODBCExecDirect := TQuery.Create(nil);
          try
            ODBCExecDirect.DatabaseName := TQuery(Query).DatabaseName;
            ODBCExecDirect.SQL.Text := TQuery(Query).SQL.Text;
            TQuery(Query).SQL.Text := FExecDirectSQL;
            ODBCExecDirect.ExecSQL;
          finally
            ODBCExecDirect.Free;
          end;
        end;  { if }
        Query.Open;
      end else
        Query.Open;

      if FExpectedResult = rtDataset then begin
        ResultDataset.Open;
        Comp := TDatasetCompare.Create;
        try
          Comp.ProgressBar := ProgressBar;
          Comp.Dataset1 := Query;
          Comp.Dataset2 := ResultDataset;
          Comp.Compare(FErrors);
          if (Query is TffQuery) then
            if MaxSourceTableReads > -1 then
              if TffQuery(Query).RecordsRead > MaxSourceTableReads then
                FErrors.Add(Format('Maximum source table reads reached. %d > %d', [TffQuery(Query).RecordsRead, MaxSourceTableReads]));
        finally
          Comp.Free;
        end;
      end else begin
        if (Query is TffQuery) then

            if TffQuery(Query).RecordsRead > MaxSourceTableReads then
              FErrors.Add(Format('Maximum source table reads reached. %d > %d', [TffQuery(Query).RecordsRead, MaxSourceTableReads]));
        if ExpectedResult = rtExceptionCode then begin
          if FExceptionCode <> 0 then
            FErrors.Add(Format('Expected exception "%d" did not occur', [FExceptionCode]));
        end else begin
          if FExceptionString <> '' then
            FErrors.Add(Format('Expected exception "%s" did not occur', [FExceptionString]));
        end;
      end;  
    except
      on E:Exception do begin
        if FExpectedResult = rtDataSet then begin
          { unexpected error. Log it.}
          FErrors.Add(Format('Unexpected exception: %s' ,[E.Message]))
        end else if FExpectedResult = rtExceptionString then begin
          { Is the expected message part of the received message? }
          if Pos(ExceptionString, E.Message) = 0 then
            FErrors.Add(Format('Unexpected exception: %s Expected: %s' ,[E.Message, ExceptionString]))
        end else if FExpectedResult = rtExceptionCode then
          if E is EffDatabaseError then
            if FExceptionCode <> EffDatabaseError(E).ErrorCode then
              FErrors.Add(Format('Unexpected exception: %d Expected: %d', [EffDatabaseError(E).ErrorCode, ExceptionCode]));
      end;
    end;
    Result := FErrors.Count = 0;
  finally
    if FCloseQuery then
      Query.Close
    else if Query.Active then
      Query.First;
    if FExpectedResult = rtDataset then
      ResultDataset.Close;
  end;
end;
{--------}
procedure TQueryTester.GetErrors(aList : TStrings);
begin
  aList.BeginUpdate;
  try
    aList.Clear;
    aList.Assign(FErrors);
  finally
    aList.EndUpdate;
  end;
end;
{====================================================================}



{=== TDatasetCompare ================================================}
function TDatasetCompare.Compare(aResultData: TStrings): Boolean;
var
  S: string;
begin
  aResultData.Clear;
  Assert(Assigned(Dataset1));
  Assert(Assigned(Dataset2));
  Dataset1.First; Dataset2.First;
  FRecordNumber := 0;
  if Dataset1.RecordCount <> Dataset2.RecordCount then begin
    aResultData.Add('Record counts differ');
  end else if Dataset1.FieldCount <> Dataset2.FieldCount then begin
    aResultData.Add('Field counts differ');
  end else if not CompareFieldNames(Dataset1, Dataset2) then begin
    aResultData.Add('Field names differ');
  end else begin
    if Assigned(FProgressBar) then begin
      FProgressBar.Max := Dataset1.RecordCount;
      FProgressBar.Position := 0;
    end;
    while not Dataset1.EOF do begin
      inc(FRecordNumber);
      if Assigned(FProgressBar) then begin
        FProgressBar.Position := FRecordNumber;
        FProgressBar.Update;
      end;  
      if not CompareRecord(S) then
        aResultData.Add(S);
      Dataset1.Next; Dataset2.Next;
    end;
  end;
  Result := aResultData.Count = 0;
end;
{--------}
function TDatasetCompare.CompareFieldNames(Dataset1,
  Dataset2: TDataset): Boolean;
var
  Idx : Integer;
begin
  Result := False;
  for Idx := 0 to Pred(Dataset1.FieldCount) do begin
    if Dataset1.Fields[Idx].FieldName <> Dataset2.Fields[Idx].FieldName then
      Exit;
  end;
  Result := True;
end;

function TDatasetCompare.CompareRecord(var aResultText: string): Boolean;
var
  bInx, Idx : Integer;
begin
  aResultText := '';
  for Idx := 0 to Pred(Dataset1.FieldCount) do begin
    { If both fields have a value then compare the values. }
    if (not DataSet1.Fields[Idx].IsNull) and
       (not DataSet2.Fields[Idx].IsNull) then begin
      { If the fields are not of the same type then they may not be compared.
        Note: The FF ODBC driver returns byte array fields as strings, so
        tests containing byte array fields will fail automatically when running
        the test against the ODBC driver. }
      if VarType(DataSet1.Fields[Idx].AsVariant) <>
         VarType(DataSet2.Fields[Idx].AsVariant) then begin
        aResultText := Format('Field type %s for Query field %d does not match field type %s for Result field %d',
                              [DataSet1.Fields[Idx].ClassName, Idx,
                               DataSet2.Fields[Idx].ClassName, Idx]);
        break;
      end
      else
      { If either field is a byte array then the values must be compared
        byte by byte. }
      if VarIsArray(DataSet1.Fields[Idx].AsVariant) or
         VarIsArray(DataSet2.Fields[Idx].AsVariant) then begin
        if DataSet1.Fields[Idx].Size <> DataSet2.Fields[Idx].Size then begin
          aResultText := Format('Record %d does not match', [FRecordNumber]);
          break;
        end
        else
          for bInx := 0 to Pred(DataSet1.Fields[Idx].Size) do begin
            if DataSet1.Fields[Idx].AsVariant[bInx] <>
               DataSet2.Fields[Idx].AsVariant[bInx] then begin
              aResultText := Format('Record %d does not match', [FRecordNumber]);
              Result := False;
              Exit;
            end;  { if }
          end;  { for }
      end
      else if Dataset1.Fields[Idx].Value <>
              Dataset2.Fields[Idx].Value then begin
        { Neither field is a byte array so just compare the values. If the
          values do not match then report an error. }
        aResultText := Format('Record %d does not match', [FRecordNumber]);
        break;
      end;  { if }
    end
    else if DataSet1.Fields[Idx].IsNull and
            DataSet2.Fields[Idx].IsNull then begin
      { Do nothing. They are both null therefore equal. }
    end
    else begin
      { One but not both are null therefore they are not equal.}
      aResultText := Format('Record %d does not match', [FRecordNumber]);
      break;
    end;  { if }
  end;  { for }
  Result := (aResultText = '');
end;
{====================================================================}

constructor TDatasetCompare.Create;
begin
  FProgressBar := nil;
end;

end.
