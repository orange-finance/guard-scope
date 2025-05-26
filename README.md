# ScopeGuard

> **Note**: This project is a fork of [zodiac-guard-scope](https://github.com/gnosisguild/zodiac-guard-scope) by Gnosis Guild, adapted to use Foundry-based deployment scripts instead of the original Hardhat-based scripts. The core smart contracts remain unchanged and are licensed under LGPL-3.0+.

[![Build Status](https://github.com/gnosis/zodiac-guard-scope/actions/workflows/ci.yml/badge.svg)](https://github.com/gnosis/zodiac-guard-scope/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/gnosis/zodiac-guard-scope/badge.svg?branch=main)](https://coveralls.io/github/gnosis/zodiac-guard-scope)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-2.1-4baaaa.svg)](https://github.com/gnosis/CODE_OF_CONDUCT)

Attaching a scope guard to an Avatar or Mod, allows one to limit the contracts and functions that may be called (by the multisig owners in the case of a Gnosis Safe, or by the mod if enable of a mod).

### Features

- Set specific addresses that the avatar can be triggered to call
- Scope the functions that are allowed to be called on specific addresses
- Allow/disallow multisig transaction to use delegate calls to specific addresses

### Flow

- Deploy ScopeGuard
- Allow addresses and function calls that the Safe multisig signers should be able to call
- Enable the txguard in the Safe

### Warnings ⚠️

Before you enable your ScopeGuard, please make sure you have setup the ScopeGuard fully to enable each of the addresses and functions you wish for the multisig owners or mod to be able to call.

Best practice is to enable another account that you control as a module to your Safe before enabling your ScopeGuard.

Some specific things you should be aware of:

- Enabling a ScopeGuard can brick your Avatar, making it unusable and rendering any funds inaccessible.
  Once enabled on your Safe, your ScopeGuard will revert any transactions to addresses or functions that have not been explicitly allowed.
- By default it is not possible to use delegate call with any contract once your ScopeGuard is enabled.
  This means if the ScopeGuard is added without allowing delegate calls for the `MultiSendCallOnly` contract, there might be issues when using some Safe apps via the Safe web interface.
- Delegate call usage checks are per address. It is not possible to limit this to a specific function of a contract.
- Transaction value is not checked.
  This means that the multisig owners can send any amount of native assets allowed addresses.
- If a contract address is marked as scoped it is not possible to call any function on this contract UNLESS it was explicitly marked as allowed.
- If the Safe contract itself is marked as scoped without any allowed functions, it is bricked (even if the Safe address itself is in the allowed list).
- Enabling the ScopeGuard will increase the gas cost of each multisig transaction.

### Solidity Compiler

The contracts have been developed with [Solidity 0.8.6](https://github.com/ethereum/solidity/releases/tag/v0.8.6) in mind. This version of Solidity made all arithmetic checked by default, therefore eliminating the need for explicit overflow or underflow (or other arithmetic) checks.

### Setup Guide

Follow our [ScopeGuard Setup Guide](./docs/setup_guide.md) to setup and use a ScopeGuard.

### Foundry Migration

This fork has been adapted to use Foundry instead of the original Hardhat toolchain:

- **Deployment Scripts**: Converted from Hardhat deployment scripts to Foundry scripts (see `scripts/` directory)
- **Build System**: Uses `foundry.toml` configuration instead of `hardhat.config.ts`
- **Testing**: Can be run using Foundry's testing framework
- **Smart Contracts**: Remain completely unchanged from the original implementation

This project uses Makefile-based commands for easy deployment and management. For example:

```bash
# Install dependencies
make install

# Build contracts
make build

# Deploy ScopeGuard
make deploy NETWORK=<network> ACCOUNT=<your_account> OWNER_ADDRESS=<owner_address>
```

For complete deployment and setup instructions, please refer to the [ScopeGuard Setup Guide](./docs/setup_guide.md).

### Security and Liability

All contracts are WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

### License

This project is a fork of [zodiac-guard-scope](https://github.com/gnosisguild/zodiac-guard-scope) by Gnosis Guild. The original project and this fork are both licensed under the [LGPL-3.0+ license](LICENSE).

**Original Copyright**: Copyright (C) Gnosis Guild  
**Fork Modifications**: Foundry-based deployment scripts and tooling adaptations

All smart contracts remain unchanged from the original implementation and retain their original licensing terms.

### Audits

An audit has been performed by the [G0 group](https://github.com/g0-group).

All issues and notes of the audit have been addressed in commit [ad2579a3fc684b2dd87c5f87c8736cd61e46e4cb](https://github.com/gnosis/zodiac-guard-scope/commit/ad2579a3fc684b2dd87c5f87c8736cd61e46e4cb).

The audit results are available as a pdf in [this repo](audits/ZodiacScopeGuardSep2021.pdf) or on the [g0-group repo](https://github.com/g0-group/Audits/blob/e11752abb010f74e32a6fc61142032a10deed578/ZodiacScopeGuardSep2021.pdf).

### Security and Liability

All contracts are WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
