// Written in the D programming language.

/**
  Test collection for dgraph library.

  Authors:   $(LINK2 http://braingam.es/, Joseph Rushton Wakeling)
  Copyright: Copyright © 2013 Joseph Rushton Wakeling
  License:   This program is free software: you can redistribute it and/or modify
             it under the terms of the GNU General Public License as published by
             the Free Software Foundation, either version 3 of the License, or
             (at your option) any later version.

             This program is distributed in the hope that it will be useful,
             but WITHOUT ANY WARRANTY; without even the implied warranty of
             MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
             GNU General Public License for more details.

             You should have received a copy of the GNU General Public License
             along with this program.  If not, see $(LINK http://www.gnu.org/licenses/).
*/

module dgraph.test.tests;

import std.algorithm, std.conv, std.exception;

import dgraph.graph;

/**
 * Tests adding edges to a graph, either one at a time or all in one go.  Can
 * be used e.g. for benchmarking or for checking that network properties are
 * reliably imported.
 */
void testAddEdge(Graph, bool allAtOnce = false, ushort verbose = 0, T : size_t)
                (immutable size_t v, T[] edgeList)
    if (isGraph!Graph)
{
    assert(edgeList.length % 2 == 0);
    static if (is(Graph == class))
    {
        auto g = new Graph;
    }
    else
    {
        auto g = Graph;
    }
    g.vertexCount = v;

    static if (allAtOnce)
    {
        g.addEdge(edgeList);
    }
    else
    {
        foreach (immutable i; 0 .. edgeList.length / 2)
        {
            g.addEdge(edgeList[2*i], edgeList[2 * i + 1]);
        }
    }

    static if (verbose > 0)
    {
        import std.stdio;
        static if (g.directed)
        {
            writeln("Directed graph.");
        }
        else
        {
            writeln("Undirected graph.");
        }
        writeln("Number of vertices: ", g.vertexCount);
        writeln("Number of edges: ", g.edgeCount);
        static if (g.directed)
        {
            writeln("Incoming neighbours of vertex 0: ", g.neighboursIn[0]);
            writeln("Outgoing neighbours of vertex 0: ", g.neighboursOut[0]);
        }
        else
        {
            writeln("Neighbours of node 0: ", g.neighbours[0]);
        }
    }
    static if (verbose > 1)
    {
        static if (g.directed)
        {
            writeln("In- and out-degrees of vertices:");
            foreach (immutable i; 0 .. g.vertexCount)
            {
                writeln("\t", i, "\t", g.degreeIn(i), "\t", g.degreeOut(i));
            }
        }
        else
        {
            writeln("Degrees of vertices:");
            foreach (immutable i; 0 .. g.vertexCount)
            {
                writeln("\t", i, "\t", g.degree(i));
            }
        }
    }
    static if (verbose > 2)
    {
        writeln("Incoming neighbours for vertices:");
        foreach (immutable i; 0 .. g.vertexCount)
        {
            write("\t", i, ": ");
            foreach (immutable n; g.neighboursIn[i])
            {
                write(" ", n);
            }
            writeln;
            assert(isSorted(g.neighboursIn[i]));
        }
        writeln("Outgoing neighbours for vertices:");
        foreach (immutable i; 0 .. g.vertexCount)
        {
            write("\t", i, ": ");
            foreach (immutable n; g.neighboursOut[i])
            {
                write(" ", n);
            }
            writeln;
            assert(isSorted(g.neighboursOut[i]));
        }
    }
}

/// Tests that the edgeID function returns correct values for all edges in the graph.
void testEdgeID(Graph)(ref Graph g)
    if (isGraph!Graph)
{
    foreach (immutable i; 0 .. g.edgeCount)
    {
        auto edge = g.edge[i];
        size_t id = g.edgeID(edge[0], edge[1]);
        enforce(i == id, text("Edge ID failure for edge ", i, ": edgeID(", edge[0], ", ", edge[1], ") returns ", id));
        static if (!Graph.directed)
        {
            id = g.edgeID(edge[1], edge[0]);
            enforce(i == id, text("Edge ID failure for edge ", i, ": edgeID(", edge[1], ", ", edge[0], ") returns ", id));
        }
    }
}

unittest
{
    import std.typetuple;
    foreach (Graph; TypeTuple!(IndexedEdgeList, CachedEdgeList))
    {
        foreach (directed; TypeTuple!(false, true))
        {
            {
                import dgraph.test.samplegraph50;
                auto g = new Graph!directed;
                g.vertexCount = 50;
                g.addEdge(sampleGraph50);
                testEdgeID(g);
            }

            {
                import dgraph.test.samplegraph10k;
                auto g = new Graph!directed;
                g.vertexCount = 10_000;
                g.addEdge(sampleGraph10k);
                testEdgeID(g);
            }
        }
    }
}
