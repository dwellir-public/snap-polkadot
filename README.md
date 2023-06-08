# Polkadot - snap

Basically the polkadot built as a snap.

It ships with custom runtimes for tracing: 

    polkadot --wasm-runtime-overrides /snap/polkadot/current/runtimes/polkadot/


## Building the snap
Clone the repo, then build with snapcraft

    sudo snap install snapcraft --classic
    cd snap-polkadot
    snapcraft --use-lxd --debug --verbosity=debug # Takes some time.


## Running polkadot

    $ sudo snap install polkadot.charm --devmode
    $ polkadot

Polkadot databases will be located in: 

    $HOME/snap/polkadot/current/.local/share/polkadot/
