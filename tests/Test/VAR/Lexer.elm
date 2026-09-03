module Test.VAR.Lexer exposing (suite)

import Parser as P exposing (Parser)
import Test exposing (Test, describe)
import Test.Lib exposing (testValue)
import VAR.Lexer as L


suite : Test
suite =
    describe "VAR.Lexer"
        [ describe "digits" <|
            List.map (testValue <| P.run L.digits)
                [ ( "123", Just 123 )
                , ( "123 ", Just 123 )
                , ( "123  ", Just 123 )
                , ( "123abc", Just 123 )
                , ( " 123", Nothing )
                , ( "onetwothree", Nothing )
                ]
        , symbolSuite
        , keywordSuite
        , idSuite
        ]


symbolSuite : Test
symbolSuite =
    let
        symbol : String -> Parser String
        symbol =
            L.symbol >> P.getChompedString
    in
    describe "symbol"
        [ describe "-" <|
            List.map (testValue <| P.run <| symbol "-")
                -- Exact match
                [ ( "-", Just "-" )

                -- Trailing spaces
                , ( "- ", Just "- " )
                , ( "-\n(1", Just "-\n" )

                -- Tabs are not spaces
                , ( "- \t\n", Just "- " )

                -- Only the symbol and spaces
                , ( "-(1", Just "-" )

                -- No match
                , ( "(-", Nothing )

                -- No leading spaces
                , ( " -", Nothing )
                ]
        ]


keywordSuite : Test
keywordSuite =
    let
        keyword : String -> Parser String
        keyword =
            L.keyword >> P.getChompedString
    in
    describe "keyword"
        [ describe "zero?" <|
            List.map (testValue <| P.run <| keyword "zero?")
                -- Exact match
                [ ( "zero?", Just "zero?" )

                -- Trailing spaces
                , ( "zero? ", Just "zero? " )
                , ( "zero?\n(1)", Just "zero?\n" )

                -- Only the keyword
                , ( "zero?(1)", Just "zero?" )

                -- No match
                , ( "zero?th", Nothing )

                -- No leading spaces
                , ( " zero?", Nothing )
                ]
        ]


idSuite : Test
idSuite =
    let
        id : Parser String
        id =
            L.id [ "let", "zero" ]
    in
    describe "id" <|
        List.map (testValue <| P.run id)
            [ ( "x", Just "x" )
            , ( "letter", Just "letter" )
            , ( "let", Nothing )
            , ( "zero", Nothing )
            ]
