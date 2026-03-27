# Stage 1: Build GoClaw from source
FROM golang:alpine AS builder
RUN apk add --no-cache git make
WORKDIR /app
RUN git clone https://github.com/nextlevelbuilder/goclaw.git .
RUN make build

# Stage 2: Final Operational Image
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install Tailscale, Python (for skills), NodeJS (for Surge), and certificates
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    python3 \
    python3-pip \
    iptables \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# Install Surge globally for simple static site deployment
RUN npm install -g surge

RUN curl -fsSL https://tailscale.com/install.sh | sh

# Set up app directory
WORKDIR /app

# Create directories for persistent storage and Tailscale runtime
RUN mkdir -p /app/config /app/data /app/logs /app/scripts /var/run/tailscale /var/cache/tailscale /var/lib/tailscale /data

# Copy the compiled GoClaw binary and its database migrations
COPY --from=builder /app/goclaw /usr/local/bin/goclaw
COPY --from=builder /app/migrations /usr/local/bin/migrations


# Copy local config and scripts
COPY config/ /app/config/
COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh

# Use entrypoint to start Tailscale and OpenClaw
ENTRYPOINT ["/app/scripts/entrypoint.sh"]
