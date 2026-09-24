FROM node:22-slim

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends ca-certificates curl gh git jq python3 python3-pip python3-venv ripgrep tree \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @github/copilot

ENTRYPOINT ["copilot", "--no-auto-update"]
