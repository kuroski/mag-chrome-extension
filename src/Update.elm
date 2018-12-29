module Update exposing (Msg(..), update, userInformation, userSummary)

import Date exposing (Date, Unit(..), fromCalendarDate, month, year)
import Http
import Json.Decode as Decoder
import Json.Encode as Encode
import Model exposing (Credentials, Model, Page(..), Reminder, Summary)
import Port.Chrome exposing (setBadge)
import Port.Storage exposing (removeLocalstorage, setLocalstorage)
import Task exposing (Task)



-- API


badgeEncoder : Int -> Encode.Value
badgeEncoder remainingDays =
    Encode.object
        [ ( "days", Encode.int remainingDays )
        ]


loginEncoder : String -> String -> Encode.Value
loginEncoder email password =
    Encode.object
        [ ( "email", Encode.string email )
        , ( "password", Encode.string password )
        ]


authenticationEncoder : Credentials -> Encode.Value
authenticationEncoder credentials =
    Encode.object
        [ ( "token", Encode.string credentials.token )
        , ( "id", Encode.string credentials.id )
        ]


authenticationDecoder : Decoder.Decoder Credentials
authenticationDecoder =
    Decoder.map2 Credentials
        (Decoder.field "token" Decoder.string)
        (Decoder.field "id" (Decoder.map String.fromInt Decoder.int))


stringToFloatDecoder : String -> Decoder.Decoder Float
stringToFloatDecoder field =
    Decoder.field field Decoder.string
        |> Decoder.andThen
            (\maybeFloat ->
                case String.toFloat maybeFloat of
                    Just a ->
                        Decoder.succeed a

                    _ ->
                        Decoder.fail <| "API não retornou " ++ field ++ " como um float válido"
            )


userSummaryDecoder : Decoder.Decoder Summary
userSummaryDecoder =
    Decoder.map4 Summary
        (Decoder.field "name" Decoder.string)
        (stringToFloatDecoder "amount")
        (stringToFloatDecoder "gains")
        (stringToFloatDecoder "percentage")


additionalReminderDecoder : Decoder.Decoder Int
additionalReminderDecoder =
    Decoder.at [ "configuration", "additional_reminder_day" ] Decoder.int


userLogin : String -> String -> String -> Cmd Msg
userLogin serverUrl email password =
    let
        body =
            Http.jsonBody <| loginEncoder email password
    in
    Http.post
        { url = serverUrl ++ "/api/v1/users/tokens"
        , body = body
        , expect = Http.expectJson GotAuthentication authenticationDecoder
        }


userSummary : String -> String -> String -> Cmd Msg
userSummary serverUrl token userId =
    Http.request
        { method = "GET"
        , headers =
            [ Http.header "Accept" "application/vnd.api+json; version=1"
            , Http.header "Authorization" ("Bearer " ++ token)
            ]
        , url = serverUrl ++ "/api/portfolio_summary/" ++ userId
        , body = Http.emptyBody
        , expect = Http.expectJson GotUserSummary userSummaryDecoder
        , timeout = Nothing
        , tracker = Nothing
        }


userInformation : String -> String -> String -> Cmd Msg
userInformation serverUrl token userId =
    Http.request
        { method = "GET"
        , headers =
            [ Http.header "Accept" "application/json"
            , Http.header "Authorization" ("Bearer " ++ token)
            ]
        , url = serverUrl ++ "/api/users_informations/" ++ userId
        , body = Http.emptyBody
        , expect = Http.expectJson GotAdditionalReminder additionalReminderDecoder
        , timeout = Nothing
        , tracker = Nothing
        }



-- UPDATE


type Msg
    = EmailInputChanged String
    | PasswordInputChanged String
    | DispatchLogin
    | GotAuthentication (Result Http.Error Credentials)
    | GotUserSummary (Result Http.Error Summary)
    | GotAdditionalReminder (Result Http.Error Int)
    | GotReminderDiff Int Date


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EmailInputChanged value ->
            ( { model | emailInput = value }, Cmd.none )

        PasswordInputChanged value ->
            ( { model | passwordInput = value }, Cmd.none )

        DispatchLogin ->
            ( model, userLogin model.serverUrl model.emailInput model.passwordInput )

        GotAuthentication (Ok data) ->
            ( { model | page = Authorized data }
            , Cmd.batch
                [ userSummary model.serverUrl data.token data.id
                , userInformation model.serverUrl data.token data.id
                , setLocalstorage (authenticationEncoder <| Credentials data.token data.id)
                ]
            )

        GotAuthentication (Err _) ->
            ( model, Cmd.none )

        GotUserSummary (Ok data) ->
            ( { model | summary = Just (Summary data.name data.amount data.gains data.percentage) }, Cmd.none )

        GotUserSummary (Err _) ->
            ( { model | page = Guest }, removeLocalstorage () )

        GotAdditionalReminder (Ok reminderDay) ->
            ( model, Task.perform (GotReminderDiff reminderDay) Date.today )

        GotAdditionalReminder (Err _) ->
            ( { model | reminder = Nothing }, removeLocalstorage () )

        GotReminderDiff reminderDay today ->
            let
                lastReminder =
                    fromCalendarDate (year today) (month today) reminderDay

                lastReminderDiff =
                    Date.diff Days today lastReminder

                nextReminder =
                    Date.add Months 1 lastReminder

                nextReminderDiff =
                    Date.diff Days today nextReminder
            in
            if lastReminderDiff < 0 then
                ( { model | reminder = Just (Reminder reminderDay nextReminderDiff (Date.month nextReminder)) }
                , setBadge (badgeEncoder <| nextReminderDiff)
                )

            else
                ( { model | reminder = Just (Reminder reminderDay lastReminderDiff (Date.month lastReminder)) }
                , setBadge (badgeEncoder <| lastReminderDiff)
                )
