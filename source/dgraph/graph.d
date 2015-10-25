// Written in the D programming language.

/**
  Basic graph data structures.

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

module dgraph.graph;

import std.algorithm, std.array, std.exception, std.range, std.traits;
import std.string : format;

/// Test if G is a Dgraph graph type.
template isGraph(G)
{
    static if (!__traits(hasMember, G, "directed") ||
               !__traits(hasMember, G, "edge") ||
               !__traits(hasMember, G, "edgeCount") ||
               !__traits(hasMember, G, "vertexCount") ||
               !__traits(hasMember, G, "isEdge") ||
               !__traits(hasMember, G, "edgeID") ||
               !__traits(hasMember, G, "addEdge") ||
               !__traits(hasMember, G, "degreeIn") ||
               !__traits(hasMember, G, "degreeOut") ||
               !__traits(hasMember, G, "incidentEdgesIn") ||
               !__traits(hasMember, G, "incidentEdgesOut") ||
               !__traits(hasMember, G, "neighboursIn") ||
               !__traits(hasMember, G, "neighboursOut"))
    {
        enum bool isGraph = false;
    }
    else static if (!isBoolean!(typeof(G.directed)))
    {
        enum bool isGraph = false;
    }
    else static if (G.directed && (__traits(hasMember, G, "degree") ||
                                   __traits(hasMember, G, "incidentEdges") ||
                                   __traits(hasMember, G, "neighbours")))
    {
        enum bool isGraph = false;
    }
    else static if (!G.directed && (!__traits(hasMember, G, "degree") ||
                                    !__traits(hasMember, G, "incidentEdges") ||
                                    !__traits(hasMember, G, "neighbours")))
    {
        enum bool isGraph = false;
    }
    else static if (!isRandomAccessRange!(ReturnType!(G.incidentEdgesIn)) ||
                    !isRandomAccessRange!(ReturnType!(G.incidentEdgesOut)))
    {
        enum bool isGraph = false;
    }
    else static if (!isRandomAccessRange!(ReturnType!(G.neighboursIn)) ||
                    !isRandomAccessRange!(ReturnType!(G.neighboursOut)))
    {
        enum bool isGraph = false;
    }
    else static if (!G.directed && (!isRandomAccessRange!(ReturnType!(G.incidentEdges)) ||
                                    !isRandomAccessRange!(ReturnType!(G.neighbours))))
    {
        enum bool isGraph = false;
    }
    else
    {
        enum bool isGraph = true;
    }
}

/// Test if G is a directed graph.
template isDirectedGraph(G)
{
    static if (isGraph!G)
    {
        enum bool isDirectedGraph = G.directed;
    }
    else
    {
        enum bool isDirectedGraph = false;
    }
}

/// Test if G is an undirected graph.
template isUndirectedGraph(G)
{
    static if (isGraph!G)
    {
        enum bool isUndirectedGraph = !G.directed;
    }
    else
    {
        enum bool isUndirectedGraph = false;
    }
}

unittest
{
    assert(isGraph!(IndexedEdgeList!true));
    assert(isGraph!(IndexedEdgeList!false));
    assert(isDirectedGraph!(IndexedEdgeList!true));
    assert(!isDirectedGraph!(IndexedEdgeList!false));
    assert(!isUndirectedGraph!(IndexedEdgeList!true));
    assert(isUndirectedGraph!(IndexedEdgeList!false));

    assert(isGraph!(CachedEdgeList!true));
    assert(isGraph!(CachedEdgeList!false));
    assert(isDirectedGraph!(CachedEdgeList!true));
    assert(!isDirectedGraph!(CachedEdgeList!false));
    assert(!isUndirectedGraph!(CachedEdgeList!true));
    assert(isUndirectedGraph!(CachedEdgeList!false));
}

/**
 * Graph data type based on igraph's igraph_t.  The basic data structure is a
 * pair of arrays whose entries consist of respectively the source (tail) and
 * destination (head) vertices of the edges in the graph.  These are extended
 * by sorted indices and cumulative sums that enable fast calculation of graph
 * properties from the stored data.
 */
final class IndexedEdgeList(bool dir)
{
  private:
    size_t[] tail_;
    size_t[] head_;
    size_t[] indexTail_;
    size_t[] indexHead_;
    size_t[] sumTail_ = [0];
    size_t[] sumHead_ = [0];

