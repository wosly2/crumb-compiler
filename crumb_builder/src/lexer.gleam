import gleam/bool
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string

import types as ty
import util

/// A spot in a buffer. Row, column format.
pub type Coord =
  #(Int, Int)

pub type Delimiter {
  // math
  AddDelim
  MinusDelim
  MulDelim
  DivDelim
  PowDelim
  ModDelim

  // bit math
  BitAndDelim
  BitOrDelim
  BitNotDelim
  BitShrDelim
  BitShlDelim

  // logic
  EqualDelim
  UnequalDelim
  GreaterDelim
  LessDelim
  GreaterEqualDelim
  LessEqualDelim
  AndDelim
  OrDelim

  // blocking
  ParenthesisOpenDelim
  CurlyBraceOpenDelim
  BracketOpenDelim
  ParenthesisCloseDelim
  CurlyBraceCloseDelim
  BracketCloseDelim

  // control
  CommaDelim
  PeriodDelim

  // impossible state
  ImpossibleDelim
}

/// `Token` is a generic used to describe parsed sections of sourcecode
pub type Token {
  DelimiterToken(Delimiter)
  KeywordToken(ty.Keyword)
  LiteralToken(ty.Value)
  TypeToken(ty.Type)
  DebugToken(String)
}

pub type Span {
  Span(start: Coord, stop: Coord)
}

pub type SpannedToken {
  SpannedToken(Token, Span)
}

pub type Mode {
  Normal
  InDelimiter
  InStringLiteral
  InComment
  WhiteSpaceConsume
  Finished
}

pub type IndicatedModeChange {
  ChangeNewDelimiter
  ChangeStringLiteral
  ChangeEndOfLine
  ChangeWhiteSpace
  ChangeComment
  ChangeNormal
}

pub type Lexer {
  Lexer(
    /// The token accumulator.
    /// Note the accumulator is inverted for performance and must be reversed when read out
    tokens: List(SpannedToken),
    mode: #(Coord, Mode),
    current_coord: Coord,
    delimiter_lookup: List(#(String, Delimiter)),
  )
}

pub fn new_lexer() -> Lexer {
  Lexer(
    tokens: [],
    mode: #(#(0, 0), Normal),
    current_coord: #(0, 0),
    delimiter_lookup: make_delimiter_lookup(),
  )
}

pub fn remove_spans(tokens: List(SpannedToken)) -> List(Token) {
  list.map(tokens, fn(st) {
    let SpannedToken(t, _) = st
    t
  })
}

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
  Lexer(..lexer, current_coord: advance_coord(lexer.current_coord, grapheme))
}

pub fn advance_over(lexer: Lexer, text: List(String)) -> Lexer {
  Lexer(..lexer, current_coord: advance_coord_over(lexer.current_coord, text))
}

pub fn push_token(lexer: Lexer, token: Token) -> Lexer {
  let spanned = SpannedToken(token, Span(lexer.mode.0, lexer.current_coord))
  Lexer(..lexer, tokens: [spanned, ..lexer.tokens])
}

pub fn present_tokens(lexer: Lexer) -> List(SpannedToken) {
  list.reverse(lexer.tokens)
}

pub fn delimiter_to_string(delimiter: Delimiter) -> String {
  case delimiter {
    AddDelim -> "+"
    MinusDelim -> "-"
    MulDelim -> "*"
    DivDelim -> "/"
    PowDelim -> "**"
    ModDelim -> "%"
    BitAndDelim -> "&"
    BitOrDelim -> "|"
    BitNotDelim -> "!"
    BitShrDelim -> ">>"
    BitShlDelim -> "<<"
    EqualDelim -> "=="
    UnequalDelim -> "!="
    GreaterDelim -> ">"
    LessDelim -> "<"
    GreaterEqualDelim -> ">="
    LessEqualDelim -> "<="
    AndDelim -> "&&"
    OrDelim -> "||"
    ParenthesisOpenDelim -> "("
    CurlyBraceOpenDelim -> "{"
    BracketOpenDelim -> "["
    ParenthesisCloseDelim -> ")"
    CurlyBraceCloseDelim -> "}"
    BracketCloseDelim -> "]"
    PeriodDelim -> "."
    CommaDelim -> ","
    ImpossibleDelim -> ""
  }
}

