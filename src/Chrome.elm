port module Chrome exposing (setBadge)

import Json.Encode as Encode


port setBadge : Encode.Value -> Cmd msg
