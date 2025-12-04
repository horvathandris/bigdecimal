import bigdecimal/rounding.{
  type RoundingMode, Ceiling, Floor, HalfDown, HalfEven, HalfUp, Up,
}
import bigi.{type BigInt}
import gleam/float
import gleam/int
import gleam/list
import gleam/order.{Eq, Gt, Lt}
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

pub fn unscaled_value(of value: BigDecimal) -> BigInt {
  let BigDecimal(unscaled_value, ..) = value
  unscaled_value
}

pub fn scale(of value: BigDecimal) -> Int {
  let BigDecimal(_, scale, ..) = value
  scale
}

pub fn zero() -> BigDecimal {
  BigDecimal(bigi.from_int(0), 0)
}

pub fn one() -> BigDecimal {
  BigDecimal(bigi.from_int(1), 0)
}

/// The number of digits in the unscaled value.
///
pub fn precision(of value: BigDecimal) -> Int {
  // todo: seems kinda inefficient
  let string_length =
    unscaled_value(value)
    |> bigi.to_string
    |> string.byte_size
  case signum(value) {
    -1 -> string_length - 1
    _ -> string_length
  }
}

pub fn absolute_value(of value: BigDecimal) -> BigDecimal {
  BigDecimal(bigi.absolute(unscaled_value(value)), scale(value))
}

/// Sign function. Returns +1 if the value is positive,
/// -1 if the value is negative, 0 if the value is zero.
///
pub fn signum(of value: BigDecimal) -> Int {
  unscaled_value(value)
  |> bigi.compare(with: bigi.zero())
  |> order.to_int
}

/// Returns the unit of least precision of this `BigDecimal`.
///
pub fn ulp(of value: BigDecimal) -> BigDecimal {
  BigDecimal(bigi.from_int(1), scale(value))
}

pub fn negate(value: BigDecimal) -> BigDecimal {
  BigDecimal(bigi.negate(unscaled_value(value)), scale(value))
}

/// Trim trailing zeros from after the decimal point.
///
pub fn trim_zeros(value: BigDecimal) -> BigDecimal {
  trim_zeros_to_match_scale(value, 0)
}

/// Truncate the `BigDecimal` to a `BigInt`.
///
pub fn truncate_to_bigint(value: BigDecimal) -> BigInt {
  unscaled_value(value)
  |> bigi.divide(multiply_power_of_ten(bigi.from_int(1), scale(value)))
}

/// N.B. if the input has equal value to either of the extremes
/// but different precision, the larger precision will be returned
///
pub fn clamp(
  value: BigDecimal,
  min min: BigDecimal,
  max max: BigDecimal,
) -> BigDecimal {
  case compare(value, min) {
    Eq ->
      case int.compare(scale(value), scale(min)) {
        Eq | Gt -> value
        Lt -> min
      }
    Lt -> min
    Gt ->
      case compare(value, max) {
        Eq ->
          case int.compare(scale(value), scale(max)) {
            Eq | Lt -> value
            Gt -> max
          }
        Gt -> max
        Lt -> value
      }
  }
}

pub fn rescale(
  value: BigDecimal,
  scale new_scale: Int,
  rounding rounding: RoundingMode,
) -> BigDecimal {
  let scale_diff = scale(value) - new_scale
  case int.compare(scale_diff, 0) {
    Eq -> value
    Lt -> add_zeros(value, new_scale, -scale_diff)
    Gt -> rescale_with_rounding(value, new_scale, scale_diff, rounding)
  }
}

fn add_zeros(value: BigDecimal, new_scale: Int, scale_diff: Int) {
  unscaled_value(value)
  |> multiply_power_of_ten(scale_diff)
  |> BigDecimal(new_scale)
}

fn rescale_with_rounding(
  value: BigDecimal,
  new_scale: Int,
  scale_diff: Int,
  rounding: RoundingMode,
) {
  let tens = multiply_power_of_ten(bigi.from_int(1), scale_diff)
  let unscaled = unscaled_value(value)
  let quotient = bigi.divide(unscaled, tens)

  adjust_unscaled_value_for_rounding(
    unscaled,
    signum(value),
    quotient,
    tens,
    rounding,
  )
  |> BigDecimal(new_scale)
}

