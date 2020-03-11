N_VALUE=2

all:
	nasm -DN=$(N_VALUE) -f elf64 -F dwarf -g euron.asm
	gcc -DN=$(N_VALUE) -g -fno-omit-frame-pointer -o euron euronmain.c euron.o -lpthread

	cp euron.asm ./tests/euron.asm
