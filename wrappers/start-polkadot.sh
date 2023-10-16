#!/bin/sh
set -eu

echo "=> Preparing the system  (${SNAP_REVISION})"

SERVICE_ARGS_FILE="$SNAP_COMMON/service-arguments"
# SERVICE_ARGS=$(tr '\n' ' ' < "$SERVICE_ARGS_FILE")
SERVICE_ARGS=$(cat "$SERVICE_ARGS_FILE")
#POLKADOT_BINARY_PATH="${SNAP}/bin/polkadot"
POLKADOT_BINARY_PATH="$SNAP/files/polkadot"


echo "=> Service arguments: ${SERVICE_ARGS}"
# TODO something in this code interprets quotes wrong making it impossible to pass strings with spaces e.g. --name "node name"
# Start the service with the specified parameters
exec "${POLKADOT_BINARY_PATH}" $SERVICE_ARGS
