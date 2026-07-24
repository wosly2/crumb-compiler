import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/string

import gleam_community/ansi

pub fn any_start_with(
  matches: List(String),
  sub: String,
) -> Result(String, Nil) {
  list.find_map(matches, fn(match) {
    case string.starts_with(match, sub) {
      True -> Ok(match)
      False -> Error(Nil)
    }
  })
}

pub fn accumulate_until(
  initial initial: a,
  update update: fn(a) -> list.ContinueOrStop(a),
) -> a {
  case update(initial) {
    list.Continue(acc) -> accumulate_until(acc, update)
    list.Stop(acc) -> acc
  }
}

pub fn try_accumulate_until(
  initial initial: a,
  update update: fn(a) -> Result(list.ContinueOrStop(a), b),
) -> Result(a, b) {
  case update(initial) {
    Ok(list.Continue(next)) -> try_accumulate_until(next, update)
    Ok(list.Stop(final)) -> Ok(final)
    Error(error) -> Error(error)
  }
}

pub fn keys(pairs: List(#(a, b))) -> List(a) {
  list.map(pairs, fn(pair) { pair.0 })
}

pub fn values(pairs: List(#(a, b))) -> List(b) {
  list.map(pairs, fn(pair) { pair.1 })
}

pub fn visible_whitespace(text: String) -> String {
  text |> string.replace(" ", "·") |> string.replace("\n", "↵")
}

pub fn visible_whitespace_still_shows_newline(text: String) -> String {
  text |> string.replace("\n", "↵") |> string.replace("↵", "↵\n")
}

pub fn cut_off_string_with_message(text: String, after n: Int) -> String {
  case string.length(text) > n {
    True ->
      text |> string.to_graphemes |> list.take(n) |> string.join("")
      <> " ..."
      <> int.to_string(string.length(text) - n)
      <> " more"
      |> ansi.gray
      |> ansi.italic
    False -> text
  }
}

pub fn option_if(condition: Bool, some: t) -> Option(t) {
  case condition {
    True -> option.Some(some)
    False -> option.None
  }
}

pub fn result_if(condition: Bool, ok: a, err: b) -> Result(a, b) {
  case condition {
    True -> Ok(ok)
    False -> Error(err)
  }
}
