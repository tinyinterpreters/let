module VAR.Env exposing (Env, empty, extend, lookup)

import Dict exposing (Dict)


type Env k v
    = Env (Dict k v)


empty : Env k v
empty =
    Env Dict.empty


extend : comparable -> v -> Env comparable v -> Env comparable v
extend name value (Env dict) =
    Env (Dict.insert name value dict)


lookup : comparable -> Env comparable v -> Maybe v
lookup name (Env dict) =
    Dict.get name dict
