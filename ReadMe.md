Unity Bootstrap Tooling
===

The purpose of this tooling is to run through the initial deployment and configuration of the staker and pool registry contracts.

Note that this is really quick-and-dirty so just setup as an Eclipse project.  In order to avoid requiring the building being done by everyone, I uploaded the built `Tools.jar` which includes the functionality here.  If this becomes long-lived, we can generalize the build to make it a basic `ant` task so everyone can easily build and package it after making changes.

Description of relevant components:
---

1)  `Tools.jar` - as mentioned, this includes the functionality of note which these scripts depend on.  The main entry-points are `cli.PackageJarAsHex` which takes the JAR given as a path argument and returns it as a hex string and `cli.SignTransaction` which takes a private key and other data to produce the hex string containing the entire raw transaction.
2)  `stakerRegistry.jar` - the StakerRegistry smart contract.  This is just the resource built from that project, committed here for convenience.
3)  `poolRegistry.jar` - the PoolRegistry smart contract.  This is just the resource built from that project, committed here for convenience.
4)  `rpc.sh` - adapted from the pre-node_test_harness functional test demonstration, this provides some of the lower-level logic around interacting with the JCON-RPC on the server as well as functionality from `Tools.jar`.
5)  `bootstrap.sh` - the top-level script which takes no arguments and will synchronously perform all operations required to bootstrap PoS block production on a running PoW Unity cluster.
6)  `deploy.sh` - deploys StakerRegistry and PoolRegistry contracts.
7)  `registerPool.sh` - registers a pool and does a self-bond.
8)  `delegate.sh` -  delegates stake to a pool.
9)  `undelegate.sh` - undelegates the amount specified from pool.

How to use bootstrap.sh
---

1)  Ensure that the cluster is in a clean state (we depend on this being the first transaction that the premined account has sent).
2)  Ensure that a node attached to the cluster is running, with JSON-RPC port open, on 127.0.0.1 (NOTE:  The IP/host and port can be changed in `rpc.sh`).
3)  Run `./bootstrap.sh` and wait for it to complete (takes a minute since it requires at least 3 blocks to be mined).
4)  Cluster is now bootstrapped and the premined account is now a valid staker.

#### What this does:

1)  Deploys the StakingRegistry contract as the premined account.
2)  Registers the premined account as a staker.
3)  Votes 1 billion Wei (whatever we call the base unit on Aion) for the premined account, from the premined account.
4)  Verifies that there is indeed 1 billion voted for the premined account.
