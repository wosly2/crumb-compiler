import gleam/io
import gleam/string
import lexer

pub fn main() -> Nil {
  let t =
    "hello there what is your name # comment
  hi again this is a new line # another comment      blah
         blahhhhh # hi hi # #hi ### hi hi
      \"hello\" hi"

  { "TEXT:\n\n" <> t }
  |> io.println

  t
  |> string.to_graphemes
  |> lexer.run(lexer.new_lexer())
  |> lexer.present_tokens
  |> lexer.remove_spans
  |> lexer.tokens_to_string(", ")
  |> fn(t) { "\n\nTOKENIZED:\n\n" <> t }
  |> io.println
}
