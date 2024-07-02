#!/bin/bash
source test-helpers.bash
set +x
set -e
# Downgrade Test Script
echo "Running downgrade tests"
# Get the current revision
current_revision=$(snap info --verbose polkadot | grep installed | awk -F ' ' '{print $3}' | tr -d '()')
previous_revision=$((current_revision - 1))

echo $previous_revision

# Downgrade the Polkadot snap
sudo snap refresh polkadot --revision=$previous_revision

sudo snap restart polkadot 

# Let polkadot settle
wait_for_polkadot_service

# Check node status using the Python script
python3 check_node_status.py

