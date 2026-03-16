# Smart Contract Security Review

## Vulnerability Report

### Title
Denial of Service (DoS) via Failed Ether Transfer (Push Payment Pattern)  

### Severity
High  

### Category
Denial of Service / Unsafe External Call / Insecure Logic Flow  

---

## Summary

The contract implements a game where users become the "King" by sending more Ether than the current prize.  

When a new king takes the throne, the contract automatically attempts to send the previous prize amount to the former king using `transfer()`. However, if the current king is a malicious contract designed to reject Ether transfers, the `transfer()` call will always revert. Since this transfer happens within the `receive()` function, the entire transaction fails, making it impossible for anyone else to ever become the new king.

---

## Intended Functionality

The contract is intended to:
- Allow users to "buy" the kingship by sending `msg.value >= prize`.
- Refund the previous king their investment (the prize).
- Update the `king` and `prize` variables to the new values.

```solidity
receive() external payable {
    require(msg.value >= prize || msg.sender == owner);
    // VULNERABLE LINE:
    payable(king).transfer(msg.value); 
    king = msg.sender;
    prize = msg.value;
}
```

---

## Root Cause

The root cause is the **Push Payment Pattern** used for a critical state update.  

The contract *pushes* funds to an external address (`king`) before updating its own internal state. Because the `king` address is user-controlled, an attacker can set the `king` to a contract address that does not have a `receive()` or `fallback()` function.  

When the next user tries to become king:
1. The `require` check passes.
2. The contract attempts to `transfer` the prize to the attacker's contract.
3. The attacker's contract rejects the Ether.
4. `transfer()` throws an exception and reverts the entire transaction.

---

## Impact

- **Permanent Denial of Service:** The contract's core functionality is completely and irreversibly broken.  
- **Logic Lockup:** No new king can ever be set, and the attacker remains the king indefinitely.  
- **Loss of Protocol Utility:** In a real-world scenario (like an auction or a crown-sharing game), this would result in a total loss of the platform's purpose.

---

## Proof of Concept (PoC)

An attacker deploys a contract that refuses to accept ETH:

```solidity
contract AttackKing {
    // 1. Become king by sending enough ETH
    function claimKingship(address payable target) public payable {
        (bool success,) = target.call{value: msg.value}("");
        require(success, "Failed to take throne");
    }

    // 2. Intentionally omit receive() and fallback()
    // OR explicitly revert:
    // receive() external payable { revert("I refuse to step down"); }
}
```

**Steps:**
1. Attacker calls `claimKingship` with `1.1 ETH` (assuming prize is 1 ETH).
2. The `King` contract sets `king = AttackKing`.
3. A legitimate user tries to send `1.2 ETH` to the `King` contract.
4. The `King` contract tries to pay `AttackKing`.
5. `AttackKing` rejects the payment.
6. **Result:** The legitimate user's transaction reverts. The attacker stays King forever.

---

## Why This Is Critical

- **External Dependency:** The contract’s availability depends on the behavior of an external party.  
- **Unexpected Failure:** Most developers assume `transfer()` is safe, but because it reverts on failure, it can be used as a weapon to stop execution.  
- **Economic Injustice:** The attacker secures a permanent position for a one-time cost, breaking the game’s economic assumptions.

---

## Recommended Remediations 

### ✔ Fix 1: Pull Payment Pattern (Best Practice)
Instead of automatically pushing funds to the previous king, store the amount in a mapping and allow the previous king to "pull" (withdraw) their funds themselves.

```solidity
mapping(address => uint) public balances;

receive() external payable {
    require(msg.value >= prize || msg.sender == owner);
    
    // Record the refund instead of sending it
    balances[king] += msg.value; 
    
    king = msg.sender;
    prize = msg.value;
}

function withdraw() public {
    uint amount = balances[msg.sender];
    balances[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
}
```

### ✔ Fix 2: Use `call` with Error Handling
If you must use a push pattern, use `call` and do not revert the transaction if the transfer fails. However, this is usually less desirable than the Pull pattern as it might leave ETH stuck in the contract.

```solidity
(bool success, ) = payable(king).call{value: msg.value}("");
// Even if success is false, we continue to update the king
king = msg.sender;
prize = msg.value;
```

### ✔ Fix 3: Favor "Pull" over "Push" for External Interactions
As a general rule in Solidity, whenever you interact with an external address, assume it might fail (maliciously or accidentally). Designing around user-initiated withdrawals is the standard way to mitigate DoS risks.