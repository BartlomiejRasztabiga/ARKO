#!/usr/bin/env sh

make all64

qqwing --generate --compact --difficulty expert >input_raw.txt
sed 's/\./#/g' <input_raw.txt >input.txt
qqwing --solve --compact <input_raw.txt >expected.txt

time ./main <input.txt >output.txt

cmp -- output.txt expected.txt
