---
title: "Point-free Programming via HKTs"
date: 2022-03-11T09:34:39-08:00
categories: [programming]
tags: [typescript, programming, type-system, point-free]
---

In Typescript, point-free programming has been traditionally limited due to the difficulty the type system has representing the abstracted types associated with point-free (also called 'tacit') programming.

- [1. What is Tacit Programming?](#1-what-is-tacit-programming)
- [2. Type-Level Programming](#2-type-level-programming)
  - [2.1. The Hard (Naive) Way](#21-the-hard-naive-way)
  - [2.2. Tacit Logic via HKTs](#22-tacit-logic-via-hkts)
- [3. Addendum: Library](#3-addendum-library)
  - [3.1. Basic HKT Abstractions](#31-basic-hkt-abstractions)
  - [3.2. HKT Composition](#32-hkt-composition)
  - [3.3. Narrow Type Inference](#33-narrow-type-inference)
  - [3.4. Value-level Apply](#34-value-level-apply)
  - [3.5. Auto-applyable HKTs](#35-auto-applyable-hkts)
  - [3.6. HKT-Level Flow](#36-hkt-level-flow)
  - [3.7. HKT-level Split](#37-hkt-level-split)
  - [3.8. HKT-level join](#38-hkt-level-join)
  - [HKT-level includes](#hkt-level-includes)
  - [HKT-level Array Manipulation](#hkt-level-array-manipulation)
- [Conclusion](#conclusion)

## 1. What is Tacit Programming?

In tacit programming, functions are represented via functional composition. Notably, we avoid explicitly representing formal parameters - instead, we compose functions at a higher level that elide the underlying variables.

For example, let us discuss the program that finds all strings in an array which are solely composed of lowercase letters, and joins them via a newline. We will demonstrate three approaches - the procedural approach, a naive functional approach, and finally a tacit approach.

**Procedural approach**

This code is limited in a number of ways - to draw a starker difference, I avoided language features such as iterator processing, regular expression usage, and string interpolation. My motivation is to show a spectrum of semantic compression across the three approaches.

```ts
function extractWords(array: string[]) {
  const words: string[] = [];

  for (let i = 0; i < words.length; i++) {
    const element = words[i];
    let isLowercaseWord = false;

    for (let j = 0; j < element.length; j++) {
      const letter = element[j];

      if ("a" <= letter && letter <= "z") {
        isWord = true;
      } else {
        isWord = false;
        break;
      }
    }

    if (isLowercaseWord) {
      words.push(element);
    }
  }

  let output = "";

  for (let i = 0; i < words.length; i++) {
    const word = words[i];
    output += "\n" + word;
  }

  return words;
}
```

**Naive functional approach**

Here we introduce chaining functional methods, as well as regular expression usage. This greatly compresses the procedure being done on a semantic level - instead of laying out each step, we are building up the approach via smaller building blocks.

```ts
function extractWords(array: string[]) {
  return array.filter((x) => /^[a-z]+$/.matches(x)).join("\n");
}
```

**Tacit approach**

Finally, we arrive at the tacit approach, whereby the method is represented without any explicit reference to any parameters being acted upon. For those unfamiliar, this syntax can be strange and unapproachable - it is based on function composition from mathematics as well as 'currying' to facilitate partial application.

A staple of this methodology is the use of unbound single-parameter functions, e.g. `matches` - which first takes in a regular expression, and then takes in the string to attempt to match on.

In general, to facilitate the approach, functions take in the most likely 'final' parameter last. So in the case of join, the signature is `(delimiter) => (array) => string`.

```ts
const extractWords = flow(filter(matches(/^[a-z]$/)), join("\n"));
```

On a type level, representing `flow` correctly can be fiendishly difficult - we need to validate that the output of `filter` matches the input of `join` - i.e. that each puzzle piece fits together correctly. This is even more difficult if `filter` is itself a generic.

## 2. Type-Level Programming

The above implementations of our contrived procedure are of type `(string[]) => string`. Believe it or not, we can encode the logic of our procedure on the type level as well, in order to benefit from what approaches proof-level type safety.

We will first approach this by annotating the **naive functional** approach, doing much of the work via pure types. We will explore why this is the _hard way_, and the benefits we receive via combining HKTs and tacit programming in terms of more tightly coupling the value and type systems.

### 2.1. The Hard (Naive) Way

We introduce a tuple generic to the above naive functional code, and then specify the return type in terms of a heretofor undefined parameterized type `ExtractWords`, in which we will encode our type-level logic.

```ts
function extractWords<T extends string[]>(array: T): ExtractWords<T> {
  return array.filter((x) => /^[a-z]+$/.matches(x)).join("\n");
}
```

**Naive / hard type-level approach**

Here we define `ExtractWords` via type-level primitives, recursive type inference, and more. While the fact that Typescript can do this is certainly impressive, there is a better way. A simple aspect is: we had to write all of this additional type-level code separately, in addition to the runtime code.

As well - by nature, Typescript's type-level syntax encourages (essentially necessitates) a functional approach. However, for example we needed to couple the 'filtering' logic with the 'is lowercase' logic in `FilterIsLowercase`. If only there was a way to take in a "higher level type function" into a generic `Filter` type!

By being forced to couple filtering logic, we are limited in the degree to which we can semantically compress our 'proof'.

Finally, the below implementation is functional _on the type level_, but it's not tacit. With higher-kinded types, tacit type-level logic is possible (and necessitated).

**order 0**

- number
- 42
- string

**order 1**

- Assume<T, U> = T
- Equals

**order 2**

- Map
- Filter

```ts
type Equals<T, U> = [T, U] extends [U, T] ? true : false;

type Assume<T, U> = T extends U ? T : U;

type IsLowercase<S extends string> = Equals<S, Lowercase<S>>;

type FilterIsLowercase<T extends string[]> = T extends []
  ? []
  : T extends [infer Head, ...infer Tail]
  ? IsLowercase<Assume<Head, string>> extends true
    ? [Head, ...FilterIsLowercase<Assume<Tail, string[]>>]
    : FilterIsLowercase<Assume<[...Tail], string[]>>
  : never;

type Join<T extends string[], D extends string> = T extends []
  ? ""
  : T extends [infer Head, ...infer Tail]
  ? Head extends string
    ? `${Head}${D}${Join<Tail extends string[] ? Tail : [], D>}`
    : never
  : never;

type ExtractWords<T extends string[]> = Join<FilterIsLowercase<T>, "\n">;

// "foo\nbar\nqux"
type Result = ExtractWords<["foo", "bar", "NOPE", "qux"]>;
```

### 2.2. Tacit Logic via HKTs

The alternative approach is to more align the type system with the value system using HKTs. In fact, representing functions as expressions allows the type system to fully encode complex type structure - as introduction of lambda expressions without generic type annotations will remove generic type safety.

In this form, we get the best of _all_ worlds, in that the type-level logic is fully implemented but there is no additional complexity or code required, aside from shared library utilities.

We will start with constructing the library that encodes the constituent ideas that will be connected to form the overall algorithm.

```ts
const isLowercaseWord = flow(split(""), every(includes(lowercaseLetters)));

const extractWords = flow(filter(isLowercaseWord), join("\n"));

// "foo\nbar\nqux"
const result = extractWords(["foo", "bar", "NOPE", "qux"]);
```

With the atomic composable elements used above (e.g. `flow`, `split`, `every`, etc.) we can minimally (and tacitly) define the underlying process in code. Because each function is capable of being composed on the type level (via arbitrarily kinded types), we get the underlying sophisticated type constructs "for free" in user-land.

Potential practical applications for this would be type-level parsing for use in embeddable type-safe DSLs - there is safety and usabibility value in having embedded languages connect to their host languages in a type-safe way.

## 3. Addendum: Library

The underlying HKT-level library code that facilitates the above tacit implementation is technically interesting, but slightly verbose. In this section this code will be provided, as well as explanatory annotations.

Not all runtime code is present - for brevity's sake in some cases only the type declarations themselves are provided.

### 3.1. Basic HKT Abstractions

These are covered in higher detail in my previous article, [Higher Kinded Types in Typescript](https://code.lol/post/programming/higher-kinded-types/). Suffice to say, these are the fundamental abstractions that facilitate the construction and application of HKTs.

The underlying approach is to use a field type on a class as a formal parameter, and a class method to act as the operation being performed. We can then 'apply' this operation by supplying the type at a later point.

We are very fortunate that the class typing system happens to work this way - this allows us arbitrary power in expressing higher-kinded types.

```ts
type GenericFunction = (...x: never[]) => unknown;

abstract class HKT {
  readonly _1?: unknown;
  new!: GenericFunction;
}

type Assume<T, U> = T extends U ? T : U;

type Apply<F extends HKT, _1> = ReturnType<
  (F & {
    readonly _1: _1;
  })["new"]
>;
```

### 3.2. HKT Composition

The core concept of composition of the HKT level allows for tacit representation of type-level logic.

The central implementation is based on `Compose`, which takes in a variadic amount of HKTs and returns a new HKT that is the composition of the input HKTs. Because function composition between `F` and `G` is `F(G(x))`, the `Compose` operator executes functions from right to left.

Because right-to-left logic is a little harder to understand, we use `Flow` instead which works left-to-right.

```ts
type Compose<HKTs extends HKT[], X> = HKTs extends []
  ? X
  : HKTs extends [infer Head, ...infer Tail]
  ? Apply<Assume<Head, HKT>, Compose<Assume<Tail, HKT[]>, X>>
  : never;

type Reverse<T extends unknown[]> = T extends []
  ? []
  : T extends [infer U, ...infer Rest]
  ? [...Reverse<Rest>, U]
  : never;

interface Flow<HKTs extends HKT[]> extends HKT {
  new: (x: this["_1"]) => Compose<Reverse<HKTs>, this["_1"]>;
}
```

### 3.3. Narrow Type Inference

Implicit type inference can be achieved through a special trick in Typescript. Specifically, this is when literal strings, tuples, and objects are interpreted as if they were annotated with `as const`, even without that annotation.

The trick is to define a more or less 'universal' type that we can use to specify a type constraint on parameters.

This recursive type constraint is checked by the compiler, which results in parameter types being narrowed as much as possible. This is a convenience for the general approach, but not particularly necessary as a fundamental idea.

```ts
type InferredType =
  | string
  | number
  | boolean
  | undefined
  | null
  | GenericFunction
  | InferredType[]
  | ReadonlyArray<InferredType>
  | {
      [key: string]: InferredType;
    };

type InferredTuple = InferredType[] | ReadonlyArray<InferredType>;
```

### 3.4. Value-level Apply

The HKT-level apply represents the actualization of a particular HKT with a given value. As we will see next, this isn't always needed due to other conveniences introduced, but is valuable from a pedaogic perspective.

The value-level implementation was elided as it's not necessary to show the type-level mechanics of this approach in general. Of course, it has also been written to automatically infer the most narrow interpretation of its parameters possible.

```ts
export declare function apply<H extends typeof HKT>(
  h: H
): <X>(
  x: InferredType | Assume<X, InferredType> | [...Assume<X, InferredTuple>]
) => Apply<Assume<InstanceOf<H>, HKT>, X>;
```

### 3.5. Auto-applyable HKTs

Normally to 'apply' a type parameter to a corresponding HKT, we would need to explicitly call either `Apply` (on the type level), or the similar value-level function `apply`. This is a bit verbose, and can be avoided by annotating each HKT with a 'callable' interface.

Here, the `build` function takes in a HKT and makes it directly callable via adding a generic callable interface to its type signature using a type-level intersection.

Finally, we utilize the inference utilities so that all parameters are narrowed as much as possible.

```ts
type InstanceOf<T> = T extends new (...args: unknown[]) => infer R ? R : never;

declare function build<H extends typeof HKT>(
  hkt: H
): H & {
  <X>(x: Assume<X, InferredType> | [...Assume<X, InferredTuple>]): Apply<
    Assume<InstanceOf<H>, HKT>,
    X
  >;
};
```

### 3.6. HKT-Level Flow

To facilitate flow-based expressions, we define a value-level function that takes in a variadic amount of HKTs and returns a new HKT that is the right-composition of the input HKTs.

For now, the value-level runtime code is not provided - although it should be quite simple to implement.

This is a core engine of the approach, and the basis of implementing larger more complicated type-level logic.

> Note: This type-level implementation does not check or account for mismatching HKT functions - i.e. it does not check that the output of parameter N - 1 is a subtype of the input of parameter N.

```ts
type MapInstanceOf<T> = {
  [key in keyof T]: InstanceOf<T[key]>;
};

const flow = <HKTs extends typeof HKT[]>(...hkts: HKTs) =>
  build(
    class extends HKT {
      new = (x: this["_1"]) =>
        x as unknown as Apply<Flow<MapInstanceOf<HKTs>>, typeof x>;
    }
  );
```

### 3.7. HKT-level Split

The following code is a simple example of a HKT-level split. The `Split` type is itself a pretty standard first order type, implemented recursively. The interesting part is the `split` runtime wrapper, which encodes the type of the split in such a way it can be composed arbitrarily deeply later.

```ts
type Split<
  S extends string,
  Delimiter extends string = ""
> = S extends `${infer Head}${Delimiter}${infer Tail}`
  ? [Head, ...Split<Tail, Delimiter>]
  : S extends Delimiter
  ? []
  : [S];

const split = <D extends string>(d: D) =>
  build(
    class extends HKT {
      new = (x: Assume<this["_1"], string>) => x.split(d) as Split<typeof x, D>;
    }
  );
```

### 3.8. HKT-level join

Similar to the above, the `Join` type is itself a first order type, with a corresponding runtime wrapper.

```ts
type Join<T extends string[], D extends string> = T extends []
  ? ""
  : T extends [infer Head, ...infer Tail]
  ? `${Assume<Head, string>}${Tail extends [] ? "" : D}${Join<
      Assume<Tail, string[]>,
      D
    >}`
  : never;

const join = <J extends string>(j: J) =>
  build(
    class extends HKT {
      new = (x: Assume<this["_1"], string[]>) => x.join(j) as Join<typeof x, J>;
    }
  );
```

### HKT-level includes

We introduce a 'includes' type-level function. Notably, the `Includes` method has unique properties, in that it defines a subtype relationship. That is, `string[]` includes 'foo' in this relationship, because 'foo' is a subtype of `string`.

> **Note:** An alternative definition could be provided based on the aspect of string equality (i.e. two types X and Y are equal if and only if X exends Y and Y extends X). This is not necessary in our case however.

```ts
type Includes<T extends readonly unknown[], X> = X extends T[number]
  ? true
  : false;

const includes = <T extends InferredTuple>(array: readonly [...T]) =>
  build(
    class extends HKT {
      new = (x: Assume<this["_1"], InferredType>) =>
        array.includes(x) as Includes<T, typeof x>;
    }
  );
```

### HKT-level Array Manipulation

Below we have a collection of HKTs that are useful for manipulating arrays - `map`, `filter`, and `every`.

```ts
type MapTuple<X extends readonly unknown[], F extends HKT> = {
  [K in keyof X]: Apply<F, X[K]>;
};

const map = <H extends typeof HKT>(hkt: H) =>
  build(
    class extends HKT {
      new = (x: Assume<this["_1"], InferredTuple>) =>
        x.map((x) => apply(hkt)(x)) as unknown as MapTuple<
          typeof x,
          Assume<InstanceOf<H>, HKT>
        >;
    }
  );

type FilterTuple<X extends readonly unknown[], F extends HKT> = X extends []
  ? []
  : X extends [infer Head, ...infer Tail]
  ? [
      ...(Apply<F, Head> extends true ? [Head] : []),
      ...FilterTuple<Assume<Tail, readonly unknown[]>, F>
    ]
  : never;

const filter = <H extends typeof HKT>(hkt: H) =>
  build(
    class extends HKT {
      new = (x: Assume<this["_1"], InferredTuple>) =>
        x.filter((x) => apply(hkt)(x)) as FilterTuple<
          typeof x,
          Assume<InstanceOf<H>, HKT>
        >;
    }
  );

type EveryTuple<X extends readonly unknown[], F extends HKT> = X extends []
  ? true
  : X extends [infer Head, ...infer Tail]
  ? Apply<F, Head> extends true
    ? EveryTuple<Tail, F>
    : false
  : never;

const every = <H extends typeof HKT>(hkt: H) =>
  build(
    class extends HKT {
      new = (x: Assume<this["_1"], InferredTuple>) =>
        x.every((x) => apply(hkt)(x)) as EveryTuple<
          typeof x,
          Assume<InstanceOf<H>, HKT>
        >;
    }
  );
```

## Conclusion

In this article we have shown an approach where we can define a set of intercomposable functional primitives that combine together to infer a type-level representation of a program.
