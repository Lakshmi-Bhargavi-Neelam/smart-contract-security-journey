# Audit Report — DexTwo

## Title
Arbitrary Token Injection Leading to Complete Liquidity Drain

## Severity
Critical

## Category
Access Control / Validation Missing, Business Logic Flaw, Price Manipulation

---

## Summary
The DexTwo contract fails to validate that only supported tokens (token1, token2) are used during swaps. 

This allows attackers to introduce malicious or arbitrary ERC20 tokens, manipulate reserve ratios, and drain all legitimate liquidity from the DEX.

---

## Intended Functionality
* Allow swapping between two predefined tokens
* Maintain fair exchange rates
* Restrict swaps to supported assets

---

## Root Cause

### 1. Missing Token Validation
```solidity
function swap(address from, address to, uint256 amount) public {
    // No validation that from/to are token1 or token2
}
```

### 2. Trusting External Token Balances
```solidity
return ((amount * IERC20(to).balanceOf(address(this))) 
        / IERC20(from).balanceOf(address(this)));
```
The contract uses untrusted token reserves in its price calculation. Attackers can manipulate `balanceOf(from)` by using a token they fully control.

### 3. No Whitelisting Mechanism
Any ERC20 token is accepted as an input for the swap, and there are no restrictions on liquidity sources for the pricing formula.

---

## Impact
An attacker can:
* Deploy a fake ERC20 token.
* Add minimal liquidity of that fake token to the DEX (e.g., 1 unit).
* Swap fake tokens for real tokens (token1 and token2) at manipulated rates.

**Result:**
* Complete drain of token1 and token2 reserves.
* Total loss of DEX funds.

---

## Proof of Concept (PoC)

**Attack Steps:**
1. Deploy a malicious ERC20 token.
2. Transfer a small amount of the malicious token (e.g., 1 unit) to the DEX contract.
3. Call the swap function:
   * `dex.swap(fakeToken, token1, 1);`
   * `dex.swap(fakeToken, token2, 1);`

**Result:**
* The DEX reserves of token1 and token2 become 0.
* The attacker gains the full balance of both legitimate tokens.

---

## Why This Is Critical
* No special permissions are required to perform the swap.
* The exploit is trivial to execute and extremely low-cost.
* It works in as few as two transactions.
* It results in the full drainage of the protocol's liquidity.

---

## Recommended Remediations

### 1. Enforce Token Whitelisting
Implement a check to ensure only the two intended tokens can be swapped:
```solidity
require(
    (from == token1 && to == token2) ||
    (from == token2 && to == token1),
    "Invalid tokens"
);
```

### 2. Validate Liquidity Sources
Only allow predefined and trusted tokens to participate in the pricing calculation. Reject all unknown ERC20 addresses.

### 3. Use Secure Pricing Models
Adopt a more robust invariant-based pricing model, such as the constant product formula used by Uniswap:
`x * y = k`

### 4. Add Reserve Safety Checks
Ensure that the output of a swap never exceeds the available reserves in the contract:
```solidity
require(swapAmount <= IERC20(to).balanceOf(address(this)), "Insufficient liquidity");
```