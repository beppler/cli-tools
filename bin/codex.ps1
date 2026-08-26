# Runs Codex CLI using WSL Containers (wslc.exe) — no Docker Desktop, no Podman.
$ErrorActionPreference = "Stop"

$HomeDirWin = "$env:USERPROFILE\.cli-tools\codex-home"
New-Item -ItemType Directory -Force -Path $HomeDirWin | Out-Null
$HomeDir = $HomeDirWin -replace '\\','/'
$Workspace = $PWD.Path -replace '\\','/'

$EnvArgs=@(
  "-e", "COLORTERM=truecolor",
  "-e", "TERM=xterm-256color"
)

if (-not [string]::IsNullOrEmpty($env:OPENAI_API_KEY)) {
  $envArgs += "-e", "OPENAI_API_KEY=$env:OPENAI_API_KEY"
}

wslc run --rm -it `
  -v "${Workspace}:/workspace" -w /workspace `
  -v "${HomeDir}:/root" `
  $EnvArgs `
  codex-cli @args
