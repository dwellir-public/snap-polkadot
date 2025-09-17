#!/bin/bash

# Enable strict mode
set -euo pipefail

# Load configuration
source "$SNAP/utils/config.sh"

# =======================
# Logging and Service Control
# =======================

# Logs to journalctl. Watch with e.g. journalctl -t SNAP_NAME -f
log() {
    logger -t "${SNAP_NAME}" -- "$*"
}

restart_service() {
    local service_status current_status
    service_status="$(snapctl services "${__SERVICE_NAME}")"
    current_status=$(grep -Po '(?<=Active: )[a-z]+' <<< "$service_status" || true)
    
    if [[ "$current_status" == "active" ]]; then
        log "Restarting ${__SERVICE_NAME} service"
        snapctl restart "${__SERVICE_NAME}" || {
            log "Failed to restart ${__SERVICE_NAME} service"
            return 1
        }
    fi
}

# =======================
# Service Arguments Management
# =======================

write_service_args_file() {
    local service_args
    service_args="$(get_service_args)"
    log "Writing snap config \"$service_args\" to file: $__SERVICE_ARGS_FILE"
    echo "$service_args" > "$__SERVICE_ARGS_FILE"
}

set_service_args() {
    [[ -z "$1" ]] && { log "Error: No service arguments provided"; return 1; }
    snapctl set "service-args=$1"
    set_previous_service_args "$1"
}

get_service_args() {
    local service_args
    service_args="$(snapctl get service-args 2>/dev/null || true)"
    
    if [[ -z "$service_args" ]]; then
        log "No service args found. Setting default service args: $__DEFAULT_SERVICE_ARGS"
        service_args="$__DEFAULT_SERVICE_ARGS"
        snapctl set "service-args=$service_args"
    fi
    echo "$service_args"
}

set_previous_service_args() {
    snapctl set "private.service-args=$1"
}

get_previous_service_args() {
    snapctl get private.service-args
}

service_args_has_changed() {
    [[ "$(get_service_args)" != "$(get_previous_service_args)" ]]
}

# =======================
# Endure Mode Management
# =======================

set_endure() {
    local value="${1,,}"  # Convert to lowercase using bash parameter expansion
    if [[ ! "$value" =~ ^(true|false)$ ]]; then
        log "Error: endure must be either 'true' or 'false', got: $1"
        return 1
    fi
    snapctl set "endure=$value"
    set_previous_endure "$value"
}

get_endure() {
    local endure
    endure="$(snapctl get endure 2>/dev/null || true)"
    
    if [[ -z "$endure" ]]; then
        log "Setting endure to false as default"
        # Don't use set_endure() since it will not work when using snap unset
        snapctl set "endure=false"
        endure="false"
    fi
    echo "$endure"
}

endure() {
    [[ "$(get_endure)" == "true" ]]
}

set_previous_endure() {
    snapctl set "private.endure=$1"
}

get_previous_endure() {
    snapctl get private.endure
}

endure_has_changed() {
    [[ "$(get_endure)" != "$(get_previous_endure)" ]]
}

# =======================
# Path Validation
# =======================

# Description: Validates that the service-args handles --base-path=<path>
#              or --base-path <path>. It only allows those paths
#              accepted by removable-media interface or the default
#              snap directory $SNAP_COMMON/polkadot_base.
validate_service_args() {
    log "Validating service-args argument: $*"
    
    local allowed_removable_media_paths=(
        "/mnt"
        "/media"
        "/run/media"
        "${SNAP_COMMON}/polkadot_base"
    )

    remove_quotes() {
        local str="$1"
        # Remove leading and trailing quotes (both single and double)
        str="${str#[\"\']}"
        str="${str%[\"\']}"
        echo "$str"
    }

    is_allowed_path() {
        local path="$1"

        # Check if path is under SNAP_COMMON
        case "$path" in
            "$SNAP_COMMON"/* | "$SNAP_COMMON" | "$SNAP_COMMON"/ )
                log "base-path $path is allowed (under SNAP_COMMON)."
                return 0
                ;;
        esac

        # Check if path is under any of the allowed removable media paths
        local allowed_removable_media_paths=(
                "/mnt"
                "/media"
                "/run/media"
            )
        for allowed_path in "${allowed_removable_media_paths[@]}"; do
            case "$path" in
                "$allowed_path"/* | "$allowed_path" | "$allowed_path"/ )
                    log "base-path $path is allowed."
                    return 0
                    ;;
            esac
        done
        log "base-path $path is NOT allowed. Use any of these: ${SNAP_COMMON} ${allowed_removable_media_paths[*]} (Hint: sudo snap connect polkadot:removable-media)"
        echo "base-path $path is NOT allowed. Use any of these: ${SNAP_COMMON} ${allowed_removable_media_paths[*]} (Hint: sudo snap connect polkadot:removable-media)"
        return 1
    }

    local service_args="$1"
    set -- $service_args  # This splits the arguments for processing

    local base_path=""
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --base-path=*)
                base_path=$(remove_quotes "${1#--base-path=}")
                ;;
            --base-path)
                shift
                if [ -z "$1" ]; then
                    log "No path specified for --base-path. No change was made to service-args."
                    set_service_args "$(get_previous_service_args)"
                    exit 1
                fi
                base_path=$(remove_quotes "$1")
                ;;
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
