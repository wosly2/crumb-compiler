import gleam/bool
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import util

/// A spot in a buffer. Row, column format.
pub type Coord =
  #(Int, Int)

pub type Delimiter {
  AddDelim
  MinusDelim
  MulDelim
  DivDelim
  PowDelim
  ModDelim
  BitAndDelim
  BitOrDelim
  BitNotDelim
  BitShrDelim
  BitShlDelim
  EqualDelim
  UnequalDelim
  GreaterDelim
  LessDelim
  GreaterEqualDelim
  LessEqualDelim
  AndDelim
  OrDelim
  CommaDelim
  ImpossibleDelim
}

/// `Keyword` represents reserved language names
pub type Keyword

/// `Block` is an organizational token used to describe subsections of source code
pub type Block {
  /// Organizational token for a `()` block
  Parentheses(List(Token))
  /// Organizational token for a `[]` block
  Brackets(List(Token))
  /// Organizational token for a `{}` block
  CurlyBrackets(List(Token))
}

/// `Primitive` contains the value of a primitive type
pub type Primitive {
  /// Contains the value of a primitive integer
  Pint(Int)
  /// Contains the value of a primitive floating-point
  Pfloat(Float)
  /// Contains the value of a primitive string
  Pstr(String)
  /// Contains the value of a primitive boolean
  Pbool(Bool)
}

/// `Type` allows data to be tagged with a primitive or custom type
pub type Type {
  /// Primitive integer type tag (represents an `Int`)
  Tint
  /// Primitive floating-point type tag (represents a `Float`)
  Tfloat
  /// Primitive string type tag (represents a `String`)
  Tstr
  /// Primitive boolean type tag (represents a `Bool`)
  Tbool
  Custom(name: String, params: List(#(String, Type)))
}

/// `Token` is a generic used to describe parsed sections of sourcecode
pub type Token {
  DelimiterToken(Delimiter)
  KeywordToken(Keyword)
  BlockToken(Block)
  LiteralToken(Primitive)
  TypeToken(Type)
  DebugToken(String)
  EOL
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
    CommaDelim,
  ]
  list.map2(delims, list.map(delims, delimiter_to_string), fn(d, ds) {
    #(ds, d)
  })
}

pub fn block_to_string(block: Block, join: String) -> String {
  case block {
    Parentheses(tokens) -> "( " <> tokens_to_string(tokens, join) <> " )"
    Brackets(tokens) -> "[ " <> tokens_to_string(tokens, join) <> " ]"
    CurlyBrackets(tokens) -> "{ " <> tokens_to_string(tokens, join) <> " }"
  }
}

pub fn keyword_to_string(keyword: Keyword) -> String {
  case keyword {
    _ -> "kw_other"
  }
}

pub fn primitive_to_string(primitive: Primitive) -> String {
  case primitive {
    Pint(i) -> "lit_int<" <> int.to_string(i) <> ">"
    Pfloat(f) -> "lit_float<" <> float.to_string(f) <> ">"
    Pstr(s) -> "lit_str<" <> s <> ">"
    Pbool(b) -> "lit_b<" <> bool.to_string(b) <> ">"
  }
}

pub fn type_to_string(type_: Type) -> String {
  case type_ {
    Tint -> "prim_int"
    Tfloat -> "prim_float"
    Tstr -> "prim_str"
    Tbool -> "prim_bool"
    Custom(name:, params: _) -> "custom_t<" <> name <> ">"
  }
}

pub fn token_to_string(token: Token, join: String) -> String {
  case token {
    DelimiterToken(delimiter) -> delimiter_to_string(delimiter)
    BlockToken(block) -> block_to_string(block, join)
    KeywordToken(keyword) -> keyword_to_string(keyword)
    LiteralToken(primitive) -> primitive_to_string(primitive)
    TypeToken(type_) -> type_to_string(type_)
    DebugToken(text) -> text
    EOL -> "EOL"
  }
}

pub fn tokens_to_string(tokens: List(Token), join: String) -> String {
  tokens
  |> list.map(token_to_string(_, join))
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
      Normal, ChangeNewDelimiter -> False
      Normal, ChangeStringLiteral -> False
      Normal, ChangeNormal -> True
      Normal, ChangeEndOfLine -> False
      Normal, ChangeWhiteSpace -> False

      InDelimiter, _ -> False

      InStringLiteral, ChangeNewDelimiter -> True
      InStringLiteral, ChangeStringLiteral -> False
      InStringLiteral, ChangeNormal -> True
      InStringLiteral, ChangeEndOfLine -> True
      InStringLiteral, ChangeWhiteSpace -> True

      InComment, ChangeNewDelimiter -> True
      InComment, ChangeStringLiteral -> True
      InComment, ChangeNormal -> True
      InComment, ChangeEndOfLine -> False
      InComment, ChangeWhiteSpace -> True

      WhiteSpaceConsume, ChangeNewDelimiter -> False
      WhiteSpaceConsume, ChangeStringLiteral -> False
      WhiteSpaceConsume, ChangeNormal -> False
      WhiteSpaceConsume, ChangeEndOfLine -> True
      WhiteSpaceConsume, ChangeWhiteSpace -> True

      Finished, _ -> False
    }
  })
}

fn determine_next_mode(rest: List(String), lexer: Lexer) -> #(Coord, Mode) {
  let mode = case list.first(rest) {
    Ok(grapheme) ->
      case
        lexer.mode.1,
        read_indicated_mode_change(grapheme, lexer.delimiter_lookup)
      {
        _, ChangeNewDelimiter -> #(lexer.current_coord, InDelimiter)
        _, ChangeStringLiteral -> #(lexer.current_coord, InStringLiteral)
        _, ChangeEndOfLine -> #(lexer.current_coord, WhiteSpaceConsume)
        _, ChangeWhiteSpace -> #(lexer.current_coord, WhiteSpaceConsume)
        _, ChangeNormal -> #(lexer.current_coord, Normal)
      }
    Error(_) -> #(lexer.current_coord, Finished)
  }
  mode
}

pub fn run_mode_normal(
  text: List(String),
  lexer: Lexer,
) -> #(List(String), Lexer) {
  let #(taken, rest) =
    split_until_mode_change(text, Normal, lexer.delimiter_lookup)

  let lexer =
    lexer
    |> advance_over(taken)
    |> push_token(DebugToken(string.join(taken, "")))

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
  #(text, lexer)
}

pub fn run_mode_in_comment(
  text: List(String),
  lexer: Lexer,
) -> #(List(String), Lexer) {
  #(text, lexer)
}

pub fn run_mode_white_space_consume(
  text: List(String),
  lexer: Lexer,
) -> #(List(String), Lexer) {
  let #(taken, rest) =
    split_until_mode_change(text, WhiteSpaceConsume, lexer.delimiter_lookup)

  let lexer = lexer |> advance_over(taken)
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
