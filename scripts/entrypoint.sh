#!/bin/bash

# Ensure tailscaled runtime dirs exist and have correct permissions
mkdir -p /var/run/tailscale /var/lib/tailscale /data/.openclaw /data/workspace

# Start tailscaled in user-space mode for Render
echo "Starting tailscaled in userspace-networking mode..."
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &

# Wait for tailscaled to start
sleep 2

# Authenticate with Tailscale
if [ -n "$TS_AUTHKEY" ]; then
    echo "Connecting to Tailscale..."
    tailscale up --authkey=$TS_AUTHKEY --hostname=${TS_HOSTNAME:-openclaw-render} --accept-routes
else
    echo "WARNING: TS_AUTHKEY not set. Tailscale will stay offline."
fi

# Start OpenClaw
export PORT=${OPENCLAW_GATEWAY_PORT:-8080}
echo "Starting OpenClaw on port $PORT..."

# Note: We use absolute paths to ensure we find the config
exec openclaw run --config /app/config/openclaw.json
