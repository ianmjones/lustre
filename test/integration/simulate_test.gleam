// IMPORTS ---------------------------------------------------------------------

import birdie
import gleam/int
import gleam/json
import gleam/list
import gleam/string
import lustre/attribute
import lustre/dev/query.{data, element}
import lustre/dev/simulate
import lustre/element
import lustre/element/html
import lustre/event
import lustre_test

//

pub fn simulate_single_event_test() {
  use <- lustre_test.test_filter("simulate_single_event_test")
  let incr_button = element(data("test-id", "incr"))

  simulate.simple(init:, update:, view:)
  |> simulate.start(0)
  |> simulate.event(on: incr_button, name: "click", data: [])
  |> to_snapshot
  |> birdie.snap("[simulate] Single increment event")
}

pub fn simulate_multiple_events_test() {
  use <- lustre_test.test_filter("simulate_multiple_events_test")
  let incr_button = element(data("test-id", "incr"))

  simulate.simple(init:, update:, view:)
  |> simulate.start(0)
  |> simulate.event(on: incr_button, name: "click", data: [])
  |> simulate.event(on: incr_button, name: "click", data: [])
  |> to_snapshot
  |> birdie.snap("[simulate] Multiple increment events")
}

pub fn simulate_message_test() {
  use <- lustre_test.test_filter("simulate_message_test")
  simulate.simple(init:, update:, view:)
  |> simulate.start(0)
  |> simulate.message(ParentResetCount(10))
  |> to_snapshot
  |> birdie.snap("[simulate] Parent reset message")
}

pub fn simulate_events_and_messages_test() {
  use <- lustre_test.test_filter("simulate_events_and_messages_test")
  let incr_button = element(data("test-id", "incr"))

  simulate.simple(init:, update:, view:)
  |> simulate.start(0)
  |> simulate.event(on: incr_button, name: "click", data: [])
  |> simulate.message(ParentResetCount(10))
  |> simulate.event(on: incr_button, name: "click", data: [])
  |> to_snapshot
  |> birdie.snap("[simulate] Events and messages")
}

// PROBLEMS -------------------------------------------------------------------

pub fn simulate_missing_element_test() {
  use <- lustre_test.test_filter("simulate_missing_element_test")
  let submit_button = element(data("test-id", "submit"))

  simulate.simple(init:, update:, view:)
  |> simulate.start(0)
  |> simulate.event(on: submit_button, name: "click", data: [])
  |> to_snapshot
  |> birdie.snap("[simulate] Missing element")
}

pub fn simulate_missing_event_handler_test() {
  use <- lustre_test.test_filter("simulate_missing_event_handler_test")
  let incr_button = element(data("test-id", "incr"))

  simulate.simple(init:, update:, view:)
  |> simulate.start(0)
  |> simulate.event(on: incr_button, name: "keydown", data: [])
  |> to_snapshot
  |> birdie.snap("[simulate] Missing event handler")
}

// UTILS -----------------------------------------------------------------------

fn to_snapshot(app) {
  let element_snapshot =
    simulate.view(app)
    |> element.to_readable_string
    |> string.replace("\n", "\n  ")

  let history_snapshot =
    simulate.history(app)
    |> list.map(fn(event) {
      case event {
        simulate.Dispatch(message:) -> "message | " <> string.inspect(message)

        simulate.Event(target:, name:, data:) ->
          "event   | "
          <> query.to_readable_string(target)
          <> " \""
          <> name
          <> "\" "
          <> json.to_string(data)

        simulate.Problem(name:, message:) ->
          "problem | " <> name <> ": " <> message
      }
    })
    |> string.join("\n  ")

  "
Output:

  ${element}

History:

  ${history}
"
  |> string.replace("${element}", element_snapshot)
  |> string.replace("${history}", history_snapshot)
}

// MODEL -----------------------------------------------------------------------

fn init(initial_count) {
  initial_count
}

// UPDATE ----------------------------------------------------------------------

type Msg {
  ParentResetCount(Int)
  UserClickedIncrement
  UserClickedDecrement
}

fn update(model, msg) {
  case msg {
    ParentResetCount(count) -> count
    UserClickedIncrement -> model + 1
    UserClickedDecrement -> model - 1
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model) {
  html.div([], [
    html.button([event.on_click(UserClickedDecrement)], [html.text("-")]),
    html.p([], [html.text(int.to_string(model))]),
    html.button(
      [attribute.data("test-id", "incr"), event.on_click(UserClickedIncrement)],
      [html.text("+")],
    ),
  ])
}
