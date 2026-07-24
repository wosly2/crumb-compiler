import gleam/bool
import gleam/float
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string

import lexer/types.{
  type Coord, type Delimiter, type Lexer, type LexerError, type Mode,
  type TextReaderChange as Change, type Token,
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
    l.ColonDelim -> ":"
    l.StringLiteralDelim -> "\""
    l.WhiteSpaceDelim -> " "
    l.NewLineDelim -> "\n"
    l.ImpossibleDelim -> "UhOh!"
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
    l.ColonDelim,
    l.StringLiteralDelim,
    l.WhiteSpaceDelim,
    l.NewLineDelim,
    // don't forget to put other delims here, but NOT ImpossibleDelim
  ]
  list.map2(delims, list.map(delims, delimiter_to_string), fn(d, ds) {
    #(ds, d)
  })
}

pub fn delimiter_length(delim: Delimiter) -> Int {
  delim |> delimiter_to_string |> string.length
}

pub fn keyword_to_string(keyword: ty.Keyword) -> String {
  case keyword {
    _ -> "other"
  }
}

pub fn literal_to_string(primitive: ty.Value) -> String {
  case primitive {
    ty.IntValue(i) -> int.to_string(i)
    ty.FloatValue(f) -> float.to_string(f)
    ty.StringValue(s) -> s
    ty.BooleanValue(b) -> bool.to_string(b)
    ty.ListValue(_, _) -> "this text does not appear"
  }
}

pub fn type_to_string(type_: ty.Type) -> String {
  case type_ {
    ty.IntType -> "int"
    ty.FloatType -> "float"
    ty.StringType -> "str"
    ty.BooleanType -> "bool"
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
    l.LiteralToken(literal) -> literal_to_string(literal)
    l.TypeToken(type_) -> type_to_string(type_)
    l.ErrorToken(error) -> error_to_string(error)
    l.DebugToken(text) -> text
  }
}

pub fn token_to_string_debug(token: Token) -> String {
  case token {
    l.DelimiterToken(_) -> "Del"
    l.KeywordToken(_) -> "Kyw"
    l.LiteralToken(_) -> "Lit"
    l.TypeToken(_) -> "Typ"
    l.ErrorToken(_) -> "Err"
    l.DebugToken(_) -> "Dbg"
  }
  <> "<"
  <> token_to_string(token)
  |> ut.visible_whitespace
  <> ">"
}

