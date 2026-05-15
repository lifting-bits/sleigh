# Common Bug Patterns in Ghidra Decompiler Source

## Strict-weak ordering violations

The most common class of bugs caught by libc++ assertions. A comparator for
`std::sort` or `std::set` must satisfy:

- **Irreflexivity**: `comp(a, a)` must return `false`
- **Asymmetry**: if `comp(a, b)` is true then `comp(b, a)` must be false
- **Transitivity**: if `comp(a, b)` and `comp(b, c)` then `comp(a, c)`

The libc++ assertion message looks like:
```
strict_weak_ordering_check.h:50: libc++ Hardening assertion
  !__comp(*(__first + __a), *(__first + __b)) failed:
  Your comparator is not a valid strict-weak ordering
```

### Pattern 1: Null pointer sentinel without self-check

```cpp
// BUG: when both are null, returns true (violates irreflexivity)
if (ptr == nullptr)
    return true;

// FIX: only return true when the other is non-null
if (ptr == nullptr)
    return (other.ptr != nullptr);
```

Real example: `PullRecord::operator<` in `bitfield.cc` — when both `readOp`
pointers were null, the comparator returned `true`.

### Pattern 2: Special index without self-check

```cpp
// BUG: when comparing the entry point with itself, returns true
if (bl1->getIndex() == 0) return true;

// FIX: check that the other is different
if (bl1->getIndex() == 0) return (bl2->getIndex() != 0);
```

Real example: `FlowBlock::compareFinalOrder` in `block.cc`.

### Pattern 3: Unsafe cast in compareDependency (TypePartial* classes)

The `TypePartialEnum`, `TypePartialStruct`, and `TypePartialUnion` classes have
`compareDependency` methods that cast `op` to their own type. If `op` is actually
the parent container type (not a partial), the cast accesses invalid memory.

```cpp
// BUG: casts op to TypePartialFoo without checking if op IS the container
TypePartialFoo *tp = (TypePartialFoo *) &op;

// FIX: add a guard before the cast
if (container == &op) return 1;  // op is our container
TypePartialFoo *tp = (TypePartialFoo *) &op;
```

Real example: `TypePartialEnum::compareDependency` in `type.cc` (patched in 0005).

## How to audit comparators systematically

1. Search for all `operator<`, `::compare`, and `::compareDependency` functions
2. Search for all `sort(`, `stable_sort(`, and `std::set` usage to find which
   comparators are actually used in sorting contexts
3. For each comparator, mentally trace the case where both arguments are identical
   — does it return false?
4. Check for early-return branches that don't verify the other operand differs
5. For `compareDependency` methods in TypePartial* classes, check for the
   container-guard pattern before unsafe casts
