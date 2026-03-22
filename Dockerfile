# Use a slim Python 3.11 base image
FROM python:3.11-slim-bullseye

# Set working directory
WORKDIR /app

# Install system dependencies for Playwright/Puppeteer (WhatsApp & Browsing)
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    gnupg \
    curl \
    ca-certificates \
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

# Install OpenClaw (assuming pip installable or from repo)
# For the purpose of this template, we assume the user clones the repo here
# Or we can pull the latest release:
RUN pip install --no-cache-dir openclaw playwright

# Install browser binaries for Playwright
RUN playwright install chromium
RUN playwright install-deps chromium

# Create directories for persistent storage
RUN mkdir -p /app/config /app/data /app/logs

# Copy local config (if any)
COPY config/ /app/config/

# Command to run OpenClaw
CMD ["openclaw", "run", "--config", "/app/config/openclaw.json"]
