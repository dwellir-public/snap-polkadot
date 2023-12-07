#!/bin/python3

import requests
import time

HEADERS = {'Content-Type': 'application/json'}

def rpc_request(method: str, params: list = []):
    data = {
        'jsonrpc': '2.0',
        'method': method,
        'params': params,
        'id': 1
    }
    return requests.post('http://localhost:9933', json=data, headers=HEADERS, timeout=5).json()
        

def main():
    print(rpc_request('system_version')['result'])
    print(rpc_request('system_health')['result'])
    print(rpc_request('system_syncState')['result'])
    time.sleep(0.5)
    print(rpc_request('system_syncState')['result'])
    print(rpc_request('system_chain')['result'])
        


if __name__ == '__main__':
    main()
