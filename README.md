# Containerized AI CLIs (Claude Code, Codex, Gemini CLI)

Each tool runs in its own container image with its own Node.js runtime.
The engine is auto-detected/chosen per OS:

| OS      | Engine                                         |
| ------- | ---------------------------------------------- |
| macOS   | Apple `container` (native, Apple Silicon only) |
| Linux   | Podman                                         |
| Windows | WSL Containers (`wslc.exe`) — native.          |

Image stores are per-engine and per-machine — build once on each machine you use (there's no shared cache between Apple `container`, Podman, and `wslc` on another box).

## Setup

**macOS / Linux:**

    ./build

Installs wrapper scripts to `~/.local/bin/claude`, `~/.local/bin/codex`,
`~/.local/bin/gemini`. Make sure `~/.local/bin` is on your `PATH`.

On macOS, `container` requires Apple Silicon and macOS 15+ (full support on macOS 26). If the daemon isn't running yet, `build` starts it for you; on some setups you may need to run `container system start` again after a reboot.

**Windows:**

WSL Containers is currently a preview feature. One-time setup, in an elevated PowerShell:

    wsl --update --pre-release
    wsl --shutdown

Reopen your terminal, then confirm it's there:

    wslc --version   # expect 2.9.3 or higher

Then build and install:

    ./build.ps1

Installs wrapper scripts to `%LOCALAPPDATA%\Programs\Bin`. Add that to your PATH and `claude`, `codex`, `gemini` work from PowerShell or cmd.exe.

On Windows it uses `wslc.exe` that ships as part of WSL itself and runs each container in its own lightweight Hyper-V VM.

## Usage

Same on every OS — from any project directory:

    cd ~/my-project
    claude
    codex
    gemini

The current directory is mounted into the container at `/workspace`, so each tool only sees the project you're in.

## Auth

Each tool's config/credentials persist in its own home directory, so you only log in once per tool:

    ~/.cli-tools/claude-home              (macOS/Linux)
    ~/.cli-tools/codex-home
    ~/.cli-tools/gemini-home
    %USERPROFILE%\.cli-tools\claude-home  (Windows, same idea)
    %USERPROFILE%\.cli-tools\codex-home
    %USERPROFILE%\.cli-tools\gemini-home

Browser-based OAuth login (Claude Code, Gemini CLI) prints a URL/code to paste into your host browser — same experience as logging in over SSH.

**Codex is the exception:** its "Sign in with ChatGPT" browser flow won't work in this containerized setup. Codex's OAuth callback server is hardcoded to bind `127.0.0.1:1455` inside its own process, so the redirect from your host browser can never reach it — no port-forwarding fix is possible. Use device-code login instead:

    codex login --device-auth

Device-code login is **disabled by default** on OpenAI accounts and must be turned on before it will work:

- Personal account: ChatGPT → Settings → Security → enable device code login.
- Team/Enterprise/Edu workspace: a workspace admin must enable it under Workspace Settings → Permissions → "Allow device code login" — it's greyed out for regular members otherwise.

Alternatively, set an API key before running:

    export ANTHROPIC_API_KEY=...    # macOS/Linux
    export OPENAI_API_KEY=...
    export GEMINI_API_KEY=...

    $env:ANTHROPIC_API_KEY = "..."  # Windows PowerShell

On Windows this just works — `wslc.exe` is a native Windows process, so the scripts read `$env:...` directly and pass it into the container.

No WSL-side environment configuration needed.

## Updating

All three engines cache the `npm install` layer, so a plain rebuild won't pull newer versions. Use the update script instead:

    ./update     # macOS/Linux
    ./update.ps1    # Windows

Both force a `--no-cache` rebuild of all three images.
