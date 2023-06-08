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
    
    # Install
    $ sudo snap install polkadot.charm --devmode

    # Check startup params
    $ sudo vi /var/snap/polkadot/common/service-arguments

    # Inspect the snap
    $ snap services polkadot
    Service            Startup   Current   Notes
    polkadot.polkadot  disabled  inactive  -

    # Start the service
    $ sudo snap start polkadot

    # Stop the service
    $ sudo snap stop polkadot

    # Alternatively - use systemd
    $ sudo systemctl start snap.polkadot.polkadot.service 

## Running with custom runtime for tracing

    # Add custom startup params
    $ echo "--name=Dwellir --wasm-runtime-overrides /snap/polkadot/current/polkadot-runtime-with-traces/" > /var/snap/polkadot/common/service-arguments


Polkadot databases will be located in: 

    $HOME/snap/polkadot/current/.local/share/polkadot/
