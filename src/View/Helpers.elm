module View.Helpers exposing (toPortugueseMonth)

import Date exposing (Date)
import Time exposing (Month(..))


toPortugueseMonth : Date.Month -> String
toPortugueseMonth month =
    case month of
        Jan ->
            "Jan"

        Feb ->
            "Fev"

        Mar ->
            "Mar"

        Apr ->
            "Abr"

        May ->
            "Mai"

        Jun ->
            "Jun"

        Jul ->
            "Jul"

        Aug ->
            "Ago"

        Sep ->
            "Set"

        Oct ->
            "Out"

        Nov ->
            "Nov"

        Dec ->
            "Dez"
