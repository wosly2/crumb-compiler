import gleam/list
import util as u

pub fn any_start_with_test() {
  let assert Ok("hello") = u.any_start_with(["hello", "bye", "here"], "hell")
  let assert Ok("hello") = u.any_start_with(["hello", "bye", "here"], "h")
  let assert Ok("pears") = u.any_start_with(["pears", "apples"], "")
}

pub fn accumulate_until_test() {
  let assert [] =
    u.accumulate_until(initial: [], update: fn(l) { list.Stop(l) })
  let assert 5 =
    u.accumulate_until(initial: 0, update: fn(n) {
      case n >= 5 {
        True -> list.Stop(n)
        False -> list.Continue(n + 1)
      }
    })
}
// i'm too lazy for this bro
