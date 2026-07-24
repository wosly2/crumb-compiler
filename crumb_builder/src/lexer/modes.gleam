import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string
import util as ut

import lexer/types.{
  type CommentDelimiter, type Delimiter, type Mode, type ModeFunction,
  type ModeInput, type ModeOutput, type Token,
} as l
import types as ty

import lexer/internal as i

pub fn get_function(mode: Mode) -> ModeFunction {
  case mode {
    l.ConsumeNormal -> normal
    l.ConsumeDelimiter(d) -> consume_delimiter(_, d)
    l.ConsumeString -> consume_string
    l.ConsumeComment(cd) -> consume_comment(_, cd)
    l.ConsumeWhiteSpace -> consume_white_space
    l.Finished -> finished
  }
}

fn token_parse_normal_graphemes(
  text: String,
  keyword_lookup: List(#(String, ty.Keyword)),
) -> Result(Token, Nil) {
  // integer?
  int.parse(text)
  |> result.map(ty.IntValue)
  |> result.or(
    // float?
    float.parse(text)
    |> result.map(ty.FloatValue),
  )
  |> result.map(l.LiteralToken)
  |> result.or(
    // keyword?
    list.key_find(keyword_lookup, text)
    |> result.map(l.KeywordToken),
  )
  |> result.or(
    l.SymbolToken(text)
    |> ut.result_if(!string.is_empty(text), _, Nil),
  )
}

fn normal(mi: ModeInput) -> ModeOutput {
  // get graphemes until mode change
  let #(taken, rest, _) =
    i.split_until_change(mi.text, l.ConsumeNormal, mi.delimiter_lookup)

  let token =
    taken
    |> string.join("")
    |> token_parse_normal_graphemes(mi.keyword_lookup)
    |> option.from_result

  l.ModeOutput(taken, rest, token)
}

fn consume_delimiter(mi: ModeInput, delimiter: Delimiter) -> ModeOutput {
  // consume the given delimiter
  let delim_str = delimiter |> i.delimiter_to_string
  let taken = delim_str |> string.split("")
  let rest = mi.text |> list.drop(list.length(taken))

  // get the proper delim from the lookup and return it
  let token =
    delim_str
    |> list.key_find(mi.delimiter_lookup, _)
    |> result.map(l.DelimiterToken)
    |> result.unwrap(l.DebugToken("Impossible"))
    |> option.Some

  l.ModeOutput(taken, rest, token)
}

fn consume_string(mi: ModeInput) -> ModeOutput {
  // remove the first string literal to prevent it getting added in
  let text = list.drop(mi.text, i.delimiter_length(l.StringLiteralDelim))

  // get graphemes until mode change
  let #(taken, rest, change) =
    i.split_until_change(text, l.ConsumeString, mi.delimiter_lookup)

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

  l.ModeOutput(taken, rest, token |> option.Some)
}

fn consume_comment(
  mi: ModeInput,
  comment_delim: CommentDelimiter,
) -> ModeOutput {
  // get graphemes until mode change
  let #(taken, rest, change) =
    i.split_until_change(
      mi.text,
      l.ConsumeComment(comment_delim),
      mi.delimiter_lookup,
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

  l.ModeOutput(taken, rest, token)
}

fn consume_white_space(mi: ModeInput) -> ModeOutput {
  // get graphemes until mode change
  let #(taken, rest, _) =
    i.split_until_change(mi.text, l.ConsumeWhiteSpace, mi.delimiter_lookup)

  l.ModeOutput(taken, rest, option.None)
}

fn finished(mi: ModeInput) -> ModeOutput {
  l.ModeOutput([], mi.text, option.None)
}
