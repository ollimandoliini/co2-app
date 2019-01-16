module Main exposing (LoadingStatus(..), Model, Msg(..), getEmissionsbyCountry, init, main, responseDecoder, showResult, subscriptions, update, view)

import Browser
import Graph exposing (plot)
import Html exposing (Attribute, Html, button, div, form, h1, img, input, label, table, tbody, text, th, thead, tr)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as JD exposing (Decoder, field, float, int, string)
import Models exposing (Datapoint, Response)



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


type alias Model =
    { loaded : LoadingStatus
    , keyword : String
    , envs : Flags
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { loaded = Initial, keyword = "", envs = flags }, Cmd.none )



-- UPDATE


type Msg
    = Search
    | Change String
    | ResultReceived (Result Http.Error Response)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Search ->
            ( { model | loaded = Loading }, getEmissionsbyCountry model.keyword model.envs )

        ResultReceived result ->
            case result of
                Ok output ->
                    ( { model | loaded = Success output }, Cmd.none )

                Err _ ->
                    ( { model | loaded = Failure }, Cmd.none )

        Change newContent ->
            ( { model | keyword = newContent }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "main-wrap" ]
        [ h1 [ class "title" ] [ text "CO2-emissions" ]
        , input [ placeholder "Search by country", value model.keyword, onInput Change ] []
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
                [ text output.country

                -- , listDatapoints output.dataPoints
                , Graph.plot output
                ]

        Initial ->
            div [ class "result" ] []


listDatapoints : List Datapoint -> Html Msg
listDatapoints datapoints =
    div [ class "p2" ]
        [ table []
            [ thead []
                [ tr []
                    [ th [] [ text "Year" ]
                    , th [] [ text "CO2" ]
                    , th [] [ text "Population" ]
                    , th [] [ text "Metric Tons Per Capita" ]
                    ]
                ]
            , tbody [] (List.map datapointRow (List.reverse datapoints))
            ]
        ]


datapointRow : Datapoint -> Html Msg
datapointRow datapoint =
    tr []
        [ th [] [ text (String.fromFloat datapoint.year) ]
        , th [] [ text (String.fromFloat datapoint.co2_kilotons) ]
        , th [] [ text (String.fromInt datapoint.population) ]
        , th [] [ text (String.fromFloat datapoint.co2_per_capita) ]
        ]



-- datapointsList :
-- HTTP


getEmissionsbyCountry : String -> Flags -> Cmd Msg
getEmissionsbyCountry keyword flags =
    Http.get
        { url = flags.apiUrl ++ "countries/" ++ keyword
        , expect = Http.expectJson ResultReceived responseDecoder
        }


responseDecoder : Decoder Response
responseDecoder =
    JD.map2 Response
        (JD.field "country" JD.string)
        (JD.field "dataPoints" datapointlistDecoder)


datapointlistDecoder : Decoder (List Datapoint)
datapointlistDecoder =
    JD.list datapointDecoder


datapointDecoder : Decoder Datapoint
datapointDecoder =
    JD.map4 Datapoint
        (JD.field "year" float)
        (JD.field "co2_kilotons" float)
        (JD.field "population" int)
        (JD.field "co2_per_capita" float)
