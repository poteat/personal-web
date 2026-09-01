---
title: "Enforcing Function Map Constraints"
date: 2020-12-16T19:41:08-08:00
categories: [typescript]
tags: [typescript, programming, type system]
---

Exploring how to enforce type constraints across function maps in TypeScript, where every function must accept a specific parameter type.

<!--more-->

Some "easy to state" problems in Typescript can require somewhat sophisticated type constructs.

Let's say you want to enforce that every function in a particular map takes in as its first parameter, either a number or a string:

```ts
type PermissibleInput = number | string;

const myFunctionMap = {
  foobar(x: number): void;
  barfoo(y: string): void;
}
```

If you do this in the naive way, as e.g. `Record<string, (number | string) => any>`, you will discover that this type actually encodes the requirements that every function must support _both_ input types - which is a problem, as `myFunctionMap` is not actually composed of such functions.

Actually encoding function parameter constraints across an entire function map requires somewhat sophisticated type generics. There are two primary problems that must be solved:

1. Looping over the map on the type level to enforce the constraint per-function
2. Dealing with Typescript's opposite-than-normal handling of function parameter types.

As we'll see, the first issue can be handled by converting the object type into a union type, via the construct `T[keyof T]` - which accesses the values associated with attributes on the object type.

The second issue is interesting, and comes down to the fact that `(1)` does not extend `(2)`:

1. `(x: string) => void`
2. `(x: string | number) => void`

But for arbitrary values and return types, `(1)` does extend `(2)`:

1. `string`
2. `string | number`

## Single Function Case

