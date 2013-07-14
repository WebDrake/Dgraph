module dgraph.metric;

import std.conv, std.traits;

import dgraph.graph;

struct VertexQueue
{
    private size_t _length, maxLength, head, tail;
    private size_t[] queue;

    this(size_t m)
    {
        maxLength = m;
        queue = new size_t[maxLength];
    }

    bool empty() @property const pure nothrow
    {
        return (_length == 0);
    }

    size_t length() @property const pure nothrow
    {
        return _length;
    }

    void push(immutable size_t v) nothrow
    {
        assert(v < maxLength, "Vertex ID is too large!");
        queue[tail] = v;
        tail = (tail + 1) % maxLength;
        ++_length;
        assert(_length <= maxLength, "Length has exceeded total number of vertices!");
    }

    auto front() @property const pure
    {
        assert(!this.empty, "Node queue is empty!");
        return queue[head];
    }

    void pop() nothrow
    {
        head = (head + 1) % maxLength;
        --_length;
    }
}

unittest
{
    auto q = VertexQueue(8);
    q.push(3);
    q.push(7);
    q.push(4);
    assert(q.front == 3);
    q.pop();
    assert(q.front == 7);
    q.pop();
    assert(q.front == 4);
    q.push(5);
    assert(q.front == 4);
    q.pop();
    assert(q.front == 5);
    q.pop();
    assert(q.empty);
    q.push(2);
    assert(q.front == 2);
    q.pop();
    assert(q.empty);
}

auto betweenness(T = double, bool directed)(ref Graph!directed g, bool[] ignore)
    if (isFloatingPoint!T)
{
    T[] centrality = new T[g.vertexCount];
    centrality[] = to!T(0);
    size_t[] stack = new size_t[g.vertexCount];
    T[] sigma = new T[g.vertexCount];
    T[] delta = new T[g.vertexCount];
    long[] d = new long[g.vertexCount];
    auto q = VertexQueue(g.vertexCount);
    size_t[][] p = new size_t[][g.vertexCount];

    sigma[] = to!T(0);
    delta[] = to!T(0);
    d[] = -1L;

    foreach (s; 0 .. g.vertexCount)
    {
        if (!ignore[s])
        {
            size_t stackLength = 0;
            assert(q.empty);
            sigma[s] = to!T(1);
            d[s] = 0L;
            q.push(s);

            while(!q.empty)
            {
                size_t v = q.front;
                q.pop();
                stack[stackLength] = v;
                ++stackLength;
                foreach (w; g.neighboursOut(v))
                {
                    if (!ignore[w])
                    {
                        if (d[w] < 0L)
                        {
                            q.push(w);
                            d[w] = d[v] + 1L;
                            assert(sigma[w] == to!T(0));
                            sigma[w] = sigma[v];
                            p[w].length = 1;
                            p[w][0] = v;
                        }
                        else if (d[w] > (d[v] + 1L))
                        {
                            /* w has already been encountered, but we've
                               found a shorter path to the source.  This
                               is probably only relevant to the weighted
                               case, but let's keep it here in order to
                               be ready for that update. */
                            d[w] = d[v] + 1L;
                            sigma[w] = sigma[v];
                            p[w].length = 1;
                            p[w][0] = v;
                        }
                        else if (d[w] == (d[v] + 1L))
                        {
                            sigma[w] += sigma[v];
                            p[w] ~= v;
                        }
                    }
                }
            }

            while(stackLength > to!size_t(0))
            {
                --stackLength;
                auto w = stack[stackLength];
                foreach (v; p[w])
                {
                    delta[v] += ((sigma[v] / sigma[w]) * (to!T(1) + delta[w]));
                }
                if (w != s)
                {
                    centrality[w] += delta[w];
                }
                sigma[w] = to!T(0);
                delta[w] = to!T(0);
                d[w] = -1L;
            }
        }
    }

    static if (!directed)
    {
        centrality[] /= 2;
    }

    return centrality;
}
