; De-compressor for ZX02 "-1" files
; ---------------------------------
;
; Decompress ZX02 data in ZX1 mode (6502 optimized format), optimized for speed
; and size 138 bytes code, 53.0 cycles/byte in test file.
;
; Compress with:
;    zx02 -1 input.bin output.zx1
;
; (c) 2022 DMSC
; Code under MIT license, see LICENSE file.


ZP=$80

offset_hi       equ ZP+0
ZX0_src         equ ZP+1
ZX0_dst         equ ZP+3
bitr            equ ZP+5
pntr            equ ZP+6

            ; Initial values for the de-compressor, the values are copied to
            ; the ZP locations at the initialization:
zx0_ini_block
            .by $00     ; Hi byte of the initial offset-1.
            .by <comp_data, >comp_data  ; Address of data to decompress.
            .by <out_addr, >out_addr    ; Address to place decompressed data
            .by $80     ; Initial value for the bit reservoir. Don't ever change.
            .by $ff     ; Low byte of the initial offset - 1 EOR 255.  The value
                        ; $FF means an initial offset of 1 byte, this is the
                        ; default value. See README for the explanation of the
                        ; '-o' option.

;--------------------------------------------------
; Decompress ZX0 data (6502 optimized format)
;
; Reads data from 'comp_data' and writes the result to 'out_addr', until the
; compressed data ends.

full_decomp
              ; Get initialization block
              ldy #7

copy_init     ldx zx0_ini_block-1, y
              stx offset_hi-1, y
              dey
              bne copy_init

; Decode literal: Copy next N bytes from compressed file
;    Elias(length)  byte[1]  byte[2]  ...  byte[N]
decode_literal
              inx
              jsr   get_elias

cop0          lda   (ZX0_src), y
              inc   ZX0_src
              bne   @+
              inc   ZX0_src+1
@             sta   (ZX0_dst),y
              inc   ZX0_dst
              bne   @+
              inc   ZX0_dst+1
@             dex
              bne   cop0

              asl   bitr
              bcs   dzx0s_new_offset

; Copy from last offset (repeat N bytes from last offset)
;    Elias(length)
              inx
              jsr   get_elias
dzx0s_copy
              lda   ZX0_dst+1
              sbc   offset_hi  ; C=0 from get_elias
              sta   pntr+1

cop1
              ldy   ZX0_dst
              lda   (pntr), y
              ldy   #0
@             sta   (ZX0_dst),y
              inc   ZX0_dst
              bne   @+
              inc   ZX0_dst+1
              inc   pntr+1
@             dex
              bne   cop1

              asl   bitr
              bcc   decode_literal

; Copy from new offset (repeat N bytes from new offset)
;    MSB(offset>127)  LSB(offset>127)  Elias(length-1)
;    LSB(offset<128)                   Elias(length-1)
dzx0s_new_offset
              sty   offset_hi   ; Clear offset MSB

              ; Get low part of offset, a literal 7 bits
              lda   (ZX0_src), y
              inc   ZX0_src
              bne   @+
              inc   ZX0_src+1
@
              lsr
              bcc   offset_ok   ; Ok, offset is 7 bits only
              cmp   #$7F
              beq   exit  ; Read a 127, signals the end
              sta   offset_hi ; This is now the "high" part

              ; Get low part of offset, a literal 8 bits
              lda   (ZX0_src), y
              inc   ZX0_src
              bne   @+
              inc   ZX0_src+1
@
offset_ok
              eor   #$ff
              sta   pntr

              ; And get the copy length.
              inx
              jsr   get_elias

              inx
              bcc   dzx0s_copy

; Read an elias-gamma interlaced code.
; ------------------------------------
elias_get     ; Read next data bit to result
              txa
              asl   bitr
              rol   @
              tax

get_elias
              ; Get one bit
              asl   bitr
              bne   elias_skip1

              ; Read new bit from stream
              lda   (ZX0_src), y
              inc   ZX0_src
              bne   @+
              inc   ZX0_src+1
@             ;sec   ; not needed, C=1 guaranteed from last bit
              rol   @
              sta   bitr

elias_skip1
              bcs   elias_get
              ; Got ending bit, stop reading
exit
              rts
