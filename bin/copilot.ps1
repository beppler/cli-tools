# Runs GitHub Copilot CLI using WSL Containers (wslc.exe) — no Docker Desktop, no Podman.
$ErrorActionPreference = "Stop"

$HomeDirWin = "$env:USERPROFILE\.cli-tools\copilot-home"
New-Item -ItemType Directory -Force -Path $HomeDirWin | Out-Null
$HomeDir = $HomeDirWin -replace '\\','/'
$Workspace = $PWD.Path -replace '\\','/'

# Mount the project at a path unique to this host folder, so tools that keep
# per-project state by path (sessions, trust, memory) don't mix projects.
$Sha = [System.Security.Cryptography.SHA256]::Create()
$Hash = -join ($Sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($PWD.Path.ToLowerInvariant())) | ForEach-Object { $_.ToString("x2") })
$Name = (Split-Path -Leaf $PWD.Path) -replace '[^A-Za-z0-9._-]','_'
$WorkDir = "/workspace/$($Hash.Substring(0, 12))/$Name"

$EnvArgs=@(
  "-e", "GIT_CONFIG_COUNT=2",
  "-e", "GIT_CONFIG_KEY_0=core.autocrlf", "-e", "GIT_CONFIG_VALUE_0=true",
  "-e", "GIT_CONFIG_KEY_1=core.filemode",  "-e", "GIT_CONFIG_VALUE_1=false"
)

container run --rm -it `
  --name "copilot_cli_$(Get-Random)" `
  -v "${Workspace}:${WorkDir}" -w $WorkDir `
  -v "${HomeDir}:/root" `
  $EnvArgs `
  copilot-cli @args
