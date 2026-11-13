FROM docker.io/library/debian:trixie-slim

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends ca-certificates curl gh git jq python3 python3-pip python3-venv python-is-python3 ripgrep tree \
    && rm -rf /var/lib/apt/lists/*

# Install mise with the official installer outside /root (the launcher
# bind-mounts a host dir over it). Keep tool installs in mise's system data
# directory too, so they don't land in that per-harness mount, and put the
# system shim directory on PATH so `mise install` works without shell
# activation. Trust the mounted project tree so project mise.toml files load
# without an interactive trust prompt.
RUN curl -fsSL https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise MISE_INSTALL_HELP=0 sh

ENV MISE_DATA_DIR=/usr/local/share/mise \
    MISE_TRUSTED_CONFIG_PATHS=/workspace \
    PATH="/usr/local/share/mise/shims:$PATH"

# Install with a temporary HOME so nothing lands in /root (the launcher
# bind-mounts a host dir over it), then copy the self-contained binary
# to /usr/local/bin. The v2 installer ships OpenCode 2 (the @opencode/cli
# line); the plain installer at opencode.ai/install only installs OpenCode 1.
RUN export HOME=/tmp/opencode-home \
    && mkdir -p "$HOME" \
    && curl -fsSL https://opencode.ai/v2/install | bash -s -- --no-modify-path \
    && install -m 0755 "$HOME/.opencode/bin/opencode" /usr/local/bin/opencode \
    && rm -rf "$HOME"

ENV OPENCODE_DISABLE_AUTOUPDATE=true

ENTRYPOINT ["opencode"]
