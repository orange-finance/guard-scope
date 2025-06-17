# ScopeGuard Deployment Makefile

# Environment variables
-include .env

# Default values
OWNER_ADDRESS ?= ""
ACCOUNT ?= ""
NETWORK ?= ""
GUARD_ADDRESS ?= ""
TARGET_ADDRESS ?= ""
SCOPED ?= ""
FUNCTION_SIG ?= ""
ALLOWED ?= ""
NEW_OWNER ?= ""
DRY_RUN ?= false
PAIR ?= ""
PAIR_CONFIG_FILE ?= ""
SENDER_ADDRESS ?= ""

# Network configurations
RPC_URL_arbitrum = arbitrum
RPC_URL_berachain = berachain
RPC_URL_sepolia = sepolia

VERIFY_NETWORKS = arbitrum berachain sonic sepolia
SUPPORTED_NETWORKS = arbitrum berachain sonic sepolia

# Helper functions to get network-specific settings
get_rpc_url = $(RPC_URL_$(1))
get_verify_flag = $(if $(filter $(1),$(VERIFY_NETWORKS)),--verify,)
get_cast_cmd = $(if $(filter true,$(DRY_RUN)),cast call --trace,cast send)

# Forge commands
FORGE_SCRIPT = forge script script/Deploy.s.sol
FORGE_GUARD_SCRIPT = forge script script/BeranciaGuardSetup.s.sol:BeranciaGuardSetup
FORGE_BUILD = forge build
FORGE_INSTALL = forge install

# Build targets
.PHONY: install build clean lint format format-check

install:
	$(FORGE_INSTALL)
	pnpm install

build:
	$(FORGE_BUILD)

clean:
	forge clean

# Lint and format targets
lint:
	npx solhint 'contracts/**/*.sol'

format:
	npx prettier 'contracts/**/*.sol' -w

format-check:
	npx prettier 'contracts/**/*.sol' --check

# Guard Deployment and Management
.PHONY: guard-deploy guard-list-pairs guard-check-config

