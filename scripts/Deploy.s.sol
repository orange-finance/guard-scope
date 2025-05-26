// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.6;

import "forge-std/Script.sol";
import "../contracts/ScopeGuard.sol";

contract Deploy is Script {
    function run() external returns (ScopeGuard scopeGuard, address owner) {
        address _owner = vm.envAddress("OWNER_ADDRESS");

        vm.startBroadcast();

        scopeGuard = new ScopeGuard(_owner);
        owner = scopeGuard.owner();

        vm.stopBroadcast();
    }
}
