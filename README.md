# LETSEQ

LETSEQ gives the multiple-binding `let` expressions from the [`multiple-bindings`](https://github.com/tinyinterpreters/let/tree/multiple-bindings) branch sequential binding semantics.

Bindings are evaluated in source order. After each initializer is evaluated, its binding becomes available to the initializers that follow it.

For example:

```txt
let
    x = 20
    y = x
in
y
```

The initializer for `y` can see the earlier binding `x = 20`, so the result is `20`.

Bindings can build on one another:

```txt
let
    a = 5
    b = -(a, 1)
    c = -(b, 1)
in
c
```

This evaluates to `3`.

Source order therefore matters. A binding cannot refer to one that appears later:

```txt
let
    a = b
    b = 1
in
a
```

When `a` is evaluated, `b` has not been introduced yet, so evaluation fails with an identifier-not-found error.

For a closer look, read [LETSEQ: Sequential Binding Semantics for `let` Expressions](https://blog.tinyinterpreters.dev/posts/letseq/).

To try it, you'll need [Nix](https://zero-to-nix.com/start/install/) with flakes enabled.

```bash
nix develop
elm repl
```

Then:

```elm
import LET.Interpreter as I

I.run "let x = 20 y = x in y"
-- Ok (VNumber 20)

I.run "let a = 5 b = -(a, 1) c = -(b, 1) in c"
-- Ok (VNumber 3)

I.run "let a = b b = 1 in a"
-- Err (RuntimeError (IdentifierNotFound "b"))
```
