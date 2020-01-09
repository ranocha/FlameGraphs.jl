using FlameGraphs, AbstractTrees
using Base.StackTraces: StackFrame
using Test

# useful for testing
stackframe(func, file, line; C=false) = StackFrame(Symbol(func), Symbol(file), line, nothing, C, false, 0)

@testset "FlameGraphs.jl" begin
    backtraces = UInt64[0, 4, 3, 2, 1,   # order: calles then caller
                        0, 6, 5, 1,
                        0, 8, 7,
                        0, 4, 3, 2, 1,
                        0]
    lidict = Dict{UInt64,StackFrame}(1=>stackframe(:f1, :file1, 1),
                                     2=>stackframe(:f2, :file1, 5),
                                     3=>stackframe(:f3, :file2, 1),
                                     4=>stackframe(:f2, :file1, 15),
                                     5=>stackframe(:f4, :file1, 20),
                                     6=>stackframe(:f5, :file3, 1),
                                     7=>stackframe(:f1, :file1, 2),
                                     8=>stackframe(:f6, :file3, 10))
    g = flamegraph(backtraces; lidict=lidict)
    @test all(node->node.data.status == 0, PostOrderDFS(g))
    level1 = collect(g)
    @test length(level1) == 2
    n1, n2 = level1
    @test n1.data.sf.func === :f1
    @test n1.data.sf.line == 1
    @test n1.data.hspan == 1:3
    @test n2.data.sf.func === :f1
    @test n2.data.sf.line == 2
    @test n2.data.hspan == 4:4
    level2a = collect(n1)
    @test length(level2a) == 2
    n3, n4 = level2a
    @test n3.data.sf.func === :f2
    @test n3.data.sf.line == 5
    @test n3.data.hspan == 1:2
    @test n4.data.sf.func === :f4
    @test n4.data.sf.line == 20
    @test n4.data.hspan == 3:3
    level2b = collect(n2)
    @test length(level2b) == 1
    n5 = level2b[1]
    @test n5.data.sf.func === :f6
    @test n5.data.sf.line == 10
    @test n5.data.hspan == 4:4
    level3a = collect(n3)
    @test length(level3a) == 1
    n6 = level3a[1]
    @test n6.data.sf.func === :f3
    @test n6.data.sf.line == 1
    @test n6.data.hspan == 1:2
    level3b = collect(n4)
    @test length(level3b) == 1
    n7 = level3b[1]
    @test n7.data.sf.func === :f5
    @test n7.data.sf.line == 1
    @test n7.data.hspan == 3:3
    @test isempty(n5)
    level4a = collect(n6)
    @test length(level4a) == 1
    n8 = level4a[1]
    @test n8.data.sf.func === :f2
    @test n8.data.sf.line == 15
    @test n8.data.hspan == 1:2
    @test isempty(n7)
    @test isempty(n8)

    # Now make some of them C calls
    lidict = Dict{UInt64,StackFrame}(1=>stackframe(:f1, :file1, 1),
                                     2=>stackframe(:jl_f, :filec, 55; C=true),
                                     3=>stackframe(:jl_invoke, :file2, 1; C=true),
                                     4=>stackframe(:f2, :file1, 15),
                                     5=>stackframe(:f4, :file1, 20),
                                     6=>stackframe(:f5, :file3, 1),
                                     7=>stackframe(:f1, :file1, 2),
                                     8=>stackframe(:f6, :file3, 10))
    g = flamegraph(backtraces; lidict=lidict)
    level1 = collect(g)
    @test length(level1) == 2
    n1, n2 = level1
    @test n1.data.sf.func === :f1
    @test n1.data.sf.line == 1
    @test n1.data.hspan == 1:3
    @test n1.data.status == FlameGraphs.runtime_dispatch
    @test n2.data.sf.func === :f1
    @test n2.data.sf.line == 2
    @test n2.data.hspan == 4:4
    @test n2.data.status == 0
    level2a = collect(n1)
    @test length(level2a) == 2
    n3, n4 = level2a
    @test n3.data.sf.func === :f4
    @test n3.data.sf.line == 20
    @test n3.data.hspan == 1:1
    @test n4.data.sf.func === :f2
    @test n4.data.sf.line == 15
    @test n4.data.hspan == 2:3
    level2b = collect(n2)
    @test length(level2b) == 1
    n5 = level2b[1]
    @test n5.data.sf.func === :f6
    @test n5.data.sf.line == 10
    @test n5.data.hspan == 4:4
    level3a = collect(n3)
    @test length(level3a) == 1
    n6 = level3a[1]
    @test n6.data.sf.func === :f5
    @test n6.data.sf.line == 1
    @test n6.data.hspan == 1:1
    @test isempty(n4)
    @test isempty(n5)
    @test isempty(n6)
end
