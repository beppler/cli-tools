# Builds the isolated CLI images using WSL Containers (wslc.exe),
# and installs the wrapper scripts to %USERPROFILE%\.local\bin.
# Builds every tool by default, or only the ones named as arguments:
#   .\build.ps1             # all tools
#   .\build.ps1 claude agy  # just these
param([Parameter(ValueFromRemainingArguments = $true)][string[]]$Tools)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$AllTools = @("agy", "claude", "codex", "copilot", "opencode")

if ($Tools) {
    foreach ($tool in $Tools) {
        if ($AllTools -notcontains $tool) {
            throw "Unknown tool: $tool (available: $($AllTools -join ' '))"
        }
    }
}
else {
    $Tools = $AllTools
}

foreach ($tool in $Tools) {
    wslc build --no-cache -t "$tool-cli" (Join-Path $ScriptDir "containers" $tool)
}

$Dest = "$env:LOCALAPPDATA\Programs\bin"
New-Item -ItemType Directory -Force -Path $Dest | Out-Null

foreach ($tool in $Tools) {
    Copy-Item (Join-Path $ScriptDir "bin" "$tool.cmd") $Dest -Force
    Copy-Item (Join-Path $ScriptDir "bin" "$tool.ps1") $Dest -Force
}

Write-Host "Done. Add $Dest to your PATH (if not already), then just run: $($Tools -join ' ')"
