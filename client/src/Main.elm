module Main exposing (addCountryData, addInitialData, countryDataDecoder, countryItem, filterEmptyDataPoints, getCountryListTask, getEmissionsbyCountryCmd, getEmissionsbyCountryTask, getInitialData, init, listCountries, main, plot, removeCountry, removeZeros, showResult, subscriptions, update, view)

import Array
import Browser
import Browser.Dom as Dom
import Color exposing (Color)
import Dropdown exposing (..)
import Html exposing (Attribute, Html, button, div, form, h1, h2, input, label, li, p, span, table, tbody, text, th, thead, tr, ul)
import Html.Attributes as Attrs exposing (..)
import Html.Events exposing (..)
import Http
import Http.Tasks exposing (..)
import Json.Decode as JD exposing (Decoder, field, float, int, string)
import List.Extra exposing (uniqueBy)
import Menu
import Model exposing (CountryData, Datapoint, Flags, InitialData, LoadingStatus(..), Model, Msg(..))
import Plot exposing (linechart)
import Task exposing (Task)



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
    ( { loaded = Initial
      , keyword = ""
      , envs = flags
      , countries = []
      , percapita = False
      , countrylist = []
      , hovered = []
      , autoState = Menu.empty
      , menuHowManyToShow = 5
      , selectedCountry = Nothing
      , showMenu = False
      }
    , getInitialData flags
    )


addInitialData : Model -> InitialData -> Model
addInitialData model initialdata =
    let
        countrylist =
            (\( x, y, z ) -> x) initialdata

        firstcountry =
            (\( x, y, z ) -> y) initialdata

        secondcountry =
            (\( x, y, z ) -> z) initialdata

        initialcountrydata =
            model.countries
                |> addCountryData firstcountry
                |> addCountryData secondcountry
    in
    { model | countrylist = countrylist, countries = initialcountrydata }



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        InitialDataReceived result ->
            case result of
                Ok output ->
                    ( addInitialData model output, Cmd.none )

                Err _ ->
                    ( { model | loaded = Failure }, Cmd.none )

        SearchAndAdd ->
            if String.length model.keyword > 0 then
                ( { model | loaded = Loading }, getEmissionsbyCountryCmd model.keyword model.envs )

            else
                ( model, Cmd.none )

        KeyDown key ->
            if key == 13 && String.length model.keyword > 0 then
                ( { model | loaded = Loading }, getEmissionsbyCountryCmd model.keyword model.envs )

            else
                ( model, Cmd.none )

        ResultReceived result ->
            case result of
                Ok output ->
                    ( { model | loaded = Success output, countries = addCountryData output model.countries, keyword = "" }, Cmd.none )

                Err _ ->
                    ( { model | loaded = Failure }, Cmd.none )

        PreviewCountry id ->
            ( { model | selectedCountry = Just (getCountryAtId model.countrylist id) }, Cmd.none )

        RemoveCountry countryname ->
            ( { model | countries = removeCountry model.countries countryname }, Cmd.none )

        TogglePerCapita ->
            ( { model | percapita = not model.percapita }, Cmd.none )

        SelectCountryKeyboard id ->
            let
                newModel =
                    setQuery model id
                        |> resetInput
            in
            ( newModel, getEmissionsbyCountryCmd id model.envs )

        SelectCountryMouse id ->
            let
                newModel =
                    setQuery model id
                        |> resetInput
            in
            ( newModel, getEmissionsbyCountryCmd id model.envs )

        SetAutoState autoMsg ->
            let
                ( newState, maybeMsg ) =
                    Menu.update updateConfig
                        autoMsg
                        model.menuHowManyToShow
                        model.autoState
                        (acceptableCountries model.keyword model.countrylist)

                newModel =
                    { model | autoState = newState }
            in
            maybeMsg
                |> Maybe.map (\updateMsg -> update updateMsg newModel)
                |> Maybe.withDefault ( newModel, Cmd.none )

        Reset ->
            ( { model
                | autoState = Menu.reset updateConfig model.autoState
                , selectedCountry = Nothing
              }
            , Cmd.none
            )

        SetQuery newQuery ->
            let
                newMenuState =
                    Menu.resetToFirstItem updateConfig (acceptableCountries newQuery model.countrylist) model.menuHowManyToShow model.autoState

                showMenu =
                    not (List.isEmpty (acceptableCountries newQuery model.countrylist))
            in
            ( { model
                | keyword = newQuery
                , autoState = newMenuState
                , showMenu = showMenu
                , selectedCountry = Nothing
              }
            , Cmd.none
            )

        Wrap toTop ->
            case model.selectedCountry of
                Just country ->
                    update Reset model

                Nothing ->
                    if toTop then
                        ( { model
                            | autoState =
                                Menu.resetToLastItem updateConfig
                                    (acceptableCountries model.keyword model.countrylist)
                                    model.menuHowManyToShow
                                    model.autoState
                            , selectedCountry =
                                acceptableCountries model.keyword model.countrylist
                                    |> List.take model.menuHowManyToShow
                                    |> List.reverse
                                    |> List.head
                          }
                        , Cmd.none
                        )

                    else
                        ( { model
                            | autoState =
                                Menu.resetToFirstItem updateConfig
                                    (acceptableCountries model.keyword model.countrylist)
                                    model.menuHowManyToShow
                                    model.autoState
                            , selectedCountry =
                                acceptableCountries model.keyword model.countrylist
                                    |> List.take model.menuHowManyToShow
                                    |> List.head
                          }
                        , Cmd.none
                        )

        HandleEscape ->
            let
                validOptions =
                    not (List.isEmpty (acceptableCountries model.keyword model.countrylist))

                handleEscape =
                    if validOptions then
                        model
                            |> removeSelection
                            |> resetMenu

                    else
                        resetInput model

                escapedModel =
                    case model.selectedCountry of
                        Just country ->
                            if model.keyword == country then
                                resetInput model

                            else
                                handleEscape

                        Nothing ->
                            handleEscape
            in
            ( escapedModel, Cmd.none )

        OnFocus ->
            ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


