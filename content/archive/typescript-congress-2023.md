---
title: "The Potential of Higher-Kinded Types for Library Semantics"
date: 2023-09-21
description: "Talk given at TypeScript Congress 2023. Abstract and transcript."
build:
  list: never
  render: always
sitemap:
  disable: true
---

*Talk given at [TypeScript Congress 2023](https://typescriptcongress.com/), 8:12 minutes. This page is an archived copy of the abstract and transcript; the recording is hosted by the conference.*

## abstract

There is a wall that we all hit when developing more sophisticated types: how can I 'abstract out' certain commonalities in my type-level logic? How can I make my types more reusable and composable? How can I make my types more expressive?

This talk will introduce the fundamentals of Higher-Kinded Types, a compelling concept hitherto underutilized, and explore how they can significantly enhance the expressiveness of library semantics, leading to a more intuitive developer experience (DX). We'll demonstrate how HKTs can provide an elevated abstraction level, allowing you to model complex domain problems more naturally and in a type-safe manner.

Join us to understand how leveraging HKTs can elevate your TypeScript coding practice, optimizing the semantics and delivering a more potent and featureful library interface.

## transcript

Hey there, everyone. I'm excited to talk about the potential of higher kinda types for library semantics today, as part of the TypeScript Congress 2023 lightning talk. First, a little bit about myself. My name's Alice Potit. I'm an engineering manager at Volley, where we are creating the future of voice-enabled entertainment. I have a passion for type-level programming. I've created HKT Toolbelt, which we'll mention a little bit later. You can read about my programming on my blog at code.lol. And I'm excited to talk about the flexibility of higher kinda types in TypeScript today.

So, library semantics. What do we mean by this? So, we want the type system to infer as much about our code as possible. Often, libraries don't do it. So, in this code example, we're using Lodash. We are doing a chain on some sort of object. We're calculating the keys, and then we're mapping those keys to convert them all to uppercase. What we know the value to be is A, B, and C in uppercase, but Lodash just infers an array of strings. So, this is sometimes very inconvenient, and forces us to make explicit type declarations when we otherwise would not have to. So, HKTs basically make better inference possible. We can use HKTs to represent type level operations, and we can compose types together using functional semantics. We can do this so well that end users never have to write any sort of custom types themselves.

So, what are higher kind of types? Basically, a kind is a type associated with a type constructor. In TypeScript, you would know this as like type foo of T equals T, right? The simplest kind is just star, these are your base types. And the next simplest kind is star to star, which is your normal sort of one-erity generic. So, like, capitalize of S or promise of T, etc. So, TypeScript natively supports these two, but we want more. So, we would like to support, for example, a type that takes in a type, sort of generic itself, and a value which represents an array, and we want to loop over that array applying this type operation to each element. So, the kind associated with this would be this sort of complicated expression, which we need to do clever things to support in the TypeScript system. So, what are we actually trying to do? So, what we want to do is we want to write code like this, so we want to say we want to use this operator, or any sort of application operator, and say, oh, right. We want to apply the operation capitalize to map, so that we get map capitalize, which, you know, converts capitalize into something that can be mapped over an array, and then we want to apply that to an array to get a result. So, we're extracting out the logic intrinsic to looping over an array and applying a transformation to each element.

This is surprisingly possible in TypeScript. So, here's the minimum definition needed to create this rich set of higher kind of types. Basically, what's going on here is that we are exploiting the fact that on interfaces, the types of functions can be a function of attributes on the object. So, basically, what we're doing is we are filling in the parameter represented by the x element on line two and then extracting out the return type of f.

Here's an example of the identity sort of higher kind of type. What we say identity extends kind and then we just return type of x for the underlying sort of transformation we are representing. So, always the transformation is on the right-hand side.

This is a slightly more complicated example. We don't need to understand or walk through all of this, but essentially on line 11 here, we are applying append to this bar string, which creates a function that appends the string bar to any string that it's given and then we're passing in foo so we get foo bar. What you'll notice is that all arguments are curried in this new semantics. We can also do map, as I mentioned before. Again, we don't need to understand the entire logic here but notably what we're doing is we are taking this append function that we made earlier, we are sort of converting it to something that can be mapped over an array and then we are running it over an array so we get foo bar and baz bar.

All right, so that was a lot of code listings. The question would be, how do we actually use this in real programming? To do this, generally speaking, we want to use a process that I call kind ratification but basically we are bringing down a higher kind of type and we are giving it a callable interface so on line two we're saying the callable function is going to be a generic function that is an input of the kind associated with this type. We are inferring what that literal constant is going to be and then we are basically recursively executing that across all of the arguments that this higher kind of type is returning. I am not including the full implementation here but it's not much more complicated than this. And essentially what this allows us to do is to create functions which behave like higher kind of types.

So using this, we can create this reified map view including the implementation. So we have a map here very simple sort of curried map logic and then we say as reified map and then we have append which is just as reified append and then we can create this result expression where we are sort of mapping over an array with this append statement so that we get hello exclamation mark world exclamation mark. So we've created these composable functional utilities that are sort of that have intelligent type inference associated with them.

So up until now we've used point free semantics to write our code where whereby we're not explicitly mentioning any arguments to our functions but you know more often folks use fluent API design for example in lodash with their chaining semantics so we can actually that using HKTs not including the full implementation but what we want in the end is and what we can get is a chaining interface that actually computes the type level result as you are executing these operations and chaining these operations together. So what we infer in the end is A and B and C.

That's my lightning talk. Thank you so much for listening.
