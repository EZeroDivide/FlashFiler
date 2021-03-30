unit TestVerify;

interface

uses
  Classes,
  FFFileInt,
  TestFramework;

type
  TffTestMethod = function(const Filename : string) : boolean of object;
    { Method used to perform a test on a file. }

  TffVerifyTests = class(TTestCase)
  protected
    procedure ProcessFiles(const DataDir, FileMask, LogFilename : string;
                                 Test : TffTestMethod);
    procedure Setup; override;
    procedure Teardown; override;
    function VerifyFile(const FileName : string) : Boolean;
      { Generic procedure used to verify a FF2 table. }
  published
    procedure testSimulatedFailures;
  end;

implementation

uses
  Dialogs,
  Forms,
  IniFiles,
  StSystem,
  SysUtils,
  FFRepair,
  uProgressW;

const
  csErrorCode='ErrorCode';
  csErrorCount='ErrorCount';
  csFileMask = '*.ff2';
  csFileDir = 'FileDir';
  csFixErrorCode='FixErrorCode';
  csFixCount='FixCount';
  csIni = '..\data\Verify\Verify.ini';
  csSimulated = 'Simulated';
  csTestSimulated = 'TestSimulated';

{====================================================================}
procedure TffVerifyTests.ProcessFiles(const DataDir, FileMask, LogFilename : string;
                                            Test : TffTestMethod);
var
  SR         : TSearchRec;
  FindResult : Boolean;
  FailedTest : Boolean;
  Log        : TStringList;
  FileName   : string;
  FileCount  : Integer;
  Dlg        : TDlgProgress;
begin
  Log := nil;
  FailedTest := False;
  FileCount := 0;

  FindResult := FindFirst(DataDir + FileMask, faAnyFile, SR) = 0;
  try

    Log := TStringList.Create;
    { Count the # of files in the DataDir. }
    if FindResult then
      repeat
        inc(FileCount);
      until FindNext(SR) <> 0;
    SysUtils.FindClose(SR);

    Dlg := TDlgProgress.Create(nil);
    try
      Dlg.Show;
      Application.ProcessMessages;
      FindResult := FindFirst(DataDir + FileMask, faAnyFile, SR) = 0;
      if FindResult then begin
        repeat
          { If we found a file matching the required file extension, perform
            the test on the file. }
          if AnsiCompareText(ExtractFileExt(Sr.Name),
                             ExtractFileExt(FileMask)) = 0 then begin
            {Update progressbar}
            FileName := DataDir + Sr.Name;
            Dlg.FileName := FileName;
            Dlg.Position := Dlg.Position + 1;
            Dlg.Max := FileCount;

            { Perform the test. }
            if not Test(FileName) then begin
              FailedTest := True;
              Log.Add('-----------------------------------------------');
              Log.Add('  Test failed : ' + FileName);
              Log.Add('-----------------------------------------------');
              Log.Add('');
              Log.SaveToFile(LogFilename);

              Dlg.AddError('-----------------------------------------------');
              Dlg.AddError('  Test failed : ' + FileName);
              Dlg.AddError('-----------------------------------------------');
              Dlg.AddError('');
            end;
          end;
        until FindNext(SR) <> 0;
      end else begin
        FailedTest := True;
        Log.Add('No files matching ' + FileMask + ' found');
        Exit;
      end;
    finally
      Dlg.Hide;
      Dlg.Free;
    end;
  finally
    Log.Free;
    SysUtils.FindClose(SR);
    Check(FileCount > 0, 'No files matching ' + DataDir + '\' + FileMask +
                         ' were found.');
    Check(not FailedTest, 'At least one file failed. See ' + LogFilename +
                          ' for info');
  end;
end;
{--------}
procedure TffVerifyTests.Setup;
begin
  inherited;
end;
{--------}
procedure TffVerifyTests.Teardown;
begin
  inherited;
end;
{--------}
procedure TffVerifyTests.testSimulatedFailures;
var
  Ini : TIniFile;
  FileDir,
  FileMask : string;
begin
  { Open the INI file & grab required information. }
  Ini := TIniFile.Create(csIni);
  try
    { Obtain the filemask. }
    FileMask := Ini.ReadString(csTestSimulated, csFileMask, '*.ff2');
    FileDir  := Ini.ReadString(csTestSimulated, csFileDir, '');
  finally
    Ini.Free;
  end;

  if FileDir = '' then
    Check(False, 'No file directory specified.');
  ProcessFiles(FileDir, FileMask, 'SimulatedFailures.log', VerifyFile);

end;
{--------}
function TffVerifyTests.VerifyFile(const FileName : string) : Boolean;
var
  Repair : TffRepairEngine;
  Inx,
  ErrCode,
  ErrCodeCount : Integer;
  Ini : TIniFile;
  BackupFile,
  Section : string;
begin
  Result := False;
  Repair := TffRepairEngine.Create;
  Ini := TIniFile.Create(csIni);
  { Make a backup of the file. }
  BackupFile := ChangeFileExt(FileName, '.bak');
  CheckEquals(0, CopyFile(FileName, BackupFile),
              'Could not create backup of ' + FileName);
  try
    { Verify the file. }
    Repair.Open(FileName);
    Repair.Verify;

    { Verify we received the correct errors. }
    Section := csSimulated + ExtractFileName(FileName);
    ErrCodeCount := Ini.ReadInteger(Section, csErrorCount, 0);
    CheckEquals(ErrCodeCount, Repair.ErrorCount, 'Error count mismatch.');

    for Inx := 1 to Repair.ErrorCount do begin
      ErrCode := Ini.ReadInteger(Section, csErrorCode + IntToStr(Inx), -1);
      CheckEquals(ErrCode, Repair.ErrorCodes[Inx - 1], 'Unexpected error code');
    end;  { for }

    { Repair the file. }
    Repair.Repair;

    { Verify the correct things were repaired. }
    ErrCodeCount := Ini.ReadInteger(Section, csFixCount, 0);
    CheckEquals(ErrCodeCount, Repair.FixCount, 'Fix error count mismatch.');

    for Inx := 1 to Repair.FixCount do begin
      ErrCode := Ini.ReadInteger(Section, csFixErrorCode + IntToStr(Inx), -1);
      CheckEquals(ErrCode, Repair.FixCodes[Inx - 1], 'Unexpected fix error code');
    end;  { for }

    { Verify the file again. This time there should be no errors. }
    Repair.OnReportFix := nil;
    Repair.Verify;
    CheckEquals(0, Repair.ErrorCount, 'Verify of repaired file reported errors.');
    Result := True;
  finally
    Ini.Free;
    Repair.Free;
    { Restore the backup. }
    if FileExists(FileName) then
      Check(DeleteFile(FileName), 'Could not delete file ' + FileName);
    Check(RenameFile(BackupFile, FileName),
          'Could not rename ' + BackupFile + ' to ' + FileName);
  end;
end;
{====================================================================}

initialization
  RegisterTest('Verify tests', TffVerifyTests);

end.
