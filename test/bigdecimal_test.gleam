import bigdecimal.{type BigDecimal}
import bigdecimal/rounding
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
    #(bigd("1.23"), bigd("1.23"), order.Eq),
    #(bigd("1.22"), bigd("1.23"), order.Lt),
    #(bigd("1.24"), bigd("1.23"), order.Gt),
    // not same scale
    #(bigd("-1.2"), bigd("-1.20"), order.Eq),
    #(bigd("0.0"), bigd("0.00"), order.Eq),
    #(bigd("-7.3e-2"), bigd("-73e-3"), order.Eq),
    #(bigd("1.2"), bigd("1.23"), order.Lt),
    #(bigd("-1.3"), bigd("-1.23"), order.Lt),
    #(bigd("1.23"), bigd("1.2"), order.Gt),
    #(bigd("-1.23"), bigd("-1.3"), order.Gt),
  ])

  bigdecimal.compare(this, with: that)
  |> should.equal(expected_order)
}

pub fn absolute_value__test() {
  use #(input, expected) <- list.each([
    #(bigd("-1.23"), bigd("1.23")),
    #(bigd("1.23"), bigd("1.23")),
    #(bigd("-7.89E9"), bigd("7.89E9")),
    #(bigd("0.1234"), bigd("0.1234")),
    #(bigd("-1"), bigd("1")),
  ])

  bigdecimal.absolute_value(of: input)
  |> should.equal(expected)
}

pub fn precision__test() {
  use #(input, expected_precision) <- list.each([
    #(bigd("0.000"), 1),
    #(bigd("-1.23"), 3),
    #(bigd("1.23"), 3),
    #(bigd("12345.67890"), 10),
    #(bigd("0.0000000009"), 1),
  ])

  bigdecimal.precision(of: input)
  |> should.equal(expected_precision)
}

pub fn signum__test() {
  use #(input, expected_sign) <- list.each([
    #(bigd("0.000"), 0),
    #(bigd("-1.23"), -1),
    #(bigd("1.23"), 1),
  ])

  bigdecimal.signum(of: input)
  |> should.equal(expected_sign)
}

pub fn ulp__test() {
  use #(input, expected_ulp) <- list.each([
    #(bigd("0.000"), bigd("0.001")),
    #(bigd("-1.23"), bigd("0.01")),
    #(bigd("3e-7"), bigd("0.0000001")),
    #(bigd("650"), bigd("1")),
  ])

  bigdecimal.ulp(of: input)
  |> should.equal(expected_ulp)
}

pub fn negation__test() {
  use #(input, expected) <- list.each([
    #(bigd("-1.23"), bigd("1.23")),
    #(bigd("1.23"), bigd("-1.23")),
    #(bigd("-7.89E9"), bigd("7.89E9")),
    #(bigd("0.1234"), bigd("-0.1234")),
    #(bigd("-1"), bigd("1")),
  ])

  bigdecimal.negate(input)
  |> should.equal(expected)
}

pub fn trim_zeros__test() {
  use #(input, expected) <- list.each([
    #(bigd("-1.23"), bigd("-1.23")),
    #(bigd("-1.230000000"), bigd("-1.23")),
    #(bigd("1000"), bigd("1000")),
  ])

  bigdecimal.trim_zeros(input)
  |> should.equal(expected)
}

pub fn truncate_to_bigint__test() {
  use #(input, expected) <- list.each([
    #(bigd("-1.23"), bigi.from_int(-1)),
    #(bigd("0.123123"), bigi.from_int(0)),
    #(bigd("1000"), bigi.from_int(1000)),
  ])

  bigdecimal.truncate_to_bigint(input)
  |> should.equal(expected)
}

pub fn simple_rescale__test() {
  use #(input, new_scale, expected) <- list.each([
    // same scale
    #(bigd("2.1e-3"), 4, bigd("2.1e-3")),
    // bigger scale
    #(bigd("1"), 5, bigd("1.00000")),
    #(bigd("-0.123"), 4, bigd("-0.1230")),
  ])

  use rounding <- list.each([
    rounding.Floor,
    rounding.Ceiling,
    rounding.Down,
    rounding.Up,
    rounding.HalfDown,
    rounding.HalfUp,
    rounding.HalfEven,
  ])

  bigdecimal.rescale(input, scale: new_scale, rounding:)
  |> should.equal(expected)
}

