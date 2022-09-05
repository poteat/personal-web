---
title: "Towards a well-typed plugin architecture"
date: 2022-09-05T12:03:54-07:00
categories: [programming]
tags: [typescript, extensibility, type-system, architecture]
---

```ts
declare abstract class EnginePlugin<I = unknown, D = unknown> {
  createInterface?(ø: Record<string, unknown>): I
  getDependencies?(): D
}

type Defined<T> = T extends undefined ? never : T

type ExtractPlugins<T> = T extends Engine<infer PX> ? PX : never

type UnionToIntersection<U> = (
  U extends unknown ? (k: U) => void : never
) extends (k: infer I) => void
  ? I
  : never

type MergeInterfaces<
  E extends Engine,
  K extends keyof EnginePlugin,
> = UnionToIntersection<ReturnType<Defined<ExtractPlugins<E>[number][K]>>>

type Assume<T, U> = T extends U ? T : never

type GetDependencies<P extends EnginePlugin> = Assume<
  P extends EnginePlugin<unknown, infer D> ? D : never,
  EnginePlugin[]
>

type PluginDependencyErrorMessage =
  `Plugin is missing one or more dependencies.`

type EnforceDependencies<
  E extends Engine,
  P extends EnginePlugin,
> = GetDependencies<P>[number] extends ExtractPlugins<E>[number]
  ? P
  : PluginDependencyErrorMessage

declare class Engine<PX extends EnginePlugin[] = []> {
  registerPlugin<P extends EnginePlugin>(
    plugin: EnforceDependencies<this, P>,
  ): asserts this is Engine<[...PX, P]>

  createInterface(): MergeInterfaces<this, "createInterface">
}

interface DogInterface {
  bark(): void
}

declare const DogPlugin: {
  new (): {
    createInterface(ø: Record<string, unknown>): DogInterface
  }
  (ø: unknown): ø is DogInterface
}

interface CatInterface {
  meow(message: string): void
}

declare const CatPlugin: {
  new (): {
    super(): typeof CatPlugin
    createInterface(ø: Record<string, unknown>): CatInterface
  }
  (ø: unknown): ø is CatInterface
}

interface PantherInterface {
  panther: {
    roar(): void
  }
}

declare const PantherPlugin: {
  new (): {
    createInterface(ø: Record<string, unknown>): PantherInterface
  }
  getDependencies(): [typeof CatPlugin]
  (ø: unknown): ø is PantherInterface
}

declare const engine: Engine

engine.registerPlugin(new DogPlugin())
engine.registerPlugin(new CatPlugin())
engine.registerPlugin(new PantherPlugin())

const ø = engine.createInterface()

ø.bark()
ø.meow("hello")
ø.panther.roar()

ø.meow("meow")

if (DogPlugin(ø)) {
  ø.bark()
}

```

# Towards a well-typed plugin architecture

## Introduction

There are many reasons why one might want to develop a plugin architecture.
First and foremost amongst these is extensibility: the ability to add new
functionality to a system without having to modify the existing
codebase. This can be a very powerful tool, allowing developers to ship
functionality as and when it is ready, rather than being forced to wait for a
major release.

A well-designed plugin architecture can also promote code reuse. By encapsulating
functionality within a plugin, it can be easily reused in other projects.

However, designing a good plugin architecture is not a trivial task. There are
many issues to consider, such as how to manage dependencies between plugins, how
to ensure that plugins can communicate with each other, and how to handle
upgrades and downgrades.

In this article, we will explore one approach to designing a plugin architecture
using the TypeScript programming language. We will see how to use TypeScript's
static type-checking to enforce dependencies between plugins, and how to
generate type-safe APIs for communication between plugins.

## An abstract `EnginePlugin` definition

We will start by defining an abstract `EnginePlugin` class. This class will
serve as the base class for all plugins that we develop.

```typescript
abstract class EnginePlugin<I = unknown, D = unknown> {
  createInterface?(ø: Record<string, unknown>): I
  getDependencies?(): D
}
```

The `EnginePlugin` class defines two abstract methods, `createInterface` and
`getDependencies`. The `createInterface` method is responsible for creating an
instance of the plugin's interface. This instance will be used by the
application to access the functionality provided by the plugin.

The `getDependencies` method is responsible for returning an array of
dependencies that the plugin has on other plugins. These dependencies will be
used to ensure that the plugin is only loaded if all of its dependencies are
satisfied.

### Why ø ?

We are using ø as a variable identifier to denote the central 'composite interface' as
a result of total plugin registration. ø is convenient as it's readily accessible on OSX
keyboards [⌥+o] and is visually unique. Unicode identifiers can be controversial.

## Extending `EnginePlugin`

Now that we have defined the `EnginePlugin` class, we can start to develop
some concrete plugins. Let's start by developing a plugin that provides a
`DogInterface`. This interface will allow us to make a dog bark.

```typescript
interface DogInterface {
  bark(): void
}

const DogPlugin: {
  new (): {
    createInterface(ø: Record<string, unknown>): DogInterface
  }
  (ø: unknown): ø is DogInterface
}
```

Our `DogPlugin` is a simple JavaScript object that contains two properties.
The first is a constructor function that creates an instance of the plugin's
interface. The second is a function that allows us to check if an object is an
instance of the plugin's interface.

Now that we have developed our plugin, we can use it to create an instance of
the `DogInterface`.

```typescript
const dog = new DogPlugin().createInterface()

dog.bark() // "woof!"
```

