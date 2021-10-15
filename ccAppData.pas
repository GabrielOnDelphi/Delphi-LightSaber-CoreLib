UNIT ccAppData;

{==================================================================================================
  Gabriel Moraru
  2021.10.15
  See Copyright.txt
 ==================================================================================================
  The AppName global variable is the central part of the App/Ini/MesageBox functionality.

  Dependences:
    cvINIFileEx.pas - Allows you to save the state of your application (all checkboxes, radioboxes, etc) to a INI file with one single function call (SaveForm/LoadForm). AppName is used for the INI file name.
    ccCore.pas (MesajInfo, MesajError, etc) - Allows you to show customized message/dialog boxes. AppName is shown in dialog's caption.

  It is CRITICAL to set the AppName global var as soon as the application starts.
  It MUST contain only I/O safe characters. By default it is initialized to an invalid value so you won't be able to start your app if you forget to initialize it.
==================================================================================================}

INTERFACE
{$WARN GARBAGE OFF}

USES
  Winapi.Windows,
  Winapi.ShlObj,
  Winapi.ShellAPI,
  System.Win.Registry,
  System.IOUtils,
  System.SysUtils,
  System.Classes,
  Vcl.Forms;

VAR
   AppName: string= '? Invalid AppName';
   AppInitializing: Boolean= True;    { Used in cvINIFileEx.pas. Set it to false once your app finished initializing. }


{--------------------------------------------------------------------------------------------------
   App PATHS
--------------------------------------------------------------------------------------------------}
 function  GetAppDir          : string;
 function  GetAppSysDir       : string;

 function  ForceAppDataFolder : string;
 function  GetAppDataFolder   : string;
 function  GetAppDataFolderAllUsers(CONST AppName: string): string;


{--------------------------------------------------------------------------------------------------
   App NAME
--------------------------------------------------------------------------------------------------}
 function  AppShortName: string;   { Returns the name of the app (exe name without extension) }
 function  AppIniFile: string;


{--------------------------------------------------------------------------------------------------
   App Control
--------------------------------------------------------------------------------------------------}
 function  RunningFirstTime: Boolean;
 procedure AppRestart;
 procedure AppSelfDelete;
 procedure RestoreApp(MainForm: TForm);



 {-------------------------------------------------------------------------------------------------
   APPLICATION Version
--------------------------------------------------------------------------------------------------}
 function  GetVersionInfoV      : string;                                     { MAIN. Returns version without Build number. Example: v1.0.0 }
 function  GetVersionInfo(ShowBuildNo: Boolean= False): string;
 function  GetVersionInfoMajor: Word;
 function  GetVersionInfoMinor: Word;
 function  GetVersionInfo_Eu: string;

 function  getVersionFixedInfo(CONST FileName: string; VAR FixedInfo: TVSFixedFileInfo): Boolean;


 {-------------------------------------------------------------------------------------------------
   APPLICATION Command line
--------------------------------------------------------------------------------------------------}
 function  CommandLinePath: string;
 procedure ExtractPathFromCmdLine(MixedInput: string; OUT Path, Parameters: string);               { recieves a full path and returns the path and the parameters separatelly. Old name: SeparatePathFromParams }
 function  FindCmdLineSwitch(const Switch: string; IgnoreCase: Boolean): Boolean; deprecated 'Use System.SysUtils.FindCmdLineSwitch';


{--------------------------------------------------------------------------------------------------
   BetaTester tools
--------------------------------------------------------------------------------------------------}
 function  RunningHome: Boolean;
 function  BetaTesterMode: Boolean;
 function  IsHardCodedExp(Year, Month, Day: word): Boolean;

 { Compiler }
 function CompilerOptimization_ : Boolean;
 function CompilerOptimizationS_: String;
 function AppPlatform: string;     { Shows if the program is compiled as 32 or 64bit app }





IMPLEMENTATION
USES
  ccCore, ccIO;




{
  Returns the folder where the EXE file resides
  The path ended with backslash. Works with UNC paths.
  Example: c:\Program Files\MyCoolApp\ }
function GetAppDir: string;
begin
 Result:= ExtractFilePath(Application.ExeName);
end;


{
  Returns the folder where the EXE file resides plus one extra folder called 'System'
  The path ended with backslash. Works with UNC paths.
  Example: c:\Program Files\MyCoolApp\System\ }
function GetAppSysDir: string;
begin
 Result:= GetAppDir+ 'system\';
end;


{ Returns ONLY the name of the app (exe name without extension) }                                             { Old name: GetAppShortName }
function AppShortName: string;
begin
 Result:= ExtractOnlyName(Application.ExeName);
