# Runs Codex CLI using WSL Containers (wslc.exe) — no Docker Desktop, no Podman.
$ErrorActionPreference = "Stop"

$HomeDirWin = "$env:USERPROFILE\.cli-tools\codex-home"
New-Item -ItemType Directory -Force -Path $HomeDirWin | Out-Null
$HomeDir = $HomeDirWin -replace '\\','/'
$Workspace = $PWD.Path -replace '\\','/'

wslc run --rm -it `
  -v "${Workspace}:/workspace" -w /workspace `
  -v "${HomeDir}:/root" `
  copilot-cli @args
