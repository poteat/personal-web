---
title: "Kind Reification"
date: 2023-02-07T23:17:12-08:00
categories: [programming]
tags: [typescript, programming, type-system, point-free]
---

The `hkt-toolbelt` now provides a way to 'reify' a higher-order type into a concrete function type. This is useful for representation of point-free code.

> to **reify:** make (something abstract) more concrete or real.

## Basics of Higher-Order Types

For the purposes of `hkt-toolbelt`, a higher-order type is merely a representation of a type _mapping_, i.e. an 'applicable' type that maps from an input type to an output type.

Higher-order types are useful because they can _take in_ higher order types, or _return_ higher order types. Through this mechanism, higher-order types are partially applicable, and can be used to represent sophisticated type relationships.

## Reification

`hkt-toolbelt` now provides the `Kind.Reify` type, which takes a higher-order type and returns a concrete function type.

In the below example, we reify a few type-level operations into their runtime counterparts. We can then use these reified types to represent point-free code.

Notably, the point-free code retains the type-level guarantees of the original type-level operations.

> [TS Playground Link](https://www.typescriptlang.org/play?#code/JYWwDg9gTgLgBAbzgEgDRwNLAHYBN0AywAzjOgMoxQ4DmcAvnAGZQQhwBEAFgNYwC0MCBAA2AIwCmImBwDcAWABQS3BIDGIgIZQJcNRGyk4ITWABcKADxY8AOgBKE4EwCehEjFsBZUwD4Fiqoa2rr6hvCmYBJ4FsjWOLgOTq4UVLS2AIJgUXj+KupaOnoGRgBWEDix8XaOzm5wlNTYNLYAUhXYeYEFIcXhcGDAUVU2ibUpmAm2AApDEl1KYUZMcAC8A3MAFADaJmCbkdG4mxwAhBwAlBfo5TgnnBcAuhcBiyXwAB5rzDvcUiIQDjoDgAd2gIlwHGesjgAHpYXAAORcf4QU5wMFQCGnRFAA)

```typescript
import { $, Kind, List, String } from "hkt-toolbelt";

declare const map: $<Kind.Reify, List.Map>;
declare const append: $<Kind.Reify, String.Append>;
declare const join: $<Kind.Reify, String.Join>;
declare const pipe: $<Kind.Reify, Kind.Pipe>;

const f = pipe([map(append("!")), join(" ")]);

const x = f(["hello", "world"]); // 'hello! world!'
```

> The above code maps over an array of strings, appending the character `!` to each string, and then joins the resulting array of strings into a single string, separated by a space.

This allows generic functions to written _without_ the need for explicit type annotations, which can be a significant improvement in readability.

## Reification Process

The reification process is fairly straightforward. The `Kind.Reify` type takes a higher-order type and returns a concrete function type.

As a higher-order type which obeys the `Kind` interface, the `Kind.Reify` type is itself a higher-order type. So it can reify itself, and so on.

The underlying process is the addition of a function interface to the original higher-order type. This function interface is used to represent the application operation (via `$`). Finally, if the _result_ of the application operation is itself a higher-order type, the reification process is repeated.

The current implementation of `Kind.Reify` is as follows:

```ts
import { $, Kind, Type } from "..";

export type _$reify<K extends Kind.Kind> = K & {
  <X extends Kind._$inputOf<K>>(x: Type._$infer<X>): $<K, X> extends Kind.Kind
    ? _$reify<$<K, X>>
    : $<K, X>;
};

export interface Reify extends Kind.Kind {
  f(x: Type._$cast<this[Kind._], Kind.Kind>): _$reify<typeof x>;
}
```

## Application

The most likely application of this reification technique is in the context of writing pure functional utilities that possess arbitrary type-level composability.

A large limitation of current functional programming libraries (e.g. [lodash](https://www.npmjs.com/package/lodash), [ramda](https://www.npmjs.com/package/ramda)) is that they are not composable at the type-level. This means that the type-level guarantees of the library are lost when composing functions.
