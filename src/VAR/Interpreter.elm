module VAR.Interpreter exposing
    ( Error(..)
    , RuntimeError(..)
    , Type(..)
    , Value(..)
    , run
    )

import VAR.AST as AST exposing (..)
import VAR.Env as Env
import VAR.Parser as P


type Value
    = VNumber Number
    | VBool Bool


type Error
    = SyntaxError P.Error
    | RuntimeError RuntimeError


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
