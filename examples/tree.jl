module Tree
using SPPL
using Distributions

n = Normal(0.0, 1.0)
d = DisjointNormal(n, [(1.0, 2.0), (3.0, 4.0)])
println(rand(d))
end
