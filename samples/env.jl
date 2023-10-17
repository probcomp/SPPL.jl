using BenchmarkTools
using Distributions
using SPPL

i = IntervalLeaf(:x, Normal(0,1), -1.0..0.0, Dict(:x=>identity, :y=>exp, :z=>abs))
j = IntervalLeaf(:x, Normal(0,1), 0.0 .. 1.0, Dict(:x=>identity, :y=>log, :z=>exp))
@btime rand($i)

# Sum and Product Nodes
sum_node = SumSPE([0.5, 0.5], [i, j])
rand(sum_node)
@btime rand($sum_node)

k = IntervalLeaf(:a, Normal(1,1), -0.0 .. 2.0, Dict(:a=>identity, :b=>log, :c=>exp))
product_node = ProductSPE((i,k))
rand(product_node)
@btime rand($product_node)


# Interval Leaves
h = PiecewiseLeaf(:x, Normal(0,1), IntervalSet(-2.0..(-1.0), 1.0..2.0), Dict(:x=>identity, :y=>abs, :z => abs))
rand(h)
@btime rand($h)

sum_node = SumSPE([i,h])
@btime rand($sum_node)

