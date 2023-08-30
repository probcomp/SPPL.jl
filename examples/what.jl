using SPPL
using Distributions
using BenchmarkTools
c = ContinuousLeaf(:x, Normal(0,1))
@code_warntype rand(c)
rand(c)
@btime rand($c)
