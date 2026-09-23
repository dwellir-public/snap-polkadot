#!/bin/bash

# Enable strict mode
set -euo pipefail

source "$SNAP/utils/config.sh"

echo "=> Preparing the system for start snap revision: (${SNAP_REVISION})"

SERVICE_ARGS=$(<$__SERVICE_ARGS_FILE)
eval "SERVICE_ARGS_ARRAY=($SERVICE_ARGS)"

echo "=> Service arguments: ${SERVICE_ARGS}"
# Start the service with the specified parameters
exec "${__SERVICE_BINARY_PATH}" "${SERVICE_ARGS_ARRAY[@]}"
