module Models exposing (Datapoint, Response)


type alias Datapoint =
    { year : Float
    , co2_kilotons : Float
    , population : Int
    , co2_per_capita : Float
    }


type alias Response =
    { country : String
    , dataPoints : List Datapoint
    }
