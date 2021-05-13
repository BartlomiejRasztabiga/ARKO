CC=gcc
ASMBIN=nasm
ASM_SRC=sudoku

all: assemble compile link

assemble: $(ASM_SRC).s
	$(ASMBIN) -o $(ASM_SRC).o -f elf32 -F dwarf $(ASM_SRC).s -g -l $(ASM_SRC).lst

compile: assemble main.c
	$(CC) -m32 -c -g -O0 -std=c99 main.c

link: compile
	$(CC) -m32 -g -o main main.o $(ASM_SRC).o

run:
	./main

clean:
	rm *.o
	rm main
	rm $(ASM_SRC).lst