#!/bin/bash
set -e

echo "[INFO] Hytale Server Container Starting..."

# Directory paths
SERVER_DIR="/hytale/server"
ASSETS_DIR="/hytale/assets"
ASSETS_ZIP="${ASSETS_DIR}/Assets.zip"
UNIVERSE_DIR="/hytale/universe"
DOWNLOADER_BIN="/hytale/hytale-downloader"

# Ensure directories exist
mkdir -p "${SERVER_DIR}" "${ASSETS_DIR}" "${UNIVERSE_DIR}"

# Print Java version for verification
echo "[INFO] Java version:"
java -version

# Download server files if not present
if [ ! -f "${SERVER_DIR}/HytaleServer.jar" ] || [ ! -f "${ASSETS_ZIP}" ]; then
    echo "[INFO] Server files or assets missing. Downloading using Hytale Downloader..."
    
    # Download the Hytale downloader tool
    cd /hytale
    wget -q https://downloader.hytale.com/hytale-downloader.zip -O hytale-downloader.zip
    unzip -q hytale-downloader.zip
    chmod +x hytale-downloader*
    
    # Find the correct downloader binary (could be different names based on architecture)
    if [ -f "hytale-downloader-linux-amd64" ]; then
        DOWNLOADER_BIN="./hytale-downloader-linux-amd64"
    elif [ -f "hytale-downloader" ]; then
        DOWNLOADER_BIN="./hytale-downloader"
    else
        # Find first executable downloader file
        DOWNLOADER_BIN=$(find . -name "hytale-downloader*" -type f -executable | head -n 1)
    fi
    
    if [ -z "$DOWNLOADER_BIN" ] || [ ! -f "$DOWNLOADER_BIN" ]; then
        echo "[ERROR] Failed to find Hytale downloader executable"
        exit 1
    fi
    
    echo "[INFO] Using downloader: ${DOWNLOADER_BIN}"
    
    # Use the downloader to download server files
    ${DOWNLOADER_BIN} --download-path /tmp/server.zip
    
    if [ -f /tmp/server.zip ]; then
        echo "[INFO] Extracting server files..."
        unzip -q /tmp/server.zip -d /tmp/server-extract
        
        # Move Server directory contents to server directory
        if [ -d "/tmp/server-extract/Server" ]; then
            mv /tmp/server-extract/Server/* "${SERVER_DIR}/"
        fi
        
        # Move Assets.zip to assets directory
        if [ -f "/tmp/server-extract/Assets.zip" ]; then
            mv /tmp/server-extract/Assets.zip "${ASSETS_ZIP}"
        fi
        
        # Cleanup
        rm -rf /tmp/server-extract /tmp/server.zip
        rm -f /hytale/hytale-downloader.zip /hytale/hytale-downloader*
        
        echo "[INFO] Server files downloaded successfully."
    else
        echo "[ERROR] Failed to download server files. Please check your internet connection and try again."
        exit 1
    fi
else
    echo "[INFO] Server files already present, skipping download."
fi

# Verify required files exist
if [ ! -f "${SERVER_DIR}/HytaleServer.jar" ]; then
    echo "[ERROR] HytaleServer.jar not found in ${SERVER_DIR}"
    exit 1
fi

if [ ! -f "${ASSETS_ZIP}" ]; then
    echo "[WARN] Assets.zip not found at ${ASSETS_ZIP}. The server may need assets to run properly."
fi

# Set default JAVA_OPTS if not provided
if [ -z "$JAVA_OPTS" ]; then
    JAVA_OPTS="-Xms4G -Xmx4G"
    echo "[INFO] Using default JAVA_OPTS: $JAVA_OPTS"
fi

# Change to server directory
cd "${SERVER_DIR}"

# Start the Hytale server
echo "[INFO] Starting Hytale server..."
echo "[INFO] Using JAVA_OPTS: $JAVA_OPTS"
echo "[INFO] Server directory: ${SERVER_DIR}"
echo "[INFO] Assets: ${ASSETS_ZIP}"
echo "[INFO] Universe: ${UNIVERSE_DIR}"
echo "[INFO] Server will listen on 0.0.0.0:5520 (UDP)"
echo ""
echo "[INFO] Note: After server starts, you may need to authenticate using: /auth login device"
echo ""

# Start server with assets, universe directory, and bind address
exec java $JAVA_OPTS -jar HytaleServer.jar --assets "${ASSETS_ZIP}" --universe "${UNIVERSE_DIR}" --bind 0.0.0.0:5520

