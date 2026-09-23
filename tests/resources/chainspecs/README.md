# Chain spec test resources

Chain specs in this directory are used only by the runtime tests. They are not
bundled into the snap. `tests/test-helpers.bash` copies the file for the selected
`POLKADOT_TEST_CHAIN` into `/var/snap/polkadot/common/test-chainspecs/` and starts the
node with `--chain=<that path>`.

## paseo.raw.json

Paseo was relaunched from block 0 as a "substitute relay" (name `Paseo`, protocol-id `pad`,
ss58 prefix 42). The `--chain=paseo` built into the polkadot binary still points at the retired
pre-relaunch chain (`Paseo Testnet`, protocol-id `pas`), whose bootnodes are gone, so a node
started that way never finds peers.

Source: https://github.com/paseo-network/paseo-chain-specs (file `paseo.raw.json`)
Pinned commit: e5c79012 (2026-09-15)
sha256: 05c2949ab4b040140416979f93620dee4ebc67b30a830e92d62e1cd76a6a8c2d

Refresh it when Paseo publishes new bootnodes and the Paseo runtime test stops finding peers:

```bash
curl -fsSL https://raw.githubusercontent.com/paseo-network/paseo-chain-specs/main/paseo.raw.json \
  -o tests/resources/chainspecs/paseo.raw.json
sha256sum tests/resources/chainspecs/paseo.raw.json   # update this README
```

`tests/test_shellscripts.sh` checks that the file exists and has `name` `Paseo` and
`protocolId` `pad`.

Note: the relaunched chain keeps the id `paseo`, so it uses the same database directory as the
retired chain (`$SNAP_COMMON/polkadot_base/chains/paseo`). The tests purge the snap before
installing, so this does not affect CI, but a real node that synced the old Paseo must remove
that directory before starting on the new spec.
