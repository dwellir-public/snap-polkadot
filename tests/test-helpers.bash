#!/bin/bash

# Function to wait for the Polkadot service to start
wait_for_polkadot_service() {
    local timeout=30
    local interval=1
    local elapsed=0

    echo "Waiting for Polkadot service to start on port 9933..."

    while (( elapsed < timeout )); do
        if nc -zv localhost 9933 2>/dev/null; then
            echo "Polkadot service is listening on port 9933."
            return 0
        fi
        sleep $interval
        (( elapsed += interval ))
	echo $elapsed
    done

    echo "Timed out waiting for Polkadot service to start."
    return 1
}


# Function to check if the Polkadot snap service is running
check_polkadot_service_running() {
    local service_name="polkadot.daemon"
    
    echo "Checking if Polkadot service is running..."

    if snap services | grep -q "$service_name.*active"; then
        echo "Polkadot service is running."
        return 0
    else
        echo "Polkadot service is not running."
        return 1
    fi
}
