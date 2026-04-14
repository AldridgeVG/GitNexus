# Delphi 安全性规范

编写 Delphi 代码时必须遵循以下安全性规则，涵盖内存管理、多线程、数值计算和异常处理。

## 内存管理

- 使用指针/对象前，若不能保证其一定存在，必须用 `Assigned()` 判空
- 对象生命周期正确管理：**创建放构造函数，释放放析构函数，成对出现**
- 哪里创建、哪里释放；跨模块传递对象时需建立明确的所有权约定
- 用 `try...finally` 保证异常情况下的内存释放：
  ```pascal
  Obj := TObject.Create;
  try
    Obj.Work();
  finally
    Obj.Free;
  end;
  ```
- `try` 应紧接 `Create`，中间不插入其他代码
- 优先使用 `FreeAndNil(Obj)` 而非 `Obj.Free`，避免野指针
- 管理对象列表时优先使用 `TObjectList<T>`（指定 AOwnsObjects）而非 `TList<T>`
- 访问数组/List 时严格检查下标范围，注意 Delphi 数组可能不从 0 开始
- 尽量避免直接内存操作（Move, MemCopy），必须使用时严格检查边界
- Debug 模式下开启 `ReportMemoryLeaksOnShutdown`

## 多线程

- 多线程读写同一数据**必须加锁**（TCriticalSection / 原子操作）
- 锁和临界区控制范围**尽可能小**，只包括需要同步的变量
- 合理使用 `Enter`（等待锁）和 `TryEnter`（非阻塞尝试）
- 创建线程时**必须命名**（`SetThreadName` / `NameThreadForDebugging`）
- while 循环中必须加 `Sleep`，避免 CPU 空转
- **禁止在非主线程中操作 VCL 控件**，需通过 `TThread.Synchronize` 调度到主线程
- 注意死锁问题：仔细检查每把锁的出入口
- 使用多线程要有节制，必要时使用线程池，避免频繁创建大量线程

## 数值计算

- **所有除法必须做除零检查和保护**
- 避免数值计算溢出：注意无符号数减法溢出、分母极小导致的误差
- 避免数值类型溢出：
  - 编码器反馈等大范围值使用 `Int64` 而非 `Integer`
  - 数学函数注意值域（`Power` 不传负值，反三角函数不传大于 1 的值）
- **浮点数不能用等号比较**，必须引入合理容差
- 上层容差不应小于底层容差
- 整型推荐 `Integer`（Int32），需要时用 `Int64`；地址用 `NativeInt`；多状态用枚举
- 浮点数推荐 `Double`

## 异常处理

- **禁止在析构函数中抛出异常**
- **异常必须被捕获并处理，不要吞异常**
- 禁止在 `finally` 中 `Exit`（会覆盖 Result 或吞异常）
- 禁止在 `finally` 中触发新异常（会吞 try 中的异常）
- 避免在循环中输出日志，日志应记录有效信息
