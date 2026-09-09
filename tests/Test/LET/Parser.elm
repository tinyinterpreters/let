module Test.LET.Parser exposing (suite)

import LET.AST as AST exposing (..)
import LET.Parser as P
import Test exposing (Test, describe)
import Test.Lib exposing (testValue)


suite : Test
suite =
    describe "LET.Parser"
        [ describe "parse" <|
            List.map (testValue P.parse)
                -- Constant expressions
                [ ( "123", Just (Program (Const 123)) )
                , ( "123 ", Just (Program (Const 123)) )
                , ( "123  ", Just (Program (Const 123)) )
                , ( " 123", Just (Program (Const 123)) )
                , ( "  123", Just (Program (Const 123)) )
                , ( "123abc", Nothing )

                -- Difference expressions
                , ( "-(456,123)", Just (Program (Diff (Const 456) (Const 123))) )
                , ( "-(456, 123)", Just (Program (Diff (Const 456) (Const 123))) )
                , ( "- ( 2, -( 4, 3 ) )", Just (Program (Diff (Const 2) (Diff (Const 4) (Const 3)))) )
                , ( """
                    -(
                        -(5 , 3),
                        -(0 , 1)
                    )
                    """
                  , Just (Program (Diff (Diff (Const 5) (Const 3)) (Diff (Const 0) (Const 1))))
                  )

                -- Is it zero?
                , ( "zero?(0)", Just (Program (Zero (Const 0))) )
                , ( "zero? ( 0 ) ", Just (Program (Zero (Const 0))) )
                , ( """
                    zero?(
                        -( 0
                         , 1
                         )
                    )
                    """
                  , Just (Program (Zero (Diff (Const 0) (Const 1))))
                  )

                -- Conditionals
                , ( "if zero?(0) then 2 else 3", Just (Program (If (Zero (Const 0)) (Const 2) (Const 3))) )

                --- Liberal whitespace
                , ( """
                    if zero? ( 1 ) then
                        2

                    else
                        3
                    """
                  , Just (Program (If (Zero (Const 1)) (Const 2) (Const 3)))
                  )

                --- Nested conditionals
                , ( """
                    if zero?(0) then
                        if zero?(1) then 2 else 4
                    else
                        if zero?(3) then 5 else 7
                    """
                  , Just
                        (Program
                            (If
                                (Zero (Const 0))
                                (If (Zero (Const 1)) (Const 2) (Const 4))
                                (If (Zero (Const 3)) (Const 5) (Const 7))
                            )
                        )
                  )

                --- A non-Boolean condition
                , ( "if 0 then 2 else 3", Just (Program (If (Const 0) (Const 2) (Const 3))) )

                --- The consequent would evaluate to a number
                --- The alternative would evaluate to a Boolean
                , ( "if zero?(0) then 2 else zero?(3)", Just (Program (If (Zero (Const 0)) (Const 2) (Zero (Const 3)))) )

                -- Variables
                , ( "onetwothree", Just (Program (Var "onetwothree")) )
                , ( "zero", Just (Program (Var "zero")) )

                --- Reserved words
                , ( "else", Nothing )
                , ( "if", Nothing )
                , ( "in", Nothing )
                , ( "let", Nothing )
                , ( "then", Nothing )

                -- Let expressions
                , ( "let a = 5 in -(a, 3)"
                  , Just
                        (Program
                            (Let
                                [ Binding
                                    "a"
                                    (Const 5)
                                ]
                                (Diff (Var "a") (Const 3))
                            )
                        )
                  )

                --- Liberal whitespace
                , ( """
                    let
                        answer =
                            -(10, 2)
                    in
                    zero?(answer)
                    """
                  , Just
                        (Program
                            (Let
                                [ Binding
                                    "answer"
                                    (Diff (Const 10) (Const 2))
                                ]
                                (Zero (Var "answer"))
                            )
                        )
                  )

                --- Expressions in both positions
                , ( "let a = if zero?(0) then 5 else 8 in -(a, 3)"
                  , Just
                        (Program
                            (Let
                                [ Binding
                                    "a"
                                    (If
                                        (Zero (Const 0))
                                        (Const 5)
                                        (Const 8)
                                    )
                                ]
                                (Diff (Var "a") (Const 3))
                            )
                        )
                  )

                --- Nested let expressions
                , ( "let a = 5 in let b = 3 in -(a, b)"
                  , Just
                        (Program
                            (Let
                                [ Binding
                                    "a"
                                    (Const 5)
                                ]
                                (Let
                                    [ Binding
                                        "b"
                                        (Const 3)
                                    ]
                                    (Diff (Var "a") (Var "b"))
                                )
                            )
                        )
                  )

                --- Multiple bindings
                , ( "let a = 5 b = 3 in -(a, b)"
                  , Just
                        (Program
                            (Let
                                [ Binding "a" (Const 5)
                                , Binding "b" (Const 3)
                                ]
                                (Diff (Var "a") (Var "b"))
                            )
                        )
                  )
                , ( """
                    let
                        a = 5
                        b = 3
                        c =
                            -(a, b)
                    in
                    c
                    """
                  , Just
                        (Program
                            (Let
                                [ Binding "a" (Const 5)
                                , Binding "b" (Const 3)
                                , Binding "c" (Diff (Var "a") (Var "b"))
                                ]
                                (Var "c")
                            )
                        )
                  )
                ]
        ]
