LDLIBS=$(shell pkg-config --libs gtk+-3.0 granite gstreamer-1.0)
VALAFLAGS=--pkg=gtk+-3.0 --pkg=gstreamer-1.0 --pkg=granite -g
goodtime: goodtime.o

# FIXME This could probably be simplified, but I couldn't get it to work with --output.
goodtime.o: audio.vala goodtime.vala
	valac $(VALAFLAGS) $^ -c
	ld -r $(patsubst %.vala,%.vala.o,$^) -o $@
	rm $(patsubst %.vala,%.vala.o,$^) -f

format:
	clang-format -i -style=WebKit $(wildcard *.c)

clean:
	rm -f $(wildcard goodtime goodtime.o goodtime.vala.o audio.vala.o)

run: goodtime
	./goodtime

.PHONY: format clean run
