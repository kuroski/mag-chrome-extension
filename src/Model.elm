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



-- TODO: Transform from String to Float and update decoders


type alias Summary =
    { name : String
    , amount : String
    , gains : String
    , percentage : String
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
    , summary : Summary
    , serverUrl : String
    , reminderDay : Maybe Int
    , nextInvestmentDay : Int
    , nextInvestmentMonth : Maybe Date.Month
    }
