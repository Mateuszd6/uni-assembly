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


# link z libm jest potrzebny tylko i wylacznie bibliotece do ppm.
all:
	# skrypt ./tests.sh generuje przykladowe wyniki dzialania obrazu
	# biblioteka uzyta do ppm to easyppm:
	# https://github.com/fmenozzi/easyppm
	nasm -g -f elf64 -F dwarf imgchange.asm
	gcc -g -no-pie $(CFLAGS) $(WARRNINGS_FLAGS) -o main main.c imgchange.o -lm