pub fn clamp__test() {
  use #(input, min, max, expected) <- list.each([
    #(bigd("1"), bigd("0"), bigd("2"), bigd("1")),
    #(bigd("0.000001"), bigd("0.001"), bigd("0.02"), bigd("0.001")),
    #(bigd("-2.4"), bigd("-3.5"), bigd("-3.3"), bigd("-3.3")),
    // no precision loss
    #(bigd("3.00e12"), bigd("3e12"), bigd("1e13"), bigd("3.00e12")),
  ])

  bigdecimal.clamp(input, min:, max:)
  |> should.equal(expected)
}

pub fn rescale__test() {
  use #(input, new_scale, rounding, expected) <- list.each([
    // smaller scale - Floor
    #(bigd("0.00000"), 3, rounding.Floor, bigd("0.000")),
    #(bigd("1.987"), 2, rounding.Floor, bigd("1.98")),
    #(bigd("-1.234"), 0, rounding.Floor, bigd("-2")),
    // smaller scale - Ceiling
    #(bigd("0.00000"), 3, rounding.Ceiling, bigd("0.000")),
    #(bigd("1.987"), 2, rounding.Ceiling, bigd("1.99")),
    #(bigd("-1.234"), 0, rounding.Ceiling, bigd("-1")),
    // smaller scale - Up
    #(bigd("0.00000"), 3, rounding.Up, bigd("0.000")),
    #(bigd("1.234"), 2, rounding.Up, bigd("1.24")),
    #(bigd("-1.234"), 0, rounding.Up, bigd("-2")),
    // smaller scale - Down
    #(bigd("0.00000"), 3, rounding.Down, bigd("0.000")),
    #(bigd("1.987"), 2, rounding.Down, bigd("1.98")),
    #(bigd("-1.987"), 0, rounding.Down, bigd("-1")),
    // smaller scale - HalfUp
    #(bigd("0.00000"), 3, rounding.HalfUp, bigd("0.000")),
    #(bigd("1.234"), 2, rounding.HalfUp, bigd("1.23")),
    #(bigd("1.235"), 2, rounding.HalfUp, bigd("1.24")),
    #(bigd("1.236"), 2, rounding.HalfUp, bigd("1.24")),
    #(bigd("-1.499"), 0, rounding.HalfUp, bigd("-1")),
    #(bigd("-1.500"), 0, rounding.HalfUp, bigd("-2")),
    #(bigd("-1.501"), 0, rounding.HalfUp, bigd("-2")),
    // smaller scale - HalfDown
    #(bigd("0.00000"), 3, rounding.HalfDown, bigd("0.000")),
    #(bigd("1.234"), 2, rounding.HalfDown, bigd("1.23")),
    #(bigd("1.235"), 2, rounding.HalfDown, bigd("1.23")),
    #(bigd("1.236"), 2, rounding.HalfDown, bigd("1.24")),
    #(bigd("-1.499"), 0, rounding.HalfDown, bigd("-1")),
    #(bigd("-1.500"), 0, rounding.HalfDown, bigd("-1")),
    #(bigd("-1.501"), 0, rounding.HalfDown, bigd("-2")),
    // smaller scale - HalfEven
    #(bigd("0.00000"), 3, rounding.HalfEven, bigd("0.000")),
    #(bigd("1.234"), 2, rounding.HalfEven, bigd("1.23")),
    #(bigd("1.235"), 2, rounding.HalfEven, bigd("1.24")),
    #(bigd("1.236"), 2, rounding.HalfEven, bigd("1.24")),
    #(bigd("1.224"), 2, rounding.HalfEven, bigd("1.22")),
    #(bigd("1.225"), 2, rounding.HalfEven, bigd("1.22")),
    #(bigd("1.226"), 2, rounding.HalfEven, bigd("1.23")),
    #(bigd("-2.499"), 0, rounding.HalfEven, bigd("-2")),
    #(bigd("-2.500"), 0, rounding.HalfEven, bigd("-2")),
    #(bigd("-2.501"), 0, rounding.HalfEven, bigd("-3")),
    #(bigd("-1.499"), 0, rounding.HalfEven, bigd("-1")),
    #(bigd("-1.500"), 0, rounding.HalfEven, bigd("-2")),
    #(bigd("-1.501"), 0, rounding.HalfEven, bigd("-2")),
  ])

  bigdecimal.rescale(input, scale: new_scale, rounding:)
  |> should.equal(expected)
}

pub fn addition__test() {
  use #(augend, addend, result) <- list.each([
    // same scale
    #(bigd("1.23"), bigd("1.23"), bigd("2.46")),
    #(bigd("-7.89E9"), bigd("7.89E9"), bigd("0e7")),
    // augend scale smaller
    #(bigd("1.2"), bigd("1.23"), bigd("2.43")),
    #(bigd("-7.89E9"), bigd("6.11e-1"), bigd("-7889999999.389")),
    // addend scale smaller
    #(bigd("1.23"), bigd("1.2"), bigd("2.43")),
    #(bigd("6.11e-1"), bigd("-7.89E9"), bigd("-7889999999.389")),
  ])

  bigdecimal.add(augend, addend)
  |> should.equal(result)
}

