module Test.LET.AST exposing (suite)

import LET.AST as AST exposing (Program(..))
import LET.Parser as P
import Set
import Test exposing (Test, describe)
import Test.Lib exposing (testValue)


suite : Test
suite =
    describe "LET.AST"
        [ [ -- Constants and variables
            ( "123", [] )
          , ( "x", [ "x" ] )

          -- Difference expressions
          , ( "-(1, 2)", [] )
          , ( "-(x, 2)", [ "x" ] )
          , ( "-(1, y)", [ "y" ] )
          , ( "-(x, y)", [ "x", "y" ] )
          , ( "-(x, x)", [ "x" ] )

          -- Is it zero?
          , ( "zero?(0)", [] )
          , ( "zero?(x)", [ "x" ] )
          , ( "zero?(-(x, y))", [ "x", "y" ] )

          -- Conditionals
          , ( "if zero?(0) then 1 else 2", [] )
          , ( "if condition then 1 else 2", [ "condition" ] )
          , ( "if zero?(0) then yes else no", [ "yes", "no" ] )
          , ( "if condition then yes else no"
            , [ "condition", "yes", "no" ]
            )
          , ( "if x then x else x", [ "x" ] )

          -- Let expressions
          , ( "let x = 1 in x", [] )
          , ( "let x = 1 in y", [ "y" ] )
          , ( "let x = 1 in -(x, y)", [ "y" ] )

          -- Binding names are bound throughout the binding group
          , ( "let x = x in x", [] )
          , ( "let x = 1 y = x in y", [] )
          , ( "let x = y y = 1 in x", [] )
          , ( "let x = y y = x in x", [] )
          , ( "let a = b b = c c = a in a", [] )

          -- Free variables in initializer expressions
          , ( "let x = outside in x", [ "outside" ] )
          , ( "let x = a y = -(x, b) in -(y, c)"
            , [ "a", "b", "c" ]
            )
          , ( "let x = y y = -(z, 1) in x", [ "z" ] )

          -- Nested let expressions
          , ( "let x = 1 in let y = x in y", [] )
          , ( "let x = outside in let y = x in y"
            , [ "outside" ]
            )
          , ( "let x = y in let y = 1 in x", [ "y" ] )
          , ( "let x = 1 in -(let y = 2 in y, y)", [ "y" ] )

          -- Shadowing
          , ( "let x = 1 in let x = 2 in x", [] )
          , ( "let x = a in let x = b in -(x, c)"
            , [ "a", "b", "c" ]
            )

          -- A name can be bound in one subtree and free in another
          , ( "-(let x = 1 in x, x)", [ "x" ] )

          -- Deep expression using every expression form
          , ( """
              let
                  x = if zero?(condition) then -(y, 1) else z
                  y =
                      let
                          z = x
                      in
                      -(z, outside)
              in
              if zero?(x) then y else result
              """
            , [ "condition", "outside", "result", "z" ]
            )

          -- Tangled LETDEP-style dependencies
          , ( """
              let
                  result = if ready then -(a, b) else fallback
                  a = if zero?(d) then c else -(c, d)
                  ready = zero?(-(g, e))
                  b = if zero?(-(f, 1)) then -(e, f) else e
                  c = -(g, h)
                  d = -(h, h)
                  e = g
                  f = 1
                  h = 2
                  g = 10
              in
              result
              """
            , [ "fallback" ]
            )

          -- Cyclic dependencies do not make variables free
          , ( """
              let
                  a = -(b, 1)
                  b = if zero?(c) then 10 else c
                  c = -(d, 1)
                  d = a
              in
              a
              """
            , []
            )
          ]
            |> List.map (Tuple.mapSecond (Just << Set.fromList))
            |> List.map
                (testValue
                    (\input ->
                        case P.parse input of
                            Ok (Program expr) ->
                                Ok (AST.freeVariables expr)

                            Err err ->
                                Err err
                    )
                )
            |> describe "freeVariables"
        ]
