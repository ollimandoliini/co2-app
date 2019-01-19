module Main exposing (Model, Msg(..), acceptablePeople, update, updateConfig, view, viewConfig)

import Html exposing (Msg)
import Menu


type CountryName
    = String


type alias Model =
    { autoState : Menu.State -- Own the State of the menu in your model
    , query : String -- Perhaps you want to filter by a string?
    , country : List CountryName -- The data you want to list and filter
    }



-- Let's filter the data however we want


acceptablePeople : String -> List String -> List String
acceptablePeople query people =
    let
        lowerQuery =
            String.toLower query
    in
    List.filter (String.contains lowerQuery << String.toLower << .name) people



-- Set up what will happen with your menu updates


updateConfig : Menu.UpdateConfig Msg CountryName
updateConfig =
    Menu.updateConfig
        { toId = .name
        , onKeyDown =
            \code maybeId ->
                if code == 13 then
                    Maybe.map SelectCountryName maybeId

                else
                    Nothing
        , onTooLow = Nothing
        , onTooHigh = Nothing
        , onMouseEnter = \_ -> Nothing
        , onMouseLeave = \_ -> Nothing
        , onMouseClick = \id -> Just <| SelectCountryName id
        , separateSelections = False
        }


type Msg
    = SetAutocompleteState Menu.Msg


update : Msg -> Model -> Model
update msg { autoState, query, people, howManyToShow } =
    case msg of
        SetAutocompleteState autoMsg ->
            let
                ( newState, maybeMsg ) =
                    Menu.update updateConfig autoMsg howManyToShow autoState (acceptablePeople query people)
            in
            { model | autoState = newState }



-- setup for your autocomplete view


viewConfig : Menu.ViewConfig CountryName
viewConfig =
    let
        customizedLi keySelected mouseSelected person =
            { attributes = [ classList [ ( "autocomplete-item", True ), ( "is-selected", keySelected || mouseSelected ) ] ]
            , children = [ Html.text person.name ]
            }
    in
    Menu.viewConfig
        { toId = .name
        , ul = [ class "autocomplete-list" ] -- set classes for your list
        , li = customizedLi -- given selection states and a person, create some Html!
        }



-- and let's show it! (See an example for the full code snippet)


autoCompleteInput : Model -> Html Msg
autoCompleteInput { autoState, query, people } =
    div []
        [ input [ onInput SetQuery ] []
        , Html.App.map SetAutocompleteState (Menu.view viewConfig 5 autoState (acceptablePeople query people))
        ]
