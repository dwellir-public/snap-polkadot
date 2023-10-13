#!/usr/bin/env python3

import os
from pathlib import Path
import subprocess as sp

# Snap environment
SNAP = Path(os.getenv('SNAP'))
SNAP_COMMON = Path(os.getenv('SNAP_COMMON'))

# Constants
SERVICE_ARGS_FILE = Path(SNAP_COMMON, 'service-arguments')
BASE_PATH = Path(SNAP_COMMON, 'polkadot_base')
POLKADOT_BINARY_PATH = Path(SNAP, 'files/polkadot')

if __name__ == '__main__':
    with open(SERVICE_ARGS_FILE, 'r', encoding='UTF-8') as file:
        service_args = file.read().strip()
    polkadot_commmand = f'{POLKADOT_BINARY_PATH} {service_args}'
    print(f'Running polkadot: {polkadot_commmand}')
    sp.run(polkadot_commmand.split(' '), check=True)
