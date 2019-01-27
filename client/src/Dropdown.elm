module Dropdown exposing (acceptableCountries, boolToString, getCountryAtId, removeSelection, resetInput, resetMenu, searchView, setQuery, updateConfig, viewConfig, viewMenu)

import Html exposing (Attribute, Html, button, div, text)
import Html.Attributes as Attrs exposing (..)
import Html.Events exposing (..)
import Json.Decode as JD exposing (Decoder)
import Menu
import Model exposing (Model, Msg(..))


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
        , onMouseEnter = \_ -> Nothing
        , onMouseLeave = \_ -> Nothing
        , onMouseClick = \id -> Just (SelectCountryMouse id)
        , separateSelections = False
        }


viewConfig : Menu.ViewConfig String
viewConfig =
    let
        customizedLi keySelected mouseSelected countryname =
            { attributes =
                [ Attrs.classList
                    [ ( "autocomplete-item", True )
                    , ( "key-selected", keySelected || mouseSelected )
                    ]
                , Attrs.id countryname
                ]
            , children = [ Html.text countryname ]
            }
    in
    Menu.viewConfig
        { toId = identity
        , ul = [ Attrs.class "autocomplete-list" ]
        , li = customizedLi
        }


onKeyDown : (Int -> msg) -> Attribute msg
onKeyDown tagger =
    on "keydown" (JD.map tagger keyCode)


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
    }


acceptableCountries : String -> List String -> List String
acceptableCountries keyword countrylist =
    let
        lowerQuery =
            String.toLower keyword
    in
    List.filter (String.contains lowerQuery << String.toLower) countrylist


boolToString : Bool -> String
boolToString bool =
    case bool of
        True ->
            "true"

        False ->
            "false"


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
                    , Attrs.class "autocomplete-input"
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


viewMenu : Model -> Html Msg
viewMenu model =
    Html.map SetAutoState (Menu.view viewConfig model.menuHowManyToShow model.autoState (acceptableCountries model.keyword model.countrylist))
