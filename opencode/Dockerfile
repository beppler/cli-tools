FROM node:22-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends git jq ripgrep \
    && rm -rf /var/lib/apt/lists/*
RUN npm install -g opencode-ai
ENTRYPOINT ["opencode"]
