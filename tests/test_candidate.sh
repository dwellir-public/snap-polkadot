#!/bin/bash
source test-helpers.bash
# Candidate Test Script

# Install the Polkadot snap from candidate channel
sudo snap install polkadot --channel=candidate

# Set service-args
sudo snap set polkadot service-args="--name=candidate-test --chain=polkadot"

# Start Polkadot service
sudo snap start polkadot

# Wait for polkadot to start (rpc disabled here)
sleep 5
check_polkadot_service_running

# Update service-args with additional parameters (enable rpc)
sudo snap set polkadot service-args="--name=testing --chain=polkadot --rpc-port=9933 --prometheus-port=9900 --prometheus-external"

# Wait for the service to come online
wait_for_polkadot_service

# Check node status using the Python script (using rpc)
python3 check_node_status.py

