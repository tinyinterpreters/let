module Test.LET.Interpreter exposing (suite)

import Expect
import LET.Interpreter as I exposing (Value(..))
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "LET.Interpreter"
        [ describe "run" <|
            List.map (testRun I.run)
                -- Constant expressions
                [ ( "123", SucceedsWith (VNumber 123) )
                , ( "123 ", SucceedsWith (VNumber 123) )
                , ( "123  ", SucceedsWith (VNumber 123) )
                , ( " 123", SucceedsWith (VNumber 123) )
                , ( "  123", SucceedsWith (VNumber 123) )
                , ( "123abc", SyntaxError )

                -- Difference expressions
                , ( "-(456,123)", SucceedsWith (VNumber 333) )
                , ( "-(456, 123)", SucceedsWith (VNumber 333) )
                , ( "- ( 2, -( 4, 3 ) )", SucceedsWith (VNumber 1) )
                , ( """
                    -(
                        -(5 , 3),
                        -(0 , 1)
                    )
                    """
                  , SucceedsWith (VNumber 3)
                  )
                , ( "-(zero?(0), 1)"
                  , RuntimeError <|
                        I.TypeError
                            { expected = [ I.TNumber, I.TNumber ]
                            , actual = [ I.TBool, I.TNumber ]
                            }
                  )
                , ( "-(0, zero?(1))"
                  , RuntimeError <|
                        I.TypeError
                            { expected = [ I.TNumber, I.TNumber ]
                            , actual = [ I.TNumber, I.TBool ]
                            }
                  )
                , ( "-(zero?(0), zero?(1))"
                  , RuntimeError <|
                        I.TypeError
                            { expected = [ I.TNumber, I.TNumber ]
                            , actual = [ I.TBool, I.TBool ]
                            }
                  )

                -- Is it zero?
                , ( "zero?(0)", SucceedsWith (VBool True) )
                , ( "zero?( 0 ) ", SucceedsWith (VBool True) )
                , ( """
                    zero?(
                        -( 0
                         , 1
                         )
                    )
                    """
                  , SucceedsWith (VBool False)
                  )
                , ( "zero?(zero?(0))"
                  , RuntimeError <|
                        I.TypeError
                            { expected = [ I.TNumber ]
                            , actual = [ I.TBool ]
                            }
                  )

                -- Conditionals
                , ( "if zero?(0) then 2 else 3", SucceedsWith (VNumber 2) )

                --- Liberal whitespace
                , ( """
                    if zero? ( 1 ) then
                        2

                    else
                        3
                    """
                  , SucceedsWith (VNumber 3)
                  )

                --- Nested conditionals
                , ( """
                    if zero?(0) then
                        if zero?(1) then 2 else 4
                    else
                        if zero?(3) then 5 else 7
                    """
                  , SucceedsWith (VNumber 4)
                  )

                --- A non-Boolean condition
                , ( "if 0 then 2 else 3"
                  , RuntimeError <|
                        I.TypeError
                            { expected = [ I.TBool ]
                            , actual = [ I.TNumber ]
                            }
                  )

                --- The consequent would evaluate to a number
                --- The alternative would evaluate to a Boolean
                , ( "if zero?(0) then 2 else zero?(3)", SucceedsWith (VNumber 2) )

                --- Verify that the unselected else branch is not evaluated
                , ( "if zero?(0) then 2 else -(zero?(0), 1)", SucceedsWith (VNumber 2) )

                --- Verify that the unselected then branch is not evaluated
                , ( "if zero?(1) then -(zero?(0), 1) else 3", SucceedsWith (VNumber 3) )

                -- Variables
                , ( "x", SucceedsWith (VNumber 10) )
                , ( "if zero?(-(5, v)) then i else v", SucceedsWith (VNumber 1) )
                , ( "y", RuntimeError <| I.IdentifierNotFound "y" )

                -- Let expressions
                , ( "let a = 5 in a"
                  , SucceedsWith (VNumber 5)
                  )
                , ( "let a = 5 in -(a, 3)"
                  , SucceedsWith (VNumber 2)
                  )

                --- Binding the results of expressions
                , ( "let a = -(5, 3) in zero?(a)"
                  , SucceedsWith (VBool False)
                  )
                , ( "let a = zero?(0) in if a then 2 else 3"
                  , SucceedsWith (VNumber 2)
                  )

                --- Nested let expressions
                , ( "let a = 5 in let b = 3 in -(a, b)"
                  , SucceedsWith (VNumber 2)
                  )
                , ( "let a = 5 in let b = -(a, 2) in -(a, b)"
                  , SucceedsWith (VNumber 2)
                  )
                , ( """
                    let x = 33
                    in let y = 22
                       in if zero?(-(x, 11)) then -(y, 2) else -(y, 4)
                    """
                  , SucceedsWith (VNumber 18)
                  )

                --- Shadowing
                , ( "let a = 5 in let a = 3 in a"
                  , SucceedsWith (VNumber 3)
                  )

                --- The outer binding remains available after evaluating the inner let
                , ( "let a = 5 in -(let a = 3 in a, a)"
                  , SucceedsWith (VNumber -2)
                  )
                , ( """
                    let z = 5 in
                      let x = 3 in
                        let y = -(x, 1) in
                          let x = 4 in -(z, -(x, y))
                    """
                  , SucceedsWith (VNumber 3)
                  )

                --- Bound expressions use the surrounding environment
                , ( """
                    let x = 7 in
                      let y = 2 in
                        let y = let x = -(x, 1) in -(x, y) in
                          -(-(x, 8), y)
                    """
                  , SucceedsWith (VNumber -5)
                  )

                --- Errors while evaluating the bound expression
                , ( "let a = zero?(zero?(0)) in a"
                  , RuntimeError <|
                        I.TypeError
                            { expected = [ I.TNumber ]
                            , actual = [ I.TBool ]
                            }
                  )
                , ( "let a = missing in a"
                  , RuntimeError <| I.IdentifierNotFound "missing"
                  )

                --- Errors while evaluating the body
                , ( "let a = zero?(0) in -(a, 1)"
                  , RuntimeError <|
                        I.TypeError
                            { expected = [ I.TNumber, I.TNumber ]
                            , actual = [ I.TBool, I.TNumber ]
                            }
                  )
                , ( "let a = 5 in missing"
                  , RuntimeError <| I.IdentifierNotFound "missing"
                  )

                --- The bound expression is evaluated before the body
                , ( "let a = zero?(zero?(0)) in missing"
                  , RuntimeError <|
                        I.TypeError
                            { expected = [ I.TNumber ]
                            , actual = [ I.TBool ]
                            }
                  )

                --- LETPAR semantics
                , ( "let x = 20 y = x in y", SucceedsWith (VNumber 10) )
                , ( "let x = 20 y = -(x, 1) in y", SucceedsWith (VNumber 9) )
                , ( "let a = 5 b = -(a, 1) c = -(b, 1) in c"
                  , RuntimeError <| I.IdentifierNotFound "a"
                  )
                , ( "let x = 1 x = x in x", SucceedsWith (VNumber 10) )
                , ( "let a = b b = 1 in a"
                  , RuntimeError <| I.IdentifierNotFound "b"
                  )
                , ( "let x = 1 x = 2 in x", SucceedsWith (VNumber 2) )
                ]
        ]


type Expected a
    = SucceedsWith a
    | SyntaxError
    | RuntimeError I.RuntimeError


testRun : (String -> Result I.Error a) -> ( String, Expected a ) -> Test
testRun f ( input, expectedOutput ) =
    test (Debug.toString input) <|
        \_ ->
            case ( f input, expectedOutput ) of
                ( Ok actual, SucceedsWith expected ) ->
                    if actual == expected then
                        Expect.pass

                    else
                        Expect.fail <|
                            Debug.toString
                                { expected = expected
                                , actual = actual
                                }

                ( Err (I.SyntaxError _), SyntaxError ) ->
                    Expect.pass

                ( Err (I.RuntimeError actual), RuntimeError expected ) ->
                    if actual == expected then
                        Expect.pass

                    else
                        Expect.fail <|
                            Debug.toString
                                { expected = expected
                                , actual = actual
                                }

                ( actual, expected ) ->
                    Expect.fail <|
                        Debug.toString
                            { expected = expected
                            , actual = actual
                            }
