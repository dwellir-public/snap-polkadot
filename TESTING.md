# Preparations before running tests

Make sure to run the tests in a container or to run `sudo snap remove polkadot --purge` before running tests to have a clean environment.

Keep a terminal window open with the logs during the tests using `sudo snap logs polkadot -f`

### Check node status
The following steps will be referenced through out this document with `Check node status`.

| Steps                                 | Command                                                                                                                               | Expected result |
|---------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------|-----------------|
| Check running version with RPC method | `curl -X POST -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_version"}' http://localhost:9933`   | The curl result should show the same version as is shown for the installed snap by running `snap info polkadot` |
| Check node health                     | `curl -X POST -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_health"}' http://localhost:9933`    | The curl result should show that the node has peers and is syncing |
| Check sync state                      | `curl -X POST -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_syncState"}' http://localhost:9933` | Run the curl command twice with a short time between and check that the current block is increased |
| Check sync state                      | `curl -X POST -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_chain"}' http://localhost:9933`     | The curl result should show the configured chain (Polkadot if not specified in service-args) |

Note: there is a utility script called [check_node_status.py](check_node_status.py) that can be used when running it on the same machine as the snap runs on.

# Edge tests
| Steps                                   | Command                                                                                                                             | Expected result |
|-----------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------|-----------------|
| Install the Polkadot snap               | `sudo snap install polkadot --channel=edge`                                                                                         |                 |
| Set --rpc-port in service-args          | `sudo snap set polkadot service-args="--name=testing --rpc-port=9933 --prometheus-port=9900 --prometheus-external"` | Check logs that Polkadot service was restarted and the new service-args where applied |
| Start Polkadot                          | `sudo snap start polkadot`                                                                                                          |                 |
| [Check node status](#Check-node-status) | See steps above                                                                                                                     |                 |

# Beta tests

# Candidate tests

# Stable tests

### Test initial installation

| Steps                                   | Command                                                                                                                             | Expected result |
|-----------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------|-----------------|
| Install the Polkadot snap               | `sudo snap install polkadot --channel=candidate`                                                                                    |                 |
| Set --rpc-port in service-args          | `sudo snap set polkadot service-args="--name=testing --chain=<chain>"`                                                              |                 |
| Start Polkadot                          | `sudo snap start polkadot`                                                                                                          | Logs appear in log terminal |
| Set --rpc-port in service-args          | `sudo snap set polkadot service-args="--name=testing --chain=<chain> --rpc-port=9933 --prometheus-port=9900 --prometheus-external"` | Check logs that Polkadot service was restarted and the new service-args where applied |
| [Check node status](#Check-node-status) | See steps above                                                                                                                     |                 |



### Test setting --base-path

| Steps                                  | Command                                                                                                                         | Expected result |
|----------------------------------------|---------------------------------------------------------------------------------------------------------------------------------|-----------------|
| Set --base-path in service-args config | `sudo snap set polkadot service-args="--name=testing --rpc-port=9933 --prometheus-port=9900 --prometheus-external --base-path"` | The following should be presented in the terminal: error: cannot perform the following tasks: Run configure hook of "polkadot" snap (run hook "configure": base-path is not allowed to pass as a service argument restoring to last used service-args. This path is alywas used instead /var/snap/polkadot/common/polkadot_base.) |

### Test downgrade

| Steps                                   | Command                                                      | Expected result |
|-----------------------------------------|--------------------------------------------------------------|-----------------|
| Get previous revision                   | `snap info polkadot`                                         | The revision is between parentheses. Check the installed one and subtract one |
| Downgrade the Polkadot snap             | `sudo snap refresh polkadot --revision=<previous-revisison>` |                 |
| [Check node status](#Check-node-status) | See steps above                                              |                 |

### Test endure

| Steps                                   | Command                                                                                                                             | Expected result |
|-----------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------|-----------------|
| Upgrade to latest version               | `sudo snap refresh polkadot`                                                                                                        |                 |
| [Check node status](#Check-node-status) | See steps above                                                                                                                     |                 |
| Enable endure config                    | `sudo snap set polkadot endure=true`                                                                                                |                 |
| Downgrade the Polkadot snap             | `sudo snap refresh polkadot --revision=<previous-revisison>`                                                                        | Check in the logs that the service didn't restart |
| Check running version with RPC method   | `curl -X POST -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_version"}' http://localhost:9933` | The curl result should __NOT__ show the same version as is shown for the installed snap by running `snap info polkdaot` |
| Restart the service                     | `sudo snap restart polkadot`                                                                                                        | 
| Check running version with RPC method   | `curl -X POST -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_version"}' http://localhost:9933` | The curl result should show the same version as is shown for the installed snap by running `snap info polkdaot` |

### Test Kusama, Paseo Testnet, Westend and Rococo

For each of Kusama, Westend and Rococo
1. Clean the environment as described in the [preparation section](#preparations-before-running-tests)
1. Run [edge tests](#test-initial-installation)


### Testing with snapstore

If you need to test stuff related to snapstore you can use the following steps:

1. Upload to a branch (lives for 30 days)
   snapcraft upload <snap>
   snapcraft release <rev> channel latest/edge/my-tests

2. sudo snap install snap --channel latest/edge/my-tests