guard-deploy:
	@test -n "$(NETWORK)" || (echo "Error: NETWORK is required. Use: make guard-deploy NETWORK=<network> PAIR=<pair>" && echo "Available networks: $(SUPPORTED_NETWORKS)" && exit 1)
	@echo "$(SUPPORTED_NETWORKS)" | grep -wq "$(NETWORK)" || (echo "Error: Unknown network '$(NETWORK)'" && echo "Available networks: $(SUPPORTED_NETWORKS)" && exit 1)
	@test -n "$(ACCOUNT)" || (echo "ACCOUNT is required for $(NETWORK)" && exit 1)
	@test -n "$(SENDER_ADDRESS)" || (echo "SENDER_ADDRESS is required for $(NETWORK) (address of the deploying account)" && exit 1)
	$(eval CONFIG_FILE := $(if $(PAIR),config/pairs/$(PAIR).toml,$(PAIR_CONFIG_FILE)))
	@test -n "$(CONFIG_FILE)" || (echo "Error: Either PAIR or PAIR_CONFIG_FILE is required"; echo "Usage examples:"; echo "  make guard-deploy NETWORK=berachain PAIR=honey-wbera"; echo "  make guard-deploy NETWORK=berachain PAIR_CONFIG_FILE=config/pairs/custom.toml"; echo "Available pairs:"; ls config/pairs/*.toml 2>/dev/null | xargs -I {} basename {} .toml || echo "No pair configurations found"; exit 1)
	@test -f "$(CONFIG_FILE)" || (echo "Error: Configuration file $(CONFIG_FILE) not found"; echo "Available pairs:"; ls config/pairs/*.toml 2>/dev/null | xargs -I {} basename {} .toml || echo "No pair configurations found"; exit 1)
	@echo "Deploying guard for pair using $(CONFIG_FILE) on $(NETWORK)..."
	@echo "Sender address: $(SENDER_ADDRESS)"
	PAIR_CONFIG_FILE="$(CONFIG_FILE)" $(FORGE_GUARD_SCRIPT) \
		--rpc-url $(call get_rpc_url,$(NETWORK)) \
		--account $(ACCOUNT) \
		--sender $(SENDER_ADDRESS) \
		--broadcast \
		$(call get_verify_flag,$(NETWORK)) \
		-vvv

guard-list-pairs:
	@echo "Available pair configurations:"
	@ls config/pairs/*.toml 2>/dev/null | while read -r file; do \
		pair_name=$$(basename "$$file" .toml); \
		echo "  $$pair_name"; \
		if [ -f "$$file" ]; then \
			grep "^pair_name" "$$file" | sed 's/^/    /'; \
		fi; \
	done || echo "No pair configurations found"

guard-check-config:
	@if [ -n "$(PAIR)" ]; then \
		config_file="config/pairs/$(PAIR).toml"; \
	elif [ -n "$(PAIR_CONFIG_FILE)" ]; then \
		config_file="$(PAIR_CONFIG_FILE)"; \
	else \
		echo "Error: Either PAIR or PAIR_CONFIG_FILE is required"; \
		exit 1; \
	fi; \
	test -f "$$config_file" || (echo "Error: Configuration file $$config_file not found" && exit 1); \
	echo "Configuration for $$config_file:"; \
	echo ""; \
	cat "$$config_file"; \
	echo ""; \
	echo "Common configuration (config/common.toml):"; \
	echo ""; \
	if [ -f "config/common.toml" ]; then \
		cat "config/common.toml"; \
	else \
		echo "Warning: config/common.toml not found"; \
	fi

# Unified deployment target
.PHONY: deploy

deploy:
	@test -n "$(NETWORK)" || (echo "Error: NETWORK is required. Use: make deploy NETWORK=<network>" && echo "Available networks: $(SUPPORTED_NETWORKS)" && exit 1)
	@echo "$(SUPPORTED_NETWORKS)" | grep -wq "$(NETWORK)" || (echo "Error: Unknown network '$(NETWORK)'" && echo "Available networks: $(SUPPORTED_NETWORKS)" && exit 1)
	@test -n "$(ACCOUNT)" || (echo "ACCOUNT is required for $(NETWORK)" && exit 1)
	@test -n "$(OWNER_ADDRESS)" || (echo "OWNER_ADDRESS is required for $(NETWORK)" && exit 1)
	@echo "Deploying to $(NETWORK)..."
	$(FORGE_SCRIPT) \
		--rpc-url $(call get_rpc_url,$(NETWORK)) \
		--account $(ACCOUNT) \
		--broadcast \
		$(call get_verify_flag,$(NETWORK)) \
		-vvvv

# ScopeGuard management commands
.PHONY: set-target-allowed set-scoped set-allowed-function transfer-ownership

set-target-allowed:
	@test -n "$(NETWORK)" || (echo "Error: NETWORK is required" && exit 1)
	@test -n "$(GUARD_ADDRESS)" || (echo "Error: GUARD_ADDRESS is required" && exit 1)
	@test -n "$(TARGET_ADDRESS)" || (echo "Error: TARGET_ADDRESS is required" && exit 1)
	@test -n "$(ALLOWED)" || (echo "Error: ALLOWED is required (true/false)" && exit 1)
	@test -n "$(ACCOUNT)" || (echo "Error: ACCOUNT is required" && exit 1)
	@echo "$(SUPPORTED_NETWORKS)" | grep -wq "$(NETWORK)" || (echo "Error: Unknown network '$(NETWORK)'" && echo "Available networks: $(SUPPORTED_NETWORKS)" && exit 1)
	@if [ "$(DRY_RUN)" = "true" ]; then \
		echo "DRY RUN: Simulating setTargetAllowed=$(ALLOWED) for $(TARGET_ADDRESS) on ScopeGuard $(GUARD_ADDRESS) via $(NETWORK)..."; \
	else \
		echo "Setting target allowed=$(ALLOWED) for $(TARGET_ADDRESS) on ScopeGuard $(GUARD_ADDRESS) via $(NETWORK)..."; \
	fi
	$(call get_cast_cmd) $(GUARD_ADDRESS) "setTargetAllowed(address,bool)" $(TARGET_ADDRESS) $(ALLOWED) \
		--rpc-url $(call get_rpc_url,$(NETWORK)) \
		--account $(ACCOUNT)

set-scoped:
	@test -n "$(NETWORK)" || (echo "Error: NETWORK is required" && exit 1)
	@test -n "$(GUARD_ADDRESS)" || (echo "Error: GUARD_ADDRESS is required" && exit 1)
	@test -n "$(TARGET_ADDRESS)" || (echo "Error: TARGET_ADDRESS is required" && exit 1)
	@test -n "$(SCOPED)" || (echo "Error: SCOPED is required (true/false)" && exit 1)
	@test -n "$(ACCOUNT)" || (echo "Error: ACCOUNT is required" && exit 1)
	@echo "$(SUPPORTED_NETWORKS)" | grep -wq "$(NETWORK)" || (echo "Error: Unknown network '$(NETWORK)'" && echo "Available networks: $(SUPPORTED_NETWORKS)" && exit 1)
	@if [ "$(DRY_RUN)" = "true" ]; then \
		echo "DRY RUN: Simulating setScoped=$(SCOPED) for target $(TARGET_ADDRESS) on ScopeGuard $(GUARD_ADDRESS) via $(NETWORK)..."; \
	else \
		echo "Setting scoped=$(SCOPED) for target $(TARGET_ADDRESS) on ScopeGuard $(GUARD_ADDRESS) via $(NETWORK)..."; \
	fi
	$(call get_cast_cmd) $(GUARD_ADDRESS) "setScoped(address,bool)" $(TARGET_ADDRESS) $(SCOPED) \
		--rpc-url $(call get_rpc_url,$(NETWORK)) \
		--account $(ACCOUNT)

set-allowed-function:
	@test -n "$(NETWORK)" || (echo "Error: NETWORK is required" && exit 1)
	@test -n "$(GUARD_ADDRESS)" || (echo "Error: GUARD_ADDRESS is required" && exit 1)
	@test -n "$(TARGET_ADDRESS)" || (echo "Error: TARGET_ADDRESS is required" && exit 1)
	@test -n "$(FUNCTION_SIG)" || (echo "Error: FUNCTION_SIG is required (e.g., 'transfer(address,uint256)')" && exit 1)
	@test -n "$(ALLOWED)" || (echo "Error: ALLOWED is required (true/false)" && exit 1)
	@test -n "$(ACCOUNT)" || (echo "Error: ACCOUNT is required" && exit 1)
	@echo "$(SUPPORTED_NETWORKS)" | grep -wq "$(NETWORK)" || (echo "Error: Unknown network '$(NETWORK)'" && echo "Available networks: $(SUPPORTED_NETWORKS)" && exit 1)
	@echo "Getting function selector for $(FUNCTION_SIG)..."
	$(eval SELECTOR := $(shell cast sig "$(FUNCTION_SIG)"))
	@echo "Function selector: $(SELECTOR)"
	@if [ "$(DRY_RUN)" = "true" ]; then \
		echo "DRY RUN: Simulating setAllowedFunction allowed=$(ALLOWED) for function $(FUNCTION_SIG) on target $(TARGET_ADDRESS) on ScopeGuard $(GUARD_ADDRESS) via $(NETWORK)..."; \
	else \
		echo "Setting allowed=$(ALLOWED) for function $(FUNCTION_SIG) on target $(TARGET_ADDRESS) on ScopeGuard $(GUARD_ADDRESS) via $(NETWORK)..."; \
	fi
	$(call get_cast_cmd) $(GUARD_ADDRESS) "setAllowedFunction(address,bytes4,bool)" $(TARGET_ADDRESS) $(SELECTOR) $(ALLOWED) \
		--rpc-url $(call get_rpc_url,$(NETWORK)) \
		--account $(ACCOUNT)

transfer-ownership:
	@test -n "$(NETWORK)" || (echo "Error: NETWORK is required" && exit 1)
	@test -n "$(GUARD_ADDRESS)" || (echo "Error: GUARD_ADDRESS is required" && exit 1)
	@test -n "$(NEW_OWNER)" || (echo "Error: NEW_OWNER is required" && exit 1)
	@test -n "$(ACCOUNT)" || (echo "Error: ACCOUNT is required" && exit 1)
	@echo "$(SUPPORTED_NETWORKS)" | grep -wq "$(NETWORK)" || (echo "Error: Unknown network '$(NETWORK)'" && echo "Available networks: $(SUPPORTED_NETWORKS)" && exit 1)
	@if [ "$(DRY_RUN)" = "true" ]; then \
		echo "DRY RUN: Simulating ownership transfer of ScopeGuard $(GUARD_ADDRESS) to $(NEW_OWNER) via $(NETWORK)..."; \
	else \
		echo "Transferring ownership of ScopeGuard $(GUARD_ADDRESS) to $(NEW_OWNER) via $(NETWORK)..."; \
	fi
	$(call get_cast_cmd) $(GUARD_ADDRESS) "transferOwnership(address)" $(NEW_OWNER) \
		--rpc-url $(call get_rpc_url,$(NETWORK)) \
		--account $(ACCOUNT)

# Utility targets
.PHONY: help status

help:
	@echo "ScopeGuard Deployment Commands:"
	@echo ""
	@echo "Setup:"
	@echo "  make install           Install dependencies"
	@echo "  make build             Compile contracts"
	@echo "  make clean             Clean build artifacts"
	@echo "  make lint              Run Solidity linter"
	@echo "  make format            Format Solidity code"
	@echo "  make format-check      Check Solidity code formatting"
	@echo ""
	@echo "Guard Deployment (New Automated System):"
	@echo "  make guard-deploy NETWORK=berachain PAIR=honey-wbera ACCOUNT=deployer SENDER_ADDRESS=0x..."
	@echo "                             Deploy guard for specific pair using config/pairs/<pair>.toml"
	@echo "  make guard-deploy NETWORK=berachain PAIR_CONFIG_FILE=config/pairs/custom.toml ACCOUNT=deployer SENDER_ADDRESS=0x..."
	@echo "                             Deploy guard using custom configuration file"
	@echo "  make guard-list-pairs      List all available pair configurations"
	@echo "  make guard-check-config PAIR=honey-wbera"
	@echo "                             Check configuration for specific pair"
	@echo ""
	@echo "Legacy Deployment:"
	@echo "  make deploy NETWORK=arbitrum   Deploy to Arbitrum One"
	@echo "  make deploy NETWORK=berachain  Deploy to Berachain"
	@echo ""
	@echo "ScopeGuard Management:"
	@echo "  make set-target-allowed NETWORK=<network> GUARD_ADDRESS=<guard> TARGET_ADDRESS=<target> ALLOWED=<true/false>"
	@echo "                             Allow a target address on ScopeGuard"
	@echo "  make set-scoped NETWORK=<network> GUARD_ADDRESS=<guard> TARGET_ADDRESS=<target> SCOPED=<true/false>"
	@echo "                             Set scoped status for a target on ScopeGuard"
	@echo "  make set-allowed-function NETWORK=<network> GUARD_ADDRESS=<guard> TARGET_ADDRESS=<target> FUNCTION_SIG=<function_sig> ALLOWED=<true/false>"
	@echo "                             Set allowed function for a target on ScopeGuard"
	@echo "  make transfer-ownership NETWORK=<network> GUARD_ADDRESS=<guard> NEW_OWNER=<new_owner>"
	@echo "                             Transfer ownership of ScopeGuard to a new owner"
	@echo ""
	@echo "Dry Run Mode:"
	@echo "  Add DRY_RUN=true to any management command to simulate the transaction without executing it"
	@echo "  Example: make set-target-allowed NETWORK=arbitrum GUARD_ADDRESS=0x... TARGET_ADDRESS=0x... ALLOWED=true DRY_RUN=true"
	@echo ""
	@echo "Supported Networks: $(SUPPORTED_NETWORKS)"
	@echo ""
	@echo "Environment Variables:"
	@echo "  ACCOUNT                Forge account name (required for deployments)"
	@echo "  SENDER_ADDRESS         Address of the deploying account (required for guard deployments)"
	@echo "  PAIR                   Pair name (e.g., honey-wbera) - will use config/pairs/<pair>.toml"
	@echo "  PAIR_CONFIG_FILE       Direct path to pair configuration file"
	@echo "  GUARD_ADDRESS          ScopeGuard contract address (for management commands)"
	@echo "  TARGET_ADDRESS         Target address to allow (for set-target-allowed command)"
	@echo "  FUNCTION_SIG           Function signature (e.g., 'transfer(address,uint256)') (for set-allowed-function)"
	@echo "  ALLOWED                Allow/disallow flag (true/false) (for set-target-allowed and set-allowed-function)"
	@echo "  NEW_OWNER              New owner address (for transfer-ownership)"
	@echo "  DRY_RUN                Dry run mode flag (true/false) - simulates transactions without executing"

status:
	@echo "Current environment:"
	@echo "NETWORK: $(NETWORK)"
	@echo "PAIR: $(PAIR)"
	@echo "PAIR_CONFIG_FILE: $(PAIR_CONFIG_FILE)"
	@echo "GUARD_ADDRESS: $(GUARD_ADDRESS)"
	@echo "TARGET_ADDRESS: $(TARGET_ADDRESS)"
	@echo "SCOPED: $(SCOPED)"
	@echo "FUNCTION_SIG: $(FUNCTION_SIG)"
	@echo "ALLOWED: $(ALLOWED)"
	@echo "NEW_OWNER: $(NEW_OWNER)"
	@echo "DRY_RUN: $(DRY_RUN)"
	@if [ -n "$(ACCOUNT)" ]; then echo "ACCOUNT: $(ACCOUNT)"; else echo "ACCOUNT: [NOT SET]"; fi
	@if [ -n "$(SENDER_ADDRESS)" ]; then echo "SENDER_ADDRESS: $(SENDER_ADDRESS)"; else echo "SENDER_ADDRESS: [NOT SET]"; fi
