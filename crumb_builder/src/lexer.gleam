import gleam/int
import gleam/list
import gleam/option.{type Option}
import gleam/string

import gleam_community/ansi

import lexer/internal as i
import lexer/modes
import lexer/types.{type Lexer, type Mode, type SpannedToken, type Token} as l
import util as ut

pub fn new_lexer() -> Lexer {
  l.Lexer(
    tokens: [],
    mode: #(#(0, 0), l.ConsumeNormal),
    current_coord: #(0, 0),
    delimiter_lookup: i.make_delimiter_lookup(),
    keyword_lookup: i.make_keyword_lookup(),
    iterations: 0,
    max_iterations: option.None,
    log: option.None,
  )
}

pub fn max_iterations(lexer: Lexer, max_iterations: Option(Int)) -> Lexer {
  l.Lexer(..lexer, max_iterations:)
}

pub fn logging(lexer: Lexer, on: Bool) -> Lexer {
  let log = case on {
    True ->
      case lexer.log {
        option.Some(old_log) -> option.Some(old_log)
        option.None -> option.Some([])
      }
    False -> option.None
  }
  l.Lexer(..lexer, log:)
}

/// `log` only creates or pushes messages if `Lexer.log` is not `None`.
/// Logging will be skipped if `message()` evaluates to `""`. Instead,
/// `""` is logged whenever `message()` evaluates to `"log_blank"`.
pub fn log(lexer: Lexer, message: fn() -> String) -> Lexer {
  case lexer.log {
    option.Some(log) -> {
      l.Lexer(
        ..lexer,
        log: option.Some(log_sure(log, message, lexer.iterations)),
      )
    }
    option.None -> lexer
  }
}

fn log_sure(
  log: List(#(Int, String)),
  message: fn() -> String,
  iterations: Int,
) -> List(#(Int, String)) {
  let msg = message()
  case msg {
    "" -> log
    "log_blank" -> [#(iterations, ""), ..log]
    _ -> [#(iterations, msg), ..log]
  }
}

/// Evaluate a series of logs with one check to ensure logging is allowed,
/// rather than a check for every message.
pub fn log_chain(lexer: Lexer, messages: List(fn() -> String)) -> Lexer {
  case lexer.log {
    option.Some(log) -> {
      let log =
        option.Some(
          list.fold(messages, log, fn(log, message) {
            log_sure(log, message, lexer.iterations)
          }),
        )
      l.Lexer(..lexer, log:)
    }
    option.None -> lexer
  }
}

/// `log_blank` triggers `log` to log a message of `""`. It returns
/// exactly `"log_blank"`.
pub fn log_blank() -> String {
  "log_blank"
}

pub fn present_log(lexer: Lexer) -> Option(List(#(Int, String))) {
  option.map(lexer.log, list.reverse)
}

pub fn log_to_string(log: Option(List(#(Int, String)))) -> Option(String) {
  option.map(log, fn(log) {
    log
    |> list.map(fn(msg) {
      "[" <> int.to_string(msg.0) |> ansi.bright_green <> "] " <> msg.1
    })
    |> string.join("\n")
  })
}

pub fn remove_spans(tokens: List(SpannedToken)) -> List(Token) {
  list.map(tokens, fn(st) {
    let l.SpannedToken(t, _) = st
    t
  })
}

pub fn present_tokens(lexer: Lexer) -> List(SpannedToken) {
  list.reverse(lexer.tokens)
}

fn mode_to_string(mode: Mode) -> String {
  case mode {
    l.ConsumeNormal -> "Normal"
    l.ConsumeDelimiter(delim) ->
      "In delimiter: " <> i.token_to_string_debug(l.DelimiterToken(delim))
    l.ConsumeString -> "In string literal"
    l.ConsumeComment(comment_delim) ->
      "In comment: "
      <> i.token_to_string_debug(
        l.DelimiterToken(l.CommentDelim(comment_delim)),
      )
    l.ConsumeWhiteSpace -> "Consume white space"
    l.Finished -> "Finished"
  }
}

fn change_to_string(change: l.TextReaderChange) -> String {
  case change {
    l.HitDelimiter(delim) ->
      "Hit delimiter: " <> i.token_to_string_debug(l.DelimiterToken(delim))
    l.HitGrapheme -> "Hit grapheme"
    l.HitEndOfFile -> "Hit EOF"
  }
}

pub fn coord_to_string(coord: l.Coord) -> String {
  "(" <> int.to_string(coord.0) <> ", " <> int.to_string(coord.0) <> ")"
}

pub fn span_to_string(span: l.Span) -> String {
  "<"
  <> coord_to_string(span.start)
  <> "->"
  <> coord_to_string(span.stop)
  <> ">"
}

pub fn run(lexer: Lexer, text: List(String)) -> Lexer {
  // count
  let lexer = l.Lexer(..lexer, iterations: lexer.iterations + 1)

  // get and run the mode
  let l.ModeOutput(taken, rest, token) =
    modes.get_function(lexer.mode.1)(l.ModeInput(
      text:,
      delimiter_lookup: lexer.delimiter_lookup,
      keyword_lookup: lexer.keyword_lookup,
    ))

  // debug print
  let lexer =
    lexer
    |> log_chain([
      fn() { "ITERATION" |> ansi.bg_bright_blue },
      fn() {
        "Mode now: " |> ansi.bright_blue
        <> mode_to_string(lexer.mode.1) |> ansi.bright_yellow
      },
      fn() {
        "Taken: " |> ansi.bright_blue
        <> taken
        |> string.join("")
        |> ut.visible_whitespace
        |> ansi.green
        |> ut.cut_off_string_with_message(50)
      },
      fn() {
        "Rest: " |> ansi.bright_blue
        <> rest
        |> string.join("")
        |> ut.visible_whitespace
        |> ansi.green
        |> ut.cut_off_string_with_message(50)
      },
      fn() {
        "Token: " |> ansi.bright_blue
        <> i.token_to_string(option.unwrap(token, l.DebugToken("No Token")))
        |> ansi.bright_yellow
      },
    ])

  // advance
  let lexer = lexer |> i.advance_over(taken)

  // push token
  let lexer = case token {
    option.Some(token) -> i.push_token(lexer, token)
    option.None -> lexer
  }

  // update lexer mode based on the rest
  let change = i.read_changes(rest, lexer.delimiter_lookup)
  let mode = i.determine_next_mode(change, lexer)

  let lexer =
    lexer
    |> log_chain([
      fn() {
        "Change: " |> ansi.bright_blue
        <> change_to_string(change) |> ansi.bright_yellow
      },
      fn() {
        "New mode: " |> ansi.bright_blue
        <> mode_to_string(mode.1) |> ansi.bright_yellow
      },
    ])

  // set mode
  let lexer = l.Lexer(..lexer, mode:)

  let lexer =
    lexer
    |> log(fn() {
      case lexer.max_iterations {
        option.Some(max) if lexer.iterations >= max ->
          "Lexer iteration count too high, quitting!"
        _ -> ""
      }
    })

  let lexer = log(lexer, fn() { string.repeat("\n", 2) })

  case lexer.max_iterations, lexer.mode.1 {
    _, l.Finished -> lexer
    option.Some(max), _ if lexer.iterations >= max -> lexer
    _, _ -> run(lexer, rest)
  }
}
