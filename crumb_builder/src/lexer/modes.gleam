import gleam/io
import gleam/list
import gleam/string

import lexer/types.{type Lexer} as l
import types as ty

import lexer/internal as i

pub fn normal(text: List(String), lexer: Lexer) -> #(List(String), Lexer) {
  // get graphemes until mode change
  let #(taken, rest, change) =
    i.split_until_mode_change(text, l.Normal, lexer.delimiter_lookup)

  // advance, push
  let lexer =
    lexer
    |> i.advance_over(taken)
    |> i.push_token(l.DebugToken(string.join(taken, "")))

  // apply next mode
  let lexer = l.Lexer(..lexer, mode: i.determine_next_mode(change, lexer))

  #(rest, lexer)
}

pub fn in_delimiter(
  text: List(String),
  lexer: Lexer,
) -> #(List(String), Lexer) {
  #(text, lexer)
}

pub fn in_string_literal(
  text: List(String),
  lexer: Lexer,
) -> #(List(String), Lexer) {
  // remove the first string literal to prevent it getting added in
  let text = list.drop(text, string.length(l.string_literal_value))

  // get graphemes until mode change
  let #(taken, rest, change) =
    i.split_until_mode_change(text, l.InStringLiteral, lexer.delimiter_lookup)

  io.println("String mode - taken:  " <> string.join(taken, ""))
  io.println("String mode - rest:   " <> string.join(rest, ""))
  io.println("String mode - change: " <> string.inspect(change))

  // react to stopping circumstances
  let #(rest, token, change) = case change {
    // if we stopped because of a comment closing string, consume and update change
    l.ChangeStringLiteral -> {
      let rest = list.drop(rest, string.length(l.string_literal_value))
      #(
        rest,
        l.LiteralToken(ty.StringValue(string.join(taken, ""))),
        i.read_indicated_mode_change(rest, lexer.delimiter_lookup),
      )
    }

    // if we stopped because of EOF, push an error token
    l.ChangeEndOfFile -> #(rest, l.ErrorToken(l.UnclosedStringLiteral), change)

    // impossible state
    _ -> #(rest, l.DebugToken("Impossible"), change)
  }

  // advance, push
  let lexer = lexer |> i.advance_over(taken) |> i.push_token(token)

  // apply next mode
  let lexer = l.Lexer(..lexer, mode: i.determine_next_mode(change, lexer))

  #(rest, lexer)
}

pub fn in_comment(
  text: List(String),
  lexer: Lexer,
  comment_delim: l.CommentDelimiter,
) -> #(List(String), Lexer) {
  // get graphemes until mode change
  let #(taken, rest, change) =
    i.split_until_mode_change(
      text,
      l.InComment(comment_delim),
      lexer.delimiter_lookup,
    )

  // advance, do not push
  let lexer = lexer |> i.advance_over(taken)

  // react to stopping circumstances
  let #(rest, lexer, change) = case change {
    // if we stopped because of a comment closing delim, consume that delim and find next change instead
    l.ChangeNewDelimiter(l.CommentDelim(l.CommentCloseDelim)) -> {
      let rest =
        list.drop(
          rest,
          string.length(
            i.delimiter_to_string(l.CommentDelim(l.CommentCloseDelim)),
          ),
        )
      #(rest, lexer, i.read_indicated_mode_change(rest, lexer.delimiter_lookup))
    }
    // if we stopped because of EOF, push an error token
    l.ChangeEndOfFile -> #(
      rest,
      i.push_token(lexer, l.ErrorToken(l.UnclosedBlockComment)),
      change,
    )
    // impossible state
    _ -> #(rest, lexer, change)
  }

  // apply next mode
  let lexer = l.Lexer(..lexer, mode: i.determine_next_mode(change, lexer))

  #(rest, lexer)
}

pub fn white_space_consume(
  text: List(String),
  lexer: Lexer,
) -> #(List(String), Lexer) {
  // get graphemes until mode change
  let #(taken, rest, change) =
    i.split_until_mode_change(text, l.WhiteSpaceConsume, lexer.delimiter_lookup)

  // advance, do not push
  let lexer = lexer |> i.advance_over(taken)

  // apply next mode
  let lexer = l.Lexer(..lexer, mode: i.determine_next_mode(change, lexer))

  #(rest, lexer)
}

pub fn finished(text: List(String), lexer: Lexer) -> #(List(String), Lexer) {
  #(text, lexer)
}
