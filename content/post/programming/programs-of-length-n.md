---
title: "Programs of Length N: Collatz, Chaitin, and Church"
date: 2021-09-03T15:12:34-07:00
categories: [programming, mathematics]
tags: [lambda calculus, programming, math]
---

There are a few interesting questions about the nature of programs, and specifically about sets of programs, as represented by lambda calculus expressions.

- [1. How many programs have N terms?](#1-how-many-programs-have-n-terms)
- [2. How fast does the set of programs of length N grow?](#2-how-fast-does-the-set-of-programs-of-length-n-grow)
- [3. How many programs of length N converge?](#3-how-many-programs-of-length-n-converge)
- [4. What is the longest-running convergent program of length N?](#4-what-is-the-longest-running-convergent-program-of-length-n)
- [5. How fast does `BB(N)` grow?](#5-how-fast-does-bbn-grow)
- [6. What percentage of programs converge?](#6-what-percentage-of-programs-converge)
- [7. What is the shortest program that diverges?](#7-what-is-the-shortest-program-that-diverges)
- [8. Can programs eventually converge to longer expressions?](#8-can-programs-eventually-converge-to-longer-expressions)
- [9. What is the shortest program which converges to a given value?](#9-what-is-the-shortest-program-which-converges-to-a-given-value)

# Quick Primer on the λ-calculus

First, what is a program? Let's assume our language is the untyped lambda calculus. In this form, a program is a lambda expression, which executes via _beta reduction_.

For example, here is the identity function in the lambda calculus:

```lambda
(λx. x)
```

This term does not reduce - in other words, it's a _non-reducible expression_, or in other words a _value_. If we apply the identity function to another term, it does reduce, via _beta reduction_:

```lambda
(λx. x) x
--> x
```

Expressions may be _convergent_, or _divergent_. If a term is _divergent_, it is reducible, but _beta reduction_ may be applied an arbitrary number of times. A prime example is the _omega_ combinator, which diverges:

```lambda
(λx. x x) (λx. x x)
--> (λx. x x) (λx. x x)
--> (λx. x x) (λx. x x)
--> ...
```

For a given expression, we can count how many _terms_ it has. For example, the identity function has two terms: `(λx. x)` and `x`. We can then talk about _"all expressions with N terms"`_:

```lambda
1 term:
  x
  (λx. x)

2 terms:
  x x
  (λx. x x)
  (λx. x) x
  (λx. x) (λx. x)
  x (λx. x)
  (λx. (λx. x))
  ...

3 terms:
  ...
```

For a convergent expression, we can also talk about _how many beta reductions are needed_ until it is fully reduced.

## 1. How many programs have N terms?

This is a straight-forward counting problem. In the untyped lambda calculus, there are only two expressions composed of one term: `x` and `(λx. x)`. For two terms, there are more possibilities, and so on.

One important aspect to note is that the number of possible programs of a given length is always finite.

## 2. How fast does the set of programs of length N grow?

Because of the recursive nature of lambda calculus, the number of programs should roughly follow the [Catalan sequence](https://en.wikipedia.org/wiki/Catalan_number).

The Catalan numbers represent, for example, how many different ways to write a well-balanced set of parentheses: `()`, `()()`, `(())`, `(()())`, `((()))` etc. In this way, it is analogous to lambda calculus expressions.

The Catalan sequence grows in proportion to the factorial, i.e. `O(n!)`.

## 3. How many programs of length N converge?

Remember, to _converge_ means to eventually reduce to a single value, such that _beta reduction_ can no longer be performed.

This is actually a non-computable function on N - no matter what technological or mathematical advancements we make, we cannot write a function that computes the number of programs of length N that converge.

Intuitively, this is because of the [halting problem](https://en.wikipedia.org/wiki/Halting_problem), whereby we cannot write a function that computes whether any given expression is convergent or divergent.

An intuitive proof of the halting problem is that programs represent proofs. A famous conjecture that is simple to state, but has not been proved is the [Collatz conjecture](https://en.wikipedia.org/wiki/Collatz_conjecture), or the "3n + 1" problem:

```ts
collatz(n: Integer)

  if n == 1
    return 1

  if n is even
    return collatz(n / 2)

  if n is odd
    return collatz(3n + 1)
```

The Collatz conjecture basically states that the above program will always converge (or _halt_) for any positive integer.

The interesting thing about this problem is that it's representation in most programming languages is quite short. Indeed, the fact that humans have thus far been unable to tell if the above program halts or not is intriguing, and gets into the core of why mathematics possesses an intrinsic "difficulty".

## 4. What is the longest-running convergent program of length N?

We define "runtime" to be how many _beta reductions_ are needed to reduce a program to a single value. Because we specified that the programs converge, the runtime will be finite.

This is actually non-computable as well - we cannot write a function that computes the runtime of the longest-running convergent program of length N, nor finds it.

This is called the [busy beaver](https://en.wikipedia.org/wiki/Busy_beaver) problem, and the corresponding function, i.e. the number of _beta reductions_ needed to reduce the longest-running program of length N, is referred to as `BB(N)`, e.g. `BB(1)` for the lambda calculus would be 0.

The concept of longest-running programs is deeply tied to the Collatz conjecture. Indeed, many of the longest-running programs work on a similar basis to the 3n + 1 problem.

Since it's non-computable to decide whether a program is convergent or divergent, `BB(N)` is a non-computable function. Indeed, we only know the first few values of `BB(N)`, and discovering new values requires deep contributions to mathematics.

## 5. How fast does `BB(N)` grow?

The busy beaver function grows _faster_ than _any computable function_. Effectively, it exists in its own computational complexity class - `O(BB(N))`. In other words, there is no possible function you could evaluate that would grow faster than `BB(N)` - it has no upper bound that can be evaluated.

An intuitive explanation is that `BB(N)` "optimally" uses the space given to it to express arbitrarily sophisticated mathematical ideas. For that reason, it grows faster than fast-growing computable functions e.g. `Ackermann(N, M)`, or `TREE(N)`, because at some point it will "embed" them.

## 6. What percentage of programs converge?

In other words, for a randomly selected program of any length, what is the likelihood that it converges? We can represent this via a single real number, but notably this number itself is non-computable.

In other words, there is no algorithm which will generate N bits of the answer. This number is known as [Chaitin's constant](https://en.wikipedia.org/wiki/Chaitin%27s_constant), Ω.

Notably, you _can_ write a function that, over time, executes in parallel all programs of successively longer lengths, whereby when one converges it is counted towards a running percentage. As the program continues running, this tallied percentage approaches Chaitin's constant - although it may do this so slowly that it's inpracticable.

In the limit, Chaitin's constant requires `O(BB(N))` steps to find the first `N` bits of the answer. Since `BB(N)` is itself non-computable, we cannot calculate how much time would be needed to find the first `N` bits.

## 7. What is the shortest program that diverges?

Within the lambda calculus, the shortest expression which diverges is omega, i.e. `(λx. x x) (λx. x x)`, because it can undergo an arbitrary number of _beta reductions_.

## 8. Can programs eventually converge to longer expressions?

Yes. Here is an example:

```lambda
(λm. λn. n m) (λf. λx. f f x) (λf. λx. f f f f f x)
--> ...
--> (λf. λx. f f f f f f f f f f f f f f f f f f f f f f f f f f f f f f f f x)
```

This is a very tedious process, and I would need to write a program to do it, but the above form is an example of a lambda calculus program that eventually converges to a form longer than itself.

This example utilizes [Church encoding](https://en.wikipedia.org/wiki/Church_encoding#Calculation_with_Church_numerals). In the above initial expression, the term `(λm. λn. n m)` represents exponentiation, while the other two terms represent `2` and `5` respectively. This expression reduces to the correct result, which is `32`.

This is the basis of compression.

## 9. What is the shortest program which converges to a given value?

By "value", we mean a non-reducible expression, i.e. one in which _beta reduction_ cannot be performed.

This is non-computable - there is no function that computes the shortest program that converges to a given value, nor is there a function which computes the _length_ of the shortest program which converges to a given value.

This is essentially [Kolmogorov complexity](https://en.wikipedia.org/wiki/Kolmogorov_complexity), which is non-computable for a given value.

In practice, [neural networks are quite good at compressing data](https://paperswithcode.com/task/image-compression). This is likely due to the [universal approximation theorem](https://en.wikipedia.org/wiki/Universal_approximation_theorem) of neural networks. Finite-size neural networks can represent computable functions, but it's unclear how much they can represent non-computable functions.
