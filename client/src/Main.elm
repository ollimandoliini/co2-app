module Main exposing (LoadingStatus(..), Model, Msg(..), countryDataDecoder, getEmissionsbyCountry, init, main, showResult, subscriptions, update, view)

import Browser
import Debug exposing (log)
import Graph exposing (plot)
import Html exposing (Attribute, Html, button, div, form, h1, img, input, label, li, span, table, tbody, text, th, thead, tr, ul)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as JD exposing (Decoder, field, float, int, string)
import Models exposing (CountryData, Datapoint)



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
    | Success CountryData
    | Initial


type alias Model =
    { loaded : LoadingStatus
    , keyword : String
    , envs : Flags
    , countries : List CountryData
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { loaded = Initial, keyword = "", envs = flags, countries = [] }, Cmd.none )



-- UPDATE


type Msg
    = SearchAndAdd
    | Change String
    | ResultReceived (Result Http.Error CountryData)
    | RemoveCountry String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        SearchAndAdd ->
            ( { model | loaded = Loading }, getEmissionsbyCountry model.keyword model.envs )

        ResultReceived result ->
            case result of
                Ok output ->
                    ( { model | loaded = Success output, countries = addCountryData model.countries output }, Cmd.none )

                Err _ ->
                    ( { model | loaded = Failure }, Cmd.none )

        Change newContent ->
            ( { model | keyword = newContent }, Cmd.none )

        RemoveCountry countryname ->
            ( { model | countries = removeCountry model.countries countryname }, Cmd.none )


addCountryData : List CountryData -> CountryData -> List CountryData
addCountryData oldList countrydataitem =
    countrydataitem :: oldList



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "main-wrap" ]
        [ h1 [ class "title" ] [ text "CO2-emissions" ]
        , input [ placeholder "Finland", value model.keyword, onInput Change ] []
        , button [ onClick SearchAndAdd ] [ text "Add" ]
        , showResult model
        ]


showResult : Model -> Html Msg
showResult model =
    case model.loaded of
        Failure ->
            div [ class "result" ] [ text "Failure" ]

        Loading ->
            div [ class "result" ] [ text "Loading..." ]

        Success output ->
            div
                [ class "result" ]
                [ listCountries model.countries
                , Graph.plot model.countries
                ]

        Initial ->
            div [ class "result" ] []


listCountries : List CountryData -> Html Msg
listCountries countrieslist =
    ul [] (List.map countryItem countrieslist)


countryItem : CountryData -> Html Msg
countryItem countrydata =
    span [ onClick (RemoveCountry countrydata.country) ] [ li [] [ text countrydata.country ] ]


removeCountry : List CountryData -> String -> List CountryData
removeCountry oldlist countryname =
    List.filter (\countryData -> countryData.country /= countryname) oldlist



-- HTTP


getEmissionsbyCountry : String -> Flags -> Cmd Msg
getEmissionsbyCountry keyword flags =
    Http.get
        { url = flags.apiUrl ++ "countries/" ++ keyword
        , expect = Http.expectJson ResultReceived countryDataDecoder
        }


countryDataDecoder : Decoder CountryData
countryDataDecoder =
    JD.map2 CountryData
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
