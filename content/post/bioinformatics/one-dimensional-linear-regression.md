---
title: "One-Dimensional Linear Regression"
date: 2019-01-25T18:27:02-05:00
categories: [bioinformatics]
tags: [javascript, demo, regression]
---

The simple linear regression algorithm is a closed-form solution to a
least-squared distance minimization problem. Here is demonstrated the
one-dimensional case of simple linear regression.

<div>
$$
\min_{\alpha,\beta} \sum_{i=1}^{n} (y_i - \alpha - \beta x_i)^2
$$
</div>

_Click and drag_ the black points to affect the regression. _Double click_ to
add or remove points. The blue point in the center represents the geometric
average, through which the fit always passes through.

<canvas id="canvas" width="500" height="500"></canvas>

<script type="text/javascript" src="/js/bioinformatics/one-dimensional-linear-regression.js"></script>

In this problem, the least-squared distance considered includes only the
vertical component. This is what makes the problem "one-dimensional", even
though the visualization of the problem is two-dimensional.