pub fn make_delimiter_lookup() -> List(#(String, Delimiter)) {
  let delims = [
    AddDelim,
    MinusDelim,
    MulDelim,
    DivDelim,
    PowDelim,
    ModDelim,
    BitAndDelim,
    BitOrDelim,
    BitNotDelim,
    BitShrDelim,
    BitShlDelim,
    EqualDelim,
    UnequalDelim,
    GreaterDelim,
    LessDelim,
    GreaterEqualDelim,
    LessEqualDelim,
    AndDelim,
    OrDelim,
    ParenthesisOpenDelim,
    CurlyBraceOpenDelim,
    BracketOpenDelim,
    ParenthesisCloseDelim,
    CurlyBraceCloseDelim,
    BracketCloseDelim,
    CommaDelim,
    PeriodDelim,
    CommaDelim,
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
    ty.IntValue(i) -> "lit_int<" <> int.to_string(i) <> ">"
    ty.FloatValue(f) -> "lit_float<" <> float.to_string(f) <> ">"
    ty.StringValue(s) -> "lit_str<" <> s <> ">"
    ty.BooleanValue(b) -> "lit_b<" <> bool.to_string(b) <> ">"
    ty.ListValue(_, _) -> "this text does not appear"
  }
}

pub fn type_to_string(type_: ty.Type) -> String {
  case type_ {
    ty.IntType -> "prim_int"
    ty.FloatType -> "prim_float"
    ty.StringType -> "prim_str"
    ty.BooleanType -> "prim_bool"
    ty.ListType(_) -> "this text does not appear"
  }
}

pub fn token_to_string(token: Token) -> String {
  case token {
    DelimiterToken(delimiter) -> delimiter_to_string(delimiter)
    KeywordToken(keyword) -> keyword_to_string(keyword)
    LiteralToken(primitive) -> literal_to_string(primitive)
    TypeToken(type_) -> type_to_string(type_)
    DebugToken(text) -> "dbg<" <> text <> ">"
  }
}

pub fn tokens_to_string(tokens: List(Token), join: String) -> String {
  tokens
  |> list.map(token_to_string)
  |> string.join(join)
}

pub fn read_indicated_mode_change(
  grapheme: String,
  delimiter_lookup: List(#(String, Delimiter)),
) -> IndicatedModeChange {
  case
    util.any_start_with(
      list.map(delimiter_lookup, fn(ds_d) { ds_d.0 }),
      grapheme,
    ),
    grapheme
  {
    Ok(_), _ -> ChangeNewDelimiter
    Error(_), "\"" -> ChangeStringLiteral
    Error(_), "\n" -> ChangeEndOfLine
    Error(_), " " -> ChangeWhiteSpace
    Error(_), "#" -> ChangeComment
    Error(_), _ -> ChangeNormal
  }
}

fn split_until_mode_change(
  text: List(String),
  mode: Mode,
  delimiter_lookup: List(#(String, Delimiter)),
) -> #(List(String), List(String)) {
  list.split_while(text, fn(grapheme: String) -> Bool {
    case mode, read_indicated_mode_change(grapheme, delimiter_lookup) {
      // stop on all but normal
      Normal, ChangeNewDelimiter -> False
      Normal, ChangeStringLiteral -> False
      Normal, ChangeNormal -> True
      Normal, ChangeEndOfLine -> False
      Normal, ChangeWhiteSpace -> False
      Normal, ChangeComment -> False

      // n/a
      InDelimiter, _ -> False

      // stop only on string
      InStringLiteral, ChangeNewDelimiter -> True
      InStringLiteral, ChangeStringLiteral -> False
      InStringLiteral, ChangeNormal -> True
      InStringLiteral, ChangeEndOfLine -> True
      InStringLiteral, ChangeWhiteSpace -> True
      InStringLiteral, ChangeComment -> True

      // stop only on EOL
      InComment, ChangeNewDelimiter -> True
      InComment, ChangeStringLiteral -> True
      InComment, ChangeNormal -> True
      InComment, ChangeEndOfLine -> False
      InComment, ChangeWhiteSpace -> True
      InComment, ChangeComment -> True

      // stop on all but EOL/whitespace
      WhiteSpaceConsume, ChangeNewDelimiter -> False
      WhiteSpaceConsume, ChangeStringLiteral -> False
      WhiteSpaceConsume, ChangeNormal -> False
      WhiteSpaceConsume, ChangeEndOfLine -> True
      WhiteSpaceConsume, ChangeWhiteSpace -> True
      WhiteSpaceConsume, ChangeComment -> False

      Finished, _ -> False
    }
  })
}

fn determine_next_mode(rest: List(String), lexer: Lexer) -> #(Coord, Mode) {
  let mode = case list.first(rest) {
    Ok(grapheme) ->
      case read_indicated_mode_change(grapheme, lexer.delimiter_lookup) {
        ChangeNewDelimiter -> #(lexer.current_coord, InDelimiter)
        ChangeStringLiteral -> #(lexer.current_coord, InStringLiteral)
        ChangeEndOfLine -> #(lexer.current_coord, WhiteSpaceConsume)
        ChangeWhiteSpace -> #(lexer.current_coord, WhiteSpaceConsume)
        ChangeNormal -> #(lexer.current_coord, Normal)
        ChangeComment -> #(lexer.current_coord, InComment)
      }
    Error(_) -> #(lexer.current_coord, Finished)
  }
  mode
}

