using SPPL
using LoopVectorization
using Distributions
using BenchmarkTools

n = 1000
x = rand(Float64, n)
y = rand(Float64, n)

a = tuple(x...)
b = tuple(y...)
@btime vcat($x,$y);
@btime ($a...,$b...);