    void indexEdgesInsertion()
    {
        assert(indexTail_.length == indexHead_.length);
        assert(tail_.length == head_.length);
        immutable size_t l = indexTail_.length;
        indexTail_.length = tail_.length;
        indexHead_.length = head_.length;
        foreach (immutable e; l .. tail_.length)
        {
            size_t i, j, lower, upper;
            upper = indexTail_[0 .. e].map!(a => tail_[a]).assumeSorted.lowerBound(tail_[e] + 1).length;
            lower = indexTail_[0 .. upper].map!(a => tail_[a]).assumeSorted.lowerBound(tail_[e]).length;
            i = lower + indexTail_[lower .. upper].map!(a => head_[a]).assumeSorted.lowerBound(head_[e]).length;
            for (j = e; j > i; --j)
            {
                indexTail_[j] = indexTail_[j - 1];
            }
            indexTail_[i] = e;

            upper = indexHead_[0 .. e].map!(a => head_[a]).assumeSorted.lowerBound(head_[e] + 1).length;
            lower = indexHead_[0 .. upper].map!(a => head_[a]).assumeSorted.lowerBound(head_[e]).length;
            i = lower + indexHead_[lower .. upper].map!(a => tail_[a]).assumeSorted.lowerBound(tail_[e]).length;
            for (j = e; j > i; --j)
            {
                indexHead_[j] = indexHead_[j - 1];
            }
            indexHead_[i] = e;
        }
        assert(indexTail_.length == indexHead_.length);
        assert(indexTail_.length == tail_.length, format("%s tail indices but %s tail values.", indexTail_.length, tail_.length));
        assert(indexHead_.length == head_.length, format("%s head indices but %s head values.", indexHead_.length, head_.length));
    }

    void indexEdgesSort()
    {
        indexTail_ ~= iota(indexTail_.length, tail_.length).array;
        indexHead_ ~= iota(indexHead_.length, head_.length).array;
        assert(indexTail_.length == indexHead_.length);
        indexTail_.multiSort!((a, b) => tail_[a] < tail_[b], (a, b) => head_[a] < head_[b]);
        indexHead_.multiSort!((a, b) => head_[a] < head_[b], (a, b) => tail_[a] < tail_[b]);
    }

    void sumEdges(ref size_t[] sum, in size_t[] vertex, in size_t[] index) @safe const nothrow pure
    {
        assert(sum.length > 1);

        size_t v = vertex[index[0]];
        sum[0 .. v + 1] = 0;
        for (size_t i = 1; i < index.length; ++i)
        {
            size_t n = vertex[index[i]] - vertex[index[sum[v]]];
            sum[v + 1 .. v + n + 1] = i;
            v += n;
        }
        sum[v + 1 .. $] = vertex.length;
    }

  public:
    /**
     * Add new edges to the graph.  These may be provided either singly, by
     * passing an individual (tail, head) pair, or en masse by passing an array
     * whose entries are [tail1, head1, tail2, head2, ...].  Duplicate edges
     * are permitted.
     */
    void addEdge()(size_t tail, size_t head)
    {
        enforce(tail < vertexCount, format("Edge tail %s is greater than largest vertex ID %s", tail, vertexCount - 1));
        enforce(head < vertexCount, format("Edge head %s is greater than largest vertex ID %s", head, vertexCount - 1));
        static if (!directed)
        {
            if (head < tail)
            {
                swap(tail, head);
            }
        }
        tail_ ~= tail;
        head_ ~= head;
        indexEdgesInsertion();
        ++sumTail_[tail + 1 .. $];
        ++sumHead_[head + 1 .. $];
    }

    /// ditto
    void addEdge(T : size_t)(T[] edgeList)
    {
        enforce(edgeList.length % 2 == 0);
        assert(tail_.length == head_.length);
        immutable size_t l = tail_.length;
        tail_.length += edgeList.length / 2;
        head_.length += edgeList.length / 2;
        foreach (immutable i; 0 .. edgeList.length / 2)
        {
            size_t tail = edgeList[2 * i];
            size_t head = edgeList[2 * i + 1];
            enforce(tail < vertexCount, format("Edge tail %s is greater than largest vertex ID %s", tail, vertexCount - 1));
            enforce(head < vertexCount, format("Edge head %s is greater than vertex count %s", head, vertexCount - 1));
            static if (!directed)
            {
                if (head < tail)
                {
                    swap(tail, head);
                }
            }
            tail_[l + i] = tail;
            head_[l + i] = head;
        }
        indexEdgesSort();
        sumEdges(sumTail_, tail_, indexTail_);
        sumEdges(sumHead_, head_, indexHead_);
    }