## Managing plugin dependencies

Now that we have developed our first plugin, we can start to develop a second
plugin that depends on the first. Let's develop a plugin that provides a
`CatInterface`. This interface will allow us to make a cat meow.

```typescript
interface CatInterface {
  meow(message: string): void
}

const CatPlugin: {
  new (): {
    createInterface(ø: Record<string, unknown>): CatInterface
  }
  (ø: unknown): ø is CatInterface
}
```

Our `CatPlugin` is very similar to our `DogPlugin`. It is a simple JavaScript
object that contains a constructor function and a function for checking if an
object is an instance of the plugin's interface.

Now that we have developed our `CatPlugin`, we can use it to create an instance
of the `CatInterface`.

```typescript
const cat = new CatPlugin().createInterface()

cat.meow("meow!") // "meow!"
```

Now let's develop a third plugin that depends on `CatPlugin`. This plugin will provide
an interface for a panther.

```typescript
interface PantherInterface {
  panther: {
    roar(): void
  }
}

const PantherPlugin: {
  new (): {
    createInterface(ø: Record<string, unknown>): PantherInterface
  }
  getDependencies(): [typeof CatPlugin]
  (ø: unknown): ø is PantherInterface
}
```

Our `PantherPlugin` is similar to our other plugins, but it introduces a new
concept: plugin dependencies. The `PantherPlugin` declares a dependency on the
`CatPlugin` by returning an array containing the `CatPlugin` from its
`getDependencies` method.

This dependency will be used to ensure that the `PantherPlugin` is only loaded
if the `CatPlugin` is also loaded - otherwise, an error will be omitted if we register
`PantherPlugin` without first having registered `CatPlugin`.

Now that we have developed our `PantherPlugin`, we can use it to create an
instance of the `PantherInterface`.

```typescript
const panther = new PantherPlugin().createInterface()

panther.panther.roar() // "roar!"
```

## Defining an `Engine` class

Now that we have developed some plugins, we need a way to load them into our
application. We will do this by defining an `Engine` class.

```typescript
declare class Engine<PX extends EnginePlugin[] = []> {
  registerPlugin<P extends EnginePlugin>(
    plugin: EnforceDependencies<this, P>,
  ): asserts this is Engine<[...PX, P]>

  createInterface(): MergeInterfaces<this, "createInterface">
}
```

Our `Engine` class is a generic class that takes a type parameter `PX` which
represents the set of plugins that have been loaded into the engine. The
`registerPlugin` method is used to register a new plugin with the engine. The
`createInterface` method is used to create an instance of the engine's
interface. This instance will be used to access the functionality provided by
the plugins.

## Loading plugins into the `Engine`

Now that we have defined our `Engine` class, we can use it to load our
plugins.

```typescript
const engine = new Engine()

engine.registerPlugin(new DogPlugin())
engine.registerPlugin(new CatPlugin())
engine.registerPlugin(new PantherPlugin())
```

## Accessing functionality from the `Engine`

Now that we have loaded our plugins into the `Engine`, we can use the
`Engine` to access the functionality that they provide.

```typescript
const ø = engine.createInterface()

ø.bark()
ø.meow("hello")
ø.panther.roar()
```

## Conclusion

In this article, we have seen how to use the TypeScript programming language
to develop a well-typed plugin architecture. We have seen how to use
TypeScript's static type-checking to enforce dependencies between plugins, and
how to generate type-safe APIs for communication between plugins.

---

# Utility Types

In the definition of `Engine`, we have used a number of utility types that are
defined in the following section.

## `ExtractPlugins`

The `ExtractPlugins` utility type is used to extract the set of plugins from
an `Engine` instance.

```typescript
type ExtractPlugins<T> = T extends Engine<infer PX> ? PX : never
```

## `UnionToIntersection`

The `UnionToIntersection` utility type is used to convert a union type to an
intersection type.

```typescript
type UnionToIntersection<U> = (
  U extends unknown ? (k: U) => void : never
) extends (k: infer I) => void
  ? I
  : never
```

## `MergeInterfaces`

The `MergeInterfaces` utility type is used to merge the interfaces of a set of
plugins.

```typescript
type MergeInterfaces<
  E extends Engine,
  K extends keyof EnginePlugin,
> = UnionToIntersection<ReturnType<Defined<ExtractPlugins<E>[number][K]>>>
```

## `Defined`

The `Defined` utility type is used to remove `undefined` from a type.

```typescript
type Defined<T> = T extends undefined ? never : T
```

## `GetDependencies`

The `GetDependencies` utility type is used to extract the dependencies of a
plugin.

```typescript
type GetDependencies<P extends EnginePlugin> = Assume<
  P extends EnginePlugin<unknown, infer D> ? D : never,
  EnginePlugin[]
>
```

## `EnforceDependencies`

The `EnforceDependencies` utility type is used to ensure that a plugin's
dependencies are satisfied.

```typescript
type EnforceDependencies<
  E extends Engine,
  P extends EnginePlugin,
> = GetDependencies<P>[number] extends ExtractPlugins<E>[number]
  ? P
  : PluginDependencyErrorMessage
```

## `PluginDependencyErrorMessage`

The `PluginDependencyErrorMessage` type is used to provide a helpful error
message when a plugin's dependencies are not satisfied.

```typescript
type PluginDependencyErrorMessage =
  `Plugin is missing one or more dependencies.`
```
