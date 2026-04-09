{ Delphi RTTI 运行时类型信息示例 }
unit RttiReflection;

interface

uses
  Windows, SysUtils, Classes, Rtti, TypInfo, Generics.Collections, Variants;

type
  // ========== RTTI 辅助类 ==========

  TRttiHelper = class
  public
    // 获取类的所有属性
    class procedure GetProperties(AClass: TClass; PropertyList: TStrings);
    // 获取类的所有方法
    class procedure GetMethods(AClass: TClass; MethodList: TStrings);
    // 获取属性值
    class function GetPropertyValue(Instance: TObject; const PropertyName: string): TValue;
    // 设置属性值
    class procedure SetPropertyValue(Instance: TObject; const PropertyName: string; const Value: TValue);
    // 检查类是否有某个属性
    class function HasProperty(AClass: TClass; const PropertyName: string): Boolean;
    // 获取属性类型
    class function GetPropertyType(AClass: TClass; const PropertyName: string): TTypeKind;
    // 获取类属性
    class function GetClassAttribute<T: TCustomAttribute>(AClass: TClass): T;
    // 获取方法属性
    class function GetMethodAttribute<T: TCustomAttribute>(AClass: TClass; const MethodName: string): T;
  end;

  // ========== 对象克隆 ==========

  TObjectCloner = class
  public
    class function Clone<T: class>(Source: T): T;
    class procedure CopyProperties(Source, Dest: TObject);
  end;

  // ========== 对象映射 ==========

  TObjectMapper = class
  public
    class procedure MapTo(Source: TObject; Dest: TObject);
    class function Map<T: class, constructor>(Source: TObject): T;
    class procedure MapFromDictionary(Dict: TDictionary<string, Variant>; Instance: TObject);
  end;

  // ========== 属性访问器 ==========

  TPropertyAccessor = class
  private
    FInstance: TObject;
    FRttiContext: TRttiContext;
    FRttiType: TRttiType;
  public
    constructor Create(Instance: TObject);
    function Get(const PropertyName: string): TValue;
    procedure SetValue(const PropertyName: string; const Value: TValue);
    function GetType(const PropertyName: string): TRttiType;
    function Exists(const PropertyName: string): Boolean;
  end;

  // ========== 自定义属性 ==========

  ColumnAttribute = class(TCustomAttribute)
  private
    FName: string;
    FLength: Integer;
    FNullable: Boolean;
  public
    constructor Create(const AName: string; ALength: Integer = 0; ANullable: Boolean = True);
    property Name: string read FName;
    property Length: Integer read FLength;
    property Nullable: Boolean read FNullable;
  end;

  TableAttribute = class(TCustomAttribute)
  private
    FName: string;
  public
    constructor Create(const AName: string);
    property Name: string read FName;
  end;

  // ========== 使用自定义属性的类 ==========

  [Table('users')]
  TUserEntity = class
  private
    FID: Integer;
    FUsername: string;
    FEmail: string;
    FAge: Integer;
  public
    [Column('id', 0, False)]
    property ID: Integer read FID write FID;
    [Column('username', 50, False)]
    property Username: string read FUsername write FUsername;
    [Column('email', 100, True)]
    property Email: string read FEmail write FEmail;
    [Column('age', 0, True)]
    property Age: Integer read FAge write FAge;
  end;

implementation

{ ========== TRttiHelper ========== }

class procedure TRttiHelper.GetProperties(AClass: TClass; PropertyList: TStrings);
var
  Context: TRttiContext;
  RttiType: TRttiType;
  Prop: TRttiProperty;
begin
  PropertyList.Clear;
  Context := TRttiContext.Create;
  try
    RttiType := Context.GetType(AClass);
    if Assigned(RttiType) then
    begin
      for Prop in RttiType.GetProperties do
        PropertyList.Add(Prop.Name);
    end;
  finally
    Context.Free;
  end;
end;

class procedure TRttiHelper.GetMethods(AClass: TClass; MethodList: TStrings);
var
  Context: TRttiContext;
  RttiType: TRttiType;
  Method: TRttiMethod;
begin
  MethodList.Clear;
  Context := TRttiContext.Create;
  try
    RttiType := Context.GetType(AClass);
    if Assigned(RttiType) then
    begin
      for Method in RttiType.GetMethods do
        MethodList.Add(Method.Name);
    end;
  finally
    Context.Free;
  end;
