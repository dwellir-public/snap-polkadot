#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/test-helpers.bash"

readonly POLKADOT_TEST_CHAIN="${POLKADOT_TEST_CHAIN:-polkadot}"

previous_args="$(sudo snap get polkadot service-args)"

set +e
command_output="$(
    sudo snap set polkadot service-args="--name=testing --chain=${POLKADOT_TEST_CHAIN} --rpc-port=9933 --prometheus-port=9900 --prometheus-external --base-path" 2>&1
)"
command_status=$?
set -e

printf '%s\n' "${command_output}"

if [[ "${command_status}" -eq 0 ]]; then
    echo "Expected --base-path without a value to be rejected." >&2
    exit 1
fi

if ! grep -qi "base-path" <<< "${command_output}"; then
    echo "Expected the snap error output to mention base-path." >&2
    exit 1
fi

current_args="$(sudo snap get polkadot service-args)"

if [[ "${current_args}" != "${previous_args}" ]]; then
    echo "service-args changed after the invalid --base-path update." >&2
    exit 1
fi
