FROM node:22-slim
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates gh git jq ripgrep \
    && rm -rf /var/lib/apt/lists/*
RUN npm install -g @github/copilot
ENTRYPOINT ["copilot"]