    static if (directed)
    {
        /**
         * Provide respectively the in- and out-degrees of a vertex v, i.e.
         * the number of vertices to which v is connected by respectively
         * incoming or outgoing links.  If the graph is undirected, these
         * values are identical and the general degree method is also defined.
         */
        size_t degreeIn(in size_t v) @safe const pure
        {
            enforce(isVertex(v));
            assert(v + 1 < sumHead_.length);
            return sumHead_[v + 1] - sumHead_[v];
        }

        ///ditto
        size_t degreeOut(in size_t v) @safe const pure
        {
            enforce(isVertex(v));
            assert(v + 1 < sumTail_.length);
            return sumTail_[v + 1] - sumTail_[v];
        }
    }
    else
    {
        /// Provides the degree of a vertex v in an undirected graph.
        size_t degree(in size_t v) @safe const pure
        {
            enforce(isVertex(v));
            assert(v + 1 < sumTail_.length);
            assert(sumTail_.length == sumHead_.length);
            return (sumTail_[v + 1] - sumTail_[v])
                 + (sumHead_[v + 1] - sumHead_[v]);
        }

        alias degreeIn = degree;
        alias degreeOut = degree;
    }

    /**
     * Static boolean value indicating whether or not the graph is directed.
     * This is available for compile-time as well as runtime checks.
     */
    alias directed = dir;

    /**
     * Returns a list of all edges in the graph in the form of a list of
     * (tail, head) vertex pairs.
     */
    auto edge() @property @safe const nothrow pure
    {
        return zip(tail_, head_);
    }

    /// Total number of edges in the graph.
    size_t edgeCount() @property @safe const nothrow pure
    {
        assert(tail_.length == head_.length);
        return tail_.length;
    }

    /**
     * Returns the edge index for a given (tail, head) vertex pair.  If
     * (tail, head) is not an edge, will throw an exception.
     */
    size_t edgeID(size_t tail, size_t head) const
    {
        if (!isVertex(tail))
        {
            throw new Exception(format("No vertex with ID %s", tail));
        }

        if (!isVertex(head))
        {
            throw new Exception(format("No vertex with ID %s", head));
        }

        static if (!directed)
        {
            if (head < tail)
            {
                swap(tail, head);
            }
        }

        size_t tailDeg = sumTail_[tail + 1] - sumTail_[tail];
        size_t headDeg = sumHead_[head + 1] - sumHead_[head];

        if (tailDeg == 0)
        {
            static if (directed)
            {
                assert(degreeOut(tail) == 0);
                throw new Exception(format("Vertex %s has no outgoing neighbours.", tail));
            }
            else
            {
                throw new Exception(format("(%s, %s) is not an edge", tail, head));
            }
        }

        if (headDeg == 0)
        {
            static if (directed)
            {
                assert(degreeIn(head) == 0);
                throw new Exception(format("Vertex %s has no incoming neighbours.", head));
            }
            else
            {
                throw new Exception(format("(%s, %s) is not an edge", tail, head));
            }
        }

        if (tailDeg < headDeg)
        {
            // search among the heads of tail
            foreach (immutable i; iota(sumTail_[tail], sumTail_[tail + 1]).map!(a => indexTail_[a]))
            {
                if (head_[i] == head)
                {
                    assert(tail_[i] == tail);
                    return i;
                }
            }
            throw new Exception(format("(%s, %s) is not an edge.", tail, head));
        }
        else
        {
            // search among the tails of head
            foreach (immutable i; iota(sumHead_[head], sumHead_[head + 1]).map!(a => indexHead_[a]))
            {
                if (tail_[i] == tail)
                {
                    assert(head_[i] == head);
                    return i;
                }
            }
            throw new Exception(format("(%s, %s) is not an edge.", tail, head));
        }
    }

