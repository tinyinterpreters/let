module Test.VAR.Interpreter exposing (suite)

import Expect
import Test exposing (Test, describe, test)
import VAR.Interpreter as I exposing (Value(..))


suite : Test
suite =
    describe "VAR.Interpreter"
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
