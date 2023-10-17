using BenchmarkTools
using Distributions
using SPPL

i = IntervalLeaf(:x, Normal(0,1), -1.0..0.0, Dict(:x=>identity, :y=>exp, :z=>abs))
j = IntervalLeaf(:a, Normal(1,1), -0.0 .. 2.0, Dict(:a=>identity, :b=>log, :c=>exp))
k = IntervalLeaf(:d, Normal(0,1), -1.0..0.0, Dict(:d=>identity, :e=>exp, :f=>abs))
l = IntervalLeaf(:g, Normal(0,1), -1.0..0.0, Dict(:g=>identity, :h=>exp, :i=>abs))

product_node = ProductSPE((i,j,k,l))
@btime rand($product_node)
@time rand(product_node,1000000)