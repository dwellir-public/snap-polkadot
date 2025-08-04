#!/bin/sh

. "$SNAP/utils/utils.sh"

BASE_PATH="$SNAP_COMMON/polkadot_base"
SERVICE_ARGS_FILE="$SNAP_COMMON/service-arguments"
DEFAULT_SERVICE_ARGS="--base-path=$BASE_PATH --name=$(hostname)"

write_service_args_file()
{
    service_args="$(get_service_args)"
    log "Writing snap config \"$service_args\" to file: $SERVICE_ARGS_FILE"
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
        log "No service args found. Setting default service args: $DEFAULT_SERVICE_ARGS"
        service_args="$DEFAULT_SERVICE_ARGS"
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

#
# Description: Checks that the service-args handles --base-path=<path>
#              or --base-path <path>. It only allows those paths
#              accepted by removable-media interface or the default
#              snap directory $SNAP_COMMON/polkadot_base.
#
# Argument(s): A single string containing the service-args argument.
validate_service_args()
{
    log "Validating service-args argument: $@"

    # These paths are allowed.
    allowed_removable_media_paths="/mnt /media /run/media $SNAP_COMMON/polkadot_base"

    is_allowed_path() {
        local path="$1"
        for allowed_path in $allowed_removable_media_paths; do
            case "$path" in
                "$allowed_path"/* | "$allowed_path")
                    log "base-path $path is allowed."
                    return 0
                    ;;
            esac
        done
        log "base-path $path is NOT allowed. Use any of these: $allowed_removable_media_paths (Hint: sudo snap connect polkadot:removable-media)"
        echo "base-path $path is NOT allowed. Use any of these: $allowed_removable_media_paths (Hint: sudo snap connect polkadot:removable-media)"
        return 1
    }

    # Split arguments into words
    set -- $@

    while [ "$#" -gt 0 ]; do
        case "$1" in
            --base-path=*)
                base_path="${1#--base-path=}"
                ;;
            --base-path)
                shift
                if [ -z "$1" ]; then
                    log "No path specified for --base-path. No change was made to service-args."
                    set_service_args "$(get_previous_service_args)"
                    exit 1
                fi
                base_path="$1"
        esac

        if [ -n "$base_path" ]; then
            if ! is_allowed_path "$base_path"; then
                set_service_args "$(get_previous_service_args)"
                log "base-path $base_path is not allowed. Only snap default or those allowed by removable-media is allowed. No change was made to service-args."
                exit 1
            fi
            # Reset to avoid false positives in next loop iteration
            base_path=""
        fi

        shift
    done
}
