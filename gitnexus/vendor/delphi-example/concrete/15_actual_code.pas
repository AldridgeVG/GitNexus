unit Event.RunStatus;

interface

uses
  superobject, EventBus.Core;

type
 // ???????????fsdc?????????????????????????????
  TAppEventType =(
    APP_SYS_START,                  // ??????
    APP_SYS_EXIT,                   // ???????
    APP_WORK_START,                 // ??????
    APP_WORK_FINISH,                // ??????
    APP_WORK_PAUSE,                 // ??????
    APP_WORK_CONTINUE,              // ???????
    APP_WORK_STOP,                  // ?????
    APP_ALARM_NEW,                  // ????????
    APP_ALARM_REMOVE,               // ???????
    APP_PART_FINISH,                // ??????
    APP_MARK_EVENT                  // ??????
  );

  [AEventTopic('AppStatusEvent')]
  TAppStatusEvent = class(TBaseEvent)
  private
    FEventType: TAppEventType;
    FEventTopic: string;
    FParamNode: ISuperObject;
    FAppName: string;
    FInsUUID: string;
  public
    class procedure New(AEventType: TAppEventType; ANode: ISuperObject);

    function IsHistoryEvent: Boolean;

    property EventTopic: string read FEventTopic;
    property ParamNode: ISuperObject read FParamNode;
  end;

  [AEventTopic('AppStatusChange')]
  TAppStatusChangeEvent = class(TBaseEvent)
  private
    FNowState: string;
    FLastState: string;
    FLocalTime: TDateTime;
    FActionTick: Int64;
    FFsdcInsID: Integer;
    FAppName: string;
  public
    class procedure New(ANowState, ALastState, AppName: string); overload;
    class procedure New(ANowState, ALastState, AppName: string;
      ALocalTime: TDateTime; AActionTick: Int64; FsdcInsID: Integer); overload;
  end;


implementation

uses
  TypInfo, uContext, uDB, DISQLite3Database, SysUtils, uCommon, DI, StatSync,
  Generics.Collections;

type
  [AHandlerPriority(1)]
  [AEventTopic('AppStatusEvent')]
  TAppStatusEventHandler = class(TBaseEventHandler)
  private
    FAppDic: TDictionary<string, string>;
    procedure InsertEventInfo(AEvent: TAppStatusEvent);
    // ??????????
    procedure HandleWorkEvent(Event: TAppStatusEvent);
    // ???????????
    procedure HandleAppSysEvent(Event: TAppStatusEvent);

  protected
    procedure OnEvent(AEvent: TBaseEvent); override;

    constructor Create; override;
    destructor Destroy; override;
  end;

  [AEventTopic('AppStatusChange')]
  TAppStatusChangeEventHandler = class(TBaseEventHandler)
  private
    function GetLastState(AppName: string): string;
    procedure RecordChangeLog(AEvent: TAppStatusChangeEvent);
  protected
    procedure OnEvent(AEvent: TBaseEvent); override;
  end;

{ TCallbackEvent }

function TAppStatusEvent.IsHistoryEvent: Boolean;
begin
  if FParamNode = nil then Exit(False);

  Result := FParamNode.B['IsHistory'];
end;

class procedure TAppStatusEvent.New(AEventType: TAppEventType;
  ANode: ISuperObject);
var
  Event: TAppStatusEvent;
begin
  Event := TAppStatusEvent.Create;
  Event.FEventType := AEventType;
  Event.FEventTopic := GetEnumName(TypeInfo(TAppEventType),Ord(AEventType));
  ANode.I['GMID'] := FsdcContext.gMID;
  Event.FParamNode := ANode;
  if ANode <> nil then
  begin
    Event.FAppName := ANode.S['AppName'];
    Event.FInsUUID := ANode.S['InsUUID'];
  end;
  TEventBus.AppEvent.Publish(Event);
end;

{ TAppStatusEventHandler }

constructor TAppStatusEventHandler.Create;
begin
  inherited;
  FAppDic := TDictionary<string, string>.Create;
end;

destructor TAppStatusEventHandler.Destroy;
begin
  FAppDic.Free;
  inherited;
end;

procedure TAppStatusEventHandler.HandleAppSysEvent(Event: TAppStatusEvent);
begin
  if Event.FInsUUID <> '' then
    FAppDic.AddOrSetValue(Event.FInsUUID, Event.FAppName);
  if not Event.IsHistoryEvent then
    InsertEventInfo(Event);
end;

procedure TAppStatusEventHandler.HandleWorkEvent(Event: TAppStatusEvent);
begin
  if Event.IsHistoryEvent then Exit;
  try
    TBeanFactory.TryInvoke<TSyncModule>(
      procedure (const AObj: TSyncModule)
      begin
        AObj.ForceSyncData;
      end);
  except

  end;
end;

procedure TAppStatusEventHandler.InsertEventInfo(AEvent: TAppStatusEvent);
var
  CurStateStr, LastStateStr: string;
