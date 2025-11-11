#!/bin/bash

export FRP_DIR=$HOME/Workspace/frp

if [ ! -d $FRP_DIR ]; then
    ./download-frp.sh
fi

# Create the systemd service file
SERVICE_NAME="frpc"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
echo "Creating systemd service file: $SERVICE_FILE"
cat << EOF | sudo tee $SERVICE_FILE &> /dev/null
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
EOF

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
mkdir "$FRP_DIR/conf.d"
TOML_FILE="$FRP_DIR/frpc.toml"
TOML_FILE_sub="$FRP_DIR/conf.d/site.toml.temp"

# Function to generate a random token
generate_token() {
    # Generate a random string of 32 alphanumeric characters
    head /dev/urandom | tr -dc A-Za-z0-9_.- | head -c 32
}

# Generate the token
AUTH_TOKEN=${AUTH_TOKEN:-$(generate_token)}

# Create the frpc.toml content
cat << EOF > "$TOML_FILE"
user = "$HOSTNAME"

auth.method = "token"
auth.token = "$AUTH_TOKEN"
serverAddr = "your-server.local"
serverPort = 12048
# Logging settings
log.to = "$HFRP_DIR/frpc.log"
# trace, debug, info, warn, error
log.level = "info"
log.maxDays = 7
includes = [ "$FRP_DIR/conf.d/*.toml" ]
EOF

cat << EOF > "$TOML_FILE_sub"
# please make sure these name are:
# unique in ALL clients
# otherwise config overwritten triggered
[[proxies]]
name = "http"
type = "http"
localIP = "127.0.0.1"
localPort = 80
customDomains = ["your-domain.local"]
transport.useEncryption = true
transport.useCompression = true

[[proxies]]
name = "https"
type = "https"
localIP = "127.0.0.1"
localPort = 443
customDomains = ["your-domain.local"]
transport.useEncryption = true
transport.useCompression = true

[[proxies]]
name = "ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = 22222
customDomains = ["your-domain.local"]
transport.useEncryption = true
transport.useCompression = true

EOF

echo "Generated '$TOML_FILE' with a new authentication token."
echo "Authentication Token: $GENERATED_TOKEN"
echo "Please keep this token secure and use it in your frpc.toml client configuration."
