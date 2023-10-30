#!/bin/sh

. "$SNAP/utils/utils.sh"

BASE_PATH="$SNAP_COMMON/polkadot_base"
SERVICE_ARGS_FILE="$SNAP_COMMON/service-arguments"

write_service_args_file()
{
    service_args="--base-path=$BASE_PATH $(get_service_args)"
    log "Writing \"$service_args\" to $SERVICE_ARGS_FILE"
    echo "$service_args" > "$SERVICE_ARGS_FILE"
}

set_service_args()
{
    snapctl set service-args="$1"
    set_previous_service_args "$1"
}

get_service_args()
{
    service_args="$(snapctl get service-args)"
    if [ -z "$service_args" ]; then
        log "Setting default service args"
        service_args="--name=$(hostname)"
        # Don't use set_service_args() since it will not work when using snap unset
        snapctl set service-args="$service_args"
    fi
    echo "$service_args"
}

set_previous_service_args()
{
    snapctl set private.service-args="$1"
}

get_previous_service_args()
{
    snapctl get private.service-args
}

service_args_has_changed()
{
	[ "$(get_service_args)" != "$(get_previous_service_args)" ]
}

validate_service_args()
{
    case "$1" in 
        *base-path*)
            log_message="base-path is not allowed to pass as a service argument restoring to last used service-args. This path is alywas used instead ${BASE_PATH}."
            log "$log_message"
            # Echo will be visible for a user if the configure hook fails when calling e.g. snap set SNAP_NAME service-args
            echo "$log_message"
            set_service_args "$(get_previous_service_args)"
            exit 1
            ;;
        esac
}
