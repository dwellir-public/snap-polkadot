# Testing

This repository has both local test scripts and GitHub Actions workflows.

## Preparation

Run the tests in a container or start from a clean local snap environment:

```bash
sudo snap remove polkadot --purge
```

Keep a terminal open with the snap logs while testing:

```bash
sudo snap logs polkadot -f
```

## Test scripts

The test scripts live in `tests/` and share the helper logic in `tests/test-helpers.bash`.

### Available scripts

- `tests/run_all_local.sh`
  Runs the full local test sequence against one snap file and one downgrade revision.
- `tests/test_basic_install.sh`
  Runs the basic install-and-sync test for a single chain.
- `tests/test_initial_install.sh`
  Runs the full install flow used for the Polkadot full suite.
- `tests/test_base_path.sh`
  Verifies that an invalid `--base-path` update is rejected and that the previous config is kept.
- `tests/test_downgrade.sh`
  Refreshes to an older revision and verifies the node still starts and syncs.
- `tests/test_endure.sh`
  Verifies `endure=true` prevents restart during refresh and that a manual restart picks up the downgraded revision.
- `tests/test_shellscripts.sh`
  Fast local unit-style coverage for `utils/utils.sh`, especially `validate_service_args()`.

### Installation source selection

The runtime test scripts can install Polkadot from three sources:

1. Local snap file

```bash
POLKADOT_SNAP_FILE=/full/path/to/polkadot.snap bash tests/test_initial_install.sh
```

2. Specific Snap Store revision

```bash
POLKADOT_INSTALL_REVISION=65 bash tests/test_initial_install.sh
```

3. Snap Store channel

```bash
POLKADOT_INSTALL_CHANNEL=edge bash tests/test_initial_install.sh
```

The scripts print the chosen install source before installation.

### Supported chains

The currently supported test chains are:

- `polkadot`
- `kusama`
- `westend`
- `paseo`

Example:

```bash
POLKADOT_INSTALL_REVISION=65 POLKADOT_TEST_CHAIN=kusama bash tests/test_basic_install.sh
```

### Downgrade and endure tests

When the installed snap comes from the Snap Store, `tests/test_downgrade.sh` and `tests/test_endure.sh` can usually discover the previous published revision automatically.

When the installed snap comes from a local `.snap` file, set the downgrade target explicitly:

```bash
POLKADOT_SNAP_FILE=/full/path/to/polkadot.snap bash tests/test_initial_install.sh
POLKADOT_DOWNGRADE_REVISION=64 bash tests/test_downgrade.sh
POLKADOT_DOWNGRADE_REVISION=64 bash tests/test_endure.sh
```

### Base-path test

Run:

```bash
bash tests/test_base_path.sh
```

Expected behavior:

- the `snap set` command fails
- the output mentions `base-path`
- the previously configured `service-args` value is preserved

Current expected output is similar to:

```text
error: cannot perform the following tasks:
- Run configure hook of "polkadot" snap (run hook "configure": base-path requires a value. No change was made to service-args.)
```

This is expected for the current validation logic.

### Node status checks

The runtime tests call `tests/check_node_status.py`, which checks:

- RPC version matches the installed snap build
- node health reports peers and syncing
- sync state increases between two checks
- `system_chain` matches the configured chain

The version match is based on the shared git SHA suffix when the snap version format and RPC version format differ.

## Recommended local flows

### Fast validation of shell helpers

```bash
bash tests/test_shellscripts.sh
```

### Test a local snap build on Polkadot

Run the full local sequence:

```bash
bash tests/run_all_local.sh /full/path/to/polkadot.snap 64
```

Or run the individual scripts:

```bash
POLKADOT_SNAP_FILE=/full/path/to/polkadot.snap bash tests/test_initial_install.sh
bash tests/test_base_path.sh
POLKADOT_DOWNGRADE_REVISION=64 bash tests/test_downgrade.sh
POLKADOT_SNAP_FILE=/full/path/to/polkadot.snap bash tests/test_initial_install.sh
POLKADOT_DOWNGRADE_REVISION=64 bash tests/test_endure.sh
```

### Test a local snap build on another chain

```bash
POLKADOT_SNAP_FILE=/full/path/to/polkadot.snap POLKADOT_TEST_CHAIN=westend bash tests/test_basic_install.sh
```

## GitHub Actions

### PR and main-branch shellscript validation

The workflow [test-shellscripts.yaml](.github/workflows/test-shellscripts.yaml) runs `tests/test_shellscripts.sh` on:

- pull requests
- pushes to `main`

### Manual runtime test workflow

The workflow [manual-revision-tests.yaml](.github/workflows/manual-revision-tests.yaml) is manually triggered with `workflow_dispatch`.

Inputs:

- `build_snap`
  If `true`, the workflow builds the snap from the selected Git ref and tests that local artifact.
- `revision`
  Required when `build_snap=false`.
- `downgrade_revision`
  Required for Polkadot full-suite runs when `build_snap=true`.
- `chain`
  One of `all`, `polkadot`, `kusama`, `westend`, `paseo`.

Behavior:

- `chain=all` runs the full Polkadot suite plus basic install tests for Kusama, Westend, and Paseo.
- `chain=polkadot` runs the full Polkadot suite only.
- `chain=kusama`, `westend`, or `paseo` runs the basic install test for that chain only.
- when `build_snap=true`, the snap is built from the selected branch or tag, uploaded as an artifact, then installed with `--dangerous` in the test jobs.

## Snap Store testing

If you need to test a branch build through the Snap Store:

1. Upload to a temporary branch channel

```bash
snapcraft upload <snap>
snapcraft release <revision> latest/edge/my-tests
```

2. Install it

```bash
sudo snap install polkadot --channel latest/edge/my-tests
```
