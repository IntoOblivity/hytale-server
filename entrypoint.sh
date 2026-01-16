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
    
    # Use the downloader to download server files with retry logic
    MAX_RETRIES=3
    RETRY_COUNT=0
    DOWNLOAD_SUCCESS=false
    
    while [ $RETRY_COUNT -lt $MAX_RETRIES ] && [ "$DOWNLOAD_SUCCESS" = false ]; do
        RETRY_COUNT=$((RETRY_COUNT + 1))
        
        if [ $RETRY_COUNT -gt 1 ]; then
            echo "[INFO] Retry attempt $RETRY_COUNT of $MAX_RETRIES..."
            sleep 5
        fi
        
        echo "[INFO] Downloading server files (attempt $RETRY_COUNT/$MAX_RETRIES)..."
        echo "[INFO] Note: If you see an authorization code, visit https://oauth.accounts.hytale.com/oauth2/device/verify to authorize."
        
        # Run downloader and capture output
        if ${DOWNLOADER_BIN} --download-path /tmp/server.zip 2>&1; then
            if [ -f /tmp/server.zip ]; then
                DOWNLOAD_SUCCESS=true
                echo "[INFO] Download completed successfully!"
            else
                echo "[WARN] Downloader completed but server.zip not found. Retrying..."
            fi
        else
            DOWNLOAD_EXIT_CODE=$?
            echo "[WARN] Downloader exited with code $DOWNLOAD_EXIT_CODE. This might be a timeout or network issue."
            
            if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
                echo "[INFO] Waiting before retry..."
            fi
        fi
    done
    
    if [ "$DOWNLOAD_SUCCESS" = false ]; then
        echo "[ERROR] Failed to download server files after $MAX_RETRIES attempts."
        echo "[ERROR] This could be due to:"
        echo "[ERROR]   - Network connectivity issues"
        echo "[ERROR]   - Hytale services being temporarily unavailable"
        echo "[ERROR]   - Timeout issues with the downloader"
        echo "[ERROR]   - Authorization required but not completed"
        echo "[ERROR]"
        echo "[ERROR] Troubleshooting steps:"
        echo "[ERROR]   1. Check your internet connection"
        echo "[ERROR]   2. Visit https://oauth.accounts.hytale.com/oauth2/device/verify with the authorization code if shown"
        echo "[ERROR]   3. Check if you can access https://account-data.hytale.com from your network"
        echo "[ERROR]   4. Try running the downloader manually inside the container"
        echo "[ERROR]   5. Wait a few minutes and restart the container"
        exit 1
    fi
    
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

