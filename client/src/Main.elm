module Main exposing (Msg(..), countryDataDecoder, getEmissionsbyCountry, init, main, showResult, subscriptions, update, view)

import Array
import Browser
import Color exposing (Color)
import Debug exposing (log)
import Html exposing (Attribute, Html, button, div, form, h1, img, input, label, li, span, table, tbody, text, th, thead, tr, ul)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as JD exposing (Decoder, field, float, int, string)
import Menu
import Model exposing (..)
import Plot exposing (linechart)



-- MAIN


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { loaded = Initial, keyword = "", envs = flags, countries = [], percapita = False, countrylist = [] }, Cmd.batch [ getEmissionsbyCountry "Finland" flags, getCountryList flags ] )



-- UPDATE


type Msg
    = CountryListReceived (Result Http.Error (List String))
    | Change String
    | KeyDown Int
    | SearchAndAdd
    | ResultReceived (Result Http.Error CountryData)
    | RemoveCountry String
    | TogglePerCapita


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CountryListReceived result ->
            case result of
                Ok output ->
                    ( { model | countrylist = output }, Cmd.none )

                Err _ ->
                    ( model, Cmd.none )

        Change newContent ->
            ( { model | keyword = newContent }, Cmd.none )

        SearchAndAdd ->
            ( { model | loaded = Loading }, getEmissionsbyCountry model.keyword model.envs )

        KeyDown key ->
            if key == 13 then
                ( { model | loaded = Loading }, getEmissionsbyCountry model.keyword model.envs )

            else
                ( model, Cmd.none )

        ResultReceived result ->
            case result of
                Ok output ->
                    ( { model | loaded = Success output, countries = addCountryData model.countries output, keyword = "" }, Cmd.none )

                Err _ ->
                    ( { model | loaded = Failure }, Cmd.none )

        RemoveCountry countryname ->
            ( { model | countries = removeCountry model.countries countryname }, Cmd.none )

        TogglePerCapita ->
            ( { model | percapita = not model.percapita }, Cmd.none )


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
        , div [ class "search" ]
            [ input [ class "searchField", placeholder "Finland", onKeyDown KeyDown, onInput Change, value model.keyword ] []
            , button [ class "searchButton", onClick SearchAndAdd ] [ text "Add" ]
            , listCountries model.countries
            ]
        , showResult model
        ]


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (JD.map tagger keyCode)


showResult : Model -> Html Msg
showResult model =
    case model.loaded of
        Failure ->
            div [ class "result" ]
                [ text "Country not found"
                , plot model.countries model.percapita
                ]

        Loading ->
            div [ class "result" ] [ text "Loading..." ]

        Success output ->
            div
                [ class "result" ]
                [ plot model.countries model.percapita
                ]

        Initial ->
            div [ class "result" ] []


plot : List CountryData -> Bool -> Html Msg
plot data percapita =
    div
        [ class "plot-container", onClick TogglePerCapita ]
        [ linechart data percapita ]


listCountries : List CountryData -> Html Msg
listCountries countrieslist =
    ul [ class "country-list" ] (List.map countryItem countrieslist)


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
        , expect = Http.expectJson CountryListReceived (JD.list string)
        }


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
    <|
        JD.field "dataPoints" <|
            JD.list <|
                JD.map4 Datapoint
                    (JD.field "year" float)
                    (JD.field "co2_kilotons" float)
                    (JD.field "population" int)
                    (JD.field "co2_per_capita" float)
