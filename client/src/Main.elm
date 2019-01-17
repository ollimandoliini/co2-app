module Main exposing (LoadingStatus(..), Model, Msg(..), countryDataDecoder, getEmissionsbyCountry, init, main, showResult, subscriptions, update, view)

import Array
import Browser
import Color exposing (Color)
import Debug exposing (log)
import Html exposing (Attribute, Html, button, div, form, h1, img, input, label, li, span, table, tbody, text, th, thead, tr, ul)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as JD exposing (Decoder, field, float, int, string)
import LineChart
import LineChart.Area as Area
import LineChart.Axis as Axis
import LineChart.Axis.Intersection as Intersection
import LineChart.Colors as Colors
import LineChart.Container as Container
import LineChart.Dots as Dots
import LineChart.Events as Events
import LineChart.Grid as Grid
import LineChart.Interpolation as Interpolation
import LineChart.Junk as Junk exposing (..)
import LineChart.Legends as Legends
import LineChart.Line as Line



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
    , percapita : Bool
    , countrylist : List String
    }


type alias Datapoint =
    { year : Float
    , co2_kilotons : Float
    , population : Int
    , co2_per_capita : Float
    }


type alias CountryData =
    { country : String
    , dataPoints : List Datapoint
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { loaded = Initial, keyword = "", envs = flags, countries = [], percapita = False, countrylist = [] }, Cmd.batch [ getEmissionsbyCountry "Finland" flags, getCountryList flags ] )



-- UPDATE


type Msg
    = SearchAndAdd
    | Change String
    | ResultReceived (Result Http.Error CountryData)
    | CountryListReceived (Result Http.Error (List String))
    | RemoveCountry String
    | TogglePerCapita
    | KeyDown Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CountryListReceived result ->
            case result of
                Ok output ->
                    ( { model | countrylist = output }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        ResultReceived result ->
            case result of
                Ok output ->
                    ( { model | loaded = Success output, countries = addCountryData model.countries output, keyword = "" }, Cmd.none )

                Err _ ->
                    ( { model | loaded = Failure }, Cmd.none )

        Change newContent ->
            ( { model | keyword = newContent }, Cmd.none )

        SearchAndAdd ->
            ( { model | loaded = Loading }, getEmissionsbyCountry model.keyword model.envs )

        RemoveCountry countryname ->
            ( { model | countries = removeCountry model.countries countryname }, Cmd.none )

        TogglePerCapita ->
            ( { model | percapita = perCapitaToggle model.percapita }, Cmd.none )

        KeyDown key ->
            if key == 13 then
                ( { model | loaded = Loading }, getEmissionsbyCountry model.keyword model.envs )

            else
                ( model, Cmd.none )


perCapitaToggle : Bool -> Bool
perCapitaToggle current =
    if current == True then
        False

    else
        True


addCountryData : List CountryData -> CountryData -> List CountryData
addCountryData oldList countrydataitem =
    -- countrydataitem :: oldList
    List.append oldList [ countrydataitem ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "main-wrap" ]
        [ h1 [ class "title" ] [ text "CO2-emissions" ]
        , input [ placeholder "Finland", onKeyDown KeyDown, onInput Change, value model.keyword ] []
        , button [ onClick SearchAndAdd ] [ text "Add" ]
        , showResult model
        ]


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (JD.map tagger keyCode)


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
                , plot model.countries model.percapita
                ]

        Initial ->
            div [ class "result" ] []


listCountries : List CountryData -> Html Msg
listCountries countrieslist =
    ul [] (List.map countryItem countrieslist)


countryItem : CountryData -> Html Msg
countryItem countrydata =
    span [ onClick (RemoveCountry countrydata.country), class "country-item" ] [ li [] [ text (countrydata.country ++ " x") ] ]


removeCountry : List CountryData -> String -> List CountryData
removeCountry oldlist countryname =
    List.filter (\countryData -> countryData.country /= countryname) oldlist



-- HTTP


getCountryList : Flags -> Cmd Msg
getCountryList flags =
    Http.get
        { url = flags.apiUrl ++ "countries/list/"
        , expect = Http.expectJson CountryListReceived countrylistDecoder
        }


countrylistDecoder : Decoder (List String)
countrylistDecoder =
    JD.list string


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



-- PLOT


plot : List CountryData -> Bool -> Html Msg
plot data percapita =
    div
        [ class "plot-container", onClick TogglePerCapita ]
        [ chart data percapita ]


chart : List CountryData -> Bool -> Html.Html msg
chart data percapita =
    LineChart.viewCustom
        { y =
            Axis.default 450
                "CO2"
                (if percapita then
                    .co2_per_capita

                 else
                    .co2_kilotons
                )
        , x = Axis.default 700 "Year" .year
        , container = Container.styled "line-chart-1" [ ( "font-family", "monospace" ) ]
        , interpolation = Interpolation.default
        , intersection = Intersection.default
        , legends = Legends.default
        , events = Events.default
        , junk = Junk.default
        , grid = Grid.default
        , area = Area.default
        , line = Line.default
        , dots = Dots.default
        }
        (List.map
            (\item -> LineChart.line (Tuple.second item) Dots.diamond (Tuple.first item).country (Tuple.first item).dataPoints)
            (colorTuple
                data
            )
        )


colorTuple : List CountryData -> List ( CountryData, Color )
colorTuple data =
    let
        colors =
            [ Colors.blue, Colors.red, Colors.green, Colors.gold, Colors.purple, Colors.pink ]
    in
    List.map2 Tuple.pair data colors
