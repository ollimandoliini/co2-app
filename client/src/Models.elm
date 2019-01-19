module Models exposing (CountryData, Datapoint, Flags, LoadingStatus(..), Model, Msg(..))

import Http exposing (Error)
import Json.Decode as JD exposing (Decoder, field, float, int, string)


type Msg
    = SearchAndAdd
    | Change String
    | ResultReceived (Result Http.Error CountryData)
    | CountryListReceived (Result Http.Error (List String))
    | RemoveCountry String
    | TogglePerCapita
    | KeyDown Int


type alias Model =
    { loaded : LoadingStatus
    , keyword : String
    , envs : Flags
    , countries : List CountryData
    , percapita : Bool
    , countrylist : List String
    }


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