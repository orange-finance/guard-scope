// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.6;

import "forge-std/Script.sol";
import "forge-std/StdToml.sol";
import "../contracts/ScopeGuard.sol";

/// @title BeranciaGuardSetup
/// @notice Script for deploying and configuring ScopeGuard for Berancia
contract BeranciaGuardSetup is Script {
    using stdToml for string;

    struct ContractConfig {
        address contractAddress;
        string[] functions;
    }

    struct PairConfig {
        string pairName;
        address owner;
        string liquidityProtocolName;
        address liquidityProtocolAddress;
        string[] liquidityProtocolFunctions;
        address infraredVault;
        address bearnVault;
        address berapawVault;
    }

    struct ConfiguredTarget {
        address targetAddress;
        string targetName;
        bytes4[] allowedSelectors;
        string[] functionSignatures;
        bool isScoped;
    }

    struct DeploymentResult {
        address scopeGuardAddress;
        address finalOwner;
        string pairName;
        ConfiguredTarget[] configuredTargets;
        uint256 totalTargets;
        uint256 totalFunctions;
    }

    // Common configurations loaded from TOML
    mapping(string => ContractConfig) private tokens;
    mapping(string => ContractConfig) private protocols;
    mapping(string => string[]) private commonVaultFunctions;

    // Result tracking
    ConfiguredTarget[] private configuredTargets;
    uint256 private totalFunctionCount;

    function run() external returns (DeploymentResult memory result) {
        string memory pairConfigFile = vm.envString("PAIR_CONFIG_FILE");

        // Load common configurations
        loadCommonConfig();

        // Load pair-specific configuration
        PairConfig memory pairConfig = loadPairConfig(pairConfigFile);

        vm.startBroadcast();

        // Deploy ScopeGuard with deployer as initial owner
        ScopeGuard scopeGuard = new ScopeGuard(msg.sender);
        console.log(
            "ScopeGuard deployed at:",
            vm.toString(address(scopeGuard))
        );
        console.log("Initial owner (deployer):", vm.toString(msg.sender));

        // Configure permissions while deployer is owner
        configureAllPermissions(scopeGuard, pairConfig);

        // Transfer ownership to final owner as last step
        if (pairConfig.owner != msg.sender) {
            scopeGuard.transferOwnership(pairConfig.owner);
            console.log(
                "Ownership transferred to:",
                vm.toString(pairConfig.owner)
            );
        }

        vm.stopBroadcast();

        console.log("Guard setup completed for pair:", pairConfig.pairName);

        // Prepare result
        result = DeploymentResult({
            scopeGuardAddress: address(scopeGuard),
            finalOwner: pairConfig.owner,
            pairName: pairConfig.pairName,
            configuredTargets: configuredTargets,
            totalTargets: configuredTargets.length,
            totalFunctions: totalFunctionCount
        });

        // Output JSON log
        outputJsonLog(result);

        return result;
    }

    function loadCommonConfig() internal {
        string memory commonToml = vm.readFile("config/common.toml");

        // Load token configurations
        tokens["lbgt"].contractAddress = commonToml.readAddress(
            ".tokens.lbgt.address"
        );
        tokens["lbgt"].functions = commonToml.readStringArray(
            ".tokens.lbgt.functions"
        );

        tokens["ibgt"].contractAddress = commonToml.readAddress(
            ".tokens.ibgt.address"
        );
        tokens["ibgt"].functions = commonToml.readStringArray(
            ".tokens.ibgt.functions"
        );

        tokens["ybgt"].contractAddress = commonToml.readAddress(
            ".tokens.ybgt.address"
        );
        tokens["ybgt"].functions = commonToml.readStringArray(
            ".tokens.ybgt.functions"
        );

        // Load protocol configurations
        protocols["bearn_vault_router"].contractAddress = commonToml
            .readAddress(".protocols.bearn_vault_router.address");
        protocols["bearn_vault_router"].functions = commonToml.readStringArray(
            ".protocols.bearn_vault_router.functions"
        );

        protocols["oogabooga_swap"].contractAddress = commonToml.readAddress(
            ".protocols.oogabooga_swap.address"
        );
        protocols["oogabooga_swap"].functions = commonToml.readStringArray(
            ".protocols.oogabooga_swap.functions"
        );

        protocols["kodiak_island_router"].contractAddress = commonToml
            .readAddress(".protocols.kodiak_island_router.address");
        protocols["kodiak_island_router"].functions = commonToml
            .readStringArray(".protocols.kodiak_island_router.functions");

        protocols["lgbt_mint"].contractAddress = commonToml.readAddress(
            ".protocols.lgbt_mint.address"
        );
        protocols["lgbt_mint"].functions = commonToml.readStringArray(
            ".protocols.lgbt_mint.functions"
        );

        // Load common vault function configurations
        commonVaultFunctions["infrared"] = commonToml.readStringArray(
            ".common_vaults.infrared.functions"
        );
        commonVaultFunctions["bearn"] = commonToml.readStringArray(
            ".common_vaults.bearn.functions"
        );
        commonVaultFunctions["berapaw"] = commonToml.readStringArray(
            ".common_vaults.berapaw.functions"
        );

        console.log("Common configurations loaded");
    }

    function loadPairConfig(
        string memory configFile
    ) internal view returns (PairConfig memory) {
        string memory toml = vm.readFile(configFile);

        return
            PairConfig({
                pairName: toml.readString(".pair_name"),
                owner: toml.readAddress(".owner"),
                liquidityProtocolName: toml.readString(
                    ".liquidity_protocol.name"
                ),
                liquidityProtocolAddress: toml.readAddress(
                    ".liquidity_protocol.address"
                ),
                liquidityProtocolFunctions: toml.readStringArray(
                    ".liquidity_protocol.functions"
                ),
                infraredVault: toml.readAddress(".vaults.infrared"),
                bearnVault: toml.readAddress(".vaults.bearn"),
                berapawVault: toml.readAddress(".vaults.berapaw")
            });
    }

    function configureAllPermissions(
        ScopeGuard scopeGuard,
        PairConfig memory pairConfig
    ) internal {
        // Configure common token permissions
        configureContractPermissions(scopeGuard, tokens["lbgt"], "LBGT Token");
        configureContractPermissions(scopeGuard, tokens["ibgt"], "iBGT Token");
        configureContractPermissions(scopeGuard, tokens["ybgt"], "yBGT Token");
        console.log("Token permissions configured");

        // Configure common protocol permissions
        configureContractPermissions(
            scopeGuard,
            protocols["bearn_vault_router"],
            "Bearn Vault Router"
        );
        configureContractPermissions(
            scopeGuard,
            protocols["oogabooga_swap"],
            "Oogabooga Swap"
        );
        configureContractPermissions(
            scopeGuard,
            protocols["kodiak_island_router"],
            "Kodiak Island Router"
        );
        configureContractPermissions(
            scopeGuard,
            protocols["lgbt_mint"],
            "LGBT Mint"
        );
        console.log("Protocol permissions configured");

        // Configure variable liquidity protocol
        configureLiquidityProtocol(scopeGuard, pairConfig);

        // Configure pair-specific vaults
        configurePairVaults(scopeGuard, pairConfig);
    }

    function configureContractPermissions(
        ScopeGuard scopeGuard,
        ContractConfig memory config,
        string memory targetName
    ) internal {
        if (config.contractAddress == address(0)) return;

        scopeGuard.setTargetAllowed(config.contractAddress, true);
        scopeGuard.setScoped(config.contractAddress, true);

        bytes4[] memory selectors = new bytes4[](config.functions.length);
        for (uint256 i = 0; i < config.functions.length; i++) {
            bytes4 selector = bytes4(keccak256(bytes(config.functions[i])));
            selectors[i] = selector;
            scopeGuard.setAllowedFunction(
                config.contractAddress,
                selector,
                true
            );
        }

        // Record the configuration
        configuredTargets.push(
            ConfiguredTarget({
                targetAddress: config.contractAddress,
                targetName: targetName,
                allowedSelectors: selectors,
                functionSignatures: config.functions,
                isScoped: true
            })
        );

        totalFunctionCount += config.functions.length;
    }

    function configureLiquidityProtocol(
        ScopeGuard scopeGuard,
        PairConfig memory pairConfig
    ) internal {
        if (pairConfig.liquidityProtocolAddress == address(0)) return;

        scopeGuard.setTargetAllowed(pairConfig.liquidityProtocolAddress, true);
        scopeGuard.setScoped(pairConfig.liquidityProtocolAddress, true);

        bytes4[] memory selectors = new bytes4[](
            pairConfig.liquidityProtocolFunctions.length
        );
        for (
            uint256 i = 0;
            i < pairConfig.liquidityProtocolFunctions.length;
            i++
        ) {
            bytes4 selector = bytes4(
                keccak256(bytes(pairConfig.liquidityProtocolFunctions[i]))
            );
            selectors[i] = selector;
            scopeGuard.setAllowedFunction(
                pairConfig.liquidityProtocolAddress,
                selector,
                true
            );
        }

        // Record the configuration
        configuredTargets.push(
            ConfiguredTarget({
                targetAddress: pairConfig.liquidityProtocolAddress,
                targetName: string.concat(
                    "Liquidity Protocol (",
                    pairConfig.liquidityProtocolName,
                    ")"
                ),
                allowedSelectors: selectors,
                functionSignatures: pairConfig.liquidityProtocolFunctions,
                isScoped: true
            })
        );

        totalFunctionCount += pairConfig.liquidityProtocolFunctions.length;

        console.log(
            string.concat(
                "Liquidity protocol configured: ",
                pairConfig.liquidityProtocolName,
                " at ",
                vm.toString(pairConfig.liquidityProtocolAddress)
            )
        );
    }

    function configurePairVaults(
        ScopeGuard scopeGuard,
        PairConfig memory pairConfig
    ) internal {
        // Configure Infrared vault
        if (pairConfig.infraredVault != address(0)) {
            configureVault(
                scopeGuard,
                pairConfig.infraredVault,
                commonVaultFunctions["infrared"],
                "Infrared Vault"
            );
            console.log(
                string.concat(
                    "Infrared vault configured: ",
                    vm.toString(pairConfig.infraredVault)
                )
            );
        }

        // Configure Bearn vault
        if (pairConfig.bearnVault != address(0)) {
            configureVault(
                scopeGuard,
                pairConfig.bearnVault,
                commonVaultFunctions["bearn"],
                "Bearn Vault"
            );
            console.log(
                string.concat(
                    "Bearn vault configured: ",
                    vm.toString(pairConfig.bearnVault)
                )
            );
        }

        // Configure Berapaw vault
        if (pairConfig.berapawVault != address(0)) {
            configureVault(
                scopeGuard,
                pairConfig.berapawVault,
                commonVaultFunctions["berapaw"],
                "Berapaw Vault"
            );
            console.log(
                string.concat(
                    "Berapaw vault configured: ",
                    vm.toString(pairConfig.berapawVault)
                )
            );
        }
    }

    function configureVault(
        ScopeGuard scopeGuard,
        address vaultAddress,
        string[] memory functions,
        string memory vaultName
    ) internal {
        scopeGuard.setTargetAllowed(vaultAddress, true);
        scopeGuard.setScoped(vaultAddress, true);

        bytes4[] memory selectors = new bytes4[](functions.length);
        for (uint256 i = 0; i < functions.length; i++) {
            bytes4 selector = bytes4(keccak256(bytes(functions[i])));
            selectors[i] = selector;
            scopeGuard.setAllowedFunction(vaultAddress, selector, true);
        }

        // Record the configuration
        configuredTargets.push(
            ConfiguredTarget({
                targetAddress: vaultAddress,
                targetName: vaultName,
                allowedSelectors: selectors,
                functionSignatures: functions,
                isScoped: true
            })
        );

        totalFunctionCount += functions.length;
    }

    function outputJsonLog(DeploymentResult memory result) internal {
        console.log("=== DEPLOYMENT RESULT JSON ===");

        // Initialize JSON object with basic information
        string memory json = "deployment_result";
        vm.serializeAddress(
            json,
            "scopeGuardAddress",
            result.scopeGuardAddress
        );
        vm.serializeAddress(json, "finalOwner", result.finalOwner);
        vm.serializeString(json, "pairName", result.pairName);
        vm.serializeUint(json, "totalTargets", result.totalTargets);
        vm.serializeUint(json, "totalFunctions", result.totalFunctions);

        // Serialize configured targets array
        string[] memory targetJsons = new string[](
            result.configuredTargets.length
        );

        for (uint256 i = 0; i < result.configuredTargets.length; i++) {
            string memory targetKey = string.concat("target_", vm.toString(i));

            // Serialize target basic info
            vm.serializeAddress(
                targetKey,
                "targetAddress",
                result.configuredTargets[i].targetAddress
            );
            vm.serializeString(
                targetKey,
                "targetName",
                result.configuredTargets[i].targetName
            );
            vm.serializeBool(
                targetKey,
                "isScoped",
                result.configuredTargets[i].isScoped
            );

            // Serialize selectors array
            string[] memory selectorStrings = new string[](
                result.configuredTargets[i].allowedSelectors.length
            );
            for (
                uint256 j = 0;
                j < result.configuredTargets[i].allowedSelectors.length;
                j++
            ) {
                selectorStrings[j] = bytes4ToHexString(
                    result.configuredTargets[i].allowedSelectors[j]
                );
            }
            vm.serializeString(targetKey, "allowedSelectors", selectorStrings);

            // Serialize function signatures and finalize target object
            targetJsons[i] = vm.serializeString(
                targetKey,
                "functionSignatures",
                result.configuredTargets[i].functionSignatures
            );
        }

        // Finalize the main JSON object
        string memory finalJson = vm.serializeString(
            json,
            "configuredTargets",
            targetJsons
        );

        console.log(finalJson);
        console.log("=== END JSON ===");

        // Write JSON to file for easy access
        string memory outputPath = string.concat(
            "./deployments/guard-deployment-",
            result.pairName,
            ".json"
        );
        vm.writeJson(finalJson, outputPath);
        console.log("JSON written to:", outputPath);
    }

    /// @notice Convert bytes4 selector to 4-byte hex string
    /// @param selector The bytes4 selector to convert
    /// @return The hex string representation (e.g., "0x095ea7b3")
    function bytes4ToHexString(
        bytes4 selector
    ) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(10); // "0x" + 8 hex characters
        str[0] = "0";
        str[1] = "x";

        for (uint256 i = 0; i < 4; i++) {
            str[2 + i * 2] = alphabet[uint8(selector[i]) / 16];
            str[3 + i * 2] = alphabet[uint8(selector[i]) % 16];
        }

        return string(str);
    }
}
