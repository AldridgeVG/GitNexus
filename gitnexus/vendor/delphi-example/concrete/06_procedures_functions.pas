{ Delphi 过程和函数定义示例 }
unit ProceduresFunctions;

interface

uses
  Windows, SysUtils, Classes, Generics.Collections;

  {$REGION ' 时间相关函数 '}

  procedure LoadTimeZone;
  function GetUTC8DateTime(ATimestamp: Int64): TDateTime;
  function UTCTimestampToLocalDateTime(ATimestamp: Int64): TDateTime;
  function GetUTCTimestamp: Int64; overload;
  function GetUTCTimestamp(ATime: TDateTime): Int64; overload;
  function GetUTCTimestamp(ATick: Int64): Int64; overload;
  function DateTimeToGmtStr(ATime: TDateTime): string;
  function GmtDateTimeNow: string;
  function GetUTCDateTime: TDateTime;
  function _GetTickCount64: Int64;
  function FileTimeToDateTime(AFileTime: TFileTime): TDateTime;
  function DateToFormatDate(ADateStr: string): TDateTime;
  function DateTimeToDateStr(ADate: TDateTime): string;
  function DateTime2DateStr(ADate: TDateTime): string;
  function GetDateTimeStr(ATimestamp: Int64): TDateTime;
  function DateStrToFormat(ADateStr: string): TDateTime;
  function DateStrToFormatV2(ADateStr: string): TDateTime;
  function Time2Datetime(AEndTime: Int64): TDateTime;

  {$ENDREGION}

  {$REGION ' 网络相关函数 '}

  function CheckNetUrl(AUrl: string): Boolean;
  function IsValidHttpAddr(AUrl: string): Boolean;
  function CreateHttpRequest: OleVariant;
  function CreateXmlHttpRequest: IXMLHttpRequest;
  function CreateServerHttpRequest: IServerXMLHTTPRequest;
  function DownloadToFile(const Url, Path: string): Boolean;

  {$ENDREGION}

  {$REGION ' 工具函数 '}

  function RandomUUID: string;
  function UrlDecode(AUrl: string): string;
  function UrlEncode(AUrl: string): string;
  function MD5Hash(AMsg: string): string;
  function FileMD5(AFilePath: string): string;
  function CreateRandom(AMin, AMax: Integer): Integer;
  function CreateRandomStr(ALength: Integer): string;
  function IncludeChinese(AStr: string): Boolean;
  function ListToStr(AList: TList<string>; ADelimiter: string): string;
  function ReversePos(SubStr, S: String): Integer;

  {$ENDREGION}

  {$REGION ' 文件操作函数 '}

  procedure WriteFile(AMsg: string; AFilePath: string);
  procedure WriteFileLog(AMsg: string);
  function FindLogFiles(const ANamePrefix: string): TStringList;
  procedure TryAddEnding(const AFileName: string);
  procedure TryRemoveEnding(const AFileName: string);

  {$ENDREGION}

  {$REGION ' 进程管理函数 '}

  function GetProcessWindow(ProcessID: Cardinal): HWND;
  function ForceForegroundWindow(hwnd: THandle): Boolean;
  function GetDosReturnValue(Cmd: string): string;
  function RunAndWaitResult(ACmd: string; ATimeOut: Integer = 100000): string;
  procedure GetProcessInfo(PName: string; var ProcessInfo: TProcessInfo);
  function IsProcessRunning(const PID: DWORD): Boolean;
  function GetProcessStartTime(const PID: DWORD; out FileTime: TFileTime): Boolean;

  {$ENDREGION}

  {$REGION ' Windows服务函数 '}

  procedure StartExeAsUser(const PID: Integer; const ExePath: string; const CmdParam: string = '');
  procedure StartExeAsUserV2(const PID: Integer; const CmdParam: string; ATimeOut: Integer = 100000);
  procedure StartExeAsUserV3(const PID: Integer; const CmdParam: string);

  {$ENDREGION}

type
  TProcessInfo = record
    AppName: string;
    FullPath: string;
    Version: string;
    PID: Cardinal;
  end;

implementation

uses
  DateUtils, ComObj, Variants, ActiveX, HTTPApp, Math, IdHashMessageDigest,
  psUtils, Registry, StrUtils, uGetTickCount64, UrlMon, WinInet, ShellAPI,
  EncdDecd, msxml;

