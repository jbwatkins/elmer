module Elmer.Html exposing
  ( HtmlTarget
  , HtmlElement
  , target
  , expect
  , render
  )

{-| Functions for working with the `Html msg` generated by the component's view function.

# Target Html Elements
@docs HtmlTarget, HtmlElement, target

# Make Expectations
@docs expect

# Render the View
@docs render

-}

import Elmer exposing (Matcher)
import Elmer.TestState as TestState exposing (TestState)
import Elmer.Context as Context exposing (Context)
import Elmer.Runtime.Command as RuntimeCommand
import Elmer.Html.Types exposing (..)
import Elmer.Html.Internal as Html_
import Elmer.Html.Query as Query
import Elmer.Errors as Errors
import Html exposing (Html)
import Expect
import Dict exposing (Dict)
import Json.Decode as Json


{-| Represents an Html element.
-}
type alias HtmlElement msg
  = Elmer.Html.Types.HtmlElement msg

{-| Represents the Html Element or Elements about which expectations will be made.

An `HtmlTarget` is determined by the last use of `Elmer.Html.target`.
-}
type alias HtmlTarget msg =
  Query.HtmlTarget msg


{-| Target an element or elements within the Html produced by the
component's `view` function.

Use this function to specify which element will receive an event or which should
be the subject of any expectations.

Note: You may provide a selector that does not match any elements.

Target an element by class:

    target ".some-class-name"

Target an element by id:

    target "#some-id"

Target an element by Html tag:

    target "div"

Target an element having an attribute:

    target "[data-my-attr]"

Target an element with an attribute and value:

    target "[data-my-attr='my-value']"

Combine tag, attribute, and class selectors as necessary:

    target "div.some-style"
    target "div[data-my-attr='my-value']"
    target "[data-my-attr].some-style"

Target the first descendant:

    target "selector1 selector2"

This will target the first element that matches `selector2` and is a
descendant of the element matching `selector1`, where these selectors follow
the syntax described above. For example,

    target "div a"

will target the first `a` element that is a descendant of the first `div` element.
You can add as many selectors as you want.
-}
target : String -> Elmer.TestState model msg -> Elmer.TestState model msg
target selector =
  TestState.map <|
    \context ->
        RuntimeCommand.mapState TargetSelector (\_ -> selector)
          |> Context.updateStateFor context
          |> TestState.with


{-| Make expectations about the targeted html.

    target ".my-class" testState
      |> expect (
        Elmer.Html.Matchers.element <|
          Elmer.Html.Matchers.hasText "some text"
      )

Use `expect` in conjunction with matchers like `element`, `elementExists`,
or `elements`.
-}
expect : Matcher (HtmlTarget msg) -> Matcher (Elmer.TestState model msg)
expect matcher =
  TestState.mapToExpectation <|
    \context ->
      case Context.state TargetSelector context of
        Just selector ->
          case Context.render context of
            Just view ->
              matcher <| Query.forHtml selector view
            Nothing ->
              Expect.fail Errors.noModel
        Nothing ->
          Expect.fail "No expectations could be made because no Html has been targeted.\n\nUse Elmer.Html.target to identify the Html you want to describe."

{-| Call the component's view function with the current model.

Sometimes, it may be useful to render the component's view manually. For example,
if you are spying on some function called by the view function, you'll need to
render the view manually before you can make expectations about that spy.

Note: Usually you will not need to render the view manually.
-}
render : Elmer.TestState model msg -> Elmer.TestState model msg
render =
  TestState.map <|
    \context ->
      let
        view = Context.render context
      in
        TestState.with context
