; De-compressor for ZX02 files
; ----------------------------
;
; Decompress ZX02 data (6502 optimized format), optimized for speed:
;  174 bytes code, 48.1 cycles/byte in test file.
;
; Compress with:
;    zx02 input.bin output.zx0
;
; (c) 2022 DMSC
; Code under MIT license, see LICENSE file.


ZP=$80

offset          equ ZP+0
ZX0_src         equ ZP+2
ZX0_dst         equ ZP+4
bitr            equ ZP+6
pntr            equ ZP+7

            ; Initial values for the de-compressor, the values are copied to
            ; the ZP locations at the initialization:
zx0_ini_block
            .by <0, >0  ; Initial offset - 1. See README for explanation (-o option).
            .by <comp_data, >comp_data  ; Address of data to decompress.
            .by <out_addr, >out_addr    ; Address to place decompressed data
            .by $80     ; Initial value for the bit reservoir. Don't ever change.

;--------------------------------------------------
; Decompress ZX0 data (6502 optimized format)
;
; Reads data from 'comp_data' and writes the result to 'out_addr', until the
; compressed data ends.
full_decomp
              ; Get initialization block
              ldy #7

copy_init     ldx zx0_ini_block-1, y
              stx offset-1, y
              dey
              bne copy_init

; Decode literal: Copy next N bytes from compressed file
;    Elias(length)  byte[1]  byte[2]  ...  byte[N]
decode_literal
              jsr   get_elias
              dex

              txa
              sec
              adc   ZX0_src
              sta   ZX0_src
              bcs   @+
              dec   ZX0_src+1
@
              txa
              sec
              adc   ZX0_dst
              sta   ZX0_dst
              bcs   @+
              dec   ZX0_dst+1
@

              txa
              eor       #$FF
              tay

cop0          lda   (ZX0_src), y
              sta   (ZX0_dst), y
              iny
              bne   cop0

              inc   ZX0_src+1
              inc   ZX0_dst+1

              asl   bitr
              bcs   dzx0s_new_offset

; Copy from last offset (repeat N bytes from last offset)
;    Elias(length)
              jsr   get_elias
              dex
dzx0s_copy
              lda   ZX0_dst
              sbc   offset  ; C=0 from get_elias
              sta   pntr
              lda   ZX0_dst+1
              sbc   offset+1
              sta   pntr+1

              txa
;              sec
              adc   pntr
              sta   pntr
              bcs   @+
              dec   pntr+1
              sec
@
              txa
              adc   ZX0_dst
              sta   ZX0_dst
              bcs   @+
              dec   ZX0_dst+1
@
              txa
              eor       #$FF
              tay

cop1          lda   (pntr), y
              sta   (ZX0_dst), y
              iny
              bne   cop1

              inc   ZX0_dst+1

              asl   bitr
              bcc   decode_literal

; Copy from new offset (repeat N bytes from new offset)
;    Elias(MSB(offset))  LSB(offset)  Elias(length-1)
dzx0s_new_offset
              ; Read elias code for high part of offset
              jsr   get_elias
              beq   exit  ; Read a 0, signals the end
              ; Decrease and divide by 2
              dex
              txa
              lsr   @
              sta   offset+1

              ; Get low part of offset, a literal 7 bits
              lda   (ZX0_src), y
              inc   ZX0_src
              bne   @+
              inc   ZX0_src+1
@
              ; Divide by 2 low part
              ror   @
              sta   offset

              ; And get the copy length.
              ; Start elias reading with the bit already in carry:
              ldx   #1
              bcc   dzx0s_copy
              jsr   elias_skip1

              bcc   dzx0s_copy

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Read an elias-gamma interlaced code.
; ------------------------------------
get_elias
              ; Initialize return value to #1
              ldx   #1
              ; Get first bit
              asl   bitr
              beq   elias_byte  ; Need to read a new byte
elias_skip1
              txa
              ; Got ending bit, stop reading
              bcc   exit
elias_get     ; Read next data bit to LEN
              asl   bitr
              rol   @
              tax
              asl   bitr
              bne   elias_skip1

elias_byte
              ; Read new byte from stream
              lda   (ZX0_src), y
              inc   ZX0_src
              bne   @+
              inc   ZX0_src+1
@
              ;sec   ; not needed, C=1 guaranteed from last bit
              rol   @
              sta   bitr
              txa
              ; Got ending bit, stop reading
              bcs   elias_get
exit
              rts

