#!/bin/bash

set -euo pipefail

readonly TESTS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd -- "${TESTS_DIR}/.." && pwd)"

SNAP_FILE="${POLKADOT_SNAP_FILE:-}"
INSTALL_REVISION="${POLKADOT_INSTALL_REVISION:-}"
DOWNGRADE_REVISION="${POLKADOT_DOWNGRADE_REVISION:-}"

usage() {
    echo "Usage:" >&2
    echo "  bash tests/run_all_local.sh --snap-file <snap-file> --downgrade-revision <revision>" >&2
    echo "  bash tests/run_all_local.sh --revision <install-revision> [--downgrade-revision <revision>]" >&2
    echo >&2
    echo "Legacy positional usage is still supported for local snap files:" >&2
    echo "  bash tests/run_all_local.sh <snap-file> <downgrade-revision>" >&2
    echo >&2
    echo "Environment variable alternatives:" >&2
    echo "  POLKADOT_SNAP_FILE, POLKADOT_INSTALL_REVISION, POLKADOT_DOWNGRADE_REVISION" >&2
}

parse_args() {
    if [[ $# -gt 0 && "${1}" != --* ]]; then
        SNAP_FILE="$1"
        if [[ $# -ge 2 ]]; then
            DOWNGRADE_REVISION="$2"
        fi
        if [[ $# -gt 2 ]]; then
            echo "Unexpected extra arguments for positional usage." >&2
            usage
            exit 1
        fi
        return 0
    fi

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --snap-file)
                SNAP_FILE="${2:-}"
                shift 2
                ;;
            --revision)
                INSTALL_REVISION="${2:-}"
                shift 2
                ;;
            --downgrade-revision)
                DOWNGRADE_REVISION="${2:-}"
                shift 2
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                echo "Unknown argument: $1" >&2
                usage
                exit 1
                ;;
        esac
    done
}

parse_args "$@"

if [[ -n "${SNAP_FILE}" && -n "${INSTALL_REVISION}" ]]; then
    echo "Specify either a snap file or an install revision, not both." >&2
    usage
    exit 1
fi

if [[ -z "${SNAP_FILE}" && -z "${INSTALL_REVISION}" ]]; then
    echo "Either a snap file or an install revision is required." >&2
    usage
    exit 1
fi

if [[ -n "${SNAP_FILE}" && ! -f "${SNAP_FILE}" ]]; then
    echo "Snap file does not exist: ${SNAP_FILE}" >&2
    exit 1
fi

if [[ -n "${INSTALL_REVISION}" && ! "${INSTALL_REVISION}" =~ ^[0-9]+$ ]]; then
    echo "Install revision must be numeric: ${INSTALL_REVISION}" >&2
    exit 1
fi

if [[ -z "${DOWNGRADE_REVISION}" && -n "${SNAP_FILE}" ]]; then
    echo "A downgrade revision is required for the downgrade and endure tests when using a local snap file." >&2
    exit 1
fi

if [[ -n "${DOWNGRADE_REVISION}" && ! "${DOWNGRADE_REVISION}" =~ ^[0-9]+$ ]]; then
    echo "Downgrade revision must be numeric: ${DOWNGRADE_REVISION}" >&2
    exit 1
fi

cleanup() {
    local status="$1"

    echo
    echo "==== Result ===="
    if [[ "${status}" -eq 0 ]]; then
        echo "All tests passed."
    else
        echo "Test run failed."
    fi

    echo
    echo "==== Cleanup ===="
    sudo snap remove polkadot --purge >/dev/null 2>&1 || true

    trap - EXIT
    exit "${status}"
}

trap 'cleanup $?' EXIT

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

    if [[ -n "${SNAP_FILE}" ]]; then
        run_step "${label}" env \
            POLKADOT_SNAP_FILE="${SNAP_FILE}" \
            POLKADOT_TEST_CHAIN="${chain}" \
            bash "${script_path}"
        return 0
    fi

    run_step "${label}" env \
        POLKADOT_INSTALL_REVISION="${INSTALL_REVISION}" \
        POLKADOT_TEST_CHAIN="${chain}" \
        bash "${script_path}"
}

run_revision_test() {
    local label="$1"
    local script_path="$2"

    if [[ -n "${SNAP_FILE}" ]]; then
        run_step "${label}" env \
            POLKADOT_SNAP_FILE="${SNAP_FILE}" \
            POLKADOT_DOWNGRADE_REVISION="${DOWNGRADE_REVISION}" \
            bash "${script_path}"
        return 0
    fi

    run_step "${label}" env \
        POLKADOT_INSTALL_REVISION="${INSTALL_REVISION}" \
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
