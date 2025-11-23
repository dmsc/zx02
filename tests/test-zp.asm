;
; Test module for 6502 ZX02 decompressors
; ---------------------------------------
;
; Test for small decompressor
;
;
out_addr = $2200
        icl	"../6502/zx02-zp.asm"

	org	$2000
        icl     "test-save.asm"

start:
        jsr     full_decomp
        sty     ZX0_dst
        jmp     save

        org  $6700

comp_data
        ins  "data.zx02"

        run	start

