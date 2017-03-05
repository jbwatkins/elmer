module Elmer.MouseEventTests exposing (all)

import Test exposing (..)
import Elmer.TestApps.MouseTestApp as App
import Elmer.EventTests as EventTests
import Expect
import Elmer
import Elmer.Internal exposing (..)
import Elmer.Html.Event as Event
import Elmer.Platform.Command as Command
import Elmer.Html as Markup

all : Test
all =
  describe "Event Tests"
    [ clickTests
    , doubleClickTests
    , mouseDownTests
    , mouseUpTests
    , mouseEnterTests
    , mouseLeaveTests
    , mouseOverTests
    , mouseOutTests
    ]

clickTests =
  describe "Click Event Tests"
  [ EventTests.standardEventBehavior Event.click "click"
  , EventTests.propagationBehavior Event.click "click"
  , describe "when the click succeeds"
    [ test "it updates the model accordingly" <|
      \() ->
        let
          initialState = Elmer.componentState App.defaultModel App.view App.update
          updatedStateResult = Markup.find ".button" initialState
                                |> Event.click
        in
          case updatedStateResult of
            Ready updatedState ->
              Expect.equal updatedState.model.clicks 1
            Failed msg ->
              Expect.fail msg
    ]
  ]

doubleClickTests =
  describe "Double Click Event Tests"
  [ EventTests.standardEventBehavior Event.doubleClick "dblclick"
  , EventTests.propagationBehavior Event.doubleClick "dblclick"
  , describe "when the double click succeeds"
    [ test "it updates the model accordingly" <|
      \() ->
        let
          initialState = Elmer.componentState App.defaultModel App.view App.update
          updatedStateResult = Markup.find ".button" initialState
                                |> Event.doubleClick
        in
          case updatedStateResult of
            Ready updatedState ->
              Expect.equal updatedState.model.doubleClicks 1
            Failed msg ->
              Expect.fail msg
    ]
  ]

mouseDownTests =
  describe "Mouse Down Event Tests"
  [ EventTests.standardEventBehavior Event.mouseDown "mousedown"
  , EventTests.propagationBehavior Event.mouseDown "mousedown"
  , let
      initialModel = App.defaultModel
      initialState = Elmer.componentState initialModel App.view App.update
    in
      describe "the mouse down event"
      [ test "at first no mouse down is recorded" <|
        \() ->
          Expect.equal initialModel.mouseDowns 0
      , test "the event updates the model" <|
        \() ->
          let
            updatedStateResult = Markup.find ".button" initialState
                                  |> Event.mouseDown
          in
            case updatedStateResult of
              Ready updatedState ->
                Expect.equal updatedState.model.mouseDowns 1
              Failed msg ->
                Expect.fail msg
      ]
  ]

mouseUpTests =
  describe "Mouse Up Event Tests"
  [ EventTests.standardEventBehavior Event.mouseUp "mouseup"
  , EventTests.propagationBehavior Event.mouseUp "mouseup"
  , let
      initialModel = App.defaultModel
      initialState = Elmer.componentState initialModel App.view App.update
    in
      describe "the mouse up event"
      [ test "at first no mouse up is recorded" <|
        \() ->
          Expect.equal initialModel.mouseUps 0
      , test "the event updates the model" <|
        \() ->
          let
            updatedStateResult = Markup.find ".button" initialState
                                  |> Event.mouseUp
          in
            case updatedStateResult of
              Ready updatedState ->
                Expect.equal updatedState.model.mouseUps 1
              Failed msg ->
                Expect.fail msg
      ]
  ]

