# Use a slim Python 3.11 base image
FROM python:3.11-slim-bullseye

# Set working directory
WORKDIR /app

# Enable non-interactive mode for apt
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies for Playwright, Puppeteer + Tailscale Setup
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    gnupg \
    curl \
    ca-certificates \
    lsb-release \
    iptables \
    iproute2 \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Install Tailscale via its official repository (STABLE)
RUN curl -fsSL https://pkgs.tailscale.com/stable/debian/bullseye.noarmor.gpg | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null && \
    curl -fsSL https://pkgs.tailscale.com/stable/debian/bullseye.tailscale-keyring.list | tee /etc/apt/sources.list.d/tailscale.list && \
    apt-get update && apt-get install -y tailscale && \
    rm -rf /var/lib/apt/lists/*

# Install OpenClaw and Playwright
RUN pip install --no-cache-dir openclaw playwright

# Install exactly what we need for Chromium to minimize image size
RUN playwright install chromium
# We already installed the typical libs above, but this confirms everything is solid
RUN playwright install-deps chromium

# Create directories for persistent storage and Tailscale runtime
RUN mkdir -p /app/config /app/data /app/logs /app/scripts /var/run/tailscale /var/cache/tailscale /var/lib/tailscale

# Copy local config and scripts
COPY config/ /app/config/
COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh

# Use entrypoint to start Tailscale and OpenClaw
ENTRYPOINT ["/app/scripts/entrypoint.sh"]
