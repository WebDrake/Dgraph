// Written in the D programming language.

/**
  Simple test file involving the generation of a 50-node undirected graph
  where each node has 4 neighbours.

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

  Credits:   The basic graph data structure used here is adapted from the library
             $(LINK2 http://igraph.sourceforge.net/, igraph) by Gábor Csárdi and
             Tamás Nepusz.
*/

import dgraph.graph;

void foo()
{

	int edges[200] =
	  [ 0, 24,
		0, 25,
		0, 16,
		0, 26,
		1, 37,
		1, 38,
		1, 11,
		1, 14,
		2, 19,
		2, 33,
		2, 35,
		2, 27,
		3, 40,
		3, 39,
		3, 23,
		3, 19,
		4, 18,
		4, 31,
		4, 37,
		4, 7,
		5, 17,
		5, 49,
		5, 18,
		5, 28,
		6, 27,
		6, 42,
		6, 9,
		6, 44,
		7, 19,
		7, 18,
		7, 49,
		8, 36,
		8, 43,
		8, 41,
		8, 33,
		9, 14,
		9, 11,
		9, 46,
		10, 26,
		10, 36,
		10, 35,
		10, 41,
		11, 32,
		11, 21,
		12, 21,
		12, 23,
		12, 29,
		12, 35,
		13, 45,
		13, 25,
		13, 38,
		13, 29,
		14, 16,
		14, 39,
		15, 48,
		15, 49,
		15, 44,
		15, 38,
		16, 47,
		16, 43,
		17, 25,
		17, 41,
		17, 49,
		18, 28,
		19, 40,
		20, 33,
		20, 21,
		20, 24,
		20, 31,
		21, 32,
		22, 32,
		22, 46,
		22, 34,
		22, 37,
		23, 30,
		23, 26,
		24, 43,
		24, 30,
		25, 42,
		26, 35,
		27, 39,
		27, 46,
		28, 47,
		28, 34,
		29, 33,
		29, 36,
		30, 38,
		30, 34,
		31, 48,
		31, 45,
		32, 46,
		34, 45,
		36, 48,
		37, 48,
		39, 40,
		40, 47,
		41, 44,
		42, 47,
		42, 44,
		43, 45
	  ];

    auto g = new Graph!false;
    g.addVertices(50);

    foreach(i; 0 .. 100)
    {
        g.addEdge(edges[2*i], edges[2 * i + 1]);
    }

/*    import std.stdio;
    writeln("Number of vertices: ", g.vertexCount);
    writeln("Number of edges: ", g.edges.length);
    writeln("Neighbours of node 0: ", g.neighbours(0));*/
}

void main()
{
	int i;
	for(i = 0; i < 10000; ++i)
		foo();
}
