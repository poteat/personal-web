---
title: "Higher Kinded Types in Typescript"
date: 2022-03-03T22:18:42-08:00
categories: [programming]
tags: [typescript, programming, type-system]
---

A comprehensive introduction to Higher Kinded Types in TypeScript, exploring how to encode and utilize these powerful abstractions from functional programming.

<!--more-->

HKTs are a powerful abstraction. Just as there are different types of higher-order functions, so are there so-called 'higher-kinded types'.

## Taxonomy

This blog post concerns one particular type of HKT - to define the taxonomy, first we will cover a few types, and a way they can be categorized.

We can classify types in terms of 'order', a rough level of abstraction.

Here are a few zero-order types that exist:

- `number`
- `string`
- `42`
- `(x: number) => number`
- `(f: (...x: string[]) => number) => string`
- `<T>(x: T) => T`

Here are a few first-order types:

- `_<T> = T & string`
- `_<T> = (f: x) => T`
- `_<T, U> = T extends U ? T : U`
- `_<T> = <U>(x: U) => T`

> _Note_: types associated with generic functions (e.g. `<T>(x: T) => T`) do not count as a type parameter. These parameters are 'bound' such that the type level cannot act on them.

When we get to second-order types, we run into a problem. In Typescript, it is neither possible to directly encode either types that _return_ parameterized types (i.e. types that return types, that themselves take in types), nor other variants.

Here are ways it _could_ work, based on various active proposals.

- `_<T> = <U> -> T & U`
- `_<T<*>, U> = T<U>`

The first is an example of a type returning a type which takes in a type, and the second is a type that takes in a type which takes in a type.

Analogous to L.C. is the nature that such nestings can become arbitrarily complicated.

In our case, this blog post concerns itself with the latter - i.e. types that take in parameterized types.

## A Simple Map

The core motivation of this post has been to implement a `map` function that properly iterates over its tuple parameter.

For example, this can be our goal:

```ts
map(["hi", "bye"], (x) => `${x}!`); // ["hi!", "bye!"]
```

When actually attempting to define `map`, we can run into trouble. Although we can type each of the parameters independently, we find there's no way to actually iterate over the generic function:

```ts
declare const map = <
  X extends unknown[],
  F extends <Y>(x: Y) => unknown
>(x: X, f: F): (???)
```

The most we can obtain with e.g. `ReturnType<F>` is the following:

```ts
// `${string}!`
map(["hi", "bye"], (x) => `${x}!`);
```

## Stepping Back: `Apply`

A more reasonable initial goal may be to implement an Apply function - i.e. one that takes in a type, and a type that can take in that type.

That is, we're looking to implement roughly the following (if we could do it directly):

```ts
type Apply<X, F<~>> = F<X>
```

### Preamble

Let's introduce a few utilities we'll need, with explanation for each.

#### Generic Functions

A useful concept is that of a 'generic function', i.e. one that fits the minimum possible scope of what a function is. A special property of this type is that all functions are a subtype of it.

```ts
type GenericFunction = (...x: never[]) => unknown;
```

#### Abstract Class: HKT

First we'll need the abstract representation for our HKTs in general - our high-level approach will be to utilize classes - the "\_1" field will represent the first and only parameter to our type.

> _Note_: This method can be expanded to more than one parameter, and even a variadic number of parameters. For now, we will only consider one type parameter.

The 'new' field represents the actual type function that will be executed. It is specified in the most permissive way. (such that any function is applicable).

```ts
abstract class HKT {
  readonly _1?: unknown;
  new?: GenericFunction;
}
```

#### Type-level Assumptions

We'll also need `Assume` - this is a common utility I use that's invaluable for many situations. Fundamentally, it's telling the compiler to _assume_ that a given type is correct, and is very helpful as a hint.

```ts
type Assume<T, U> = T extends U ? T : U;
```

#### Apply

Finally, we get to our definition of `Apply`. This type takes in a 'HKT', as well as a type to apply, and returns the result.

Stepping in, what we're actually doing is 'setting' the \_1 parameter using an intersection. Quite amazingly, this actually results in the type of `new` updating dynamically, in a way that the return type can be cleanly extracted.

