/**
 * Graph edges are connections (tail -> head) between pairs of vertices.
 * This module provides data structures for storing lists of graph edges
 * and any associated properties, such as edge weights.
 *
 * Authors: $(LINK2 http://braingam.es/, Joseph Rushton Wakeling)
 *
 * Copyright: Copyright © 2016 Joseph Rushton Wakeling
 *
 * License: This program is free software: you can redistribute it and/or
 *          modify it under the terms of the GNU General Public License
 *          as published by the Free Software Foundation, either version
 *          3 of the License, or (at your option) any later version.
 *
 *          This program is distributed in the hope that it will be useful,
 *          but WITHOUT ANY WARRANTY; without even the implied warranty of
 *          MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *          GNU General Public License for more details.
 *
 *          You should have received a copy of the GNU General Public License
 *          along with this program.  If not, see
 *                                    $(LINK http://www.gnu.org/licenses/).
 */
module dgraph.data.edge;


/**
 * Data structure to hold all properties of graph edges.
 *
 * Edge property values are stored in arrays where the
 * i'th entry is the value of that property for edge i.
 * The element type and name of each property array
 * matches the type and name of the corresponding edge
 * property.
 *
 * No assumptions whatsoever are made about what edge
 * properties should be stored, or about whether the
 * implicit edge labels 0, 1, 2, ... are persistent;
 * the requirements here are left to the graph types
 * making use of this data structure.
 */
public struct EdgeData (GraphPropertyList...)
{
  private:
    import dgraph.data.properties :
        GraphElement, graphProperty, graphPropertyArrays, graphPropertyArrayVar;

  public:
    mixin graphPropertyArrays!(GraphElement.edge, GraphPropertyList);
}

unittest
{
    import std.traits : hasUDA;
    import dgraph.data.properties : GraphElement, graphProperty;

    enum Edge = GraphElement.edge;
    enum Vertex = GraphElement.vertex;

    enum Weights = graphProperty!(Edge, "weight", double);
    enum Deletion = graphProperty!(Edge, "deleted", bool);
    enum Colour = graphProperty!(Vertex, "colour", uint);

    {
        alias W = EdgeData!Weights;
        static assert(is(typeof(W.weight) == double[]));
        static assert(hasUDA!(W.weight, Weights));
    }

    {
        alias D = EdgeData!Deletion;
        static assert(is(typeof(D.deleted) == bool[]));
        static assert(hasUDA!(D.deleted, Deletion));
    }

    {
        alias C = EdgeData!Colour;
        static assert(!is(typeof(C.colour)));
    }

    {
        alias WD = EdgeData!(Weights, Deletion);
        static assert(is(typeof(WD.weight) == double[]));
        static assert(hasUDA!(WD.weight, Weights));
        static assert(!hasUDA!(WD.weight, Deletion));
        static assert(is(typeof(WD.deleted) == bool[]));
        static assert(hasUDA!(WD.deleted, Deletion));
        static assert(!hasUDA!(WD.deleted, Weights));
    }

    {
        alias WC = EdgeData!(Weights, Colour);
        static assert(is(typeof(WC.weight) == double[]));
        static assert(hasUDA!(WC.weight, Weights));
        static assert(!hasUDA!(WC.weight, Colour));
        static assert(!is(typeof(WC.colour)));
    }
}


/**
 * Helper template for constructing individual edge properties.
 */
template EdgeProperty (string name, T)
{
    import dgraph.data.properties : GraphElement, graphProperty;
    alias EdgeProperty = graphProperty!(GraphElement.edge, name, T);
}


/**
 * Property that records tail nodes for each edge
 * (in a directed graph, the source node that the
 * edge points away from; in undirected graphs,
 * the tail/head designation can be arbitrary).
 */
public enum EdgeTail = EdgeProperty!("tail", size_t);


