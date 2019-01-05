module Main exposing (LoadingStatus(..), Model, Msg(..), getEmissionsbyCountry, init, main, responseDecoder, showData, subscriptions, update, view)

import Browser
import Html exposing (..)
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
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { loaded = Initial, country = "" }, Cmd.none )



-- UPDATE


type Msg
    = Search
    | Change String
    | ResultReceived (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Search ->
            ( { model | loaded = Loading }, getEmissionsbyCountry model.country )

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
    div []
        [ h2 [ class "title" ] [ text "CO2-emissions" ]
        , input [ placeholder "Search by country", value model.country, onInput Change ] []
        , button [ onClick Search ] [ text "Search" ]
        , showData model.loaded
        ]


showData : LoadingStatus -> Html Msg
showData model =
    case model of
        Failure ->
            div [] [ text "Failure" ]

        Loading ->
            text "Loading..."

        Success output ->
            div []
                [ text output
                ]

        Initial ->
            div [] []



-- HTTP


getEmissionsbyCountry : String -> Cmd Msg
getEmissionsbyCountry keyword =
    Http.get
        { url = "http://127.0.0.1:5000/" ++ keyword
        , expect = Http.expectJson ResultReceived responseDecoder
        }


responseDecoder : Decoder String
responseDecoder =
    field "result" string