pub fn sum__test() {
  use #(inputs, expected_sum) <- list.each([
    #([], bigdecimal.zero()),
    #([bigd("1.00"), bigd("1"), bigd("0.1")], bigd("2.10")),
  ])

  bigdecimal.sum(inputs)
  |> should.equal(expected_sum)
}

pub fn subtraction__test() {
  use #(minuend, subtrahend, result) <- list.each([
    // same scale
    #(bigd("1.23"), bigd("1.23"), bigd("0.00")),
    #(bigd("-7.89E9"), bigd("7.89E9"), bigd("-15.78e9")),
    // minuend scale smaller
    #(bigd("1.2"), bigd("1.23"), bigd("-0.03")),
    #(bigd("-7.89E9"), bigd("6.11e-1"), bigd("-7890000000.611")),
    // subtrahend scale smaller
    #(bigd("1.23"), bigd("1.2"), bigd("0.03")),
    #(bigd("6.11e-1"), bigd("-7.89E9"), bigd("7890000000.611")),
  ])

  bigdecimal.subtract(minuend, subtrahend)
  |> should.equal(result)
}

pub fn multiplication__test() {
  use #(this, that, expected_product) <- list.each([
    #(bigd("0.123"), bigd("1.23"), bigd("0.15129")),
    #(bigd("0.0"), bigd("-12.93"), bigd("0.000")),
    #(bigd("-3e2"), bigd("-0.2e4"), bigd("6e5")),
  ])

  bigdecimal.multiply(this, with: that)
  |> should.equal(expected_product)
}

pub fn product__test() {
  use #(inputs, expected_product) <- list.each([
    #([], bigd("1")),
    #([bigd("-3e-2")], bigd("-3e-2")),
    #([bigd("0.123"), bigd("1.23"), bigd("1.0")], bigd("0.151290")),
    #([bigd("0.0"), bigd("-12.93"), bigd("0.00")], bigd("0.00000")),
  ])

  bigdecimal.product(inputs)
  |> should.equal(expected_product)
}

pub fn division__test() {
  use #(input, divisor, rounding, expected_quotient) <- list.each([
    // dividend is zero
    #(bigd("0.00"), bigd("92.71245"), rounding.Floor, bigd("0e3")),
    // divisor is zero
    #(bigd("92.71245"), bigd("0.000"), rounding.Floor, bigd("0")),
    // non-edge cases
    #(bigd("1"), bigd("2"), rounding.Floor, bigd("0.5")),
    #(bigd("1.25"), bigd("10"), rounding.Floor, bigd("0.125")),
    #(bigd("1.00000000"), bigd("20"), rounding.Floor, bigd("0.05000000")),
    #(bigd("1"), bigd("3"), rounding.Floor, bigd("0.33333")),
    #(bigd("0.333"), bigd("0.33"), rounding.Floor, bigd("1.009090909")),
    #(bigd("-0.123"), bigd("0.4"), rounding.Floor, bigd("-0.3075")),
    #(bigd("-0.123"), bigd("-0.4"), rounding.Floor, bigd("0.3075")),
  ])

  bigdecimal.divide(input, by: divisor, rounding:)
  |> should.equal(expected_quotient)
}

