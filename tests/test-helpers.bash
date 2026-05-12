#!/bin/bash

set -euo pipefail

readonly TESTS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly STATUS_CHECKER="${TESTS_DIR}/check_node_status.py"
readonly POLKADOT_SNAP_NAME="${POLKADOT_SNAP_NAME:-polkadot}"
readonly POLKADOT_SNAP_SERVICE="snap.${POLKADOT_SNAP_NAME}.polkadot.service"

cleanup_polkadot_snap() {
    sudo snap remove "${POLKADOT_SNAP_NAME}" --purge >/dev/null 2>&1 || true
}

install_polkadot_snap() {
    if [[ -n "${POLKADOT_INSTALL_REVISION:-}" ]]; then
        sudo snap install "${POLKADOT_SNAP_NAME}" --revision="${POLKADOT_INSTALL_REVISION}"
        return 0
    fi

    if [[ -n "${POLKADOT_INSTALL_CHANNEL:-}" ]]; then
        sudo snap install "${POLKADOT_SNAP_NAME}" --channel="${POLKADOT_INSTALL_CHANNEL}"
        return 0
    fi

    echo "POLKADOT_INSTALL_REVISION or POLKADOT_INSTALL_CHANNEL must be set." >&2
    return 1
}

check_polkadot_service_running() {
    echo "Checking if Polkadot service is running..."

    if snap services "${POLKADOT_SNAP_NAME}" | awk '$1 == "polkadot.polkadot" && $3 == "active" { found=1 } END { exit(found ? 0 : 1) }'; then
        echo "Polkadot service is running."
        return 0
    fi

    echo "Polkadot service is not running."
    return 1
}

wait_for_polkadot_service() {
    local timeout="${1:-90}"
    local interval=2
    local elapsed=0

    echo "Waiting for Polkadot RPC to start on port 9933..."

    while (( elapsed < timeout )); do
        if nc -z localhost 9933 >/dev/null 2>&1; then
            echo "Polkadot RPC is listening on port 9933."
            return 0
        fi

        sleep "${interval}"
        elapsed=$((elapsed + interval))
        echo "Still waiting after ${elapsed}s"
    done

    echo "Timed out waiting for the Polkadot RPC port."
    return 1
}

run_node_status_checks() {
    python3 "${STATUS_CHECKER}"
}

get_installed_revision() {
    snap info --verbose "${POLKADOT_SNAP_NAME}" | awk '/installed:/ { gsub(/[()]/, "", $3); print $3; exit }'
}

find_previous_available_revision() {
    local current_revision="${1:-$(get_installed_revision)}"
    local max_probe_depth="${POLKADOT_REVISION_PROBE_DEPTH:-25}"
    local candidate_revision temp_dir basename

    temp_dir="$(mktemp -d)"
    trap 'rm -rf "${temp_dir}"' RETURN

    for ((offset = 1; offset <= max_probe_depth; offset++)); do
        candidate_revision=$((current_revision - offset))
        if ((candidate_revision <= 0)); then
            break
        fi

        basename="revision-probe-${candidate_revision}"
        if snap download "${POLKADOT_SNAP_NAME}" \
            --revision="${candidate_revision}" \
            --basename="${basename}" \
            --target-directory="${temp_dir}" >/dev/null 2>&1; then
            echo "${candidate_revision}"
            return 0
        fi
    done

    echo "Unable to find a lower published revision for ${POLKADOT_SNAP_NAME} below ${current_revision}." >&2
    return 1
}

get_service_pid() {
    systemctl show --property MainPID --value "${POLKADOT_SNAP_SERVICE}"
}

get_snap_version() {
    snap info "${POLKADOT_SNAP_NAME}" | awk '/installed:/ { print $2; exit }'
}

get_rpc_version() {
    curl -fsS \
        -H "Content-Type: application/json" \
        -d '{"id":1,"jsonrpc":"2.0","method":"system_version"}' \
        http://localhost:9933 | python3 -c 'import json, sys; print(json.load(sys.stdin)["result"])'
}

get_snap_logs() {
    sudo snap logs "${POLKADOT_SNAP_NAME}" -n all --abs-time
}

assert_logs_contain() {
    local pattern="$1"

    if get_snap_logs | grep -Fq -- "${pattern}"; then
        echo "Snap logs contain expected text: ${pattern}"
        return 0
    fi

    echo "Snap logs do not contain expected text: ${pattern}" >&2
    return 1
}

assert_logs_do_not_contain() {
    local pattern="$1"

    if get_snap_logs | grep -Fq -- "${pattern}"; then
        echo "Snap logs unexpectedly contain text: ${pattern}" >&2
        return 1
    fi

    echo "Snap logs do not contain forbidden text: ${pattern}"
    return 0
}

assert_rpc_version_matches_installed() {
    local snap_version rpc_version normalized_snap_version

    snap_version="$(get_snap_version)"
    rpc_version="$(get_rpc_version)"
    normalized_snap_version="${snap_version#v}"

    if [[ "${rpc_version}" == "${normalized_snap_version}"* ]]; then
        echo "RPC version matches installed snap version: ${rpc_version} vs ${snap_version}"
        return 0
    fi

    echo "RPC version does not match installed snap version: ${rpc_version} vs ${snap_version}" >&2
    return 1
}

assert_rpc_version_differs_from_installed() {
    local snap_version rpc_version normalized_snap_version

    snap_version="$(get_snap_version)"
    rpc_version="$(get_rpc_version)"
    normalized_snap_version="${snap_version#v}"

    if [[ "${rpc_version}" != "${normalized_snap_version}"* ]]; then
        echo "RPC version still reflects the pre-refresh process as expected: ${rpc_version} vs ${snap_version}"
        return 0
    fi

    echo "RPC version already matches the installed snap version: ${rpc_version} vs ${snap_version}" >&2
    return 1
}
