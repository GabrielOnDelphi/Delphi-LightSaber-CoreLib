UNIT ccStreamBuff;

{-----------------------------------------------------------------------------------------------------------------------
  Gabriel Moraru
  2021.10.15
  See Copyright.txt

  Buffered file access (very fast reading/writing to a file).
  ONLY works for linear reading NOT for random reading!
  Update 2021: When reading character by character, the new System.Classes.TBufferedFileStream seems to be 70% faster.


  Source: http://stackoverflow.com/questions/5639531/buffered-files-for-faster-disk-access
-----------------------------------------------------------------------------------------------------------------------


   Speed tests:
     Reading a 317MB SFF file.
     Delphi streams: 9.84sec
     This stream:    2.05sec

     3.1sec only to read a 90MB file line by line (no other processing)
     ______________________________________
     Input file: input2_700MB.txt
     Content: "WP_000000006.1" "NZ_AFCM01000246.1"
     (PS: multiply time with 10)
     Tester: c:\MyProjects\Project Testers\IO ccStreamBuff.pas tester\

     Lines: 19 millions
     Compiler optmization: ON
     I/O check: On
     FastMM: release
     ______________________________________
     Reading: linear (ReadLine) (19 millions reads)
      HDD Laptop                                    (PS: multiply time with 10)
      We see clear performance drop at 8KB. Recommended 32KB
        Time: 622 ms  Cache size: 128KB.
        Time: 622 ms  Cache size: 64KB.
        Time: 622 ms  Cache size: 32KB.
        Time: 622 ms  Cache size: 24KB.
        Time: 624 ms  Cache size: 256KB.
        Time: 625 ms  Cache size: 18KB.
        Time: 626 ms  Cache size: 1024KB.
        Time: 626 ms  Cache size: 26KB.
        Time: 626 ms  Cache size: 16KB.
        Time: 628 ms  Cache size: 42KB.
        Time: 644 ms  Cache size: 8KB.      <--- the speed drops suddenly for 8K buffers (and lower)
        Time: 664 ms  Cache size: 4KB.
        Time: 705 ms  Cache size: 2KB.
        Time: 791 ms  Cache size: 1KB.
        Time: 795 ms  Cache size: 1KB.
     ______________________________________
      SSD Laptop
      We see a small improvement as we go towards higher buffers. Recommended 16 or 32KB
        Time: 610 ms  Cache size: 128KB.
        Time: 611 ms  Cache size: 256KB.
        Time: 614 ms  Cache size: 32KB.
        Time: 623 ms  Cache size: 16KB.
        Time: 625 ms  Cache size: 66KB.
        Time: 639 ms  Cache size: 8KB.       <--- definitivelly not good with < 8K
        Time: 660 ms  Cache size: 4KB.
     ______________________________________
     Reading: Random (ReadInteger) (100000 reads)
      SSD Laptop
       Time: 064 ms. Cache size: 1KB.   Count: 100000.  RAM: 13.27 MB         <-- probably the best buffer size for ReadInteger is 4bytes!
       Time: 067 ms. Cache size: 2KB.   Count: 100000.  RAM: 13.27 MB
       Time: 080 ms. Cache size: 4KB.   Count: 100000.  RAM: 13.27 MB
       Time: 098 ms. Cache size: 8KB.   Count: 100000.  RAM: 13.27 MB
       Time: 140 ms. Cache size: 16KB.  Count: 100000.  RAM: 13.27 MB
       Time: 213 ms. Cache size: 32KB.  Count: 100000.  RAM: 13.27 MB
       Time: 360 ms. Cache size: 64KB.  Count: 100000.  RAM: 13.27 MB

     Conclusion: This library is NOT the perfect solution for random reading.
     ______________________________________


    Windows file caching is very effective, especially if you are using Vista or later. TFileStream is a loose wrapper around
    the Windows ReadFile() and WriteFile() API functions and for many use cases the only thing faster is a memory mapped file.

    However, there is one common scenario where TFileStream becomes a performance bottleneck.
    That is if you read or write small amounts of data with each call to the stream read or write
    functions. For example if you read an array of integers one item at a time then you incur a
    significant overhead by reading 4 bytes at a time in the calls to ReadFile().

    Again, memory mapped files are an excellent way to solve this bottleneck, but the other commonly used approach is
    to read a much larger buffer, many kilobytes say, and then resolve future reads of the stream from this in memory
    cache rather than further calls to ReadFile(). This approach only really works for sequential access.


    Also see TBinaryReader / TBinaryWriter
      http://docwiki.embarcadero.com/CodeExamples/Tokyo/en/TBinaryReader_and_TBinaryWriter_(Delphi)
-----------------------------------------------------------------------------------------------------------------------}

INTERFACE
{$WARN GARBAGE OFF}   {Silence the: 'W1011 Text after final END' warning }

USES
   System.Types, System.SysUtils, System.AnsiStrings, System.Classes, system.Math, Winapi.Windows;


