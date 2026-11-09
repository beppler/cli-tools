FROM docker.io/library/debian:trixie-slim

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends ca-certificates curl gh git jq python3 python3-pip python3-venv python-is-python3 ripgrep tree \
    && rm -rf /var/lib/apt/lists/*

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
