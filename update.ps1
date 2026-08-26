# Rebuilds all images with the latest npm package versions.
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

foreach ($tool in @("claude", "codex", "copilot", "gemini", "opencode")) {
    Push-Location (Join-Path $ScriptDir $tool)
    wslc build --no-cache -t "$tool-cli" .
    Pop-Location
}

Write-Host "Updated. Wrapper scripts need no changes."
