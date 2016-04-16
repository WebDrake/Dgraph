/**
 * This module provides data structures for storing properties of graph
 * vertices.
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
module dgraph.data.vertex;


/**
 * Data structure to hold all graph vertex properties.
 *
 * Vertex property values are stored in arrays where the
 * i'th entry is the value of that property for vertex i.
 * The element type and name of each property array
 * matches the type and name of the corresponding vertex
 * property.
 *
 * No assumptions whatsoever are made about what vertex
 * properties should be stored, or about whether the
 * vertex index values 0, 1, 2, ... persistently refer
 * to the same vertices; the requirements here are left
 * to the graph types making use of this data structure.
 */
public struct VertexData (GraphPropertyList...)
{
  private:
    import dgraph.data.properties :
        GraphElement, graphProperty, graphPropertyArrays, graphPropertyArrayVar;

  public:
    mixin graphPropertyArrays!(GraphElement.vertex, GraphPropertyList);
}

unittest
{
    import std.traits : hasUDA;
    import dgraph.data.properties : GraphElement, graphProperty;

    enum Edge = GraphElement.edge;
    enum Vertex = GraphElement.vertex;

    enum SumTail = graphProperty!(Vertex, "sumTail", size_t);
    enum SumHead = graphProperty!(Vertex, "sumHead", size_t);
    enum Colour = graphProperty!(Vertex, "colour", uint);
    enum Weights = graphProperty!(Edge, "weight", double);

    {
        alias ST = VertexData!SumTail;
        static assert(is(typeof(ST.sumTail) == size_t[]));
        static assert(hasUDA!(ST.sumTail, SumTail));
    }

    {
        alias SH = VertexData!SumHead;
        static assert(is(typeof(SH.sumHead) == size_t[]));
        static assert(hasUDA!(SH.sumHead, SumHead));
    }

    {
        alias C = VertexData!Colour;
        static assert(is(typeof(C.colour) == uint[]));
        static assert(hasUDA!(C.colour, Colour));
    }

    {
        alias W = VertexData!Weights;
        static assert(!is(typeof(W.weight)));
    }

    {
        alias WTH = VertexData!(Weights, SumTail, SumHead);
        static assert(!is(typeof(WTH.weight)));
        static assert(is(typeof(WTH.sumTail) == size_t[]));
        static assert(hasUDA!(WTH.sumTail, SumTail));
        static assert(is(typeof(WTH.sumHead) == size_t[]));
        static assert(hasUDA!(WTH.sumHead, SumHead));
    }
}


/**
 * Helper template for constructing individual vertex properties.
 */
public template VertexProperty (string name, T)
{
    import dgraph.data.properties : GraphElement, graphProperty;
    alias VertexProperty = graphProperty!(GraphElement.vertex, name, T);

}


/**
 * Property that allows colouring of graph vertices
 */
public enum VertexColour = VertexProperty!("colour", ulong);


/**
 * Template for creation of a property that associates
 * an identity marker with vertices (e.g. a string or
 * numerical label).
 */
public template VertexID (T)
{
    enum VertexID = VertexProperty!("id", T);
}


/**
 * Vertex properties that record the number of graph edges
 * with, respectively, tail or head less than the vertex's
 * index value
 */
public enum VertexSumTail = VertexProperty!("sumTail", size_t);
/// ditto
public enum VertexSumHead = VertexProperty!("sumHead", size_t);
