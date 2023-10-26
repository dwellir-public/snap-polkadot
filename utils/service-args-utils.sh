#!/bin/sh

. "$SNAP/utils/utils.sh"

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
        *wasm-runtime-overrides*)
            log_message="wasm-runtime-overrides is not allowed to pass as a service argument restoring to last used service-args. This is set when enabling tracing to use the correct runtime override."
            log "$log_message"
            # Echo will be visible for a user if the configure hook fails when calling e.g. snap set SNAP_NAME service-args
            echo "$log_message"
            set_service_args "$(get_previous_service_args)"
            exit 1
            ;;
        *rpc-methods*)
            if is_tracing_enabled; then
                log_message="rpc-methods is not allowed when tracing is enabled. Tracing requires unsafe rpc-methods which is set when tracing is enabled."
                log "$log_message"
                # Echo will be visible for a user if the configure hook fails when calling e.g. snap set SNAP_NAME service-args
                echo "$log_message"
                set_service_args "$(get_previous_service_args)"
                exit 1
            fi
            ;;
        esac
}
