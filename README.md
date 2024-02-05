# Polkadot - snap

Basically the polkadot service built as a snap.

## Building the snap

Clone the repo, then build with snapcraft

```
sudo snap install snapcraft --classic
cd snap-polkadot
snapcraft pack --use-lxd --debug --verbosity=debug # Takes some time.
```

## Upgrading Polkadot version

Simply change the version number here: https://github.com/dwellir-public/snap-polkadot/blob/main/snap/snapcraft.yaml#L58 and then of course rebuild.

## Releasing

When a commit is made to the main branch a build will start in launchpad and if successful release to the edge channel.
To promote further follow the instructions in [this document](TESTING.md)

Promoting can be done either from [this webpage](https://snapcraft.io/polkadot/publicise)
or by running
`snapcraft release polkadot <revision> <channel>`

### Install snap

`sudo snap install <snap-file> --devmode`
or from snap store
`sudo snap install polkadot`

### Configuration

#### service-args

default=--base-path=$SNAP_COMMON/polkadot_base --name=<hostname>

For available arguments see https://github.com/paritytech/polkadot-sdk
The value set here will be passed to the Polkadot binary with a few exceptions listed below. 
* --name defaults to the systems hostname the first time the snap is installed.
* --base-path is always set by the snap to `$SNAP_COMMON/polkadot_base` and is not allowed to be configured.

Example:

    sudo snap set polkadot service-args="--name=my-westend-node --chain=westend"

#### endure

default=false

If true the Polkadot service will not be restarted after a snap refresh.
Note that the Polkadot service will still be restarted as the result of changing service-args, etc.

Use this when restarts should be avoided e.g. when running a validator.

### Start the service

`sudo snap start polkadot`

### Check logs from polkadot

`sudo snap logs polkadot -f`

### Stop the service

`sudo snap stop polkadot`

### Alternatively - use systemd

`sudo systemctl <stop|start> snap.polkadot.polkadot.service`
