module Main exposing (Msg(..), main)

import Browser exposing (Document, document)
import Chrome exposing (setBadge)
import Date exposing (Date, Unit(..), fromCalendarDate, fromOrdinalDate, month, toIsoString, year)
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (Locale)
import Html exposing (Html, a, br, button, div, form, h2, img, input, label, p, span, text)
import Html.Attributes exposing (class, for, href, id, placeholder, src, type_, value, width)
import Html.Events exposing (onInput, onSubmit)
import Http
import Json.Decode as Decoder
import Json.Encode as Encode
import Storage exposing (removeLocalstorage, setLocalstorage)
import Task exposing (Task)
import Time exposing (Month(..))



-- MAIN


main : Program Flags Model Msg
main =
    document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


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


type Page
    = Authorized Credentials
    | Guest


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


init : Flags -> ( Model, Cmd Msg )
init flags =
    case flags.credentials of
        Just credentials ->
            ( { page = Authorized credentials
              , emailInput = ""
              , passwordInput = ""
              , summary = Summary "" "" "" ""
              , serverUrl = flags.serverUrl
              , reminderDay = Nothing
              , nextInvestmentDay = 0
              , nextInvestmentMonth = Nothing
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
              , summary = Summary "" "" "" ""
              , serverUrl = flags.serverUrl
              , reminderDay = Nothing
              , nextInvestmentDay = 0
              , nextInvestmentMonth = Nothing
              }
            , Cmd.none
            )



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


userSummaryDecoder : Decoder.Decoder Summary
userSummaryDecoder =
    Decoder.map4 Summary
        (Decoder.field "name" Decoder.string)
        (Decoder.field "amount" Decoder.string)
        (Decoder.field "gains" Decoder.string)
        (Decoder.field "percentage" Decoder.string)


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
    | GotToday Date


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
            ( { model | summary = Summary data.name data.amount data.gains data.percentage }, Cmd.none )

        GotUserSummary (Err _) ->
            ( { model | page = Guest }, removeLocalstorage () )

        GotAdditionalReminder (Ok data) ->
            ( { model | reminderDay = Just data }, Task.perform GotToday Date.today )

        GotAdditionalReminder (Err _) ->
            ( { model | reminderDay = Nothing }, removeLocalstorage () )

        GotToday date ->
            case ( Just date, model.reminderDay ) of
                ( Just today, Just reminderDay ) ->
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
                        ( { model | nextInvestmentDay = nextReminderDiff, nextInvestmentMonth = Just (Date.month nextReminder) }
                        , setBadge (badgeEncoder <| nextReminderDiff)
                        )

                    else
                        ( { model | nextInvestmentDay = lastReminderDiff, nextInvestmentMonth = Just (Date.month lastReminder) }
                        , setBadge (badgeEncoder <| lastReminderDiff)
                        )

                _ ->
                    ( model, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "Magnetis Chrome extension"
    , body =
        [ div [ class "w-full min-h-screen flex flex-col items-center justify-center bg-black pt-8" ]
            [ case model.page of
                Guest ->
                    guestView model

                Authorized { token } ->
                    authorizedView model token
            ]
        ]
    }


guestView : Model -> Html Msg
guestView model =
    div [ class "flex flex-col items-center justify-center" ]
        [ img [ src "images/logo.svg" ] []
        , form
            [ onSubmit DispatchLogin
            , class "w-full max-w-xs px-4 py-8"
            ]
            [ div [ class "mb-4" ]
                [ label [ class "block text-grey text-xs font-bold mb-1", for "email" ]
                    [ text "Email" ]
                , input
                    [ onInput EmailInputChanged
                    , value model.emailInput
                    , class "shadow appearance-none bg-grey-darkest rounded w-full py-2 px-3 text-grey-dark leading-tight focus:outline-none focus:shadow-outline"
                    , id "email"
                    , placeholder "Digite seu email"
                    , type_ "text"
                    ]
                    []
                ]
            , div [ class "mb-8" ]
                [ label [ class "block text-grey text-xs font-bold mb-1", for "password" ]
                    [ text "Senha" ]
                , input
                    [ onInput PasswordInputChanged
                    , value model.passwordInput
                    , class "shadow appearance-none bg-grey-darkest rounded w-full py-2 px-3 text-grey-dark leading-tight focus:outline-none focus:shadow-outline"
                    , id "password"
                    , placeholder "Digite sua senha"
                    , type_ "password"
                    ]
                    []
                ]
            , div [ class "flex items-center justify-between" ]
                [ button
                    [ class
                        "w-full bg-blue hover:bg-blue-dark text-white font-semibold py-4 px-4 rounded-sm focus:outline-none focus:shadow-outline"
                    , type_ "submit"
                    ]
                    [ text "Login" ]
                ]
            ]
        ]