{$REGION ' 时间相关函数 '}

var
  TimeZone: _TIME_ZONE_INFORMATION;

procedure LoadTimeZone;
begin
  GetTimeZoneInformation(TimeZone);
end;

function GetUTCTimestamp: Int64;
begin
  Result := GetUTCTimestamp(Now);
end;

function GetUTCTimestamp(ATime: TDateTime): Int64;
var
  UTCTime: TDateTime;
begin
  if TimeZone.Bias = 0 then
    GetTimeZoneInformation(TimeZone);
  UTCTime := IncMinute(ATime, TimeZone.Bias);
  Result := DateTimeToUnix(UTCTime) * 1000;
end;

function GetUTCTimestamp(ATick: Int64): Int64;
begin
  Result := GetUTCTimestamp(Now - (_GetTickCount64 - ATick) / 86400000);
end;

function GetUTC8DateTime(ATimestamp: Int64): TDateTime;
var
  UTCTime: TDateTime;
begin
  UTCTime := UnixToDateTime(ATimestamp div 1000);
  Result := IncHour(UTCTime, 8);
end;

function UTCTimestampToLocalDateTime(ATimestamp: Int64): TDateTime;
var
  UtcDateTime: TDateTime;
begin
  UtcDateTime := UnixToDateTime(ATimestamp div 1000);
  Result := IncMinute(UtcDateTime, -TimeZone.Bias);
end;

function GetUTCDateTime: TDateTime;
begin
  Result := IncMinute(Now, TimeZone.Bias);
end;

function DateTimeToGmtStr(ATime: TDateTime): string;
const
  sDateFormat = '{0}, dd {1} yyyy hh:nn:ss';
var
  Time0: TDateTime;
begin
  Time0 := IncMinute(ATime, TimeZone.Bias);
  Result := FormatDateTime(sDateFormat, Time0);
  Result := StringReplace(Result, '{0}', DayOfWeekStr(Time0), []);
  Result := StringReplace(Result, '{1}', MonthStr(Time0), []);
  Result := Result + ' GMT';
end;

function GmtDateTimeNow: string;
var
  NowTime: TDateTime;
begin
  try
    if (FsdcContext = nil) or (FsdcContext.InsLog = nil) then
      Exit(DateTimeToGmtStr(Now));
    NowTime := Now + (FsdcContext.InsLog.GetServerTime(_GetTickCount64) - GetUTCTimestamp) * 1.0 / 1000 / 86400;
    Result := DateTimeToGmtStr(NowTime);
  except
    Result := DateTimeToGmtStr(Now);
  end;
end;

function FileTimeToDateTime(AFileTime: TFileTime): TDateTime;
var
  ModifiedTime: TFileTime;
  SystemTime: TSystemTime;
begin
  Result := Now;
  if (AFileTime.dwLowDateTime = 0) and (AFileTime.dwHighDateTime = 0) then Exit;
  try
    FileTimeToLocalFileTime(AFileTime, ModifiedTime);
    FileTimeToSystemTime(ModifiedTime, SystemTime);
    Result := SystemTimeToDateTime(SystemTime);
  except
    Result := Now;
  end;
end;

function DateToFormatDate(ADateStr: string): TDateTime;
var
  year, month, day: Word;
  Date: Int64;
begin
  Result := Now;
  try
    Date := StrToInt(ADateStr);
    year := Date div 10000;
    month := Date mod 10000 div 100;
    day := Date mod 10000 mod 100;
    Result := EncodeDate(year, month, day);
  except
  end;
end;

function DateTimeToDateStr(ADate: TDateTime): string;
begin
  DateTimeToString(Result, 'yyyymmdd', ADate);
end;

function DateTime2DateStr(ADate: TDateTime): string;
begin
  DateTimeToString(Result, 'yyyy-mm-dd hh:mm:ss', ADate);
end;

function GetDateTimeStr(ATimestamp: Int64): TDateTime;
var
  UtcDateTime: TDateTime;
begin
  UtcDateTime := UnixToDateTime(ATimestamp);
  Result := IncHour(UtcDateTime, 8);
end;