    static if (directed)
    {
        /**
         * Returns the IDs of edges respectively incoming to or outgoing from
         * the specified vertex v.  If the graph is undirected the two will be
         * identical and the general method incidentEdges is also defined.
         */
        auto incidentEdgesIn(in size_t v) const
        {
            enforce(isVertex(v));
            return iota(sumHead_[v], sumHead_[v + 1]).map!(a => indexHead_[a]);
        }

        /// ditto
        auto incidentEdgesOut(in size_t v) const
        {
            enforce(isVertex(v));
            return iota(sumTail_[v], sumTail_[v + 1]).map!(a => indexTail_[a]);
        }
    }
    else
    {
        /// ditto
        auto incidentEdges(in size_t v) const
        {
            enforce(isVertex(v));
            return chain(iota(sumHead_[v], sumHead_[v + 1]).map!(a => indexHead_[a]),
                         iota(sumTail_[v], sumTail_[v + 1]).map!(a => indexTail_[a]));
        }

        alias incidentEdgesIn  = incidentEdges;
        alias incidentEdgesOut = incidentEdges;
    }

    /**
     * Checks if a given (tail, head) vertex pair forms an edge in the graph.
     */
    bool isEdge(size_t tail, size_t head) const
    {
        if (!(isVertex(tail) && isVertex(head)))
        {
            return false;
        }

        static if (!directed)
        {
            if (head < tail)
            {
                swap(tail, head);
            }
        }

        size_t tailDeg = sumTail_[tail + 1] - sumTail_[tail];
        if (tailDeg == 0)
        {
            return false;
        }

        size_t headDeg = sumHead_[head + 1] - sumHead_[head];
        if (headDeg == 0)
        {
            return false;
        }

        if (tailDeg < headDeg)
        {
            // search among the heads of tail
            foreach (immutable t; iota(sumTail_[tail], sumTail_[tail + 1]).map!(a => head_[indexTail_[a]]))
            {
                if (t == head)
                {
                    return true;
                }
            }
            return false;
        }
        else
        {
            // search among the tails of head
            foreach (immutable h; iota(sumHead_[head], sumHead_[head + 1]).map!(a => tail_[indexHead_[a]]))
            {
                if (h == tail)
                {
                    return true;
                }
            }
            return false;
        }
    }

    bool isVertex(T : size_t)(in T v) @safe const nothrow pure
    {
        static if (isSigned!T)
        {
            if (v < 0)
            {
                return false;
            }
        }

        if (v < vertexCount)
        {
            return true;
        }

        return false;
    }

    static if (directed)
    {
        /**
         * Returns the IDs of vertices connected to v via incoming or outgoing
         * links.  If the graph is undirected the two will be identical and the
         * general neighbours method is also defined.
         */
        auto neighboursIn(in size_t v) const
        {
            enforce(isVertex(v));
            return iota(sumHead_[v], sumHead_[v + 1]).map!(a => tail_[indexHead_[a]]);
        }

        /// ditto
        auto neighboursOut(in size_t v) const
        {
            enforce(isVertex(v));
            return iota(sumTail_[v], sumTail_[v + 1]).map!(a => head_[indexTail_[a]]);
        }
    }
    else
    {
        /// ditto
        auto neighbours(in size_t v) const
        {
            enforce(isVertex(v));
            return chain(iota(sumHead_[v], sumHead_[v + 1]).map!(a => tail_[indexHead_[a]]),
                         iota(sumTail_[v], sumTail_[v + 1]).map!(a => head_[indexTail_[a]]));
        }

        alias neighbors = neighbours;
        alias neighboursIn  = neighbours;
        alias neighboursOut = neighbours;
    }

    alias neighborsIn = neighboursIn;
    alias neighborsOut = neighboursOut;

    /**
     * Get or set the total number of vertices in the graph.  Will throw an
     * exception if resetting the number of vertices would delete edges.
     */
    size_t vertexCount() @property @safe const nothrow pure
    {
        assert(sumTail_.length == sumHead_.length);
        return sumTail_.length - 1;
    }

    /// ditto
    size_t vertexCount(in size_t n) @property @safe pure
    {
        immutable size_t l = sumTail_.length;
        if (n < (l - 1))
        {
            // Check that no edges are lost this way
            if ((sumTail_[n] != sumTail_[$-1]) ||
                (sumHead_[n] != sumHead_[$-1]))
            {
                throw new Exception("Cannot set vertexCount value without deleting edges");
            }
            else
            {
                sumTail_.length = n + 1;
                sumHead_.length = n + 1;
            }
        }
        else
        {
            sumTail_.length = n + 1;
            sumHead_.length = n + 1;
            sumTail_[l .. $] = sumTail_[l - 1];
            sumHead_[l .. $] = sumHead_[l - 1];
        }
        return vertexCount;
    }
}

