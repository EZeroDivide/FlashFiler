unit testTmpStore;

interface

uses
  TestFramework;

type
  TffTmpStoreTest = class(TTestCase)
  protected
    procedure Setup; override;
  published
    procedure testWriteBlock;
  end;

implementation

uses
  SysUtils,
  FFFile,
  FFLLBase,
  FFLLTemp,
  FFSRBase;

const
  ffc_20MB = 20 * 1024 * 1024;


procedure TffTmpStoretest.Setup;
begin
  inherited;
  FileProcsInitialize;
end;

procedure TffTmpStoreTest.testWriteBlock;
const
  cBlockSize = 64 * 1024;
var
  aBlock : PffBlock;
  aBlockNum : TffWord32;
  aBlockValue : Byte;
  aFile : TffBaseTempStorage;
  BlockIndex : TffWord32;
  ByteIndex : integer;
  InvalidValue : boolean;
begin

  { Create the file & obtain memory for the data block. }
  aFile := ffcTempStorageClass.Create('.\', ffc_20MB, cBlockSize);
  FFGetMem(aBlock, cBlockSize);
  aBlockValue := 1;

  try
    { Write to each block. }
    for BlockIndex := 0 to pred(aFile.BlockCount) do begin
      FillChar(aBlock^, cBlockSize, aBlockValue);
      aBlockNum := aFile.WriteBlock(aBlock);
      Assert(aBlockNum = BlockIndex,
             format('Unexpected block number %d',[aBlockNum]));
      inc(aBlockValue);
    end;

    { Now verify the values were properly written. }
    for BlockIndex := pred(aFile.BlockCount) downto 0 do begin
      dec(aBlockValue);
      aFile.ReadBlock(BlockIndex, aBlock);
      { Verify the values in the block. }
      InvalidValue := false;
      for ByteIndex := 0 to pred(cBlockSize) do
        if aBlock^[ByteIndex] <> aBlockValue then begin
          InvalidValue := True;
          break;
        end;
      Assert(not InvalidValue, format('Bad value in block %d at byte %s',
                                      [BlockIndex, ByteIndex]));
    end;
  finally
    { Destroy the file. }
    aFile.Free;

    { Free the data block. }
    FFFreeMem(aBlock, cBlockSize);
  end;

end;

initialization

  RegisterTest('Temp storage tests', TffTmpStoreTest.Suite);

end.
