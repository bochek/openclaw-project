# Use the official Microsoft Playwright Python image as base
FROM mcr.microsoft.com/playwright/python:v1.45.0-jammy

# Set working directory
WORKDIR /app

# Enable non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Install Tailscale and networking tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    gnupg \
    curl \
    ca-certificates \
    lsb-release \
    iptables \
    iproute2 \
    && rm -rf /var/lib/apt/lists/*

# Install Tailscale via its official repository for Ubuntu Jammy
RUN curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null && \
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list && \
    apt-get update && apt-get install -y tailscale && \
    rm -rf /var/lib/apt/lists/*

# Install OpenClaw, Playwright AND tenacity (needed as a workaround for current version)
RUN pip install --no-cache-dir openclaw playwright tenacity

# HOTPATCH: Fix known bug in openclaw 2026.3.20 (broken TimeoutError import from cmdop)
RUN sed -i 's/TimeoutError,//g' /usr/local/lib/python3.10/dist-packages/openclaw/__init__.py

# DEBUG: Confirm binary location
RUN find /usr/local/bin -name "openclaw*"
RUN find /usr/local/bin -name "pyclaw*"

# Use python -m playwright to ensure we call the installed package correctly
RUN python -m playwright install chromium

# Create directories for persistent storage and Tailscale runtime
RUN mkdir -p /app/config /app/data /app/logs /app/scripts /var/run/tailscale /var/cache/tailscale /var/lib/tailscale /data

# Copy local config and scripts
COPY config/ /app/config/
COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh

# Use entrypoint to start Tailscale and OpenClaw
ENTRYPOINT ["/app/scripts/entrypoint.sh"]
