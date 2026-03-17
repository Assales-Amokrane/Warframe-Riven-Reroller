param(
    [string]$CompilerPath = "C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe",
    [string]$BasePath = "C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe",
    [string]$SourcePath = ".\Riven Reroller Release.ahk",
    [string]$OutputPath = ".\dist\Riven Reroller.exe"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$source = Join-Path $repoRoot $SourcePath
$output = Join-Path $repoRoot $OutputPath
$outputDir = Split-Path -Parent $output

if (-not (Test-Path $CompilerPath)) {
    throw "Ahk2Exe not found at '$CompilerPath'."
}

if (-not (Test-Path $BasePath)) {
    throw "AutoHotkey v2 base executable not found at '$BasePath'."
}

if (-not (Test-Path $source)) {
    throw "Release entry script not found at '$source'."
}

New-Item -ItemType Directory -Force -Path $outputDir | Out-Null

& $CompilerPath /in $source /out $output /base $BasePath

if (-not (Test-Path $output)) {
    throw "Ahk2Exe did not produce '$output'."
}

Write-Host "Built release executable: $output"
