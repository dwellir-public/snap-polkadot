#!/usr/bin/env python3

import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request


def get_snap_version():
    snap_info_output = subprocess.check_output(["snap", "info", "polkadot"], text=True)
    for line in snap_info_output.splitlines():
        if line.strip().startswith("installed:"):
            snap_version = line.split()[1].strip()
            return snap_version
    return None

def rpc_request(method: str):
    payload = json.dumps({"id": 1, "jsonrpc": "2.0", "method": method}).encode("utf-8")
    request = urllib.request.Request(
        "http://localhost:9933",
        data=payload,
        headers={"Content-Type": "application/json"},
    )

    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            return json.loads(response.read().decode("utf-8"))
    except urllib.error.URLError as exc:
        print(f"FAIL: RPC call for {method} failed: {exc}")
        sys.exit(1)


def extract_git_suffix(version: str):
    if "-" not in version:
        return None

    candidate = version.rsplit("-", 1)[-1].lower()
    if all(char in "0123456789abcdef" for char in candidate):
        return candidate

    return None


def versions_match(snap_version: str, rpc_version: str):
    normalized_snap_version = snap_version[1:] if snap_version.startswith("v") else snap_version
    if rpc_version == normalized_snap_version or rpc_version.startswith(f"{normalized_snap_version}-"):
        return True

    snap_git_suffix = extract_git_suffix(normalized_snap_version)
    rpc_git_suffix = extract_git_suffix(rpc_version)
    if snap_git_suffix and rpc_git_suffix:
        return rpc_git_suffix.startswith(snap_git_suffix) or snap_git_suffix.startswith(rpc_git_suffix)

    return False


def expected_chain_name():
    explicit_expected = os.environ.get("POLKADOT_EXPECTED_CHAIN")
    if explicit_expected:
        return explicit_expected

    configured_chain = os.environ.get("POLKADOT_TEST_CHAIN", "polkadot").strip().lower()
    mapping = {
        "polkadot": "Polkadot",
        "kusama": "Kusama",
        "paseo": "Paseo Testnet",
        "paseo-testnet": "Paseo Testnet",
        "westend": "Westend",
    }
    return mapping.get(configured_chain, configured_chain)

def check_version():
    print("CHECK: Validate that the installed snap version is the same as for the snap using system_version rpc call")
    version_info = rpc_request("system_version")
    rpc_version = version_info["result"]

    snap_version = get_snap_version()

    if snap_version is None:
        print("Failed to retrieve the snap version.")
        sys.exit(1)

    if versions_match(snap_version, rpc_version):
        print(f"SUCCESS: Version check passed: RPC version {rpc_version} matches snap version {snap_version}")
    else:
        print(f"FAIL: Version check failed: RPC version {rpc_version} does not match snap version {snap_version}")
        sys.exit(1)


def check_health():
    print("CHECK: system_health")
    health_info = rpc_request("system_health")
    print(health_info)
    if health_info["result"]["peers"] > 0 and health_info["result"]["isSyncing"] and health_info["result"]["shouldHavePeers"]:
        print("SUCCESS: system_health indicates that we have peers and node is syncing")
    else:
        print("FAIL: system_health indicates that we dont have peers or node is not syncing.)")
        sys.exit(1)


def check_sync_state():
    print("system_syncState")
    sync_state1 = rpc_request("system_syncState")
    current_block1 = sync_state1["result"]["currentBlock"]
    print("First sync test check: ", sync_state1)
    print("Sleeping 20 secs to get let node get peers and sync a bit")
    time.sleep(20)
    sync_state2 = rpc_request("system_syncState")
    current_block2 = sync_state2["result"]["currentBlock"]
    print("Second sync test check: ", sync_state2)

    if current_block2 > current_block1:
        print("SUCCESS: Sync state check passed: currentBlock increased from {} to {}".format(current_block1, current_block2))
    else:
        print("FAIL: Sync state check failed: currentBlock did not increase. Node isn't syncing.")
        sys.exit(1)


def check_chain():
    print("CHECK: system_chain")
    chain_info = rpc_request("system_chain")
    expected_chain = expected_chain_name()
    if chain_info["result"] == expected_chain:
        print(f"SUCCESS: The system_chain is {chain_info['result']}")
    else:
        print(f"FAIL: The system_chain is {chain_info['result']}, expected {expected_chain}.")
        sys.exit(1)

if __name__ == "__main__":
    check_version()
    check_health()
    check_sync_state()
    check_chain()
