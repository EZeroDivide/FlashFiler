unit ExCreateDSN;

interface
uses
  ffllprot;

function CreateDSN(const aDSN: string;
                   const aProtocol : TffProtocolType;
                   const aServerName : string;
                   const aUserName : string;
                   const aPassWord : string;
                   const aAlias : string) : Boolean;

function DeleteDSN(const aDSN : string) : Boolean;

implementation
uses
  Windows, SysUtils, ffutil;
const
  ODBC_ADD_DSN = 1; // Add data source
  ODBC_CONFIG_DSN = 2; // Configure (edit) data
  ODBC_REMOVE_DSN = 3; // Remove data source
  ODBC_ADD_SYS_DSN = 4; // add a system DSN
  ODBC_CONFIG_SYS_DSN = 5; // Configure a system DSN
  ODBC_REMOVE_SYS_DSN = 6; // remove a system DSN
  ODBC_REMOVE_DEFAULT_DSN = 7; // remove the default DSN

function SQLConfigDataSource(
  hwndParent: HWND;
  fRequest: WORD;
  lpszDriver: LPCSTR;
  lpszAttributes: LPCSTR): BOOL; stdcall; external 'ODBCCP32.DLL';

function CreateDSN(const aDSN: string;
                   const aProtocol : TffProtocolType;
                   const aServerName : string;
                   const aUserName : string;
                   const aPassWord : string;
                   const aAlias : string) : Boolean;
begin
  Result := SQLConfigDataSource(0, ODBC_ADD_DSN,
                                'TurboPower FlashFiler Driver',
                                PChar('DSN=' + aDSN + #0 +
                                      'Protocol=' + FFGetProtocolString(aProtocol) + #0 +
                                      'ServerName=' + aServerName + #0 +
                                      'UserName=' + aUserName + #0 +
                                      'Password=' + aPassword + #0 +
                                      'Database=' + aAlias + #0));
end;

function DeleteDSN(const aDSN : string) : Boolean;
begin
  Result := SQLConfigDataSource(0, ODBC_REMOVE_DSN, 'TurboPower FlashFiler Driver',
                                PChar('DSN=' + aDSN + #0));

end;

end.
