#!/bin/sh

echo "VPN-Watcher version: ${CONTAINER_BUILD_VERSION}"


##################################
## CHECK IF ENVIRONMENT VARIABLES ARE CONFIGURED
##################################
echo "Initialization.."
EMPTY_ENV=""
if [ -z "$TRUENAS_IP" ]; then
    EMPTY_ENV=$EMPTY_ENV"TRUENAS_IP "
fi
if [ -z "$TRUENAS_USER" ]; then
    EMPTY_ENV=$EMPTY_ENV"TRUENAS_USER "
fi
if [ -z "$TRUENAS_API_KEY" ]; then
    EMPTY_ENV=$EMPTY_ENV"TRUENAS_API_KEY "
fi
if [ -z "$QBITTORRENT_URLPORT" ]; then
    EMPTY_ENV=$EMPTY_ENV"QBITTORRENT_URLPORT "
fi
if [ -z "$QBITTORRENT_API_KEY" ]; then
    EMPTY_ENV=$EMPTY_ENV"QBITTORRENT_API_KEY "
fi
if [ -z "$TRUENAS_APP_VPN" ]; then
    EMPTY_ENV=$EMPTY_ENV"TRUENAS_APP_VPN "
fi
if [ -z "$TRUENAS_APP_DEPENDANT" ]; then
    EMPTY_ENV=$EMPTY_ENV"TRUENAS_APP_DEPENDANT "
fi
if [ -z "$CONTAINER_WATCHING" ]; then
    EMPTY_ENV=$EMPTY_ENV"TRUENAS_APP_DEPENDANT "
fi

for var in $EMPTY_ENV; do
    echo "Environment variable $var is not assigned. Please configure it before restarting the container."
done
if ! [ -z "$EMPTY_ENV" ]; then
    echo "Shutting down.."
    sleep 5
    exit 1
fi


##################################
## INSTALL CRON JOB
##################################
# Add task to cron file
echo "0 * * * * /app/croncheck_qbit_status.sh" > /etc/crontabs/root
# Start cron deamon in background after 1h of first start
sleep 3600 && crond -f &


##################################
## START WATCHER
##################################
echo "Initialization complete"
exec /app/watcher.sh
