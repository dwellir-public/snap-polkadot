#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/test-helpers.bash"

echo "Running endure tests"

downgrade_revision="${POLKADOT_DOWNGRADE_REVISION:-}"
if [[ -z "${downgrade_revision}" ]]; then
    current_revision="$(get_installed_revision)"
    downgrade_revision="$(find_previous_available_revision "${current_revision}")"
fi

run_node_status_checks

before_refresh_pid="$(get_service_pid)"

sudo snap set polkadot endure=true
sudo snap refresh polkadot --revision="${downgrade_revision}"

after_refresh_pid="$(get_service_pid)"
if [[ "${before_refresh_pid}" != "${after_refresh_pid}" ]]; then
    echo "Polkadot service restarted during refresh even though endure=true." >&2
    exit 1
fi

assert_logs_contain "Endure is enabled, not restarting service."
assert_logs_do_not_contain "Preparing the system for start snap revision: (${downgrade_revision})"
assert_rpc_version_differs_from_installed

sudo snap restart polkadot
wait_for_polkadot_service

after_manual_restart_pid="$(get_service_pid)"
if [[ "${after_refresh_pid}" == "${after_manual_restart_pid}" ]]; then
    echo "Polkadot service PID did not change after a manual restart." >&2
    exit 1
fi

assert_rpc_version_matches_installed
assert_logs_contain "Preparing the system for start snap revision: (${downgrade_revision})"
