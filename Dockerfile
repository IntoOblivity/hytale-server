FROM eclipse-temurin:25-jre

LABEL maintainer="Hytale Server Docker"
LABEL description="Hytale Server with Java 25 (Temurin) and Hytale Downloader"

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /hytale

# Create directories for server files, assets, and persistent data
RUN mkdir -p /hytale/server /hytale/assets /hytale/universe /hytale/downloader

# Copy entrypoint script
COPY entrypoint.sh /hytale/entrypoint.sh
RUN chmod +x /hytale/entrypoint.sh

# Note: If you have a local downloader executable, you can mount it as a volume
# Example: -v /path/to/hytale-downloader:/hytale/downloader/hytale-downloader-linux-amd64
# Or place it in your project directory and mount the parent directory
# The entrypoint script will check for local downloader first before downloading

# Expose default UDP port for Hytale server (QUIC over UDP)
EXPOSE 5520/udp

# Default environment variables
ENV JAVA_OPTS="-Xms4G -Xmx4G"

# Volumes for persistent data
VOLUME ["/hytale/server", "/hytale/assets", "/hytale/universe"]

ENTRYPOINT ["/hytale/entrypoint.sh"]
CMD []

