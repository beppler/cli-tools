# Builds all isolated CLI images using WSL Containers (wslc.exe),
# and installs the wrapper scripts to %USERPROFILE%\.local\bin.
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

foreach ($tool in @("claude", "codex", "copilot", "gemini", "opencode")) {
    Push-Location (Join-Path $ScriptDir $tool)
    wslc build -t "$tool-cli" .
    Pop-Location
}

$Dest = "$env:LOCALAPPDATA\Programs\bin"
New-Item -ItemType Directory -Force -Path $Dest | Out-Null
Copy-Item (Join-Path $ScriptDir "bin\*.cmd") $Dest -Force
Copy-Item (Join-Path $ScriptDir "bin\*.ps1") $Dest -Force

Write-Host "Done. Add $Dest to your PATH (if not already), then just run: claude / codex / gemini"
