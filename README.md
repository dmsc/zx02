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

With the above changes, compared with the original `ZX02` have:

* Worst case expansion for random data is bigger than the original, 1.01% for
  `ZX02` compared with 0.8% for `ZX0`

* Compression for long repeated runs is also lower, original can encode runs
  of 1K with 4 bytes, we need 12 bytes.

* Code and 16 bit data can compress a lot more than with the original, as it
  is possible to change the offset at any place in the input.

So, this compressor is better suited to smaller data, and specially when you
need the de-compressor code to be as small as possible.

## 6502 decompressors

There are three 6502 assembly decoders, all with ROM-able code and using 8
bytes of zero-page:

* Smallest decoder, 130 bytes: [zx02-small.asm](6502/zx02-small.asm)
* Fast and small decoder, 138 bytes: [zx02-optim.asm](6502/zx02-optim.asm)
* Faster decoder, 175 bytes: [zx02-fast.asm](6502/zx02-fast.asm)

## C decompressor

There is a C decompressor command `dzx02` that supports all variations of the
format, including starting offsets and backward encode/decode.

## Downloads

You can download pre-compiled compressor and decompressor binaries in the
[GitHub releases area](https://github.com/dmsc/zx02/releases/).

