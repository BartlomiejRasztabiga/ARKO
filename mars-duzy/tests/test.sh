#!/usr/bin/env sh

java -jar mars.jar nc ../zad16b.asm pa input.txt

if cmp --silent -- "output.txt" "expected_output.txt";
then
    echo "test 1 passed"
else
    echo "test 1 failed"
    exit 1
fi

java -jar mars.jar nc ../zad16b.asm pa input1.txt

if cmp --silent -- "output.txt" "expected_output1.txt";
then
    echo "test 2 passed"
else
    echo "test 2 failed"
    exit 1
fi

java -jar mars.jar nc ../zad16b.asm pa input2.txt

if cmp --silent -- "output.txt" "expected_output2.txt";
then
    echo "test 3 passed"
else
    echo "test 3 failed"
    exit 1
fi

