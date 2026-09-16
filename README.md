# LET — Multiple Bindings

This branch extends [LET](https://github.com/tinyinterpreters/let) so a single `let` expression can contain multiple bindings:

```txt
let
    a = 5
    b = 3
in
-(a, b)
```

The grammar, AST, and parser support these expressions, but their evaluation semantics are deliberately left undefined.

Multiple bindings introduce a question that single-binding `let` never had to answer:

```txt
let
    x = 20
    y = x
in
y
```

What does the `x` in `y = x` refer to: the sibling binding `x = 20`, or an `x` from the surrounding environment?

For a closer look at the syntax and the different meanings we could give it, read [Multiple-Binding `let` Expressions: Syntax Before Semantics](https://blog.tinyinterpreters.dev/posts/multiple-binding-let-expressions/).

To explore the parser, you'll need [Nix](https://zero-to-nix.com/start/install/) with flakes enabled.

```bash
nix develop
elm repl
```

Then:

```elm
import LET.Parser as P

P.parse """
    let
        a = 5
        b = 3
    in
    -(a, b)
"""
-- Ok (Program (Let [Binding "a" (Const 5),Binding "b" (Const 3)] (Diff (Var "a") (Var "b"))))
```
