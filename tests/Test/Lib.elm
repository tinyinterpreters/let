module Test.Lib exposing (testValue)

import Expect
import Test exposing (Test, test)


testValue : (String -> Result e a) -> ( String, Maybe a ) -> Test
testValue f ( input, expectedOutput ) =
    test (Debug.toString input) <|
        \_ ->
            case ( f input, expectedOutput ) of
                ( Ok actual, Just expected ) ->
                    if actual == expected then
                        Expect.pass

                    else
                        Expect.fail <|
                            Debug.toString
                                { expected = expected
                                , actual = actual
                                }

                ( Err _, Nothing ) ->
                    Expect.pass

                ( actual, expected ) ->
                    Expect.fail <|
                        Debug.toString
                            { expected = expected
                            , actual = actual
                            }
