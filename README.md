# :b: bigdecimal

[![Package Version](https://img.shields.io/hexpm/v/bigdecimal)](https://hex.pm/packages/bigdecimal)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/bigdecimal/)
![Erlang Target](https://img.shields.io/badge/target-erlang-A90433)
![JavaScript Target](https://img.shields.io/badge/target-javascript-F7E02A)

A library for [arbitrary precision decimal arithmetic](https://en.wikipedia.org/wiki/Arbitrary-precision_arithmetic) in Gleam.

This library builds on the excellent [bigi](https://hex.pm/packages/bigi) library, which is used
to represent the unscaled value of `BigDecimal`s.
A `BigDecimal` consists of an arbitrary precision integer unscaled value of type `bigi.Bigint`
and an integer scale of built-in type `Int` (arbitrary precision on the Erlang target, bound between
[Number.MIN_SAFE_INTEGER](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/MIN_SAFE_INTEGER)
and [Number.MAX_SAFE_INTEGER](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Number/MAX_SAFE_INTEGER)
on the JavaScript target). If zero or positive, the scale is the number of digits to the right of
the decimal point. If negative, the unscaled value of the number is multiplied by ten to the power
of the negation of the scale. The value of the number represented by the `BigDecimal` is therefore
unscaled_value × 10<sup>-scale</sup>.

## Usage

```sh
gleam add bigdecimal@1
```

```gleam
import bigdecimal

pub fn main() {
  let assert Ok(number) = bigdecimal.from_string("12.00340")

  bigdecimal.scale(of: number) // 5

  bigdecimal.unscaled_value(of: number) // 1_200_340
}
```

Further documentation can be found at <https://hexdocs.pm/bigdecimal>.

## Development

The library supports all targets and runtimes. To do a matrix run of the test suite, run:

```sh
./scripts/matrix-test.sh
```

## TODO

### Pre v1
- [x] absolute value
- [x] compare
- [x] add
- [x] subtract
- [x] multiply
- [x] product (list input)
- [x] sum (list input)
- [x] signum
- [x] ulp
- [x] power
- [x] rescale/round (with rounding modes)
- [x] clamp
- [ ] divide
- [ ] modulo

### Post v1
- [ ] square root
- [ ] trim trailing zeros
- [ ] truncate (to BigInt)
