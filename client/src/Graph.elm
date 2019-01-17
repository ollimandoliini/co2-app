module Graph exposing (plot)

import Html
import Html.Attributes exposing (class)
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
import Models exposing (CountryData, Datapoint)


plot : List CountryData -> Html.Html msg
plot data =
    Html.div
        [ class "container" ]
        [ chart data ]


chart : List CountryData -> Html.Html msg
chart data =
    LineChart.viewCustom
        { y = Axis.default 450 "CO2" .co2_per_capita
        , x = Axis.default 700 "Year" .year
        , container = Container.styled "line-chart-1" [ ( "font-family", "monospace" ) ]
        , interpolation = Interpolation.default
        , intersection = Intersection.default
        , legends = Legends.default
        , events = Events.default
        , junk = Junk.default
        , grid = Grid.default
        , area = Area.default
        , line = Line.default
        , dots = Dots.default

        -- Try out these different configs!
        -- Dots.default
        -- Dots.custom (Dots.full 10)
        --
        -- Dots.custom (Dots.empty 10 1)
        -- customConfig
        -- For making the dots change based on whether it's hovered, see Events.elm!
        }
        (List.map
            (\item -> LineChart.line Colors.red Dots.diamond item.country item.dataPoints)
            data
        )



-- customConfig : Dots.Config Info
-- customConfig =
--     let
--         style size =
--             Dots.full size
--         getSize datum =
--             (datum.height - 1) * 12
--     in
--     Dots.customAny
--         { legend = \_ -> style 7
--         , individual = \datum -> style (getSize datum)
--         }
-- DATA


type alias Info =
    { age : Float
    , weight : Float
    }


alice : List Info
alice =
    [ Info 10 34
    , Info 16 42
    , Info 25 75
    , Info 43 83
    ]


bobby : List Info
bobby =
    [ Info 10 38
    , Info 17 69
    , Info 25 78
    , Info 43 77
    ]


chuck : List Info
chuck =
    [ Info 10 42
    , Info 15 72
    , Info 25 89
    , Info 43 95
    ]
