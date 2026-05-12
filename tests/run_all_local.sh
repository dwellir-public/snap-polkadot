#!/bin/bash

set -euo pipefail

readonly TESTS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${TESTS_DIR}/.." && pwd)"

SNAP_FILE="${1:-${POLKADOT_SNAP_FILE:-}}"
DOWNGRADE_REVISION="${2:-${POLKADOT_DOWNGRADE_REVISION:-}}"

if [[ -z "${SNAP_FILE}" ]]; then
    echo "Usage: bash tests/run_all_local.sh <snap-file> <downgrade-revision>" >&2
    echo "Alternatively set POLKADOT_SNAP_FILE and POLKADOT_DOWNGRADE_REVISION." >&2
    exit 1
fi

if [[ ! -f "${SNAP_FILE}" ]]; then
    echo "Snap file does not exist: ${SNAP_FILE}" >&2
    exit 1
fi

if [[ -z "${DOWNGRADE_REVISION}" ]]; then
    echo "A downgrade revision is required for the downgrade and endure tests." >&2
    exit 1
fi

if [[ ! "${DOWNGRADE_REVISION}" =~ ^[0-9]+$ ]]; then
    echo "Downgrade revision must be numeric: ${DOWNGRADE_REVISION}" >&2
    exit 1
fi

cleanup() {
    echo
    echo "==== Cleanup ===="
    sudo snap remove polkadot --purge >/dev/null 2>&1 || true
}

trap cleanup EXIT

run_step() {
    local label="$1"
    shift

    echo
    echo "==== ${label} ===="
    "$@"
}

run_runtime_test() {
    local label="$1"
    local chain="$2"
    local script_path="$3"

    run_step "${label}" env \
        POLKADOT_SNAP_FILE="${SNAP_FILE}" \
        POLKADOT_TEST_CHAIN="${chain}" \
        bash "${script_path}"
}

run_revision_test() {
    local label="$1"
    local script_path="$2"

    run_step "${label}" env \
        POLKADOT_SNAP_FILE="${SNAP_FILE}" \
        POLKADOT_DOWNGRADE_REVISION="${DOWNGRADE_REVISION}" \
        bash "${script_path}"
}

cd "${REPO_ROOT}"

run_step "Shellscript helper tests" bash tests/test_shellscripts.sh

run_runtime_test "Polkadot initial install" polkadot tests/test_initial_install.sh

run_step "Base-path validation" bash tests/test_base_path.sh

run_revision_test "Polkadot downgrade" tests/test_downgrade.sh

run_runtime_test "Polkadot initial install before endure" polkadot tests/test_initial_install.sh

run_revision_test "Polkadot endure" tests/test_endure.sh

for chain in kusama westend paseo; do
    run_runtime_test "Basic install ${chain}" "${chain}" tests/test_basic_install.sh
done
