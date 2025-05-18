#!/bin/bash

# scripts/ngrok_setup.sh
# Sets up Ngrok for SSH access on a VM, outputs SSH address and port for GitHub Workflow Dispatch inputs

# Exit on error
set -e

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Check for required dependencies
if ! command_exists curl; then
  echo "Installing curl..."
  sudo apt update
  sudo apt install -y curl
fi

if ! command_exists jq; then
  echo "Installing jq..."
  sudo apt update
  sudo apt install -y jq
fi

# Check if Ngrok is installed
if command_exists ngrok; then
  echo "Ngrok is already installed."
else
  echo "Installing Ngrok..."
  curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /usr/share/keyrings/ngrok.asc >/dev/null
  echo "deb [signed-by=/usr/share/keyrings/ngrok.asc] https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
  sudo apt update
  sudo apt install -y ngrok
fi

# Prompt for Ngrok authtoken
read -p "Enter your Ngrok authtoken (get from https://dashboard.ngrok.com/get-started/your-authtoken): " NGROK_AUTHTOKEN
if [ -z "$NGROK_AUTHTOKEN" ]; then
  echo "Error: Ngrok authtoken is required."
  exit 1
fi

# Authenticate Ngrok
echo "Authenticating Ngrok..."
ngrok config add-authtoken "$NGROK_AUTHTOKEN"

# Prompt for SSH port
read -p "Enter the SSH port to tunnel (e.g., 2222, default 22): " SSH_PORT
SSH_PORT=${SSH_PORT:-22}

# Validate SSH port
if ! [[ "$SSH_PORT" =~ ^[0-9]+$ ]] || [ "$SSH_PORT" -lt 1 ] || [ "$SSH_PORT" -gt 65535 ]; then
  echo "Error: Invalid SSH port. Must be a number between 1 and 65535."
  exit 1
fi

# Start Ngrok tunnel for SSH
echo "Starting Ngrok tunnel for SSH port $SSH_PORT..."
ngrok tcp "$SSH_PORT" --log=stdout > ngrok.log &

# Wait for Ngrok to initialize
echo "Waiting for Ngrok tunnel to establish..."
sleep 5

# Get the Ngrok public URL
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')
if [ -z "$NGROK_URL" ]; then
  echo "Error: Failed to retrieve Ngrok tunnel URL. Check ngrok.log for details."
  cat ngrok.log
  exit 1
fi

# Extract host and port from the URL (e.g., tcp://0.tcp.ngrok.io:12345)
NGROK_HOST=$(echo "$NGROK_URL" | cut -d '/' -f 3 | cut -d ':' -f 1)
NGROK_PORT=$(echo "$NGROK_URL" | cut -d ':' -f 3)

# Validate extracted values
if [ -z "$NGROK_HOST" ] || [ -z "$NGROK_PORT" ]; then
  echo "Error: Failed to parse Ngrok host or port from URL: $NGROK_URL"
  exit 1
fi

# Output SSH connection details for GitHub Workflow Dispatch inputs
echo "Ngrok SSH connection details for GitHub Workflow Dispatch inputs:"
echo "server_ssh_address: $NGROK_HOST"
echo "server_ssh_port: $NGROK_PORT"
echo ""
echo "Use these values in the GitHub Workflow Dispatch inputs when triggering the workflow."
echo "Connect manually using: ssh -p $NGROK_PORT user@$NGROK_HOST"
echo ""
echo "Ngrok is running in the background. Logs are saved to ngrok.log."
echo "To keep Ngrok running, use 'nohup' or a terminal multiplexer like 'tmux':"
echo "  nohup $0 &"
echo "  tmux new -s ngrok '$0'"
