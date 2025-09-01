#!/bin/bash

# Prevent multiple sourcing
if [ -z "${__CONFIG_LOADED:-}" ]; then
    # =======================
    # File and Path Configuration
    # =======================
    # Default directory for polkadot data
    __DEFAULT_DATA_PATH="$SNAP_COMMON/polkadot_base"
    readonly __DEFAULT_DATA_PATH

    # Service configuration files
    __SERVICE_ARGS_FILE="$SNAP_COMMON/service-arguments"
    readonly __SERVICE_ARGS_FILE

    # =======================
    # Service Defaults
    # =======================
    # Service binary path
    __SERVICE_BINARY_PATH="${SNAP}/bin/polkadot"
    readonly __SERVICE_BINARY_PATH

    # Default service arguments
    __DEFAULT_SERVICE_ARGS="--base-path=$__DEFAULT_DATA_PATH"
    readonly __DEFAULT_SERVICE_ARGS

    # Default endure mode setting
    __DEFAULT_ENDURE="false"
    readonly __DEFAULT_ENDURE

    # Service name for systemd
    __SERVICE_NAME="polkadot"
    readonly __SERVICE_NAME

    # Mark as loaded
    __CONFIG_LOADED=1
    readonly __CONFIG_LOADED
fi