function DateStrToFormat(ADateStr: string): TDateTime;
var
  Fmt: TFormatSettings;
begin
  try
    Fmt.ShortDateFormat := 'yyyy-MM-dd HH:mm:ss';
    Fmt.DateSeparator := '-';
    Result := StrToDateTime(ADateStr, Fmt);
  except
    Result := 0;
  end;
end;

function DateStrToFormatV2(ADateStr: string): TDateTime;
var
  Fmt: TFormatSettings;
begin
  try
    Fmt.ShortDateFormat := 'yyyy-MM-dd';
    Fmt.DateSeparator := '-';
    Fmt.ShortTimeFormat := 'HH:mm:ss';
    Fmt.TimeSeparator := ':';
    Result := StrToDateTime(ADateStr, Fmt);
  except
    Result := 0;
  end;
end;

function Time2Datetime(AEndTime: Int64): TDateTime;
var
  EndIsTs: Boolean;
begin
  Result := Now;
  if AEndTime <= 0 then Exit;
  EndIsTs := AEndTime > 1262275200000;
  if EndIsTs then
    Result := UTCTimestampToLocalDateTime(AEndTime);
end;

function _GetTickCount64: Int64;
begin
  Result := GetSysTickCount64;
end;

{$ENDREGION}

{$REGION ' 网络相关函数 '}

function CheckNetUrl(AUrl: string): Boolean;
var
  tcp: TFsTcpClient;
begin
  tcp := TFsTcpClient.Create(nil);
  try
    tcp.RemoteHost := AnsiString(AUrl);
    tcp.RemotePort := AnsiString('80');
    try
      Result := tcp.ConnectTimeout(1000);
    except
      Result := False;
    end;
  finally
    tcp.Free;
  end;
end;

function IsValidHttpAddr(AUrl: string): Boolean;
begin
  Result := (Pos('http://', LowerCase(AUrl)) = 1) or
    (Pos('https://', LowerCase(AUrl)) = 1);
end;

function CreateXmlHttpRequest: IXMLHttpRequest;
begin
  CoInitialize(nil);
  try
    Result := CoXMLHTTP60.Create;
  except
    try
      Result := CoXMLHTTP40.Create;
    except
      try
        Result := CoXMLHTTP30.Create;
      except
        try
          Result := CoXMLHTTP26.Create;
        except
          Result := nil;
        end;
      end;
    end;
  end;
  CoUninitialize;
end;

function CreateServerHttpRequest: IServerXMLHttpRequest;
begin
  CoInitialize(nil);
  try
    Result := CoServerXMLHTTP60.Create;
  except
    try
      Result := CoServerXMLHTTP40.Create;
    except
      try
        Result := CoServerXMLHTTP30.Create;
      except
        try
          Result := CoServerXMLHTTP.Create;
        except
          Result := nil;
        end;
      end;
    end;
  end;
  CoUninitialize;
end;

function CreateHttpRequest: OleVariant;
begin
  CoInitialize(nil);
  try
    Result := CreateOleObject('WinHttp.WinHttpRequest.5.1');
    Result.SetTimeouts(10000, 10000, 10000, 10000);
  except
    try
      Result := CreateOleObject('Msxml2.ServerXMLHTTP');
      Result.SetTimeouts(10000, 10000, 10000, 10000);
    except
      try
        Result := CreateXmlHttpRequest;
      except
        Result := Null;
      end;
    end;
  end;
  CoUninitialize;
end;

{$ENDREGION}

{$REGION ' 工具函数 '}

function RandomUUID: string;
var
  GUID: TGUID;
begin
  CreateGUID(GUID);
  Result := StringReplace(GUIDToString(GUID), '-', '', [rfReplaceAll]);
  if Length(Result) > 2 then
    Result := Copy(Result, 2, Length(Result) - 2);
end;

function UrlDecode(AUrl: string): string;
begin
  Result := UTF8ToString(HTTPDecode(AnsiString(AUrl)));
end;

function UrlEncode(AUrl: string): string;
begin
  Result := string(HTTPEncode(UTF8Encode(AUrl)));
  Result := StringReplace(Result, '+', '%20', [rfReplaceAll]);
  Result := StringReplace(Result, '%2F', '/', [rfReplaceAll]);