TYPE
  TBaseCachedFileStream = class(TStream)
  private
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  protected
    FHandle     : THandle;
    FOwnsHandle : Boolean;
    FCache      : PByte;
    FCacheSize  : Integer;
    FPosition   : Int64;                                                        //the current position in the file (relative to the beginning of the file)
    FCacheStart : Int64;                                                        //the postion in the file of the start of the cache (relative to the beginning of the file)
    FCacheEnd   : Int64;                                                        //the postion in the file of the end of the cache (relative to the beginning of the file)
    FFileName   : string;
    FLastError  : DWORD;
    procedure HandleError(const Msg: string);
    procedure RaiseSystemError(const Msg: string; LastError: DWORD); overload;
    procedure RaiseSystemError(const Msg: string); overload;
    procedure RaiseSystemErrorFmt(const Msg: string; const Args: array of const);
    function  CreateHandle(FlagsAndAttributes: DWORD): THandle; virtual; abstract;
    function  GetFileSize: Int64; virtual;
    procedure SetSize(NewSize: Longint); override;
    procedure SetSize(const NewSize: Int64); override;
    function  FileRead(var Buffer; Count: Longword): Integer;
    function  FileWrite(const Buffer; Count: Longword): Integer;
    function  FileSeek(const Offset: Int64; Origin: TSeekOrigin): Int64;
  public
    MagicNo: AnsiString;
    constructor Create(const FileName: string); overload;
    constructor Create(const FileName: string; CacheSize: Integer); overload;
    constructor Create(const FileName: string; CacheSize: Integer; Handle: THandle); overload; virtual;
    destructor Destroy; override;
    property CacheSize: Integer read FCacheSize;
    function Read  (var Buffer; Count: Longint): Longint; override;
    function Write (const Buffer; Count: Longint): Longint; override;
    function Seek  (const Offset: Int64; Origin: TSeekOrigin): Int64; override;
  end;


  IDisableStreamReadCache = interface ['{0B6D0004-88D1-42D5-BC0F-447911C0FC21}']
    procedure DisableStreamReadCache;
    procedure EnableStreamReadCache;
  end;


(* This class works by filling the cache each time a call to Read is made and
     FPosition is outside the existing cache.  By filling the cache we mean reading from the file into the temporary cache.  Calls to Read when
     FPosition is in the existing cache are then dealt with by filling the buffer with bytes from the cache.                                        *)
 TReadCachedStream = class(TBaseCachedFileStream, IDisableStreamReadCache)
  private
    Buff: AnsiString;
    BuffPos: Integer;
    FUseAlignedCache: Boolean;
    FViewStart: Int64;
    FViewLength: Int64;
    FDisableStreamReadCacheRefCount: Integer;
    procedure disableStreamReadCache;
    procedure enableStreamReadCache;
    procedure flushCache;
    procedure fillBuffer;
  protected
    function  CreateHandle(FlagsAndAttributes: DWORD): THandle; override;
    function  GetFileSize: Int64; override;
  public
    EOF: Boolean;                                                                     { True when all lines have been read (end of file). Use it with ReadLine. }
    LineOffset: Int64;                                                                { Offset of the current entry (line) in file. Used by Fasta Sorter to retrieve sequence start }
    LastAddress: Int64;                                                               { Address from where I currently read in file. Needs to be public because it used to show progress in TCubeEx.SplitMultiplex }
    MaxLineLength: integer;                                                           { Maximum line length. If a text file contains lines longer than this value, the program will crash.   }
    constructor Create(const FileName: string; CacheSize: Integer; Handle: THandle); overload; override;
    property  UseAlignedCache: Boolean read FUseAlignedCache write FUseAlignedCache;
    function  Read(var Buffer; Count: Longint): Longint; override;
    procedure SetViewWindow(const ViewStart, ViewLength: Int64);

    function  ReadMagicVer: Word;
    function  ReadMagicNo  (CONST MagicNo_: AnsiString): Boolean;                                   { Read a string from disk and compare it with MagicNo. Retursn TRUE if it matches }

    function  ReadSingle: Single;
    function  ReadDate: TDateTime;
    function  ReadEnter: Word;
    function  ReadInteger: Integer;
    function  ReadByte: Byte;
    function  ReadShortInt: ShortInt;
    function  ReadSmallInt: SmallInt;
    function  ReadBoolean: Boolean;
    function  ReadCardinal: Cardinal;
    function  ReadWordSwap: Word;
    function  ReadWord: Word;
    function  ReadStringA(CONST Lungime: integer): AnsiString; overload;                           { You need to specify the length of the string }
    function  ReadStringA: AnsiString;                         overload;                           { It automatically detects the length of the string }
    function  ReadStringU: string;
    procedure ReadStrings(TSL: TStrings);                                              { Works for both Delphi7 and Delphi UNICODE }
    function  ReadChars(Count: Longint): AnsiString;
    procedure ReadPadding(CONST Bytes: Integer= 1024);
    function  ReadBytes: TByteDynArray;

    procedure FirstLine;    { Go to first line. I need to use it after CountLines }
    function  CountLines: Int64;
    function  ReadLine: AnsiString;
    function  ReadEachLine: AnsiString;
    function  ReadLines(StopChar: AnsiChar): AnsiString;      { Read lines until 'StopChar' is encountered }
    function  CountAppearance(C: AnsiChar): Int64;
    procedure GoToOffset(Offset: Int64);   { Flush buffer, move to the specified offset. The next ReadLine will fill the buffer with data from that position }
  end;


