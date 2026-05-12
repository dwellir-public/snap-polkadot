#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/test-helpers.bash"

readonly POLKADOT_TEST_CHAIN="${POLKADOT_TEST_CHAIN:-polkadot}"
readonly EXPECTED_SERVICE_ARGS="--name=testing --chain=${POLKADOT_TEST_CHAIN} --rpc-port=9933 --prometheus-port=9900 --prometheus-external"

cleanup_polkadot_snap
install_polkadot_snap

sudo snap set polkadot service-args="--name=testing --chain=${POLKADOT_TEST_CHAIN}"
sudo snap start polkadot

sleep 5
check_polkadot_service_running

sudo snap set polkadot service-args="${EXPECTED_SERVICE_ARGS}"

wait_for_polkadot_service

echo "Waiting 20 seconds for node to get peers"
sleep 20

run_node_status_checks
assert_logs_contain "Service arguments: ${EXPECTED_SERVICE_ARGS}"