authorizedView : Model -> String -> Html Msg
authorizedView model token =
    let
        amountLocale =
            Locale 2 "." "," "−" "" "" ""

        percentageLocale =
            Locale 1 "." "," "-" "" "+" ""

        gainLocale =
            Locale 2 "." "," "− R$ " "" "+ R$ " ""
    in
    div [ class "text-grey-lighter text-center" ]
        [ div [ class "text-grey-light" ] [ text "Minha carteira" ]
        , div [ class "text-4xl font-semibold" ]
            [ case String.toFloat model.summary.amount of
                Just amount ->
                    div [] [ text <| "R$ " ++ format amountLocale amount ]

                _ ->
                    div [] [ text "R$ -,--" ]
            ]
        , div [ class "flex justify-between" ]
            [ case String.toFloat model.summary.percentage of
                Just percentage ->
                    let
                        formattedPercentage =
                            format percentageLocale (percentage * 100) ++ "%"
                    in
                    if percentage > 0 then
                        div [ class "text-green" ] [ text formattedPercentage ]

                    else
                        div [ class "text-red-light" ] [ text formattedPercentage ]

                _ ->
                    div [] [ text "-,- %" ]
            , case String.toFloat model.summary.gains of
                Just gains ->
                    div [] [ text <| format gainLocale gains ]

                _ ->
                    div [] [ text "R$ -,--" ]
            ]
        , div [ class "text-center mt-4" ]
            [ remainingDaysToInvestmentView model
            ]
        ]


remainingDaysToInvestmentView : Model -> Html Msg
remainingDaysToInvestmentView model =
    case model.reminderDay of
        Just reminderDay ->
            div [ class "text-xs mb-2" ]
                [ div [ class "flex flex-col" ]
                    [ reminderView model.reminderDay model.nextInvestmentMonth
                    , span [ class "font-semibold" ]
                        [ text <| String.fromInt model.nextInvestmentDay ++ " dias"
                        ]
                    , span []
                        [ text "até sua nova aplicação"
                        ]
                    ]
                ]

        _ ->
            span [] []


reminderView : Maybe Int -> Maybe Date.Month -> Html Msg
reminderView maybeReminderDay maybeMonth =
    case ( maybeReminderDay, maybeMonth ) of
        ( Just reminderDay, Just month ) ->
            div
                [ class "relative flex justify-center items-center mb-2" ]
                [ div [ class "absolute pin flex flex-col justify-center items-center text-xs font-medium mt-3" ]
                    [ span []
                        [ text <| toPortugueseMonth month
                        ]
                    , span [] [ text <| String.fromInt reminderDay ]
                    ]
                , img [ width 46, src "images/calendar.svg" ] []
                ]

        _ ->
            span [] [ text "Nenhum lembrete configurado" ]


toPortugueseMonth : Date.Month -> String
toPortugueseMonth month =
    case month of
        Jan ->
            "Jan"

        Feb ->
            "Fev"

        Mar ->
            "Mar"

        Apr ->
            "Abr"

        May ->
            "Mai"

        Jun ->
            "Jun"

        Jul ->
            "Jul"

        Aug ->
            "Ago"

        Sep ->
            "Set"

        Oct ->
            "Out"

        Nov ->
            "Nov"

        Dec ->
            "Dez"
