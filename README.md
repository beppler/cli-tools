# Containerized AI Coding CLIs

Run **Claude Code**, **Codex**, **GitHub Copilot**, **Antigravity**, and **OpenCode** in isolated containers — same commands, every OS, no Node.js or Python sprawl on your host. Each tool ships as its own image with its own runtime and its own persistent home directory, and it only ever sees the project directory you launch it from.

| Tool | Command | Entrypoint notes |
| ---- | ------- | --------------- |
| Claude Code | `claude` | `IS_SANDBOX=1` so `--dangerously-skip-permissions` works as root |
| Codex | `codex` | full-access sandbox mode inside the container |
| GitHub Copilot | `copilot` | |
| Antigravity | `agy` | |
| OpenCode | `opencode` | provider-agnostic: ANTHROPIC / OPENAI / GEMINI keys all supported |

## Container engines

Auto-detected per OS, no configuration needed:

| OS | Engine |
| -- | ------ |
| macOS | Apple `container` (Apple Silicon only, macOS 15+) |
| Linux | Podman (rootless), or rootless Docker |
| Windows | WSL Containers (`wslc.exe`) — native, ships with WSL |

Images are stored **per engine and per machine** — you must build on each machine you use; there's no shared cache between `container`, Podman, and `wslc`.

## Setup

### macOS / Linux

```bash
./build              # build and install all five tools
./build claude agy   # only some
./build --scripts-only       # re-install wrappers without rebuilding images
./build --prune-images       # also prune dangling build images
```

Wrappers install to `~/.local/bin/` — make sure it's on your `PATH`.

On macOS, `container` requires Apple Silicon and macOS 15+ (full support on macOS 26). If the daemon isn't running yet, `build` starts it for you; on some setups you may need to run `container system start` again after a reboot.

### Windows (WSL Containers preview)

One-time setup in an elevated PowerShell:

```powershell
wsl --update --pre-release
wsl --shutdown
```

Reopen your terminal, then confirm it's there:

```powershell
wslc --version   # expect 2.9.3+
```

Then:

```powershell
./build.ps1                # all tools
./build.ps1 claude agy     # only some
./build.ps1 -ScriptsOnly   # wrappers only
./build.ps1 -PruneImages   # also prune dangling images
```

Wrappers install to `%LOCALAPPDATA%\Programs\bin`. Add that to your PATH and `claude`, `codex`, `copilot`, `agy`, `opencode` work from PowerShell or cmd.exe.

`wslc.exe` ships as part of WSL itself and runs each container in its own lightweight Hyper-V VM.

### WSL (Podman networking)

To make Podman network work on WSL, install the `slirp4netns` package:

```bash
sudo apt update && sudo apt install -y slirp4netns
```

And add the following lines to `/etc/containers/containers.conf`:

```toml
[network]
default_rootless_network_cmd = "slirp4netns"
```

## Usage

Same on every OS — from any project directory:

```bash
cd ~/my-project
claude    # or codex / copilot / agy / opencode
```

**How mounting works:** the current directory is bind-mounted at `/workspace/<hash-of-host-path>/<folder-name>`. The folder keeps its own name inside the container. The hash is deliberate — these tools keep per-project state (sessions, memory, folder trust) keyed by path, so every project must map to a unique in-container path. Side effect: renaming or moving a project on the host gives it a fresh hash and a fresh session history.

**Auth persistence:** each tool keeps its credentials in a dedicated host directory, bind-mounted as `/root` in the container — log in once, stay logged in:

```text
~/.cli-tools/claude-home          (macOS/Linux)
~/.cli-tools/codex-home
~/.cli-tools/copilot-home
~/.cli-tools/antigravity-home
~/.cli-tools/opencode-home
```

