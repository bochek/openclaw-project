# Echo (bochek-ai) — High-Performance AI Agent on Render

Echo (known as **bochek-ai**) is a production-ready AI agent built on the **GoClaw** engine. It is specifically optimized to run on low-resource cloud hosting (like the **Render Starter tier**) while providing a full suite of autonomous capabilities, long-term memory, and multi-channel connectivity.

## 🚀 Why this architecture?

Standard AI agents (e.g., Node.js-based) often require 1GB+ of RAM, which makes them expensive to host. This project uses **GoClaw** (a Go-based rewrite), which consumes only **~35MB of RAM**, allowing you to host a powerful agent for as little as $7/month on Render.

### Key Features:
- **Ultra-Lightweight:** 25MB binary, minimal memory footprint.
- **Persistent Memory:** Powered by PostgreSQL and a 1GB persistent disk.
- **Secure Networking:** Built-in **Tailscale** support for secure access to local tools and private databases.
- **Multi-Channel:** Native support for Telegram (and Discord/Slack).
- **Python Skills:** Full support for executing complex Python-based tools.

---

## 🛠️ Quick Start (Render Deployment)

1. **Fork this repository.**
2. **Create a Blueprint on Render:**
   - Link your fork to Render.
   - Use the provided `render.yaml` (Blueprint).
3. **Configure Environment Variables:**
   Render will prompt you for these:
   - `GOCLAW_TELEGRAM_TOKEN`: Your Telegram Bot API token.
   - `GOCLAW_ENCRYPTION_KEY`: A **64-character HEX string** (32 bytes) for encrypting keys in the DB.
   - `GOCLAW_GATEWAY_TOKEN`: A secret password for accessing the Gateway API from the UI.
   - `TS_AUTHKEY`: Your Tailscale Auth Key (optional, for private networking).
4. **Deploy.**

---

## 🖥️ Web UI Dashboard

The Web UI is served separately to save cloud resources. To manage your agent:

1. **Clone your repo locally.**
2. **Run the UI via Docker Compose:**
   ```bash
   docker compose up -d
   ```
3. **Access the dashboard:**
   Open `http://localhost:8081` in your browser.
4. **Login:**
   - **User ID:** `system`
   - **Token:** The value you set for `GOCLAW_GATEWAY_TOKEN`.

---

## 🧠 Soul & Identity

Echo is configured as a digital alter-ego for **Andrey Bochek**. It follows the principle of "Do first, ask later" and maintains a deep contextual memory of its owner's life, nomad lifestyle, and digital art preferences.

---

## 📂 Project Structure
- `/scripts/entrypoint.sh`: Orchestrates Tailscale and GoClaw startup.
- `Dockerfile`: Multi-stage build (clones and compiles GoClaw from source).
- `render.yaml`: Blueprint for Render.com (API, Disk, and Database).
- `docker-compose.yml`: Local UI development server.

---

## 📜 License
MIT
