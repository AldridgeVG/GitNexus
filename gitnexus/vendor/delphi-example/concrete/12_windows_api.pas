{ Delphi Windows API 调用示例 }
unit WindowsAPICalls;

interface

uses
  Windows, SysUtils, Classes;

  function IsMainWindow(Handle: HWND): Boolean;
  function GetProcessWindow(ProcessID: Cardinal): HWND;
  function ForceForegroundWindow(hwnd: THandle): Boolean;
  function GetWindowsVersion: string;
  function IsWindows64Bit: Boolean;
  function GetSystemUpTime: DWORD;

implementation

function IsMainWindow(Handle: HWND): Boolean;
begin
  Result := (GetWindow(Handle, GW_OWNER) = 0) and IsWindowVisible(Handle);
end;

function EnumWindowsProc(Wnd: HWND; ProcWndInfo: PProcessWindow): BOOL; stdcall;
var
  WndProcessID: Cardinal;
begin
  GetWindowThreadProcessId(Wnd, @WndProcessID);
  if (WndProcessID = ProcWndInfo^.ProcessID) and IsMainWindow(Wnd) then
  begin
    ProcWndInfo^.FoundWindow := Wnd;
    Result := False;
  end
  else
    Result := True;
end;

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

function GetWindowsVersion: string;
var
  OSInfo: TOSVersionInfo;
begin
  OSInfo.dwOSVersionInfoSize := SizeOf(TOSVersionInfo);
  if GetVersionEx(OSInfo) then
  begin
    Result := Format('%d.%d (Build %d)', [OSInfo.dwMajorVersion, OSInfo.dwMinorVersion, OSInfo.dwBuildNumber]);
  end
  else
    Result := 'Unknown';
end;

function IsWindows64Bit: Boolean;
type
  TIsWow64Process = function(Handle: THandle; var Res: BOOL): BOOL; stdcall;
var
  IsWow64Result: BOOL;
  IsWow64Process: TIsWow64Process;
begin
  Result := False;
  IsWow64Process := GetProcAddress(GetModuleHandle('kernel32'), 'IsWow64Process');
  if Assigned(IsWow64Process) then
  begin
    if IsWow64Process(GetCurrentProcess, IsWow64Result) then
      Result := IsWow64Result;
  end;
end;

function GetSystemUpTime: DWORD;
beginn  Result := GetTickCount;
end;

end.
