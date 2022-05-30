#!/bin/sh
set -e

TEST="$1"

if [ ! -f "$TEST" ]; then
    echo "ERROR: file '$TEST' does not exists"
    exit 1
fi

wrap() {
    cmdout=$($* 2>&1)
    if [ "$?" -ne 0 ]; then
        printf "\e[41m ERROR IN COMMAND $* \e[0m\n"
        echo " $cmdout"
        exit 1
    fi
}

size=$(stat -c %s "$TEST")

echo "-----------------------------------------------------"
echo "TESTING FILE '$TEST', $size bytes."
echo " -> Compressing"
wrap ../build/zx02 -f "$TEST" data.zx02


printf " -> Decompress FAST:  "
wrap mads test-fast.asm
wrap minisim -d test-fast.obx
cycles=$(echo "$cmdout" | tail -1 | sed -e 's/^.*cycles://g')
cmp "$TEST" OUT.BIN &&
    printf "%7d cycles, %2d.%1d cycles/byte: \e[42m TEST PASSED \e[0m\n" \
           "$cycles" "$(($cycles/$size))" "$(($cycles*10/$size%10))" || (
    printf "\e[41m TEST NOT PASSED \e[0m\n" && false )

printf " -> Decompress OPTIM: "
wrap mads test-optim.asm
wrap minisim -d test-optim.obx
cycles=$(echo "$cmdout" | tail -1 | sed -e 's/^.*cycles://g')
cmp "$TEST" OUT.BIN &&
    printf "%7d cycles, %2d.%1d cycles/byte: \e[42m TEST PASSED \e[0m\n" \
           "$cycles" "$(($cycles/$size))" "$(($cycles*10/$size%10))" || (
    printf "\e[41m TEST NOT PASSED \e[0m\n" && false )

printf " -> Decompress SMALL: "
wrap mads test-small.asm
wrap minisim -d test-small.obx
cycles=$(echo "$cmdout" | tail -1 | sed -e 's/^.*cycles://g')
cmp "$TEST" OUT.BIN &&
    printf "%7d cycles, %2d.%1d cycles/byte: \e[42m TEST PASSED \e[0m\n" \
           "$cycles" "$(($cycles/$size))" "$(($cycles*10/$size%10))" || (
    printf "\e[41m TEST NOT PASSED \e[0m\n" && false )