/**
 * An extension of IndexedEdgeList that caches the results of calculations of
 * various graph properties so as to provide speedier performance.  Provides
 * the same set of public methods.  This is the recommended data type to use
 * with Dgraph.
 */
final class CachedEdgeList(bool dir)
{
  private:
    IndexedEdgeList!dir _graph;
    size_t[] _incidentEdgesCache;
    size_t[] _neighboursCache;

    static if (directed)
    {
        const(size_t)[][] _incidentEdgesIn;
        const(size_t)[][] _incidentEdgesOut;
        const(size_t)[][] _neighboursIn;
        const(size_t)[][] _neighboursOut;
    }
    else
    {
        const(size_t)[][] _incidentEdges;
        const(size_t)[][] _neighbours;
    }

  public:
    this()
    {
        _graph = new IndexedEdgeList!dir;
    }

    alias _graph this;

    void addEdge()(size_t tail, size_t head)
    {
        _graph.addEdge(tail, head);
        _neighboursCache.length = 2 * tail_.length;
        _incidentEdgesCache.length = 2 * tail_.length;
        static if (directed)
        {
            _neighboursIn[] = null;
            _neighboursOut[] = null;
            _incidentEdgesIn[] = null;
            _incidentEdgesOut[] = null;
        }
        else
        {
            _neighbours[] = null;
            _incidentEdges[] = null;
        }
    }

    void addEdge(T : size_t)(T[] edgeList)
    {
        _graph.addEdge(edgeList);
        _neighboursCache.length = 2 * tail_.length;
        _incidentEdgesCache.length = 2 * tail_.length;
        static if (directed)
        {
            _neighboursIn[] = null;
            _neighboursOut[] = null;
            _incidentEdgesIn[] = null;
            _incidentEdgesOut[] = null;
        }
        else
        {
            _neighbours[] = null;
            _incidentEdges[] = null;
        }
    }

    static if (directed)
    {
        size_t degreeIn(in size_t v) @safe const pure
        {
            return _graph.degreeIn(v);
        }

        size_t degreeOut(in size_t v) @safe const pure
        {
            return _graph.degreeOut(v);
        }
    }
    else
    {
        size_t degree(in size_t v) @safe const pure
        {
            return _graph.degree(v);
        }

        alias degreeIn = degree;
        alias degreeOut = degree;
    }

    alias directed = dir;

    auto edge() @property @safe const nothrow pure
    {
        return _graph.edge;
    }

    size_t edgeCount() @property @safe const nothrow pure
    {
        return _graph.edgeCount;
    }

    size_t edgeID(size_t tail, size_t head) const
    {
        return _graph.edgeID(tail, head);
    }

    static if (directed)
    {
        auto incidentEdgesIn(in size_t v) @safe nothrow pure
        {
            if (_incidentEdgesIn[v] is null)
            {
                immutable size_t start = sumHead_[v] + sumTail_[v];
                immutable size_t end = sumTail_[v] + sumHead_[v + 1];
                size_t j = start;
                foreach (immutable i; sumHead_[v] .. sumHead_[v + 1])
                {
                    _incidentEdgesCache[j] = indexHead_[i];
                    ++j;
                }
                assert(j == end);
                _incidentEdgesIn[v] = _incidentEdgesCache[start .. end];
            }
            return _incidentEdgesIn[v];
        }

        auto incidentEdgesOut(in size_t v) @safe nothrow pure
        {
            if (_incidentEdgesOut[v] is null)
            {
                immutable size_t start = sumTail_[v] + sumHead_[v + 1];
                immutable size_t end = sumHead_[v + 1] + sumTail_[v + 1];
                size_t j = start;
                foreach (immutable i; sumTail_[v] .. sumTail_[v + 1])
                {
                    _incidentEdgesCache[j] = indexTail_[i];
                    ++j;
                }
                assert(j == end);
                _incidentEdgesOut[v] = _incidentEdgesCache[start .. end];
            }
            return _incidentEdgesOut[v];
        }
    }
    else
    {
        auto incidentEdges(in size_t v) @safe nothrow pure
        {
            if (_incidentEdges[v] is null)
            {
                immutable size_t start = sumHead_[v] + sumTail_[v];
                immutable size_t end = sumHead_[v + 1] + sumTail_[v + 1];
                size_t j = start;
                foreach (immutable i; sumHead_[v] .. sumHead_[v + 1])
                {
                    _incidentEdgesCache[j] = indexHead_[i];
                    ++j;
                }
                foreach (immutable i; sumTail_[v] .. sumTail_[v + 1])
                {
                    _incidentEdgesCache[j] = indexTail_[i];
                    ++j;
                }
                assert(j == end);
                _incidentEdges[v] = _incidentEdgesCache[start .. end];
            }
            return _incidentEdges[v];
        }

        alias incidentEdgesIn  = incidentEdges;
        alias incidentEdgesOut = incidentEdges;
    }

