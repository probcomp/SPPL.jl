using BenchmarkTools

function apply(f, x)
    f(x)
end
function foo()
    N = rand(2:10)
    display(N)
    x = [(rand((0, 1)), Set(rand(100))) for i = 1:N]
    # x = [(rand((0, 1)), Set(rand(10))) for i = 1:10]
    # @btime union(Iterators.map(v -> v[2], Iterators.filter(s -> s[1] == 0, $x))...)
    @btime union([v[2] for v in filter(s -> s[1] == 0, $x)]...)
    @btime union([v[2] for v in Iterators.filter(s -> s[1] == 0, $x)]...)
    @btime reduce(union, map(v -> v[2], Iterators.filter(s -> s[1] == 0, $x)))
    @btime reduce(union, Iterators.map(v -> v[2], Iterators.filter(s -> s[1] == 0, $x)))

    # @time union([v[2] for v in filter(s -> s[1] == 0, x)]...)
    # @time union([v[2] for v in Iterators.filter(s -> s[1] == 0, x)]...)
    # @time reduce(union, map(v -> v[2], Iterators.filter(s -> s[1] == 0, x)))
    # @time reduce(union, Iterators.map(v -> v[2], Iterators.filter(s -> s[1] == 0, x)))

    1
end
foo()
