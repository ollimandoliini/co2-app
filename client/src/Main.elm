import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode exposing (Decoder, field, string)

-- MAIN


main =
  Browser.element
    { init = init
    , update = update
    , subscriptions = subscriptions
    , view = view
    }

-- MODEL

type Model
  = Failure
  | Loading
  | Success String

type alias CountryData =
  { country : String
  }

init : () -> (Model, Cmd Msg)
init _ =
  (Loading, getEmissionsbyCountry "")


-- UPDATE

type Msg
  = Search
  | Change
  | ResultReceived (Result Http.Error String)


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Search ->
      (Loading, getEmissionsbyCountry "moro")

    ResultReceived result ->
      case result of
        Ok output ->
          (Success output, Cmd.none)

        Err _ ->
          (Failure, Cmd.none)
    
    Change newContent ->
      { model | country = newContent }

-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

-- VIEW

view : Model -> Html Msg
view model =
  div []
    [ h2 [ class "title"] [ text "CO2-emissions" ]
    , input [ placeholder "Search by country", value model.content, onInput Change ] []
    , button [onClick Search] [text "Search"]
    , showData model
    ]


showData : Model -> Html Msg
showData model =
  case model of
    Failure ->
      div [] []

    Loading ->
      text "Loading..."

    Success output ->
      div []
        [text output
        ]

-- HTTP

getEmissionsbyCountry : String -> Cmd Msg
getEmissionsbyCountry keyword =
  Http.get
    { url = "http://127.0.0.1:5000/" ++ keyword
    , expect = Http.expectJson ResultReceived responseDecoder
    }

responseDecoder : Decoder String
responseDecoder =
  field "result" string
