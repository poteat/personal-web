---
title: "Self Modifying Type Predicates in Typescript"
date: 2020-05-03T19:41:57-07:00
categories: [typescript]
tags: [typescript, programming, type system, design patterns]
---

Typescript's type system is uniquely powerful among mainstream programming languages, approximating the expressive power of Haskell or Idris, while also remaining flexible enough for production applications.

Type predicates are a useful tool in building a well-typed software framework. Essentially, they allow you to "simulate" [dependents types](https://en.wikipedia.org/wiki/Dependent_type), a powerful type feature present in Idris.

Further explanation on type predicates can be found [here](https://www.typescriptlang.org/docs/handbook/advanced-types.html#using-type-predicates).

The premise of this article is a usage of type predicates I haven't seen discussed online, and thus an application I might consider "advanced" or at least somewhat obscure.

Essentially, in the context of an `interface` or `class`, you may apply a type predicate which applies additional type constraints on `this`.  To motivate the example, I'll invoke the common `Shape` class hierarchy, and try to avoid the corresponding quagmires with the Liskov substitution principle.

First, we will introduce the type `ShapeTypes`, which will be a mapping from the type `'circle' | 'rectangle'` to `Circle | Rectangle`.  Basically, this type converts a string type into a concrete `Shape` type.

Usually, every individual type would be in separate files.

```ts
// ShapeTypes.ts
type ShapeTypes = {
  circle: Circle;
  rectangle: Rectangle;
};
```

Next, we will define what it means exactly to be a `Shape` in this model.  The magic here is the `is` abstract, generic function.

```ts
// Shape.ts
abstract class Shape {
  public abstract get area(): number;
  public abstract get perimeter(): number;
  public abstract is<ShapeKey extends keyof ShapeTypes>(
    shapeType: ShapeKey
  ): this is ShapeTypes[ShapeKey];
}
```

Let's break down `Shape`, line-by-line:

2. The function declaration, specifying the class is `abstract` and therefore may possess abstract properties, and cannot be instantiated.
  * Instead of specifying `Shape` as an `abstract class`, this could be equivalently represented as an `interface`. However, the `abstract class` form is slightlymore extensible as we may more strictly specify what a `Shape` is, e.g. that it must possess a particular private property.

3. We specify that there must exist an accessible `area` property, and we _suggest_ but not require that the `get` syntax is used.

4. We specify that there must exist an accessible `perimeter` property.

5. This line declares that `is` is a generic member function which takes, as an type parameter, a type which `extends keyof ShapeTypes`, which automatically narrows to `'circle' | 'rectangle'`.  That means the type parameter will be either `'circle'` or `'rectangle'`.

6. The `is` function additionally takes in a value parameter `shapeType` with a type equal to the above type parameter. This means that if the call-site code passes in a literal string, the `ShapeType` type parameter will be implicitly narrowed to the corresponding literal string type of `shapeType`.

7. This line defines that the "native return type" of `is` is a boolean, and that additionally we are declaring the constraint that if `is` returns true, that `this` does extend type `ShapeTypes[ShapeKey]`, which resolves to either `Circle` or `Rectangle`.

In the end, `is` becomes a type-narrowing function which we can very easily use in our client code.  First though, we have a few more files to define.

```ts
// Circle.ts
class Circle extends Shape {
  public constructor(private _radius: number) {
    super();
  }

  public get area() {
    return Math.PI * this._radius ** 2;
  }

  public get perimeter() {
    return 2 * Math.PI * this._radius;
  }

  public get radius() {
    return this._radius;
  }

  public is<ShapeKey extends keyof ShapeTypes>(shapeType: ShapeKey) {
    return shapeType === "circle";
  }
}
```

The definition of `Circle` is pretty straight-forward: various functions encoding geometric primitives.  However, as part of the contract between `Shape` and any types which implement it, the `is` function must exist. So, we define it and specify that the parameter must be equal to `'circle'`.  Note that we provide additional read-only user-facing properties such as `radius`.

We then have `Rectangle`, along similar lines:

```ts
// Rectangle.ts
class Rectangle extends Shape {
  public constructor(private _width: number, private _height: number) {
    super();
  }

  public get area() {
    return this._width * this._height;
  }

  public get perimeter() {
    return 2 * (this._width + this._height);
  }

  public get height() {
    return this._height;
  }

  public get width() {
    return this._width;
  }

  public is<ShapeKey extends keyof ShapeTypes>(shapeType: ShapeKey) {
    return shapeType === "rectangle";
  }
}
```

We now have enough context to motivate the problem properly.  Let's say we have a function which somehow acts upon objects of type `Shape`.  In general, this could be for rendering, additional geometric computation, serialization, etc.  One relevant application would be a logging utility, `logShapeData`.

`logShapeData` takes in a `Shape`, but its behavior depends on internal properties.  This is the quintessential application for type predicates.

```ts
// logShapeData.ts
function logShapeData(shape: Shape) {
  console.log(`P: ${shape.perimeter}, A: ${shape.area}`);

  if (shape.is("circle")) {
    console.log(`  R: ${shape.radius}`);
  } else if (shape.is("rectangle")) {
    console.log(`  W: ${shape.width}, H: ${shape.height}`);
  }
}
```

In this form, the compiler knows that on line 128, shape is definitely of `Circle` type, because of the type predicate. We have implemented the ability to check, at run-time, whether or not a particular object is of a type we specify.  Additionally, through the use of generics and type predicates, we have extended that check to compile-time as well.

## Final Notes

For this simple example, a similar functionality can be achieved using the `instanceof` operator. However, this approach has limitations in that it requires leaf types to specifically be implemented as classes, while the type generic approach works just as well for a pure functional paradigm.

As well, using self-modifying type predicates is applicable beyond the problem of determining whether an object is of a certain type or not.

## Technical Addendum

One behavior of type predicates in general is that they are only capable of widening types, not narrowing them.  How they seem to work is, if `x` is originally of type `X`, and you specify `x is Y`, x becomes `X & Y` in the clause.  In other words, type predicates apply a top-level intersection to the variable according to its predicate type.