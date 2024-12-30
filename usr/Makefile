LIBPL := array colors string
LIBPL := $(LIBPL:%=inc/%.pl)

all: bin/pcpp $(LIBPL) inc/printhelp.pl

bin/pcpp: /map/pcpp/bin/pcpp | bin
	cp $< $@

$(LIBPL): inc/%.pl: /map/libpl/inc/%.pl | inc
	cp $< $@
	@head -n 1 $@ | xargs -n1 | grep libpl | sed 's:/.*::' | sed s:libpl-:: > .libpl.version

inc/printhelp.pl: /map/helpman/inc/printhelp.pl | inc
	cp $< $@
	@head -n 1 $@ | xargs -n1 | grep helpman | sed 's:/.*::' | sed s:helpman-:: > .helpman.version

bin inc:
	mkdir -p $@

clean:
	rm -f .*

mrproper: clean
	rm -rf inc bin

