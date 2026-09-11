FROM node:22-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends bubblewrap ca-certificates git jq ripgrep \
    && rm -rf /var/lib/apt/lists/*
RUN npm install -g @openai/codex
ENTRYPOINT ["codex"]
