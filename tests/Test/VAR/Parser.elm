module Test.VAR.Parser exposing (suite)

import Test exposing (Test, describe)
import Test.Lib exposing (testValue)
import VAR.AST as AST exposing (..)
import VAR.Parser as P


suite : Test
suite =
    describe "VAR.Parser"
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
                , ( "else", Nothing )
                , ( "if", Nothing )
                , ( "let", Just (Program (Var "let")) )
                , ( "then", Nothing )
                , ( "zero", Just (Program (Var "zero")) )
                ]
        ]
