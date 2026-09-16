# LET

LET extends [VAR](https://github.com/tinyinterpreters/var) with `let` expressions:

```txt
let a = 5 in -(a, 3)
```

A `let` expression evaluates the bound expression first, then binds its resulting value to a name while evaluating the body:

```txt
let a = 5 in -(a, 3)
→ VNumber 2
```

The binding's scope is the body. This means an inner `let` can shadow an outer binding:

```txt
let a = 5 in -(let a = 3 in a, a)
→ VNumber -2
```

The inner body sees `a = 3`, while the second operand still sees the outer `a = 5`.

For a closer look, read [LET: Introducing Local Bindings and Scope](https://blog.tinyinterpreters.dev/posts/let/).

To try it, you'll need [Nix](https://zero-to-nix.com/start/install/) with flakes enabled.

```bash
nix develop
elm repl
```

Then:

```elm
import LET.Interpreter as I

I.run "let a = 5 in -(a, 3)"
-- Ok (VNumber 2)

I.run "let a = 5 in -(let a = 3 in a, a)"
-- Ok (VNumber -2)
```
