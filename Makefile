CC = gcc
CFLAGS = -Wall

objects = *.o

all: pgma

pgma: pgma.c meuAlocador.o
meuAlocador.o: meuAlocador.h meuAlocador.s
	as meuAlocador.s -o meuAlocador.o

debug: CFLAGS += -g -DDEBUG
debug: all

clean:
	rm -f $(objects)
purge: clean
	rm -f pgma