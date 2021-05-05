CC=gcc
ASMBIN=nasm
AMS_SRC=remrep

all: assemble compile link
assemble:
	$(ASMBIN) -o $(AMS_SRC).o -f elf32 -F dwarf $(AMS_SRC).s -g -l $(AMS_SRC).lst

compile:
	$(CC) -m32 -c -g -O0 -std=c99 main.c &> errors.txt

link:
	$(CC) -m32 -g -o main main.o $(AMS_SRC).o

run:
	./main

clean:
	rm *.o
	rm main
	rm errors.txt
	rm $(AMS_SRC).lst