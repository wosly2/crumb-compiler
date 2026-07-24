import gleam/list

import lexer/internal as i
import lexer/modes
import lexer/types.{type Lexer, type SpannedToken, type Token} as l

pub fn new_lexer() -> Lexer {
  l.Lexer(
    tokens: [],
    mode: #(#(0, 0), l.Normal),
    current_coord: #(0, 0),
    delimiter_lookup: i.make_delimiter_lookup(),
  )
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

pub fn run(text: List(String), lexer: l.Lexer) -> l.Lexer {
  let #(text, lexer) = case lexer.mode.1 {
    l.Normal -> modes.normal(text, lexer)
    l.InDelimiter -> modes.in_delimiter(text, lexer)
    l.InStringLiteral -> modes.in_string_literal(text, lexer)
    l.InComment(comment_delim) -> modes.in_comment(text, lexer, comment_delim)
    l.WhiteSpaceConsume -> modes.white_space_consume(text, lexer)
    l.Finished -> modes.finished(text, lexer)
  }
  case lexer.mode.1 {
    l.Finished -> lexer
    _ -> run(text, lexer)
  }
}
