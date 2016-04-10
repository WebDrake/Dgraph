/**
 * Graph properties are custom data fields that describe aspects of some
 * graph elements of interest: edges, vertices, or general features of
 * the graph as a whole.
 *
 * This module provides data structures and helper templates for using
 * properties and applying them to different graph elements.
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
module dgraph.data.properties;


/**
 * Enum of the different graph elements that
 * properties can describe: edges, vertices,
 * or general features of the whole graph.
 */
public enum GraphElement
{
    none,
    edge,
    vertex,
    general
}


/**
 * Helper template for constructing individual
 * properties of graph elements
 */
public template graphProperty (GraphElement element, string name, T)
{
    enum graphProperty = GraphProperty(element, name, T.stringof);
}


// Helper struct describing a single graph property
private struct GraphProperty
{
    /// Graph element the property applies to
    public GraphElement element;

    /// Name of the field that contains the property value
    public string name;

    /// Name of the type in which to store property values
    public string type;
}


/**
 * Mixin template that provides an array variable
 * for each of the graph properties applying to the
 * specified element type.  The array element type
 * will correspond to the property value type, and
 * the array name will be the same as the property
 * name.
 */
public mixin template graphPropertyArrays (GraphElement element, GraphPropertyList...)
{
    static if (GraphPropertyList.length > 0)
    {
        mixin graphPropertyArrayVar!(element, GraphPropertyList[0]);
        mixin graphPropertyArrays!(element, GraphPropertyList[1 .. $]);
    }
}

unittest
{
    import std.traits : hasUDA;

    enum Edge = GraphElement.edge;
    enum Vertex = GraphElement.vertex;

    enum Weights = graphProperty!(Edge, "weight", double);
    enum Deletion = graphProperty!(Edge, "deleted", bool);
    enum Colour = graphProperty!(Vertex, "colour", uint);

    {
        struct W { mixin graphPropertyArrays!(Edge, Weights); }
        static assert(is(typeof(W.weight) == double[]));
        static assert(hasUDA!(W.weight, Weights));
    }

    {
        struct D { mixin graphPropertyArrays!(Edge, Deletion); }
        static assert(is(typeof(D.deleted) == bool[]));
        static assert(hasUDA!(D.deleted, Deletion));
    }

    {
        struct C { mixin graphPropertyArrays!(Vertex, Colour); }
        static assert(is(typeof(C.colour) == uint[]));
        static assert(hasUDA!(C.colour, Colour));
    }

    {
        struct WD { mixin graphPropertyArrays!(Edge, Weights, Deletion); }
        static assert(is(typeof(WD.weight) == double[]));
        static assert(hasUDA!(WD.weight, Weights));
        static assert(!hasUDA!(WD.weight, Deletion));
        static assert(is(typeof(WD.deleted) == bool[]));
        static assert(hasUDA!(WD.deleted, Deletion));
        static assert(!hasUDA!(WD.deleted, Weights));
    }

    {
        struct WCe { mixin graphPropertyArrays!(Edge, Weights, Colour); }
        static assert(is(typeof(WCe.weight) == double[]));
        static assert(hasUDA!(WCe.weight, Weights));
        static assert(!hasUDA!(WCe.weight, Colour));
        static assert(!is(typeof(WCe.colour)));
    }

    {
        struct WCv { mixin graphPropertyArrays!(Vertex, Weights, Colour); }
        static assert(!is(typeof(WCv.weight)));
        static assert(is(typeof(WCv.colour) == uint[]));
        static assert(hasUDA!(WCv.colour, Colour));
        static assert(!hasUDA!(WCv.colour, Weights));
    }
}


/**
 * Mixin template that provides all the variables needed
 * to contain all the graph properties applying to the
 * specified element type.  Each variable will contain
 * a single property value, and its name will be the
 * same as the property name.
 */
public mixin template graphPropertyValues (GraphElement element, GraphPropertyList...)
{
    static if (GraphPropertyList.length > 0)
    {
        mixin graphPropertySingleVar!(element, GraphPropertyList[0]);
        mixin graphPropertyValues!(element, GraphPropertyList[1 .. $]);
    }
}

