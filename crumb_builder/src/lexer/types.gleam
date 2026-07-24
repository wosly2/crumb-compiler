import gleam/option.{type Option}
import types as ty

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
  ColonDelim

  // assignment
  EqualsDelim
  ReturnsDelim

  // comments
  CommentDelim(CommentDelimiter)

  // string
  StringLiteralDelim

  // whitespace
  WhiteSpaceDelim
  NewLineDelim
}

pub type CommentDelimiter {
  CommentLineDelim
  CommentOpenDelim
  CommentCloseDelim
}

/// `Token` is a generic used to describe parsed sections of sourcecode
pub type Token {
  DelimiterToken(Delimiter)
  KeywordToken(ty.Keyword)
  LiteralToken(ty.Value)
  SymbolToken(String)
  ErrorToken(LexerError)
  DebugToken(String)
}

pub type LexerError {
  UnexpectedCommentClose
  UnclosedBlockComment
  UnclosedStringLiteral
}

pub type Span {
  Span(start: Coord, stop: Coord)
}

pub type SpannedToken {
  SpannedToken(Token, Span)
}

pub type Mode {
  ConsumeNormal
  ConsumeDelimiter(Delimiter)
  ConsumeString
  ConsumeComment(CommentDelimiter)
  ConsumeWhiteSpace
  Finished
}

pub type ModeOutput {
  ModeOutput(taken: List(String), rest: List(String), token: Option(Token))
}

pub type ModeInput {
  ModeInput(
    text: List(String),
    delimiter_lookup: List(#(String, Delimiter)),
    keyword_lookup: List(#(String, ty.Keyword)),
  )
}

pub type ModeFunction =
  fn(ModeInput) -> ModeOutput

pub type TextReaderChange {
  HitDelimiter(Delimiter)
  HitGrapheme
  HitEndOfFile
}

pub type Lexer {
  Lexer(
    /// The token accumulator.
    /// Note the accumulator is inverted for performance and must be reversed when read out
    tokens: List(SpannedToken),
    mode: #(Coord, Mode),
    current_coord: Coord,
    delimiter_lookup: List(#(String, Delimiter)),
    keyword_lookup: List(#(String, ty.Keyword)),
    iterations: Int,
    max_iterations: Option(Int),
    // the log is also inverted for performance. tick, message
    log: Option(List(#(Int, String))),
  )
}
