module dgraph.graph;

import std.exception, std.range;

final class Graph(bool directed)
{
  private:
    size_t v; // number of vertices;
    size_t[] _head;
    size_t[] _tail;

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
    foreach(head, tail; g1.edges)
        writeln("\t", head, "\t", tail);

    auto g2 = new Graph!true;
    g2.v = 10;
    g2.addEdge(5, 8);
    g2.addEdge(7, 4);
    foreach(head, tail; g2.edges)
        writeln("\t", head, "\t", tail);
}
