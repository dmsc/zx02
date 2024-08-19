#!/bin/sh
set -e

wrap() {
    cmdout=$($* 2>&1)
    if [ "$?" -ne 0 ]; then
        printf "\e[41m ERROR IN COMMAND $* \e[0m\n"
        echo " $cmdout"
        exit 1
    fi
}

do_test() {
    wrap mads "-l:${1%.*}.lst" "-t:${1%.*}.lab" "$1"
    wrap minisim -d "${1%.*}.obx"
    cycles=$(echo "$cmdout" | tail -1 | sed -e 's/^.*cycles://g')
    cmp "$TEST" OUT.BIN &&
        printf "%7d cycles, %2d.%1d cycles/byte: \e[42m TEST PASSED \e[0m\n" \
               "$cycles" "$(($cycles/$size))" "$(($cycles*10/$size%10))" || (
        printf "\e[41m TEST NOT PASSED \e[0m\n" && false )
}

test_one() {
    TEST="$1"

    echo "-----------------------------------------------------"
    if [ ! -f "$TEST" ]; then
        printf "\e[41mERROR: file '$TEST' does not exists \e[0m\n"
        return
    fi

    size=$(stat -c %s "$TEST")

    echo "TESTING FILE '$TEST', $size bytes."
    printf " -> Compressing ZX0 based format:"
    wrap ../build/zx02 -f "$TEST" data.zx02
    stat -c " %s bytes" data.zx02

    printf " -> Compressing ZX1 based format:"
    wrap ../build/zx02 -1 -f "$TEST" data.zx12
    stat -c " %s bytes" data.zx12

    printf " -> Compressing ZX0-x based format:"
    wrap ../build/zx02 -x -f "$TEST" data.zx02x
    stat -c " %s bytes" data.zx02x

    printf " -> Decompress ZX02 FAST:  "
    do_test test-fast.asm

    printf " -> Decompress ZX02 OPTIM: "
    do_test test-optim.asm

    printf " -> Decompress ZX02 SMALL: "
    do_test test-small.asm

    printf " -> Decompress ZX02 -1 OPTIM: "
    do_test test-optim-1.asm

    printf " -> Decompress ZX02 -1 SMALL: "
    do_test test-small-1.asm

    printf " -> Decompress ZX02 -x OPTIM: "
    do_test test-optim-2.asm
}

while test -n "$1"; do
    test_one "$1"
    shift
done