end;

function MD5Hash(AMsg: string): string;
var
  Md5Encode: TIdHashMessageDigest5;
begin
  Md5Encode := TIdHashMessageDigest5.Create;
  try
    try
      Result := UpperCase(Md5Encode.HashStringAsHex(AMsg));
    except
      Result := '';
    end;
  finally
    Md5Encode.Free;
  end;
end;

function FileMD5(AFilePath: string): string;
var
  Md5Encode: TIdHashMessageDigest5;
  fs: TFileStream;
begin
  if not FileExists(AFilePath) then Exit;
  fs := TFileStream.Create(AFilePath, fmOpenRead OR fmShareDenyWrite);
  Md5Encode := TIdHashMessageDigest5.Create;
  try
    try
      Result := UpperCase(Md5Encode.HashStreamAsHex(fs));
    except
      Result := '';
    end;
  finally
    fs.Free;
    Md5Encode.Free;
  end;
end;

function CreateRandomStr(ALength: Integer): string;
const
  SourceStr: string = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
var
  I: Integer;
begin
  Randomize;
  for I := 0 to ALength - 1 do
  begin
    Result := Result + SourceStr[Random(62) + 1];
  end;
end;

function CreateRandom(AMin, AMax: Integer): Integer;
begin
  Randomize;
  Result := Random(AMax) mod (AMax - AMin + 1) + AMin;
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
      #$4E00 .. #$9FA5: Exit(True);
    end;
    Inc(p);
  end;
end;

function ListToStr(AList: TList<string>; ADelimiter: string): string;
var
  I: Integer;
begin
  for I := 0 to AList.Count - 1 do
  begin
    if Result = '' then
      Result := AList[I]
    else
      Result := Result + ADelimiter + AList[I];
  end;
end;

function ReversePos(SubStr, S: String): Integer;
var
  i: Integer;
begin
  i := Pos(ReverseString(SubStr), ReverseString(S));
  if i > 0 then i := Length(S) - i - Length(SubStr) + 2;
  Result := i;
end;

{$ENDREGION}

{$REGION ' 文件操作函数 '}

procedure WriteFile(AMsg: string; AFilePath: string);
var
  txt: TextFile;
begin
  try
    AssignFile(txt, AFilePath);
    if FileExists(AFilePath) then
    begin
      Append(txt);
      Writeln(txt, AMsg);
    end
    else
    begin
      Rewrite(txt);
      Writeln(txt, AMsg);
    end;
  finally
    CloseFile(txt);
  end;
end;

procedure WriteFileLog(AMsg: string);
begin
  WriteFile(DateTimeToStr(Now) + ': ' + AMsg, 'C:\Users\Public\errLog.txt');
end;

function FindLogFiles(const ANamePrefix: string): TStringList;
var
  Target: string;
  Sch: TSearchRec;
begin
  Result := TStringList.Create;
  Target := Format('%s\%s*.rtf', [LogFileDir, ANamePrefix]);
  try
    if FindFirst(Target, faAnyFile, Sch) = 0 then
    begin
      repeat
        if ((Sch.Name = '.') or (Sch.Name = '..')) then Continue;
        Result.Add(Sch.Name);
      until FindNext(Sch) <> 0;
    end;
  finally
    FindClose(Sch);
  end;
end;

{$ENDREGION}

{$REGION ' 进程管理函数 '}

function GetProcessWindow(ProcessID: Cardinal): HWND;
var
  ProcWndInfo: TProcessWindow;
begin
  ProcWndInfo.ProcessID := ProcessID;
  ProcWndInfo.FoundWindow := 0;
  EnumWindows(@EnumWindowsProc, Integer(@ProcWndInfo));
  Result := ProcWndInfo.FoundWindow;
end;

function ForceForegroundWindow(hwnd: THandle): Boolean;
const
  SPI_GETFOREGROUNDLOCKTIMEOUT = $2000;
  SPI_SETFOREGROUNDLOCKTIMEOUT = $2001;
var
  ForegroundThreadID: DWORD;
  ThisThreadID: DWORD;
  timeout: DWORD;
