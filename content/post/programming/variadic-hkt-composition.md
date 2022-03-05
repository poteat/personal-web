---
title: "Variadic HKT Composition"
date: 2022-03-05T00:17:15-08:00
categories: [programming]
tags: [typescript, programming, type-system]
images: ["img/art/angel.png"]
---

In a previous article, [Higher Kinded Types in Typescript](../../programming/higher-kinded-types/), we explored how to encode HKTs, as well as some of their applications.

For example, we could define a value and type-level operation like the following:

```ts
// "hello! hello!"
const result = map(double, map(append("! "), "hello"));
```

On both the type and value levels, the given string goes through a complex operation. In the end though, the type system can still capture and encode the operations being performed.

However, what if we wanted to more cleanly implement the above operation with via composition, while still retaining type knowledge?

```ts
// "hello! hello!"
const result = compose(double, append("! "))("hello");
```

## Binary Composition

For convenience, we will start off on the type level only, and introduce the value level encodings later.

First, let's define the type analogues of `double` and `append`. For any utility types not explained, see the previous article.

```ts
interface DoubleString extends HKT {
  new: (x: Assume<this["_1"], string>) => `${typeof x}${typeof x}`;
}

interface Append<S extends string> extends HKT {
  new: (x: Assume<this["_1"], string>) => `${typeof x}${S}`;
}
```

The type level analogue of their manual composition would be:

```ts
// "hello! hello!"
type Result = Apply<DoubleString, Apply<Append<"! ">, "hello>>>
```

### Simple Binary Composition

To compose multiple HKTs in a simple way, we can create a first-order type that takes in the two HKTs to be composed, as well as the value type to be applied.

```ts
type SimpleCompose<HKT1, HKT2, X> = Apply<HKT1, Apply<HKT2, X>>;
```

The issue with this type is that we must provide the type X when composing the actual HKTs - this is not very useful for us.

Instead, we would like our `Compose` to _itself_ return a HKT that is then filled with a value at a later stage - in line with how composition normally works for value-level functional programming.

### Curried Binary Composition

To provide the 'value' type to be applied at a later step, our `SimpleCompose` should return a type that takes in a type - i.e. `SimpleCompose` itself must be a higher-kinded type of the form:

- `((*) => (*), (*) => (*)) => (*) => (*)`

In other words, `SimpleCompose` takes in _two_ first-order types, represented by `(*) => (*)`, and then returns a first-order type representing the composition of the two input first-order types.

Since `SimpleCompose` is _parameterized_ by first-order types, that makes `SimpleCompose` a second-order type.

```ts
interface SimpleCompose<_1 extends HKT, _2 extends HKT> extends HKT {
  new: (x: this["_1"]) => Apply<_1, Apply<_2, this["_1"]>>;
}

type ExclaimThenDouble = SimpleCompose<DoubleString, Append<"! ">>;

// "hello! hello!"
type SimpleComposeValue = Apply<ExclaimThenDouble, "hello">;
```

## Variadic Composition

It would be best if we could encode `Compose` in a variadic way, so that we can compose 3 or more HKTs without having to nest type applications.

To facilitate this, we will need a recursive analogue to our `Apply`, which I will refer to as `Reduce`.

```ts
type Reduce<HKTs extends HKT[], X> = HKTs extends []
  ? X
  : HKTs extends [infer Head, ...infer Tail]
  ? Apply<Assume<Head, HKT>, Reduce<Assume<Tail, HKT[]>, X>>
  : never;
```

Our base case is when the set of HKTs form an empty tuple, in which case we return the parameter to fill, unmodified.

The recursive type algorithm continues as follows:

- Extract the `Head` and `Tail` of the tuple (the first, and the rest respectively)
- `Apply` X to the result of the recursive `Reduce` call.
- For the recursive reduce call, pass in the `Tail` and X types.

We also use `Assume` for one of its most powerful applications - Typescript cannot properly infer that `Head` extends type `HKT` and that `Tail` extends type `HKT[]`, although it can evaluate such structures with some additional hints.

For the purposes of HKT-level application, we instruct the compiler to _assume_ that `Head` is a `HKT`. Amazingly, this does not make the resultant type too generic to be useful - all possible narrowness is maintained.

> _Note:_ `Reduce` may be an abuse of terminology - usually reduction is applied to an array of values with one reducer function. In this case, instead a tuple of _type functions_ (i.e. HKTs) are being applied to a single value.
>
> Alternative names may include `Squish`, or `Onion`, or perhaps `__Compose` - the latter of which I am reserving for the next section.

From `Reduce`, we can now construct a `Compose` that properly returns a HKT that can be filled with a HKT-level application in a separate step.

```ts
interface Compose<HKTs extends HKT[]> extends HKT {
  new: (x: this["_1"]) => Reduce<HKTs, this["_1"]>;
}

type MyProcess = Compose<[Append<"goodbye!">, DoubleString, Append<"! ">]>;

// "hi! hi! goodbye!"
type MyProcessResult = Apply<MyProcess, "hi">;
```

We now have a HKT-level Compose operator (that acts purely on types). The type of which is the following:

- `((*) => (*)[]) => (*) => (*)`

## Left Composition (i.e. Flow)

Formal function composition order can be hard to understand, since functions are applied to the argument from _left_ to _right_. The following is a reformulation of the above code to encode a `Flow` concept:

```ts
type Reverse<T extends unknown[]> = T extends []
  ? []
  : T extends [infer U, ...infer Rest]
  ? [...Reverse<Rest>, U]
  : never;

interface Flow<HKTs extends HKT[]> extends HKT {
  new: (x: this["_1"]) => Reduce<Reverse<HKTs>, this["_1"]>;
}

type MyFlow = Flow<[Append<"! ">, DoubleString, Append<"goodbye!">]>;

// "hi! hi! goodbye!"
type MyFlowResult = Apply<MyFlow, "hi">;
```

## Conclusion

In the end, we were able to extend our HKT model with support for variadic HKT composition, which facilitates a point-free HKT encoding technique.

This sophisticated HKT machinery brings us ever closer to the ability to encode value-level effects on the type system.
