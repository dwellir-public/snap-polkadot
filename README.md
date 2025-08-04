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

Promoting can be done either from [this webpage](https://snapcraft.io/polkadot/releases)
or by running
`snapcraft release polkadot <revision> <channel>`

## Hardware requirements

See https://wiki.polkadot.network/docs/maintain-guides-how-to-validate-polkadot#standard-hardware

## Install snap

`sudo snap install <snap-file> --devmode`
or from snap store
`sudo snap install polkadot`

### Configuration

#### service-args

```sudo snap set polkadot service-args="<my service args>"```

For available arguments see https://github.com/paritytech/polkadot-sdk

Example:

```
sudo snap set polkadot service-args="--base-path=/var/snap/polkadot/common/polkadot_base \
--name DWELLIR-NODE \
--chain kusama \
--prometheus-external \
--pruning archive \
--rpc-external \
--rpc-port=9933 \
--rpc-cors all \
--rpc-methods Safe \
--rpc-max-connections=1000"
```

#### endure

```sudo snap set polkadot endure=true|false```

If true the Polkadot service will not be restarted after a snap refresh.
Note that the Polkadot service will still be restarted as the result of changing service-args, etc.

Use this when restarts should be avoided e.g. when running a validator.

#### Changing base-path outside of the SNAP_COMMON directory
Setting an alternative base-path can be done by connecting the snap removable-media interface This allows the snap to access external filsystems/dirs (see: snap interface removable-media)

    sudo snap connect polkadot:removable-media

Configure your startup parameters (written to /var/snap/polkadot/common/service-arguments). 

    sudo snap set polkadot service-args='--base-path /mnt/polkadot/'


### Start the service

`sudo snap start polkadot`

### Check logs from polkadot

`sudo snap logs polkadot -f`

### Stop the service

`sudo snap stop polkadot`

### Alternatively - use systemd

`sudo systemctl <stop|start> snap.polkadot.polkadot.service`
