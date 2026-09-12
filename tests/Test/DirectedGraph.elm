module Test.DirectedGraph exposing (suite)

import DirectedGraph exposing (DirectedGraph, Edge, Vertex)
import Expect
import Set
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "DirectedGraph"
        [ tsortSuite
        ]


tsortSuite : Test
tsortSuite =
    describe "tsort"
        [ tsort [ "a" ] [] <|
            Just [ "a" ]
        , tsort [ "a", "b", "c" ] [ ( "a", "b" ), ( "a", "c" ), ( "b", "c" ) ] <|
            Just [ "a", "b", "c" ]
        , tsort [ "a", "b", "c" ] [ ( "a", "b" ), ( "a", "c" ), ( "c", "b" ) ] <|
            Just [ "a", "c", "b" ]
        , tsort [ "a", "b", "c" ] [ ( "a", "b" ), ( "a", "c" ), ( "b", "c" ), ( "c", "b" ) ] <|
            Nothing
        , tsort
            [ "result", "a", "ready", "b", "c", "d", "e", "f", "h", "g" ]
            [ ( "a", "result" )
            , ( "b", "result" )
            , ( "ready", "result" )
            , ( "c", "a" )
            , ( "d", "a" )
            , ( "g", "ready" )
            , ( "e", "b" )
            , ( "e", "ready" )
            , ( "f", "b" )
            , ( "g", "c" )
            , ( "g", "e" )
            , ( "h", "c" )
            , ( "h", "d" )
            ]
          <|
            Just [ "h", "g", "f", "e", "ready", "d", "c", "b", "a", "result" ]
        ]


tsort : List Vertex -> List Edge -> Maybe (List Vertex) -> Test
tsort vertices edges maybeVertices =
    test ("V = " ++ Debug.toString vertices ++ ", E = " ++ Debug.toString edges) <|
        \_ ->
            DirectedGraph.new (Set.fromList vertices) (Set.fromList edges)
                |> DirectedGraph.tsort
                |> Expect.equal maybeVertices
