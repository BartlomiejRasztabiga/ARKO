#!/usr/bin/env sh

make all

# Test 1
./main < tests/input1.txt > output.txt

if cmp --silent -- "output.txt" "tests/output1.txt";
then
    echo "test 1 passed"
else
    echo "test 1 failed"
    exit 1
fi

# Test 2
./main < tests/input2.txt > output.txt

if cmp --silent -- "output.txt" "tests/output2.txt";
then
    echo "test 2 passed"
else
    echo "test 2 failed"
    exit 1
fi

# Test 3
./main < tests/input3.txt > output.txt

if cmp --silent -- "output.txt" "tests/output3.txt";
then
    echo "test 3 passed"
else
    echo "test 3 failed"
    echo "test 3 failed"
    exit 1
fi