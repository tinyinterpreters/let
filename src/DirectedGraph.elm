module DirectedGraph exposing
    ( DirectedGraph
    , Edge
    , Vertex
    , new
    , tsort
    )

import Dict exposing (Dict)
import Set exposing (Set)


type DirectedGraph
    = DirectedGraph AdjSet


type alias AdjSet =
    Dict Vertex (Set Vertex)


type alias Vertex =
    String


type alias Edge =
    ( Vertex, Vertex )


new : Set Vertex -> Set Edge -> DirectedGraph
new vertices =
    DirectedGraph
        << Set.foldl
            (\( u, v ) adj ->
                if Set.member u vertices && Set.member v vertices then
                    addEdge u v adj

                else
                    adj
            )
            (Set.foldl (\u -> Dict.insert u Set.empty) Dict.empty vertices)


addEdge : Vertex -> Vertex -> AdjSet -> AdjSet
addEdge u v =
    Dict.update u (addVertex v)


addVertex : Vertex -> Maybe (Set Vertex) -> Maybe (Set Vertex)
addVertex v maybeVertices =
    Just <|
        case maybeVertices of
            Nothing ->
                Set.singleton v

            Just vertices ->
                Set.insert v vertices


type alias TsortState =
    { time : Int
    , color : Dict Vertex Color
    , vertices : List Vertex
    }


type Color
    = Gray
    | Black


tsort : DirectedGraph -> Maybe (List Vertex)
tsort (DirectedGraph adj) =
    Dict.foldl
        (\u vs maybePrevState ->
            Maybe.andThen
                (\prevState ->
                    case Dict.get u prevState.color of
                        Nothing ->
                            visit u vs prevState adj

                        Just _ ->
                            maybePrevState
                )
                maybePrevState
        )
        (Just { time = 0, color = Dict.empty, vertices = [] })
        adj
        |> Maybe.map .vertices


visit : Vertex -> Set Vertex -> TsortState -> AdjSet -> Maybe TsortState
visit u vs state adj =
    Set.foldl
        (\v maybePrevState ->
            Maybe.andThen
                (\prevState ->
                    case Dict.get v prevState.color of
                        Nothing ->
                            Dict.get v adj
                                |> Maybe.andThen
                                    (\ws ->
                                        visit v ws prevState adj
                                    )

                        Just Gray ->
                            --
                            -- Found a cycle since (u, v) is a back edge
                            --
                            Nothing

                        Just Black ->
                            maybePrevState
                )
                maybePrevState
        )
        (Just
            { state
                | time = state.time + 1
                , color = Dict.insert u Gray state.color
            }
        )
        vs
        |> Maybe.map
            (\s ->
                { s
                    | time = s.time + 1
                    , color = Dict.insert u Black s.color
                    , vertices = u :: s.vertices
                }
            )
