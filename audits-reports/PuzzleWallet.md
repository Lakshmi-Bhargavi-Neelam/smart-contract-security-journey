# Smart Contract Audit Report

## Title (Vulnerability Type)

Multiple Critical Vulnerabilities: Storage Collision + Delegatecall Misuse + Multicall Reentrancy (msg.value Reuse)

## Severity

Critical

## Category

* Proxy Storage Collision
* Delegatecall Misconfiguration
* Business Logic Flaw
* Reentrancy-like / msg.value Reuse
* Access Control Bypass

## Summary

The system consists of a proxy (PuzzleProxy) and an implementation contract (PuzzleWallet) using delegatecall. Due to improper storage layout alignment and unsafe use of delegatecall, an attacker can:

* Overwrite critical proxy variables (admin)
* Bypass access control (become owner and whitelist self)
* Exploit multicall to inflate internal balances without sending equivalent ETH
* Drain contract funds
* Take full control of the proxy

Ultimately, the attacker can become the admin of the proxy, gaining complete control over the system.

## Intended Functionality

* PuzzleProxy manages upgradeability and admin control
* PuzzleWallet handles:
    * Deposits
    * Withdrawals
    * Whitelisting users
    * Batch execution via multicall

* Only trusted users (whitelisted) should interact
* Only admin should upgrade contract

## Root Cause

### 1. Storage Collision

Proxy Storage | Wallet Interpretation
--- | ---
pendingAdmin (slot 0) | owner
admin (slot 1) | maxBalance

Due to delegatecall, both contracts share the same storage.

### 2. Unrestricted proposeNewAdmin

```solidity
function proposeNewAdmin(address _newAdmin) external {
    pendingAdmin = _newAdmin;
}
```

* Anyone can call this
* Overwrites slot 0 which corresponds to owner in the wallet

### 3. Unsafe Delegatecall in multicall

```solidity
(bool success,) = address(this).delegatecall(data[i]);
```

* Executes internal functions with:
    * Same msg.sender
    * Same msg.value

### 4. Incorrect Deposit Protection

```solidity
bool depositCalled = false;
```

* Local variable resets in nested multicalls
* Allows multiple deposits using the same msg.value

### 5. Critical Storage Overwrite

```solidity
function setMaxBalance(uint256 _maxBalance)
```

* Writes to slot 1
* Overwrites admin in the proxy

## Impact

* Unauthorized ownership takeover
* Theft of all contract funds
* Full proxy admin takeover
* Ability to upgrade contract to malicious implementation
* Complete system compromise

## Proof of Concept

### Step 1: Become Owner
`proxy.proposeNewAdmin(attacker);`

pendingAdmin maps to slot 0, which makes the attacker the owner.

### Step 2: Whitelist Attacker
`wallet.addToWhitelist(attacker);`

### Step 3: Inflate Balance via Multicall
`multicall([deposit(), multicall([deposit()])])`

Deposit is counted twice with the same ETH.

### Step 4: Drain Funds
`execute(attacker, contractBalance, "");`

### Step 5: Overwrite Admin
`setMaxBalance(uint256(uint160(attacker)));`

slot 1 overwrite makes the attacker the admin.

## Why This is Critical

* Combines multiple vulnerabilities into one exploit chain
* Breaks both access control and financial integrity
* Exploitable by any external user
* Leads to complete protocol takeover
* Demonstrates real-world risks in upgradeable contracts and proxy patterns

## Recommended Remediations

### 1. Align Storage Layout Properly
* Use EIP-1967 storage slots
* Avoid overlapping variables between proxy and implementation

### 2. Restrict Admin Functions
`function proposeNewAdmin(address) external onlyAdmin`

### 3. Avoid Unsafe Delegatecall Usage
* Do not use delegatecall on address(this) for batching
* Use internal function calls instead

### 4. Fix Multicall Logic

Track deposit globally:
`mapping(address => bool) depositCalled;`

Or:
* Track msg.value usage properly
* Prevent nested multicalls

### 5. Avoid Critical State Writes from User Functions
* setMaxBalance should NOT affect admin storage
* Separate proxy and logic storage safely

### 6. Follow Checks-Effects-Interactions Pattern

### 7. Use Established Proxy Standards
* EIP-1967
* OpenZeppelin Transparent Proxy