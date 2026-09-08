#!/bin/sh

TRUENAS_URI="wss://${TRUENAS_IP}/api/current"
TRUENAS_USER="${TRUENAS_USER:-}"
API_PATH=/api/v2/transfer/info
API_URL_REQUEST="$QBITTORRENT_URLPORT""$API_PATH"
TIME_MAX=60         # Time for qBitTorrent to start


log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

midclt_call() {
    if [ -n "$TRUENAS_USER" ]; then
        midclt --uri "$TRUENAS_URI" --insecure  --username "$TRUENAS_USER" --api-key "$TRUENAS_API_KEY" --plain call --job "$@"
    else
        midclt --uri "$TRUENAS_URI" --insecure  --api-key "$TRUENAS_API_KEY" call --job "$@"
    fi
}

call_qbit_api() {
    # POSSIBLE VALUE
    # connected         green planet in WebUI
    # firewalled        yellow/orange planet in WebUI
    # disconnected      red planet in WebUI
    STATUS=$(wget -qO- --header="Authorization: Bearer ${QBITTORRENT_API_KEY}" "$API_URL_REQUEST" | jq -r '.connection_status')
    echo "$STATUS"
}

qbit_status() {
    TIME_SINCE_START=0
    if ! [ "$( call_qbit_api )" = "connected" ]; then
        log "Grep qBitTorrent status.."
        while test $TIME_SINCE_START -lt $TIME_MAX; do
            sleep 2
            TIME_SINCE_START=$(( TIME_SINCE_START + 2))
            if [ "$( call_qbit_api )" = "connected" ]; then
                log "qBitTorrent is connected"
                break
            fi
            log "qBitTorrent status is not connected (green planet). Retrying..."
        done

        if test $TIME_SINCE_START -ge $TIME_MAX; then
            log "qBitTorrent seems unable to connect. Restarting the VPN..."
            return 1
        fi
        return 0
    fi
}

app_redeploy() {
    if ! midclt_call app.redeploy "$1"; then
        log "ERREUR: échec de app.redeploy ${1}"
    fi
}
