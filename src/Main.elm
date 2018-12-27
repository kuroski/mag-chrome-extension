module Main exposing (main)

import Browser exposing (Document, document)
import Init exposing (init)
import Model exposing (Flags, Model)
import Subs exposing (subs)
import Update exposing (Msg(..), update, userInformation, userSummary)
import View exposing (view)


main : Program Flags Model Msg
main =
    document
        { init = init
        , view = view
        , update = update
        , subscriptions = subs
        }
