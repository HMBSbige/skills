---
name: tunit-testing
description: Use when working with TUnit tests in .NET projects.
---

# TUnit 测试

## 编写

- `await` 每个 TUnit 断言；未等待的断言不会执行。
- 保持测试独立；TUnit 为每个测试创建新的类实例，实例字段不会跨测试共享。
- 仅在必须排序时使用 `[DependsOn]`；依赖过多时合并测试或改用 setup/teardown。
- 使用 `[ClassDataSource<>]` 的 `Shared` 选项共享昂贵资源，并用 `IAsyncInitializer` 和 `IAsyncDisposable` 管理生命周期。
- 根据初始化和清理的频率选择 hook：每个测试使用 `[Before(Test)]` / `[After(Test)]`（实例方法），每个测试类使用 `[Before(Class)]` / `[After(Class)]`（静态方法），每个程序集使用 `[Before(Assembly)]` / `[After(Assembly)]`（静态方法）。

## 运行

```sh
dotnet test
dotnet test --project <test.csproj>
dotnet test --solution <solution.slnx>
dotnet test --test-modules path/to/TestProject.dll
dotnet run --project <test.csproj>
dotnet exec path/to/TestProject.dll
```

按需生成报告、覆盖率或诊断日志：

```sh
dotnet test --project <test.csproj> --report-trx --coverage
dotnet test --project <test.csproj> --diagnostic
```

使用 `--disable-logo` 隐藏 TUnit 标志，不要使用 `--nologo`。

## 过滤

使用 `--treenode-filter`，不要使用 VSTest 的 `--filter`：

```sh
dotnet test --project <test.csproj> --treenode-filter "/*/*/MyTestClass/*"
dotnet test --project <test.csproj> --treenode-filter "/*/*/MyTestClass/MyTestMethod"
dotnet test --project <test.csproj> --treenode-filter "/*/MyProject.Tests.Integration/*/*"
dotnet test --project <test.csproj> --treenode-filter "/*/*/*/*[Category=Integration]"
dotnet test --project <test.csproj> --treenode-filter "/**[(Category=Integration)&(Priority=High)]"
```
