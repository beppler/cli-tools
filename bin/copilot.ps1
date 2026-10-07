# Runs GitHub Copilot CLI using WSL Containers (wslc.exe) — no Docker Desktop, no Podman.
$ErrorActionPreference = "Stop"

$HomeDirWin = "$env:USERPROFILE\.cli-tools\copilot-home"
New-Item -ItemType Directory -Force -Path $HomeDirWin | Out-Null
$HomeDir = $HomeDirWin -replace '\\','/'
$Workspace = $PWD.Path -replace '\\','/'

container run --rm -it `
  --name "copilot_cli_$(Get-Random)" `
  -v "${Workspace}:/workspace" -w /workspace `
  -v "${HomeDir}:/root" `
  copilot-cli @args
