---
name: tunit-testing
description: Use when working with TUnit tests in .NET projects.
---

# TUnit 测试

当 .NET 仓库包含 TUnit 测试时使用本技能。先确认 TUnit、SDK 和潜在 VSTest 冲突：

```powershell
rg -n 'PackageReference Include="TUnit|PackageReference Include="TUnit.Engine|PackageReference Include="Microsoft.NET.Test.Sdk|\[Test\]' -g '*.csproj' -g '*.cs'
dotnet --version
dotnet list <test.csproj> package
```

项目配置：

- 优先使用 `TUnit` 元包；它包含常用的断言、引擎、覆盖率和 TRX 报告扩展。
- TUnit 测试项目应是可执行项目；手动从 console 项目配置时删除 `Program.cs` 或 main 方法，并检查 `<OutputType>Exe</OutputType>`。
- 不要引用 `Microsoft.NET.Test.Sdk`、`coverlet.collector` 或 `coverlet.msbuild`；它们属于 VSTest/Coverlet 路线，容易破坏 TUnit 发现或覆盖率。

运行测试。多目标框架优先用 `dotnet test`；需要方便传 runner 参数或只跑单个 TFM 时用 `dotnet run`：

```powershell
dotnet test <test.csproj>
dotnet test <test.csproj> -c Release
dotnet test <test.csproj> -c Release --no-build
dotnet run --project <test.csproj> -c Release
dotnet exec path/to/TestProject.dll
dotnet path/to/TestProject.dll
```

传递 TUnit/Microsoft.Testing.Platform 参数：

```powershell
dotnet test <test.csproj> -- --report-trx --coverage --diagnostic
dotnet run --project <test.csproj> -c Release --report-trx --coverage
dotnet exec path/to/TestProject.dll --report-trx --coverage
dotnet run --project <test.csproj> -c Release --coverage --coverage-output-format cobertura
```

在 .NET 10+ SDK 中，`dotnet test` 通常可以直接传递平台参数；如果失败，把参数放到 `--` 后面：

```powershell
dotnet test <test.csproj> --report-trx --coverage
```

使用 tree-node 语法过滤测试，不要使用 VSTest 的 `--filter` 语法；用错时可能打印 MTP help 或显示 0 个测试：

```powershell
dotnet test <test.csproj> --treenode-filter "/*/*/MyTestClass/*"
dotnet test <test.csproj> --treenode-filter "/*/*/MyTestClass/MyTestMethod"
dotnet test <test.csproj> --treenode-filter "/*/MyProject.Tests.Integration/*/*"
dotnet test <test.csproj> --treenode-filter "/*/*/*/*[Category=Integration]"
dotnet test <test.csproj> --treenode-filter "/*/*/*/*[Category!=Performance]"
dotnet test <test.csproj> --treenode-filter "/*/*/ClassA/*|/*/*/ClassB/*"
dotnet test <test.csproj> --treenode-filter "/*/*/*/*[(Category=Integration)&(Priority=High)]"
```

如果 `dotnet test --treenode-filter ...` 在旧 SDK 或项目配置下失败，改用 `dotnet test <test.csproj> -- --treenode-filter "..."`。

覆盖率使用 `Microsoft.Testing.Extensions.CodeCoverage`，TRX 使用 `Microsoft.Testing.Extensions.TrxReport`；`TUnit` 元包已经包含它们。如果直接使用 `TUnit.Engine`，按需手动添加这些扩展。

如果没有发现测试，检查：是否存在 `TUnit` 包、是否已移除 `Microsoft.NET.Test.Sdk`、方法是否带有 `[Test]`、测试方法是否为 public 实例方法且不是 static，以及宿主错误是否带有 `<OutputType>Exe</OutputType>`。IDE 不发现测试时，先 clean rebuild；然后启用 Microsoft.Testing.Platform 支持：Visual Studio 的 testing platform server mode、Rider 的 Testing Platform support、VS Code 的 C# Dev Kit testing platform protocol。需要诊断时加 `--diagnostic`。

写或迁移测试时注意：TUnit 断言必须 `await`；每个测试方法会创建新的测试类实例，不要依赖实例字段共享状态；必须排序时优先用 `[DependsOn]`；类级和程序集级 hook 必须是 static，测试级 hook 可以是实例方法。
