# Hytale Server Docker Setup for Unraid

This Docker setup allows you to run a Hytale server on Unraid using the official Hytale Downloader and Java 25 (Eclipse Temurin).

## Requirements

- **Java**: Java 25 (Eclipse Temurin) - installed in container
- **RAM**: Minimum 4GB (higher recommended for more players)
- **Port**: UDP 5520 (default Hytale server port)
- **Storage**: Space for server files and world data

## Quick Start

### Using Docker Compose

1. **Clone or download this repository** to your Unraid server

2. **Build and start the container:**
   ```bash
   docker-compose up -d
   ```

3. **View logs:**
   ```bash
   docker-compose logs -f
   ```

### Manual Docker Build

1. **Build the image:**
   ```bash
   docker build -t hytale-server:latest .
   ```

2. **Run the container:**
   ```bash
   docker run -d \
     --name hytale-server \
     --restart unless-stopped \
     -p 5520:5520/udp \
     -v ./data:/hytale/data \
     -v ./server:/hytale/server \
     -e JAVA_OPTS="-Xms4G -Xmx4G" \
     hytale-server:latest
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
   - `/mnt/user/appdata/hytale/server` → `/hytale/server`
   - `/mnt/user/appdata/hytale/assets` → `/hytale/assets`
   - `/mnt/user/appdata/hytale/universe` → `/hytale/universe`
   - **Environment Variables**:
     - `JAVA_OPTS` = `-Xms4G -Xmx4G` (adjust based on your server RAM)

3. **Click Apply** to start the container

### Using Docker Compose Plugin (if installed)

1. Place `docker-compose.yml` in your desired location (e.g., `/mnt/user/appdata/hytale/`)
2. Update volume paths in `docker-compose.yml` to use Unraid paths:
   ```yaml
   volumes:
     - /mnt/user/appdata/hytale/server:/hytale/server
     - /mnt/user/appdata/hytale/assets:/hytale/assets
     - /mnt/user/appdata/hytale/universe:/hytale/universe
   ```
3. Run via Unraid's Docker Compose plugin or via terminal:
   ```bash
   docker-compose up -d
   ```

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

1. Update the port mapping in docker-compose.yml or Unraid GUI
2. Update the `--bind` parameter in `entrypoint.sh` if needed

### Persistent Data

The Docker setup uses three persistent volumes:

- **`/hytale/server`** - Server JAR files and server-related files
- **`/hytale/assets`** - Assets.zip file
- **`/hytale/universe`** - World files, server configuration, logs, player data

For Unraid, these map to:
- `/mnt/user/appdata/hytale/server`
- `/mnt/user/appdata/hytale/assets`
- `/mnt/user/appdata/hytale/universe`

## Updating Server Files

The container automatically downloads server files on first run. To update:

1. **Option 1**: Delete server files and restart
   ```bash
   rm -rf ./server/*
   docker-compose restart
   ```

2. **Option 2**: Manually use the downloader inside the container
   ```bash
   docker exec -it hytale-server hytale-downloader --download-path /tmp/update.zip
   ```

## Troubleshooting

### Server won't start
- Check logs: `docker-compose logs hytale-server`
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
