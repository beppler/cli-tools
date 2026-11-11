# Runs opencode using WSL Containers (wslc.exe) — no Docker Desktop, no Podman.
$ErrorActionPreference = "Stop"

$HomeDirWin = "$env:USERPROFILE\.cli-tools\opencode-home"
New-Item -ItemType Directory -Force -Path $HomeDirWin | Out-Null
$HomeDir = $HomeDirWin -replace '\\','/'

# opencode keeps a single service registration (service.json) in its state dir.
# Sharing it between containers makes each instance kill the other's server, so
# every run gets its own temporary state dir, removed on exit.
# Per-user state (model selection, prompt history, the release-highlights
# "seen" marker) must survive runs, so it is seeded from the shared state dir
# below and saved back at the end. The prompt history is a JSONL log, so it is
# saved back by appending only its new entries — concurrent instances merge
# instead of the last one wiping the others. service.json and the rest of
# latest/ and locks/ stay per-run: they can't be shared between instances.
$StateParent = "$HomeDirWin\.local\state"
$SharedDirWin = Join-Path $StateParent "opencode"
New-Item -ItemType Directory -Force -Path $SharedDirWin | Out-Null
$SharedFiles = @("model.json", "prompt-history.jsonl", "latest/tui/highlights.json")
# Named after this script's PID so orphaned dirs are easy to spot (PID not running).
$StateDirWin = Join-Path $StateParent "opencode-$PID"
Remove-Item -Recurse -Force -Path $StateDirWin -ErrorAction SilentlyContinue  # stale leftover with the same PID
New-Item -ItemType Directory -Force -Path $StateDirWin | Out-Null
foreach ($File in $SharedFiles) {
  $SharedFile = Join-Path $SharedDirWin $File
  if (Test-Path -PathType Leaf $SharedFile) {
    $RunFile = Join-Path $StateDirWin $File
    New-Item -ItemType Directory -Force -Path (Split-Path $RunFile) | Out-Null
    Copy-Item $SharedFile $RunFile
  }
}
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
  # Prompt history is appended (see save logic below), not overwritten.
  foreach ($File in ($SharedFiles | Where-Object { $_ -ne "prompt-history.jsonl" })) {
    $RunFile = Join-Path $StateDirWin $File
    $SharedFile = Join-Path $SharedDirWin $File
    if (Test-Path -PathType Leaf $RunFile) {
      $RunHash = (Get-FileHash $RunFile).Hash
      $SharedHash = if (Test-Path -PathType Leaf $SharedFile) { (Get-FileHash $SharedFile).Hash } else { "" }
      if ($RunHash -ne $SharedHash) {
        New-Item -ItemType Directory -Force -Path (Split-Path $SharedFile) | Out-Null
        Copy-Item $RunFile $SharedFile -Force
      }
    }
  }
  # Prompt history: append instead of overwrite so entries saved by instances
  # that exited in the meantime are not lost. The run file starts as a copy of
  # the shared one and opencode later rewrites it whole when trimming (it
  # keeps at most 50 entries), so "new" is judged per line: entries already
  # present in the shared copy are skipped. .NET file APIs with an explicit
  # UTF-8 (no BOM) encoding are used because prompts may contain non-ASCII
  # text and Add-Content's default encoding differs between PowerShell versions.
  $Utf8NoBom = [System.Text.UTF8Encoding]::new($false)
  $RunHistory = Join-Path $StateDirWin "prompt-history.jsonl"
  $SharedHistory = Join-Path $SharedDirWin "prompt-history.jsonl"
  if ((Test-Path -PathType Leaf $RunHistory) -and (Get-Item $RunHistory).Length -gt 0) {
    New-Item -ItemType Directory -Force -Path (Split-Path $SharedHistory) | Out-Null
    if (Test-Path -PathType Leaf $SharedHistory) {
      # Two JSON objects must never end up on the same line.
      $Raw = Get-Content $SharedHistory -Raw
      if ($Raw -and -not $Raw.EndsWith("`n")) {
        [System.IO.File]::AppendAllText($SharedHistory, "`n", $Utf8NoBom)
      }
    }
    $Known = [System.Collections.Generic.HashSet[string]]::new()
    if (Test-Path -PathType Leaf $SharedHistory) {
      foreach ($KnownLine in [System.IO.File]::ReadAllLines($SharedHistory)) { [void]$Known.Add($KnownLine) }
    }
    $New = [System.Collections.Generic.List[string]]::new()
    foreach ($Line in [System.IO.File]::ReadAllLines($RunHistory)) {
      if ($Line -and $Known.Add($Line)) { $New.Add($Line) }
    }
    if ($New.Count -gt 0) {
      [System.IO.File]::AppendAllText($SharedHistory, ($New -join "`n") + "`n", $Utf8NoBom)
    }
  }
  Remove-Item -Recurse -Force -Path $StateDirWin -ErrorAction SilentlyContinue
}
