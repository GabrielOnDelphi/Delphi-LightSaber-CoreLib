UNIT ccWinVersion;

{=======================================================================================================================
  CubicDesign
  2021.10.23
  See Copyright.txt

  This library provides 3 ways to get Windows version:
     Using RtlGetVersion in NtDLL.dll    Win10 ok
     Using GetVersionEx                  Win10 wrong results
     Using NetServerGetInfo              Win10 ok

  A 4th alternative proposed by u_dzOsUtils.pas (dummzeuch) is GetKernel32Version which uses GetFileVersionInfo on kernel32.dll

  ---------------------------------------------
   Windows Serv 2019       10.0
   Windows 10              10.0 *
   Windows Serv 2016       10.0
   Windows 8.1             6.3
   Windows Serv 2012 R2    6.3
   Windows 8               6.2
   Windows Serv 2012       6.2
   Windows 7               6.1  *
   Windows Serv 2008 R2    6.1
   Windows Vista           6.0
   Windows Serv 2008       6.0
   Windows XP 64-Bit       5.2  *
   Windows Serv 2003 R2    5.2
   Windows Serv 2003       5.2
   Windows XP              5.1  *
   Windows 2000            5.0
   Windows Millenium       4.9
   Windows 98              4.1
   Windows 95              4.0
   Windows NT 4.0          4.0
   Windows NT 3.51         3.51
   Windows NT 3.5          3.5
   Windows NT 3.1          3.1
  ---------------------------------------------
   https://techthoughts.info/windows-version-numbers/
  ---------------------------------------------

  Details (from dummzeuch):
   Starting with Windows 8 the GerVersionEx function is lying. Quote (    https://docs.microsoft.com/en-us/windows/desktop/api/sysinfoapi/nf-sysinfoapi-getversionexa )
     "With the release of Windows 8.1, the behavior of the GetVersionEx API has changed in the value it will return for the operating system version.
     The value returned  by the GetVersionEx function now depends on how the application is manifested.
     Applications not manifested for Windows 8.1 or Windows 10 will return the Windows 8 OS version value (6.2).
     Once an application is manifested for a given operating system version, GetVersionEx will always return the version that the application is manifested for in future releases. To manifest your applications  for Windows 8.1 or Windows 10"

   So, we can only get the correct version, if the Delphi IDE has a manifest telling Windows that it supports the version installed. This of course will not work if the Delphi version is older than the Windows version (e.g. Delphi 2007 won't know  about anything newer than Windows XP).
   Instead we now use GetFileVersionInfo on kernel32.dll.
   https://docs.microsoft.com/en-us/windows/desktop/sysinfo/getting-the-system-version

   Tester: see TestUnit function below
=======================================================================================================================}

//ToDo: add support for Win11: https://stackoverflow.com/questions/68510685/how-to-detect-windows-11-using-delphi-10-3-3

INTERFACE

USES
   WinApi.Windows, System.SysUtils;


{-------------------------------------------------------------------------------------------------------------
   Get Windows version
   All 4 functions tested on Win10 ok
-------------------------------------------------------------------------------------------------------------}
procedure GetWinVersion (OUT MajVersion, MinVersion: Cardinal);  overload;
function  GetWinVersion: string;                                 overload;
function  GetWinVersionMajor: Integer;
function  GetWinVerNetServer: string;   { Alternative to GetWinVersion }


{-------------------------------------------------------------------------------------------------------------
   Check for specific version
-------------------------------------------------------------------------------------------------------------}
function  IsWindowsXP     : Boolean;
function  IsWindowsXPUp   : Boolean;
function  IsWindowsVista  : Boolean;
function  IsWindowsVistaUp: Boolean;
function  IsWindows7      : Boolean;
function  IsWindows7Up    : Boolean;
function  IsWindows8      : Boolean;
function  IsWindows8Up    : Boolean;
function  IsWindows10     : Boolean;


{-------------------------------------------------------------------------------------------------------------
   Utils
-------------------------------------------------------------------------------------------------------------}
function  GetOSName: string;       { Returns "beautiful" name }
function  IsNTKernel : Boolean;
function  Is64Bit    : Boolean;
function  Architecture: string;
function  CheckMinWinVersion(aMajor: Integer; aMinor: Integer= 0): Boolean; deprecated 'Use directly System.SysUtils.CheckWin32Version';  { Check to see whether you are running on a specific level (or higher) of the Windows 32 bit Operating System. The Windows Operating System Major.Minor version number is compared with the passed AMajor and AMinor values. AMinor defaults to 0 if not supplied. CheckWin32Version Returns True if the Windows OS Major.Minor version number is >= the passed AMajor.AMinor value. }
function  TestUnit: string;


{-------------------------------------------------------------------------------------------------------------
   DON'T USE ON Win10:
-------------------------------------------------------------------------------------------------------------}
function  WinMajorVersion: Integer;
function  WinMinorVersion: Integer;




IMPLEMENTATION                                                                                 { Silence the: 'W1011 Text after final END' warning }
USES ccCore;



function GetOSName: string;
begin
 if IsWindows10
 then Result:= 'Windows 10'  // In Delphi XE7, TOSVersion.ToString will report Win10 as Win8. So I don't use it there.
 else Result:= TOSVersion.ToString;
end;





{-------------------------------------------------------------------------------------------------------------
   Read RTL Version directly from NTDLL
   On Win10 returns 10.0
-------------------------------------------------------------------------------------------------------------}
procedure GetWinVersion(OUT MajVersion, MinVersion: Cardinal);
TYPE
   pfnRtlGetVersion = function(var RTL_OSVERSIONINFOEXW): LONG; stdcall;
VAR
   Ver: RTL_OSVERSIONINFOEXW;
   RtlGetVersion: pfnRtlGetVersion;
begin
  MajVersion:= 0;
  MinVersion:= 0;

  @RtlGetVersion := GetProcAddress(GetModuleHandle('ntdll.dll'), 'RtlGetVersion');
  if Assigned(RtlGetVersion) then
  begin
    ZeroMemory(@ver, SizeOf(ver));
    ver.dwOSVersionInfoSize := SizeOf(ver);

    if RtlGetVersion(ver) = 0 then
     begin
      MajVersion:= ver.dwMajorVersion;
      MinVersion:= ver.dwMinorVersion;
     end;
  end;
end;


function GetWinVersionMajor: Integer;
VAR MajVersion, MinVersion: Cardinal;
begin
 GetWinVersion(MajVersion, MinVersion);
 Result:= MajVersion;
end;


function GetWinVersion: string;
var MajVersion, MinVersion: Cardinal;
begin
 GetWinVersion(MajVersion, MinVersion);
 result:= IntToStr(MajVersion)+ '.'+ IntToStr(MinVersion);
end;




{-------------------------------------------------------------------------------------------------------------
   NetServerGetInfo
   Tested: On Win10 returns 10.0
-------------------------------------------------------------------------------------------------------------}
TYPE
  NET_API_STATUS = DWORD;

  _SERVER_INFO_101 = record
    sv101_platform_id: DWORD;
    sv101_name: LPWSTR;
    sv101_version_major: DWORD;
    sv101_version_minor: DWORD;
    sv101_type: DWORD;
    sv101_comment: LPWSTR;
  end;

 SERVER_INFO_101   = _SERVER_INFO_101;
 PSERVER_INFO_101  = ^SERVER_INFO_101;
 LPSERVER_INFO_101 = PSERVER_INFO_101;

CONST
  MAJOR_VERSION_MASK = $0F;

function NetServerGetInfo(servername: LPWSTR; level: DWORD; var bufptr): NET_API_STATUS; stdcall; external 'Netapi32.dll';
function NetApiBufferFree(Buffer: LPVOID): NET_API_STATUS; stdcall; external 'Netapi32.dll';


function GetWinVerNetServer: string;
VAR
   Buffer: PSERVER_INFO_101;
begin
  Buffer:= NIL;
  if NetServerGetInfo(nil, 101, Buffer) = NO_ERROR then
  TRY
    Result:= Format('%d.%d', [Buffer.sv101_version_major and MAJOR_VERSION_MASK, Buffer.sv101_version_minor]);
  FINALLY
    NetApiBufferFree(Buffer);
  END;
end;










{-------------------------------------------------------------------------------------------------------------
   UTILS
-------------------------------------------------------------------------------------------------------------}
{ Check to see whether you are running on a specific level (or higher) of the Windows 32 bit Operating System.
  The Windows Operating System Major.Minor version number is compared with the passed AMajor and AMinor values.
  AMinor defaults to 0 if not supplied.
  Returns True if the Windows OS Major.Minor version number is >= the passed AMajor.AMinor value. }
function CheckMinWinVersion(aMajor: Integer; aMinor: Integer= 0): Boolean;
begin
 Result:= System.SysUtils.CheckWin32Version(aMajor, aMinor);  // from:    ms-help://embarcadero.rs_xe7/libraries/System.SysUtils.Win32MajorVersion.html
end;





{ Win XP }
function IsWindowsXP: Boolean;
VAR vMajor, vMinor: Cardinal;
begin
 GetWinVersion(vMajor, vMinor);
 Result:= (vMajor = 5) AND (vMinor= 1);
end;

function IsWindowsXPUp: Boolean;
VAR vMajor, vMinor: Cardinal;
begin
 GetWinVersion(vMajor, vMinor);
 Result:= (vMajor = 5) AND (vMinor= 1)
       OR (vMajor > 5);
end;



{ Win Vista }
function IsWindowsVista: Boolean;
VAR vMajor, vMinor: Cardinal;
begin
 GetWinVersion(vMajor, vMinor);
 Result:= (vMajor= 6) AND (vMinor= 0);
end;

function IsWindowsVistaUp: Boolean;
begin
 Result:= GetWinVersionMajor >= 6;
end;



{ Win 7 }
function IsWindows7: Boolean;
VAR vMajor, vMinor: Cardinal;
begin
 GetWinVersion(vMajor, vMinor);
 Result:= (vMajor= 6) AND (vMinor= 1);
end;

function IsWindows7Up: Boolean;
VAR vMajor, vMinor: Cardinal;
begin
 GetWinVersion(vMajor, vMinor);
 Result:= ((vMajor= 6) AND (vMinor>= 1))
        OR (vMajor> 6);
end;



{ Win 8 }
function IsWindows8: Boolean;
VAR vMajor, vMinor: Cardinal;
begin
 GetWinVersion(vMajor, vMinor);
 Result:= (vMajor = 6) AND (vMinor= 2);
end;

function IsWindows8Up: Boolean;
VAR vMajor, vMinor: Cardinal;
begin
 GetWinVersion(vMajor, vMinor);
 Result:= ((vMajor= 6) AND (vMinor>= 2))
        OR (vMajor> 6);
end;




{ Win 10 }
function IsWindows10: Boolean;
begin
 Result:= GetWinVersionMajor >= 10;
end;



{ Win details }
function IsNTKernel: Boolean;                                                                                           { Win32Platform is defined as system var }
begin
 Result:= (Win32Platform = VER_PLATFORM_WIN32_NT);
end;


function Is64Bit: Boolean;
begin
  Result := TOSVersion.Architecture = arIntelX64
end;


function Architecture: string;
begin
 case TOSVersion.Architecture of
    arIntelX86: Result := 'Intel 32bit';
    arIntelX64: Result := 'AMD 64bit';
    arARM32   : Result := 'ARM 32bit';
    arARM64   : Result := 'ARM 64bit';   //supported on Delphi 10+
   else
      Result:= 'Unknown architecture';
 end;
end;





{-------------------------------------------------------------------------------------------------------------
   DON'T USE!
   Delphi XE7  -> I think it reports the incorrect Win version on Win10
   Delphi 10.2 -> It reports the correct Win version on Win10 because the manifest generated by Delphi 10.2 says the app is Win10 ready
-------------------------------------------------------------------------------------------------------------}
function WinMajorVersion: Integer;
begin
 Result:= System.SysUtils.Win32MajorVersion;
end;

function WinMinorVersion: Integer;
begin
 Result:= System.SysUtils.Win32MinorVersion;
end;






{-------------------------------------------------------------------------------------------------------------
  TestUnit

   On Win7 this returns:
     Major: 6 Minor: 1
     IsWindowsXP:         False
     IsWinVista:          False
     IsWindows7:          True    OK
     IsWindows8:          False
     IsWindows10 PW:      False

     IsWindowsXPUp:       True
     IsWindowsVistaUp:    True
     IsWindows7Up:        True
     IsWindows8Up:        False

     Win32MajorMinorVersion: 6.1     OK
     GetVersionEx:           6.1     OK
     GetWinVerNetServer:     6.1     OK

   ----------

   On Win10 this returns:
     Major: 10 Minor: 0
     IsWindowsXP:         False
     IsWinVista:          False
     IsWindows7:          False
     IsWindows8:          False
     IsWindows10 PW:      True    OK

     IsWindowsXPUp:       True
     IsWindowsVistaUp:    True
     IsWindows7Up:        True
     IsWindows8Up:        True

     Win32MajorMinorVersion: 6.2     WRONG!!
     GetVersionEx:           6.2     WRONG!!
     GetWinVerNetServer:    10.0     OK

-------------------------------------------------------------------------------------------------------------}
function TestUnit: string;
VAR vMajor, vMinor: Cardinal;
begin
 Result:= '';

 { Win32MajorVersion
   On Win10 returns 6.2 which is WRONG }
 Result:= Result+ CRLF+ '  Win32MajorMinorVersion: '+ IntToStr(System.SysUtils.Win32MajorVersion)+ '.'+ IntToStr(System.SysUtils.Win32MinorVersion);

 { GetVersionEx
   On Win10 returns 6.2 which is WRONG }
 Result:= Result+ CRLF+ Format('  GetVersionEx: %d.%d', [Win32MajorVersion, Win32MinorVersion]);   // Win32MajorVersion and Win32MinorVersion are populated from GetVersionEx()...

 { NetServerGetInfo
   On Win10 returns 10.0 which is OK }
 Result:= Result+ CRLF+ '  GetWinVerNetServer: '+ GetWinVerNetServer;

 { System.SysUtils.Win32MajorVersion
   Delphi XE7  -> I think it reports the incorrect Win version on Win10
   Delphi 10.2 -> It reports the correct Win version on Win10 because the manifest generated by Delphi 10.2 says the app is Win10 ready  }
 Result:= Result+ CRLF+ '  System.SysUtils.Win32MajorVersion: '+ IntToStr(WinMajorVersion)+'.'+ IntToStr(WinMinorVersion);


 { GetWinVersion
   Works on Win10 }
 Result:= Result+ CRLF;
 Result:= Result+ CRLF;
 Result:= Result+ CRLF+ '[GetWinVersion]';
 GetWinVersion(vMajor, vMinor);
 Result:= Result+ CRLF+ '  Major: '+IntToStr(vMajor)+ '   Minor: '+IntToStr(vMinor);

 Result:= Result+ #13#10+ '  IsWindowsXP: '      + Tab     + BoolToStr(IsWindowsXP, TRUE);
 Result:= Result+ #13#10+ '  IsWinVista:'        + Tab+ Tab+ BoolToStr(IsWindowsVista, TRUE);
 Result:= Result+ #13#10+ '  IsWindows7: '       + Tab+ Tab+ BoolToStr(IsWindows7, TRUE);
 Result:= Result+ #13#10+ '  IsWindows8: '       + Tab+ Tab+ BoolToStr(IsWindows8, TRUE);
 Result:= Result+ #13#10+ '  IsWindows10 PW: '   + Tab     + BoolToStr(IsWindows10, TRUE);
 Result:= Result+ #13#10;
 Result:= Result+ #13#10+ '  IsWindowsXPUp: '    + Tab+ BoolToStr(IsWindowsXPUp, TRUE);
 Result:= Result+ #13#10+ '  IsWindowsVistaUp: ' + Tab+ BoolToStr(IsWindowsVistaUp, TRUE);
 Result:= Result+ #13#10+ '  IsWindows7Up: '     + Tab+ BoolToStr(IsWindows7Up, TRUE);
 Result:= Result+ #13#10+ '  IsWindows8Up: '     + Tab+ BoolToStr(IsWindows8Up, TRUE);
end;





end.
