unit main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Grids, DBGrids, Db, FFDB, FFSqlBas, FFSqlEng, FFDBBase,
  FFLLBase, ffllcomp, FFLLEng, ffsrIntm, FFSrEng, FFLLDict, fflllog;

type
  TfrmMain = class(TForm)
    qryMain: TffQuery;
    dsMain: TDataSource;
    grdMain: TDBGrid;
    pbSort: TButton;
    pbClose: TButton;
    seEngine: TffServerEngine;
    ffDB: TffDatabase;
    ffSession: TffSession;
    ffClient: TffClient;
    sqlEngine: TffSqlEngine;
    pbGenerate: TButton;
    tblContacts: TffTable;
    efCount: TEdit;
    lblTime: TLabel;
    ffLog: TffEventLog;
    memSQL: TMemo;
    pbQuery: TButton;
    lblRecs: TLabel;
    procedure pbCloseClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure pbSortClick(Sender: TObject);
    procedure pbGenerateClick(Sender: TObject);
    procedure pbQueryClick(Sender: TObject);
    procedure qryMainAfterOpen(DataSet: TDataSet);
  private
    { Private declarations }
    procedure PrepareContactTable;
  public
    { Public declarations }
  end;

function CreateContactDict : TffDataDictionary;

var
  frmMain: TfrmMain;

implementation

uses
  ContactU,
  FFSrBase,
  FFSrBDE;

{$R *.DFM}

{====================================================================}
function CreateContactDict : TffDataDictionary;
var
  FldArray : TffFieldList;
  IHFldList : TffFieldIHList;
begin

  Result := TffDataDictionary.Create(65536);
  with Result do begin

    { Add fields }
    AddField('ID', '', fftAutoInc, 0, 0, false, nil);
    AddField('FirstName', '', fftShortString, 25, 0, true, nil);
    AddField('LastName', '', fftShortString, 25, 0, true, nil);
    AddField('Age', '', fftInt16, 5, 0, false, nil);
    AddField('State', '', fftShortString, 2, 0, false, nil);
    AddField('DecisionMaker', '', fftBoolean, 0, 0, false, nil);
    AddField('BirthDate', '', fftDateTime, 0, 0, false, nil);

    { Add indexes }
    FldArray[0] := 0;
    IHFldList[0] := '';
    AddIndex('primary', '', 0, 1, FldArray, IHFldList, False, True, True);

//    FldArray[0] := 2;
//    IHFldList[0] := '';
//    AddIndex('byLastName', '', 0, 1, FldArray, IHFldList, True, True, True);

//    FldArray[0] := 1;
//    IHFldList[0] := '';
//    AddIndex('byFirstName', '', 0, 1, FldArray, IHFldList, True, True, True);

    FldArray[0] := 3;
    IHFldList[0] := '';
    AddIndex('byAge', '', 0, 1, FldArray, IHFldList, True, True, True);

//    FldArray[0] := 4;
//    IHFldList[0] := '';
//    AddIndex('byState', '', 0, 1, FldArray, IHFldList, True, True, True);

//    FldArray[0] := 1;
//    FldArray[1] := 2;
//    IHFldList[0] := '';
//    IHFldList[1] := '';
//    AddIndex('byFullName', '', 0, 2, FldArray, IHFldList, True, True, True);

//    FldArray[0] := 3;
//    FldArray[1] := 4;
//    IHFldList[0] := '';
//    IHFldList[1] := '';
//    AddIndex('byAgeState', '', 0, 2, FldArray, IHFldList, True, True, True);

//    FldArray[0] := 4;
//    FldArray[1] := 3;
//    IHFldList[0] := '';
//    IHFldList[1] := '';
//    AddIndex('byStateAge', '', 0, 2, FldArray, IHFldList, True, True, True);

//    FldArray[0] := 5;
//    IHFldList[0] := '';
//    AddIndex('byDecisionMaker', '', 0, 1, FldArray, IHFldList, True, True, True);

//    FldArray[0] := 3;
//    FldArray[1] := 4;
//    IHFldList[0] := '';
//    IHFldList[1] := '';
//    AddIndex('byAgeDecisionMaker', '', 0, 2, FldArray, IHFldList, True, True, True);

  end;

end;
{--------}
procedure TfrmMain.PrepareContactTable;
var
  Dict : TffDataDictionary;
begin
  { Make sure Contacts table exists. }
  Dict := CreateContactDict;
  try
    FFDB.CreateTable(True, 'Contacts', Dict);
  finally
    Dict.Free;
  end;
end;
{--------}
procedure TfrmMain.pbCloseClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  ffClient.Active := True;
  ffSession.Active := True;
  ffDB.AliasName := 'e:\ff2db\test';
  ffDB.Connected := True;
end;

procedure TfrmMain.pbSortClick(Sender: TObject);
const
  cNumFields = 3;
var
  aCursor : TffSrBaseCursor;
  aOrderByArray : TffOrderByArray;
  aResult : TffResult;
  FldList : TffFieldList;
  IHList : TffFieldIHList;
  StartTime, TotalTime : DWORD;
begin
  aCursor := TffSrBaseCursor(qryMain.CursorID);
  if aCursor.Dictionary.IndexCount > 0 then
    aCursor.Dictionary.RemoveIndex(0);

  { Set up the index for sorting. }
  FldList[0] := 1; { first name }
  FldList[1] := 2; { last name }
  FldList[2] := 3; { age }
  IHList[0] := '';
  IHList[1] := '';
  IHList[2] := '';
  aCursor.Dictionary.AddIndex('Sort', '', 0, cNumFields,
                              FldList, IHList, True, True, True);
  aCursor.Dictionary.BindIndexHelpers;

//  aOrderByArray[0] := ffobDescending;
  aOrderByArray[0] := ffobAscending;
  aOrderByArray[1] := ffobDescending;
  aOrderbyArray[2] := ffobAscending;
  FFSetRetry(1000000);
  StartTime := GetTickCount;
  try
    aResult := aCursor.SortRecords(FldList, aOrderByArray, cNumFields);
    if aResult <> DBIERR_NONE then
      showMessage(format('Error: %d', [aResult]));
  finally
    TotalTime := GetTickCount - StartTime;
    lblTime.Caption := format('# milliseconds: %d', [TotalTime]);
  end;
  qryMain.Refresh;
end;

procedure TfrmMain.pbGenerateClick(Sender: TObject);
begin
  if qryMain.Active then
    qryMain.Close;

  PrepareContactTable;
  tblContacts.Open;
  InsertRandomContacts(tblContacts, StrToInt(efCount.Text));
  qryMain.Open;

end;

procedure TfrmMain.pbQueryClick(Sender: TObject);
var
  Cursor : TCursor;
  StartTime, TotalTime : DWORD;
begin
  Cursor := Screen.Cursor;
  Screen.Cursor := crHourGlass;
  try
    qryMain.SQL.Assign(memSQL.Lines);
    StartTime := GetTickCount;
    try
      qryMain.Open;
    finally
      TotalTime := GetTickCount - StartTime;
      lblTime.Caption := format('# milliseconds: %d', [TotalTime]);
    end;
  finally
    Screen.Cursor := Cursor;
  end;
end;

procedure TfrmMain.qryMainAfterOpen(DataSet: TDataSet);
begin
  lblRecs.Caption := format('# Records: %d', [qryMain.RecordCount]);
end;

end.