pub fn remainder__test() {
  use #(input, divisor, expected_remainder) <- list.each([
    // basic positives
    #(bigd("10"), bigd("3"), bigd("1")),
    #(bigd("10"), bigd("4"), bigd("2")),
    #(bigd("1.5"), bigd("0.5"), bigd("0.0")),
    #(bigd("1.5"), bigd("0.2"), bigd("0.1")),

    // scale mismatch (divisor scale > value scale)
    #(bigd("1"), bigd("0.01"), bigd("0.00")),
    #(bigd("1.23"), bigd("0.456"), bigd("0.318")),
    #(bigd("0.5"), bigd("0.005"), bigd("0.000")),
    #(bigd("0.5"), bigd("0.002"), bigd("0.000")),
    #(bigd("0.5"), bigd("0.003"), bigd("0.002")),

    // negative dividend (trunc toward zero is key)
    #(bigd("-10"), bigd("3"), bigd("-1")),
    #(bigd("-10"), bigd("4"), bigd("-2")),
    #(bigd("-1.5"), bigd("0.5"), bigd("0.0")),
    #(bigd("-1.5"), bigd("0.2"), bigd("-0.1")),

    // negative divisor
    #(bigd("10"), bigd("-3"), bigd("1")),
    #(bigd("-10"), bigd("-3"), bigd("-1")),

    // opposite sign fractional
    #(bigd("1.23"), bigd("-0.456"), bigd("0.318")),
    #(bigd("-1.23"), bigd("0.456"), bigd("-0.318")),

    // a = 0
    #(bigd("0"), bigd("5"), bigd("0")),
    #(bigd("0"), bigd("-5"), bigd("0")),
    #(bigd("0"), bigd("0.0001"), bigd("0.0000")),

    // tiny values
    #(bigd("0.0001"), bigd("0.0003"), bigd("0.0001")),
    #(bigd("0.0003"), bigd("0.0001"), bigd("0.0000")),

    // high precision
    #(bigd("3.14159"), bigd("2.71828"), bigd("0.42331")),
    #(bigd("2.71828"), bigd("3.14159"), bigd("2.71828")),
    #(bigd("1.234567"), bigd("0.0001"), bigd("0.000067")),

    // large integers
    #(bigd("999999999999"), bigd("3"), bigd("0")),
    #(bigd("999999999999"), bigd("7"), bigd("0")),
    #(bigd("1000000000000000000"), bigd("0.1"), bigd("0.0")),

    // tricky sign boundary cases (trunc vs floor mismatch tests)
    #(bigd("-7"), bigd("3"), bigd("-1")),
    #(bigd("-1.1"), bigd("0.4"), bigd("-0.3")),
    #(bigd("1.1"), bigd("-0.4"), bigd("0.3")),
  ])

  bigdecimal.remainder(input, divisor)
  |> should.equal(expected_remainder)
}

pub fn power__test() {
  use #(input, exponent, expected_product) <- list.each([
    // zero exponent
    #(bigd("2314.234142"), 0, bigd("1")),
    #(bigd("0.0"), 0, bigd("1")),

    // positive exponent
    #(bigd("2314.234142"), 1, bigd("2314.234142")),
    #(bigd("1.2"), 2, bigd("1.44")),
    #(bigd("2.123"), 3, bigd("9.568634867")),
    #(bigd("0.0000"), 8, bigd("0e-32")),

    // negative exponent
    #(bigd("2.123"), -3, bigd("0.10450811572388113782960592930314393")),
    #(bigd("-1.234"), -2, bigd("0.6567040287478755624670006")),
    #(bigd("1.234"), -3, bigd("0.53217506381513416731523551260568821")),
    #(bigd("0.0000"), -8, bigd("0")),
  ])

  bigdecimal.power(input, of: exponent)
  |> should.equal(expected_product)
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

pub fn constants__test() {
  use #(util_const, expected_unscaled_value, expected_scale) <- list.each([
    #(bigdecimal.zero(), bigi.from_int(0), 0),
    #(bigdecimal.one(), bigi.from_int(1), 0),
  ])

  common_assertions(util_const, expected_unscaled_value, expected_scale)
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
  bigd(input)
  |> common_assertions(expected_unscaled_value, expected_scale)
}

fn bigd(input: String) {
  bigdecimal.from_string(input)
  |> should.be_ok
}

fn common_assertions(
  value: BigDecimal,
  expected_unscaled_value: BigInt,
  expected_scale: Int,
) {
  bigdecimal.unscaled_value(of: value)
  |> should.equal(expected_unscaled_value)

  bigdecimal.scale(of: value)
  |> should.equal(expected_scale)
}

pub fn to_plain_string__test() {
  use input <- list.each([
    "100",
    "100.00",
    "0.009",
    "-0.009",
    "-100",
    "0",
    "0.00",
    "9.00",
    "0.9",
    "0.1",
    "9.9",
    "9.1",
    "-9.1",
    "-0.1",
    "9.0001",
    "9.0001000",
    "9.01",
    "100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
    "0.0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009",
  ])

  let assert Ok(bigdec) = bigdecimal.from_string(input)
  let result = bigdecimal.to_plain_string(bigdec)

  result
  |> should.equal(input)

  result
  |> bigdecimal.from_string
  |> should.be_ok
  |> should.equal(bigdec)
}

pub fn to_plain_string_negative_scale__test() {
  use #(input, expected) <- list.each([
    #(bigdecimal.rescale(bigd("0"), -4, rounding.Down), "0"),
    #(bigdecimal.rescale(bigd("1000"), -3, rounding.Down), "1000"),
    #(bigdecimal.rescale(bigd("2000"), -1, rounding.Down), "2000"),
  ])

  bigdecimal.to_plain_string(input)
  |> should.equal(expected)
}
