# check_node_status.py
#
# Helper functions to run tests
#
import requests
import json
import time
import subprocess
import sys

def get_snap_version():
    # Run the `snap info` command and extract the version
    snap_info_output = subprocess.check_output(['snap', 'info', 'polkadot']).decode('utf-8')
    for line in snap_info_output.splitlines():
        if line.strip().startswith('installed:'):
            snap_version = line.split()[1].strip()
            return snap_version
    return None

def check_version():
    """
    Checks that the version compiled and running, actually is what is installed.
    """
    print("CHECK: Validate that the installed snap version is the same as for the snap using system_version rpc call")
    response = requests.post('http://localhost:9933', json={"id": 1, "jsonrpc": "2.0", "method": "system_version"})
    version_info = response.json()
    rpc_version = version_info['result']

    snap_version = get_snap_version()

    if snap_version is None:
        print("Failed to retrieve the snap version.")
        return

    # Strip 'v' from snap version if present
    if snap_version.startswith('v'):
        snap_version = snap_version[1:]

    # Compare the common part of the versions
    common_length = min(len(rpc_version), len(snap_version))
    if rpc_version[:common_length] == snap_version[:common_length]:
        print(f"SUCCESS: Version check passed: RPC version {rpc_version} matches snap version {snap_version}")
    else:
        print(f"FAIL: Version check failed: RPC version {rpc_version} does not match snap version {snap_version}")
        sys.exit(1)


def check_health():
    """
    Checks that the node has peers and syncing.
    """
    print("CHECK: system_health")
    response = requests.post('http://localhost:9933', json={"id":1, "jsonrpc":"2.0", "method": "system_health"})
    health_info = response.json()
    print(health_info)
    # Check that {'peers': 8, 'isSyncing': True, 'shouldHavePeers': True}
    if health_info['result']['peers'] > 0 and health_info['result']['isSyncing'] and health_info['result']['shouldHavePeers']:
        print("SUCCESS: system_health indicates that we have peers and node is syncing")
    else:
        print("FAIL: system_health indicates that we dont have peers or node is not syncing.)")
        return


def check_sync_state():
    """
    Checks that the node is syncing.
    """
    print("system_syncState")
    response1 = requests.post('http://localhost:9933', json={"id":1, "jsonrpc":"2.0", "method": "system_syncState"})
    sync_state1 = response1.json()
    current_block1 = sync_state1['result']['currentBlock']
    print("First sync test check: " , sync_state1)
    print("Sleeping 20 secs to get let node get peers and sync a bit")
    # wait a short time
    time.sleep(20)
    response2 = requests.post('http://localhost:9933', json={"id":1, "jsonrpc":"2.0", "method": "system_syncState"})
    sync_state2 = response2.json()
    current_block2 = sync_state2['result']['currentBlock']
    print("Second sync test check: " , sync_state2)

    # Add your sync state check logic here

    if current_block2 > current_block1:
        print("SUCCESS: Sync state check passed: currentBlock increased from {} to {}".format(current_block1, current_block2))
    else:
        print("FAIL: Sync state check failed: currentBlock did not increase. Node isn't syncing.")
        return
    

def check_chain():
    """
    Check that the system chains is what we expect.
    """
    print("CHECK: system_chain")
    response = requests.post('http://localhost:9933', json={"id":1, "jsonrpc":"2.0", "method": "system_chain"})
    chain_info = response.json()
    supportedChains = ['Polkadot', 'Kusama', 'Paseo Testnet', 'Westend']
    if chain_info['result'] in supportedChains:
        print("SUCCESS: The system_chain is Polkadot")
    else:
        print("FAIL: The system_chain name is not in the list of suppored chains we expect.")
        return

if __name__ == "__main__":
    check_version()
    check_health()
    check_sync_state()
    check_chain()

