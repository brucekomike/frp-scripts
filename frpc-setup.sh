#!/bin/bash

export FRP_DIR=$HOME/Workspace/frp
# Create the systemd service file
echo "Creating systemd service file: $SERVICE_FILE"
sudo bash -c "cat << EOF | sudo tee $SERVICE_FILE &> /dev/null
[Unit]
Description = frp server
After = network.target syslog.target
Wants = network.target

[Service]
Type = simple
User = $USER
ExecStart = $FRP_DIR/frpc -c $FRP_DIR/frpc.toml
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
TOML_FILE="$HOME/Workspace/frp/frpc.toml"

# Function to generate a random token
generate_token() {
    # Generate a random string of 32 alphanumeric characters
    head /dev/urandom | tr -dc A-Za-z0-9_.- | head -c 32
}

# Generate the token
AUTH_TOKEN=${AUTH_TOKEN:-$(generate_token)}

# Create the frps.toml content
cat << EOF > "$TOML_FILE"
# frpc.toml - FRP Client Configuration
user = "$HOSTNAME"

# Basic client settings

auth.method = "token"
auth.token = "$AUTH_TOKEN"
serverAddr = "SERVER.local"
serverPort = 12048

[[proxies]]
name = "http"
remotePort = 80 
localPort = 80

localIP = "127.0.0.1"
type = "http"
transport.useEncryption = true
transport.useCompression = true
healthCheck.type = "tcp"
healthCheck.timeoutSeconds = 3
healthCheck.maxFailed = 3
healthCheck.intervalSeconds = 10

[[proxies]]
name = "https"
type = "https"
localIP = "127.0.0.1"

localPort = 443
remotePort = 443
# Logging settings
log.to = "./frpc.log"
# trace, debug, info, warn, error
log.level = "info"
log.maxDays = 7
EOF

echo "Generated '$TOML_FILE' with a new authentication token."
echo "Authentication Token: $GENERATED_TOKEN"
echo "Please keep this token secure and use it in your frpc.toml client configuration."
