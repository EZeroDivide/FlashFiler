unit testMemPool;

interface

uses
  TestFramework,
  ffllbase;

type
  PffLongInt = ^LongInt;
  
  TffMemPoolTest = class(TTestCase)
  protected
    { No setup or teardown necessary as FFLLBASE initialization will create
      the required memory pools. }
//    procedure Setup; override;
//    procedure Teardown; override;
    function calcBlockCount(const ItemsInBlock, numItems : integer) : integer;
    function calcBlockIndex(const BlockCount, ItemsInBlock,
                                  thisItemIndex : integer) : integer;
    function calcItemCount(const ItemSize, ItemsInBlock : integer) : integer;
    function calcItemSize(const Index : integer) : integer;
      { Calculate the expected item size of a pool.  Index is the index of
        the memory pool, with valid values being in the range 0..MaxPool. }
    function calcUsageCount(const ItemsInBlock, numItems : integer) : integer;
  public
    procedure testAllocNItems(const MaxItems : integer); virtual;
      { Verify that N items are allocated & disposed properly. }

  published
    procedure testInitialStats; virtual;
      { Test the block size, item size, and item count of each memory pool
        after it is initially created. }

    procedure testAlloc1Item; virtual;
      { Verify that one item is allocated properly. }

    procedure testAlloc5Items; virtual;
      { Verify that 5 items are allocated & disposed properly. }

    procedure testAlloc100Items; virtual;

    procedure testAlloc4096Items; virtual;

    procedure testRemoveUnused; virtual;
      { Verify that unused blocks are removed. }

  end;

const
  MaxPool = 91;
    {-The highest pool number to use. }

implementation

uses
  SysUtils;

const
  ItemsInBlock = 1024;

{===TffMemPoolTest===================================================}
function TffMemPoolTest.calcBlockCount(const ItemsInBlock, numItems : integer) : integer;
var
  adjustment : integer;
begin

  if numItems <= ItemsInBlock then begin
    Result := 1;
    exit;
  end;

  if (numItems mod ItemsInBlock) > 0 then
    adjustment := 1
  else
    adjustment := 0;

  Result := (numItems div ItemsInBlock) + adjustment;
end;
{--------}
function TffMemPoolTest.calcBlockIndex(const BlockCount, ItemsInBlock,
                                             thisItemIndex : integer) : integer;
var
  BlockLocation : integer;
begin

  { Assumption: thisItemIndex is base 1 }

  { Calculate the location of the item?  In other words, which block should it
    be in? }
  if (thisItemIndex <= ItemsInBlock) then
    Result := pred(BlockCount)
  else begin
    BlockLocation := thisItemIndex div ItemsInBlock;
    if (thisItemIndex mod ItemsInBlock) > 0 then
      inc(BlockLocation);
    Result := BlockCount - BlockLocation;
  end;

end;
{--------}
function TffMemPoolTest.calcItemCount(const ItemSize, ItemsInBlock : integer) : integer;
const
  MaxBlockSize = (64 * 1024) + (sizeof(TffMemBlockInfo) * 2);
var
  RealItemSize : integer;
  TestSize : integer;
  TmpItemsInBlock : integer;
begin
  TmpItemsInBlock := ItemsInBlock;
  RealItemSize := ItemSize + sizeOf(Word);
  TestSize := (RealItemSize * TmpItemsInBlock) + sizeof(TffMemBlockInfo);
  if (TestSize > MaxBlockSize) then
    TmpItemsInBlock := (MaxBlockSize - sizeof(TffMemBlockInfo)) div RealItemSize;
  Result := TmpItemsInBlock;
end;
{--------}
function TffMemPoolTest.calcItemSize(const Index : integer) : integer;
begin
  { Calculate the size of each item in the block. }
  if (Index <= 31) then
    Result := succ(Index) * 32
  else
    Result := 1024 + ((Index - 31) * 256);
end;
{--------}
function TffMemPoolTest.calcUsageCount(const ItemsInBlock, numItems : integer) : integer;
begin
 if numItems <= ItemsInBlock then
   Result := numItems
 else if (numItems mod ItemsInBlock) = 0 then
   Result := ItemsInBlock
 else
   Result := (numItems mod ItemsInBlock);
end;
{--------}
procedure TffMemPoolTest.testInitialStats;
var
  Index : integer;
  ItemCount : integer;
  ItemSize : integer;
  Pool : TffMemoryPool;
