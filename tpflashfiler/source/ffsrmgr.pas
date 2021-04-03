{*********************************************************}
{* FlashFiler: String resource manager                   *}
{*********************************************************}

(* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is TurboPower FlashFiler
 *
 * The Initial Developer of the Original Code is
 * TurboPower Software
 *
 * Portions created by the Initial Developer are Copyright (C) 1996-2002
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * ***** END LICENSE BLOCK ***** *)

{$I ffdefine.inc}

{include the resource compiled using BRCC32.EXE and SRMC.EXE}
{$R ffsrmgr.res}

unit ffsrmgr;

interface

uses
  Windows,
  Classes,
  SysUtils,
  ffllbase;

const
  DefReportError = False;

  {id at start of binary resource; must match SRMC}
  ResID : array[0..3] of Ansichar = 'STR0';

type
  EffStringResourceError = class(Exception);

  PIndexRec = ^TIndexRec;
  TIndexRec = record
    id : Integer;
    ofs: Integer;
    len: Integer;
  end;
  TIndexArray = array[0..(MaxInt div SizeOf(TIndexRec))-2] of TIndexRec;

  PResourceRec = ^TResourceRec;
  TResourceRec = packed record
    id : array[0..3] of AnsiChar;
    count : LongInt;
    index : TIndexArray;
  end;

  TffStringResource = class
  private
    {property variables}
    FReportError  : Boolean;             {true to raise exception if string not found}

    {internal variables}
    FHandle      : THandle;             {handle for TPStrings resource}
    srP          : PResourceRec;        {pointer to start of resource}
    FPadlock     : TffPadlock;                                        {!!.03}

    {internal methods}
    procedure CloseResource;
    function FindIdent(Ident : Integer) : PIndexRec;
    function GetCount : Longint;
    procedure srLock;
    procedure srLoadResource(Instance : THandle; const ResourceName : string);
    procedure OpenResource(Instance : THandle; const ResourceName : string);
    procedure UnLock;

    function GetStringAtIndex(const anIndex : longInt) : AnsiString;
    function GetString(Ident : Integer) : String;
  public
    constructor Create(Instance : THandle; const ResourceName: string); virtual;
    destructor Destroy; override;
    procedure ChangeResource(Instance : THandle; const ResourceName: string);

    function GetIdentAtIndex(const anIndex : longInt) : integer;

    property Strings[Ident : Integer] : String read GetString; default;

    /// <summary> Returns the number of strings managed by this resource. <summary>
    property Count : Longint read GetCount;

    property ReportError : Boolean read FReportError write FReportError;
  end;

var
  ffResStrings : TffStringResource; {error strings for this unit}

implementation

{===TffStringResource================================================}
{*** TffStringResource ***}

procedure TffStringResource.ChangeResource(Instance : THandle; const ResourceName : string);
begin
  CloseResource;
  if ResourceName <> '' then
    OpenResource(Instance, ResourceName);
end;
{--------}
constructor TffStringResource.Create(Instance : THandle; const ResourceName : string);
begin
  inherited Create;
  FPadlock := TffPadlock.Create;
  FReportError := DefReportError;
  ChangeResource(Instance, ResourceName);
end;
{--------}
destructor TffStringResource.Destroy;
begin
  CloseResource;
  FPadlock.Free;
  inherited Destroy;
end;
{--------
procedure WideCopy(Dest, Src : PWideChar; Len : Integer);
begin
  while Len > 0 do begin
    Dest^ := Src^;
    inc(Dest);
    inc(Src);
    dec(Len);
  end;
  Dest^ := #0;
end;
--------}
function TffStringResource.GetString(Ident: Integer): String;
var
  P : PIndexRec;
  Src : PWideChar;
  Len : Integer;
begin
  srLock;
  try
    P := FindIdent(Ident);
    if P = nil then
      Result := ''

    else
    begin
      Src := PWideChar(PByte(srP)+P^.ofs);
      Len := P^.len;
      SetString(Result, Src, Len);
    end;
  finally
    UnLock;
  end;
end;

