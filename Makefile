CC = gcc
CFLAGS = -Wall -no-pie
ASFLAGS = 

objects = *.o

all: pgma

pgma: pgma.c meuAlocador.o
meuAlocador.o: meuAlocador.h meuAlocador.s
	as $(ASFLAGS) meuAlocador.s -o meuAlocador.o

debug: CFLAGS += -g -DDEBUG
debug: ASFLAGS += -g
debug: all

clean:
	rm -f $(objects)
purge: clean
	rm -f pgma