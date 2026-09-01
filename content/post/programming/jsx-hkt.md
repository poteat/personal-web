---
title: "Higher-kinded types in declarative JSX syntax"
date: 2026-01-24T23:39:00-08:00
categories: [programming]
tags: [typescript, programming, type-system]
---

I've oft thought JSX an under-utilized syntax. In the current day, JSX is
cruelly relegated to frontend component architectures. In my view, there's much
to explore re using JSX as a way to represent other interesting things.

<!--more-->

## What is JSX anyway?

JSX is a syntactic sugar, technically independent of React, but practically used
primarily as syntactic sugar for `React.createElement`.

JSX is composed of three parts:

| Part     | Description                                                     |
| -------- | --------------------------------------------------------------- |
| Tag      | The component being rendered                                    |
| Props    | A key-value object representing attributes for the component    |
| Children | An array of nodes that in some sense are 'contained' by the Tag |

The below snippet illustrates the placement of these elements:

```tsx
<Card /* <-- tag */
  elevation={2}
  rounded
  padding="lg"
  onClick={handler} /* <-- props */
>
  <CardHeader /> {/* <-- children */}
  <CardBody />
</Card>
```

As well, here is the desugared React form:

```ts
React.createElement(
  Card,
  { elevation: 2, rounded: true, padding: "lg", onClick: handler },
  React.createElement(CardHeader, null),
  React.createElement(CardBody, null),
);
```

The former has in my view some ineffable appeal. Perhaps the ancient XML
structure tickles something in our evolutionary hindbrain (since XML of course
predates the ancestral environment).

This je ne sais quoi perhaps comes down to the clear tree-like representation,
or even the declarative style of defining what _is_, rather than an iterative
series of von Neumann-esque steps. We elide the 'detail' of how these are
created.

## Alternative JSX

The signature of `React.createElement` is `(tag, props, ...children)`. In
principle, we can replace `React.createElement` with an arbitrary function `jsx`
that resolves the three parameters to an arbitrary value and type.

There is prior art here - the TypeScript devs
[briefly experimented with narrower return types for JSX](https://github.com/microsoft/TypeScript/pull/29818),
but ran into performance problems. As it stands in early 2026, TypeScript is
hardcoded to type all JSX as returning an opaque `JSX.Element`.

However, [ts-patch](https://www.npmjs.com/package/ts-patch) exists! So it's
quite feasible to use JSX for alternative purposes.

## JSX for higher-kinded types

When specifying computation in a point-free way... well, the syntax can become
quite baroque and LISPy. It's something I've struggled with for a long time (as
any aficionado of Lodash or Ramda can also say). However, I recently got
type-safe compiler patching and language server patching working - and I have to
say I find the result eminently comprehensible comparatively when using
[hkt-toolbelt](https://github.com/poteat/hkt-toolbelt):

```tsx
const extractRouteParams = (
  <Kind.lazyPipe>
    <String.split>{"/"}</String.split>
    <List.filter>
      <String.startsWith>{":"}</String.startsWith>
    </List.filter>
    <List.map>
      <String.tail />
    </List.map>
  </Kind.lazyPipe>
);

const result = extractRouteParams("/users/:userId/posts/:postId");
//    ^?       ["userId", "postId"]
```

In comparison, the non-JSX representation of the above is:

```ts
const extractRouteParams = Kind.lazyPipe([
  String.split("/"),
  List.filter(String.startsWith(":")),
  List.map(String.tail),
]);
```

Arguably, in the above example, the function call form is certainly more terse.
I think the real power shines when we need to 'emulate control structure' on the
type level.

### Branching example

Here, we demonstrate a type-level pipeline for converting words into 'pig latin'
form.

```tsx
const LengthGreaterThanOne = (
  <Kind.pipe>
    <String.length />
    <NaturalNumber.isGreaterThan>{1}</NaturalNumber.isGreaterThan>
  </Kind.pipe>
);

const MoveFirstLetterToEndAndAddAy = (
  <Kind.lazyPipe>
    <Kind.juxt>
      <String.first />
      <String.tail />
    </Kind.juxt>
    <Kind.uncurry>
      <String.append />
    </Kind.uncurry>
    <String.append>{"ay"}</String.append>
  </Kind.lazyPipe>
);

const If = (
  <Kind.uncurry>
    <Conditional.if />
  </Kind.uncurry>
);

const pigLatinWord = (
  <If>
    <LengthGreaterThanOne />
    <MoveFirstLetterToEndAndAddAy />
    <Function.identity />
  </If>
);

pigLatinWord("hello"); // "ellohay"
pigLatinWord("a"); // "a"
```

## Final words

I'm just a fan of representing point-free structure declaratively - there's a
sort of code-as-data lispiness to it. Because a lot of point-free semantics is
about transformation / composition, this form seems quite natural.
