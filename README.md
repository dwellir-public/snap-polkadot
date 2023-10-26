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

### Inspect the snap

    $ snap services polkadot
    Service            Startup   Current   Notes
    polkadot.polkadot  disabled  inactive  -

### Configuration

#### service-args

Arguments passed to the Polkadot service. Set and get with snap set/get polkadot service-args 

* --name defaults to the systems hostname the first time the snap is installed.
* --base-path is always set by the snap and is not allowed to be configured.
* --wasm-runtime-overrides is set when tracing is enabled and is not allowed to be configured.
* --rpc-methods is not allowed to be set if tracing is enabled since tracing required the value to be true.

#### tracing-enabled

If true tracing will be enabled on the Polkadot service. This means that service args --wasm-runtime-overrides will be set and point to the correct runtime overrides based on the running chain and that --rpc-methods will be set to true.

Is not allowed to be enabled if --rpc-methods is set in service-args since it needs to be true for tracing to work.

#### endure

If true the Polkadot service will not be restarted after a snap refresh.
Note that the Polkadot service will still be restarted as the result of changing service-args, tracing-enabled, etc.

This is reccomended when running a validator since it can be sensitive for a validator to go offline.

### Start the service

    $ sudo snap start polkadot

### Check logs from polkadot

    $ sudo snap logs polkadot -f

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
