UNIT ccStreamFile;

{--------------------------------------------------------------------------------------------------
  Gabriel Moraru
  2021.10.15
  See Copyright.txt

  It loads the entire contents of a file into the memory so don't use it with large files.

  DOCS:
     Wrtiting string to TMemoryStream - Pointer to string - http://stackoverflow.com/questions/3808104/wrtiting-string-to-tmemorystream-pointer-to-string
     How do I put a string onto a stream? http://pages.cs.wisc.edu/~rkennedy/string-stream

  Read vs ReadBuffer:
     Read treats Count as an upper bound.
     The ReadBuffer, by contrast, raises an exception if Count bytes cannot be read. So this is better if I don't accept errors in my files.

  Also see TBinaryReader / TBinaryWriter
    http://docwiki.embarcadero.com/CodeExamples/Tokyo/en/TBinaryReader_and_TBinaryWriter_(Delphi)
--------------------------------------------------------------------------------------------------}

INTERFACE
USES
   Winapi.Windows, System.SysUtils, System.Classes;

TYPE
  TCubicFileStream= class(TFileStream)
    private
    public
     function  ReadStringU: string;                                                                { Works for both Delphi7 and Delphi UNICODE }
     function  ReadStringA  (CONST Lungime: integer): AnsiString; overload;                        { It will raise an error if there is not enough data (Lungime) to read }
     function  ReadStringAR (CONST Lungime: integer): AnsiString;                                  { This is the relaxed version. It won't raise an error if there is not enough data (Lungime) to read }
     function  ReadStringA : AnsiString;                          overload;                        { It automatically detects the length of the string }
     procedure ReadStringList   (TSL: TStringList);
     {}
     function  RevReadLongword : Cardinal;                                                         { REVERSE READ - read 4 bytes and swap their position }
     function  RevReadLongInt  : Longint;
     function  RevReadWord     : Word;                                                             { REVERSE READ - read 2 bytes and swap their position }
     {}
     function  ReadInteger     : Longint;
     function  ReadInt64: Int64;
     function  ReadUInt64: UInt64;
     function  ReadCardinal    : Cardinal;
     function  ReadRevInt      : Cardinal;                                                         { REVERSE READ - read 4 bytes and swap their position - reads a UInt4 }
     function  ReadBoolean     : Boolean;
     function  ReadByte        : Byte;
     function  ReadWord        : Word;
     function  ReadDate        : TDateTime;
     procedure ReadPadding         (CONST Bytes: Integer);
     function  ReadStringUNoLen    (CONST Lungime: Integer): string;
     function  ReadEnter: Boolean;

     procedure WriteEnter;
     procedure WriteStringUNoLen   (CONST s: string);
     procedure WriteStringList     (CONST TSL: TStringList);
     procedure WriteStringANoLen   (CONST s: AnsiString);                                          { Write the string but don't write its length }
     procedure WriteStringA        (CONST s: AnsiString);
     procedure WriteStringU        (CONST s: string);                                              { Works for both Delphi7 and Delphi UNICODE }
     procedure WriteUInt64         (const i: UInt64);
     procedure WriteInteger        (CONST i: Longint);
     procedure WriteBoolean        (CONST b: bool);
     procedure WriteCardinal       (CONST c: Cardinal);
     procedure WritePadding        (CONST Bytes: Integer);
     procedure WriteDate           (CONST aDate: TDateTime);
     procedure WriteByte           (CONST aByte: Byte);
     procedure WriteWord           (CONST aWord: Word);

     function  ReadCheckPoint  : Boolean;
     procedure WriteCheckPoint;
     function  ReadMagicNo         (const MagicNo: AnsiString): Boolean;
     procedure WriteMagicNo        (const MagicNo: AnsiString);

     function  AsStringU: String;                                                                  { Returns the content of the stream as a string }
     function  AsString: AnsiString;
     procedure PushData(CONST Data: AnsiString);                                                   { Put binary data (or text) into the stream }
  end;

IMPLEMENTATION
USES ccBinary;

CONST ctCheckPoint= '<*>Checkpoint<*>';



 






{--------------------------------------------------------------------------------------------------
   ASCII STRINGS
--------------------------------------------------------------------------------------------------}
function TCubicFileStream.ReadStringA: AnsiString;                                                     { It automatically detects the length of the string }
VAR Lungime: LongInt;
begin
 ReadBuffer(Lungime, 4);                                                                           { First, find out how many characters to read }
 Result:= ReadStringA(Lungime);                                                                    { Do the actual strign reading }
end;


procedure TCubicFileStream.WriteStringA(CONST s: AnsiString);
VAR Lungime: cardinal;
begin
 Lungime:= Length(s);
 WriteBuffer(Lungime, SizeOf(Lungime));
 if Lungime > 0                                                                                    { This makes sure 's' is not empty. Else I will get a RangeCheckError at runtime }
 then WriteBuffer(s[1], Lungime);
end;




{--------------------------------------------------------------------------------------------------
   STRING WITHOUT LENGTH
--------------------------------------------------------------------------------------------------}
procedure TCubicFileStream.WriteStringANoLen(CONST s: AnsiString);                                 { Write the string but don't write its length }
begin
 Assert(s<> '', 'WriteStringA - The string is empty');                                             { This makes sure 's' is not empty. Else I will get a RangeCheckError at runtime }
 WriteBuffer(s[1], Length(s));
end;


function TCubicFileStream.ReadStringA(CONST Lungime: integer): AnsiString;                         { You need to specify the length of the string }
begin
 Assert(Lungime> -1, 'TCubicFileStream-String size is: '+ IntToStr(Lungime));

 if (Lungime+ Position > Size)
 then raise exception.Create('TCubicFileStream-Invalid string size: '+ IntToStr(Lungime));

 if Lungime= 0
 then Result:= ''
 else
  begin
   SetLength(Result, Lungime);                                                                     { Initialize the result }
   ReadBuffer(Result[1], Lungime);
  end;
end;


function TCubicFileStream.ReadStringAR(CONST Lungime: integer): AnsiString;                        { This is the relaxed/safe version. It won't raise an error if there is not enough data (Lungime) to read }
VAR ReadBytes: Integer;
begin
 Assert(Lungime> -1, 'TCubicFileStream-String size is: '+ IntToStr(Lungime));

 if Lungime= 0
 then Result:= ''
 else
  begin
   SetLength(Result, Lungime);                                                                     { Initialize the result }
   ReadBytes:= Read(Result[1], Lungime);
   if ReadBytes<> Lungime                                                                          { Not enough data to read? }
   then SetLength(Result, ReadBytes);
  end;
end;




{--------------------------------------------------------------------------------------------------
   UNICODE STRINGS
--------------------------------------------------------------------------------------------------}
procedure TCubicFileStream.WriteStringU(CONST s: string);                                          { Works for both Delphi7 and Delphi UNICODE }
VAR
  Lungime: cardinal;
  UTF: UTF8String;
begin
 UTF := UTF8String(s);

 { Write length }
 Lungime := Length(UTF);
 WriteBuffer(Lungime, SizeOf(Lungime));

 { Write string }
 if Lungime > 0
 then WriteBuffer(UTF[1], Lungime);
end;


function TCubicFileStream.ReadStringU: string;                                                         { Works for both Delphi7 and Delphi UNICODE }
VAR
   Lungime: Cardinal;
   UTF: UTF8String;
begin
 ReadBuffer(Lungime, 4);                                                                           { Read length }
 if Lungime > 0
 then
  begin
   SetLength(UTF, Lungime);                                                                        { Read string }
   ReadBuffer(UTF[1], Lungime);
   Result:= string(UTF);
  end
 else Result:= '';
end;






procedure TCubicFileStream.WriteStringUNoLen(CONST s: string);                                         { Works for both Delphi7 and Delphi UNICODE }
VAR UTF: UTF8String;
begin
 UTF := UTF8String(s);
 if Length(UTF) > 0
 then WriteBuffer(UTF[1], Length(UTF));
end;


function TCubicFileStream.ReadStringUNoLen(CONST Lungime: Integer): string;                            { Works for both Delphi7 and Delphi UNICODE }
VAR UTF: UTF8String;
begin
 if Lungime > 0
 then
  begin
   SetLength(UTF, Lungime);
   ReadBuffer(UTF[1], Lungime);
   Result:= string(UTF);
  end
 else Result:= '';
end;





function TCubicFileStream.ReadMagicNo(CONST MagicNo: AnsiString): Boolean;                          { Read a string from disk and compare it with MagicNo. Retursn TRUE if it matches }
VAR MagNo: AnsiString;
begin
 MagNo:= ReadStringA(Length(MagicNo));
 Result:= MagicNo = MagicNo;
end;


procedure TCubicFileStream.WriteMagicNo(CONST MagicNo: AnsiString);
begin
 Assert(MagicNo > '', 'Magic number is empty!');
 Write(MagicNo[1], Length(MagicNo));
end;










{}
procedure TCubicFileStream.WriteStringList(CONST TSL: TStringList);
begin
 WriteStringU(TSL.Text);
end;


procedure TCubicFileStream.ReadStringList(TSL: TStringList);
begin
 TSL.Text:= String(ReadStringA);
end;










{--------------------------------------------------------------------------------------------------
                                    PADDING
--------------------------------------------------------------------------------------------------}
procedure TCubicFileStream.WritePadding(CONST Bytes: Integer);
VAR s: string;
begin
 if Bytes> 0 then
  begin
   s:= StringOfChar(#0, Bytes); // GenerateString(Bytes, #0);
   WriteBuffer(s[1], Bytes);
  end;
end;

procedure TCubicFileStream.ReadPadding(CONST Bytes: Integer);
VAR s: string;
begin
 if Bytes> 0 then
  begin
   SetLength(s, Bytes);
   ReadBuffer(s[1], Bytes);
  end;
end;




function TCubicFileStream.ReadEnter: Boolean;                                                      { Returns TRUE if the byte read is LF }
VAR aByte: Byte;
begin
 ReadBuffer(aByte, 1);
 Result:= aByte= Byte(#10);
end;

procedure TCubicFileStream.WriteEnter;
VAR aByte: Byte;
begin
 aByte:= Byte(#10);
 WriteBuffer(abyte, 1);
end;






{--------------------------------------------------------------------------------------------------
                                NUMBERS
--------------------------------------------------------------------------------------------------}
function TCubicFileStream.ReadRevInt: Cardinal;                                                        { REVERSE READ - read 4 bytes and swap their position - reads a UInt4. Used in 'UNIT ReadSCF' }
begin
 ReadBuffer(Result, 4);
 SwapCardinal(Result);
end;

function TCubicFileStream.ReadInt64: Int64;
begin
 ReadBuffer(Result, 8);
end;




function TCubicFileStream.ReadUInt64: UInt64;
begin
 ReadBuffer(Result, 8);
end;

procedure TCubicFileStream.WriteUInt64(CONST i: UInt64);
begin
 WriteBuffer(i, 8);                                                                                { Longint = Fundamental integer type. Its size will not change! }
end;




function TCubicFileStream.ReadInteger: Longint;
begin
 ReadBuffer(Result, 4);
end;

procedure TCubicFileStream.WriteInteger(CONST i: Longint);
begin
 WriteBuffer(i, 4);                                                                                { Longint = Fundamental integer type. Its size will not change! }
end;




procedure TCubicFileStream.WriteBoolean(CONST b: bool);
begin
 WriteBuffer(b, 1);
end;

function TCubicFileStream.ReadBoolean: Boolean;
VAR b: byte;
begin
 ReadBuffer(b, 1);    { Valid values for a Boolean are 0 and 1. If you put a different value into a Boolean variable then future behaviour is undefined. You should read into a byte variable b and assign b <> 0 into the Boolean. Or sanitise by casting the byte to ByteBool. Or you may choose to validate the value read from the file and reject anything other than 0 and 1. http://stackoverflow.com/questions/28383736/cannot-read-boolean-value-with-tmemorystream }
 Result:= b <> 0;
end;




procedure TCubicFileStream.WriteCardinal(CONST c: Cardinal);
begin
 WriteBuffer(c, 4);
end;

function TCubicFileStream.ReadCardinal: Cardinal;                                                      { Cardinal IS NOT a fundamental type!! }
begin
 ReadBuffer(Result, 4);
end;




procedure TCubicFileStream.WriteByte(CONST aByte: Byte);
begin
 WriteBuffer(aByte, 1);
end;

function TCubicFileStream.ReadByte: Byte;
begin
 ReadBuffer(Result, 1);
end;




procedure TCubicFileStream.WriteWord(CONST aWord: Word);
begin
 WriteBuffer(aWord, 2);
end;

function TCubicFileStream.ReadWord: Word;
begin
 ReadBuffer(Result, 2);
end;









{   DATE   }
function TCubicFileStream.ReadDate: TDateTime;
VAR Temp: Double;
begin
 ReadBuffer(Temp, 8);                                                                              { The size of Double is 8 bytes }
 Result:= Temp;
end;


procedure TCubicFileStream.WriteDate(CONST aDate: TDateTime);
VAR Temp: Double;
begin
 Temp:= aDate;
 WriteBuffer(Temp, 8);                                                                             { The size of Double is 8 bytes }
end;










{--------------------------------------------------------------------------------------------------
                                READ MACINTOSH
--------------------------------------------------------------------------------------------------}
function TCubicFileStream.RevReadLongword: Cardinal;                                                   { REVERSE READ - read 4 bytes and swap their position }
begin
  ReadBuffer( Result, 4);
  SwapCardinal(Result);
end;


function TCubicFileStream.RevReadLongInt: Longint;
begin
  ReadBuffer(Result, 4);
  SwapInt(Result);
end;


function TCubicFileStream.RevReadWord: Word;                                                           { REVERSE READ - read 2 bytes and swap their position }
begin
  ReadBuffer(Result, 2);
  Result:= Swap(Result);                                                                           { Exchanges high order byte with the low order byte of an integer or word. In Delphi code, Swap exchanges the high-order bytes with the low-order bytes of the argument. X is an expression of type SmallInt, as a 16-bit value, or Word. This is provided for backward compatibility only. }
end;




{--------------------------------------------------------------------------------------------------
                     PUSH/LOAD DATA DIRECTLY INTO THE STREAM
--------------------------------------------------------------------------------------------------}

function TCubicFileStream.AsString: AnsiString;                                                        { Put the content of the stream into a string }
begin
 Position:= 0;
 Result:= ReadStringA(Size);
end;


function TCubicFileStream.AsStringU: string;                                                           {THIS SHOULD NEVER BE USED. TO BE DELETED! }
begin
 Result:= string(AsString);
end;


procedure TCubicFileStream.PushData(CONST Data: AnsiString);
begin
 ////////Clear;                                                                                            { Sets the Memory property to nil (Delphi). Sets the Position property to 0. Sets the Size property to 0. }
 WriteBuffer(Data[1], Length(Data));
end;











{--------------------------------------------------------------------------------------------------
                                Others
--------------------------------------------------------------------------------------------------}
function TCubicFileStream.ReadCheckPoint: Boolean;
begin
 Result:= ReadStringA = ctCheckPoint;
end;

procedure TCubicFileStream.WriteCheckPoint;
begin
 WriteStringA(ctCheckPoint);
end;












end.//=============================================================================================





