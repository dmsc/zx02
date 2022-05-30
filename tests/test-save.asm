;
; Test module for 6502 ZX02 decompressors
; ---------------------------------------
;
; Routine to save result

ICCOM   =       $342
ICBAL   =       $344
ICBAH   =       $345
ICBLL   =       $348
ICBLH   =       $349
ICAX1   =       $34A
CIOV    =       $E456

save:
        ldx #16
        jsr close

        lda #<fname
        sta ICBAL, x
        lda #>fname
        sta ICBAH, x
        lda #8
        sta ICAX1, x
        lda #$03
        sta ICCOM, x
        jsr CIOV

        lda #<out_addr
        sta ICBAL, x
        lda #>out_addr
        sta ICBAH, x
        lda ZX0_dst
        sec
        sbc #<out_addr
        sta ICBLL, x
        lda ZX0_dst+1
        sbc #>out_addr
        sta ICBLH, x
        lda #$0B
        sta ICCOM, x
        jsr CIOV

close
         lda #$0C
         sta ICCOM, x
         jmp CIOV

fname    .by "D:OUT.BIN", $9B

