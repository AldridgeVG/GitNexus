
unit AppStatus;

interface

type
  TBaseEvent = class
  end;

  TAppStatusEvent = class(TBaseEvent)
    FEventType: Integer;
    FInsUUID: string;
    FAppName: string;
  end;

  TAppStatusEventHandler = class
  private
    FAppDic: TObject;
    function GetDBUtil: TObject;
    procedure HandleAppSysEvent(Event: TAppStatusEvent);
    procedure HandleWorkEvent(Event: TAppStatusEvent);
  public
    procedure OnEvent(AEvent: TBaseEvent);
  end;

implementation

{ TAppStatusEventHandler }

function TAppStatusEventHandler.GetDBUtil: TObject;
begin
  Result := nil;
end;

procedure TAppStatusEventHandler.HandleAppSysEvent(Event: TAppStatusEvent);
begin
  // handle sys event
end;

procedure TAppStatusEventHandler.HandleWorkEvent(Event: TAppStatusEvent);
begin
  // handle work event
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
  if (Event.FEventType = APP_WORK_START) or (Event.FEventType = APP_WORK_FINISH) then
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

end.
