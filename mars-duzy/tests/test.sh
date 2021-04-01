#!/usr/bin/env sh

java -jar mars.jar ../zad16.asm
if cmp --silent -- "output.txt" "expected_output.txt"; then
  exit 0
else
  echo "invalid output"
  exit -1
fi
