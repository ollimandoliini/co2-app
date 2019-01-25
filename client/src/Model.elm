module Model exposing (CountryData, Datapoint, Flags, InitialData, LoadingStatus(..), Model, Msg(..))

import Http exposing (Error)
import Json.Decode as JD exposing (Decoder, field, float, int, string)
import Menu


type Msg
    = InitialDataReceived (Result Http.Error InitialData)
    | Change String
    | KeyDown Int
    | SearchAndAdd
    | ResultReceived (Result Http.Error CountryData)
    | RemoveCountry String
    | TogglePerCapita
    | SelectCountryKeyboard String
    | SelectCountryMouse String
    | SetAutoState Menu.Msg
    | PreviewCountry String
    | OnFocus
    | SetQuery String
    | HandleEscape
    | Reset
    | NoOp


type alias InitialData =
    ( List String, CountryData, CountryData )


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
    , hovered : List String
    , autoState : Menu.State
    , menuHowManyToShow : Int
    , selectedCountry : Maybe String
    , showMenu : Bool
    }


type alias CountryData =
    { country : String
    , dataPoints : List Datapoint
    }


type alias Datapoint =
    { year : Float
    , co2_kilotons : Float
    , population : Int
    , co2_per_capita : Float
    }
