module Main exposing (countryDataDecoder, getEmissionsbyCountry, init, main, showResult, subscriptions, update, view)

import Array
import Browser
import Color exposing (Color)
import Html exposing (Attribute, Html, button, div, form, h1, h2, input, label, li, p, span, table, tbody, text, th, thead, tr, ul)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as JD exposing (Decoder, field, float, int, string)
import List.Extra exposing (uniqueBy)
import Menu
import Model exposing (CountryData, Datapoint, Flags, LoadingStatus(..), Model, Msg(..))
import Plot exposing (linechart)



-- MAIN


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- ss
-- MODEL


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { loaded = Initial
      , keyword = ""
      , envs = flags
      , countries = []
      , percapita = False
      , countrylist = []
      , hovered = []
      }
    , Cmd.batch [ getEmissionsbyCountry "Finland" flags, getEmissionsbyCountry "India" flags, getCountryList flags ]
    )



-- UPDATE


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
            if String.length model.keyword > 0 then
                ( { model | loaded = Loading }, getEmissionsbyCountry model.keyword model.envs )

            else
                ( model, Cmd.none )

        KeyDown key ->
            if key == 13 && String.length model.keyword > 0 then
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



-- Hover ->
--     ( logsomething model, Cmd.none )


logsomething model =
    let
        _ =
            Debug.log "moro"
    in
    model


addCountryData : List CountryData -> CountryData -> List CountryData
addCountryData oldList countrydataitem =
    oldList
        |> List.append [ filterEmptyDataPoints countrydataitem ]
        |> List.Extra.uniqueBy .country


filterEmptyDataPoints : CountryData -> CountryData
filterEmptyDataPoints country =
    { country | dataPoints = removeZeros country.dataPoints }


removeZeros : List Datapoint -> List Datapoint
removeZeros oldList =
    List.filter (\item -> item.co2_kilotons > 0) oldList



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "main-wrap" ]
        [ div [ class "titleAndText griditem" ]
            [ h1 [ class "title" ] [ text "Carbon dioxide emissions" ]
            , div [ class "" ]
                [ p [] [ text "Explore carbon dioxide emissions by country in absolute and per capita values." ]
                , p [] [ text "Add countries by entering them into the input below." ]
                ]
            ]
        , div [ class "searchAndCountryList griditem" ]
            [ h2 [] [ text "Add countries" ]
            , div [ class "search" ]
                [ div [ class "searchbar" ]
                    [ input [ class "searchField", placeholder "e.g.  Finland", onKeyDown KeyDown, onInput Change, value model.keyword ] []
                    , button [ class "searchButton", onClick SearchAndAdd ] [ text "Add" ]
                    ]
                , listCountries model.countries
                ]
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
            div [ class "result griditem" ]
                [ text "Country not found"
                , plot model
                ]

        Loading ->
            div [ class "result griditem" ] [ text "Loading..." ]

        Success output ->
            div
                [ class "result griditem" ]
                [ plot model
                ]

        Initial ->
            div [ class "result griditem" ] []


plot : Model -> Html Msg
plot model =
    div
        [ class "plot-container", onClick TogglePerCapita ]
        [ linechart model
        , div [] [ text "Click the plot to switch between absolute and per capita values" ]
        ]


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
        (JD.field "dataPoints"
            (JD.list
                (JD.map4
                    Datapoint
                    (JD.field "year" float)
                    (JD.field "co2_kilotons" float)
                    (JD.field "population" int)
                    (JD.field "co2_per_capita" float)
                )
            )
        )
