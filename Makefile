DC = gdmd
DFLAGS = -O -inline
LIBSRC = dgraph/*.d
PROGS = graph50

all: $(PROGS)

%: %.d $(LIBSRC)
	$(DC) $(DFLAGS) -of$* $*.d $(LIBSRC)

.PHONY: clean

clean:
	rm -f $(PROGS) *.o *.di

doc-clean:
	rm -rf html
