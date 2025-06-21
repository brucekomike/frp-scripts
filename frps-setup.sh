#!/bin/bash

export FRP_DIR=$HOME/Workspace/frp
# Create the systemd service file
SERVICE_NAME="frps"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
echo "Creating systemd service file: $SERVICE_FILE"
sudo bash -c "cat << EOF | sudo tee $SERVICE_FILE &> /dev/null
[Unit]
Description = frp server
After = network.target syslog.target
Wants = network.target

[Service]
Type = simple
User = $USER
ExecStart = $FRP_DIR/frps -c $FRP_DIR/frps.toml
Restart = on-failure
RestartSec = 5s

[Install]
WantedBy = multi-user.target
EOF"

# Reload systemd daemon, enable and start the service
echo "Reloading systemd daemon..."
sudo systemctl daemon-reload

echo "Enabling $SERVICE_NAME service to start on boot..."
sudo systemctl enable "$SERVICE_NAME"

echo "Service creation complete. "
echo "You can start service by"
echo "systemctl start $SERVICE_NAME"
echo "Remember to configure your frps.toml file properly."

# Define the output file
TOML_FILE="$HOME/Workspace/frp/frps.toml"

# Function to generate a random token
generate_token() {
    # Generate a random string of 32 alphanumeric characters
    head /dev/urandom | tr -dc A-Za-z0-9_.- | head -c 32
}

# Generate the token
GENERATED_TOKEN=$(generate_token)

# Create the frps.toml content
cat << EOF > "$TOML_FILE"
# frps.toml - FRP Server Configuration

# Basic server settings
bindAddr = "0.0.0.0"
bindPort =12048
kcpBindPort = 12048
# Authentication settings
auth.method = "token"
auth.token = "$GENERATED_TOKEN"

# proxy setting
vhostHTTPPort=80
vhostHTTPSPort=443
allowPorts=[80,443,20000-30000]
# Logging settings
log.to = "./frps.log"
# trace, debug, info, warn, error
log.level = "info"
log.maxDays = 7
EOF
echo "Generated '$TOML_FILE' with a new authentication token."
echo "Authentication Token: $GENERATED_TOKEN"
echo "Please keep this token secure and use it in your frpc.toml client configuration."
