#!/bin/bash
source test-helpers.bash
set +x
set -e
# Endure Test Script


# Upgrade to the latest version
sudo snap refresh polkadot

current_revision=$(snap info --verbose polkadot | grep installed | awk -F ' ' '{print $3}' | tr -d '()')
previous_revision=$((current_revision - 1))

# Check node status using the Python script
python3 check_node_status.py

# Enable endure config
sudo snap set polkadot endure=true

# Downgrade the Polkadot snap
sudo snap refresh polkadot --revision=$previous_revision

# Check that the service didn't restart
# ADD LOGICS HERE
