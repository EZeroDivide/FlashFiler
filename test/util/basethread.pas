unit baseThread;

interface

uses
  classes,
  sysUtils,
  windows,
  ffllbase,
  FFLLEng;

type

  TffTestThreadMode = (ffttmSynch, ffttmAsynch);
    { ffttmSynch - The thread should run through all its steps from beginning
                   to end.  When a thread is in Synch mode, its ExecuteSynch
                   method is called UNLESS a step filter has been specified
                   in which case ExecuteStep is called.

     ffttmAsynch - The thread should run through each step as the WorkEvent
                   is signalled.  If the test has three different steps then
                   the controlling primary thread would have to signal the
                   WorkEvent 3 times in order for all steps to be completed.

                   The scope/meaning of a step is up to the whims of the
                   person writing the test thread.

                   Steps are base 1.  When a step is to be executed, the
                   thread's ExecuteStep method is called.

                   This is useful for cases where thread actions must be
                   coordinated. }

  { This class serves as the base class for threads used in the testing of
    FlashFiler 2.  Each instance of this class should be created with a
    unique name so that the actors in the test situation are easily
    identifiable.

    By default, instances of TffBaseTestThread set Self.FreeOnTerminate to
    True. }
  TffBaseTestThread = class(TThread)
  protected

    FDieEvent : TffEvent;
      { The event that, when signalled, causes the thread to die. }

    FEngine : TffBaseServerEngine;
      { The server engine through which this thread is to route
        database activity. }

    FInputParms : TStringList;
      { Input parameters specified by the parent thread. }

    FMode : TffTestThreadMode;
      { The mode of the thread (i.e., synch or asynch). }

    FName : string;
      { The thread's name. }

    FNextStep : integer;
      { For asynch mode, the next step to be executed by the thread.
        Steps are base 1 unless a filter is active in which case it
        is base 0. }

    FReady : boolean;
      { Set to True when the test thread has completed its initialization
        & is waiting for work to perform. }

    FRepeatCount : longInt;
      { The number of times the test is to be repeated.  Defaults to 1. }

    FResults : TStringList;
      { Result data recorded by the thread.  Stored as key/value pairs. }

    FStartEvent : TffEvent;
      { This event is signalled once the thread has started. }

    FStepEvent : TffEvent;
      { For asynch threads, this event is signalled once the step has
        completed. }

    FStepFilter : TList;
      { List of the steps that may be executed by the test. }

    FThreadEventHandles: Array[0..1] of THandle;
      {-When a thread is created, it pauses in its execute method until it
        receives one of two events:

        1. Wake up and do some work.
        2. Wake up and terminate.

        This array stores these two event handles. }

    FWaitAtEnd : boolean;
      { If True then thread is to wait before terminating. }

    FWorkEvent : TffEvent;
      { The event that, when signalled, notifies the thread it has work to
        do.  If the thread is in synch mode then the ExecuteSync procedure
        will be called.  If the thread is in asynch mode then the ExecuteStep
        will be called with the number of the step to be executed. }

    procedure AfterTest; virtual;
      { Called after a test is started.  Use this to initialize objects needed
        for the test. }

    procedure BeforeTest; virtual;
      { Called before a test is started.  Use this to free objects created for
        the test. }

    procedure Execute; override;
    procedure ExecuteStep(const StepNumber : integer); virtual; abstract;
    procedure ExecuteSynch; virtual; abstract;

    function GetFiltered : boolean;

    function GetInput(const key : string) : string;
      { Used to retrieve the value for a particular input parameter set via
        SetInput method. }

    function GetInputBool(const key : string) : boolean;
      { Used to retrieve a boolean value for a particular input parameter
        set via SetInputBool method. }

    function GetInputInt(const key : string) : longInt;
      { Used to retrieve an integer value for a particular input parameter set
        via SetInputInt method. }

    function GetResult(const key : string) : string;
      { Used to retrieve the value for a particular result key. }

    function GetResultBool(const key : string) : boolean;
      { Used to retrieve the value for a particular result key as a boolean
        value. }

    function GetResultInt(const key : string) : longInt;
      { Used to retrieve the value for a particular result key as an integer
        value. }

    function GetStepCount : integer; virtual; abstract;
      { Returns the number of steps for an asynch test thread.  Only called
        if the test is in asynch mode and no step filter has been specified.
        Example implementation:

        function TffMyTestThread.GetStepCount : integer;
        begin
          Result := ciNumSteps;
        end;

        where ciNumSteps is a const set equal to 3.
      }

    procedure SaveException(E: Exception;
                      const msgKey, codeKey : string);
      { Use this method to write the results of an exception to the Results
        stringlist.  MsgKey is the key value for the exception's message.
        CodeKey is the key value for the exception's error code. }

    procedure SaveResult(const key, value : string);
      { Use this method to record a result key/value pair. }

    procedure SaveResultBool(const key : string; const value : boolean);
      { Use this method to record a result key/value pair where the value
        is a boolean. }

    procedure SaveResultInt(const key : string; const value : longInt);
      { Use this method to record a result key/value pair where the value
        is an integer. }

  public
    constructor Create(const aThreadName : string;
                       const aMode : TffTestThreadMode;
                             anEngine : TffBaseServerEngine);
    destructor Destroy; override;

    procedure AddToFilter(const Steps : array of integer);
      { If an asynchronous is to include only a certain number of steps in
        its test execution, use this method to specify which steps may be
        executed.  The steps will be executed in the order they are added. }

    procedure ClearFilter;
      { Empties the current step filter (see AddToFilter above). }

    procedure ClearResults;
      { Clears the current set of results. }

    procedure NextStep;
      { Causes an Asynch thread to execute its next step. }

    procedure WaitForReady(const timeout : longInt);
      { It is possible for the primary thread to be ready prior to the test
        thread being ready.  Use this method to have the primary thread wait
        until the test thread has finished its initialization. }

    procedure WaitForStep(const timeout : longInt);
      { For asynch threads, have the primary thread call this method when it
        wants to wait for a step to finish.  This routine will exit once
        the step has been completed. }

    procedure SetInput(const key, value : string);
      { Use this method to set an input value for the thread.  For example,
        if the thread is to open a specific table then you can set an input
        parameter that tells the thread which table it is to open.

        The thread can call its GetInput method to retrieve an input value. }

    procedure SetInputBool(const key : string; const value : boolean);
      { Similar to SetInput, use this method to set a boolean input value for
        the thread.

        The thread can call its GetInputBool method to retrieve an input value. }

    procedure SetInputInt(const key : string; const value : longInt);
      { Similar to SetInput, use this method to set an integer input value for
        the thread.

        The thread can call its GetInputInt method to retrieve an input value. }

    { properties }

    property DieEvent : TffEvent read FDieEvent;
      { Signal this event if the thread is to be terminated.  The thread
        signalling this event must call TThread.Terminate beforehand. }

    property Filtered : boolean read GetFiltered;
      { If True then a step filter has been specified for the test. }

    property Mode : TffTestThreadMode read FMode;
      { Whether this thread performs its test synchronously or asynchronously. }

    property Name : string read FName;
      { Returns the thread's name. }

    property RepeatCount : longInt read FRepeatCount write FRepeatCount;
      { The number of times the test is to be repeated.  Defaults to 1. }

    property Results[const key : string] : string read GetResult;

    property ResultsBool[const key : string] : boolean read GetResultBool;

    property ResultsInt[const key : string] : longInt read GetResultInt;

    property WaitAtEnd : boolean read FWaitAtEnd write FWaitAtEnd;
      { If True then the thread is to wait for a signal from the controlling
        thread before terminating.  Otherwise, the thread will terminate
        after all steps have been completed the required number of times.
        This property is useful when the controller thread must obtain
        results from a synchronous thread.  Normally, the synchronous thread
        would do its work and then terminate.  By setting this property to
        True, the controller thread can read the results and then tell the
        thread to terminate. }

    property WorkEvent : TffEvent read FWorkEvent;
      { Signal this event when the thread is to perform work.  Synch threads
        will call their ExecuteSynch method.  Asynch threads will call
        ExecuteStep with the next step number to be executed. }
  end;


implementation

uses
  ffllExcp, ffdbBase;

{===Utility routines=================================================}
function mapBoolToStr(aBool : boolean) : string;
begin
  if aBool then
    Result := 'T'
  else
    Result := 'F';
end;
{====================================================================}

{===TffBaseTestThread================================================}
constructor TffBaseTestThread.Create(const aThreadName : string;
                                     const aMode : TffTestThreadMode;
                                           anEngine : TffBaseServerEngine);
begin
  inherited Create(True);
  FReady := False;
  FreeOnTerminate := True;
  FDieEvent := TffEvent.Create;
  FEngine := anEngine;
  FInputParms := TStringList.Create;
  FMode := aMode;
  if aThreadName = '' then
    FName := 'ThreadID ' + intToStr(getCurrentThreadID)
  else
    FName := aThreadName;
  FNextStep := 1;
  FRepeatCount := 1;
  FResults := TStringList.Create;
  FStartEvent := TffEvent.Create;
  FStepEvent := TffEvent.Create;
  FStepFilter := TList.Create;
  FWaitAtEnd := False;
  FWorkEvent := TffEvent.Create;

  FThreadEventHandles[0] := FWorkEvent.Handle;
  FThreadEventHandles[1] := FDieEvent.Handle;

  { Cause thread to start. }
  Resume;
end;
{--------}
destructor TffBaseTestThread.Destroy;
begin
  FDieEvent.Free;
  FInputParms.Free;
  FResults.Free;
  FStartEvent.Free;
  FStepEvent.Free;
  FStepFilter.Free;
  FWorkEvent.Free;
  inherited Destroy;
end;
{--------}
procedure TffBaseTestThread.AddToFilter(const Steps : array of integer);
var
  index : integer;
begin
  for index := 0 to high(Steps) do
    FStepFilter.Add(pointer(Steps[index]));
end;
{--------}
procedure TffBaseTestThread.AfterTest;
begin
  { do nothing }
end;
{--------}
procedure TffBaseTestThread.ClearFilter;
begin
  FStepFilter.Clear;
end;
{--------}
procedure TffBaseTestThread.ClearResults;
begin
  FResults.Clear;
end;
{--------}
procedure TffBaseTestThread.BeforeTest;
begin
  { do nothing }
end;
{--------}
procedure TffBaseTestThread.Execute;
var
  firstTime : boolean;
  tmpRepeat : boolean;
  WaitResult : DWORD;
begin

  firstTime := True;

  if Filtered then
    FNextStep := 0
  else
    FNextStep := 1;

  BeforeTest;

  { Indicate the thread is ready. }
  FReady := True;
  FStartEvent.SignalEvent;

  { Repeat this loop until we are terminated. }
  repeat
    { If this is our first time in the loop or we are in asynchronous mode then
      wait for a signal from the parent thread. }
    if FirstTime or (FMode = ffttmAsynch) then begin
      WaitResult := WaitForMultipleObjects(2, @FThreadEventHandles, false,
                                           ffcl_INFINITE);            {!!.06}
      FirstTime := False;
    end else
      { Make the following IF statement think we have something to do. }
      WaitResult := WAIT_OBJECT_0;

    if WaitResult = WAIT_FAILED then
      {TODO -cThreads -owinstead: Handle case where thread is unable to Wait}
    else if (WaitResult = WAIT_OBJECT_0) then begin
      { Is the thread filtered? }
      if Filtered then begin
        { Yes.  Execute the next step. }
        ExecuteStep(integer(FStepFilter.items[FNextStep]));
        inc(FNextStep);
        if (FNextStep = FStepFilter.Count) then begin
          dec(FRepeatCount);
          FNextStep := 0;
        end;
        { If we are in asynch mode then signal the step as being completed. }
        if Fmode = ffttmAsynch then begin
          FStepEvent.SignalEvent;
        end;
      end
        { No.  Is it synchronous? }
      else if (FMode = ffttmSynch) then begin
        ExecuteSynch;
        dec(FRepeatCount);
      end
      else begin
        { No.  Asynchronous & not filtered. }
        ExecuteStep(FNextStep);
        inc(FNextStep);
        if (FNextStep > GetStepCount) then begin
          dec(FRepeatCount);
          FNextStep := 1
        end;
        { If we are in asynch mode then signal the step as being completed. }
        if Fmode = ffttmAsynch then
          FStepEvent.SignalEvent;
      end;
    end else begin
      AfterTest;
      Terminate;
    end;

    TmpRepeat := (FRepeatCount > 0);

  until Terminated or (not TmpRepeat);

  if not Terminated then
    AfterTest;

  { If we are in synchronous mode then the controller thread may be waiting
    for us.  Signal an event. }
  FStepEvent.SignalEvent;

  if FWaitAtEnd then
    WaitForMultipleObjects(2, @FThreadEventHandles, false,
                           ffcl_INFINITE);              {!!.06}
end;
{--------}
function TffBaseTestThread.GetFiltered : boolean;
begin
  Result := (FStepFilter.Count > 0);
end;
{--------}
function TffBaseTestThread.GetInput(const key : string) : string;
begin
  Result := FInputParms.Values[key];
end;
{--------}
function TffBaseTestThread.GetInputBool(const key : string) : boolean;
begin
  Result := (FInputParms.Values[key] = 'T');
end;
{--------}
function TffBaseTestThread.GetInputInt(const key : string) : longInt;
var
  Code : integer;
begin
  val(FInputParms.Values[key], Result, Code);
  if Code <> 0 then
    Result := -1;
end;
{--------}
function TffBaseTestThread.GetResult(const key : string) : string;
begin
  Result := FResults.Values[key];
end;
{--------}
function TffBaseTestThread.GetResultBool(const key : string) : boolean;
begin
  Result := (FResults.Values[key] = 'T');
end;
{--------}
function TffBaseTestThread.GetResultInt(const key : string) : longInt;
var
  Code : integer;
begin
  val(FResults.Values[key], Result, Code);
  if Code <> 0 then
    Result := -1;
end;
{--------}
procedure TffBaseTestThread.SaveException(E: Exception;
                                    const msgKey, codeKey : string);
var
  Ex : EffException;
begin
  if (E is EffException) or (E is EffDatabaseError) then begin
    Ex := EffException(E);
    SaveResult(msgKey, Ex.Message);
    SaveResultInt(codeKey, Ex.ErrorCode);
  end else
    SaveResult(msgkey, E.message);
end;
{--------}
procedure TffBaseTestThread.NextStep;
begin
  FWorkEvent.SignalEvent;
end;
{--------}
procedure TffBaseTestThread.WaitForReady(const timeout : longInt);
begin
  if FReady then
    exit
  else
    FStartEvent.WaitFor(timeout);
end;
{--------}
procedure TffBaseTestThread.WaitForStep(const timeout : longInt);
begin
  FStepEvent.WaitFor(timeout);
end;
{--------}
procedure TffBaseTestThread.SaveResult(const key, value : string);
begin
  FResults.Add(key + '=' + value);
end;
{--------}
procedure TffBaseTestThread.SaveResultBool(const key : string; const value : boolean);
begin
  FResults.Add(key + '=' + mapBoolToStr(value));
end;
{--------}
procedure TffBaseTestThread.SaveResultInt(const key : string; const value : longInt);
begin
  FResults.Add(key + '=' + intToStr(value));
end;
{--------}
procedure TffBaseTestThread.SetInput(const key, value : string);
var
  index : longInt;
begin
  { Is the key already in the list?  If so then get rid of it. }
  index := FInputParms.IndexOfName(key);
  if index >= 0 then
    FInputParms.Delete(index);
  FInputParms.Add(key + '=' + value);
end;
{--------}
procedure TffBaseTestThread.SetInputBool(const key : string; const value : boolean);
begin
  SetInput(key, mapBoolToStr(value));
end;
{--------}
procedure TffBaseTestThread.SetInputInt(const key : string;
                                        const value : longInt);
begin
  SetInput(key, intToStr(value));
end;
{====================================================================}

end.
