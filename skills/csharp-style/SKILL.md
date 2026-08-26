---
name: csharp-style
description: Use when writing, editing, reviewing, or refactoring C#/.NET code
---

# C# Style

- Span/Memory 代码中使用 `.Slice()` 而非 range 表达式
- 语法尽量使用模式匹配和递归模式
- 尽量不使用 nullable 抑制
- 简单 null/空值校验优先使用直接 guard clause，避免为了模式匹配而让判断复杂化
- 方法声明和调用的参数列表应保持单行，简短的泛型约束也与声明同行；仅在参数较多、表达式复杂或存在清晰语义分组，且单行明显影响可读性时才换行
- 向量运算优先使用类型自带的运算符重载，而非 SIMD 专有方法
