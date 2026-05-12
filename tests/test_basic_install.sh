#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/test-helpers.bash"

readonly POLKADOT_TEST_CHAIN="${POLKADOT_TEST_CHAIN:-polkadot}"
readonly EXPECTED_SERVICE_ARGS_SUBSTRING="--name=testing --chain=${POLKADOT_TEST_CHAIN} --rpc-port=9933 --prometheus-port=9900 --prometheus-external"

cleanup_polkadot_snap
install_polkadot_snap

sudo snap set polkadot service-args="${EXPECTED_SERVICE_ARGS_SUBSTRING}"
before_start_log_count="$(get_snap_log_count)"
sudo snap start polkadot

wait_for_polkadot_service

wait_for_node_health
run_node_status_checks
assert_logs_after_line_contain "${before_start_log_count}" "Service arguments: --base-path="
assert_logs_after_line_contain "${before_start_log_count}" "${EXPECTED_SERVICE_ARGS_SUBSTRING}"
