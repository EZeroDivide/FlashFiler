unit memLog;

interface

uses
  Classes,
  FFLLBase,
  FFLLLog;

type
  TffMemoryLog = class(TffEventLog)
  protected

    FLog : TStringList;
    FMaxLines : Integer;

    procedure elWritePrim(const LogStr : string); override;

  public
    constructor Create(aOwner : TComponent); override;
    destructor Destroy; override;

    procedure Clear;

    procedure SaveToFile;

  published

    property MaxLines : Integer
      read FMaxLines write FMaxLines default 500;
      { Maximum number of log lines to be retained in memory. }

  end;

implementation

uses
  SysUtils;

{===TffMemoryLog=====================================================}
constructor TffMemoryLog.Create(aOwner : TComponent);
begin
  inherited Create(aOwner);
  FLog := TStringList.Create;
  FMaxLines := 500;
end;
{--------}
destructor TffMemoryLog.Destroy;
begin
  FLog.Free;
  inherited Destroy;
end;
{--------}
procedure TffMemoryLog.Clear;
begin
  FLog.Clear;
end;
{--------}
procedure TffMemoryLog.elWritePrim(const LogStr : string);
begin
  if FLog.Count = FMaxLines then
    FLog.Delete(0);
  FLog.Add(LogStr);
end;
{--------}
procedure TffMemoryLog.SaveToFile;
var
  Inx : Integer;
  aStr : string;
  FileStm : TFileStream;
  LogMode : Word;
begin
  { Assumption: Log file locked for use by this thread. }

  { Check whether file exists, set flags appropriately }
//  if FileExists(FFileName) then
//    LogMode := (fmOpenReadWrite or fmShareDenyWrite)
//  else
    LogMode := (fmCreate or fmShareDenyWrite);

  { Open file, write string, close file }
  FileStm := TFileStream.Create(FFileName, LogMode);
  try
    FileStm.Seek(0, soFromEnd);
    for Inx := 0 to Pred(FLog.Count) do begin
      aStr := FLog.Strings[Inx];
      FileStm.WriteBuffer(aStr[1], Length(aStr));
    end;
  finally
    FileStm.Free;
  end;
end;
{====================================================================}

end.
