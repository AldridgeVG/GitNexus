{ Delphi 字符串操作示例 }
unit StringOperations;

interface

uses
  Windows, SysUtils, Classes, StrUtils;

  {$REGION ' 字符串处理函数 '}

  function FormatAppID(const AHigh, ALow: DWORD; const PID: Integer): string;
  function FormatLogFileName(const AppName, StartDate, StartTime: string;
    const PID: Integer; const SliceCount: Integer = 0): string;
  function IncludeChinese(AStr: string): Boolean;
  function ReversePos(SubStr, S: String): Integer;
  function ListToStr(AList: TStringList; ADelimiter: string): string;

  {$ENDREGION}

  {$REGION ' 编码转换函数 '}

  function UrlDecode(AUrl: string): string;
  function UrlEncode(AUrl: string): string;
  function Base64Encode(const Input: string): string;
  function Base64Decode(const Input: string): string;

  {$ENDREGION}

  {$REGION ' 路径处理函数 '}

  function ExtractFileNameExt(const FileName: string): string;
  function ChangeFileExt(const FileName, Extension: string): string;
  function CombinePath(const Path1, Path2: string): string;

  {$ENDREGION}

implementation

uses
  HTTPApp, EncdDecd;

{$REGION ' 字符串处理函数 '}

function FormatAppID(const AHigh, ALow: DWORD; const PID: Integer): string;
begin
  // Format 函数示例
  Result := Format('%x-%x-%d', [AHigh, ALow, PID]);
end;

function FormatLogFileName(const AppName, StartDate, StartTime: string;
  const PID: Integer; const SliceCount: Integer = 0): string;
var
  DateTimeStr: string;
begin
  // StringReplace 函数示例
  DateTimeStr := StringReplace(StartDate, '-', '', [rfReplaceAll]) +
    StringReplace(StartTime, ':', '', [rfReplaceAll]);

  // 条件格式示例
  if SliceCount = 0 then
    Result := Format('%s-%s-%d', [AppName, DateTimeStr, PID])
  else
    Result := Format('%s-%s-%d-%d', [AppName, DateTimeStr, PID, SliceCount]);
end;

function IncludeChinese(AStr: string): Boolean;
var
  p: PWideChar;
begin
  Result := False;
  p := PWideChar(AStr);
  while p^ <> #0 do
  begin
    case p^ of
      #$4E00 .. #$9FA5: Exit(True);  // 中文字符范围
    end;
    Inc(p);
  end;
end;

function ReversePos(SubStr, S: String): Integer;
var
  i: Integer;
begin
  // ReverseString 和 Pos 组合使用
  i := Pos(ReverseString(SubStr), ReverseString(S));
  if i > 0 then
    i := Length(S) - i - Length(SubStr) + 2;
  Result := i;
end;

