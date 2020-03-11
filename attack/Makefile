.PHONY: all validate

all: validate

build:
	nasm -g -f elf64 -o attack.o attack.asm
	ld -o attack attack.o

validate: build
	./script.sh
