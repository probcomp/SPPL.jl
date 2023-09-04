module Sampling
using SPPL
using Distributions
using InteractiveUtils
using BenchmarkTools

# children = NominalLeaf.([Symbol(i) for i in 'a':'z'], Ref(["a"]))
# p = ProductSPE(children)
# display(rand(p, 10))
# @btime rand($p, 1000)

c = ContinuousLeaf(:x, Normal(0, 1))
display(pdf(c, Dict(:x => 0.0)))
end
