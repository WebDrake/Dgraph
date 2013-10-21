DC = gdmd
DFLAGS = -O -inline
LIBSRC = source/dgraph/*.d source/dgraph/test/*.d
PROGS = dgraph_graphtest dgraph_betweenness50 dgraph_betweenness10k

all: $(PROGS)

docs: $(LIBSRC)
	$(DC) -o- -D -Dddocs $(LIBSRC)

dgraph_%: util/*/source/%.d $(LIBSRC)
	$(DC) $(DFLAGS) -ofdgraph_$* util/$*/source/$*.d $(LIBSRC)

.PHONY: clean

clean:
	rm -f $(PROGS) *.o *.di

docs-clean:
	rm -rf docs