{--------}
function TffStringResource.GetIdentAtIndex(const anIndex : longInt) : integer;
begin
  srLock;
  try
    if anIndex > pred(srP^.Count) then
      raise EffStringResourceError.CreateFmt(ffResStrings[6], [anIndex]);
    Result := PIndexRec(@srP^.index[anIndex])^.id;
  finally
    UnLock;
  end;
end;
{--------}
function TffStringResource.GetStringAtIndex(const anIndex : longInt) : Ansistring;
var
  P : PIndexRec;
  Src : PWideChar;
  Len, OLen : Integer;
begin
  srLock;
  try
    if anIndex > pred(srP^.Count) then
      raise EffStringResourceError.CreateFmt(ffResStrings[6], [anIndex]);

    P := @srP^.index[anIndex];
    if P = nil then
      Result := ''

    else begin
      Src := PWideChar(PByte(srP)+P^.ofs);
      Len := P^.len;
      OLen :=  WideCharToMultiByte(CP_ACP, 0, Src, Len, nil, 0, nil, nil);
      SetLength(Result, OLen);
      WideCharToMultiByte(CP_ACP, 0, Src, Len, PAnsiChar(Result), OLen, nil, nil);
    end;
  finally
    UnLock;
  end;
end;
{--------}
procedure TffStringResource.CloseResource;
begin
  while Assigned(srP) do
    UnLock;

  if FHandle <> 0 then begin
    FreeResource(FHandle);
    FHandle := 0;
  end;
end;
{--------}
function TffStringResource.FindIdent(Ident : Integer) : PIndexRec;
var
  L, R, M : Integer;
begin
  Assert(srP <> nil, 'Lock not obtained on string resource');
  {binary search to find matching index record}
  L := 0;
  R := srP^.count-1;
  while L <= R do begin
    M := (L+R) shr 1;
    Result := @srP^.index[M];
    if Ident = Result^.id then
      exit;
    if Ident > Result^.id then
      L := M+1
    else
      R := M-1;
  end;

  {not found}
  Result := nil;
  if FReportError then
    raise EffStringResourceError.CreateFmt(ffResStrings[1], [Ident]);
end;
{--------}
function TffStringResource.GetCount : longInt;
begin
  srLock;
  try
    Result := srP^.count;
  finally
    UnLock;
  end;
end;
{--------}
procedure TffStringResource.srLock;
begin
  FPadlock.Lock;                                                      {!!.03}
  try                                                                  {!!.03}
    srP := LockResource(FHandle);
    if not Assigned(srP) then
      raise EffStringResourceError.Create(ffResStrings[2]);
  except                                                               {!!.03}
    FPadlock.Unlock;                                                  {!!.03}
    raise;                                                             {!!.03}
  end;                                                                 {!!.03}
end;
{--------}
procedure TffStringResource.srLoadResource(Instance : THandle; const ResourceName : string);
var
  H : THandle;
  Buf : array[0..255] of Char;
begin
  StrPLCopy(Buf, ResourceName, SizeOf(Buf)-1);
  {$IFDEF UsesCustomDataSet}
  Instance := FindResourceHInstance(Instance);
  {$ENDIF}
  H := FindResource(Instance, Buf, RT_RCDATA);
  if H = 0 then begin
    raise EffStringResourceError.CreateFmt(ffResStrings[3], [ResourceName]);
  end else begin
    FHandle := LoadResource(Instance, H);
    if FHandle = 0 then
      raise EffStringResourceError.CreateFmt(ffResStrings[4], [ResourceName]);
  end;
end;
{--------}
procedure TffStringResource.OpenResource(Instance : THandle; const ResourceName : string);
begin
  {find and load the resource}
  srLoadResource(Instance, ResourceName);

  {confirm it's in the correct format}
  srLock;
  try
    if srP^.id <> ResId then
      raise EffStringResourceError.Create(ffResStrings[5]);
  finally
    UnLock;
  end;
end;
{--------}
procedure TffStringResource.UnLock;
begin
  try                                                                  {!!.03}
    if not UnLockResource(FHandle) then
      srP := nil;
  finally                                                              {!!.03}
    FPadlock.Unlock;                                                  {!!.03}
  end;                                                                 {!!.03}
end;

{====================================================================}

initialization
  ffResStrings := TffStringResource.Create(HInstance, 'FFSRMGR_STRINGS');

finalization
  ffResStrings.Free;

end.