function ListToStr(AList: TStringList; ADelimiter: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to AList.Count - 1 do
  begin
    if Result = '' then
      Result := AList[I]
    else
      Result := Result + ADelimiter + AList[I];
  end;
end;

{$ENDREGION}

{$REGION ' 编码转换函数 '}

function UrlDecode(AUrl: string): string;
begin
  // HTTPDecode 进行 URL 解码
  Result := UTF8ToString(HTTPDecode(AnsiString(AUrl)));
end;

function UrlEncode(AUrl: string): string;
begin
  // HTTPEncode 进行 URL 编码
  Result := string(HTTPEncode(UTF8Encode(AUrl)));
  // 替换特定字符
  Result := StringReplace(Result, '+', '%20', [rfReplaceAll]);
  Result := StringReplace(Result, '%2F', '/', [rfReplaceAll]);
end;

function Base64Encode(const Input: string): string;
var
  Bytes: TBytes;
begin
  Bytes := TEncoding.UTF8.GetBytes(Input);
  Result := string(EncodeBase64(Bytes));
end;

function Base64Decode(const Input: string): string;
var
  Bytes: TBytes;
begin
  Bytes := DecodeBase64(AnsiString(Input));
  Result := TEncoding.UTF8.GetString(Bytes);
end;

{$ENDREGION}

{$REGION ' 路径处理函数 '}

function ExtractFileNameExt(const FileName: string): string;
begin
  // ExtractFileName 提取文件名
  Result := ExtractFileName(FileName);
end;

function ChangeFileExt(const FileName, Extension: string): string;
begin
  // ChangeFileExt 改变文件扩展名
  Result := SysUtils.ChangeFileExt(FileName, Extension);
end;

function CombinePath(const Path1, Path2: string): string;
begin
  // IncludeTrailingPathDelimiter 确保路径分隔符
  Result := IncludeTrailingPathDelimiter(Path1) + Path2;
end;

{$ENDREGION}

{ ========== 字符串操作综合示例 ========== }

function ParseConnectionString(const ConnStr: string): TConnParams;
var
  Parts: TStringList;
  I: Integer;
  Key, Value: string;
  EqPos: Integer;
  Part: string;
begin
  Result := Default(TConnParams);
  Parts := TStringList.Create;
  try
    // 使用分隔符分割字符串
    Parts.Delimiter := ';';
    Parts.StrictDelimiter := True;
    Parts.DelimitedText := ConnStr;

    for I := 0 to Parts.Count - 1 do
    begin
      Part := Trim(Parts[I]);
      if Part = '' then Continue;

      EqPos := Pos('=', Part);
      if EqPos > 0 then
      begin
        Key := Trim(Copy(Part, 1, EqPos - 1));
        Value := Trim(Copy(Part, EqPos + 1, MaxInt));

        // 移除引号
        if (Length(Value) >= 2) and
           (Value[1] = '"') and (Value[Length(Value)] = '"') then
          Value := Copy(Value, 2, Length(Value) - 2);

        // 根据键名赋值
        if SameText(Key, 'Server') then
          Result.Server := Value
        else if SameText(Key, 'Database') then
          Result.Database := Value
        else if SameText(Key, 'User') then
          Result.User := Value
        else if SameText(Key, 'Password') then
          Result.Password := Value;
      end;
    end;
  finally
    Parts.Free;
  end;
end;

function BuildQualifiedName(const Namespace, Name: string): string;
begin
  // 使用命名空间构建限定名
  if Namespace <> '' then
    Result := Format('%s.%s', [Namespace, Name])
  else
    Result := Name;
end;

function NormalizeLineEndings(const S: string): string;
begin
  // 统一换行符
  Result := S;
  Result := StringReplace(Result, #13#10, #10, [rfReplaceAll]);  // CRLF -> LF
  Result := StringReplace(Result, #13, #10, [rfReplaceAll]);      // CR -> LF
  Result := StringReplace(Result, #10, sLineBreak, [rfReplaceAll]); // LF -> 系统换行符
end;

function IndentText(const Text: string; const Indent: string): string;
var
  Lines: TStringList;
  I: Integer;
begin
  Lines := TStringList.Create;
  try
    Lines.Text := Text;
    for I := 0 to Lines.Count - 1 do
    begin
      if Lines[I] <> '' then
        Lines[I] := Indent + Lines[I];
    end;
    Result := Lines.Text;
  finally
    Lines.Free;
  end;
end;

function MatchesMask(const FileName, Mask: string): Boolean;
begin
  // 使用 Mask 进行通配符匹配
  Result := SysUtils.MatchesMask(FileName, Mask);
end;

{ ========== 字符串Builder模式 ========== }

type
  TStringBuilderHelper = class helper for TStringBuilder
  public
    procedure AppendLine(const Value: string);
    procedure AppendFormat(const Format: string; const Args: array of const);
  end;

procedure TStringBuilderHelper.AppendLine(const Value: string);
begin
  Self.Append(Value);
  Self.AppendLine;
end;

procedure TStringBuilderHelper.AppendFormat(const Format: string; const Args: array of const);
begin
  Self.Append(System.SysUtils.Format(Format, Args));
end;

end.
