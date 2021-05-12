#!/usr/bin/env sh

make all

# Test 1
./main < tests/input1.txt > output.txt

if cmp --silent -- "output.txt" "tests/output1.txt":
then
    echo "Test 1 passed"
else
    echo "Test 1 failed"
    exit 1
fi

