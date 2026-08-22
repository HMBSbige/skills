---
name: wsl-pwsh
description: 在 Windows 的 pwsh 中调用 WSL 程序，或执行需要 Bash 管道、变量、重定向或多行脚本的 WSL 命令时
---

# 从 pwsh 调用 WSL

调用单个 Linux 程序时，用 PowerShell 参数数组逐项传参，并检查退出码：

```powershell
$wslArguments = @('--exec', $program) + @($programArguments)
& wsl.exe @wslArguments
if ($LASTEXITCODE -ne 0) { throw "$program failed with exit code $LASTEXITCODE" }
```

每个动态值必须各占一个数组元素；不要拼接命令字符串，也不要套 `bash`/`sh -c`。

需要 Bash 语法时，调用本 skill 的 `scripts/invoke-wsl-bash.ps1`。Bash 源码放在单引号 here-string 中，PowerShell 动态值通过 `-BashArguments` 逐项传入，并在 Bash 中从 `$1` 开始读取：

```powershell
$bashScript = @'
# Bash 源码
'@
& '<本 skill 目录>\scripts\invoke-wsl-bash.ps1' `
    -Script $bashScript `
    -BashArguments @($value1, $value2)
```

不要用 PowerShell 管道直接向 `wsl.exe` 传脚本，也不要使用 `bash`/`sh -c` 或 `-lc`。
