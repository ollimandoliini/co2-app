module Model exposing (CountryData, Datapoint, Flags, LoadingStatus(..), Model)

import Http exposing (Error)
import Json.Decode as JD exposing (Decoder, field, float, int, string)
import Menu


type alias Model =
    { loaded : LoadingStatus
    , query : String
    , envs : Flags
    , countries : List CountryData
    , percapita : Bool
    , countryList : List CountryName
    , autoState : Menu.State
    , showMenu : Bool
    , selectedCountry : Maybe String
    , howManyToShow : Int
    }


type alias CountryName =
    { name : String }


type alias Flags =
    { apiUrl : String, environment : String }


type LoadingStatus
    = Failure
    | Loading
    | Success CountryData
    | Initial


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
