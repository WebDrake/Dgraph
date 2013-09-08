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

import std.algorithm, std.array, std.conv, std.range, std.traits;

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
    else
    {
        enum bool isGraph = true;
    }
}

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

final class IndexedEdgeList(bool dir)
{
  private:
    size_t[] _head;
    size_t[] _tail;
    size_t[] _indexHead;
    size_t[] _indexTail;
    size_t[] _sumHead = [0];
    size_t[] _sumTail = [0];

    void indexEdgesInsertion()
    {
        assert(_indexHead.length == _indexTail.length);
        assert(_head.length == _tail.length);
        immutable size_t l = _indexHead.length;
        _indexHead.length = _head.length;
        _indexTail.length = _tail.length;
        foreach (immutable e; l .. _head.length)
        {
            size_t i, j, lower, upper;
            upper = _indexHead[0 .. e].map!(a => _head[a]).assumeSorted.lowerBound(_head[e] + 1).length;
            lower = _indexHead[0 .. upper].map!(a => _head[a]).assumeSorted.lowerBound(_head[e]).length;
            i = lower + _indexHead[lower .. upper].map!(a => _tail[a]).assumeSorted.lowerBound(_tail[e]).length;
            for(j = e; j > i; --j)
                _indexHead[j] = _indexHead[j - 1];
            _indexHead[i] = e;

            upper = _indexTail[0 .. e].map!(a => _tail[a]).assumeSorted.lowerBound(_tail[e] + 1).length;
            lower = _indexTail[0 .. upper].map!(a => _tail[a]).assumeSorted.lowerBound(_tail[e]).length;
            i = lower + _indexTail[lower .. upper].map!(a => _head[a]).assumeSorted.lowerBound(_head[e]).length;
            for(j = e; j > i; --j)
                _indexTail[j] = _indexTail[j - 1];
            _indexTail[i] = e;
        }
        assert(_indexHead.length == _indexTail.length);
        assert(_indexHead.length == _head.length, text(_indexHead.length, " head indices but ", _head.length, " head values."));
        assert(_indexTail.length == _tail.length, text(_indexTail.length, " tail indices but ", _tail.length, " tail values."));
    }

    void indexEdgesSort()
    {
        _indexHead ~= iota(_indexHead.length, _head.length).array;
        _indexTail ~= iota(_indexTail.length, _tail.length).array;
        assert(_indexHead.length == _indexTail.length);
        _indexHead.multiSort!((a, b) => _head[a] < _head[b], (a, b) => _tail[a] < _tail[b]);
        _indexTail.multiSort!((a, b) => _tail[a] < _tail[b], (a, b) => _head[a] < _head[b]);
    }

    void sumEdges(ref size_t[] sum, ref size_t[] vertex, ref size_t[] index)
    {
        assert(sum.length > 1);

        size_t v = vertex[index[0]];
        sum[0 .. v + 1] = 0;
        for(size_t i = 1; i < index.length; ++i)
        {
            size_t n = vertex[index[i]] - vertex[index[sum[v]]];
            sum[v + 1 .. v + n + 1] = i;
            v += n;
        }
        sum[v + 1 .. $] = vertex.length;
    }

  public:
    enum bool directed = dir;

    auto edge() @property const pure nothrow
    {
        return zip(_head, _tail);
    }

    size_t edgeCount() @property const pure nothrow
    {
        assert(_head.length == _tail.length);
        return _head.length;
    }

    size_t vertexCount() @property const pure nothrow
    {
        assert(_sumHead.length == _sumTail.length);
        return _sumHead.length - 1;
    }

    bool isEdge(size_t head, size_t tail) const
    {
        assert(head < vertexCount);
        assert(tail < vertexCount);
        static if (!directed)
        {
            if (tail < head)
            {
                swap(head, tail);
            }
        }

        size_t headDeg = _sumHead[head + 1] - _sumHead[head];
        if (headDeg == 0)
        {
            return false;
        }

        size_t tailDeg = _sumTail[tail + 1] - _sumTail[tail];
        if (tailDeg == 0)
        {
            return false;
        }
        else if (headDeg < tailDeg)
        {
            // search among the tails of head
            foreach (immutable t; iota(_sumHead[head], _sumHead[head + 1]).map!(a => _tail[_indexHead[a]]))
            {
                if (t == tail)
                {
                    return true;
                }
            }
            return false;
        }
        else
        {
            // search among the heads of tail
            foreach (immutable h; iota(_sumTail[tail], _sumTail[tail + 1]).map!(a => _head[_indexTail[a]]))
            {
                if (h == head)
                {
                    return true;
                }
            }
            return false;
        }
    }

