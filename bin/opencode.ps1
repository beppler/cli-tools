# Runs opencode using WSL Containers (wslc.exe) — no Docker Desktop, no Podman.
$ErrorActionPreference = "Stop"

$HomeDirWin = "$env:USERPROFILE\.cli-tools\opencode-home"
New-Item -ItemType Directory -Force -Path $HomeDirWin | Out-Null
$HomeDir = $HomeDirWin -replace '\\','/'

# opencode keeps a single service registration (service.json) in its state dir.
# Sharing it between containers makes each instance kill the other's server, so
# every run gets its own temporary state dir, removed on exit.
# Named after this script's PID so orphaned dirs are easy to spot (PID not running).
$StateDirWin = Join-Path "$HomeDirWin\.local\state" "opencode-$PID"
Remove-Item -Recurse -Force -Path $StateDirWin -ErrorAction SilentlyContinue  # stale leftover with the same PID
New-Item -ItemType Directory -Force -Path $StateDirWin | Out-Null
$StateDir = $StateDirWin -replace '\\','/'
$Workspace = $PWD.Path -replace '\\','/'

# Mount the project at a path unique to this host folder, so tools that keep
# per-project state by path (sessions, trust, memory) don't mix projects.
$Sha = [System.Security.Cryptography.SHA256]::Create()
$Hash = -join ($Sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($PWD.Path.ToLowerInvariant())) | ForEach-Object { $_.ToString("x2") })
$Name = (Split-Path -Leaf $PWD.Path) -replace '[^A-Za-z0-9._-]','_'
$WorkDir = "/workspace/$($Hash.Substring(0, 12))/$Name"

$EnvArgs=@(
  "-e", "COLORTERM=truecolor",
  "-e", "TERM=xterm-256color",
  "-e", "GIT_CONFIG_COUNT=2",
  "-e", "GIT_CONFIG_KEY_0=core.autocrlf", "-e", "GIT_CONFIG_VALUE_0=true",
  "-e", "GIT_CONFIG_KEY_1=core.filemode",  "-e", "GIT_CONFIG_VALUE_1=false"
)

if (-not [string]::IsNullOrEmpty($env:ANTHROPIC_API_KEY)) {
  $envArgs += "-e", "ANTHROPIC_API_KEY=$env:ANTHROPIC_API_KEY"
}

if (-not [string]::IsNullOrEmpty($env:GEMINI_API_KEY)) {
  $EnvArgs += "-e", "GEMINI_API_KEY=$env:GEMINI_API_KEY"
}

if (-not [string]::IsNullOrEmpty($env:GOOGLE_API_KEY)) {
  $EnvArgs += "-e", "GOOGLE_API_KEY=$env:GOOGLE_API_KEY"
}

if (-not [string]::IsNullOrEmpty($env:GOOGLE_GENAI_USE_VERTEXAI)) {
  $EnvArgs += "-e", "GOOGLE_GENAI_USE_VERTEXAI=$env:GOOGLE_GENAI_USE_VERTEXAI"
}

try {
  container run --rm -it `
    --name "opencode_cli_$(Get-Random)" `
    -v "${Workspace}:${WorkDir}" -w $WorkDir `
    -v "${HomeDir}:/root" `
    -v "${StateDir}:/root/.local/state/opencode" `
    $EnvArgs `
    opencode-cli @args
}
finally {
  Remove-Item -Recurse -Force -Path $StateDirWin -ErrorAction SilentlyContinue
}
