module dgraph.metric;

import std.algorithm, std.conv, std.range, std.traits;

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

auto betweenness(T = double, bool directed)(ref Graph!directed g, bool[] ignore = null)
    if (isFloatingPoint!T)
{
    T[] centrality = new T[g.vertexCount];
    centrality[] = to!T(0);
    size_t[] stack = new size_t[g.vertexCount];
    T[] sigma = new T[g.vertexCount];
    T[] delta = new T[g.vertexCount];
    long[] d = new long[g.vertexCount];
    auto q = VertexQueue(g.vertexCount);
    Appender!(size_t[])[] p = new Appender!(size_t[])[g.vertexCount];

    sigma[] = to!T(0);
    delta[] = to!T(0);
    d[] = -1L;

    foreach (immutable s; 0 .. g.vertexCount)
    {
        if (ignore && ignore[s])
        {
            continue;
        }

        size_t stackLength = 0;
        assert(q.empty);
        sigma[s] = to!T(1);
        d[s] = 0L;
        q.push(s);

        while (!q.empty)
        {
            size_t v = q.front;
            q.pop();
            stack[stackLength] = v;
            ++stackLength;
            foreach (immutable w; g.neighboursOut(v))
            {
                if (ignore && ignore[w])
                {
                    continue;
                }

                if (d[w] < 0L)
                {
                    q.push(w);
                    d[w] = d[v] + 1L;
                    assert(sigma[w] == to!T(0));
                    sigma[w] = sigma[v];
                    p[w].clear;
                    p[w].put(v);
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
                    p[w].clear;
                    p[w].put(v);
                }
                else if (d[w] == (d[v] + 1L))
                {
                    sigma[w] += sigma[v];
                    p[w].put(v);
                }
            }
        }

        while (stackLength > to!size_t(0))
        {
            --stackLength;
            auto w = stack[stackLength];
            foreach (immutable v; p[w].data)
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

    static if (!directed)
    {
        centrality[] /= 2;
    }

    return centrality;
}

size_t largestClusterSize(bool directed)(ref Graph!directed g, bool[] ignore)
{
    long[] cluster = new long[g.vertexCount];
    cluster[] = -1L;
    auto q = VertexQueue(g.vertexCount);
    size_t largestCluster = 0;

    foreach (immutable s; 0 .. g.vertexCount)
    {
        if (!ignore[s] && cluster[s] < 0)
        {
            assert(q.empty);
            cluster[s] = 0;
            q.push(s);
            size_t clusterSize = 1;

            while (!q.empty)
            {
                size_t v = q.front;
                q.pop();

                static if (directed)
                {
                    auto allNeighbours = chain(g.neighboursIn(v), g.neighboursOut(v));
                }
                else
                {
                    auto allNeighbours = g.neighbours(v);
                }

                foreach (immutable w; allNeighbours)
                {
                    if (!ignore[w] && cluster[w] < 0)
                    {
                       q.push(w);
                       cluster[w] = clusterSize;
                       ++clusterSize;
                    }
                }
            }

            largestCluster = max(largestCluster, clusterSize);
        }
    }

    return largestCluster;
}

unittest
{
    import std.stdio, std.typecons;

    void clusterTest1(bool directed = false)()
    {
        auto g = new Graph!directed;
        bool[] ignore = new bool[5];
        g.addVertices(5);
        g.addEdge(0, 1);
        g.addEdge(1, 2);
        g.addEdge(3, 4);
        size_t largest = largestClusterSize(g, ignore);
        writeln("largest cluster size = ", largest);

        ignore[0 .. 2] = true;
        largest = largestClusterSize(g, ignore);
        writeln("largest cluster size = ", largest);
    }

    void clusterTest2(bool directed = false)()
    {
        auto g = new Graph!directed;
        bool ignore[] = new bool[100];
        g.addVertices(100);
        foreach (immutable i; 0 .. 100)
        {
            foreach (immutable j; i .. 100)
            {
                g.addEdge(i, j);
            }
        }
        writeln("largest cluster size = ", largestClusterSize(g, ignore));
        foreach (immutable i; 0 .. 100)
        {
            ignore[i] = true;
            writeln(i, ": largest cluster size = ", largestClusterSize(g, ignore));
        }
    }

    void clusterTest3(bool directed = false)(immutable size_t n)
    {
        auto g = new Graph!directed;
        bool ignore[] = new bool[n];
        g.addVertices(n);
        foreach (immutable i; 0 .. n - 1)
        {
            g.addEdge(i, i + 1);
        }
        writeln("largest cluster size = ", largestClusterSize(g, ignore));
        ignore[n / 4] = true;
        writeln("largest cluster size = ", largestClusterSize(g, ignore));
    }

    void clusterTest50(bool directed = false)()
    {
        import std.random;
        import dgraph.test.samplegraph50;

        auto g = new Graph!directed;
        bool ignore[] = new bool[50];
        g.addVertices(50);
        g.addEdge(sampleGraph50);
        writeln("[[50]] largest cluster size = ", largestClusterSize(g, ignore));

        foreach (immutable i; 0 .. 10)
        {
            auto sample1 = randomSample(iota(50), 7, Random(100 * i * i));
            ignore[] = false;
            foreach (immutable s; sample1)
            {
                ignore[s] = true;
            }
            writeln("[[50.", i, "]] largest cluster size = ", largestClusterSize(g, ignore));
        }

    }

    clusterTest1!false();
    clusterTest2!false();
    clusterTest1!true();
    clusterTest2!true();

    clusterTest50!false();
    clusterTest50!true();

    clusterTest3!false(40);
    clusterTest3!true(40);
}
