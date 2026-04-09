{ Delphi 泛型类型示例 }
unit GenericTypes;

interface

uses
  Windows, SysUtils, Classes, Generics.Collections, Generics.Defaults;

type
  // ========== 泛型类示例 ==========

  TGenericPair<TKey, TValue> = class
  private
    FKey: TKey;
    FValue: TValue;
  public
    constructor Create(const AKey: TKey; const AValue: TValue);
    property Key: TKey read FKey;
    property Value: TValue read FValue write FValue;
  end;

  TGenericStack<T> = class
  private
    FItems: array of T;
    FCount: Integer;
    function GetItem(Index: Integer): T;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Push(const Item: T);
    function Pop: T;
    function Peek: T;
    function Count: Integer;
    property Items[Index: Integer]: T read GetItem; default;
  end;

  // ========== 泛型字典使用示例 ==========

  TStringIntDict = TDictionary<string, Integer>;
  TIntStrDict = TDictionary<Integer, string>;
  TStringObjectDict = TObjectDictionary<string, TObject>;
  TStringStringDict = TDictionary<string, string>;

  // ========== 泛型列表使用示例 ==========

  TStringList<T> = class(TList<T>)
  public
    function Join(const Separator: string): string;
    procedure SortBy(Comparison: TComparison<T>);
  end;

  // ========== 泛型接口示例 ==========

  IRepository<T> = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    function GetById(Id: Integer): T;
    function GetAll: TList<T>;
    procedure Add(Entity: T);
    procedure Update(Entity: T);
    procedure Delete(Id: Integer);
  end;

  IComparer<T> = interface
    function Compare(const Left, Right: T): Integer;
  end;

  // ========== 带约束的泛型类 ==========

  TEntityRepository<T: class, constructor> = class(TInterfacedObject, IRepository<T>)
  private
    FItems: TDictionary<Integer, T>;
    FNextId: Integer;
  public
    constructor Create;
    destructor Destroy; override;
    function GetById(Id: Integer): T;
    function GetAll: TList<T>;
    procedure Add(Entity: T);
    procedure Update(Entity: T);
    procedure Delete(Id: Integer);
  end;

  // ========== 泛型方法示例 ==========

  TGenericUtils = class
  public
    class function IfThen<T>(Condition: Boolean; const ThenValue, ElseValue: T): T;
    class procedure Swap<T>(var A, B: T);
    class function InArray<T>(const Value: T; const Values: array of T): Boolean;
    class function Coalesce<T>(const Values: array of T; const DefaultValue: T): T;
  end;

  // ========== 泛型事件示例 ==========

  TEventHandler<T> = procedure(Sender: TObject; const EventArgs: T) of object;

  TEventPublisher<T> = class
  private
    FHandlers: TList<TEventHandler<T>>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Subscribe(Handler: TEventHandler<T>);
    procedure Unsubscribe(Handler: TEventHandler<T>);
    procedure Publish(Sender: TObject; const EventArgs: T);
  end;

  // ========== 泛型枚举器示例 ==========

  TRangeEnumerator<T: Integer> = class
  private
    FCurrent: T;
    FStart: T;
    FEnd: T;
    FStep: T;
  public
    constructor Create(Start, Finish: T; Step: T = 1);
    function MoveNext: Boolean;
    property Current: T read FCurrent;
  end;

implementation

{ ========== TGenericPair<TKey, TValue> ========== }

constructor TGenericPair<TKey, TValue>.Create(const AKey: TKey; const AValue: TValue);
begin
  FKey := AKey;
  FValue := AValue;
end;

{ ========== TGenericStack<T> ========== }

constructor TGenericStack<T>.Create;
begin
  inherited Create;
  FCount := 0;
  SetLength(FItems, 16);  // 初始容量
end;

destructor TGenericStack<T>.Destroy;
begin
  SetLength(FItems, 0);
  inherited;
end;

function TGenericStack<T>.GetItem(Index: Integer): T;
begin
  if (Index < 0) or (Index >= FCount) then
    raise EListError.Create('Index out of bounds');
  Result := FItems[Index];
end;

procedure TGenericStack<T>.Push(const Item: T);
begin
  if FCount >= Length(FItems) then
    SetLength(FItems, Length(FItems) * 2);
  FItems[FCount] := Item;
  Inc(FCount);
end;

function TGenericStack<T>.Pop: T;
begin
  if FCount = 0 then
    raise EListError.Create('Stack is empty');
  Dec(FCount);
  Result := FItems[FCount];
end;

function TGenericStack<T>.Peek: T;
begin
  if FCount = 0 then
    raise EListError.Create('Stack is empty');
  Result := FItems[FCount - 1];
end;

function TGenericStack<T>.Count: Integer;
begin
  Result := FCount;
