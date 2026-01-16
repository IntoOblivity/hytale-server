# Hytale Server Docker Setup for Unraid

This Docker setup allows you to run a Hytale server on Unraid using the official Hytale Downloader and Java 25 (Eclipse Temurin).

## Requirements

- **Java**: Java 25 (Eclipse Temurin) - installed in container
- **RAM**: Minimum 4GB (higher recommended for more players)
- **Port**: UDP 5520 (default Hytale server port)
- **Storage**: Space for server files and world data

## Quick Start (Unraid - Standard Docker Commands)

**Note:** Unraid typically doesn't have `docker-compose` installed by default. Use standard Docker commands as shown below.

1. **Navigate to the directory with your Docker files:**
   ```bash
   cd /mnt/user/appdata/hytale-server
   ```

2. **Build the image:**
   ```bash
   docker build -t hytale-server:latest .
   ```

   **Optional - Using a Local Downloader:**
   
   If you have already downloaded the Hytale downloader executable and placed it in your project folder, you can mount it as a volume to avoid downloading it each time:
   
   ```bash
   docker run -d \
     --name hytale-server \
     --restart unless-stopped \
     -p 5520:5520/udp \
     -v /mnt/user/appdata/hytale-server/server:/hytale/server \
     -v /mnt/user/appdata/hytale-server/assets:/hytale/assets \
     -v /mnt/user/appdata/hytale-server/universe:/hytale/universe \
     -v /mnt/user/appdata/hytale-server/hytale-downloader-linux-amd64:/hytale/downloader/hytale-downloader-linux-amd64:ro \
     -e JAVA_OPTS="-Xms8G -Xmx8G" \
     hytale-server:latest
   ```
   
   The entrypoint script will automatically detect and use the local downloader if present, otherwise it will download it automatically.

3. **Run the container:**
   ```bash
   docker run -d \
     --name hytale-server \
     --restart unless-stopped \
     -p 5520:5520/udp \
     -v /mnt/user/appdata/hytale-server/server:/hytale/server \
     -v /mnt/user/appdata/hytale-server/assets:/hytale/assets \
     -v /mnt/user/appdata/hytale-server/universe:/hytale/universe \
     -e JAVA_OPTS="-Xms8G -Xmx8G" \
     hytale-server:latest
   ```

4. **View logs:**
   ```bash
   docker logs -f hytale-server
   ```

5. **Stop the container:**
   ```bash
   docker stop hytale-server
   ```

6. **Start the container:**
   ```bash
   docker start hytale-server
   ```

7. **Remove the container (keeps volumes):**
   ```bash
   docker rm hytale-server
   ```

## Unraid Setup

### Using Unraid Docker GUI

1. **In Unraid, go to Docker tab** → Add Container

2. **Configuration:**
   - **Repository**: Use local image `hytale-server:latest` (build first) OR build from Dockerfile
   - **Container Name**: `hytale-server`
   - **Network Type**: Bridge (or Host if you prefer)
   - **Ports**: Add port mapping
     - **Container Port**: `5520`
     - **Host Port**: `5520`
     - **Type**: `UDP`
   - **Volume Mappings**:
   - `/mnt/user/appdata/hytale-server/server` → `/hytale/server`
   - `/mnt/user/appdata/hytale-server/assets` → `/hytale/assets`
   - `/mnt/user/appdata/hytale-server/universe` → `/hytale/universe`
   
   **Tip:** You can create these directories first:
   ```bash
   mkdir -p /mnt/user/appdata/hytale-server/{server,assets,universe}
   ```
   - **Environment Variables**:
     - `JAVA_OPTS` = `-Xms4G -Xmx4G` (adjust based on your server RAM)

3. **Click Apply** to start the container

### Alternative: Using Docker Compose (if installed via NerdPack or Community Apps)

**Note:** Unraid doesn't come with Docker Compose by default. If you've installed it via NerdPack or a plugin, you can use:

1. Place `docker-compose.yml` in your desired location (e.g., `/mnt/user/appdata/hytale-server/`)
2. Update volume paths in `docker-compose.yml` to use Unraid paths:
   ```yaml
   volumes:
     - /mnt/user/appdata/hytale-server/server:/hytale/server
     - /mnt/user/appdata/hytale-server/assets:/hytale/assets
     - /mnt/user/appdata/hytale-server/universe:/hytale/universe
   ```
3. Run via terminal (if docker-compose is installed):
   ```bash
   docker-compose up -d
   ```

**Recommended:** Use the standard Docker commands method above instead, as it works on all Unraid systems without additional plugins.

## Server Authentication

After the server starts, you **must authenticate** using the device login method:

1. **Access the container console:**
   ```bash
   docker exec -it hytale-server bash
   ```
   Or via Unraid: Docker → hytale-server → Console

