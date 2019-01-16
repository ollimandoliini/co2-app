module Main exposing (LoadingStatus(..), Model, Msg(..), getEmissionsbyCountry, init, main, responseDecoder, showResult, subscriptions, update, view)

import Browser
import Html exposing (Attribute, Html, button, div, form, h1, img, input, label, text)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as JD exposing (Decoder, field, float, int, string)



-- MAIN


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type alias Flags =
    { apiUrl : String, environment : String }


type LoadingStatus
    = Failure
    | Loading
    | Success Response
    | Initial


type alias Response =
    { country : String
    , dataPoints : List DataPoint
    }


type alias DataPoint =
    { year : Int
    , co2_kilotons : Maybe Float
    , population : Int
    , co2_per_capita : Maybe Float
    }


type alias Model =
    { loaded : LoadingStatus
    , country : String
    , envs : Flags
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { loaded = Initial, country = "", envs = flags }, Cmd.none )



-- UPDATE


type Msg
    = Search
    | Change String
    | ResultReceived (Result Http.Error Response)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Search ->
            ( { model | loaded = Loading }, getEmissionsbyCountry model.country model.envs )

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
                [ text output.country ]

        Initial ->
            div [ class "result" ] []



-- HTTP


getEmissionsbyCountry : String -> Flags -> Cmd Msg
getEmissionsbyCountry country flags =
    Http.get
        { url = flags.apiUrl ++ "countries/" ++ country
        , expect = Http.expectJson ResultReceived responseDecoder
        }


responseDecoder : Decoder Response
responseDecoder =
    JD.map2 Response
        (JD.field "country" JD.string)
        (JD.field "dataPoints" datapointlistDecoder)


datapointlistDecoder : Decoder (List DataPoint)
datapointlistDecoder =
    JD.list datapointDecoder


datapointDecoder : Decoder DataPoint
datapointDecoder =
    JD.map4 DataPoint
        (JD.field "year" int)
        (JD.maybe (JD.field "co2_kilotons" JD.float))
        (JD.field "population" int)
        (JD.maybe (JD.field "co2_per_capita" JD.float))
