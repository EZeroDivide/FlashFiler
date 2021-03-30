{*********************************************************}
{* FlashFiler: CONTACTU.PAS                              *}
{* Copyright (c) TurboPower Software Co 1996-2000        *}
{* All rights reserved.                                  *}
{*********************************************************}
{* FlashFiler: Contact utilities                         *}
{*********************************************************}
unit contactu;

interface

uses
  FFDB,
  FFSrEng;

function GenAge : integer;
function GenBirthDate(StartDate : TDateTime; Spread : integer) : TDateTime;
function GenDecisionMaker : boolean;
function GenFirstName : string;
function GenLastName : string;
function GenState : string;

procedure InsertRandomContacts(aTable : TffTable; aCount : longInt);
  { Insert the specified number of contacts into the specified table.
    Assumes aTable has the following fields:
      ID (autoinc), FirstName, LastName, Age, DecisionMaker (boolean) }

procedure InsertRandomContactsViaCursor(aCursor : TffSrBaseCursor; aCount : longInt);
  { Use a server-side cursor to insert the specified number of contacts into
    the specified table.
    Assumes aTable has the following fields:
      ID (autoinc), FirstName, LastName, Age, DecisionMaker (boolean) }

procedure InsertRandomContactsSameAge(aTable : TffTable; anAge : integer;
                                      aCount : longInt);
  { Insert the specified number of contacts into the specified table.  Each
    contact is to have the specified age.
    Assumes aTable has the following fields:
      ID (autoinc), FirstName, LastName, Age, DecisionMaker (boolean) }

implementation

uses
  DB,
  SysUtils,
  FFLLBase,
  FFLLDict,
  ffSrLock;

{===Contact utility routines=========================================}
function GenAge : integer;
begin
  Result := 18 + Random(82);
end;
{--------}
function GenBirthDate(StartDate : TDateTime; Spread : integer) : TDateTime;
begin
  Result := StartDate + Random(Spread);
end;
{--------}
function GenDecisionMaker : boolean;
begin
  Result := (Random(100) > 80);
end;
{--------}
function GenFirstName : string;
const
  FirstNames : array[0..51] of string =
    ('Andy', 'Alice',
     'Bob', 'Brenda',
     'Charles', 'Carol',
     'Dan', 'Darla',
     'Evan', 'Eve',
     'Fred', 'Faye',
     'Gimli', 'Gloria',
     'Howard', 'Hannah',
     'Ivan', 'Ingrid',
     'Jack', 'Jill',
     'Kent', 'Klara',
     'Lysander', 'Lucilla',
     'Mike', 'Margaret',
     'Nate', 'Nancy',
     'Oliver', 'Olivia',
     'Paul', 'Penny',
     'Quinn', 'QuinnellaBrucillaLeaAnnaMaria',
     'Roger', 'Roweena',
     'Stan', 'Shannon',
     'Trent', 'Twila',
     'Unzo', 'Unza',
     'Vince', 'Violet',
     'Walter', 'Wendy',
     'Xavier', 'Julia',
     'Yik', 'Yak',
     'Zed', 'Zerta');

begin
  Result := FirstNames[Random(52)];
end;
{--------}
function GenLastName : string;
const
  LastNames : array[0..51] of string =
    ('Anvil','Aragon',
     'Bernstein','Borst',
     'Clark','Collins',
     'Dunn','Dermot',
     'Englewood','Ewing',
     'Farley','Fenwick',
     'Grace','Garman',
     'Horton','HamfordShireVilleDale',
     'Ingersoll','Isaacson',
     'Jenkinis','Jose',
     'Knoche','Kowal',
     'Lowery','Lunsford',
     'Makarevich','McCaughey',
     'Nelson','Newkirk',
     'Olsen','Owens',
     'Palmerton','Pierson',
     'Quade','Quick',
     'Redding','Reves',
     'Segura','Scroggins',
     'Toomey','Tucker',
     'Undine','Uhrin',
     'Vanvreede','Vollrath',
     'Walsh','Wallin',
     'Xatkoun','Xavier',
     'Yager','Young',
     'Zapor','Zimla');
begin
  Result := LastNames[Random(52)];