    size_t edgeID(size_t head, size_t tail) const
    {
        assert(head < vertexCount);
        assert(tail < vertexCount);
        assert(isEdge(head, tail));
        static if (!directed)
        {
            if (tail < head)
            {
                swap(head, tail);
            }
        }

        size_t headDeg = _sumHead[head + 1] - _sumHead[head];
        size_t tailDeg = _sumTail[tail + 1] - _sumTail[tail];
        assert(headDeg > 0);
        assert(tailDeg > 0);

        if (headDeg < tailDeg)
        {
            // search among the tails of head
            foreach (immutable i; iota(_sumHead[head], _sumHead[head + 1]).map!(a => _indexHead[a]))
            {
                if (_tail[i] == tail)
                {
                    assert(_head[i] == head);
                    return i;
                }
            }
            assert(false);
        }
        else
        {
            // search among the heads of tail
            foreach (immutable i; iota(_sumTail[tail], _sumTail[tail + 1]).map!(a => _indexTail[a]))
            {
                if (_head[i] == head)
                {
                    assert(_tail[i] == tail);
                    return i;
                }
            }
            assert(false);
        }
    }

    static if (directed)
    {
        size_t degreeIn(immutable size_t v) const pure nothrow
        {
            assert(v + 1 < _sumTail.length);
            return _sumTail[v + 1] - _sumTail[v];
        }

        size_t degreeOut(immutable size_t v) const pure nothrow
        {
            assert(v + 1 < _sumHead.length);
            return _sumHead[v + 1] - _sumHead[v];
        }
    }
    else
    {
        size_t degree(immutable size_t v) const pure nothrow
        {
            assert(v + 1 < _sumHead.length);
            assert(_sumHead.length == _sumTail.length);
            return (_sumHead[v + 1] - _sumHead[v])
                 + (_sumTail[v + 1] - _sumTail[v]);
        }

        alias degreeIn = degree;
        alias degreeOut = degree;
    }

    static if (directed)
    {
        auto incidentEdgesIn(immutable size_t v)
        {
            return iota(_sumTail[v], _sumTail[v + 1]).map!(a => _indexTail[a]);
        }

        auto incidentEdgesOut(immutable size_t v)
        {
            return iota(_sumHead[v], _sumHead[v + 1]).map!(a => _indexHead[a]);
        }
    }
    else
    {
        auto incidentEdges(immutable size_t v)
        {
            return chain(iota(_sumTail[v], _sumTail[v + 1]).map!(a => _indexTail[a]),
                         iota(_sumHead[v], _sumHead[v + 1]).map!(a => _indexHead[a]));
        }

        alias incidentEdgesIn  = incidentEdges;
        alias incidentEdgesOut = incidentEdges;
    }

    static if (directed)
    {
        auto neighboursIn(immutable size_t v) const
        {
            return iota(_sumTail[v], _sumTail[v + 1]).map!(a => _head[_indexTail[a]]);
        }

        auto neighboursOut(immutable size_t v) const
        {
            return iota(_sumHead[v], _sumHead[v + 1]).map!(a => _tail[_indexHead[a]]);
        }
    }
    else
    {
        auto neighbours(immutable size_t v) const
        {
            return chain(iota(_sumTail[v], _sumTail[v + 1]).map!(a => _head[_indexTail[a]]),
                         iota(_sumHead[v], _sumHead[v + 1]).map!(a => _tail[_indexHead[a]]));
        }

        alias neighbors = neighbours;
        alias neighboursIn  = neighbours;
        alias neighboursOut = neighbours;
    }

    alias neighborsIn = neighboursIn;
    alias neighborsOut = neighboursOut;

    void addVertices(immutable size_t n)
    {
        immutable size_t l = _sumHead.length;
        _sumHead.length += n;
        _sumTail.length += n;
        assert(_sumHead.length == _sumTail.length);
        _sumHead[l .. $] = _sumHead[l - 1];
        _sumTail[l .. $] = _sumTail[l - 1];
    }

