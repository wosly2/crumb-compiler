import gleam/io
import gleam/string
import lexer

pub fn main() -> Nil {
  "hello there what is your name"
  |> string.to_graphemes
  |> lexer.run(lexer.new_lexer())
  |> lexer.present_tokens
  |> lexer.remove_spans
  |> lexer.tokens_to_string(", ")
  |> io.println
}
