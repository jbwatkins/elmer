module Elmer.TestApp exposing (..)

import Html exposing (Html, div, text, input, Attribute, li, ul, p, a)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, on, keyCode)
import Task exposing (Task)
import Json.Decode as Json exposing (..)
import Json.Encode as Encode
import Navigation
import Http

type Route
  = View
  | NotFound String

type alias Model =
  { name: String
  , activity: String
  , clicks: Int
  , numberFromTask: Int
  , numberTaskError: String
  , numberTaskGenerator: Task String Int
  , httpSend: (Result Http.Error String -> Msg) -> Http.Request String -> Cmd Msg
  , anotherHttpSend: (Result Http.Error String -> Msg) -> Http.Request String -> Cmd Msg
  , lastLetter : Int
  , route: Route
  , webServiceData: String
  , anotherWebServiceData: String
  }

defaultModel : Model
defaultModel =
  { name = "Brian"
  , activity = "reading"
  , clicks = 0
  , numberFromTask = -1
  , numberTaskError = "No error"
  , numberTaskGenerator = (makeNumberTaskThatSucceeds True)
  , httpSend = Http.send
  , anotherHttpSend = Http.send
  , lastLetter = -1
  , route = View
  , webServiceData = "Not Requested"
  , anotherWebServiceData = "Not Requested"
  }

onlyText : Html Msg
onlyText =
  text "Only Text"

type Msg
  = HandleClick
  | ClickForNumber
  | TaskNumber Int
  | HandleNumberTaskError String
  | HandleInput String
  | HandleKeyUp Int
  | HandleOtherInput String
  | NavigationClick
  | ModifyNavigationClick
  | ViewRoute
  | RouteNotFound String
  | RequestData
  | AnotherRequestData
  | CreateStuff
  | WebServiceResponse (Result Http.Error String)
  | AnotherWebServiceResponse (Result Http.Error String)
  | CreateStuffResponse (Result Http.Error String)

simpleView : Model -> Html Msg
simpleView model =
  div [ id "root" ] [ text "Some text" ]

textView : Model -> Html Msg
textView model =
  text "Some text"

