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
User = root
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
TOML_FILE="$FRP_DIR/frps.toml"

# Function to generate a random token
generate_token() {
    # Generate a random string of 32 alphanumeric characters
    head /dev/urandom | tr -dc A-Za-z0-9_.- | head -c 32
}

# Generate the token
GENERATED_TOKEN=$(generate_token)

# Create the frps.toml content
cat << EOF > "$TOML_FILE"
bindAddr = "0.0.0.0"
bindPort = 12048
kcpBindPort = 12048
auth.method = "token"
auth.token = "$GENERATED_TOKEN"
vhostHTTPPort = 80
vhostHTTPSPort = 443
allowPorts = [
  { single = 80 },
  { single = 443 },
  { start = 20000, end = 30000 }
]
log.to = "$FRP_DIR/frps.log"
log.level = "info"
log.maxDays = 7
custom404Page = "./404.html
# sshTunnelGateway.bindPort = 12022
# sshTunnelGateway.privateKeyFile = "$HOME/.ssh/id_rsa"
# sshTunnelGateway.autoGenPrivateKeyPath = ""
# sshTunnelGateway.authorizedKeysFile = "$HOME/.ssh/authorized_keys"
EOF
echo "Generated '$TOML_FILE' with a new authentication token."
echo "Authentication Token: $GENERATED_TOKEN"
echo "Please keep this token secure and use it in your frpc.toml client configuration."
