DC = gdmd
DFLAGS = -O -inline
LIBSRC = source/dgraph/*.d source/dgraph/test/*.d
PROGS = graphtest betweenness50 betweenness10k

all: $(PROGS)

html: $(LIBSRC)
	$(DC) -o- -D -Ddhtml $(LIBSRC)

%: util/*/source/%.d $(LIBSRC)
	$(DC) $(DFLAGS) -of$* util/$*/source/$*.d $(LIBSRC)

.PHONY: clean

clean:
	rm -f $(PROGS) *.o *.di

doc-clean:
	rm -rf html