unittest
{
    import std.traits : hasUDA;

    enum Edge = GraphElement.edge;
    enum Vertex = GraphElement.vertex;

    enum Weights = graphProperty!(Edge, "weight", double);
    enum Deletion = graphProperty!(Edge, "deleted", bool);
    enum Colour = graphProperty!(Vertex, "colour", uint);

    {
        struct W { mixin graphPropertyValues!(Edge, Weights); }
        static assert(is(typeof(W.weight) == double));
        static assert(hasUDA!(W.weight, Weights));
    }

    {
        struct D { mixin graphPropertyValues!(Edge, Deletion); }
        static assert(is(typeof(D.deleted) == bool));
        static assert(hasUDA!(D.deleted, Deletion));
    }

    {
        struct C { mixin graphPropertyValues!(Vertex, Colour); }
        static assert(is(typeof(C.colour) == uint));
        static assert(hasUDA!(C.colour, Colour));
    }

    {
        struct WD { mixin graphPropertyValues!(Edge, Weights, Deletion); }
        static assert(is(typeof(WD.weight) == double));
        static assert(hasUDA!(WD.weight, Weights));
        static assert(!hasUDA!(WD.weight, Deletion));
        static assert(is(typeof(WD.deleted) == bool));
        static assert(hasUDA!(WD.deleted, Deletion));
        static assert(!hasUDA!(WD.deleted, Weights));
    }

    {
        struct WCe { mixin graphPropertyValues!(Edge, Weights, Colour); }
        static assert(is(typeof(WCe.weight) == double));
        static assert(hasUDA!(WCe.weight, Weights));
        static assert(!hasUDA!(WCe.weight, Colour));
        static assert(!is(typeof(WCe.colour)));
    }

    {
        struct WCv { mixin graphPropertyValues!(Vertex, Weights, Colour); }
        static assert(!is(typeof(WCv.weight)));
        static assert(is(typeof(WCv.colour) == uint));
        static assert(hasUDA!(WCv.colour, Colour));
        static assert(!hasUDA!(WCv.colour, Weights));
    }
}


/**
 * Mixin template that provides an array variable containing
 * values of a single graph element property, whose name
 * matches the property name.
 *
 * If the `element` parameter does not match the graph
 * element the property applies to, no variable will be
 * emitted.
 */
public mixin template graphPropertyArrayVar (GraphElement element, GraphProperty property)
{
    static if (element == property.element)
    {
        @(property) mixin(property.type ~ `[] ` ~ property.name ~ `;`);
    }
}

unittest
{
    import std.traits : hasUDA;

    enum Edge = GraphElement.edge;
    enum Vertex = GraphElement.vertex;

    enum Weights = graphProperty!(Edge, "weight", double);
    enum Deletion = graphProperty!(Edge, "deleted", bool);
    enum Colour = graphProperty!(Vertex, "colour", uint);

    // scope the following tests to avoid variable shadowing

    {
        mixin graphPropertyArrayVar!(Edge, Weights);
        static assert(is(typeof(weight) == double[]));
        static assert(hasUDA!(weight, Weights));
    }

    {
        mixin graphPropertyArrayVar!(Edge, Deletion);
        static assert(is(typeof(deleted) == bool[]));
        static assert(hasUDA!(deleted, Deletion));
    }

    {
        mixin graphPropertyArrayVar!(Vertex, Colour);
        static assert(is(typeof(colour) == uint[]));
        static assert(hasUDA!(colour, Colour));
    }

    {
        mixin graphPropertyArrayVar!(Vertex, Weights);
        static assert(!is(typeof(weight)));
    }

    {
        mixin graphPropertyArrayVar!(Edge, Colour);
        static assert(!is(typeof(colour)));
    }
}

