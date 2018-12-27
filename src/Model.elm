module Model exposing (Credentials, Flags, Model, Page(..), Summary)

import Date exposing (Date)


type Page
    = Authorized Credentials
    | Guest


type alias Flags =
    { serverUrl : String
    , credentials : Maybe Credentials
    }


type alias Credentials =
    { token : String
    , id : String
    }


type alias Summary =
    { name : String
    , amount : String
    , gains : String
    , percentage : String
    }


type alias Model =
    { page : Page
    , emailInput : String
    , passwordInput : String
    , summary : Summary
    , serverUrl : String
    , reminderDay : Maybe Int
    , nextInvestmentDay : Int
    , nextInvestmentMonth : Maybe Date.Month
    }
