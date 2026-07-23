pub type Node {
  Block(List(Node))
  PrimitiveNode(Primitive)
}

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
