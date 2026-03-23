# Smart Contract Security Review

## Vulnerability Report

### Title
Denial   

### Severity
Critical

### Category
Denial of Service via Gas Griefing 

---

## Vulnerability Summary

The `Denial` contract implements a withdrawal mechanism where:
*   1% of funds are sent to a designated **partner**.
*   1% of funds are sent to the **owner**.

However, the contract contains a critical **Denial of Service (DoS)** vulnerability that allows a malicious partner to permanently block all withdrawals, effectively freezing the contract's funds.

### Root Cause

The vulnerability stems from the following line:
```solidity
partner.call{value: amountToSend}("");
```
1.  **Gas Forwarding:** By default, `address.call` forwards all remaining gas to the recipient.
2.  **Unchecked Return Value:** The contract does not check if the call succeeded; it simply proceeds to the next line.
3.  **Dependent Execution:** The next line is `payable(owner).transfer(amountToSend)`. The `transfer()` function requires a stipend of **2300 gas** to complete.

If the `partner` is a contract that consumes all forwarded gas (e.g., via an infinite loop), there will be insufficient gas left for the `owner.transfer()` to execute. Because the `transfer()` function reverts on failure, the entire `withdraw()` transaction reverts.

---

## Attack Scenario

1.  **Attacker Entry:** The attacker calls `setWithdrawPartner(attacker_contract)`.
2.  **Malicious Implementation:** The attacker deploys a contract with a malicious `receive` or `fallback` function:
    ```solidity
    receive() external payable {
        // Consumes all available gas
        while(true) {} 
    }
    ```
3.  **The Trigger:** When anyone calls `withdraw()`:
    *   `call()` forwards all remaining gas to the attacker.
    *   The attacker enters an infinite loop, exhausting the gas limit.
    *   The transaction runs out of gas at the `transfer()` step and **reverts**.

---

## Impact

*   **Fund Lockup:** The owner is permanently unable to withdraw their share of the funds.
*   **Protocol Failure:** The contract’s core functionality is completely broken.
*   **Permanent DoS:** Since the partner can only be changed by the partner or owner, and the owner cannot successfully execute a transaction that interacts with the partner logic, the contract is bricked.

---

## Code Reference

```solidity
function withdraw() public {
    uint256 amountToSend = address(this).balance / 100;

    // VULNERABLE: Forwards all gas to an untrusted contract
    partner.call{value: amountToSend}(""); 

    // This will fail if the line above consumes all gas
    payable(owner).transfer(amountToSend); 

    timeLastWithdrawn = block.timestamp;
    withdrawPartnerBalances[partner] += amountToSend;
}
```

---

## Why This Happens

| Behavior | Effect |
| :--- | :--- |
| **`call()`** | Forwards all available gas to the recipient. |
| **Attacker** | Intentionally consumes all gas (Griefing). |
| **`transfer()`** | Requires a fixed amount of gas (2300) to complete. |
| **Result** | Transaction reverts due to "Out of Gas." |

---

## Recommended Remediations

### 1. Use the Pull Payment Pattern (Best Practice)
Instead of pushing funds to the partner and owner in a single transaction, store the balances in a mapping and allow each party to withdraw their funds independently. This isolates the external call risk.

### 2. Limit Gas Forwarding
If you must use a "Push" pattern, explicitly cap the gas sent to the untrusted partner to ensure enough remains for the owner's transfer.
```solidity
partner.call{value: amountToSend, gas: 10000}("");
```

### 3. Use `call` for the Owner Transfer
The `transfer()` function is generally discouraged because it reverts on failure. Using `call` for the owner transfer would still fail if there is no gas, but it is better practice to handle the partner call in a way that doesn't affect the owner.

### 4. Isolate External Calls
Never perform multiple external transfers to different parties in the same function if one party can interfere with the other. Ensure that a failure (or gas exhaustion) in one call does not prevent the other from completing.