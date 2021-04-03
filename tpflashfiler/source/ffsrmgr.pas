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
  SysUtils,                                                            {!!.03}
  ffllbase;                                                            {!!.03}

const
  DefReportError = False;

  {id at start of binary resource; must match SRMC}
  ResID : array[0..3] of Ansichar = 'STR0';

type
  EffStringResourceError = class(Exception);

  TInt32 = Integer;

  PIndexRec = ^TIndexRec;
  TIndexRec = record
    id : TInt32;
    ofs: TInt32;
    len: TInt32;
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
    srHandle      : THandle;             {handle for TPStrings resource}
    srP           : PResourceRec;        {pointer to start of resource}
    srPadlock     : TffPadlock;                                        {!!.03}

    {internal methods}
    procedure srCloseResource;
    function srFindIdent(Ident : TInt32) : PIndexRec;
    function srGetCount : longInt;
    procedure srLock;
    procedure srLoadResource(Instance : THandle; const ResourceName : string);
    procedure srOpenResource(Instance : THandle; const ResourceName : string);
    procedure srUnLock;

    function GetAsciiZ(Ident : TInt32; Buffer : PAnsiChar; BufChars : Integer) : PAnsiChar;
  public
    constructor Create(Instance : THandle; const ResourceName: string); virtual;
    destructor Destroy; override;
    procedure ChangeResource(Instance : THandle; const ResourceName: string);

    function GetIdentAtIndex(const anIndex : longInt) : integer;

    function GetString(Ident : TInt32) : AnsiString;
    function GetStringAtIndex(const anIndex : longInt) : AnsiString;
    function GetWideString(Ident : TInt32) : String;

    // property Strings[Ident : TInt32] : AnsiString read GetString; default;
    property Strings[Ident : TInt32] : String read GetWideString; default;
    function GetWideChar(Ident : TInt32; Buffer : PWideChar; BufChars : Integer) : PWideChar;

    /// <summary> -Returns the number of strings managed by this resource. <summary>
    property Count : longInt read srGetCount;

    property ReportError : Boolean read FReportError write FReportError;
  end;

var
  ffResStrings : TffStringResource; {error strings for this unit}

implementation

{===TffStringResource================================================}
{*** TffStringResource ***}

procedure TffStringResource.ChangeResource(Instance : THandle; const ResourceName : string);
begin
  srCloseResource;
  if ResourceName <> '' then
    srOpenResource(Instance, ResourceName);
end;
{--------}
constructor TffStringResource.Create(Instance : THandle; const ResourceName : string);
begin
  inherited Create;
  srPadlock := TffPadlock.Create;
  FReportError := DefReportError;
  ChangeResource(Instance, ResourceName);
end;
{--------}
destructor TffStringResource.Destroy;
begin
  srCloseResource;
  srPadlock.Free;
  inherited Destroy;
end;
{--------}
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
{--------}
function TffStringResource.GetWideChar(Ident : TInt32;
  Buffer : PWideChar; BufChars : Integer) : PWideChar;
var
  OLen : Integer;
  P : PIndexRec;
begin
  srLock;
  try
    P := srFindIdent(Ident);
    if P = nil then
      Buffer[0] := #0

    else begin
      OLen := P^.len;
      if OLen >= BufChars then
        OLen := BufChars-1;
      WideCopy(Buffer, PWideChar(PByte(srP)+P^.ofs), OLen);
    end;
  finally
    srUnLock;
  end;

  Result := Buffer;
end;

function TffStringResource.GetWideString(Ident: TInt32): String;
var
  P : PIndexRec;
  Src : PWideChar;
  Len : Integer;
begin
  srLock;
  try
    P := srFindIdent(Ident);
    if P = nil then
      Result := ''

    else
    begin
      Src := PWideChar(PByte(srP)+P^.ofs);
      Len := P^.len;
      SetString(Result, Src, Len);
    end;
  finally
    srUnLock;
  end;
end;

{--------}
function TffStringResource.GetAsciiZ(Ident : TInt32; Buffer : PAnsiChar; BufChars : Integer) : PAnsiChar;
var
  P : PIndexRec;
  Src : PWideChar;
  Len, OLen : Integer;
