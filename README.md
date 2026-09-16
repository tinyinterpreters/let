# LETDEP

LETDEP gives the multiple-binding `let` expressions from the [`multiple-bindings`](https://github.com/tinyinterpreters/let/tree/multiple-bindings) branch dependency-ordered binding semantics.

Instead of using source order to decide when bindings become available, LETDEP looks at the dependencies between their initializers and finds an order in which they can be evaluated.

That means forward references are allowed:

```txt
let
    a = b
    b = 1
in
a
```

Even though `b` appears after `a`, LETDEP sees that `a` depends on `b`, evaluates `b` first, and produces `1`.

The same idea works for longer dependency chains:

```txt
let
    a = 5
    b = -(a, 1)
    c = -(b, 1)
in
c
```

This evaluates to `3`, regardless of whether those bindings were originally written in dependency order.

Some binding groups have no valid evaluation order:

```txt
let
    a = b
    b = a
in
a
```

Here `a` depends on `b` and `b` depends on `a`, so LETDEP reports a cyclic-bindings static error instead of evaluating the program.

For a closer look, read [LETDEP: Dependency-Ordered Binding Semantics for `let` Expressions](https://blog.tinyinterpreters.dev/posts/letdep/).

To try it, you'll need [Nix](https://zero-to-nix.com/start/install/) with flakes enabled.

```bash
nix develop
elm repl
```

Then:

```elm
import LET.Interpreter as I

I.run "let a = b b = 1 in a"
-- Ok (VNumber 1)

I.run "let a = 5 b = -(a, 1) c = -(b, 1) in c"
-- Ok (VNumber 3)

I.run "let a = b b = a in a"
-- Err (StaticError CyclicBindings)
```
