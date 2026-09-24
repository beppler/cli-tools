FROM oven/bun:slim

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends ca-certificates curl gh git jq python3 python3-pip python3-venv ripgrep tree \
    && rm -rf /var/lib/apt/lists/*

# Install global bun packages outside of $HOME, since $HOME (/root) is
# bind-mounted over at runtime by bin/opencode, which would otherwise
# hide the default $HOME/.bun install location.
ENV BUN_INSTALL=/usr/local

RUN bun add -g opencode-ai

ENV OPENCODE_DISABLE_AUTOUPDATE=true

ENTRYPOINT ["opencode"]
