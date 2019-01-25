module Main exposing (acceptableCountries, addCountryData, countryDataDecoder, countryItem, filterEmptyDataPoints, getCountryAtId, getCountryListTask, getEmissionsbyCountryCmd, getEmissionsbyCountryTask, getInitialData, init, listCountries, main, onKeyDown, plot, removeCountry, removeSelection, removeZeros, resetMenu, searchView, setQuery, showResult, subscriptions, update, updateConfig, view, viewConfig, viewMenu)

import Array
import Browser
import Browser.Dom as Dom
import Color exposing (Color)
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



-- UPDATE


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


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    -- case Debug.log "message" msg of
    case msg of
        InitialDataReceived result ->
            case result of
                Ok output ->
                    ( addInitialData model output, Cmd.none )

                Err _ ->
                    ( { model | loaded = Failure }, Cmd.none )

        Change newContent ->
            let
                showMenu =
                    not (List.isEmpty (acceptableCountries model.keyword model.countrylist)) && String.length newContent > 0
            in
            ( { model | keyword = newContent, showMenu = showMenu }, Cmd.none )

        SearchAndAdd ->
            if String.length model.keyword > 0 then
                ( { model | loaded = Loading }, getEmissionsbyCountryCmd model.keyword model.envs )

            else
                ( model, Cmd.none )

        -- KeyDown key ->
        --     if key == 13 && String.length model.keyword > 0 then
        --         ( { model | loaded = Loading }, getEmissionsbyCountryCmd model.keyword model.envs )
        --     else
        --         ( model, Cmd.none )
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
            in
            ( newModel, getEmissionsbyCountryCmd id model.envs )

        SelectCountryMouse id ->
            let
                newModel =
                    setQuery model id
                        |> resetMenu
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
                showMenu =
                    not (List.isEmpty (acceptableCountries newQuery model.countrylist))
            in
            ( { model
                | keyword = newQuery
                , showMenu = showMenu
                , selectedCountry = Nothing
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


resetInput model =
    { model | keyword = "" }
        |> removeSelection
        |> resetMenu


removeSelection model =
    { model | selectedCountry = Nothing }


resetMenu model =
    { model
        | autoState = Menu.empty
        , keyword = ""
        , showMenu = False
    }


getCountryAtId countrylist id =
    List.filter (\country -> country == id) countrylist
        |> List.head
        |> Maybe.withDefault ""


setQuery : Model -> String -> Model
setQuery model id =
    { model
        | keyword = getCountryAtId model.countrylist id
        , selectedCountry = Just (getCountryAtId model.countrylist id)
    }


acceptableCountries : String -> List String -> List String
acceptableCountries keyword countrylist =
    let
        lowerQuery =
            String.toLower keyword
    in
    List.filter (String.contains lowerQuery << String.toLower) countrylist


updateConfig : Menu.UpdateConfig Msg String
updateConfig =
    Menu.updateConfig
        { toId = identity
        , onKeyDown =
            \code maybeId ->
                if code == 38 || code == 40 then
                    Maybe.map PreviewCountry maybeId

                else if code == 13 then
                    Maybe.map SelectCountryKeyboard maybeId

                else
                    Just Reset
        , onTooLow = Nothing
        , onTooHigh = Nothing
        , onMouseEnter = \id -> Just (PreviewCountry id)
        , onMouseLeave = \_ -> Nothing
        , onMouseClick = \id -> Just (SelectCountryMouse id)
        , separateSelections = False
        }


viewConfig : Menu.ViewConfig String
viewConfig =
    let
        customizedLi keySelected mouseSelected countryname =
            { attributes = [ classList [ ( "autocomplete-item", True ), ( "is-selected", keySelected || mouseSelected ) ] ]
            , children = [ Html.text countryname ]
            }
    in
    Menu.viewConfig
        { toId = identity
        , ul = [ class "autocomplete-list" ]
        , li = customizedLi
        }


addCountryData : CountryData -> List CountryData -> List CountryData
addCountryData countrydataitem oldList =
    List.Extra.uniqueBy .country (oldList ++ [ filterEmptyDataPoints countrydataitem ])



-- oldList
--     |> List.append [ filterEmptyDataPoints countrydataitem ]
--     |> List.Extra.uniqueBy .country


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
    div [ class "main-wrap" ]
        [ div [ class "titleAndText griditem" ]
            [ h1 [ class "title" ] [ text mainTitle ]
            , div [ class "" ]
                [ p [ class "info" ] [ text "Explore carbon dioxide emissions by country in absolute and per capita values." ]
                , p [ class "info" ] [ text "Add countries by entering them into the input below." ]
                ]
            ]
        , div [ class "searchAndCountryList griditem" ]
            [ h2 [] [ text "Add countries" ]
            , div [ class "search" ]
                [ div [ class "searchbar" ]
                    [ searchView model
                    ]
                , listCountries model.countries
                ]
            ]
        , showResult model
        ]


searchView : Model -> Html Msg
searchView model =
    let
        menu =
            if model.showMenu then
                viewMenu model

            else
                Html.text ""

        query =
            model.selectedCountry
                |> Maybe.map identity
                |> Maybe.withDefault model.keyword

        activeDescendant attributes =
            model.selectedCountry
                |> Maybe.map identity
                |> Maybe.map (Attrs.attribute "aria-activedescendant")
                |> Maybe.map (\attribute -> attribute :: attributes)
                |> Maybe.withDefault attributes

        upDownEscDecoderHelper : Int -> Decoder Msg
        upDownEscDecoderHelper code =
            if code == 38 || code == 40 then
                JD.succeed NoOp

            else if code == 27 then
                JD.succeed HandleEscape

            else
                JD.fail "not handling that key"

        upDownEscDecoder : Decoder ( Msg, Bool )
        upDownEscDecoder =
            Html.Events.keyCode
                |> JD.andThen upDownEscDecoderHelper
                |> JD.map (\msg -> ( msg, True ))
    in
    div []
        (List.append
            [ Html.input
                (activeDescendant
                    [ Html.Events.onInput SetQuery
                    , Html.Events.onFocus OnFocus
                    , Html.Events.preventDefaultOn "keydown" upDownEscDecoder
                    , Attrs.value query
                    , Attrs.class "searchField"
                    , Attrs.autocomplete False
                    , Attrs.attribute "aria-owns" "list-of-countries"
                    , Attrs.attribute "aria-expanded" (boolToString model.showMenu)
                    , Attrs.attribute "aria-haspopup" (boolToString model.showMenu)
                    , Attrs.attribute "role" "combobox"
                    , Attrs.attribute "aria-autocomplete" "list"
                    ]
                )
                []
            ]
            [ menu
            , button [ class "searchButton", onClick SearchAndAdd ] [ text "Add" ]
            ]
        )


boolToString : Bool -> String
boolToString bool =
    case bool of
        True ->
            "true"

        False ->
            "false"


viewMenu : Model -> Html Msg
viewMenu model =
    Html.map SetAutoState (Menu.view viewConfig model.menuHowManyToShow model.autoState (acceptableCountries model.keyword model.countrylist))


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
            div
                [ class "result griditem" ]
                [ plot model
                ]


plot : Model -> Html Msg
plot model =
    div
        [ class "plot-container", onClick TogglePerCapita ]
        [ linechart model
        , div [ class "clickinfo" ] [ text "Click the plot to switch between absolute and per capita values" ]
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


getCountryListTask : Flags -> Task Http.Error (List String)
getCountryListTask flags =
    get
        { url = flags.apiUrl ++ "countries/"
        , resolver = resolveJson (JD.list string)
        }


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
