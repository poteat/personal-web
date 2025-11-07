---
title: "React + Jotai as a Modern MVC Architecture"
date: 2025-11-05T18:30:44-08:00
categories: [programming]
tags: [programming, frontend, architecture]
---

React is a library for building user interfaces in a declarative style. Jotai is
a complementary library for modeling state in a monadic, declarative style. When
these are used purposefully, what arises is a very sane MVC architecture built
with [boring technology](https://mcfunley.com/choose-boring-technology) [1].

MVC is a decades-old pattern to separate concerns in an application in three
primary buckets - to lay out succinctly:

- **View**: What it looks like
- **Controller**: What it does
- **Model**: What it is

I've laid out the above in order of 'View --> Controller --> Model' as I think
that ordering more clearly lays out the hierarchy in terms of cause-and-effect
arising from the user.

### What MVC isn't

MVC isn't a network boundary abstraction - it's a means of more generally
representing or architecting software. This article focuses on frontend
architecture, but MVC also works on the backend; that aspect isn't mutually
exclusive.

MVC isn't even really about classes or objects in my view - in contrast I would
characterize this particular instantiation of MVC as a particularly functional
and declarative one.

## Diagrammatic overview

- **View**: React components
- **Controller**: Jotai 'action' atoms
- **Model**: Jotai state

![mvc-diagram](/img/programming/react-jotai-mvc.png)

The above diagram illustrates the 'knows about' (flow of control, or 'import
flow') relationship between MVC (and optionally S), as well as the data flow.
Importantly, the data flow is reversed as compared to the order of knowledge re
each part of the system.

It's worth making explicit that 'flow of control' here _isn't really_ 'control
flow' - instead it's really module import relationships, or alternatively static
compile-time binding.

Re services, by "how it speaks" I predominantly mean "how it speaks to the
world", i.e. how we externally reify changes or learn about things outside of
it, 'it' meaning 'the software being architected'.

## Parts in detail

### 1. View

At the top, the user interacts with the view - in terms of JSX rendered down to
DOM, with corresponding interaction handlers (e.g. `onClick`, etc.), form
inputs, etc. When the model changes, components are automatically re-rendered.

On user interaction, the view invokes the controller. Notably, in React, we
don't wait for a return value from these actions; they are often asynchronous.
For a form, this might look like invoking a setter for an action atom with the
underlying form data.

Views 'know about' models in as far as they subscribe to them; however they
should delegate any updates to controllers - a controller will invoke domain
commands on one or more models.

### 2. Controller

Controllers translate user intent to one or more model commands. They are
ideally an orchestration layer. In Jotai, this takes the form of a write-only
'action' atom that predominantly reads/writes from/to other atoms and
encapsulates side-effects.

The particularly nice thing about using write-only atoms as a controller layer
is that it well-conforms to the Open/Closed principle: your implementation
becomes easy (open to) extension via composition, and closed to modification. At
least this is true compared to something like Redux, where you pretty much
constantly need to be modifying the implementation of your central event
reducers.

We are consistently using composition to enable abstraction and extension: React
components of course compose declaratively, while Jotai atoms compose
functionally.

### 3. Model

This view renders data from the _model_, i.e. base Jotai atoms which store data
presumably fetched and/or synchronized from some backend. These can either be
simple primitive, atomic atoms, or more complicated abstractions that perform
caching, staleness re-fetching, listen for / update when server-sent events are
received (e.g. WebSocket events), etc. These can be based on HTTP RESTful
clients, GraphQL-type APIs, etc - the idea of the model is agnostic to those
implementation concerns.

This 'thick model' idea somewhat diverges from contemporary common usage but
arguably better fits the original MVC vision [2].

In Jotai, this will include projection atoms that create filtered or transformed
read-only views, to optimize re-rendering and ensure logic remains declarative
and reactive.

### 4. The (optional, auxilliary) "Service layer"

MVC+S is a pretty common extension to the core MVC idea.

- **Service**: How it talks to the world

and in specific terms:

- **Service**: - Encapsulated TypeScript modules for external effects

Optionally, a service layer can be introduced, which exists below the model and
specifies details like network transports (typed http client, websockets etc.),
keeping these ideas outside of the model. Whether this is made explicit isn't an
important piece - it opens you up for dependency injection or other benefits
arising from a service-oriented architecture, if that's useful for your domain.
However, it's pretty tangential to MVC itself.

## Code sketch

To illustrate this idea concretely, let's play with a hyper-minimal example.

From a product perspective I'm thinking this: we're on a user profile page, and
we're displaying the user's name. We want the name to be editable inline, and
when focus changes, we want to persist that updated name against the backend.

### View

For the view, we're displaying the user's name and allowing edits. On a blur DOM
event (focus changed), we call our `renameUser` controller. We also subscribe to
a derived `userName` via normal reactive React / Jotai semantics.

```ts
/* view/UserNameInlineEditor.tsx */

function UserNameInlineEditor() {
  const userName = useAtomValue(userNameAtom);
  const renameUser = useSetAtom(renameUserActionAtom);
  const [draftName, setDraftName] = React.useState(userName);

  React.useEffect(() => setDraftName(userName), [userName]);

  return (
    <input
      value={draftName}
      onChange={(e) => setDraftName(e.target.value)}
      onBlur={() => renameUser(draftName)}
    />
  );
}
```

### Controller

We keep our controllers quite thin - they should ideally translate user intent
to one or more model domain-specific commands.

In many cases controllers would be more complex; it's not always a 1:1 mapping.

```ts
/* controller/renameUserActionAtom.ts */

export const renameUserActionAtom = atom(null, (_get, set, name: string) =>
  set(userAtom, { type: "rename", name })
);
```

### Model

This is your classic 'thick model', whereby the `userAtom` is in charge of
keeping itself up-to-date, optimistic semantics, rollbacks, etc. For a sketch I
wanted to go with something low-abstraction, but likely there would be a bit
more sugar here at least to e.g. more cleanly handle commands.

```ts
/* model/userIdAtom.ts */

const _userStateAtom = atom<{ id: string; name: string } | null>(null);

export const userAtom = atom(
  (get) => get(_userStateAtom),
  async (get, set, action: { type: "rename"; name: string }) => {
    const prev = get(_userStateAtom);
    if (!prev) return; // Not logged in; ignore

    switch (action.type) {
      case "rename": {
        const optimistic = { ...prev, name: action.name };
        set(_userStateAtom, optimistic); // optimistic self-update
        try {
          const saved = await api.updateUserName(prev.id, action.name);
          set(_userStateAtom, saved); // reconcile with server
        } catch {
          set(_userStateAtom, prev); // rollback on failure
        }
        return;
      }
    }
  }
);
```

## Final words

When used with purpose, I think React and Jotai together form a compelling way
to use MVC in a manner that prioritizes a declarative and monadic code
representation.

## Refs

<details>
<summary>[1]: re boring technology</summary>

> The essay "Choose Boring Technology" was written in 2015, and then perhaps
> rightly listed NodeJS as a non-boring, innovation-point spending technology. I
> would say NodeJS is quite boring now however, in a good way.

</details>

<details>
<summary>[2]: re bona-fide, thick models</summary>

> I espouse here a definition of models that's more faithful to the original
> idea from Smalltalk; you often might see a more modern corruption whereby the
> model is considered to be a 'thin' or 'dumb' data layer, which is updated by
> 'fat' controllers.
>
> Models as a 'big dumb bag of data' don't actually really follow the original
> spirit of MVC in my view. Instead, in a OOP sort of way, models encapsulate
> the details of keeping themselves consistent, in a valid state, etc.

</details>
