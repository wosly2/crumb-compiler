import gleam/bool
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string

import lexer/types.{
  type Coord, type Delimiter, type IndicatedModeChange, type Lexer,
  type LexerError, type Mode, type Token,
} as l
import types as ty
import util as ut

pub fn advance_coord(coord: Coord, grapheme: String) -> Coord {
  case grapheme {
    "\n" -> #(coord.0 + 1, 0)
    _ -> #(coord.0, coord.1 + 1)
  }
}

pub fn advance_coord_over(coord: Coord, text: List(String)) -> Coord {
  case list.is_empty(text) {
    True -> coord
    False -> {
      let #(first, rest) = list.split(text, 1)
      let coord = advance_coord(coord, result.unwrap(list.first(first), ""))
      advance_coord_over(coord, rest)
    }
  }
}

pub fn advance(lexer: Lexer, grapheme: String) -> Lexer {
  l.Lexer(..lexer, current_coord: advance_coord(lexer.current_coord, grapheme))
}

pub fn advance_over(lexer: Lexer, text: List(String)) -> Lexer {
  l.Lexer(..lexer, current_coord: advance_coord_over(lexer.current_coord, text))
}

pub fn push_token(lexer: Lexer, token: Token) -> Lexer {
  let spanned = l.SpannedToken(token, l.Span(lexer.mode.0, lexer.current_coord))
  l.Lexer(..lexer, tokens: [spanned, ..lexer.tokens])
}

pub fn delimiter_to_string(delimiter: Delimiter) -> String {
  case delimiter {
    l.AddDelim -> "+"
    l.MinusDelim -> "-"
    l.MulDelim -> "*"
    l.DivDelim -> "/"
    l.PowDelim -> "**"
    l.ModDelim -> "%"
    l.BitAndDelim -> "&"
    l.BitOrDelim -> "|"
    l.BitNotDelim -> "!"
    l.BitShrDelim -> ">>"
    l.BitShlDelim -> "<<"
    l.EqualDelim -> "=="
    l.UnequalDelim -> "!="
    l.GreaterDelim -> ">"
    l.LessDelim -> "<"
    l.GreaterEqualDelim -> ">="
    l.LessEqualDelim -> "<="
    l.AndDelim -> "&&"
    l.OrDelim -> "||"
    l.ParenthesisOpenDelim -> "("
    l.CurlyBraceOpenDelim -> "{"
    l.BracketOpenDelim -> "["
    l.ParenthesisCloseDelim -> ")"
    l.CurlyBraceCloseDelim -> "}"
    l.BracketCloseDelim -> "]"
    l.PeriodDelim -> "."
    l.CommaDelim -> ","
    l.CommentDelim(l.CommentLineDelim) -> "//"
    l.CommentDelim(l.CommentOpenDelim) -> "/*"
    l.CommentDelim(l.CommentCloseDelim) -> "*/"
    l.ImpossibleDelim -> ""
  }
}

pub fn make_delimiter_lookup() -> List(#(String, Delimiter)) {
  let delims = [
    l.AddDelim,
    l.MinusDelim,
    l.MulDelim,
    l.DivDelim,
    l.PowDelim,
    l.ModDelim,
    l.BitAndDelim,
    l.BitOrDelim,
    l.BitNotDelim,
    l.BitShrDelim,
    l.BitShlDelim,
    l.EqualDelim,
    l.UnequalDelim,
    l.GreaterDelim,
    l.LessDelim,
    l.GreaterEqualDelim,
    l.LessEqualDelim,
    l.AndDelim,
    l.OrDelim,
    l.ParenthesisOpenDelim,
    l.CurlyBraceOpenDelim,
    l.BracketOpenDelim,
    l.ParenthesisCloseDelim,
    l.CurlyBraceCloseDelim,
    l.BracketCloseDelim,
    l.CommaDelim,
    l.PeriodDelim,
    l.CommaDelim,
    l.CommentDelim(l.CommentLineDelim),
    l.CommentDelim(l.CommentOpenDelim),
    l.CommentDelim(l.CommentCloseDelim),
    // don't forget to put other delims here, but NOT ImpossibleDelim
  ]
  list.map2(delims, list.map(delims, delimiter_to_string), fn(d, ds) {
    #(ds, d)
  })
}

