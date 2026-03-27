# Stage 1: Build GoClaw from source
FROM golang:alpine AS builder
RUN apk add --no-cache git make
WORKDIR /app
RUN git clone https://github.com/nextlevelbuilder/goclaw.git .
RUN make build

# Stage 2: Final Operational Image
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install Tailscale, Python (for skills), and certificates
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    python3 \
    python3-pip \
    iptables \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://tailscale.com/install.sh | sh

# Set up app directory
WORKDIR /app

# Create directories for persistent storage and Tailscale runtime
RUN mkdir -p /app/config /app/data /app/logs /app/scripts /var/run/tailscale /var/cache/tailscale /var/lib/tailscale /data

# Copy the compiled GoClaw binary
COPY --from=builder /app/goclaw /usr/local/bin/goclaw

# Copy local config and scripts
COPY config/ /app/config/
COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh

# Use entrypoint to start Tailscale and OpenClaw
ENTRYPOINT ["/app/scripts/entrypoint.sh"]
