---
title: "Type Guard Composition"
date: 2021-11-14T12:08:01-08:00
categories: [typescript]
tags: [typescript, programming, safety, type-guard, type system]
---

Type guards are a powerful tool for type system design. They are used to express
that a type is only valid if it satisfies a certain condition. For example, we
can express that a type is only valid if it is a number or a string.

- [1. Union Type Guards](#1-union-type-guards)
  - [1.1. Naive Union Implementation](#11-naive-union-implementation)
  - [1.2. 2-adic Union Composition](#12-2-adic-union-composition)
  - [1.3. N-adic Union Composition](#13-n-adic-union-composition)
    - [1.3.1. GuardReturnType](#131-guardreturntype)
    - [1.3.2. Variadic Is-Union](#132-variadic-is-union)
    - [1.3.3. References for this Section](#133-references-for-this-section)
- [2. Record Type Guards](#2-record-type-guards)
  - [2.1. Record Type Brief Overview](#21-record-type-brief-overview)
  - [2.2. Naive Implementation](#22-naive-implementation)
  - [2.3. Generic Is-Record](#23-generic-is-record)
- [3. Object Type Guards](#3-object-type-guards)
  - [3.1. Naive Implementation](#31-naive-implementation)
  - [3.2. Generic Is-Object](#32-generic-is-object)
- [4. Array Type Guards](#4-array-type-guards)
- [5. Tuple Type Guards](#5-tuple-type-guards)
  - [5.1. Naive Implementation](#51-naive-implementation)
  - [5.2. Generic Is-Tuple](#52-generic-is-tuple)
- [6. Optionality](#6-optionality)
- [7. Infinite Type Guards](#7-infinite-type-guards)
  - [7.1. Naive Implementation](#71-naive-implementation)
  - [7.2. Use-before-define Issue](#72-use-before-define-issue)
  - [7.3 Lazy Generic Is-Object](#73-lazy-generic-is-object)
- [8. Conclusion](#8-conclusion)

Here is a naive implementation of a type guard:

```ts
const isNumber = (x: unknown): x is number => typeof x === "number";
```

I am using `const` function declaration syntax here - this is just like normal function declaration, but eschews the `function` keyword, and encourages single-expression-style functional programming.

The type guard is a function that takes an unknown value and returns a boolean
value. The function returns `true` if the value is a number and `false` if it
is not.

# 1. Union Type Guards

## 1.1. Naive Union Implementation

We can also specify that a type is only valid if it is a number or a string.

```ts
const isNumberOrString = (x: unknown): x is number | string =>
  typeof x === "number" || typeof x === "string";
```

1. Here we are using `const` function declaration syntax again. We check the native type using `typeof` and then check the type of the value using `||` to combine the two conditions.

## 1.2. 2-adic Union Composition

> Note: `adic` is a term used to describe the number of arguments that a function takes. So 2-adic means that the function takes two arguments. Another term for this is "arity".

However, this type guard is not expressive enough. It would be better if we
composed this type guard out of smaller type guards. To do this, we need a
function that takes two type guards and returns a new type guard. Let us call
this function `isUnion`.

```ts
type Guard<T = unknown> = (x: unknown) => x is T;

const isUnion =
  <T1, T2>(isT1: Guard<T1>, isT2: Guard<T2>) =>
  (x: unknown): x is T1 | T2 =>
    isT1(x) || isT2(x);

const isNumberOrString = isUnion(isNumber, isString);
```

1. We define a new type `Guard` that takes a type parameter `T` and returns a type guard of the specified type.

2. We then define a function `isUnion` that takes two type guards and returns a new type guard. We call this function `isUnion`. This takes two type parameters `T1` and `T2`, which are the types that the returned type guard will check.

3. Finally, we define a function `isNumberOrString` that takes an unknown value and returns a boolean value. We use the `isUnion` function to combine the two type guards into a single type guard.

## 1.3. N-adic Union Composition

> Note: N-adic means that the function takes N arguments. Functions that take an arbitrary amount of arguments are also called variadic functions.

Type guard composition is a way to combine multiple type guards into a single type guard.

It would be nice if `isUnion` could be used to combine an arbitrary amount of type guards. This is possible using tuple types.

```ts
type Guard<T = unknown> = (x: unknown) => x is T;

type GuardReturnType<T extends Guard> = T extends Guard<infer U> ? U : never;

const isUnion =
  <T extends Guard[]>(...guards: T) =>
  (x: unknown): x is GuardReturnType<T[number]> =>
    guards.some((g) => g(x));

const isNumberOrString = isUnion(isNumber, isString);
```

### 1.3.1. GuardReturnType

We define a new type `GuardReturnType` that takes a current Guard type, and returns the type of the value that the guard returns. This is a way to extract the type that a guard type is checking for.

We use the `infer` syntax, which can be a little scary at first. It is a type inference keyword. It allows us to infer the type of a variable. In this case, we are using it to infer the type of the value that the guard returns.

The phrase `infer U` within an `extends` clause creates a new type `U` that may be used within the truthy branch of the `extends` clause. The truthy branch will only be used if the guard is true, i.e. that there _does exist_ a type `U` such that T can possibly extend it.

> Note: `infer` is a way to express _Existential Quantification_ on the type level. This is one way that first-order predicate calculus is related to type systems.

### 1.3.2. Variadic Is-Union

Next is the function `isUnion` that takes an arbitrary amount of type guards and returns a new type guard.

We introduce a type parameter `T` to the function, which is a tuple of type guards. We use the `...` syntax to spread the tuple into an array. We use the `T[number]` syntax to create a union type of all of the type guards in the tuple. This union distributes over the type function `GuardReturnType`, which is a way to extract the type that a guard type is checking for.

Finally, we return a boolean value. We use the `guards.some` syntax to check if any of the guards are true.

### 1.3.3. References for this Section

- [https://javascript.plainenglish.io/typescript-infer-keyword-explained-76f4a7208cb0](https://javascript.plainenglish.io/typescript-infer-keyword-explained-76f4a7208cb0)
- [https://blog.logrocket.com/understanding-infer-typescript/](https://blog.logrocket.com/understanding-infer-typescript/)
- [https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-8.html](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-2-8.html)
- [https://en.wikipedia.org/wiki/Existential_quantification](https://en.wikipedia.org/wiki/Existential_quantification)

# 2. Record Type Guards

Let us also reason about type guards for records. That is to say, let us consider the construction of type guards for record types like `Record<string, number>` or `Record<number, string>`.

## 2.1. Record Type Brief Overview

A Record type is a type that is a collection of key-value pairs. It is a general specification on both key type and value type.

There are a few oddities about Record key types. Namely, the presence of alternative keys does not preclude type validity. For example, the type `{ foo: "bar" }` _does_ extends the type `Record<number, number>`.

This is because `Record<X, Y>` is only a specification that for all keys present that extend type `X`, their value type must extend type `Y`.

One final note is that there are only three type categories that are valid for keys in general: `string`, `number`, and `symbol`.

## 2.2. Naive Implementation

Let us consider writing a type guard that checks if a value is of type `Record<string, string | number>`. In other words, for each string attribute, the value must be either a string or a number.

```ts
const isRecordStringStringOrNumber = (
  x: unknown
): x is Record<string, string | number> =>
  typeof x === "object" &&
  x !== null &&
  Object.keys(x).every((key) =>
    typeof key === "string"
      ? typeof x[key] === "string" || typeof x[key] === "number"
      : true
  );
```

## 2.3. Generic Is-Record

The above type guard is a naive implementation of a type guard for records. It is not expressive enough.

With this in mind, let us make a `isRecord` type guard that takes a key type guard and a value type guard and returns a new type guard.

```ts
type Guard<T = unknown> = (x: unknown) => x is T;

type KeyGuard = Guard<string | number | symbol>;

type GuardReturnType<T extends Guard> = T extends Guard<infer U> ? U : never;

const isRecord =
  <K extends KeyGuard, V extends Guard>(isK: K, isV: V) =>
  (x: unknown): x is Record<GuardReturnType<K>, GuardReturnType<V>> =>
    typeof x === "object" &&
    Object.entries(x).every(([k, v]) => (isK(k) ? isV(v) : true));
```

Now that we have this `isRecord` utility, we can express the type guard for `Record<string, string | number>` as:

```ts
const isRecordStringStringOrNumber = isRecord(
  isString,
  isUnion(isString, isNumber)
);
```

In this way, we have true composability. This is much more expressive than the naive implementation.

# 3. Object Type Guards

To round out the discussion, let us consider the type guard for objects.

## 3.1. Naive Implementation

Let us assume that we have the following type:

```ts
type Person = {
  name: string;
  age: number;
};
```

A naive implementation of a type guard for this Person object would be:

```ts
const isPerson = (x: unknown): x is Person =>
  typeof x === "object" &&
  x !== null &&
  typeof x.name === "string" &&
  typeof x.age === "number";
```

## 3.2. Generic Is-Object

The above implementation of `isPerson` is not expressive enough. Instead, let us make a `isObject` type guard that takes a type guard for each property of the object. It then returns a new type guard.

```ts
type Guard<T = unknown> = (x: unknown) => x is T;

type GuardReturnType<T extends Guard> = T extends Guard<infer U> ? U : never;

type Key = string | number | symbol;

type GuardRecord = Record<Key, Guard>;

const isObject =
  <T extends GuardRecord>(guards: T) =>
  (x: unknown): x is { [key in keyof T]: GuardReturnType<T[key]> } =>
    typeof x === "object" &&
    x !== null &&
    Object.entries(x).every(([key, value]) => guards[key](value));
```

The only novel type mechanism here is the type mapping syntax. We use the `key in keyof T` syntax to map each key in the object to the corresponding checked type.

At the end, we use the `guards[key]` syntax to extract the guard for the key. We ensure that for every key, its guard is satisfied by the value.

With the above implementation, we can express the type guard for `Person` as:

```ts
const isPerson = isObject({
  name: isString,
  age: isNumber,
});
```

This is a much more expressive type guard than the naive implementation. Additionally, by continuous composition, we can express deep type guards:

```ts
const isPerson = isObject({
  name: isString,
  age: isNumber,
  address: isObject({
    street: isString,
    city: isString,
    zip: isNumber,
  }),
});
```

# 4. Array Type Guards

For completeness sake, let us consider the type guard for arrays. This does not involve any fundamentally new concepts, so we can do away with some of the exposition.

Let us consider a type guard to check that a value is an array of strings or numbers. We can naively express this as:

```ts
const isArrayOfStringsOrNumbers = (x: unknown): x is (string | number)[] =>
  Array.isArray(x) &&
  x.every((y) => typeof y === "string" || typeof y === "number");
```

Instead, let us attempt to represent this type guard in a more expressive way, with a `isArray` type guard that takes a type guard for the array elements, and returns a new type guard.

```ts
type Guard<T = unknown> = (x: unknown) => x is T;

const isArray =
  <T extends Guard>(guard: T) =>
  (x: unknown): x is T[] =>
    Array.isArray(x) && x.every((y) => guard(y));
```

We may now express the type guard for `(string | number)[]` as:

```ts
const isArrayOfStringsOrNumbers = isArray(isUnion(isString, isNumber));
```

# 5. Tuple Type Guards

Tuple types are used to represent a fixed number of elements of a given type. Let us consider a game engine, whose entities each have a three-dimensional position and a velocity, corresponding to each X, Y, and Z axis.

```ts
type Coordinate = [number, number, number];

type Entity = {
  id: string;
  position: Coordinate;
  velocity: Coordinate;
};
```

How might we check that an entity is a valid entity?

## 5.1. Naive Implementation

The naive implementation in this case is quite painful and verbose:

```ts
const isEntity = (x: unknown): x is Entity =>
  typeof x === "object" &&
  x !== null &&
  typeof x.id === "string" &&
  Array.isArray(x.position) &&
  x.position.length === 3 &&
  x.position.every((y) => typeof y === "number") &&
  Array.isArray(x.velocity) &&
  x.velocity.length === 3 &&
  x.velocity.every((y) => typeof y === "number");
```

## 5.2. Generic Is-Tuple

Instead, let us make a `isTuple` type guard that takes a type guard for each element of the given tuple. It then returns a new type guard.

```ts
type Guard<T = unknown> = (x: unknown) => x is T;

const isTuple =
  <T extends Guard[]>(guards: T) =>
  (x: unknown): x is { [key in keyof T]: GuardReturnType<T[key]> } =>
    Array.isArray(x) &&
    x.length === guards.length &&
    x.every((y, i) => guards[i](y));
```

We can now express the type guard for `Entity` as:

```ts
const isEntity = isObject({
  id: isString,
  position: isTuple([isNumber, isNumber, isNumber]),
  velocity: isTuple([isNumber, isNumber, isNumber]),
});
```

# 6. Optionality

Sometimes, we may want to express a type guard that is optional. For example, not everyone has a middle name.

Let us consider a `Name` type:

```ts
type Name = {
  first: string;
  middle?: string;
  last: string;
};
```

A naive implementation of a type guard for this type would be:

```ts
const isName = (x: unknown): x is Name =>
  typeof x === "object" &&
  x !== null &&
  typeof x.first === "string" &&
  (typeof x.middle === "string" || x.middle === undefined) &&
  typeof x.last === "string";
```

Luckily, we can express this type guard in a more expressive way:

```ts
const isOptional =
  <T>(guard: Guard<T>) =>
  (x: unknown): x is T | undefined =>
    x === undefined || guard(x);
```

```ts
const isName = isObject({
  first: isString,
  middle: isOptional(isString),
  last: isString,
});
```

> Note: Because the `undefined` native type only has one value, "`x === undefined`" and "`typeof x === "undefined"`" are interchangeable.

# 7. Infinite Type Guards

We are almost done. Let us consider the problem of representing family trees. In our example, we have a `Person` type, each of which may optionally have children who are themselves people.

```ts
type Person = {
  name: string;
  children?: Person[];
};
```

## 7.1. Naive Implementation

We could certainly implement a specific type guard for this type, using recursion:

```ts
const isPerson = (x: unknown): x is Person =>
  typeof x === "object" &&
  x !== null &&
  typeof x.name === "string" &&
  (x.children === undefined || x.children.every((y) => isPerson(y)));
```

## 7.2. Use-before-define Issue

We would want to represent our type guard for `Person` as:

```ts
const isPerson = isObject({
  name: isString,
  children: isOptional(isArray(isPerson)),
});
```

This doesn't work as `isPerson` has not been defined where we are using it.

## 7.3 Lazy Generic Is-Object

The fix is to make `isObject` an optionally lazy generic type guard:

```ts
type LazyGuardRecord = Record<Key, () => Guard>;

const isLazyObject =
  <T extends LazyGuardRecord>(guards: T) =>
  (
    x: unknown
  ): x is { [key in keyof T]: GuardReturnType<ReturnType<T[key]>> } =>
    typeof x === "object" &&
    x !== null &&
    Object.entries(x).every(([key, value]) => guards[key]()(value));
```

Now we can represent `Person` as:

```ts
const isPerson: Guard<Person> = isLazyObject({
  name: () => isString,
  children: () => isOptional(isArray(isPerson)),
});
```

> Note 1: `tsc` as of writing cannot determine the type of `isPerson` due to the recursion used. Instead, you must explicitly type the guard.

> Note 2: This implementation does not handle cyclic references.

# 8. Conclusion

We have now covered the following:

- Type guards for unions, tuples, and optional types
- Type guards for objects
- Type guards for arrays
- Type guards for optional types
- Type guards for recursive types

We have sketched out a framework for building composable type guards that are cleanly expressed and type-safe.

Techniques like this form the basis of runtime type checking in TypeScript.
