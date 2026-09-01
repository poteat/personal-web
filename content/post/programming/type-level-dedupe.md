---
title: "String Deduplication on the Type Level"
date: 2021-01-09T15:18:24-08:00
categories: [typescript, algorithms]
tags: [typescript, programming, tuples, strings, algorithms]
images: ["img/art/water-on-clouds.png"]
---

Solving the classic string deduplication algorithm entirely within TypeScript's type system using literal string types and recursive type manipulation.

<!--more-->

The string deduplication problem is a canonical one within computer science, serving a similar purpose as fizz-buzz in terms of being an example of a simple problem that a reasonably knowledgable practitioner should be able to solve with minimal effort.

The problem appears in a few variants, but briefly one such variant is to remove duplicate letters in a given string, such that the string then has only one instance of any given letter.

I thought this problem would be a particularly interesting case study into Typescript 4.1's powerful literal string types.

## String Splitting

The first step of any string algorithm is to split the string into units that can be processed individually. In this case, we split a given string literal into an array of strings, each of length 1.

```ts
type Split<S extends string> = S extends ""
  ? []
  : S extends `${infer C}${infer R}`
  ? [C, ...Split<R>]
  : never;

type Result = Split<"Foobar">; // :: ["F", "o", "o", "b", "a", "r"]
```

`Split` is defined essentially as a nested conditional type (using the ternary syntax), that recurses into itself to define the tuple type. The `C` type is inferred to be the first character of `S`, and the `R` type is inferred to be the rest. (corresponding to `Character` and `Rest` respectively).

## String Joining

Another important capability when working with strings is the ability to collapse an array of strings into one string, via concatenation. On the type level, we can implement this in a similar fashion as the above `Split` type.

```ts
type Join<T extends string[]> = T extends []
  ? ""
  : T extends [infer Head, ...infer Tail]
  ? Head extends string
    ? `${Head}${Join<Tail extends string[] ? Tail : []>}`
    : never
  : never;
```

With this pattern, we are essentially performing a `reduce` operation in a similar manner as you might do when implementing it in a combinator form, e.g. using the Y combinator instead of a reduce function as such.

For example, this is how the equivalent meaning would be written on the value level:

```ts
const join = (x: string[]): string =>
  x.length === 0 ? "" : `${x[0]}${join(x.slice(1))}`;
```

## Tuple Uniqueness

The next feature we need is the ability to enforce tuples to be unique, only allowing the first instance of a given element to exist, and filtering away all others. We do this by keeping track of letters we have already seen (`R`), and conditionally outputting to an output string tuple type (`O`).

```ts
type Invert<T extends Record<string, unknown>> = {
  [key in keyof T as T[key] extends string ? T[key] : never]: key;
};

type Unique<
  T extends string[],
  R extends Record<string, string> = {},
  O extends string[] = []
> = T extends []
  ? O
  : T extends [infer Head, ...infer Tail]
  ? Unique<
      Tail extends string[] ? Tail : [],
      R & Invert<{ _: Head }>,
      Head extends string ? (R[Head] extends string ? O : [...O, Head]) : []
    >
  : never;
```

This is somewhat complicated by a limitation of TS 4.1, namely the ability to construct an object with a given key, whereby the key type is a literal type. The way we work around that now is via `Invert`, which switches the keys and values of an object type.

## Putting it Together

The string deduplication problem is essentially a composition between various simple operations. With the fundamental utilities we've defined, the actual deduplication type is concise:

```ts
type DedupeString<S extends string> = Join<Unique<Split<S>>>;

type Result = DedupeString<"banana">; // "ban"
```