2. **In the server console, run the authentication command:**
   ```
   /auth login device
   ```

3. **Follow the instructions:**
   - The server will display a code
   - Visit https://accounts.hytale.com/device (from the official Hytale Server Manual)
   - Enter the code and complete authentication
   - Authentication is required for the server to operate

## Configuration

### Memory Settings

Adjust `JAVA_OPTS` environment variable based on your server's RAM:

- **Small server (few players)**: `-Xms4G -Xmx4G`
- **Medium server**: `-Xms6G -Xmx8G`
- **Large server**: `-Xms8G -Xmx12G` or higher

### Port Configuration

The default port is **UDP 5520**. To change it:

1. Update the port mapping in your `docker run` command or Unraid GUI (e.g., `-p 5530:5520/udp` for host port 5530)
2. Update the `--bind` parameter in `entrypoint.sh` if needed (e.g., `--bind 0.0.0.0:5530`)

### Persistent Data

The Docker setup uses three persistent volumes:

- **`/hytale/server`** - Server JAR files and server-related files
- **`/hytale/assets`** - Assets.zip file
- **`/hytale/universe`** - World files, server configuration, logs, player data

For Unraid, these map to:
- `/mnt/user/appdata/hytale-server/server`
- `/mnt/user/appdata/hytale-server/assets`
- `/mnt/user/appdata/hytale-server/universe`

**Note:** Make sure these directories exist before running the container:
```bash
mkdir -p /mnt/user/appdata/hytale-server/{server,assets,universe}
```

## Updating Server Files

The container automatically downloads server files on first run. To update:

1. **Option 1**: Delete server files and restart
   ```bash
   rm -rf /mnt/user/appdata/hytale-server/server/*
   docker restart hytale-server
   ```

2. **Option 2**: Manually use the downloader inside the container
   ```bash
   docker exec -it hytale-server hytale-downloader --download-path /tmp/update.zip
   ```

## Troubleshooting

### Downloader timeout / "context deadline exceeded" error

If you see errors like:
```
error fetching manifest: could not get signed URL for manifest: context deadline exceeded
```

**Solutions:**

1. **Complete the authorization first:**
   - If you see an authorization code (e.g., `gGErMuVN`), visit: https://oauth.accounts.hytale.com/oauth2/device/verify
   - Enter the code and complete the OAuth flow

2. **Check network connectivity from container:**
   ```bash
   docker exec hytale-server ping -c 3 account-data.hytale.com
   docker exec hytale-server curl -I https://account-data.hytale.com/game-assets/version/release.json
   ```

3. **Test DNS resolution:**
   ```bash
   docker exec hytale-server nslookup account-data.hytale.com
   ```

4. **Manual download (alternative):**
   - The script now includes retry logic (3 attempts)
   - If all retries fail, you can manually run the downloader:
   ```bash
   docker exec -it hytale-server bash
   cd /hytale
   wget https://downloader.hytale.com/hytale-downloader.zip
   unzip hytale-downloader.zip
   chmod +x hytale-downloader*
   ./hytale-downloader-linux-amd64 --download-path /tmp/server.zip
   ```

5. **Network/Firewall:**
   - Ensure your Unraid server can access `account-data.hytale.com`
   - Check if any firewall is blocking outbound HTTPS connections
   - Try using host network mode (add `--network host` to docker run, but this may affect port mappings)

6. **Wait and retry:**
   - Hytale services may be temporarily slow or unavailable
   - Wait 5-10 minutes and restart the container

### Server won't start
- Check logs: `docker logs hytale-server` or `docker logs -f hytale-server` (follow)
- Verify Java is installed: `docker exec hytale-server java -version`
- Check port 5520 is not in use: `netstat -un | grep 5520`

### Authentication issues
- Ensure you run `/auth login device` after first start
- Authentication may be required after server updates

### Memory issues
- Increase `JAVA_OPTS` memory settings
- Ensure Unraid has sufficient RAM allocated to Docker

### Port forwarding
- Ensure UDP port 5520 is forwarded on your router
- Check firewall rules on Unraid

## File Structure

```
.
├── Dockerfile              # Container image definition
├── entrypoint.sh          # Startup script
├── docker-compose.yml     # Docker Compose configuration
├── README.md              # This file
├── server/                # Server files (downloaded automatically)
│   └── HytaleServer.jar
├── assets/                # Assets directory
│   └── Assets.zip
└── universe/              # Universe directory (created on first run)
    ├── worlds/
    ├── config/
    └── logs/
```

## References

- [Hytale Server Manual](https://support.hytale.com/hc/en-us/articles/45326769420827-Hytale-Server-Manual#server-setup)
- [Hytale Downloader](https://downloader.hytale.com/hytale-downloader.zip)

## License

This Docker setup is provided as-is. Hytale and its server software are property of Hypixel Studios.

"# hytale-server" 
