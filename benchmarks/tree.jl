module Tree
using SPPL
using Distributions
using BenchmarkTools

s = ContinuousLeaf(:x, Normal(0, 1), -1 .. 1, x -> 2 * x)
r = ContinuousLeaf(:x, Normal(-1, 2), -3 .. (-1), x -> -x)
t = ContinuousLeaf(:z, Normal(-1, 2), -3 .. (-1), x -> -x)
w = ContinuousLeaf(:a, Normal(0, 1), -1 .. 1, x -> 2 * x)
weights = [0.5, 0.5]
sus = SumSPE(weights, [s, s])
# prod = ProductSPE([s,t])
prod = ProductSPE([sus, w])
display(rand(prod))
# display(rand(prod))
end
