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

import dgraph.graph;

/**
  Tests adding edges one at a time.  Can be used e.g. for benchmarking or for
  checking that network properties are reliably imported.
 */
void testAddEdge(bool directed = false, ushort verbose = 0)(immutable size_t v, immutable size_t[] edgeList)
{
    assert(edgeList.length % 2 == 0);
    auto g = new Graph!directed;
    g.addVertices(v);

    foreach(i; 0 .. edgeList.length / 2)
    {
        g.addEdge(edgeList[2*i], edgeList[2 * i + 1]);
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
            writeln("Incoming neighbours of vertex 0: ", g.neighboursIn(0));
            writeln("Outgoing neighbours of vertex 0: ", g.neighboursOut(0));
        }
        else
        {
            writeln("Neighbours of node 0: ", g.neighbours(0));
        }
        static if (verbose > 1)
        {
            static if (g.directed)
            {
                writeln("In- and out-degrees of vertices:");
                foreach(i; 0 .. g.vertexCount)
                {
                    writeln("\t", i, "\t", g.degreeIn(i), "\t", g.degreeOut(i));
                }
            }
            else
            {
                writeln("Degrees of vertices:");
                foreach(i; 0 .. g.vertexCount)
                {
                    writeln("\t", i, "\t", g.degree(i));
                }
            }
        }
    }
}
