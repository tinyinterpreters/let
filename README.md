# LETPAR

LETPAR gives the multiple-binding `let` expressions from the [`multiple-bindings`](https://github.com/tinyinterpreters/let/tree/multiple-bindings) branch parallel binding semantics.

Every initializer is evaluated in the incoming environment. The new bindings become available together only when evaluating the body.

For example, the initial environment contains `x = 10`:

```txt
let
    x = 20
    y = x
in
y
```

The initializer for `y` sees the incoming `x = 10`, not its sibling binding `x = 20`, so the result is `10`.

Sibling bindings therefore cannot depend on one another:

```txt
let
    a = 5
    b = -(a, 1)
in
b
```

Because there is no `a` in the incoming environment, evaluating `b`'s initializer fails with an identifier-not-found error.

For a closer look, read [LETPAR: Parallel Binding Semantics for `let` Expressions](https://blog.tinyinterpreters.dev/posts/letpar/).

To try it, you'll need [Nix](https://zero-to-nix.com/start/install/) with flakes enabled.

```bash
nix develop
elm repl
```

Then:

```elm
import LET.Interpreter as I

I.run "let x = 20 y = x in y"
-- Ok (VNumber 10)

I.run "let a = 5 b = -(a, 1) in b"
-- Err (RuntimeError (IdentifierNotFound "a"))
```
