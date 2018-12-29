module Model exposing (Credentials, Flags, Model, Page(..), Reminder, Summary)

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
    , amount : Float
    , gains : Float
    , percentage : Float
    }


type alias Reminder =
    { reminderDay : Int
    , nextInvestmentDay : Int
    , nextInvestmentMonth : Date.Month
    }


type alias Model =
    { page : Page
    , emailInput : String
    , passwordInput : String
    , summary : Maybe Summary
    , serverUrl : String
    , reminder : Maybe Reminder
    }
