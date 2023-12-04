#!/bin/python3

import argparse
import requests
import yaml

HEADERS = {'Content-Type': 'application/json'}

def rpc_request(method: str, params: list = []):
    data = {
        'jsonrpc': '2.0',
        'method': method,
        'params': params,
        'id': 1
    }
    return requests.post('http://localhost:9933', json=data, headers=HEADERS, timeout=5).json()

def get_configured_version():
    with open('./snap/snapcraft.yaml', 'r') as file:
        return yaml.safe_load(file)['parts']['polkadot']['source-tag']
        

def main():
    parser = argparse.ArgumentParser(description='Util functions to test the Polkadot snap')
    parser.add_argument('--check_version', action='store_true', help='Check that the Polkadot binary version matched the provided version.')
    args = parser.parse_args()
    if args.check_version:
        configured_version = get_configured_version().split('-v')[1]
        running_version = rpc_request('system_version')['result'].split('-')[0]
        if configured_version != running_version:
            raise RuntimeError(f'Configured and running version not matching. Configured {configured_version}, Running {running_version}')
        


if __name__ == '__main__':
    main()
