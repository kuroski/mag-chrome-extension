port module Port.Storage exposing (removeLocalstorage, setLocalstorage)

import Json.Encode as Encode


port setLocalstorage : Encode.Value -> Cmd msg


port removeLocalstorage : () -> Cmd msg
