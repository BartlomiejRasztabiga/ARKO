#!/usr/bin/env sh

make all

qqwing --generate --compact --difficulty expert >input_raw.txt
sed 's/\./#/g' <input_raw.txt >input.txt
qqwing --solve --compact <input_raw.txt >expected.txt

./main <input.txt >output.txt

cmp -- output.txt expected.txt