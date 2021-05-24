CC=gcc
ASMBIN=nasm
ASM_SRC=sudoku

all: assemble compile link

all64: assemble64 compile64 link64

assemble: $(ASM_SRC).s
	$(ASMBIN) -o $(ASM_SRC).o -f elf32 -F dwarf $(ASM_SRC).s -g -l $(ASM_SRC).lst

assemble64: $(ASM_SRC)64.s
	$(ASMBIN) -o $(ASM_SRC)64.o -f elf64 -F dwarf $(ASM_SRC)64.s -g -l $(ASM_SRC)64.lst

compile: assemble main.c
	$(CC) -m32 -c -g -O0 -std=c99 main.c

compile64: assemble64 main.c
	$(CC) -m64 -c -g -O0 -std=c99 main.c

link: compile
	$(CC) -m32 -g -o main main.o $(ASM_SRC).o

link64: compile64
	$(CC) -m64 -g -o main main.o $(ASM_SRC)64.o

run:
	./main

clean:
	rm *.o
	rm main
	rm $(ASM_SRC).lst