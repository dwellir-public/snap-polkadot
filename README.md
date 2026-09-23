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

Simply change the version number here: https://github.com/dwellir-public/snap-polkadot/blob/main/snap/snapcraft.yaml#L53 and then of course rebuild.

## Releasing

When a commit is made to the main branch a build will start in launchpad and if successful release to the edge channel.
To promote further follow the instructions in [TESTING.md](TESTING.md).

Promoting can be done either from [this webpage](https://snapcraft.io/polkadot/releases)
or by running
`snapcraft release polkadot <revision> <channel>`

## Testing

The main testing guide lives in [TESTING.md](TESTING.md).

### Local test scripts

The local test entry points are:

- `bash tests/run_all_local.sh /path/to/file.snap <downgrade-revision>`
  Runs the full local test sequence.
- `bash tests/run_all_local.sh --revision <revision> [--downgrade-revision <revision>]`
  Runs the same full sequence against a Snap Store revision.
- `bash tests/test_shellscripts.sh`
  Fast helper coverage for `utils/utils.sh`.
- `bash tests/test_basic_install.sh`
  Basic install-and-sync coverage for one chain.
- `bash tests/test_initial_install.sh`
  Full install flow used by the Polkadot suite.
- `bash tests/test_base_path.sh`
- `bash tests/test_downgrade.sh`
- `bash tests/test_endure.sh`

The runtime tests can install from:

- a local `.snap` file via `POLKADOT_SNAP_FILE=/path/to/file.snap`
- a specific Snap Store revision via `POLKADOT_INSTALL_REVISION=<revision>`
- a Snap Store channel via `POLKADOT_INSTALL_CHANNEL=<channel>`

Example:

```bash
POLKADOT_SNAP_FILE=/full/path/to/polkadot.snap bash tests/test_initial_install.sh
```

For local `.snap` installs, downgrade and endure tests need an explicit store revision to downgrade to:

```bash
POLKADOT_DOWNGRADE_REVISION=64 bash tests/test_endure.sh
```

### GitHub Actions

This repository has two test-oriented GitHub workflows:

- [manual-revision-tests.yaml](.github/workflows/manual-revision-tests.yaml)
  Manual runtime test workflow.
- [test-shellscripts.yaml](.github/workflows/test-shellscripts.yaml)
  Runs `tests/test_shellscripts.sh` on pull requests and pushes to `main`.

The manual workflow supports:

- testing a Snap Store revision
- building the snap from the selected branch or tag and testing that local artifact
- `chain=all`, which runs the full Polkadot suite and basic install tests for Kusama, Westend, and Paseo

## Hardware requirements

See https://wiki.polkadot.network/docs/maintain-guides-how-to-validate-polkadot#standard-hardware

## Install snap

`sudo snap install <snap-file> --dangerous`
or from snap store
`sudo snap install polkadot`

### Configuration

#### service-args

```sudo snap set polkadot service-args="<my service args>"```

For available arguments see https://github.com/paritytech/polkadot-sdk

Example:

```
sudo snap set polkadot service-args="--name DWELLIR-NODE \
--chain kusama \
--prometheus-external \
--pruning archive \
--rpc-external \
--rpc-port=9933 \
--rpc-cors all \
--rpc-methods Safe \
--rpc-max-connections=1000"
```

If `service-args` does not include `--base-path`, the snap automatically prepends the default base path under `$SNAP_COMMON/polkadot_base` and logs that behavior in `snap logs polkadot`.

#### endure

```sudo snap set polkadot endure=true|false```

If true the Polkadot service will not be restarted after a snap refresh.
Changes to `service-args` are written immediately, but they take effect on the next service start or manual `sudo snap restart polkadot`.

Use this when restarts should be avoided e.g. when running a validator.

#### Changing base-path outside of the SNAP_COMMON directory
Setting an alternative base-path can be done by connecting the snap removable-media interface This allows the snap to access external filsystems/dirs (see: snap interface removable-media)

    sudo snap connect polkadot:removable-media

Configure your startup parameters (written to /var/snap/polkadot/common/service-arguments). 

    sudo snap set polkadot service-args='--base-path /mnt/polkadot/'

#### Running with a chain spec file (Paseo)

The `paseo` chain spec built into the polkadot binary is the retired pre-relaunch Paseo chain, so `--chain=paseo` starts a node that never finds peers. Paseo was relaunched from block 0 as a substitute relay and its live spec is published at https://github.com/paseo-network/paseo-chain-specs. The snap does not bundle that file because its bootnodes change. Download it and place it where the service can read it, under `/var/snap/polkadot/common`:

```bash
curl -fsSL https://raw.githubusercontent.com/paseo-network/paseo-chain-specs/main/paseo.raw.json -o paseo.raw.json
sudo install -d -m 0755 /var/snap/polkadot/common/chain-specs
sudo install -m 0644 paseo.raw.json /var/snap/polkadot/common/chain-specs/paseo.raw.json
```

Then pass the absolute path as `--chain` and restart the service:

```bash
sudo snap set polkadot service-args="--name DWELLIR-NODE --chain=/var/snap/polkadot/common/chain-specs/paseo.raw.json --rpc-port=9933"
sudo snap restart polkadot
```

Notes:

- A node that previously synced the retired Paseo chain must remove `/var/snap/polkadot/common/polkadot_base/chains/paseo` before restarting, since both chains use the id `paseo` and share that database directory. Otherwise the node fails with a genesis mismatch.
- The file can also live under `/mnt`, `/media` or `/run/media` after `sudo snap connect polkadot:removable-media`. The service cannot read files under `$HOME`.
- `polkadot.polkadot-cli` plugs the `home` interface, so it can read a spec directly from your home directory: `polkadot.polkadot-cli --chain=$HOME/paseo.raw.json ...`.
- When Paseo publishes new bootnodes, re-run the download and install commands above and restart the service.


### Start the service

`sudo snap start polkadot`

### Check logs from polkadot

`sudo snap logs polkadot -f`

### Stop the service

`sudo snap stop polkadot`

### Alternatively - use systemd

`sudo systemctl <stop|start> snap.polkadot.polkadot.service`

### Running polkadot from other snaps

Other snaps can call on this snap to execute polkadot commands by connecting to the bins slot. This avoids getting "Permission denied" when calling on polkadot from other snaps.

```sudo snap connect <snap-name>:bins polkadot:bins```
