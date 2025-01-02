PACKAGE	:= lddiff
VERSION	:= 0.5
AUTHORS	:= R.Jaksa 2024 GPLv3
SUBVERS	:= 

SHELL	:= /bin/bash
PATH	:= usr/bin:$(PATH)
PKGNAME	:= $(PACKAGE)-$(VERSION)$(SUBVERSION)
PROJECT := $(shell getversion -prj)
DATE	:= $(shell date '+%Y-%m-%d')

BIN	:= lddiff
DEP	:= $(BIN:%=.%.d)
DOC	:= $(BIN:%=doc/%.md)

# don't re-generate man-md file without man2md
ifneq ($(shell man2md -h 2>/dev/null),)
all: $(BIN) $(DOC)
else
all: $(BIN)
endif

$(BIN): %: %.pl .%.d .version.pl .%.built.pl Makefile
	@echo -e '#!/usr/bin/perl' > $@
	@echo "# $@ generated from $(PKGNAME)/$< $(DATE)" >> $@
	pcpp -v $< >> $@
	@chmod 755 $@
	@sync

$(DEP): .%.d: %.pl
	pcpp -d $(<:%.pl=%) $< > $@

$(DOC): doc/%.md: %
	./$* -h | man2md > $@

.version.pl: Makefile
	@echo 'our $$PACKAGE = "$(PACKAGE)";' > $@
	@echo 'our $$VERSION = "$(VERSION)";' >> $@
	@echo 'our $$AUTHOR = "$(AUTHORS)";' >> $@
	@echo 'our $$SUBVERSION = "$(SUBVERS)";' >> $@
	@echo "make $@"

.PRECIOUS: .%.built.pl
.%.built.pl: %.pl .version.pl Makefile
	@echo 'our $$BUILT = "$(DATE)";' > $@
	@echo "make $@"

# /usr/local install
ifeq ($(wildcard /map),)
install: $(BIN)
	install $(BIN) /usr/local/bin

# /map install (requires /map directory plus getversion and mapinstall tools)
else
install: $(BIN) $(DOC)
	mapinstall -v /box/$(PROJECT)/$(PKGNAME) /map/$(PACKAGE) bin $^
	mapinstall -v /box/$(PROJECT)/$(PKGNAME) /map/$(PACKAGE) doc README.md doc/*
	sed -i 's:doc/::g' /map/lddiff/doc/README.md
endif

clean:
	rm -f .version.pl .*.built.pl
	rm -f $(DEP)

mrproper: clean
	rm -f $(DOC) $(BIN)

-include $(DEP)
-include ~/.github/Makefile.git
