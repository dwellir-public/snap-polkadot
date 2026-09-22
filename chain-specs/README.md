# Bundled chain specs

## paseo.raw.json

Paseo was relaunched from block 0 as a "substitute relay" (name `Paseo`, protocol-id `pad`,
ss58 prefix 42). The `--chain=paseo` built into the polkadot binary still points at the retired
pre-relaunch chain (`Paseo Testnet`, protocol-id `pas`), whose bootnodes are gone, so a node
started that way never finds peers.

The snap therefore ships the live spec and `wrappers/start-polkadot.bash` rewrites
`--chain=paseo` (or `--chain paseo`) to `$SNAP/chain-specs/paseo.raw.json` at service start.
See `resolve_chain_spec_args` in `utils/utils.sh`.

Source: https://github.com/paseo-network/paseo-chain-specs (file `paseo.raw.json`)
Pinned commit: e5c79012 (2026-09-15)
sha256: 05c2949ab4b040140416979f93620dee4ebc67b30a830e92d62e1cd76a6a8c2d

Refresh it when Paseo publishes new bootnodes:

```bash
curl -fsSL https://raw.githubusercontent.com/paseo-network/paseo-chain-specs/main/paseo.raw.json \
  -o chain-specs/paseo.raw.json
sha256sum chain-specs/paseo.raw.json   # update this README
```

Note: the relaunched chain keeps the id `paseo`, so it uses the same database directory as the
retired chain (`$SNAP_COMMON/polkadot_base/chains/paseo`). A node that previously synced the old
Paseo will fail with a genesis mismatch on start; remove that directory (or use a fresh
`--base-path`) before starting on the new spec.

Note: `polkadot-cli` runs the binary directly and bypasses the wrapper, so pass the spec path
explicitly there: `polkadot.polkadot-cli --chain=/snap/polkadot/current/chain-specs/paseo.raw.json ...`
