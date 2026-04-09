{ Delphi 控制流语句示例 }
unit ControlFlow;

interface

uses
  Windows, SysUtils, Classes;

  function CompareVersion(V1, V2: string; Delimiter: Char = '.'): Integer;
  function GetGasType(AGasStr: string): Integer;
  function ValidTaskIdFormat(const ATaskId: string): Boolean;
  procedure ProcessLogFiles(const ANamePrefix: string);
  function BinarySearch(const Arr: array of Integer; const Target: Integer): Integer;
  function Factorial(N: Integer): Int64;
  function Fibonacci(N: Integer): Int64;

implementation

uses
  Math;

{ ========== 条件语句示例 ========== }

function CompareVersion(V1, V2: string; Delimiter: Char = '.'): Integer;
var
  List1, List2: TStringList;
  I, e1, e2: Integer;
begin
  List1 := TStringList.Create;
  List2 := TStringList.Create;
  try
    // 设置分隔符
    List1.StrictDelimiter := True;
    List2.StrictDelimiter := True;
    List1.Delimiter := Delimiter;
    List2.Delimiter := Delimiter;
    List1.DelimitedText := V1;
    List2.DelimitedText := V2;

    // for 循环比较版本号各部分
    for I := 0 to Min(List1.Count, List2.Count) - 1 do
    begin
      e1 := StrToIntDef(List1[I], -1);
      e2 := StrToIntDef(List2[I], -1);
      if e1 > e2 then Exit(1)
      else if e1 < e2 then Exit(-1);
    end;
    Result := List1.Count - List2.Count;
  finally
    FreeAndNil(List1);
    FreeAndNil(List2);
  end;
end;

function GetGasType(AGasStr: string): Integer;
begin
  // if-else if-else 链示例
  Result := 0;
  if SameText(AGasStr, 'Air') then
    Result := 1
  else if SameText(AGasStr, 'O2') then
    Result := 2
  else if SameText(AGasStr, 'N2') then
    Result := 3
  else if SameText(AGasStr, 'H-Air') then
    Result := 4
  else if SameText(AGasStr, 'H-O2') then
    Result := 5
  else if SameText(AGasStr, 'H-N2') then
    Result := 6
  else if SameText(AGasStr, 'Low') then
    Result := 81
  else if SameText(AGasStr, 'High') then
    Result := 82;
end;

function ValidTaskIdFormat(const ATaskId: string): Boolean;
begin
  // 复合条件判断示例
  Result := (Length(ATaskId) = 24) and
            ((ATaskId[1] = 'T') or (Copy(ATaskId, 1, 3) = 'MGT'));
end;

{ ========== 循环语句示例 ========== }

procedure ProcessLogFiles(const ANamePrefix: string);
var
  Target: string;
  Sch: TSearchRec;
  Count: Integer;
begin
  Count := 0;
  Target := Format('%s\%s*.log', [LogFileDir, ANamePrefix]);

  // repeat-until 循环示例
  if FindFirst(Target, faAnyFile, Sch) = 0 then
  begin
    repeat
      if ((Sch.Name = '.') or (Sch.Name = '..')) then Continue;

      // while 循环示例
      while Count < MaxFiles do
      begin
        Inc(Count);
        ProcessFile(Sch.Name);
        Break;
      end;

    until FindNext(Sch) <> 0;
    FindClose(Sch);
  end;
end;

{ ========== Case 语句示例 ========== }

function GetLogLevelColor(Level: Integer): TColor;
begin
  case Level of
    0: Result := clBlack;      // Debug
    1: Result := clGreen;      // Info
    2: Result := clYellow;     // Warning
    3: Result := clRed;        // Error
    4: Result := clPurple;     // Fatal
  else
    Result := clGray;          // Unknown
  end;
end;

procedure HandleCommand(const Cmd: string);
begin
  case AnsiIndexStr(Cmd, ['start', 'stop', 'restart', 'status']) of
    0: StartService;
    1: StopService;
    2: RestartService;
    3: ShowStatus;
  else
    UnknownCommand(Cmd);
  end;
end;

{ ========== 异常处理示例 ========== }

function SafeDivide(A, B: Double): Double;
begin
  try
    if B = 0 then
      raise Exception.Create('Division by zero');
    Result := A / B;
  except
    on E: EDivByZero do
    begin
      Result := 0;
      LogError('Division by zero error');
    end;
    on E: Exception do
    begin
      Result := -1;
      LogError(E.Message);
      raise;  // 重新抛出异常
    end;
  end;