fn adjust_unscaled_value_for_rounding(
  unscaled_value: BigInt,
  quotient_sign: Int,
  quotient: BigInt,
  divisor: BigInt,
  rounding: RoundingMode,
) {
  let adjustment = case rounding, quotient_sign {
    Floor, s if s < 0 -> bigi.from_int(-1)
    Ceiling, s if s > 0 -> bigi.from_int(1)
    Up, s -> bigi.from_int(s)
    HalfUp, s | HalfDown, s | HalfEven, s if s != 0 ->
      calculate_adjustment_for_half_round(
        unscaled_value,
        s,
        quotient,
        divisor,
        rounding,
      )
    _, _ -> bigi.zero()
  }

  quotient
  |> bigi.add(adjustment)
}

fn calculate_adjustment_for_half_round(
  unscaled_value: BigInt,
  sign: Int,
  quotient: BigInt,
  power_of_ten: BigInt,
  rounding: RoundingMode,
) {
  let remainder =
    bigi.multiply(quotient, power_of_ten)
    |> bigi.subtract(unscaled_value)
    |> bigi.absolute

  let to_compare =
    get_magnitude(remainder, 0)
    |> multiply_power_of_ten(bigi.from_int(5), _)

  case bigi.compare(remainder, to_compare), rounding {
    Eq, HalfEven ->
      case is_even(quotient) {
        True -> bigi.zero()
        False -> bigi.from_int(sign)
      }
    Eq, HalfUp -> bigi.from_int(sign)
    Gt, _ -> bigi.from_int(sign)
    _, _ -> bigi.zero()
  }
}

fn is_even(value: BigInt) {
  case
    bigi.modulo(value, bigi.from_int(2))
    |> bigi.to_int
  {
    Ok(0) -> True
    _ -> False
  }
}

fn get_magnitude(value: BigInt, magnitude: Int) {
  let quotient = bigi.divide(value, bigi.from_int(10))
  case bigi.compare(quotient, bigi.zero()) {
    Lt | Gt -> get_magnitude(quotient, magnitude + 1)
    Eq -> magnitude
  }
}

pub fn add(augend: BigDecimal, addend: BigDecimal) -> BigDecimal {
  case int.subtract(scale(augend), scale(addend)) {
    scale_difference if scale_difference < 0 ->
      scale_adjusted_add(augend, addend, -scale_difference)
    scale_difference if scale_difference > 0 ->
      scale_adjusted_add(addend, augend, scale_difference)
    _same_scale ->
      BigDecimal(
        bigi.add(unscaled_value(augend), unscaled_value(addend)),
        scale(augend),
      )
  }
}

pub fn sum(values: List(BigDecimal)) -> BigDecimal {
  // this may be more efficient? idk need to benchmark
  // list.reduce(over: values, with: add)
  // |> result.lazy_unwrap(zero)
  list.fold(over: values, from: zero(), with: add)
}

