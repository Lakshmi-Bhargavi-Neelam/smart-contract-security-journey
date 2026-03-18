# Smart Contract Security Review

## Vulnerability Report

### Title

Unrestricted `selfdestruct` Allows Unauthorized Ether Withdrawal

### Severity 
Critical 
 
### Category 
Access Control / Insecure Selfdestruct / Funds Theft  

---

## Summary

The deployed `SimpleToken` contract exposes a `destroy()` function that internally calls `selfdestruct` without any access control. This allows any external user to destroy the contract and redirect all its Ether balance to an arbitrary address.

Additionally, the contract address can be deterministically derived, making “lost” contracts recoverable and exploitable.

---

## Intended Functionality

The system is designed to:
*   Use the `Recovery` contract as a factory to deploy token contracts
*   Allow users to interact with deployed `SimpleToken` instances
*   Accept Ether via `receive()` and manage token balances
*   Provide a cleanup mechanism using `selfdestruct`

---

## Root Cause

The vulnerability arises due to:

**1. Missing Access Control**
```solidity
function destroy(address payable _to) public {
    selfdestruct(_to);
}
```
*   No restriction on who can call `destroy()`
*   Any address can trigger contract destruction

**2. Dangerous Use of `selfdestruct`**
*   Transfers entire contract balance to `_to`
*   Permanently removes contract code

**3. Predictable Contract Address**
Contract addresses are derived using:
`keccak256(rlp([creator_address, nonce]))`
Allows attackers to recover “lost” contract addresses

---

## Impact

An attacker can:
*   Recover the address of deployed token contracts
*   Call `destroy()` on the contract
*   Transfer all Ether to their own address
*   Permanently destroy the contract

 **Results in:**
*   Complete loss of funds
*   Irreversible contract destruction

---

## Proof of Concept

**Step 1: Identify Factory Contract**  
Locate the deployed `Recovery` contract.

**Step 2: Compute Lost Contract Address**  
Using:
*   Factory address
*   Nonce = 1  
`derived_address = keccak256(rlp([factory_address, 1]))`

**Step 3: Interact with Token Contract**  
Call:  
`SimpleToken(derived_address).destroy(attackerAddress);`

**Step 4: Execute Selfdestruct**  
`selfdestruct(attackerAddress);`

**Step 5: Result**  
*   **All ETH** → transferred to attacker
*   **Contract** → destroyed