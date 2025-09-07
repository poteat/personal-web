---
title: "Quadratic Bezier Curves"
date: 2019-01-25T17:40:45-05:00
categories: [bioinformatics]
tags: [javascript, demo, curves]
---

An interactive visualization of quadratic Bézier curves, demonstrating how three control points define smooth parametric curves commonly used in computer graphics and design.

<!--more-->

Quadratic Bézier curves are explicit parametric functions of the following form:

<div>
$$
x(t) = (1-t)^2 x_0 + 2t(1-t) x_1 + t^2 x_2\\
y(t) = (1-t)^2 y_0 + 2t(1-t) y_1 + t^2 y_2\\
t \in \mathbb R[0,1]
$$
</div>

These curves are perhaps the simplest class of parametric curves, but useful in
their own right. This is a small demo of such curves.

Drag the control points around to see the curve change.

<canvas id="canvas" width="500" height="500"></canvas>

<script type="text/javascript" src="/js/bioinformatics/quadratic-bezier-curves.js"></script>

## Background

The general form of an nth order Bézier curve, with n+1 control points, can be
represented explicitly with the following summation:

<div>
$$
\sum_{i=0}^{n} \binom{n}{i} (1-t)^{n-i} t^i P_i
$$
</div>

The tick marks in the demo correspond to the segment lines of intersection
(related to the tangent line) at each point. However, the placement of the tick
marks along the curve is parameterized in terms of t, rather than arc-length.

It turns out reparameterizing the quadratic bezier curve in terms of arc-length
is non-trivial. There does exist a closed form solution of the reparameterized
curve, but it is quite unwieldy - and calculated by Mathematica, not any hand
derivation.

The normal way to reparameterize in terms of arc-length is to use a general
numerical method that calculates arc-length, and build a small table that maps t
onto that length. In your formula, you then divide your parameter t by the
length it maps to. This is a much neater solution than the complicated closed
form solution, since you cannot 'exactly' reparameterize any higher-order Bézier
curves. This does not preclude a generalized, accurate estimate of the mapping
between t and arc-length, the mapping approximation perhaps being in the form of
a Bézier curve itself.

I use the "table of arc-lengths" method here, which is rebuilt every time the
curve's control points are moved. The units of length are pixels.