pub fn match_longest_delimiter(
  text: List(String),
  delimiter_lookup: List(#(String, Delimiter)),
) -> Result(Delimiter, Nil) {
  let #(_, prefix) =
    ut.accumulate_until(initial: #(text, option.None), update: fn(acc) {
      let #(rest, prefix_builder) = acc

      // has first, is created?
      case list.first(rest), prefix_builder {
        Ok(grapheme), option.Some(prefix_string) -> {
          // build
          let new_prefix_string = string.append(prefix_string, grapheme)

          // see if it matches now
          case ut.any_start_with(ut.keys(delimiter_lookup), new_prefix_string) {
            // it does now, keep going (also drop from rest to make sure the text progresses)
            Ok(_) ->
              list.Continue(#(
                list.drop(rest, 1),
                option.Some(new_prefix_string),
              ))

            Error(_) ->
              // it does not now. if prefix_string has a length greater than 0,
              // then we know that it had to match, and is therefore the longest match.
              // otherwise, there is no match (as prefix_string_new is the first character)
              case string.is_empty(prefix_string) {
                // there is no match
                True -> list.Stop(#(rest, option.None))
                False -> list.Stop(#(rest, option.Some(prefix_string)))
              }
          }
        }
        // there is a first but we need to build the delim
        Ok(_), option.None -> {
          list.Continue(#(rest, option.Some("")))
        }
        // all out :( return as is
        Error(_), _ -> list.Stop(#(rest, prefix_builder))
      }
    })

  // check if the prefix actually matches with any delim strings, then return delim
  prefix
  |> option.map(list.key_find(delimiter_lookup, _))
  |> option.to_result(Nil)
  |> result.flatten
}

pub fn read_changes(
  text: List(String),
  delimiter_lookup: List(#(String, Delimiter)),
) -> Change {
  case list.is_empty(text), match_longest_delimiter(text, delimiter_lookup) {
    True, _ -> l.HitEndOfFile
    False, Ok(delimiter) -> l.HitDelimiter(delimiter)
    False, Error(_) -> l.HitGrapheme
  }
}

// determine whether to keep taking graphemes depending on the mode and change
pub fn continue_on_change(mode: Mode, change: Change) -> Bool {
  case mode, change {
    // always stop on EOF
    _, l.HitEndOfFile -> False

    // n/a?
    l.Finished, _ -> False

    // -----------------------------------------------------------------------
    // stop on all but normal
    l.ConsumeNormal, l.HitGrapheme -> True
    l.ConsumeNormal, _ -> False

    // stop on all but hit delim
    l.ConsumeDelimiter(_), l.HitDelimiter(_) -> True
    l.ConsumeDelimiter(_), _ -> False

    // stop on string lit
    l.ConsumeString, l.HitDelimiter(l.StringLiteralDelim) -> False
    l.ConsumeString, _ -> True

    // stop on newline if line type
    l.ConsumeComment(l.CommentLineDelim), l.HitDelimiter(l.NewLineDelim) ->
      False
    // stop on closing if block type
    l.ConsumeComment(l.CommentOpenDelim),
      l.HitDelimiter(l.CommentDelim(l.CommentCloseDelim))
    -> False
    // malformed, always stop here
    l.ConsumeComment(l.CommentCloseDelim), _ -> False
    // otherwise go
    l.ConsumeComment(_), _ -> True

    // stop on not whitespace/newline
    l.ConsumeWhiteSpace, l.HitDelimiter(l.NewLineDelim) -> True
    l.ConsumeWhiteSpace, l.HitDelimiter(l.WhiteSpaceDelim) -> True
    l.ConsumeWhiteSpace, _ -> False
  }
}

pub fn split_until_change(
  text: List(String),
  mode: Mode,
  delimiter_lookup: List(#(String, Delimiter)),
) -> #(List(String), List(String), Change) {
  // emulating a split_while but with an accumulator so we
  // can have the parts accumulate inside the loop
  let #(left_reverse, right, change) =
    ut.accumulate_until(#([], text, l.HitEndOfFile), fn(acc) {
      // we don't care what change the accumulator had (the EOF above is placeholder)
      let #(left_reverse, right, _) = acc

      // check what the change is rn
      let change = read_changes(right, delimiter_lookup)

      // stop or go?
      case continue_on_change(mode, change) {
        True -> {
          // build left reversed from right
          let left_reverse = [
            list.first(right) |> result.unwrap(""),
            ..left_reverse
          ]
          let right = list.drop(right, 1)

          list.Continue(#(left_reverse, right, change))
        }
        False -> list.Stop(#(left_reverse, right, change))
      }
    })

  // flip left side before return
  #(list.reverse(left_reverse), right, change)
}

pub fn determine_next_mode(change: Change, lexer: Lexer) -> #(Coord, Mode) {
  let mode = case change {
    l.HitDelimiter(delim) ->
      case delim {
        l.CommentDelim(comment_delim) -> l.ConsumeComment(comment_delim)
        l.StringLiteralDelim -> l.ConsumeString
        l.WhiteSpaceDelim | l.NewLineDelim -> l.ConsumeWhiteSpace
        _ -> l.ConsumeDelimiter(delim)
      }
    l.HitGrapheme -> l.ConsumeNormal
    l.HitEndOfFile -> l.Finished
  }

  #(lexer.current_coord, mode)
}
