{ Delphi 高级类定义示例 }
unit ClassAdvanced;

interface

uses
  Windows, SysUtils, Classes, Generics.Collections, SyncObjs;

type
  // ========== 继承类 ==========
  TNcThrdStateBase = class(TComponent)
  private
    FLock: TCriticalSection;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function TryLockData: Boolean;
    procedure LockData;
    procedure UnLockData;
  end;

  // ========== 多接口实现类 ==========
  TNcSerialCommTrans = class(TInterfacedObject, INcDataTransIntf, INcSerialCommTransIntf)
  private
    FType: TTransType;
    FComm: TCommCtrl;
  public
    constructor Create;
    destructor Destroy; override;
    function CheckConnection: Boolean;
    function SendBuff(Buffer: TBytes): Boolean;
    function GetReceiveBuff(): TBytes;
    procedure SetCommParams(AParams: TCommSerial);
  end;

  // ========== 线程类 ==========
  TIOCPThread = class(TThread)
  private
    FIndex: Integer;
    FTaskCount: Integer;
    FLastRunTime: TDateTime;
    FOwner: TIOCPThreadPool;
    FCompletionPortHandle: THandle;
  protected
    procedure Execute; override;
  public
    constructor Create(const ThreadPool: TIOCPThreadPool;
      const CompletionPortHandle: THandle);
    procedure FinishTask;
    function GetThreadName: string;
  end;

  // ========== 泛型集合类 ==========
  TEventBusDict = class(TObjectDictionary<string, TEventBus>)
  private
  public
    constructor Create;
    destructor Destroy; override;
    function RegisterHandler(AHandler: TBaseEventHandler): Boolean;
    function UnRegisterHandler(AHandler: TBaseEventHandler): Boolean;
  end;

  TIOCPThreadPool = class
  private
    FCompletionPortHandle: THandle;
    FThreadCountMin: Integer;
    FThreadCountMax: Integer;
    FThreadList: TList<TIOCPThread>;
    FThreadMap: TDictionary<DWORD, TIOCPThread>;
    FTaskCount: Integer;
    FTaskListCS: TRTLCriticalSection;
    procedure DeleteTask();
    procedure ResizeUp();
    procedure ResizeDown();
    procedure SetThreadCountMin(Value: Integer);
    procedure SetThreadCountMax(Value: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    function AddTask(ATask: IRunnable): Boolean;
    property ThreadCountMin: Integer read FThreadCountMin write SetThreadCountMin;
    property ThreadCountMax: Integer read FThreadCountMax write SetThreadCountMax;
  end;

  // ========== 属性声明属性 ==========
  AEventTopic = class(TCustomAttribute)
  private
    FTopic: string;
  public
    constructor Create(ATopic: string);
    property Topic: string read FTopic;
  end;

  [AEventTopic('LOG')]
  TLogHandler = class(TBaseEventHandler)
  private
    procedure RecordLog(ALocation, AMsg: string);
  protected
    procedure OnEvent(AEvent: TBaseEvent); override;
  end;

  // ========== 嵌套方法类 ==========
  TModbusComm = class(TDevDataCommBase)
  private
    FName: string;
    FHostAddr: Byte;
    FDelayTm: Integer;
    FTimeOut: Integer;
    FOnParserModbusAck: TModbusParserProc;
    FIsModbusTcp: Boolean;
  public
    constructor Create(AName: string); reintroduce;
    destructor Destroy; override;
    function CheckDatavalid(Buf: TBytes): Boolean; override;
    function SendCommand(const ACMD: Byte; const AModBusFunction: Byte; const ARegAddr: Word;
      const ABlockLength: Word; Data: array of Word): Boolean;
    procedure WaitforAckData(const ACMD: Byte; ATimeOut: Cardinal = 1000); virtual;
    property OnParserModbusAck: TModbusParserProc read FOnParserModbusAck write FOnParserModbusAck;
    property IsModbusTcp: Boolean read FIsModbusTcp write FIsModbusTcp;
    property DelayTm: Integer read FDelayTm write FDelayTm;
  end;

implementation

{ TNcThrdStateBase }

constructor TNcThrdStateBase.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLock := TCriticalSection.Create;
end;

destructor TNcThrdStateBase.Destroy;
begin
  FreeAndNil(FLock);
  inherited;
end;

procedure TNcThrdStateBase.LockData;
begin
  FLock.Enter;
end;

function TNcThrdStateBase.TryLockData: Boolean;
begin
  Result := FLock.TryEnter;
end;

procedure TNcThrdStateBase.UnLockData;
begin
  FLock.Leave;
end;

{ TNcSerialCommTrans }

constructor TNcSerialCommTrans.Create;
begin
  inherited;
  FComm := nil;
end;

destructor TNcSerialCommTrans.Destroy;
begin
  FreeAndNil(FComm);
  inherited;
end;

function TNcSerialCommTrans.CheckConnection: Boolean;
begin
  Result := (FComm <> nil) and FComm.Active;
end;

function TNcSerialCommTrans.SendBuff(Buffer: TBytes): Boolean;
begin
  Result := True;
  try
    if Buffer = nil then Exit(False);
    Result := FComm.Write(Buffer[0], Length(Buffer)) <> -1;
  except
    Result := False;
  end;
end;

function TNcSerialCommTrans.GetReceiveBuff: TBytes;
begin
  Result := nil;
  if not CheckConnection then Exit;
end;

procedure TNcSerialCommTrans.SetCommParams(AParams: TCommSerial);
begin
  FComm := TCommCtrl.Create(nil);
  FComm.Settings := AParams.CommSettings;
  FComm.CommPort := AParams.CommPort;
  FComm.Active := True;
  FComm.Open;
end;

{ TIOCPThread }

constructor TIOCPThread.Create(const ThreadPool: TIOCPThreadPool;
  const CompletionPortHandle: THandle);
begin
  inherited Create(False);
  FOwner := ThreadPool;
  FCompletionPortHandle := CompletionPortHandle;
  FIndex := ThreadPool.FThreadList.Count + 1;
end;

procedure TIOCPThread.Execute;
begin
  inherited;
  FreeOnTerminate := False;
  while not Terminated do
  begin
    // 线程执行逻辑
    Sleep(50);
  end;
end;

procedure TIOCPThread.FinishTask;
begin
  Inc(FTaskCount);
  FLastRunTime := Now;
end;

function TIOCPThread.GetThreadName: string;
begin
  Result := Format('%s-Thread-%d', ['IOCPThreadPool', FIndex]);
end;

{ TEventBusDict }

constructor TEventBusDict.Create;
begin
  inherited Create([doOwnsValues]);
end;

destructor TEventBusDict.Destroy;
var
  Name: string;
begin
  try
    for Name in Self.Keys do
      Remove(Name);
  finally
    inherited;
  end;
end;

function TEventBusDict.RegisterHandler(AHandler: TBaseEventHandler): Boolean;
var
  Topic: string;
begin
  try
    Topic := AHandler.FTopic;
    if not ContainsKey(Topic) then
    begin
      Add(Topic, TEventBus.Create(AHandler));
    end;
    Result := True;
  except
    Result := False;
  end;
end;

function TEventBusDict.UnRegisterHandler(AHandler: TBaseEventHandler): Boolean;
begin
  try
    Remove(AHandler.Topic);
    Result := True;
  except
    Result := False;
  end;
end;

{ AEventTopic }

constructor AEventTopic.Create(ATopic: string);
begin
  FTopic := ATopic;
end;

{ TModbusComm }

constructor TModbusComm.Create(AName: string);
begin
  inherited Create(nil);
  FName := AName;
  FDelayTm := 50;
  FTimeOut := 1000;
  FOnParserModbusAck := nil;
  FIsModbusTcp := False;
  FHostAddr := 1;
end;

destructor TModbusComm.Destroy;
begin
  FOnParserModbusAck := nil;
  inherited;
end;

function TModbusComm.CheckDatavalid(Buf: TBytes): Boolean;
var
  ALen: Integer;
  ACrc: Word;
begin
  Result := False;
  ALen := Length(Buf);
  if ALen < 7 then Exit;

  if FIsModbusTcp then
  begin
    Result := (Buf[0] = 0) and (Buf[1] = 0);
    Exit;
  end;

  ACrc := CalcCRC(Buf[0], ALen - 2, $FFFF);
  if (Hi(ACrc) = Buf[ALen - 1]) and (Lo(ACrc) = Buf[ALen - 2]) then
    Result := True;
end;

function TModbusComm.SendCommand(const ACMD: Byte; const AModBusFunction: Byte;
  const ARegAddr, ABlockLength: Word; Data: array of Word): Boolean;
var
  ABuff: TBytes;
begin
  Result := False;
  if not CheckConnection then Exit;
  ABuff := GenerateModbusBuf(AModBusFunction, ARegAddr, ABlockLength, Data, FHostAddr);
  LockData;
  try
    Result := CommIntf.SendBuff(ABuff);
    WaitforAckData(ACMD, FTimeOut);
  finally
    UnLockData;
  end;
end;

procedure TModbusComm.WaitforAckData(const ACMD: Byte; ATimeOut: Cardinal);
var
  ABuf: TBytes;
  ATime: Cardinal;
begin
  Sleep(FDelayTm);
  if not CheckConnection then Exit;

  ABuf := CommIntf.GetReceiveBuff;
  ATime := GetTickCount;
  while (ABuf = nil) and ((GetTickCount - ATime) < ATimeOut) do
  begin
    Sleep(10);
    ABuf := CommIntf.GetReceiveBuff;
  end;
end;

end.
