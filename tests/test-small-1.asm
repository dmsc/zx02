;
; Test module for 6502 ZX02 decompressors
; ---------------------------------------
;
; Test for small decompressor
;
	org	$2000

out_addr = $2200

        icl	"../6502/zx102-small.asm"
        icl     "test-save.asm"

start:
        jsr     full_decomp
        jmp     save

        org  $6700

comp_data
        ins  "data.zx12"

        run	start

