all: load_entropy

load_entropy: load_entropy.c Makefile
	gcc -Wall -static -o $@ $<

install: load_entropy
	cp load_entropy ../scripts/guest_load_entropy

clean:
	rm -f load_entropy
