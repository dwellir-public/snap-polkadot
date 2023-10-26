#!/bin/sh

. "$SNAP/utils/utils.sh"

set_tracing_enabled()
{
    snapctl set tracing-enabled="$1"
    set_previous_tracing_enabled "$1"
}

get_tracing_enabled()
{
    tracing_enabled="$(snapctl get tracing-enabled)"
    if [ -z "$tracing_enabled" ]; then
        log "Disabling tracing as default"
        # Don't use set_tracing_enabled() since it will not work when using snap unset
        snapctl set tracing-enabled="false"
    fi
    echo "$tracing_enabled"
}

is_tracing_enabled()
{
    [ "$(get_tracing_enabled)" = "true" ]
}

set_previous_tracing_enabled()
{
    snapctl set private.tracing-enabled="$1"
}

get_previous_tracing_enabled()
{
    snapctl get private.tracing-enabled
}

tracing_enabled_has_changed()
{
	[ "$(get_tracing_enabled)" != "$(get_previous_tracing_enabled)" ]
}

validate_tracing_enabled()
{
    if is_tracing_enabled; then
        case "$(get_service_args)" in 
        *rpc-methods*)
            log_message="It is not allowed to enable tracing when rpc-methods is set in the service-args configuration. Tracing requires unsafe rpc-methods which is set when tracing is enabled."
            log "$log_message"
            # Echo will be visible for a user if the configure hook fails when calling e.g. snap set SNAP_NAME service-args
            echo "$log_message"
            set_tracing_enabled "$(get_previous_tracing_enabled)"
            exit 1
            ;;
        esac
    fi
}