begin
  CurStateStr := AEvent.EventTopic;
  LastStateStr := AEvent.EventTopic;
  if CurStateStr = 'APP_SYS_START' then
  begin
    CurStateStr := 'IDLE';
    LastStateStr := 'OFFLINE';
  end;
  if CurStateStr = 'APP_SYS_EXIT' then
  begin
    CurStateStr := 'OFFLINE';
    LastStateStr := '';
  end;
  TAppStatusChangeEvent.New(CurStateStr, LastStateStr, AEvent.FAppName);
end;

procedure TAppStatusEventHandler.OnEvent(AEvent: TBaseEvent);
var
  Event: TAppStatusEvent;
begin
  if not (AEvent is TAppStatusEvent) then Exit;

  Event := AEvent as TAppStatusEvent;
  if (Event.FEventType = APP_SYS_START) or (Event.FEventType = APP_SYS_EXIT) then
  begin
    HandleAppSysEvent(Event);
  end;
  // ??????????
  if (Event.FEventType =  APP_WORK_START) or (Event.FEventType = APP_WORK_FINISH) then
  begin
    HandleWorkEvent(Event);
  end;

  if (Event.FInsUUID <> '') and FAppDic.ContainsKey(Event.FInsUUID) then
    Event.FAppName := FAppDic[Event.FInsUUID]
  else
  begin
    Event.FAppName := GetDBUtil.QueryStr(Format('select AppName from tbl_appInstance where InstanceUUID = "%s"',
      [Event.FInsUUID]));
    if (Event.FAppName <> '') and (Event.FInsUUID <> '') then
      FAppDic.AddOrSetValue(Event.FInsUUID, Event.FAppName);
  end;
end;

{ TAppStatusChangeEvent }

class procedure TAppStatusChangeEvent.New(ANowState, ALastState,
  AppName: string);
var
  InsID: Integer;
begin
  InsID := 0;
  if (FsdcContext <> nil) and (FsdcContext.InsLog <> nil) then
    InsID := FsdcContext.InsLog.ID;

  New(ANowState, ALastState, AppName, Now, _GetTickCount64, InsID);
end;

class procedure TAppStatusChangeEvent.New(ANowState, ALastState,
  AppName: string; ALocalTime: TDateTime; AActionTick: Int64;
  FsdcInsID: Integer);
var
  Event: TAppStatusChangeEvent;
begin
  Event := TAppStatusChangeEvent.Create;
  Event.FNowState := ANowState;
  Event.FLastState := ALastState;
  Event.FAppName := AppName;
  Event.FLocalTime := ALocalTime;
  Event.FActionTick := AActionTick;
  Event.FFsdcInsID := FsdcInsID;
  TEventBus.AppEvent.Publish(Event);
end;

{ TAppStatusChangeEventHandler }

function TAppStatusChangeEventHandler.GetLastState(AppName: string): string;
const
  QUERY_SQL = 'select NowState from tbl_status_log ' +
  ' where AppName = "%s" order by LocalTime desc LIMIT 1';
begin
  Result := GetDBUtil.QueryStr(Format(QUERY_SQL, [AppName]));
end;

procedure TAppStatusChangeEventHandler.OnEvent(AEvent: TBaseEvent);
begin
 if not (AEvent is TAppStatusChangeEvent) then Exit;

  RecordChangeLog(AEvent as TAppStatusChangeEvent);
end;

procedure TAppStatusChangeEventHandler.RecordChangeLog(
  AEvent: TAppStatusChangeEvent);
const
  INSERT_SQL = 'Insert into tbl_status_log(NowState, LastState, LocalTime, ' +
  'StartTick, FsdcInsID, AppName) VALUES(?, ?, ?, ?, ?, ?)';
var
  Stmt: TDISQLITE3Statement;
begin
  Stmt := GetDBUtil.PrepareStatement(INSERT_SQL);
  if (AEvent.FLastState = 'UNKNOWN') or (AEvent.FNowState = 'APP_SYS_EXIT') then
    AEvent.FLastState := GetLastState(AEvent.FAppName);

  if Stmt = nil then Exit;
  try
    try
      Stmt.Bind_Str16(1, AEvent.FNowState);
      Stmt.Bind_Str16(2, AEvent.FLastState);
      Stmt.Bind_Double(3, AEvent.FLocalTime);
      Stmt.Bind_Int64(4, AEvent.FActionTick);
      Stmt.Bind_Int(5, AEvent.FFsdcInsID);
      Stmt.Bind_Str16(6, AEvent.FAppName);
      Stmt.Step;
    finally
      Stmt.Free;
    end;
  except

  end;
end;

initialization
  TEventBus.AppEvent.RegisterHandler(TAppStatusEventHandler);
  TEventBus.AppEvent.RegisterHandler(TAppStatusChangeEventHandler);

end.
