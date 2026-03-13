# Smart Contract Security Review

## Vulnerability Report

### Title
Predictable Randomness via Block Variables  

### Severity
High (Critical if real funds were involved)  

### Category
Weak Randomness / On-Chain Predictability / Insecure Use of Block Variables  

---

## Summary

The contract attempts to implement a coin flip game using the previous block's hash as a source of entropy.  

Since `blockhash(block.number - 1)` is publicly accessible and fully deterministic within a transaction, an attacker can replicate the exact randomness calculation inside an attack contract and always predict the correct outcome before calling the `flip()` function.  

This allows the attacker to win the game indefinitely with a 100% success rate.  

---

## Intended Functionality

The contract intends to:
- Generate a pseudo-random boolean outcome.
- Allow users to guess the result (`true`/`false`).
- Increment `consecutiveWins` when the guess is correct.
- Reset the counter to zero when the guess is incorrect.

The developer assumes that because the blockhash changes every block, players cannot predict the result.  

---

## Root Cause

The root cause is the **use of publicly accessible and deterministic blockchain data as a randomness source.**  

Specifically:  
`uint256 blockValue = uint256(blockhash(block.number - 1));`  

**Important Clarification:**  
The vulnerability is **not** because variables like `FACTOR` are public. Even if every variable were `private`, the attack would still work. The fundamental problem is that `blockhash`, `block.number`, and all on-chain computations are visible and reproducible by any other contract executing within the same block.  

---

## Impact

An attacker can:  
1. Predict every coin flip result with zero margin of error.  
2. Win indefinitely to reach the required win streak.  
3. In a real-world betting scenario, this would lead to **unlimited profit extraction** and **protocol insolvency**.  

---

## Proof of Concept (PoC)

An attacker uses an exploit contract to calculate the "random" value in the same transaction:  

```solidity
// Exploit Contract Logic
function attack() public {
    // 1. Replicate the target's "randomness" logic
    uint256 blockValue = uint256(blockhash(block.number - 1));
    uint256 coinFlip = blockValue / FACTOR;
    bool side = (coinFlip == 1 ? true : false);

    // 2. Since both contracts run in the same block, the values match perfectly
    // 3. Call the target with the guaranteed correct guess
    coinFlipContract.flip(side);
}
```

**Result:** The attacker wins every single time the `attack()` function is called in different blocks.  

---

## Why This Is Critical

- **Total Predictability:** Randomness is the foundation of fairness. Without it, the game mechanics are entirely broken.  
- **No Cost to Exploit:** No brute force or miner collusion is required; it is a simple logic replication.  
- **Standard Vulnerability:** This is one of the most common pitfalls in Solidity development—assuming that "hard to find" data is the same as "random" data.  

---

## Recommended Remediations 

### ✔ Fix 1: Use Chainlink VRF (Best Practice)
For true randomness on Ethereum, use a **Verifiable Random Function (VRF)**.  
- **Benefits:** Provides cryptographically secure, unpredictable values with on-chain verification that the provider did not tamper with the result.  

### ✔ Fix 2: Commit–Reveal Scheme
Implement a two-step process:  
1. **Commit:** The user (or dealer) submits a hash of a secret value.  
2. **Reveal:** Later, the secret is revealed, and the contract verifies it matches the hash before using it to generate the result.  
- **Note:** This prevents same-block prediction by forcing the "secret" to be revealed in a later block.  

### ✔ Fix 3: Off-Chain Randomness + Signature
Generate randomness in a secure off-chain environment and pass the result to the contract along with a cryptographic signature to prove authenticity.