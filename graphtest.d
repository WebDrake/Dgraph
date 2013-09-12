// Written in the D programming language.

/**
  Simple test file benchmarking the generation of small and large graphs by the
  addition of edges one at a time.

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

import std.datetime, std.stdio, std.typetuple;
import dgraph.graph, dgraph.test.tests, dgraph.test.samplegraph50,
       dgraph.test.samplegraph10k;

void main()
{
    writeln("Let's benchmark some simple graph creation scenarios.");

    foreach (G; TypeTuple!(IndexedEdgeList, CachedEdgeList))
    {
        foreach (directed; TypeTuple!(false, true))
        {
            alias Graph = G!directed;
            StopWatch watch;

            writeln;
            writeln("Graph type: ", (Graph.directed) ? "directed " : "undirected ", Graph.stringof);
            writeln;

            writeln("First, a graph of 50 vertices, with edges added one at a time.");
            writeln("This is quite quick, so we'll do it 100_001 times with the last");
            writeln("time being verbose.");
            watch.start;
            foreach (immutable _; 0 .. 100_000)
            {
                testAddEdge!(Graph, true, 0)(50, sampleGraph50);
            }
            testAddEdge!(Graph, true, 1)(50, sampleGraph50);
            watch.stop;
            writeln("Done in ", watch.peek.msecs, " ms.");
            writeln;

            writeln("Now let's try a much bigger graph of 10,000 vertices, again");
            writeln("with each edge being added one at a time.  Because it's bigger");
            writeln("we'll only do it 1001 times, the last verbosely.");
            watch.reset;
            watch.start;
            foreach (immutable _; 0 .. 1_000)
            {
                testAddEdge!(Graph, true, 0)(10_000, sampleGraph10k);
            }
            testAddEdge!(Graph, true, 1)(10_000, sampleGraph10k);
            watch.stop;
            writeln("Done in ", watch.peek.msecs, " ms.");
            writeln;
        }
    }
}