pub fn run_mode_normal(
  text: List(String),
  lexer: Lexer,
) -> #(List(String), Lexer) {
  // get graphemes until mode change
  let #(taken, rest) =
    split_until_mode_change(text, Normal, lexer.delimiter_lookup)

  // advance, push
  let lexer =
    lexer
    |> advance_over(taken)
    |> push_token(DebugToken(string.join(taken, "")))

  // apply next mode
  let lexer = Lexer(..lexer, mode: determine_next_mode(rest, lexer))

  #(rest, lexer)
}

pub fn run_mode_in_delimiter(
  text: List(String),
  lexer: Lexer,
) -> #(List(String), Lexer) {
  #(text, lexer)
}

pub fn run_mode_in_string_literal(
  text: List(String),
  lexer: Lexer,
) -> #(List(String), Lexer) {
  // remove the first string literal to prevent endless loop
  let text = list.drop(text, 1)

  // get graphemes until mode change
  let #(taken, rest) =
    split_until_mode_change(text, InStringLiteral, lexer.delimiter_lookup)

  // remove the second string literal to prevent going into string again
  let rest = list.drop(rest, 1)

  // advance, push
  let lexer =
    lexer
    |> advance_over(taken)
    |> push_token(LiteralToken(ty.StringValue(string.join(taken, ""))))

  // apply next mode
  let lexer = Lexer(..lexer, mode: determine_next_mode(rest, lexer))

  #(rest, lexer)
}

pub fn run_mode_in_comment(
  text: List(String),
  lexer: Lexer,
) -> #(List(String), Lexer) {
  // get graphemes until mode change
  let #(taken, rest) =
    split_until_mode_change(text, InComment, lexer.delimiter_lookup)

  // advance, do not push
  let lexer = lexer |> advance_over(taken)

  // apply next mode
  let lexer = Lexer(..lexer, mode: determine_next_mode(rest, lexer))

  #(rest, lexer)
}

pub fn run_mode_white_space_consume(
  text: List(String),
  lexer: Lexer,
) -> #(List(String), Lexer) {
  // get graphemes until mode change
  let #(taken, rest) =
    split_until_mode_change(text, WhiteSpaceConsume, lexer.delimiter_lookup)

  // advance, do not push
  let lexer = lexer |> advance_over(taken)

  // apply next mode
  let lexer = Lexer(..lexer, mode: determine_next_mode(rest, lexer))

  #(rest, lexer)
}

pub fn run_mode_finished(
  text: List(String),
  lexer: Lexer,
) -> #(List(String), Lexer) {
  #(text, lexer)
}

pub fn run(text: List(String), lexer: Lexer) -> Lexer {
  let #(text, lexer) = case lexer.mode.1 {
    Normal -> run_mode_normal(text, lexer)
    InDelimiter -> run_mode_in_delimiter(text, lexer)
    InStringLiteral -> run_mode_in_string_literal(text, lexer)
    InComment -> run_mode_in_comment(text, lexer)
    WhiteSpaceConsume -> run_mode_white_space_consume(text, lexer)
    Finished -> run_mode_finished(text, lexer)
  }
  case lexer.mode.1 {
    Finished -> lexer
    _ -> run(text, lexer)
  }
}
