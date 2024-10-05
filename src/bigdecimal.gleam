import bigi.{type BigInt}
import gleam/float
import gleam/int
import gleam/order
import gleam/result
import gleam/string

pub opaque type BigDecimal {
  BigDecimal(
    // unscaled value
    BigInt,
    // scale
    Int,
  )
}

pub fn unscaled_value(value: BigDecimal) -> BigInt {
  let BigDecimal(unscaled_value, ..) = value
  unscaled_value
}

pub fn scale(value: BigDecimal) -> Int {
  let BigDecimal(_, scale, ..) = value
  scale
}

pub fn zero() -> BigDecimal {
  BigDecimal(bigi.from_int(0), 0)
}

pub fn absolute(value: BigDecimal) -> BigDecimal {
  BigDecimal(bigi.absolute(unscaled_value(value)), scale(value))
}

pub fn negate(value: BigDecimal) -> BigDecimal {
  BigDecimal(bigi.negate(unscaled_value(value)), scale(value))
}

pub fn add(augend: BigDecimal, addend: BigDecimal) -> BigDecimal {
  case int.compare(scale(augend), scale(addend)) {
    order.Eq ->
      BigDecimal(
        bigi.add(unscaled_value(augend), unscaled_value(addend)),
        scale(augend),
      )
    order.Lt -> BigDecimal(todo, scale(addend))
    order.Gt -> BigDecimal(todo, scale(augend))
  }
}

pub fn subtract(minuend: BigDecimal, subtrahend: BigDecimal) -> BigDecimal {
  case int.compare(scale(minuend), scale(subtrahend)) {
    order.Eq ->
      BigDecimal(
        bigi.subtract(unscaled_value(minuend), unscaled_value(subtrahend)),
        scale(minuend),
      )
    order.Lt -> BigDecimal(todo, scale(subtrahend))
    order.Gt -> BigDecimal(todo, scale(minuend))
  }
}

pub fn compare(this: BigDecimal, with that: BigDecimal) -> order.Order {
  case scale(this) == scale(that) {
    True -> bigi.compare(unscaled_value(this), unscaled_value(that))
    False -> todo
  }
}

pub fn from_float(value: Float) -> BigDecimal {
  // TODO: this works fine but idk if it could be better/quicker
  let assert Ok(bigd) =
    float.to_string(value)
    |> from_string

  bigd
}

pub fn from_string(value: String) -> Result(BigDecimal, Nil) {
  parse_exponential(value)
}

fn parse_exponential(value: String) -> Result(BigDecimal, Nil) {
  let value = value |> string.trim |> string.lowercase
  case value |> string.split_once("e") {
    Ok(#(number, exponent)) ->
      int.parse(exponent)
      |> result.map(int.negate)
      |> result.try(parse_decimal(number, _))

    Error(_) -> parse_decimal(value, 0)
  }
}

fn parse_decimal(value: String, initial_scale: Int) -> Result(BigDecimal, Nil) {
  case value |> string.split_once(".") {
    Ok(#(before, after)) ->
      parse_unscaled(before <> after, string.byte_size(after) + initial_scale)

    Error(_) -> parse_unscaled(value, initial_scale)
  }
}

fn parse_unscaled(value: String, scale: Int) -> Result(BigDecimal, Nil) {
  bigi.from_string(value)
  |> result.map(BigDecimal(_, scale))
}
