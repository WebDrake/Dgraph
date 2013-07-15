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

import std.algorithm, std.array, std.conv, std.range;

final class Graph(bool dir)
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
        foreach(e; l .. _head.length)
        {
            size_t i, j;
            i = _indexHead[0 .. e].map!(a => _head[a]).assumeSorted.lowerBound(_head[e]).length;
            for(j = e; j > i; --j)
                _indexHead[j] = _indexHead[j - 1];
            _indexHead[i] = e;
            i = _indexTail[0 .. e].map!(a => _tail[a]).assumeSorted.lowerBound(_tail[e]).length;
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
        _indexHead.schwartzSort!(a => _head[a], "a < b");
        _indexTail.schwartzSort!(a => _tail[a], "a < b");
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
            foreach (t; map!(a => _tail[_indexHead[a]])(iota(_sumHead[head], _sumHead[head + 1])))
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
            foreach (h; map!(a => _head[_indexTail[a]])(iota(_sumTail[tail], _sumTail[tail + 1])))
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
            foreach (i; map!(a => _indexHead[a])(iota(_sumHead[head], _sumHead[head + 1])))
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
            foreach (i; map!(a => _indexTail[a])(iota(_sumTail[tail], _sumTail[tail + 1])))
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
        auto neighboursIn(immutable size_t v) const
        {
            return map!(a => _head[_indexTail[a]])(iota(_sumTail[v], _sumTail[v + 1]));
        }

        auto neighboursOut(immutable size_t v) const
        {
            return map!(a => _tail[_indexHead[a]])(iota(_sumHead[v], _sumHead[v + 1]));
        }
    }
    else
    {
        auto neighbours(immutable size_t v) const
        {
            return chain(map!(a => _tail[_indexHead[a]])(iota(_sumHead[v], _sumHead[v + 1])),
                         map!(a => _head[_indexTail[a]])(iota(_sumTail[v], _sumTail[v + 1])));
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
        foreach(i; 0 .. edgeList.length / 2)
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

unittest
{
    import std.stdio;
    auto g1 = new Graph!false;
    g1.addVertices(10);
    assert(g1.vertexCount == 10);
/*    g1.addEdge(5, 8);
    g1.addEdge(7, 4);
    g1.addEdge(6, 9);
    g1.addEdge(3, 2);*/
    g1.addEdge([5, 8, 7, 4, 6, 9, 3, 2]);
    foreach(head, tail; g1.edge)
        writeln("\t", head, "\t", tail);
    writeln(g1._indexHead);
    writeln(g1._indexTail);
    writeln(g1._sumHead);
    writeln(g1._sumTail);
    foreach(v; iota(g1.vertexCount))
    {
        writeln("\td(", v, ") =\t", g1.degree(v), "\tn(", v, ") = ", g1.neighbours(v));
    }
    writeln;
    assert(isSorted(map!(a => g1._head[g1._indexHead[a]])(iota(g1._head.length))));
    foreach (h; iota(10))
    {
        foreach (t; iota(10))
        {
            if ((h == 5 && t == 8) || (h == 8 && t == 5) ||
                (h == 7 && t == 4) || (h == 4 && t == 7) ||
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
    foreach(i; 0 .. g1.edgeCount)
    {
        size_t h = g1._head[i];
        size_t t = g1._tail[i];
        assert(i == g1.edgeID(h, t));
        assert(i == g1.edgeID(t, h));
    }

    auto g2 = new Graph!true;
    g2.addVertices(10);
    assert(g2.vertexCount == 10);
/*    g2.addEdge(5, 8);
    g2.addEdge(7, 4);
    g2.addEdge(6, 9);
    g2.addEdge(3, 2);*/
    g2.addEdge([5, 8, 7, 4, 6, 9, 3, 2]);
    foreach(head, tail; g2.edge)
        writeln("\t", head, "\t", tail);
    writeln(g2._indexHead);
    writeln(g2._indexTail);
    writeln(g2._sumHead);
    writeln(g2._sumTail);
    foreach(v; iota(g2.vertexCount))
    {
        writeln("\td_out(", v, ") =\t", g2.degreeOut(v), "\tn_out(", v, ") = ", g2.neighboursOut(v),
                "\td_in(", v, ") =\t", g2.degreeIn(v), "\tn_in(", v, ") = ", g2.neighboursIn(v));
    }
    assert(isSorted(map!(a => g2._head[g2._indexHead[a]])(iota(g2._head.length))));
    foreach (h; iota(10))
    {
        foreach (t; iota(10))
        {
            if ((h == 5 && t == 8) ||
                (h == 7 && t == 4) ||
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
    foreach(i; 0 .. g2.edgeCount)
    {
        size_t h = g2._head[i];
        size_t t = g2._tail[i];
        assert(i == g2.edgeID(h, t));
    }
}
