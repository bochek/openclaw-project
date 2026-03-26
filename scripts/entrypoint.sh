#!/bin/bash

# Start tailscaled in the background
# --tun=userspace-networking is safer for PaaS like Render
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --outbound-http-proxy-listen=localhost:1055 &

# Wait for tailscaled to start
sleep 2

# Authenticate with Tailscale
# Use TS_AUTHKEY from environment variables
if [ -n "$TS_AUTHKEY" ]; then
    echo "Connecting to Tailscale..."
    tailscale up --authkey=$TS_AUTHKEY --hostname=${TS_HOSTNAME:-openclaw-render} --accept-routes
else
    echo "TS_AUTHKEY not set, skipping Tailscale connection."
fi

# Start OpenClaw
echo "Starting OpenClaw..."
exec openclaw run --config /app/config/openclaw.json
