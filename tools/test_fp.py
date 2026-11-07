"""Original-Z80-Routinen direkt ausführen: python3 -m unittest discover -s tools -p test_fp.py."""
import math
from pathlib import Path
import unittest

from z80 import Z80Machine

ORIGINAL = (Path(__file__).resolve().parents[1] / 'original' / 'BASICT.COM').read_bytes()


def encode(value):
    if value == 0:
        return bytes(5)
    fraction, exponent = math.frexp(abs(value))
    mantissa = int(fraction * 2**31)
    if value < 0:
        mantissa |= 0x80000000
    return mantissa.to_bytes(4, 'little') + bytes([exponent & 255])


def decode(data):
    mantissa = int.from_bytes(data[:4], 'little') & 0x7fffffff
    exponent = int.from_bytes(data[4:], 'little', signed=True)
    return math.ldexp(mantissa, exponent - 31) * (-1 if data[3] & 128 else 1)


def invoke(address, value=0, argument=0, text=None):
    machine = Z80Machine()
    machine.set_memory_block(0x100, ORIGINAL)
    machine.set_memory_block(0x42e2, encode(value) + encode(argument))
    machine.memory[0x42e1] = 2
    machine.set_memory_block(0x6000, bytes([0xcd, address & 255, address >> 8, 0]))
    machine.sp = 0x7000
    machine.pc = 0x6000
    machine.set_breakpoint(0x6003)
    machine.set_breakpoint(0x3359)
    if text is not None:
        machine.de = 0x6100
        machine.set_memory_block(0x6100, text.encode('ascii') + bytes(1))
    for _ in range(1000):
        machine.ticks_to_stop = 100000
        machine.run()
        if machine.pc in (0x6003, 0x3359):
            return machine
    raise AssertionError(f'Routine {address:04X} beendet sich nicht; PC={machine.pc:04X}')


class FloatingPointTests(unittest.TestCase):
    def result(self, address, value=0, argument=0, text=None):
        machine = invoke(address, value, argument, text)
        self.assertEqual(machine.pc, 0x6003)
        return decode(bytes(machine.memory[0x42e2:0x42e7]))

    def test_stored_one_uses_signed_exponent_without_bias(self):
        self.assertEqual(ORIGINAL[0x2cdc-0x100:0x2ce1-0x100], bytes.fromhex('0000004001'))
        self.assertEqual(self.result(0x26c3, 0.5, 0.5), 1)

    def test_addition_aligns_exponents(self):
        self.assertEqual(self.result(0x26c3, 1, 2), 3)

    def test_subtraction_cancels_to_canonical_zero(self):
        machine = invoke(0x26b6, 3, 3)
        self.assertEqual(machine.pc, 0x6003)
        self.assertEqual(bytes(machine.memory[0x42e2:0x42e7]), bytes(5))

    def test_addition_discards_low_bits_instead_of_rounding(self):
        self.assertEqual(self.result(0x26c3, 1, 3 * 2**-32), 1)

    def test_multiply_uses_xor_sign(self):
        self.assertEqual(self.result(0x278d, -3, 2), -6)

    def test_division_produces_fraction(self):
        self.assertEqual(self.result(0x27ef, 3, 2), 1.5)

    def test_nonzero_divided_by_zero_reports_error_40(self):
        machine = invoke(0x27ef, 1, 0)
        self.assertEqual((machine.pc, machine.a), (0x3359, 40))

    def test_raw_fp_zero_divided_by_zero_returns_zero(self):
        self.assertEqual(self.result(0x27ef, 0, 0), 0)

    def test_floor_negative_fraction(self):
        self.assertEqual(self.result(0x2957, -2.7), -3)

    def test_floor_negative_exact_integer(self):
        self.assertEqual(self.result(0x2957, -2), -2)

    def test_integer_conversion_half_ties_away_from_zero(self):
        for value, expected in [(2.5, 3), (-2.5, -3)]:
            with self.subTest(value=value):
                machine = invoke(0x32b7, value)
                self.assertEqual(machine.pc, 0x6003)
                self.assertEqual(machine.memory[0x42e1], 1)
                self.assertEqual(int.from_bytes(machine.memory[0x42e2:0x42e4], 'little', signed=True), expected)

    def test_integer_conversion_discards_low_mantissa_at_upper_boundary(self):
        machine = invoke(0x32b7, 32767.5)
        self.assertEqual(machine.pc, 0x6003)
        self.assertEqual(int.from_bytes(machine.memory[0x42e2:0x42e4], 'little', signed=True), 32767)

    def test_integer_conversion_rejects_negative_32768(self):
        machine = invoke(0x32b7, -32768)
        self.assertEqual((machine.pc, machine.a), (0x3359, 31))

    def test_sqrt_two(self):
        self.assertAlmostEqual(self.result(0x28d5, 2), math.sqrt(2), delta=2e-9)

    def test_negative_sqrt_reports_function_error(self):
        machine = invoke(0x28d5, -1)
        self.assertEqual((machine.pc, machine.a), (0x3359, 41))

    def test_log_two(self):
        self.assertAlmostEqual(self.result(0x29d0, 2), math.log(2), delta=3e-8)

    def test_exp_one(self):
        self.assertAlmostEqual(self.result(0x2a5b, 1), math.e, delta=7e-8)

    def test_exp_negative_64_reports_overflow(self):
        machine = invoke(0x2a5b, -64)
        self.assertEqual((machine.pc, machine.a), (0x3359, 32))

    def test_sine_one_radian(self):
        self.assertAlmostEqual(self.result(0x2b09, 1), math.sin(1), delta=2e-9)

    def test_cosine_zero(self):
        self.assertAlmostEqual(self.result(0x2afb, 0), 1, delta=2e-9)

    def test_atan_one_radian(self):
        self.assertAlmostEqual(self.result(0x2bc3, 1), math.pi/4, delta=4e-9)

    def test_parser_discards_after_nine_significant_digits(self):
        self.assertEqual(self.result(0x2e1b, text='1.23456789123'), self.result(0x2e1b, text='1.23456789'))
        self.assertEqual(self.result(0x2e1b, text='1234567890'), 1234567890)

    def test_parser_applies_decimal_exponent(self):
        self.assertEqual(self.result(0x2e1b, text='1E+2'), 100)

    def test_rnd_uses_fractional_increment_and_stores_remainder(self):
        self.assertEqual(decode(ORIGINAL[0x2d77-0x100:0x2d7c-0x100]), 99991.15625)
        machine = invoke(0x2c85)
        self.assertEqual(machine.pc, 0x6003)
        result = decode(bytes(machine.memory[0x42e2:0x42e7]))
        state = decode(bytes(machine.memory[0x41d5:0x41da]))
        self.assertGreaterEqual(result, 0)
        self.assertLess(result, 1)
        self.assertAlmostEqual(result, state/199019, delta=1e-9)


if __name__ == '__main__':
    unittest.main()