> _Note_: Technically, what is being typed as a 'HKT' isn't actually the higher-kinded type, despite the abuse of terminology. Rather, "Apply" itself is actually the HKT. A better name for what's typed as HKT here may be 'HktParameter' or such - although it's less concise.
>
> In other words, F is a first-order type, and Apply is a second-order type.

```ts
type Apply<F extends HKT, _1> = ReturnType<
  (F & {
    readonly _1: _1;
  })["new"]
>;
```

## Stepping Forward: Using `Apply`

Now that we have Apply, we can use it: let us consider a `DoubleString` type function, that duplicates a literal string type.

We refer to the type parameter via `this["_1"]`, and we assert an additional type constraint via a type assumption.

```ts
interface DoubleString extends HKT {
  new: (x: Assume<this["_1"], string>) => `${typeof x}${typeof x}`;
}

// "hi!hi!"
type Result = Apply<DoubleString, "hi!">;
```

This works, but since DoubleString is a first-order type, this is nothing we couldn't do with the base Typescript language.

## Stepping Forward a Kilometre: `Map`

Now that we have `Apply`, it's not much work at all to implement first-order type-level tuple mapping:

```ts
type MapTuple<X extends readonly unknown[], F extends HKT> = {
  [K in keyof X]: Apply<F, X[K]>;
};

// ["hellohello", "worldworld"]
type MapResult = MapTuple<["hello", "world"], DoubleString>;
```

Now we're at the point where we can represent things that are normally impossible to directly encode in Typescript.

## Closing it out: The Value Level

With a few more utilities and definitions, we can unlock very powerful end-user APIs that encode very sophisticated types in a readable package.

### Inferred Types

This type is useful for having functions correctly infer literal parameter values as constant. It's a weird trick, but having "extends" on a universal type acts as a hint to the compiler that function parameters should be narrowed automatically.

This lets us avoid having the user be forced to do "as const".

```ts
type InferredType = string | number | boolean | object | undefined | null;
```

### Inferred Tuples

For much the same reason as above, we need the `InferredTuple` type, in that this will prevent `as const` from being needed. We can also elegantly handle `readonly` tuples here.

```ts
type InferredTuple = InferredType[] | ReadonlyArray<InferredType>;
```

### Instance Of

This allows us to pass in HKT classes directly, rather than needing to pre-construct instances before-hand - this results in a cleaner interface at the end.

In other words, `InstanceOf` converts a class definition type to the underlying class instance type. Very useful, and particularly hard to search for online.

```ts
type InstanceOf<T> = T extends new (...args: any) => infer R ? R : never;
```

### Value-level Map

This is the value-level definition (sans body) of a `map` function whose interface is compliant with `MapTuple` defined above. To allow for passing in HKT definitions directly, we end up doing a bit of interesting assumptions in the return type.

The `readonly [...X]` bit is not a typo - this is part of what forces the compiler to interpret parameters in the most narrow possible form, without requiring `as const`. Very useful as well!

```ts
declare function map<X extends InferredTuple, F extends typeof HKT>(
  x: readonly [...X],
  f: F
): MapTuple<X, Assume<InstanceOf<F>, HKT>>;
```

### Closing out: User-Level Code

At this point, end-users can more-or-less succintly define new HKTs and compose them in interesting ways.

At the end, we append a string across a tuple of strings on the type level, while preserving order. Doing this manually in Typescript can be pretty fraught and require advanced knowledge, but with our HKT utilities it becomes easier (assuming `append` already exists).

In the end, this whole operation is encoded as a third-order type. We're passing in the type `!!!`, which returns the "curried" HKT, which is then passed into `map`, and finally applied to each literal string in the tuple.

```ts
const append = <S extends string>(s: S) =>
  class extends HKT {
    new = (x: Assume<this["_1"], string>) => `${x}${s}` as const;
  };

// ["hello!!!", "world!!!"]
const result = map(["hello", "world"], append("!!!"));
```

## Conclusion

Did you ever wish Lodash's types were a bit smarter? Techniques like those described in this article can be utilized to increase the power of the type system and allow it to infer more from our code.

We covered HKT taxonomy from the bottom-up, all the way to defining complex type-level string manipulation routines. I hope this helps folks with their Typescript!
