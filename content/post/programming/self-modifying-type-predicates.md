---
title: "Self Modifying Type Predicates in Typescript"
date: 2020-05-03T19:41:57-07:00
categories: []
tags: []
---

Typescript's type system is uniquely powerful among traditional programming languages, nearing the expressive power of Haskell or Idris, while also remaining flexible enough for production applications.

Type predicates are a useful tool in building a well-typed software framework. Essentially, they allow you to "simulate" [dependents types](https://en.wikipedia.org/wiki/Dependent_type), a powerful type feature present in Idris

Further explanation on type predicates can be found [here](https://www.typescriptlang.org/docs/handbook/advanced-types.html#using-type-predicates).

One little-known fact

A basic example is as follows:

```ts
type Dog = {
  bark: () => "woof"
}

// An object is a dog if it barks
function isADog(maybeDog: any): maybeDog is Dog {
  return maybeDog?.bark() === "woof"
}

let dog: any = {}

if (isADog(dog)) {
  // Here, we (and the compiler) are 100% certain that `dog` is of type `Dog`.
  dog.bark()
}
```