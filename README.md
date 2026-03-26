# OpenClaw on Render.com with Tailscale

Deploying OpenClaw to Render allowing it to securely access your local MCP servers via Tailscale.

## 🚀 Deployment to Render

1.  **Push your code** to GitHub.
2.  **Create a New Service** on Render using the `Blueprint` (pointing to `render.yaml`).
3.  **Configure Secrets** in Render Dashboard:
    - `TS_AUTHKEY`: Generate an **Ephemeral Auth Key** in your [Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys).
    - `OPENROUTER_API_KEY`: Your key from [OpenRouter](https://openrouter.ai/).
    - `TELEGRAM_BOT_TOKEN`: Your bot token.

## 🔐 Tailscale Integration

- The agent will appear as a node named `openclaw-render` in your Tailscale network.
- To reach local machines, use their **Tailscale MagicDNS** name (e.g., `my-laptop`) or their **Tailscale IP** (starts with `100.`).
- Example `mcp_servers.json`:
  ```json
  {
    "mcpServers": {
      "local-pc": {
        "command": "curl",
        "args": ["http://my-pc:1234/sse"]
      }
    }
  }
  ```

## 🛠️ Local Development

- **Build**: `docker build -t openclaw-render .`
- **Run**: `docker run --env-file .env openclaw-render`

## 🛡️ Security

- All traffic between Render and your local machines is encrypted by Tailscale.
- Cloudflare Tunnel is no longer required for this setup but can be used as a fallback.
