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
  case int.subtract(scale(augend), scale(addend)) {
    scale_difference if scale_difference < 0 ->
      scale_adjusted_add(augend, addend, scale_difference)
    scale_difference if scale_difference > 0 ->
      scale_adjusted_add(addend, augend, scale_difference)
    _same_scale ->
      BigDecimal(
        bigi.add(unscaled_value(augend), unscaled_value(addend)),
        scale(augend),
      )
  }
}

pub fn subtract(minuend: BigDecimal, subtrahend: BigDecimal) -> BigDecimal {
  case int.subtract(scale(minuend), scale(subtrahend)) {
    scale_difference if scale_difference < 0 ->
      scale_adjusted_add(minuend, negate(subtrahend), scale_difference)
    scale_difference if scale_difference > 0 ->
      scale_adjusted_add(negate(subtrahend), minuend, scale_difference)
    _same_scale ->
      BigDecimal(
        bigi.subtract(unscaled_value(minuend), unscaled_value(subtrahend)),
        scale(minuend),
      )
  }
}

fn scale_adjusted_add(
  to_scale: BigDecimal,
  to_add: BigDecimal,
  scale_difference: Int,
) -> BigDecimal {
  // TODO: wonder if this could be sped up somehow
  let assert Ok(new_unscaled_value) =
    int.absolute_value(scale_difference)
    |> bigi.from_int
    |> bigi.power(bigi.from_int(10), _)
    |> result.map(bigi.multiply(_, unscaled_value(to_scale)))
    |> result.map(bigi.add(_, unscaled_value(to_add)))
  BigDecimal(new_unscaled_value, scale(to_add))
}

pub fn compare(this: BigDecimal, with that: BigDecimal) -> order.Order {
  case int.subtract(scale(this), scale(that)) {
    scale_difference if scale_difference < 0 ->
      scale_adjusted_compare(this, that, scale_difference)
    scale_difference if scale_difference > 0 ->
      scale_adjusted_compare(that, this, scale_difference)
      |> order.negate
    _same_scale -> bigi.compare(unscaled_value(this), unscaled_value(that))
  }
}

fn scale_adjusted_compare(
  to_scale: BigDecimal,
  to_compare: BigDecimal,
  scale_difference: Int,
) -> order.Order {
  // TODO: wonder if this could be sped up somehow
  let assert Ok(compare_order) =
    int.absolute_value(scale_difference)
    |> bigi.from_int
    |> bigi.power(bigi.from_int(10), _)
    |> result.map(bigi.multiply(_, unscaled_value(to_scale)))
    |> result.map(bigi.compare(_, unscaled_value(to_compare)))
  compare_order
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
