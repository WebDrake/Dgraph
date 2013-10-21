import std.datetime, std.stdio;

import dgraph.graph, dgraph.metric, dgraph.test.samplegraph50;

void betw(Graph)(ref Graph g)
    if(isGraph!Graph)
{
    auto centrality = betweenness(g);
    assert(centrality.length == g.vertexCount);
/*    writeln("Centrality values:");
    foreach (immutable i, immutable c; centrality)
    {
        writeln("\t", i, "\t", c);
    }*/
}

void main()
{
    alias Graph = CachedEdgeList!false;
    auto g = new Graph;
    g.vertexCount = 50;

    foreach (immutable i; 0 .. sampleGraph50.length / 2)
    {
        g.addEdge(sampleGraph50[2*i], sampleGraph50[2 * i + 1]);
    }
    writeln("Vertex count: ", g.vertexCount);
    writeln("Edge count: ", g.edgeCount);

    StopWatch watch;
    watch.start;
    foreach (immutable _; 0 .. 10_000)
    {
        betw(g);
    }
    watch.stop;
    writeln("Done in ", watch.peek.msecs, " ms.");
}