    void addEdge()(size_t head, size_t tail)
    {
        assert(head < this.vertexCount, text("Edge head ", head, " is greater than vertex count ", this.vertexCount));
        assert(tail < this.vertexCount, text("Edge tail ", tail, " is greater than vertex count ", this.vertexCount));
        static if (!directed)
        {
            if (tail < head)
            {
                swap(head, tail);
            }
        }
        _head ~= head;
        _tail ~= tail;
        indexEdgesInsertion();
        ++_sumHead[head + 1 .. $];
        ++_sumTail[tail + 1 .. $];
    }

    void addEdge(T : size_t)(T[] edgeList)
    {
        assert(edgeList.length % 2 == 0);
        assert(_head.length == _tail.length);
        immutable size_t l = _head.length;
        _head.length += edgeList.length / 2;
        _tail.length += edgeList.length / 2;
        foreach (immutable i; 0 .. edgeList.length / 2)
        {
            size_t head = edgeList[2 * i];
            size_t tail = edgeList[2 * i + 1];
            assert(head < this.vertexCount, text("Edge head ", head, " is greater than vertex count ", this.vertexCount));
            assert(tail < this.vertexCount, text("Edge tail ", tail, " is greater than vertex count ", this.vertexCount));
            static if (!directed)
            {
                if (tail < head)
                {
                    swap(head, tail);
                }
            }
            _head[l + i] = head;
            _tail[l + i] = tail;
        }
        indexEdgesSort();
        sumEdges(_sumHead, _head, _indexHead);
        sumEdges(_sumTail, _tail, _indexTail);
    }
}

final class CachedEdgeList(bool dir)
{
  /* WARNING!! This should be private but has to be public for now due to
   * D Issue #10996: http://d.puremagic.com/issues/show_bug.cgi?id=10996
   *
   * Do not make use of CachedEdgeList._graph directly.
   */
  public:
    IndexedEdgeList!dir _graph;

  private:
    size_t[] _neighboursCache;
    size_t[] _incidentEdgesCache;

    static if (directed)
    {
        size_t[][] _neighboursIn;
        size_t[][] _neighboursOut;
        size_t[][] _incidentEdgesIn;
        size_t[][] _incidentEdgesOut;
    }
    else
    {
        size_t[][] _neighbours;
        size_t[][] _incidentEdges;
    }

  public:
    this()
    {
        _graph = new IndexedEdgeList!dir;
    }

    alias dir directed;

    alias _graph this;

