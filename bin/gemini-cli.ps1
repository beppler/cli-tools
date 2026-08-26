# Runs Gemini CLI using WSL Containers (wslc.exe) — no Docker Desktop, no Podman.
$ErrorActionPreference = "Stop"

$HomeDirWin = "$env:USERPROFILE\.cli-tools\gemini-home"
New-Item -ItemType Directory -Force -Path $HomeDirWin | Out-Null
$HomeDir = $HomeDirWin -replace '\\','/'
$Workspace = $PWD.Path -replace '\\','/'

$EnvArgs=@()

if (-not [string]::IsNullOrEmpty($env:GEMINI_API_KEY)) {
  $envArgs += "-e", "GEMINI_API_KEY=$env:GEMINI_API_KEY"
}

if (-not [string]::IsNullOrEmpty($env:GOOGLE_API_KEY)) {
  $envArgs += "-e", "GOOGLE_API_KEY=$env:GOOGLE_API_KEY"
}

if (-not [string]::IsNullOrEmpty($env:GOOGLE_GENAI_USE_VERTEXAI)) {
  $envArgs += "-e", "GOOGLE_GENAI_USE_VERTEXAI=$env:GOOGLE_GENAI_USE_VERTEXAI"
}

wslc run --rm -it `
  -v "${Workspace}:/workspace" -w /workspace `
  -v "${HomeDir}:/root" `
  $EnvArgs `
  gemini-cli @args
