---
name: csharp-style
description: Use when writing, editing, reviewing, or refactoring C#/.NET code
---

# C# Style

## 语法

- Span/Memory 代码中使用 `.Slice()` 而非 range 表达式
- 语法尽量使用模式匹配和递归模式
- 尽量不使用 nullable 抑制
- 简单 null/空值校验优先使用直接 guard clause，避免为了模式匹配而让判断复杂化
- 向量运算优先使用类型自带的运算符重载，而非 SIMD 专有方法
- 新语法只在能让代码更清晰或类型更安全时才用，已经清晰的写法不必为了统一而改
- 需要从内层循环跳出或继续外层循环时，给外层循环加标签并写 `break outer;` 或 `continue outer;`，不要用 `goto` 或布尔标志
- 集合表达式需要传比较器或容量时，写成 `[with(comparer), a, b]`；如果左侧已经写出了类型，直接用 `new(comparer)` 更简洁
- 要把一个已有集合整体传给构造函数时用 `new(source, comparer)`，因为 `[with(comparer), .. source]` 会先建空集合再逐个添加
- 给不属于自己的类型补索引访问时，可以在 `extension` 块里声明索引器；但只用于廉价且安全的访问，不要用它把线性查找或 `Unsafe.Add` 这类无检查访问包装成 `x[i]`

## 多选一的类型

- 如果一个值只能是几种形态之一，而且每种形态带的数据不同，就用类型把它表达出来，不要靠互斥的可空成员、`Debug.Assert(x is not null)` 或强转来维持
- 各个分支是专门为此新建的类型时，用 `closed` 基类加嵌套的 `sealed` 子类；分支是已有的类型时，用 `union Name(A, B)`，但要注意它会把值类型分支装箱
- 按分支处理时优先写不带 `_` 分支的 `switch` 表达式，这样以后新增分支，编译器会指出漏改的地方；`switch` 语句没有这项检查，需要自己加上 `default: throw new UnreachableException();`

## 格式

- 方法声明和调用的参数列表应保持单行，简短的泛型约束也与声明同行；仅在参数较多、表达式复杂或存在清晰语义分组，且单行明显影响可读性时才换行

## 语言版本

- `closed`、`union`、`with(...)`、扩展索引器和带标签的跳转都是 C# 15 的语法，项目的语言版本低于 15 时不要使用
- 项目同时面向 net11.0 以下的目标时，还要为 `closed` 和 `union` 补上 `IsClosedTypeAttribute`、`UnionAttribute`、`IUnion` 的 internal 定义，并放在 `#if !NET11_0_OR_GREATER` 里