begin
  { Test each memory pool created by FFLLBASE. }
  for Index := 0 to MaxPool do begin

    { Get the expected item size & count. }
    ItemSize := calcItemSize(Index);
    ItemCount := calcItemCount(ItemSize, ItemsInBlock);

    { Create the memory pool. }
    Pool := TffMemoryPool.Create(ItemSize, ItemsInBlock);

    { Verify the initial block count is zero. }
    CheckEquals(0, Pool.BlockCount,
                 format('Invalid Block Count, Pool %d', [Index]));

    { Verify the item size and item count. }
    CheckEquals(ItemSize, Pool.ItemSize,
                 format('Invalid Item Size, Pool %d', [Index]));

    CheckEquals(ItemCount, Pool.ItemsInBlock,
                 format('Invalid ItemsInBlock, Pool %d', [Index]));

    { Free the memory pool. }
    Pool.Free;
  end;


end;
{--------}
procedure TffMemPoolTest.testAlloc1Item;
begin
  testAllocNItems(1);
end;
{--------}
procedure TffMemPoolTest.testAlloc5Items;
begin
  testAllocNItems(5);
end;
{--------}
procedure TffMemPoolTest.testAlloc100Items;
begin
  testAllocNItems(100);
end;
{--------}
procedure TffMemPoolTest.testAlloc4096Items;
begin
  testAllocNItems(4096);
end;
{--------}
procedure TffMemPoolTest.testAllocNItems(const MaxItems : integer);
var
  BlockCount : integer;
  BlockIndex : integer;
  Index : integer;
  ItemIndex : integer;
  Items : array of pointer;
  ItemSize : integer;
  Pool : TffMemoryPool;
  UsageCount : integer;
begin

  Pool := nil;
  BlockCount := 0;

  { Allocate space for the array. }
  SetLength(Items, MaxItems);

  { Test each memory pool created by FFLLBASE. }
  for Index := 0 to MaxPool do begin
    { Calculate the ItemSize. }
    ItemSize := calcItemSize(Index);

    try

      { Create the memory pool. }
      Pool := TffMemoryPool.Create(ItemSize, ItemsInBlock);

      { Allocate the items. }
      for ItemIndex := 0 to pred(MaxItems) do begin

        Items[ItemIndex] := Pool.Alloc;

        { Calculate expected block count. }
        BlockCount := calcBlockCount(Pool.ItemsInBlock, succ(ItemIndex));

        { Verify the # of blocks. }
        CheckEquals(BlockCount, Pool.BlockCount,
                     format('Invalid block count, Pool %d, item %d',
                            [Index, ItemIndex]));

        { Verify the usage count of the first block. }
        UsageCount := calcUsageCount(Pool.ItemsInBlock, succ(ItemIndex));
        CheckEquals(UsageCount, Pool.BlockUsageCount(0),
                     format('Invalid block usage count, Pool %d, item %d',
                            [Index, ItemIndex]));
      end;

      { Deallocate the items. }
      for ItemIndex := pred(MaxItems) downto 0 do begin

        { Calculate expected block count. }
        { Since blocks are not freed, we will retain the highest block count
          as returned by the previous FOR loop. }

        { Deallocate the item. }
        Pool.Dispose(Items[ItemIndex]);

        { Verify the # of blocks. }
        CheckEquals(BlockCount, Pool.BlockCount,
                     format('Invalid final block count, Pool %d, item %d',
                            [Index, ItemIndex]));

        { Verify the usage count of the block. }
        UsageCount := calcUsageCount(Pool.ItemsInBlock, ItemIndex);
        BlockIndex := calcBlockIndex(BlockCount, Pool.ItemsInBlock, ItemIndex);
        CheckEquals(UsageCount, Pool.BlockUsageCount(BlockIndex),
                     format('Invalid final block usage count, Pool %d, item %d',
                            [Index, ItemIndex]));

      end;

    finally

      { Free the pool. }
      Pool.Free;

    end;

  end;
end;
{--------}
procedure TffMemPoolTest.testRemoveUnused;
var
  Pool : TffMemoryPool;
  Index : integer;
  Items : array[0..99] of pointer;
begin

  { Create a pool for 32k items. }
  Pool := TffMemoryPool.Create(64 * 1024, 1024);

  { Allocate 100 items. }
  for Index := 0 to 99 do
    Items[Index] := Pool.Alloc;

  { Verify block count. }
  CheckEquals(100, Pool.BlockCount, 'Block count failure');

  { Dispose of every other item. }
  Index := 0;
  while Index <= 99 do begin
    Pool.Dispose(Items[Index]);
    inc(Index,2);
  end;

  { Tell pool to remove excess blocks. }
  Pool.RemoveUnusedBlocks;

  { Verify block count. }
  CheckEquals(50, Pool.BlockCount, 'Final block count failure');

  { Free the pool. }
  Pool.Free;

end;
{====================================================================}

initialization

  RegisterTest('Memory pool tests', TffMemPoolTest.Suite);

end.
