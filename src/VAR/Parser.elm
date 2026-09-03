module VAR.Parser exposing (Error, parse)

import Parser as P exposing ((|.), (|=), Parser)
import VAR.AST as AST exposing (..)
import VAR.Lexer as L


type alias Error =
    List P.DeadEnd


parse : String -> Result Error AST.Program
parse =
    P.run program


program : Parser AST.Program
program =
    P.succeed Program
        |. L.spaces
        |= expr
        |. P.end


expr : Parser Expr
expr =
    P.oneOf
        [ constExpr
        , diffExpr
        , zeroExpr
        , ifExpr
        , varExpr
        ]


constExpr : Parser Expr
constExpr =
    P.map Const number


number : Parser Number
number =
    L.digits


diffExpr : Parser Expr
diffExpr =
    P.succeed Diff
        |. L.symbol "-"
        |. L.symbol "("
        |= P.lazy (\_ -> expr)
        |. L.symbol ","
        |= P.lazy (\_ -> expr)
        |. L.symbol ")"


zeroExpr : Parser Expr
zeroExpr =
    P.succeed Zero
        |. L.keyword "zero?"
        |. L.symbol "("
        |= P.lazy (\_ -> expr)
        |. L.symbol ")"


ifExpr : Parser Expr
ifExpr =
    P.succeed If
        |. L.keyword "if"
        |= P.lazy (\_ -> expr)
        |. L.keyword "then"
        |= P.lazy (\_ -> expr)
        |. L.keyword "else"
        |= P.lazy (\_ -> expr)


varExpr : Parser Expr
varExpr =
    P.map Var (L.id keywords)


keywords : List String
keywords =
    --
    -- Remember to update this list of keywords anytime you
    -- introduce new reserved words into the language.
    --
    -- Since zero? is not a valid identifier we don't need
    -- to include it in this list.
    --
    [ "else"
    , "if"
    , "then"
    ]
