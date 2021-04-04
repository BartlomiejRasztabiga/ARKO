#!/usr/bin/env sh

java -jar mars.jar nc ../zad16.asm

if cmp --silent -- "output.txt" "expected_output.txt";
then
    echo "test 1 passed"
else
    echo "test 1 failed"
    exit 1
fi


if cmp --silent -- "output1.txt" "expected_output1.txt";
then
    echo "test 2 passed"
else
    echo "test 2 failed"
    exit 1
fi