end;
{--------}
function GenState : string;
begin
  { Assumption: We don't need no valid state. }
  Result := char(65 + random(26)) + char(65 + random(26));
end;
{--------}
procedure InsertRandomContacts(aTable : TffTable; aCount : longInt);
const
  RecsPerTran = 1000;
var
  Index : longInt;
  fldFirstName : TField;
  fldLastName : TField;
  fldAge : TField;
  fldState : TField;
  fldDecisionMaker : TField;
  fldBDate : TField;
begin

  { Assumptions: Using contact table as defined in testCursor.pas and
                 testDBThread.pas }

  with aTable do begin
    fldFirstName := FieldByName('FirstName');
    fldLastName := FieldByName('LastName');
    fldAge := FieldByName('age');
    fldState := FieldByName('State');
    fldDecisionMaker := FieldByName('DecisionMaker');
    fldBDate := FieldByName('BirthDate');
  end;

  { Start a transaction. }
  aTable.Database.StartTransaction;

  try

    { Start inserting records. }
    for Index := 1 to aCount do begin
      with aTable do begin
        Insert;
        fldFirstName.asString := genFirstName;
        fldLastName.asString := genLastName;
        fldAge.asInteger := genAge;
          { Okay, so the age is going to be a little off compared to the
            birth date... }
        fldState.asString := genState;
        fldDecisionMaker.asBoolean := genDecisionMaker;
        fldBDate.asDateTime := genBirthDate(StrToDateTime('1/1/60'), 365 * 20);
        Post;
      end;
      if Index mod RecsPerTran = 0 then begin
        aTable.Database.Commit;
        aTable.Database.StartTransaction;
      end;
    end;

    if aTable.Database.InTransaction then
      aTable.Database.Commit;
  except
    on E:Exception do begin
      { Commit what we have inserted so far. }
      aTable.Database.Commit;
      raise;
    end;
  end;

end;
{--------}
procedure InsertRandomContactsViaCursor(aCursor : TffSrBaseCursor; aCount : longInt);
var
  aRecord : PffByteArray;
  Dict : TffDataDictionary;
  Index : longInt;
  fldFirstName : string[25];
  fldLastName : string[25];
  fldAge : integer;
  fldState : string[2];
  fldDecisionMaker : boolean;
begin

  { Assumptions: Using contact table as defined in testCursor.pas and
                 testDBThread.pas }

  { Obtain a buffer to hold the record. }
  Dict := aCursor.Dictionary;
  FFGetMem(aRecord, Dict.RecordLength);

  { Start inserting records. }
  for Index := 1 to aCount do begin
    FillChar(aRecord^, Dict.RecordLength, 0);
      { Make sure buffer is zeroed out so that autoincrement field doesn't
        appear to be filled. }
    fldFirstName := genFirstName;
    fldFirstName := fldFirstName + StringOfChar(' ', 25 - length(fldFirstName));
    fldLastName := genLastName;
    fldLastName := fldLastName + StringOfChar(' ', 25 - length(fldLastName));
    fldAge := genAge;
    fldState := genState;
    fldDecisionMaker := genDecisionMaker;
    Dict.SetRecordField(1, aRecord, @fldFirstName[0]);
    Dict.SetRecordField(2, aRecord, @fldLastName[0]);
    Dict.SetRecordField(3, aRecord, @fldAge);
    Dict.SetRecordField(4, aRecord, @fldState[0]);
    Dict.SetRecordField(5, aRecord, @fldDecisionMaker);
    { Skip birthDate field since I don't want to code the transformation of
      a TDateTime into the right format. }
    aCursor.InsertRecord(aRecord, ffsltExclusive);
  end;

end;
{--------}
procedure InsertRandomContactsSameAge(aTable : TffTable; anAge : integer;
                                      aCount : longInt);
const
  RecsPerTran = 1000;
var
  Index : longInt;
  fldFirstName : TField;
  fldLastName : TField;
  fldAge : TField;
  fldState : TField;
  fldDecisionMaker : TField;
begin

  { Assumptions: Using contact table as defined in testCursor.pas and
                 testDBThread.pas }

  with aTable do begin
    fldFirstName := FieldByName('FirstName');
    fldLastName := FieldByName('LastName');
    fldAge := FieldByName('age');
    fldState := FieldByName('State');
    fldDecisionMaker := FieldByName('DecisionMaker');
  end;

  { Start a transaction. }
  aTable.Database.StartTransaction;

  try

    { Start inserting records. }
    for Index := 1 to aCount do begin
      with aTable do begin
        Insert;
        fldFirstName.asString := genFirstName;
        fldLastName.asString := genLastName;
        fldAge.asInteger := anAge;
        fldState.asString := genState;
        fldDecisionMaker.asBoolean := genDecisionMaker;
        Post;
      end;
      if Index mod RecsPerTran = 0 then begin
        aTable.Database.Commit;
        aTable.Database.StartTransaction;
      end;
    end;

    if aTable.Database.InTransaction then
      aTable.Database.Commit;
  except
    on E:Exception do begin
      { Commit what we have inserted so far. }
      aTable.Database.Commit;
      raise;
    end;
  end;

end;
{====================================================================}

end.
