using BenchmarkTools
using Distributions
using SPPL

c = SolvedEvent(:x, FiniteReal(1,2,3.0))
d = UnsolvedEvent(:z, -Inf..Inf, exp)
e = SolvedEvent(:x, -1.0..1.0)
f = SolvedEvent(:a, -1.0..1.0)
g = SolvedEvent(:y, 1.0..2.0)
h = SolvedEvent(:z, 1.0..2.0)

and = intersect(c,h)
or = OrEvent([and], [f,g])
typeof(or)