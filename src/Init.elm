module Init exposing (init)

import Model exposing (Flags, Model, Page(..), Summary)
import Update exposing (Msg, userInformation, userSummary)


init : Flags -> ( Model, Cmd Msg )
init flags =
    case flags.credentials of
        Just credentials ->
            ( { page = Authorized credentials
              , emailInput = ""
              , passwordInput = ""
              , summary = Nothing
              , serverUrl = flags.serverUrl
              , reminder = Nothing
              }
            , Cmd.batch
                [ userSummary flags.serverUrl credentials.token credentials.id
                , userInformation flags.serverUrl credentials.token credentials.id
                ]
            )

        _ ->
            ( { page = Guest
              , emailInput = ""
              , passwordInput = ""
              , summary = Nothing
              , serverUrl = flags.serverUrl
              , reminder = Nothing
              }
            , Cmd.none
            )
