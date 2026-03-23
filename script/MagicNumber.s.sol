//SPDX-License-Identifer:UNLICENSED
pragma solidity ^0.8.0;

import "../src/MagicNumber.sol";
import "forge-std/Script.sol";

contract MagicNumSolution is Script {

    MagicNum magicNumber = MagicNum(0x7358B397eFa74Adc45d2397dcefb14580e2cD960);

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        bytes memory bytecode = hex"6008600c60003960086000f3602a5f5260205ff3";

        address solver;
        assembly {
            solver := create(0, add(bytecode, 0x20), mload(bytecode))
        }

        magicNumber.setSolver(solver);

        vm.stopBroadcast();
    }
}