unittest
{
    import std.traits : hasUDA;

    enum Edge = GraphElement.edge;
    enum Vertex = GraphElement.vertex;

    enum Weights = graphProperty!(Edge, "weight", double);
    enum Deletion = graphProperty!(Edge, "deleted", bool);
    enum Colour = graphProperty!(Vertex, "colour", uint);

    {
        struct W { mixin graphPropertyArrayVar!(Edge, Weights); }
        static assert(is(typeof(W.weight) == double[]));
        static assert(hasUDA!(W.weight, Weights));
    }

    {
        struct D { mixin graphPropertyArrayVar!(Edge, Deletion); }
        static assert(is(typeof(D.deleted) == bool[]));
        static assert(hasUDA!(D.deleted, Deletion));
    }

    {
        struct C { mixin graphPropertyArrayVar!(Vertex, Colour); }
        static assert(is(typeof(C.colour) == uint[]));
        static assert(hasUDA!(C.colour, Colour));
    }

    {
        struct VW { mixin graphPropertyArrayVar!(Vertex, Weights); }
        static assert(!is(typeof(VW.weight)));
    }

    {
        struct EC { mixin graphPropertyArrayVar!(Edge, Colour); }
        static assert(!is(typeof(EC.colour)));
    }
}


/**
 * Mixin template that provides a variable containing
 * a single graph element property value, whose name
 * matches the property name.
 *
 * If the `element` parameter does not match the graph
 * element the property applies to, no variable will be
 * emitted.
 */
public mixin template graphPropertySingleVar (GraphElement element, GraphProperty property)
{
    static if (element == property.element)
    {
        @(property) mixin(property.type ~ ` ` ~ property.name ~ `;`);
    }
}

unittest
{
    import std.traits : hasUDA;

    enum Edge = GraphElement.edge;
    enum Vertex = GraphElement.vertex;

    enum Weights = graphProperty!(Edge, "weight", double);
    enum Deletion = graphProperty!(Edge, "deleted", bool);
    enum Colour = graphProperty!(Vertex, "colour", uint);

    // scope the following tests to avoid variable shadowing

    {
        mixin graphPropertySingleVar!(Edge, Weights);
        static assert(is(typeof(weight) == double));
        static assert(hasUDA!(weight, Weights));
    }

    {
        mixin graphPropertySingleVar!(Edge, Deletion);
        static assert(is(typeof(deleted) == bool));
        static assert(hasUDA!(deleted, Deletion));
    }

    {
        mixin graphPropertySingleVar!(Vertex, Colour);
        static assert(is(typeof(colour) == uint));
        static assert(hasUDA!(colour, Colour));
    }

    {
        mixin graphPropertySingleVar!(Vertex, Weights);
        static assert(!is(typeof(weight)));
    }

    {
        mixin graphPropertySingleVar!(Edge, Colour);
        static assert(!is(typeof(colour)));
    }
}

unittest
{
    import std.traits : hasUDA;

    enum Edge = GraphElement.edge;
    enum Vertex = GraphElement.vertex;

    enum Weights = graphProperty!(Edge, "weight", double);
    enum Deletion = graphProperty!(Edge, "deleted", bool);
    enum Colour = graphProperty!(Vertex, "colour", uint);

    {
        struct W { mixin graphPropertySingleVar!(Edge, Weights); }
        static assert(is(typeof(W.weight) == double));
        static assert(hasUDA!(W.weight, Weights));
    }

    {
        struct D { mixin graphPropertySingleVar!(Edge, Deletion); }
        static assert(is(typeof(D.deleted) == bool));
        static assert(hasUDA!(D.deleted, Deletion));
    }

    {
        struct C { mixin graphPropertySingleVar!(Vertex, Colour); }
        static assert(is(typeof(C.colour) == uint));
        static assert(hasUDA!(C.colour, Colour));
    }

    {
        struct VW { mixin graphPropertySingleVar!(Vertex, Weights); }
        static assert(!is(typeof(VW.weight)));
    }

    {
        struct EC { mixin graphPropertySingleVar!(Edge, Colour); }
        static assert(!is(typeof(EC.colour)));
    }
}
