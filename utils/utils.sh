#!/bin/sh

BASE_PATH="$SNAP_COMMON/polkadot_base"
SERVICE_ARGS_FILE="$SNAP_COMMON/service-arguments"
DEFAULT_CHAIN="polkadot"

# Logs to journalctl. Watch with e.g. journalctl -t SNAP_NAME -f
log()
{
    logger -t ${SNAP_NAME} "$1"
}

restart_polkadot()
{
    polkadot_status="$(snapctl services polkadot)"
    current_status=$(echo "$polkadot_status" | awk 'NR==2 {print $3}')
    if [ "$current_status" = "active" ]; then
        snapctl restart polkadot
    fi
}

get_configured_chain()
{
    input_string="$1"
    chain_value=""

    # Use basic string manipulation to extract the value after "--chain"
    rest_of_string="${input_string#*--chain=}"
    if [ "$rest_of_string" = "$input_string" ]; then
        rest_of_string="${input_string#*--chain }"
    fi

    if [ "$rest_of_string" != "$input_string" ]; then
        chain_value="${rest_of_string%% *}"
    else
        log "No chain specified in service arg. Defaulting to $DEFAULT_CHAIN."
        chain_value=$DEFAULT_CHAIN
    fi
    echo $chain_value
}

write_service_args_file()
{
    service_args="--base-path=$BASE_PATH $(get_service_args)"
    if is_tracing_enabled; then
        service_args="--base-path=$BASE_PATH --rpc-methods=unsafe --wasm-runtime-overrides=$SNAP/$(get_configured_chain)-runtime-with-traces/ $(get_service_args)"
    fi
    log "Writing \"$service_args\" to $SERVICE_ARGS_FILE"
    echo "$service_args" > "$SERVICE_ARGS_FILE"
}