begin
  if IsIconic(hwnd) or not IsWindowVisible(hwnd) then
    ShowWindow(hwnd, SW_RESTORE);

  if ((Win32Platform = VER_PLATFORM_WIN32_NT) and (Win32MajorVersion > 4)) then
  begin
    Result := False;
    ForegroundThreadID := GetWindowThreadProcessID(GetForegroundWindow, nil);
    ThisThreadID := GetWindowThreadProcessId(hwnd, nil);
    if AttachThreadInput(ThisThreadID, ForegroundThreadID, True) then
    begin
      BringWindowToTop(hwnd);
      SetForegroundWindow(hwnd);
      AttachThreadInput(ThisThreadID, ForegroundThreadID, False);
      Result := (GetForegroundWindow = hwnd);
    end;

    if not Result then
    begin
      SystemParametersInfo(SPI_GETFOREGROUNDLOCKTIMEOUT, 0, @timeout, 0);
      SystemParametersInfo(SPI_SETFOREGROUNDLOCKTIMEOUT, 0, TObject(0), SPIF_SENDCHANGE);
      BringWindowToTop(hwnd);
      SetForegroundWindow(hWnd);
      SystemParametersInfo(SPI_SETFOREGROUNDLOCKTIMEOUT, 0, TObject(timeout), SPIF_SENDCHANGE);
    end;
  end
  else
  begin
    BringWindowToTop(hwnd);
    SetForegroundWindow(hwnd);
  end;

  Result := (GetForegroundWindow = hwnd);
end;

procedure GetProcessInfo(PName: string; var ProcessInfo: TProcessInfo);
const
  wbemFlagForwardOnly = $00000020;
var
  FSWbemLocator: OLEVariant;
  FWMIService: OLEVariant;
  FWbemObjectSet: OLEVariant;
  FWbemObject: OLEVariant;
  oEnum: IEnumVariant;
  iValue: LongWord;
begin
  ProcessInfo.AppName := PName;
  ProcessInfo.PID := 0;
  if Pos('.exe', PName) <= 0 then
    PName := PName + '.exe';

  CoInitialize(nil);
  try
    ProcessInfo.PID := PsPidByName(PName);
    ProcessInfo.FullPath := string(PsPathByPID(ProcessInfo.PID));
    ProcessInfo.Version := GetFileVersionStr(ProcessInfo.FullPath);
    if (ProcessInfo.PID <> 0) and (ProcessInfo.Version <> '') then Exit;
  except
  end;

  try
    FSWbemLocator := CreateOleObject('WbemScripting.SWbemLocator');
    FWMIService := FSWbemLocator.ConnectServer('localhost', 'root\CIMV2', '', '');
    FWbemObjectSet := FWMIService.ExecQuery(
      Format('SELECT ExecutablePath, ProcessId FROM Win32_Process WHERE Name = "%s"', [PName]),
      'WQL', wbemFlagForwardOnly);
    oEnum := IUnknown(FWbemObjectSet._NewEnum) as IEnumVariant;
    while oEnum.Next(1, FWbemObject, iValue) = 0 do
    begin
      if not VarIsNull(FWbemObject.ExecutablePath) then
      begin
        ProcessInfo.FullPath := FWbemObject.ExecutablePath;
        ProcessInfo.PID := FWbemObject.ProcessId;
        ProcessInfo.Version := GetFileVersionStr(ProcessInfo.FullPath);
      end;
      FWbemObject := Unassigned;
    end;
  except
  end;
end;

function IsProcessRunning(const PID: DWORD): Boolean;
var
  hProcess: Integer;
  ExitCode: DWORD;
  LastErr: DWORD;
begin
  hProcess := OpenProcess(PROCESS_QUERY_INFORMATION, False, PID);
  try
    if hProcess > 0 then
      Result := GetExitCodeProcess(hProcess, ExitCode) and (ExitCode = STILL_ACTIVE)
    else
    begin
      LastErr := GetLastError();
      if LastErr = ERROR_INVALID_PARAMETER then
        Result := False
      else if LastErr = ERROR_ACCESS_DENIED then
        Result := True
      else
        Result := False;
    end;
  finally
    CloseHandle(hProcess);
  end;
end;

function GetProcessStartTime(const PID: DWORD; out FileTime: TFileTime): Boolean;
var
  pHandle: Integer;
  lpCreation, lpExit, lpKernel, lpUser: TFileTime;
  pResult: Boolean;
