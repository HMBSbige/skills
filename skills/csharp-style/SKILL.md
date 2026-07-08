---
name: csharp-style
description: Use when writing, editing, reviewing, or refactoring C#/.NET code
---

# C# Style

- Span/Memory 代码中使用 `.Slice()` 而非 range 表达式
- 语法尽量使用模式匹配和递归模式
- 尽量不使用 nullable 抑制
- 简单 null/空值校验优先使用直接 guard clause，避免为了模式匹配而让判断复杂化
