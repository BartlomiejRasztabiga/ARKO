CC=gcc
ASMBIN=nasm

all: assemble compile link
assemble:
	$(ASMBIN) -o removerng.o -f elf32 -F dwarf removerng.s -g -l removerng.lst

compile:
	$(CC) -m32 -c -g -O0 -std=c99 main.c &> errors.txt

link:
	$(CC) -m32 -g -o main main.o removerng.o

run:
	./main

clean:
	rm *.o
	rm main
	rm errors.txt
	rm removerng.lst