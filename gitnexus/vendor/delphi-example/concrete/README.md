# Delphi 语法分析验证代码示例

本目录包含了从 `fsdc` 代码库中提炼的关键 Delphi/Pascal 代码形式，用于 Delphi 语法分析器的验证。

## 文件列表

| 文件名 | 描述 | 关键语法点 |
|--------|------|-----------|
| `01_unit_structure.pas` | 单元基本结构 | unit, interface, uses, implementation, initialization, finalization |
| `02_data_types.pas` | 数据类型定义 | 枚举、record、数组、指针、过程类型、常量、全局变量 |
| `03_interface_types.pas` | 接口定义 | interface、GUID、继承接口、泛型接口 |
| `04_class_basic.pas` | 基础类定义 | class、属性、构造/析构、异常类 |
| `05_class_advanced.pas` | 高级类定义 | 继承、接口实现、线程类、泛型集合、属性声明属性 |
| `06_procedures_functions.pas` | 过程和函数 | 重载、默认参数、region、外部函数声明 |
| `07_control_flow.pas` | 控制流语句 | if/else、case、for、while、repeat、try/except/finally |
| `08_string_operations.pas` | 字符串操作 | Format、StringReplace、编码转换、路径处理 |
| `09_generic_types.pas` | 泛型类型 | 泛型类、泛型方法、泛型接口、泛型约束 |
| `10_rtti_reflection.pas` | RTTI 反射 | TRttiContext、属性访问、自定义属性 |
| `11_memory_management.pas` | 内存管理 | 动态数组、指针操作、内存流 |
| `12_windows_api.pas` | Windows API | API 声明、回调函数、stdcall |
| `13_database_operations.pas` | 数据库操作 | SQL 构建器、事务处理、实体类 |

## 关键语法特性汇总

### 1. 基本结构
- Unit 结构: `unit`, `interface`, `uses`, `implementation`, `initialization`, `finalization`
- 程序块: `begin`/`end`, `procedure`, `function`

### 2. 数据类型
- 基本类型: `Integer`, `Int64`, `Double`, `Boolean`, `Char`, `string`
- 枚举类型: `type TEnum = (value1, value2);`
- 记录类型: `record` / `packed record`
- 数组类型: 静态数组、动态数组 `TArray<T>`
- 指针类型: `^T`, `@` 操作符
- 过程类型: `procedure of object`

### 3. 类与对象
- 类声明: `class`, `class(TAncestor)`, `class abstract`
- 属性: `property`, `read`, `write`, `default`
- 方法: `virtual`, `override`, `abstract`, `reintroduce`
- 构造/析构: `constructor`, `destructor`
- 属性声明属性: `class(TCustomAttribute)`

### 4. 接口
- 接口声明: `interface`, `['{GUID}']`
- 接口继承: `interface(IBase)`
- 接口实现: `class(TObject, IInterface)`

### 5. 泛型
- 泛型类: `TClass<T>`, `TClass<T: class>`
- 泛型方法: `procedure Method<T>`
- 泛型约束: `constructor`, `class`, `record`
- 标准泛型: `TList<T>`, `TDictionary<K,V>`, `TArray<T>`

### 6. 控制流
- 条件: `if`/`then`/`else`, `case`/`of`/`else`
- 循环: `for`/`to`/`do`, `for`/`in`/`do`, `while`/`do`, `repeat`/`until`
- 跳转: `Exit`, `Break`, `Continue`

### 7. 异常处理
- `try`/`except`/`end`
- `try`/`finally`/`end`
- `try`/`except`/`on E: Exception`/`end`
- `raise`, `raise E`

### 8. 字符串操作
- 字符串函数: `Format`, `StringReplace`, `Pos`, `Copy`, `Length`
- 字符串类型: `string`, `AnsiString`, `WideString`, `UnicodeString`

### 9. 内存管理
- 动态数组: `SetLength`, `Length`, `High`, `Low`
- 指针: `New`, `Dispose`, `GetMem`, `FreeMem`
- 对象: `Create`, `Free`, `FreeAndNil`

### 10. 其他特性
- 条件编译: `{$IFDEF}`, `{$ELSE}`, `{$ENDIF}`
- 区域: `{$REGION}`/`{$ENDREGION}`
- 外部函数: `external`, `stdcall`, `cdecl`
- RTTI: `TRttiContext`, `TRttiType`, `TRttiProperty`
