module View exposing (view)

import Browser exposing (Document, document)
import Date exposing (Date)
import FormatNumber exposing (format)
import FormatNumber.Locales exposing (Locale)
import Html exposing (Html, a, br, button, div, form, h2, img, input, label, p, span, text)
import Html.Attributes exposing (class, for, href, id, placeholder, src, type_, value, width)
import Html.Events exposing (onInput, onSubmit)
import Model exposing (Model, Page(..), Reminder, RemoteData(..), Summary)
import Update exposing (Msg(..))
import View.Helpers exposing (toPortugueseMonth)


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
        [ img [ class "w-16", src "images/logo.svg" ] []
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
    div [ class "text-grey-lighter text-center" ]
        [ summaryView model.summary
        , div [ class "text-center mt-4" ]
            [ reminderView model.reminder
            ]
        ]


summaryView : Maybe Summary -> Html Msg
summaryView maybeSummary =
    let
        amountLocale =
            Locale 2 "." "," "−" "" "" ""

        percentageLocale =
            Locale 1 "." "," "-" "" "+" ""

        gainLocale =
            Locale 2 "." "," "− R$ " "" "+ R$ " ""
    in
    case maybeSummary of
        Just summary ->
            div []
                [ div [ class "text-grey-light" ] [ text "Minha carteira" ]
                , div [ class "text-4xl font-semibold" ]
                    [ div [] [ text <| "R$ " ++ format amountLocale summary.amount ]
                    ]
                , div [ class "flex justify-between" ]
                    [ let
                        formattedPercentage =
                            format percentageLocale (summary.percentage * 100) ++ "%"
                      in
                      if summary.percentage > 0 then
                        div [ class "text-green" ] [ text formattedPercentage ]

                      else
                        div [ class "text-red-light" ] [ text formattedPercentage ]
                    , div [] [ text <| format gainLocale summary.gains ]
                    ]
                ]

        Nothing ->
            div []
                [ div [ class "text-grey-light" ] [ text "Minha carteira" ]
                , div [ class "placeholder h-10 w-64 mt-1" ] []
                , div [ class "flex justify-between mt-1" ]
                    [ div [ class "placeholder h-4 w-12" ] []
                    , div [ class "placeholder h-4 w-16" ] []
                    ]
                ]


reminderView : RemoteData Reminder -> Html Msg
reminderView maybeReminder =
    case maybeReminder of
        Data reminder ->
            div [ class "text-xs mb-2" ]
                [ div [ class "flex flex-col" ]
                    [ div
                        [ class "relative flex justify-center items-center mb-2" ]
                        [ div [ class "absolute pin flex flex-col justify-center items-center text-xs font-medium mt-3" ]
                            [ span []
                                [ text <| toPortugueseMonth reminder.nextInvestmentMonth
                                ]
                            , span [] [ text <| String.fromInt reminder.reminderDay ]
                            ]
                        , img [ width 46, src "images/calendar.svg" ] []
                        ]
                    , span
                        [ class "font-semibold" ]
                        [ text <| String.fromInt reminder.nextInvestmentDay ++ " dias"
                        ]
                    , span []
                        [ text "até sua nova aplicação"
                        ]
                    ]
                ]

        Loading ->
            span [] [ text "loading" ]

        NoData ->
            span [] []