mouseEnterTests =
  describe "Mouse Enter Event Tests"
  [ EventTests.standardEventBehavior Event.mouseEnter "mouseenter"
  , let
      initialModel = App.defaultModel
      initialState = Elmer.componentState initialModel App.viewForMouseEnterLeave App.update
    in
      describe "the mouse enter event"
      [ describe "when the element does not have a mouse enter event but its ancestor does"
        [ test "it fails to find the event" <|
          \() ->
            Markup.find "li[data-option='2']" initialState
              |> Event.mouseEnter
              |> Expect.equal (Failed ("No relevant event handler found"))
        ]
      , describe "when the element has a mouse enter event"
        [ test "at first no mouse enter is recorded" <|
          \() ->
            Expect.equal initialModel.mouseEnters 0
        , test "the event updates the model" <|
          \() ->
            let
              updatedStateResult = Markup.find "#event-parent" initialState
                                    |> Event.mouseEnter
            in
              case updatedStateResult of
                Ready updatedState ->
                  Expect.equal updatedState.model.mouseEnters 1
                Failed msg ->
                  Expect.fail msg
        ]
      , describe "when the element and its ancestor have a mouse enter event"
        [ test "it triggers only the handler on the element" <|
          \() ->
            let
              updatedStateResult = Markup.find "li[data-option='1']" initialState
                                    |> Event.mouseEnter
            in
              case updatedStateResult of
                Ready updatedState ->
                  Expect.equal updatedState.model.mouseEnters 1
                Failed msg ->
                  Expect.fail msg
        ]
      ]
  ]

mouseLeaveTests =
  describe "Mouse Leave Event Tests"
  [ EventTests.standardEventBehavior Event.mouseLeave "mouseleave"
  , let
      initialModel = App.defaultModel
      initialState = Elmer.componentState initialModel App.viewForMouseEnterLeave App.update
    in
      describe "the mouse leave event"
      [ describe "when the element does not have a mouse leave event but its ancestor does"
        [ test "it fails to find the event" <|
          \() ->
            Markup.find "li[data-option='2']" initialState
              |> Event.mouseLeave
              |> Expect.equal (Failed ("No relevant event handler found"))
        ]
      , describe "when the element has the mouse leave event"
        [ test "at first no mouse leave is recorded" <|
          \() ->
            Expect.equal initialModel.mouseLeaves 0
        , test "the event updates the model" <|
          \() ->
            let
              updatedStateResult = Markup.find "#event-parent" initialState
                                    |> Event.mouseLeave
            in
              case updatedStateResult of
                Ready updatedState ->
                  Expect.equal updatedState.model.mouseLeaves 1
                Failed msg ->
                  Expect.fail msg
        ]
      , describe "when the element and its ancestor have a mouse leave event"
        [ test "it triggers only the handler on the element" <|
          \() ->
            let
              updatedStateResult = Markup.find "li[data-option='1']" initialState
                                    |> Event.mouseLeave
            in
              case updatedStateResult of
                Ready updatedState ->
                  Expect.equal updatedState.model.mouseLeaves 1
                Failed msg ->
                  Expect.fail msg
        ]
      ]

  ]

mouseOverTests =
  describe "Mouse Over Event Tests"
  [ EventTests.standardEventBehavior Event.mouseOver "mouseover"
  , EventTests.propagationBehavior Event.mouseOver "mouseover"
  , let
      initialModel = App.defaultModel
      initialState = Elmer.componentState initialModel App.view App.update
    in
      describe "when the mouseOver event is registered"
      [ describe "when the targeted element has the mouseOver event"
        [ test "at first no mouse over is recorded" <|
          \() ->
            Expect.equal initialModel.mouseOvers 0
        , test "the event updates the model" <|
          \() ->
            let
              updatedStateResult = Markup.find ".button" initialState
                                    |> Event.mouseOver
            in
              case updatedStateResult of
                Ready updatedState ->
                  Expect.equal updatedState.model.mouseOvers 1
                Failed msg ->
                  Expect.fail msg
        ]
      ]
  ]

mouseOutTests =
  describe "Mouse Out Event Tests"
  [ EventTests.standardEventBehavior Event.mouseOut "mouseout"
  , EventTests.propagationBehavior Event.mouseOut "mouseOut"
  , let
      initialModel = App.defaultModel
      initialState = Elmer.componentState initialModel App.view App.update
    in
      describe "when the mouseOut event is registered"
      [ describe "when the targeted element has the mouseOut event"
        [ test "at first no mouse out is recorded" <|
          \() ->
            Expect.equal initialModel.mouseOuts 0
        , test "the event updates the model" <|
          \() ->
            let
              updatedStateResult = Markup.find ".button" initialState
                                    |> Event.mouseOut
            in
              case updatedStateResult of
                Ready updatedState ->
                  Expect.equal updatedState.model.mouseOuts 1
                Failed msg ->
                  Expect.fail msg
        ]
      ]
  ]