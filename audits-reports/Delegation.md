# Smart Contract Security Review

## Vulnerability Report

### Title
Ownership Takeover via Unsafe `delegatecall` in Fallback Function  

### Severity
Critical  

### Category
Access Control / Unsafe `delegatecall` / Storage Context Confusion  

---

## Summary

The `Delegation` contract forwards arbitrary calldata to another contract (`Delegate`) using `delegatecall` inside its fallback function.  

Because `delegatecall` executes code in the context of the calling contract's storage, any function in the `Delegate` contract can modify the storage of the `Delegation` contract. An attacker can call the `pwn()` function through the fallback mechanism, which sets `owner = msg.sender`. Since the code executes in the storage context of `Delegation`, the attacker becomes the owner of the proxy contract.  

---

## Intended Functionality

The contract implements a delegation pattern where unknown function calls are forwarded to a logic contract (`Delegate`).  
**Goals:**  
- Allow logic to be executed from an external contract.  
- Maintain state (storage) in the primary contract (`Delegation`).  
- Provide a flexible, upgradeable-like architecture.  

---

## Root Cause

The vulnerability stems from two core architectural flaws:

###  Unsafe `delegatecall` Usage
The fallback function blindly forwards any `msg.data` to the `Delegate` contract:  
`(bool result,) = address(delegate).delegatecall(msg.data);`  
This allows an attacker to trigger **any** public function existing in the `Delegate` contract.

###  Storage Context Confusion
`delegatecall` runs the code of the target contract but uses the **storage, balance, and address** of the calling contract.  
In the `Delegate` contract, the `pwn()` function is defined as:  
`function pwn() public { owner = msg.sender; }`  

Since both `Delegate` and `Delegation` have `address public owner` declared as their first state variable, they both map to **Storage Slot 0**. When `pwn()` executes via `delegatecall`, it overwrites Slot 0 of the `Delegation` contract.

---

## Impact

- **Full Contract Takeover:** An attacker becomes the official `owner` of the `Delegation` contract.
- **Administrative Control:** The attacker gains access to any functions protected by an `onlyOwner` modifier.
- **Permanent Compromise:** The original owner is displaced and cannot regain control unless the attacker relinquishes it.

---

## Proof of Concept (PoC)

1. **Identify the Target:** The `Delegation` contract (Proxy) and `Delegate` contract (Logic).
2. **Craft the Payload:** The attacker needs to call the `pwn()` function. The data sent must be the function selector of `pwn()`, which is `keccak256("pwn()").slice(0,4)`.
3. **Trigger the Fallback:**
   ```javascript
   // Using Ethers.js / Web3.js console
   await contract.sendTransaction({
     data: web3.utils.sha3("pwn()").slice(0,10) 
   });
   ```
4. **Execution Flow:**
   - `Delegation` receives the transaction.
   - No `pwn()` function exists in `Delegation`, so `fallback()` triggers.
   - `delegatecall` executes `Delegate.pwn()` inside `Delegation`'s context.
   - `owner` (Slot 0) is updated to the Attacker's address.

**Result:** `Delegation.owner() == Attacker`.

---

## Why This Is Critical

- **Complete Takeover:** There is no higher level of privilege than `owner`.
- **Zero Requirements:** The attack requires no special permissions and costs only a small amount of gas.
- **Real-World Relevance:** This is a classic "Proxy" vulnerability. Similar logic errors led to the infamous **Parity Multi-sig Wallet hack**, where $30M+ was stolen/frozen.
- **Single Transaction:** The exploit is atomic and completed in one step.

---

## Recommended Remediations 

### ✔ Fix 1: Restrict `delegatecall` Access
Do not forward arbitrary data to a delegate contract in a public fallback function unless the delegate contract is strictly controlled and contains no administrative logic.

### ✔ Fix 2: Use Established Proxy Standards
Follow audited patterns like **EIP-1967** and use the **OpenZeppelin Proxy library**. These standards use specific, randomized storage slots for administrative variables (like `owner` or `implementation`) to prevent "storage collisions."

### ✔ Fix 3: Implement Function Whitelisting
If a fallback must use `delegatecall`, implement a whitelist of allowed function selectors to prevent sensitive functions like `pwn()` or `initialize()` from being called by unauthorized users.

### ✔ Fix 4: Separate Logic and Administration
Ensure that logic contracts (Implementation) cannot modify administrative state variables (like ownership) through simple public functions. Critical state changes should always require an `onlyOwner` check within the context of the proxy.