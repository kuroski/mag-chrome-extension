module Main exposing (main)

import Browser exposing (Document, document)
import Html exposing (Html, a, br, button, div, form, img, input, label, p, text)
import Html.Attributes exposing (class, for, href, id, placeholder, src, type_, value)
import Html.Events exposing (onInput, onSubmit)
import Http
import Json.Decode as Decoder
import Json.Encode as Encode



-- MAIN


main : Program () Model Msg
main =
    document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


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
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { page = Guest
      , emailInput = ""
      , passwordInput = ""
      , summary = Summary "" "" "" ""
      }
    , Cmd.none
    )



-- API


loginEncoder : String -> String -> Encode.Value
loginEncoder email password =
    Encode.object
        [ ( "email", Encode.string email )
        , ( "password", Encode.string password )
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


userLogin : String -> String -> Cmd Msg
userLogin email password =
    let
        body =
            Http.jsonBody <| loginEncoder email password
    in
    Http.post
        { url = "http://localhost:4000/api/v1/users/tokens"
        , body = body
        , expect = Http.expectJson GotAuthentication authenticationDecoder
        }


userSummary : String -> String -> Cmd Msg
userSummary token userId =
    Http.request
        { method = "GET"
        , headers =
            [ Http.header "Accept" "application/vnd.api+json; version=1"
            , Http.header "Authorization" ("Bearer " ++ token)
            ]
        , url = "http://localhost:4000/api/portfolio_summary/" ++ userId
        , body = Http.emptyBody
        , expect = Http.expectJson GotUserSummary userSummaryDecoder
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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EmailInputChanged value ->
            ( { model | emailInput = value }, Cmd.none )

        PasswordInputChanged value ->
            ( { model | passwordInput = value }, Cmd.none )

        DispatchLogin ->
            ( model, userLogin model.emailInput model.passwordInput )

        GotAuthentication (Ok data) ->
            ( { model | page = Authorized data }, userSummary data.token data.id )

        GotAuthentication (Err _) ->
            ( model, Cmd.none )

        GotUserSummary (Ok data) ->
            ( { model | summary = Summary data.name data.amount data.gains data.percentage }, Cmd.none )

        GotUserSummary (Err _) ->
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
            [ img [ src "images/logo.svg" ] []
            , case model.page of
                Guest ->
                    guestView model

                Authorized { token } ->
                    authorizedView model token
            ]
        ]
    }


guestView : Model -> Html Msg
guestView model =
    form
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


authorizedView : Model -> String -> Html Msg
authorizedView model token =
    div []
        [ div [] [ text model.summary.name ]
        , div [] [ text model.summary.amount ]
        , div [] [ text model.summary.gains ]
        , div [] [ text model.summary.percentage ]
        ]