pub fn subtract(minuend: BigDecimal, subtrahend: BigDecimal) -> BigDecimal {
  case int.subtract(scale(minuend), scale(subtrahend)) {
    scale_difference if scale_difference < 0 ->
      scale_adjusted_add(minuend, negate(subtrahend), -scale_difference)
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
  unscaled_value(to_scale)
  |> multiply_power_of_ten(scale_difference)
  |> bigi.add(unscaled_value(to_add))
  |> BigDecimal(scale(to_add))
}

fn multiply_power_of_ten(value: BigInt, n: Int) {
  let assert True = n >= 0

  bigi.from_int(10)
  |> bigi.power(bigi.from_int(n))
  // unreachable unwrap
  |> result.lazy_unwrap(fn() { bigi.from_int(0) })
  |> bigi.multiply(value)
}

/// N.B. If scale is different, trailing zeros are ignored.
///
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

pub fn multiply(
  multiplicand: BigDecimal,
  with multiplier: BigDecimal,
) -> BigDecimal {
  BigDecimal(
    bigi.multiply(unscaled_value(multiplicand), unscaled_value(multiplier)),
    int.add(scale(multiplicand), scale(multiplier)),
  )
}

/// For an empty list, this will return `one()`.
///
pub fn product(values: List(BigDecimal)) -> BigDecimal {
  // this may be more efficient? idk need to benchmark
  // list.reduce(over: values, with: multiply)
  // |> result.lazy_unwrap(one)
  list.fold(over: values, from: one(), with: multiply)
}

/// Divide the dividend by the divisor.
/// The result has a preferred scale of `scale(dividend) - scale(divisor)`,
/// but might have scale up to `precision(dividend) + ceil(10 * precision(divisor) / 3)`.
///
pub fn divide(
  dividend: BigDecimal,
  by divisor: BigDecimal,
  rounding rounding: RoundingMode,
) -> BigDecimal {
  let new_scale = scale(dividend) - scale(divisor)
  case signum(dividend), signum(divisor) {
    _, 0 -> zero()
    0, _ -> BigDecimal(bigi.from_int(0), new_scale)
    _, _ -> divide_internal(dividend, divisor, new_scale, rounding)
  }
}

fn divide_internal(
  dividend: BigDecimal,
  divisor: BigDecimal,
  preferred_scale: Int,
  rounding: RoundingMode,
) {
  let new_scale =
    { 10 * precision(divisor) }
    |> int.to_float
    |> float.divide(3.0)
    // unreachable unwrap
    |> result.lazy_unwrap(fn() { 0.0 })
    |> float.ceiling
    |> float.round
    |> int.add(precision(dividend))

  case scale(divisor) - scale(dividend) + new_scale {
    x if x > 0 ->
      unscaled_value(dividend)
      |> multiply_power_of_ten(x)
      |> divide_and_round(unscaled_value(divisor), new_scale, rounding)
    x ->
      unscaled_value(divisor)
      |> multiply_power_of_ten(-x)
      |> divide_and_round(unscaled_value(dividend), _, new_scale, rounding)
  }
  |> trim_zeros_to_match_scale(preferred_scale)
}

fn divide_and_round(
  dividend: BigInt,
  divisor: BigInt,
  scale: Int,
  rounding: RoundingMode,
) {
  let quotient = bigi.divide(dividend, divisor)

  let quotient_sign =
    bigi.compare(quotient, bigi.zero())
    |> order.to_int

  let remainder = bigi.remainder(dividend, divisor)

  case bigi.compare(remainder, bigi.zero()) {
    Eq -> BigDecimal(quotient, scale)
    Lt | Gt ->
      adjust_unscaled_value_for_rounding(
        dividend,
        quotient_sign,
        quotient,
        divisor,
        rounding,
      )
      |> BigDecimal(scale)
  }
}

/// trims trailing zeros until the requested scale
/// is reached or no more zeros can be trimmed
///
fn trim_zeros_to_match_scale(value: BigDecimal, preferred_scale: Int) {
  case scale(value) > preferred_scale {
    False -> value
    True -> {
      let non_zero_remainder =
        unscaled_value(value)
        |> bigi.remainder(bigi.from_int(10))
        |> bigi.compare(bigi.zero())
        != Eq

      case non_zero_remainder {
        True -> value
        False ->
          trim_zeros_to_match_scale(
            unscaled_value(value)
              |> bigi.divide(bigi.from_int(10))
              |> BigDecimal(scale(value) - 1),
            preferred_scale,
          )
      }
    }
  }
}

/// Computes the **truncating remainder** of two `BigDecimal` values.
///
/// The sign of the result always matches the sign of `value`
/// (the dividend), and the remainder may be negative.
///
/// Follows the standard Gleam divide-by-zero rule of 0 when the divisor is 0.
///
/// Note: This is **not** a modulo operation.
///
pub fn remainder(value: BigDecimal, divisor: BigDecimal) -> BigDecimal {
  let common_scale = int.max(scale(value), scale(divisor))
  bigi.remainder(
    rescale(value, common_scale, Floor)
      |> unscaled_value,
    rescale(divisor, common_scale, Floor)
      |> unscaled_value,
  )
  |> BigDecimal(common_scale)
}

/// Returns an error if the exponent is negative.
/// (Inherited behaviour from `bigi`)
///
pub fn power(value: BigDecimal, exponent: Int) {
  unscaled_value(value)
  |> bigi.power(bigi.from_int(exponent))
  |> result.map(BigDecimal(_, int.multiply(scale(value), exponent)))
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