{ This class works by caching calls to Write.  By this we mean temporarily storing the bytes to be written in the cache.  As each call to Write is processed the cache grows.  The cache is written to file when:
       1.  A call to Write is made when the cache is full.
       2.  A call to Write is made and FPosition is outside the cache (this must be as a result of a call to Seek).
       3.  The class is destroyed.
   Note that data can be read from these streams but the reading is not cached and in fact a read operation will flush the cache before attempting to read the data.                                             }
  TWriteCachedStream = class(TBaseCachedFileStream, IDisableStreamReadCache)
  private
    FFileSize: Int64;
    FReadStream: TReadCachedStream;
    FReadStreamCacheSize: Integer;
    FReadStreamUseAlignedCache: Boolean;
    procedure DisableStreamReadCache;
    procedure EnableStreamReadCache;
    procedure CreateReadStream;
    procedure FlushCache;
  protected
    function CreateHandle(FlagsAndAttributes: DWORD): THandle; override;
    function GetFileSize: Int64; override;
  public
    constructor Create(const FileName: string; CacheSize, ReadStreamCacheSize: Integer; ReadStreamUseAlignedCache: Boolean); overload;
    destructor Destroy; override;
    function  Read         (VAR   Buffer; Count: Longint): Longint; override;
    function  Write        (CONST Buffer; Count: Longint): Longint; override;

    procedure WriteMagicVer(const MVersion: Word);
    procedure WriteMagicNo (CONST MagicNo_: AnsiString);
    { BINARY WRITING }                                                               { All these functions are mine }
    procedure WriteSingle  (CONST Sngl: Single);
    procedure WriteBytes   (CONST Buffer: TByteDynArray);
    procedure WriteByte    (CONST b: Byte);
    procedure WriteShortInt(CONST s: ShortInt);     //Signed 8bit: -128..127
    procedure WriteSmallInt(const s: SmallInt);
    procedure WriteEnter;
    procedure WriteDate    (CONST aDate: TDateTime);
    procedure WriteBoolean (CONST b: bool);
    procedure WriteStringA (CONST s: AnsiString);
    procedure WriteStringU (const s: String);
    procedure WriteStrings (TSL: TStrings);                                              { Works for both Delphi7 and Delphi UNICODE }
    procedure WriteChars   (CONST s: AnsiString);                                        { Writes a bunch of chars from the file. Why 'chars' and not 'string'? This function writes C++ strings (the length of the string was not written to disk also) and not real Delphi strings. }
    procedure WriteCardinal(CONST c: Cardinal);
    procedure WriteInteger (CONST i: Integer);
    procedure WriteWord    (CONST w: Word);
    procedure WritePadding (CONST Bytes: Integer= 1024);
    { TEXT WRITING }
    procedure WriteText    (CONST s: AnsiString); { Writes the specified string as plain text (without its length as binary number in front of it) }
    procedure WriteTextLn  (s: AnsiString); { Same as xx but it automatically adds an enter after each text }
  end;



function SetFilePointerEx(hFile: THandle; DistanceToMove: Int64; lpNewFilePointer: PInt64; dwMoveMethod: DWORD): BOOL; stdcall; external 'kernel32.dll';



IMPLEMENTATION



USES
  ccBinary, ccCore;

