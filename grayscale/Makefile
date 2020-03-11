CC := cc
ASMC := as
DEBUG := YES
USE_SANITIZERS := NO

SANITIZERS_FLAGS := -fsanitize=address,undefined
WARRNINGS_FLAGS := -Wall -Wextra -Wshadow

CFLAGS := --std=c99
ASMFLAGS := -g3
DEBUG_FLAGS := -g3 -O0 -DDEBUG
RELEASE_FLAGS := -O1 -DNDEBUG

# Link z libm jest potrzebny tylko i wylacznie bibliotece do ppm.
LINKER_FLAGS := -lm

C_OBJECTS := main.o
EXE_NAME := main

ifeq ($(DEBUG),YES)
	CFLAGS += $(DEBUG_FLAGS)
else
	CFLAGS += $(RELEASE_FLAGS)
endif

.PHONY: all clear library assemby

all: library assemby $(C_OBJECTS)
	$(CC) $(CFLAGS) $(C_OBJECTS) grayscale.o easyppm.o $(LINKER_FLAGS) -o $(EXE_NAME)

%.o: %.c
	$(CC) -c $(CFLAGS) $(WARRNINGS_FLAGS) $< -o $@

%.o: %.s
	$(ASMC) $(ASMFLAGS) $< -o $@

assemby: grayscale.o

library: easyppm.o
easyppm.o: easyppm/easyppm.c
	$(CC) -c $(CFLAGS) $(WARRNINGS_FLAGS) $< -o $@

clean:
	@rm -f *.o
