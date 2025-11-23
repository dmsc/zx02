; De-compressor for ZX02 files
; ----------------------------
;
; Decompress ZX02 data (6502 optimized format), optimized for code located
; at zero page.
;  109 bytes code, 64.2 cycles/byte in test file.
;
; Compress with:
;    zx02 input.bin output.zx0
;
; (c) 2025 DMSC
; Code under MIT license, see LICENSE file.


ZP=$80

              org  ZP

; Parameters used in this code:
;   comp_data   : Address of the compressed data (input)
;   out_addr    : Address of the decompressed data (output)
;   ini_offset  : Initial offset (see README for the explanation of the '-o' option)

; Define initial offset if not given
.if .not .def ini_offset
ini_offset = 1
.endif

; This is the value to initialize the pointer, based on the initial offset
ini_pntr = ((out_addr-($FF+ini_offset))&$FF00) | ($FF&($100-ini_offset))

;--------------------------------------------------
; Decompress ZX0 data (6502 optimized format)
;
; Reads data from 'comp_data' and writes the result to 'out_addr', until the
; compressed data ends.

full_decomp

; Decode literal: Copy next N bytes from compressed file
;    Elias(length)  byte[1]  byte[2]  ...  byte[N]
decode_literal
              inx
              jsr   get_elias

cop0          jsr   get1
              jsr   put1
              bne   cop0

              asl   bitr
              bcs   dzx0s_new_offset

; Copy from last offset (repeat N bytes from last offset)
;    Elias(length)
              inx
              jsr   get_elias
dzx0s_copy

cop1          ldy   ZX0_dst
pntr = *+1
              lda.a ini_pntr,y
              jsr   put1
              bne   cop1

              asl   bitr
              bcc   decode_literal

; Copy from new offset (repeat N bytes from new offset)
;    Elias(MSB(offset))  LSB(offset)  Elias(length-1)
dzx0s_new_offset
              ; Read elias code for high part of offset
              inx
              jsr   get_elias
              beq   exit  ; Read a 0, signals the end
              ; Decrease and divide by 2
              dex
              txa
              lsr   @
              sta   pntr+1

              ; Get low part of offset, a literal 7 bits
              jsr   get1

              ; Divide by 2
              ror   @
              eor   #$ff
              sta   pntr

              ; And get the copy length.
              ; Start elias reading with the bit already in carry:
              ldx   #1
              jsr   elias_skip1

              lda   ZX0_dst+1
              sbc   pntr+1  ; C=0 from get_elias
              sta   pntr+1

              inx
              bcs   dzx0s_copy

; Read an elias-gamma interlaced code.
; ------------------------------------
elias_get     ; Read next data bit to result
              asl   bitr
              rol   @
              tax

get_elias
              ; Get one bit
              asl   bitr
              bne   elias_skip1

              ; Read new byte from stream
              jsr   get1
              ;sec   ; not needed, C=1 guaranteed from last bit
              rol   @
              sta   bitr

elias_skip1
              txa
              bcs   elias_get
              ; Got ending bit, stop reading
exit
              rts


; Get one byte from input.
; ------------------------
get1          lda   comp_data
              inc   get1+1
              bne   @+
              inc   get1+2
@             rts


; Store one byte to output.
; -------------------------
ZX0_dst = *+1
put1          sta   out_addr
              inc   ZX0_dst
              bne   @+
              inc   ZX0_dst+1
              inc   pntr+1
@             dex
              rts


; ZP temporary locations:
bitr        .by $80     ; Initial value for the bit reservoir. Don't ever change.

