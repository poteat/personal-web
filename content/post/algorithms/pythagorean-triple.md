---
title: "Pythagorean Triple Problem in Sub-linear Time"
date: 2019-03-10T15:48:49-04:00
categories: [algorithms]
tags: [math, number theory, factorization]
---

We explore a solution to finding Pythagorean triples with a product constraint, achieving O(√n) time complexity by reducing the problem to the well-known 3SUM problem.

<!--more-->

The Pythagorean triple problem is as follows. Given an input integer \\(n\\),
return integers \\(a\\), \\(b\\), \\(c\\) such that the two following conditions
hold:

$$ a b c = n $$
$$ a^2 + b^2 = c^2 $$

I was interested in finding a solution to this problem that was both succint and
had good asymptotic complexity. The solution I found runs in `O(sqrt(n))` time
by deconstructing the problem into the well-known
[3SUM problem](https://en.wikipedia.org/wiki/3SUM).

## Getting the Divisors

We know that the three numbers we generate must all multiply together to form
\\(n\\). Therefore, each number must be a divisor of \\(n\\). There is a
simple `O(sqrt(n))` time algorithm that generates all divisors of \\(n\\):

```ts
// @require n >= 1
export const divisors = (n: number) => {
  const d = _.times(Math.sqrt(n) - 1)
    .map((i) => i + 1)
    .filter((i) => n % i === 0);

  return _.uniq(d.concat([...d].reverse().map((i) => n / i)));
};
```

The algorithm is expressed in TypeScript, in a functional form. The algorithm
takes all numbers in the range of `[1 ... sqrt(n)]` and filters such numbers
that \\(n\\) is divisble by. We are left with all of the divisors up until
\\(\sqrt n\\).

To then get the rest of the numbers, concatenate the current array with each
divisor's pair. This is because if \\(i\\) is a divisor, \\(\frac{n}{i}\\) is
also guaranteed to be a divisor. All references to \_ are
[lodash](https://lodash.com/).

## Invoking the 3SUM Problem

We now have a list of numbers to search from to achieve the two conditions. The
length of the list is on order of `O(log(n))` because that is, up to a constant
factor, how many divisors a given number has.

On inspection, we expect the second condition to be more "stringent" i.e. there
exists fewer combinations which satisfy the condition. Luckily, there exists a
body of knowledge on solving that sort of problem.

### The 3SUM Problem

The 3SUM problem is to, given a list of numbers \\(A\\), return a set of three
numbers \\(a\\), \\(b\\), \\(c\\) such that the following conditions hold:

$$ a + b + c = 0 $$
$$ a, b, c \in A $$

There are many algorithms to solve this, including a relatively simple
\\(O(n^2)\\) solution. However, this does not quite match our problem. However,
if we squint our eyes a bit, we can see how it may be applied. We may perform
some simple algebra on our condition:

$$ a^2 + b^2 = c^2 $$
$$ a^2 + b^2 - c^2 = 0 $$

So we see if we include all negative numbers of our divisor into our search set
\\(A\\), we're much better off. As well, we square each number of our original
divisor set. So, given a divisor set for example, of 30:

$$ {1, 2, 3, 5, 6, 10, 15, 30} $$

We transform this set into the following:

$$ {-900, -225, -100, -36, -25, -9, -4, -1, 1, 4, 9, 25, 36, 100, 225, 900} $$

The 3SUM search is guaranteed to find a 3-set matching our original Pythagorean
condition. However, it will also match false-positives constructed of more than
one negative number. To filter these out, we only consider solutions to the
3SUM problem which possess one negative number.

## Putting it all Together

The following code implements the algorithm described above, taking the divisor
set, transforming it, applying it to the 3SUM problem, and filtering the
results. The overall complexity is \\(O(\sqrt{n})\\) because the complexity of
constructing the divisors is strictly more expensive than solving the 3SUM
problem on the divisor set. The complexity could probably be improved via
Pollard's Rho algorithm, at the cost of sacrificing simplicity.

```ts
// Returns [a, b, c] where a^2 + b^2 = c^2 and a * b * c = n
// If no such 3-tuple exists, returns [].
// Runs in O(sqrt(n)) time.
// @require n >= 1
export const pythagoreanTriplet = (n: number) => {
  let d = divisors(n).map((x) => x ** 2);
  d = [...d]
    .reverse()
    .map((x) => -x)
    .concat(d);

  // O(log(n)^2)
  const p = sum3(d)
    .filter((x) => _.countBy(x, (y) => y < 0).true === 1)
    .map((x) => x.map((y) => Math.sqrt(Math.abs(y))).sort((a, b) => a - b))
    .filter((x) => x.reduce((a, y) => a * y) === n);

  return p.length > 0 ? p[0] : [];
};
```
