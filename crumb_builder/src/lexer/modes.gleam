import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string

import lexer/types.{type Token} as l
import types as ty

import lexer/internal as i

pub fn normal(
  text: List(String),
  delimiter_lookup: List(#(String, l.Delimiter)),
) -> #(List(String), List(String), Option(l.Token)) {
  // get graphemes until mode change
  let #(taken, rest, _) =
    i.split_until_change(text, l.ConsumeNormal, delimiter_lookup)

  #(taken, rest, option.Some(l.DebugToken(string.join(taken, ""))))
}

pub fn in_delimiter(
  text: List(String),
  delimiter: l.Delimiter,
  delimiter_lookup: List(#(String, l.Delimiter)),
) -> #(List(String), List(String), Option(Token)) {
  // consume the given delimiter
  let delim_str = delimiter |> i.delimiter_to_string
  let taken = delim_str |> string.split("")
  let rest = text |> list.drop(list.length(taken))

  // get the proper delim from the lookup and return it
  let token =
    delim_str
    |> list.key_find(delimiter_lookup, _)
    |> result.unwrap(l.ImpossibleDelim)
    |> l.DelimiterToken

  #(taken, rest, option.Some(token))
}

pub fn in_string_literal(
  text: List(String),
  delimiter_lookup: List(#(String, l.Delimiter)),
) -> #(List(String), List(String), Option(l.Token)) {
  // remove the first string literal to prevent it getting added in
  let text = list.drop(text, i.delimiter_length(l.StringLiteralDelim))

  // get graphemes until mode change
  let #(taken, rest, change) =
    i.split_until_change(text, l.ConsumeString, delimiter_lookup)

  // put the delim back into taken to not mess up the span
  let taken =
    i.delimiter_to_string(l.StringLiteralDelim)
    |> string.split("")
    |> list.append(taken)

  // react to stopping circumstances
  let #(taken, rest, token) = case change {
    // if we stopped because of a comment closing string, consume that closing delimiter
    l.HitDelimiter(l.StringLiteralDelim) -> {
      let rest = list.drop(rest, i.delimiter_length(l.StringLiteralDelim))

      // put the delim back into taken to not mess up the span
      let taken =
        i.delimiter_to_string(l.StringLiteralDelim)
        |> string.split("")
        |> list.append(taken, _)

      #(taken, rest, l.LiteralToken(ty.StringValue(string.join(taken, ""))))
    }

    // if we stopped because of EOF, push an error token
    l.HitEndOfFile -> #(taken, rest, l.ErrorToken(l.UnclosedStringLiteral))

    // impossible state
    _ -> #(taken, rest, l.DebugToken("Impossible"))
  }

  #(taken, rest, option.Some(token))
}

pub fn in_comment(
  text: List(String),
  comment_delim: l.CommentDelimiter,
  delimiter_lookup: List(#(String, l.Delimiter)),
) -> #(List(String), List(String), Option(l.Token)) {
  // get graphemes until mode change
  let #(taken, rest, change) =
    i.split_until_change(
      text,
      l.ConsumeComment(comment_delim),
      delimiter_lookup,
    )

  // react to stopping circumstances
  let #(taken, rest, token) = case comment_delim, change {
    // always push an error token on a comment close
    l.CommentCloseDelim, _ -> #(
      taken,
      rest,
      option.Some(l.ErrorToken(l.UnexpectedCommentClose)),
    )

    // if we stopped because of a comment closing delim, consume that delim
    _, l.HitDelimiter(l.CommentDelim(l.CommentCloseDelim)) -> {
      // put the delim back into taken to not mess up the span
      let taken =
        i.delimiter_to_string(l.CommentDelim(l.CommentCloseDelim))
        |> string.split("")
        |> list.append(taken, _)

      #(
        taken,
        list.drop(rest, i.delimiter_length(l.CommentDelim(l.CommentCloseDelim))),
        option.None,
      )
    }

    // if we stopped because of EOF during block comment, push an error token
    l.CommentOpenDelim, l.HitEndOfFile -> #(
      taken,
      rest,
      option.Some(l.ErrorToken(l.UnclosedBlockComment)),
    )

    // no error in this case
    l.CommentLineDelim, l.HitEndOfFile -> #(taken, rest, option.None)

    // impossible states
    _, _ -> #(taken, rest, option.None)
  }

  #(taken, rest, token)
}

pub fn white_space_consume(
  text: List(String),
  delimiter_lookup: List(#(String, l.Delimiter)),
) -> #(List(String), List(String), Option(l.Token)) {
  // get graphemes until mode change
  let #(taken, rest, _) =
    i.split_until_change(text, l.ConsumeWhiteSpace, delimiter_lookup)

  #(taken, rest, option.None)
}

pub fn finished(
  text: List(String),
) -> #(List(String), List(String), Option(l.Token)) {
  #([], text, option.None)
}