end;

{ ========== TStringList<T> ========== }

function TStringList<T>.Join(const Separator: string): string;
var
  I: Integer;
  SB: TStringBuilder;
  Comparer: IEqualityComparer<T>;
begin
  if Count = 0 then Exit('');

  SB := TStringBuilder.Create;
  try
    for I := 0 to Count - 1 do
    begin
      if I > 0 then
        SB.Append(Separator);
      // 使用默认比较器处理不同类型
      Comparer := TEqualityComparer<T>.Default;
      SB.Append(Items[I].ToString);
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

procedure TStringList<T>.SortBy(Comparison: TComparison<T>);
begin
  Sort(TComparer<T>.Construct(Comparison));
end;

{ ========== TEntityRepository<T> ========== }

constructor TEntityRepository<T>.Create;
begin
  inherited Create;
  FItems := TDictionary<Integer, T>.Create;
  FNextId := 1;
end;

destructor TEntityRepository<T>.Destroy;
var
  Item: TPair<Integer, T>;
begin
  // 清理所有对象
  for Item in FItems do
    Item.Value.Free;
  FItems.Free;
  inherited;
end;

function TEntityRepository<T>.GetById(Id: Integer): T;
begin
  if not FItems.TryGetValue(Id, Result) then
    Result := nil;
end;

function TEntityRepository<T>.GetAll: TList<T>;
var
  Item: TPair<Integer, T>;
begin
  Result := TList<T>.Create;
  for Item in FItems do
    Result.Add(Item.Value);
end;

procedure TEntityRepository<T>.Add(Entity: T);
begin
  FItems.Add(FNextId, Entity);
  Inc(FNextId);
end;

procedure TEntityRepository<T>.Update(Entity: T);
begin
  // 更新逻辑
end;

procedure TEntityRepository<T>.Delete(Id: Integer);
var
  Entity: T;
begin
  if FItems.TryGetValue(Id, Entity) then
  begin
    Entity.Free;
    FItems.Remove(Id);
  end;
end;

{ ========== TGenericUtils ========== }

class function TGenericUtils.IfThen<T>(Condition: Boolean; const ThenValue, ElseValue: T): T;
begin
  if Condition then
    Result := ThenValue
  else
    Result := ElseValue;
end;

class procedure TGenericUtils.Swap<T>(var A, B: T);
var
  Temp: T;
begin
  Temp := A;
  A := B;
  B := Temp;
end;

class function TGenericUtils.InArray<T>(const Value: T; const Values: array of T): Boolean;
var
  I: Integer;
  Comparer: IEqualityComparer<T>;
begin
  Comparer := TEqualityComparer<T>.Default;
  for I := Low(Values) to High(Values) do
  begin
    if Comparer.Equals(Value, Values[I]) then
      Exit(True);
  end;
  Result := False;
end;

class function TGenericUtils.Coalesce<T>(const Values: array of T; const DefaultValue: T): T;
var
  I: Integer;
  Comparer: IEqualityComparer<T>;
  EmptyValue: T;
begin
  Comparer := TEqualityComparer<T>.Default;
  EmptyValue := Default(T);

  for I := Low(Values) to High(Values) do
  begin
    if not Comparer.Equals(Values[I], EmptyValue) then
      Exit(Values[I]);
  end;
  Result := DefaultValue;
end;

{ ========== TEventPublisher<T> ========== }

constructor TEventPublisher<T>.Create;
begin
  inherited Create;
  FHandlers := TList<TEventHandler<T>>.Create;
end;

destructor TEventPublisher<T>.Destroy;
begin
  FHandlers.Free;
  inherited;
end;

procedure TEventPublisher<T>.Subscribe(Handler: TEventHandler<T>);
begin
  if not FHandlers.Contains(Handler) then
    FHandlers.Add(Handler);
end;

procedure TEventPublisher<T>.Unsubscribe(Handler: TEventHandler<T>);
begin
  FHandlers.Remove(Handler);
end;

procedure TEventPublisher<T>.Publish(Sender: TObject; const EventArgs: T);
var
  Handler: TEventHandler<T>;
begin
  for Handler in FHandlers do
    Handler(Sender, EventArgs);
end;

{ ========== TRangeEnumerator<T> ========== }

constructor TRangeEnumerator<T>.Create(Start, Finish: T; Step: T);
begin
  FStart := Start;
  FEnd := Finish;
  FStep := Step;
  FCurrent := Start - Step;
end;

function TRangeEnumerator<T>.MoveNext: Boolean;
begin
  FCurrent := FCurrent + FStep;
  if FStep > 0 then
    Result := FCurrent <= FEnd
  else
    Result := FCurrent >= FEnd;
end;

end.
