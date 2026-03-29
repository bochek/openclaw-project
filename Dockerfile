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

# Copy built binary from builder stage
COPY --from=builder /app/bin/goclaw /usr/local/bin/goclaw
RUN chmod +x /usr/local/bin/goclaw

# Copy the entrypoint script
COPY scripts/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Run entrypoint
CMD ["/app/entrypoint.sh"]
