module Subs exposing (subs)

import Model exposing (Model)
import Update exposing (Msg)


subs : Model -> Sub Msg
subs model =
    Sub.none
