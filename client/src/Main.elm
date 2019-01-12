module Main exposing (LoadingStatus(..), Model, Msg(..), getEmissionsbyCountry, init, main, responseDecoder, showResult, subscriptions, update, view)

import Browser
import Html exposing (Attribute, Html, button, div, form, h1, img, input, label, text)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode exposing (Decoder, field, string)



-- MAIN


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type LoadingStatus
    = Failure
    | Loading
    | Success String
    | Initial


type alias Model =
    { loaded : LoadingStatus
    , country : String
    , year : Int
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { loaded = Initial, country = "", year = 0 }, Cmd.none )



-- UPDATE


type Msg
    = Search
    | Change String
    | ResultReceived (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Search ->
            ( { model | loaded = Loading }, getEmissionsbyCountry model.country model.year )

        ResultReceived result ->
            case result of
                Ok output ->
                    ( { model | loaded = Success output }, Cmd.none )

                Err _ ->
                    ( { model | loaded = Failure }, Cmd.none )

        Change newContent ->
            ( { model | country = newContent }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "main-wrap" ]
        [ h1 [ class "title" ] [ text "CO2-emissions" ]
        , input [ placeholder "Search by country", value model.country, onInput Change ] []
        , button [ onClick Search ] [ text "Search" ]
        , label [] [ input [ type_ "checkbox" ] [], text "Per Capita" ]
        , showResult model.loaded
        ]


showResult : LoadingStatus -> Html Msg
showResult model =
    case model of
        Failure ->
            div [ class "result" ] [ text "Failure" ]

        Loading ->
            div [ class "result" ] [ text "Loading..." ]

        Success output ->
            div
                [ class "result" ]
                [ text output
                , img [ src "//127.0.0.1:5000/picture" ] []
                ]

        Initial ->
            div [ class "result" ] []



-- HTTP


getEmissionsbyCountry : String -> Int -> Cmd Msg
getEmissionsbyCountry country year =
    Http.get
        { url = "http://127.0.0.1:5000/" ++ country
        , expect = Http.expectJson ResultReceived responseDecoder
        }


responseDecoder : Decoder String
responseDecoder =
    field "result" string