begin
  srLock;
  try
    P := srFindIdent(Ident);
    if P = nil then
      OLen := 0

    else begin
      Src := PWideChar(PAnsiChar(srP)+P^.ofs);
      Len := P^.len;

      {see if entire string fits in Buffer}
      OLen :=  WideCharToMultiByte(CP_ACP, 0, Src, Len, nil, 0, nil, nil);

      while OLen >= BufChars do begin
        {reduce length to get what will fit}
        dec(Len);
        OLen :=  WideCharToMultiByte(CP_ACP, 0, Src, Len, nil, 0, nil, nil);
      end;

      {copy to buffer}
      OLen := WideCharToMultiByte(CP_ACP, 0, Src, Len, Buffer, BufChars, nil, nil)
    end;
  finally
    srUnLock;
  end;

  {null terminate the result}
  Buffer[OLen] := #0;
  Result := Buffer;
end;
{--------}
function TffStringResource.GetIdentAtIndex(const anIndex : longInt) : integer;
begin
  Result := -1;
  srLock;
  try
    if anIndex > pred(srP^.Count) then
      raise EffStringResourceError.CreateFmt(ffResStrings[6], [anIndex]);
    Result := PIndexRec(@srP^.index[anIndex])^.id;
  finally
    srUnLock;
  end;
end;
{--------}
function TffStringResource.GetString(Ident : TInt32) : Ansistring;
var
  P : PIndexRec;
  Src : PWideChar;
  Len, OLen : Integer;
begin
  srLock;
  try
    P := srFindIdent(Ident);
    if P = nil then
      Result := ''

    else
    begin
      Src := PWideChar(PByte(srP)+P^.ofs);
      Len := P^.len;
      OLen :=  WideCharToMultiByte(CP_ACP, 0, Src, Len, nil, 0, nil, nil);
      SetLength(Result, OLen);
      WideCharToMultiByte(CP_ACP, 0, Src, Len, PAnsiChar(Result), OLen, nil, nil);
    end;
  finally
    srUnLock;
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
    srUnLock;
  end;
end;
{--------}
procedure TffStringResource.srCloseResource;
begin
  while Assigned(srP) do
    srUnLock;

  if srHandle <> 0 then begin
    FreeResource(srHandle);
    srHandle := 0;
  end;
end;
{--------}
function TffStringResource.srFindIdent(Ident : TInt32) : PIndexRec;
var
  L, R, M : TInt32;
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
function TffStringResource.srGetCount : longInt;
begin
  srLock;
  try
    Result := srP^.count;
  finally
    srUnlock;
  end;
end;
{--------}
procedure TffStringResource.srLock;
begin
  srPadlock.Lock;                                                      {!!.03}
  try                                                                  {!!.03}
    srP := LockResource(srHandle);
    if not Assigned(srP) then
      raise EffStringResourceError.Create(ffResStrings[2]);
  except                                                               {!!.03}
    srPadlock.Unlock;                                                  {!!.03}
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
    srHandle := LoadResource(Instance, H);
    if srHandle = 0 then
      raise EffStringResourceError.CreateFmt(ffResStrings[4], [ResourceName]);
  end;
end;
{--------}
procedure TffStringResource.srOpenResource(Instance : THandle; const ResourceName : string);
begin
  {find and load the resource}
  srLoadResource(Instance, ResourceName);

  {confirm it's in the correct format}
  srLock;
  try
    if srP^.id <> ResId then
      raise EffStringResourceError.Create(ffResStrings[5]);
  finally
    srUnLock;
  end;
end;
{--------}
procedure TffStringResource.srUnLock;
begin
  try                                                                  {!!.03}
    if not UnLockResource(srHandle) then
      srP := nil;
  finally                                                              {!!.03}
    srPadlock.Unlock;                                                  {!!.03}
  end;                                                                 {!!.03}
end;

{====================================================================}

initialization
  ffResStrings := TffStringResource.Create(HInstance, 'FFSRMGR_STRINGS');

finalization
  ffResStrings.Free;

end.