end;









{ Returns the path to current user's AppData folder on Windows, and to the current user's home directory on Mac OS X.
  Example:  c:\Documents and Settings\UserName\Application Data\AppName\ }
function GetAppDataFolder: string;
begin
 Assert(System.IOUtils.TPath.HasValidFileNameChars(AppName, FALSE), 'Invalid chars in AppName: '+ AppName);
 Result:= Trail(Trail(System.SysUtils.GetHomePath)+ AppName);
end;


{ Example: 'C:\Documents and Settings\All Users\Application Data\AppName' }
function GetAppDataFolderAllUsers(CONST AppName: string): string;
begin
 Result:= Trail(GetSpecialFolder(CSIDL_COMMON_APPDATA)+ AppName);
 if NOT DirectoryExists(Result)
 then ForceDirectories(Result);
end;


{ Creates the folder (full path) where the INI file will be written. }
function ForceAppDataFolder: string;
begin
 Result:= GetAppDataFolder;
 ForceDirectories(Result);
end;










{-----------------------------------------------------------------------------------------------------------------------
   APP UTILS
-----------------------------------------------------------------------------------------------------------------------}

{ Returns the name of the INI file (where we will write application's settings).
  It is based on the name of the application.
  Example: c:\Documents and Settings\Bere\Application Data\MyApp\MyApp.ini }
function AppIniFile: string;                                                                                  { Old name: GetAppIniFile }
begin
 Result:= GetAppDataFolder+ AppName+ '.ini';
end;


function RunningFirstTime: Boolean;
begin
 Result:= NOT FileExists(AppIniFile);
end;


function RunningHome: Boolean;
begin
 Result:= FileExists(ChangeFileExt(Application.ExeName, '.dpr'));
end;


function BetaTesterMode: Boolean;
begin
 Result:= FileExists(GetAppSysDir+ 'betatester') OR FileExists(GetAppDir+ 'betatester');
end;


function IsHardCodedExp(Year, Month, Day: word): Boolean;                                          { HARD CODED DATE }
VAR
   s: string;
   HardCodedDate: TDateTime;
begin
 if FileExists(GetAppDir+ 'dvolume.bin')                                                           { If file exists, ignore the date passed as parameter and use the date written in file }
 then
  begin
   s:= StringFromFile(GetAppDir+ 'dvolume.bin');
   HardCodedDate:= StrToInt64Def(s, 0);
   Result:= round(HardCodedDate- Date) <= 0;     { For example: 2016.07.18 is 3678001053146ms. One day more is: 3678087627949 }
   //todayInMilliseconds := round((Now+1) * SecsPerDay * 1000);
  end
 else
  begin
   HardCodedDate:= EncodeDate(Year, Month, Day);
   Result:= round(HardCodedDate- Date) <= 0;
  end;
end;













{--------------------------------------------------------------------------------------------------
   APPLICATION / WIN START UP
--------------------------------------------------------------------------------------------------}

{ Run the specified application at Windows startup }
function RunFileAtWinStartUp(FilePath: string; Active: Boolean): Boolean;                             { Porneste anApp odata cu windows-ul }
VAR Reg: TRegistry;
begin
 Result:= FALSE;
 TRY
  Reg:= TRegistry.Create;
  TRY
   Reg.LazyWrite:= TRUE;
   Reg.RootKey:= HKEY_CURRENT_USER;                                                                { This is set by default by the constructor }
   if Reg.OpenKey('\Software\Microsoft\Windows\CurrentVersion\Run', TRUE) then
     begin
      if Active
      then Reg.WriteString(ExtractOnlyName(FilePath),'"'+ FilePath + '"')                                { I got once an error here: ERegistryexception-Failed to set data for 'App-Name2'. Probably cause by an anti-virus }
      else Reg.DeleteValue(ExtractOnlyName(FilePath));
      Reg.CloseKey;
      Result:= TRUE;
     end;
  FINALLY
    FreeAndNil(Reg);
  END;
 except
   Result:= FALSE;                                                                                 { To catch possible issues caused by antivirus programs that won't let the program write to 'autorun' section }
 END;
end;


{ Run THIS application at Windows startup }
function RunSelfAtWinStartUp(Active: Boolean): Boolean;
begin
 Result:= RunFileAtWinStartUp(ParamStr(0), Active);
end;







{--------------------------------------------------------------------------------------------------
   APPLICATION Control
--------------------------------------------------------------------------------------------------}
procedure AppRestart;                                                                              { from www.About.com }
VAR PAppName : PChar;
begin
  PAppName:= PChar(Application.ExeName);
  Winapi.ShellAPI.ShellExecute( {Handle}0, 'open', PAppName, nil, nil, SW_SHOWNORMAL);   { Handle does not work. Replaced with 0. }
  Application.Terminate;
end;


procedure AppSelfDelete;                                                                           { Very dirty! Think twice before using it! It creates a BAT that deletes the EXE. }
CONST
   cBatCode = ':delete_exe' + CRLF +'del "%s"' + CRLF +'if exist "%s" goto delete_exe' + CRLF +'del "%s"';
VAR
 List : TStringList;
 BatPath : string;
 S : string;
 PI : TProcessInformation;
 SI : TStartupInfo;
begin
 BatPath:= GetTempFolder+ ChangeFileExt(AppShortName, '.BAT');   // make it in temp
 List := TStringList.Create;
 TRY
  S := Format(cBatCode, [Application.ExeName, Application.ExeName, BatPath]);
  List.Text := S;
  List.SaveToFile(BatPath);
 FINALLY
  FreeAndNil(List);
 END;

 FillChar(SI, SizeOf(SI), 0);
 SI.dwFlags := STARTF_USESHOWWINDOW;
 SI.wShowWindow := SW_HIDE;

 if CreateProcess( NIL, PChar(BatPath), nil, nil, False, IDLE_PRIORITY_CLASS, nil, nil, SI, PI) then
  begin
   CloseHandle(PI.hThread);
   CloseHandle(PI.hProcess);
  end;

 Application.Terminate;                                                                            { This is mandatory }
end;




{ Bring the application back to screen (if minimized, in background, hidden) }
procedure RestoreApp{(MainForm: TForm)};
begin
  MainForm.Visible:= TRUE;
  if MainForm.WindowState = wsMinimized
  then MainForm.WindowState:= TWindowState.wsNormal;
  //Use Restore to restore the application to its previous size before it was minimized. When the user restores the application to normal size, Restore is automatically called.
  //Note: Don't confuse the Restore method, which restores the entire application, with restoring a form or window to its original size. To minimize, maximize, and restore a window or form, change the value of its WindowState property.
  Application.Restore;
  SetForegroundWindow(MainForm.Handle);
  Application.BringToFront;
end;







{--------------------------------------------------------------------------------------------------
   VERSION INFO
--------------------------------------------------------------------------------------------------}

function getVersionFixedInfo(CONST FileName: string; VAR FixedInfo: TVSFixedFileInfo): Boolean;  { FROM JCL } { TVSFixedFileInfo returns all kind of more or less info about an executable file }
var
  InfoSize, FixInfoLen: DWORD;
  DummyHandle: DWORD;
  Buffer: string;
  FixInfoBuf: PVSFixedFileInfo;
begin
  Result := False;
  InfoSize := GetFileVersionInfoSize(PChar(FileName), DummyHandle);
  if InfoSize > 0 then
   begin
    FixInfoLen := 0;
    FixInfoBuf := Nil;

    SetLength(Buffer, InfoSize);
    if  GetFileVersionInfo(PChar(FileName), DummyHandle, InfoSize, Pointer(Buffer))    { The DummyHandle parameter is ignored by GetFileVersionInfo }
    AND VerQueryValue(Pointer(Buffer), '\', Pointer(FixInfoBuf), FixInfoLen)
    AND (FixInfoLen = SizeOf(TVSFixedFileInfo)) then
     begin
      Result := True;
      FixedInfo := FixInfoBuf^;
     end;
  end;
end;


function GetVersionInfoMajor: Word;
VAR FixedInfo: TVSFixedFileInfo;
begin
 if GetVersionFixedInfo(Application.ExeName, FixedInfo)
 then Result:= HiWord(FixedInfo.dwFileVersionMS)
 else Result:= 0;
end;


function GetVersionInfoMinor: Word;
VAR FixedInfo: TVSFixedFileInfo;
begin
 if GetVersionFixedInfo(Application.ExeName, FixedInfo)
 then Result:= LoWord(FixedInfo.dwFileVersionMS)
 else Result:= 0;
end;



{ Returns version with/without build number.
  Example: 1.0.0.876

  See also: CheckWin32Version }
function GetVersionInfo(ShowBuildNo: Boolean= False): string;
VAR FixedInfo: TVSFixedFileInfo;
begin
  FixedInfo.dwSignature:= 0;
  if GetVersionFixedInfo(Application.ExeName, FixedInfo)
  then
     begin
      Result:= IntToStr(HiWord(FixedInfo.dwFileVersionMS))+'.'+ IntToStr(LoWord(FixedInfo.dwFileVersionMS))+'.'+ IntToStr(HiWord(FixedInfo.dwFileVersionLS));
      if ShowBuildNo
      then Result:= Result+ '.'+ IntToStr(LoWord(FixedInfo.dwFileVersionLS));
     end
  else Result:= '0';
end;


function GetVersionInfoV: string;                                                                  { Returns version without build number. Example: v1.0.0 }
begin
 Result:= ' v'+ GetVersionInfo(False);
end;


function GetVersionInfo_Eu: string;
const
  InfoStr: array[1..2] of string = ('FileVersion', 'InternalName');
var
  S: string;
  InfoSize, Len, VZero: DWORD;
  Buf: PChar;      //ok
  FixInfoBuf: PChar;
begin
  Result := '';
  S:= Application.ExeName;
  InfoSize:= GetFileVersionInfoSize(PChar(S), VZero);    // https://docs.microsoft.com/en-us/windows/win32/api/winver/nf-winver-getfileversioninfosizea
  if InfoSize > 0 then
  begin
    Buf:= AllocMem(InfoSize);
    GetFileVersionInfo(PChar(S), 0, InfoSize, Buf);

     if VerQueryValue(Buf, PChar('StringFileInfo\040904E4\' + InfoStr[1]), Pointer(FixInfoBuf), Len)
     then Result:= FixInfoBuf;                                                                     {         <---- AV here, on Vista 64bit }

    FreeMem(Buf, InfoSize);
  end
end;










{-----------------------------------------------------------------------------------------------------------------------
   APP UTILS
-----------------------------------------------------------------------------------------------------------------------}

{ Importan note:
   $O+ has a local scope, therefore, the result of the function reflects only the optimization state at that specific source code location.
   So, if you are using the $O switch to optimize pieces of code then the function MUST be used as a subfunction,
    otherwise, if you use the global switch only (in Project Options) it can be used as a normal (declared) function. }

function CompilerOptimization_: Boolean;
begin
 {$IfOpt O+}
 Result:= TRUE;
 {$Else}
 Result:= FALSE;
 {$EndIf}
end;

function CompilerOptimizationS_: String;
begin
 Result:= 'Compiler optimization is ' +
 {$IfOpt O+}
 'enabled'
 {$Else}
 'disabled'
 {$EndIf}
end;


{ Shows if the program is compiled as 32 or 64bit app }
function AppPlatform: String;
begin
 {$IF Defined(CPUX86)}
   Result:= '32bit';
 {$ELSEIF Defined(CPUX64)}
   Result:= '64bit';
 {$ELSE}
   {$Message Fatal 'Unknown CPU'}  {TODO 2: do this in all functions that are platform conditionated }        { Contitional compilation: http://docwiki.embarcadero.com/RADStudio/XE8/en/Conditional_compilation_%28Delphi%29 }
 {$ENDIF}
end;









{-----------------------------------------------------------------------------------------------------------------------
   APP COMMAND LINE
-----------------------------------------------------------------------------------------------------------------------}
function CommandLinePath: string;    { Tested ok. Returns the path sent as command line param }
begin
 if ParamCount > 0
 then Result:= Trim(ParamStr(1))     { Do we have parameter into the command line? }
 else Result := '';
end;



procedure ExtractPathFromCmdLine(MixedInput: string; out Path, Parameters: string);                { recieves a full path and returns the path and the parameters separatelly }
VAR i: Integer;
begin
 Assert(Length(MixedInput) > 0, 'ExtractPathFromCmdLine -> Length=0');

 MixedInput:= Trim(MixedInput);

 { I don't have paramters }
 if MixedInput[1]<> '"' then
  begin
   Path:= MixedInput;
   Parameters:= '';
  end

 else
 {Copiaza tot ce e intre ""}
 for i:= 2 to Length(MixedInput) DO                                                                { ATENTIE! Asta presupune ca pe prima pozitie am caracterul " }
  if MixedInput[i]= '"' then                                                                       { find next " character }
   begin
    Path:= CopyTo(MixedInput, 1+1, i-1);                                                           { +1 si -1 pt ca nu vreau sa copiez si ghilimele }
    Parameters:= system.COPY(MixedInput, i+1, Length(MixedInput));
    Break;
   end;
end;
                                                                                             { A SE VEDEA SI: http://delphi.about.com/od/delphitips2007/qt/parse_cmd_line.htm }


function FindCmdLineSwitch(const Switch: string; IgnoreCase: Boolean): Boolean;
begin
  Result:= System.SysUtils.FindCmdLineSwitch(Switch, IgnoreCase);
end;



end.