pub fn keyword_to_string(keyword: ty.Keyword) -> String {
  case keyword {
    _ -> "kw_other"
  }
}

pub fn literal_to_string(primitive: ty.Value) -> String {
  case primitive {
    ty.IntValue(i) -> "Lit_int<" <> int.to_string(i) <> ">"
    ty.FloatValue(f) -> "Lit_float<" <> float.to_string(f) <> ">"
    ty.StringValue(s) -> "Lit_str<" <> s <> ">"
    ty.BooleanValue(b) -> "Lit_b<" <> bool.to_string(b) <> ">"
    ty.ListValue(_, _) -> "this text does not appear"
  }
}

pub fn type_to_string(type_: ty.Type) -> String {
  case type_ {
    ty.IntType -> "Prim_int"
    ty.FloatType -> "Prim_float"
    ty.StringType -> "Prim_str"
    ty.BooleanType -> "Prim_bool"
    ty.ListType(_) -> "this text does not appear"
  }
}

pub fn error_to_string(error: LexerError) -> String {
  case error {
    l.UnexpectedCommentClose -> "UnexpectedCommentClose"
    l.UnclosedBlockComment -> "UnclosedBlockComment"
    l.UnclosedStringLiteral -> "UnclosedStringLiteral"
  }
}

pub fn token_to_string(token: Token) -> String {
  case token {
    l.DelimiterToken(delimiter) -> delimiter_to_string(delimiter)
    l.KeywordToken(keyword) -> keyword_to_string(keyword)
    l.LiteralToken(primitive) -> literal_to_string(primitive)
    l.TypeToken(type_) -> type_to_string(type_)
    l.ErrorToken(error) -> "Error" <> error_to_string(error)
    l.DebugToken(text) -> "Dbg<" <> text <> ">"
  }
}

pub fn tokens_to_string(tokens: List(Token), join: String) -> String {
  tokens
  |> list.map(token_to_string)
  |> string.join(join)
}

