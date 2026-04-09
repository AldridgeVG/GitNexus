{ Delphi 内存管理和指针示例 }
unit MemoryManagement;

interface

uses
  Windows, SysUtils, Classes;

type
  // ========== 动态数组操作 ==========

  TArrayHelper = class
  public
    class procedure Append<T>(var Arr: TArray<T>; const Value: T);
    class procedure Insert<T>(var Arr: TArray<T>; Index: Integer; const Value: T);
    class procedure Delete<T>(var Arr: TArray<T>; Index: Integer);
    class function IndexOf<T>(const Arr: TArray<T>; const Value: T): Integer;
    class function Contains<T>(const Arr: TArray<T>; const Value: T): Boolean;
  end;

  // ========== 内存流操作 ==========

  TMemoryStreamHelper = class
  public
    class function ToBytes(Stream: TMemoryStream): TBytes;
    class procedure FromBytes(Stream: TMemoryStream; const Bytes: TBytes);
    class function Clone(Stream: TMemoryStream): TMemoryStream;
  end;

  // ========== 指针操作示例 ==========

  PIntegerArray = ^TIntegerArray;
  TIntegerArray = array[0..MaxInt div SizeOf(Integer) - 1] of Integer;

  PByteArray = ^TByteArray;
  TByteArray = array[0..MaxInt - 1] of Byte;

  procedure SwapIntegers(P1, P2: PInteger);
  procedure FillMemoryBlock(Dest: Pointer; Size: Integer; Value: Byte);
  procedure CopyMemoryBlock(Source, Dest: Pointer; Size: Integer);
  function CompareMemoryBlocks(P1, P2: Pointer; Size: Integer): Integer;

  // ========== 不安全代码示例 ==========

  procedure UnsafeArrayAccess;
  procedure PointerArithmetic;

implementation

uses
  Generics.Defaults;

{ ========== TArrayHelper ========== }

class procedure TArrayHelper.Append<T>(var Arr: TArray<T>; const Value: T);
var
  Len: Integer;
begin
  Len := Length(Arr);
  SetLength(Arr, Len + 1);
  Arr[Len] := Value;
end;

class procedure TArrayHelper.Insert<T>(var Arr: TArray<T>; Index: Integer; const Value: T);
var
  Len, I: Integer;
begin
  Len := Length(Arr);
  if (Index < 0) or (Index > Len) then
    raise EListError.CreateFmt('Index %d out of bounds', [Index]);

  SetLength(Arr, Len + 1);
  for I := Len - 1 downto Index do
    Arr[I + 1] := Arr[I];
  Arr[Index] := Value;
end;

class procedure TArrayHelper.Delete<T>(var Arr: TArray<T>; Index: Integer);
var
  Len, I: Integer;
begin
  Len := Length(Arr);
  if (Index < 0) or (Index >= Len) then
    raise EListError.CreateFmt('Index %d out of bounds', [Index]);

  for I := Index to Len - 2 do
    Arr[I] := Arr[I + 1];
  SetLength(Arr, Len - 1);
end;

class function TArrayHelper.IndexOf<T>(const Arr: TArray<T>; const Value: T): Integer;
var
  I: Integer;
  Comparer: IEqualityComparer<T>;
begin
  Comparer := TEqualityComparer<T>.Default;
  for I := Low(Arr) to High(Arr) do
  begin
    if Comparer.Equals(Arr[I], Value) then
      Exit(I);
  end;
  Result := -1;
end;

class function TArrayHelper.Contains<T>(const Arr: TArray<T>; const Value: T): Boolean;
beginn  Result := IndexOf<T>(Arr, Value) >= 0;
end;

{ ========== TMemoryStreamHelper ========== }

class function TMemoryStreamHelper.ToBytes(Stream: TMemoryStream): TBytes;
begin
  SetLength(Result, Stream.Size);
  if Stream.Size > 0 then
  begin
    Stream.Position := 0;
    Stream.Read(Result[0], Stream.Size);
  end;
end;

class procedure TMemoryStreamHelper.FromBytes(Stream: TMemoryStream; const Bytes: TBytes);
begin
  Stream.Clear;
  if Length(Bytes) > 0 then
  begin
    Stream.Write(Bytes[0], Length(Bytes));
    Stream.Position := 0;
  end;
end;

class function TMemoryStreamHelper.Clone(Stream: TMemoryStream): TMemoryStream;
begin
  Result := TMemoryStream.Create;
  try
    Stream.Position := 0;
    Result.CopyFrom(Stream, Stream.Size);
    Result.Position := 0;
  except
    Result.Free;
    raise;
  end;
end;

{ ========== 指针操作 ========== }

procedure SwapIntegers(P1, P2: PInteger);
var
  Temp: Integer;
begin
  Temp := P1^;
  P1^ := P2^;
  P2^ := Temp;
end;

procedure FillMemoryBlock(Dest: Pointer; Size: Integer; Value: Byte);
begin
  FillChar(Dest^, Size, Value);
end;

procedure CopyMemoryBlock(Source, Dest: Pointer; Size: Integer);
begin
  Move(Source^, Dest^, Size);
end;

function CompareMemoryBlocks(P1, P2: Pointer; Size: Integer): Integer;
var
  B1, B2: PByte;
  I: Integer;
begin
  B1 := PByte(P1);
  B2 := PByte(P2);

  for I := 0 to Size - 1 do
  begin
    if B1[I] <> B2[I] then
    begin
      Result := B1[I] - B2[I];
      Exit;
    end;
  end;
  Result := 0;
end;

{ ========== 不安全代码示例 ========== }

procedure UnsafeArrayAccess;
var
  IntArray: array of Integer;
  P: PInteger;
  I: Integer;
begin
  SetLength(IntArray, 10);
  P := @IntArray[0];

  for I := 0 to High(IntArray) do
  begin
    P^ := I * 10;
    Inc(P);
  end;
end;

procedure PointerArithmetic;
var
  Buffer: array of Byte;
  P: PByte;
  Offset: Integer;
begin
  SetLength(Buffer, 256);
  P := @Buffer[0];
  for Offset := 0 to 255 do
  begin
    P^ := Byte(Offset);
    Inc(P);
  end;
end;

end.
