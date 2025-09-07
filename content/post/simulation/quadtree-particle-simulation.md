---
title: "Quadtree Particle Simulation"
date: 2019-01-28T13:59:19-05:00
categories: [simulation]
tags: [javascript, demo, physics]
---

A JavaScript particle physics simulation using a quadtree spatial data structure to efficiently compute inter-particle forces, optimizing from O(n²) to near-linear complexity.

<!--more-->

A small particle simulation was written in JS, utilizing a simplified (constant
depth) quadtree structure. The model includes forces between nearby particles,
so rather than invoke a O(n^2) operation to compute the net force for each
particle, a quadtree is used so each particle may efficiently access its
neighbors.

The forces used are tuned to provide some amount of clustering, but also to
provide global homogeneity to prevent too many particles appearing in one
quadtree section (which would decrease cpu-time efficiency).

<canvas id="canvas" width="500" height="500"></canvas>

<script type="text/javascript" src="/js/simulation/quadtree-particle-simulation.js"></script>