pub fn read_indicated_mode_change(
  text: List(String),
  delimiter_lookup: List(#(String, Delimiter)),
) -> IndicatedModeChange {
  // check if there even is a first character
  case list.first(text) {
    Ok(grapheme) ->
      // there is! match it over stuff we know
      case grapheme {
        // not a delim char. figure out what it is
        v if v == l.string_literal_value -> l.ChangeStringLiteral
        v if v == l.end_of_line_value -> l.ChangeEndOfLine
        v if v == l.white_space_value -> l.ChangeWhiteSpace
        // it didn't match any of that, check if it's a delim instead
        _ ->
          case
            ut.any_start_with(
              list.map(delimiter_lookup, fn(ds_d) { ds_d.0 }),
              grapheme,
            )
          {
            // yes!! figure out which and return it
            Ok(_) ->
              // build the whole delim string
              list.take_while(text, fn(g) {
                ut.any_start_with(
                  list.map(delimiter_lookup, fn(ds_d) { ds_d.0 }),
                  g,
                )
                |> result.is_ok
              })
              |> string.join("")
              // get the proper delim from the lookup and return it
              |> list.key_find(delimiter_lookup, _)
              |> result.unwrap(l.ImpossibleDelim)
              |> l.ChangeNewDelimiter

            // isn't a delim :(
            Error(_) -> l.ChangeNormal
          }
      }
    // there are no more characters!
    Error(_) -> l.ChangeEndOfFile
  }
}

pub fn continue_on_change(mode: Mode, change: IndicatedModeChange) -> Bool {
  case mode, change {
    // stop on all but normal
    l.Normal, l.ChangeNewDelimiter(_) -> False
    l.Normal, l.ChangeStringLiteral -> False
    l.Normal, l.ChangeNormal -> True
    l.Normal, l.ChangeEndOfLine -> False
    l.Normal, l.ChangeWhiteSpace -> False

    // n/a
    l.InDelimiter, _ -> False

    // stop only on string
    l.InStringLiteral, l.ChangeNewDelimiter(_) -> True
    l.InStringLiteral, l.ChangeStringLiteral -> False
    l.InStringLiteral, l.ChangeNormal -> True
    l.InStringLiteral, l.ChangeEndOfLine -> True
    l.InStringLiteral, l.ChangeWhiteSpace -> True

    // stop depending on comment type
    l.InComment(l.CommentOpenDelim),
      l.ChangeNewDelimiter(l.CommentDelim(l.CommentCloseDelim))
    -> False
    l.InComment(_), l.ChangeNewDelimiter(_) -> True
    l.InComment(_), l.ChangeStringLiteral -> True
    l.InComment(_), l.ChangeNormal -> True
    l.InComment(l.CommentLineDelim), l.ChangeEndOfLine -> False
    l.InComment(l.CommentOpenDelim), l.ChangeEndOfLine -> True
    l.InComment(_), l.ChangeWhiteSpace -> True

    // in this scenario we always want to stop to check if there is an error
    l.InComment(l.CommentCloseDelim), _ -> False

    // stop on all but EOL/whitespace
    l.WhiteSpaceConsume, l.ChangeNewDelimiter(_) -> False
    l.WhiteSpaceConsume, l.ChangeStringLiteral -> False
    l.WhiteSpaceConsume, l.ChangeNormal -> False
    l.WhiteSpaceConsume, l.ChangeEndOfLine -> True
    l.WhiteSpaceConsume, l.ChangeWhiteSpace -> True

    // n/a
    l.Finished, _ -> False

    // ALWAYS stop mode when file ends
    _, l.ChangeEndOfFile -> False
  }
}

pub fn split_until_mode_change(
  text: List(String),
  mode: Mode,
  delimiter_lookup: List(#(String, Delimiter)),
) -> #(List(String), List(String), IndicatedModeChange) {
  // emulating a split_while but with an accumulator so we
  // can have the parts accumulate inside the loop
  let #(left_reverse, right, change) =
    ut.accumulate_until(#([], text, l.ChangeNormal), fn(acc) {
      // we don't care what change the accumulator had
      let #(left_reverse, right, _) = acc

      // pop from right to left, reversed
      let left_reverse = [
        list.first(right) |> result.unwrap(""),
        ..left_reverse
      ]
      let right = list.drop(right, 1)

      // check what the change is rn
      let change = read_indicated_mode_change(right, delimiter_lookup)

      // stop or go?
      case continue_on_change(mode, change) {
        True -> list.Continue(#(left_reverse, right, change))
        False -> list.Stop(#(left_reverse, right, change))
      }
    })

  // we built the left side in reverse so now flip and return
  #(list.reverse(left_reverse), right, change)
}

pub fn determine_next_mode(
  change: IndicatedModeChange,
  lexer: Lexer,
) -> #(Coord, Mode) {
  let mode = case change {
    l.ChangeNewDelimiter(l.CommentDelim(comment_delim)) ->
      l.InComment(comment_delim)
    l.ChangeNewDelimiter(_) -> l.InDelimiter
    l.ChangeStringLiteral -> l.InStringLiteral
    l.ChangeEndOfLine -> l.WhiteSpaceConsume
    l.ChangeWhiteSpace -> l.WhiteSpaceConsume
    l.ChangeNormal -> l.Normal
    l.ChangeEndOfFile -> l.Finished
  }

  #(lexer.current_coord, mode)
}
