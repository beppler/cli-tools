# Builds all isolated CLI images using WSL Containers (wslc.exe),
# and installs the wrapper scripts to %USERPROFILE%\.local\bin.
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$tools = @("agy", "claude", "codex", "copilot", "opencode")

foreach ($tool in $tools) {
    wslc build --no-cache -t "$tool-cli" (Join-Path $ScriptDir "containers" $tool)
}

$Dest = "$env:LOCALAPPDATA\Programs\bin"
New-Item -ItemType Directory -Force -Path $Dest | Out-Null

foreach ($tool in $tools) {
    Copy-Item (Join-Path $ScriptDir "bin" "$tool.cmd") $Dest -Force
    Copy-Item (Join-Path $ScriptDir "bin" "$tool.ps1") $Dest -Force
}

Write-Host "Done. Add $Dest to your PATH (if not already), then just run: $($tools -join ' ')"
