#!/bin/bash

# Ensure tailscaled runtime dir exists
mkdir -p /var/run/tailscale /var/lib/tailscale

# Start tailscaled in user-space mode for Render
echo "Starting tailscaled in userspace-networking mode..."
tailscaled --tun=userspace-networking --socks5-server=localhost:1055 &

# Wait for tailscaled to start
sleep 2

# Authenticate with Tailscale (using pre-configured Auth Key)
if [ -n "$TS_AUTHKEY" ]; then
    echo "Connecting to Tailscale..."
    tailscale up --authkey=$TS_AUTHKEY --hostname=${TS_HOSTNAME:-openclaw-render} --accept-routes
else
    echo "WARNING: TS_AUTHKEY not set. Tailscale will not connect."
fi

# Start OpenClaw
# Note: Render usually handles port binding automatically, but we ensure it's on 8080 or port from env
export PORT=${OPENCLAW_GATEWAY_PORT:-8080}
echo "Starting OpenClaw on port $PORT..."

# Assuming 'openclaw run' is the main command. 
# We use 'exec' to make OpenClaw the primary process for signal handling.
exec openclaw run --config /app/config/openclaw.json
