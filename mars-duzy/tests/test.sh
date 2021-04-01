#!/usr/bin/env sh

java -jar mars.jar nc ../zad16.asm > output.txt
if cmp --silent -- "output.txt" "expected_output.txt"; then
  exit 0
else
  echo "invalid output"
  exit 1
fi
