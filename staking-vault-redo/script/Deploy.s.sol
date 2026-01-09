// SPDX-License-Identifier: MIT
pragma solidity >0.8.18;

import "forge-std/Script.sol";
import "../src/StakingVault.sol";
import "../src/MockToken.sol";

contract DeployScript is Script {
    function run() external {
        uint deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        MockToken token = new MockToken();
        console.log("Token Deployed at:", address(token));

        StakingVault vault = new StakingVault(address(token));
        console.log("Vault Deployed at:", address(vault));

        vm.stopBroadcast();
    }
}