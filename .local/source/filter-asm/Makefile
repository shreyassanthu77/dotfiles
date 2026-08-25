PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin

.PHONY: all install clean

all: filter-asm

filter-asm: filter-asm.c
	$(CC) -O2 -Wall -Wextra -o $@ $<

install: filter-asm
	install -Dm755 filter-asm $(BINDIR)/filter-asm

clean:
	rm -f filter-asm
