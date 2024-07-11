#!/bin/sh

# Logs to journalctl. Watch with e.g. journalctl -t SNAP_NAME -f
log()
{
    logger -t ${SNAP_NAME} -- "$1"
}

restart_polkadot()
{
    polkadot_status="$(snapctl services polkadot)"
    current_status=$(echo "$polkadot_status" | awk 'NR==2 {print $3}')
    if [ "$current_status" = "active" ]; then
        snapctl restart polkadot
    fi
}
