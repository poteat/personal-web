---
title: "Unchained Tuple Types"
date: 2021-01-09T16:33:40-08:00
categories: [typescript]
tags: [typescript, programming, tuples, type system]
---

The `asserts` syntax of the as-yet unreleased Typescript 4.2 allows us to interleave mutative runtime code with type annotations to express type mutations in a powerful way.

This allows us to do away with the chaining syntax as described in my earlier article, **[Chained Tuple Types](https://mpote.at/post/programming/chained-tuple-types.md)**, and express our Set mutations in a much more familiar iterative way:

```ts
const set: Set = new Set();

set.insert(2);
set.insert(4);
set.insert(8);
set.remove(4);

const hasResult1 = set.has(8); // :: true
const hasResult2 = set.has(4); // :: false

const result = set.value(); // :: [2, 8]
```

This pattern allows us to simulate dependent types that additionally depend on control-flow analysis. That is, we can facilitate the type-level reasoning that because we inserted `4` and then removed it, it is not present when we serialize the result.

I am not familiar with other mainstream programming languages that can express such a deep level of type safety and compile-time inference.

## Addendum: The Gritty Details

Using the `Filter` and `Has` utility types discussed in previous articles, as follows is the updated implementation of `Set` which utilizes the `asserts` capability.

```ts
type Filter<T extends unknown[], N> = T extends []
  ? []
  : T extends [infer H, ...infer R]
  ? H extends N
    ? Filter<R, N>
    : [H, ...Filter<R, N>]
  : T;

type Has<T extends unknown[], X> = X extends T[number] ? true : false;

export class Set<Elements extends number[] = []> {
  private elements: number[] = [];

  public insert<SpecificValue extends number>(
    x: SpecificValue
  ): asserts this is Has<
    this extends Set<infer E> ? E : never,
    SpecificValue
  > extends true
    ? Set<Elements>
    : Set<[...Elements, SpecificValue]> {
    this.elements.push(x);
  }

  public remove<SpecificValue extends number>(
    x: SpecificValue
  ): asserts this is Set<Filter<Elements, SpecificValue>> {
    this.elements = this.elements.filter((y) => x === y);
  }

  public has<SpecificValue extends number>(
    x: SpecificValue
  ): Has<this extends Set<infer E> ? E : never, SpecificValue> {
    return this.elements.includes(x) as any;
  }

  public value(): this extends Set<infer E> ? E : never {
    return this.elements as any;
  }
}
```

An important part of the above implementation is the "`this extends Set<infer E> ? E : never`" pattern. One would intuitively think that this should be equivalent to just "`Elements`", but this is not so. The former representation bypasses the intersection wall associated with type assertions by interfering with a certain step in the type inference.

### Intersection Wall

All type assertions involving `this` eventually run into a problem: Because of how the type system is designed, type assertions cannot easily overwrite or contradict the previous type of the object. Instead, an intersection is applied such that all applicable type assertions are applied at once. But because e.g. `[] & [2] & [2, 4]` is simplified to `never`, we need to take care that we bypass this intersection problem.