    bool isEdge(size_t tail, size_t head) const
    {
        return _graph.isEdge(tail, head);
    }

    static if (directed)
    {
        auto neighboursIn(in size_t v) @safe nothrow pure
        {
            if (_neighboursIn[v] is null)
            {
                immutable size_t start = sumHead_[v] + sumTail_[v];
                immutable size_t end = sumTail_[v] + sumHead_[v + 1];
                size_t j = start;
                foreach (immutable i; sumHead_[v] .. sumHead_[v + 1])
                {
                    _neighboursCache[j] = tail_[indexHead_[i]];
                    ++j;
                }
                assert(j == end);
                _neighboursIn[v] = _neighboursCache[start .. end];
            }
            return _neighboursIn[v];
        }

        auto neighboursOut(in size_t v) @safe nothrow pure
        {
            if (_neighboursOut[v] is null)
            {
                immutable size_t start = sumTail_[v] + sumHead_[v + 1];
                immutable size_t end = sumHead_[v + 1] + sumTail_[v + 1];
                size_t j = start;
                foreach (immutable i; sumTail_[v] .. sumTail_[v + 1])
                {
                    _neighboursCache[j] = head_[indexTail_[i]];
                    ++j;
                }
                assert(j == end);
                _neighboursOut[v] = _neighboursCache[start .. end];
            }
            return _neighboursOut[v];
        }
    }
    else
    {
        auto neighbours(in size_t v) @safe nothrow pure
        {
            if (_neighbours[v] is null)
            {
                immutable size_t start = sumHead_[v] + sumTail_[v];
                immutable size_t end = sumHead_[v + 1] + sumTail_[v + 1];
                size_t j = start;
                foreach (immutable i; sumHead_[v] .. sumHead_[v + 1])
                {
                    _neighboursCache[j] = tail_[indexHead_[i]];
                    ++j;
                }
                foreach (immutable i; sumTail_[v] .. sumTail_[v + 1])
                {
                    _neighboursCache[j] = head_[indexTail_[i]];
                    ++j;
                }
                assert(j == end);
                _neighbours[v] = _neighboursCache[start .. end];
            }
            return _neighbours[v];
        }

        alias neighbors = neighbours;
        alias neighboursIn  = neighbours;
        alias neighboursOut = neighbours;
    }

    alias neighborsIn = neighboursIn;
    alias neighborsOut = neighboursOut;

    size_t vertexCount() @property @safe const nothrow pure
    {
        return _graph.vertexCount;
    }

    size_t vertexCount(in size_t n) @property @safe pure
    {
        static if (directed)
        {
            assert(sumHead_.length == _neighboursIn.length + 1);
            assert(sumTail_.length == _neighboursOut.length + 1);
            assert(sumHead_.length == _incidentEdgesIn.length + 1);
            assert(sumTail_.length == _incidentEdgesOut.length + 1);
        }
        else
        {
            assert(sumTail_.length == _neighbours.length + 1);
            assert(sumHead_.length == _incidentEdges.length + 1);
        }

        immutable size_t l = sumTail_.length;
        _graph.vertexCount = n;

        static if (directed)
        {
            _neighboursIn.length = n;
            _neighboursOut.length = n;
            _incidentEdgesIn.length = n;
            _incidentEdgesOut.length = n;

            if (n >= l)
            {
                _neighboursIn[l - 1 .. $] = null;
                _neighboursOut[l - 1 .. $] = null;
                _incidentEdgesIn[l - 1 .. $] = null;
                _incidentEdgesOut[l - 1 .. $] = null;
            }
        }
        else
        {
            _neighbours.length = n;
            _incidentEdges.length = n;

            if (n >= l)
            {
                _neighbours[l - 1 .. $] = null;
                _incidentEdges[l - 1 .. $] = null;
            }
        }
        return vertexCount;
    }
}