[Follow along in the TS Sandbox](https://www.typescriptlang.org/play?#code/PTAEGUEsDsHMBsCmoBiBXaBjALpA9tKAMICGAzogFDQkC2iZADiZslHEulrgaRaAG9KoUADMMOfIRqQAbogCCjRvACeAClEAuUOoAeO6GloAjRACdQAH1Bls5mLACUoALwA+UCWiqXAgL6UwqCYBHagtKrsCIhckgRuugagRqYWLh6C-gDcQSIgoAAqABbIMvJeyuZ4LMWgACZ4DCl42KAA7njmANZaweWKymrqkdGcEjzQTtmgBYWqjMgAoubV5gCEoABEdg5wWw1NZC1tiHrYiND126lm5lt5s2AA6mWIiNdk8JCwxdhqoFKJFkkAsEVqMAsqj6ImwC2QAEkyAAFCy0SBkMiQEzjbhSAA8wREKFAZwuV2O+h03l8bk8NOCnlcoGRJHMdEQF3MZHxKHcAG0AAwAXVJ50u9WOu0c1hSxjuoAA-KB7GhkDpRCR4BRcsFxHiEiQhqp8YUxeTJUlqT4MvSfO51ESxDokajzOjMdjcfFoKbPGSJcdVchlWbDIh5OZgn5AsEjSoNKNHN7JtNHgUFMd2sh2t5sAAaFXFDFiCZSUAl6CtLyYViMC71GGVBPqKleG10rLTJ4s6qLSxwxak1ZdUAAWlAegrxyrbRItnsMtHtwsADpKLGCnFJqAALJG4jkKg0ehMFjIbdSfeMPjIISw+GgV1ojFYnGxMsEQkiYnmwNW9taUyBkRCZFk2Q5LkeT5IVRQDCkFz2WBZRXSxlWDUANS1HVHn1H1mzUa9eU-aBrz-BCACVEFCcx6nxaU4ELNsaVtQD3AdJ1RGvF0URfT130vL9BNIo1+W6RBVDwURUBI69hX9cUEODJ0RGVYTrxUzCUgjCxoyyR5QmgcJInUg9mXvH9RDwPATDZNsGOcLJ8ydWzzCsvB1GhOU0nMGNnJEHJHnjQijRGVRTMYNNgkM4zVARaBZC1SB6gixILJEVdMpM2SjX8n8YES756jbGyACtqOwPzgkCuNjWvML4sK5KIu7ApkT7MFB2QCw1i8Y56gYSBzA+DcghPBhmFYYg0DsPB0QALw+FY1l3BgyBIWA72CLqn1491Xy9D8DV9J0SXgy1mI7YCfEZRJWXZegoN5AURXIy0HJQ+UwXQ8w1S0zVtUQXUHyHFAAFUADkiEKBEAHkIYAfV3BRkSRpZdwAISWCiEYACQUcAEeeCj4YAcQR5EFAohRdyWQpsYRwoAE1kSWNLQAR8NI1AGqRDwndgtUIjUvO44qJouiHKY5IWM7Gl2MdH8xG43a3Q9N8UwJCKxIkqSZOOuSFItINfqoJXVP1n0NPNrTwahmH4aRlG0cxhn8cJ4myYpqmabphnmdZvSAgMsI2kiRqkpSnLGDSzjrNc+zFzgKqldc9zPMML7fKcp0CsjkqTHKnAU554HZgAKnLoly9AAARDEVBIVQg0fHquibUAq5-GuFHMWBjEuNo9Z2gByAQxHjuzkgcpwdFkPBkpmNPrIz7y7ln0B58X6uKwS-PkjKiqN63+oZn8EfpxOPqsVgGh3xVPBQGYB7OTBYf4R3ke7ehuHEeR1Haauxxu7ImJMIbk0ptTWm9McYByWCPdc3cd7tTwP2OEoAR4IwviWdWMoYAqkfGPCeNkp46BnnPBep9QDLw8tCHeqFj6UJmHnIqBci6VQoYvHmF8TBoDaMNAAjmgIaHxd4EMWJ-b+Ds-7O0AVjYBBNQFe0gb7GBjMWbwNXNgMg6gABMABmAALAAVicNXYAtUEz1XDnvIqLVciBCAA)

To illustrate the problem in a minimal way, let's attempt to enforce a constraint on a function passed into a higher-order function:

```ts
function apply(f: (x: number | string) => any) {}

const mySingleFunction = (x: number) => {}

apply(mySingleFunction) // Type Error! "string" does not extend "number"
```

To actually encode this, we need to use a trick that involves deferring the type-check to later in the inference. Namely, we want to first build a "helper type" that returns the type `true` or `false` for an arbitrary function type, referring to whether or not its first parameter is a string or number.

```ts
type IsPermissibleFunction<
  F extends (x: any) => any
> = Parameters<F>[0] extends string | number ? true : false;
```

This type is asking whether or not the first parameter of an arbitrary type `F` extends `number | string`. Because we're no longer performing this check _in the context of a function parameter_, the normal and intuitive rules apply. In other words, if we say `A ::> B` means `A extends B`, then:

* `number ::> number | string`
* `string ::> number | string`

In terms of mathematics, type systems like this do form a meaningfully formal system of logic, that can be understood in terms of decomposable operations and axioms. And in that line of reasoning, there is nothing stopping us from proving these type theorems by hand - although the compiler usually does that for us.

The trick is to redefine our `apply` function to cleverly throw a type error if the result of `IsPermissibleFunction` is false. We do this by then asserting that the input is of the `never` type - which can never occurr:

```ts
function apply<T extends (x: any) => any>(f: 
  IsPermissibleFunction<T> extends true ? T : never
  ) {}
```

Again, if our condition represented by `IsPermissibleFunction` passes, then we define `f` to be of type `T` - if not, we define it to be `never`, which no value can possibly meet. Because the compiler automatically infers the narrowest type available, `T` will correspond to the narrowest interpretation of the type we pass in.

## Multiple-Function Map Case

Reusing our `IsPermissibleFunction` type along with the previously discussed `T[keyof T]` trick to convert an object type into a union type, we can devise the following function which demonstrates an attribute-level function parameter constraint:

```ts
function applyMap<FunctionMap extends Record<string, (x: any) => any>>(
  fMap: IsPermissibleFunction<FunctionMap[keyof FunctionMap]> extends true
    ? FunctionMap
    : never
) {}
```

Unpacking this a little bit, we specify that `FunctionMap` is some type which extends a record of strings to functions which take in one parameter. This is merely specifying the constraint that the type discussed is actually a function map.

Next, much like in the single case, we check if the type passes our permissible function check. If so, we apply the `FunctionMap` type to `fMap` - if not, we make `fMap` the `never` type.

This trick works because our `IsPermissibleFunction` type accepts unions just fine - because in this case `Parameters` returns a union for the zeroth parameter of all constituent function types passed, which is then evaluated in the condition as a strict conjunction.

In the end, we are left with a function type which only accepts function maps that obey our initial condition, and rejects all non-compliant function maps:

```ts
const myFunctionMap = {
  foobar(x: string) {},
  barfoo(y: number) {},
};

applyMap(myFunctionMap);

const myInvalidFunctionMap = {
  ...myFunctionMap,
  invalid(x: object) {},
};

// Type error as desired:
applyMap(myInvalidFunctionMap); // TypeError: type (...) does not extend "never"
```

# Customizing Error Messages

Admittedly, never-based type errors can be inscrutable if they appear in application code, i.e. code that is using your shared library which enforces this condition in some part of its interface.

With a bit more work, we can at least display a message to the library-user denoting that something was wrong with the function map passed in. A useful trick common in strongly-typed linear algebra code is error types with particular names, like `MATRIX_SIZE_MISMATCH`. We can take a similar philosophy here:

```ts
type FUNCTION_MAP_MEMBER_HAS_WRONG_PARAMETER_TYPE = { _: never };

function applyMap<FunctionMap extends Record<string, (x: any) => any>>(
  fMap: IsPermissibleFunction<FunctionMap[keyof FunctionMap]> extends true
    ? FunctionMap
    : FUNCTION_MAP_MEMBER_HAS_WRONG_PARAMETER_TYPE
) {}

const myInvalidFunctionMap = {
  foobar(x: string) {},
  barfoo(y: number) {},
  invalid(x: object) {},
};

/**
  * Displays type error:
  *
  * Argument of type '{ foobar(x: string): void; barfoo(y: number): void;
  * invalid(x: object): void; }' is not assignable to parameter of type
  * 'FUNCTION_MAP_MEMBER_HAS_WRONG_PARAMETER_TYPE'.
  *
  * Property '_' is missing in type '{ foobar(x: string): void; barfoo(y:
  * number): void; invalid(x: object): void; }' but required in type
  * 'FUNCTION_MAP_MEMBER_HAS_WRONG_PARAMETER_TYPE'.ts(2345)
  */
applyMap(myInvalidFunctionMap);
```

This is somewhat a blunt tool, but this allows us to define at least a small reference for what the type error is likely to be, so that downstream application users have some idea of what went wrong. You can even include more context in a JSDoc near the "error type", or keep a list of such error types present in your project's documentation.

## Advanced Error Messages

It's possible to specifically extract those attribute keys which contain non-compliant function types, allowing the downstream user to identify more quickly which part of their application has a problem.

With the advent of Typescript 4.2, it is even possible to serialize these extracted types into their own unique error message string type, allowing us to more closely simulate built-in compiler errors. However, this blog post is getting to be long - so that will have to be an exercise for the reader for now.