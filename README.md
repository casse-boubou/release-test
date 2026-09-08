# vpn-watcher

VPN-Watcher is a Docker container designed for Truenas that monitors the Gluetun and qBitTorrent containers in order to start or restart the Arr stack containers that are configured to use the Gluetun VPN network.

When the Gluetun VPN container is stopped or restarted in Truenas, containers configured with `network_mode: “container:gluetun”` lose their network connection and are unable to reconnect after Gluetun restarts. It is therefore necessary to restart the stack (Truenas app) with the services configured as `network_mode: “container:gluetun”`.

## What it does

- Start the Arr stack (Truenas app) when the Gluetun VPN is healthy

- Stop the Arr stack (Truenas app) when the Gluetun VPN is unhealthy or shut down

- Monitor the qBitTorrent connection status to restart the VPN and the Arr stack (Truenas app) if the connection is lost in qBitTorrent

## How It Works

VPN-Watcher monitors `Docker events` on the Gluetun container to see if it has been stopped or started. This allows it to make an `API call to Truenas` to stop or start the Arr stack (Truenas app).

Upon startup, and then periodically every hour, VPN-Watcher also makes an `API call to qBitTorrent` to check its VPN connection status; if, after a one-minute cooldown, qBitTorrent still has no connection, VPN-Watcher restarts the Gluetun container.

# Installation

### First step

First, you'll need to have the [Gluetun](https://github.com/passteque/gluetun) and qBitTorrent containers in one stack (Truenas app) configured to work together.
You can configure it using the documentation here [wiki](https://github.com/qdm12/gluetun-wiki).

###### *You can also configure the ports now for other services that you'll connect to the Gluetun VPN (such as ARR apps, for example)*

```yaml
services:
  gluetun:
    container_name: gluetun
    ....
    ports:
      - ${qbittorrent_WebUI_EXTERNAL_PORT}:${qbittorrent_WebUI_PORT}      # port for qbittorrent container
      - ${prowlarr_EXTERNAL_PORT}:${prowlarr_PORT}                        # port for Prowlarr container
      - ${autobrr_EXTERNAL_PORT}:${autobrr_PORT}                          # port for Autobrr container
      - ${radarr_EXTERNAL_PORT}:${radarr_PORT}                            # port for Radarr container
      - ${sonarr_EXTERNAL_PORT}:${sonarr_PORT}                            # port for Sonarr container
  qbittorrent:
    depends_on:
      gluetun:
        condition: service_healthy
    ....
    network_mode: service:gluetun # run on the vpn network
```

Next, you'll need to have the ARR suite you want in another stack (Truenas app) and configure it to work with the Gluetun VPN.

```yaml
services:
  prowlarr:
    ....
    network_mode: "container:gluetun"
  radarr:
    ....
    network_mode: "container:gluetun"
  sonarr:
    ....
    network_mode: "container:gluetun"
  autobrr:
    ....
    network_mode: "container:gluetun"
```

### Second step

Make sure that VPN-Watcher and Gluetun are on the same network so they can communicate. You can create this network in your Docker Compose file that contains the Gluetun VPN.

```yaml
networks:
  internal_vpn_gluetun:
    internal: true

services:
  gluetun:
    ....
    networks:
      - internal_vpn_gluetun
```

### Third step

- Add vpn_watcher to a `docker-compose.yml`.

```yaml
networks:
  internal_vpn_gluetun:
    external: true

services:
  vpn_watcher:
    container_name: vpn_watcher
    image: ghcr.io/casse-boubou/vpn-watcher:latest
    restart: unless-stopped
    security_opt:
      - no-new-privileges=true
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 128M
    environment:
      - TZ=Etc/UTC
      - TRUENAS_IP=${NENYA_IP}                                            # IP of Truenas instance
      - TRUENAS_USER=TRUENAS_USERNAME                                     # required for version 26+
      - TRUENAS_API_KEY=${TrueNas_API_KEY}                                # require to interact with the truenas api
      - QBITTORRENT_URLPORT=http://gluetun:${qbittorrent_WebUI_PORT}      # address at which qBitTorrent can be reached through the VPN
      - QBITTORRENT_API_KEY=${qbittorrent_API_KEY}                        # API_KEY for qBitTorrent WebUI
      - TRUENAS_APP_VPN=vpn                                               # name of the app containing the Gluetun container in Truenas
      - TRUENAS_APP_DEPENDANT=arr-apps                                    # name of the app containing the Gluetun network dependant in Truenas
      - CONTAINER_WATCHING=gluetun                                        # name of the Gluetun container
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    networks:
      - internal_vpn_gluetun
```

# Configuration Options

## Required

### Grants access to the Docker socket

Access to the `Docker socket` is required to listen for events. You can also use Docker-Socket-Proxy like [linuxserver.io socket-proxy](https://docs.linuxserver.io/images/docker-socket-proxy).

```yaml
services:
  vpn_watcher:
    ....
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
```

### Configure environment

Environment variables are required and must be configured as follows:

```yaml
services:
  vpn_watcher:
    ....
    environment:
      - TRUENAS_IP=${NENYA_IP}                                            # IP of Truenas instance
      - TRUENAS_USER=TRUENAS_USERNAME                                     # required for version 26+
      - TRUENAS_API_KEY=${TrueNas_API_KEY}                                # require to interact with the truenas api
      - QBITTORRENT_URLPORT=http://gluetun:${qbittorrent_WebUI_PORT}      # address at which qBitTorrent can be reached through the VPN
      - QBITTORRENT_API_KEY=${qbittorrent_API_KEY}                        # API_KEY for qBitTorrent WebUI
      - TRUENAS_APP_VPN=vpn                                               # name of the app containing the Gluetun container in Truenas
      - TRUENAS_APP_DEPENDANT=arr-apps                                    # name of the app containing the Gluetun network dependant in Truenas
      - CONTAINER_WATCHING=gluetun                                        # name of the Gluetun container
```

## Optional

### Limit the resources allocated to the container

VPN-Watcher is just a monitoring tool and doesn't require many resources (15–30 MB). You can therefore limit the resources allocated to the container

```yaml
services:
  vpn_watcher:
    ....
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 128M
```

### Healthcheck

The container includes a built-in healthcheck.
By default, it is configured to be checked every 30 seconds.

You can fully customize or override the healthcheck in your docker-compose.yml.

```yaml
services:
  vpn_watcher:
    ....
    healthcheck:
      test: ["CMD", "sh", "healthcheck"]
      interval: 10m
      timeout: 30s
      retries: 10
      start_period: 60s
      start_interval: 5s
```
