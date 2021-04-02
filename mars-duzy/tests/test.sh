#!/usr/bin/env sh

java -jar mars.jar nc ../zad16.asm > console_output.txt
if cmp --silent -- "console_output.txt" "expected_output.txt"; then
  if cmp --silent -- "output.txt" "expected_output_file.txt"; then
    exit 0
  else
    echo "invalid file output"
    exit 1
  fi
else
  echo "invalid console output"
  exit 1
fi
