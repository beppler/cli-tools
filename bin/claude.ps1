# Runs Claude Code using WSL Containers (wslc.exe) — no Docker Desktop, no Podman.
$ErrorActionPreference = "Stop"

$HomeDirWin = "$env:USERPROFILE\.cli-tools\claude-home"
New-Item -ItemType Directory -Force -Path $HomeDirWin | Out-Null
$HomeDir = $HomeDirWin -replace '\\','/'
$Workspace = $PWD.Path -replace '\\','/'

# Mount the project at a path unique to this host folder, so tools that keep
# per-project state by path (sessions, trust, memory) don't mix projects.
$Sha = [System.Security.Cryptography.SHA256]::Create()
$Hash = -join ($Sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($PWD.Path.ToLowerInvariant())) | ForEach-Object { $_.ToString("x2") })
$Name = (Split-Path -Leaf $PWD.Path) -replace '[^A-Za-z0-9._-]','_'
$WorkDir = "/workspace/$Name-$($Hash.Substring(0, 12))"

$EnvArgs=@(
  "-e", "COLORTERM=truecolor",
  "-e", "TERM=xterm-256color"
)

if (-not [string]::IsNullOrEmpty($env:ANTHROPIC_API_KEY)) {
  $envArgs += "-e", "ANTHROPIC_API_KEY=$env:ANTHROPIC_API_KEY"
}

container run --rm -it  `
  --name "claude_cli_$(Get-Random)" `
  -v "${Workspace}:${WorkDir}" -w $WorkDir `
  -v "${HomeDir}:/root" `
  $EnvArgs `
  claude-cli @args
