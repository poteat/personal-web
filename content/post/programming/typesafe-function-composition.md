---
title: "Typesafe Function Composition"
date: 2022-10-09T16:45:40-07:00
categories: [programming]
tags: [type safety, typescript, functional programming, type-system]
---

> Do ya wanna know how to well-type function composition in Typescript? Read on!

<!--more-->

- [1. Background](#1-background)
  - [1.1. Type-theoretic Pseudocode](#11-type-theoretic-pseudocode)
- [2. Typescript](#2-typescript)
  - [2.1. IsComposablePair](#21-iscomposablepair)
    - [2.1.1. Type-based Pattern Matching using `infer`](#211-type-based-pattern-matching-using-infer)
    - [2.1.2. IsComposablePair](#212-iscomposablepair)
  - [2.2. Every](#22-every)
  - [2.3. Pair](#23-pair)
- [3. Component Synthesis](#3-component-synthesis)
- [4. Function Integration](#4-function-integration)
- [5. Future Work: Constructive Approach](#5-future-work-constructive-approach)

# 1. Background

Function composition is an operation that takes two functions, $f$ and $g$, and produces a new function $h$ such that $h(x) = g(f(x))$.

A typed function is a function that takes an input of a certain type and returns an output of a certain type. A type represents a set of values and the operations that can be performed on them.

When $f:: (A{\rightarrow}B)$ and $g:: (B{\rightarrow}C)$ are typed functions, composition preserves the types of the functions, so that if $f$ is a function that takes an input of type $A$ and returns an output of type $B$, and $g$ is a function that takes an input of type $B$ and returns an output of type $C$, then the composed function $h = f \circ g$ will take an input of type $A$ and return an output of type $C$.

Incompatible functions may not be composed if they do not have compatible type signatures. For example, if $f:: (A{\rightarrow}B)$ is a function that takes an input of type $A$ and returns an output of type $B$, and $f:: (C{\rightarrow}D)$ is a function that takes an input of type $C$ and returns an output of type $D$, then $f$ and $g$ are incompatible and cannot be composed, unless $C$ is a subtype of $B$.

Variadic composition is a type of function composition in which the number of functions being composed is not fixed. That is, given $n$ functions $f_1, f_2, \ldots, f_n$, the composed function $h$ is given by $h(x) = f_n(\ldots(f_2(f_1(x)))\ldots)$.

A tuple of functions are compatible if each consecutive pair is compatible, that is $(f_1, f_2), (f_2, f_3), \ldots, (f_{n-1}, f_n)$ are all compatible.

## 1.1. Type-theoretic Pseudocode

The following pseudocode is a minimally functional representation of the above specification for composable function tuples.

```
type IsComposable fx =
  every
    map each pair f g of fx
      output(f) is a subtype of input(g)
```

A tuple of functions is composable if and only if for every pair of elements $(f, g)$, the output of $f$ is a subtype of the input of $g$.

# 2. Typescript

To begin writing the implementation of this specification, we can identify some common components to abstract out, that will make the implementation of our type easier.

By inspection, we can identity three components to start with:

| Name             | Description                                                                                                         |
| ---------------- | ------------------------------------------------------------------------------------------------------------------- |
| IsComposablePair | Takes in two functions, returning whether they may be validly composed.                                             |
| Every            | Takes an tuple of boolean types, returning `true` iff all tuple elements are `true`, else returns `false`.          |
| Pair             | Takes in a tuple, returning a tuple composed of all pairwise elements. e.g. $(a, b, c)$ becomes $((a, b), (b, c))$. |

## 2.1. IsComposablePair

To implement IsComposable, we need two more utility types: `InputOf` and `OutputOf`. We can implement both of these types using pattern matching.

```ts
type InputOf<T> = T extends (x: infer X) => unknown ? X : never;
```

```ts
type OutputOf<T> = T extends (x: never) => infer X ? X : never;
```

> These types can also be constructed via built-ins `Parameters` and `ReturnType`, but this is a convenient lesson on type-based pattern matching. See the associated section below.

### 2.1.1. Type-based Pattern Matching using `infer`

A conditional type in Typescript is composed of four clauses:

```ts
<operand> extends <matcher> ? <true_val> : <false_val>
```

The `<matcher>` expression may contain one or more `infer <type>` statements, which can be referenced in the `<true_val>` expression.

Typescript will attempt to find the narrowest type possible that makes the `<operand>` a subtype of the `<matcher>` expression. If it can find a type such that `<operand>` is a subtype of `<matcher>`, the `<true_val>` expression will be returned, else the `<false_val>` expression will be returned.

### 2.1.2. IsComposablePair

For `IsComposable`, it's straightforward to use a conditional type (without `infer`) to represent the subtype condition that we encoded in the specification above.

```ts
type IsComposablePair<F1, F2> = InputOf<F1> extends OutputOf<F2> ? true : false;
```

## 2.2. Every

The `Every` type will take in a tuple of boolean types and return `true` if and only if every element in its input is `true`.

First though, we need an additional helper type, which will be a type-level analogue of 'and':

```ts
type And<T, U> = [T, U] extends [true, true] ? true : false;
```

To implement this in Typescript, we now need to use tuple-level recursion, which takes the following form:

```ts
type Every<T extends unknown[]> = T extends [infer Head, ...infer Rest]
  ? And<Head, Every<Rest>>
  : true;
```

We infer the 'head' of the tuple (a functional programming term referring to the first element), as well as the 'rest' of the tuple. We then define `Every` recursively.

## 2.3. Pair

`Pair` will be the most complex of our three component types.

```ts
type Pair<T extends unknown[]> = T extends [infer X1, infer X2, ...infer Rest]
  ? [[X1, X2], ...Pair<[X2, ...Rest]>]
  : [];
```

# 3. Component Synthesis

With these utility functions, in the optimal case we could represent our type with something like the following (matching our pseudocode implementation):

```ts
type IsComposable<T> = Every<Map<Pair<T>, IsComposablePair>>; // wrong
```

Unfortunately, this representation is not directly available because Typescript has no built-in support for _Higher-Kinded Types_ (or HKTs). In this case, the higher-kinded type I am trying to invoke above is _Map_.

Instead, we need to create our own alias type to implement the mapping operation:

```ts
type IsComposablePairMap<T extends [unknown, unknown][]> = {
  [key in keyof T]: IsComposablePair<T[key][0], T[key][1]>;
};
```

Now, utilizing this type, we can finally create our `IsComposable` type.

```ts
type IsComposable<T extends unknown[]> = Every<IsComposablePairMap<Pair<T>>>;
```

This type _checks_ if a given tuple type represents a variadic number of composable functions. However, it's not immediately clear how to use this in a function signature in a useful way.

# 4. Function Integration

To fully integrate this type into a `compose` function declaration, we need a few more utility types:

```ts
type Enforce<B, X> = B extends true ? X : never;

type Composable<T extends unknown[]> = Enforce<IsComposable<T>, T>;

type First<T extends unknown[]> = T[0];

type Last<T extends unknown[]> = T extends [...unknown[], infer L] ? L : never;

type Resolve<T extends unknown> = T;

type ComposedFunction<T extends unknown[]> = Resolve<
  (x: InputOf<First<T>>) => OutputOf<Last<T>>
>;
```

> The `Resolve` type's purpose is to ensure that the return type of `compose` is ultimately rendered (on hover) as the most resolved possible type.

With these, we can declare `compose` as the following:

```ts
declare function compose<T extends unknown[]>(
  ...fx: Composable<T>
): ComposedFunction<T>;
```

This technique (called `Enforce`) uses `never` as a "sledgehammer" to force a type error to appear - however, it doesn't result in particularly useful errors for the developer, aside from signalling that _something_ with the types are wrong.

# 5. Future Work: Constructive Approach

It may be possible to slightly modify this implementation to improve type errors - instead of returning a boolean, _search_ for the first non-compliant function, and transform its type into a compliant one.

That way, only the non-compliant function will be squiggled, and the error message will be of a more understandable form (i.e. not involving `never`).
