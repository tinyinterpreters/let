module VAR.Lexer exposing (digits, id, keyword, spaces, symbol)

import Parser as P exposing ((|.), (|=), Parser)
import Set exposing (Set)


digits : Parser Int
digits =
    chompOneOrMore Char.isDigit
        |> P.getChompedString
        |> P.map (Maybe.withDefault 0 << String.toInt)
        |> lexeme


chompOneOrMore : (Char -> Bool) -> Parser ()
chompOneOrMore isGood =
    P.succeed ()
        |. P.chompIf isGood
        |. P.chompWhile isGood


id : List String -> Parser String
id keywords =
    lexeme <|
        P.variable
            { start = Char.isLower
            , inner = Char.isLower
            , reserved = Set.fromList keywords
            }


keyword : String -> Parser ()
keyword =
    lexeme << P.keyword


symbol : String -> Parser ()
symbol =
    lexeme << P.symbol


lexeme : Parser a -> Parser a
lexeme p =
    P.succeed identity
        |= p
        |. spaces


spaces : Parser ()
spaces =
    P.spaces
