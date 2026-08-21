---
name: tunit-testing
description: Use when working with TUnit tests in .NET projects.
---

# TUnit 测试

TUnit 使用 Microsoft.Testing.Platform (MTP)，不是 VSTest。

## 运行

从仓库根目录检查配置，并优先沿用仓库已有的测试命令：

```
dotnet --version
rg -n -e 'Microsoft.Testing.Platform' -e 'TUnit' -e 'Microsoft.NET.Test.Sdk' -g 'global.json' -g '*.csproj' -g '*.props' -g '*.targets' .
```

- `global.json` 的 `test.runner` 应为 `Microsoft.Testing.Platform`。
- 测试项目不应引用 `Microsoft.NET.Test.Sdk`。
- 遇到与当前改动无关的编译、配置、文件锁或超时问题时，报告后停止，不要反复更换 runner 或参数。

保留完整输出、退出码和测试摘要：

```
dotnet test --project path/to/TestProject.csproj --disable-logo --minimum-expected-tests 1
dotnet test --solution path/to/Solution.slnx --disable-logo --minimum-expected-tests 1
```

- 在当前工作树和配置尚未成功构建前，不要加 `--no-build` 或 `--no-restore`；否则可能验证陈旧二进制。
- 同一工作树一次只运行一个测试或基准进程；命令未结束时等待原进程，不要重复启动。
- 先运行最小相关测试；仅在验收需要时运行一次完整测试集。
- 使用 `--disable-logo`，不要使用 VSTest 的 `--nologo`、`--filter` 或额外的 `--`。

## 定向测试

使用 `--treenode-filter`，并以 `--minimum-expected-tests 1` 防止零测试被误判为通过：

```
dotnet test --project path/to/TestProject.csproj --disable-logo --minimum-expected-tests 1 --treenode-filter "/*/*/MyTestClass/*"
dotnet test --project path/to/TestProject.csproj --disable-logo --minimum-expected-tests 1 --treenode-filter "/*/*/MyTestClass/MyTestMethod"
```

不知道测试层级时先列举：

```
dotnet test --project path/to/TestProject.csproj --list-tests --disable-logo
```

需要 runner 日志时使用：

```
dotnet test --project path/to/TestProject.csproj --diagnostic --minimum-expected-tests 1
```

## 编写测试

- `await` 每个 TUnit 断言；未等待的断言不会执行。
- 保持测试独立；TUnit 为每个测试创建新的类实例，实例字段不会跨测试共享。
- 仅在必须排序时使用 `[DependsOn]`；依赖过多时合并测试或改用 setup/teardown。
- 使用 `[ClassDataSource<>]` 的 `Shared` 选项共享昂贵资源，并用 `IAsyncInitializer` 和 `IAsyncDisposable` 管理生命周期。
- 根据初始化和清理的频率选择 hook：每个测试使用 `[Before(Test)]` / `[After(Test)]`（实例方法），每个测试类使用 `[Before(Class)]` / `[After(Class)]`（静态方法），每个程序集使用 `[Before(Assembly)]` / `[After(Assembly)]`（静态方法）。