end;

procedure ProcessFileStream(const FileName: string);
var
  Stream: TFileStream;
begin
  Stream := nil;
  try
    try
      Stream := TFileStream.Create(FileName, fmOpenRead);
      // 处理文件内容
      ProcessData(Stream);
    except
      on E: EFOpenError do
        WriteLog('Cannot open file: ' + FileName);
      on E: Exception do
        WriteLog('Error: ' + E.Message);
    end;
  finally
    // 确保资源释放
    if Stream <> nil then
      Stream.Free;
  end;
end;

function ReadConfigValue(const Key: string; out Value: string): Boolean;
begin
  Result := False;
  Value := '';

  try
    Value := Config[Key];
    Result := True;
  except
    // 静默处理异常
  end;
end;

{ ========== 递归示例 ========== }

function Factorial(N: Integer): Int64;
begin
  // 递归计算阶乘
  if N <= 1 then
    Result := 1
  else
    Result := N * Factorial(N - 1);
end;

function Fibonacci(N: Integer): Int64;
begin
  // 递归计算斐波那契数列
  if N <= 0 then
    Result := 0
  else if N = 1 then
    Result := 1
  else
    Result := Fibonacci(N - 1) + Fibonacci(N - 2);
end;

{ ========== With 语句示例 ========== }

procedure InitializeStartupInfo(var SI: TStartupInfo);
begin
  with SI do
  begin
    cb := SizeOf(TStartupInfo);
    lpReserved := nil;
    lpDesktop := nil;
    lpTitle := nil;
    dwFlags := STARTF_USESHOWWINDOW;
    wShowWindow := SW_HIDE;
    cbReserved2 := 0;
    lpReserved2 := nil;
  end;
end;

procedure FillSecurityAttributes(var SA: TSecurityAttributes);
begin
  with SA do
  begin
    nLength := SizeOf(TSecurityAttributes);
    bInheritHandle := True;
    lpSecurityDescriptor := nil;
  end;
end;

{ ========== 标签和 Goto 示例（不推荐但支持） ========== }

function FindInArray(const Arr: array of Integer; Target: Integer): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := Low(Arr) to High(Arr) do
  begin
    if Arr[I] = Target then
    begin
      Result := I;
      Exit;  // 立即退出函数
    end;
  end;
end;

procedure ProcessWithExit(const Data: string);
var
  Stream: TStream;
begin
  Stream := TMemoryStream.Create;
  try
    if Data = '' then
      Exit;  // 提前退出

    if Length(Data) > MaxSize then
      Exit;  // 提前退出

    // 正常处理流程
    Stream.Write(Data[1], Length(Data));
  finally
    Stream.Free;
  end;
end;

{ ========== 嵌套函数示例 ========== }

function CalculateStats(const Values: array of Double): TStats;

  function Average: Double;
  var
    Sum: Double;
    I: Integer;
  begin
    Sum := 0;
    for I := Low(Values) to High(Values) do
      Sum := Sum + Values[I];
    if Length(Values) > 0 then
      Result := Sum / Length(Values)
    else
      Result := 0;
  end;

  function Variance: Double;
  var
    Avg, SumSq: Double;
    I: Integer;
  begin
    Avg := Average;
    SumSq := 0;
    for I := Low(Values) to High(Values) do
      SumSq := SumSq + Sqr(Values[I] - Avg);
    if Length(Values) > 1 then
      Result := SumSq / (Length(Values) - 1)
    else
      Result := 0;
  end;

begin
  Result.Mean := Average;
  Result.Var := Variance;
  Result.Count := Length(Values);
end;

{ ========== 迭代器示例（Delphi 2009+） ========== }

procedure ProcessStringList(Strings: TStringList);
var
  S: string;
  I: Integer;
begin
  // 传统 for 循环
  for I := 0 to Strings.Count - 1 do
  begin
    ProcessString(Strings[I]);
  end;

  // 增强 for 循环（Delphi 2009+）
  for S in Strings do
  begin
    ProcessString(S);
  end;
end;

procedure IterateDictionary(const Dict: TDictionary<string, Integer>);
var
  Pair: TPair<string, Integer>;
  Key: string;
begin
  // 遍历键值对
  for Pair in Dict do
  begin
    WriteLog(Format('%s = %d', [Pair.Key, Pair.Value]));
  end;

  // 仅遍历键
  for Key in Dict.Keys do
  begin
    WriteLog('Key: ' + Key);
  end;
end;

end.
