#!/bin/sh
set -eu

echo "=> Preparing the system  (${SNAP_REVISION})"

# shellcheck disable=SC2155
export SNAP_CURRENT="$(realpath "${SNAP}/..")/current"

# Create a config if its missing.
if [ ! -f "${SNAP_COMMON}/service-arguments" ]; then
    echo "==> Creating basic service argument file ${SNAP_COMMON}/service-arguments"
    echo "--name=Unspecified_Dwellir_node" > "${SNAP_COMMON}/service-arguments"
    chmod 0644 "${SNAP_COMMON}/service-arguments"
fi

# Read the system wide configuration file
echo "=> Using service argument file: ${SNAP_COMMON}/service-arguments"

SERVICE_ARGS_FILE="$SNAP_COMMON/service-arguments"
# SERVICE_ARGS=$(tr '\n' ' ' < "$SERVICE_ARGS_FILE")
SERVICE_ARGS=$(cat "$SERVICE_ARGS_FILE")

echo "=> Service arguments: ${SERVICE_ARGS}"
# Start the service with the specified parameters
POLKADOT="${SNAP}/bin/polkadot"
# TODO something in this code interprets quotes wrong making it impossible to pass strings with spaces e.g. --name "node name"
exec "${POLKADOT}" $SERVICE_ARGS

