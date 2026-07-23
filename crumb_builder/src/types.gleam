/// `Keyword` represents reserved language names
pub type Keyword

pub type Block {
  Parentheses
  Brackets
  CurlyBraces
}

pub type Type {
  IntType
  FloatType
  StringType
  BooleanType
  ListType(Type)
}

pub type Value {
  IntValue(Int)
  FloatValue(Float)
  StringValue(String)
  BooleanValue(Bool)
  ListValue(Type, List(Value))
}
