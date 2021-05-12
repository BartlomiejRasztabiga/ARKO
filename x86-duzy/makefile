CC=gcc
ASMBIN=nasm
ASM_SRC=sudoku

all: assemble compile link
assemble:
	$(ASMBIN) -o $(ASM_SRC).o -f elf32 -F dwarf $(ASM_SRC).s -g -l $(ASM_SRC).lst

compile:
	$(CC) -m32 -c -g -O0 -std=c99 main.c &> errors.txt

link:
	$(CC) -m32 -g -o main main.o $(ASM_SRC).o

run:
	./main

clean:
	rm *.o
	rm main
	rm errors.txt
	rm $(ASM_SRC).lst