import gleam/list
import gleam/string

pub type Either(a, b) {
  Left(a)
  Right(b)
}

pub fn unwrap_left(either: Either(a, _), or: a) -> a {
  case either {
    Left(a) -> a
    Right(_) -> or
  }
}

pub fn unwrap_right(either: Either(_, b), or: b) -> b {
  case either {
    Left(_) -> or
    Right(b) -> b
  }
}

pub fn or_left(either: Either(a, _), or: a) -> Either(a, _) {
  case either {
    Left(_) -> either
    Right(_) -> Left(or)
  }
}

pub fn or_right(either: Either(_, b), or: b) -> Either(_, b) {
  case either {
    Left(_) -> Right(or)
    Right(_) -> either
  }
}

pub fn any_start_with(
  matches: List(String),
  sub: String,
) -> Result(String, Nil) {
  list.find_map(matches, fn(match) {
    case string.starts_with(match, sub) {
      True -> Ok(match)
      False -> Error(Nil)
    }
  })
}

pub fn accumulate_until(
  initial initial: a,
  update update: fn(a) -> list.ContinueOrStop(a),
) -> a {
  case update(initial) {
    list.Continue(acc) -> accumulate_until(acc, update)
    list.Stop(acc) -> acc
  }
}

pub fn try_accumulate_until(
  initial initial: a,
  update update: fn(a) -> Result(list.ContinueOrStop(a), b),
) -> Result(a, b) {
  case update(initial) {
    Ok(list.Continue(next)) -> try_accumulate_until(next, update)
    Ok(list.Stop(final)) -> Ok(final)
    Error(error) -> Error(error)
  }
}
