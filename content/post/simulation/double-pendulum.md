---
title: "Double Pendulum"
date: 2019-01-25T20:58:30-05:00
categories: [simulation]
tags: [javascript, demo, physics]
---

An interactive JavaScript simulation demonstrating the chaotic behavior of a double pendulum system, showcasing how small changes in initial conditions lead to dramatically different outcomes.

<!--more-->

This is a simulation of 2 bobs, connected by massless, perfectly rigid rods to a
central pivot under the force of uniform gravity. In addition to being the
motivating example for chaotic systems (in addition to the Lorenz system, its
fluid mechanics counterpart), the double pendulum represents some interesting
challenges.

<canvas id="canvas" width="500" height="500" style="position: absolute; margin-bottom: 0"></canvas>
<canvas id="tracer" width="500" height="500" style="margin-bottom: 0"></canvas>

<script type="text/javascript" src="/js/simulation/double-pendulum.js"></script>

<div id="controls">
  <input type="checkbox" id="circlebounds" onclick="circlebounds = document.getElementById('circlebounds').checked"> Draw circle bounds
  <input type="checkbox" id="cherrytracer" onclick="cherrytracer = document.getElementById('cherrytracer').checked"> Draw cherry tracer
  <input type="checkbox" id="connections" checked="true" onclick="connections = document.getElementById('connections').checked"> Draw connections
  <input type="checkbox" id="paused" onclick="paused = document.getElementById('paused').checked"> Pause
  <br>
  <button type="button" onclick="ctx_tracer.clearRect(0, 0, cvs_tracer.width, cvs_tracer.height);">Clear cherry tracer</button><br>
  Simulation parameters:<br>
  <input type="number" id="ang1" value="90"> Angle 1<br>
  <input type="number" id="ang2" value="180"> Angle 2<br>
  <input type="number" id="vang1" value="0"> Radial Velocity 1<br>
  <input type="number" id="vang2" value="0"> Radial Velocity 2<br>
  <input type="number" id="L1" value="10"> Length 1<br>
  <input type="number" id="L2" value="10"> Length 2<br>
  <input type="number" id="M1" value="1"> Mass 1<br>
  <input type="number" id="M2" value="1"> Mass 2<br>
  <button type="button" onclick="reinitialize();">Begin new simulation</button><br>
  Advanced options:<br>
  <input type="number" id="g" value="98.0"> Gravity<br>
  <input type="number" id ="fps_in" value="60"> Frames per second<br>
  <input type="number" id ="steps" value="10"> Steps per frame<br>
</div>

<div id="fps"></div>
<br>
One challenge is that when end mass is much larger than central mass, the
problem becomes stiff, and consequently the step-size must decrease quite a bit.
Thus a RK8 numerical integrator called [Verner's
Method](http://www.mymathlib.com/diffeq/runge-kutta/runge_kutta_verner.html) is 
used, which was manually ported from C to Javascript.

The system is modeled directly from the equations of motion, which were derived
using Mathematica (via the Euler-Lagrange formula).
