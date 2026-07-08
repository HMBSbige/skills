---
name: git-conventions
description: Use when creating, editing, reviewing, or suggesting Git commit messages
---

# Git 提交规范

- 基于实际 diff 生成提交信息
- 提交标题使用 Conventional Commits，`!` 仅用于标记破坏性变更：
  - 无 scope：`<type>: <description>` 或 `<type>!: <description>`
  - 有 scope：`<type>(<scope>): <description>` 或 `<type>(<scope>)!: <description>`
- type 可使用：`feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `style`, `perf`, `ci`, `build`
- description 紧跟 type/scope 前缀后的冒号和空格，是代码变更的简短摘要
- 提交正文可选；仅当标题无法说明原因、影响范围、迁移注意事项，或多个相关变更之间的关系时添加；若存在，必须从 description 后的一个空行开始，并可用空行分隔段落
- 使用 footer 记录 issue 链接等元数据，footer 必须和正文或 description 之间空一行。footer 使用 `Token: value` 或 `Token #value` 形式；token 内部空白使用 `-` 替代
- 破坏性变更必须用标题中的 `!` 或 footer 中的 `BREAKING CHANGE:` 标记。使用 `!` 时可以省略 `BREAKING CHANGE:` footer，但 description 应说明破坏性影响