view : Model -> Html Msg
view model =
  case model.route of
    NotFound message ->
      div [ id "root", class "error" ] [ text ("Route not found: " ++ message) ]
    View ->
      div [ id "root", class "content" ]
        [ div [ id "userNameLabel", class "label" ] []
        , div
          [ classList [ ("awesome", True), ("super", True), ("root", True) ] ]
          []
        , div [ class "withText" ]
          [ text "Some Fun Text"
          , div [ class "anotherWithText", attribute "data-special-node" "specialStuff" ]
            [ p [] [ text "my text" ]
            , p [ class "special", attribute "data-special-node" "differentSpecialStuff" ] [ text "special!" ]
            , p [ class "specialer", attribute "data-special-node" "moreSpecialStuff" ] [ text "more special!" ]
            , a [ id "fun-link", href "http://fun.com/fun.html" ] [ text "link to fun!" ]
            ]
          , text "Some more text"
          ]
        , input [ class "nameField", onInput HandleInput, onKeyUp HandleKeyUp ] []
        , div [ class "button", onClick HandleClick ] [ text "Click Me" ]
        , div [ id "clickCount" ] [ text ((toString model.clicks) ++ " clicks!") ]
        , div [ id "numberButton", onClick ClickForNumber ] [ text "Get a number!" ]
        , div [ id "numberOutput" ] [ text ("Clicked and got number: " ++ ((toString model.numberFromTask))) ]
        , div [ id "numberOutputError" ] [ text ("Got error requesting number: " ++ model.numberTaskError)]
        , div [ id "navigationClick", onClick NavigationClick ] [ text "Click to change the URL" ]
        , div [ id "modifyNavigationClick", onClick ModifyNavigationClick ] [ text "Click to modify the URL" ]
        , div [ id "webservice-data" ]
          [ div [ id "request-data-click", onClick RequestData ] [ text "Click me to request data!" ]
          , div [ id "data-result" ] [ text model.webServiceData ]
          ]
        , div [ id "another-webservice-data" ]
          [ div [ id "another-request-data-click", onClick AnotherRequestData ] [ text "Click me to request more data!" ]
          , div [ id "another-data-result" ] [ text model.anotherWebServiceData ]
          ]
        , div [ id "create-stuff" ]
          [ div [ id "create-stuff-click", onClick CreateStuff ] [ text "Click me to create stuff!" ]
          ]
        ]

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    HandleClick ->
      ( { model | clicks = model.clicks + 1 }, Cmd.none )
    HandleInput inputString ->
      ( { model | name = inputString }, Cmd.none )
    HandleOtherInput inputString ->
      ( { model | activity = inputString }, Cmd.none )
    ClickForNumber ->
      ( model, Task.attempt processNumberTaskResult model.numberTaskGenerator )
    TaskNumber number ->
      ( { model | numberFromTask = number }, Cmd.none )
    HandleNumberTaskError message ->
      ( { model | numberTaskError = message }, Cmd.none )
    HandleKeyUp key ->
      ( { model | lastLetter = key }, Cmd.none )
    NavigationClick ->
      ( model, Navigation.newUrl "http://fun.com/fun.html" )
    ModifyNavigationClick ->
      ( model, Navigation.modifyUrl "http://fun.com/evenMoreFun.html" )
    ViewRoute ->
      ( { model | route = View }, Cmd.none )
    RouteNotFound message ->
      ( { model | route = NotFound message }, Cmd.none )
    RequestData ->
      ( model, fetchData model )
    CreateStuff ->
      ( model, postData model )
    AnotherRequestData ->
      ( model, fetchMoreData model )
    WebServiceResponse (Ok name) ->
      ( { model | webServiceData = ("Name: " ++ name) }, Cmd.none )
    WebServiceResponse (Err (Http.BadPayload message response)) ->
      ( { model | webServiceData = ("BadPayload Error: " ++ message) }, Cmd.none )
    WebServiceResponse (Err (Http.BadStatus response)) ->
      ( { model | webServiceData = ("BadStatus Error: " ++ (toString response.status.code) ++ " " ++ response.status.message) }, Cmd.none )
    WebServiceResponse (Err Http.Timeout) ->
      ( { model | webServiceData = "Timeout Error" }, Cmd.none )
    WebServiceResponse (Err _) ->
      ( { model | webServiceData = "Error: Some unknown error" }, Cmd.none )
    AnotherWebServiceResponse (Ok data) ->
      ( { model | anotherWebServiceData = data }, Cmd.none )
    AnotherWebServiceResponse (Err _) ->
      ( { model | anotherWebServiceData = "Error" }, Cmd.none )
    CreateStuffResponse _ ->
      ( model, Cmd.none )

fetchData : Model -> Cmd Msg
fetchData model =
  model.httpSend WebServiceResponse (Http.get "http://fun.com/fun.html" webServiceDecoder)

fetchMoreData : Model -> Cmd Msg
fetchMoreData model =
  model.anotherHttpSend AnotherWebServiceResponse (Http.get "http://awesome.com/awesome.html" anotherWebServiceDecoder)

requestBody : Encode.Value
requestBody =
  Encode.object [ ("name", Encode.string "me") ]

postData : Model -> Cmd Msg
postData model =
  model.httpSend CreateStuffResponse (Http.post "http://fun.com/fun" (Http.jsonBody requestBody) webServiceDecoder)

webServiceDecoder : Json.Decoder String
webServiceDecoder =
  Json.field "name" Json.string

anotherWebServiceDecoder : Json.Decoder String
anotherWebServiceDecoder =
  Json.field "data" Json.string

parseLocation : Navigation.Location -> Msg
parseLocation location =
  if location.pathname == "/api/view" then
    ViewRoute
  else
    RouteNotFound ("Unknown path: " ++ location.pathname)

parseLocationFail : Navigation.Location -> Msg
parseLocationFail location =
  RouteNotFound "Unparseable url!"

onKeyUp : (Int -> msg) -> Attribute msg
onKeyUp tagger =
  on "keyup" (Json.map tagger keyCode)

makeNumberTaskThatSucceeds : Bool -> Task String Int
makeNumberTaskThatSucceeds shouldSucceed =
  if shouldSucceed then
    Task.succeed 3
  else
    Task.fail "Bad things happened!"

processNumberTaskResult : Result String Int -> Msg
processNumberTaskResult result =
  case result of
    Ok number ->
      TaskNumber number
    Err message ->
      HandleNumberTaskError message

eventView : Model -> Html Msg
eventView model =
  input [ id "nameLabel", classList [ ("nameField", True), ("awesome", True) ], onInput HandleInput ] [ text "Click Me" ]
