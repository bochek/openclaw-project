#!/bin/bash

# Ensure tailscaled runtime dirs exist and have correct permissions
mkdir -p /var/run/tailscale /var/lib/tailscale /data/.openclaw /data/workspace

# Start tailscaled in user-space mode for Render
echo "Starting tailscaled in userspace-networking mode..."
# Using --tun=userspace-networking is required when /dev/net/tun is not available (like on Render)
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &

# Wait for tailscaled to start
sleep 5

# Authenticate with Tailscale
if [ -n "$TS_AUTHKEY" ]; then
    echo "Connecting to Tailscale..."
    tailscale up --authkey=$TS_AUTHKEY --hostname=${TS_HOSTNAME:-openclaw-render} --accept-routes
else
    echo "WARNING: TS_AUTHKEY not set. Tailscale will stay offline."
fi

# Start GoClaw
export PORT=${OPENCLAW_GATEWAY_PORT:-8080}
# Route all outbound traffic into the Tailscale SOCKS5 proxy!
export ALL_PROXY="socks5://localhost:1055"
export HTTP_PROXY="socks5://localhost:1055"
export HTTPS_PROXY="socks5://localhost:1055"

echo "Starting GoClaw on port $PORT..."

# Execute the GoClaw binary (auto-onboards via GOCLAW_*_API_KEY env vars)
exec /usr/local/bin/goclaw
