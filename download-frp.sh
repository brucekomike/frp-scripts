#!/bin/bash
get_latest_release_tag() {
    curl -s "https://api.github.com/repos/fatedier/frp/releases/latest" | grep -Po '"tag_name": "\K[^"]*'
}

# Function to detect architecture
detect_arch() {
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)
            echo "amd64"
            ;;
        aarch64)
            echo "arm64"
            ;;
        armv7l)
            echo "arm"
            ;;
        *)
            echo "unsupported"
            ;;
    esac
}

# Main script
main() {
    LATEST_TAG=$(get_latest_release_tag)
    if [ -z "$LATEST_TAG" ]; then
        echo "Error: Could not fetch the latest release tag."
        exit 1
    fi
    echo "Latest FRP release: $LATEST_TAG"

    DETECTED_ARCH=$(detect_arch)
    if [ "$DETECTED_ARCH" == "unsupported" ]; then

        echo "Error: Your architecture ($ARCH) is not directly supported by this script for FRP downloads."
        echo "Please manually download from https://github.com/fatedier/frp/releases"
        exit 1
    fi
    echo "Detected architecture: $DETECTED_ARCH"

    FILENAME="frp_${LATEST_TAG#v}_linux_${DETECTED_ARCH}.tar.gz"
    DOWNLOAD_URL="https://github.com/fatedier/frp/releases/download/${LATEST_TAG}/${FILENAME}"

    echo "Attempting to download: $DOWNLOAD_URL"

    # Use curl to download the file
    curl -L -o "$FILENAME" "$DOWNLOAD_URL"

    if [ $? -eq 0 ]; then
        echo "Download complete: $FILENAME"
        echo "extracting it using: tar -xzf $FILENAME"
        tar -xzf $FILENAME
    else
        echo "Error: Download failed."
        echo "Please check the URL or your network connection."
    fi
}



mkdir -p ~/Workspace
cd ~/Workspace
main
mv ${FILENAME%.tar.gz} frp

