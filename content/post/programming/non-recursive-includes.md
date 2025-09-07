---
title: "A non-recursive type-level inclusion operator"
date: 2022-08-27T16:37:21-07:00
categories: [programming]
tags: [typescript, performance, type-system, efficiency]
---

A performance-optimized, non-recursive implementation of a type-level array inclusion operator in TypeScript.

<!--more-->

```ts
type E1<X> = <T>() => T extends X ? 0 : 1;
type E2<X> = <T>() => T extends X ? 0 : 1;

type IsEqual<X, Y> = E1<X> extends E2<Y> ? true : false;

/**
 * Whether or not T includes U as an element.
 */
type Includes<T extends readonly unknown[], U> = true extends {
  [key in keyof T]: IsEqual<T[key], U>;
}[number]
  ? true
  : false;
```

# A non-recursive type-level `Includes` operator in Typescript

## Introduction

`Includes` is a type-level operator that determines whether a given type `T` includes a given type `U` as an element. In other words, it returns `true` if `T` is a subtype of `U`.

This operator is implemented using a simple helper function, `IsEqual`, which compares two types `X` and `Y` and returns `true` if they are equal.

## Implementation

### IsEqual

The `IsEqual` function is implemented as follows:

```
type IsEqual<X, Y> = E1<X> extends E2<Y> ? true : false
```

where `E1` and `E2` are helper functions that take a type `T` and return `0` if `T` is equal to `X`, and `1` otherwise.

Thus, `IsEqual<X, Y>` returns `true` if `E1<X>` is equal to `E2<Y>`, and `false` otherwise.

#### E1 and E2

The `E1` and `E2` functions are implemented as follows:

```ts
type E1<X> = <T>() => T extends X ? 0 : 1;
type E2<X> = <T>() => T extends X ? 0 : 1;
```

These functions take a type `T` and return `0` if `T` is equal to `X`, and `1` otherwise. These functions exploit deep behavior around generics to implement a "true type-level equality check", which will even distinguish readonly attributes from non-readonly attributes.

The deep behavior needed to distinguish readonly attributes does not work without _both_ type declarations, despite the equivalence. The internal type-checking behavior seems to depend on comparing two _separate_ type identifiers.

### Includes

The `Includes` function is implemented as follows:

```ts
type Includes<T extends readonly unknown[], U> = true extends {
  [key in keyof T]: IsEqual<T[key], U>;
}[number]
  ? true
  : false;
```

First, note that `Includes` takes two type parameters: `T`, which is a _readonly_ array type, and `U`, which is the element type that we want to check for inclusion in `T`. We do not introduce a constraint whereby U must be an element of T, since the whole purpose of the function is to determine whether or not U is an element of T.

Next, we define a helper type, `R`, which is a _mapped type_. This is a type whose properties are determined by mapping a given type `T` to another type `U`. In this case, we are mapping each element of `T` to the result of `IsEqual<T[key], U>`.

Thus, `R` is a type with one property for each element of `T`, whose value is `true` if the element is equal to `U`, and `false` otherwise.

Finally, we return `true` if `R` has a property with value `true`, and `false` otherwise.

## Advantages

The `Includes` operator has a number of advantages over other implementations.

First, it is _non-recursive_. This means that it will not suffer from _exponential typechecking_, which is a problem with other implementations of `Includes`.

Second, it is _type-safe_. This means that it will only return `true` if `U` is _actually_ an element of `T`. Other implementations may return `true` even if `U` is not an element of `T`.

Third, it is _efficient_. This means that it will not introduce _unnecessary_ type-checking constraints. Other implementations may introduce such constraints, which can lead to _slow_ type-checking.

## Conclusion

The `Includes` operator is a simple, efficient, and type-safe way to determine whether a given type `T` includes a given type `U` as an element.
