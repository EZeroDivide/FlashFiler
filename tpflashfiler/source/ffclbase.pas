{*********************************************************}
{* FlashFiler: Client base unit                          *}
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

unit ffclbase;

interface

uses
  ffsrbde,
  ffllexcp,
  ffllbase,
  ffllprot,
  ffsrmgr;

{$R ffclcnst.res}

{$I ffclcfg.inc}

var
  ffStrResClient : TffStringResource;

function GetErrorStringPrim(aResult : TffResult; aStrZ : PAnsiChar) : TffResult; overload;
function GetErrorStringPrim(aResult : TffResult): String; overload;

(*
resourcestring

  SDupItemInColl = 'Duplicate item in collection';
  SInvalidParameter = 'Invalid Parameter';
  SREG_PRODUCT = '\Software\TurboPower\FlashFiler\2.0';
  *)
  (*
  SImport_NoSchemaFile = 'Schema file %s not found';
  SImport_RECLENGTHRequired = 'RECLENGTH required in schema file for this import filetype';
  SImport_NoMatchingFields = 'No import fields match any target table fields; nothing to import';
  SImport_FILETYPEMissing = 'FILETYPE missing in schema file';
  SImport_FILETYPEInvalid = 'Invalid FILETYPE in schema file';
  SImport_BadFieldName = 'Error in schema file: %s has invalid fieldname %s';
  SImport_BadFieldType = 'Error in schema file: %s has invalid datatype %s';
  SImport_BadFloatSize = 'Error in schema file: %s has invalid field size for FLOAT';
  SImport_BadIntegerSize = 'Error in schema file: %s has invalid field size for INTEGER';
  SImport_BadUIntegerSize = 'Error in schema file: %s has invalid field size for UINTEGER';
  SImport_BadAutoIncSize = 'Error in schema file: %s has invalid field size for AUTOINC';
  SImport_NoFields = 'No fields defined in schema file';
  SImport_BadOffset = 'Error in schema file: %s has invalid field offset %s';
  SImport_BadSize = 'Error in schema file: %s has invalid field size %s';
  SImport_BadDecPl = 'Error in schema file: %s  has invalid field decimal places %s';
  SImport_BadDateMask = 'Error in schema file: %s has invalid field date/time picture mask %s';
  SImport_BadSchemaHeader = 'Invalid section header in schema file: %s';

  SDesign_SLinkMasterSource = 'The MasterSource property of ''%s'' must be linked to a DataSource';
  SDesign_SLinkMaster = 'Unable to open the MasterSource Table';
  SDesign_SLinkDesigner = 'Field ''%s'', from the Detail Fields list, must be linked';
  *)
implementation

function GetErrorStringPrim(aResult : TffResult; aStrZ : PAnsiChar) : TffResult;
begin
  ffStrResBDE.GetASCIIZ(aResult, aStrZ, sizeof(DBIMSG));
  Result := DBIERR_NONE;
end;

function GetErrorStringPrim(aResult : TffResult): String;
begin
  Result := ffStrResBDE[aResult];
end;

initialization
  ffStrResClient := TffStringResource.Create(hInstance, 'FF_CLIENT_STRINGS');

finalization
  ffStrResClient.Free;

end.
