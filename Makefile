LDLIBS=$(shell pkg-config --libs gtk+-3.0 granite)
CFLAGS=$(shell pkg-config --cflags gtk+-3.0 granite) -g -Wall

goodtime: goodtime.o
goodtime.o: goodtime.c goodtime.glade

format:
	clang-format -i -style=WebKit $(wildcard *.c)

clean:
	rm -f $(wildcard goodtime goodtime.o)

run: goodtime
	./goodtime

.PHONY: format clean run
