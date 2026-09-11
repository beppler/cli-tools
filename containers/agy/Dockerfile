FROM debian:stable-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git jq ripgrep \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fsSL https://antigravity.google/cli/install.sh | bash -s -- --dir /usr/local/bin

ENTRYPOINT ["agy"]
