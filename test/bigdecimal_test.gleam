import bigdecimal.{type BigDecimal}
import bigi.{type BigInt}
import gleam/list
import gleam/order
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn compare__test() {
  use #(this, that, expected_order) <- list.each([
    // same scale
    #(bigdecimal.from_float(1.23), bigdecimal.from_float(1.23), order.Eq),
    #(bigdecimal.from_float(1.22), bigdecimal.from_float(1.23), order.Lt),
    #(bigdecimal.from_float(1.24), bigdecimal.from_float(1.23), order.Gt),
    // not same scale
    #(
      bigdecimal.from_string("1.2") |> should.be_ok,
      bigdecimal.from_string("1.23") |> should.be_ok,
      order.Lt,
    ),
    #(
      bigdecimal.from_string("-1.3") |> should.be_ok,
      bigdecimal.from_string("-1.23") |> should.be_ok,
      order.Lt,
    ),
    #(
      bigdecimal.from_string("1.23") |> should.be_ok,
      bigdecimal.from_string("1.2") |> should.be_ok,
      order.Gt,
    ),
    #(
      bigdecimal.from_string("-1.23") |> should.be_ok,
      bigdecimal.from_string("-1.2") |> should.be_ok,
      order.Gt,
    ),
  ])

  bigdecimal.compare(this, with: that)
  |> should.equal(expected_order)
}

pub fn absolute_value__test() {
  use #(input, expected) <- list.each([
    #(bigdecimal.from_float(-1.23), bigdecimal.from_float(1.23)),
    #(bigdecimal.from_float(1.23), bigdecimal.from_float(1.23)),
    #(
      bigdecimal.from_string("-7.89E9") |> should.be_ok,
      bigdecimal.from_string("7.89E9") |> should.be_ok,
    ),
    #(
      bigdecimal.from_string("0.1234") |> should.be_ok,
      bigdecimal.from_string("0.1234") |> should.be_ok,
    ),
    #(
      bigdecimal.from_string("-1") |> should.be_ok,
      bigdecimal.from_string("1") |> should.be_ok,
    ),
  ])

  input
  |> bigdecimal.absolute
  |> should.equal(expected)
}

pub fn negation__test() {
  use #(input, expected) <- list.each([
    #(bigdecimal.from_float(-1.23), bigdecimal.from_float(1.23)),
    #(bigdecimal.from_float(1.23), bigdecimal.from_float(-1.23)),
    #(
      bigdecimal.from_string("-7.89E9") |> should.be_ok,
      bigdecimal.from_string("7.89E9") |> should.be_ok,
    ),
    #(
      bigdecimal.from_string("0.1234") |> should.be_ok,
      bigdecimal.from_string("-0.1234") |> should.be_ok,
    ),
    #(
      bigdecimal.from_string("-1") |> should.be_ok,
      bigdecimal.from_string("1") |> should.be_ok,
    ),
  ])

  input
  |> bigdecimal.negate
  |> should.equal(expected)
}

pub fn addition__test() {
  use #(augend, addend, result) <- list.each([
    // same scale
    #(
      bigdecimal.from_float(1.23),
      bigdecimal.from_float(1.23),
      bigdecimal.from_float(2.46),
    ),
    #(
      bigdecimal.from_string("-7.89E9") |> should.be_ok,
      bigdecimal.from_string("7.89E9") |> should.be_ok,
      bigdecimal.from_string("0e7") |> should.be_ok,
    ),
    // augend scale smaller
    #(
      bigdecimal.from_string("1.2") |> should.be_ok,
      bigdecimal.from_string("1.23") |> should.be_ok,
      bigdecimal.from_string("2.43") |> should.be_ok,
    ),
    #(
      bigdecimal.from_string("-7.89E9") |> should.be_ok,
      bigdecimal.from_string("6.11e-1") |> should.be_ok,
      bigdecimal.from_string("-7889999999.389") |> should.be_ok,
    ),
    // addend scale smaller
    #(
      bigdecimal.from_string("1.23") |> should.be_ok,
      bigdecimal.from_string("1.2") |> should.be_ok,
      bigdecimal.from_string("2.43") |> should.be_ok,
    ),
    #(
      bigdecimal.from_string("6.11e-1") |> should.be_ok,
      bigdecimal.from_string("-7.89E9") |> should.be_ok,
      bigdecimal.from_string("-7889999999.389") |> should.be_ok,
    ),
  ])

  bigdecimal.add(augend, addend)
  |> should.equal(result)
}

pub fn subtraction__test() {
  use #(minuend, subtrahend, result) <- list.each([
    // same scale
    #(
      bigdecimal.from_float(1.23),
      bigdecimal.from_float(1.23),
      bigdecimal.from_string("0.00") |> should.be_ok,
    ),
    #(
      bigdecimal.from_string("-7.89E9") |> should.be_ok,
      bigdecimal.from_string("7.89E9") |> should.be_ok,
      bigdecimal.from_string("-15.78e9") |> should.be_ok,
    ),
    // minuend scale smaller
    #(
      bigdecimal.from_string("1.2") |> should.be_ok,
      bigdecimal.from_string("1.23") |> should.be_ok,
      bigdecimal.from_string("-0.03") |> should.be_ok,
    ),
    #(
      bigdecimal.from_string("-7.89E9") |> should.be_ok,
      bigdecimal.from_string("6.11e-1") |> should.be_ok,
      bigdecimal.from_string("-7890000000.611") |> should.be_ok,
    ),
    // subtrahend scale smaller
    #(
      bigdecimal.from_string("1.23") |> should.be_ok,
      bigdecimal.from_string("1.2") |> should.be_ok,
      bigdecimal.from_string("0.03") |> should.be_ok,
    ),
    #(
      bigdecimal.from_string("6.11e-1") |> should.be_ok,
      bigdecimal.from_string("-7.89E9") |> should.be_ok,
      bigdecimal.from_string("7890000000.611") |> should.be_ok,
    ),
  ])

  bigdecimal.subtract(minuend, subtrahend)
  |> should.equal(result)
}

