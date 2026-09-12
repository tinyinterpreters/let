module LET.Interpreter exposing
    ( Error(..)
    , RuntimeError(..)
    , StaticError(..)
    , Type(..)
    , Value(..)
    , resolveDependencies
    , run
    )

import LET.AST as AST exposing (..)
import LET.Env as Env
import LET.Parser as P


type Value
    = VNumber Number
    | VBool Bool


type Error
    = SyntaxError P.Error
    | StaticError StaticError
    | RuntimeError RuntimeError


type StaticError
    = DuplicateBinding Id
    | CyclicBindings


type RuntimeError
    = TypeError
        { expected : List Type
        , actual : List Type
        }
    | IdentifierNotFound Id


type Type
    = TNumber
    | TBool


run : String -> Result Error Value
run input =
    case P.parse input of
        Ok program ->
            runProgram program
                |> Result.mapError RuntimeError

        Err err ->
            Err <| SyntaxError err


runProgram : AST.Program -> Result RuntimeError Value
runProgram (Program expr) =
    runExpr expr initEnv


type alias Env =
    Env.Env Id Value


initEnv : Env
initEnv =
    Env.empty
        |> Env.extend "x" (VNumber 10)
        |> Env.extend "v" (VNumber 5)
        |> Env.extend "i" (VNumber 1)


runExpr : Expr -> Env -> Result RuntimeError Value
runExpr expr env =
    case expr of
        Const n ->
            Ok <| VNumber n

        Diff a b ->
            runExpr a env
                |> Result.andThen
                    (\va ->
                        runExpr b env
                            |> Result.andThen
                                (\vb ->
                                    evalDiff va vb
                                )
                    )

        Zero a ->
            runExpr a env
                |> Result.andThen
                    (\va ->
                        evalZero va
                    )

        If condition consequent alternative ->
            runExpr condition env
                |> Result.andThen
                    (\vCondition ->
                        evalIf vCondition consequent alternative env
                    )

        Var name ->
            case Env.lookup name env of
                Just value ->
                    Ok value

                Nothing ->
                    Err <| IdentifierNotFound name

        Let bindings body ->
            evalBindings bindings env
                |> Result.andThen
                    (\bodyEnv ->
                        runExpr body bodyEnv
                    )


evalBindings : List Binding -> Env -> Result RuntimeError Env
evalBindings bindings bodyEnv =
    case bindings of
        [] ->
            Ok bodyEnv

        (Binding name bound) :: restOfBindings ->
            runExpr bound bodyEnv
                |> Result.andThen
                    (\vBound ->
                        evalBindings
                            restOfBindings
                            (Env.extend name vBound bodyEnv)
                    )


evalDiff : Value -> Value -> Result RuntimeError Value
evalDiff va vb =
    case ( va, vb ) of
        ( VNumber a, VNumber b ) ->
            Ok <| VNumber <| a - b

        _ ->
            Err <|
                TypeError
                    { expected = [ TNumber, TNumber ]
                    , actual = [ typeOf va, typeOf vb ]
                    }


evalZero : Value -> Result RuntimeError Value
evalZero va =
    case va of
        VNumber a ->
            Ok <| VBool <| a == 0

        _ ->
            Err <|
                TypeError
                    { expected = [ TNumber ]
                    , actual = [ typeOf va ]
                    }


evalIf : Value -> Expr -> Expr -> Env -> Result RuntimeError Value
evalIf vCondition consequent alternative env =
    case vCondition of
        VBool True ->
            runExpr consequent env

        VBool False ->
            runExpr alternative env

        _ ->
            Err <|
                TypeError
                    { expected = [ TBool ]
                    , actual = [ typeOf vCondition ]
                    }


typeOf : Value -> Type
typeOf v =
    case v of
        VNumber _ ->
            TNumber

        VBool _ ->
            TBool



-- STATIC ANALYSIS


resolveDependencies : AST.Program -> Result StaticError AST.Program
resolveDependencies (Program expr) =
    expr
        |> resolveDependenciesOfExpr
        |> Result.map Program


resolveDependenciesOfExpr : Expr -> Result StaticError Expr
resolveDependenciesOfExpr expr =
    case expr of
        Let bindings body ->
            sort bindings
                |> Result.andThen
                    (\dependencyOrderedBindings ->
                        resolveDependenciesOfInitializers dependencyOrderedBindings
                            |> Result.map
                                (\resolvedBindings ->
                                    Let resolvedBindings body
                                )
                    )

        _ ->
            Ok expr


sort : List Binding -> Result StaticError (List Binding)
sort =
    Debug.todo "Implement sort"


resolveDependenciesOfInitializers : List Binding -> Result StaticError (List Binding)
resolveDependenciesOfInitializers =
    traverse
        (\(Binding name initializer) ->
            resolveDependenciesOfExpr initializer
                |> Result.map (Binding name)
        )


traverse : (a -> Result e b) -> List a -> Result e (List b)
traverse f xs =
    case xs of
        [] ->
            Ok []

        x :: restXs ->
            f x
                |> Result.andThen
                    (\y ->
                        Result.map ((::) y) (traverse f restXs)
                    )