On Windows the same layout lives under `%USERPROFILE%\.cli-tools\`.

## Logging in

| Tool | Method | Notes |
| ---- | ------ | ----- |
| Claude, Antigravity | Browser OAuth | prints a URL/code to paste into your host browser — like SSH login |
| Codex, Copilot | Device code | browser OAuth can't work: the callback server binds `127.0.0.1` inside the container, reachable from nowhere — no port-forwarding fix is possible |
| Antigravity (personal accounts) | API key | OAuth unavailable; set `GEMINI_API_KEY` in a `.env` in `antigravity-home` — get one at [Google AI Studio](https://aistudio.google.com/app/apikey) |
| OpenCode | Any | reads whichever of `ANTHROPIC_API_KEY` / `OPENAI_API_KEY` / `GEMINI_API_KEY` (or `GOOGLE_API_KEY`) is set, or `opencode auth login` in-container |

API keys from your shell are passed through automatically (including PowerShell on Windows — `wslc.exe` is a native Windows process, so the scripts read `$env:...` directly and pass them into the container; no WSL-side configuration needed).

Note that OpenAI device-code login is **disabled by default** and must be turned on before it will work:

- Personal account: ChatGPT → Settings → Security → enable device code login
- Team/Enterprise/Edu: a workspace admin must allow it under Workspace Settings → Permissions → "Allow device code login" — it's greyed out for regular members otherwise

Or skip login entirely:

```bash
export ANTHROPIC_API_KEY=...   # or OPENAI_API_KEY / GEMINI_API_KEY
# PowerShell: $env:ANTHROPIC_API_KEY = "..."
```

## Sandboxing

Tools run as root **inside** their containers — that root is not your host root:

- rootless Podman / rootless Docker map container root to your own user
- Apple `container` and `wslc` run each container in a lightweight per-container VM

On Linux the wrappers **refuse to run against a system (rootful) Docker daemon**, where container root would be host root. Fix with:

```bash
dockerd-rootless-setuptool.sh install
```

Verify what you're on:

```bash
podman info --format '{{.Host.Security.Rootless}}'    # expect true
docker info --format '{{.SecurityOptions}}' | grep rootless
```

**Linux hardening** (applied automatically by the wrappers on Podman/Docker):

```text
--security-opt no-new-privileges
--cap-drop=ALL --cap-add=CHOWN,DAC_OVERRIDE,FOWNER,FSETID,SETUID,SETGID
```

No privilege escalation via setuid; the dropped capabilities include network admin, raw sockets, kill, chroot, and capability editing. The retained ones are what file handling and `apt-get install` inside the container need. Podman and Docker must run rootless — the scripts check and refuse otherwise (see above); with `sudo podman` or a system dockerd, container root is host root.

**Claude skip-permissions:** the image sets `IS_SANDBOX=1`, which lets `claude --dangerously-skip-permissions` run as root (Claude Code otherwise refuses it when running as root). It's still opt-in — plain `claude` asks for permissions as usual.

## Troubleshooting: Windows line endings (CRLF)

A repo cloned on Windows has CRLF files on disk and LF in the index, which the host's global `core.autocrlf=true` hides. The container doesn't see your Windows gitconfig, so without help `git status` would show every file as modified. The Windows wrappers (`bin/*.ps1`) therefore pass these settings to Git inside the container:

```text
core.autocrlf=true
core.filemode=false
```

They are set through `GIT_CONFIG_*` environment variables, so only Windows runs are affected and the images stay portable.

Two things to know:

- A committed `.gitattributes` still takes precedence over these settings.
- The environment settings override the repo's own `.git/config`. If you deliberately keep a repo LF-only on Windows (`core.autocrlf=false`), a `git checkout` or `git stash pop` inside the container can rewrite files to CRLF.

To check what Git sees inside the container:

```bash
git config --show-origin --get-all core.autocrlf   # which setting applies, and from where
git ls-files --eol                                 # index (i/) vs disk (w/) line endings
git diff --ignore-cr-at-eol --stat                 # is anything really changed?
```

If you still see phantom diffs, set the same values in the repo itself (stored in `.git/config`, so nothing is committed and collaborators are unaffected):

```bash
git config core.autocrlf true
git config core.filemode false
```

It also helps to add this to the project's `CLAUDE.md` / `AGENTS.md`: "This working tree uses Windows line endings. Never convert or 'fix' line endings. Verify real changes with `git diff --ignore-cr-at-eol`." Don't run `dos2unix` in the container: it only moves the phantom changes to the Windows side and breaks `.bat`/`.cmd` files.
