---
title: "Dijkstra's Shunting Yard in Typescript"
date: 2019-12-23T16:39:53-08:00
categories: [algorithms, typescript]
tags: [parsing, dijkstra]
---

The shunting yard algorithm converts infix expressions (i.e. `1+2`) into reverse Polish notation, i.e. `1 2 +`, which lends itself well to execution on a stack machine.

*An aside: I wanted to revisit this algorithm because it was one of the first I implemented in C during self-study [five years ago](https://github.com/poteat/infix_to_rpn/blob/master/main.c).  In a way, reimplementing it is a way of measuring my progress since then.*

The internal details aren't too complicated - it's based on the simple pseudo-code of the Wikipedia article describing the [shunting yard algorithm](https://en.wikipedia.org/wiki/Shunting-yard_algorithm#The_algorithm_in_detail).  However, the interesting parts I think are the high-level design decisions.

```ts
export const shuntingYard = (operatorDefinition: OperatorDefinition) => (
  tokens: string[]
) => {
  const { outputStack, operatorStack } = tokens.reduce(
    (
      {
        outputStack,
        operatorStack
      }: { outputStack: string[]; operatorStack: string[] },
      token
    ) => {
      if (token === "(") {
        // Internal logic... left parens
      } else if (token === ")") {
        // Internal logic... right parens
      } else if (operatorDefinition[token] !== undefined) {
        // Internal logic... operators
      } else {
        // Internal logic... tokens
      }

      return {
        outputStack,
        operatorStack
      };
    },
    { outputStack: [], operatorStack: [] }
  );

  // More parsing logic

  return outputStack;
};
```

The entire function is curried on the structure that defines the operations and the input. In other words, the outer function returns a parser specific to a given language definition.  For the purposes of the algorithm, this structure just defines the priority (as in order-of-operations) for each operator.

We use a `reduce` method on line 4 to map through the tokens, keeping the two intermediary stacks as parameters and return values of the central parsing function.  As consistent with the algorithm, both stacks start out empty.

The final interesting thing we do is that we assume any non-recognized token is a item to be operated on.  This allows us to define and process non-numerical fields such as sets or Boolean algebraic expressions, which I demonstrate on [Github](https://github.com/poteat/shunting-yard-typescript/blob/master/test/index.test.ts).  What's more, these structures do not need to be explicitly defined or recognized, as long as the operator functions know how to process them.


