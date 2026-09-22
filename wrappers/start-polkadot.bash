#!/bin/bash

# Enable strict mode
set -euo pipefail

source "$SNAP/utils/config.sh"
source "$SNAP/utils/utils.sh"

echo "=> Preparing the system for start snap revision: (${SNAP_REVISION})"

SERVICE_ARGS=$(<$__SERVICE_ARGS_FILE)
eval "SERVICE_ARGS_ARRAY=($SERVICE_ARGS)"

echo "=> Service arguments: ${SERVICE_ARGS}"

# Rewrite --chain=paseo to the bundled substitute-relay spec (the binary's
# built-in "paseo" spec is the retired pre-relaunch chain).
resolve_chain_spec_args RESOLVED_ARGS "${SERVICE_ARGS_ARRAY[@]}"
if [[ "${RESOLVED_ARGS[*]}" != "${SERVICE_ARGS_ARRAY[*]}" ]]; then
    echo "=> Using bundled Paseo chain spec: ${__PASEO_CHAIN_SPEC}"
fi

# Start the service with the specified parameters
exec "${__SERVICE_BINARY_PATH}" "${RESOLVED_ARGS[@]}"
