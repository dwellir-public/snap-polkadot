#!/bin/bash
source test-helpers.bash
set +x
set -e
# Edge Test Script

# Install the Polkadot snap from edge channel
sudo snap install polkadot --channel=edge

# Set service-args
sudo snap set polkadot service-args="--name=edge-testing --rpc-port=9933 --prometheus-port=9900 --prometheus-external"

# Start Polkadot service
sudo snap start polkadot

wait_for_polkadot_service

# We need to wait some for the node to get peers and start syncing.
echo "Waiting 20 seconds for node to get peers"
sleep 20

# Check node status using the Python script
echo "Running node status tests..."
python3 check_node_status.py
