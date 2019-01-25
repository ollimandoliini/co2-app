module Plot exposing (colorTuple, linechart)

import Color exposing (Color)
import Html
import Html.Attributes
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
import Model exposing (..)


linechart : Model -> Html.Html msg
linechart model =
    LineChart.viewCustom
        { y =
            Axis.default 400
                "CO2"
                (if model.percapita then
                    .co2_per_capita

                 else
                    .co2_kilotons
                )
        , x = Axis.default 650 "Year" .year
        , container = containerConfig
        , interpolation = Interpolation.default
        , intersection = Intersection.default
        , legends = Legends.default
        , events = Events.default
        , junk = Junk.default
        , grid = Grid.default
        , area = Area.default
        , line = Line.default
        , dots = Dots.custom (Dots.full 2)
        }
        (List.map
            (\item -> LineChart.line (Tuple.second item) Dots.circle (Tuple.first item).country (Tuple.first item).dataPoints)
            (colorTuple
                model.countries
            )
        )


containerConfig : Container.Config msg
containerConfig =
    Container.custom
        { attributesHtml = []
        , attributesSvg = []
        , size = Container.relative
        , margin = Container.Margin 20 110 20 75
        , id = "line-chart-area"
        }


colorTuple : List CountryData -> List ( CountryData, Color )
colorTuple data =
    let
        colors =
            [ Color.blue, Colors.green, Colors.red, Colors.gold, Colors.purple, Colors.pink ]
    in
    List.map2 Tuple.pair data colors
