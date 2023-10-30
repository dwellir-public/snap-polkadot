# Polkadot - snap

Basically the polkadot service built as a snap.

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
* --base-path is always set by the snap to `$SNAP_COMMON/polkadot_base` and is not allowed to be configured.

#### endure

If true the Polkadot service will not be restarted after a snap refresh.
Note that the Polkadot service will still be restarted as the result of changing service-args, etc.

This is reccomended when running a validator since it can be sensitive for a validator to go offline.

### Start the service

    $ sudo snap start polkadot

### Check logs from polkadot

    $ sudo snap logs polkadot -f

### Stop the service

    $ sudo snap stop polkadot

### Alternatively - use systemd

    $ sudo systemctl <stop|start> snap.polkadot.polkadot.service 