end;

class function TRttiHelper.GetPropertyValue(Instance: TObject; const PropertyName: string): TValue;
var
  Context: TRttiContext;
  RttiType: TRttiType;
  Prop: TRttiProperty;
begin
  Context := TRttiContext.Create;
  try
    RttiType := Context.GetType(Instance.ClassType);
    Prop := RttiType.GetProperty(PropertyName);
    if Assigned(Prop) and Prop.IsReadable then
      Result := Prop.GetValue(Instance)
    else
      Result := TValue.Empty;
  finally
    Context.Free;
  end;
end;

class procedure TRttiHelper.SetPropertyValue(Instance: TObject; const PropertyName: string; const Value: TValue);
var
  Context: TRttiContext;
  RttiType: TRttiType;
  Prop: TRttiProperty;
begin
  Context := TRttiContext.Create;
  try
    RttiType := Context.GetType(Instance.ClassType);
    Prop := RttiType.GetProperty(PropertyName);
    if Assigned(Prop) and Prop.IsWritable then
      Prop.SetValue(Instance, Value);
  finally
    Context.Free;
  end;
end;

class function TRttiHelper.HasProperty(AClass: TClass; const PropertyName: string): Boolean;
var
  Context: TRttiContext;
  RttiType: TRttiType;
begin
  Context := TRttiContext.Create;
  try
    RttiType := Context.GetType(AClass);
    Result := Assigned(RttiType) and Assigned(RttiType.GetProperty(PropertyName));
  finally
    Context.Free;
  end;
end;

class function TRttiHelper.GetPropertyType(AClass: TClass; const PropertyName: string): TTypeKind;
var
  Context: TRttiContext;
  RttiType: TRttiType;
  Prop: TRttiProperty;
begin
  Context := TRttiContext.Create;
  try
    RttiType := Context.GetType(AClass);
    Prop := RttiType.GetProperty(PropertyName);
    if Assigned(Prop) and Assigned(Prop.PropertyType) then
      Result := Prop.PropertyType.TypeKind
    else
      Result := tkUnknown;
  finally
    Context.Free;
  end;
end;

class function TRttiHelper.GetClassAttribute<T: TCustomAttribute>(AClass: TClass): T;
var
  Context: TRttiContext;
  RttiType: TRttiType;
  Attr: TCustomAttribute;
begin
  Result := nil;
  Context := TRttiContext.Create;
  try
    RttiType := Context.GetType(AClass);
    if Assigned(RttiType) then
    begin
      for Attr in RttiType.GetAttributes do
      begin
        if Attr is T then
          Exit(T(Attr));
      end;
    end;
  finally
    Context.Free;
  end;
end;

class function TRttiHelper.GetMethodAttribute<T: TCustomAttribute>(AClass: TClass; const MethodName: string): T;
var
  Context: TRttiContext;
  RttiType: TRttiType;
  Method: TRttiMethod;
  Attr: TCustomAttribute;
begin
  Result := nil;
  Context := TRttiContext.Create;
  try
    RttiType := Context.GetType(AClass);
    if Assigned(RttiType) then
    begin
      Method := RttiType.GetMethod(MethodName);
      if Assigned(Method) then
      begin
        for Attr in Method.GetAttributes do
        begin
          if Attr is T then
            Exit(T(Attr));
        end;
      end;
    end;
  finally
    Context.Free;
  end;
end;

{ ========== TObjectCloner ========== }

class function TObjectCloner.Clone<T>(Source: T): T;
begin
  if not Assigned(Source) then
    Exit(nil);

  Result := T(Source.ClassType.Create);
  CopyProperties(Source, Result);
end;

class procedure TObjectCloner.CopyProperties(Source, Dest: TObject);
var
  Context: TRttiContext;
  SourceType, DestType: TRttiType;
  SourceProp, DestProp: TRttiProperty;
