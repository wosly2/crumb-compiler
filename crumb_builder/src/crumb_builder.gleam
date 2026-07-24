import gleam/io
import gleam/list
import gleam/option
import gleam/string
import util

import lexer
import lexer/internal as lexi

pub fn main() -> Nil {
  let t =
    // "f \"string literal //comment
    // \"
    // readable // cant, read me me.me/* hi*/ bye
    // hello hello \"     hi\" whoop /* stuff stuff
    // . . \"kabloo\" blee bloh */ text shoop
    // readable /*"
    //   "
    // *
    // **
    // ***
    // /
    // //
    // /*
    // */
    // <
    // <=
    // <<
    // >
    // >=
    // >>
    // &
    // &&
    // |
    // ||
    // !
    // !=
    // "
    "***=
  >>=
  <<=
  !==
  //**/"

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
    <> t
    <> "\n\nTEXT (whitespace made visible):\n\n"
    <> {
      t
      |> util.visible_whitespace
      |> util.visible_whitespace_still_shows_newline
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
