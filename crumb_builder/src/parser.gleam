import types as ty

pub type Node {
  Block(List(Node))
  PrimitiveNode(ty.Primitive)
}
