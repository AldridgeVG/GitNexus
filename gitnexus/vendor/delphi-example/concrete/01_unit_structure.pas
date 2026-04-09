{ Delphi Unit 基本结构示例 }
unit UnitStructure;

interface

uses
  Windows, SysUtils, Classes, Generics.Collections;

type
  // 在此声明类型

implementation

uses
  // 实现部分引用的单元
  Rtti, Variants;

// 在此实现代码

initialization
  // 单元初始化代码

finalization
  // 单元清理代码

end.
