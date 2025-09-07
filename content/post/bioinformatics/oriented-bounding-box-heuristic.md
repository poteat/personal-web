---
title: "Oriented Bounding-Box Heuristic"
date: 2019-01-25T20:35:20-05:00
categories: [bioinformatics]
tags: [javascript, demo, regression]
---

A fast O(n) heuristic for finding near-optimal oriented bounding boxes around point sets, using orthogonal linear regression to align rectangles with the natural orientation of the data.

<!--more-->

The 2-dimensional minimum-area oriented bounding box problem is as follows:
Given a set of coplanar points, how can we efficiently find the smallest
rectangle which encloses these points? Additionally, that rectangle can be
oriented at any angle with respect to the coordinate system.

One interesting estimate for the solution, which guarantees "pretty good"
results in O(n) time is a natural extension of orthogonal linear regression.
Specifically, we assume that the minimum rectangle is aligned to the orthogonal
"line of best fit" of the point set. The parameters for this fit can be found
in O(n) time.

This method appears to work when points who are not members of the convex-set do
not have much of an effect on the result. Specifically, when the non-convex-set
points are evenly distributed, the method generates acceptable boxes.

<canvas id="canvas" width="500" height="500"></canvas>

<script type="text/javascript" src="/js/bioinformatics/oriented-bounding-box-heuristic.js"></script>
