module Elmer.SubscriptionTests exposing (all)

import Test exposing (..)
import Expect
import Elmer
import Elmer.Internal exposing (..)
import Elmer.Platform
import Elmer.Platform.Subscription as Subscription
import Elmer.Printer exposing (..)
import Elmer.Html as Markup
import Elmer.Html.Matchers as Matchers
import Elmer.TestApps.SubscriptionTestApp as App
import Time

all : Test
all =
  describe "Subscription Tests"
  [ withTests
  , sendTests
  ]

withTests : Test
withTests =
  describe "with"
  [ describe "when there is an upstream failure"
    [ test "it fails" <|
      \() ->
        let
          initialState = Failed "You Failed!"
        in
          Subscription.with (\() _ -> Sub.none) initialState
            |> Expect.equal (Failed "You Failed!")
    ]
  , describe "when the override is not a function"
    [ test "it fails" <|
      \() ->
        let
          initialState = Elmer.componentState App.defaultModel App.view App.update
          override = Elmer.Platform.stub (\_ -> "Huh?") (\_ -> Sub.none)
        in
          Elmer.Platform.use [ override ] initialState
            |> Subscription.with (\() _ -> Sub.none)
            |> Expect.equal (Failed "Failed to install stubs!")
    ]
  ]

sendTests : Test
sendTests =
  describe "send"
  [ describe "when there is an upstream failure"
    [ test "it fails" <|
      \() ->
        let
          initialState = Failed "You Failed!"
        in
          Subscription.send "mySub" 37 initialState
            |> Expect.equal (Failed "You Failed!")
    ]
  , describe "when no subscription is found"
    [ describe "when there are no subscriptions spies"
      [ test "it fails and explains why" <|
        \() ->
          let
            initialState = Elmer.componentState App.defaultModel App.view App.update
          in
            Subscription.send "someOtherSub" 37 initialState
              |> Expect.equal (Failed (
                format
                  [ message "No subscription spy found with name" "someOtherSub"
                  , description "because there are no subscription spies"]
                ))
      ]
    , describe "when there are subscription spies"
      [ test "it fails and lists the spies" <|
        \() ->
          let
            initialState = Elmer.componentState App.defaultModel App.view App.update
            override = Elmer.Platform.stub (\_ -> Time.every) (\interval tagger ->
                  Subscription.fake ("my-spy-" ++ (toString interval)) tagger
                )
          in
            Elmer.Platform.use [ override ] initialState
              |> Subscription.with (\() -> App.mappedSubscriptions)
              |> Subscription.send "someOtherSub" 37
              |> Expect.equal (Failed (
                format
                  [ message "No subscription spy found with name" "someOtherSub"
                  , message "These are the current subscription spies" "my-spy-3600000\nmy-spy-1"
                  ]
                ))
      ]
    ]
  , describe "when the subscription is found"
    [ describe "when the subscription is a single Sub"
      [ test "the data is tagged and processed" <|
        \() ->
          let
            initialState = Elmer.componentState App.defaultModel App.view App.update
            override = Elmer.Platform.stub (\_ -> Time.every) (\interval tagger ->
                  Subscription.fake ("fakeTime-" ++ (toString interval)) tagger
                )
          in
            Elmer.Platform.use [ override ] initialState
              |> Subscription.with (\() -> App.subscriptions)
              |> Subscription.send "fakeTime-1000" 23000
              |> Markup.find "#time"
              |> Markup.expectElement ( Matchers.hasText "23 seconds" )
      ]
    , describe "when the subscription is a batch of Subs"
      [ test "the data is tagged and processed" <|
        \() ->
          let
            initialState = Elmer.componentState App.defaultModel App.view App.update
            override = Elmer.Platform.stub (\_ -> Time.every) (\interval tagger ->
                  Subscription.fake ("fakeTime-" ++ (toString interval)) tagger
                )
          in
            Elmer.Platform.use [ override ] initialState
              |> Subscription.with (\() -> App.batchedSubscriptions)
              |> Subscription.send "fakeTime-60000" (1000 * 60 * 37)
              |> Markup.find "#minute"
              |> Markup.expectElement ( Matchers.hasText "37 minutes" )
      ]
    , describe "when the subscription is a mapped Sub"
      [ test "the data is tagged and processed" <|
        \() ->
          let
            initialState = Elmer.componentState App.defaultModel App.view App.update
            override = Elmer.Platform.stub (\_ -> Time.every) (\interval tagger ->
                  Subscription.fake ("fakeTime-" ++ (toString interval)) tagger
                )
          in
            Elmer.Platform.use [ override ] initialState
              |> Subscription.with (\() -> App.mappedSubscriptions)
              |> Subscription.send "fakeTime-3600000" (1000 * 60 * 60 * 18)
              |> Markup.find "#child-hours"
              |> Markup.expectElement ( Matchers.hasText "18 hours" )
      ]
    ]
  ]
