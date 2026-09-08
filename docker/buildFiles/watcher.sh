#!/bin/sh

. /app/functions.sh

TRUENAS_APP_VPN="${TRUENAS_APP_VPN:-vpn}"
TRUENAS_APP_DEPENDANT="${TRUENAS_APP_DEPENDANT:-arr-apps}"
CONTAINER_WATCHING="${CONTAINER_WATCHING:-gluetun_torrent}"
FIRST_START=true




log "Surveillance du conteneur '${CONTAINER_WATCHING}' démarrée"

docker events --filter container="${CONTAINER_WATCHING}" --format "{{.Action}}" |

    while read -r result; do
        case "$result" in
            "stop")
                log "${CONTAINER_WATCHING} arrêté -> Arret des containers dépendants "
                if ! midclt_call app.stop "$TRUENAS_APP_DEPENDANT"; then
                    log "ERREUR: échec de app.stop ${TRUENAS_APP_DEPENDANT}"
                fi
                FIRST_START=false
                ;;
            "health_status: unhealthy")
                log "${CONTAINER_WATCHING} unhealthy -> Arret des containers dépendants "
                if ! midclt_call app.stop "$TRUENAS_APP_DEPENDANT"; then
                    log "ERREUR: échec de app.stop ${TRUENAS_APP_DEPENDANT}"
                fi
                FIRST_START=false
                ;;
            "health_status: healthy")
                if [ "$FIRST_START" = "false" ]; then
                    if qbit_status ; then
                        log "${CONTAINER_WATCHING} healthy -> Demarrage des containers dépendants "
                        if ! midclt_call app.start "$TRUENAS_APP_DEPENDANT"; then
                            log "ERREUR: échec de app.start ${TRUENAS_APP_DEPENDANT}"
                        fi
                    else
                        app_redeploy "$TRUENAS_APP_VPN"
                    fi
                fi
                ;;
        esac
    done
