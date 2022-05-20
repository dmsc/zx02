# Custom version of ZX0 compressor

This is a modified version of the [ZX0](https://github.com/einar-saukas/ZX0)
compressor to make the decompressor smaller on a 6502.

Also, there is a new C decompressor compatible with all variants: new, classic,
6502 optimized and backwards modes)

## Compressed Stream Variants

The variants differ on how the bits are stored in the stream, but the basic
code is the same. The table shows the differences:

| Format   | Elias Code ending | Offset MSB | Offset LSB | Decoding Order |
| -------- | ----------------- | ---------- | ---------- | -------------- |
| New (V2) | Bit `1` ends      | Negative   | Negative   | From Start     |
| Classic  | Bit `1` ends      | Positive   | Negative   | From Start     |
| 6502 (2) | Bit `0` ends      | Positive   | Positive   | From Start     |
| 6502 (3) | Bit `1` ends      | Positive   | Positive   | From Start     |
| Backward | Bit `0` ends      | Positive   | Positive   | From End       |


* **Elias Code ending**: bit used to mark the end of the elias-code.
* **Offset MSB**: how the elias-code of the MSB offset is stored.
* **Offset LSB**: how the literal LSB of offset is stored.
* **Decoding Order**: the direction the compression/decompression is performed,
                      from start to end or in reverse.


The 6502 (2) format decoder is one byte shorter than the old (3) format.

