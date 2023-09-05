using BenchmarkTools
using Distributions
using SPPL

i = IntervalLeaf(:x, Normal(0,1), -Inf..Inf, Dict(:x=>identity, :y=>exp, :z=>abs))
# j = IntervalLeaf(:x, Normal(0,1), 0.0 .. 1.0, Dict(:x=>identity, :y=>log, :z=>exp))

e = SolvedEvent(:x, -1.0..1.0)
f = SolvedEvent(:a, -1.0..1.0)
g = SolvedEvent(:y, 1.0..2.0)
h = SolvedEvent(:z, 1.0..2.0)
ee = condition(i,e)
ff = condition(i,f)
gg = condition(i,g)
hh = condition(i,h)


e_new = SolvedEvent(:x, IntervalSet(@int("(1.0, 1.5)"), 1.7..2.0))
cc = condition(hh, e_new)

e_new_2 = SolvedEvent(:x, 1.0..1.6)
cc2 = condition(cc, e_new_2)

# Sum Node
i = IntervalLeaf(:x, Normal(0,1), -1.0..0.0, Dict(:x=>identity, :y=>exp, :z=>abs))
j = IntervalLeaf(:x, Normal(0,1), 0.0 .. 1.0, Dict(:x=>identity, :y=>log, :z=>exp))
e = SolvedEvent(:x, -5.5..5.5)
sum_node = SumSPE([0.5, 0.5], [i, j])
sum_new = condition(sum_node, e)
SPPL.partition(sum_new)

# Product Node
i = IntervalLeaf(:x, Normal(0,1), -Inf..Inf, Dict(:x=>identity))
j = IntervalLeaf(:a, Normal(0,1), -Inf .. Inf, Dict(:a=>identity, :b => abs))
product_node = ProductSPE([i,j])
e = SolvedEvent(:x, -2..2)
conditioned_product = condition(product_node, e)
conditioned_product.Z

