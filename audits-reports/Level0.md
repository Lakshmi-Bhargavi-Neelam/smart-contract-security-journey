# Smart Contract Security Review

## Vulnerability Report

### Title
Sensitive Data Exposure via Public State Variable  

### Severity
High  

### Category
Information Disclosure / Authentication Bypass  

---

## Summary

The contract stores a sensitive value (`password`) in a public state variable.  

Since all on-chain storage is publicly readable, any user can retrieve the password directly from the blockchain and successfully call the `authenticate()` function.  

This completely breaks the intended authentication mechanism.  

---

## Intended Functionality

The contract attempts to:
- Store a confidential password
- Allow only users who know the password to call `authenticate()`
- Set `cleared = true` upon successful authentication

```solidity
string public password;

function authenticate(string memory passkey) public {
    if(keccak256(abi.encodePacked(passkey)) 
        == keccak256(abi.encodePacked(password))) {
        cleared = true;
    }
}
```

The assumption made by the developer is: **"Only authorized users will know the password."**

---

## Root Cause

The contract ignores a fundamental blockchain property: **All contract storage is publicly readable.**  

Even if a variable is marked `private`, it is still readable from storage using tools like:  
- `cast storage`  
- `eth_getStorageAt`  
- Block explorers  
- Foundry / Hardhat scripts  

Since `password` is declared `public`, it is even easier to retrieve via the auto-generated getter: `password()`. Thus, secrecy based on on-chain storage is impossible.  

---

## Impact

An attacker can:
1. Read the password directly from contract storage.
2. Call `authenticate(password)`.
3. Set `cleared = true`.

This results in a **complete authentication bypass**. The contract’s access control mechanism is fully compromised.

---

## Proof of Concept (Foundry)

After deployment, an attacker can execute the following:

```solidity
// Attacker retrieves the password via the public getter
string memory pwd = level0.password();

// Attacker bypasses the check using the leaked data
level0.authenticate(pwd);
```

**Result:**  
`cleared == true`  
No authorization required.

---

## Why This Is Critical

On Ethereum:
- Smart contracts are transparent
- Storage is publicly accessible
- There are no real “secrets” on-chain

Storing confidential data on-chain and relying on secrecy for authorization is fundamentally insecure.

---

## Recommended Remediations

### ✔ Fix 1: Signature-Based Authentication (Best Practice)
Instead of passwords, use cryptographic signature verification.
**Flow:**
1. User signs a message off-chain using their private key.
2. Contract verifies signature using `ECDSA.recover()`.
3. Authentication is based on wallet ownership.

**Advantages:**
- No secret stored on-chain
- Aligns with Web3 identity model
- Secure and standard practice

### ✔ Fix 2: Avoid On-Chain Secrets
Sensitive data should be:
- Stored off-chain
- Verified through trusted backend systems
- Or handled via zero-knowledge / signature systems

### ✔ Fix 3: Commit–Reveal Scheme (When Applicable)
If secrets must be temporarily hidden:
1. **User submits:** `keccak256(secret + salt)`
2. **Later reveals:** `secret + salt`

**Used for:**
- Fair randomness
- Sealed-bid auctions
- Games (rock-paper-scissors)

**⚠ Important:** Commit–Reveal does not make secrets permanently hidden. It only delays disclosure.