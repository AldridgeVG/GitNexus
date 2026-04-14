# Delphi 命名规范

编写 Delphi 代码时必须遵循以下命名规则。

## 大小写与风格

- 常量：全大写 + 下划线分隔，如 `MAX_RETRY_COUNT`
- 变量、类、函数：PascalCase（大驼峰）
- 关键字/保留字：全小写，如 `begin`, `end`, `string`, `for`

## 前缀规则

| 前缀 | 适用范围 | 示例 |
|------|---------|------|
| `T` | 类、结构体、枚举、集合类型声明 | `TPoint`, `TForm` |
| `I` | 接口类型 | `IServiceProvider` |
| `E` | 异常类型 | `EArgumentException` |
| `P` | 指针类型 | `PMemoryBasicInformation` |
| `F` | 类的 private 成员变量、implementation 下全局变量 | `FThread` |
| `G` | interface 下的全局变量 | `GDeviceManager` |
| `A` | 函数形参 | `ACurve: TCurve` |
| `S` | 字符串常量/变量声明 | `SServo: string = '...'` |
| `Temp` | 当前函数内创建并销毁的临时对象变量 | `TempList` |

- 函数局部变量**无需前缀**，通过上下文即可识别作用域
- 枚举元素：类型名小写缩写 + 含义，如 `TAlign` 的元素 `alNone`, `alTop`

## 命名原则

- 变量名是名词，函数/过程名是动词
- 禁止单字母命名（循环下标 `I`, `J`, `K` 除外）
- 使用完整单词组合，变量名 2-7 个单词（不含前缀）
- 禁止自创缩写，仅允许广为人知的缩写或元音字母缩写
- 避免命名冲突或极其相似的命名
- 使用设计模式的地方在命名中体现，如 `xxxFactory`, `xxxProxy`
- 从 0 开始的索引用 `Id`/`Idx`，从 1 开始的用 `Num`