pub fn basic_parse__test() {
  use #(input, expected_unscaled_value, expected_scale) <- list.each([
    // basic
    #("123.45", bigi.from_int(12_345), 2),
    #("0.123", bigi.from_int(123), 3),
    #("123.0", bigi.from_int(1230), 1),
    // leading zeros
    #("000123.45", bigi.from_int(12_345), 2),
    #("0000.12", bigi.from_int(12), 2),
    #("000.000", bigi.from_int(0), 3),
    // negative numbers
    #("-123.45", bigi.from_int(-12_345), 2),
    #("-0.123", bigi.from_int(-123), 3),
    // whitespace
    #(" 123.45 ", bigi.from_int(12_345), 2),
    #("\t 123.45 \r\n", bigi.from_int(12_345), 2),
    // zeros
    #("0", bigi.from_int(0), 0),
    #("0.0", bigi.from_int(0), 1),
    #("-0.0", bigi.from_int(0), 1),
    // trailing/leading decimal point
    #("123.", bigi.from_int(123), 0),
    #("-456.", bigi.from_int(-456), 0),
    #(".789", bigi.from_int(789), 3),
    #("-.123", bigi.from_int(-123), 3),
    // explicit plus sign
    #("+123", bigi.from_int(123), 0),
    #("+123.4", bigi.from_int(1234), 1),
  ])

  from_string_common_assertions(input, expected_unscaled_value, expected_scale)
}

pub fn extreme_parse__test() {
  use #(input, expected_unscaled_value, expected_scale) <- list.each([
    #(
      "123456789123456789123456789.123456789",
      bigi.from_string("123456789123456789123456789123456789"),
      9,
    ),
    #(
      "-123456789123456789123456789.123456789",
      bigi.from_string("-123456789123456789123456789123456789"),
      9,
    ),
    #(
      "0.00000000123456789123456789123456789123456789",
      bigi.from_string("123456789123456789123456789123456789"),
      44,
    ),
    #(
      "-0.00000000123456789123456789123456789123456789",
      bigi.from_string("-123456789123456789123456789123456789"),
      44,
    ),
  ])

  let assert Ok(expected_unscaled_value) = expected_unscaled_value
  from_string_common_assertions(input, expected_unscaled_value, expected_scale)
}

pub fn scientific_notation_parse__test() {
  use #(input, expected_unscaled_value, expected_scale) <- list.each([
    #("1.23E3", bigi.from_string("123"), -1),
    #("4.56E-7", bigi.from_string("456"), 9),
    #("-7.89E9", bigi.from_string("-789"), -7),
    #("1E-32", bigi.from_string("1"), 32),
    #("+1.23e3", bigi.from_string("123"), -1),
    #("4.56e-7", bigi.from_string("456"), 9),
    #("-7.89e9", bigi.from_string("-789"), -7),
    #("-1e32", bigi.from_string("-1"), -32),
  ])

  let assert Ok(expected_unscaled_value) = expected_unscaled_value
  from_string_common_assertions(input, expected_unscaled_value, expected_scale)
}

pub fn parse_fail__test() {
  use input <- list.each([
    "123 .45", "123. 45", "123x", "NaN", "Infinity", "1,234.5", "12.34.56",
    "12e3e4",
  ])

  bigdecimal.from_string(input)
  |> should.be_error
}

pub fn zero__test() {
  let bigd = bigdecimal.zero()
  common_assertions(bigd, bigi.from_int(0), 0)
}

pub fn from_float__test() {
  use #(input, expected_unscaled_value, expected_scale) <- list.each([
    #(0.0123, bigi.from_int(123), 4),
    #(-0.123, bigi.from_int(-123), 3),
    #(1.23, bigi.from_int(123), 2),
    #(12.3, bigi.from_int(123), 1),
    #(-123.456, bigi.from_int(-123_456), 3),
  ])

  let bigd = bigdecimal.from_float(input)
  common_assertions(bigd, expected_unscaled_value, expected_scale)
}

fn from_string_common_assertions(
  input: String,
  expected_unscaled_value: BigInt,
  expected_scale: Int,
) {
  let bigd =
    bigdecimal.from_string(input)
    |> should.be_ok
  common_assertions(bigd, expected_unscaled_value, expected_scale)
}

fn common_assertions(
  value: BigDecimal,
  expected_unscaled_value: BigInt,
  expected_scale: Int,
) {
  value
  |> bigdecimal.unscaled_value
  |> should.equal(expected_unscaled_value)

  value
  |> bigdecimal.scale
  |> should.equal(expected_scale)
}
