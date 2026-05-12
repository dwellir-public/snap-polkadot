#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/test-helpers.bash"

echo "Running downgrade tests"

downgrade_revision="${POLKADOT_DOWNGRADE_REVISION:-}"
if [[ -z "${downgrade_revision}" ]]; then
    current_revision="$(get_installed_revision)"
    downgrade_revision="$(find_previous_available_revision "${current_revision}")"
fi

echo "Refreshing polkadot to revision ${downgrade_revision}"
sudo snap refresh polkadot --revision="${downgrade_revision}"
sudo snap restart polkadot

wait_for_polkadot_service
run_node_status_checks
assert_logs_contain "Preparing the system for start snap revision: (${downgrade_revision})"
