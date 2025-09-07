---
title: "Chained Tuple Types"
date: 2021-01-05T20:23:23-08:00
categories: [typescript]
tags: [typescript, programming, tuples, type system]
---

TypeScript 4.1's variadic tuple types enable building complex type-safe data structures through method chaining, where each operation expands the chain's type signature at compile time.

<!--more-->

With Typescript 4.1, it's now possible to use variadic tuple types to construct large types with what appears to be runtime code. The general idea is that we will utilize a chaining pattern, where each operation on the chain returns an expanded version of the chain's type.

To motivate the example, let us consider a `Set` class. Our `Set` is a chaining class, where you may insert, remove, and check for the existence of numbers. To end the chain, you call `.value()` which returns an array of numbers.

Here is an example of how you might use `Set`:

```ts
const set = new Set().insert(2).insert(4).insert(8);

const hasTwo = set.has(2); // true

const value = set.remove(2).value(); // [4, 8]
```

> [Note: all of this code is on **TS Playground** :)](https://www.typescriptlang.org/play?#code/PQKgBApgzgNglgOwC4FoAmcoEMBGMKSyKoDGA9gLYUTJTAbZ4Qo274oAOWcATmCMABQoMAHUCaMggDkSMFhJIArlhgwAnpAAeSGmjBIAFgQDmMMjlVgAyhDkWAVhEUAaMFDJgAZqqjMOZFBwSHAAbhAAXPxCItDwyOiYbAQIZChKfiw6eigIWCHhwKnpmRDZCGi5+WEEAoLCICCC-GAAYnAwunxkSnIQ4TyaEPjUyGAU+SSGiCZgAHJgiAbGBkoc+GAAKgB0zXVI6hwE7Z0QPAA8m9q6FVBgSggA1qkA7ggA2gC6bnMAfGAAXi21z0dy+zTAAH4wOCwGAolcyjc0GDEF4zmAABJuba4tEYgBKnwh0MxINu8whcOhJy65wJP1+VPhMOxYFx21pZ3pjOJcIRAG56qAmi0ACJ2M4URAEF7GIwYrAIIYjGhIO4TJBTGbzbSYORLBWrdYEHZgACSXjALwIXkQaD2YCkEDcPDsSh4CEgWB4Gm2YAAFFBDGQeKReCQlMEAJR7IQHI5gACiWn1UEu5JR9yerw+33m-yBiPKWdhUO8vggEIRmdRCHRfDZHPxfCJJKxtcpcOpBh4Sir3ZZKbTPIL1bAODIZHwSqFDVF4E2K2IZzyMAMhwIWCgHhIcHyEH0L2ChnkXsQUCQSpIBDIVqwNjsu2igjKATDG8TtiQ5oQl+vEDnEmqq0J2CBKBQOBnF8gIwp8hZgAA3hCF5nEg5zWEce52iQABqqj9mBEFQTwvwBsyWhRJhzhwDh+EwP2ELRlRdi-v+CA3uc7wclyFzARAozqm41HYXAeEERAvzCVhtFifR-bwXOcJuhQZDhBhMl0RJRGQWcZEUVRmlyRJTEsT+f5XhxgG8UBIFCTYRniQxkm-EpYCGNuGk0Vpzk6SR+mDpRDnecZzmmcmqaXum-GCVA0khU5-aufUcKhBJAbMcmdlQEKAC+c4io6S4EN+YDkBZfaKKGn4QP64jWjwWAcMsBAXpZN41YsXqhmgGJIJ4HBuuEyCOqEmBwDgHTBJod7jHYIb6F4DyKHAUg1XcUFeKGBDlZelUhGtHl3GQJCRjwbpoM+dRvqGcgJiVdiwchcIIBALyBpl35se1EB5QVjRFSspV9sgcDUGVMDbncYMmoJ1RSG4vWhGQcD6LN0wmMYPAoPg4Trvd0PdTwvU8I6-XjFgjwEEaIMhOD5C9fIdwkDOfDbmAAQ7hNGzk26WCXXGgi7XIpVAgGLNQ0hEKDWEB7uHYUTgbpPAwUCXxuRwSh4GJXV+GGAZBUrJHRlLg5GJg2x+HIascubUCW0+dqnDwAYBuoJsAv8mgAIQAkCWjRm4WifEKg5usonrLJgodgLlKUc1r8AkGAKlqRABuK8RZwm893Z2w71tR-bVvbE7XSu+7gJe2Avv+9GMfKe6kd2zHcfS4nOtHRnYBG9npt59MxdPogLNKL1UAG-XzLhx6XotxCbdwpr2vJ2lzkZf3jcR163G4vnVshwvgi5Uz2bPGQbwm+z37-QuYAoA-j9P8-L+v2-78f5-b+OnCKZYBQJo7jADAGKHgNQ+AAGEyC9UdF-OB8CEGIKfnUecjo-4AI2AARgRGsDYbE0KrQQILe6EVMEAH0ADyYCTCICsGrAATG4AALG4AAHIfEhKZyFzDejFNUsFMEAAYhQ3Q-JwrQ5CCTQCUJ0JUSAACC50sCaBtriLhlDqG0JgG4dRPCXh8OQIfVBLR0EmjAPQhEm4cb9GGI+OQ+CwyEMFqIuQwsIr0Ngq9d634MrbFQvreh0Y-F-jQgGJhQS179gyrfNBWh-5mIAMw4LMVI1Sa9iGbgigkjRcAaFrlgu8RhYAWFgHYSIrQ747qZJTNkqRUAZGWQUUolRbQOh0hqTkvJqg3D0OSsY8ApiNhMMsUcaxeM7FgFSWpVQziKm3TKlIS8EUmGeLenY3x-ikABkCcEvWWzwnbFTuEbZET0pT36RFeJGwACsIzmC41sQYuQw5Lw0A6hA4wJBHhQAyYmFM1yyGYIKUUkpZTXxzLEdUrQALyGYm3K0HofAgQvPVEBaFgLmGuTAMAYBSA+xVnBZUzq-yyEeKBL3FWh8XHEvRfQshcKoAIo9LBFF0V0WYMxQKbFwDJzTggEqYUAMTFxIwQQAAbHcsZtjSooreQQD5zhHgzEFm4klQLyVrJ8UEzZJzdmhIOTq1hQSu7hK5Ti3sjFqWqtpas7xdgNkhICUEo56cdld0CWa4BPgYB+EEEAA)

It would be interesting to have a version of `Set` which can infer that the final `value` type is the tuple type `[4, 8]`. This is what we will attempt to do.

## Baldi's Basics

Let's begin with a specification of the `Set` type which obeys our chaining constraints, such that the `insert` and `remove` method returns an instance of `Set`:

```ts
export type Set = {
  new (): Set;
  insert(x: number): Set;
  remove(x: number): Set;
  has(x: number): boolean;
  value(): number[];
};
```

The `new (): T` syntax specifies a constructor, and allows the `new` keyword to be used, which in this case is an ergonomic choice.

The next improvement we will make is to add a tuple type parameter to `Set`, which extends an array of numbers. We will additionally make the default value of that type parameter the empty array. This type parameter represents the current contents of `Set`.

```ts
export type Set<Elements extends number[] = []> = {
  new (): Set<Elements>;
  insert(x: number): Set<Elements>;
  remove(x: number): Set<Elements>;
  has(x: number): boolean;
  value(): Elements;
};
```

In preparation, let us next specify that each member function which takes in a number, additionally takes in an inferred type based on the value which it is passed. Each of these types represent the specific value which was passed in.

```ts
export type Set<Elements extends number[] = []> = {
  new (): Set<Elements>;
  insert<SpecificValue extends number>(x: SpecificValue): Set<Elements>;
  remove<SpecificValue extends number>(x: SpecificValue): Set<Elements>;
  has<SpecificValue extends number>(x: SpecificValue): boolean;
  value(): Elements;
};
```

## Tuple Insertion

In the following example, we can see how to represent the addition of a new element into an existing tuple type. This uses a recently developed tuple destructuring syntax. We could also prepend elements by switching the positions of `Ex1_Original` and `Ex1_NewElement` on the last line.

```ts
type Ex1_Original = [2, 4, 8];
type Ex1_NewElement = 10;
type Ex1_ResultantArray = [...Ex1_Original, Ex1_NewElement]; // [2, 4, 8, 10]
```

We can use the above simple example to finish our `insert` method type, by specifying that `insert` returns an instance of `Set` with the type of our specific value appended to the current tuple type. We will additionally introduce some whitespace to reduce visual noise.

```ts
export type Set<Elements extends number[] = []> = {
  new (): Set<Elements>;

  insert<SpecificValue extends number>(
    x: SpecificValue
  ): Set<[...Elements, SpecificValue]>;

  remove<SpecificValue extends number>(x: SpecificValue): Set<Elements>;

  has<SpecificValue extends number>(x: SpecificValue): boolean;

  value(): Elements;
};
```

At this point, we may use the `insert` and `value()` methods and expect they will infer the transient types automatically. This general approach for continually building up types in a "runtime-fashion" is very useful for writing easy-to-use and type-safe libraries.

```ts
const Ex2_Array = new Set().insert(2).insert(4).value(); // [2, 4]
```

## Tuple Removal

As of yet, there is no built-in operation for tuple removal. However, it can be implemented using a recursive loop on the type level, the mechanics of which would detract from this article. Of note - at the time of writing, `ts-toolbelt` uses a less modern variant than the following, and will not work. I may attempt to explain tuple type loops in another article.

```ts
type Filter<T extends unknown[], N> = T extends []
  ? []
  : T extends [infer H, ...infer R]
  ? H extends N
    ? Filter<R, N>
    : [H, ...Filter<R, N>]
  : T;

type Ex3_Original = [2, 4, 8];
type Ex3_ResultantArray = Filter<Ex3_Original, 2>; // [4, 8]
```

We can deputize this ability to empower our `remove` method to remove the corresponding element types from our tuple type.

```ts
export type Set<Elements extends number[] = []> = {
  new (): Set<Elements>;

  insert<SpecificValue extends number>(
    x: SpecificValue
  ): Set<[...Elements, SpecificValue]>;

  remove<SpecificValue extends number>(
    x: SpecificValue
  ): Set<Filter<Elements, SpecificValue>>;

  has<SpecificValue extends number>(x: SpecificValue): boolean;

  value(): Elements;
};
```

At this point, we are able to insert, remove, and get the array value of the numbers we place into our `Set` object:

```ts
const Ex4 = new Set().insert(2).insert(4).remove(2).value(); // [4]
```

## Tuple Insertion #2 - Duplicate Edge Case

Readers following along very closely may have noticed an issue with our `insert` method type - namely, that multiple insertions of the same value will emplace duplicates on the type level. Since `Set` is a set, this is not wanted.

Luckily, with our `Filter` utility type available, we can ensure no duplicates exist by first filtering out that value type.

```ts
export type Set<Elements extends number[] = []> = {
  new (): Set<Elements>;

  insert<SpecificValue extends number>(
    x: SpecificValue
  ): Set<[...Filter<Elements, SpecificValue>, SpecificValue]>;

  remove<SpecificValue extends number>(
    x: SpecificValue
  ): Set<Filter<Elements, SpecificValue>>;

  has<SpecificValue extends number>(x: SpecificValue): boolean;

  value(): Elements;
};
```

Note that we could have just as well determined whether or not the value was already present, and decided whether or not to insert it. This underlines the isomorphism between the value-level and the type-level - specifically that in a lot of cases, any given operation you could think of has both a value-level component and a type-level component, including array operations, arithmetic, graph operations, etc.

As well, any given type specification will have multiple possible representations, with differing efficiency, albeit with respect to compilation time and memory in lieu of runtime cost.

## Tuple Existence Checks

For existence check, we can utilize `extends` - we convert the tuple to a union and perform an extends check to determine whether or not the given element is present in the tuple.

```ts
type Has<T extends unknown[], X> = X extends T[number] ? true : false;

type Ex5_1 = [2, 4, 8];
type Ex5_1_HasFour = Has<Ex5_1, 4>; // true

type Ex5_2 = number[];
type Ex5_2_HasFour = Has<Ex5_1, 4>; // boolean
```

We now have enough code to finish our type specification of `Set`, complete with a type-safe existence check.

```ts
export type Set<Elements extends number[] = []> = {
  new (): Set<Elements>;

  insert<SpecificValue extends number>(
    x: SpecificValue
  ): Set<[...Filter<Elements, SpecificValue>, SpecificValue]>;

  remove<SpecificValue extends number>(
    x: SpecificValue
  ): Set<Filter<Elements, SpecificValue>>;

  has<SpecificValue extends number>(
    x: SpecificValue
  ): Has<Elements, SpecificValue>;

  value(): Elements;
};
```

And we can finish the section with a few examples of existence checking. Even if we insert an element, remove it, and then check, we still get the correct result. In general, this will work until the compiler no longer has patience, which is an internal implementation detail. In that case, the compiler will claim that our `Set` contains `number[]`. Though for reasonable examples, our `Set` type checking works as we expect:

```ts
const Ex5_1 = new Set().insert(2).insert(4).insert(8).has(4); // true
const Ex5_2 = new Set().insert(2).remove(2).has(2); // false
```

## Value-Level

A value-level implementation of `Set` is provided below, mostly to demonstrate the separation between value-level implementation and type-level specification, which is sometimes wise with more involved types.

```ts
const Set = class {
  private set: number[] = [];

  public insert(x: number) {
    this.set = [...this.set.filter((y) => y !== x), x];
    return this;
  }

  public remove(x: number) {
    this.set = this.set.filter((y) => y !== x);
    return this;
  }

  public has(x: number) {
    this.set.includes(x);
    return this;
  }

  public value() {
    return [...this.set];
  }
} as unknown as Set;
```

The downside is that we now are not doing any compile-checks against the implementation of `Set` - namely, we are not checking that `Set` actually does what the types says it will do. The issue with attempting that is that while that approach is possible, it would require every sub-function e.g. `includes`, etc. to also be just as type-safe. Essentially, for libraries in Typescript it's my opinion that it's safer and more readable to keep the type specification and the value-level separate. Application-side code should endeavor to do the opposite however.

It may be possible to automatically extract a simplified type of `Set` which we can validate our runtime implementation against, but it would be hard.

Final note: For pedagogic reasons, I have glossed over some nuance with respect to `new ()` - really, a wrapper type is needed to hide the member functions until the class is actually constructed, which is demonstrated on the TS Playground version of the code.
