# OpenClaw Deployment Guide (DigitalOcean)

This repository contains the configuration files for deploying the **OpenClaw AI Agent** on a DigitalOcean Droplet using Docker Compose.

## 🚀 Quick Start

1.  **Clone the repository** (if you haven't already):
    ```bash
    git clone <your-repo-url> openclaw-project
    cd openclaw-project
    ```

2.  **Configure Environment Variables**:
    Copy the example environment file and fill in your secrets:
    ```bash
    cp .env.example .env
    nano .env
    ```

3.  **Prepare MCP Servers Configuration**:
    The agent is pre-configured to talk to your local MCP servers via Cloudflare Tunnel. Ensure your `CF_ACCESS_CLIENT_ID` and `CF_ACCESS_CLIENT_SECRET` are set in `.env`.

4.  **Deploy**:
    ```bash
    docker-compose up -d --build
    ```

## 🔑 API Keys Checklist

- [ ] **Together AI**: Get your API key from [together.ai](https://api.together.xyz/).
- [ ] **Telegram**: Create a bot via [@BotFather](https://t.me/botfather) to get the token.
- [ ] **Cloudflare**: In Zero Trust -> Access -> Service Auth, create a Service Token for `mcp.mydomain.com`.
- [ ] **Google Cloud**: Create a Service Account, download the JSON key, and place it at `config/google_service_account.json`.

## 🛡️ Networking & Security

- **Cloudflare Tunnel**: The `mcp_servers.json` uses `curl` with headers to securely bypass Cloudflare Access while communicating with your local servers.
- **Persistent Data**: Logs and session data (including WhatsApp) are stored in the `./data` and `./logs` folders for persistence between restarts.

## 🛠️ Commands for DigitalOcean

- **View Logs**: `docker-compose logs -f openclaw`
- **Restart Agent**: `docker-compose restart openclaw`
- **Update Image**: `docker-compose pull && docker-compose up -d`
