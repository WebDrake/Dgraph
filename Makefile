DC = gdmd
DFLAGS = -O -inline
LIBSRC = source/dgraph/*.d source/dgraph/test/*.d
PROGS = graphtest betweenness50 betweenness10k

all: $(PROGS)

html: $(LIBSRC)
	$(DC) -o- -D -Ddhtml $(LIBSRC)

%: source/%.d $(LIBSRC)
	$(DC) $(DFLAGS) -of$* source/$*.d $(LIBSRC)

.PHONY: clean

clean:
	rm -f $(PROGS) *.o *.di

doc-clean:
	rm -rf html
