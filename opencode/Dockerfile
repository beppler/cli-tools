FROM oven/bun:slim

# Install global bun packages outside of $HOME, since $HOME (/root) is
# bind-mounted over at runtime by bin/opencode, which would otherwise
# hide the default $HOME/.bun install location.
ENV BUN_INSTALL=/usr/local

RUN apt-get update \
    && apt-get install -y --no-install-recommends git jq ripgrep \
    && rm -rf /var/lib/apt/lists/* \
    && bun add -g opencode-ai

ENTRYPOINT ["opencode"]
