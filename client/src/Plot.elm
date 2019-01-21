module Plot exposing (colorTuple, linechart)

import Color exposing (Color)
import Html exposing (Html)
import LineChart
import LineChart.Area as Area
import LineChart.Axis as Axis
import LineChart.Axis.Intersection as Intersection
import LineChart.Colors as Colors
import LineChart.Container as Container
import LineChart.Dots as Dots
import LineChart.Events as Events
import LineChart.Grid as Grid
import LineChart.Interpolation as Interpolation
import LineChart.Junk as Junk exposing (..)
import LineChart.Legends as Legends
import LineChart.Line as Line
import Models exposing (CountryData, Model)


linechart : List CountryData -> Bool -> Html.Html msg
linechart data percapita =
    LineChart.viewCustom
        { y =
            Axis.default 400
                "CO2"
                (if percapita then
                    .co2_per_capita

                 else
                    .co2_kilotons
                )
        , x = Axis.default 650 "Year" .year

        -- , container = Container.styled "line-chart-1" [ ( "font-family", "Helvetica" ) ]
        , container = Container.responsive "line-chart-1"
        , interpolation = Interpolation.default
        , intersection = Intersection.default
        , legends = Legends.default
        , events = Events.default
        , junk = Junk.default
        , grid = Grid.default
        , area = Area.default
        , line = Line.default
        , dots = Dots.default
        }
        (List.map
            (\item -> LineChart.line (Tuple.second item) Dots.diamond (Tuple.first item).country (Tuple.first item).dataPoints)
            (colorTuple
                data
            )
        )


colorTuple : List CountryData -> List ( CountryData, Color )
colorTuple data =
    let
        colors =
            [ Colors.blue, Colors.green, Colors.red, Colors.gold, Colors.purple, Colors.pink ]
    in
    List.map2 Tuple.pair data colors
