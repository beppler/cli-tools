FROM debian:stable-slim

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends ca-certificates curl gh git jq python3 python3-pip python3-venv ripgrep tree \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://antigravity.google/cli/install.sh | bash -s -- --dir /usr/local/bin

ENV AGY_CLI_DISABLE_AUTO_UPDATE=true

ENTRYPOINT ["agy"]
