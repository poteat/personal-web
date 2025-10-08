---
title: "Capture Semantics"
date: 2025-10-08T11:09:09-07:00
categories: [programming]
tags: [programming, ast, meta, codemod]
---

As part of my efforts on [ts-unify](https://github.com/poteat/ts-unify), I
needed a way to represent 'capturing' and transforming values in a data
structure from one form to another. This article elucidates those extraction
semantics.

<!--more-->

Continuation of [prior article](../towards-declarative-ast-transformation).

## Basic capturing

The capture primitive `$` represents a particlar value to capture from a
structure.

```ts
const matcher = match({
  person: {
    name: "Alice",
    age: $("age"),
  },
});
```

In the above example, the 'capture bag' extracted for a input value of
`{ person: { name: "Alice", age: 200 } }` would be `{ age: 200 }`. This form
minimally specifies that the key 'age' should exist, but the value could be
fulfilled by `null` or `undefined`, as long as the key is present.

Extra keys present on the underlying value but not the specified shape are
ignored.

### Multiple captures

Multiple capture keys simply separately add to the capture bag:

```ts
const matcher = match({
  person: {
    name: "Alice",
    age: $("age"),
  },
  location: $("location"),
});
```

So the capture bag becomes: `{ age, location }` in this case.

### Multiple captures of equivalent capture term

If one capture term with a particular name is present in multiple places in the
shape pattern, this represents a constraint that the two instances must be the
same deeply equivalent value.

```ts
const matcher = match({
  person: {
    name: "Alice",
    age: $("age"),
  },
  pet: {
    age: $("age"),
  },
});
```

So the above matcher only matches if `pet.age` and `person.age` are the same
value.

## Implicit capture by key

If the capture term is named equivalently to its corresponding key, we may elide
the invocation of `$` and leave it as a bare function. The matching engine then
will implicitly bind that key's value to the corresponding bag entry.

```ts
const matcher = match({
  person: {
    name: "Alice",
    age: $,
  },
});
```

This form is equivalent to the one priorly displayed.

## Array element capture position

Tuple and array elements may be captured by emplacing the capture term in the
appropriate slot:

```ts
const matcher = match({
  person: {
    name: "Alice",
    inventory: [$("item")],
  },
});
```

The above specifier says, "only match if the inventory has only one element",
and "extract that element into 'item'" - so the resultant capture bag is
`{ item }`.

### Implicit array element capture

In the case of e.g. `{ inventory: [$] }`, the capture implicitly takes the name
`inventory`.

## Spread array elements

The capture primitive may be used in an array spread case to extract out
subarrays.

```ts
const matcher = match({
  person: {
    name: "Alice",
    inventory: [...$("items"), "pencil"],
  },
});
```

The above matcher only matches if the last element in inventory is `"pencil"`,
and extracts out the prior elements (may result in an empty array) into the
capture term keyed by `"items"`.

### Implicit spread array elements

Equivalently, `{ inventory: ["pencil", ...$] }` would match only if the first
entry is a `"pencil"` value, binding to the `inventory` key in the resultant
capture bag.

## Object spread captures

The capture primitive `$` may also be used in an object spread position. This
assigns all non-pattern-specified keys into the specified capture term.

```ts
const matcher = match({
  person: {
    name: "Alice",
    ...$("attrs"),
  },
});
```

In this case, the capture term `"attrs"` is granted all attributes present on
`person` except for `"name"`.

### Implicit object spread capture

The `$` primitive may also be used as a bare object spread.

```ts
const matcher = match({
  person: {
    name: "Alice",
    ...$,
  },
});
```

In this case, the other attributes are emplaced on a key `"person"` in the
resultant capture bag.

## Full wildcard

If an explicitly named capture is used directly without being on a subobject,
that entire object is supplied on the given capture key:

```ts
const matcher = match($("stuff"));
```

In line with the other examples, the capture bag becomes `{ stuff }`, where
`stuff` has a value of whatever is passed in.

### Implicit full wildcard

If a bare `$` primitive is used, then all keys and values present on the
provided object becomes entries on the capture bag - in other words, the value
provided becomes the capture bag itself.

```ts
const matcher = match($);
```

So in this case, if `{ person: { name: "Alice", age: 200 }}` is provided, then
the underlying capture bag has key `"person"` with that value.

# Destination transforms

The syntax for matching and resultant transformation can in principle have a 1:1
correspondence. So a matching pattern can be alternatively interpreted to
_supply_ mentioned capture terms with their priorly matched value.
