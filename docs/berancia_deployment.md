# Berancia Guard Deployment and Configuration Guide

This guide explains how to deploy and configure ScopeGuard for new liquidity pairs automatically using Makefile commands and Foundry scripts.

## Overview

The automation system consists of:

- **Makefile**: Convenient wrapper commands for deployment and management
- **BeranciaGuardSetup.s.sol**: Main deployment script with clean configuration loading
- **config/common.toml**: Common contract addresses and function selectors
- **config/pairs/\*.toml**: Per-pair configuration files
- **deployments/**: JSON output directory for deployment results

## Configuration Structure

### Common Configuration (`config/common.toml`)

All shared contracts and their allowed functions are defined here:

```toml
[tokens]
lbgt = { address = "0x...", functions = ["approve(address,uint256)"] }
ibgt = { address = "0x...", functions = ["approve(address,uint256)"] }
ybgt = { address = "0x...", functions = ["approve(address,uint256)"] }

[protocols]
bearn_vault_router = { address = "0x...", functions = ["deposit(address,address,uint256,uint256)"] }
oogabooga_swap = { address = "0x...", functions = ["swap((address,uint256,address,uint256,uint256,address),bytes,address,uint32)"] }
kodiak_island_router = { address = "0x...", functions = ["addLiquiditySingle()"] }
lgbt_mint = { address = "0x...", functions = ["mint()"] }

[common_vaults]
infrared = { functions = ["stake()", "getReward()", "withdraw()", "exit()"] }
bearn = { functions = ["getReward()", "exit()"] }
berapaw = { functions = ["stake()", "getReward()", "setOperator()", "exit()"] }
```

### Pair Configuration (`config/pairs/*.toml`)

Each pair has its own configuration file:

```toml
pair_name = "HONEY-WBERA"
owner = "0x..." # Safe/multisig address

# Variable liquidity protocol (can be kodiak, bex, etc.)
[liquidity_protocol]
name = "kodiak"
address = "0x..."
functions = ["approve()"]

# Pair-specific vault addresses
[vaults]
infrared = "0x..."
bearn = "0x..."
berapaw = "0x..."
```

## Quick Start

### 1. Setup Common Configuration

The `config/common.toml` file contains all shared contract configurations. Update the addresses if needed:

```bash
# Edit common configuration
vi config/common.toml
```

### 2. Check Available Pairs

List all available pair configurations:

```bash
make guard-list-pairs
```

### 3. Create or Check Pair Configuration

Create a new configuration file for your pair:

```bash
# Copy from existing template or create new
cp config/pairs/example-pair.toml config/pairs/your-pair.toml
vi config/pairs/your-pair.toml

# Check configuration before deployment
make guard-check-config PAIR=your-pair
```

### 4. Deploy Guard

Deploy guard using the Makefile wrapper:

```bash
make guard-deploy \
    NETWORK=berachain \
    PAIR=your-pair \
    ACCOUNT=deployer \
    SENDER_ADDRESS=0x1234567890123456789012345678901234567890
```

## Makefile Commands

### Primary Commands

#### `make guard-deploy`

Deploy and configure a guard for a specific pair.

**Required parameters:**

- `NETWORK`: Target network (berachain, arbitrum, sepolia, sonic)
- `ACCOUNT`: Foundry account name for deployment
- `SENDER_ADDRESS`: Address of the deploying account
- `PAIR`: Pair name (uses config/pairs/{PAIR}.toml) OR
- `PAIR_CONFIG_FILE`: Direct path to configuration file

**Examples:**

```bash
# Deploy using pair name
make guard-deploy \
    NETWORK=berachain \
    PAIR=honey-wbera \
    ACCOUNT=deployer \
    SENDER_ADDRESS=0x742d35Cc6605C24C0532C8B4a7cA7F948b8F4b78

# Deploy using custom config file
make guard-deploy \
    NETWORK=berachain \
    PAIR_CONFIG_FILE=config/pairs/custom-pair.toml \
    ACCOUNT=deployer \
    SENDER_ADDRESS=0x742d35Cc6605C24C0532C8B4a7cA7F948b8F4b78
```

#### `make guard-list-pairs`

List all available pair configurations.

```bash
make guard-list-pairs
```

Output example:

```
Available pair configurations:
  honey-wbera
    pair_name = "HONEY-WBERA"
  btc-weth
    pair_name = "BTC-WETH"
```

#### `make guard-check-config`

Check and display configuration for a specific pair.

**Required parameters:**

- `PAIR`: Pair name OR
- `PAIR_CONFIG_FILE`: Direct path to configuration file

**Examples:**

```bash
# Check by pair name
make guard-check-config PAIR=honey-wbera

# Check custom config file
make guard-check-config PAIR_CONFIG_FILE=config/pairs/custom.toml
```

### Utility Commands

#### `make status`

Display current environment variables.

```bash
make status
```

#### `make help`

Display all available commands and their usage.

```bash
make help
```

## Deployment Output

### JSON Results

Each deployment generates a detailed JSON file in the `deployments/` directory:

```bash
deployments/guard-deployment-{PAIR_NAME}.json
```

**JSON Structure:**

```json
{
  "scopeGuardAddress": "0x...",
  "finalOwner": "0x...",
  "pairName": "HONEY-WBERA",
  "totalTargets": 8,
  "totalFunctions": 15,
  "configuredTargets": [
    {
      "targetAddress": "0xBaadCC2962417C01Af99fb2B7C75706B9bd6Babe",
      "targetName": "LBGT Token",
      "isScoped": true,
      "allowedSelectors": ["0xa9059cbb"],
      "functionSignatures": ["approve(address,uint256)"]
    }
  ]
}
```

### Console Output

During deployment, you'll see:

- Configuration loading status
- Contract deployment address
- Permission configuration progress
- Ownership transfer confirmation
- JSON file output location

## Configuration Examples

### Kodiak-based Pair

```toml
pair_name = "HONEY-WBERA"
owner = "0x5678901234567890123456789012345678901234"

[liquidity_protocol]
name = "kodiak"
address = "0x1234567890123456789012345678901234567890"
functions = ["approve()"]

[vaults]
infrared = "0x2345678901234567890123456789012345678901"
bearn = "0x3456789012345678901234567890123456789012"
berapaw = "0x4567890123456789012345678901234567890123"
```

### BEX-based Pair

```toml
pair_name = "HONEY-USDC-BEX"
owner = "0x5678901234567890123456789012345678901234"

[liquidity_protocol]
name = "bex"
address = "0xABCDEF1234567890123456789012345678901234"
functions = ["addLiquidity()", "removeLiquidity()"]

[vaults]
infrared = "0x2345678901234567890123456789012345678901"
bearn = "0x3456789012345678901234567890123456789012"
berapaw = "0x4567890123456789012345678901234567890123"
```

## Environment Variables

### Required for Deployment

- `NETWORK`: Target blockchain network
- `ACCOUNT`: Foundry account identifier
- `SENDER_ADDRESS`: Deployer's address
- `PAIR` or `PAIR_CONFIG_FILE`: Configuration specification

### Optional

- `DRY_RUN`: Set to "true" for simulation mode

### Setup Example

Create a `.env` file:

```bash
# Foundry account configuration
ACCOUNT=deployer
SENDER_ADDRESS=0x1234567890123456789012345678901234567890

# API keys for verification
ALCHEMY_API_KEY=your_alchemy_key
BERASCAN_API_KEY=your_berascan_key
```

## Network Support

Configured networks in `foundry.toml`:

- **berachain**: Berachain mainnet
- **arbitrum**: Arbitrum One
- **sonic**: Sonic mainnet
- **sepolia**: Ethereum Sepolia testnet

## Automatic Configuration

The system automatically configures permissions for:

### Tokens (from common.toml)

- **LBGT token**: `approve(address,uint256)`
- **iBGT token**: `approve(address,uint256)`
- **yBGT token**: `approve(address,uint256)`

### Protocols (from common.toml)

- **BEARN_VAULT_ROUTER**: `deposit(address,address,uint256,uint256)`
- **oogabooga swap**: `swap((address,uint256,address,uint256,uint256,address),bytes,address,uint32)`
- **kodiak island router**: `addLiquiditySingle()`
- **LGBT_MINT**: `mint()`

### Vaults (functions from common.toml, addresses from pair config)

- **Infrared Vault**: `stake()`, `getReward()`, `withdraw()`, `exit()`
- **Bearn Vault**: `getReward()`, `exit()`
- **Berapaw Vault**: `stake()`, `getReward()`, `setOperator()`, `exit()`

### Variable Liquidity Protocol

- **Flexible protocol support**: Kodiak, BEX, or custom protocols
- **Custom function selectors**: Each protocol can have different functions
- **Address per pair**: Each pair can use different protocol addresses

## Troubleshooting

### Common Issues

1. **Missing configuration file**

   ```bash
   Error: Configuration file config/pairs/your-pair.toml not found
   ```

   **Solution**: Check file exists and use correct pair name.

2. **TOML parsing errors**

   ```bash
   Error: Failed to parse TOML
   ```

   **Solution**: Ensure all addresses have `0x` prefix and valid format.

3. **Account not found**

   ```bash
   Error: Account 'deployer' not found
   ```

   **Solution**: Check foundry account setup with `cast wallet list`.

4. **Sender address mismatch**
   ```bash
   Error: msg.sender mismatch
   ```
   **Solution**: Ensure `SENDER_ADDRESS` matches the account address.

### Debug Mode

For detailed logging:

```bash
make guard-deploy \
    NETWORK=berachain \
    PAIR=your-pair \
    ACCOUNT=deployer \
    SENDER_ADDRESS=0x... \
    -vvvv
```

### Verify Configuration

Before deployment, always check your configuration:

```bash
make guard-check-config PAIR=your-pair
```

## Best Practices

### Security

- Always verify contract addresses before deployment
- Test deployments on testnets first
- Ensure the owner address is correct (usually a Safe/multisig)
- Review the configured permissions before enabling the guard

### Workflow

1. **Setup**: Configure common.toml with correct addresses
2. **Create**: Create pair-specific configuration
3. **Verify**: Use `guard-check-config` to verify settings
4. **Test**: Deploy to testnet first
5. **Deploy**: Deploy to mainnet
6. **Confirm**: Check generated JSON file for accuracy

### File Management

- Keep pair configurations in version control
- Use descriptive pair names
- Archive old configurations in separate directory
- Back up deployment JSON files

## Integration

### With External Tools

The generated JSON files can be used by:

- **Monitoring tools**: Parse deployment results
- **Documentation generators**: Auto-generate configuration docs
- **Audit tools**: Verify deployed permissions
- **CI/CD pipelines**: Automated deployment validation

### Example Integration

```bash
# Deploy and extract guard address
make guard-deploy NETWORK=berachain PAIR=honey-wbera ACCOUNT=deployer SENDER_ADDRESS=0x...

# Extract guard address from JSON
GUARD_ADDRESS=$(jq -r '.scopeGuardAddress' deployments/guard-deployment-HONEY-WBERA.json)

# Use in subsequent operations
echo "Deployed guard at: $GUARD_ADDRESS"
```
