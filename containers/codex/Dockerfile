FROM docker.io/library/node:22-slim

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends bubblewrap ca-certificates curl gh git jq python3 python3-pip python3-venv ripgrep tree \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g @openai/codex

ENTRYPOINT ["codex", "-c", "check_for_update_on_startup=false", "-c", "sandbox_mode=\"danger-full-access\""]
