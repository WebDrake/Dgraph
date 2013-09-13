Dgraph
======

Dgraph is a library for creating, analysing and manipulating graphs, written in
the D programming language.  It aims to be fast and memory-efficient while also
being easy to use and extend.

The project is in very early experimental stages of development, so breaking
changes may occur on a regular basis (although every effort will be made to
ensure that such breakage is justified by the gains).  News and updates on
the project will be published on the author's blog: http://braingam.es/

Git repository: https://github.com/WebDrake/Dgraph

Dgraph is distributed under the terms of the GNU General Public License,
version 3 or (at your option) any later version.


Features
--------

Dgraph currently implements two different graph types (module dgraph.graph):
```IndexedEdgeList``` is an adaptation to D of the similarly-named igraph
data type, while ```CachedEdgeList``` is an extension of the indexed edge
list that (as its name indicates) caches the results of various calculations
in order to provide faster performance.

Graphs may be directed or undirected, but Dgraph currently offers no support
for weighted graphs or any other edge or vertex properties.  Arbitrary vertex
IDs (e.g. strings) are not currently supported.

The module dgraph.metric offers a selection of metrics for calculating
different graph properties: currently betweenness centrality and largest
connected cluster size are implemented.

Finally, the library provides a small selection of benchmarks for graph
construction and calculation of graph metrics.


Contributing
------------

Code contributions to Dgraph are welcome.  Please try to follow the D style
guidelines: http://dlang.org/dstyle.html

Feature requests and bug reports can be submitted via the Dgraph GitHub
issue list.
