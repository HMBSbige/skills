[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [AllowEmptyString()]
    [string]$Script,

    [string[]]$BashArguments = @()
)

$startInfo = [System.Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = 'wsl.exe'
$startInfo.UseShellExecute = $false
$startInfo.RedirectStandardInput = $true
$startInfo.StandardInputEncoding = [System.Text.UTF8Encoding]::new($false)

$wslArguments = @('--exec', 'bash', '-l', '-s', '--') + @($BashArguments)
foreach ($argument in $wslArguments) {
    [void]$startInfo.ArgumentList.Add([string]$argument)
}

$process = [System.Diagnostics.Process]::new()
$process.StartInfo = $startInfo
try {
    if (-not $process.Start()) {
        throw 'Failed to start wsl.exe'
    }

    $writeError = $null
    try {
        $normalizedScript = $Script.Replace("`r`n", "`n").Replace("`r", "`n")
        $process.StandardInput.Write($normalizedScript)
    }
    catch {
        $writeError = $_
    }
    finally {
        $process.StandardInput.Close()
    }

    $process.WaitForExit()
    if ($null -ne $writeError) {
        throw $writeError
    }
    if ($process.ExitCode -ne 0) {
        throw "WSL Bash failed with exit code $($process.ExitCode)"
    }
}
finally {
    $process.Dispose()
}
