CC = gcc
CFLAGS = -Wall -no-pie
ASFLAGS =
LDFILES = /lib/x86_64-linux-gnu/ld-linux-x86-64.so.2 /usr/lib/x86_64-linux-gnu/crt1.o  /usr/lib/x86_64-linux-gnu/crti.o /usr/lib/x86_64-linux-gnu/crtn.o 

objects = *.o

all: pgma

pgma: pgma.o meuAlocador.o
	ld pgma.o meuAlocador.o -o pgma -dynamic-linker $(LDFILES) -lc
pgma.o: pgma.c
meuAlocador.o: meuAlocador.h meuAlocador.s
	as meuAlocador.s -o meuAlocador.o $(ASFLAGS) $(ASFILES) $(ASLIBS)

debug: CFLAGS += -g -DDEBUG
debug: ASFLAGS += -g
debug: all

clean:
	rm -f $(objects)
purge: clean
	rm -f pgma