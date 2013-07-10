module dgraph.graph;

import std.algorithm, std.exception, std.range;

final class Graph(bool directed)
{
  private:
    size_t v; // number of vertices;
    size_t[] _head;
    size_t[] _tail;
    size_t[] _indexHead;
    size_t[] _indexTail;

    void indexEdges()
    {
        _indexHead ~= iota(_indexHead.length, _head.length).array;
        _indexTail ~= iota(_indexTail.length, _tail.length).array;
        assert(_indexHead.length == _indexTail.length);
        schwartzSort!(a => _head[a], "a < b")(_indexHead);
        schwartzSort!(a => _tail[a], "a < b")(_indexTail);
    }

  public:
    void addEdge(size_t head, size_t tail)
    {
        enforce(head < v);
        enforce(tail < v);
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
    g1.v = 10;
    g1.addEdge(5, 8);
    g1.addEdge(7, 4);
    g1.addEdge(6, 9);
    g1.addEdge(3, 2);
    foreach(head, tail; g1.edges)
        writeln("\t", head, "\t", tail);
    writeln(g1._indexHead);
    writeln(g1._indexTail);
    writeln;
    assert(isSorted(map!(a => g1._head[g1._indexHead[a]])(iota(g1._head.length))));

    auto g2 = new Graph!true;
    g2.v = 10;
    g2.addEdge(5, 8);
    g2.addEdge(7, 4);
    g2.addEdge(6, 9);
    g2.addEdge(3, 2);
    foreach(head, tail; g2.edges)
        writeln("\t", head, "\t", tail);
    writeln(g2._indexHead);
    writeln(g2._indexTail);
    assert(isSorted(map!(a => g2._head[g2._indexHead[a]])(iota(g2._head.length))));
}
