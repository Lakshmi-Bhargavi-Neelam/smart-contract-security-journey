# Smart Contract Security Review

## Vulnerability Report

### Title
Trusting Untrusted External Contract for Critical Logic  

### Severity
High  

### Category
Logic Vulnerability / Trust Assumption Violation  

---

## Summary

The contract relies on an external contract (implementing the `Building` interface) to determine whether a floor is the last floor.  

Because the caller (`msg.sender`) is assumed to be a trusted `Building` contract, an attacker can deploy a malicious contract that implements the interface and manipulates the return value of `isLastFloor()`. Since the `Elevator` calls this function twice during the execution of a single transaction, the attacker can provide inconsistent answers to bypass the logic and set `top = true`.

---

## Intended Functionality

The contract simulates an elevator that should only be able to reach the "top" floor if the building itself confirms that the requested floor is indeed the last one.

```solidity
function goTo(uint _floor) public {
    Building building = Building(msg.sender);

    if (! building.isLastFloor(_floor)) {
        floor = _floor;
        top = building.isLastFloor(floor);
    }
}
```

**Expected behavior:**
1. Elevator asks the building if the given floor is the last floor.
2. If it is **not** the last floor, the elevator moves there.
3. The elevator then checks again to see if it is at the top.

The developer assumes that `isLastFloor` will return a consistent, honest value for a given input.

---

## Root Cause

The root cause is a **Trust Assumption Violation**.  

The contract blindly trusts the `msg.sender` to be a legitimate building and to return consistent data.  
- **Interface Spoofing:** Any address can implement the `Building` interface.
- **State Manipulation:** An external call to an untrusted contract allows that contract to execute its own logic. 
- **Inconsistent Returns:** Because `isLastFloor` is called twice, the external contract can change its internal state between calls to return `false` first (to pass the `if` check) and `true` second (to set `top = true`).

---

## Impact

An attacker can manipulate the elevator logic to reach the top floor regardless of actual building height.
1. The first check `!building.isLastFloor(_floor)` passes because the attacker returns `false`.
2. The elevator sets `floor = _floor`.
3. The second call `building.isLastFloor(floor)` returns `true` because the attacker toggled their internal state.
4. **Result:** `top` becomes `true`, breaking the contract's primary invariant.

---

## Proof of Concept

The attacker deploys a contract that "lies" to the elevator by toggling a boolean:

```solidity
contract AttackBuilding is Building {
    Elevator public elevator;
    bool public isSecondCall = false;

    constructor(address _elevator) {
        elevator = Elevator(_elevator);
    }

    function attack() public {
        elevator.goTo(1); // Any floor number works
    }

    function isLastFloor(uint) external override returns (bool) {
        // Toggle behavior: return false first, then true
        if (!isSecondCall) {
            isSecondCall = true;
            return false;
        } else {
            return true;
        }
    }
}
```

**Result:** `elevator.top()` returns `true`.

---

## Why This Is Critical

Smart contracts operate in a "Trustless" environment.  
- **External Calls = Risk:** Every time a contract calls an external address, it hands over control. If that address is not a verified, trusted entity, the execution flow is no longer under the contract's control.
- **Side Effects:** Functions that are expected to be "pure" or "view" (like checking if a floor is the last) might actually have side effects in a malicious implementation.
- **Logic Bypass:** This pattern is common in "Oracle" or "Callback" vulnerabilities where the order of operations allows a malicious actor to change the "truth" mid-transaction.

---

## Recommended Remediations 

### ✔ Fix 1: Avoid Trusting External Contracts for State
Critical state variables like `top` should be calculated based on internal, authoritative data maintained by the contract itself, rather than external inputs from `msg.sender`.

### ✔ Fix 2: Use Local Variables to Ensure Consistency
Avoid calling the same external function multiple times in a single execution block if you expect the same result. Store the result in a local variable.

```solidity
function goTo(uint _floor) public {
    Building building = Building(msg.sender);
    bool lastFloor = building.isLastFloor(_floor);

    if (!lastFloor) {
        floor = _floor;
        top = lastFloor; // This will always be false
    }
}
```

### ✔ Fix 3: Implement Access Control
If the elevator should only work for a specific building, restrict the `goTo` function so only a trusted, pre-approved building address can call it.

```solidity
require(msg.sender == trustedBuildingAddress, "Unauthorized building");
```