/// `Keyword` represents reserved language names
pub type Keyword

pub type BlockType {
  Parentheses
  Brackets
  CurlyBraces
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

  /// Custom-defined type
  Custom(name: String, params: List(#(String, Type)))
}
