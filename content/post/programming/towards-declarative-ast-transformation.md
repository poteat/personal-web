---
title: "Towards type-aware declarative codemods via unification"
date: 2025-09-07T11:13:46-07:00
categories: [programming]
tags: [programming, ast, meta, codemod]
---

I've been playing with codemod transformations for TypeScript using
[`jscodeshift`](https://github.com/facebook/jscodeshift) (from Facebook) and
[`ts-pattern`](https://github.com/gvergnaud/ts-pattern). Working closely with
these has made me want a declarative type-aware codemod engine for TypeScript,
which I haven't yet been able to find.

<!--more-->

The basic structure of these codemods follows a pattern matching approach:

<details>
<summary>Show codemod template</summary>

```ts
import type { Transform, FileInfo, API, ASTPath } from "jscodeshift";
import { match, P } from "ts-pattern";

const pattern = {
    /* Some AST pattern to match against with extracted selectors */
}

const isEligible = (path: ASTPath) => {
  return match(path.node)
    .with(pattern, () => true)
    .otherwise(() => false);
};

export const transform: Transform = (fileInfo, api) => {
  const j = api.jscodeshift;
  const root = j(fileInfo.source);

  root
    .find(/* Some particular node type */)
    .filter(isEligible)
    .replaceWith((path: ASTPath) =>
      match(path.node)
        .with(pattern, ({ test, /* Some set of selected fragments */ }) =>
          /* Some AST builder using jscodeshift utils */
        )
        .otherwise(() => path.node)
    );

  return root.toSource();
};

export const matches = (fileInfo: FileInfo, api: API): boolean => {
  const j = api.jscodeshift;
  const root = j(fileInfo.source);

  const matching = root
    .find(/* Some particular node type */)
    .filter(isEligible);

  return matching.length > 0;
};

export default transform;
```

</details>

As a more concrete example, let's take the simple case of a if-else condition
whose consequent (truthy branch) and alternate (falsey branch) are both
immediate returns:

```ts
function renderPetName(pet) {
  if (pet.type === "dog") {
    return `Woof: ${pet.name}`;
  } else {
    return pet.name;
  }
}
```

We could distribute the conditional into the branches, resulting in the
following alternative more terse implementation:

```ts
function renderPetName(pet) {
  return pet.type === "dog" ? `Woof: ${pet.name}` : pet.name;
}
```

An example codemod using the aforementioned jscodeshift and ts-pattern would
look like this:

<details>
<summary>Show complete codemod 'if-to-ternary-return' example</summary>

```ts
/**
 * Transform if-else statements with returns into ternary expressions
 */
import type { Transform, FileInfo, API, ASTPath } from "jscodeshift";
import { match, P } from "ts-pattern";

const ifWithReturnsPattern = {
  type: "IfStatement",
  test: P.select("test"),
  consequent: {
    type: "BlockStatement",
    body: [
      {
        type: "ReturnStatement",
        argument: P.select("consequentArg"),
      },
    ],
  },
  alternate: {
    type: "BlockStatement",
    body: [
      {
        type: "ReturnStatement",
        argument: P.select("alternateArg"),
      },
    ],
  },
} as const;

/**
 * Check if a node is an if-statement eligible for transformation to ternary
 */
const isTransformableIfStatement = (path: ASTPath) => {
  return match(path.node)
    .with(ifWithReturnsPattern, () => true)
    .otherwise(() => false);
};

const transform: Transform = (fileInfo, api) => {
  const j = api.jscodeshift;
  const root = j(fileInfo.source);

  root
    .find(j.IfStatement)
    .filter(isTransformableIfStatement)
    .replaceWith((path: ASTPath) =>
      match(path.node)
        .with(ifWithReturnsPattern, ({ test, consequentArg, alternateArg }) =>
          j.returnStatement(
            j.conditionalExpression(test, consequentArg, alternateArg)
          )
        )
        .otherwise(() => path.node)
    );

  return root.toSource();
};

/**
 * Check if the selected code can be transformed
 */
export const matches = (fileInfo: FileInfo, api: API): boolean => {
  const j = api.jscodeshift;
  const root = j(fileInfo.source);

  const matchingIfStatements = root
    .find(j.IfStatement)
    .filter(isTransformableIfStatement);

  return matchingIfStatements.length > 0;
};

export default transform;
```

</details>

The above transform is pretty nice - it abstracts away source text and only
deals with recognition and transformation on AST structures. However, there are
a few core flaws in this representation:

1. `jscodeshift` has no affordance to inspect the type of an expression.
2. There is no ability to avoid recomputing certain steps between the match and
   transform.
3. Most critically, we must use different semantics for representing two
   elements:
   - The structure to _match_.
   - The structure to replace the match with.

# Towards unification

The concept of unification - at least how I'm using it - refers to the idea of
using equivalent semantics between the matched structure and the structure-
builder to replace with. There are some tools which do a limited\* form of this
via pattern codes (e.g. Comby, ast-grep). My umbrage is two-fold:

- these tools also don't allow type-semantic analysis.
- and also don't _really_ support algebraic parser-combinator-esque
  structures, like match [this] OR [that], MAYBE [this], etc., in my opinion.

So, I think there's space for a tool that uses direct-ish AST pattern matching
_embedded_ in TypeScript, that also supports type-level semantics. It would use
the same semantics for matching as it does replacing, based on a pattern-
matching, declarative philosophy.

For the above rule, it would look something like this:

```ts
const ifToTernary = transform({
  from: U.ifStatement({
    test: $("test"),
    consequent: U.block({
      body: [U.returnStatement({ argument: $("consequent") })],
    }),
    alternate: U.block({
      body: [U.returnStatement({ argument: $("alternate") })],
    }),
  }),

  to: ({ test, consequent, alternate }) =>
    U.returnStatement({
      argument: U.conditional({
        test,
        consequent,
        alternate,
      }),
    }),
});
```

<details>

<summary>ast-grep comparison for fairness sake</summary>

To be fair, `ast-grep` is quite terse! Still, there's no hope of either
inspecting types, or doing complex actions like "find common subexpressions".

```txt
rule:
  pattern: |
    if ($TEST) {
      return $CONSEQUENT;
    } else {
      return $ALTERNATE;
    }
fix: |
  return $TEST ? $CONSEQUENT : $ALTERNATE;
```

</details>

There's a few things going on here - introduced into the scope are `transform`,
`U`, and `$`:

- `transform`: specify a transformation via `from` and `to` AST structures.
- `U`: namespace of AST matcher / builders.
- `$`: wildcard operator for pattern-matching and captured names.

A few design choices:

1. All functions are unary, taking in objects (except for $).
2. Code is represented as an explicit AST, not with code-pattern wildcards.
3. Captures come through the context passed into `to`.

Although it's not really within scope of this article, as a hint towards type
awareness, I'm thinking expressions, captures could have a jest-like building
pattern syntax that specifies type constraints, probably with its own pattern-
matching syntax to match against more complicated types (like generics).

As far as type _safety_ of the actual transformation goes, I'm thinking capture
names can be type-level captured such that downstream usage is known.

# Data-flow semantics

A core piece of this is a "context data-flow" using this $ concept. In the
initial step, $ gets populated with matched fragments. I will elide this for
now; instead, I want to explicate the `.with` builder that is a core piece of
this design.

```ts
// { port: 3000, host: "localhost", ...url, isSecure: false }
const result = scope({ port: 3000 })
  .with(() => ({ host: "localhost" }))
  .with(({ port, host }) => ({ url: `http://${host}:${port}` }))
  .with(({ port }) => ({ isSecure: port === 443 }))
  .value();
```

This isn't used in the parser above, but it's a core piece - the ability to
type-safely 'merge' / 'overwrite' keys into a shared context which then
eventually gets used.

I have a small demonstration of the type-level semantics for the data-flow
pattern here:

- [TS Playground Link](https://tsplay.dev/mMkzkw)

# Next steps

I think the next step would be to come up with a type definition for
`transform`, `U`, and `$` - and then make up some "fantasy" codemods that could
form the basis of a test suite / requirement set to build towards.
