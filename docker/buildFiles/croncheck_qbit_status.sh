#!/bin/sh
. /app/functions.sh

TRUENAS_APP_VPN="${TRUENAS_APP_VPN:-vpn}"

if ! qbit_status ; then
    app_redeploy "$TRUENAS_APP_VPN"
fi
