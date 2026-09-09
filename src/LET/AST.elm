module LET.AST exposing
    ( Binding(..)
    , Expr(..)
    , Id
    , Number
    , Program(..)
    )


type Program
    = Program Expr


type Expr
    = Const Number
    | Diff Expr Expr
    | Zero Expr
    | If Expr Expr Expr
    | Var Id
    | Let (List Binding) Expr


type Binding
    = Binding Id Expr


type alias Number =
    Int


type alias Id =
    String
