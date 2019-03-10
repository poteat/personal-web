---
title: "Mathematica Steps to LaTeX [WiP]"
date: 2019-02-01T15:01:48-05:00
categories: [simulation]
tags: [math, mathematica, latex, wip]
---

A common problem when using Mathematica to derive expressions is similar to a
big problem plaguing machine learning algorithms today: It is difficult or
impossible to explain the result due to the internal complexity of the black-box
which generates it.

Mathematica's internal algorithms for performing various symbolic computation
are built for speed, not simplicity, and in many cases the method Mathematica
uses is nothing like the manual way humans would find the solution.

For simple cases, a workaround is passing your problem to the `WolframAlpha[]`
command in Mathematica as a string, and then choosing to see the steps laid out,
in the way Wolfram Alpha presupposes a human would do it. This has its own
problems, namely in the limited complexity of problems WolframAlpha can handle
as compared to Mathematica. However, it is enough to get the job done in some
cases.

However, although Mathematica then displays the steps, it's internal interface
for converting those step-expressions to LaTeX is hit-and-miss, which results in
trouble when trying to create documentation. However, it does allow generation
of steps in plaintext format.

Enter this web-page, which converts Mathematica plaintext steps into
well-formatted LaTeX. The following command will generate the plaintext steps
for a given simple problem.

```
ShowSteps[exp_] :=
 WolframAlpha[
  ToString@HoldForm@InputForm@exp, {{"Input", 2}, "Plaintext"},
  PodStates -> {"Input__Step-by-step solution"}]
```

This app is still in beta, and the parsing is not 100% complete. So, you will
have to manually fix some things until I get time to write a proper parser.
I've noticed any instances of `integral` or `bracketing bar` still require
adjustment.

## Usage

1. Use the `ShowSteps[]` command to get the derivation steps in plaintext.
2. Copy the plaintext into the input box on this page.
3. Copy the output LaTeX into your LaTeX editor of choice.

## Plaintext Input

<textarea id="text-input" class="monospace" rows="20" cols="150"></textarea>

## LaTeX Output

<textarea id="text-output" class="monospace" rows="20" cols="150" readonly></textarea>

<script type="text/javascript" src="/js/simulation/mathematica-steps-to-latex.js"></script>
