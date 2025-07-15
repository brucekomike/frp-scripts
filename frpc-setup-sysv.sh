#!/bin/bash

# --- Configuration Variables ---
# Base directory for frp binaries and configuration
export FRP_DIR="$HOME/Workspace/frp"
# Name of the service
SERVICE_NAME="frpc"
# Location for the SysV init script
SERVICE_FILE="/etc/init.d/${SERVICE_NAME}"
# User to run the frpc service as (defaults to the user executing this script)
SERVICE_USER=$(whoami)
# Standard location for the PID file
PID_FILE="/var/run/${SERVICE_NAME}.pid"

# Ensure the frp directory exists
mkdir -p "$FRP_DIR"

echo "Creating SysV init script: $SERVICE_FILE"
# Create the SysV init script content
cat << EOF | sudo tee "$SERVICE_FILE" &> /dev/null
#!/bin/sh
### BEGIN INIT INFO
# Provides:          ${SERVICE_NAME}
# Required-Start:    \$network \$syslog
# Required-Stop:     \$network \$syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: frp client service
# Description:       frp client service for tunneling
### END INIT INFO

# LSB Init Script variables
NAME="${SERVICE_NAME}"
DESC="frp client service"
DAEMON="${FRP_DIR}/frpc"
DAEMON_ARGS="-c ${FRP_DIR}/frpc.toml"
PIDFILE="${PID_FILE}"

# User to run the service as
SERVICE_USER="${SERVICE_USER}"

# Check if the frpc executable exists
test -x "\$DAEMON" || exit 0

# Include functions from /lib/lsb/init-functions (if available)
# This provides log_daemon_msg, log_end_msg, status_of_proc
if [ -f /lib/lsb/init-functions ]; then
    . /lib/lsb/init-functions
else
    # Fallback for systems without lsb-base (e.g., some minimal installs)
    log_daemon_msg() { echo "\$@"; }
    log_end_msg() { [ "\$1" -eq 0 ] && echo "OK" || echo "FAILED"; }
    status_of_proc() {
        if [ -f "\$1" ]; then
            PID=\$(cat "\$1")
            if ps -p \$PID > /dev/null; then
                echo "\$3 is running (PID \$PID)"
                return 0
            else
                echo "\$3 is not running (PID file exists but process not found)"
                return 1
            fi
        else
            echo "\$3 is not running (PID file not found)"
            return 3
        fi
    }
fi

# Function to start the service
do_start() {
    log_daemon_msg "Starting \$DESC" "\$NAME"
    # Use start-stop-daemon to manage the process
    # --start: start the process
    # --pidfile: create a PID file
    # --chuid: change user and group
    # --background: run in background
    # --exec: executable
    # --: arguments to the executable
    start-stop-daemon --start --pidfile "\$PIDFILE" --chuid "\$SERVICE_USER" --background \
        --exec "\$DAEMON" -- \$DAEMON_ARGS || log_end_msg 1
    log_end_msg 0
}

# Function to stop the service
do_stop() {
    log_daemon_msg "Stopping \$DESC" "\$NAME"
    # Use start-stop-daemon to stop the process
    # --stop: stop the process
    # --pidfile: use PID file to find process
    # --retry: retry stopping for a few seconds
    start-stop-daemon --stop --pidfile "\$PIDFILE" --retry 5 || log_end_msg 1
    rm -f "\$PIDFILE" # Clean up PID file
    log_end_msg 0
}

# Main case statement for init script actions
case "\$1" in
    start)
        do_start
        ;;
    stop)
        do_stop
        ;;
    restart|force-reload)
        do_stop
        do_start
        ;;
    status)
        status_of_proc -p "\$PIDFILE" "\$DAEMON" "\$NAME" && exit 0 || exit \$?
        ;;
    *)
        echo "Usage: \$0 {start|stop|restart|status}" >&2
        exit 3
        ;;
esac

exit 0
EOF

echo "Setting permissions for $SERVICE_FILE..."
sudo chmod +x "$SERVICE_FILE"

echo "Enabling $SERVICE_NAME service to start on boot..."
# Check for update-rc.d (Debian/Ubuntu) or chkconfig (RHEL/CentOS)
if command -v update-rc.d &> /dev/null; then
    sudo update-rc.d "$SERVICE_NAME" defaults
    echo "Used update-rc.d for service management."
elif command -v chkconfig &> /dev/null; then
    sudo chkconfig --add "$SERVICE_NAME"
    sudo chkconfig "$SERVICE_NAME" on
    echo "Used chkconfig for service management."
else
    echo "Warning: Neither update-rc.d nor chkconfig found. You may need to manually enable the service."
    echo "Refer to your distribution's documentation for adding init scripts to runlevels."
fi

echo "Service creation complete. "
echo "You can start service by:"
echo "sudo service $SERVICE_NAME start"
echo "Remember to configure your frps.toml file properly."

# Define the output file for frpc.toml
TOML_FILE="$FRP_DIR/frpc.toml"

# Function to generate a random token
generate_token() {
    # Generate a random string of 32 alphanumeric characters
    head /dev/urandom | tr -dc A-Za-z0-9_.- | head -c 32
}

# Generate the token (if not already set in environment)
AUTH_TOKEN=${AUTH_TOKEN:-$(generate_token)}

# Create the frpc.toml content
cat << EOF > "$TOML_FILE"
user = "$HOSTNAME"

auth.method = "token"
auth.token = "$AUTH_TOKEN"
serverAddr = "your-server.local"
serverPort = 12048
# Logging settings
log.to = "$FRP_DIR/frpc.log" # Absolute path for logs
# trace, debug, info, warn, error
log.level = "info"
log.maxDays = 7

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
echo "Authentication Token: $AUTH_TOKEN"
echo "Please keep this token secure and use it in your frpc.toml client configuration."
