module dgraph.graph;

import std.algorithm, std.exception, std.range;

final class Graph(bool dir)
{
  private:
    size_t[] _head;
    size_t[] _tail;
    size_t[] _indexHead;
    size_t[] _indexTail;
    size_t[] _sumHead = [0];
    size_t[] _sumTail = [0];

    void indexEdges()
    {
        _indexHead ~= iota(_indexHead.length, _head.length).array;
        _indexTail ~= iota(_indexTail.length, _tail.length).array;
        assert(_indexHead.length == _indexTail.length);
        schwartzSort!(a => _head[a], "a < b")(_indexHead);
        schwartzSort!(a => _tail[a], "a < b")(_indexTail);
    }

  public:
    enum bool directed = dir;

    size_t vertexCount() @property const pure nothrow
    {
        assert(_sumHead.length == _sumTail.length);
        return _sumHead.length - 1;
    }

    static if (!directed)
    {
        size_t degree(immutable size_t v)
        {
            return (_sumHead[v + 1] - _sumHead[v])
                 + (_sumTail[v + 1] - _sumTail[v]);
        }

        alias degreeIn = degree;
        alias degreeOut = degree;
    }
    else
    {
        size_t degreeIn(immutable size_t v)
        {
            return _sumTail[v + 1] - _sumTail[v];
        }

        size_t degreeOut(immutable size_t v)
        {
            return _sumHead[v + 1] - _sumHead[v];
        }
    }

    static if (!directed)
    {
        auto neighbours(immutable size_t v)
        {
            return chain(map!(a => _tail[_indexHead[a]])(iota(_sumHead[v], _sumHead[v + 1])),
                         map!(a => _head[_indexTail[a]])(iota(_sumTail[v], _sumTail[v + 1])));
        }

        alias neighbors = neighbours;
        alias neighboursIn  = neighbours;
        alias neighboursOut = neighbours;
    }
    else
    {
        auto neighboursIn(immutable size_t v)
        {
            return map!(a => _head[_indexTail[a]])(iota(_sumTail[v], _sumTail[v + 1]));
        }

        auto neighboursOut(immutable size_t v)
        {
            return map!(a => _tail[_indexHead[a]])(iota(_sumHead[v], _sumHead[v + 1]));
        }
    }

    alias neighborsIn = neighboursIn;
    alias neighborsOut = neighboursOut;

    void addVertices(immutable size_t n)
    {
        size_t l = _sumHead.length;
        _sumHead.length += n;
        _sumTail.length += n;
        assert(_sumHead.length == _sumTail.length);
        _sumHead[l .. $] = _sumHead[l - 1];
        _sumTail[l .. $] = _sumTail[l - 1];
    }

    void addEdge(size_t head, size_t tail)
    {
        enforce(head < this.vertexCount);
        enforce(tail < this.vertexCount);
        static if (!directed)
        {
            if (tail < head)
            {
                size_t tmp = head;
                head = tail;
                tail = tmp;
            }
        }
        _head ~= head;
        _tail ~= tail;
        ++_sumHead[head + 1 .. $];
        ++_sumTail[tail + 1 .. $];
        indexEdges();
    }

    auto edges() @property pure
    {
        return zip(_head, _tail);
    }
}

unittest
{
    import std.stdio;
    auto g1 = new Graph!false;
    g1.addVertices(10);
    assert(g1.vertexCount == 10);
    g1.addEdge(5, 8);
    g1.addEdge(7, 4);
    g1.addEdge(6, 9);
    g1.addEdge(3, 2);
    foreach(head, tail; g1.edges)
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

    auto g2 = new Graph!true;
    g2.addVertices(10);
    assert(g2.vertexCount == 10);
    g2.addEdge(5, 8);
    g2.addEdge(7, 4);
    g2.addEdge(6, 9);
    g2.addEdge(3, 2);
    foreach(head, tail; g2.edges)
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
}
