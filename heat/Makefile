DEBUG=NO
USE_SANITIZERS=NO

SANITIZERS_FLAGS=-fsanitize=address,undefined
WARRNINGS_FLAGS=-Wall -Wextra -Wshadow

DEBUG_FLAGS=-g -O0 -DDEBUG
RELEASE_FLAGS=-O1 -DNDEBUG

ifeq ($(DEBUG),YES)
	CFLAGS += $(DEBUG_FLAGS)
else
	CFLAGS += $(RELEASE_FLAGS)
endif

ifeq ($(USE_SANITIZERS),YES)
	CFLAGS += $(SANITIZERS_FLAGS)
endif

all:
	nasm -f elf64 -F dwarf -g heat.asm
	clang -no-pie $(CFLAGS) $(WARRNINGS_FLAGS) -o main main.c heat.o