unittest
{
    import std.typetuple;

    foreach (Graph; TypeTuple!(IndexedEdgeList, CachedEdgeList))
    {
        foreach (directed; TypeTuple!(true, false))
        {
            /* We begin by creating two graphs with the different
             * addEdge methods and ensuring that they wind up with
             * the same internal data.
             */
            auto g1 = new Graph!directed;
            auto g2 = new Graph!directed;
            g1.vertexCount = g2.vertexCount = 10;
            assert(g1.vertexCount == 10);
            assert(g2.vertexCount == 10);

            g1.addEdge(5, 8);
            g1.addEdge(5, 4);
            g1.addEdge(7, 4);
            g1.addEdge(3, 4);
            g1.addEdge(6, 9);
            g1.addEdge(3, 2);

            g2.addEdge([5, 8, 5, 4, 7, 4, 3, 4, 6, 9, 3, 2]);

            assert(g1.edgeCount == 6);
            assert(g2.edgeCount == 6);

            if (directed)
            {
                assert(g1.tail_ == [5, 5, 7, 3, 6, 3]);
                assert(g2.tail_ == [5, 5, 7, 3, 6, 3]);
                assert(g1.head_ == [8, 4, 4, 4, 9, 2]);
                assert(g2.head_ == [8, 4, 4, 4, 9, 2]);

                assert(g1.indexTail_ == [5, 3, 1, 0, 4, 2]);
                assert(g2.indexTail_ == [5, 3, 1, 0, 4, 2]);
                assert(g1.indexHead_ == [5, 3, 1, 2, 0, 4]);
                assert(g2.indexHead_ == [5, 3, 1, 2, 0, 4]);

                assert(g1.sumTail_ == [0, 0, 0, 0, 2, 2, 4, 5, 6, 6, 6]);
                assert(g2.sumTail_ == [0, 0, 0, 0, 2, 2, 4, 5, 6, 6, 6]);
                assert(g1.sumHead_ == [0, 0, 0, 1, 1, 4, 4, 4, 4, 5, 6]);
                assert(g2.sumHead_ == [0, 0, 0, 1, 1, 4, 4, 4, 4, 5, 6]);
            }
            else
            {
                assert(g1.tail_ == [5, 4, 4, 3, 6, 2]);
                assert(g2.tail_ == [5, 4, 4, 3, 6, 2]);
                assert(g1.head_ == [8, 5, 7, 4, 9, 3]);
                assert(g2.head_ == [8, 5, 7, 4, 9, 3]);

                assert(g1.indexTail_ == [5, 3, 1, 2, 0, 4]);
                assert(g2.indexTail_ == [5, 3, 1, 2, 0, 4]);
                assert(g1.indexHead_ == [5, 3, 1, 2, 0, 4]);
                assert(g2.indexHead_ == [5, 3, 1, 2, 0, 4]);

                assert(g1.sumTail_ == [0, 0, 0, 1, 2, 4, 5, 6, 6, 6, 6]);
                assert(g2.sumTail_ == [0, 0, 0, 1, 2, 4, 5, 6, 6, 6, 6]);
                assert(g1.sumHead_ == [0, 0, 0, 0, 1, 2, 3, 3, 4, 5, 6]);
                assert(g2.sumHead_ == [0, 0, 0, 0, 1, 2, 3, 3, 4, 5, 6]);
            }

            foreach (immutable v; 0 .. g1.vertexCount)
            {
                assert(g1.degreeIn(v) == g2.degreeIn(v));
                assert(g1.degreeOut(v) == g2.degreeOut(v));
                static if (!directed)
                {
                    assert(g1.degree(v) == g2.degree(v));
                }
            }

            /* If the above all passes, then we know that the internal data
             * representation is correct and we can focus on how the graph
             * transforms this into output.
             *
             * Let's start by checking that vertex IDs are recognized ...
             */
            foreach (immutable i; -10 .. 20)
            {
                if (0 <= i && i < g1.vertexCount)
                {
                    assert(g1.isVertex(i));
                }
                else
                {
                    assert(!g1.isVertex(i));
                }
            }

            /* Now check that edges are correctly recognized and that the
             * edge ID representation works.
             */
            foreach (immutable h; -10 .. 20)
            {
                foreach (immutable t; -10 .. 20)
                {
                    if (directed)
                    {
                        if ((h == 5 && t == 8) ||
                            (h == 5 && t == 4) ||
                            (h == 7 && t == 4) ||
                            (h == 3 && t == 4) ||
                            (h == 6 && t == 9) ||
                            (h == 3 && t == 2))
                        {
                            assert(g1.isEdge(h, t));
                            auto i = g1.edgeID(h, t);
                            assert(h == g1.tail_[i]);
                            assert(t == g1.head_[i]);
                        }
                        else
                        {
                            assert(!g1.isEdge(h, t));
                            assertThrown(g1.edgeID(h, t));
                        }
                    }
                    else
                    {
                        if ((h == 5 && t == 8) || (h == 8 && t == 5) ||
                            (h == 5 && t == 4) || (h == 4 && t == 5) ||
                            (h == 7 && t == 4) || (h == 4 && t == 7) ||
                            (h == 3 && t == 4) || (h == 4 && t == 3) ||
                            (h == 6 && t == 9) || (h == 9 && t == 6) ||
                            (h == 3 && t == 2) || (h == 2 && t == 3))
                        {
                            assert(g1.isEdge(h, t));
                            auto i = g1.edgeID(h, t);
                            if (h <= t)
                            {
                                assert(h == g1.tail_[i]);
                                assert(t == g1.head_[i]);
                            }
                            else
                            {
                                assert(h == g1.head_[i]);
                                assert(t == g1.tail_[i]);
                            }
                        }
                        else
                        {
                            assert(!g1.isEdge(h, t));
                            assertThrown(g1.edgeID(h, t));
                        }
                    }
                }
            }

            // Another check on edge ID.
            foreach (immutable e; 0 .. g1.edgeCount)
            {
                size_t h = g1.tail_[e];
                size_t t = g1.head_[e];
                assert(e == g1.edgeID(h, t));
                if (!directed)
                {
                    assert(e == g1.edgeID(t, h));
                }
            }

            // Let's check the edge and neighbour functions.
            foreach (immutable v; 0 .. g1.vertexCount)
            {
                foreach (immutable e, immutable n; zip(g1.incidentEdgesOut(v), g1.neighboursOut(v)))
                {
                    if (directed || v <= n)
                    {
                        assert(g1.edge[e][0] == v);
                        assert(g1.edge[e][1] == n);
                    }
                    else
                    {
                        assert(g1.edge[e][0] == n);
                        assert(g1.edge[e][1] == v);
                    }
                }

                foreach (immutable e, immutable n; zip(g1.incidentEdgesIn(v), g1.neighboursIn(v)))
                {
                    if (directed || v > n)
                    {
                        assert(g1.edge[e][0] == n);
                        assert(g1.edge[e][1] == v);
                    }
                    else
                    {
                        assert(g1.edge[e][0] == v);
                        assert(g1.edge[e][1] == n);
                    }
                }

                static if (!directed)
                {
                    foreach (immutable e, immutable n; zip(g1.incidentEdges(v), g1.neighbours(v)))
                    {
                        if (v <= n)
                        {
                            assert(g1.edge[e][0] == v);
                            assert(g1.edge[e][1] == n);
                        }
                        else
                        {
                            assert(g1.edge[e][0] == n);
                            assert(g1.edge[e][1] == v);
                        }
                    }
                }
            }

            // Check that altering the number of vertices works OK.
            g1.vertexCount = 20;
            assert(g1.vertexCount == 20);
            assertThrown(g1.vertexCount(5));
            g1.vertexCount = 10;

            // Check that now we've re-resized it it's back to where it was.
            assert(g1.tail_ == g2.tail_);
            assert(g1.head_ == g2.head_);
            assert(g1.indexTail_ == g2.indexTail_);
            assert(g1.indexHead_ == g2.indexHead_);
            assert(g1.sumTail_ == g2.sumTail_);
            assert(g1.sumHead_ == g2.sumHead_);
        }
    }
}
