# ScopeGuard Setup Guide

This guide shows how to setup a ScopeGuard with a Gnosis Safe on supported networks.

_Note: transaction guards only work with safes on version 1.3.0 or greater._

## Warning ⚠️

Enabling a ScopeGuard can brick your Safe, making it unusable and rendering any funds inaccessible.
Once enabled on your Safe, your ScopeGuard will revert any transactions to addresses or functions that have not been explicitly allowed.

Before you enable your ScopeGuard, please make sure you have setup the ScopeGuard fully to enable each of the addresses and functions you wish the multisig owners to be able to call.

## Prerequisites

To start the process you need to create a Safe on your target network. A Safe transaction is required to setup the ScopeGuard.

Before anything else, you'll need to install the project dependencies by running:

```bash
make install
```

And then compile the contracts with:

```bash
make build
```

For the deployment and management commands to work, the environment needs to be properly configured. See the [sample env file](../.env.sample) for more information.

## Supported Networks

The following networks are supported:

- arbitrum (Arbitrum One)
- berachain (Berachain)
- sonic (Sonic)
- sepolia (Sepolia testnet)

## Deploying the ScopeGuard

The scope guard has one variable which must be set:

- Owner: address that can call setter functions

### Production Networks

For production networks, you need to set the required environment variables:

```bash
make deploy NETWORK=arbitrum ACCOUNT=<your_account> OWNER_ADDRESS=<owner_address>
```

Replace `arbitrum` with your target network (arbitrum, berachain, sonic, sepolia).

This will deploy and verify the contract (on supported networks) and return the address of the deployed Scope Guard.

_Note: Multiple safes can use the same instance of a ScopeGuard, but they will all have the same settings controlled by the same `owner`. In most cases it is preferable for each safe to have its own instance of ScopeGuard._

### Setting up the ScopeGuard

⚠️ Warning, this step is critical to ensure that you do not brick your Safe.

Allow any target addresses that the multisig owners should be allowed to call.

#### Allow a target address

```bash
make set-target-allowed NETWORK=<network> GUARD_ADDRESS=<scope_guard_address> TARGET_ADDRESS=<target_address> ALLOWED=true ACCOUNT=<your_account>
```

You should use this command once for each address that the multisig owners are allowed to call.

#### Limit the scope of an address

To limit the scope of an address to specific function signatures, you must toggle on `scoped` for that address and then allow the function signature for that address.

```bash
make set-scoped NETWORK=<network> GUARD_ADDRESS=<scope_guard_address> TARGET_ADDRESS=<target_address> SCOPED=true ACCOUNT=<your_account>
```

Then set allow the specific function signature:

```bash
make set-allowed-function NETWORK=<network> GUARD_ADDRESS=<scope_guard_address> TARGET_ADDRESS=<target_address> FUNCTION_SIG="transfer(address,uint256)" ALLOWED=true ACCOUNT=<your_account>
```

An example of a function signature is `transfer(address,uint256)` or `balanceOf(address)`.

#### Transferring Ownership of the guard

Once you have set up your guard, you should transfer ownership to the appropriate address (usually the Safe that the guard will be enabled on).

```bash
make transfer-ownership NETWORK=<network> GUARD_ADDRESS=<scope_guard_address> NEW_OWNER=<new_owner_address> ACCOUNT=<your_account>
```

### Dry Run Mode

You can simulate any management command without executing it by adding `DRY_RUN=true`:

```bash
make set-target-allowed NETWORK=arbitrum GUARD_ADDRESS=<scope_guard_address> TARGET_ADDRESS=<target_address> ALLOWED=true ACCOUNT=<your_account> DRY_RUN=true
```

This will show you what the transaction would do without actually executing it.

### Enabling the ScopeGuard

Once your scope guard is set up, you'll need to call the `setGuard()` function on your GnosisSafe.
You can do this with a custom contract interaction via the [Gnosis Safe UI](http://gnosis-safe.io/) or the [Gnosis Safe CLI](https://github.com/gnosis/safe-cli).

## Environment Variables

The following environment variables are required for different operations:

- `ACCOUNT`: Forge account name
- `OWNER_ADDRESS`: ScopeGuard owner address
- `GUARD_ADDRESS`: ScopeGuard contract address (for management commands)
- `TARGET_ADDRESS`: Target address to allow (for set-target-allowed command)
- `FUNCTION_SIG`: Function signature (e.g., 'transfer(address,uint256)') (for set-allowed-function)
- `ALLOWED`: Allow/disallow flag (true/false) (for set-target-allowed and set-allowed-function)
- `NEW_OWNER`: New owner address (for transfer-ownership)
- `DRY_RUN`: Dry run mode flag (true/false) - simulates transactions without executing
- `ARBISCAN_API_KEY`: Arbiscan verification key (for Arbitrum)

## Available Commands

For a complete list of available commands, run:

```bash
make help
```

To check your current environment configuration:

```bash
make status
```