/**
 * Property that records head nodes for each edge
 * (in a directed graph, the source node that the
 * edge points towards; in undirected graphs, the
 * tail/head designation can be arbitrary).
 */
public enum EdgeHead = EdgeProperty!("head", size_t);


/**
 * Property that provides weights for graph edges
 */
public enum EdgeWeights = EdgeProperty!("weight", double);


/**
 * Property that describes if an edge has been deleted
 * from the graph
 */
public enum EdgeDeletion = EdgeProperty!("deleted", bool);

/**
 * Extensible data structure describing the edges of
 * a graph in terms of their tail and head vertices,
 * together with any other custom edge properties.
 */
public template ExtensibleEdgeList (ExtraGraphProperties...)
{
    alias ExtensibleEdgeList = EdgeData!(EdgeTail, EdgeHead, ExtraGraphProperties);
}

unittest
{
    import std.traits : hasUDA;

    {
        alias E = ExtensibleEdgeList!();
        static assert(is(typeof(E.tail) == size_t[]));
        static assert(hasUDA!(E.tail, EdgeTail));
        static assert(is(typeof(E.head) == size_t[]));
        static assert(hasUDA!(E.head, EdgeHead));
    }

    import dgraph.data.properties : GraphElement, graphProperty;

    enum Edge = GraphElement.edge;
    enum Vertex = GraphElement.vertex;

    enum Weights = graphProperty!(Edge, "weight", double);
    enum Deletion = graphProperty!(Edge, "deleted", bool);
    enum Colour = graphProperty!(Vertex, "colour", uint);

    {
        alias W = ExtensibleEdgeList!Weights;
        static assert(is(typeof(W.tail) == size_t[]));
        static assert(hasUDA!(W.tail, EdgeTail));
        static assert(is(typeof(W.head) == size_t[]));
        static assert(hasUDA!(W.head, EdgeHead));
        static assert(is(typeof(W.weight) == double[]));
        static assert(hasUDA!(W.weight, Weights));
    }

    {
        alias D = ExtensibleEdgeList!Deletion;
        static assert(is(typeof(D.tail) == size_t[]));
        static assert(hasUDA!(D.tail, EdgeTail));
        static assert(is(typeof(D.head) == size_t[]));
        static assert(hasUDA!(D.head, EdgeHead));
        static assert(is(typeof(D.deleted) == bool[]));
        static assert(hasUDA!(D.deleted, Deletion));
    }

    {
        alias C = ExtensibleEdgeList!Colour;
        static assert(is(typeof(C.tail) == size_t[]));
        static assert(hasUDA!(C.tail, EdgeTail));
        static assert(is(typeof(C.head) == size_t[]));
        static assert(hasUDA!(C.head, EdgeHead));
        static assert(!is(typeof(C.colour)));
    }

    {
        alias WD = ExtensibleEdgeList!(Weights, Deletion);
        static assert(is(typeof(WD.tail) == size_t[]));
        static assert(hasUDA!(WD.tail, EdgeTail));
        static assert(is(typeof(WD.head) == size_t[]));
        static assert(hasUDA!(WD.head, EdgeHead));
        static assert(is(typeof(WD.weight) == double[]));
        static assert(hasUDA!(WD.weight, Weights));
        static assert(is(typeof(WD.deleted) == bool[]));
        static assert(hasUDA!(WD.deleted, Deletion));
    }

    {
        alias WC = ExtensibleEdgeList!(Weights, Colour);
        static assert(is(typeof(WC.tail) == size_t[]));
        static assert(hasUDA!(WC.tail, EdgeTail));
        static assert(is(typeof(WC.head) == size_t[]));
        static assert(hasUDA!(WC.head, EdgeHead));
        static assert(is(typeof(WC.weight) == double[]));
        static assert(hasUDA!(WC.weight, Weights));
        static assert(!is(typeof(WC.colour)));
    }
}


/**
 * Edge list without any custom edge properties
 */
public alias EdgeList = ExtensibleEdgeList!();
