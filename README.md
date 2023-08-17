# Polkadot - snap

Basically the polkadot service built as a snap.

It ships with custom runtimes for tracing.

## Building the snap
Clone the repo, then build with snapcraft

    sudo snap install snapcraft --classic
    cd snap-polkadot
    snapcraft pack --use-lxd --debug --verbosity=debug # Takes some time.

## Releasing to edge (work in progress)
The snap inherits (adopt-info) the version by picking up the version from the upstream polkadot repo tag.
E.g. "v0.9.42" etc. and adds the commit hash to it.

The release to the edge is then:

    snapcraft upload --release=edge ./polkadot_<version>.snap
    
### Install snap

    $ sudo snap install polkadot.charm --devmode

### Check/edit startup params

    $ sudo vi /var/snap/polkadot/common/service-arguments

### Inspect the snap

    $ snap services polkadot
    Service            Startup   Current   Notes
    polkadot.polkadot  disabled  inactive  -

### Start the service

    $ sudo snap start polkadot

### Stop the service

    $ sudo snap stop polkadot

### Alternatively - use systemd

    $ sudo systemctl <stop|start> snap.polkadot.polkadot.service 

## Running with custom runtime for tracing

### Add custom startup params
    $ echo "--name=Dwellir --wasm-runtime-overrides /snap/polkadot/current/polkadot-runtime-with-traces/" > /var/snap/polkadot/common/service-arguments

### Testing tracing:
    curl -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "state_traceBlock", \
    "params": ["0xb246acf1adea1f801ce15c77a5fa7d8f2eb8fed466978bcee172cc02cf64e264", "pallet,frame,state", "", ""]}' http://localhost:9933/


# Polkadot databases 

Located in: 

    $HOME/snap/polkadot/current/.local/share/polkadot/