addCountryData : CountryData -> List CountryData -> List CountryData
addCountryData countrydataitem oldList =
    List.Extra.uniqueBy .country (oldList ++ [ filterEmptyDataPoints countrydataitem ])


filterEmptyDataPoints : CountryData -> CountryData
filterEmptyDataPoints country =
    { country | dataPoints = removeZeros country.dataPoints }


removeZeros : List Datapoint -> List Datapoint
removeZeros oldList =
    List.filter (\item -> item.co2_kilotons > 0) oldList



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map SetAutoState Menu.subscription



-- VIEW


view : Model -> Html Msg
view model =
    let
        mainTitle =
            "CO" ++ String.fromChar (Char.fromCode 8322) ++ " EMISSIONS"
    in
    div [ class "root" ]
        [ div [ class "main-wrap", onClick HandleEscape ]
            [ div [ class "left-column" ]
                [ h1 [ class "title" ] [ text mainTitle ]
                , div [ class "infocontainer" ]
                    [ p [ class "info" ] [ text "When talking about climate change, some people say that small countries like Finland don't matter when comparing to giants like India or China.\n                    And if you only look at absolute values that does make sense. However, emissions per capita tell a totally different story. Click the graph and see for yourself." ]
                    , p [ class "info" ] [ text "Explore other countries' CO2-emissions by adding them to the input." ]
                    , p [ class "info clicktheplot" ] [ text "Click the plot to switch between absolute (kilotons) and per capita values (metric tons)" ]
                    ]
                ]
            , div [ class "right-column" ]
                [ div [ class "searchAndCountryList" ]
                    [ h2 [] [ text "Add countries" ]
                    , div [ class "search" ]
                        [ div [ class "searchbar" ]
                            [ searchView model
                            ]
                        ]
                    , div [ class "countrylist" ]
                        [ listCountries model.countries
                        ]
                    ]
                , showResult model
                ]
            ]
        ]


showResult : Model -> Html Msg
showResult model =
    case model.loaded of
        Failure ->
            div [ class "result griditem" ]
                [ text "Country not found"
                , plot model
                ]

        Loading ->
            div [ class "result griditem" ] [ text "Loading...", plot model ]

        Success output ->
            div
                [ class "result griditem" ]
                [ plot model
                ]

        Initial ->
            div
                [ class "result griditem" ]
                [ plot model
                ]


plot : Model -> Html Msg
plot model =
    div
        [ class "plot-container", id "plot-container", onClick TogglePerCapita ]
        [ linechart model
        ]


listCountries : List CountryData -> Html Msg
listCountries countrieslist =
    ul [ class "country-list" ] (List.map countryItem countrieslist)


countryItem : CountryData -> Html Msg
countryItem countrydata =
    let
        deleteChar =
            String.fromChar (Char.fromCode 10005)
    in
    span [ onClick (RemoveCountry countrydata.country), class "country-item" ] [ li [] [ text (countrydata.country ++ " " ++ deleteChar) ] ]


removeCountry : List CountryData -> String -> List CountryData
removeCountry oldlist countryname =
    List.filter (\countryData -> countryData.country /= countryname) oldlist


getInitialData : Flags -> Cmd Msg
getInitialData flags =
    let
        listcountries =
            getCountryListTask flags

        firstcountry =
            getEmissionsbyCountryTask "Finland" flags

        secondcountry =
            getEmissionsbyCountryTask "India" flags
    in
    Task.map3 (\x y z -> ( x, y, z )) listcountries firstcountry secondcountry
        |> Task.attempt InitialDataReceived


getCountryListTask : Flags -> Task Http.Error (List String)
getCountryListTask flags =
    get
        { url = flags.apiUrl ++ "countries/"
        , resolver = resolveJson (JD.list string)
        }


getEmissionsbyCountryTask : String -> Flags -> Task Http.Error CountryData
getEmissionsbyCountryTask keyword flags =
    get
        { url = flags.apiUrl ++ "countries/" ++ keyword
        , resolver = resolveJson countryDataDecoder
        }


getEmissionsbyCountryCmd : String -> Flags -> Cmd Msg
getEmissionsbyCountryCmd keyword flags =
    getEmissionsbyCountryTask keyword flags
        |> Task.attempt ResultReceived


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
