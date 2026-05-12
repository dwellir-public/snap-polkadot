#!/bin/bash

set -euo pipefail

readonly TESTS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly STATUS_CHECKER="${TESTS_DIR}/check_node_status.py"
readonly POLKADOT_SNAP_NAME="${POLKADOT_SNAP_NAME:-polkadot}"
readonly POLKADOT_SNAP_SERVICE="snap.${POLKADOT_SNAP_NAME}.polkadot.service"

using_local_snap_build() {
    [[ -n "${POLKADOT_SNAP_FILE:-}" ]]
}

cleanup_polkadot_snap() {
    sudo snap remove "${POLKADOT_SNAP_NAME}" --purge >/dev/null 2>&1 || true
}

install_polkadot_snap() {
    if using_local_snap_build; then
        if [[ ! -f "${POLKADOT_SNAP_FILE}" ]]; then
            echo "Local snap file does not exist: ${POLKADOT_SNAP_FILE}" >&2
            return 1
        fi

        echo "Installing ${POLKADOT_SNAP_NAME} from local snap file: ${POLKADOT_SNAP_FILE}"
        sudo snap install --dangerous "${POLKADOT_SNAP_FILE}"
        return 0
    fi

    if [[ -n "${POLKADOT_INSTALL_REVISION:-}" ]]; then
        echo "Installing ${POLKADOT_SNAP_NAME} from Snap Store revision: ${POLKADOT_INSTALL_REVISION}"
        sudo snap install "${POLKADOT_SNAP_NAME}" --revision="${POLKADOT_INSTALL_REVISION}"
        return 0
    fi

    if [[ -n "${POLKADOT_INSTALL_CHANNEL:-}" ]]; then
        echo "Installing ${POLKADOT_SNAP_NAME} from Snap Store channel: ${POLKADOT_INSTALL_CHANNEL}"
        sudo snap install "${POLKADOT_SNAP_NAME}" --channel="${POLKADOT_INSTALL_CHANNEL}"
        return 0
    fi

    echo "POLKADOT_SNAP_FILE, POLKADOT_INSTALL_REVISION, or POLKADOT_INSTALL_CHANNEL must be set." >&2
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

wait_for_node_health() {
    local timeout="${1:-120}"
    local interval=5
    local elapsed=0

    echo "Waiting for Polkadot to get peers and start syncing..."

    while (( elapsed < timeout )); do
        if python3 - <<'PY'
import json
import sys
import urllib.error
import urllib.request

payload = json.dumps({"id": 1, "jsonrpc": "2.0", "method": "system_health"}).encode("utf-8")
request = urllib.request.Request(
    "http://localhost:9933",
    data=payload,
    headers={"Content-Type": "application/json"},
)

try:
    with urllib.request.urlopen(request, timeout=10) as response:
        data = json.loads(response.read().decode("utf-8"))
except Exception:
    sys.exit(1)

result = data.get("result", {})
healthy = (
    result.get("peers", 0) > 0
    and result.get("isSyncing") is True
    and result.get("shouldHavePeers") is True
)
sys.exit(0 if healthy else 1)
PY
        then
            echo "Polkadot has peers and is syncing."
            return 0
        fi

        sleep "${interval}"
        elapsed=$((elapsed + interval))
        echo "Still waiting for healthy node state after ${elapsed}s"
    done

    echo "Timed out waiting for Polkadot to get peers and start syncing." >&2
    return 1
}

get_installed_revision_raw() {
    snap info --verbose "${POLKADOT_SNAP_NAME}" | awk '/installed:/ { gsub(/[()]/, "", $3); print $3; exit }'
}

get_tracking_channel() {
    snap list "${POLKADOT_SNAP_NAME}" --all | awk 'NR==2 { print $4; exit }'
}

is_untracked_install() {
    [[ "$(get_tracking_channel)" == "-" ]]
}

get_installed_revision() {
    local revision

    revision="$(get_installed_revision_raw)"
    if [[ ! "${revision}" =~ ^[0-9]+$ ]]; then
        echo "Installed revision is not numeric: ${revision}" >&2
        return 1
    fi

    echo "${revision}"
}

find_previous_available_revision() {
    local current_revision="${1:-}"
    local max_probe_depth="${POLKADOT_REVISION_PROBE_DEPTH:-25}"
    local candidate_revision temp_dir basename

    if [[ -z "${current_revision}" ]]; then
        current_revision="$(get_installed_revision_raw)"
    fi

    if [[ ! "${current_revision}" =~ ^[0-9]+$ ]]; then
        echo "Installed revision '${current_revision}' is not numeric. Set POLKADOT_DOWNGRADE_REVISION explicitly when testing a local snap build." >&2
        return 1
    fi

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

refresh_to_revision() {
    local revision="$1"

    if is_untracked_install; then
        echo "Refreshing ${POLKADOT_SNAP_NAME} to revision ${revision} with --amend because the current install is untracked."
        sudo snap refresh "${POLKADOT_SNAP_NAME}" --amend --revision="${revision}"
        return 0
    fi

    echo "Refreshing ${POLKADOT_SNAP_NAME} to revision ${revision}."
    sudo snap refresh "${POLKADOT_SNAP_NAME}" --revision="${revision}"
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

extract_git_suffix() {
    local version="$1"
    local candidate

    [[ "${version}" == *-* ]] || return 1
    candidate="${version##*-}"

    if [[ "${candidate}" =~ ^[0-9a-fA-F]+$ ]]; then
        printf '%s\n' "${candidate,,}"
        return 0
    fi

    return 1
}

versions_match() {
    local snap_version="$1"
    local rpc_version="$2"
    local normalized_snap_version snap_git_suffix rpc_git_suffix

    normalized_snap_version="${snap_version#v}"
    if [[ "${rpc_version}" == "${normalized_snap_version}" || "${rpc_version}" == "${normalized_snap_version}-"* ]]; then
        return 0
    fi

    snap_git_suffix="$(extract_git_suffix "${normalized_snap_version}" || true)"
    rpc_git_suffix="$(extract_git_suffix "${rpc_version}" || true)"

    if [[ -n "${snap_git_suffix}" && -n "${rpc_git_suffix}" ]]; then
        [[ "${rpc_git_suffix}" == "${snap_git_suffix}"* || "${snap_git_suffix}" == "${rpc_git_suffix}"* ]]
        return
    fi

    return 1
}

get_snap_logs() {
    sudo snap logs "${POLKADOT_SNAP_NAME}" -n all --abs-time
}

get_snap_log_count() {
    get_snap_logs | wc -l | tr -d '[:space:]'
}

get_snap_logs_after_line() {
    local line_count="$1"
    local start_line=$((line_count + 1))

    get_snap_logs | tail -n +"${start_line}"
}

assert_logs_contain() {
    local pattern="$1"
    local logs

    logs="$(get_snap_logs)"
    if grep -Fq -- "${pattern}" <<< "${logs}"; then
        echo "Snap logs contain expected text: ${pattern}"
        return 0
    fi

    echo "Snap logs do not contain expected text: ${pattern}" >&2
    return 1
}

assert_logs_do_not_contain() {
    local pattern="$1"
    local logs

    logs="$(get_snap_logs)"
    if grep -Fq -- "${pattern}" <<< "${logs}"; then
        echo "Snap logs unexpectedly contain text: ${pattern}" >&2
        return 1
    fi

    echo "Snap logs do not contain forbidden text: ${pattern}"
    return 0
}

assert_logs_after_line_contain() {
    local line_count="$1"
    local pattern="$2"
    local logs

    logs="$(get_snap_logs_after_line "${line_count}")"
    if grep -Fq -- "${pattern}" <<< "${logs}"; then
        echo "New snap logs contain expected text: ${pattern}"
        return 0
    fi

    echo "New snap logs do not contain expected text: ${pattern}" >&2
    return 1
}

assert_logs_after_line_do_not_contain() {
    local line_count="$1"
    local pattern="$2"
    local logs

    logs="$(get_snap_logs_after_line "${line_count}")"
    if grep -Fq -- "${pattern}" <<< "${logs}"; then
        echo "New snap logs unexpectedly contain text: ${pattern}" >&2
        return 1
    fi

    echo "New snap logs do not contain forbidden text: ${pattern}"
    return 0
}

assert_rpc_version_matches_installed() {
    local snap_version rpc_version

    snap_version="$(get_snap_version)"
    rpc_version="$(get_rpc_version)"

    if versions_match "${snap_version}" "${rpc_version}"; then
        echo "RPC version matches installed snap version: ${rpc_version} vs ${snap_version}"
        return 0
    fi

    echo "RPC version does not match installed snap version: ${rpc_version} vs ${snap_version}" >&2
    return 1
}

assert_rpc_version_differs_from_installed() {
    local snap_version rpc_version

    snap_version="$(get_snap_version)"
    rpc_version="$(get_rpc_version)"

    if ! versions_match "${snap_version}" "${rpc_version}"; then
        echo "RPC version still reflects the pre-refresh process as expected: ${rpc_version} vs ${snap_version}"
        return 0
    fi

    echo "RPC version already matches the installed snap version: ${rpc_version} vs ${snap_version}" >&2
    return 1
}
