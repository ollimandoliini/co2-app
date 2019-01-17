module Models exposing (CountryData, Datapoint)


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