begin
  Result := False;
  pHandle := OpenProcess(PROCESS_QUERY_INFORMATION, False, PID);
  try
    if pHandle <= 0 then Exit;
    pResult := GetProcessTimes(pHandle, lpCreation, lpExit, lpKernel, lpUser);
    if not pResult then Exit;
    Result := True;
    FileTime := lpCreation;
  finally
    CloseHandle(pHandle);
  end;
end;

{$ENDREGION}

{$REGION ' Windows服务函数 '}

function CreateEnvironmentBlock(var lpEnvironment: Pointer; hToken: THandle;
  bInherit: BOOL): BOOL; stdcall; external 'Userenv.dll';

function DestroyEnvironmentBlock(pEnvironment: Pointer): BOOL; stdcall; external 'Userenv.dll';

procedure StartExeAsUser(const PID: Integer; const ExePath: string; const CmdParam: string);
var
  Pi: TProcessInformation;
  Si: TStartupInfo;
  ProcessHandle: Cardinal;
  hToken: Cardinal;
  ExeName: string;
  Env: Pointer;
  PCmdParam: PChar;
begin
  if PID <= 0 then Exit;
  ExeName := ExtractFileName(ExePath);
  ProcessHandle := OpenProcess(PROCESS_ALL_ACCESS, True, PID);
  if ProcessHandle <= 0 then Exit;

  if not OpenProcessToken(ProcessHandle, MAXIMUM_ALLOWED, hToken) then Exit;

  Si := Default(TStartupInfo);
  Pi := Default(TProcessInformation);
  SI.cb := SizeOf(SI);
  SI.wShowWindow := SW_SHOWNORMAL;

  if not FileExists(ExePath) then Exit;

  if not CreateEnvironmentBlock(Env, hToken, False) then
    Env := nil;

  if CmdParam = '' then
    PCmdParam := nil
  else
    PCmdParam := PChar(CmdParam);

  try
    if not CreateProcessAsUser(hToken, PChar(ExePath), PCmdParam, nil, nil,
      False, CREATE_UNICODE_ENVIRONMENT, Env, nil, SI, PI) then
    begin
      OutputDebugString(PCHAR(SysErrorMessage(GetLastError)));
    end;
  finally
    CloseHandle(Pi.hProcess);
    CloseHandle(Pi.hThread);
    DestroyEnvironmentBlock(Env);
    CloseHandle(hToken);
  end;
end;

procedure StartExeAsUserV2(const PID: Integer; const CmdParam: string; ATimeOut: Integer);
var
  Pi: TProcessInformation;
  Si: TStartupInfo;
  ProcessHandle: Cardinal;
  hToken: Cardinal;
  Env: Pointer;
  PCmdParam: PChar;
  exitCode: Dword;
begin
  if PID <= 0 then Exit;
  ProcessHandle := OpenProcess(PROCESS_ALL_ACCESS, True, PID);
  if ProcessHandle <= 0 then Exit;

  if not OpenProcessToken(ProcessHandle, MAXIMUM_ALLOWED, hToken) then Exit;

  Si := Default(TStartupInfo);
  Pi := Default(TProcessInformation);
  SI.cb := SizeOf(SI);
  si.dwFlags := STARTF_USESHOWWINDOW;
  SI.wShowWindow := SW_HIDE;

  if not CreateEnvironmentBlock(Env, hToken, False) then
    Env := nil;

  if CmdParam = '' then
    PCmdParam := nil
  else
    PCmdParam := PChar(CmdParam);

  try
    if not CreateProcessAsUser(hToken, nil, PCmdParam, nil, nil,
      False, CREATE_UNICODE_ENVIRONMENT, Env, nil, SI, PI) then Exit;
    WaitForSingleObject(Pi.hProcess, ATimeOut);
    GetExitCodeProcess(Pi.hProcess, exitCode);
  finally
    CloseHandle(Pi.hProcess);
    CloseHandle(Pi.hThread);
    DestroyEnvironmentBlock(Env);
    CloseHandle(hToken);
  end;
end;

{$ENDREGION}

initialization
  GetTimeZoneInformation(TimeZone);

end.
