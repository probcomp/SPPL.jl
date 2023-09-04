using Dictionaries
using BenchmarkTools

function foo(n)
    x = rand(n)
    y = fill(true, n)
    @btime Dictionary($x, $y)
    @btime Set($x)
    return
end
foo(100)
