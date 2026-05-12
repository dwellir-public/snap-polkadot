#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/test-helpers.bash"

export POLKADOT_INSTALL_CHANNEL="${POLKADOT_INSTALL_CHANNEL:-edge}"
exec bash "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/test_initial_install.sh"
