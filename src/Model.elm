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
    , amount : Float
    , gains : Float
    , percentage : Float
    }



{-
   type alias ReminderDay =
       { reminderDay : Int
       , nextInvestmentDay : Int
       , nextInvestmentMonth : Date.Month
       }
-}
-- TODO: Refactor reminder to type alias and put only in one case on the view


type alias Model =
    { page : Page
    , emailInput : String
    , passwordInput : String
    , summary : Maybe Summary
    , serverUrl : String
    , reminderDay : Maybe Int
    , nextInvestmentDay : Int
    , nextInvestmentMonth : Maybe Date.Month
    }
