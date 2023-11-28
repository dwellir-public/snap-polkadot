#!/bin/bash
set -eu

echo "=> Preparing the system  (${SNAP_REVISION})"

SERVICE_ARGS_FILE="$SNAP_COMMON/service-arguments"
POLKADOT_BINARY_PATH="${SNAP}/bin/polkadot"

SERVICE_ARGS=$(<$SERVICE_ARGS_FILE)
eval "SERVICE_ARGS_ARRAY=($SERVICE_ARGS)"

echo "=> Service arguments: ${SERVICE_ARGS}"
# Start the service with the specified parameters
exec "${POLKADOT_BINARY_PATH}" "${SERVICE_ARGS_ARRAY[@]}"