CONST
  DefaultCacheSize = 32*KB;     { Author: 16kb - this was chosen empirically but it seems to be the best value - don't make it too large otherwise the progress report is 'jerky' }
  DefMaxLineLength =  2*MB;     { Maximum line length. If a text file contains lines longer than this value, the program will crash.  }

{ MaxLineLength   Best speed
      16KB          47ms
      32KB          47ms
      96KB          46ms
     128KB          47ms
     256KB          47ms
     512KB          47ms
    1024KB          47ms
    2048KB          49ms
------------------------------------}








{ TBaseCachedFileStream }

constructor TBaseCachedFileStream.Create(const FileName: string);
begin
 Create(FileName, 0);
end;


constructor TBaseCachedFileStream.Create(const FileName: string; CacheSize: Integer);
begin
 Create(FileName, CacheSize, 0);
end;


constructor TBaseCachedFileStream.Create(const FileName: string; CacheSize: Integer; Handle: THandle);
begin
 inherited Create;
 FFileName := FileName;
 FOwnsHandle := Handle=0;

 if FOwnsHandle
 then FHandle := CreateHandle(FILE_ATTRIBUTE_NORMAL)
 else FHandle := Handle;

 FCacheSize := CacheSize;
 if FCacheSize<= 0
 then FCacheSize := DefaultCacheSize;
 GetMem(FCache, FCacheSize);
end;


destructor TBaseCachedFileStream.Destroy;
begin
 FreeMem(FCache);

 if FOwnsHandle and (FHandle<>0)
 then
   {debug: if NOT CloseHandle(FHandle) then MessageBox_replace_with_Mesaj(0, PChar('cannot close file'), '', 0);   }
   CloseHandle(FHandle);

 inherited Destroy;
end;


function TBaseCachedFileStream.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
 if GetInterface(IID, Obj)
 then Result := S_OK
 else Result := E_NOINTERFACE;
end;


function TBaseCachedFileStream._AddRef: Integer;
begin
 Result := -1;
end;


function TBaseCachedFileStream._Release: Integer;
begin
 Result := -1;
end;


procedure TBaseCachedFileStream.HandleError(const Msg: string);
begin
 if FLastError<>0
 then RaiseSystemError(Msg, FLastError);
end;


procedure TBaseCachedFileStream.RaiseSystemError(const Msg: string; LastError: DWORD);
begin
  RAISE EStreamError.Create(Trim(Msg)+ #13#10+ SysErrorMessage(LastError));
end;


procedure TBaseCachedFileStream.RaiseSystemError(const Msg: string);
begin
 RaiseSystemError(Msg, GetLastError);
end;


procedure TBaseCachedFileStream.RaiseSystemErrorFmt(const Msg: string; const Args: array of const);
var
  LastError: DWORD;
begin
  LastError := GetLastError; // must call GetLastError before Format
  RaiseSystemError(Format(Msg, Args), LastError);
end;


function TBaseCachedFileStream.GetFileSize: Int64;
begin
 if NOT GetFileSizeEx(FHandle, Result)
 then RaiseSystemErrorFmt('GetFileSizeEx failed for %s.', [FFileName]);
end;


procedure TBaseCachedFileStream.SetSize(NewSize: Longint);
begin
 SetSize(Int64(NewSize));
end;


procedure TBaseCachedFileStream.SetSize(const NewSize: Int64);
begin
 Seek(NewSize, soBeginning);
 if NOT WinApi.Windows.SetEndOfFile(FHandle)
 then RaiseSystemErrorFmt('SetEndOfFile for %s.', [FFileName]);
end;


function TBaseCachedFileStream.FileRead(var Buffer; Count: Longword): Integer;
begin
 if WinApi.Windows.ReadFile(FHandle, Buffer, Count, LongWord(Result), nil)
 then FLastError := 0
 else
  begin
   FLastError := GetLastError;
   Result := -1;
  end;
end;


function TBaseCachedFileStream.FileWrite(const Buffer; Count: Longword): Integer;
begin
 if WinApi.Windows.WriteFile(FHandle, Buffer, Count, LongWord(Result), nil)
 then FLastError := 0
 else
  begin
   FLastError := GetLastError;
   Result := -1;
  end;
end;


function TBaseCachedFileStream.FileSeek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
 if NOT SetFilePointerEx(FHandle, Offset, @Result, ord(Origin))
 then RaiseSystemErrorFmt('SetFilePointerEx failed for %s.', [FFileName]);
end;


function TBaseCachedFileStream.Read(var Buffer; Count: Integer): Longint;
begin
 RAISE EAssertionFailed.Create('Cannot read from this stream');
end;


function TBaseCachedFileStream.Write(const Buffer; Count: Integer): Longint;
begin
 RAISE EAssertionFailed.Create('Cannot write to this stream');
end;


function TBaseCachedFileStream.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
//Set FPosition to the value specified - if this has implications for the cache then overriden Write and Read methods must deal with those.
begin
 case Origin of
  soBeginning: FPosition := Offset;
  soEnd      : FPosition := GetFileSize+Offset;
  soCurrent  : inc(FPosition, Offset);
 end;
 Result := FPosition;
end;












{==================================================================================================
   TReadCachedStream
==================================================================================================}

constructor TReadCachedStream.Create(const FileName: string; CacheSize: Integer; Handle: THandle);
begin
  inherited;
  Buff             := '';      { Used by ReadLine }
  BuffPos          := 0;
  LastAddress      := 0;
  EOF              := FALSE;
  MaxLineLength    := DefMaxLineLength;   { Maximum line length. If a text file contains lines longer than this value, the program will crash.  }
  SetViewWindow(0, inherited GetFileSize);
end;


function TReadCachedStream.CreateHandle(FlagsAndAttributes: DWORD): THandle;
begin
  Result := WinApi.Windows.CreateFile( PChar(FFileName), GENERIC_READ, FILE_SHARE_READ, NIL, OPEN_EXISTING, FlagsAndAttributes, 0);
  if Result=INVALID_HANDLE_VALUE
  then RaiseSystemErrorFmt('Cannot open %s.', [FFileName]);
end;


procedure TReadCachedStream.DisableStreamReadCache;
begin
  inc(FDisableStreamReadCacheRefCount);
end;


procedure TReadCachedStream.EnableStreamReadCache;
begin
  dec(FDisableStreamReadCacheRefCount);
end;


procedure TReadCachedStream.FlushCache;
begin
  FCacheStart := 0;
  FCacheEnd  := 0;

  {For ReadLine}
  Buff       := '';
  BuffPos    := 0;
  LastAddress:= 0;
  EOF:= FALSE;
end;


function TReadCachedStream.GetFileSize: Int64;
begin
  Result := FViewLength;
end;


procedure TReadCachedStream.SetViewWindow(const ViewStart, ViewLength: Int64);
begin
  if ViewStart<0
  then raise EAssertionFailed.Create('Invalid view window');

  if (ViewStart+ViewLength) > inherited GetFileSize
  then raise EAssertionFailed.Create('Invalid view window');

  FViewStart := ViewStart;
  FViewLength := ViewLength;
  FPosition := 0;
  FCacheStart := 0;
  FCacheEnd := 0;
end;












function TReadCachedStream.Read(var Buffer; Count: Longint): Longint;
VAR
   NumOfBytesToCopy, NumOfBytesLeft, NumOfBytesRead: Longint;
   CachePtr, BufferPtr: PByte;
begin
  if FDisableStreamReadCacheRefCount > 0
  then
   begin
    FileSeek(FPosition+FViewStart, soBeginning);
    Result := FileRead(Buffer, Count);
    if Result=-1 then Result := 0;         //contract is to return number of bytes that were read
    inc(FPosition, Result);
   end
  else
   begin
    Result := 0;
    NumOfBytesLeft := Count;
    BufferPtr := @Buffer;
    WHILE NumOfBytesLeft>0 DO
     begin
      if (FPosition<FCacheStart) or (FPosition>=FCacheEnd) then
       begin
        //the current position is not available in the cache so we need to re-fill the cache
        FCacheStart := FPosition;
        if UseAlignedCache
        then FCacheStart := FCacheStart - (FCacheStart mod CacheSize);
        FileSeek(FCacheStart+FViewStart, soBeginning);
        NumOfBytesRead := FileRead(FCache^, CacheSize);
        if NumOfBytesRead=-1 then EXIT;
        Assert(NumOfBytesRead>=0);
        FCacheEnd := FCacheStart+NumOfBytesRead;
        if NumOfBytesRead=0 then
         begin
          FLastError := ERROR_HANDLE_EOF;//must be at the end of the file
          break;
         end;
       end;

      //read from cache to Buffer
      NumOfBytesToCopy := Min(FCacheEnd-FPosition, NumOfBytesLeft);
      CachePtr := FCache;
      inc(CachePtr, FPosition-FCacheStart);
      Move(CachePtr^, BufferPtr^, NumOfBytesToCopy);    //ok
      inc(Result, NumOfBytesToCopy);
      inc(FPosition, NumOfBytesToCopy);
      inc(BufferPtr, NumOfBytesToCopy);
      dec(NumOfBytesLeft, NumOfBytesToCopy);
    end;
  end;
end;












{==================================================================================================
   TWriteCachedStream
==================================================================================================}

constructor TWriteCachedStream.Create(const FileName: string; CacheSize, ReadStreamCacheSize: Integer; ReadStreamUseAlignedCache: Boolean);
begin
  inherited Create(FileName, CacheSize);

  FFileSize                  := 0; // No need to initialize as fields of a class are automatically initialized.
  FReadStreamCacheSize       := ReadStreamCacheSize;
  FReadStreamUseAlignedCache := ReadStreamUseAlignedCache;
end;


destructor TWriteCachedStream.Destroy;
begin
  FlushCache;                                                                                      { make sure that the final calls to Write get recorded in the file }
  FreeAndNil(FReadStream);
  inherited Destroy;
end;



function TWriteCachedStream.CreateHandle(FlagsAndAttributes: DWORD): THandle;
begin
 Result := WinApi.Windows.CreateFile(PChar(FFileName), GENERIC_READ or GENERIC_WRITE, 0, nil,
   CREATE_ALWAYS,   // if it exists, the file is deleted and recreated.       In OPEN_ALWAYS mode the file will be opened. Nu e bine asa.
   FlagsAndAttributes, 0);

 if Result=INVALID_HANDLE_VALUE
 then RaiseSystemErrorFmt('Cannot create %s.', [FFileName]);
end;


procedure TWriteCachedStream.DisableStreamReadCache;
begin
  CreateReadStream;
  FReadStream.DisableStreamReadCache;
end;


procedure TWriteCachedStream.EnableStreamReadCache;
begin
  Assert(Assigned(FReadStream));
  FReadStream.EnableStreamReadCache;
end;


function TWriteCachedStream.GetFileSize: Int64;
begin
  Result := FFileSize;
end;


procedure TWriteCachedStream.CreateReadStream;
begin
  if not Assigned(FReadStream) then
  begin
    FReadStream := TReadCachedStream.Create(FFileName, FReadStreamCacheSize, FHandle);
    FReadStream.UseAlignedCache := FReadStreamUseAlignedCache;
  end;
end;


procedure TWriteCachedStream.FlushCache;
var
  NumOfBytesToWrite: Longint;
begin
  if Assigned(FCache) then
  begin
    NumOfBytesToWrite := FCacheEnd-FCacheStart;
    if NumOfBytesToWrite>0 then
     begin
      FileSeek(FCacheStart, soBeginning);
      if FileWrite(FCache^, NumOfBytesToWrite)<>NumOfBytesToWrite
      then RaiseSystemErrorFmt('FileWrite failed for %s.', [FFileName]);

      if Assigned(FReadStream)
      then FReadStream.FlushCache;
     end;
    FCacheStart := FPosition;
    FCacheEnd := FPosition;
  end;
end;


function TWriteCachedStream.Read(var Buffer; Count: Integer): Longint;
begin
  FlushCache;
  CreateReadStream;
  Assert(FReadStream.FViewStart=0);
  if FReadStream.FViewLength<>FFileSize
  then FReadStream.SetViewWindow(0, FFileSize);
  FReadStream.Position := FPosition;
  Result := FReadStream.Read(Buffer, Count);
  inc(FPosition, Result);
end;


function TWriteCachedStream.Write(CONST Buffer; Count: Longint): Longint;
var
  NumOfBytesToCopy, NumOfBytesLeft: Longint;
  CachePtr, BufferPtr: PByte;
begin
  Result := 0;
  BufferPtr := @Buffer;

  NumOfBytesLeft := Count;
  while NumOfBytesLeft> 0 do
   begin
     if ((FPosition<FCacheStart) or (FPosition>FCacheEnd))                      // the current position is outside the cache
     OR (FPosition-FCacheStart=FCacheSize)                                      // the cache is full
     then
      begin
       FlushCache;
       Assert(FCacheStart=FPosition);
      end;

     //write from Buffer to the cache
     NumOfBytesToCopy := Min(FCacheSize-(FPosition-FCacheStart), NumOfBytesLeft);
     CachePtr := FCache;
     inc(CachePtr, FPosition-FCacheStart);

     Move(BufferPtr^, CachePtr^, NumOfBytesToCopy);  //Source, Dest, Count

     inc(Result, NumOfBytesToCopy);
     inc(FPosition, NumOfBytesToCopy);
     FCacheEnd := Max(FCacheEnd, FPosition);
     inc(BufferPtr, NumOfBytesToCopy);
     dec(NumOfBytesLeft, NumOfBytesToCopy);
   end;
  FFileSize := Max(FFileSize, FPosition);
end;











{----------------------------------------------------------------------------------------------------------------------}








{ MAGIC NUMBER - Obsolete }

function TReadCachedStream.ReadMagicNo(CONST MagicNo_: AnsiString): Boolean;                          { Read a string from disk and compare it with MagicNo. Retursn TRUE if it matches }
VAR s: AnsiString;
begin
 s:= ReadStringA(Length(MagicNo_));
 Result:= s = MagicNo_;
end;

procedure TWriteCachedStream.WriteMagicNo(CONST MagicNo_: AnsiString);
begin
 Assert(MagicNo_ > '', 'Magic number is empty!');
 Write(MagicNo_[1], Length(MagicNo_));
end;






{ MAGIC NUMBER
  Read the first x chars in a file and compares it with MagicNo.
  If matches then reads another reads the FileVersion word.
  Returns the FileVersion. If magicno fails, it returns zero }
function TReadCachedStream.ReadMagicVer: Word;
VAR s: AnsiString;
begin
 Assert(MagicNo > '', 'MagicNo is empty!');

 s:= ReadStringA(Length(MagicNo));
 if s = MagicNo
 then Result:= ReadWord
 else Result:= 0;
end;


procedure TWriteCachedStream.WriteMagicVer(CONST MVersion: Word);
begin
 Assert(MagicNo > '', 'Magic number is empty!');
 if MVersion= 0
 then RAISE exception.Create('MagicVersion must be higher than 0!');

 Write(MagicNo[1], Length(MagicNo));
 WriteWord(MVersion);
end;







{ CHARS }
procedure TWriteCachedStream.WriteChars(CONST s: AnsiString);                                    { Writes a bunch of chars from the file. Why 'chars' and not 'string'? This function writes C++ strings (the length of the string was not written to disk also) and not real Delphi strings. }
begin
 Assert(Length(s) > 0);
 Write(s[1], Length(s));
end;


function TReadCachedStream.ReadChars(Count: Longint): AnsiString;                              { Reads a bunch of chars from the file. Fedra. Why 'ReadChars' and not 'ReadString'? This function reads C++ strings (the length of the string was not written to disk also) and not real Delphi strings. So, i have to give the number of chars to read as parameter. IMPORTANT: The function will reserve memory for s. }
begin
 if Count= 0 then RAISE exception.Create('Count is zero!');                                      { It gives a range check error if you try s[1] on an empty string so we added 'Count = 0' as protection. }
 SetLength(Result, Count);
 Read(Result[1], Count);
{ Alternative:  Result:= Read(Pointer(s)^, Count)= Count;     <--- Don't use this! Ever. See explanation from A Buchez:   http://stackoverflow.com/questions/6411246/pointers-versus-s1 }
end;





{ STRING ANSI }
procedure TWriteCachedStream.WriteText(CONST s: AnsiString); { Writes the specified string as plain text (without its length as binary number in front of it) }
begin
 if s > ''
 then Write(s[1], Length(s));
end;

procedure TWriteCachedStream.WriteTextLn(s: AnsiString); { Same as xx but it automatically adds an enter after each text }
begin
 s:= s+ CRLF;
 Write(s[1], Length(s));
end;


procedure TWriteCachedStream.WriteStringA(CONST s: AnsiString);
VAR Lungime: Cardinal;
begin
 Lungime:= Length(s);
 Write(Lungime, 4);
 if Lungime > 0                                                                                    { This makes sure 's' is not empty. Else I will get a RangeCheckError at runtime }
 then Write(s[1], Lungime);
end;


function TReadCachedStream.ReadStringA(CONST Lungime: integer): AnsiString;                         { You need to specify the length of the string }
VAR TotalBytes: Integer;
begin
 if Lungime> 0
 then
  begin
   SetLength(Result, Lungime);                                                                     { Initialize the result }
   //FillChar(Result[1], Lungime, '?'); DEBUG ONLY!
   TotalBytes:= Read(Result[1], Lungime);                                                          { Read is used in cases where the number of bytes to read from the stream is not necessarily fixed. It attempts to read up to Count bytes into buffer and returns the number of bytes actually read.  }

   if TotalBytes= 0
   then Result:= ''
   else
     if TotalBytes < Lungime                                                                       { If there is not enough data to read... }
     then SetLength(Result, TotalBytes);                                                           { ...set the buffer to whater I was able to read }
  end
 else Result:= '';
end;


function TReadCachedStream.ReadStringA: AnsiString;                                                 { It automatically detects the length of the string }
VAR Lungime: Cardinal;
begin
 Read(Lungime, 4);
 Assert(Lungime<= Size- Position, 'TReadCachedStream: Invalid string size!');
 Result:= ReadStringA(Lungime);
end;




{ STRING UNICODE }

procedure TWriteCachedStream.WriteStringU(CONST s: String);
VAR Lungime: Cardinal;
    UTF: UTF8String;
begin
 UTF := UTF8String(s);

 { Write length }
 Lungime := Length(UTF);
 Write(Lungime, SizeOf(Lungime));

 { Write string }
 if Lungime > 0
 then Write(UTF[1], Lungime);
end;


function TReadCachedStream.ReadStringU: string;                                                         { Works for both Delphi7 and Delphi UNICODE }
VAR
   Lungime: Cardinal;
   UTF: UTF8String;
begin
 Read(Lungime, 4);                                                                           { Read length }
 if Lungime > 0
 then
  begin
   SetLength(UTF, Lungime);                                                                        { Read string }
   Read(UTF[1], Lungime);
   Result:= string(UTF);
  end
 else Result:= '';
end;






procedure TWriteCachedStream.WriteStrings(TSL: TStrings);                                              { Works for both Delphi7 and Delphi UNICODE }
begin
 WriteStringU(TSL.Text)
end;


procedure TReadCachedStream.ReadStrings(TSL: TStrings);                                              { Works for both Delphi7 and Delphi UNICODE }
begin
 TSL.Text:= ReadStringU;
end;











{ PADDING }

procedure TReadCachedStream.ReadPadding(CONST Bytes: Integer);
VAR b: TBytes;
begin
 if Bytes> 0 then
  begin
   SetLength(b, Bytes);
   Read(b[0], Bytes);
  end;
end;



procedure TWriteCachedStream.WritePadding(CONST Bytes: Integer= 1024);
VAR b: TBytes;
begin
 if Bytes> 0 then
  begin
   SetLength(b, Bytes);
   FillChar (b[0], Bytes, #0);
   Write(b[0], Bytes);
  end;
end;



{ SINGLE }

function TReadCachedStream.ReadSingle: Single;
begin
 Read(Result, 4);                                                                              { The size of Double is 8 bytes }
end;


procedure TWriteCachedStream.WriteSingle(CONST Sngl: Single);
begin
 Write(sngl, 4);                                                                             { The size of Double is 8 bytes }
end;




{ DATE }

function TReadCachedStream.ReadDate: TDateTime;
VAR Temp: Double;
begin
 Read(Temp, 8);                                                                              { The size of Double is 8 bytes }
 Result:= Temp;
end;


procedure TWriteCachedStream.WriteDate(CONST aDate: TDateTime);
VAR Temp: Double;
begin
 Temp:= aDate;
 Write(Temp, 8);                                                                             { The size of Double is 8 bytes }
end;




{ CARDINAL }

procedure TWriteCachedStream.WriteCardinal(CONST c: Cardinal);
begin
 Write(c, 4);
end;


function TReadCachedStream.ReadCardinal: Cardinal;
begin
 Read(Result, 4);
end;




{ INTEGER }

procedure TWriteCachedStream.WriteInteger(CONST i: Integer);
begin
 Write(i, 4);
end;


function TReadCachedStream.ReadInteger: Integer;
begin
 Read(Result, 4);
end;




{ BYTE }

procedure TWriteCachedStream.WriteByte(CONST b: Byte);
begin
 Write(b, 1);
end;


function TReadCachedStream.ReadByte: Byte;
begin
 Read(Result, 1);
end;




procedure TWriteCachedStream.WriteShortInt(CONST s: ShortInt);     //Signed 8bit: -128..127
begin
 Write(s, 1);
end;


function TReadCachedStream.ReadShortInt: ShortInt;
begin
 Read(Result, 1);
end;



procedure TWriteCachedStream.WriteSmallInt(CONST s: SmallInt);     //Signed 16bit: -32768..32767
begin
 Write(s, 2);
end;


function TReadCachedStream.ReadSmallInt: SmallInt;
begin
 Read(Result, 2);
end;






procedure TWriteCachedStream.WriteBytes(CONST Buffer: TByteDynArray);
begin
 WriteCardinal(Length(Buffer));
 Write(Buffer[0], High(Buffer));
end;


function TReadCachedStream.ReadBytes: TByteDynArray;
VAR Cnt: Cardinal;
begin
 Cnt:= ReadCardinal;
 SetLength(Result, Cnt);
 Read(Result[0], Cnt);
end;





{ BOOLEAN }

function TReadCachedStream.ReadBoolean: Boolean;
VAR b: byte;
begin
 Read(b, 1);                                  { Valid values for a Boolean are 0 and 1. If you put a different value into a Boolean variable then future behaviour is undefined. You should read into a byte variable b and assign b <> 0 into the Boolean. Or sanitise by casting the byte to ByteBool. Or you may choose to validate the value read from the file and reject anything other than 0 and 1. http://stackoverflow.com/questions/28383736/cannot-read-boolean-value-with-tmemorystream }
 Result:= b <> 0;
end;


procedure TWriteCachedStream.WriteBoolean(const b: bool);
begin
 Write(b, 1);
end;





{ WORD }

procedure TWriteCachedStream.WriteWord(const w: Word);
begin
 Write(W, 2);
end;


function TReadCachedStream.ReadWord: Word;
begin
 Read(Result, 2);
end;


function TReadCachedStream.ReadWordSwap: Word;
begin
 Read(Result, 2);
 SwapWord(Result);
end;





{ ENTER }

procedure TWriteCachedStream.WriteEnter;
VAR W: Word;
begin
 W:= $0D0A;
 Write(w, 2);
end;


function TReadCachedStream.ReadEnter: Word;  { Should return $0D0A (or 3338 zecimal) }
begin
 Read(Result, 2);
end;














{ READ LINE }

procedure TReadCachedStream.FirstLine;    { Go to first line. I need to use it after CountLines }
begin
 Buff       := '';
 BuffPos    := 0;
 LastAddress:= 0;
 Position   := 0;
 EOF        := FALSE;
end;



procedure TReadCachedStream.fillBuffer;
VAR s: AnsiString;
begin
 { Do I have to fill the buffer? }
 if (Length(Buff)- BuffPos < MaxLineLength)    { Buffer is getting empty }
 AND (LastAddress < Size) then  { I need this for TINY tiny files -> file that are smaller than the capacity of the buffer (MaxSeqLen) so I read them at a single pass }
  begin
   { Read more data }
   s:= ReadStringA(MaxLineLength);
   if s<> ''
   then
    begin
     LastAddress:= LastAddress+ Length(s);

     { Rebuild the buffer }
     Buff:= system.COPY(Buff, BuffPos, MaxInt);
     Buff:= Buff+ s;
     BuffPos:= 1;
    end;
  end;
end;





function TReadCachedStream.ReadLine: AnsiString;    { Read only non-empty lines. Empty lines are simply ignored. }
VAR
   ValidChar, i: Integer;                                           { ValidChar = the position of the caracter BEFORE the enter }
begin
 FillBuffer;
 Assert(BuffPos < Size, 'Trying to read beyond EOF!');

 LineOffset:= (Position- Length(Buff)) + (BuffPos- indexdiff);      { Used by Fasta Sorter to retrieve sequence start }
 ValidChar:= Length(Buff);                                          { I set it to the end of the buffer because I need it this way when I read the last line in the FastQ file and there is no ENTER at the end (the file doesn't end with an enter) }

 for i:= BuffPos to Length(Buff) DO                                 { Find the first enter }
  if Buff[i] in [CR, LF] then
   begin
    ValidChar:= i-1;
    Break;
   end;

 Result:= CopyTo(Buff, BuffPos, ValidChar);                         { +1 beacuse I want to skip over the '>' sign }
 BuffPos:= ValidChar+1;                                             { Skip over the ENTER character }

 { Find additional enter characters }
 WHILE (BuffPos+1 <= Length(Buff) )                                 { there is more data to read? }
 AND (Buff[BuffPos+1] in [CR, LF])
  DO inc(BuffPos);

 inc(BuffPos);                                                      { Now BuffPos points to the first char in the next row }

 EOF:= (BuffPos >= Length(Buff));                                   {+3 allow 2 enter characters at the end of the file }
end;


function TReadCachedStream.ReadEachLine: AnsiString;   { Read all lines, including the empty lines. The Enter must be a Windows Enter (CRLF) }
VAR
   ValidChar, i: Integer;                                                                       { ValidChar = the position of the caracter BEFORE the enter }
begin
 FillBuffer;
 Assert(BuffPos < Size, 'Trying to read beyond EOF!');

 LineOffset:= (Position- Length(Buff)) + (BuffPos- indexdiff);                                  { Used by Fasta Sorter to retrieve sequence start }
 ValidChar:= Length(Buff);                                                                      { I set it to the end of the buffer because I need it this way when I read the last line in the FastQ file and there is no ENTER at the end (the file doesn't end with an enter) }

 for i:= BuffPos to Length(Buff) DO                                                             { Find the first enter }
  if Buff[i] = CR then
   begin
    ValidChar:= i-1;
    Break;
   end;

 Result:= CopyTo(Buff, BuffPos, ValidChar);                                                     { +1 beacuse I want to skip over the '>' sign }
 BuffPos:= ValidChar+1;                                                                         { Skip over the ENTER character }

 { Find the LF character }
 if (BuffPos+1 <= Length(Buff) )                                                             { there is more data to read? }
 AND (Buff[BuffPos+1] = LF)
 then inc(BuffPos);

 inc(BuffPos);                                                                                  { Now BuffPos points to the first char in the next row }

 EOF:= (BuffPos >= Length(Buff));                                                               {+3 allow 2 enter characters at the end of the file }
end;



function TReadCachedStream.ReadLines(StopChar: AnsiChar): AnsiString;      { Read lines until 'StopChar' is encountered }  { Used by: TFasParser.ReadNextSample }
begin
 Result:= ReadLine;

 { Check if bases continues on the next line }
 WHILE (BuffPos < Length(Buff))                                                                 { Don't go out of the buffer }
 AND (Buff[BuffPos] <> StopChar)                                                                     { If next row doesn't start with '>' }
  DO Result:= Result+ ReadLine;                                                                 { Read bases until I encounter the next > sign }
end;




procedure TReadCachedStream.GoToOffset(Offset: Int64);   { Flush buffer, move to the specified offset. The next ReadLine will fill the buffer with data from that position }
begin
 Buff       := '';
 BuffPos    := 0;
 LastAddress:= Offset;
 Position   := Offset;
 EOF        := FALSE;
end;




function TReadCachedStream.CountLines: Int64;                                                   { NOTE!!! ccCore.CountLines is 5.2 times faster than this, but that function does not handle well Mac/Linux files!!! }

  procedure ReadLn;
  VAR
     ValidChar, i: Integer;                                                                       { ValidChar = the position of the caracter BEFORE the enter }
  begin
   FillBuffer;
   ValidChar:= Length(Buff);                                                                      { I set it to the end of the buffer because I need it this way when I read the last line in the FastQ file and there is no ENTER at the end (the file doesn't end with an enter) }

   { Find the first enter }
   for i:= BuffPos to Length(Buff) DO
    if Buff[i] in [CR, LF] then
     begin
      ValidChar:= i;
      Break;
     end;
   BuffPos:= ValidChar;                                                                         { Skip over the ENTER character }

   { Find additional enter characters }
   WHILE (BuffPos+1 <= Length(Buff) )                                                             { there is more data to read? }
   AND (Buff[BuffPos+1] in [CR, LF])
    DO inc(BuffPos);

   inc(BuffPos);   //Now BuffPos points to the first char in the next row
  end;

begin
 Result:= 0;

 FirstLine;
 fillBuffer;

 WHILE BuffPos < Length(Buff) DO  {This checks for EOF }
  begin
   ReadLn;       {TODO 1: speed improvement: modify the ReadLine function to a procedure. I don't need to actually dead the text. I only need to find the enters }
   Inc(Result);
  end;
end;




function TReadCachedStream.CountAppearance(C: AnsiChar): Int64;    { Used by TFasParser.CountSequences }
var
   s: AnsiString;    { When I open the file I don't know how many sequences I have inside. CountSequences reads all sequences to find out how many I have }
   BuffPo: Int64;
begin
 Result:= 0;
 BuffPo:= 0;
 FirstLine;

 WHILE BuffPo< Size DO
  begin
   s:= ReadStringA(1024*KB);
   Inc(BuffPo, 1024*KB);
   Result:= Result+ Cardinal(ccCore.CountAppearance(c, s));
  end;
end;








end.(*=============================================================================================





del
function GetFileSize2(CONST sFilename: string): Int64;                                             { works with big files  -  http://www.tek-tips.com/viewthread.cfm?qid=520316 }
VAR BigFileStream: TFileStream;
begin
 TRY
   BigFileStream:= TFileStream.Create(sFilename, fmOpenRead or fmShareDenyNone);
   TRY
     Result:= BigFileStream.Size;
   FINALLY
     FreeAndNil(BigFileStream);
   END;
 except_
   Result:= 0;
 END;
end;

