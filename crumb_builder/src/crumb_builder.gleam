import gleam/io
import gleam/list
import gleam/option
import gleam/string
import gleam_community/ansi
import util

import lexer
import lexer/internal as lexi

pub fn main() -> Nil {
  let t =
    "

  let x = 5 / 3
  print(x)
  func print(s: String) -> {
    // hi
    Nil
  }
  paper.cut(\"hello // \")

  \"
  "

  let lex =
    lexer.new_lexer()
    //|> lexer.max_iterations(option.Some(10))
    |> lexer.logging(True)
    |> lexer.run(string.to_graphemes(t))

  lex
  |> lexer.present_log
  |> lexer.log_to_string
  |> option.map(io.println)

  {
    "TEXT:\n\n"
    <> t |> ansi.bright_green
    <> "\n\nTEXT (whitespace made visible):\n\n"
    <> {
      t
      |> util.visible_whitespace
      |> util.visible_whitespace_still_shows_newline
      |> ansi.bright_green
    }
  }
  |> io.println

  lex
  |> lexer.present_tokens
  |> lexer.remove_spans
  |> list.map(lexi.token_to_string_debug)
  |> string.join("\n")
  |> fn(t) { "\n\nTOKENIZED:\n\n" <> t }
  |> io.println
}
