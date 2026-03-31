# Stage 1: Build GoClaw from source
FROM golang:1.21-alpine AS builder
RUN apk add --no-cache git make
WORKDIR /app
# COPY current directory
COPY . .

# Find where go.mod is and build from there
RUN if [ -f "temp_goclaw/go.mod" ]; then \
        echo "Building from temp_goclaw..." && \
        cd temp_goclaw && \
        go build -o /app/goclaw . && \
        if [ -d "migrations" ]; then cp -r migrations /app/migrations; fi; \
    elif [ -f "go.mod" ]; then \
        echo "Building from root..." && \
        go build -o /app/goclaw . && \
        if [ -d "migrations" ]; then cp -r migrations /app/migrations; fi; \
    else \
        echo "ERROR: go.mod not found in /app or /app/temp_goclaw" && \
        ls -R /app && \
        exit 1; \
    fi

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

# Copy built binary and migrations from builder stage
COPY --from=builder /app/goclaw /usr/local/bin/goclaw
COPY --from=builder /app/migrations /usr/local/bin/migrations/
RUN chmod +x /usr/local/bin/goclaw

# Copy the entrypoint script
COPY scripts/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Run entrypoint
CMD ["/app/entrypoint.sh"]
