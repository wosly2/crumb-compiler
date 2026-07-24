import gleam/io
import gleam/string
import lexer
import lexer/internal as lexi

pub fn main() -> Nil {
  let t =
    "\"string literal //comment
    \"
    readable // cant read me
    readable /*"

  { "TEXT:\n\n" <> t }
  |> io.println

  t
  |> string.to_graphemes
  |> lexer.run(lexer.new_lexer())
  |> lexer.present_tokens
  |> lexer.remove_spans
  |> lexi.tokens_to_string(", ")
  |> fn(t) { "\n\nTOKENIZED:\n\n" <> t }
  |> io.println
}
