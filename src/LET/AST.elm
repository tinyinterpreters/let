module LET.AST exposing
    ( Binding(..)
    , Expr(..)
    , Id
    , Number
    , Program(..)
    , freeVariables
    )

import Set exposing (Set)


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


freeVariables : Expr -> Set Id
freeVariables expr =
    case expr of
        Const _ ->
            Set.empty

        Diff a b ->
            Set.union (freeVariables a) (freeVariables b)

        Zero a ->
            freeVariables a

        If condition consequent alternative ->
            Set.union
                (freeVariables condition)
                (Set.union
                    (freeVariables consequent)
                    (freeVariables alternative)
                )

        Var name ->
            Set.singleton name

        Let bindings body ->
            let
                ( boundNames, initializerFreeVariables ) =
                    analyzeBindings bindings
            in
            Set.diff
                (Set.union initializerFreeVariables (freeVariables body))
                boundNames


analyzeBindings : List Binding -> ( Set Id, Set Id )
analyzeBindings bindings =
    case bindings of
        [] ->
            ( Set.empty, Set.empty )

        (Binding name bound) :: restOfBindings ->
            let
                ( boundNames, initializerFreeVariables ) =
                    analyzeBindings restOfBindings
            in
            ( Set.insert name boundNames
            , Set.union (freeVariables bound) initializerFreeVariables
            )
