DC = gdmd
DFLAGS = -O -inline
LIBSRC = dgraph/*.d dgraph/test/*.d
PROGS = graphtest betweenness

all: $(PROGS)

%: %.d $(LIBSRC)
	$(DC) $(DFLAGS) -of$* $*.d $(LIBSRC)

.PHONY: clean

clean:
	rm -f $(PROGS) *.o *.di

doc-clean:
	rm -rf html
