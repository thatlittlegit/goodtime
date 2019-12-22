LDLIBS=$(shell pkg-config --libs gtk+-3.0 granite gstreamer-1.0)
CFLAGS=$(shell pkg-config --cflags gtk+-3.0 granite gstreamer-1.0) -g -Wall
VALAFLAGS=--pkg=gtk+-3.0 --pkg=gstreamer-1.0 -g
goodtime: goodtime.o goodtime_vala.o
goodtime.o: goodtime.c goodtime.glade

# FIXME This could probably be simplified, but I couldn't get it to work with --output.
goodtime_vala.o: goodtime_vala.vala
	valac $(VALAFLAGS) $^ -c && mv $^.o $@

format:
	clang-format -i -style=WebKit $(wildcard *.c)

clean:
	rm -f $(wildcard goodtime goodtime.o goodtime_vala.o)

run: goodtime
	./goodtime

.PHONY: format clean run