    static if (directed)
    {
        auto incidentEdgesIn(immutable size_t v)
        {
            if (_incidentEdgesIn[v] is null)
            {
                immutable size_t start = _sumTail[v] + _sumHead[v];
                immutable size_t end = _sumHead[v] + _sumTail[v + 1];
                size_t j = start;
                foreach (immutable i; _sumTail[v] .. _sumTail[v + 1])
                {
                    _incidentEdgesCache[j] = _indexTail[i];
                    ++j;
                }
                assert(j == end);
                _incidentEdgesIn[v] = _incidentEdgesCache[start .. end];
            }
            return _incidentEdgesIn[v];
        }

        auto incidentEdgesOut(immutable size_t v)
        {
            if (_incidentEdgesOut[v] is null)
            {
                immutable size_t start = _sumHead[v] + _sumTail[v + 1];
                immutable size_t end = _sumTail[v + 1] + _sumHead[v + 1];
                size_t j = start;
                foreach (immutable i; _sumHead[v] .. _sumHead[v + 1])
                {
                    _incidentEdgesCache[j] = _indexHead[i];
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
        auto incidentEdges(immutable size_t v)
        {
            if (_incidentEdges[v] is null)
            {
                immutable size_t start = _sumTail[v] + _sumHead[v];
                immutable size_t end = _sumTail[v + 1] + _sumHead[v + 1];
                size_t j = start;
                foreach (immutable i; _sumTail[v] .. _sumTail[v + 1])
                {
                    _incidentEdgesCache[j] = _indexTail[i];
                    ++j;
                }
                foreach (immutable i; _sumHead[v] .. _sumHead[v + 1])
                {
                    _incidentEdgesCache[j] = _indexHead[i];
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

    static if (directed)
    {
        auto neighboursIn(immutable size_t v)
        {
            if (_neighboursIn[v] is null)
            {
                immutable size_t start = _sumTail[v] + _sumHead[v];
                immutable size_t end = _sumHead[v] + _sumTail[v + 1];
                size_t j = start;
                foreach (immutable i; _sumTail[v] .. _sumTail[v + 1])
                {
                    _neighboursCache[j] = _head[_indexTail[i]];
                    ++j;
                }
                assert(j == end);
                _neighboursIn[v] = _neighboursCache[start .. end];
            }
            return _neighboursIn[v];
        }

        auto neighboursOut(immutable size_t v)
        {
            if (_neighboursOut[v] is null)
            {
                immutable size_t start = _sumHead[v] + _sumTail[v + 1];
                immutable size_t end = _sumTail[v + 1] + _sumHead[v + 1];
                size_t j = start;
                foreach (immutable i; _sumHead[v] .. _sumHead[v + 1])
                {
                    _neighboursCache[j] = _tail[_indexHead[i]];
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
        auto neighbours(immutable size_t v)
        {
            if(_neighbours[v] is null)
            {
                immutable size_t start = _sumTail[v] + _sumHead[v];
                immutable size_t end = _sumTail[v + 1] + _sumHead[v + 1];
                size_t j = start;
                foreach (immutable i; _sumTail[v] .. _sumTail[v + 1])
                {
                    _neighboursCache[j] = _head[_indexTail[i]];
                    ++j;
                }
                foreach (immutable i; _sumHead[v] .. _sumHead[v + 1])
                {
                    _neighboursCache[j] = _tail[_indexHead[i]];
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

    void addVertices(immutable size_t n)
    {
        static if (directed)
        {
            assert(_sumTail.length == _neighboursIn.length + 1);
            assert(_sumHead.length == _neighboursOut.length + 1);
            assert(_sumTail.length == _incidentEdgesIn.length + 1);
            assert(_sumHead.length == _incidentEdgesOut.length + 1);
        }
        else
        {
            assert(_sumHead.length == _neighbours.length + 1);
            assert(_sumTail.length == _incidentEdges.length + 1);
        }

        immutable size_t l = _sumHead.length;
        _graph.addVertices(n);

        static if (directed)
        {
            _neighboursIn.length += n;
            _neighboursOut.length += n;
            _incidentEdgesIn.length += n;
            _incidentEdgesOut.length += n;
            _neighboursIn[l - 1 .. $] = null;
            _neighboursOut[l - 1 .. $] = null;
            _incidentEdgesIn[l - 1 .. $] = null;
            _incidentEdgesOut[l - 1 .. $] = null;
        }
        else
        {
            _neighbours.length += n;
            _incidentEdges.length += n;
            _neighbours[l - 1 .. $] = null;
            _incidentEdges[l - 1 .. $] = null;
        }
    }

    void addEdge()(size_t head, size_t tail)
    {
        _graph.addEdge(head, tail);
        _neighboursCache.length = 2 * _head.length;
        _incidentEdgesCache.length = 2 * _head.length;
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
        _neighboursCache.length = 2 * _head.length;
        _incidentEdgesCache.length = 2 * _head.length;
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
}

unittest
{
    import std.stdio, std.typetuple;
    foreach (Graph; TypeTuple!(IndexedEdgeList, CachedEdgeList))
    {
        writeln;
        auto g1 = new Graph!false;
        g1.addVertices(10);
        assert(g1.vertexCount == 10);
        g1.addEdge(5, 8);
        g1.addEdge(5, 4);
        g1.addEdge(7, 4);
        g1.addEdge(3, 4);
        g1.addEdge(6, 9);
        g1.addEdge(3, 2);
        foreach (immutable head, immutable tail; g1.edge)
        {
            writeln("\t", head, "\t", tail);
        }
        writeln(g1._indexHead);
        writeln(g1._indexTail);
        writeln(g1._sumHead);
        writeln(g1._sumTail);
        foreach (immutable v; 0 .. g1.vertexCount)
        {
            writeln("\td(", v, ") =\t", g1.degree(v), "\tn(", v, ") = ", g1.neighbours(v), "\ti(", v, ") = ", g1.incidentEdges(v));
            foreach (immutable e, immutable n; zip(g1.incidentEdges(v), g1.neighbours(v)))
            {
                if (g1.edge[e][0] == v)
                {
                    assert(g1.edge[e][1] == n);
                }
                else
                {
                    assert(g1.edge[e][1] == v);
                    assert(g1.edge[e][0] == n);
                }
            }
        }
        static if (is(typeof(g1) == CachedEdgeList!false))
        {
            writeln(g1._neighboursCache);
            writeln(g1._incidentEdgesCache);
        }
        writeln;
        assert(iota(g1._head.length).map!(a => g1._head[g1._indexHead[a]]).isSorted);
        assert(iota(g1._tail.length).map!(a => g1._tail[g1._indexTail[a]]).isSorted);
        foreach (immutable h; 0 .. 10)
        {
            foreach (immutable t; 0 .. 10)
            {
                if ((h == 5 && t == 8) || (h == 8 && t == 5) ||
                    (h == 5 && t == 4) || (h == 4 && t == 5) ||
                    (h == 7 && t == 4) || (h == 4 && t == 7) ||
                    (h == 3 && t == 4) || (h == 4 && t == 3) ||
                    (h == 6 && t == 9) || (h == 9 && t == 6) ||
                    (h == 3 && t == 2) || (h == 2 && t == 3))
                {
                    assert(g1.isEdge(h, t), text("isEdge failure for edge (", h, ", ", t, ")"));
                }
                else
                {
                    assert(!g1.isEdge(h, t), text("isEdge false positive for edge (", h, ", ", t, ")"));
                }
            }
        }
        foreach (immutable i; 0 .. g1.edgeCount)
        {
            size_t h = g1._head[i];
            size_t t = g1._tail[i];
            assert(i == g1.edgeID(h, t));
            assert(i == g1.edgeID(t, h));
        }

        auto g2 = new Graph!true;
        g2.addVertices(10);
        assert(g2.vertexCount == 10);
        g2.addEdge(5, 8);
        g2.addEdge(5, 4);
        g2.addEdge(7, 4);
        g2.addEdge(3, 4);
        g2.addEdge(6, 9);
        g2.addEdge(3, 2);
        foreach (immutable head, immutable tail; g2.edge)
            writeln("\t", head, "\t", tail);
        writeln(g2._indexHead);
        writeln(g2._indexTail);
        writeln(g2._sumHead);
        writeln(g2._sumTail);
        foreach (immutable v; 0 .. g2.vertexCount)
        {
            writeln("\td_out(", v, ") =\t", g2.degreeOut(v), "\tn_out(", v, ") = ", g2.neighboursOut(v), "\ti_out(", v, ") = ", g2.incidentEdgesOut(v),
                    "\td_in(", v, ") =\t", g2.degreeIn(v), "\tn_in(", v, ") = ", g2.neighboursIn(v), "\ti_in(", v, ") = ", g2.incidentEdgesIn(v));

            foreach (immutable e, immutable n; zip(g2.incidentEdgesIn(v), g2.neighboursIn(v)))
            {
                assert(g2.edge[e][0] == n);
                assert(g2.edge[e][1] == v);
            }

            foreach (immutable e, immutable n; zip(g2.incidentEdgesOut(v), g2.neighboursOut(v)))
            {
                assert(g2.edge[e][0] == v);
                assert(g2.edge[e][1] == n);
            }
        }
        static if (is(typeof(g2) == CachedEdgeList!true))
        {
            writeln(g2._neighboursCache);
            writeln(g2._incidentEdgesCache);
        }
        assert(iota(g2._head.length).map!(a => g2._head[g2._indexHead[a]]).isSorted);
        assert(iota(g2._tail.length).map!(a => g2._tail[g2._indexTail[a]]).isSorted);
        foreach (immutable h; 0 .. 10)
        {
            foreach (immutable t; 0 .. 10)
            {
                if ((h == 5 && t == 8) ||
                    (h == 5 && t == 4) ||
                    (h == 7 && t == 4) ||
                    (h == 3 && t == 4) ||
                    (h == 6 && t == 9) ||
                    (h == 3 && t == 2))
                {
                    assert(g2.isEdge(h, t), text("isEdge failure for edge (", h, ", ", t, ")"));
                }
                else
                {
                    assert(!g2.isEdge(h, t), text("isEdge false positive for edge (", h, ", ", t, ")"));
                }
            }
        }
        foreach (immutable i; 0 .. g2.edgeCount)
        {
            size_t h = g2._head[i];
            size_t t = g2._tail[i];
            assert(i == g2.edgeID(h, t));
        }
    }
}
