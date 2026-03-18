# Smart Contract Security Review

## Vulnerability Report

### Title
Timelock Bypass via Unrestricted `transferFrom()` (Allowance Abuse)

### Severity
High

### Category
Access Control Bypass / Business Logic Flaw

---

## Summary

The contract attempts to restrict token transfers from the player using a timelock mechanism applied to the `transfer()` function.

However, it fails to enforce the same restriction on `transferFrom()`, allowing an attacker to bypass the timelock using the ERC20 allowance mechanism.

This enables the player to transfer their tokens indirectly before the lock period expires.

---

## Intended Functionality

The contract aims to:
*   Assign the entire token supply to player
*   Prevent the player from transferring tokens until `timeLock` expires

```solidity
modifier lockTokens() {
    if (msg.sender == player) {
        require(block.timestamp > timeLock);
        _;
    } else {
        _;
    }
}
```

Applied only to:
`function transfer(address _to, uint256 _value)`

---

## Root Cause

**1. Incomplete Access Control**  
The restriction is applied only to:
*   `transfer()`

But NOT to:
*   `transferFrom()`
*   `approve()`

**2. Misunderstanding of ERC20 Mechanics**  
ERC20 allows token transfers via:
*   Direct transfer → `transfer()`
*   Delegated transfer → `transferFrom()`

The contract ignores the second pathway.

---

## Impact

An attacker (player) can:
1.  Approve another address (or contract) to spend tokens
2.  Use that address to call `transferFrom()`
3.  Drain the entire balance before the timelock expires

**Result:**
*   Player balance → 0
*   Tokens moved despite active timelock

**Complete bypass of intended restriction**

---

## Proof of Concept

**Step 1: Player approves attacker**  
`naughtCoin.approve(attacker, INITIAL_SUPPLY);`

**Step 2: Attacker drains tokens**  
`IERC20(naughtCoin).transferFrom(player, attacker, amount);`

---

## Recommended Remediations

**✔ Fix 1: Apply Restriction to `transferFrom()`**
```solidity
function transferFrom(address from, address to, uint256 amount)
    public override lockTokens returns (bool)
{
    return super.transferFrom(from, to, amount);
}
```

**✔ Fix 2: Restrict Approvals (Optional Hardening)**
```solidity
function approve(address spender, uint256 amount)
    public override lockTokens returns (bool)
{
    return super.approve(spender, amount);
}
```