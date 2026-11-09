FROM docker.io/library/debian:trixie-slim

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends bubblewrap ca-certificates curl gh git jq python3 python3-pip python3-venv python-is-python3 ripgrep tree \
    && rm -rf /var/lib/apt/lists/*

# The installer keeps the real files under $CODEX_HOME and only symlinks
# /usr/local/bin/codex to them. The launcher bind-mounts a host dir over /root,
# so install the payload outside of it (CODEX_HOME is set for this step only,
# so runtime config/auth still lands in /root/.codex).
RUN curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_HOME=/opt/codex CODEX_INSTALL_DIR=/usr/local/bin sh

ENTRYPOINT ["codex", "-c", "check_for_update_on_startup=false", "-c", "sandbox_mode=\"danger-full-access\""]