begin
  if not Assigned(Source) or not Assigned(Dest) then Exit;

  Context := TRttiContext.Create;
  try
    SourceType := Context.GetType(Source.ClassType);
    DestType := Context.GetType(Dest.ClassType);

    for SourceProp in SourceType.GetProperties do
    begin
      if not SourceProp.IsReadable then Continue;

      DestProp := DestType.GetProperty(SourceProp.Name);
      if Assigned(DestProp) and DestProp.IsWritable then
      begin
        if SourceProp.PropertyType.TypeKind = DestProp.PropertyType.TypeKind then
          DestProp.SetValue(Dest, SourceProp.GetValue(Source));
      end;
    end;
  finally
    Context.Free;
  end;
end;

{ ========== TObjectMapper ========== }

class procedure TObjectMapper.MapTo(Source: TObject; Dest: TObject);
begin
  TObjectCloner.CopyProperties(Source, Dest);
end;

class function TObjectMapper.Map<T>(Source: TObject): T;
begin
  if not Assigned(Source) then
    Exit(nil);

  Result := T.Create;
  try
    CopyProperties(Source, Result);
  except
    Result.Free;
    raise;
  end;
end;

class procedure TObjectMapper.MapFromDictionary(Dict: TDictionary<string, Variant>; Instance: TObject);
var
  Context: TRttiContext;
  RttiType: TRttiType;
  Prop: TRttiProperty;
  Value: Variant;
  TV: TValue;
begin
  Context := TRttiContext.Create;
  try
    RttiType := Context.GetType(Instance.ClassType);

    for Prop in RttiType.GetProperties do
    begin
      if not Prop.IsWritable then Continue;
      if not Dict.TryGetValue(Prop.Name, Value) then Continue;

      if VarIsNull(Value) then
      begin
        Prop.SetValue(Instance, TValue.Empty);
      end
      else
      begin
        case Prop.PropertyType.TypeKind of
          tkInteger:
            begin
              TV := TValue.From<Integer>(Value);
              Prop.SetValue(Instance, TV);
            end;
          tkInt64:
            begin
              TV := TValue.From<Int64>(Value);
              Prop.SetValue(Instance, TV);
            end;
          tkUString, tkString, tkWString:
            begin
              TV := TValue.From<string>(Value);
              Prop.SetValue(Instance, TV);
            end;
          tkFloat:
            begin
              TV := TValue.From<Double>(Value);
              Prop.SetValue(Instance, TV);
            end;
          tkEnumeration:
            begin
              // 处理枚举类型
              if Prop.PropertyType.Handle = TypeInfo(Boolean) then
              begin
                TV := TValue.From<Boolean>(Value);
                Prop.SetValue(Instance, TV);
              end;
            end;
        end;
      end;
    end;
  finally
    Context.Free;
  end;
end;

{ ========== TPropertyAccessor ========== }

constructor TPropertyAccessor.Create(Instance: TObject);
begin
  inherited Create;
  FInstance := Instance;
  FRttiContext := TRttiContext.Create;
  FRttiType := FRttiContext.GetType(Instance.ClassType);
end;

function TPropertyAccessor.Get(const PropertyName: string): TValue;
var
  Prop: TRttiProperty;
begin
  Prop := FRttiType.GetProperty(PropertyName);
  if Assigned(Prop) and Prop.IsReadable then
    Result := Prop.GetValue(FInstance)
  else
    Result := TValue.Empty;
end;

procedure TPropertyAccessor.SetValue(const PropertyName: string; const Value: TValue);
var
  Prop: TRttiProperty;
begin
  Prop := FRttiType.GetProperty(PropertyName);
  if Assigned(Prop) and Prop.IsWritable then
    Prop.SetValue(FInstance, Value);
end;

function TPropertyAccessor.GetType(const PropertyName: string): TRttiType;
var
  Prop: TRttiProperty;
begin
  Prop := FRttiType.GetProperty(PropertyName);
  if Assigned(Prop) then
    Result := Prop.PropertyType
  else
    Result := nil;
end;

function TPropertyAccessor.Exists(const PropertyName: string): Boolean;
begin
  Result := Assigned(FRttiType.GetProperty(PropertyName));
end;

{ ========== 自定义属性 ========== }

constructor ColumnAttribute.Create(const AName: string; ALength: Integer; ANullable: Boolean);
begin
  FName := AName;
  FLength := ALength;
  FNullable := ANullable;
end;

constructor TableAttribute.Create(const AName: string);
begin
  FName := AName;
end;

end.
