# Smart Contract Audit Report

## Title
Improper Pricing Mechanism Leading to Complete Liquidity Drain

## Severity
Critical

## Category
Business Logic Flaw, Price Manipulation, Lack of Invariant Enforcement

## Summary
The DEX contract implements a token swap mechanism using a naive price calculation formula based solely on current token balances:

(amount * balance_to) / balance_from

This design lacks any invariant (e.g., constant product like Uniswap), allowing attackers to manipulate token prices through repeated swaps, ultimately draining all liquidity from the contract.

## Intended Functionality
The contract is supposed to:

* Allow users to swap between token1 and token2
* Maintain a fair exchange rate based on available liquidity
* Ensure swaps do not break pool balance integrity

## Root Cause
The vulnerability arises due to:

1. Incorrect Pricing Model
return ((amount * IERC20(to).balanceOf(address(this))) / IERC20(from).balanceOf(address(this)));
Price depends only on current balances. No invariant like:
* x * y = k (Uniswap)
* constant sum or oracle pricing

2. No Slippage / Output Validation
The contract does not check if output exceeds reserves. Allows swaps that fully drain one side.

3. Fully Manipulatable State
Each swap changes reserves. Next swap uses updated (manipulated) reserves. Leads to compounding price distortion.

## Impact
An attacker can:

* Repeatedly swap tokens back and forth
* Exploit price imbalance
* Eventually:
* Drain all of token1 or token2
* Extract entire liquidity from the DEX

Total loss of funds in the contract.

## Proof of Concept (PoC)
Attack Strategy:
* Start with equal token balances
* Perform repeated swaps:
* token1 -> token2
* token2 -> token1
* Each swap manipulates price ratio
* Final step:
* Adjust input amount to exactly drain remaining tokens

Key Exploit Logic:
uint256 swapAmount = dex.getSwapPrice(from, to, amount);

if (swapAmount > dexToBalance) {
    amount = dexFromBalance;
}

Result:
* One token reserve becomes 0
* Attacker gains full balance
* DEX becomes unusable

## Why This Is Critical
* 100% fund drain possible
* Exploit requires no special permissions
* Can be executed in a single transaction loop
* Exploits fundamental design flaw (not edge case)

## Recommended Remediations
1. Use Constant Product Formula (AMM)
Implement invariant-based pricing like:
x * y = k
Used in Uniswap

2. Add Slippage Protection
Ensure output does not exceed safe limits. Validate reserves before transfer.

3. Prevent Full Drain
require(swapAmount < IERC20(to).balanceOf(address(this)));

4. Use Oracle-Based Pricing (Optional)
Integrate trusted price feeds. Avoid reserve-only pricing.

5. Limit Swap Impact
Cap max swap percentage per transaction. Prevent large imbalance shifts.