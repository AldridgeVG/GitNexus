{ Delphi 数据类型定义示例 }
unit DataTypes;

interface

uses
  Windows, SysUtils;

type
  // ========== 枚举类型 ==========
  TCmdResult = (
    crBusy = -101,
    crDuplicated = -102,
    crFmtError = -103,
    crUnrecognized = -104,
    crCondFailed = -105,
    crExeFailed = -106,
    crSucceed = 0);

  TTransType = (ttASCII, ttHex);

  TCatalog = (ttActive, ttFinished);

  TEnsureType = (etNotEof, etEof);

  // ========== 记录类型 (Record) ==========
  TLogMailMsgHead = packed record
    Size: WORD;
    ProcessID: DWORD;
    MsgTime: TDateTime;
    MsgColor: Integer;
    MsgType: Integer;
    AppStartHigh: DWORD;
    AppStartLow: DWORD;
  end;

  TProcessInfo = record
    AppName: string;
    FullPath: string;
    Version: string;
    PID: Cardinal;
  end;

  TCommSerial = record
    CommPort: Integer;
    CommSettings: array[0..255] of Char;
    Baudrate: Integer;
    procedure Initialize();
  end;

  TCommNet = record
    TcpHost: array[0..255] of Char;
    TcpPort: Integer;
    procedure Initialize();
  end;

  // ========== 指针类型 ==========
  PProcessWindow = ^TProcessWindow;
  TProcessWindow = record
    ProcessID: Cardinal;
    FoundWindow: HWND;
  end;

  // ========== 数组类型 ==========
  TCachData = TByteArray;
  TDevCMD = Byte;

  // ========== 过程类型 ==========
  TTaskExecProc = procedure of object;
  TOnExtractBuff = procedure (ABuff: TBytes) of Object;
  TModbusParserProc = procedure (ALoaderCmd, AModbusCode: Byte; ABuf: TBytes;
    ADataIdx: Integer) of Object;

const
  // ========== 常量定义 ==========
  TCMD_UNKNOW = 0;
  mbfReadCoils = $01;
  mbfReadInputBits = $02;
  mbfReadHoldingRegs = $03;
  mbfWriteOneReg = $06;
  TNCModbusAlarm_IDPrefix = 'TPModbus';
  ALM_TimeOut = 1;
  ALM_CRCError = 2;

var
  // ========== 全局变量 ==========
  WindowsRebooted: Boolean;

implementation

{ TCommSerial }

procedure TCommSerial.Initialize;
begin
  FillChar(Self, Sizeof(TCommSerial), 0);
  StrCopy(@CommSettings, '9600,n,8,1');
  CommPort := 1;
  Baudrate := 9600;
end;

{ TCommNet }

procedure TCommNet.Initialize;
begin
  FillChar(Self, Sizeof(TCommNet), 0);
end;

end.
