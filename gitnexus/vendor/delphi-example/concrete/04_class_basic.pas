{ Delphi 类定义基础示例 }
unit ClassBasic;

interface

uses
  Windows, SysUtils, Classes, Generics.Collections;

type
  // ========== 基础类 ==========
  TBaseEvent = class
  private
    FEventUUID: string;
    FTopic: string;
  public
    constructor Create;
    property Topic: string read FTopic;
    property EventUUID: string read FEventUUID;
  end;

  // ========== 带属性的类 ==========
  TBaseEntity = class
  private
    FID: Integer;
  public
    property ID: Integer read FID write FID;
    procedure PopulateFromMap(Data: TDictionary<string, Variant>);
  end;

  // ========== 抽象基类 ==========
  TBaseEventHandler = class
  private
    FTopic: string;
  protected
    procedure OnEvent(AEvent: TBaseEvent); virtual; abstract;
  public
    constructor Create; virtual;
    property Topic: string read FTopic;
  end;

  // ========== 完整类定义示例 ==========
  TCloudTaskSvc = class
  private
    FAuthStr: string;
    FExpiredTime: TDateTime;
    procedure PrepareAuthStr;
    function GetAuthStr: string;
    function GetRequestResult(ADomain: THttpDomain; AURI: string; AMethod: THttpMethod;
      AData: ISuperObject; ACheckAuth: Boolean = False): ISuperObject;
  public
    function ListCloudTask(ASearchText: string; APageSize, APageNum: Integer): ISuperObject;
    function PullTask(AParamData: ISuperObject): ISuperObject;
    function UpdateTaskStatus(AUUID, AFilePath: string): ISuperObject;
  end;

  // ========== 带构造/析构的类 ==========
  TRunnaleWrapper = class
  private
    FRunnale: IRunnable;
  public
    constructor Create(ARunnable: IRunnable);
    procedure Run();
  end;

  // ========== 异常类 ==========
  EAuthException = class(Exception)
  private
    FStatus: Integer;
    FMsg: string;
  public
    constructor Create(AStatus: Integer; AMsg: string);
    property Status: Integer read FStatus;
    property Msg: string read FMsg;
  end;

implementation

uses
  Rtti, Variants;

{ TBaseEvent }

constructor TBaseEvent.Create;
var
  GUID: TGUID;
begin
  CreateGUID(GUID);
  FEventUUID := GUIDToString(GUID);
end;

{ TBaseEventHandler }

constructor TBaseEventHandler.Create;
begin
  FTopic := '';
end;

{ TBaseEntity }

procedure TBaseEntity.PopulateFromMap(Data: TDictionary<string, Variant>);
var
  RttiContext: TRttiContext;
  RttiType: TRttiType;
  RttiProp: TRttiProperty;
  Value: Variant;
begin
  RttiContext := TRttiContext.Create;
  try
    RttiType := RttiContext.GetType(Self.ClassType);
    for RttiProp in RttiType.GetProperties do
    begin
      if RttiProp.IsWritable and Data.TryGetValue(RttiProp.Name, Value) then
      begin
        if VarIsNull(Value) then
          RttiProp.SetValue(Self, TValue.Empty)
        else
          case RttiProp.PropertyType.TypeKind of
            tkInteger:
              RttiProp.SetValue(Self, TValue.From<Integer>(Value));
            tkInt64:
              RttiProp.SetValue(Self, TValue.From<Int64>(Value));
            tkUString:
              RttiProp.SetValue(Self, TValue.From<string>(Value));
          end;
      end;
    end;
  finally
    RttiContext.Free;
  end;
end;

{ TRunnaleWrapper }

constructor TRunnaleWrapper.Create(ARunnable: IRunnable);
begin
  FRunnale := ARunnable;
end;

procedure TRunnaleWrapper.Run;
begin
  if Assigned(FRunnale) then
    FRunnale.Run;
end;

{ EAuthException }

constructor EAuthException.Create(AStatus: Integer; AMsg: string);
begin
  FStatus := AStatus;
  FMsg := AMsg;
  inherited Create(AMsg);
end;

end.
