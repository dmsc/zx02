# ZX02: 6502 optimized compression

This is a modified version of the [ZX0](https://github.com/einar-saukas/ZX0)
compressor to make the decompressor smaller and faster on a 6502.

**The compression format is not compatible with ZX0**

Compared to ZX0, the differences are:

* The Elias gamma codes are limited to 8 bits (from 1 to 256). This makes
  decoding simpler and faster in the 6502, as all registers are 8-bit.

* Allowed to encode matches with 1 byte length. This is needed as the encoder
  can't output more than 256 literal bytes, so at least one match is needed to
  separate two literal runs. This has the added advantage of allowing new
  match lengths for the repeated offset matches.

* Offsets are stored as positive integers (minus one). This is faster in the
  6502 because a SBC instruction can subtract one more than the value.

* The Elias gamma codes are stored with a 0 bit at the end.

* It is possible to start with any initial offset, the 6502 decoders included
  assume initial offset 1, but changing it does not make the decoder bigger.

## 6502 decompressors

There are two 6502 assembly decoders:

* Small decoder, 130 bytes: [zx02-small.asm](6502/zx02-small.asm)
* Fast decoder, 175 bytes: [zx02-fast.asm](6502/zx02-fast.asm)

## C decompressor

There is a C decompressor command `dzx02` that supports all variations of the
format, including starting offsets and backward encode/decode.

